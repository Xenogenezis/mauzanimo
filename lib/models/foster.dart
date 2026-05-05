import 'package:cloud_firestore/cloud_firestore.dart';

class Foster {
  final String id;
  final String petId;
  final String petName;
  final String fosterUserId;
  final String fosterUserName;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String? notes;
  final DateTime createdAt;

  const Foster({
    required this.id,
    required this.petId,
    required this.petName,
    required this.fosterUserId,
    required this.fosterUserName,
    required this.startDate,
    this.endDate,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
  });

  factory Foster.fromMap(String id, Map<String, dynamic> map) => Foster(
        id: id,
        petId: map['petId'] ?? '',
        petName: map['petName'] ?? '',
        fosterUserId: map['fosterUserId'] ?? '',
        fosterUserName: map['fosterUserName'] ?? '',
        startDate: (map['startDate'] as Timestamp).toDate(),
        endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
        status: map['status'] ?? 'pending',
        notes: map['notes'] as String?,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'petId': petId,
        'petName': petName,
        'fosterUserId': fosterUserId,
        'fosterUserName': fosterUserName,
        'startDate': FieldValue.serverTimestamp(),
        'endDate': endDate,
        'status': status,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
