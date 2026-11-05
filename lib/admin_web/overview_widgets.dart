// Presentational widgets for the admin Overview page. They take already
// loaded values (AsyncSnapshot) and never touch Firebase, so they are
// widget-testable on their own.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'overview_stats.dart';

/// Grey placeholder block shown while a value loads.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const SkeletonBox({super.key, this.width = 48, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// A count, a skeleton while loading, or "—" with the error as tooltip.
class CountText extends StatelessWidget {
  final AsyncSnapshot<int> value;
  final TextStyle? style;
  final double skeletonWidth;
  final double skeletonHeight;
  const CountText(this.value, {super.key, this.style, this.skeletonWidth = 48, this.skeletonHeight = 14});

  @override
  Widget build(BuildContext context) {
    if (value.hasError) {
      return Tooltip(
        message: describeError(value.error),
        child: Text('—', style: style),
      );
    }
    if (!value.hasData) return SkeletonBox(width: skeletonWidth, height: skeletonHeight);
    return Text(NumberFormat.decimalPattern('en').format(value.data), style: style);
  }
}

/// KPI card: a headline count plus an optional per-status breakdown.
class KpiTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final AsyncSnapshot<int> value;
  final List<(String, AsyncSnapshot<int>)> breakdown;
  final VoidCallback? onTap;

  const KpiTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    this.breakdown = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CountText(
                    value,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    skeletonWidth: 56,
                    skeletonHeight: 28,
                  ),
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ),
              if (onTap != null) const Icon(Icons.chevron_right, color: Colors.grey),
            ]),
            if (breakdown.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final (name, v) in breakdown)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('$name ', style: const TextStyle(fontSize: 12)),
                      CountText(v,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          skeletonWidth: 16,
                          skeletonHeight: 12),
                    ]),
                  ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Simple vertical bar chart of [WeekBucket]s, drawn with Containers.
class WeeklyBars extends StatelessWidget {
  final String title;
  final Color color;
  final AsyncSnapshot<List<WeekBucket>> buckets;
  final double barAreaHeight;

  const WeeklyBars({
    super.key,
    required this.title,
    required this.color,
    required this.buckets,
    this.barAreaHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    final data = buckets.data;
    final total = data?.fold<int>(0, (s, b) => s + b.count);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
            CountText(
              buckets.hasError
                  ? AsyncSnapshot.withError(ConnectionState.done, buckets.error!)
                  : total == null
                      ? const AsyncSnapshot.waiting()
                      : AsyncSnapshot.withData(ConnectionState.done, total),
              style: const TextStyle(fontWeight: FontWeight.bold),
              skeletonWidth: 24,
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(height: barAreaHeight + 48, child: _body(context, data)),
        ]),
      ),
    );
  }

  Widget _body(BuildContext context, List<WeekBucket>? data) {
    if (buckets.hasError) {
      return Center(
        child: Tooltip(
          message: describeError(buckets.error),
          child: const Text('—', style: TextStyle(fontSize: 24, color: Colors.grey)),
        ),
      );
    }
    if (data == null) {
      return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (final f in const [0.4, 0.7, 0.5, 0.9, 0.6])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SkeletonBox(height: barAreaHeight * f),
            ),
          ),
      ]);
    }
    final max = data.fold<int>(0, (m, b) => b.count > m ? b.count : m);
    final fmt = DateFormat('d MMM');
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (final b in data)
        Expanded(
          child: Tooltip(
            message: '${fmt.format(b.start)} – ${fmt.format(b.end)}: ${b.count}',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${b.count}', style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 2),
                Container(
                  key: const ValueKey('week-bar'),
                  height: max == 0 ? 2 : 2 + (barAreaHeight - 2) * b.count / max,
                  decoration: BoxDecoration(
                    color: b.count == 0 ? color.withValues(alpha: 0.25) : color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(fmt.format(b.start),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            ),
          ),
        ),
    ]);
  }
}

/// Lays children out in equal-width columns: 1 (narrow) up to 4 (wide).
class ResponsiveTileGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final int maxColumns;
  const ResponsiveTileGrid({super.key, required this.children, this.spacing = 16, this.maxColumns = 4});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = tileColumnsFor(c.maxWidth).clamp(1, maxColumns);
      final w = (c.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(spacing: spacing, runSpacing: spacing, children: [
        for (final child in children) SizedBox(width: w.floorToDouble(), child: child),
      ]);
    });
  }
}

/// One record in a "Needs attention" group.
class AttentionRow {
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  const AttentionRow({required this.title, this.subtitle = '', this.badge, this.badgeColor});
}

/// A titled group of records needing an admin, with a button that opens the
/// matching admin section.
class AttentionGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final AsyncSnapshot<List<AttentionRow>> rows;
  final String actionLabel;
  final VoidCallback? onAction;
  final int maxRows;

  const AttentionGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
    required this.actionLabel,
    this.onAction,
    this.maxRows = 5,
  });

  @override
  Widget build(BuildContext context) {
    final data = rows.data;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
            CountText(
              rows.hasError
                  ? AsyncSnapshot.withError(ConnectionState.done, rows.error!)
                  : data == null
                      ? const AsyncSnapshot.waiting()
                      : AsyncSnapshot.withData(ConnectionState.done, data.length),
              style: TextStyle(fontWeight: FontWeight.bold, color: (data?.isNotEmpty ?? false) ? color : null),
              skeletonWidth: 20,
            ),
          ]),
          const SizedBox(height: 8),
          if (rows.hasError)
            const Text('Could not load.', style: TextStyle(color: Colors.grey))
          else if (data == null)
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: SkeletonBox(width: double.infinity, height: 16),
              )
          else if (data.isEmpty)
            const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Text('All clear', style: TextStyle(color: Colors.grey)),
            ])
          else ...[
            for (final r in data.take(maxRows))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (r.subtitle.isNotEmpty)
                        Text(r.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ]),
                  ),
                  if (r.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (r.badgeColor ?? color).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(r.badge!, style: TextStyle(fontSize: 11, color: r.badgeColor ?? color)),
                    ),
                ]),
              ),
            if (data.length > maxRows)
              Text('+ ${data.length - maxRows} more', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          if (onAction != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(actionLabel),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
