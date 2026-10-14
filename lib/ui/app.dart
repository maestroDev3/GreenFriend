import 'package:flutter/material.dart';

import '../domain/backup_files.dart';
import '../domain/care_log_repository.dart';
import '../domain/identification.dart';
import '../domain/journal_repository.dart';
import '../domain/missing_species.dart';
import '../domain/photos.dart';
import '../domain/plant_repository.dart';
import '../domain/species.dart';
import '../domain/settings.dart';
import '../domain/tips.dart';
import '../l10n/app_localizations.dart';
import 'app_shell.dart';
import 'calendar_sync.dart';
import 'locale_resolution.dart';
import 'settings_controller.dart';
import 'theme.dart';
import 'weather_sync.dart';

/// The root widget that sets up settings, localization, theme and the home
/// screen.
class GreenFriendApp extends StatelessWidget {
  const GreenFriendApp({
    super.key,
    required this.settings,
    required this.plants,
    required this.careLogs,
    required this.journal,
    required this.photos,
    required this.species,
    required this.photoPicker,
    required this.backupArchive,
    required this.fileSharing,
    this.identifier,
    this.tips,
    this.calendarSync,
    this.missingSpecies,
    this.weatherSync,
  });

  final SettingsController settings;
  final PlantRepository plants;
  final CareLogRepository careLogs;
  final JournalRepository journal;
  final PhotoStore photos;

  /// The plant database used to suggest species and their care profile.
  final SpeciesCatalog species;
  final PhotoPicker photoPicker;
  final BackupArchive backupArchive;
  final FileSharing fileSharing;

  /// Identifies new plants from a photo; `null` hides that option.
  final PlantIdentifier? identifier;

  /// Care tips for the home screen; `null` hides the tip card.
  final TipCatalog? tips;

  /// Syncs the care plan into a phone calendar; `null` hides that option.
  final CalendarSync? calendarSync;

  /// Identified species without a care profile; `null` hides the list.
  final MissingSpeciesRepository? missingSpecies;

  /// Weather for outdoor plants; `null` hides the hint and the setting.
  final WeatherSync? weatherSync;

  @override
  Widget build(BuildContext context) {
    final app = SettingsScope(
      controller: settings,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: switch (settings.themeMode) {
            AppThemeMode.system => ThemeMode.system,
            AppThemeMode.light => ThemeMode.light,
            AppThemeMode.dark => ThemeMode.dark,
          },
          locale: switch (settings.language) {
            AppLanguage.system => null,
            AppLanguage.english => const Locale('en'),
            AppLanguage.german => const Locale('de'),
          },
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback: resolveLocale,
          home: AppShell(
            species: species,
            plants: plants,
            careLogs: careLogs,
            journal: journal,
            photos: photos,
            photoPicker: photoPicker,
            backupArchive: backupArchive,
            fileSharing: fileSharing,
            identifier: identifier,
            tips: tips,
            missingSpecies: missingSpecies,
            weather: weatherSync,
          ),
        ),
      ),
    );
    final withWeather = switch (weatherSync) {
      final sync? => WeatherScope(sync: sync, child: app),
      null => app,
    };
    return switch (calendarSync) {
      final sync? => CalendarScope(sync: sync, child: withWeather),
      null => withWeather,
    };
  }
}
