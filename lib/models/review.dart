import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String targetUserId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.targetUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> map) => Review(
        id: id,
        reviewerId: map['reviewerId'] ?? '',
        reviewerName: map['reviewerName'] ?? '',
        targetUserId: map['targetUserId'] ?? '',
        rating: (map['rating'] as num?)?.toInt() ?? 0,
        comment: map['comment'] as String?,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'targetUserId': targetUserId,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
