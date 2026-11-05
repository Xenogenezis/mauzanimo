// Pure helpers behind the admin Overview page. Kept free of Firebase calls so
// they can be unit tested; Firestore values (Timestamp) are only inspected.
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/widgets.dart' show AsyncSnapshot, ConnectionState;

/// Best-effort conversion of a stored date (Timestamp, DateTime, epoch millis
/// or ISO string) to a [DateTime]. Returns null for anything else.
DateTime? asDateTime(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// One bar of the "last 30 days" chart: [start] inclusive, [end] exclusive.
class WeekBucket {
  final DateTime start;
  final DateTime end;
  final int count;
  const WeekBucket(this.start, this.end, this.count);

  @override
  String toString() => 'WeekBucket($start, $end, $count)';
}

/// Splits the [days] before [now] into 7-day buckets anchored on [now] (the
/// newest bucket ends at [now]; the oldest one is shorter when [days] is not a
/// multiple of 7, e.g. 30 days -> 2 + 7 + 7 + 7 + 7) and counts [dates] per
/// bucket. Buckets are returned oldest first.
///
/// Dates before the window are ignored. Dates slightly after [now] (server
/// timestamps vs. a lagging client clock) are counted in the newest bucket.
List<WeekBucket> bucketByWeek(Iterable<DateTime?> dates, {required DateTime now, int days = 30}) {
  assert(days > 0);
  final windowStart = now.subtract(Duration(days: days));
  final starts = <DateTime>[];
  final ends = <DateTime>[];
  var end = now;
  while (end.isAfter(windowStart)) {
    final start = end.subtract(const Duration(days: 7));
    final clipped = start.isBefore(windowStart) ? windowStart : start;
    starts.insert(0, clipped);
    ends.insert(0, end);
    end = clipped;
  }
  final counts = List<int>.filled(starts.length, 0);
  for (final d in dates) {
    if (d == null || d.isBefore(windowStart)) continue;
    if (!d.isBefore(now)) {
      counts[counts.length - 1]++;
      continue;
    }
    for (var i = starts.length - 1; i >= 0; i--) {
      if (!d.isBefore(starts[i])) {
        counts[i]++;
        break;
      }
    }
  }
  return [for (var i = 0; i < starts.length; i++) WeekBucket(starts[i], ends[i], counts[i])];
}

/// When the adoption entered its current stage: the latest `stageHistory`
/// entry for `currentStage`, else `createdAt`.
DateTime? stageEnteredAt(Map<String, dynamic> adoption) {
  final stage = adoption['currentStage'] as String? ?? 'application';
  DateTime? latest;
  final history = adoption['stageHistory'];
  if (history is List) {
    for (final h in history) {
      if (h is! Map || h['stage'] != stage) continue;
      final t = asDateTime(h['timestamp']);
      if (t != null && (latest == null || t.isAfter(latest))) latest = t;
    }
  }
  return latest ?? asDateTime(adoption['createdAt']);
}

/// A record that has been waiting for an admin for [waited].
class Waiting<T> {
  final T item;
  final DateTime since;
  final Duration waited;
  const Waiting(this.item, this.since, this.waited);
}

/// Items whose [since] date is more than [threshold] before [now], longest
/// waiting first. Items without a date are skipped.
List<Waiting<T>> waitingLongerThan<T>(
  Iterable<T> items, {
  required DateTime? Function(T) since,
  required DateTime now,
  required Duration threshold,
}) {
  final out = <Waiting<T>>[];
  for (final item in items) {
    final s = since(item);
    if (s == null) continue;
    final waited = now.difference(s);
    if (waited > threshold) out.add(Waiting(item, s, waited));
  }
  out.sort((a, b) => b.waited.compareTo(a.waited));
  return out;
}

const _urgencyRank = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};

/// Rescue reports ordered most urgent first, then oldest first.
int compareRescue(Map<String, dynamic> a, Map<String, dynamic> b) {
  final ua = _urgencyRank[a['urgency']] ?? 2;
  final ub = _urgencyRank[b['urgency']] ?? 2;
  if (ua != ub) return ua.compareTo(ub);
  final ta = asDateTime(a['createdAt']);
  final tb = asDateTime(b['createdAt']);
  if (ta == null || tb == null) return (ta == null ? 1 : 0) - (tb == null ? 1 : 0);
  return ta.compareTo(tb);
}

/// "3 d", "5 h", "12 min".
String formatAge(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} d';
  if (d.inHours >= 1) return '${d.inHours} h';
  return '${d.inMinutes.clamp(0, 59)} min';
}

/// Combines several counts into one: an error if any failed, waiting while
/// any is still loading, otherwise their sum.
AsyncSnapshot<int> sumCounts(List<AsyncSnapshot<int>> parts) {
  for (final p in parts) {
    if (p.hasError) return AsyncSnapshot.withError(ConnectionState.done, p.error!, p.stackTrace ?? StackTrace.empty);
  }
  if (parts.any((p) => !p.hasData)) return const AsyncSnapshot.waiting();
  return AsyncSnapshot.withData(ConnectionState.done, parts.fold(0, (s, p) => s + p.data!));
}

/// How many KPI tiles fit side by side: 1 on narrow screens up to 4 on wide.
int tileColumnsFor(double width) {
  if (width >= 1100) return 4;
  if (width >= 800) return 3;
  if (width >= 520) return 2;
  return 1;
}

/// Short, readable form of a load error for tooltips.
String describeError(Object? e) {
  final s = e.toString();
  if (s.contains('permission-denied')) return 'Permission denied by Firestore rules';
  return s.length > 200 ? '${s.substring(0, 200)}…' : s;
}
