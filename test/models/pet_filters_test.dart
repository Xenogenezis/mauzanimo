import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/models/pet.dart';
import 'package:stray_pets_mu/models/pet_filters.dart';
import 'package:stray_pets_mu/screens/info/adoption_quiz_screen.dart';

Pet _pet(String name,
        {String age = '2 years',
        String gender = 'Male',
        bool vaccinated = false,
        bool sterilized = false,
        String status = 'available',
        DateTime? createdAt}) =>
    Pet(
      id: name,
      name: name,
      type: 'dogs',
      location: 'Grand Baie',
      description: '',
      age: age,
      gender: gender,
      vaccinated: vaccinated,
      sterilized: sterilized,
      status: status,
      contact: '',
      createdAt: createdAt,
    );

void main() {
  group('parseAgeYears', () {
    test('years by default', () => expect(PetFilters.parseAgeYears('2 years'), 2));
    test('months', () => expect(PetFilters.parseAgeYears('6 months'), 0.5));
    test('French months', () => expect(PetFilters.parseAgeYears('3 mois'), 0.25));
    test('weeks', () => expect(PetFilters.parseAgeYears('8 weeks'), closeTo(0.15, 0.01)));
    test('decimal comma', () => expect(PetFilters.parseAgeYears('1,5 ans'), 1.5));
    test('no number', () => expect(PetFilters.parseAgeYears('Unknown'), isNull));
  });

  group('ageGroupOf', () {
    test('6 months is young, not senior', () =>
        expect(PetFilters.ageGroupOf('6 months'), AgeGroup.young));
    test('3 years is adult', () => expect(PetFilters.ageGroupOf('3 years'), AgeGroup.adult));
    test('10 years is senior', () => expect(PetFilters.ageGroupOf('10 years'), AgeGroup.senior));
    test('unknown is any', () => expect(PetFilters.ageGroupOf('?'), AgeGroup.any));
  });

  group('apply', () {
    final pets = [
      _pet('Rex', createdAt: DateTime(2026, 1, 1), vaccinated: true),
      _pet('Bella', gender: 'Female', age: '4 months', createdAt: DateTime(2026, 3, 1)),
      _pet('Max', age: '9 years', sterilized: true, status: 'adopted', createdAt: DateTime(2026, 2, 1)),
    ];
    List<String> names(PetFilters f) => f.apply(pets).map((p) => p.name).toList();

    test('default sorts newest first', () =>
        expect(names(PetFilters.none), ['Bella', 'Max', 'Rex']));
    test('oldest first', () =>
        expect(names(const PetFilters(sort: PetSort.oldest)), ['Rex', 'Max', 'Bella']));
    test('by name', () =>
        expect(names(const PetFilters(sort: PetSort.name)), ['Bella', 'Max', 'Rex']));
    test('gender is case-insensitive', () =>
        expect(names(const PetFilters(gender: 'female')), ['Bella']));
    test('age group', () =>
        expect(names(const PetFilters(ageGroup: AgeGroup.senior)), ['Max']));
    test('health and availability', () {
      expect(names(const PetFilters(vaccinatedOnly: true)), ['Rex']);
      expect(names(const PetFilters(sterilizedOnly: true)), ['Max']);
      expect(names(const PetFilters(availableOnly: true)), ['Bella', 'Rex']);
    });
    test('activeCount ignores sort', () {
      expect(const PetFilters(sort: PetSort.name).activeCount, 0);
      expect(const PetFilters(gender: 'male', vaccinatedOnly: true).activeCount, 2);
    });
    test('copyWith can clear gender', () =>
        expect(const PetFilters(gender: 'male').copyWith(clearGender: true).gender, isNull));
  });

  group('quizVerdict', () {
    test('7-8 yes is ready', () {
      expect(quizVerdict(8), QuizVerdict.ready);
      expect(quizVerdict(7), QuizVerdict.ready);
    });
    test('4-6 yes is almost', () {
      expect(quizVerdict(6), QuizVerdict.almost);
      expect(quizVerdict(4), QuizVerdict.almost);
    });
    test('under 4 is not yet', () => expect(quizVerdict(3), QuizVerdict.notYet));
  });
}
