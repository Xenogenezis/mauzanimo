import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/lang/strings_account.dart';
import 'package:stray_pets_mu/utils/account_data.dart';

void main() {
  group('accountDeletionPlan', () {
    AccountCollectionPlan plan(String c) =>
        accountDeletionPlan.firstWhere((p) => p.collection == c);

    test('deletes the user-owned collections with the right owner field', () {
      expect(plan('pets').ownerField, 'uploadedBy');
      expect(plan('lostfound').ownerField, 'userId');
      expect(plan('sightings').ownerField, 'reporterId');
      expect(plan('favourites').ownerField, 'userId');
      for (final c in ['pets', 'lostfound', 'sightings', 'favourites', 'stories', 'pet_updates']) {
        expect(plan(c).action, AccountDataAction.delete, reason: c);
      }
    });

    test('users/{uid} is deleted last and keyed by uid', () {
      expect(accountDeletionPlan.last.collection, 'users');
      expect(accountDeletionPlan.last.keyedByUid, isTrue);
      expect(accountDeletionPlan.last.action, AccountDataAction.delete);
    });

    test('rules-limited collections are cancelled/anonymised, not deleted', () {
      expect(plan('event_registrations').action, AccountDataAction.cancel);
      final g = plan('user_gamification');
      expect(g.keyedByUid, isTrue);
      expect(g.action, AccountDataAction.anonymise);
      expect(g.anonymisedFields['showOnLeaderboard'], isFalse);
      expect(g.subcollections, contains('impact_history'));
      expect(g.deleteIfAllowed, isTrue);
      expect(plan('event_registrations').deleteIfAllowed, isTrue);
    });

    test('welfare records are kept', () {
      for (final c in ['adoptions', 'fosters', 'inquiries', 'rescue_reports']) {
        expect(plan(c).action, AccountDataAction.keep, reason: c);
        expect(plan(c).ownerField, isNotNull);
      }
    });

    test('no collection appears twice', () {
      final names = accountDeletionPlan.map((p) => p.collection).toList();
      expect(names.toSet().length, names.length);
    });

    test('every non-uid plan has an owner field', () {
      for (final p in [...accountDeletionPlan, ...accountExportPlan]) {
        expect(p.keyedByUid || (p.ownerField?.isNotEmpty ?? false), isTrue, reason: p.collection);
      }
    });
  });

  group('chunked', () {
    test('splits into batches of the given size', () {
      final out = chunked(List.generate(10, (i) => i), 4);
      expect(out, [
        [0, 1, 2, 3],
        [4, 5, 6, 7],
        [8, 9],
      ]);
    });
    test('empty input yields no batches', () => expect(chunked(<int>[]), isEmpty));
    test('default size stays under Firestore 500-op limit', () {
      expect(accountBatchSize, lessThanOrEqualTo(500));
      expect(chunked(List.filled(801, 0)).map((c) => c.length), [400, 400, 1]);
    });
    test('rejects non-positive size', () => expect(() => chunked([1], 0), throwsArgumentError));
  });

  group('sanitizeForExport', () {
    final bigBase64 = 'A' * 2000;

    test('replaces data URIs and long base64 strings with [image]', () {
      expect(sanitizeForExport('data:image/jpeg;base64,/9j/4AAQ'), '[image]');
      expect(sanitizeForExport(bigBase64), '[image]');
    });

    test('keeps ordinary text, even long text with spaces/punctuation', () {
      expect(sanitizeForExport('Rex is friendly'), 'Rex is friendly');
      final longText = 'A friendly dog, very calm! ' * 40;
      expect(sanitizeForExport(longText), longText);
    });

    test('converts Firestore types to JSON-friendly values', () {
      final ts = Timestamp.fromDate(DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(sanitizeForExport(ts), '2026-01-02T03:04:05.000Z');
      expect(sanitizeForExport(const GeoPoint(-20.1, 57.5)),
          {'latitude': -20.1, 'longitude': 57.5});
      expect(sanitizeForExport(DateTime.utc(2026)), '2026-01-01T00:00:00.000Z');
    });

    test('recurses into maps and lists', () {
      final out = sanitizeForExport({
        'images': ['data:image/png;base64,iVBOR', 'https://x.test/a.jpg'],
        'nested': {'imageUrl': bigBase64, 'n': 3, 'ok': true, 'none': null},
      });
      expect(out, {
        'images': ['[image]', 'https://x.test/a.jpg'],
        'nested': {'imageUrl': '[image]', 'n': 3, 'ok': true, 'none': null},
      });
    });
  });

  group('buildAccountExport', () {
    final export = buildAccountExport(
      uid: 'u1',
      email: 'a@b.mu',
      profile: {'name': 'Alice', 'photo': 'data:image/jpeg;base64,xx'},
      collections: {
        'pets': {
          'p1': {'name': 'Rex', 'imageUrl': 'data:image/jpeg;base64,abc', 'uploadedBy': 'u1'},
        },
        'adoptions': {
          'a1': {'adopterId': 'u1', 'createdAt': Timestamp.fromDate(DateTime.utc(2026, 5, 1))},
        },
      },
      exportedAt: DateTime.utc(2026, 11, 5),
    );

    test('includes profile and every export collection', () {
      expect(export['uid'], 'u1');
      expect(export['email'], 'a@b.mu');
      expect(export['profile'], {'name': 'Alice', 'photo': '[image]'});
      for (final p in accountExportPlan) {
        expect(export.containsKey(p.collection), isTrue, reason: p.collection);
      }
      for (final c in ['pets', 'lostfound', 'sightings', 'favourites', 'adoptions', 'fosters', 'inquiries']) {
        expect(export.containsKey(c), isTrue, reason: c);
      }
      expect(export['lostfound'], isEmpty);
    });

    test('docs carry their id and stripped images', () {
      expect(export['pets'], [
        {'id': 'p1', 'name': 'Rex', 'imageUrl': '[image]', 'uploadedBy': 'u1'},
      ]);
      expect((export['adoptions'] as List).single['createdAt'], '2026-05-01T00:00:00.000Z');
    });

    test('encodes as pretty JSON that round-trips', () {
      final json = encodeAccountExport(export);
      expect(json, contains('\n  "uid": "u1"'));
      expect(jsonDecode(json)['exportedAt'], '2026-11-05T00:00:00.000Z');
      expect(json, isNot(contains('base64')));
    });

    test('null profile is allowed', () {
      final e = buildAccountExport(
          uid: 'u', profile: null, collections: const {}, exportedAt: DateTime.utc(2026));
      expect(e['profile'], isNull);
      expect(e.containsKey('email'), isFalse);
    });
  });

  test('accountExportFileName pads date parts', () {
    expect(accountExportFileName(DateTime(2026, 3, 7)), 'mauzanimo-data-2026-03-07.json');
  });

  test('isDeleteConfirmation', () {
    expect(isDeleteConfirmation('DELETE'), isTrue);
    expect(isDeleteConfirmation('  delete '), isTrue);
    expect(isDeleteConfirmation('DELET'), isFalse);
    expect(isDeleteConfirmation(''), isFalse);
  });

  test('accountStrings has the same keys in en, fr and mfe', () {
    final en = accountStrings['en']!.keys.toSet();
    expect(en, isNotEmpty);
    expect(accountStrings['fr']!.keys.toSet(), en);
    expect(accountStrings['mfe']!.keys.toSet(), en);
    expect(accountStrings['fr']!['acct_delete'], 'Supprimer mon compte');
  });
}
