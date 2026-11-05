import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/models/sighting.dart';
import 'package:stray_pets_mu/repositories/sighting_repository.dart';

void main() {
  group('Sighting', () {
    test('round-trips GeoPoint and fields through toMap/fromMap', () {
      const s = Sighting(
        id: 'x',
        reporterId: 'u1',
        reporterName: 'Ana',
        animalType: 'Dog',
        description: 'Brown, red collar',
        latitude: -20.0108,
        longitude: 57.5817,
        accuracyMeters: 8,
        lostReportId: 'lost42',
      );
      final map = s.toMap();
      expect(map['geo'], isA<GeoPoint>());
      expect(map['status'], 'open');

      map['createdAt'] = Timestamp.fromDate(DateTime(2026, 11, 5));
      final back = Sighting.fromMap('x', map);
      expect(back.latitude, closeTo(-20.0108, 1e-9));
      expect(back.longitude, closeTo(57.5817, 1e-9));
      expect(back.accuracyMeters, 8);
      expect(back.isLinkedToLostReport, isTrue);
      expect(back.createdAt, DateTime(2026, 11, 5));
    });

    test('fromMap tolerates missing fields', () {
      final s = Sighting.fromMap('y', {});
      expect(s.animalType, 'Animal');
      expect(s.status, 'open');
      expect(s.createdAt, isNull);
      expect(s.isLinkedToLostReport, isFalse);
    });
  });

  group('SightingRepository.within', () {
    Sighting at(String id, double lat, double lng) => Sighting(
          id: id, reporterId: '', reporterName: '', animalType: 'Dog',
          description: '', latitude: lat, longitude: lng);

    test('filters by radius and sorts nearest first', () {
      // Grand Baie, Port Louis (~22 km away), and a point ~600 m from Grand Baie.
      final all = [
        at('portlouis', -20.1609, 57.5012),
        at('grandbaie', -20.0108, 57.5817),
        at('near', -20.0155, 57.5850),
      ];
      final r = SightingRepository.within(all, -20.0108, 57.5817, 5);
      expect(r.map((s) => s.id), ['grandbaie', 'near']);
    });
  });
}
