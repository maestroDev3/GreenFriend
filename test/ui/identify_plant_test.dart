import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/identification.dart';
import 'package:green_friend/domain/species.dart';
import 'package:green_friend/ui/plant_form_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_identifier.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime.utc(2026, 5, 10, 9);

final monstera = Species(
  id: 'monstera-deliciosa',
  scientificName: 'Monstera deliciosa',
  names: const {
    'en': ['Swiss cheese plant', 'Monstera'],
  },
  wateringIntervalDays: 7,
  fertilizingIntervalDays: 14,
  repottingIntervalMonths: 24,
  light: Light.brightIndirect,
  humidity: Humidity.medium,
);

final weepingFig = Species(
  id: 'ficus-benjamina',
  scientificName: 'Ficus benjamina',
  names: const {
    'en': ['Weeping fig'],
  },
  wateringIntervalDays: 10,
  fertilizingIntervalDays: 30,
  repottingIntervalMonths: 24,
  light: Light.brightIndirect,
  humidity: Humidity.medium,
);

final candidates = [
  IdentificationCandidate(
    scientificName: 'Monstera deliciosa',
    commonNames: const ['Swiss cheese plant'],
    probability: 0.91,
  ),
  IdentificationCandidate(
    scientificName: 'Ficus elastica',
    commonNames: const ['Rubber plant'],
    probability: 0.06,
  ),
  IdentificationCandidate(
    scientificName: 'Aloe vera',
    commonNames: const ['Aloe'],
    probability: 0.02,
  ),
  IdentificationCandidate(
    scientificName: 'Yucca elephantipes',
    commonNames: const ['Yucca'],
    probability: 0.01,
  ),
];

class Setup {
  Setup({FakePlantIdentifier? identifier})
    : identifier = identifier ?? FakePlantIdentifier(candidates: candidates);

  final plants = FakePlantRepository();
  final journal = FakeJournalRepository();
  final photos = FakePhotoStore();
  final picker = FakePhotoPicker();
  final FakePlantIdentifier identifier;

  Widget form() => PlantFormScreen(
    plants: plants,
    careLogs: FakeCareLogRepository(),
    journal: journal,
    photos: photos,
    species: FakeSpeciesCatalog([monstera, weepingFig]),
    photoPicker: picker,
    identifier: identifier,
    clock: fixedNow,
  );
}

Future<SettingsController> settingsWithKey(String? key) async {
  final settings = SettingsController(
    FakeSettingsRepository(plantIdApiKey: key),
  );
  await settings.load();
  return settings;
}

Future<void> identifyWithCamera(WidgetTester tester) async {
  await tester.tap(find.text('Identify from photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Take photo'));
  await tester.pumpAndSettle();
}

String fieldText(WidgetTester tester, String label) => tester
    .widget<TextFormField>(find.widgetWithText(TextFormField, label))
    .controller!
    .text;

void main() {
  group('Identify from photo', () {
    testWidgets('without a key explains where to enter it', (tester) async {
      final setup = Setup();
      await tester.pumpApp(setup.form(), settings: await settingsWithKey(null));

      await tester.tap(find.text('Identify from photo'));
      await tester.pumpAndSettle();

      expect(find.text('API key needed'), findsOneWidget);
      expect(setup.picker.requests, isEmpty);
      expect(setup.identifier.calls, isEmpty);
    });

    testWidgets('shows the three best candidates with their probability', (
      tester,
    ) async {
      final setup = Setup();
      await tester.pumpApp(setup.form(), settings: await settingsWithKey('k'));

      await identifyWithCamera(tester);

      expect(setup.picker.requests, ['camera']);
      expect(setup.identifier.calls.single.apiKey, 'k');
      expect(setup.identifier.calls.single.languageCode, 'en');
      expect(find.text('Which plant is it?'), findsOneWidget);
      expect(find.text('Monstera deliciosa'), findsOneWidget);
      expect(find.text('Ficus elastica'), findsOneWidget);
      expect(find.text('Aloe vera'), findsOneWidget);
      expect(find.text('Yucca elephantipes'), findsNothing);
      expect(find.text('91%'), findsOneWidget);
      expect(find.text('Uncertain'), findsNWidgets(2));
      expect(find.text('Enter manually'), findsOneWidget);
    });

    testWidgets('fills the form from the matching species', (tester) async {
      final setup = Setup();
      await tester.pumpApp(setup.form(), settings: await settingsWithKey('k'));

      await identifyWithCamera(tester);
      await tester.tap(find.text('Monstera deliciosa'));
      await tester.pumpAndSettle();

      expect(fieldText(tester, 'Name'), 'Swiss cheese plant');
      expect(fieldText(tester, 'Species (optional)'), 'Swiss cheese plant');
      expect(fieldText(tester, 'Water every (days)'), '7');
      expect(
        find.text('Care values from the plant database – adjust them if needed.'),
        findsOneWidget,
      );
    });

    testWidgets('uses a species of the same genus as a template', (
      tester,
    ) async {
      final setup = Setup();
      await tester.pumpApp(setup.form(), settings: await settingsWithKey('k'));

      await identifyWithCamera(tester);
      await tester.tap(find.text('Ficus elastica'));
      await tester.pumpAndSettle();

      expect(fieldText(tester, 'Name'), 'Rubber plant');
      expect(fieldText(tester, 'Species (optional)'), 'Ficus elastica');
      expect(fieldText(tester, 'Water every (days)'), '10');
      expect(
        find.text(
          'Care intervals taken from Weeping fig (same genus) – adjust them '
          'if needed.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('leaves the intervals empty for an unknown species', (
      tester,
    ) async {
      final setup = Setup();
      await tester.pumpApp(setup.form(), settings: await settingsWithKey('k'));

      await identifyWithCamera(tester);
      await tester.tap(find.text('Aloe vera'));
      await tester.pumpAndSettle();

      expect(fieldText(tester, 'Name'), 'Aloe');
      expect(fieldText(tester, 'Species (optional)'), 'Aloe vera');
      expect(fieldText(tester, 'Water every (days)'), '');
      expect(
        find.text(
          'Aloe vera is not in the plant database yet – please enter the '
          'care intervals.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('saves the plant and its photo as a journal entry', (
      tester,
    ) async {
      final setup = Setup();
      await tester.pumpApp(setup.form(), settings: await settingsWithKey('k'));

      await identifyWithCamera(tester);
      await tester.tap(find.text('Monstera deliciosa'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final plant = setup.plants.plants.single;
      expect(plant.name, 'Swiss cheese plant');
      expect(plant.speciesId, 'monstera-deliciosa');
      expect(plant.wateringIntervalDays, 7);
      final entry = setup.journal.entries.single;
      expect(entry.plantId, plant.id);
      expect(entry.photo, 'photo-1.jpg');
      expect(entry.day, DateTime.utc(2026, 5, 10));
      expect(setup.photos.stored, {'photo-1.jpg'});
    });

    testWidgets('deletes the photo when the form is left without saving', (
      tester,
    ) async {
      final setup = Setup();
      await tester.pumpApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => setup.form()),
            ),
            child: const Text('open'),
          ),
        ),
        settings: await settingsWithKey('k'),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await identifyWithCamera(tester);
      await tester.tap(find.text('Enter manually'));
      await tester.pumpAndSettle();
      expect(setup.photos.stored, {'photo-1.jpg'});

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(setup.photos.stored, isEmpty);
      expect(setup.journal.entries, isEmpty);
    });

    testWidgets('shows a message when the key is rejected', (tester) async {
      final setup = Setup(
        identifier: FakePlantIdentifier(failure: const InvalidApiKey()),
      );
      await tester.pumpApp(setup.form(), settings: await settingsWithKey('k'));

      await identifyWithCamera(tester);

      expect(
        find.text(
          'The plant.id API key was rejected. Please check it in the settings.',
        ),
        findsOneWidget,
      );
      expect(find.text('Which plant is it?'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
    });

    testWidgets('shows a message when the service is not reachable', (
      tester,
    ) async {
      final setup = Setup(
        identifier: FakePlantIdentifier(failure: const ServiceUnavailable()),
      );
      await tester.pumpApp(setup.form(), settings: await settingsWithKey('k'));

      await identifyWithCamera(tester);

      expect(
        find.text(
          'Plant identification is not reachable. Check your internet '
          'connection and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('is not offered when editing a plant', (tester) async {
      final setup = Setup();
      await setup.plants.add(name: 'Monty');
      await tester.pumpApp(
        PlantFormScreen(
          plants: setup.plants,
          careLogs: FakeCareLogRepository(),
          journal: setup.journal,
          photos: setup.photos,
          species: FakeSpeciesCatalog([monstera]),
          photoPicker: setup.picker,
          identifier: setup.identifier,
          plant: setup.plants.plants.single,
          clock: fixedNow,
        ),
        settings: await settingsWithKey('k'),
      );

      expect(find.text('Identify from photo'), findsNothing);
    });
  });
}
