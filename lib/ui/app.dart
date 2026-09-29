import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'locale_resolution.dart';

/// The root widget that sets up localization and the home screen.
class GreenFriendApp extends StatelessWidget {
  const GreenFriendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: resolveLocale,
      home: const HomeScreen(),
    );
  }
}
