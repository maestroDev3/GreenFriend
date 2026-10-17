import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/gif_timelapse_encoder.dart';
import 'data/bundled_species_catalog.dart';
import 'data/bundled_tips.dart';
import 'data/device_phone_calendar.dart';
import 'data/file_photo_store.dart';
import 'data/home_care_widget.dart';
import 'data/image_picker_photo_picker.dart';
import 'data/local_notification_scheduler.dart';
import 'data/open_meteo_weather_service.dart';
import 'data/plant_id_health_checker.dart';
import 'data/plant_id_identifier.dart';
import 'data/platform_file_sharing.dart';
import 'data/shared_preferences_care_log_repository.dart';
import 'data/shared_preferences_journal_repository.dart';
import 'data/shared_preferences_missing_species_repository.dart';
import 'data/shared_preferences_plant_repository.dart';
import 'data/shared_preferences_settings_repository.dart';
import 'data/zip_backup_archive.dart';
import 'notification_actions.dart';
import 'widget_actions.dart';
import 'ui/app.dart';
import 'ui/calendar_sync.dart';
import 'ui/font_licenses.dart';
import 'ui/reminder_sync.dart';
import 'ui/settings_controller.dart';
import 'ui/weather_sync.dart';
import 'ui/widget_sync.dart';

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
    onBackgroundAction: onNotificationActionInBackground,
  );
  ReminderSync(
    plants: plants,
    settings: settings,
    scheduler: scheduler,
    localizations: () => appLocalizationsFor(settings),
  ).start();

  WidgetSync(
    plants: plants,
    settings: settings,
    widget: HomeCareWidget(),
  ).start();
  unawaited(HomeWidget.registerInteractivityCallback(onCareWidgetClicked));

  final calendarSync = CalendarSync(
    plants: plants,
    settings: settings,
    calendar: DevicePhoneCalendar(),
  )..start();

  final careLogs = SharedPreferencesCareLogRepository(preferences);
  final journal = SharedPreferencesJournalRepository(preferences);
  final photos = await FilePhotoStore.create();

  final species = BundledSpeciesCatalog();
  final weatherSync = WeatherSync(
    plants: plants,
    careLogs: careLogs,
    settings: settings,
    service: OpenMeteoWeatherService(),
    species: species,
  );
  unawaited(weatherSync.refresh());

  // Reminder buttons record care in a background isolate; pick that up
  // whenever the app comes back to the foreground, then check the weather.
  AppLifecycleListener(
    onResume: () async {
      await plants.reload();
      await careLogs.reload();
      await weatherSync.refresh();
    },
  );

  runApp(
    GreenFriendApp(
      species: species,
      settings: settings,
      plants: plants,
      careLogs: careLogs,
      journal: journal,
      photos: photos,
      photoPicker: ImagePickerPhotoPicker(),
      backupArchive: ZipBackupArchive(
        plants: plants,
        careLogs: careLogs,
        journal: journal,
        photos: photos,
      ),
      fileSharing: PlatformFileSharing(),
      identifier: PlantIdIdentifier(),
      tips: BundledTipCatalog(),
      calendarSync: calendarSync,
      missingSpecies: SharedPreferencesMissingSpeciesRepository(preferences),
      weatherSync: weatherSync,
      timelapseEncoder: const GifTimelapseEncoder(),
      healthChecker: PlantIdHealthChecker(),
    ),
  );
}
