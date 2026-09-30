import 'care_log.dart';
import 'care_log_repository.dart';
import 'plant.dart';
import 'plant_repository.dart';

/// What [confirmWatering] changed, so it can be undone.
class WateringConfirmation {
  const WateringConfirmation({required this.before, required this.log});

  /// The plant as it was before the confirmation.
  final Plant before;

  /// The care log written for the confirmation.
  final CareLog log;
}

/// Records that [plant] was watered [today]: sets its last watering and adds
/// a care log.
Future<WateringConfirmation> confirmWatering({
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required Plant plant,
  required DateTime today,
}) async {
  final log = await careLogs.add(
    plantId: plant.id,
    kind: const Water(),
    day: today,
  );
  await plants.update(plant.copyWith(lastWateredOn: today));
  return WateringConfirmation(before: plant, log: log);
}

/// Reverts a [confirmWatering]: restores the plant and removes the log.
Future<void> undoWatering({
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required WateringConfirmation confirmation,
}) async {
  await careLogs.delete(confirmation.log.id);
  await plants.update(confirmation.before);
}

/// Deletes a plant together with its care history.
Future<void> deletePlant({
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required String plantId,
}) async {
  await careLogs.deleteForPlant(plantId);
  await plants.delete(plantId);
}
