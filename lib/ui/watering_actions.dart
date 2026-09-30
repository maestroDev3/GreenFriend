import 'package:flutter/material.dart';

import '../domain/care_actions.dart';
import '../domain/care_log_repository.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../l10n/app_localizations.dart';

/// Confirms that [plant] was watered today and offers to undo it in a
/// snackbar.
Future<void> waterWithUndo(
  BuildContext context, {
  required PlantRepository plants,
  required CareLogRepository careLogs,
  required Plant plant,
  required DateTime today,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final confirmation = await confirmWatering(
    plants: plants,
    careLogs: careLogs,
    plant: plant,
    today: today,
  );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(l10n.plantWatered(plant.name)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => undoWatering(
            plants: plants,
            careLogs: careLogs,
            confirmation: confirmation,
          ),
        ),
      ),
    );
}
