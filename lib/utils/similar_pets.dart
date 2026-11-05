/// A pet document as read from Firestore: its id plus its raw data.
typedef PetDoc = ({String id, Map<String, dynamic> data});

/// Maximum number of pets shown in the "Similar pets" section.
const int kMaxSimilarPets = 6;

/// Picks the pets to show as "similar" to [currentPetId] from [candidates]
/// (already narrowed to the same type and ordered newest first).
///
/// Keeps only pets that are still available (a missing status counts as
/// available, as on the detail screen), drops the current pet and any
/// duplicate ids, and returns at most [max] pets in their original order.
List<PetDoc> filterSimilarPets(
  Iterable<PetDoc> candidates, {
  required String currentPetId,
  int max = kMaxSimilarPets,
}) {
  final seen = <String>{};
  final result = <PetDoc>[];
  for (final pet in candidates) {
    if (result.length >= max) break;
    if (pet.id == currentPetId || !seen.add(pet.id)) continue;
    final status = (pet.data['status'] ?? 'available').toString().trim();
    if (status.toLowerCase() != 'available') continue;
    result.add(pet);
  }
  return result;
}
