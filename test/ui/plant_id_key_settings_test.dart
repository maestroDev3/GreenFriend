import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/settings_screen.dart';

import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';

const keyField = ValueKey('plant-id-api-key');

Future<SettingsController> loadedSettings(FakeSettingsRepository repo) async {
  final settings = SettingsController(repo);
  await settings.load();
  return settings;
}

Future<void> showKeyField(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(keyField),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('plant.id API key setting', () {
    testWidgets('saves the entered key and hides its text', (tester) async {
      final repository = FakeSettingsRepository();
      final settings = await loadedSettings(repository);
      await tester.pumpApp(const SettingsScreen(), settings: settings);
      await showKeyField(tester);

      expect(find.text('Plant identification'), findsOneWidget);
      await tester.enterText(find.byKey(keyField), ' my-key ');
      await tester.pumpAndSettle();

      expect(repository.plantIdApiKey, 'my-key');
      expect(settings.plantIdApiKey, 'my-key');
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(keyField),
          matching: find.byType(TextField),
        ),
      );
      expect(field.obscureText, isTrue);
    });

    testWidgets('shows a stored key and removes it when cleared', (
      tester,
    ) async {
      final repository = FakeSettingsRepository(plantIdApiKey: 'stored');
      final settings = await loadedSettings(repository);
      await tester.pumpApp(const SettingsScreen(), settings: settings);
      await showKeyField(tester);

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(keyField),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller?.text, 'stored');

      await tester.enterText(find.byKey(keyField), '');
      await tester.pumpAndSettle();

      expect(repository.plantIdApiKey, isNull);
      expect(settings.plantIdApiKey, isNull);
    });

    testWidgets('can show the key text with the visibility button', (
      tester,
    ) async {
      final settings = await loadedSettings(
        FakeSettingsRepository(plantIdApiKey: 'stored'),
      );
      await tester.pumpApp(const SettingsScreen(), settings: settings);
      await showKeyField(tester);

      await tester.tap(find.byTooltip('Show key'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(keyField),
          matching: find.byType(TextField),
        ),
      );
      expect(field.obscureText, isFalse);
    });
  });
}
