import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import 'data/shared_preferences_care_log_repository.dart';
import 'data/shared_preferences_plant_repository.dart';
import 'domain/care_actions.dart';
import 'notification_actions.dart';

/// Handles a check button in the home-screen widget in a background isolate:
/// records the plant's care and replans reminders, calendar and widget.
@pragma('vm:entry-point')
Future<void> onCareWidgetClicked(Uri? uri) async {
  DartPluginRegistrant.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final plants = SharedPreferencesPlantRepository(preferences);
  final done = await completeCareFromWidget(
    plants: plants,
    careLogs: SharedPreferencesCareLogRepository(preferences),
    uri: uri,
    today: DateTime.now(),
  );
  if (done) await replanReminders(preferences, plants);
}
