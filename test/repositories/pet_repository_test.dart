import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/models/pet.dart';
import 'package:stray_pets_mu/repositories/pet_repository.dart';
import 'package:stray_pets_mu/utils/result.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDocumentSnapshot extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late PetRepository repository;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    repository = PetRepository(firestore: mockFirestore);
  });

  group('PetRepository Tests', () {
    final testPet = Pet(
      id: 'pet123',
      name: 'Buddy',
      type: 'dog',
      location: 'Port Louis',
      description: 'Friendly dog',
      age: '2 years',
      gender: 'Male',
      contact: '1234567890',
    );

    test('should return success when adding pet', () async {
      // Arrange
      when(() => mockFirestore.collection('pets')).thenReturn(mockCollection);
      when(() => mockCollection.add(any())).thenAnswer((_) async => mockDocument);

      // Act
      final result = await repository.addPet(testPet);

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockCollection.add(any())).called(1);
    });

    test('should return success when updating pet', () async {
      // Arrange
      when(() => mockFirestore.collection('pets')).thenReturn(mockCollection);
      when(() => mockCollection.doc('pet123')).thenReturn(mockDocument);
      when(() => mockDocument.update(any())).thenAnswer((_) async => {});

      // Act
      final result = await repository.updatePet(testPet);

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockDocument.update(any())).called(1);
    });

    test('should return success when deleting pet', () async {
      // Arrange
      when(() => mockFirestore.collection('pets')).thenReturn(mockCollection);
      when(() => mockCollection.doc('pet123')).thenReturn(mockDocument);
      when(() => mockDocument.delete()).thenAnswer((_) async => {});

      // Act
      final result = await repository.deletePet('pet123');

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockDocument.delete()).called(1);
    });

    test('should return success with null when pet not found', () async {
      // Arrange
      final mockDocSnapshot = MockDocumentSnapshot();
      when(() => mockFirestore.collection('pets')).thenReturn(mockCollection);
      when(() => mockCollection.doc('nonexistent')).thenReturn(mockDocument);
      when(() => mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(false);

      // Act
      final result = await repository.getPetById('nonexistent');

      // Assert
      expect(result.isSuccess, true);
      expect(result.dataOrNull, isNull);
    });

    test('should return stream of pets successfully', () {
      // Act
      final result = repository.getPetsStream();

      // Assert
      expect(result.isSuccess, true);
      expect(result.dataOrNull, isA<Stream<List<Pet>>>());
    });

    test('should return stream with filter successfully', () {
      // Act
      final result = repository.getPetsStream(typeFilter: 'Dogs');

      // Assert
      expect(result.isSuccess, true);
      expect(result.dataOrNull, isA<Stream<List<Pet>>>());
    });

    test('should return failure on FirebaseException', () async {
      // Arrange
      when(() => mockFirestore.collection('pets')).thenThrow(
        FirebaseException(
          plugin: 'firestore',
          code: 'permission-denied',
          message: 'Permission denied',
        ),
      );

      // Act
      final result = await repository.deletePet('pet123');

      // Assert
      expect(result.isFailure, true);
      expect(result.errorOrNull, contains('Permission denied'));
    });
  });
}
