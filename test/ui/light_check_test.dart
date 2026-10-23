import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/species.dart';
import 'package:green_friend/ui/light_check_screen.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_light_sensor.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
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

Future<void> pumpDetail(
  WidgetTester tester,
  FakeLightSensor sensor, {
  String? speciesId = 'monstera-deliciosa',
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    PlantDetailScreen(
      species: FakeSpeciesCatalog([monstera]),
      plants: FakePlantRepository([
        Plant(id: 'p', name: 'Monty', speciesId: speciesId),
      ]),
      careLogs: FakeCareLogRepository(),
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      photoPicker: FakePhotoPicker(),
      plantId: 'p',
      lightSensor: sensor,
      clock: () => DateTime(2026, 10, 17, 10),
    ),
    locale: locale,
  );
}

Future<void> measure(
  WidgetTester tester,
  FakeLightSensor sensor,
  List<double> readings, {
  String tooltip = 'Light check',
}) async {
  await tester.tap(find.byTooltip(tooltip));
  await tester.pumpAndSettle();
  for (final lux in readings) {
    sensor.emit(lux);
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.pump(const Duration(seconds: 3));
  await tester.pump();
}

void main() {
  group('light check', () {
    testWidgets('after measuring, the screen shows the lux value and the '
        'verdict for the species', (tester) async {
      final sensor = FakeLightSensor();
      await pumpDetail(tester, sensor);

      await measure(tester, sensor, [1000, 1400]);

      expect(find.byType(LightCheckScreen), findsOneWidget);
      expect(find.text('1,200 lx'), findsOneWidget);
      expect(find.text('Too dark for Monty'), findsOneWidget);
      expect(find.text('Needs: Bright, no direct sun'), findsOneWidget);
    });

    testWidgets('after measuring, the verdict says when the light is fine', (
      tester,
    ) async {
      final sensor = FakeLightSensor();
      await pumpDetail(tester, sensor);

      await measure(tester, sensor, [5000]);

      expect(find.text('Good light for Monty'), findsOneWidget);
    });

    testWidgets('measuring again starts a new measurement', (tester) async {
      final sensor = FakeLightSensor();
      await pumpDetail(tester, sensor);
      await measure(tester, sensor, [30000]);
      expect(find.text('Too bright for Monty'), findsOneWidget);

      await tester.tap(find.text('Measure again'));
      await tester.pump();
      sensor.emit(5000);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(find.text('Good light for Monty'), findsOneWidget);
      expect(sensor.listens, 2);
    });

    testWidgets('without species only the lux value is shown', (tester) async {
      final sensor = FakeLightSensor();
      await pumpDetail(tester, sensor, speciesId: null);

      await measure(tester, sensor, [800]);

      expect(find.text('800 lx'), findsOneWidget);
      expect(find.text('Shady spot'), findsOneWidget);
      expect(find.textContaining('Monty'), findsNothing);
    });

    testWidgets('without sensor an explanation is shown', (tester) async {
      await pumpDetail(tester, FakeLightSensor(available: false));

      await tester.tap(find.byTooltip('Light check'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This phone has no light sensor, so the light cannot be measured.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the light check in German', (tester) async {
      final sensor = FakeLightSensor();
      await pumpDetail(tester, sensor, locale: const Locale('de'));

      await measure(tester, sensor, [1000, 1400], tooltip: 'Lichtcheck');

      expect(find.text('1.200 lx'), findsOneWidget);
      expect(find.text('Zu dunkel für Monty'), findsOneWidget);
    });
  });
}
