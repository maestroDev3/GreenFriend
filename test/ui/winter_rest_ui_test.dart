import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';
import 'package:green_friend/ui/plant_form_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

const switchLabel = 'Winter rest (Nov–Feb)';
const detailHint = 'Water less, no fertilizer until March';

Widget form(FakePlantRepository plants, {Plant? plant}) => PlantFormScreen(
  plants: plants,
  careLogs: FakeCareLogRepository(),
  journal: FakeJournalRepository(),
  photos: FakePhotoStore(),
  species: FakeSpeciesCatalog(const []),
  plant: plant,
  clock: () => DateTime.utc(2026, 10, 2),
);

Widget detail(FakePlantRepository plants, DateTime now) => PlantDetailScreen(
  plants: plants,
  careLogs: FakeCareLogRepository(),
  journal: FakeJournalRepository(),
  photos: FakePhotoStore(),
  species: FakeSpeciesCatalog(const []),
  photoPicker: FakePhotoPicker(),
  plantId: '1',
  clock: () => now,
);

Future<void> showSwitch(WidgetTester tester) => tester.scrollUntilVisible(
  find.text(switchLabel),
  200,
  scrollable: find.byType(Scrollable).first,
);

bool switchValue(WidgetTester tester) => tester
    .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, switchLabel))
    .value;

void main() {
  group('winter rest in the plant form', () {
    testWidgets('is on for new plants and can be switched off', (tester) async {
      final plants = FakePlantRepository();
      await tester.pumpApp(form(plants));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Lemon tree',
      );
      await showSwitch(tester);
      expect(switchValue(tester), isTrue);

      await tester.tap(find.text(switchLabel));
      await tester.pumpAndSettle();
      expect(switchValue(tester), isFalse);
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(plants.plants.single.winterRest, isFalse);
    });

    testWidgets('shows and keeps the stored value when editing', (
      tester,
    ) async {
      final lemon = Plant(id: '1', name: 'Lemon tree', winterRest: false);
      final plants = FakePlantRepository([lemon]);
      await tester.pumpApp(form(plants, plant: lemon));

      await showSwitch(tester);
      expect(switchValue(tester), isFalse);

      await tester.tap(find.text(switchLabel));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(plants.plants.single.winterRest, isTrue);
    });
  });

  group('winter rest on the detail page', () {
    testWidgets('is shown in December', (tester) async {
      final plants = FakePlantRepository([
        Plant(id: '1', name: 'Monstera', wateringIntervalDays: 7),
      ]);
      await tester.pumpApp(detail(plants, DateTime.utc(2026, 12, 10)));

      expect(find.text('Winter rest'), findsOneWidget);
      expect(find.text(detailHint), findsOneWidget);
    });

    testWidgets('is not shown in May', (tester) async {
      final plants = FakePlantRepository([
        Plant(id: '1', name: 'Monstera', wateringIntervalDays: 7),
      ]);
      await tester.pumpApp(detail(plants, DateTime.utc(2026, 5, 10)));

      expect(find.text(detailHint), findsNothing);
    });

    testWidgets('is not shown when switched off', (tester) async {
      final plants = FakePlantRepository([
        Plant(
          id: '1',
          name: 'Monstera',
          wateringIntervalDays: 7,
          winterRest: false,
        ),
      ]);
      await tester.pumpApp(detail(plants, DateTime.utc(2026, 12, 10)));

      expect(find.text(detailHint), findsNothing);
    });
  });
}
