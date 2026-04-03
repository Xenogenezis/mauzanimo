import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_found.dart';
import '../utils/result.dart';

class LostFoundRepository {
  final FirebaseFirestore _firestore;

  LostFoundRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all lost & found reports as a stream with optional type filter
  Result<Stream<List<LostFound>>> getLostFoundStream({String? typeFilter}) {
    try {
      Query query = _firestore
          .collection('lostfound')
          .orderBy('createdAt', descending: true);

      if (typeFilter != null && typeFilter != 'All') {
        query = query.where('type', isEqualTo: typeFilter);
      }

      final stream = query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return LostFound.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      });

      return Result.success(stream);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load reports. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Add a new lost/found report
  Future<Result<void>> addLostFound(LostFound report) async {
    try {
      await _firestore.collection('lostfound').add({
        ...report.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to add report: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to add report. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update an existing report
  Future<Result<void>> updateLostFound(LostFound report) async {
    try {
      await _firestore.collection('lostfound').doc(report.id).update(report.toMap());
      return Result.success(null);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to update report: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to update report. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete a report
  Future<Result<void>> deleteLostFound(String id) async {
    try {
      await _firestore.collection('lostfound').doc(id).delete();
      return Result.success(null);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to delete report: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to delete report. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get a single report by ID
  Future<Result<LostFound?>> getLostFoundById(String id) async {
    try {
      final doc = await _firestore.collection('lostfound').doc(id).get();
      if (!doc.exists) return Result.success(null);
      return Result.success(
        LostFound.fromMap(doc.id, doc.data() as Map<String, dynamic>),
      );
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to load report: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load report. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get reports by user ID (server-side query)
  Result<Stream<List<LostFound>>> getUserReportsStream(String userId) {
    try {
      final stream = _firestore
          .collection('lostfound')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return LostFound.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      });

      return Result.success(stream);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load your reports. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Search reports by location or description
  /// Note: Firestore doesn't support full-text search natively.
  Future<Result<List<LostFound>>> searchReports(String query) async {
    try {
      final snapshot = await _firestore.collection('lostfound').get();
      final searchLower = query.toLowerCase();

      final results = snapshot.docs
          .map((doc) => LostFound.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .where((report) =>
              report.description.toLowerCase().contains(searchLower) ||
              report.location.toLowerCase().contains(searchLower) ||
              report.animalType.toLowerCase().contains(searchLower))
          .toList();

      return Result.success(results);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Search failed: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Search failed. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
