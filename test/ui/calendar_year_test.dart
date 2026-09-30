import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/calendar_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Future<void> pumpYear(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  String year = 'Year',
}) async {
  await tester.pumpApp(
    CalendarScreen(
      plants: FakePlantRepository([
        Plant(
          id: 'w',
          name: 'Weekly',
          wateringIntervalDays: 7,
          lastWateredOn: DateTime(2026, 9, 28),
        ),
      ]),
      careLogs: FakeCareLogRepository(),
      clock: fixedNow,
    ),
    locale: locale,
  );
  await tester.tap(find.text(year));
  await tester.pumpAndSettle();
}

Finder monthTile(String isoMonth) =>
    find.byKey(ValueKey('year-month-$isoMonth'));

String monthText(WidgetTester tester, String isoMonth) => tester
    .widgetList<Text>(
      find.descendant(of: monthTile(isoMonth), matching: find.byType(Text)),
    )
    .map((text) => text.data)
    .join(' | ');

void main() {
  group('calendar year view', () {
    testWidgets('shows twelve months with their task counts', (tester) async {
      await pumpYear(tester);

      expect(find.text('2026'), findsOneWidget);
      for (var m = 1; m <= 12; m++) {
        expect(monthTile('2026-${m.toString().padLeft(2, '0')}'), findsOne);
      }
      expect(monthText(tester, '2026-10'), 'October | 4 tasks');
      expect(monthText(tester, '2026-11'), 'November | 5 tasks');
    });

    testWidgets('shows no count for a month without tasks', (tester) async {
      await pumpYear(tester);

      expect(monthText(tester, '2026-01'), 'January');
      expect(monthText(tester, '2026-09'), 'September');
    });

    testWidgets('opens a month in the month view', (tester) async {
      await pumpYear(tester);

      await tester.tap(monthTile('2026-11'));
      await tester.pumpAndSettle();

      expect(find.text('November 2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('month-day-2026-11-02')), findsOne);
    });

    testWidgets('moves to the next and previous year', (tester) async {
      await pumpYear(tester);

      await tester.tap(find.byTooltip('Next year'));
      await tester.pumpAndSettle();
      expect(find.text('2027'), findsOneWidget);
      expect(monthText(tester, '2027-01'), 'January | 4 tasks');

      await tester.tap(find.byTooltip('Previous year'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous year'));
      await tester.pumpAndSettle();
      expect(find.text('2025'), findsOneWidget);
    });

    testWidgets('shows the year view in German', (tester) async {
      await pumpYear(tester, locale: const Locale('de'), year: 'Jahr');

      expect(monthText(tester, '2026-10'), 'Oktober | 4 Aufgaben');
      expect(find.byTooltip('Nächstes Jahr'), findsOneWidget);
    });
  });
}
