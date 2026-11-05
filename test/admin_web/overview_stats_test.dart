import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/admin_web/overview_stats.dart';

void main() {
  final now = DateTime(2026, 11, 5, 12);
  DateTime daysAgo(num d) => now.subtract(Duration(minutes: (d * 24 * 60).round()));

  group('asDateTime', () {
    test('converts supported types', () {
      final d = DateTime(2026, 1, 2, 3, 4);
      expect(asDateTime(Timestamp.fromDate(d)), d);
      expect(asDateTime(d), d);
      expect(asDateTime(d.millisecondsSinceEpoch), d);
      expect(asDateTime('2026-01-02T03:04:00'), d);
    });

    test('returns null for anything else', () {
      expect(asDateTime(null), isNull);
      expect(asDateTime('not a date'), isNull);
      expect(asDateTime(1.5), isNull);
    });
  });

  group('bucketByWeek', () {
    test('30 days gives 5 buckets, newest ending now, oldest 2 days long', () {
      final b = bucketByWeek(const [], now: now);
      expect(b, hasLength(5));
      expect(b.last.end, now);
      expect(b.last.start, now.subtract(const Duration(days: 7)));
      expect(b.first.start, now.subtract(const Duration(days: 30)));
      expect(b.first.end, now.subtract(const Duration(days: 28)));
      for (var i = 1; i < b.length; i++) {
        expect(b[i].start, b[i - 1].end, reason: 'buckets are contiguous');
      }
      expect(b.every((x) => x.count == 0), isTrue);
    });

    test('28 days gives 4 full weeks', () {
      final b = bucketByWeek(const [], now: now, days: 28);
      expect(b, hasLength(4));
      expect(b.first.start, now.subtract(const Duration(days: 28)));
    });

    test('counts dates into the right bucket (start inclusive, end exclusive)', () {
      final b = bucketByWeek([
        daysAgo(0.5), // newest
        daysAgo(6.9), // newest
        daysAgo(7), // exactly on a bucket start -> still newest (start inclusive)
        daysAgo(13), // second newest
        daysAgo(20),
        daysAgo(27),
        daysAgo(29), // oldest (2-day) bucket
        daysAgo(30), // window start is inclusive
      ], now: now);
      expect(b.map((x) => x.count).toList(), [2, 1, 1, 1, 3]);
    });

    test('ignores old and null dates, counts future dates as newest', () {
      final b = bucketByWeek([
        daysAgo(31),
        daysAgo(365),
        null,
        now,
        now.add(const Duration(minutes: 2)),
      ], now: now);
      expect(b.map((x) => x.count).toList(), [0, 0, 0, 0, 2]);
    });

    test('total equals number of dates in the window', () {
      final dates = [for (var h = 0; h < 30 * 24; h += 5) now.subtract(Duration(hours: h))];
      final b = bucketByWeek(dates, now: now);
      expect(b.fold<int>(0, (s, x) => s + x.count), dates.length);
    });
  });

  group('stageEnteredAt', () {
    test('uses latest history entry for the current stage', () {
      final d = {
        'currentStage': 'screening',
        'createdAt': Timestamp.fromDate(daysAgo(10)),
        'stageHistory': [
          {'stage': 'application', 'timestamp': Timestamp.fromDate(daysAgo(10))},
          {'stage': 'screening', 'timestamp': Timestamp.fromDate(daysAgo(6))},
          {'stage': 'application', 'timestamp': Timestamp.fromDate(daysAgo(4))},
          {'stage': 'screening', 'timestamp': Timestamp.fromDate(daysAgo(2))},
        ],
      };
      expect(stageEnteredAt(d), daysAgo(2));
    });

    test('falls back to createdAt and tolerates bad history', () {
      final d = {
        'createdAt': Timestamp.fromDate(daysAgo(5)),
        'stageHistory': [
          'junk',
          {'stage': 'application'}, // pending serverTimestamp: no timestamp
        ],
      };
      expect(stageEnteredAt(d), daysAgo(5));
      expect(stageEnteredAt(const {}), isNull);
    });
  });

  group('waitingLongerThan', () {
    test('keeps items past the threshold, longest first, skips missing dates', () {
      final items = {'a': daysAgo(1), 'b': daysAgo(4), 'c': daysAgo(10), 'd': null, 'e': daysAgo(3)};
      final out = waitingLongerThan(
        items.keys,
        since: (k) => items[k],
        now: now,
        threshold: const Duration(days: 3),
      );
      expect(out.map((w) => w.item), ['c', 'b']);
      expect(out.first.waited, const Duration(days: 10));
      expect(out.first.since, daysAgo(10));
    });
  });

  test('compareRescue sorts by urgency then age', () {
    Map<String, dynamic> r(String? u, num age) => {'urgency': u, 'createdAt': Timestamp.fromDate(daysAgo(age))};
    final list = [r('low', 9), r('high', 1), r(null, 5), r('critical', 1), r('high', 3), r('medium', 6)]
      ..sort(compareRescue);
    expect(list.map((d) => d['urgency']), ['critical', 'high', 'high', 'medium', null, 'low']);
    expect(asDateTime(list[1]['createdAt']), daysAgo(3), reason: 'older high-urgency first');
  });

  test('formatAge', () {
    expect(formatAge(const Duration(days: 4, hours: 3)), '4 d');
    expect(formatAge(const Duration(hours: 5)), '5 h');
    expect(formatAge(const Duration(minutes: 12)), '12 min');
    expect(formatAge(const Duration(seconds: -30)), '0 min');
  });

  group('sumCounts', () {
    const ok1 = AsyncSnapshot<int>.withData(ConnectionState.done, 3);
    const ok2 = AsyncSnapshot<int>.withData(ConnectionState.done, 4);
    const waiting = AsyncSnapshot<int>.waiting();
    const failed = AsyncSnapshot<int>.withError(ConnectionState.done, 'permission-denied');

    test('sums when all loaded', () => expect(sumCounts([ok1, ok2]).data, 7));
    test('waits while any is loading', () {
      final s = sumCounts([ok1, waiting]);
      expect(s.hasData, isFalse);
      expect(s.hasError, isFalse);
    });
    test('error wins', () => expect(sumCounts([ok1, waiting, failed]).error, 'permission-denied'));
    test('empty list is zero', () => expect(sumCounts(const []).data, 0));
  });

  test('tileColumnsFor goes from 1 to 4 columns', () {
    expect(tileColumnsFor(360), 1);
    expect(tileColumnsFor(600), 2);
    expect(tileColumnsFor(900), 3);
    expect(tileColumnsFor(1400), 4);
  });

  test('describeError shortens errors', () {
    expect(describeError('[cloud_firestore/permission-denied] Missing or insufficient permissions.'),
        'Permission denied by Firestore rules');
    expect(describeError('x' * 500).length, lessThanOrEqualTo(201));
  });
}
