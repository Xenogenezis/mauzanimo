import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/app_image.dart';
import 'csv_download.dart';

typedef Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

/// One column of a [CollectionTable].
class Col {
  final String label;
  final Object? Function(Map<String, dynamic> d) value;

  /// Render as a small thumbnail (value must be a URL or data URI).
  final bool image;
  final double? width;
  const Col(this.label, this.value, {this.image = false, this.width});

  /// Convenience for a plain field, formatting Timestamps as dates.
  factory Col.field(String label, String field, {double? width}) =>
      Col(label, (d) => d[field], width: width);
}

/// Editable status/enum column rendered as a dropdown.
class StatusCol {
  final String label;
  final String field;
  final List<String> options;
  final String fallback;

  /// Custom writer (e.g. to also append history). Defaults to a field update.
  final Future<void> Function(Doc doc, String value)? onChange;

  /// Options the current admin may not pick (shown disabled).
  final bool Function(String option)? isLocked;

  const StatusCol({
    required this.label,
    required this.field,
    required this.options,
    required this.fallback,
    this.onChange,
    this.isLocked,
  });
}

String formatCell(Object? v) {
  if (v == null) return '';
  if (v is Timestamp) return DateFormat('yyyy-MM-dd HH:mm').format(v.toDate());
  if (v is GeoPoint) return '${v.latitude.toStringAsFixed(5)}, ${v.longitude.toStringAsFixed(5)}';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is String && v.startsWith('data:')) return '[image]';
  return v.toString();
}

/// Searchable, filterable, paginated, CSV-exportable view of a Firestore
/// collection, for the desktop admin panel.
class CollectionTable extends StatefulWidget {
  final String title;
  final String collection;
  final String? orderBy;
  final List<Col> columns;
  final StatusCol? status;
  final bool allowDelete;
  final int limit;
  final List<Widget> Function(Doc doc)? extraActions;
  final Widget? header;

  const CollectionTable({
    super.key,
    required this.title,
    required this.collection,
    required this.columns,
    this.orderBy = 'createdAt',
    this.status,
    this.allowDelete = true,
    this.limit = 1000,
    this.extraActions,
    this.header,
  });

  @override
  State<CollectionTable> createState() => _CollectionTableState();
}

class _CollectionTableState extends State<CollectionTable> {
  String _query = '';
  String? _statusFilter;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection(widget.collection);
    // Note: orderBy hides docs missing the field, so it is optional.
    if (widget.orderBy != null) q = q.orderBy(widget.orderBy!, descending: true);
    _stream = q.limit(widget.limit).snapshots();
  }

  List<Doc> _filter(List<Doc> docs) {
    final q = _query.trim().toLowerCase();
    return docs.where((d) {
      final data = d.data();
      final st = widget.status;
      if (st != null && _statusFilter != null &&
          (data[st.field] as String? ?? st.fallback) != _statusFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return widget.columns.any((c) => !c.image && formatCell(c.value(data)).toLowerCase().contains(q)) ||
          d.id.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _export(List<Doc> docs) async {
    final st = widget.status;
    final header = [
      'id',
      ...widget.columns.where((c) => !c.image).map((c) => c.label),
      if (st != null) st.label,
    ];
    final rows = docs.map((d) {
      final data = d.data();
      return <Object?>[
        d.id,
        ...widget.columns.where((c) => !c.image).map((c) => formatCell(c.value(data))),
        if (st != null) data[st.field] ?? st.fallback,
      ];
    });
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    await downloadTextFile('${widget.collection}-$stamp.csv', toCsv(header, rows));
  }

  Future<void> _delete(Doc doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this record?'),
        content: Text('${widget.title}: ${doc.id}\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _guard(() => doc.reference.delete(), 'Deleted');
  }

  Future<void> _guard(Future<void> Function() op, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await op();
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } on FirebaseException catch (e) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text(e.code == 'permission-denied'
            ? 'Permission denied by Firestore rules.'
            : 'Failed: ${e.message}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText('Could not load ${widget.collection}: ${snap.error}'),
          ));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final all = snap.data!.docs;
        final docs = _filter(all);
        final st = widget.status;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
                  Chip(label: Text('${docs.length} / ${all.length}')),
                  SizedBox(
                    width: 280,
                    child: TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  if (st != null)
                    DropdownButton<String?>(
                      value: _statusFilter,
                      hint: Text('All ${st.label.toLowerCase()}'),
                      items: [
                        DropdownMenuItem(value: null, child: Text('All ${st.label.toLowerCase()}')),
                        for (final o in st.options) DropdownMenuItem(value: o, child: Text(o)),
                      ],
                      onChanged: (v) => setState(() => _statusFilter = v),
                    ),
                  OutlinedButton.icon(
                    onPressed: docs.isEmpty ? null : () => _export(docs),
                    icon: const Icon(Icons.download),
                    label: const Text('Export CSV'),
                  ),
                ],
              ),
            ),
            if (widget.header != null) widget.header!,
            Expanded(
              child: docs.isEmpty
                  ? const Center(child: Text('Nothing here.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: PaginatedDataTable(
                        rowsPerPage: docs.length < 25 ? docs.length.clamp(1, 25) : 25,
                        showFirstLastButtons: true,
                        columns: [
                          for (final c in widget.columns) DataColumn(label: Text(c.label)),
                          if (st != null) DataColumn(label: Text(st.label)),
                          const DataColumn(label: Text('')),
                        ],
                        source: _Source(docs, widget, context, _delete, _guard),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Source extends DataTableSource {
  final List<Doc> docs;
  final CollectionTable w;
  final BuildContext context;
  final Future<void> Function(Doc) onDelete;
  final Future<void> Function(Future<void> Function(), String) guard;
  _Source(this.docs, this.w, this.context, this.onDelete, this.guard);

  @override
  DataRow? getRow(int index) {
    if (index >= docs.length) return null;
    final doc = docs[index];
    final d = doc.data();
    final st = w.status;
    return DataRow(cells: [
      for (final c in w.columns)
        DataCell(c.image
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AppImage(c.value(d) as String?, width: 44, height: 44, decodeWidth: 44),
              )
            : ConstrainedBox(
                constraints: BoxConstraints(maxWidth: c.width ?? 240),
                child: Tooltip(
                  message: formatCell(c.value(d)),
                  waitDuration: const Duration(milliseconds: 600),
                  child: Text(formatCell(c.value(d)), overflow: TextOverflow.ellipsis, maxLines: 2),
                ),
              )),
      if (st != null)
        DataCell(DropdownButton<String>(
          value: st.options.contains(d[st.field]) ? d[st.field] as String : st.fallback,
          underline: const SizedBox(),
          items: [
            for (final o in st.options)
              DropdownMenuItem(
                value: o,
                enabled: !(st.isLocked?.call(o) ?? false),
                child: Text(o, style: TextStyle(
                    color: (st.isLocked?.call(o) ?? false) ? Colors.grey : null)),
              ),
          ],
          onChanged: (v) {
            if (v == null) return;
            guard(
              () => st.onChange != null
                  ? st.onChange!(doc, v)
                  : doc.reference.update({st.field: v, 'updatedAt': FieldValue.serverTimestamp()}),
              '${st.label} → $v',
            );
          },
        )),
      DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
        ...?w.extraActions?.call(doc),
        if (w.allowDelete)
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => onDelete(doc),
          ),
      ])),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => docs.length;
  @override
  int get selectedRowCount => 0;
}
