import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';

import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';
import '../support/fake_species_catalog.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Plant pothos() => Plant(
  id: '1',
  name: 'Pothos',
  fertilizingIntervalDays: 14,
  lastFertilizedOn: DateTime(2026, 9, 20),
  repottingIntervalMonths: 12,
  lastRepottedOn: DateTime(2025, 7, 30),
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
  final button = find.widgetWithText(TextButton, label);
  await tester.scrollUntilVisible(button, 100);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('fertilizing and repotting on the detail page', () {
    testWidgets('shows a card per scheduled care kind', (tester) async {
      await pumpDetail(
        tester,
        FakePlantRepository([pothos()]),
        FakeCareLogRepository(),
      );

      await tester.scrollUntilVisible(find.text('Fertilizing'), 100);
      expect(find.text('Every 14 days'), findsOneWidget);
      expect(find.text('Fertilize in 4 days'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Repotting'), 100);
      expect(find.text('Every 12 months'), findsOneWidget);
      expect(find.text('Repotting overdue by 2 months'), findsOneWidget);
    });

    testWidgets('confirms fertilizing and logs it', (tester) async {
      final plants = FakePlantRepository([pothos()]);
      final logs = FakeCareLogRepository();
      await pumpDetail(tester, plants, logs);

      await tapButton(tester, 'Fertilize');

      expect(find.text('Pothos fertilized'), findsOneWidget);
      expect(plants.plants.single.lastFertilizedOn, DateTime.utc(2026, 9, 30));
      expect(logs.logs.single.kind, const Fertilize());
      await tester.scrollUntilVisible(find.text('Fertilize in 14 days'), -100);
      expect(find.text('Fertilize in 14 days'), findsOneWidget);
    });

    testWidgets('confirms repotting and can undo it', (tester) async {
      final plants = FakePlantRepository([pothos()]);
      final logs = FakeCareLogRepository();
      await pumpDetail(tester, plants, logs);

      await tapButton(tester, 'Repot');
      expect(find.text('Pothos repotted'), findsOneWidget);
      expect(find.text('Repot in 12 months'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(plants.plants.single, pothos());
      expect(logs.logs, isEmpty);
    });

    testWidgets('shows the cards in German', (tester) async {
      await pumpDetail(
        tester,
        FakePlantRepository([pothos()]),
        FakeCareLogRepository(),
        locale: const Locale('de'),
      );

      await tester.scrollUntilVisible(find.text('Umtopfen'), 100);
      expect(find.text('Alle 14 Tage'), findsOneWidget);
      expect(find.text('Alle 12 Monate'), findsOneWidget);
      expect(find.text('Umtopfen seit 2 Monaten überfällig'), findsOneWidget);
    });
  });

  group('fertilizing and repotting on the home screen', () {
    Plant fertilizeToday() => Plant(
      id: '2',
      name: 'Aloe',
      fertilizingIntervalDays: 10,
      lastFertilizedOn: DateTime(2026, 9, 20),
    );

    testWidgets('shows pills for due fertilizing and overdue repotting', (
      tester,
    ) async {
      await tester.pumpApp(
        HomeScreen(
          species: FakeSpeciesCatalog(const []),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          plants: FakePlantRepository([pothos(), fertilizeToday()]),
          careLogs: FakeCareLogRepository(),
          clock: fixedNow,
        ),
      );

      expect(find.text('Fertilize today'), findsOneWidget);
      expect(find.text('Repotting overdue by 2 months'), findsOneWidget);
      expect(find.text('Fertilize in 4 days'), findsNothing);
    });

    testWidgets('counts a plant once in the summary', (tester) async {
      final plant = Plant(
        id: '3',
        name: 'Ficus',
        wateringIntervalDays: 3,
        lastWateredOn: DateTime(2026, 9, 25),
        fertilizingIntervalDays: 10,
        lastFertilizedOn: DateTime(2026, 9, 20),
      );
      await tester.pumpApp(
        HomeScreen(
          species: FakeSpeciesCatalog(const []),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          plants: FakePlantRepository([plant, fertilizeToday()]),
          careLogs: FakeCareLogRepository(),
          clock: fixedNow,
        ),
      );

      expect(find.text('2 of 2 plants need attention today'), findsOneWidget);
    });

    testWidgets('shows the pills in German', (tester) async {
      await tester.pumpApp(
        HomeScreen(
          species: FakeSpeciesCatalog(const []),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          plants: FakePlantRepository([fertilizeToday()]),
          careLogs: FakeCareLogRepository(),
          clock: fixedNow,
        ),
        locale: const Locale('de'),
      );

      expect(find.text('Heute düngen'), findsOneWidget);
    });
  });
}
