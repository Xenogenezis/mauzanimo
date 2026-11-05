// Append-only audit trail of writes made from the web admin.
//
// Entries go to the `admin_audit` collection. firestore.rules only lets an
// admin create an entry for themselves (actorUid == auth.uid, at == server
// time) and nobody can update or delete one, so the log can't be rewritten
// from a client. Logging is best effort: it never throws, so a failed audit
// write can't break (or roll back) the admin action it describes.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

const auditCollection = 'admin_audit';

// Field limits, mirrored from firestore.rules.
const auditActionMax = 64;
const auditCollectionMax = 64;
const auditDocIdMax = 128;
const auditSummaryMax = 500;

/// Builds the audit document for [actorUid]. Strings are clipped to the
/// limits enforced by firestore.rules so a long summary doesn't get the whole
/// entry rejected. Exposed for tests.
@visibleForTesting
Map<String, Object> buildAuditEntry({
  required String actorUid,
  required String action,
  required String collection,
  required String docId,
  String? summary,
  Object? at,
}) {
  final s = summary?.trim();
  return {
    'actorUid': actorUid,
    'action': _clip(action, auditActionMax),
    'collection': _clip(collection, auditCollectionMax),
    'docId': _clip(docId, auditDocIdMax),
    if (s != null && s.isNotEmpty) 'summary': _clip(s, auditSummaryMax),
    'at': at ?? FieldValue.serverTimestamp(),
  };
}

String _clip(String v, int max) => v.length <= max ? v : v.substring(0, max);

/// Records that the signed-in admin performed [action] on
/// `[collection]/[docId]`. Never throws; failures are only printed.
///
/// Call it *after* the write succeeded. It is safe to not await it.
Future<void> logAdminAction({
  required String action,
  required String collection,
  required String docId,
  String? summary,
  FirebaseFirestore? firestore,
  FirebaseAuth? auth,
}) async {
  try {
    final uid = (auth ?? FirebaseAuth.instance).currentUser?.uid;
    if (uid == null) {
      debugPrint('admin audit skipped (signed out): $action $collection/$docId');
      return;
    }
    await (firestore ?? FirebaseFirestore.instance).collection(auditCollection).add(buildAuditEntry(
          actorUid: uid,
          action: action,
          collection: collection,
          docId: docId,
          summary: summary,
        ));
  } catch (e) {
    debugPrint('admin audit write failed for $action $collection/$docId: $e');
  }
}
