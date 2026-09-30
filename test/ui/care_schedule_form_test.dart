import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/plant_form_screen.dart';

import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Finder field(String label) => find.widgetWithText(TextFormField, label);

/// The form's list; text fields contain scrollables of their own.
Finder get formList => find.byType(Scrollable).first;

Future<void> scrollTo(
  WidgetTester tester,
  Finder finder, [
  double delta = 100,
]) => tester.scrollUntilVisible(finder, delta, scrollable: formList);

Future<void> pumpForm(
  WidgetTester tester,
  FakePlantRepository plants, {
  Plant? plant,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    PlantFormScreen(
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      plants: plants,
      careLogs: FakeCareLogRepository(),
      plant: plant,
      clock: fixedNow,
    ),
    locale: locale,
  );
}

Future<void> enter(WidgetTester tester, Finder finder, String text) async {
  await scrollTo(tester, finder, 100);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await scrollTo(tester, find.text('Save'), 100);
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('fertilizing and repotting in the plant form', () {
    testWidgets('saves both schedules with today as last done', (tester) async {
      final plants = FakePlantRepository();
      await pumpForm(tester, plants);

      await enter(tester, field('Name'), 'Pothos');
      await enter(tester, field('Fertilize every (days)'), '14');
      await enter(tester, field('Repot every (months)'), '12');
      await scrollTo(tester, find.text('Last repotted: Sep 30, 2026'), 100);
      expect(find.text('Last fertilized: Sep 30, 2026'), findsOneWidget);
      await save(tester);

      final plant = plants.plants.single;
      expect(plant.fertilizingIntervalDays, 14);
      expect(plant.lastFertilizedOn, DateTime.utc(2026, 9, 30));
      expect(plant.repottingIntervalMonths, 12);
      expect(plant.lastRepottedOn, DateTime.utc(2026, 9, 30));
    });

    testWidgets('validates the ranges', (tester) async {
      final plants = FakePlantRepository();
      await pumpForm(tester, plants);

      await enter(tester, field('Name'), 'Pothos');
      await enter(tester, field('Fertilize every (days)'), '0');
      await enter(tester, field('Repot every (months)'), '61');
      await save(tester);

      expect(plants.plants, isEmpty);
      await scrollTo(tester, find.text('Enter a number from 1 to 60'), -100);
      expect(find.text('Enter a number from 1 to 60'), findsOneWidget);
      expect(find.text('Enter a number from 1 to 365'), findsOneWidget);
    });

    testWidgets('shows the stored schedules when editing', (tester) async {
      await pumpForm(
        tester,
        FakePlantRepository(),
        plant: Plant(
          id: '1',
          name: 'Pothos',
          fertilizingIntervalDays: 14,
          lastFertilizedOn: DateTime(2026, 9, 20),
          repottingIntervalMonths: 18,
          lastRepottedOn: DateTime(2025, 4, 2),
        ),
      );

      await scrollTo(tester, find.text('Last repotted: Apr 2, 2025'), 100);
      expect(find.widgetWithText(TextFormField, '14'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '18'), findsOneWidget);
      expect(find.text('Last fertilized: Sep 20, 2026'), findsOneWidget);
    });

    testWidgets('removes a schedule when its interval is cleared', (
      tester,
    ) async {
      final plant = Plant(
        id: '1',
        name: 'Pothos',
        fertilizingIntervalDays: 14,
        lastFertilizedOn: DateTime(2026, 9, 20),
      );
      final plants = FakePlantRepository([plant]);
      await pumpForm(tester, plants, plant: plant);

      await enter(tester, find.widgetWithText(TextFormField, '14'), '');
      await save(tester);

      expect(plants.plants.single.fertilizingIntervalDays, isNull);
    });

    testWidgets('shows the labels in German', (tester) async {
      await pumpForm(tester, FakePlantRepository(), locale: const Locale('de'));

      await enter(tester, field('Düngen alle (Tage)'), '14');
      await enter(tester, field('Umtopfen alle (Monate)'), '12');

      expect(find.textContaining('Zuletzt gedüngt:'), findsOneWidget);
      await scrollTo(tester, find.textContaining('Zuletzt umgetopft:'), 100);
      expect(find.textContaining('Zuletzt umgetopft:'), findsOneWidget);
    });
  });
}
