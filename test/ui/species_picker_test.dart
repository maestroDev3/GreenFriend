import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/species.dart';
import 'package:green_friend/ui/plant_form_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

final monstera = Species(
  id: 'monstera-deliciosa',
  scientificName: 'Monstera deliciosa',
  names: const {
    'en': ['Swiss cheese plant', 'Monstera'],
    'de': ['Fensterblatt', 'Monstera'],
  },
  wateringIntervalDays: 7,
  fertilizingIntervalDays: 14,
  repottingIntervalMonths: 24,
  pruningIntervalMonths: 12,
  light: Light.brightIndirect,
  humidity: Humidity.medium,
);

final snakePlant = Species(
  id: 'dracaena-trifasciata',
  scientificName: 'Dracaena trifasciata',
  names: const {
    'en': ['Snake plant'],
    'de': ['Bogenhanf'],
  },
  wateringIntervalDays: 21,
  fertilizingIntervalDays: 30,
  repottingIntervalMonths: 36,
  light: Light.medium,
  humidity: Humidity.low,
);

Finder field(String label) => find.widgetWithText(TextFormField, label);

Finder get formList => find.byType(Scrollable).first;

String textOf(WidgetTester tester, String label) =>
    tester.widget<TextFormField>(field(label)).controller!.text;

Future<void> pumpForm(
  WidgetTester tester,
  FakePlantRepository plants, {
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    PlantFormScreen(
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      plants: plants,
      careLogs: FakeCareLogRepository(),
      species: FakeSpeciesCatalog([monstera, snakePlant]),
      clock: fixedNow,
    ),
    locale: locale,
  );
}

Future<void> enter(WidgetTester tester, Finder finder, String text) async {
  await tester.scrollUntilVisible(finder, 100, scrollable: formList);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

Future<void> pick(
  WidgetTester tester,
  String query,
  String option, {
  String label = 'Species (optional)',
}) async {
  await enter(tester, field(label), query);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Save'), 100, scrollable: formList);
  await tester.ensureVisible(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('species picker in the plant form', () {
    testWidgets('suggests matching species while typing', (tester) async {
      await pumpForm(tester, FakePlantRepository());

      await enter(tester, field('Species (optional)'), 'swiss');

      expect(find.text('Swiss cheese plant'), findsOneWidget);
      expect(find.text('Monstera deliciosa'), findsOneWidget);
      expect(find.text('Snake plant'), findsNothing);
    });

    testWidgets('fills the species and care intervals and saves them', (
      tester,
    ) async {
      final plants = FakePlantRepository();
      await pumpForm(tester, plants);

      await enter(tester, field('Name'), 'Monty');
      await pick(tester, 'swiss', 'Swiss cheese plant');

      expect(textOf(tester, 'Species (optional)'), 'Swiss cheese plant');
      expect(textOf(tester, 'Water every (days)'), '7');
      expect(textOf(tester, 'Fertilize every (days)'), '14');
      expect(textOf(tester, 'Repot every (months)'), '24');
      await save(tester);

      final plant = plants.plants.single;
      expect(plant.species, 'Swiss cheese plant');
      expect(plant.speciesId, 'monstera-deliciosa');
      expect(plant.wateringIntervalDays, 7);
      expect(plant.fertilizingIntervalDays, 14);
      expect(plant.repottingIntervalMonths, 24);
    });

    testWidgets('fills the pruning interval or clears it', (tester) async {
      final plants = FakePlantRepository();
      await pumpForm(tester, plants);

      await enter(tester, field('Name'), 'Monty');
      await pick(tester, 'swiss', 'Swiss cheese plant');
      await tester.scrollUntilVisible(
        field('Prune every (months)'),
        100,
        scrollable: formList,
      );
      expect(textOf(tester, 'Prune every (months)'), '12');

      await tester.scrollUntilVisible(
        field('Species (optional)'),
        -100,
        scrollable: formList,
      );
      await pick(tester, 'snake', 'Snake plant');
      await tester.scrollUntilVisible(
        field('Prune every (months)'),
        100,
        scrollable: formList,
      );
      expect(textOf(tester, 'Prune every (months)'), '');
      await save(tester);

      expect(plants.plants.single.pruningIntervalMonths, isNull);
      expect(plants.plants.single.speciesId, 'dracaena-trifasciata');
    });

    testWidgets('keeps intervals changed after picking', (tester) async {
      final plants = FakePlantRepository();
      await pumpForm(tester, plants);

      await enter(tester, field('Name'), 'Monty');
      await pick(tester, 'swiss', 'Swiss cheese plant');
      await enter(tester, field('Water every (days)'), '5');
      await save(tester);

      final plant = plants.plants.single;
      expect(plant.wateringIntervalDays, 5);
      expect(plant.speciesId, 'monstera-deliciosa');
    });

    testWidgets('unlinks the species when its text is edited', (tester) async {
      final plants = FakePlantRepository();
      await pumpForm(tester, plants);

      await enter(tester, field('Name'), 'Monty');
      await pick(tester, 'swiss', 'Swiss cheese plant');
      await enter(tester, field('Species (optional)'), 'Some other plant');
      await save(tester);

      final plant = plants.plants.single;
      expect(plant.species, 'Some other plant');
      expect(plant.speciesId, isNull);
      expect(plant.wateringIntervalDays, 7);
    });

    testWidgets('suggests German names in German', (tester) async {
      final plants = FakePlantRepository();
      await pumpForm(tester, plants, locale: const Locale('de'));

      await enter(tester, field('Name'), 'Monty');
      await pick(tester, 'fenster', 'Fensterblatt', label: 'Art (optional)');
      await tester.scrollUntilVisible(
        find.text('Speichern'),
        100,
        scrollable: formList,
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(plants.plants.single.species, 'Fensterblatt');
      expect(plants.plants.single.speciesId, 'monstera-deliciosa');
    });
  });
}
