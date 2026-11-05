import 'package:cloud_firestore/cloud_firestore.dart';

/// An in-app notification (`notifications/{id}`).
///
/// No title or body is stored: the reader builds localised text from
/// [type] + [params] (see `notificationTitle` / `notificationBody`).
class AppNotification {
  static const String typeAdoptionStage = 'adoption_stage';
  static const String typeSighting = 'sighting';

  final String id;
  final String toUid;
  final String type;
  final Map<String, String> params;
  final String refCollection;
  final String refId;
  final String fromUid;
  final bool read;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.toUid,
    required this.type,
    this.params = const {},
    required this.refCollection,
    required this.refId,
    this.fromUid = '',
    this.read = false,
    this.createdAt,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    final raw = map['params'];
    final ts = map['createdAt'];
    return AppNotification(
      id: id,
      toUid: map['toUid'] as String? ?? '',
      type: map['type'] as String? ?? '',
      params: raw is Map
          ? {for (final e in raw.entries) '${e.key}': '${e.value ?? ''}'}
          : const {},
      refCollection: map['refCollection'] as String? ?? '',
      refId: map['refId'] as String? ?? '',
      fromUid: map['fromUid'] as String? ?? '',
      read: map['read'] as bool? ?? false,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  /// Map for a new document. Rules require `read == false` and
  /// `createdAt == request.time`.
  Map<String, dynamic> toCreateMap() => {
        'toUid': toUid,
        'type': type,
        'params': params,
        'refCollection': refCollection,
        'refId': refId,
        'fromUid': fromUid,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        toUid: toUid,
        type: type,
        params: params,
        refCollection: refCollection,
        refId: refId,
        fromUid: fromUid,
        read: read ?? this.read,
        createdAt: createdAt,
      );

  /// Newest first; pending server timestamps (null) count as newest.
  static List<AppNotification> sortNewestFirst(Iterable<AppNotification> items) {
    final out = items.toList();
    final far = DateTime(9999);
    out.sort((a, b) => (b.createdAt ?? far).compareTo(a.createdAt ?? far));
    return out;
  }
}
