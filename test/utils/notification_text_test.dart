import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/lang/strings_notify.dart';
import 'package:stray_pets_mu/models/app_notification.dart';
import 'package:stray_pets_mu/utils/notification_text.dart';

void main() {
  group('notificationBody', () {
    test('adoption stage, every stage and language, includes the pet name', () {
      for (final lang in ['en', 'fr', 'mfe']) {
        for (final stage in kNotifyStages) {
          final text = notificationBody(
              'adoption_stage', {'petName': 'Rex', 'stage': stage}, lang);
          expect(text, contains('Rex'), reason: '$lang/$stage');
          expect(text, isNot(contains('{pet}')));
        }
      }
    });

    test('adoption stage text is localised', () {
      final p = {'petName': 'Rex', 'stage': 'trial'};
      expect(notificationBody('adoption_stage', p, 'en'),
          'Your trial period with Rex has started.');
      expect(notificationBody('adoption_stage', p, 'fr'),
          'Votre période d\'essai avec Rex a commencé.');
      expect(notificationBody('adoption_stage', p, 'mfe'),
          'To period lesey avek Rex finn koumanse.');
    });

    test('unknown stage and missing pet name fall back', () {
      expect(notificationBody('adoption_stage', {'stage': 'weird'}, 'en'),
          'Your application for your pet has been updated.');
    });

    test('sighting localises the animal type', () {
      expect(notificationBody('sighting', {'animalType': 'Dog'}, 'en'),
          'Someone may have seen your dog. Tap to see the sighting.');
      expect(notificationBody('sighting', {'animalType': 'Cat'}, 'fr'),
          contains('votre chat'));
      expect(notificationBody('sighting', {'animalType': 'Other'}, 'mfe'),
          contains('to zanimo'));
    });

    test('unknown type gives generic text', () {
      expect(notificationBody('promo', const {}, 'en'), 'You have a new update.');
      expect(notificationTitle('promo', 'fr'), 'Notification');
    });

    test('unknown language falls back to English', () {
      expect(notificationTitle('sighting', 'xx'), 'New sighting');
    });
  });

  test('titles', () {
    expect(notificationTitle('adoption_stage', 'en'), 'Adoption update');
    expect(notificationTitle('sighting', 'fr'), 'Nouveau signalement');
    expect(notificationTitle('sighting', 'mfe'), 'Nouvo signalman');
  });

  test('notificationAge', () {
    final now = DateTime(2026, 1, 10, 12);
    expect(notificationAge(null, now, 'en'), 'Just now');
    expect(notificationAge(now.subtract(const Duration(seconds: 20)), now, 'en'), 'Just now');
    expect(notificationAge(now.subtract(const Duration(minutes: 5)), now, 'en'), '5 min ago');
    expect(notificationAge(now.subtract(const Duration(hours: 3)), now, 'fr'), 'Il y a 3 h');
    expect(notificationAge(now.subtract(const Duration(days: 2)), now, 'mfe'), '2 zour desela');
  });

  test('notify strings have the same keys in en, fr and mfe', () {
    final en = notifyStrings['en']!.keys.toSet();
    expect(notifyStrings['fr']!.keys.toSet(), en);
    expect(notifyStrings['mfe']!.keys.toSet(), en);
  });

  group('AppNotification', () {
    test('fromMap reads params and timestamp', () {
      final n = AppNotification.fromMap('n1', {
        'toUid': 'u1',
        'type': 'sighting',
        'params': {'animalType': 'Dog', 'sightingId': 's1'},
        'refCollection': 'lostfound',
        'refId': 'l1',
        'fromUid': 'u2',
        'read': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      expect(n.params['animalType'], 'Dog');
      expect(n.read, isTrue);
      expect(n.createdAt, DateTime(2026, 1, 1));
    });

    test('toCreateMap always writes read=false', () {
      const n = AppNotification(
          id: '', toUid: 'a', type: 'sighting', refCollection: 'lostfound', refId: 'l', fromUid: 'b', read: true);
      final m = n.toCreateMap();
      expect(m['read'], isFalse);
      expect(m.keys.toSet(), {
        'toUid', 'type', 'params', 'refCollection', 'refId', 'fromUid', 'read', 'createdAt',
      });
    });

    test('sortNewestFirst puts pending (null) timestamps first', () {
      AppNotification at(String id, DateTime? t) => AppNotification(
          id: id, toUid: 'a', type: 't', refCollection: 'c', refId: 'r', createdAt: t);
      final sorted = AppNotification.sortNewestFirst([
        at('old', DateTime(2026, 1, 1)),
        at('pending', null),
        at('new', DateTime(2026, 2, 1)),
      ]);
      expect(sorted.map((n) => n.id), ['pending', 'new', 'old']);
    });
  });
}
