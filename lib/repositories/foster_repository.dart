import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/foster.dart';
import '../utils/result.dart';

class FosterRepository {
  final FirebaseFirestore _firestore;
  FosterRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Result<void>> createFoster(Foster foster) async {
    try {
      await _firestore.collection('fosters').add(foster.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Firestore error', error: e);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }

  Future<Result<void>> updateFosterStatus(String id, String status, {DateTime? endDate}) async {
    try {
      await _firestore.collection('fosters').doc(id).update({
        'status': status,
        if (endDate != null) 'endDate': Timestamp.fromDate(endDate),
      });
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Firestore error', error: e);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }

  Result<Stream<List<Foster>>> getFostersForUser(String userId) {
    try {
      final stream = _firestore
          .collection('fosters')
          .where('fosterUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => Foster.fromMap(d.id, d.data())).toList());
      return Result.success(stream);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }
}
