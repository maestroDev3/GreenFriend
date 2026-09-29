import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/settings.dart';
import 'package:green_friend/ui/app.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/settings_screen.dart';

import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';

Future<SettingsController> loadedSettings(FakeSettingsRepository repo) async {
  final settings = SettingsController(repo);
  await settings.load();
  return settings;
}

bool isSelected(WidgetTester tester, String label) =>
    tester.widget<ListTile>(find.widgetWithText(ListTile, label)).selected;

ThemeMode appThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode ??
    ThemeMode.system;

void main() {
  group('HomeScreen', () {
    testWidgets('has a settings button that opens the settings', (
      tester,
    ) async {
      await tester.pumpApp(const HomeScreen());

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('SettingsScreen', () {
    testWidgets('offers System, Light and Dark with the current one selected', (
      tester,
    ) async {
      final settings = await loadedSettings(
        FakeSettingsRepository(themeMode: AppThemeMode.light),
      );

      await tester.pumpApp(const SettingsScreen(), settings: settings);

      expect(find.text('Settings'), findsOneWidget);
      expect(isSelected(tester, 'System'), isFalse);
      expect(isSelected(tester, 'Light'), isTrue);
      expect(isSelected(tester, 'Dark'), isFalse);
    });

    testWidgets('shows the theme options in German', (tester) async {
      await tester.pumpApp(
        const SettingsScreen(),
        locale: const Locale('de'),
      );

      expect(find.text('Einstellungen'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Hell'), findsOneWidget);
      expect(find.text('Dunkel'), findsOneWidget);
    });
  });

  group('theme mode', () {
    testWidgets('follows the system without a stored choice', (tester) async {
      final settings = await loadedSettings(FakeSettingsRepository());

      await tester.pumpWidget(GreenFriendApp(settings: settings));

      expect(appThemeMode(tester), ThemeMode.system);
    });

    testWidgets('switches to dark immediately and saves the choice', (
      tester,
    ) async {
      final repository = FakeSettingsRepository();
      final settings = await loadedSettings(repository);
      await tester.pumpWidget(GreenFriendApp(settings: settings));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(appThemeMode(tester), ThemeMode.dark);
      expect(repository.themeMode, AppThemeMode.dark);
    });

    testWidgets('restores the saved choice on app start', (tester) async {
      final settings = await loadedSettings(
        FakeSettingsRepository(themeMode: AppThemeMode.dark),
      );

      await tester.pumpWidget(GreenFriendApp(settings: settings));

      expect(appThemeMode(tester), ThemeMode.dark);
    });
  });
}
