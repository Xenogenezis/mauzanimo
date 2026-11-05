import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../utils/account_data.dart';
import '../utils/result.dart';

/// How the signed-in user can prove it is them before a sensitive action.
enum ReauthMethod { password, google, unsupported }

/// What [AccountRepository.deleteOwnData] did, per collection.
class AccountDeletionReport {
  final Map<String, int> deleted = {};
  final Map<String, int> anonymised = {};
  final Map<String, int> cancelled = {};

  /// Collections whose docs were left untouched because the rules don't
  /// let the owner change them.
  final Map<String, int> kept = {};
}

/// Firestore + Auth calls for "Delete my account" and "Download my data".
/// What to touch is decided by the pure plans in `utils/account_data.dart`.
class AccountRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AccountRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  ReauthMethod get reauthMethod {
    final providers =
        _auth.currentUser?.providerData.map((p) => p.providerId).toSet() ?? {};
    if (providers.contains(EmailAuthProvider.PROVIDER_ID)) {
      return ReauthMethod.password;
    }
    if (providers.contains(GoogleAuthProvider.PROVIDER_ID)) {
      return ReauthMethod.google;
    }
    return ReauthMethod.unsupported;
  }

  /// Re-authenticates the current user. [password] is required for email
  /// accounts; Google accounts go through the provider flow (popup on web).
  Future<Result<void>> reauthenticate({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return Result.failure('Not signed in.');
    try {
      switch (reauthMethod) {
        case ReauthMethod.password:
          final email = user.email;
          if (email == null || password == null || password.isEmpty) {
            return Result.failure('Password required.');
          }
          await user.reauthenticateWithCredential(
              EmailAuthProvider.credential(email: email, password: password));
        case ReauthMethod.google:
          final provider = GoogleAuthProvider();
          if (kIsWeb) {
            await user.reauthenticateWithPopup(provider);
          } else {
            await user.reauthenticateWithProvider(provider);
          }
        case ReauthMethod.unsupported:
          return Result.failure('Unsupported sign-in method.');
      }
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(e.code, error: e);
    } catch (e, st) {
      return Result.failure(e.toString(), error: e, stackTrace: st);
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _ownedDocs(
      String collection, String ownerField, String uid) async {
    final snap = await _firestore
        .collection(collection)
        .where(ownerField, isEqualTo: uid)
        .get();
    return snap.docs;
  }

  Future<void> _commitInBatches(
      List<DocumentReference<Map<String, dynamic>>> refs,
      void Function(WriteBatch, DocumentReference<Map<String, dynamic>>) op) async {
    for (final chunk in chunked(refs)) {
      final batch = _firestore.batch();
      for (final ref in chunk) {
        op(batch, ref);
      }
      await batch.commit();
    }
  }

  /// Runs [attempt]; returns false (instead of throwing) when the rules deny it.
  Future<bool> _allowed(Future<void> Function() attempt) async {
    try {
      await attempt();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
  }

  /// Deletes (or anonymises/cancels where the rules only allow that) all of
  /// [uid]'s data following [accountDeletionPlan]. Call after
  /// [reauthenticate] and before [deleteAuthUser].
  Future<Result<AccountDeletionReport>> deleteOwnData(String uid) async {
    final report = AccountDeletionReport();
    try {
      for (final plan in accountDeletionPlan) {
        if (plan.keyedByUid) {
          final ref = _firestore.collection(plan.collection).doc(uid);
          for (final sub in plan.subcollections) {
            final subDocs = await ref.collection(sub).get();
            await _commitInBatches(subDocs.docs.map((d) => d.reference).toList(),
                (b, r) => b.delete(r));
          }
          switch (plan.action) {
            case AccountDataAction.delete:
              await ref.delete();
              report.deleted[plan.collection] = 1;
            case AccountDataAction.anonymise:
              final snap = await ref.get();
              if (!snap.exists) break;
              if (plan.deleteIfAllowed && await _allowed(ref.delete)) {
                report.deleted[plan.collection] = 1;
              } else {
                await ref.update(plan.anonymisedFields);
                report.anonymised[plan.collection] = 1;
              }
            case AccountDataAction.cancel:
            case AccountDataAction.keep:
              break;
          }
          continue;
        }
        final docs = await _ownedDocs(plan.collection, plan.ownerField!, uid);
        final refs = docs.map((d) => d.reference).toList();
        if (refs.isNotEmpty &&
            plan.deleteIfAllowed &&
            plan.action != AccountDataAction.delete &&
            await _allowed(() => _commitInBatches(refs, (b, r) => b.delete(r)))) {
          report.deleted[plan.collection] = refs.length;
          continue;
        }
        switch (plan.action) {
          case AccountDataAction.delete:
            await _commitInBatches(refs, (b, r) => b.delete(r));
            report.deleted[plan.collection] = refs.length;
          case AccountDataAction.cancel:
            final active = docs
                .where((d) => d.data()['status'] != 'cancelled')
                .map((d) => d.reference)
                .toList();
            await _commitInBatches(
                active,
                (b, r) => b.update(r, {
                      'status': 'cancelled',
                      'cancelledAt': FieldValue.serverTimestamp(),
                    }));
            report.cancelled[plan.collection] = active.length;
          case AccountDataAction.anonymise:
            await _commitInBatches(
                refs, (b, r) => b.update(r, plan.anonymisedFields));
            report.anonymised[plan.collection] = refs.length;
          case AccountDataAction.keep:
            report.kept[plan.collection] = refs.length;
        }
      }
      return Result.success(report);
    } on FirebaseException catch (e, st) {
      return Result.failure(e.message ?? e.code, error: e, stackTrace: st);
    } catch (e, st) {
      return Result.failure(e.toString(), error: e, stackTrace: st);
    }
  }

  /// Deletes the Firebase Auth user and signs out.
  Future<Result<void>> deleteAuthUser() async {
    try {
      await _auth.currentUser?.delete();
      await _auth.signOut();
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      return Result.failure(e.code, error: e);
    } catch (e, st) {
      return Result.failure(e.toString(), error: e, stackTrace: st);
    }
  }

  /// Collects the user's profile and records for "Download my data".
  Future<Result<Map<String, Object?>>> exportOwnData(String uid) async {
    try {
      final profileSnap = await _firestore.collection('users').doc(uid).get();
      final collections = <String, Map<String, Map<String, dynamic>>>{};
      for (final plan in accountExportPlan) {
        final docs = await _ownedDocs(plan.collection, plan.ownerField!, uid);
        collections[plan.collection] = {for (final d in docs) d.id: d.data()};
      }
      return Result.success(buildAccountExport(
        uid: uid,
        email: _auth.currentUser?.email,
        profile: profileSnap.data(),
        collections: collections,
        exportedAt: DateTime.now(),
      ));
    } on FirebaseException catch (e, st) {
      return Result.failure(e.message ?? e.code, error: e, stackTrace: st);
    } catch (e, st) {
      return Result.failure(e.toString(), error: e, stackTrace: st);
    }
  }
}
