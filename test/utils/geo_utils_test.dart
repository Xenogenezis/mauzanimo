import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/utils/geo_utils.dart';

void main() {
  test('haversine Grand Baie -> Port Louis is about 18-20 km', () {
    final km = haversineKm(-20.0108, 57.5817, -20.1609, 57.5012);
    expect(km, inInclusiveRange(18, 20));
  });

  test('haversine of identical points is 0', () {
    expect(haversineKm(-20.2, 57.5, -20.2, 57.5), 0);
  });

  test('formatDistance', () {
    expect(formatDistance(0.35), '350 m');
    expect(formatDistance(4.23), '4.2 km');
    expect(formatDistance(23.4), '23 km');
  });

  test('isInMauritiusRegion', () {
    expect(isInMauritiusRegion(-20.25, 57.55), isTrue); // Mauritius
    expect(isInMauritiusRegion(-19.7, 63.4), isTrue); // Rodrigues
    expect(isInMauritiusRegion(0, 0), isFalse);
    expect(isInMauritiusRegion(48.85, 2.35), isFalse); // Paris
  });
}
