import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/adoption.dart';
import 'notification_repository.dart';
import '../utils/result.dart';

class AdoptionRepository {
  final FirebaseFirestore _firestore;
  final NotificationRepository _notifications;
  AdoptionRepository({FirebaseFirestore? firestore, NotificationRepository? notifications})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _notifications = notifications ?? NotificationRepository(firestore: firestore);

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
      // Fire-and-forget: never blocks or fails the stage change.
      unawaited(_notifications.notifyAdoptionStage(adoptionId: id, stage: stage.name));
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
      unawaited(_notifications.notifyAdoptionStage(
          adoptionId: id, stage: AdoptionStage.rejected.name));
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
