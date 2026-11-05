import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/admin_web/session_timeout.dart';

/// Manual clock: timers fire only when [elapse] moves time past them.
class FakeClock {
  Duration now = Duration.zero;
  final _timers = <_FakeTimer>[];

  Timer create(Duration d, void Function() cb) {
    final t = _FakeTimer(now + d, cb);
    _timers.add(t);
    return t;
  }

  void elapse(Duration d) {
    final end = now + d;
    while (true) {
      final due = _timers.where((t) => t.isActive && t.at <= end).toList()
        ..sort((a, b) => a.at.compareTo(b.at));
      if (due.isEmpty) break;
      final t = due.first;
      now = t.at;
      t.fire();
    }
    now = end;
  }

  int get active => _timers.where((t) => t.isActive).length;
}

class _FakeTimer implements Timer {
  final Duration at;
  final void Function() cb;
  bool _active = true;
  _FakeTimer(this.at, this.cb);

  void fire() {
    _active = false;
    cb();
  }

  @override
  void cancel() => _active = false;
  @override
  bool get isActive => _active;
  @override
  int get tick => 0;
}

void main() {
  late FakeClock clock;
  late List<String> events;
  late IdleTimeout idle;

  setUp(() {
    clock = FakeClock();
    events = [];
    idle = IdleTimeout(
      onWarning: () => events.add('warn@${clock.now.inSeconds}'),
      onTimeout: () => events.add('out@${clock.now.inSeconds}'),
      timerFactory: clock.create,
    )..start();
  });

  test('warns at 29 minutes and signs out at 30 without activity', () {
    clock.elapse(const Duration(minutes: 28, seconds: 59));
    expect(events, isEmpty);
    clock.elapse(const Duration(seconds: 1));
    expect(events, ['warn@1740']);
    expect(idle.state, IdleState.warning);
    clock.elapse(const Duration(seconds: 59));
    expect(events, ['warn@1740']);
    clock.elapse(const Duration(seconds: 1));
    expect(events, ['warn@1740', 'out@1800']);
    expect(idle.state, IdleState.expired);
  });

  test('activity resets the countdown', () {
    clock.elapse(const Duration(minutes: 20));
    idle.activity();
    clock.elapse(const Duration(minutes: 20));
    expect(events, isEmpty, reason: 'only 20 minutes since the last activity');
    clock.elapse(const Duration(minutes: 9));
    expect(events, ['warn@2940']);
    expect(clock.active, 1, reason: 'old timers are cancelled');
  });

  test('activity while the warning is shown does not extend the session', () {
    clock.elapse(const Duration(minutes: 29));
    idle.activity();
    clock.elapse(const Duration(seconds: 60));
    expect(events, ['warn@1740', 'out@1800']);
  });

  test('stayActive during the warning restarts a full 30 minutes', () {
    clock.elapse(const Duration(minutes: 29, seconds: 30));
    idle.stayActive();
    expect(idle.state, IdleState.active);
    clock.elapse(const Duration(minutes: 28, seconds: 59));
    expect(events, ['warn@1740']);
    clock.elapse(const Duration(seconds: 1));
    expect(events, ['warn@1740', 'warn@3510']);
  });

  test('nothing fires after expiry or dispose', () {
    clock.elapse(const Duration(minutes: 30));
    idle.stayActive();
    idle.activity();
    clock.elapse(const Duration(hours: 2));
    expect(events, ['warn@1740', 'out@1800']);

    final other = IdleTimeout(
      onWarning: () => events.add('x'),
      onTimeout: () => events.add('y'),
      timerFactory: clock.create,
    )..start();
    other.dispose();
    clock.elapse(const Duration(hours: 1));
    expect(events, ['warn@1740', 'out@1800']);
  });

  testWidgets('IdleSignOut shows the warning, then signs out', (tester) async {
    var signedOut = 0;
    await tester.pumpWidget(MaterialApp(
      home: IdleSignOut(
        timeout: const Duration(minutes: 2),
        warning: const Duration(seconds: 60),
        signOut: () async => signedOut++,
        child: const Scaffold(body: Text('shell')),
      ),
    ));
    await tester.pump(const Duration(seconds: 59));
    expect(find.text('Still there?'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Still there?'), findsOneWidget);
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();
    expect(signedOut, 1);
    expect(find.text('Still there?'), findsNothing);
  });

  testWidgets('"Stay signed in" keeps the session', (tester) async {
    var signedOut = 0;
    await tester.pumpWidget(MaterialApp(
      home: IdleSignOut(
        timeout: const Duration(minutes: 2),
        warning: const Duration(seconds: 60),
        signOut: () async => signedOut++,
        child: const Scaffold(body: Text('shell')),
      ),
    ));
    await tester.pump(const Duration(seconds: 61));
    await tester.tap(find.text('Stay signed in'));
    await tester.pumpAndSettle();
    expect(find.text('Still there?'), findsNothing);
    await tester.pump(const Duration(seconds: 50));
    expect(find.text('Still there?'), findsNothing);
    // Pointer activity in the shell resets the timer (warning would
    // otherwise appear 60 s after "Stay signed in").
    await tester.tap(find.text('shell'));
    await tester.pump(const Duration(seconds: 50));
    expect(find.text('Still there?'), findsNothing);
    expect(signedOut, 0);
    await tester.pump(const Duration(seconds: 11));
    await tester.pump();
    expect(find.text('Still there?'), findsOneWidget);
    await tester.pump(const Duration(seconds: 60));
    await tester.pumpAndSettle();
    expect(signedOut, 1);
  });
}
