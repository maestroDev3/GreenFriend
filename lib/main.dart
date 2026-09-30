import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/local_notification_scheduler.dart';
import 'data/shared_preferences_care_log_repository.dart';
import 'data/shared_preferences_plant_repository.dart';
import 'data/shared_preferences_settings_repository.dart';
import 'ui/app.dart';
import 'ui/font_licenses.dart';
import 'ui/reminder_sync.dart';
import 'ui/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();

  final preferences = await SharedPreferences.getInstance();
  final settings = SettingsController(
    SharedPreferencesSettingsRepository(preferences),
  );
  await settings.load();

  final plants = SharedPreferencesPlantRepository(preferences);
  final l10n = appLocalizationsFor(settings);
  final scheduler = await LocalNotificationScheduler.create(
    channelName: l10n.dailyReminder,
    channelDescription: l10n.reminderChannelDescription,
  );
  ReminderSync(
    plants: plants,
    settings: settings,
    scheduler: scheduler,
    localizations: () => appLocalizationsFor(settings),
  ).start();

  runApp(
    GreenFriendApp(
      settings: settings,
      plants: plants,
      careLogs: SharedPreferencesCareLogRepository(preferences),
    ),
  );
}
