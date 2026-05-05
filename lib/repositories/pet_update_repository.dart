import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet_update.dart';
import '../utils/result.dart';

class PetUpdateRepository {
  final FirebaseFirestore _firestore;
  PetUpdateRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Result<void>> addUpdate(PetUpdate update) async {
    try {
      await _firestore
          .collection('pet_updates')
          .add(update.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Firestore error', error: e);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }

  Result<Stream<List<PetUpdate>>> getUpdatesForPet(String petId) {
    try {
      final stream = _firestore
          .collection('pet_updates')
          .where('petId', isEqualTo: petId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => PetUpdate.fromMap(d.id, d.data())).toList());
      return Result.success(stream);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }
}
