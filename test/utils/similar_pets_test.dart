import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/utils/similar_pets.dart';

PetDoc pet(String id, [String? status = 'available']) =>
    (id: id, data: {'name': id, if (status != null) 'status': status});

void main() {
  test('drops the current pet and non-available pets', () {
    final result = filterSimilarPets([
      pet('current'),
      pet('a'),
      pet('b', 'adopted'),
      pet('c', 'pending'),
      pet('d', 'Available'),
    ], currentPetId: 'current');
    expect(result.map((p) => p.id), ['a', 'd']);
  });

  test('treats a missing status as available', () {
    final result = filterSimilarPets([pet('a', null)], currentPetId: 'x');
    expect(result.map((p) => p.id), ['a']);
  });

  test('keeps order, removes duplicates and caps at six', () {
    final result = filterSimilarPets(
      [for (var i = 0; i < 10; i++) pet('p$i'), pet('p0')],
      currentPetId: 'p3',
    );
    expect(result.map((p) => p.id), ['p0', 'p1', 'p2', 'p4', 'p5', 'p6']);
    expect(kMaxSimilarPets, 6);
  });

  test('respects a custom max and handles empty input', () {
    expect(
        filterSimilarPets([pet('a'), pet('b')], currentPetId: 'x', max: 1)
            .map((p) => p.id),
        ['a']);
    expect(filterSimilarPets(const [], currentPetId: 'x'), isEmpty);
  });
}
