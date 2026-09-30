import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/species.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

final monsteraProfile = Species(
  id: 'monstera-deliciosa',
  scientificName: 'Monstera deliciosa',
  names: const {
    'en': ['Swiss cheese plant'],
    'de': ['Fensterblatt'],
  },
  wateringIntervalDays: 7,
  fertilizingIntervalDays: 14,
  repottingIntervalMonths: 24,
  light: Light.brightIndirect,
  humidity: Humidity.high,
);

Plant plant({String? speciesId}) => Plant(
  id: '1',
  name: 'Monty',
  species: 'Swiss cheese plant',
  speciesId: speciesId,
  wateringIntervalDays: 7,
);

Future<void> pumpDetail(
  WidgetTester tester,
  Plant plant, {
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    PlantDetailScreen(
      species: FakeSpeciesCatalog([monsteraProfile]),
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      photoPicker: FakePhotoPicker(),
      careLogs: FakeCareLogRepository(),
      plants: FakePlantRepository([plant]),
      plantId: '1',
      clock: fixedNow,
    ),
    locale: locale,
  );
}

void main() {
  group('care profile on the plant detail', () {
    testWidgets('shows light and humidity needs of the species', (
      tester,
    ) async {
      await pumpDetail(tester, plant(speciesId: 'monstera-deliciosa'));

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Bright, no direct sun'), findsOneWidget);
      expect(find.text('Humidity'), findsOneWidget);
      expect(find.text('High – mist or use a humidifier'), findsOneWidget);
    });

    testWidgets('shows nothing without a species', (tester) async {
      await pumpDetail(tester, plant());

      expect(find.text('Light'), findsNothing);
      expect(find.text('Humidity'), findsNothing);
    });

    testWidgets('shows nothing for an unknown species', (tester) async {
      await pumpDetail(tester, plant(speciesId: 'gone'));

      expect(find.text('Light'), findsNothing);
      expect(find.text('Humidity'), findsNothing);
    });

    testWidgets('shows the texts in German', (tester) async {
      await pumpDetail(
        tester,
        plant(speciesId: 'monstera-deliciosa'),
        locale: const Locale('de'),
      );

      expect(find.text('Licht'), findsOneWidget);
      expect(find.text('Hell, ohne direkte Sonne'), findsOneWidget);
      expect(find.text('Luftfeuchte'), findsOneWidget);
      expect(
        find.text('Hoch – besprühen oder Luftbefeuchter'),
        findsOneWidget,
      );
    });
  });
}
