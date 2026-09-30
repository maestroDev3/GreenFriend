import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/settings.dart';
import 'package:green_friend/ui/app.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/settings_screen.dart';

import '../support/fake_backup.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';
import '../support/fake_species_catalog.dart';

Future<SettingsController> loadedSettings(FakeSettingsRepository repo) async {
  final settings = SettingsController(repo);
  await settings.load();
  return settings;
}

bool isSelected(WidgetTester tester, Key key) =>
    tester.widget<ListTile>(find.byKey(key)).selected;

const themeSystem = ValueKey('theme-system');
const themeLight = ValueKey('theme-light');
const themeDark = ValueKey('theme-dark');
const languageSystem = ValueKey('language-system');
const languageEnglish = ValueKey('language-english');
const languageGerman = ValueKey('language-german');

ThemeMode appThemeMode(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode ??
    ThemeMode.system;

/// In the app shell the settings live under "More".
Future<void> openSettingsFromApp(WidgetTester tester) async {
  await tester.tap(find.text('More'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Settings'));
}

void main() {
  group('HomeScreen', () {
    testWidgets('has a settings button that opens the settings', (
      tester,
    ) async {
      await tester.pumpApp(
        HomeScreen(
          species: FakeSpeciesCatalog(const []),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          careLogs: FakeCareLogRepository(),
          plants: FakePlantRepository(),
        ),
      );

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
      expect(isSelected(tester, themeSystem), isFalse);
      expect(isSelected(tester, themeLight), isTrue);
      expect(isSelected(tester, themeDark), isFalse);
    });

    testWidgets('shows the theme options in German', (tester) async {
      await tester.pumpApp(const SettingsScreen(), locale: const Locale('de'));

      expect(find.text('Einstellungen'), findsOneWidget);
      expect(find.text('System'), findsNWidgets(2));
      expect(find.text('Hell'), findsOneWidget);
      expect(find.text('Dunkel'), findsOneWidget);
    });
  });

  group('theme mode', () {
    testWidgets('follows the system without a stored choice', (tester) async {
      final settings = await loadedSettings(FakeSettingsRepository());

      await tester.pumpWidget(
        GreenFriendApp(
          species: FakeSpeciesCatalog(const []),
          backupArchive: FakeBackupArchive(),
          fileSharing: FakeFileSharing(),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          careLogs: FakeCareLogRepository(),
          settings: settings,
          plants: FakePlantRepository(),
        ),
      );

      expect(appThemeMode(tester), ThemeMode.system);
    });

    testWidgets('switches to dark immediately and saves the choice', (
      tester,
    ) async {
      final repository = FakeSettingsRepository();
      final settings = await loadedSettings(repository);
      await tester.pumpWidget(
        GreenFriendApp(
          species: FakeSpeciesCatalog(const []),
          backupArchive: FakeBackupArchive(),
          fileSharing: FakeFileSharing(),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          careLogs: FakeCareLogRepository(),
          settings: settings,
          plants: FakePlantRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await openSettingsFromApp(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(themeDark));
      await tester.pumpAndSettle();

      expect(appThemeMode(tester), ThemeMode.dark);
      expect(repository.themeMode, AppThemeMode.dark);
    });

    testWidgets('restores the saved choice on app start', (tester) async {
      final settings = await loadedSettings(
        FakeSettingsRepository(themeMode: AppThemeMode.dark),
      );

      await tester.pumpWidget(
        GreenFriendApp(
          species: FakeSpeciesCatalog(const []),
          backupArchive: FakeBackupArchive(),
          fileSharing: FakeFileSharing(),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          careLogs: FakeCareLogRepository(),
          settings: settings,
          plants: FakePlantRepository(),
        ),
      );

      expect(appThemeMode(tester), ThemeMode.dark);
    });
  });

  group('language', () {
    testWidgets('offers System, English and Deutsch with the current one '
        'selected', (tester) async {
      final settings = await loadedSettings(
        FakeSettingsRepository(language: AppLanguage.german),
      );

      await tester.pumpApp(const SettingsScreen(), settings: settings);
      await tester.scrollUntilVisible(find.byKey(languageGerman), 100);

      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Deutsch'), findsOneWidget);
      expect(isSelected(tester, languageSystem), isFalse);
      expect(isSelected(tester, languageEnglish), isFalse);
      expect(isSelected(tester, languageGerman), isTrue);
    });

    testWidgets('follows the device language without a stored choice', (
      tester,
    ) async {
      final settings = await loadedSettings(FakeSettingsRepository());

      await tester.pumpWidget(
        GreenFriendApp(
          species: FakeSpeciesCatalog(const []),
          backupArchive: FakeBackupArchive(),
          fileSharing: FakeFileSharing(),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          careLogs: FakeCareLogRepository(),
          settings: settings,
          plants: FakePlantRepository(),
        ),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, isNull);
    });

    testWidgets('switches to German immediately and saves the choice', (
      tester,
    ) async {
      final repository = FakeSettingsRepository();
      final settings = await loadedSettings(repository);
      await tester.pumpWidget(
        GreenFriendApp(
          species: FakeSpeciesCatalog(const []),
          backupArchive: FakeBackupArchive(),
          fileSharing: FakeFileSharing(),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          careLogs: FakeCareLogRepository(),
          settings: settings,
          plants: FakePlantRepository(),
        ),
      );
      await tester.pumpAndSettle();

      await openSettingsFromApp(tester);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(languageGerman), 100);
      await tester.tap(find.byKey(languageGerman));
      await tester.pumpAndSettle();

      expect(find.text('Einstellungen'), findsOneWidget);
      expect(repository.language, AppLanguage.german);
    });

    testWidgets('restores the saved language on app start', (tester) async {
      final settings = await loadedSettings(
        FakeSettingsRepository(language: AppLanguage.german),
      );

      await tester.pumpWidget(
        GreenFriendApp(
          species: FakeSpeciesCatalog(const []),
          backupArchive: FakeBackupArchive(),
          fileSharing: FakeFileSharing(),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          careLogs: FakeCareLogRepository(),
          settings: settings,
          plants: FakePlantRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Noch keine Pflanzen – füge deine erste Pflanze hinzu.'),
        findsOneWidget,
      );
    });
  });
}
