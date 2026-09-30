import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/calendar_screen.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Plant olive() => Plant(
  id: '1',
  name: 'Olive',
  pruningIntervalMonths: 12,
  lastPrunedOn: DateTime(2025, 7, 30),
);

Future<void> pumpDetail(
  WidgetTester tester,
  FakePlantRepository plants,
  FakeCareLogRepository logs, {
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    PlantDetailScreen(
      species: FakeSpeciesCatalog(const []),
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      photoPicker: FakePhotoPicker(),
      plants: plants,
      careLogs: logs,
      plantId: '1',
      clock: fixedNow,
    ),
    locale: locale,
  );
}

Future<void> tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.scrollUntilVisible(button, 100);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('pruning', () {
    testWidgets('the detail shows a pruning card and confirms it', (
      tester,
    ) async {
      final plants = FakePlantRepository([olive()]);
      final logs = FakeCareLogRepository();
      await pumpDetail(tester, plants, logs);

      await tester.scrollUntilVisible(find.text('Pruning'), 100);
      expect(find.text('Pruning overdue by 2 months'), findsOneWidget);
      expect(find.text('Every 12 months'), findsOneWidget);

      await tapButton(tester, 'Pruned');

      expect(find.text('Olive pruned'), findsOneWidget);
      expect(find.text('Prune in 12 months'), findsOneWidget);
      expect(plants.plants.single.lastPrunedOn, DateTime.utc(2026, 9, 30));
      expect(logs.logs.single.kind, const Prune());
    });

    testWidgets('the history shows pruning', (tester) async {
      await pumpDetail(
        tester,
        FakePlantRepository([olive()]),
        FakeCareLogRepository([
          CareLog(
            id: 'l',
            plantId: '1',
            kind: const Prune(),
            day: DateTime(2026, 9, 1),
          ),
        ]),
      );

      final entry = find.widgetWithText(ListTile, 'Pruned');
      await tester.scrollUntilVisible(entry, 100);
      expect(entry, findsOneWidget);
    });

    testWidgets('the calendar lists pruning', (tester) async {
      await tester.pumpApp(
        CalendarScreen(
          plants: FakePlantRepository([olive()]),
          careLogs: FakeCareLogRepository(),
          clock: fixedNow,
        ),
      );

      expect(find.text('Prune Olive'), findsOneWidget);
    });

    testWidgets('shows the pruning texts in German', (tester) async {
      await pumpDetail(
        tester,
        FakePlantRepository([olive()]),
        FakeCareLogRepository(),
        locale: const Locale('de'),
      );

      await tester.scrollUntilVisible(find.text('Zurückschneiden'), 100);
      expect(
        find.text('Zurückschneiden seit 2 Monaten überfällig'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FilledButton, 'Zurückgeschnitten'),
        findsOneWidget,
      );
    });
  });
}
