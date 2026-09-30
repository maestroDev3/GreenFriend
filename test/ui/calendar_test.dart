import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/calendar_screen.dart';
import 'package:green_friend/ui/home_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

List<Plant> plants() => [
  Plant(
    id: 'm',
    name: 'Monstera',
    location: 'Living room',
    wateringIntervalDays: 3,
    lastWateredOn: DateTime(2026, 9, 28),
  ),
  Plant(
    id: 'p',
    name: 'Pothos',
    wateringIntervalDays: 7,
    lastWateredOn: DateTime(2026, 9, 23),
  ),
];

Future<void> pumpCalendar(
  WidgetTester tester, {
  FakePlantRepository? repository,
  FakeCareLogRepository? logs,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    CalendarScreen(
      plants: repository ?? FakePlantRepository(plants()),
      careLogs: logs ?? FakeCareLogRepository(),
      clock: fixedNow,
    ),
    locale: locale,
  );
}

void main() {
  group('CalendarScreen', () {
    testWidgets('marks the days that have care tasks', (tester) async {
      await pumpCalendar(tester);

      expect(find.byKey(const ValueKey('marker-2026-09-30')), findsOneWidget);
      expect(find.byKey(const ValueKey('marker-2026-10-01')), findsOneWidget);
      expect(find.byKey(const ValueKey('marker-2026-10-02')), findsNothing);
    });

    testWidgets('lists today\'s tasks and those of a selected day', (
      tester,
    ) async {
      await pumpCalendar(tester);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Water Pothos'), findsOneWidget);
      expect(find.text('Every 7 days'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('day-2026-10-01')));
      await tester.pumpAndSettle();

      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Water Monstera'), findsWidgets);
      expect(find.text('Every 3 days · Living room'), findsWidgets);
      expect(find.text('Water Pothos'), findsNothing);
    });

    testWidgets('says "Nothing to do" for a day without tasks', (tester) async {
      await pumpCalendar(tester);

      await tester.tap(find.byKey(const ValueKey('day-2026-10-02')));
      await tester.pumpAndSettle();

      expect(find.text('Nothing to do'), findsOneWidget);
    });

    testWidgets('confirms today\'s task with one tap', (tester) async {
      final repository = FakePlantRepository(plants());
      final logs = FakeCareLogRepository();
      await pumpCalendar(tester, repository: repository, logs: logs);

      await tester.tap(find.byTooltip('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Pothos watered'), findsOneWidget);
      expect(find.text('Water Pothos'), findsNothing);
      final pothos = repository.plants.firstWhere((p) => p.name == 'Pothos');
      expect(pothos.lastWateredOn, DateTime.utc(2026, 9, 30));
      expect(logs.logs.single.kind, const Water());
    });

    testWidgets('shows the calendar in German', (tester) async {
      await pumpCalendar(tester, locale: const Locale('de'));

      expect(find.text('Kalender'), findsOneWidget);
      expect(find.text('Heute'), findsOneWidget);
      expect(find.text('Pothos gießen'), findsOneWidget);
      expect(find.text('Alle 7 Tage'), findsOneWidget);
    });
  });

  testWidgets('the home screen opens the calendar', (tester) async {
    await tester.pumpApp(
      HomeScreen(
        plants: FakePlantRepository(plants()),
        careLogs: FakeCareLogRepository(),
        clock: fixedNow,
      ),
    );

    await tester.tap(find.byTooltip('Calendar'));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarScreen), findsOneWidget);
  });
}
