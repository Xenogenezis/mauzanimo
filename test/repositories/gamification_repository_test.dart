import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/models/user_gamification.dart';
import 'package:stray_pets_mu/repositories/gamification_repository.dart';
import 'package:stray_pets_mu/utils/result.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  late GamificationRepository repository;
  late MockFirebaseFirestore mockFirestore;
  late MockDocumentReference mockUserDocRef;
  late MockCollectionReference mockUserCollection;
  late MockCollectionReference mockHistoryCollection;
  late MockDocumentReference mockHistoryDocRef;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockUserDocRef = MockDocumentReference();
    mockUserCollection = MockCollectionReference();
    mockHistoryCollection = MockCollectionReference();
    mockHistoryDocRef = MockDocumentReference();
    repository = GamificationRepository(firestore: mockFirestore);

    // Common setup
    when(() => mockFirestore.collection('user_gamification'))
        .thenReturn(mockUserCollection);
    when(() => mockUserCollection.doc(any())).thenReturn(mockUserDocRef);
    when(() => mockUserDocRef.collection('impact_history'))
        .thenReturn(mockHistoryCollection);
    when(() => mockHistoryCollection.doc(any())).thenReturn(mockHistoryDocRef);
  });

  group('GamificationRepository getOrCreateUserGamification Tests', () {
    test('should return existing user gamification', () async {
      // Arrange
      final mockSnapshot = MockDocumentSnapshot();
      final existingData = {
        'totalPoints': 500,
        'tier': 'supporter',
        'recentActions': [],
        'certificates': [],
        'showOnLeaderboard': true,
        'leaderboardRank': 5,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      when(() => mockUserDocRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn(existingData);

      // Act
      final result = await repository.getOrCreateUserGamification('user123');

      // Assert
      expect(result.isSuccess, true);
      expect(result.dataOrNull, isA<UserGamification>());
      expect(result.dataOrNull?.totalPoints, 500);
      expect(result.dataOrNull?.tier, MembershipTier.supporter);
    });

    test('should create new user gamification when not exists', () async {
      // Arrange
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockUserDocRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockUserDocRef.set(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.getOrCreateUserGamification('user123');

      // Assert
      expect(result.isSuccess, true);
      expect(result.dataOrNull, isA<UserGamification>());
      expect(result.dataOrNull?.totalPoints, 0);
      expect(result.dataOrNull?.tier, MembershipTier.supporter);
      verify(() => mockUserDocRef.set(any(that: isMap))).called(1);
    });

    test('should return failure on FirebaseException', () async {
      // Arrange
      when(() => mockUserDocRef.get()).thenThrow(
        FirebaseException(
          plugin: 'firestore',
          code: 'permission-denied',
          message: 'Permission denied',
        ),
      );

      // Act
      final result = await repository.getOrCreateUserGamification('user123');

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, contains('Permission denied'));
    });
  });

  group('GamificationRepository getUserGamificationStream Tests', () {
    test('should return result', () {
      // Act
      final result = repository.getUserGamificationStream('user123');

      // Assert - just verify a Result is returned
      expect(result, isA<Result<Stream<UserGamification?>>>());
    });
  });

  group('GamificationRepository toggleLeaderboardVisibility Tests', () {
    test('should toggle visibility to true', () async {
      // Arrange
      when(() => mockUserDocRef.update(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.toggleLeaderboardVisibility('user123', true);

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockUserDocRef.update(any(that: isMap))).called(1);
    });

    test('should toggle visibility to false', () async {
      // Arrange
      when(() => mockUserDocRef.update(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.toggleLeaderboardVisibility('user123', false);

      // Assert
      expect(result.isSuccess, true);
    });

    test('should return failure on FirebaseException', () async {
      // Arrange
      when(() => mockUserDocRef.update(any())).thenThrow(
        FirebaseException(
          plugin: 'firestore',
          code: 'not-found',
          message: 'Document not found',
        ),
      );

      // Act
      final result = await repository.toggleLeaderboardVisibility('user123', true);

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, contains('Document not found'));
    });
  });

  group('GamificationRepository getLeaderboard Tests', () {
    test('should return failure on FirebaseException (missing index)', () async {
      // Arrange
      when(() => mockUserCollection.where('showOnLeaderboard', isEqualTo: true))
          .thenThrow(
        FirebaseException(
          plugin: 'firestore',
          code: 'failed-precondition',
          message: 'The query requires an index',
        ),
      );

      // Act
      final result = await repository.getLeaderboard();

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('GamificationRepository markWeeklySummaryViewed Tests', () {
    test('should mark weekly summary as viewed', () async {
      // Arrange
      when(() => mockUserDocRef.update(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.markWeeklySummaryViewed('user123');

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockUserDocRef.update(any(that: isMap))).called(1);
    });

    test('should return failure on error', () async {
      // Arrange
      when(() => mockUserDocRef.update(any())).thenThrow(Exception('Network error'));

      // Act
      final result = await repository.markWeeklySummaryViewed('user123');

      // Assert
      expect(result.isFailure, true);
    });
  });

  group('StringExtension capitalize Tests', () {
    test('should capitalize first letter', () {
      expect('hello'.capitalize(), 'Hello');
      expect('world'.capitalize(), 'World');
    });

    test('should handle empty string', () {
      expect(''.capitalize(), '');
    });

    test('should handle single character', () {
      expect('a'.capitalize(), 'A');
    });

    test('should handle already capitalized', () {
      expect('Hello'.capitalize(), 'Hello');
    });
  });
}
