import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/repositories/auth_repository.dart';
import 'package:stray_pets_mu/utils/result.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late AuthRepository repository;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUserCredential mockCredential;
  late MockUser mockUser;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockCredential = MockUserCredential();
    mockUser = MockUser();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    repository = AuthRepository(auth: mockAuth, firestore: mockFirestore);

    // Common setup
    when(() => mockCredential.user).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('user123');
    when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
    when(() => mockCollection.doc(any())).thenReturn(mockDocument);
  });

  group('AuthRepository Sign In Tests', () {
    test('should return success on valid sign in', () async {
      // Arrange
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => mockCredential);

      // Act
      final result = await repository.signIn('test@example.com', 'password123');

      // Assert
      expect(result.isSuccess, true);
      expect(result.dataOrNull, isA<UserCredential>());
    });

    test('should return failure on invalid email', () async {
      // Arrange
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        ),
      );

      // Act
      final result = await repository.signIn('invalid-email', 'password123');

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, 'Invalid email address.');
    });

    test('should return failure on user not found', () async {
      // Arrange
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'user-not-found',
          message: 'There is no user record corresponding to this identifier.',
        ),
      );

      // Act
      final result = await repository.signIn('unknown@example.com', 'password123');

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, 'No account found with this email.');
    });

    test('should return failure on wrong password', () async {
      // Arrange
      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'wrong-password',
          message: 'The password is invalid.',
        ),
      );

      // Act
      final result = await repository.signIn('test@example.com', 'wrongpass');

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, 'Incorrect password.');
    });
  });

  group('AuthRepository Register Tests', () {
    test('should return success on valid registration', () async {
      // Arrange
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => mockCredential);
      when(() => mockDocument.set(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.register(
        'newuser@example.com',
        'password123',
        'John Doe',
        phone: '1234567890',
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.dataOrNull, isA<UserCredential>());
      verify(() => mockDocument.set(any())).called(1);
    });

    test('should return failure on email already in use', () async {
      // Arrange
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'The email address is already in use.',
        ),
      );

      // Act
      final result = await repository.register(
        'existing@example.com',
        'password123',
        'John Doe',
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, 'An account already exists with this email.');
    });

    test('should return failure on weak password', () async {
      // Arrange
      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        FirebaseAuthException(
          code: 'weak-password',
          message: 'Password should be at least 6 characters.',
        ),
      );

      // Act
      final result = await repository.register(
        'newuser@example.com',
        '123',
        'John Doe',
      );

      // Assert
      expect(result.isFailure, true);
      expect(
        result.errorOrNull,
        'Password is too weak. Please use at least 6 characters.',
      );
    });
  });

  group('AuthRepository Password Reset Tests', () {
    test('should return success on password reset email sent', () async {
      // Arrange
      when(
        () => mockAuth.sendPasswordResetEmail(email: any(named: 'email')),
      ).thenAnswer((_) async => {});

      // Act
      final result = await repository.sendPasswordReset('user@example.com');

      // Assert
      expect(result.isSuccess, true);
    });

    test('should return failure on user not found for reset', () async {
      // Arrange
      when(
        () => mockAuth.sendPasswordResetEmail(email: any(named: 'email')),
      ).thenThrow(
        FirebaseAuthException(
          code: 'user-not-found',
          message: 'There is no user record corresponding to this identifier.',
        ),
      );

      // Act
      final result = await repository.sendPasswordReset('unknown@example.com');

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, 'No account found with this email.');
    });
  });

  group('AuthRepository Sign Out Tests', () {
    test('should return success on sign out', () async {
      // Arrange
      when(() => mockAuth.signOut()).thenAnswer((_) async => {});

      // Act
      final result = await repository.signOut();

      // Assert
      expect(result.isSuccess, true);
    });
  });
}
