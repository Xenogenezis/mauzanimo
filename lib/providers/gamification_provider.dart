import 'package:flutter/material.dart';
import '../repositories/gamification_repository.dart';
import '../models/user_gamification.dart';
import '../utils/result.dart';

/// Provider for gamification state management
/// Wraps GamificationRepository and exposes user gamification data
class GamificationProvider extends ChangeNotifier {
  // Dependencies
  final GamificationRepository _repository;
  final String? _userId;

  // State
  UserGamification? _gamification;
  bool _isLoading = false;
  String? _error;

  /// Constructor requires repository and optional userId
  GamificationProvider(this._repository, {String? userId}) : _userId = userId;

  // ==================== GETTERS ====================

  /// Current gamification data
  UserGamification? get gamification => _gamification;

  /// Whether data is currently loading
  bool get isLoading => _isLoading;

  /// Error message if last operation failed
  String? get error => _error;

  /// Whether gamification data has been loaded
  bool get hasData => _gamification != null;

  /// Total impact points earned
  int get totalPoints => _gamification?.totalPoints ?? 0;

  /// Current membership tier
  MembershipTier get tier => _gamification?.tier ?? MembershipTier.supporter;

  /// Progress to next tier (0.0 to 1.0)
  double get tierProgress => _gamification?.tierProgress ?? 0.0;

  /// Points needed to reach next tier
  int get pointsToNextTier => _gamification?.pointsToNextTier ?? 1000;

  /// List of earned certificates
  List<Certificate> get certificates => _gamification?.certificates ?? [];

  /// Recent impact actions (last 10)
  List<ImpactRecord> get recentActions => _gamification?.recentActions ?? [];

  /// Whether user appears on leaderboard
  bool get showOnLeaderboard => _gamification?.showOnLeaderboard ?? false;

  /// Whether weekly summary should be shown to user
  bool get shouldShowWeeklySummary {
    if (_gamification?.lastWeekSummary == null) return false;
    final viewedAt = _gamification?.weeklySummaryViewedAt;
    if (viewedAt == null) return true;
    final daysSinceViewed = DateTime.now().difference(viewedAt).inDays;
    return daysSinceViewed >= 7;
  }

  // ==================== METHODS ====================

  /// Load gamification data for the current user
  /// Call this after user authentication
  Future<void> loadGamification() async {
    final userId = _userId;
    if (userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getOrCreateUserGamification(userId);

    result.when(
      success: (gamification) {
        _gamification = gamification;
        _isLoading = false;
        notifyListeners();
      },
      failure: (message) {
        _error = message;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Record an impact action and award points
  /// Returns true on success, false on failure
  Future<bool> recordAction(
    ImpactAction action, {
    String? description,
    String? relatedEntityId,
  }) async {
    final userId = _userId;
    if (userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.recordAction(
      userId,
      action,
      description: description,
      relatedEntityId: relatedEntityId,
    );

    final success = result.when(
      success: (_) {
        _isLoading = false;
        return true;
      },
      failure: (message) {
        _error = message;
        _isLoading = false;
        return false;
      },
    );

    // Reload gamification data after successful action
    if (success) {
      await loadGamification();
    } else {
      notifyListeners();
    }

    return success;
  }

  /// Toggle leaderboard visibility
  /// Optimistically updates local state before API call
  Future<bool> toggleLeaderboardVisibility(bool visible) async {
    final userId = _userId;
    if (userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    // Optimistically update local state
    if (_gamification != null) {
      _gamification = _gamification!.copyWith(showOnLeaderboard: visible);
      notifyListeners();
    }

    _error = null;

    final result = await _repository.toggleLeaderboardVisibility(userId, visible);

    return result.when(
      success: (_) {
        return true;
      },
      failure: (message) {
        // Revert optimistic update on failure
        if (_gamification != null) {
          _gamification = _gamification!.copyWith(showOnLeaderboard: !visible);
        }
        _error = message;
        notifyListeners();
        return false;
      },
    );
  }

  /// Mark weekly summary as viewed
  Future<void> markWeeklySummaryViewed() async {
    final userId = _userId;
    if (userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    _error = null;

    final result = await _repository.markWeeklySummaryViewed(userId);

    result.when(
      success: (_) {
        // Update local state
        if (_gamification != null) {
          _gamification = _gamification!.copyWith(
            weeklySummaryViewedAt: DateTime.now(),
          );
        }
        notifyListeners();
      },
      failure: (message) {
        _error = message;
        notifyListeners();
      },
    );
  }

  /// Clear any error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh gamification data from repository
  /// Alias for loadGamification()
  Future<void> refresh() async {
    await loadGamification();
  }
}
