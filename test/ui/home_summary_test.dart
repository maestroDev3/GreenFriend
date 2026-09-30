import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/theme.dart';

import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';
import '../support/fake_species_catalog.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Plant plant(String name, {int? every, DateTime? lastWatered}) => Plant(
  id: name,
  name: name,
  wateringIntervalDays: every,
  lastWateredOn: lastWatered,
);

final plants = [
  plant('Aloe', every: 7, lastWatered: DateTime(2026, 9, 25)),
  plant('Begonia'),
  plant('Monstera', every: 7, lastWatered: DateTime(2026, 9, 23)),
  plant('Zamioculcas', every: 3, lastWatered: DateTime(2026, 9, 25)),
];

Future<void> pumpHome(
  WidgetTester tester,
  List<Plant> plants, {
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    HomeScreen(
      species: FakeSpeciesCatalog(const []),
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      photoPicker: FakePhotoPicker(),
      careLogs: FakeCareLogRepository(),
      plants: FakePlantRepository(plants),
      clock: fixedNow,
    ),
    locale: locale,
  );
}

void main() {
  group('home screen with plants', () {
    testWidgets('greets the user and lists the plants by urgency', (
      tester,
    ) async {
      await pumpHome(tester, plants);

      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('My plants'), findsOneWidget);
      final order = ['Zamioculcas', 'Monstera', 'Aloe', 'Begonia'];
      for (var i = 0; i < order.length - 1; i++) {
        await tester.scrollUntilVisible(find.text(order[i + 1]), 100);
        expect(
          tester.getTopLeft(find.text(order[i])).dy,
          lessThan(tester.getTopLeft(find.text(order[i + 1])).dy),
          reason: '${order[i]} before ${order[i + 1]}',
        );
      }
    });

    testWidgets('summarizes how many plants need attention today', (
      tester,
    ) async {
      await pumpHome(tester, plants);

      expect(find.text('2 of 4 plants need attention today'), findsOneWidget);
    });

    testWidgets('uses the singular for one plant', (tester) async {
      await pumpHome(tester, [plants[2], plants[1]]);

      expect(find.text('1 of 2 plants needs attention today'), findsOneWidget);
    });

    testWidgets('says all plants are happy when nothing is due', (
      tester,
    ) async {
      await pumpHome(tester, [plants[0], plants[1]]);

      expect(find.text('All your plants are happy today'), findsOneWidget);
    });

    testWidgets('shows the summary in German', (tester) async {
      await pumpHome(tester, plants, locale: const Locale('de'));

      expect(find.text('Hallo!'), findsOneWidget);
      expect(find.text('Meine Pflanzen'), findsOneWidget);
      expect(
        find.text('2 von 4 Pflanzen brauchen heute Aufmerksamkeit'),
        findsOneWidget,
      );
    });

    testWidgets('shows the summary on a primary-colored card', (tester) async {
      await pumpHome(tester, plants);

      final card = tester.widget<Card>(
        find
            .ancestor(
              of: find.text('2 of 4 plants need attention today'),
              matching: find.byType(Card),
            )
            .first,
      );
      expect(card.color, lightTheme.colorScheme.primary);
    });
  });

  testWidgets('the empty state shows no greeting or summary', (tester) async {
    await pumpHome(tester, []);

    expect(find.text('Hello!'), findsNothing);
    expect(find.textContaining('attention'), findsNothing);
    expect(find.text('No plants yet – add your first plant.'), findsOneWidget);
  });
}
