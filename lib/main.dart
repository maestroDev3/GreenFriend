import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/shared_preferences_care_log_repository.dart';
import 'data/shared_preferences_plant_repository.dart';
import 'data/shared_preferences_settings_repository.dart';
import 'ui/app.dart';
import 'ui/font_licenses.dart';
import 'ui/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();

  final preferences = await SharedPreferences.getInstance();
  final settings = SettingsController(
    SharedPreferencesSettingsRepository(preferences),
  );
  await settings.load();

  runApp(
    GreenFriendApp(
      settings: settings,
      plants: SharedPreferencesPlantRepository(preferences),
      careLogs: SharedPreferencesCareLogRepository(preferences),
    ),
  );
}
