import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/models/adoption.dart';
import 'package:stray_pets_mu/utils/adoption_sorting.dart';

Adoption _a(String id, DateTime createdAt,
        {AdoptionStage stage = AdoptionStage.application,
        List<StageRecord> history = const []}) =>
    Adoption(
      id: id,
      petId: 'pet_$id',
      petName: 'Pet $id',
      adopterId: 'u1',
      adopterName: 'A',
      adopterEmail: 'a@b.mu',
      adopterPhone: '123',
      currentStage: stage,
      stageHistory: history,
      createdAt: createdAt,
    );

void main() {
  group('sortAdoptionsNewestFirst', () {
    test('orders by createdAt descending', () {
      final sorted = sortAdoptionsNewestFirst([
        _a('old', DateTime(2025, 1, 1)),
        _a('new', DateTime(2026, 3, 1)),
        _a('mid', DateTime(2025, 6, 1)),
      ]);
      expect(sorted.map((a) => a.id), ['new', 'mid', 'old']);
    });

    test('breaks ties by id and does not mutate the input', () {
      final same = DateTime(2026, 1, 1);
      final input = [_a('b', same), _a('a', same), _a('c', same)];
      final sorted = sortAdoptionsNewestFirst(input);
      expect(sorted.map((a) => a.id), ['a', 'b', 'c']);
      expect(input.map((a) => a.id), ['b', 'a', 'c']);
    });

    test('handles an empty list', () {
      expect(sortAdoptionsNewestFirst(const []), isEmpty);
    });
  });

  group('groupAdoptions', () {
    test('splits active and closed, each newest first', () {
      final groups = groupAdoptions([
        _a('done', DateTime(2025, 1, 1), stage: AdoptionStage.completed),
        _a('trial', DateTime(2025, 2, 1), stage: AdoptionStage.trial),
        _a('rej', DateTime(2025, 5, 1), stage: AdoptionStage.rejected),
        _a('app', DateTime(2025, 4, 1)),
      ]);
      expect(groups.active.map((a) => a.id), ['app', 'trial']);
      expect(groups.closed.map((a) => a.id), ['rej', 'done']);
      expect(groups.isEmpty, isFalse);
    });

    test('isEmpty for no adoptions', () {
      expect(groupAdoptions(const []).isEmpty, isTrue);
    });
  });

  group('adoptionReachedStep', () {
    test('uses the current stage index for active adoptions', () {
      expect(adoptionReachedStep(_a('x', DateTime(2025))), 0);
      expect(
          adoptionReachedStep(
              _a('x', DateTime(2025), stage: AdoptionStage.meet_greet)),
          2);
      expect(
          adoptionReachedStep(
              _a('x', DateTime(2025), stage: AdoptionStage.completed)),
          kAdoptionSteps.length - 1);
    });

    test('uses the furthest recorded step for rejected adoptions', () {
      final history = [
        StageRecord(stage: AdoptionStage.screening, timestamp: DateTime(2025)),
        StageRecord(stage: AdoptionStage.meet_greet, timestamp: DateTime(2025)),
        StageRecord(stage: AdoptionStage.rejected, timestamp: DateTime(2025)),
      ];
      expect(
          adoptionReachedStep(_a('x', DateTime(2025),
              stage: AdoptionStage.rejected, history: history)),
          2);
      expect(
          adoptionReachedStep(
              _a('x', DateTime(2025), stage: AdoptionStage.rejected)),
          0);
    });
  });

  test('isAdoptionClosed', () {
    expect(isAdoptionClosed(AdoptionStage.completed), isTrue);
    expect(isAdoptionClosed(AdoptionStage.rejected), isTrue);
    expect(isAdoptionClosed(AdoptionStage.trial), isFalse);
  });

  test('Adoption.fromMap tolerates a pending server timestamp', () {
    final a = Adoption.fromMap('id1', {
      'petId': 'p',
      'petName': 'Rex',
      'adopterId': 'u1',
      'currentStage': 'screening',
      'createdAt': null,
    });
    expect(a.currentStage, AdoptionStage.screening);
    expect(a.createdAt, isA<DateTime>());
  });
}
