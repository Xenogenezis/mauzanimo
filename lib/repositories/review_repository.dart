import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';
import '../utils/result.dart';

class ReviewRepository {
  final FirebaseFirestore _firestore;
  ReviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Result<void>> addReview(Review review) async {
    try {
      await _firestore.collection('reviews').add(review.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Firestore error', error: e);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }

  Result<Stream<List<Review>>> getReviewsForUser(String userId) {
    try {
      final stream = _firestore
          .collection('reviews')
          .where('targetUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => Review.fromMap(d.id, d.data())).toList());
      return Result.success(stream);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }
}
