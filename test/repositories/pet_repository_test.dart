import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/models/pet.dart';
import 'package:stray_pets_mu/repositories/pet_repository.dart';
import 'package:stray_pets_mu/utils/result.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

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
      when(() => mockFirestore.collection('pets')).thenReturn(mockCollection);
      when(() => mockCollection.add(any())).thenAnswer((_) async => mockDocument);

      final result = await repository.addPet(testPet);

      expect(result.isSuccess, true);
      verify(() => mockCollection.add(any())).called(1);
    });

    test('should return success when updating pet', () async {
      when(() => mockFirestore.collection('pets')).thenReturn(mockCollection);
      when(() => mockCollection.doc('pet123')).thenReturn(mockDocument);
      when(() => mockDocument.update(any())).thenAnswer((_) async => {});

      final result = await repository.updatePet(testPet);

      expect(result.isSuccess, true);
      verify(() => mockDocument.update(any())).called(1);
    });

    test('should return success when deleting pet', () async {
      when(() => mockFirestore.collection('pets')).thenReturn(mockCollection);
      when(() => mockCollection.doc('pet123')).thenReturn(mockDocument);
      when(() => mockDocument.delete()).thenAnswer((_) async => {});

      final result = await repository.deletePet('pet123');

      expect(result.isSuccess, true);
      verify(() => mockDocument.delete()).called(1);
    });

    test('should return success with null when pet not found', () async {
      final mockDocSnapshot = MockDocumentSnapshot();
      when(() => mockFirestore.collection('pets')).thenReturn(mockCollection);
      when(() => mockCollection.doc('nonexistent')).thenReturn(mockDocument);
      when(() => mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);
      when(() => mockDocSnapshot.exists).thenReturn(false);

      final result = await repository.getPetById('nonexistent');

      expect(result.isSuccess, true);
      expect(result.dataOrNull, isNull);
    });

    test('should return failure on FirebaseException', () async {
      when(() => mockFirestore.collection('pets')).thenThrow(
        FirebaseException(
          plugin: 'firestore',
          code: 'permission-denied',
          message: 'Permission denied',
        ),
      );

      final result = await repository.deletePet('pet123');

      expect(result.isFailure, true);
      expect(result.errorOrNull, contains('Permission denied'));
    });

    test('getPetsStream should return Result type', () {
      when(() => mockFirestore.collection('pets')).thenReturn(mockCollection);

      final result = repository.getPetsStream();

      expect(result, isA<Result<Stream<List<Pet>>>>());
    });

    test('getPetsStream with filter should return Result type', () {
      when(() => mockFirestore.collection('pets')).thenReturn(mockCollection);

      final result = repository.getPetsStream(typeFilter: 'Dogs');

      expect(result, isA<Result<Stream<List<Pet>>>>());
    });

    test('loadMorePets should handle FirebaseException', () async {
      when(() => mockFirestore.collection('pets')).thenThrow(
        FirebaseException(
          plugin: 'firestore',
          code: 'permission-denied',
          message: 'Permission denied',
        ),
      );

      final mockDoc = MockDocumentSnapshot();
      final result = await repository.loadMorePets(startAfter: mockDoc);

      expect(result.isFailure, true);
    });
  });
}
