import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

/// Reads and writes in-app notifications (`notifications` collection).
///
/// The `notify*` helpers are fire-and-forget: they never throw, so a
/// failed notification can never break the action that caused it.
class NotificationRepository {
  static const String collection = 'notifications';
  final FirebaseFirestore? _injected;
  final String? Function()? _currentUid;

  NotificationRepository({FirebaseFirestore? firestore, String? Function()? currentUid})
      : _injected = firestore,
        _currentUid = currentUid;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;
  String? get _uid => (_currentUid ?? () => FirebaseAuth.instance.currentUser?.uid)();

  CollectionReference<Map<String, dynamic>> get _col => _firestore.collection(collection);

  /// The user's notifications, newest first. Single-field query plus a
  /// client-side sort, so no composite index is needed.
  Stream<List<AppNotification>> watchFor(String uid) {
    return _col.where('toUid', isEqualTo: uid).snapshots().map((s) =>
        AppNotification.sortNewestFirst(
            s.docs.map((d) => AppNotification.fromMap(d.id, d.data()))));
  }

  Future<void> markRead(String id) => _col.doc(id).update({'read': true});

  Future<void> markAllRead(Iterable<String> ids) async {
    final list = ids.toList();
    // Firestore batches hold at most 500 writes.
    for (var i = 0; i < list.length; i += 450) {
      final batch = _firestore.batch();
      for (final id in list.skip(i).take(450)) {
        batch.update(_col.doc(id), {'read': true});
      }
      await batch.commit();
    }
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Writes [n]. Swallows every error.
  Future<void> send(AppNotification n) async {
    try {
      if (n.toUid.isEmpty || n.fromUid.isEmpty) return;
      // Don't await server confirmation: offline the write is queued.
      _col.doc().set(n.toCreateMap()).catchError((Object e) {
        debugPrint('Notification write failed: $e');
      });
    } catch (e) {
      debugPrint('Notification write failed: $e');
    }
  }

  /// Tell the adopter their application moved to [stage]. Pass [adopterId]
  /// and [petName] when known; otherwise they are read from the adoption.
  Future<void> notifyAdoptionStage({
    required String adoptionId,
    required String stage,
    String? adopterId,
    String? petName,
  }) async {
    try {
      final from = _uid;
      if (from == null) return;
      var to = adopterId;
      var name = petName;
      if (to == null || to.isEmpty || name == null) {
        final snap = await _firestore.collection('adoptions').doc(adoptionId).get();
        final data = snap.data() ?? const {};
        to = data['adopterId'] as String?;
        name = data['petName'] as String? ?? '';
      }
      if (to == null || to.isEmpty) return;
      final pet = name;
      await send(AppNotification(
        id: '',
        toUid: to,
        type: AppNotification.typeAdoptionStage,
        params: {
          'petName': pet.length > 100 ? pet.substring(0, 100) : pet,
          'stage': stage,
        },
        refCollection: 'adoptions',
        refId: adoptionId,
        fromUid: from,
      ));
    } catch (e) {
      debugPrint('notifyAdoptionStage failed: $e');
    }
  }

  /// Tell the owner of lost post [lostReportId] that sighting [sightingId]
  /// was reported. Skipped when the reporter owns the post.
  Future<void> notifySighting({
    required String lostReportId,
    required String sightingId,
    required String animalType,
  }) async {
    try {
      final from = _uid;
      if (from == null || lostReportId.isEmpty) return;
      final snap = await _firestore.collection('lostfound').doc(lostReportId).get();
      final owner = snap.data()?['userId'] as String?;
      if (owner == null || owner.isEmpty || owner == from) return;
      await send(AppNotification(
        id: '',
        toUid: owner,
        type: AppNotification.typeSighting,
        params: {
          'animalType': animalType.length > 40 ? animalType.substring(0, 40) : animalType,
          'sightingId': sightingId,
        },
        refCollection: 'lostfound',
        refId: lostReportId,
        fromUid: from,
      ));
    } catch (e) {
      debugPrint('notifySighting failed: $e');
    }
  }
}
