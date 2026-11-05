import '../models/pet.dart';

/// "New since your last visit" rule: a pet is new when it was created
/// after the previous visit. With no previous visit nothing is new.
bool isNewSince(Pet pet, DateTime? lastVisit) =>
    lastVisit != null &&
    pet.createdAt != null &&
    pet.createdAt!.isAfter(lastVisit);

int countNewSince(Iterable<Pet> pets, DateTime? lastVisit) =>
    pets.where((p) => isNewSince(p, lastVisit)).length;
