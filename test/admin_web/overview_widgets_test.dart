import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/admin_web/overview_stats.dart';
import 'package:stray_pets_mu/admin_web/overview_widgets.dart';

Widget _host(Widget child, {double width = 400}) => MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    );

AsyncSnapshot<T> _data<T>(T v) => AsyncSnapshot.withData(ConnectionState.done, v);

void main() {
  group('KpiTile', () {
    testWidgets('shows count, breakdown and handles taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(KpiTile(
        label: 'Pets',
        icon: Icons.pets,
        color: Colors.teal,
        value: _data(1234),
        breakdown: [('Available', _data(10)), ('Adopted', _data(3))],
        onTap: () => taps++,
      )));
      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('Pets'), findsOneWidget);
      expect(find.text('Available '), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.text('Pets'));
      expect(taps, 1);
    });

    testWidgets('shows skeletons while loading', (tester) async {
      await tester.pumpWidget(_host(const KpiTile(
        label: 'Users',
        icon: Icons.people,
        color: Colors.grey,
        value: AsyncSnapshot.waiting(),
        breakdown: [('Lost', AsyncSnapshot.waiting())],
      )));
      expect(find.byType(SkeletonBox), findsNWidgets(2));
      expect(find.text('—'), findsNothing);
    });

    testWidgets('one failed part shows a dash with the error as tooltip', (tester) async {
      await tester.pumpWidget(_host(KpiTile(
        label: 'Lost & found',
        icon: Icons.search,
        color: Colors.orange,
        value: _data(5),
        breakdown: const [
          ('Lost', AsyncSnapshot.withError(ConnectionState.done, 'permission-denied')),
          ('Found', AsyncSnapshot.withData(ConnectionState.done, 2)),
        ],
      )));
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      final tip = tester.widget<Tooltip>(find.ancestor(of: find.text('—'), matching: find.byType(Tooltip)));
      expect(tip.message, 'Permission denied by Firestore rules');
    });
  });

  group('WeeklyBars', () {
    final now = DateTime(2026, 11, 5);

    testWidgets('draws one bar per bucket, tallest for the max', (tester) async {
      final buckets = bucketByWeek([
        now.subtract(const Duration(days: 1)),
        now.subtract(const Duration(days: 2)),
        now.subtract(const Duration(days: 3)),
        now.subtract(const Duration(days: 10)),
      ], now: now);
      await tester.pumpWidget(_host(WeeklyBars(title: 'New pets', color: Colors.teal, buckets: _data(buckets))));
      final bars = find.byKey(const ValueKey('week-bar'));
      expect(bars, findsNWidgets(5));
      final heights = [for (final e in bars.evaluate()) tester.getSize(find.byWidget(e.widget)).height];
      expect(heights.last, greaterThan(heights[3]));
      expect(heights[3], greaterThan(heights[0]));
      expect(find.text('4'), findsOneWidget, reason: 'total in header');
      expect(tester.takeException(), isNull);
    });

    testWidgets('all-zero buckets do not divide by zero', (tester) async {
      await tester.pumpWidget(_host(WeeklyBars(
        title: 'Adoptions',
        color: Colors.pink,
        buckets: _data(bucketByWeek(const [], now: now)),
      )));
      expect(find.byKey(const ValueKey('week-bar')), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading and error states', (tester) async {
      await tester.pumpWidget(_host(const WeeklyBars(title: 'x', color: Colors.teal, buckets: AsyncSnapshot.waiting())));
      expect(find.byType(SkeletonBox), findsWidgets);
      await tester.pumpWidget(_host(const WeeklyBars(
        title: 'x',
        color: Colors.teal,
        buckets: AsyncSnapshot.withError(ConnectionState.done, 'boom'),
      )));
      expect(find.text('—'), findsWidgets);
      expect(find.byKey(const ValueKey('week-bar')), findsNothing);
    });
  });

  testWidgets('ResponsiveTileGrid uses 1 column narrow and 4 wide', (tester) async {
    Future<List<double>> lefts(double width) async {
      await tester.pumpWidget(_host(
        ResponsiveTileGrid(children: [for (var i = 0; i < 4; i++) SizedBox(key: ValueKey(i), height: 40)]),
        width: width,
      ));
      return [for (var i = 0; i < 4; i++) tester.getTopLeft(find.byKey(ValueKey(i))).dx];
    }

    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    expect((await lefts(360)).toSet(), hasLength(1));
    expect((await lefts(1400)).toSet(), hasLength(4));
  });

  group('AttentionGroup', () {
    testWidgets('lists rows, caps them and fires the action', (tester) async {
      var opened = 0;
      await tester.pumpWidget(_host(SingleChildScrollView(
        child: AttentionGroup(
          title: 'Rescue',
          icon: Icons.warning,
          color: Colors.red,
          maxRows: 2,
          rows: _data(const [
            AttentionRow(title: 'Dog · Grand Baie', badge: 'critical'),
            AttentionRow(title: 'Cat · Curepipe', subtitle: 'pending'),
            AttentionRow(title: 'Dog · Flacq'),
          ]),
          actionLabel: 'Open Rescue SOS',
          onAction: () => opened++,
        ),
      )));
      expect(find.text('Dog · Grand Baie'), findsOneWidget);
      expect(find.text('Dog · Flacq'), findsNothing);
      expect(find.text('+ 1 more'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.text('Open Rescue SOS'));
      expect(opened, 1);
    });

    testWidgets('empty shows all clear', (tester) async {
      await tester.pumpWidget(_host(AttentionGroup(
        title: 'Inquiries',
        icon: Icons.mail,
        color: Colors.indigo,
        rows: _data(const <AttentionRow>[]),
        actionLabel: 'Open',
      )));
      expect(find.text('All clear'), findsOneWidget);
    });
  });
}
