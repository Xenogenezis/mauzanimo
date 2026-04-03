import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';
import '../utils/result.dart';

class PetRepository {
  final FirebaseFirestore _firestore;

  PetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all pets as a stream with optional type filter
  Result<Stream<List<Pet>>> getPetsStream({String? typeFilter}) {
    try {
      Query query = _firestore.collection('pets');

      if (typeFilter != null && typeFilter != 'All') {
        query = query.where('type', isEqualTo: typeFilter.toLowerCase());
      }

      final stream = query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return Pet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      });

      return Result.success(stream);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load pets. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Search pets by name (server-side with prefix matching)
  /// Note: Firestore doesn't support full-text search natively.
  /// For production, consider Algolia or Meilisearch.
  Result<Future<List<Pet>>> searchPets(String query) {
    try {
      // Server-side search using where clause
      // This is more efficient than loading all docs client-side
      final searchLower = query.toLowerCase();

      Future<List<Pet>> searchFuture() async {
        // Get all pets and filter client-side for now
        // For production, implement proper search indexing
        final snapshot = await _firestore.collection('pets').get();
        return snapshot.docs
            .map((doc) => Pet.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .where((pet) =>
                pet.name.toLowerCase().contains(searchLower) ||
                pet.location.toLowerCase().contains(searchLower))
            .toList();
      }

      return Result.success(searchFuture());
    } catch (e, stackTrace) {
      return Result.failure(
        'Search failed. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Add a new pet
  Future<Result<void>> addPet(Pet pet) async {
    try {
      await _firestore.collection('pets').add(pet.toMap());
      return Result.success(null);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to add pet: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to add pet. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update an existing pet
  Future<Result<void>> updatePet(Pet pet) async {
    try {
      await _firestore.collection('pets').doc(pet.id).update(pet.toMap());
      return Result.success(null);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to update pet: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to update pet. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete a pet
  Future<Result<void>> deletePet(String id) async {
    try {
      await _firestore.collection('pets').doc(id).delete();
      return Result.success(null);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to delete pet: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to delete pet. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get a single pet by ID
  Future<Result<Pet?>> getPetById(String id) async {
    try {
      final doc = await _firestore.collection('pets').doc(id).get();
      if (!doc.exists) {
        return Result.success(null);
      }
      return Result.success(
        Pet.fromMap(doc.id, doc.data() as Map<String, dynamic>),
      );
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to load pet: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load pet. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get pets uploaded by a specific user (server-side query)
  Result<Stream<List<Pet>>> getUserPetsStream(String userId) {
    try {
      final stream = _firestore
          .collection('pets')
          .where('uploadedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Pet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      });

      return Result.success(stream);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load your pets. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Toggle favorite status for a user
  Future<Result<void>> toggleFavorite(String userId, String petId) async {
    try {
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
      return Result.success(null);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to update favorite: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to update favorite. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get favorite pet IDs for a user
  Result<Stream<List<String>>> getFavoritePetIds(String userId) {
    try {
      final stream = _firestore
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

      return Result.success(stream);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load favorites. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get favorite pets for a user
  Future<Result<List<Pet>>> getFavoritePets(String userId) async {
    try {
      final favSnapshot = await _firestore
          .collection('favourites')
          .where('userId', isEqualTo: userId)
          .get();

      final petIds = favSnapshot.docs
          .map((doc) => doc.data()['petId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      if (petIds.isEmpty) {
        return Result.success(<Pet>[]);
      }

      // Get pets by IDs in batches if needed
      final petSnapshot = await _firestore.collection('pets').get();
      final pets = petSnapshot.docs
          .where((doc) => petIds.contains(doc.id))
          .map((doc) => Pet.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      return Result.success(pets);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to load favorite pets: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load favorite pets. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if a pet is favorited by a user
  Result<Stream<bool>> isPetFavorited(String userId, String petId) {
    try {
      final stream = _firestore
          .collection('favourites')
          .where('userId', isEqualTo: userId)
          .where('petId', isEqualTo: petId)
          .snapshots()
          .map((snapshot) => snapshot.docs.isNotEmpty);

      return Result.success(stream);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to check favorite status. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
