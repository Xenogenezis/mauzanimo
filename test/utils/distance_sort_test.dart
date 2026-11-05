import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/utils/distance_sort.dart';

void main() {
  group('sortByDistance', () {
    test('puts items with a distance first, nearest first', () {
      final items = ['far', 'near', 'mid'];
      final km = {'far': 30.0, 'near': 1.5, 'mid': 8.0};
      expect(sortByDistance(items, (i) => km[i]), ['near', 'mid', 'far']);
    });

    test('keeps items without a distance after, in original order', () {
      final items = ['noA', 'far', 'noB', 'near', 'noC'];
      final km = {'far': 12.0, 'near': 0.4};
      expect(
        sortByDistance(items, (i) => km[i]),
        ['near', 'far', 'noA', 'noB', 'noC'],
      );
    });

    test('is stable for equal distances', () {
      final items = ['a', 'b', 'c'];
      expect(sortByDistance(items, (_) => 2.0), ['a', 'b', 'c']);
    });

    test('treats NaN as unknown', () {
      final items = ['nan', 'ok'];
      final km = {'nan': double.nan, 'ok': 3.0};
      expect(sortByDistance(items, (i) => km[i]), ['ok', 'nan']);
    });

    test('handles empty input and does not modify the original list', () {
      expect(sortByDistance(<String>[], (_) => 1.0), isEmpty);
      final items = ['b', 'a'];
      final km = {'a': 1.0, 'b': 2.0};
      expect(sortByDistance(items, (i) => km[i]), ['a', 'b']);
      expect(items, ['b', 'a']);
    });
  });

  group('distanceKmToGeo', () {
    test('returns null when geo is missing or not a GeoPoint', () {
      expect(distanceKmToGeo(null, -20.16, 57.5), isNull);
      expect(distanceKmToGeo('nope', -20.16, 57.5), isNull);
    });

    test('computes distance to a GeoPoint', () {
      // Port Louis to Grand Baie is roughly 18 km as the crow flies.
      final d = distanceKmToGeo(const GeoPoint(-20.0127, 57.5803), -20.1609, 57.5012);
      expect(d, isNotNull);
      expect(d!, closeTo(18.4, 2));
    });

    test('is zero for the same point', () {
      expect(distanceKmToGeo(const GeoPoint(-20.2, 57.5), -20.2, 57.5), closeTo(0, 1e-9));
    });
  });
}
