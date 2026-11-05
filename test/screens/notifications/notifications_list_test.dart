import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/models/app_notification.dart';
import 'package:stray_pets_mu/screens/notifications/notifications_screen.dart';

void main() {
  final now = DateTime(2026, 3, 1, 12);
  final items = [
    AppNotification(
      id: 'n1',
      toUid: 'alice',
      type: 'adoption_stage',
      params: const {'petName': 'Rex', 'stage': 'completed'},
      refCollection: 'adoptions',
      refId: 'ad1',
      createdAt: now.subtract(const Duration(minutes: 5)),
    ),
    AppNotification(
      id: 'n2',
      toUid: 'alice',
      type: 'sighting',
      params: const {'animalType': 'Cat', 'sightingId': 's1'},
      refCollection: 'lostfound',
      refId: 'l1',
      read: true,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
  ];

  Future<void> pump(WidgetTester tester, List<AppNotification> list,
      {String lang = 'en',
      void Function(AppNotification)? onTap,
      void Function(AppNotification)? onDismissed}) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotificationsList(
          items: list,
          lang: lang,
          now: now,
          onTap: onTap ?? (_) {},
          onDismissed: onDismissed ?? (_) {},
        ),
      ),
    ));
  }

  testWidgets('shows localised titles, bodies and ages', (tester) async {
    await pump(tester, items);
    expect(find.text('Adoption update'), findsOneWidget);
    expect(find.text('Congratulations! The adoption of Rex is complete.'), findsOneWidget);
    expect(find.text('New sighting'), findsOneWidget);
    expect(find.text('Someone may have seen your cat. Tap to see the sighting.'), findsOneWidget);
    expect(find.text('5 min ago'), findsOneWidget);
    expect(find.text('1 d ago'), findsOneWidget);
    // Only the unread one has a dot.
    expect(find.byKey(const ValueKey('notif-unread-dot')), findsOneWidget);
  });

  testWidgets('French text', (tester) async {
    await pump(tester, items, lang: 'fr');
    expect(find.text('Félicitations ! L\'adoption de Rex est finalisée.'), findsOneWidget);
    expect(find.text('Nouveau signalement'), findsOneWidget);
  });

  testWidgets('tap reports the notification', (tester) async {
    AppNotification? tapped;
    await pump(tester, items, onTap: (n) => tapped = n);
    await tester.tap(find.text('New sighting'));
    expect(tapped?.id, 'n2');
  });

  testWidgets('swipe to delete', (tester) async {
    AppNotification? removed;
    await pump(tester, items, onDismissed: (n) => removed = n);
    await tester.drag(find.byKey(const ValueKey('notif-n1')), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(removed?.id, 'n1');
  });

  testWidgets('empty state', (tester) async {
    await pump(tester, const [], lang: 'mfe');
    expect(find.text('Pankor ena okenn notifikasion'), findsOneWidget);
  });
}
