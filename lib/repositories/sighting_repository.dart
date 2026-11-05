import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sighting.dart';
import '../utils/geo_utils.dart';
import '../utils/result.dart';

class SightingRepository {
  static const String collection = 'sightings';
  final FirebaseFirestore _firestore;

  SightingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Result<String>> create(Sighting sighting) async {
    try {
      final ref = await _firestore.collection(collection).add(sighting.toMap());
      return Result.success(ref.id);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Could not save sighting', error: e);
    } catch (e) {
      return Result.failure('Could not save sighting. Please try again.', error: e);
    }
  }

  /// Recent open sightings, newest first.
  Stream<List<Sighting>> watchOpen({int limit = 200}) {
    return _firestore
        .collection(collection)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Sighting.fromMap(d.id, d.data())).toList());
  }

  /// All sightings regardless of status (admin).
  Stream<List<Sighting>> watchAll({int limit = 500}) {
    return _firestore
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Sighting.fromMap(d.id, d.data())).toList());
  }

  /// Sightings attached to a specific lost-animal report.
  Stream<List<Sighting>> watchForLostReport(String lostReportId) {
    return _firestore
        .collection(collection)
        .where('lostReportId', isEqualTo: lostReportId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Sighting.fromMap(d.id, d.data())).toList());
  }

  Future<Result<void>> setStatus(String id, String status, {String? handledBy}) async {
    try {
      await _firestore.collection(collection).doc(id).update({
        'status': status,
        if (handledBy != null) 'handledBy': handledBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Update failed', error: e);
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await _firestore.collection(collection).doc(id).delete();
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Delete failed', error: e);
    }
  }

  /// Client-side radius filter. Mauritius is small enough that pulling the
  /// latest few hundred open sightings and filtering locally is cheaper and
  /// simpler than geohash indexing.
  static List<Sighting> within(
    List<Sighting> all,
    double lat,
    double lng,
    double radiusKm,
  ) {
    final out = all
        .where((s) => haversineKm(lat, lng, s.latitude, s.longitude) <= radiusKm)
        .toList();
    out.sort((a, b) => haversineKm(lat, lng, a.latitude, a.longitude)
        .compareTo(haversineKm(lat, lng, b.latitude, b.longitude)));
    return out;
  }
}
