import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/local_notification_scheduler.dart';
import 'data/shared_preferences_care_log_repository.dart';
import 'data/shared_preferences_plant_repository.dart';
import 'data/shared_preferences_settings_repository.dart';
import 'domain/care_actions.dart';
import 'domain/plant_repository.dart';
import 'ui/reminder_sync.dart';
import 'ui/settings_controller.dart';

/// Handles a tap on a reminder button ("Watered") in a background isolate:
/// records the care and replans the reminders, without opening the app.
///
/// The app reloads its data when it comes back to the foreground, because
/// this isolate writes the storage on its own.
@pragma('vm:entry-point')
Future<void> onNotificationActionInBackground(
  NotificationResponse response,
) async {
  DartPluginRegistrant.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final plants = SharedPreferencesPlantRepository(preferences);
  final done = await completeCareFromAction(
    plants: plants,
    careLogs: SharedPreferencesCareLogRepository(preferences),
    actionId: response.actionId,
    today: DateTime.now(),
  );
  if (!done) return;
  await replanReminders(preferences, plants);
}

/// Schedules the reminders once from the stored plants and settings (used
/// outside the running app).
Future<void> replanReminders(
  SharedPreferences preferences,
  PlantRepository plants,
) async {
  final settings = SettingsController(
    SharedPreferencesSettingsRepository(preferences),
  );
  await settings.load();
  final l10n = appLocalizationsFor(settings);
  final scheduler = await LocalNotificationScheduler.create(
    channelName: l10n.dailyReminder,
    channelDescription: l10n.reminderChannelDescription,
    onBackgroundAction: onNotificationActionInBackground,
  );
  final sync = ReminderSync(
    plants: plants,
    settings: settings,
    scheduler: scheduler,
    localizations: () => appLocalizationsFor(settings),
    askPermission: false,
  )..start();
  await sync.idle;
  sync.dispose();
}
