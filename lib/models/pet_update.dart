import 'package:cloud_firestore/cloud_firestore.dart';

class PetUpdate {
  final String id;
  final String petId;
  final String userId;
  final String userName;
  final String? imageUrl;
  final String? caption;
  final DateTime createdAt;

  const PetUpdate({
    required this.id,
    required this.petId,
    required this.userId,
    required this.userName,
    this.imageUrl,
    this.caption,
    required this.createdAt,
  });

  factory PetUpdate.fromMap(String id, Map<String, dynamic> map) => PetUpdate(
        id: id,
        petId: map['petId'] ?? '',
        userId: map['userId'] ?? '',
        userName: map['userName'] ?? '',
        imageUrl: map['imageUrl'] as String?,
        caption: map['caption'] as String?,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'petId': petId,
        'userId': userId,
        'userName': userName,
        'imageUrl': imageUrl,
        'caption': caption,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
