import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/adoption.dart';
import '../utils/result.dart';

class AdoptionRepository {
  final FirebaseFirestore _firestore;
  AdoptionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Result<void>> createAdoption(Adoption adoption) async {
    try {
      await _firestore.collection('adoptions').doc(adoption.id).set(adoption.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Firestore error', error: e);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }

  Future<Result<void>> updateStage(String id, AdoptionStage stage,
      {String? notes, String? changedBy}) async {
    try {
      final record = StageRecord(stage: stage, timestamp: DateTime.now(), notes: notes, changedBy: changedBy);
      await _firestore.collection('adoptions').doc(id).update({
        'currentStage': stage.name,
        'stageHistory': FieldValue.arrayUnion([record.toMap()]),
      });
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Firestore error', error: e);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }

  Future<Result<void>> rejectAdoption(String id, String reason) async {
    try {
      await _firestore.collection('adoptions').doc(id).update({
        'currentStage': AdoptionStage.rejected.name,
        'rejectionReason': reason,
      });
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Firestore error', error: e);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }

  Result<Stream<List<Adoption>>> getAdoptionsForUser(String userId) {
    try {
      final stream = _firestore
          .collection('adoptions')
          .where('adopterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => Adoption.fromMap(d.id, d.data())).toList());
      return Result.success(stream);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }

  Result<Stream<List<Adoption>>> getAllAdoptions() {
    try {
      final stream = _firestore
          .collection('adoptions')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => Adoption.fromMap(d.id, d.data())).toList());
      return Result.success(stream);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }
}
