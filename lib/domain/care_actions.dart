import 'care_log.dart';
import 'care_log_repository.dart';
import 'journal_actions.dart';
import 'journal_repository.dart';
import 'photos.dart';
import 'plant.dart';
import 'plant_repository.dart';

/// What [confirmCare] changed, so it can be undone.
class CareConfirmation {
  const CareConfirmation({required this.before, required this.log});

  /// The plant as it was before the confirmation.
  final Plant before;

  /// The care log written for the confirmation.
  final CareLog log;
}

/// Records that [kind] of care was done for [plant] [today]: sets the
/// matching last-done day and adds a care log.
Future<CareConfirmation> confirmCare({
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required Plant plant,
  required CareKind kind,
  required DateTime today,
}) async {
  final log = await careLogs.add(plantId: plant.id, kind: kind, day: today);
  await plants.update(switch (kind) {
    Water() => plant.copyWith(lastWateredOn: today),
    Fertilize() => plant.copyWith(lastFertilizedOn: today),
    Repot() => plant.copyWith(lastRepottedOn: today),
    Prune() => plant.copyWith(lastPrunedOn: today),
  });
  return CareConfirmation(before: plant, log: log);
}

/// Reverts a [confirmCare]: restores the plant and removes the log.
Future<void> undoCare({
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required CareConfirmation confirmation,
}) async {
  await careLogs.delete(confirmation.log.id);
  await plants.update(confirmation.before);
}

/// Records that [plant] was watered [today].
Future<CareConfirmation> confirmWatering({
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required Plant plant,
  required DateTime today,
}) => confirmCare(
  plants: plants,
  careLogs: careLogs,
  plant: plant,
  kind: const Water(),
  today: today,
);

/// Reverts a [confirmWatering].
Future<void> undoWatering({
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required CareConfirmation confirmation,
}) => undoCare(plants: plants, careLogs: careLogs, confirmation: confirmation);

/// Deletes a plant together with its care history, journal and photos.
Future<void> deletePlant({
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required JournalRepository journal,
  required PhotoStore photos,
  required String plantId,
}) async {
  await careLogs.deleteForPlant(plantId);
  await deleteJournalForPlant(
    journal: journal,
    photos: photos,
    plantId: plantId,
  );
  await plants.delete(plantId);
}
