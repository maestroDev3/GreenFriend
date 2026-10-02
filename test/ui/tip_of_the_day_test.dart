import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/species.dart';
import 'package:green_friend/domain/tips.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/fake_tip_catalog.dart';
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

final tips = FakeTipCatalog([
  CareTip(
    id: 'monstera',
    texts: const {'en': 'Give it a moss pole.', 'de': 'Gib ihr einen Moosstab.'},
    genus: 'Monstera',
  ),
  CareTip(
    id: 'general',
    texts: const {'en': 'Check the soil first.', 'de': 'Erst die Erde prüfen.'},
  ),
]);

/// On this day the tip for the user's plants is shown (the other days
/// alternate with general tips).
final plantTipDay = DateTime(2026, 10, 3, 9);

Plant monty() => Plant(id: '1', name: 'Monty', speciesId: monstera.id);

Future<SettingsController> loadedSettings(FakeSettingsRepository repo) async {
  final settings = SettingsController(repo);
  await settings.load();
  return settings;
}

Widget home(FakePlantRepository plants, DateTime now) => HomeScreen(
  plants: plants,
  careLogs: FakeCareLogRepository(),
  journal: FakeJournalRepository(),
  photos: FakePhotoStore(),
  photoPicker: FakePhotoPicker(),
  species: FakeSpeciesCatalog([monstera]),
  tips: tips,
  clock: () => now,
);

void main() {
  group('tip of the day on the home screen', () {
    testWidgets('shows the tip for one of my plants', (tester) async {
      await tester.pumpApp(
        home(FakePlantRepository([monty()]), plantTipDay),
        settings: await loadedSettings(FakeSettingsRepository()),
      );

      expect(find.text('Tip of the day'), findsOneWidget);
      expect(find.text('Give it a moss pole.'), findsOneWidget);
      expect(find.text('For your Monty'), findsOneWidget);
    });

    testWidgets('shows a general tip on the next day', (tester) async {
      await tester.pumpApp(
        home(
          FakePlantRepository([monty()]),
          plantTipDay.add(const Duration(days: 1)),
        ),
        settings: await loadedSettings(FakeSettingsRepository()),
      );

      expect(find.text('Check the soil first.'), findsOneWidget);
      expect(find.textContaining('For your'), findsNothing);
    });

    testWidgets('is shown in German', (tester) async {
      await tester.pumpApp(
        home(FakePlantRepository([monty()]), plantTipDay),
        locale: const Locale('de'),
        settings: await loadedSettings(FakeSettingsRepository()),
      );

      expect(find.text('Tipp des Tages'), findsOneWidget);
      expect(find.text('Gib ihr einen Moosstab.'), findsOneWidget);
    });

    testWidgets('stays hidden for the day after closing it', (tester) async {
      final repository = FakeSettingsRepository();
      await tester.pumpApp(
        home(FakePlantRepository([monty()]), plantTipDay),
        settings: await loadedSettings(repository),
      );

      await tester.tap(find.byTooltip('Hide tip for today'));
      await tester.pumpAndSettle();

      expect(find.text('Tip of the day'), findsNothing);
      expect(repository.tipDismissedOn, DateTime.utc(2026, 10, 3));

      // After a restart on the same day it is still hidden.
      await tester.pumpApp(
        home(FakePlantRepository([monty()]), plantTipDay),
        settings: await loadedSettings(repository),
      );
      expect(find.text('Tip of the day'), findsNothing);

      // The next day it is back.
      await tester.pumpApp(
        home(
          FakePlantRepository([monty()]),
          plantTipDay.add(const Duration(days: 1)),
        ),
        settings: await loadedSettings(repository),
      );
      expect(find.text('Tip of the day'), findsOneWidget);
    });

    testWidgets('is not shown without plants', (tester) async {
      await tester.pumpApp(
        home(FakePlantRepository(), plantTipDay),
        settings: await loadedSettings(FakeSettingsRepository()),
      );

      expect(find.text('Tip of the day'), findsNothing);
    });
  });
}
