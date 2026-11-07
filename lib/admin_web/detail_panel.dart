import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/app_image.dart';

/// Slides a detail panel in from the right edge of the admin window.
Future<void> showDetailPanel(
  BuildContext context, {
  required String title,
  required Widget child,
  double width = 520,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (c, _, __) => Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 12,
        color: Theme.of(c).colorScheme.surface,
        child: SizedBox(
          width: width.clamp(320, MediaQuery.sizeOf(c).width).toDouble(),
          height: double.infinity,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
              color: Theme.of(c).colorScheme.primary,
              child: Row(children: [
                Expanded(
                  child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(c).textTheme.titleLarge?.copyWith(color: Colors.white)),
                ),
                IconButton(
                  tooltip: 'Close',
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(c),
                ),
              ]),
            ),
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: child)),
          ]),
        ),
      ),
    ),
    transitionBuilder: (c, anim, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

String formatWhen(Object? v) {
  if (v is Timestamp) return DateFormat('EEE d MMM yyyy, HH:mm').format(v.toDate());
  if (v is DateTime) return DateFormat('EEE d MMM yyyy, HH:mm').format(v);
  return v?.toString() ?? '';
}

/// A titled card grouping related content inside a detail panel.
class PanelSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const PanelSection(this.title, {super.key, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(title.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 0.8, color: Theme.of(context).colorScheme.primary)),
              ),
              if (trailing != null) trailing!,
            ]),
            const SizedBox(height: 8),
            child,
          ]),
        ),
      );
}

/// Label / value line. Empty values are skipped.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: SelectableText(value)),
      ]),
    );
  }
}

/// Small coloured pill for statuses and roles.
class StatusPill extends StatelessWidget {
  final String text;
  const StatusPill(this.text, {super.key});

  static Color colorFor(String s) => switch (s) {
        'available' || 'open' || 'pending' || 'application' => Colors.blue,
        'screening' || 'meet_greet' || 'trial' || 'contacted' || 'assigned' || 'active' => Colors.orange,
        'adopted' || 'completed' || 'approved' || 'resolved' => Colors.green,
        'rejected' || 'cancelled' || 'hidden' => Colors.red,
        'admin' || 'superAdmin' => Colors.purple,
        'partner' || 'volunteer' => Colors.teal,
        _ => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    final c = colorFor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// Every field of a document, for collections without a custom panel.
class GenericFields extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const GenericFields({super.key, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final image = data['imageUrl'] as String?;
    final keys = data.keys.where((k) => k != 'imageUrl').toList()..sort();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (image != null && image.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppImage(image, height: 260, width: double.infinity, decodeWidth: 520),
          ),
        ),
      PanelSection('Fields', child: Column(children: [
        InfoRow('ID', id),
        for (final k in keys) InfoRow(k, _describe(data[k])),
      ])),
    ]);
  }

  static String _describe(Object? v) {
    if (v is Timestamp) return formatWhen(v);
    if (v is GeoPoint) return '${v.latitude.toStringAsFixed(5)}, ${v.longitude.toStringAsFixed(5)}';
    if (v is String && v.startsWith('data:')) return '[image]';
    if (v is List) return v.map(_describe).join('\n');
    if (v is Map) return v.entries.map((e) => '${e.key}: ${_describe(e.value)}').join('\n');
    return v?.toString() ?? '';
  }
}
