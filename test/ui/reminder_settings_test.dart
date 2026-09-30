import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/reminders.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/settings_screen.dart';

import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';

Future<SettingsController> loadedSettings(FakeSettingsRepository repo) async {
  final settings = SettingsController(repo);
  await settings.load();
  return settings;
}

void main() {
  group('reminder settings', () {
    testWidgets('shows the daily reminder switch and the time', (tester) async {
      final settings = await loadedSettings(FakeSettingsRepository());

      await tester.pumpApp(const SettingsScreen(), settings: settings);
      await tester.scrollUntilVisible(find.text('Daily reminder'), 100);

      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('9:00 AM'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
    });

    testWidgets('turns the reminder off and saves it', (tester) async {
      final repository = FakeSettingsRepository();
      final settings = await loadedSettings(repository);
      await tester.pumpApp(const SettingsScreen(), settings: settings);
      await tester.scrollUntilVisible(find.text('Daily reminder'), 100);

      await tester.tap(find.text('Daily reminder'));
      await tester.pumpAndSettle();

      expect(repository.reminder.enabled, isFalse);
      expect(repository.reminder.time, const ReminderTime(9, 0));
    });

    testWidgets('shows the texts in German', (tester) async {
      final settings = await loadedSettings(FakeSettingsRepository());

      await tester.pumpApp(
        const SettingsScreen(),
        settings: settings,
        locale: const Locale('de'),
      );
      await tester.scrollUntilVisible(find.text('Tägliche Erinnerung'), 100);

      expect(find.text('Erinnerungen'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
    });
  });
}
