import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/home_screen.dart';

import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';
import '../support/fake_species_catalog.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> openNewPlantForm(
  WidgetTester tester,
  FakePlantRepository repo,
) async {
  await tester.pumpApp(
    HomeScreen(
      species: FakeSpeciesCatalog(const []),
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      photoPicker: FakePhotoPicker(),
      careLogs: FakeCareLogRepository(),
      plants: repo,
      clock: fixedNow,
    ),
  );
  await tester.tap(find.text('Add plant'));
  await tester.pumpAndSettle();
  await tester.enterText(field('Name'), 'Monstera');
}

Future<void> save(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save'));
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('watering interval in the plant form', () {
    testWidgets('saves the interval with today as last watering', (
      tester,
    ) async {
      final repository = FakePlantRepository();
      await openNewPlantForm(tester, repository);

      await tester.enterText(field('Water every (days)'), '7');
      await tester.pumpAndSettle();
      expect(find.text('Last watered: Sep 30, 2026'), findsOneWidget);
      await save(tester);

      final plant = repository.plants.single;
      expect(plant.wateringIntervalDays, 7);
      expect(plant.lastWateredOn, DateTime.utc(2026, 9, 30));
    });

    testWidgets('hides the last watering without an interval', (tester) async {
      final repository = FakePlantRepository();
      await openNewPlantForm(tester, repository);

      expect(find.textContaining('Last watered'), findsNothing);
      await save(tester);

      expect(repository.plants.single.wateringIntervalDays, isNull);
    });

    for (final input in ['0', '366', 'abc']) {
      testWidgets('rejects "$input" as interval', (tester) async {
        final repository = FakePlantRepository();
        await openNewPlantForm(tester, repository);

        await tester.enterText(field('Water every (days)'), input);
        await save(tester);

        expect(find.text('Enter a number from 1 to 365'), findsOneWidget);
        expect(repository.plants, isEmpty);
      });
    }

    testWidgets('shows the stored interval and last watering when editing', (
      tester,
    ) async {
      final repository = FakePlantRepository([
        Plant(
          id: '1',
          name: 'Monstera',
          wateringIntervalDays: 5,
          lastWateredOn: DateTime(2026, 9, 27),
        ),
      ]);
      await tester.pumpApp(
        HomeScreen(
          species: FakeSpeciesCatalog(const []),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          careLogs: FakeCareLogRepository(),
          plants: repository,
          clock: fixedNow,
        ),
      );

      await tester.tap(find.text('Monstera'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit plant'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, '5'), findsOneWidget);
      expect(find.text('Last watered: Sep 27, 2026'), findsOneWidget);
    });

    testWidgets('removes the schedule when the interval is cleared', (
      tester,
    ) async {
      final repository = FakePlantRepository([
        Plant(
          id: '1',
          name: 'Monstera',
          wateringIntervalDays: 5,
          lastWateredOn: DateTime(2026, 9, 27),
        ),
      ]);
      await tester.pumpApp(
        HomeScreen(
          species: FakeSpeciesCatalog(const []),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          careLogs: FakeCareLogRepository(),
          plants: repository,
          clock: fixedNow,
        ),
      );
      await tester.tap(find.text('Monstera'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit plant'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, '5'), '');
      await save(tester);

      expect(repository.plants.single.wateringIntervalDays, isNull);
    });

    testWidgets('shows the interval texts in German', (tester) async {
      await tester.pumpApp(
        HomeScreen(
          species: FakeSpeciesCatalog(const []),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          careLogs: FakeCareLogRepository(),
          plants: FakePlantRepository(),
          clock: fixedNow,
        ),
        locale: const Locale('de'),
      );
      await tester.tap(find.text('Pflanze hinzufügen'));
      await tester.pumpAndSettle();

      await tester.enterText(field('Gießen alle (Tage)'), '3');
      await tester.pumpAndSettle();

      expect(find.textContaining('Zuletzt gegossen:'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);
    });
  });
}
