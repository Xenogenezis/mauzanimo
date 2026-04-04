import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Membership tiers based on total impact points
enum MembershipTier {
  supporter, // 0-999 points
  advocate, // 1,000-4,999 points
  champion, // 5,000-9,999 points
  guardian, // 10,000+ points
}

/// Actions that earn impact points
enum ImpactAction {
  listPet, // +50 points
  completeAdoption, // +100 points
  attendEvent, // +25 points
  shareStory, // +30 points
  volunteerHour, // +40 points
  reportLostFound, // +20 points
}

/// Record of a single impact action
class ImpactRecord {
  final String id;
  final ImpactAction action;
  final int points;
  final DateTime timestamp;
  final String? description;
  final String? relatedEntityId;

  const ImpactRecord({
    required this.id,
    required this.action,
    required this.points,
    required this.timestamp,
    this.description,
    this.relatedEntityId,
  });

  factory ImpactRecord.fromMap(String id, Map<String, dynamic> map) {
    return ImpactRecord(
      id: id,
      action: _parseImpactAction(map['action'] as String?),
      points: (map['points'] as num?)?.toInt() ?? 0,
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      description: map['description'] as String?,
      relatedEntityId: map['relatedEntityId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action.name,
      'points': points,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
      'relatedEntityId': relatedEntityId,
    };
  }

  ImpactRecord copyWith({
    String? id,
    ImpactAction? action,
    int? points,
    DateTime? timestamp,
    String? description,
    String? relatedEntityId,
  }) {
    return ImpactRecord(
      id: id ?? this.id,
      action: action ?? this.action,
      points: points ?? this.points,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
    );
  }

  static ImpactAction _parseImpactAction(String? value) {
    return ImpactAction.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ImpactAction.listPet,
    );
  }
}

/// Certificate earned by user for achievements
class Certificate {
  final String id;
  final String title;
  final String description;
  final DateTime earnedAt;
  final String? shareableImageUrl;

  const Certificate({
    required this.id,
    required this.title,
    required this.description,
    required this.earnedAt,
    this.shareableImageUrl,
  });

  factory Certificate.fromMap(String id, Map<String, dynamic> map) {
    return Certificate(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      earnedAt: map['earnedAt'] != null
          ? (map['earnedAt'] as Timestamp).toDate()
          : DateTime.now(),
      shareableImageUrl: map['shareableImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'shareableImageUrl': shareableImageUrl,
    };
  }

  Certificate copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? earnedAt,
    String? shareableImageUrl,
  }) {
    return Certificate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      earnedAt: earnedAt ?? this.earnedAt,
      shareableImageUrl: shareableImageUrl ?? this.shareableImageUrl,
    );
  }
}

/// Weekly summary of user's impact
class WeeklySummary {
  final DateTime weekStarting;
  final int pointsEarned;
  final int actionsCount;
  final List<String> highlights;

  const WeeklySummary({
    required this.weekStarting,
    required this.pointsEarned,
    required this.actionsCount,
    required this.highlights,
  });

  factory WeeklySummary.fromMap(Map<String, dynamic> map) {
    return WeeklySummary(
      weekStarting: map['weekStarting'] != null
          ? (map['weekStarting'] as Timestamp).toDate()
          : DateTime.now(),
      pointsEarned: (map['pointsEarned'] as num?)?.toInt() ?? 0,
      actionsCount: (map['actionsCount'] as num?)?.toInt() ?? 0,
      highlights: (map['highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekStarting': Timestamp.fromDate(weekStarting),
      'pointsEarned': pointsEarned,
      'actionsCount': actionsCount,
      'highlights': highlights,
    };
  }

  WeeklySummary copyWith({
    DateTime? weekStarting,
    int? pointsEarned,
    int? actionsCount,
    List<String>? highlights,
  }) {
    return WeeklySummary(
      weekStarting: weekStarting ?? this.weekStarting,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      actionsCount: actionsCount ?? this.actionsCount,
      highlights: highlights ?? this.highlights,
    );
  }
}

/// Main gamification model for user impact tracking
class UserGamification {
  final String userId;
  final int totalPoints;
  final MembershipTier tier;
  final List<ImpactRecord> recentActions;
  final List<Certificate> certificates;
  final WeeklySummary? lastWeekSummary;
  final DateTime? weeklySummaryViewedAt;
  final bool showOnLeaderboard;
  final int leaderboardRank;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserGamification({
    required this.userId,
    this.totalPoints = 0,
    this.tier = MembershipTier.supporter,
    this.recentActions = const [],
    this.certificates = const [],
    this.lastWeekSummary,
    this.weeklySummaryViewedAt,
    this.showOnLeaderboard = false,
    this.leaderboardRank = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserGamification.fromMap(String userId, Map<String, dynamic> map) {
    return UserGamification(
      userId: userId,
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
      tier: _parseMembershipTier(map['tier'] as String?),
      recentActions: (map['recentActions'] as List<dynamic>?)
              ?.map((e) => ImpactRecord.fromMap(
                    e['id'] as String? ?? '',
                    e as Map<String, dynamic>,
                  ))
              .toList() ??
          [],
      certificates: (map['certificates'] as List<dynamic>?)
              ?.map((e) => Certificate.fromMap(
                    e['id'] as String? ?? '',
                    e as Map<String, dynamic>,
                  ))
              .toList() ??
          [],
      lastWeekSummary: map['lastWeekSummary'] != null
          ? WeeklySummary.fromMap(map['lastWeekSummary'] as Map<String, dynamic>)
          : null,
      weeklySummaryViewedAt: map['weeklySummaryViewedAt'] != null
          ? (map['weeklySummaryViewedAt'] as Timestamp).toDate()
          : null,
      showOnLeaderboard: map['showOnLeaderboard'] ?? false,
      leaderboardRank: (map['leaderboardRank'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPoints': totalPoints,
      'tier': tier.name,
      'recentActions': recentActions.map((e) => {...e.toMap(), 'id': e.id}).toList(),
      'certificates': certificates.map((e) => {...e.toMap(), 'id': e.id}).toList(),
      'lastWeekSummary': lastWeekSummary?.toMap(),
      'weeklySummaryViewedAt': weeklySummaryViewedAt != null
          ? Timestamp.fromDate(weeklySummaryViewedAt!)
          : null,
      'showOnLeaderboard': showOnLeaderboard,
      'leaderboardRank': leaderboardRank,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserGamification copyWith({
    String? userId,
    int? totalPoints,
    MembershipTier? tier,
    List<ImpactRecord>? recentActions,
    List<Certificate>? certificates,
    WeeklySummary? lastWeekSummary,
    DateTime? weeklySummaryViewedAt,
    bool? showOnLeaderboard,
    int? leaderboardRank,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserGamification(
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      tier: tier ?? this.tier,
      recentActions: recentActions ?? this.recentActions,
      certificates: certificates ?? this.certificates,
      lastWeekSummary: lastWeekSummary ?? this.lastWeekSummary,
      weeklySummaryViewedAt: weeklySummaryViewedAt ?? this.weeklySummaryViewedAt,
      showOnLeaderboard: showOnLeaderboard ?? this.showOnLeaderboard,
      leaderboardRank: leaderboardRank ?? this.leaderboardRank,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Calculate tier based on points
  static MembershipTier calculateTier(int points) {
    if (points >= 10000) return MembershipTier.guardian;
    if (points >= 5000) return MembershipTier.champion;
    if (points >= 1000) return MembershipTier.advocate;
    return MembershipTier.supporter;
  }

  /// Points needed to reach next tier
  int get pointsToNextTier {
    switch (tier) {
      case MembershipTier.supporter:
        return 1000 - totalPoints;
      case MembershipTier.advocate:
        return 5000 - totalPoints;
      case MembershipTier.champion:
        return 10000 - totalPoints;
      case MembershipTier.guardian:
        return 0;
    }
  }

  /// Progress to next tier (0.0 to 1.0)
  double get tierProgress {
    final tierMinMax = _getTierMinMax();
    if (tier == MembershipTier.guardian) return 1.0;
    final range = tierMinMax.$2 - tierMinMax.$1;
    final progress = totalPoints - tierMinMax.$1;
    return (progress / range).clamp(0.0, 1.0);
  }

  (int, int) _getTierMinMax() {
    switch (tier) {
      case MembershipTier.supporter:
        return (0, 1000);
      case MembershipTier.advocate:
        return (1000, 5000);
      case MembershipTier.champion:
        return (5000, 10000);
      case MembershipTier.guardian:
        return (10000, 10000);
    }
  }

  /// Get points value for an action
  static int pointsForAction(ImpactAction action) {
    switch (action) {
      case ImpactAction.listPet:
        return 50;
      case ImpactAction.completeAdoption:
        return 100;
      case ImpactAction.attendEvent:
        return 25;
      case ImpactAction.shareStory:
        return 30;
      case ImpactAction.volunteerHour:
        return 40;
      case ImpactAction.reportLostFound:
        return 20;
    }
  }

  /// Display name for current tier
  String get tierDisplayName {
    switch (tier) {
      case MembershipTier.supporter:
        return 'Supporter';
      case MembershipTier.advocate:
        return 'Advocate';
      case MembershipTier.champion:
        return 'Champion';
      case MembershipTier.guardian:
        return 'Guardian';
    }
  }

  /// Color associated with current tier
  Color get tierColor {
    switch (tier) {
      case MembershipTier.supporter:
        return const Color(0xFF8B7355); // Bronze
      case MembershipTier.advocate:
        return const Color(0xFF2A9D8F); // Primary teal
      case MembershipTier.champion:
        return const Color(0xFFE9C46A); // Gold
      case MembershipTier.guardian:
        return const Color(0xFF264653); // Dark blue
    }
  }

  static MembershipTier _parseMembershipTier(String? value) {
    return MembershipTier.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MembershipTier.supporter,
    );
  }
}
