import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../lang/app_strings.dart';
import '../providers/language_provider.dart';
import '../utils/offline_write.dart';
import 'auth_guard.dart';

/// Collections that can be reported (must match firestore.rules).
const List<String> kReportTargetCollections = [
  'pets',
  'lostfound',
  'sightings',
  'stories',
  'reviews',
];

/// Report reasons, in display order (must match firestore.rules).
/// Each has a `report_reason_<id>` string.
const List<String> kReportReasons = [
  'spam',
  'scam',
  'animal_welfare',
  'inappropriate',
  'wrong_info',
  'other',
];

/// Max length of the optional details (must match firestore.rules).
const int kReportDetailsMaxLength = 1000;

/// Sends a report with the chosen [reason] and optional [details].
typedef ReportSubmitter = Future<WriteOutcome> Function(
    String reason, String? details);

/// The `reports` document the rules accept: exactly these fields, with a
/// server timestamp so `createdAt == request.time`. Empty details are left
/// out (the rules require a string when present).
Map<String, dynamic> buildReportData({
  required String reporterId,
  required String targetCollection,
  required String targetId,
  required String reason,
  String? details,
}) {
  var text = details?.trim() ?? '';
  if (text.length > kReportDetailsMaxLength) {
    text = text.substring(0, kReportDetailsMaxLength);
  }
  return {
    'reporterId': reporterId,
    'targetCollection': targetCollection,
    'targetId': targetId,
    'reason': reason,
    if (text.isNotEmpty) 'details': text,
    'status': 'open',
    'createdAt': FieldValue.serverTimestamp(),
  };
}

/// Targets reported by each user during this app session, so the same user
/// can't file the same report twice in a row.
class ReportedTargets {
  ReportedTargets._();

  static final Set<String> _keys = {};

  static String _key(String uid, String collection, String id) =>
      '$uid|$collection/$id';

  static bool contains(String uid, String collection, String id) =>
      _keys.contains(_key(uid, collection, id));

  static void add(String uid, String collection, String id) =>
      _keys.add(_key(uid, collection, id));

  @visibleForTesting
  static void clear() => _keys.clear();
}

/// Flag icon that lets a signed-in user report a piece of content.
class ReportButton extends StatelessWidget {
  final String targetCollection;
  final String targetId;
  final Color? color;
  final double? iconSize;

  const ReportButton({
    super.key,
    required this.targetCollection,
    required this.targetId,
    this.color,
    this.iconSize,
  }) : assert(targetCollection == 'pets' ||
            targetCollection == 'lostfound' ||
            targetCollection == 'sightings' ||
            targetCollection == 'stories' ||
            targetCollection == 'reviews');

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    return IconButton(
      icon: Icon(Icons.flag_outlined, color: color, size: iconSize),
      tooltip: AppStrings.get('report_action', lang),
      visualDensity: VisualDensity.compact,
      onPressed: () => startReport(
        context,
        targetCollection: targetCollection,
        targetId: targetId,
      ),
    );
  }
}

/// Opens the report flow: asks signed-out users to sign in, blocks repeat
/// reports in this session, shows [ReportSheet] and thanks the user.
Future<void> startReport(
  BuildContext context, {
  required String targetCollection,
  required String targetId,
}) async {
  if (FirebaseAuth.instance.currentUser == null) {
    AuthGuard.requireAuth(context, () {});
    return;
  }
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final lang = context.read<LanguageProvider>().lang;
  final messenger = ScaffoldMessenger.of(context);
  void snack(String key) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(AppStrings.get(key, lang))));

  if (ReportedTargets.contains(uid, targetCollection, targetId)) {
    snack('report_already');
    return;
  }

  final outcome = await showModalBottomSheet<WriteOutcome>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ReportSheet(
      onSubmit: (reason, details) => writeOfflineFirst(
        FirebaseFirestore.instance.collection('reports').doc().set(
              buildReportData(
                reporterId: uid,
                targetCollection: targetCollection,
                targetId: targetId,
                reason: reason,
                details: details,
              ),
            ),
      ),
    ),
  );
  if (outcome == null) return;
  ReportedTargets.add(uid, targetCollection, targetId);
  snack(outcome == WriteOutcome.queued ? 'report_queued' : 'report_thanks');
}

/// Bottom sheet with the reason list, optional details and a submit button
/// (disabled until a reason is chosen). Pops with the [WriteOutcome] once
/// [onSubmit] succeeds.
class ReportSheet extends StatefulWidget {
  final ReportSubmitter onSubmit;

  const ReportSheet({super.key, required this.onSubmit});

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _details = TextEditingController();
  String? _reason;
  bool _sending = false;
  bool _failed = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      final details = _details.text.trim();
      final outcome =
          await widget.onSubmit(reason, details.isEmpty ? null : details);
      if (mounted) Navigator.of(context).pop(outcome);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String k) => AppStrings.get(k, lang);
    final theme = Theme.of(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('report_title'), style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                t('report_subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (v) {
                  if (!_sending) setState(() => _reason = v);
                },
                child: Column(
                  children: [
                    for (final r in kReportReasons)
                      RadioListTile<String>(
                        key: ValueKey('report-reason-$r'),
                        value: r,
                        title: Text(t('report_reason_$r')),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('report-details'),
                controller: _details,
                enabled: !_sending,
                maxLines: 3,
                maxLength: kReportDetailsMaxLength,
                decoration: InputDecoration(
                  hintText: t('report_details_hint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_failed) ...[
                const SizedBox(height: 4),
                Text(t('report_failed'),
                    style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('report-submit'),
                onPressed: _reason == null || _sending ? null : _submit,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag_outlined),
                label: Text(t('report_submit')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
