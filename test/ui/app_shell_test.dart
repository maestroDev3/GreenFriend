import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/app_shell.dart';
import 'package:green_friend/ui/calendar_screen.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';
import 'package:green_friend/ui/settings_screen.dart';
import 'package:green_friend/ui/theme.dart';

import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Future<void> pumpShell(
  WidgetTester tester, {
  List<Plant> plants = const [],
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    AppShell(journal: FakeJournalRepository(), photos: FakePhotoStore(), photoPicker: FakePhotoPicker(), 
      plants: FakePlantRepository(plants),
      careLogs: FakeCareLogRepository(),
      clock: fixedNow,
    ),
    locale: locale,
  );
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('AppShell', () {
    testWidgets('shows the navigation with the add button in the middle', (
      tester,
    ) async {
      await pumpShell(tester);

      for (final label in ['Home', 'Plants', 'Calendar', 'More']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byTooltip('Add plant'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Home')).style?.color,
        lightTheme.colorScheme.primary,
      );
    });

    testWidgets('lists all plants alphabetically and opens one', (
      tester,
    ) async {
      await pumpShell(
        tester,
        plants: [
          Plant(id: 'z', name: 'Zamioculcas'),
          Plant(id: 'a', name: 'Aloe'),
        ],
      );

      await openTab(tester, 'Plants');

      expect(
        tester.getTopLeft(find.text('Aloe')).dy,
        lessThan(tester.getTopLeft(find.text('Zamioculcas')).dy),
      );
      await tester.tap(find.text('Aloe'));
      await tester.pumpAndSettle();
      expect(find.byType(PlantDetailScreen), findsOneWidget);
    });

    testWidgets('shows the calendar', (tester) async {
      await pumpShell(tester);

      await openTab(tester, 'Calendar');

      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('opens settings and about from More', (tester) async {
      await pumpShell(tester);

      await openTab(tester, 'More');
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('the add button opens the new-plant form', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.byTooltip('Add plant'));
      await tester.pumpAndSettle();

      expect(find.text('New plant'), findsOneWidget);
    });

    testWidgets('shows the labels in German', (tester) async {
      await pumpShell(tester, locale: const Locale('de'));

      for (final label in ['Start', 'Pflanzen', 'Kalender', 'Mehr']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });
  });
}
