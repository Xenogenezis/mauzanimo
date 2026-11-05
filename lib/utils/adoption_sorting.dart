import '../models/adoption.dart';

/// The adoption steps in order, excluding the terminal `rejected` stage.
const List<AdoptionStage> kAdoptionSteps = [
  AdoptionStage.application,
  AdoptionStage.screening,
  AdoptionStage.meet_greet,
  AdoptionStage.trial,
  AdoptionStage.completed,
];

/// True once an adoption can no longer move forward.
bool isAdoptionClosed(AdoptionStage stage) =>
    stage == AdoptionStage.completed || stage == AdoptionStage.rejected;

/// Returns a new list sorted newest first by `createdAt`. Ties are broken by
/// id so the order is stable across stream updates.
List<Adoption> sortAdoptionsNewestFirst(Iterable<Adoption> adoptions) {
  final list = adoptions.toList();
  list.sort((a, b) {
    final byDate = b.createdAt.compareTo(a.createdAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  return list;
}

/// Adoptions split into those still in progress and those that are closed
/// (completed or rejected), each newest first.
class AdoptionGroups {
  final List<Adoption> active;
  final List<Adoption> closed;

  const AdoptionGroups({required this.active, required this.closed});

  bool get isEmpty => active.isEmpty && closed.isEmpty;
}

AdoptionGroups groupAdoptions(Iterable<Adoption> adoptions) {
  final sorted = sortAdoptionsNewestFirst(adoptions);
  return AdoptionGroups(
    active: sorted.where((a) => !isAdoptionClosed(a.currentStage)).toList(),
    closed: sorted.where((a) => isAdoptionClosed(a.currentStage)).toList(),
  );
}

/// Index in [kAdoptionSteps] of the furthest step [adoption] reached.
///
/// For a rejected adoption this is the furthest non-rejected step recorded in
/// its history (0 when there is none).
int adoptionReachedStep(Adoption adoption) {
  final current = kAdoptionSteps.indexOf(adoption.currentStage);
  if (current >= 0) return current;
  var reached = 0;
  for (final record in adoption.stageHistory) {
    final i = kAdoptionSteps.indexOf(record.stage);
    if (i > reached) reached = i;
  }
  return reached;
}
