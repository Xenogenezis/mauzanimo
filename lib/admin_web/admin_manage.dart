import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/verification_badge.dart';
import '../repositories/notification_repository.dart';
import '../widgets/app_image.dart';
import 'audit.dart';
import 'detail_panel.dart';

// Rich detail panels and one-click actions for the web admin:
// adoptions, pets and users, each linking to the others.

final _db = FirebaseFirestore.instance;
typedef Json = Map<String, dynamic>;

const adminRoles = ['admin', 'superAdmin'];
const allRoles = ['adopter', 'rehomer', 'volunteer', 'partner', 'admin', 'superAdmin'];

/// The stages an application normally moves through, in order.
const _flow = ['application', 'screening', 'meet_greet', 'trial', 'completed'];

String stageLabel(String s) => switch (s) {
      'application' => 'Application',
      'screening' => 'Screening',
      'meet_greet' => 'Meet & greet',
      'trial' => 'Trial',
      'completed' => 'Adopted',
      'rejected' => 'Rejected',
      _ => s,
    };

String? _nextStage(String s) {
  final i = _flow.indexOf(s);
  return i >= 0 && i < _flow.length - 1 ? _flow[i + 1] : null;
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

Future<void> _run(BuildContext context, String done, Future<void> Function() job) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await job();
    messenger.showSnackBar(SnackBar(content: Text(done)));
  } on FirebaseException catch (e) {
    messenger.showSnackBar(SnackBar(
      backgroundColor: Colors.red,
      content: Text(e.code == 'permission-denied' ? 'Permission denied by Firestore rules.' : 'Failed: ${e.message}'),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text('Failed: $e')));
  }
}

Future<String?> _askText(BuildContext context,
    {required String title, required String label, String initial = '', bool required = true, int maxLines = 3}) {
  final ctl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: TextField(
            controller: ctl,
            autofocus: true,
            maxLines: maxLines,
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (required && ctl.text.trim().isEmpty) return;
            Navigator.pop(c, ctl.text.trim());
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<bool> _confirm(BuildContext context, String title, String body, {String ok = 'Confirm', bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r == true;
}

/// Mauritian numbers are 8 digits; WhatsApp needs the +230 prefix.
String _waNumber(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  return digits.length == 8 ? '230$digits' : digits;
}

Widget _contactButtons({String? email, String? phone, String subject = 'MauZanimo'}) {
  final e = (email ?? '').trim();
  final p = (phone ?? '').trim();
  return Wrap(spacing: 8, runSpacing: 8, children: [
    if (e.isNotEmpty)
      OutlinedButton.icon(
        icon: const Icon(Icons.email_outlined, size: 18),
        label: const Text('Email'),
        onPressed: () => launchUrl(Uri(scheme: 'mailto', path: e, queryParameters: {'subject': subject})),
      ),
    if (p.isNotEmpty) ...[
      OutlinedButton.icon(
        icon: const Icon(Icons.chat_outlined, size: 18),
        label: const Text('WhatsApp'),
        onPressed: () => launchUrl(Uri.parse('https://wa.me/${_waNumber(p)}')),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.call_outlined, size: 18),
        label: const Text('Call'),
        onPressed: () => launchUrl(Uri(scheme: 'tel', path: p)),
      ),
    ],
  ]);
}

/// Pet photo looked up by id, cached for the session (used in table cells).
class PetThumb extends StatelessWidget {
  final String? petId;
  final double size;
  const PetThumb(this.petId, {super.key, this.size = 44});

  static final Map<String, Future<DocumentSnapshot<Json>>> _cache = {};

  @override
  Widget build(BuildContext context) {
    final id = petId;
    if (id == null || id.isEmpty) return SizedBox(width: size, height: size);
    final f = _cache.putIfAbsent(id, () => _db.collection('pets').doc(id).get());
    return FutureBuilder<DocumentSnapshot<Json>>(
      future: f,
      builder: (context, s) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: AppImage(s.data?.data()?['imageUrl'] as String?, width: size, height: size, decodeWidth: size),
      ),
    );
  }
}

/// Private admin-only notes about a record, stored in `admin_notes`.
class AdminNotes extends StatefulWidget {
  final String collection;
  final String docId;
  const AdminNotes({super.key, required this.collection, required this.docId});

  @override
  State<AdminNotes> createState() => _AdminNotesState();
}

class _AdminNotesState extends State<AdminNotes> {
  final _ctl = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  String _saved = '';

  DocumentReference<Json> get _ref => _db.collection('admin_notes').doc('${widget.collection}_${widget.docId}');

  @override
  void initState() {
    super.initState();
    _ref.get().then((s) {
      if (!mounted) return;
      _saved = s.data()?['text'] as String? ?? '';
      setState(() {
        _ctl.text = _saved;
        _loaded = true;
      });
    }, onError: (_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await _run(context, 'Notes saved', () async {
      await _ref.set({
        'text': _ctl.text.trim(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _saved = _ctl.text.trim();
    });
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => PanelSection(
        'Private admin notes',
        child: !_loaded
            ? const LinearProgressIndicator()
            : Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                TextField(
                  controller: _ctl,
                  maxLines: 4,
                  maxLength: 4000,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Only admins can see this, e.g. "home visit OK, fenced garden".',
                    border: OutlineInputBorder(),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _saving || _ctl.text.trim() == _saved ? null : _save,
                  child: const Text('Save notes'),
                ),
              ]),
      );
}

/// Live list of documents for a "linked records" section.
class _Linked extends StatelessWidget {
  final Query<Json> query;
  final String empty;
  final Widget Function(QueryDocumentSnapshot<Json>) tile;
  const _Linked({required this.query, required this.empty, required this.tile});

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Json>>(
        stream: query.limit(50).snapshots(),
        builder: (context, s) {
          if (s.hasError) return Text('Could not load: ${s.error}', style: const TextStyle(color: Colors.red));
          if (!s.hasData) return const LinearProgressIndicator();
          if (s.data!.docs.isEmpty) return Text(empty, style: const TextStyle(color: Colors.grey));
          return Column(children: [for (final d in s.data!.docs) tile(d)]);
        },
      );
}

Widget _docStream(DocumentReference<Json> ref, Widget Function(Json? data) build) =>
    StreamBuilder<DocumentSnapshot<Json>>(
      stream: ref.snapshots(),
      builder: (context, s) {
        if (s.hasError) return Text('Could not load: ${s.error}', style: const TextStyle(color: Colors.red));
        if (!s.hasData) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
        return build(s.data!.data());
      },
    );

// ---------------------------------------------------------------------------
// Adoptions
// ---------------------------------------------------------------------------

/// Moves an adoption to [stage]: records history, keeps the pet's public
/// status in step, logs it and notifies the adopter.
/// Pass [logStage] false when the caller already logs the stage change
/// (CollectionTable does for its dropdown).
Future<void> setAdoptionStage(DocumentReference<Json> ref, Json data, String stage,
    {String? reason, String? note, bool logStage = true}) async {
  final by = FirebaseAuth.instance.currentUser?.email ?? 'admin';
  final batch = _db.batch();
  batch.update(ref, {
    'currentStage': stage,
    if (stage == 'rejected') 'rejectionReason': reason ?? '',
    if (stage != 'rejected') 'rejectionReason': null,
    'updatedAt': FieldValue.serverTimestamp(),
    'stageHistory': FieldValue.arrayUnion([
      {
        'stage': stage,
        'timestamp': Timestamp.now(),
        'changedBy': by,
        'notes': note ?? (reason != null && reason.isNotEmpty ? 'Rejected: $reason' : 'Changed in web admin'),
      }
    ]),
  });
  final petId = data['petId'] as String?;
  String? petStatus;
  if (petId != null && petId.isNotEmpty) {
    petStatus = switch (stage) { 'completed' => 'adopted', 'rejected' => 'available', _ => 'pending' };
    batch.update(_db.collection('pets').doc(petId), {'status': petStatus});
  }
  await batch.commit();
  final before = data['currentStage'] ?? 'application';
  if (logStage) {
    unawaited(logAdminAction(
        action: 'status_change', collection: 'adoptions', docId: ref.id, summary: 'currentStage: $before → $stage'));
  }
  if (petStatus != null) {
    unawaited(logAdminAction(
        action: 'status_change', collection: 'pets', docId: petId!,
        summary: 'status → $petStatus (adoption ${ref.id} moved to $stage)'));
  }
  unawaited(NotificationRepository().notifyAdoptionStage(
    adoptionId: ref.id,
    stage: stage,
    adopterId: data['adopterId'] as String?,
    petName: data['petName'] as String?,
  ));
}

void showAdoptionPanel(BuildContext context, String adoptionId, {bool isSuper = false}) {
  final ref = _db.collection('adoptions').doc(adoptionId);
  showDetailPanel(context,
      title: 'Adoption application',
      width: 560,
      child: _docStream(ref, (a) => a == null
          ? const Text('This application no longer exists.')
          : _AdoptionDetail(ref: ref, a: a, isSuper: isSuper)));
}

class _AdoptionDetail extends StatelessWidget {
  final DocumentReference<Json> ref;
  final Json a;
  final bool isSuper;
  const _AdoptionDetail({required this.ref, required this.a, required this.isSuper});

  String get _stage => a['currentStage'] as String? ?? 'application';

  Future<void> _reject(BuildContext context) async {
    final reason = await _askText(context,
        title: 'Reject application', label: 'Reason (shown to the adopter)');
    if (reason == null || !context.mounted) return;
    await _run(context, 'Application rejected', () => setAdoptionStage(ref, a, 'rejected', reason: reason));
  }

  Future<void> _meetGreet(BuildContext context) async {
    final now = DateTime.now();
    final current = a['meetGreetAt'] is Timestamp ? (a['meetGreetAt'] as Timestamp).toDate() : null;
    final date = await showDatePicker(
        context: context,
        initialDate: current ?? now,
        firstDate: now.subtract(const Duration(days: 30)),
        lastDate: now.add(const Duration(days: 365)));
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: current != null ? TimeOfDay.fromDateTime(current) : const TimeOfDay(hour: 10, minute: 0));
    if (time == null || !context.mounted) return;
    final when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await _run(context, 'Meet & greet scheduled', () async {
      await ref.update({'meetGreetAt': Timestamp.fromDate(when), 'updatedAt': FieldValue.serverTimestamp()});
      unawaited(logAdminAction(
          action: 'update', collection: 'adoptions', docId: ref.id, summary: 'meet & greet → ${formatWhen(when)}'));
      if (_stage == 'application' || _stage == 'screening') {
        await setAdoptionStage(ref, a, 'meet_greet', note: 'Meet & greet scheduled for ${formatWhen(when)}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stage;
    final next = _nextStage(stage);
    final closed = stage == 'completed' || stage == 'rejected';
    final petId = a['petId'] as String? ?? '';
    final adopterId = a['adopterId'] as String? ?? '';
    final history = [...(a['stageHistory'] as List? ?? const [])]
      ..sort((x, y) {
        final tx = (x as Map)['timestamp'], ty = (y as Map)['timestamp'];
        return (ty is Timestamp ? ty.millisecondsSinceEpoch : 0).compareTo(tx is Timestamp ? tx.millisecondsSinceEpoch : 0);
      });

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // --- status + progress ---
      Row(children: [
        StatusPill(stage),
        const SizedBox(width: 10),
        Expanded(child: Text('Applied ${formatWhen(a['createdAt'])}', style: const TextStyle(color: Colors.grey))),
      ]),
      const SizedBox(height: 12),
      _StageStepper(stage: stage),
      if (stage == 'rejected' && (a['rejectionReason'] as String? ?? '').isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Reason: ${a['rejectionReason']}', style: const TextStyle(color: Colors.red)),
        ),
      if (a['meetGreetAt'] is Timestamp)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            const Icon(Icons.event, size: 18, color: Colors.orange),
            const SizedBox(width: 6),
            Text('Meet & greet: ${formatWhen(a['meetGreetAt'])}'),
          ]),
        ),
      const SizedBox(height: 14),

      // --- actions ---
      PanelSection('Actions',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            if (next != null && next != 'completed')
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text('Move to ${stageLabel(next)}'),
                onPressed: () => _run(context, 'Moved to ${stageLabel(next)}', () => setAdoptionStage(ref, a, next)),
              ),
            if (!closed)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Mark adopted'),
                onPressed: () async {
                  if (await _confirm(context, 'Mark as adopted?',
                          'The pet will be shown as adopted and the adopter notified.', ok: 'Mark adopted') &&
                      context.mounted) {
                    await _run(context, 'Marked as adopted', () => setAdoptionStage(ref, a, 'completed'));
                  }
                },
              ),
            if (!closed)
              OutlinedButton.icon(
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(a['meetGreetAt'] is Timestamp ? 'Reschedule meet & greet' : 'Schedule meet & greet'),
                onPressed: () => _meetGreet(context),
              ),
            if (!closed)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Reject…'),
                onPressed: () => _reject(context),
              ),
            if (closed)
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Reopen application'),
                onPressed: () => _run(context, 'Application reopened', () => setAdoptionStage(ref, a, 'application')),
              ),
          ])),

      // --- competing applications ---
      if (petId.isNotEmpty) _Competing(petId: petId, selfId: ref.id, isSuper: isSuper),

      // --- pet ---
      PanelSection('Pet post',
          trailing: petId.isEmpty
              ? null
              : TextButton(onPressed: () => showPetPanel(context, petId, isSuper: isSuper), child: const Text('Open pet')),
          child: petId.isEmpty
              ? const Text('No pet linked.')
              : _docStream(_db.collection('pets').doc(petId), (p) {
                  if (p == null) return Text('The pet post was deleted (id $petId).');
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppImage(p['imageUrl'] as String?, width: 110, height: 110, decodeWidth: 110),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['name'] as String? ?? a['petName'] as String? ?? 'Pet',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Wrap(spacing: 6, children: [
                          StatusPill(p['status'] as String? ?? 'available'),
                          if (p['hidden'] == true) const StatusPill('hidden'),
                        ]),
                        const SizedBox(height: 4),
                        Text([p['type'], p['age'], p['gender'], p['location']]
                            .where((v) => v != null && v.toString().isNotEmpty)
                            .join(' · ')),
                      ]),
                    ),
                  ]);
                })),

      // --- adopter ---
      PanelSection('Adopter',
          trailing: adopterId.isEmpty
              ? null
              : TextButton(onPressed: () => showUserPanel(context, adopterId, isSuper: isSuper), child: const Text('Open profile')),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InfoRow('Name', a['adopterName'] as String? ?? ''),
            InfoRow('Email', a['adopterEmail'] as String? ?? ''),
            InfoRow('Phone', a['adopterPhone'] as String? ?? ''),
            if (adopterId.isNotEmpty)
              _docStream(_db.collection('users').doc(adopterId), (u) => Column(children: [
                    InfoRow('Verification', _verificationName(u?['verificationLevel'] as String?)),
                    InfoRow('Role', u?['role'] as String? ?? 'adopter'),
                  ])),
            if (adopterId.isNotEmpty)
              StreamBuilder<QuerySnapshot<Json>>(
                stream: _db.collection('adoptions').where('adopterId', isEqualTo: adopterId).snapshots(),
                builder: (context, s) {
                  final docs = s.data?.docs ?? const [];
                  final done = docs.where((d) => d.data()['currentStage'] == 'completed').length;
                  return InfoRow('History', s.hasData ? '${docs.length} application(s), $done completed' : '');
                },
              ),
            const SizedBox(height: 8),
            _contactButtons(
              email: a['adopterEmail'] as String?,
              phone: a['adopterPhone'] as String?,
              subject: 'Your MauZanimo adoption application for ${a['petName'] ?? ''}',
            ),
          ])),

      AdminNotes(collection: 'adoptions', docId: ref.id),

      // --- timeline ---
      PanelSection('Timeline',
          child: history.isEmpty
              ? const Text('No stage changes yet.', style: TextStyle(color: Colors.grey))
              : Column(children: [
                  for (final h in history.cast<Map>())
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.circle, size: 12, color: StatusPill.colorFor(h['stage'] as String? ?? '')),
                      title: Text(stageLabel(h['stage'] as String? ?? '')),
                      subtitle: Text([formatWhen(h['timestamp']), h['changedBy'], h['notes']]
                          .where((v) => v != null && v.toString().isNotEmpty)
                          .join(' · ')),
                    ),
                ])),
    ]);
  }
}

class _StageStepper extends StatelessWidget {
  final String stage;
  const _StageStepper({required this.stage});

  @override
  Widget build(BuildContext context) {
    final rejected = stage == 'rejected';
    final at = _flow.indexOf(stage);
    return Row(children: [
      for (var i = 0; i < _flow.length; i++) ...[
        Expanded(
          child: Column(children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: rejected
                    ? Colors.red.withValues(alpha: 0.25)
                    : i <= at
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 4),
            Text(stageLabel(_flow[i]),
                style: TextStyle(fontSize: 11, color: i == at ? null : Colors.grey, fontWeight: i == at ? FontWeight.bold : null)),
          ]),
        ),
        if (i < _flow.length - 1) const SizedBox(width: 4),
      ],
    ]);
  }
}

class _Competing extends StatelessWidget {
  final String petId;
  final String selfId;
  final bool isSuper;
  const _Competing({required this.petId, required this.selfId, required this.isSuper});

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Json>>(
        stream: _db.collection('adoptions').where('petId', isEqualTo: petId).snapshots(),
        builder: (context, s) {
          final others = (s.data?.docs ?? const <QueryDocumentSnapshot<Json>>[])
              .where((d) => d.id != selfId && !['rejected'].contains(d.data()['currentStage']))
              .toList();
          if (others.isEmpty) return const SizedBox.shrink();
          return Card(
            color: Colors.orange.withValues(alpha: 0.1),
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('${others.length} other application(s) for this pet',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                for (final o in others)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(o.data()['adopterName'] as String? ?? o.id),
                    subtitle: Text('Applied ${formatWhen(o.data()['createdAt'])}'),
                    trailing: StatusPill(o.data()['currentStage'] as String? ?? 'application'),
                    onTap: () {
                      Navigator.pop(context);
                      showAdoptionPanel(context, o.id, isSuper: isSuper);
                    },
                  ),
              ]),
            ),
          );
        },
      );
}

String _verificationName(String? level) => switch (level) {
      'emailVerified' => 'Email verified',
      'phoneVerified' => 'Phone verified',
      'homeCheckDone' => 'Home check done',
      'pastAdoptionCompleted' => 'Trusted adopter',
      _ => 'Not verified',
    };

// ---------------------------------------------------------------------------
// Pets
// ---------------------------------------------------------------------------

void showPetPanel(BuildContext context, String petId, {bool isSuper = false}) {
  final ref = _db.collection('pets').doc(petId);
  showDetailPanel(context,
      title: 'Pet post',
      width: 560,
      child: _docStream(ref, (p) => p == null
          ? SelectableText('This pet post no longer exists.\nPet ID: $petId')
          : _PetDetail(ref: ref, p: p, isSuper: isSuper)));
}

Future<void> setPetHidden(DocumentReference<Json> ref, bool hidden) async {
  await ref.update({
    'hidden': hidden,
    'hiddenAt': hidden ? FieldValue.serverTimestamp() : null,
    'hiddenBy': hidden ? FirebaseAuth.instance.currentUser?.uid : null,
  });
  unawaited(logAdminAction(
      action: hidden ? 'hide' : 'unhide', collection: 'pets', docId: ref.id, summary: hidden ? 'Hidden from app' : 'Visible again'));
}

class _PetDetail extends StatelessWidget {
  final DocumentReference<Json> ref;
  final Json p;
  final bool isSuper;
  const _PetDetail({required this.ref, required this.p, required this.isSuper});

  String s(String k) => (p[k] ?? '').toString();

  Future<void> _setStatus(BuildContext context, String status) => _run(context, 'Status → $status', () async {
        final before = s('status').isEmpty ? 'available' : s('status');
        await ref.update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
        unawaited(logAdminAction(action: 'status_change', collection: 'pets', docId: ref.id, summary: 'status: $before → $status'));
      });

  Future<void> _edit(BuildContext context) async {
    final fields = <String, TextEditingController>{
      for (final k in ['name', 'type', 'age', 'gender', 'location', 'contact', 'description'])
        k: TextEditingController(text: s(k)),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit pet post'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final e in fields.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: e.value,
                    maxLines: e.key == 'description' ? 4 : 1,
                    decoration: InputDecoration(
                        labelText: e.key[0].toUpperCase() + e.key.substring(1), border: const OutlineInputBorder()),
                  ),
                ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final changes = <String, Object?>{
      for (final e in fields.entries)
        if (e.value.text.trim() != s(e.key)) e.key: e.value.text.trim(),
    };
    if (changes.isEmpty) return;
    await _run(context, 'Pet post updated', () async {
      await ref.update({...changes, 'updatedAt': FieldValue.serverTimestamp()});
      unawaited(logAdminAction(
          action: 'update', collection: 'pets', docId: ref.id, summary: 'Edited ${changes.keys.join(', ')}'));
    });
  }

  Future<void> _delete(BuildContext context) async {
    if (!await _confirm(context, 'Delete this pet post?', '${s('name')} will be removed permanently. This cannot be undone.',
            ok: 'Delete', danger: true) ||
        !context.mounted) {
      return;
    }
    final nav = Navigator.of(context);
    await _run(context, 'Pet post deleted', () async {
      await ref.delete();
      unawaited(logAdminAction(action: 'delete', collection: 'pets', docId: ref.id, summary: 'Deleted ${s('name')}'));
      nav.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = s('status').isEmpty ? 'available' : s('status');
    final hidden = p['hidden'] == true;
    final owner = s('uploadedBy');
    String yn(String k) => p[k] == true ? 'Yes' : 'No';

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AppImage(p['imageUrl'] as String?, height: 280, width: double.infinity, decodeWidth: 560),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Text(s('name'), style: Theme.of(context).textTheme.headlineSmall)),
        StatusPill(status),
        if (hidden) ...[const SizedBox(width: 6), const StatusPill('hidden')],
      ]),
      if (s('description').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(s('description'))),
      const SizedBox(height: 14),

      PanelSection('Manage',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'available', label: Text('Available'), icon: Icon(Icons.pets)),
                ButtonSegment(value: 'pending', label: Text('Pending'), icon: Icon(Icons.hourglass_top)),
                ButtonSegment(value: 'adopted', label: Text('Adopted'), icon: Icon(Icons.favorite)),
              ],
              selected: {status},
              onSelectionChanged: (v) => _setStatus(context, v.first),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                icon: Icon(hidden ? Icons.visibility : Icons.visibility_off, size: 18),
                label: Text(hidden ? 'Show in app' : 'Hide from app'),
                onPressed: () => _run(context, hidden ? 'Pet visible again' : 'Pet hidden from the app',
                    () => setPetHidden(ref, !hidden)),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit details'),
                onPressed: () => _edit(context),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Delete'),
                onPressed: () => _delete(context),
              ),
            ]),
          ])),

      PanelSection('Details',
          child: Column(children: [
            InfoRow('Type', s('type')),
            InfoRow('Age', s('age')),
            InfoRow('Gender', s('gender')),
            InfoRow('Location', s('location')),
            InfoRow('Health', 'Vaccinated ${yn('vaccinated')} · Sterilized ${yn('sterilized')} · Dewormed ${yn('dewormed')}'),
            InfoRow('Contact', s('contact')),
            InfoRow('Posted', formatWhen(p['createdAt'])),
            InfoRow('Pet ID', ref.id),
          ])),

      PanelSection('Posted by',
          trailing: owner.isEmpty
              ? null
              : TextButton(onPressed: () => showUserPanel(context, owner, isSuper: isSuper), child: const Text('Open profile')),
          child: owner.isEmpty
              ? const Text('Added by an admin.', style: TextStyle(color: Colors.grey))
              : _docStream(_db.collection('users').doc(owner), (u) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    InfoRow('Name', u?['name'] as String? ?? ''),
                    InfoRow('Email', u?['email'] as String? ?? s('uploaderEmail')),
                    InfoRow('Phone', u?['phone'] as String? ?? ''),
                    const SizedBox(height: 6),
                    _contactButtons(
                        email: u?['email'] as String? ?? s('uploaderEmail'),
                        phone: (u?['phone'] as String?) ?? s('contact'),
                        subject: 'Your MauZanimo post for ${s('name')}'),
                  ]))),

      PanelSection('Adoption applications',
          child: _Linked(
            query: _db.collection('adoptions').where('petId', isEqualTo: ref.id),
            empty: 'No applications yet.',
            tile: (d) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(d.data()['adopterName'] as String? ?? d.id),
              subtitle: Text('Applied ${formatWhen(d.data()['createdAt'])}'),
              trailing: StatusPill(d.data()['currentStage'] as String? ?? 'application'),
              onTap: () => showAdoptionPanel(context, d.id, isSuper: isSuper),
            ),
          )),

      PanelSection('Inquiries',
          child: _Linked(
            query: _db.collection('inquiries').where('petId', isEqualTo: ref.id),
            empty: 'No inquiries.',
            tile: (d) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(d.data()['applicantName'] as String? ?? d.id),
              subtitle: Text(d.data()['message'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: StatusPill(d.data()['status'] as String? ?? 'pending'),
            ),
          )),

      AdminNotes(collection: 'pets', docId: ref.id),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Users
// ---------------------------------------------------------------------------

void showUserPanel(BuildContext context, String uid, {bool isSuper = false}) {
  final ref = _db.collection('users').doc(uid);
  showDetailPanel(context,
      title: 'User profile',
      width: 560,
      child: _docStream(ref, (u) => u == null
          ? SelectableText('This user has no profile document.\nUID: $uid')
          : _UserDetail(ref: ref, u: u, isSuper: isSuper)));
}

class _UserDetail extends StatelessWidget {
  final DocumentReference<Json> ref;
  final Json u;
  final bool isSuper;
  const _UserDetail({required this.ref, required this.u, required this.isSuper});

  String s(String k) => (u[k] ?? '').toString();

  bool _roleLocked(String role) => !isSuper && adminRoles.contains(role);

  Future<void> _setRole(BuildContext context, String role) async {
    final before = s('role').isEmpty ? 'adopter' : s('role');
    if (role == before) return;
    final self = ref.id == FirebaseAuth.instance.currentUser?.uid;
    if (self && adminRoles.contains(before) && !adminRoles.contains(role)) {
      if (!await _confirm(context, 'Remove your own admin access?',
              'You will be signed out of the admin panel immediately.', ok: 'Remove', danger: true) ||
          !context.mounted) {
        return;
      }
    } else if (adminRoles.contains(role)) {
      if (!await _confirm(context, 'Grant $role?',
              '${s('email')} will be able to manage all MauZanimo data.', ok: 'Grant') ||
          !context.mounted) {
        return;
      }
    }
    await _run(context, 'Role → $role', () async {
      await ref.update({'role': role, 'updatedAt': FieldValue.serverTimestamp()});
      unawaited(logAdminAction(action: 'role_change', collection: 'users', docId: ref.id, summary: 'role: $before → $role'));
    });
  }

  Future<void> _setVerification(BuildContext context, String level) async {
    final before = s('verificationLevel').isEmpty ? 'none' : s('verificationLevel');
    if (level == before) return;
    await _run(context, 'Verification → ${_verificationName(level)}', () async {
      await ref.update({'verificationLevel': level, 'updatedAt': FieldValue.serverTimestamp()});
      unawaited(logAdminAction(
          action: 'update', collection: 'users', docId: ref.id, summary: 'verificationLevel: $before → $level'));
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = allRoles.contains(s('role')) ? s('role') : 'adopter';
    final level = VerificationLevel.values.any((v) => v.name == s('verificationLevel')) ? s('verificationLevel') : 'none';
    final name = s('name').isEmpty ? s('email') : s('name');

    Widget count(String label, Query<Json> q) => StreamBuilder<QuerySnapshot<Json>>(
          stream: q.limit(200).snapshots(),
          builder: (context, snap) => Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(children: [
                Text(snap.hasData ? '${snap.data!.docs.length}' : '–',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            Text(s('email'), style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Wrap(spacing: 6, children: [StatusPill(role), if (level != 'none') StatusPill(_verificationName(level))]),
          ]),
        ),
      ]),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        count('Pets posted', _db.collection('pets').where('uploadedBy', isEqualTo: ref.id)),
        count('Adoptions', _db.collection('adoptions').where('adopterId', isEqualTo: ref.id)),
        count('Inquiries', _db.collection('inquiries').where('userId', isEqualTo: ref.id)),
        count('Lost & found', _db.collection('lostfound').where('userId', isEqualTo: ref.id)),
      ]),
      const SizedBox(height: 14),

      PanelSection('Access',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const SizedBox(width: 110, child: Text('Role', style: TextStyle(color: Colors.grey))),
              DropdownButton<String>(
                value: role,
                items: [
                  for (final r in allRoles)
                    DropdownMenuItem(
                      value: r,
                      enabled: !_roleLocked(r) && !(_roleLocked(role)),
                      child: Text(r, style: TextStyle(color: _roleLocked(r) ? Colors.grey : null)),
                    ),
                ],
                onChanged: _roleLocked(role) ? null : (v) => v == null ? null : _setRole(context, v),
              ),
            ]),
            if (!isSuper)
              const Text('Only a superAdmin can grant or remove admin rights.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            Row(children: [
              const SizedBox(width: 110, child: Text('Verification', style: TextStyle(color: Colors.grey))),
              DropdownButton<String>(
                value: level,
                items: [
                  for (final v in VerificationLevel.values)
                    DropdownMenuItem(value: v.name, child: Text(_verificationName(v.name))),
                ],
                onChanged: (v) => v == null ? null : _setVerification(context, v),
              ),
            ]),
          ])),

      PanelSection('Contact',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InfoRow('Email', s('email')),
            InfoRow('Phone', s('phone')),
            InfoRow('Joined', formatWhen(u['createdAt'])),
            InfoRow('UID', ref.id),
            const SizedBox(height: 6),
            _contactButtons(email: s('email'), phone: s('phone')),
          ])),

      PanelSection('Pets posted',
          child: _Linked(
            query: _db.collection('pets').where('uploadedBy', isEqualTo: ref.id),
            empty: 'No pets posted.',
            tile: (d) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AppImage(d.data()['imageUrl'] as String?, width: 40, height: 40, decodeWidth: 40),
              ),
              title: Text(d.data()['name'] as String? ?? d.id),
              subtitle: Text(formatWhen(d.data()['createdAt'])),
              trailing: Wrap(spacing: 4, children: [
                StatusPill(d.data()['status'] as String? ?? 'available'),
                if (d.data()['hidden'] == true) const StatusPill('hidden'),
              ]),
              onTap: () => showPetPanel(context, d.id, isSuper: isSuper),
            ),
          )),

      PanelSection('Adoption applications',
          child: _Linked(
            query: _db.collection('adoptions').where('adopterId', isEqualTo: ref.id),
            empty: 'No adoption applications.',
            tile: (d) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: PetThumb(d.data()['petId'] as String?, size: 40),
              title: Text(d.data()['petName'] as String? ?? 'Pet'),
              subtitle: Text('Applied ${formatWhen(d.data()['createdAt'])}'),
              trailing: StatusPill(d.data()['currentStage'] as String? ?? 'application'),
              onTap: () => showAdoptionPanel(context, d.id, isSuper: isSuper),
            ),
          )),

      AdminNotes(collection: 'users', docId: ref.id),
    ]);
  }
}
