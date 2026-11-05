import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/admin_web/reports_section.dart';
import 'package:stray_pets_mu/models/pet.dart';
import 'package:stray_pets_mu/models/sighting.dart';
import 'package:stray_pets_mu/utils/moderation.dart';
import 'package:stray_pets_mu/utils/similar_pets.dart';

void main() {
  group('isHiddenContent / withoutHidden', () {
    test('only an explicit hidden: true hides content', () {
      expect(isHiddenContent({'hidden': true}), isTrue);
      expect(isHiddenContent({'hidden': false}), isFalse);
      expect(isHiddenContent({'hidden': 'true'}), isFalse);
      expect(isHiddenContent({}), isFalse);
      expect(isHiddenContent(null), isFalse);
    });

    test('drops hidden items and keeps order', () {
      final docs = <(String, Map<String, dynamic>?)>[
        ('a', {'name': 'A'}),
        ('b', {'hidden': true}),
        ('c', {'hidden': false}),
        ('d', null),
      ];
      expect(withoutHidden(docs, (d) => d.$2).map((d) => d.$1), ['a', 'c', 'd']);
    });
  });

  group('models read the hidden flag', () {
    test('Pet.fromMap defaults hidden to false', () {
      expect(Pet.fromMap('p', {'name': 'Rex'}).hidden, isFalse);
      expect(Pet.fromMap('p', {'name': 'Rex', 'hidden': true}).hidden, isTrue);
      expect(Pet.fromMap('p', {'hidden': true}).copyWith(name: 'X').hidden, isTrue);
    });

    test('Pet.toMap does not write hidden (owner edits never clear it)', () {
      expect(Pet.fromMap('p', {'hidden': true}).toMap().containsKey('hidden'), isFalse);
    });

    test('Sighting.fromMap defaults hidden to false', () {
      final base = <String, dynamic>{'reporterId': 'u', 'geo': const GeoPoint(-20, 57)};
      expect(Sighting.fromMap('s', base).hidden, isFalse);
      expect(Sighting.fromMap('s', {...base, 'hidden': true}).hidden, isTrue);
    });
  });

  test('similar pets skip hidden pets', () {
    final result = filterSimilarPets([
      (id: 'a', data: <String, dynamic>{'status': 'available', 'hidden': true}),
      (id: 'b', data: <String, dynamic>{'status': 'available'}),
    ], currentPetId: 'x');
    expect(result.map((p) => p.id), ['b']);
  });

  group('admin reports helpers', () {
    test('sorts newest first, unstamped reports on top', () {
      final reports = <Map<String, dynamic>>[
        {'id': 'old', 'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1))},
        {'id': 'pending', 'createdAt': null},
        {'id': 'new', 'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1))},
      ];
      expect(sortReportsNewestFirst(reports, (r) => r).map((r) => r['id']),
          ['pending', 'new', 'old']);
    });

    test('summarises target fields and skips empty ones', () {
      final rows = reportTargetSummary(
          {'name': 'Rex', 'description': '', 'uploadedBy': 'u1', 'hidden': true});
      expect(rows, [('Name', 'Rex'), ('Owner uid', 'u1'), ('Hidden', 'true')]);
    });
  });
}
