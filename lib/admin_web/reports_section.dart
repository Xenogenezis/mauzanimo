import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Human labels for report reasons (admin is English-only).
const Map<String, String> kReportReasonLabels = {
  'spam': 'Spam / advertising',
  'scam': 'Scam / asking for money',
  'animal_welfare': 'Animal welfare',
  'inappropriate': 'Inappropriate',
  'wrong_info': 'Wrong info',
  'other': 'Other',
};

/// Sorts report docs newest first by `createdAt`. A pending server
/// timestamp (null) counts as newest. Done client-side so the
/// `status == open` query needs no composite index.
List<T> sortReportsNewestFirst<T>(
  Iterable<T> reports,
  Map<String, dynamic> Function(T) dataOf,
) {
  int millis(T r) {
    final ts = dataOf(r)['createdAt'];
    if (ts is Timestamp) return ts.millisecondsSinceEpoch;
    if (ts is DateTime) return ts.millisecondsSinceEpoch;
    return 1 << 52; // not yet stamped by the server: just filed
  }

  return reports.toList()..sort((a, b) => millis(b).compareTo(millis(a)));
}

/// The most useful fields of a reported document, as label/value pairs.
List<(String, String)> reportTargetSummary(Map<String, dynamic> data) {
  const fields = [
    ('Name', 'name'),
    ('Pet', 'petName'),
    ('Type', 'type'),
    ('Animal', 'animalType'),
    ('Rating', 'rating'),
    ('Description', 'description'),
    ('Story', 'story'),
    ('Comment', 'comment'),
    ('Location', 'location'),
    ('Place', 'locationLabel'),
    ('Contact', 'contact'),
    ('Status', 'status'),
    ('Owner uid', 'uploadedBy'),
    ('Owner uid', 'userId'),
    ('Owner uid', 'reporterId'),
    ('Owner uid', 'reviewerId'),
    ('Hidden', 'hidden'),
  ];
  final out = <(String, String)>[];
  for (final (label, key) in fields) {
    final v = data[key];
    if (v == null || v.toString().trim().isEmpty) continue;
    var text = v.toString();
    if (text.length > 400) text = '${text.substring(0, 400)}…';
    out.add((label, text));
  }
  return out;
}

/// Admin "Reports" section: open abuse reports, newest first, with
/// view / hide / dismiss / delete actions.
class AdminReportsSection extends StatefulWidget {
  const AdminReportsSection({super.key});

  @override
  State<AdminReportsSection> createState() => _AdminReportsSectionState();
}

class _AdminReportsSectionState extends State<AdminReportsSection> {
  final _db = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream = _db
      .collection('reports')
      .where('status', isEqualTo: 'open')
      .snapshots();

  /// Open reports currently shown, used to close duplicates together.
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _open = [];

  DocumentReference<Map<String, dynamic>> _targetOf(Map<String, dynamic> r) =>
      _db.collection(r['targetCollection'] as String).doc(r['targetId'] as String);

  /// Every open report about the same target as [report] (including it).
  Iterable<DocumentReference> _sameTarget(QueryDocumentSnapshot<Map<String, dynamic>> report) {
    final r = report.data();
    final refs = _open
        .where((d) =>
            d.data()['targetCollection'] == r['targetCollection'] &&
            d.data()['targetId'] == r['targetId'])
        .map((d) => d.reference)
        .toSet();
    refs.add(report.reference);
    return refs;
  }

  Map<String, dynamic> _resolution(String status, String action) => {
        'status': status,
        'action': action,
        'resolvedBy': FirebaseAuth.instance.currentUser?.uid,
        'resolvedAt': FieldValue.serverTimestamp(),
      };

  Future<void> _run(String done, Future<void> Function() job) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await job();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _hide(QueryDocumentSnapshot<Map<String, dynamic>> report) =>
      _run('Content hidden', () {
        final batch = _db.batch()
          ..update(_targetOf(report.data()), {
            'hidden': true,
            'hiddenAt': FieldValue.serverTimestamp(),
            'hiddenBy': FirebaseAuth.instance.currentUser?.uid,
          });
        for (final ref in _sameTarget(report)) {
          batch.update(ref, _resolution('actioned', 'hidden'));
        }
        return batch.commit();
      });

  Future<void> _dismiss(QueryDocumentSnapshot<Map<String, dynamic>> report) =>
      _run('Report dismissed',
          () => report.reference.update(_resolution('dismissed', 'none')));

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> report) async {
    final r = report.data();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete content?'),
        content: Text(
            'This permanently deletes ${r['targetCollection']}/${r['targetId']}. '
            'This cannot be undone. Consider "Hide content" instead.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run('Content deleted', () {
      final batch = _db.batch()..delete(_targetOf(r));
      for (final ref in _sameTarget(report)) {
        batch.update(ref, _resolution('actioned', 'deleted'));
      }
      return batch.commit();
    });
  }

  Future<void> _view(Map<String, dynamic> r) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${r['targetCollection']}/${r['targetId']}'),
        content: SizedBox(
          width: 480,
          child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: _targetOf(r).get(),
            builder: (ctx, snap) {
              if (snap.hasError) return Text('Could not load: ${snap.error}');
              if (!snap.hasData) {
                return const SizedBox(
                    height: 80, child: Center(child: CircularProgressIndicator()));
              }
              final data = snap.data!.data();
              if (data == null) return const Text('This content no longer exists.');
              final rows = reportTargetSummary(data);
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rows.isEmpty) const Text('No summary fields.'),
                    for (final (label, value) in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SelectableText.rich(TextSpan(children: [
                          TextSpan(
                              text: '$label: ',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: value),
                        ])),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        _open = sortReportsNewestFirst(snap.data!.docs, (d) => d.data());

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Reports', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('${_open.length} open report${_open.length == 1 ? '' : 's'}, newest first',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 16),
            if (_open.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No open reports. All clear.')),
              ),
            for (final report in _open) _card(report),
          ],
        );
      },
    );
  }

  Widget _card(QueryDocumentSnapshot<Map<String, dynamic>> report) {
    final r = report.data();
    final ts = r['createdAt'];
    final when = ts is Timestamp
        ? DateFormat('d MMM yyyy, HH:mm').format(ts.toDate())
        : 'just now';
    final reason = r['reason'] as String? ?? 'other';
    final details = (r['details'] as String? ?? '').trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  avatar: const Icon(Icons.flag_outlined, size: 16),
                  label: Text(kReportReasonLabels[reason] ?? reason),
                  backgroundColor: Colors.red.withValues(alpha: 0.08),
                ),
                SelectableText('${r['targetCollection']}/${r['targetId']}',
                    style: const TextStyle(fontFamily: 'monospace')),
                Text('· $when · by ${r['reporterId']}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(details),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _view(r),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
                FilledButton.icon(
                  onPressed: () => _hide(report),
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const Text('Hide content'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _dismiss(report),
                  icon: const Icon(Icons.close),
                  label: const Text('Dismiss'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _delete(report),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete content'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
