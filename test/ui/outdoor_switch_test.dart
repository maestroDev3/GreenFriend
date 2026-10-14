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

const label = 'Outdoors (balcony, garden)';

Widget form(FakePlantRepository plants, {Plant? plant}) => PlantFormScreen(
  plants: plants,
  careLogs: FakeCareLogRepository(),
  journal: FakeJournalRepository(),
  photos: FakePhotoStore(),
  species: FakeSpeciesCatalog(const []),
  plant: plant,
  clock: () => DateTime.utc(2026, 10, 14),
);

Future<void> scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
}

bool value(WidgetTester tester) => tester
    .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, label))
    .value;

void main() {
  group('outdoor switch in the plant form', () {
    testWidgets('is off for new plants and can be turned on', (tester) async {
      final plants = FakePlantRepository();
      await tester.pumpApp(form(plants));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Lavender',
      );
      await scrollTo(tester, label);
      expect(value(tester), isFalse);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await scrollTo(tester, 'Save');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(plants.plants.single.outdoor, isTrue);
    });

    testWidgets('keeps the stored value when editing', (tester) async {
      final lavender = Plant(id: '1', name: 'Lavender', outdoor: true);
      final plants = FakePlantRepository([lavender]);
      await tester.pumpApp(form(plants, plant: lavender));

      await scrollTo(tester, label);
      expect(value(tester), isTrue);
      await scrollTo(tester, 'Save');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(plants.plants.single.outdoor, isTrue);
    });
  });
}
