// "Audit log" section of the web admin: the latest admin_audit entries.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'audit.dart';

/// Distinct actions in [entries], sorted, for the filter chips.
List<String> auditActions(Iterable<Map<String, dynamic>> entries) =>
    {for (final e in entries) if (e['action'] case final String a) a}.toList()..sort();

/// Entries whose action is [action] (all of them when it is null).
List<T> filterByAction<T>(List<T> entries, String? action, String? Function(T) actionOf) =>
    action == null ? entries : [for (final e in entries) if (actionOf(e) == action) e];

class AuditLogPage extends StatefulWidget {
  /// How many of the most recent entries to load.
  static const limit = 200;
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  // Single-field orderBy: served by Firestore's automatic index. The action
  // filter runs client-side so no composite index is needed.
  final _stream = FirebaseFirestore.instance
      .collection(auditCollection)
      .orderBy('at', descending: true)
      .limit(AuditLogPage.limit)
      .snapshots();
  String? _action;
  static final _time = DateFormat('yyyy-MM-dd HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Could not load the audit log: ${snap.error}'));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final all = snap.data!.docs;
        final actions = auditActions(all.map((d) => d.data()));
        final action = actions.contains(_action) ? _action : null;
        final rows = filterByAction(all, action, (d) => d.data()['action'] as String?);
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Audit log', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Latest ${AuditLogPage.limit} admin writes. Entries are append-only: '
              'nobody can edit or delete them from the app.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ChoiceChip(
                label: Text('All (${all.length})'),
                selected: action == null,
                onSelected: (_) => setState(() => _action = null),
              ),
              for (final a in actions)
                ChoiceChip(
                  label: Text(a),
                  selected: action == a,
                  onSelected: (_) => setState(() => _action = a),
                ),
            ]),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('No entries yet.'))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('When')),
                    DataColumn(label: Text('Action')),
                    DataColumn(label: Text('Collection')),
                    DataColumn(label: Text('Document')),
                    DataColumn(label: Text('Summary')),
                    DataColumn(label: Text('Admin (uid)')),
                  ],
                  rows: [
                    for (final d in rows)
                      DataRow(cells: [
                        DataCell(Text(switch (d.data()['at']) {
                          final Timestamp t => _time.format(t.toDate()),
                          _ => 'pending',
                        })),
                        DataCell(Text('${d.data()['action'] ?? ''}')),
                        DataCell(Text('${d.data()['collection'] ?? ''}')),
                        DataCell(SelectableText('${d.data()['docId'] ?? ''}')),
                        DataCell(ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Text('${d.data()['summary'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        )),
                        DataCell(SelectableText('${d.data()['actorUid'] ?? ''}')),
                      ]),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
