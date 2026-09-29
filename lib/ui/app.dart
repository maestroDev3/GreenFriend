import 'package:flutter/material.dart';

import '../domain/plant_repository.dart';
import '../domain/settings.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'locale_resolution.dart';
import 'settings_controller.dart';
import 'theme.dart';

/// The root widget that sets up settings, localization, theme and the home
/// screen.
class GreenFriendApp extends StatelessWidget {
  const GreenFriendApp({
    super.key,
    required this.settings,
    required this.plants,
  });

  final SettingsController settings;
  final PlantRepository plants;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
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
          home: HomeScreen(plants: plants),
        ),
      ),
    );
  }
}
