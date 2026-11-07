import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/lang/strings_alerts.dart';
import 'package:stray_pets_mu/models/pet.dart';
import 'package:stray_pets_mu/models/pet_filters.dart';
import 'package:stray_pets_mu/models/saved_search.dart';
import 'package:stray_pets_mu/providers/pet_provider.dart';
import 'package:stray_pets_mu/repositories/pet_repository.dart';
import 'package:stray_pets_mu/screens/info/donate_screen.dart';
import 'package:stray_pets_mu/utils/result.dart';

class MockPetRepository extends Mock implements PetRepository {}

Pet _pet(String id, DateTime createdAt, {String type = 'dogs'}) => Pet(
      id: id,
      name: id,
      type: type,
      location: 'Grand Baie',
      description: '',
      age: '2 years',
      gender: 'Male',
      contact: '',
      createdAt: createdAt,
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late MockPetRepository repo;
  late StreamController<List<Pet>> pets;
  final lastVisit = DateTime(2026, 11, 1);

  setUp(() {
    repo = MockPetRepository();
    pets = StreamController<List<Pet>>.broadcast();
    when(() => repo.getPetsStream(
            typeFilter: any(named: 'typeFilter'), limit: any(named: 'limit')))
        .thenAnswer((_) => Result.success(pets.stream));
  });

  tearDown(() => pets.close());

  group('new since last visit', () {
    test('marks pets created after the stored visit and counts them',
        () async {
      SharedPreferences.setMockInitialValues(
          {PetProvider.lastVisitKey: lastVisit.millisecondsSinceEpoch});
      final p = PetProvider(repo);
      await _settle();
      final fresh = _pet('fresh', DateTime(2026, 11, 3));
      final old = _pet('old', DateTime(2026, 10, 1));
      pets.add([fresh, old]);
      await _settle();

      expect(p.lastVisit, lastVisit);
      expect(p.isNewPet(fresh), isTrue);
      expect(p.isNewPet(old), isFalse);
      expect(p.newPetCount, 1);
      expect(p.showNewBanner, isTrue);
      p.dismissNewBanner();
      expect(p.showNewBanner, isFalse);
      p.dispose();
    });

    test('first visit shows nothing new; markVisited stores the time',
        () async {
      SharedPreferences.setMockInitialValues({});
      final p = PetProvider(repo);
      await _settle();
      pets.add([_pet('a', DateTime(2026, 11, 3))]);
      await _settle();
      expect(p.newPetCount, 0);
      expect(p.showNewBanner, isFalse);

      final now = DateTime(2026, 11, 5, 10);
      await p.markVisited(now);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(PetProvider.lastVisitKey),
          now.millisecondsSinceEpoch);
      // The baseline for this session does not move on leave.
      expect(p.lastVisit, isNull);
      p.dispose();
    });

    test('storage failure keeps the features off without throwing', () async {
      final p = PetProvider(repo, prefs: () => Future.error(Exception('x')));
      await _settle();
      expect(p.lastVisit, isNull);
      expect(p.savedSearches, isEmpty);
      await p.markVisited();
      p.dispose();
    });
  });

  group('saved searches', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('saves current type, filters and query, persisted as JSON',
        () async {
      final p = PetProvider(repo);
      await _settle();
      p.setFilter('Cats');
      p.setSearchQuery('grand');
      const filters = PetFilters(gender: 'female');
      expect(await p.saveCurrentSearch('  My cats ', filters: filters), isTrue);

      final s = p.savedSearches.single;
      expect(s.name, 'My cats');
      expect(s.typeFilter, 'Cats');
      expect(s.query, 'grand');
      expect(s.filters, filters);

      final prefs = await SharedPreferences.getInstance();
      final stored =
          SavedSearch.decodeList(prefs.getString(PetProvider.savedSearchesKey));
      expect(stored.single.name, 'My cats');

      // A new provider (next app start) loads them back.
      final p2 = PetProvider(repo);
      await _settle();
      expect(p2.savedSearches.single.filters, filters);
      p.dispose();
      p2.dispose();
    });

    test('refuses empty names and more than 5 searches', () async {
      final p = PetProvider(repo);
      await _settle();
      expect(await p.saveCurrentSearch('   '), isFalse);
      for (var i = 0; i < SavedSearch.maxCount; i++) {
        expect(await p.saveCurrentSearch('s$i'), isTrue);
      }
      expect(p.canSaveSearch, isFalse);
      expect(await p.saveCurrentSearch('one too many'), isFalse);
      expect(p.savedSearches.length, SavedSearch.maxCount);

      await p.deleteSavedSearch(p.savedSearches.first.id);
      expect(p.savedSearches.length, SavedSearch.maxCount - 1);
      expect(p.canSaveSearch, isTrue);
      p.dispose();
    });

    test('applying a search sets the list state and resets lastOpened',
        () async {
      final old = DateTime(2020);
      SharedPreferences.setMockInitialValues({
        PetProvider.savedSearchesKey: SavedSearch.encodeList([
          SavedSearch(
            id: 'x',
            name: 'Dogs',
            typeFilter: 'Dogs',
            filters: const PetFilters(vaccinatedOnly: true),
            query: 'rex',
            lastOpened: old,
          ),
        ]),
      });
      final p = PetProvider(repo);
      await _settle();
      await p.applySavedSearch(p.savedSearches.single);
      expect(p.selectedFilter, 'Dogs');
      expect(p.searchQuery, 'rex');
      expect(p.listFilters, const PetFilters(vaccinatedOnly: true));
      expect(p.savedSearches.single.lastOpened.isAfter(old), isTrue);
      p.dispose();
    });

    test('recentPetsForAlerts reads the first snapshot of all types',
        () async {
      final p = PetProvider(repo);
      await _settle();
      final future = p.recentPetsForAlerts();
      await _settle();
      pets.add([_pet('a', DateTime(2026))]);
      expect((await future).single.id, 'a');
      verify(() => repo.getPetsStream(typeFilter: 'All', limit: 100))
          .called(1);
      p.dispose();
    });
  });

  test('alerts strings exist in en, fr and mfe', () {
    final keys = alertsStrings['en']!.keys.toSet();
    expect(keys, isNotEmpty);
    for (final lang in ['fr', 'mfe']) {
      expect(alertsStrings[lang]!.keys.toSet(), keys, reason: lang);
    }
    expect(AppStrings.get('alerts_copied', 'fr'), 'Copié');
  });

  test('donate copyValueOf keeps the value after the label', () {
    expect(copyValueOf('Account No: XXXX-XXXX-XXXX'), 'XXXX-XXXX-XXXX');
    expect(copyValueOf('Nom Kont: MauZanimo'), 'MauZanimo');
    expect(copyValueOf('No label'), 'No label');
    expect(copyValueOf('Empty:'), 'Empty:');
  });
}
