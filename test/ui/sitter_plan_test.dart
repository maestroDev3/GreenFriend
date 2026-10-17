import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/sitter_plan.dart';
import 'package:green_friend/domain/vacation.dart';
import 'package:green_friend/l10n/app_localizations.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/settings_screen.dart';
import 'package:green_friend/ui/sitter_plan_text.dart';

import '../support/fake_backup.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';

final vacation = Vacation(
  first: DateTime(2026, 10, 20),
  last: DateTime(2026, 10, 25),
);

final plan = [
  SitterDay(
    day: DateTime.utc(2026, 10, 21),
    entries: const [
      SitterEntry(
        plantName: 'Monstera',
        location: 'Living room',
        kinds: [Water(), Fertilize()],
      ),
      SitterEntry(plantName: 'Aloe', kinds: [Water()]),
    ],
  ),
];

void main() {
  setUpAll(initializeDateFormatting);

  group('sitterPlanText', () {
    test('has a heading, one block per day and one line per plant', () {
      final text = sitterPlanText(
        lookupAppLocalizations(const Locale('en')),
        'en',
        vacation,
        plan,
      );

      expect(
        text,
        'Plant care plan: Oct 20, 2026 – Oct 25, 2026\n'
        '\n'
        'Wed, Oct 21\n'
        '• Monstera (Living room): Water, Fertilize\n'
        '• Aloe: Water\n',
      );
    });

    test('is written in German', () {
      final text = sitterPlanText(
        lookupAppLocalizations(const Locale('de')),
        'de',
        vacation,
        plan,
      );

      expect(text, contains('Pflegeplan'));
      expect(text, contains('• Monstera (Living room): Gießen, Düngen'));
    });

    test('says so when no care is needed', () {
      final text = sitterPlanText(
        lookupAppLocalizations(const Locale('en')),
        'en',
        vacation,
        const [],
      );

      expect(text, contains('No care needed in this period.'));
    });
  });

  testWidgets('the vacation section shares the plan', (tester) async {
    final settings = SettingsController(
      FakeSettingsRepository(vacation: vacation),
    );
    await settings.load();
    final sharing = FakeFileSharing();
    await tester.pumpApp(
      SettingsScreen(
        clock: () => DateTime(2026, 10, 17, 9),
        plants: FakePlantRepository([
          Plant(
            id: 'a',
            name: 'Aloe',
            wateringIntervalDays: 14,
            lastWateredOn: DateTime(2026, 10, 10),
          ),
        ]),
        sharing: sharing,
      ),
      settings: settings,
    );
    await tester.scrollUntilVisible(
      find.text('Share plan for the plant sitter'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share plan for the plant sitter'));
    await tester.pumpAndSettle();

    expect(sharing.sharedTexts.single, contains('• Aloe: Water'));
  });
}
