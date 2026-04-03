import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/models/pet.dart';

void main() {
  group('Pet Model Tests', () {
    test('should create Pet from map correctly', () {
      // Arrange
      final map = {
        'name': 'Buddy',
        'type': 'dog',
        'location': 'Port Louis',
        'description': 'Friendly dog',
        'imageUrl': 'https://example.com/dog.jpg',
        'age': '2 years',
        'gender': 'Male',
        'vaccinated': true,
        'sterilized': false,
        'dewormed': true,
        'status': 'available',
        'contact': '1234567890',
        'uploadedBy': 'user123',
        'uploaderEmail': 'user@example.com',
        'isUserUpload': true,
      };

      // Act
      final pet = Pet.fromMap('pet123', map);

      // Assert
      expect(pet.id, 'pet123');
      expect(pet.name, 'Buddy');
      expect(pet.type, 'dog');
      expect(pet.location, 'Port Louis');
      expect(pet.description, 'Friendly dog');
      expect(pet.imageUrl, 'https://example.com/dog.jpg');
      expect(pet.age, '2 years');
      expect(pet.gender, 'Male');
      expect(pet.vaccinated, true);
      expect(pet.sterilized, false);
      expect(pet.dewormed, true);
      expect(pet.status, 'available');
      expect(pet.contact, '1234567890');
      expect(pet.uploadedBy, 'user123');
      expect(pet.uploaderEmail, 'user@example.com');
      expect(pet.isUserUpload, true);
    });

    test('should use default values for missing fields', () {
      // Arrange
      final map = {
        'name': 'Kitty',
        'type': 'cat',
        'location': 'Curepipe',
        'description': '',
        'age': '1 year',
        'gender': 'Female',
        'contact': '0987654321',
      };

      // Act
      final pet = Pet.fromMap('pet456', map);

      // Assert
      expect(pet.id, 'pet456');
      expect(pet.name, 'Kitty');
      expect(pet.type, 'cat');
      expect(pet.vaccinated, false);
      expect(pet.sterilized, false);
      expect(pet.dewormed, false);
      expect(pet.status, 'available');
      expect(pet.isUserUpload, false);
      expect(pet.imageUrl, null);
      expect(pet.uploadedBy, null);
      expect(pet.uploaderEmail, null);
    });

    test('should convert Pet to map correctly', () {
      // Arrange
      final pet = Pet(
        id: 'pet789',
        name: 'Max',
        type: 'dog',
        location: 'Rose Hill',
        description: 'Playful puppy',
        imageUrl: 'https://example.com/max.jpg',
        age: '6 months',
        gender: 'Male',
        vaccinated: true,
        sterilized: true,
        dewormed: true,
        status: 'pending',
        contact: '5555555555',
        uploadedBy: 'user789',
        uploaderEmail: 'max@example.com',
        isUserUpload: true,
      );

      // Act
      final map = pet.toMap();

      // Assert
      expect(map['name'], 'Max');
      expect(map['type'], 'dog');
      expect(map['location'], 'Rose Hill');
      expect(map['description'], 'Playful puppy');
      expect(map['imageUrl'], 'https://example.com/max.jpg');
      expect(map['age'], '6 months');
      expect(map['gender'], 'Male');
      expect(map['vaccinated'], true);
      expect(map['sterilized'], true);
      expect(map['dewormed'], true);
      expect(map['status'], 'pending');
      expect(map['contact'], '5555555555');
      expect(map['uploadedBy'], 'user789');
      expect(map['uploaderEmail'], 'max@example.com');
      expect(map['isUserUpload'], true);
    });

    test('should create copy of Pet with copyWith', () {
      // Arrange
      final original = Pet(
        id: 'original',
        name: 'Original',
        type: 'dog',
        location: 'Port Louis',
        description: 'Original description',
        age: '2 years',
        gender: 'Male',
        contact: '1234567890',
      );

      // Act
      final copy = original.copyWith(
        name: 'Updated',
        status: 'adopted',
      );

      // Assert
      expect(copy.id, 'original');
      expect(copy.name, 'Updated');
      expect(copy.type, 'dog');
      expect(copy.status, 'adopted');
      expect(original.name, 'Original');
      expect(original.status, 'available');
    });

    test('should handle null values gracefully', () {
      // Arrange
      final map = <String, dynamic>{
        'name': null,
        'type': null,
        'location': null,
        'description': null,
        'imageUrl': null,
        'age': null,
        'gender': null,
        'vaccinated': null,
        'sterilized': null,
        'dewormed': null,
        'status': null,
        'contact': null,
      };

      // Act
      final pet = Pet.fromMap('empty', map);

      // Assert
      expect(pet.name, 'Unknown');
      expect(pet.type, 'pet');
      expect(pet.location, 'Mauritius');
      expect(pet.description, '');
      expect(pet.age, 'Unknown');
      expect(pet.gender, 'Unknown');
      expect(pet.status, 'available');
      expect(pet.contact, '');
      expect(pet.vaccinated, false);
      expect(pet.sterilized, false);
      expect(pet.dewormed, false);
    });
  });
}
