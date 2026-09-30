import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Plant monstera({int? every = 7}) => Plant(
  id: '1',
  name: 'Monstera',
  wateringIntervalDays: every,
  lastWateredOn: DateTime(2026, 9, 27),
);

void main() {
  group('confirming watering on the home screen', () {
    testWidgets('marks the plant as watered today and logs it', (
      tester,
    ) async {
      final plants = FakePlantRepository([monstera()]);
      final logs = FakeCareLogRepository();
      await tester.pumpApp(
        HomeScreen(plants: plants, careLogs: logs, clock: fixedNow),
      );
      expect(find.text('Water in 4 days'), findsOneWidget);

      await tester.tap(find.text('Watered'));
      await tester.pumpAndSettle();

      expect(find.text('Water in 7 days'), findsOneWidget);
      expect(find.text('Monstera watered'), findsOneWidget);
      expect(plants.plants.single.lastWateredOn, DateTime.utc(2026, 9, 30));
      expect(logs.logs.single.day, DateTime.utc(2026, 9, 30));
    });

    testWidgets('can be undone from the snackbar', (tester) async {
      final plants = FakePlantRepository([monstera()]);
      final logs = FakeCareLogRepository();
      await tester.pumpApp(
        HomeScreen(plants: plants, careLogs: logs, clock: fixedNow),
      );

      await tester.tap(find.text('Watered'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Water in 4 days'), findsOneWidget);
      expect(plants.plants.single.lastWateredOn, DateTime.utc(2026, 9, 27));
      expect(logs.logs, isEmpty);
    });

    testWidgets('offers no button for plants without a schedule', (
      tester,
    ) async {
      await tester.pumpApp(
        HomeScreen(
          plants: FakePlantRepository([monstera(every: null)]),
          careLogs: FakeCareLogRepository(),
          clock: fixedNow,
        ),
      );

      expect(find.text('Watered'), findsNothing);
    });

    testWidgets('shows the texts in German', (tester) async {
      await tester.pumpApp(
        HomeScreen(
          plants: FakePlantRepository([monstera()]),
          careLogs: FakeCareLogRepository(),
          clock: fixedNow,
        ),
        locale: const Locale('de'),
      );

      await tester.tap(find.text('Gegossen'));
      await tester.pumpAndSettle();

      expect(find.text('Monstera gegossen'), findsOneWidget);
      expect(find.text('Rückgängig'), findsOneWidget);
    });
  });

  testWidgets('the detail page confirms watering as well', (tester) async {
    final plants = FakePlantRepository([monstera()]);
    final logs = FakeCareLogRepository();
    await tester.pumpApp(
      PlantDetailScreen(
        plants: plants,
        careLogs: logs,
        plantId: '1',
        clock: fixedNow,
      ),
    );

    await tester.ensureVisible(find.text('Watered'));
    await tester.tap(find.text('Watered'));
    await tester.pumpAndSettle();

    expect(find.text('Water in 7 days'), findsOneWidget);
    expect(logs.logs, hasLength(1));
  });
}
