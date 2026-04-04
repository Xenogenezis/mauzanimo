import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_gamification.dart';
import '../utils/result.dart';

/// Extension method to capitalize a string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

/// Repository for gamification-related Firestore operations
class GamificationRepository {
  final FirebaseFirestore _firestore;

  GamificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection name for user gamification data
  static const String _collectionName = 'user_gamification';

  /// Sub-collection name for impact history
  static const String _impactHistoryCollection = 'impact_history';

  /// Get or create user gamification record
  Future<Result<UserGamification>> getOrCreateUserGamification(String userId) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(userId);
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        return Result.success(
          UserGamification.fromMap(userId, doc.data()!),
        );
      }

      // Create new user gamification record
      final now = DateTime.now();
      final newGamification = UserGamification(
        userId: userId,
        totalPoints: 0,
        tier: MembershipTier.supporter,
        recentActions: const [],
        certificates: const [],
        showOnLeaderboard: false,
        leaderboardRank: 0,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set({
        ...newGamification.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(newGamification);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to get or create gamification data: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to get or create gamification data. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get user gamification stream for real-time updates
  Result<Stream<UserGamification?>> getUserGamificationStream(String userId) {
    try {
      final stream = _firestore
          .collection(_collectionName)
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return null;
        }
        return UserGamification.fromMap(userId, snapshot.data()!);
      });

      return Result.success(stream);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load gamification stream. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Record an impact action and award points
  /// Uses Firestore transaction for atomic updates
  Future<Result<ImpactRecord>> recordAction(
    String userId,
    ImpactAction action, {
    String? description,
    String? relatedEntityId,
  }) async {
    try {
      final points = UserGamification.pointsForAction(action);
      final actionId = _firestore.collection(_collectionName).doc().id;
      final now = DateTime.now();

      final impactRecord = ImpactRecord(
        id: actionId,
        action: action,
        points: points,
        timestamp: now,
        description: description,
        relatedEntityId: relatedEntityId,
      );

      final userRef = _firestore.collection(_collectionName).doc(userId);
      final historyRef = userRef.collection(_impactHistoryCollection).doc(actionId);

      await _firestore.runTransaction((transaction) async {
        // Read current user data
        final userDoc = await transaction.get(userRef);

        int currentPoints = 0;
        MembershipTier currentTier = MembershipTier.supporter;
        List<Certificate> currentCertificates = [];

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          currentPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
          currentTier = UserGamification.calculateTier(currentPoints);
          currentCertificates = (data['certificates'] as List<dynamic>?)
                  ?.map((e) => Certificate.fromMap(
                        e['id'] as String? ?? '',
                        e as Map<String, dynamic>,
                      ))
                  .toList() ??
              [];
        }

        // Calculate new points and tier
        final newPoints = currentPoints + points;
        final newTier = UserGamification.calculateTier(newPoints);

        // Check for tier upgrade
        List<Certificate> updatedCertificates = currentCertificates;
        if (newTier != currentTier) {
          // Award certificate for tier upgrade
          final certificateId = _firestore.collection(_collectionName).doc().id;
          final certificate = Certificate(
            id: certificateId,
            title: '${newTier.name.capitalize()} Member',
            description: 'Reached ${newTier.name.capitalize()} tier with $newPoints points!',
            earnedAt: now,
          );
          updatedCertificates = [...currentCertificates, certificate];
        }

        // Prepare update data
        final updateData = {
          'totalPoints': newPoints,
          'tier': newTier.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'certificates': updatedCertificates
              .map((c) => {...c.toMap(), 'id': c.id})
              .toList(),
        };

        // Update recent actions
        final recentActionsData = {
          ...impactRecord.toMap(),
          'id': actionId,
        };

        if (userDoc.exists) {
          transaction.update(userRef, {
            ...updateData,
            'recentActions': FieldValue.arrayUnion([recentActionsData]),
          });
        } else {
          transaction.set(userRef, {
            ...updateData,
            'userId': userId,
            'recentActions': [recentActionsData],
            'showOnLeaderboard': false,
            'leaderboardRank': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Add to impact history sub-collection
        transaction.set(historyRef, {
          ...impactRecord.toMap(),
          'userId': userId,
        });
      });

      return Result.success(impactRecord);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to record action: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to record action. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get paginated impact history
  Future<Result<List<ImpactRecord>>> getImpactHistory(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .doc(userId)
          .collection(_impactHistoryCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final records = snapshot.docs.map((doc) {
        return ImpactRecord.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();

      return Result.success(records);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to load impact history: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load impact history. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Toggle leaderboard visibility
  Future<Result<void>> toggleLeaderboardVisibility(String userId, bool visible) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'showOnLeaderboard': visible,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to update leaderboard visibility: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to update leaderboard visibility. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get leaderboard (only users who opted in)
  Future<Result<List<UserGamification>>> getLeaderboard({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('showOnLeaderboard', isEqualTo: true)
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      final leaderboard = snapshot.docs.map((doc) {
        return UserGamification.fromMap(doc.id, doc.data());
      }).toList();

      return Result.success(leaderboard);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to load leaderboard: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load leaderboard. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Mark weekly summary as viewed
  Future<Result<void>> markWeeklySummaryViewed(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).update({
        'weeklySummaryViewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Result.success(null);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to mark weekly summary as viewed: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to mark weekly summary as viewed. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
