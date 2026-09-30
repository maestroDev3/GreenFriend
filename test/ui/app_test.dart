import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/l10n/app_localizations.dart';
import 'package:green_friend/ui/app.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';

Future<void> pumpWithDeviceLocale(WidgetTester tester, Locale locale) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    GreenFriendApp(careLogs: FakeCareLogRepository(), 
      settings: SettingsController(FakeSettingsRepository()),
      plants: FakePlantRepository(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('GreenFriendApp', () {
    testWidgets('shows the title and the empty-state hint in English', (
      tester,
    ) async {
      await pumpWithDeviceLocale(tester, const Locale('en'));

      expect(find.text('Green Friend'), findsOneWidget);
      expect(
        find.text('No plants yet – add your first plant.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the empty-state hint in German on German devices', (
      tester,
    ) async {
      await pumpWithDeviceLocale(tester, const Locale('de', 'DE'));

      expect(find.text('Green Friend'), findsOneWidget);
      expect(
        find.text('Noch keine Pflanzen – füge deine erste Pflanze hinzu.'),
        findsOneWidget,
      );
    });

    testWidgets('falls back to English for an unsupported device language', (
      tester,
    ) async {
      await pumpWithDeviceLocale(tester, const Locale('fr'));

      expect(
        find.text('No plants yet – add your first plant.'),
        findsOneWidget,
      );
    });

    testWidgets('registers the localization delegates', (tester) async {
      await pumpWithDeviceLocale(tester, const Locale('en'));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.localizationsDelegates, contains(AppLocalizations.delegate));
      expect(
        app.localizationsDelegates,
        contains(GlobalMaterialLocalizations.delegate),
      );
    });
  });

  group('AppLocalizations', () {
    test('supports English and German', () {
      expect(
        AppLocalizations.supportedLocales,
        containsAll(const [Locale('en'), Locale('de')]),
      );
    });
  });
}
