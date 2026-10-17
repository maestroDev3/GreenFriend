import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/species.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';
import 'package:green_friend/ui/plant_form_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

const fieldLabel = 'Lowest temperature (°C)';

final lemon = Species(
  id: 'citrus-limon',
  scientificName: 'Citrus limon',
  names: const {
    'en': ['Lemon tree'],
    'de': ['Zitronenbaum'],
  },
  wateringIntervalDays: 4,
  fertilizingIntervalDays: 14,
  repottingIntervalMonths: 24,
  light: Light.direct,
  humidity: Humidity.medium,
  minTemperature: 3,
);

Finder field(String label) => find.widgetWithText(TextFormField, label);

Finder get formList => find.byType(Scrollable).first;

Widget form(FakePlantRepository plants, {Plant? plant}) => PlantFormScreen(
  plants: plants,
  careLogs: FakeCareLogRepository(),
  journal: FakeJournalRepository(),
  photos: FakePhotoStore(),
  species: FakeSpeciesCatalog([lemon]),
  plant: plant,
  clock: () => DateTime(2026, 10, 17),
);

Future<void> enter(WidgetTester tester, Finder finder, String text) async {
  await tester.scrollUntilVisible(finder, 100, scrollable: formList);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

Future<void> pumpDetail(
  WidgetTester tester,
  Plant plant, {
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    PlantDetailScreen(
      species: FakeSpeciesCatalog([lemon]),
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      photoPicker: FakePhotoPicker(),
      careLogs: FakeCareLogRepository(),
      plants: FakePlantRepository([plant]),
      plantId: plant.id,
      clock: () => DateTime(2026, 10, 17, 10),
    ),
    locale: locale,
  );
}

Future<void> scrollDetailTo(WidgetTester tester, String text) => tester
    .scrollUntilVisible(find.text(text), 100, scrollable: formList);

void main() {
  group('lowest temperature in the plant form', () {
    testWidgets('choosing a species fills in its value', (tester) async {
      final plants = FakePlantRepository();
      await tester.pumpApp(form(plants));

      await enter(tester, field('Name'), 'Lemmy');
      await enter(tester, field('Species (optional)'), 'Lemon');
      await tester.tap(find.text('Lemon tree').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        field(fieldLabel),
        100,
        scrollable: formList,
      );
      expect(
        tester.widget<TextFormField>(field(fieldLabel)).controller!.text,
        '3',
      );

      await save(tester);
      expect(plants.plants.single.minTemperature, 3);
    });

    testWidgets('choosing a species fills in its value; I can change it, '
        'also below zero', (tester) async {
      final plant = Plant(id: '1', name: 'Lemmy', minTemperature: 3);
      final plants = FakePlantRepository([plant]);
      await tester.pumpApp(form(plants, plant: plant));

      await enter(tester, field(fieldLabel), '-2');
      await save(tester);

      expect(plants.plants.single.minTemperature, -2);
    });

    testWidgets('an empty value leaves the plant without own value', (
      tester,
    ) async {
      final plant = Plant(id: '1', name: 'Lemmy', minTemperature: 3);
      final plants = FakePlantRepository([plant]);
      await tester.pumpApp(form(plants, plant: plant));

      await enter(tester, field(fieldLabel), '');
      await save(tester);

      expect(plants.plants.single.minTemperature, isNull);
    });

    testWidgets('rejects a value outside -30 to 20 °C', (tester) async {
      final plant = Plant(id: '1', name: 'Lemmy');
      final plants = FakePlantRepository([plant]);
      await tester.pumpApp(form(plants, plant: plant));

      await enter(tester, field(fieldLabel), '25');
      await save(tester);

      expect(find.text('Enter a temperature from -30 to 20 °C'), findsOneWidget);
      expect(plants.plants.single.minTemperature, isNull);
    });
  });

  group('lowest temperature on the detail page', () {
    testWidgets('the detail page shows the tolerated minimum', (tester) async {
      await pumpDetail(
        tester,
        Plant(id: '1', name: 'Lemmy', speciesId: 'citrus-limon'),
      );

      await scrollDetailTo(tester, 'Tolerates down to 3 °C');
      expect(find.text('Cold tolerance'), findsOneWidget);
    });

    testWidgets('the detail page shows my own value', (tester) async {
      await pumpDetail(
        tester,
        Plant(
          id: '1',
          name: 'Lemmy',
          speciesId: 'citrus-limon',
          minTemperature: -2,
        ),
      );

      await scrollDetailTo(tester, 'Tolerates down to -2 °C');
    });

    testWidgets('the detail page shows 5 °C without species', (tester) async {
      await pumpDetail(tester, Plant(id: '1', name: 'Lemmy'));

      await scrollDetailTo(tester, 'Tolerates down to 5 °C');
    });

    testWidgets('the detail page shows the tolerated minimum in German', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        Plant(id: '1', name: 'Lemmy', speciesId: 'citrus-limon'),
        locale: const Locale('de'),
      );

      await scrollDetailTo(tester, 'Verträgt bis 3 °C');
      expect(find.text('Kälteverträglichkeit'), findsOneWidget);
    });
  });
}
