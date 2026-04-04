import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/models/user_gamification.dart';

void main() {
  group('UserGamification Model Tests', () {
    group('MembershipTier calculation', () {
      test('should return supporter for 0-999 points', () {
        expect(UserGamification.calculateTier(0), MembershipTier.supporter);
        expect(UserGamification.calculateTier(500), MembershipTier.supporter);
        expect(UserGamification.calculateTier(999), MembershipTier.supporter);
      });

      test('should return advocate for 1000-4999 points', () {
        expect(UserGamification.calculateTier(1000), MembershipTier.advocate);
        expect(UserGamification.calculateTier(2500), MembershipTier.advocate);
        expect(UserGamification.calculateTier(4999), MembershipTier.advocate);
      });

      test('should return champion for 5000-9999 points', () {
        expect(UserGamification.calculateTier(5000), MembershipTier.champion);
        expect(UserGamification.calculateTier(7500), MembershipTier.champion);
        expect(UserGamification.calculateTier(9999), MembershipTier.champion);
      });

      test('should return guardian for 10000+ points', () {
        expect(UserGamification.calculateTier(10000), MembershipTier.guardian);
        expect(UserGamification.calculateTier(50000), MembershipTier.guardian);
      });
    });

    group('pointsToNextTier calculation', () {
      test('should calculate points to advocate tier correctly', () {
        final gamification = UserGamification(
          userId: 'user1',
          totalPoints: 500,
          tier: MembershipTier.supporter,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(gamification.pointsToNextTier, 500);
      });

      test('should calculate points to champion tier correctly', () {
        final gamification = UserGamification(
          userId: 'user1',
          totalPoints: 2500,
          tier: MembershipTier.advocate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(gamification.pointsToNextTier, 2500);
      });

      test('should calculate points to guardian tier correctly', () {
        final gamification = UserGamification(
          userId: 'user1',
          totalPoints: 7500,
          tier: MembershipTier.champion,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(gamification.pointsToNextTier, 2500);
      });

      test('should return 0 for guardian tier (max tier)', () {
        final gamification = UserGamification(
          userId: 'user1',
          totalPoints: 15000,
          tier: MembershipTier.guardian,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(gamification.pointsToNextTier, 0);
      });
    });

    group('tierProgress calculation', () {
      test('should calculate supporter progress correctly', () {
        final gamification = UserGamification(
          userId: 'user1',
          totalPoints: 500,
          tier: MembershipTier.supporter,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(gamification.tierProgress, 0.5);
      });

      test('should calculate advocate progress correctly', () {
        final gamification = UserGamification(
          userId: 'user1',
          totalPoints: 3000,
          tier: MembershipTier.advocate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(gamification.tierProgress, 0.5);
      });

      test('should calculate champion progress correctly', () {
        final gamification = UserGamification(
          userId: 'user1',
          totalPoints: 7500,
          tier: MembershipTier.champion,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(gamification.tierProgress, 0.5);
      });

      test('should return 1.0 for guardian tier', () {
        final gamification = UserGamification(
          userId: 'user1',
          totalPoints: 15000,
          tier: MembershipTier.guardian,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(gamification.tierProgress, 1.0);
      });
    });

    group('pointsForAction calculation', () {
      test('should return correct points for listPet', () {
        expect(UserGamification.pointsForAction(ImpactAction.listPet), 50);
      });

      test('should return correct points for completeAdoption', () {
        expect(
          UserGamification.pointsForAction(ImpactAction.completeAdoption),
          100,
        );
      });

      test('should return correct points for attendEvent', () {
        expect(UserGamification.pointsForAction(ImpactAction.attendEvent), 25);
      });

      test('should return correct points for shareStory', () {
        expect(UserGamification.pointsForAction(ImpactAction.shareStory), 30);
      });

      test('should return correct points for volunteerHour', () {
        expect(UserGamification.pointsForAction(ImpactAction.volunteerHour), 40);
      });

      test('should return correct points for reportLostFound', () {
        expect(
          UserGamification.pointsForAction(ImpactAction.reportLostFound),
          20,
        );
      });
    });

    group('fromMap/toMap serialization', () {
      test('should create UserGamification from map correctly', () {
        final timestamp = Timestamp.now();
        final map = {
          'totalPoints': 2500,
          'tier': 'advocate',
          'recentActions': [
            {
              'id': 'action1',
              'action': 'listPet',
              'points': 50,
              'timestamp': timestamp,
              'description': 'Listed a pet',
            }
          ],
          'certificates': [],
          'showOnLeaderboard': true,
          'leaderboardRank': 5,
          'createdAt': timestamp,
          'updatedAt': timestamp,
        };

        final gamification = UserGamification.fromMap('user123', map);

        expect(gamification.userId, 'user123');
        expect(gamification.totalPoints, 2500);
        expect(gamification.tier, MembershipTier.advocate);
        expect(gamification.recentActions.length, 1);
        expect(gamification.showOnLeaderboard, true);
        expect(gamification.leaderboardRank, 5);
      });

      test('should convert UserGamification to map correctly', () {
        final gamification = UserGamification(
          userId: 'user123',
          totalPoints: 1000,
          tier: MembershipTier.advocate,
          showOnLeaderboard: false,
          leaderboardRank: 10,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        final map = gamification.toMap();

        expect(map['totalPoints'], 1000);
        expect(map['tier'], 'advocate');
        expect(map['showOnLeaderboard'], false);
        expect(map['leaderboardRank'], 10);
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final original = UserGamification(
          userId: 'user1',
          totalPoints: 1000,
          tier: MembershipTier.advocate,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        final copy = original.copyWith(
          totalPoints: 1500,
          leaderboardRank: 5,
        );

        expect(copy.userId, 'user1');
        expect(copy.totalPoints, 1500);
        expect(copy.tier, MembershipTier.advocate);
        expect(copy.leaderboardRank, 5);
        expect(original.totalPoints, 1000);
        expect(original.leaderboardRank, 0);
      });
    });

    group('tierDisplayName and tierColor', () {
      test('should return correct display names', () {
        final supporter = UserGamification(
          userId: 'u1',
          totalPoints: 100,
          tier: MembershipTier.supporter,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(supporter.tierDisplayName, 'Supporter');

        final advocate = UserGamification(
          userId: 'u2',
          totalPoints: 1000,
          tier: MembershipTier.advocate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(advocate.tierDisplayName, 'Advocate');

        final champion = UserGamification(
          userId: 'u3',
          totalPoints: 5000,
          tier: MembershipTier.champion,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(champion.tierDisplayName, 'Champion');

        final guardian = UserGamification(
          userId: 'u4',
          totalPoints: 10000,
          tier: MembershipTier.guardian,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(guardian.tierDisplayName, 'Guardian');
      });

      test('should return correct tier colors', () {
        final supporter = UserGamification(
          userId: 'u1',
          totalPoints: 100,
          tier: MembershipTier.supporter,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(supporter.tierColor.value, 0xFF8B7355);

        final guardian = UserGamification(
          userId: 'u4',
          totalPoints: 10000,
          tier: MembershipTier.guardian,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(guardian.tierColor.value, 0xFF264653);
      });
    });

    group('ImpactRecord', () {
      test('should create ImpactRecord from map', () {
        final timestamp = Timestamp.now();
        final map = {
          'action': 'listPet',
          'points': 50,
          'timestamp': timestamp,
          'description': 'Test action',
        };

        final record = ImpactRecord.fromMap('rec1', map);

        expect(record.id, 'rec1');
        expect(record.action, ImpactAction.listPet);
        expect(record.points, 50);
        expect(record.description, 'Test action');
      });

      test('should convert ImpactRecord to map', () {
        final record = ImpactRecord(
          id: 'rec1',
          action: ImpactAction.completeAdoption,
          points: 100,
          timestamp: DateTime(2024, 1, 1),
          description: 'Adoption completed',
        );

        final map = record.toMap();

        expect(map['action'], 'completeAdoption');
        expect(map['points'], 100);
        expect(map['description'], 'Adoption completed');
      });
    });

    group('Certificate', () {
      test('should create Certificate from map', () {
        final timestamp = Timestamp.now();
        final map = {
          'title': 'First Pet',
          'description': 'Listed your first pet',
          'earnedAt': timestamp,
          'shareableImageUrl': 'https://example.com/cert.png',
        };

        final cert = Certificate.fromMap('cert1', map);

        expect(cert.id, 'cert1');
        expect(cert.title, 'First Pet');
        expect(cert.shareableImageUrl, 'https://example.com/cert.png');
      });
    });

    group('WeeklySummary', () {
      test('should create WeeklySummary from map', () {
        final timestamp = Timestamp.now();
        final map = {
          'weekStarting': timestamp,
          'pointsEarned': 150,
          'actionsCount': 3,
          'highlights': ['Listed a pet', 'Attended event'],
        };

        final summary = WeeklySummary.fromMap(map);

        expect(summary.pointsEarned, 150);
        expect(summary.actionsCount, 3);
        expect(summary.highlights.length, 2);
      });
    });
  });
}
