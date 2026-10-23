@Tags(['screenshot'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/bundled_species_catalog.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/identification.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/calendar_screen.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';
import 'package:green_friend/ui/plant_form_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_identifier.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';

/// A typical phone: 1080 × 2340 pixels.
const pixels = Size(1080, 2340);
const pixelRatio = 2.625;

DateTime now() => DateTime(2026, 5, 12, 9);

final species = BundledSpeciesCatalog();

/// Demo plants in the screenshot's language.
List<Plant> demoPlants(String locale) {
  final de = locale.startsWith('de');
  return [
    Plant(
      id: 'monty',
      name: 'Monty',
      species: 'Monstera deliciosa',
      speciesId: 'monstera-deliciosa',
      location: de ? 'Wohnzimmer' : 'Living room',
      wateringIntervalDays: 7,
      lastWateredOn: DateTime(2026, 5, 5),
      fertilizingIntervalDays: 14,
      lastFertilizedOn: DateTime(2026, 5, 1),
      potDiameterCm: 17,
    ),
    Plant(
      id: 'basil',
      name: de ? 'Basilikum' : 'Basil',
      species: 'Ocimum basilicum',
      speciesId: 'ocimum-basilicum',
      wateringIntervalDays: 2,
      lastWateredOn: DateTime(2026, 5, 9),
      outdoor: true,
    ),
    Plant(
      id: 'aloe',
      name: 'Aloe',
      species: 'Aloe vera',
      speciesId: 'aloe-vera',
      wateringIntervalDays: 14,
      lastWateredOn: DateTime(2026, 5, 4),
    ),
    Plant(
      id: 'ficus',
      name: 'Ficus',
      species: 'Ficus lyrata',
      speciesId: 'ficus-lyrata',
      wateringIntervalDays: 7,
      lastWateredOn: DateTime(2026, 5, 9),
      fertilizingIntervalDays: 14,
      lastFertilizedOn: DateTime(2026, 4, 30),
    ),
  ];
}

List<CareLog> demoLogs() => [
  for (var day = 1; day <= 11; day += 2)
    CareLog(
      id: 'log-$day',
      plantId: 'monty',
      kind: const Water(),
      day: DateTime(2026, 5, day),
    ),
];

Future<void> loadFonts() async {
  Future<void> load(String family, Future<ByteData> data) async {
    await (FontLoader(family)..addFont(data)).load();
  }

  await load('Inter', rootBundle.load('assets/fonts/Inter-Variable.ttf'));
  await load(
    'PlayfairDisplay',
    rootBundle.load('assets/fonts/PlayfairDisplay-Variable.ttf'),
  );
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    await load(
      'MaterialIcons',
      icons.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  }
}

Future<void> shoot(
  WidgetTester tester,
  Widget screen,
  String locale,
  String name, {
  SettingsController? settings,
  Future<void> Function()? before,
}) async {
  // Real shadows instead of the test framework's solid outlines.
  debugDisableShadows = false;
  addTearDown(() => debugDisableShadows = true);
  // Touch mode: no keyboard focus frames in the pictures.
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
  await tester.pumpApp(
    screen,
    locale: Locale(locale.substring(0, 2)),
    settings: settings,
    debugBanner: false,
  );
  tester.view.physicalSize = pixels;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
  await tester.pumpAndSettle();
  if (before != null) await before();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../store/screenshots/$locale/$name.png'),
  );
}

void main() {
  setUpAll(loadFonts);

  for (final locale in ['en-US', 'de-DE']) {
    testWidgets('home screen $locale', (tester) async {
      await shoot(
        tester,
        HomeScreen(
          plants: FakePlantRepository(demoPlants(locale)),
          careLogs: FakeCareLogRepository(),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          species: species,
          clock: now,
        ),
        locale,
        '1_home',
      );
    });

    testWidgets('plant detail $locale', (tester) async {
      await shoot(
        tester,
        PlantDetailScreen(
          plants: FakePlantRepository(demoPlants(locale)),
          careLogs: FakeCareLogRepository(demoLogs()),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          photoPicker: FakePhotoPicker(),
          species: species,
          plantId: 'monty',
          clock: now,
        ),
        locale,
        '2_plant_detail',
      );
    });

    testWidgets('calendar $locale', (tester) async {
      await shoot(
        tester,
        CalendarScreen(
          plants: FakePlantRepository(demoPlants(locale)),
          careLogs: FakeCareLogRepository(demoLogs()),
          clock: now,
        ),
        locale,
        '3_calendar',
      );
    });

    testWidgets('identification $locale', (tester) async {
      final settings = SettingsController(
        FakeSettingsRepository(plantIdApiKey: 'demo'),
      );
      await settings.load();
      await shoot(
        tester,
        PlantFormScreen(
          plants: FakePlantRepository(),
          careLogs: FakeCareLogRepository(),
          journal: FakeJournalRepository(),
          photos: FakePhotoStore(),
          species: species,
          photoPicker: FakePhotoPicker(),
          identifier: FakePlantIdentifier(
            candidates: [
              IdentificationCandidate(
                scientificName: 'Monstera deliciosa',
                commonNames: [
                  locale.startsWith('de')
                      ? 'Fensterblatt'
                      : 'Swiss cheese plant',
                ],
                probability: 0.93,
              ),
              IdentificationCandidate(
                scientificName: 'Philodendron hederaceum',
                commonNames: [
                  locale.startsWith('de')
                      ? 'Kletterphilodendron'
                      : 'Heartleaf philodendron',
                ],
                probability: 0.04,
              ),
              IdentificationCandidate(
                scientificName: 'Epipremnum aureum',
                commonNames: [locale.startsWith('de') ? 'Efeutute' : 'Pothos'],
                probability: 0.02,
              ),
            ],
          ),
          clock: now,
        ),
        locale,
        '4_identification',
        settings: settings,
        before: () async {
          final identify = find.byIcon(Icons.photo_camera_outlined).first;
          await tester.tap(identify);
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.photo_camera_outlined).last);
          await tester.pumpAndSettle();
        },
      );
    });
  }
}
