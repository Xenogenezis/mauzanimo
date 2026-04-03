import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';

class PetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all pets as a stream with optional type filter
  Stream<List<Pet>> getPetsStream({String? typeFilter}) {
    Query query = _firestore.collection('pets');

    if (typeFilter != null && typeFilter != 'All') {
      query = query.where('type', isEqualTo: typeFilter.toLowerCase());
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Pet.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Search pets by name or location
  Future<List<Pet>> searchPets(String query) async {
    final snapshot = await _firestore.collection('pets').get();
    final searchLower = query.toLowerCase();

    return snapshot.docs
        .map((doc) => Pet.fromMap(doc.id, doc.data()))
        .where((pet) =>
            pet.name.toLowerCase().contains(searchLower) ||
            pet.location.toLowerCase().contains(searchLower))
        .toList();
  }

  // Add a new pet
  Future<void> addPet(Pet pet) async {
    await _firestore.collection('pets').add(pet.toMap());
  }

  // Update an existing pet
  Future<void> updatePet(Pet pet) async {
    await _firestore.collection('pets').doc(pet.id).update(pet.toMap());
  }

  // Delete a pet
  Future<void> deletePet(String id) async {
    await _firestore.collection('pets').doc(id).delete();
  }

  // Get a single pet by ID
  Future<Pet?> getPetById(String id) async {
    final doc = await _firestore.collection('pets').doc(id).get();
    if (!doc.exists) return null;
    return Pet.fromMap(doc.id, doc.data());
  }

  // Get pets uploaded by a specific user
  Stream<List<Pet>> getUserPetsStream(String userId) {
    return _firestore
        .collection('pets')
        .where('uploadedBy', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Pet.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Toggle favorite status for a user
  Future<void> toggleFavorite(String userId, String petId) async {
    final ref = _firestore.collection('favourites');
    final existing = await ref
        .where('userId', isEqualTo: userId)
        .where('petId', isEqualTo: petId)
        .get();

    if (existing.docs.isEmpty) {
      await ref.add({
        'userId': userId,
        'petId': petId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await existing.docs.first.reference.delete();
    }
  }

  // Get favorite pet IDs for a user
  Stream<List<String>> getFavoritePetIds(String userId) {
    return _firestore
        .collection('favourites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => (doc.data()['petId'] as String?))
          .where((id) => id != null)
          .cast<String>()
          .toList();
    });
  }

  // Get favorite pets for a user
  Future<List<Pet>> getFavoritePets(String userId) async {
    final favSnapshot = await _firestore
        .collection('favourites')
        .where('userId', isEqualTo: userId)
        .get();

    final petIds = favSnapshot.docs
        .map((doc) => doc.data()['petId'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    if (petIds.isEmpty) return [];

    final petSnapshot = await _firestore.collection('pets').get();
    return petSnapshot.docs
        .where((doc) => petIds.contains(doc.id))
        .map((doc) => Pet.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Check if a pet is favorited by a user
  Stream<bool> isPetFavorited(String userId, String petId) {
    return _firestore
        .collection('favourites')
        .where('userId', isEqualTo: userId)
        .where('petId', isEqualTo: petId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}
