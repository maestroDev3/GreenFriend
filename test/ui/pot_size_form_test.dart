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

const label = 'Pot diameter (cm)';

Finder field(String label) => find.widgetWithText(TextFormField, label);

Widget form(FakePlantRepository plants, Plant plant) => PlantFormScreen(
  plants: plants,
  careLogs: FakeCareLogRepository(),
  journal: FakeJournalRepository(),
  photos: FakePhotoStore(),
  species: FakeSpeciesCatalog(const []),
  plant: plant,
  clock: () => DateTime(2026, 10, 17),
);

Future<void> enter(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    field(label),
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(field(label), text);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('pot size in the plant form', () {
    testWidgets('the form saves the pot size', (tester) async {
      final plant = Plant(id: '1', name: 'Monty');
      final plants = FakePlantRepository([plant]);
      await tester.pumpApp(form(plants, plant));

      await enter(tester, '14');

      expect(plants.plants.single.potDiameterCm, 14);
    });

    testWidgets('the form keeps an empty pot size empty', (tester) async {
      final plant = Plant(id: '1', name: 'Monty', potDiameterCm: 14);
      final plants = FakePlantRepository([plant]);
      await tester.pumpApp(form(plants, plant));

      await enter(tester, '');

      expect(plants.plants.single.potDiameterCm, isNull);
    });

    testWidgets('the form validates the pot size', (tester) async {
      final plant = Plant(id: '1', name: 'Monty');
      final plants = FakePlantRepository([plant]);
      await tester.pumpApp(form(plants, plant));

      await enter(tester, '3');

      expect(find.text('Enter a diameter from 5 to 100 cm'), findsOneWidget);
      expect(plants.plants.single.potDiameterCm, isNull);
    });
  });
}
