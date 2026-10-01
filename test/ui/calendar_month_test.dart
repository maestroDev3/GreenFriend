import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/calendar_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

List<Plant> plants() => [
  Plant(
    id: 'm',
    name: 'Monstera',
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

Future<void> pumpMonth(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  String month = 'Month',
}) async {
  await tester.pumpApp(
    CalendarScreen(
      plants: FakePlantRepository(plants()),
      careLogs: FakeCareLogRepository(),
      clock: fixedNow,
    ),
    locale: locale,
  );
  await tester.tap(find.text(month));
  await tester.pumpAndSettle();
}

Finder dayCell(String isoDay) => find.byKey(ValueKey('month-day-$isoDay'));

Finder marker(String isoDay) => find.byKey(ValueKey('month-marker-$isoDay'));

void main() {
  group('calendar month view', () {
    testWidgets('shows the current month with all its days', (tester) async {
      await pumpMonth(tester);

      expect(find.text('September 2026'), findsOneWidget);
      for (var d = 1; d <= 30; d++) {
        expect(dayCell('2026-09-${d.toString().padLeft(2, '0')}'), findsOne);
      }
      expect(dayCell('2026-10-01'), findsNothing);
    });

    testWidgets('marks days with planned care', (tester) async {
      await pumpMonth(tester);

      expect(marker('2026-09-30'), findsOneWidget);
      expect(marker('2026-09-29'), findsNothing);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      expect(marker('2026-10-01'), findsOneWidget);
      expect(marker('2026-10-04'), findsOneWidget);
      expect(marker('2026-10-02'), findsNothing);
    });

    testWidgets('shows the tasks of a day more than three weeks ahead', (
      tester,
    ) async {
      await pumpMonth(tester);
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      await tester.tap(dayCell('2026-10-28'));
      await tester.pumpAndSettle();

      expect(find.text('Wed, Oct 28'), findsOneWidget);
      expect(find.text('Water Monstera'), findsWidgets);
      expect(find.text('Water Pothos'), findsWidgets);
    });

    testWidgets('moves to the next and previous month', (tester) async {
      await pumpMonth(tester);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('August 2026'), findsOneWidget);
    });

    testWidgets('starts the week on Sunday in US English', (tester) async {
      await pumpMonth(tester);

      final sunday = tester.getTopLeft(dayCell('2026-09-06')).dx;
      expect(sunday, lessThan(tester.getTopLeft(dayCell('2026-09-01')).dx));
      expect(sunday, lessThan(tester.getTopLeft(dayCell('2026-09-07')).dx));
    });

    testWidgets('starts the week on Monday in German', (tester) async {
      await pumpMonth(tester, locale: const Locale('de'), month: 'Monat');

      expect(find.text('September 2026'), findsOneWidget);
      final monday = tester.getTopLeft(dayCell('2026-09-07')).dx;
      expect(monday, lessThan(tester.getTopLeft(dayCell('2026-09-01')).dx));
      expect(monday, lessThan(tester.getTopLeft(dayCell('2026-09-06')).dx));
      expect(find.byTooltip('Nächster Monat'), findsOneWidget);
    });
  });
}
