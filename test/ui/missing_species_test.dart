import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/identification.dart';
import 'package:green_friend/domain/missing_species.dart';
import 'package:green_friend/domain/species.dart';
import 'package:green_friend/ui/missing_species_screen.dart';
import 'package:green_friend/ui/plant_form_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_missing_species_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_identifier.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

final monstera = Species(
  id: 'monstera-deliciosa',
  scientificName: 'Monstera deliciosa',
  names: const {
    'en': ['Swiss cheese plant'],
  },
  wateringIntervalDays: 7,
  fertilizingIntervalDays: 14,
  repottingIntervalMonths: 24,
  light: Light.brightIndirect,
  humidity: Humidity.medium,
);

Future<void> identifyAndPick(
  WidgetTester tester,
  FakeMissingSpeciesRepository missing,
  String scientificName,
) async {
  final settings = SettingsController(
    FakeSettingsRepository(plantIdApiKey: 'k'),
  );
  await settings.load();
  await tester.pumpApp(
    PlantFormScreen(
      plants: FakePlantRepository(),
      careLogs: FakeCareLogRepository(),
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      species: FakeSpeciesCatalog([monstera]),
      photoPicker: FakePhotoPicker(),
      identifier: FakePlantIdentifier(
        candidates: [
          IdentificationCandidate(
            scientificName: 'Monstera deliciosa',
            commonNames: const ['Swiss cheese plant'],
            probability: 0.6,
          ),
          IdentificationCandidate(
            scientificName: 'Aloe aristata',
            commonNames: const ['Lace aloe'],
            probability: 0.3,
          ),
        ],
      ),
      missingSpecies: missing,
      clock: () => DateTime(2026, 10, 14, 9),
    ),
    settings: settings,
  );
  await tester.tap(find.text('Identify from photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Take photo'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(scientificName));
  await tester.pumpAndSettle();
}

void main() {
  group('missing species', () {
    testWidgets('remembers a picked species that is not in the database', (
      tester,
    ) async {
      final missing = FakeMissingSpeciesRepository();

      await identifyAndPick(tester, missing, 'Aloe aristata');

      expect(missing.species.single.scientificName, 'Aloe aristata');
      expect(missing.species.single.commonName, 'Lace aloe');
    });

    testWidgets('does not remember a species from the database', (
      tester,
    ) async {
      final missing = FakeMissingSpeciesRepository();

      await identifyAndPick(tester, missing, 'Monstera deliciosa');

      expect(missing.species, isEmpty);
    });

    testWidgets('lists them and can clear the list', (tester) async {
      final missing = FakeMissingSpeciesRepository([
        MissingSpecies(
          scientificName: 'Aloe aristata',
          commonName: 'Lace aloe',
          count: 2,
          lastSeen: DateTime.utc(2026, 10, 14),
        ),
      ]);
      await tester.pumpApp(MissingSpeciesScreen(repository: missing));

      expect(find.text('Lace aloe'), findsOneWidget);
      expect(find.textContaining('Aloe aristata'), findsOneWidget);
      expect(find.textContaining('2×'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear list'));
      await tester.pumpAndSettle();

      expect(missing.species, isEmpty);
      expect(
        find.textContaining('Species found by photo identification'),
        findsOneWidget,
      );
    });
  });
}
