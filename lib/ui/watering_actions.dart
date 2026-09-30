import 'package:flutter/material.dart';

import '../domain/care_actions.dart';
import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../l10n/app_localizations.dart';

/// Confirms that [kind] of care was done for [plant] today and offers to undo
/// it in a snackbar.
Future<void> careWithUndo(
  BuildContext context, {
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required Plant plant,
  required CareKind kind,
  required DateTime today,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final confirmation = await confirmCare(
    plants: plants,
    careLogs: careLogs,
    plant: plant,
    kind: kind,
    today: today,
  );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(switch (kind) {
          Water() => l10n.plantWatered(plant.name),
          Fertilize() => l10n.plantFertilized(plant.name),
          Repot() => l10n.plantRepotted(plant.name),
          Prune() => l10n.plantPruned(plant.name),
        }),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => undoCare(
            plants: plants,
            careLogs: careLogs,
            confirmation: confirmation,
          ),
        ),
      ),
    );
}

/// Confirms that [plant] was watered today, with undo.
Future<void> waterWithUndo(
  BuildContext context, {
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required Plant plant,
  required DateTime today,
}) => careWithUndo(
  context,
  plants: plants,
  careLogs: careLogs,
  plant: plant,
  kind: const Water(),
  today: today,
);
