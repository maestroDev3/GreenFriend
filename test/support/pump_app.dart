import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/l10n/app_localizations.dart';
import 'package:green_friend/ui/theme.dart';

/// Logical size of a typical phone screen used by widget tests.
const phoneSize = Size(390, 844);

/// Renders widgets the way the app does, so widget tests only need to care
/// about the widget under test.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) async {
    view.physicalSize = phoneSize * view.devicePixelRatio;
    addTearDown(view.reset);
    await pumpWidget(
      MaterialApp(
        theme: theme ?? lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: widget,
      ),
    );
    await pumpAndSettle();
  }
}
