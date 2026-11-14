import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// What account deletion does with a user's documents in one collection.
enum AccountDataAction {
  /// Delete every document the user owns (rules allow owner delete).
  delete,

  /// Overwrite identifying fields; the rules allow owner update but not
  /// owner delete.
  anonymise,

  /// Set `status: cancelled` (the only owner change the rules allow).
  cancel,

  /// Keep untouched: the rules give the owner no update/delete rights, and
  /// the records matter for animal-welfare follow-up.
  keep,
}

/// One collection the user owns documents in, and how deletion treats it.
class AccountCollectionPlan {
  final String collection;

  /// Field holding the owner's uid, or null when the doc id is the uid.
  final String? ownerField;
  final AccountDataAction action;

  /// For [AccountDataAction.anonymise]: the fields to overwrite.
  final Map<String, Object?> anonymisedFields;

  /// Subcollections under the user's doc to delete (doc-id-owned only).
  final List<String> subcollections;

  /// For cancel/anonymise: try a real delete first and fall back to
  /// [action] only when the rules deny it (so a later rules change that
  /// allows owner delete makes erasure complete without an app update).
  final bool deleteIfAllowed;

  const AccountCollectionPlan(
    this.collection,
    this.ownerField,
    this.action, {
    this.anonymisedFields = const {},
    this.subcollections = const [],
    this.deleteIfAllowed = false,
  });

  bool get keyedByUid => ownerField == null;
}

/// The deletion plan, in execution order. `users/{uid}` comes last so the
/// rules (which may look the user up) still work for the earlier steps.
///
/// Mirrors firestore.rules: change both together.
const List<AccountCollectionPlan> accountDeletionPlan = [
  AccountCollectionPlan('pets', 'uploadedBy', AccountDataAction.delete),
  AccountCollectionPlan('lostfound', 'userId', AccountDataAction.delete),
  AccountCollectionPlan('sightings', 'reporterId', AccountDataAction.delete),
  AccountCollectionPlan('favourites', 'userId', AccountDataAction.delete),
  AccountCollectionPlan('stories', 'userId', AccountDataAction.delete),
  AccountCollectionPlan('pet_updates', 'userId', AccountDataAction.delete),
  // Rules: owners may only cancel; admins can purge.
  AccountCollectionPlan('event_registrations', 'userId', AccountDataAction.cancel,
      deleteIfAllowed: true),
  // Rules: owner may update the doc and delete its history; delete of the
  // doc itself is admin-only in the block (but see report).
  AccountCollectionPlan('user_gamification', null, AccountDataAction.anonymise,
      deleteIfAllowed: true,
      anonymisedFields: {
        'showOnLeaderboard': false,
        'recentActions': <Object?>[],
        'certificates': <Object?>[],
        'lastWeekSummary': null,
      },
      subcollections: ['impact_history']),
  // Welfare records: only admins may change them.
  AccountCollectionPlan('adoptions', 'adopterId', AccountDataAction.keep),
  AccountCollectionPlan('fosters', 'fosterUserId', AccountDataAction.keep),
  AccountCollectionPlan('inquiries', 'userId', AccountDataAction.keep),
  AccountCollectionPlan('rescue_reports', 'reporterId', AccountDataAction.keep),
  // Rescue phone notifications: the rescuer's area and device tokens.
  AccountCollectionPlan('rescue_subscribers', null, AccountDataAction.delete),
  AccountCollectionPlan('users', null, AccountDataAction.delete),
];

/// Collections included in "Download my data" (besides the profile).
const List<AccountCollectionPlan> accountExportPlan = [
  // Rescue phone notifications: the area the rescuer chose and device tokens.
  AccountCollectionPlan('rescue_subscribers', null, AccountDataAction.keep),
  AccountCollectionPlan('pets', 'uploadedBy', AccountDataAction.keep),
  AccountCollectionPlan('lostfound', 'userId', AccountDataAction.keep),
  AccountCollectionPlan('sightings', 'reporterId', AccountDataAction.keep),
  AccountCollectionPlan('favourites', 'userId', AccountDataAction.keep),
  AccountCollectionPlan('adoptions', 'adopterId', AccountDataAction.keep),
  AccountCollectionPlan('fosters', 'fosterUserId', AccountDataAction.keep),
  AccountCollectionPlan('inquiries', 'userId', AccountDataAction.keep),
  AccountCollectionPlan('stories', 'userId', AccountDataAction.keep),
  AccountCollectionPlan('event_registrations', 'userId', AccountDataAction.keep),
];

/// Firestore caps a write batch at 500 operations; stay well under it.
const int accountBatchSize = 400;

/// Splits [items] into lists of at most [size].
List<List<T>> chunked<T>(List<T> items, [int size = accountBatchSize]) {
  if (size <= 0) throw ArgumentError.value(size, 'size');
  return [
    for (var i = 0; i < items.length; i += size)
      items.sublist(i, i + size > items.length ? items.length : i + size),
  ];
}

const String exportImagePlaceholder = '[image]';

final RegExp _base64Body = RegExp(r'^[A-Za-z0-9+/=\s]+$');

/// True for inline images: data URIs, or long bare base64 blobs.
bool looksLikeInlineImage(String s) {
  if (s.startsWith('data:image') || s.startsWith('data:application/octet')) {
    return true;
  }
  return s.length >= 512 && _base64Body.hasMatch(s);
}

/// Converts a Firestore value into plain JSON-encodable data, replacing
/// inline (base64) images with [exportImagePlaceholder].
Object? sanitizeForExport(Object? value) {
  if (value == null || value is bool || value is num) return value;
  if (value is String) {
    return looksLikeInlineImage(value) ? exportImagePlaceholder : value;
  }
  if (value is Timestamp) return value.toDate().toUtc().toIso8601String();
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is GeoPoint) {
    return {'latitude': value.latitude, 'longitude': value.longitude};
  }
  if (value is DocumentReference) return value.path;
  if (value is Blob) return exportImagePlaceholder;
  if (value is Map) {
    return {
      for (final e in value.entries) e.key.toString(): sanitizeForExport(e.value),
    };
  }
  if (value is Iterable) return [for (final v in value) sanitizeForExport(v)];
  return value.toString();
}

/// Builds the "Download my data" document. [collections] maps a collection
/// name to the user's docs in it, keyed by doc id.
Map<String, Object?> buildAccountExport({
  required String uid,
  String? email,
  Map<String, dynamic>? profile,
  required Map<String, Map<String, Map<String, dynamic>>> collections,
  required DateTime exportedAt,
}) {
  return {
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'app': 'MauZanimo',
    'controller': 'MauZanimo',
    'uid': uid,
    if (email != null) 'email': email,
    'profile': sanitizeForExport(profile),
    for (final plan in accountExportPlan)
      plan.collection: [
        for (final e in (collections[plan.collection] ?? const {}).entries)
          {'id': e.key, ...?(sanitizeForExport(e.value) as Map<String, Object?>?)},
      ],
  };
}

/// Pretty-printed JSON for [export].
String encodeAccountExport(Map<String, Object?> export) =>
    const JsonEncoder.withIndent('  ').convert(export);

/// File name for the export, e.g. `mauzanimo-data-2026-11-05.json`.
String accountExportFileName(DateTime when) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'mauzanimo-data-${when.year}-${two(when.month)}-${two(when.day)}.json';
}

/// Normalised check for the "type DELETE to confirm" field.
bool isDeleteConfirmation(String input) => input.trim().toUpperCase() == 'DELETE';
