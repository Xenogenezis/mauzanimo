import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/models/pet.dart';
import 'package:stray_pets_mu/models/pet_filters.dart';
import 'package:stray_pets_mu/models/saved_search.dart';
import 'package:stray_pets_mu/utils/new_since.dart';

Pet _pet(String name,
        {String type = 'cats',
        String gender = 'Female',
        String age = '6 months',
        String location = 'Grand Baie',
        bool vaccinated = true,
        DateTime? createdAt}) =>
    Pet(
      id: name,
      name: name,
      type: type,
      location: location,
      description: '',
      age: age,
      gender: gender,
      vaccinated: vaccinated,
      contact: '',
      createdAt: createdAt,
    );

void main() {
  group('PetFilters JSON', () {
    test('round-trips every field', () {
      const f = PetFilters(
        gender: 'female',
        ageGroup: AgeGroup.young,
        vaccinatedOnly: true,
        sterilizedOnly: true,
        availableOnly: true,
        sort: PetSort.name,
      );
      final back = PetFilters.fromJson(
          jsonDecode(jsonEncode(f.toJson())) as Map<String, dynamic>);
      expect(back, f);
    });

    test('defaults round-trip to none', () {
      expect(PetFilters.fromJson(PetFilters.none.toJson()), PetFilters.none);
      expect(PetFilters.none.toJson().containsKey('gender'), isFalse);
    });

    test('unknown or missing values fall back to defaults', () {
      final f = PetFilters.fromJson({
        'gender': 'robot',
        'ageGroup': 'ancient',
        'sort': 42,
        'vaccinatedOnly': 'yes',
      });
      expect(f, PetFilters.none);
      expect(PetFilters.fromJson(const {}), PetFilters.none);
    });

    test('matches agrees with apply', () {
      const f = PetFilters(gender: 'male');
      expect(f.matches(_pet('a', gender: 'Male')), isTrue);
      expect(f.matches(_pet('b', gender: 'Female')), isFalse);
    });
  });

  group('SavedSearch', () {
    final opened = DateTime(2026, 11, 1);
    final search = SavedSearch(
      id: '1',
      name: 'Young cats',
      typeFilter: 'Cats',
      filters: const PetFilters(ageGroup: AgeGroup.young),
      query: 'grand',
      lastOpened: opened,
    );

    test('JSON round-trip', () {
      final back = SavedSearch.fromJson(
          jsonDecode(jsonEncode(search.toJson())) as Map<String, dynamic>);
      expect(back.id, '1');
      expect(back.name, 'Young cats');
      expect(back.typeFilter, 'Cats');
      expect(back.filters, search.filters);
      expect(back.query, 'grand');
      expect(back.lastOpened, opened);
    });

    test('decodeList tolerates corrupt data and caps at max', () {
      expect(SavedSearch.decodeList(null), isEmpty);
      expect(SavedSearch.decodeList('not json'), isEmpty);
      expect(SavedSearch.decodeList('{"a":1}'), isEmpty);
      final many = [
        for (var i = 0; i < 8; i++)
          SavedSearch(id: '$i', name: 'n$i', lastOpened: opened),
      ];
      final raw = SavedSearch.encodeList(many);
      expect(SavedSearch.decodeList(raw).length, SavedSearch.maxCount);
      final withJunk = jsonEncode([
        'junk',
        {'name': 'no id'},
        search.toJson(),
      ]);
      expect(SavedSearch.decodeList(withJunk).single.id, '1');
    });

    test('matches type, text and filters', () {
      expect(search.matches(_pet('Mimi')), isTrue);
      expect(search.matches(_pet('Rex', type: 'dogs')), isFalse);
      expect(search.matches(_pet('Mimi', location: 'Curepipe')), isFalse);
      expect(search.matches(_pet('Old', age: '9 years')), isFalse);
    });

    test('newMatchCount counts only pets created after lastOpened', () {
      final pets = [
        _pet('new1', createdAt: opened.add(const Duration(hours: 1))),
        _pet('new2', createdAt: opened.add(const Duration(days: 2))),
        _pet('old', createdAt: opened.subtract(const Duration(hours: 1))),
        _pet('undated'),
        _pet('newDog',
            type: 'dogs', createdAt: opened.add(const Duration(hours: 1))),
      ];
      expect(search.newMatchCount(pets), 2);
      expect(
          search
              .copyWith(lastOpened: opened.add(const Duration(days: 1)))
              .newMatchCount(pets),
          1);
    });
  });

  group('new since last visit', () {
    final visit = DateTime(2026, 11, 3, 12);
    test('no previous visit means nothing is new', () {
      expect(isNewSince(_pet('a', createdAt: DateTime(2030)), null), isFalse);
    });
    test('created after the visit is new; before or undated is not', () {
      expect(isNewSince(_pet('a', createdAt: DateTime(2026, 11, 4)), visit),
          isTrue);
      expect(isNewSince(_pet('b', createdAt: DateTime(2026, 11, 2)), visit),
          isFalse);
      expect(isNewSince(_pet('c', createdAt: visit), visit), isFalse);
      expect(isNewSince(_pet('d'), visit), isFalse);
    });
    test('countNewSince', () {
      expect(
          countNewSince([
            _pet('a', createdAt: DateTime(2026, 11, 4)),
            _pet('b', createdAt: DateTime(2026, 11, 5)),
            _pet('c', createdAt: DateTime(2026, 11, 1)),
          ], visit),
          2);
    });
  });
}
