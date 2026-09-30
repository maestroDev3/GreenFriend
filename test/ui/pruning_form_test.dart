import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/plant_form_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Finder field(String label) => find.widgetWithText(TextFormField, label);

Finder get formList => find.byType(Scrollable).first;

Future<void> scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 100, scrollable: formList);

Future<void> pumpForm(
  WidgetTester tester,
  FakePlantRepository plants, {
  Plant? plant,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    PlantFormScreen(
      species: FakeSpeciesCatalog(const []),
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
  await scrollTo(tester, finder);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester, [String label = 'Save']) async {
  await scrollTo(tester, find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('pruning in the plant form', () {
    testWidgets('saves the interval with today as last pruned', (
      tester,
    ) async {
      final plants = FakePlantRepository();
      await pumpForm(tester, plants);

      await enter(tester, field('Name'), 'Olive');
      await enter(tester, field('Prune every (months)'), '12');
      await scrollTo(tester, find.text('Last pruned: Sep 30, 2026'));
      await save(tester);

      final plant = plants.plants.single;
      expect(plant.pruningIntervalMonths, 12);
      expect(plant.lastPrunedOn, DateTime.utc(2026, 9, 30));
    });

    testWidgets('changes the last pruning with the date picker', (
      tester,
    ) async {
      final plants = FakePlantRepository();
      await pumpForm(tester, plants);

      await enter(tester, field('Name'), 'Olive');
      await enter(tester, field('Prune every (months)'), '6');
      await scrollTo(tester, find.text('Last pruned: Sep 30, 2026'));
      await tester.tap(find.text('Last pruned: Sep 30, 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Last pruned: Sep 15, 2026'), findsOneWidget);
      await save(tester);
      expect(plants.plants.single.lastPrunedOn, DateTime.utc(2026, 9, 15));
    });

    for (final input in ['0', '61']) {
      testWidgets('rejects "$input" as pruning interval', (tester) async {
        final plants = FakePlantRepository();
        await pumpForm(tester, plants);

        await enter(tester, field('Name'), 'Olive');
        await enter(tester, field('Prune every (months)'), input);
        await save(tester);

        expect(find.text('Enter a number from 1 to 60'), findsOneWidget);
        expect(plants.plants, isEmpty);
      });
    }

    testWidgets('shows and keeps the pruning of an existing plant', (
      tester,
    ) async {
      final olive = Plant(
        id: '1',
        name: 'Olive',
        pruningIntervalMonths: 6,
        lastPrunedOn: DateTime(2026, 5, 3),
      );
      final plants = FakePlantRepository([olive]);
      await pumpForm(tester, plants, plant: olive);

      await scrollTo(tester, find.text('Last pruned: May 3, 2026'));
      expect(
        tester
            .widget<TextFormField>(field('Prune every (months)'))
            .controller
            ?.text,
        '6',
      );
      await save(tester);

      expect(plants.plants.single, olive);
    });

    testWidgets('shows the pruning field in German', (tester) async {
      await pumpForm(tester, FakePlantRepository(), locale: const Locale('de'));

      await scrollTo(tester, field('Zurückschneiden alle (Monate)'));
      expect(field('Zurückschneiden alle (Monate)'), findsOneWidget);
    });
  });
}
