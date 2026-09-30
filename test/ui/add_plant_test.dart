import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/home_screen.dart';

import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

Finder field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  group('HomeScreen plant list', () {
    testWidgets('shows the empty-state hint and an Add plant button', (
      tester,
    ) async {
      await tester.pumpApp(
        HomeScreen(journal: FakeJournalRepository(), photos: FakePhotoStore(), photoPicker: FakePhotoPicker(), 
          careLogs: FakeCareLogRepository(),
          plants: FakePlantRepository(),
        ),
      );

      expect(
        find.text('No plants yet – add your first plant.'),
        findsOneWidget,
      );
      expect(find.text('Add plant'), findsOneWidget);
    });

    testWidgets('shows name, species and location of each plant', (
      tester,
    ) async {
      final repository = FakePlantRepository([
        Plant(
          id: '1',
          name: 'Monstera',
          species: 'Monstera deliciosa',
          location: 'Living room',
        ),
        Plant(id: '2', name: 'Aloe'),
      ]);

      await tester.pumpApp(
        HomeScreen(journal: FakeJournalRepository(), photos: FakePhotoStore(), photoPicker: FakePhotoPicker(), careLogs: FakeCareLogRepository(), plants: repository),
      );

      expect(find.text('Monstera'), findsOneWidget);
      expect(find.text('Monstera deliciosa'), findsOneWidget);
      expect(find.text('Living room'), findsOneWidget);
      expect(find.text('Aloe'), findsOneWidget);
      expect(find.text('No plants yet – add your first plant.'), findsNothing);
    });

    testWidgets('lets long texts wrap with large system fonts', (tester) async {
      final repository = FakePlantRepository([
        Plant(
          id: '1',
          name: 'A very long plant name that needs more than one line',
          location: 'The sunny window sill in the upstairs guest bathroom',
        ),
      ]);

      await tester.pumpApp(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: HomeScreen(journal: FakeJournalRepository(), photos: FakePhotoStore(), photoPicker: FakePhotoPicker(), 
            careLogs: FakeCareLogRepository(),
            plants: repository,
          ),
        ),
      );

      final name = find.text(
        'A very long plant name that needs more than one line',
      );
      await tester.scrollUntilVisible(name, 200);

      expect(tester.takeException(), isNull);
      expect(name, findsOneWidget);
    });

    testWidgets('shows the button in German', (tester) async {
      await tester.pumpApp(
        HomeScreen(journal: FakeJournalRepository(), photos: FakePhotoStore(), photoPicker: FakePhotoPicker(), 
          careLogs: FakeCareLogRepository(),
          plants: FakePlantRepository(),
        ),
        locale: const Locale('de'),
      );

      expect(find.text('Pflanze hinzufügen'), findsOneWidget);
    });
  });

  group('adding a plant', () {
    testWidgets('saves the plant and shows it in the list', (tester) async {
      final repository = FakePlantRepository();
      await tester.pumpApp(
        HomeScreen(journal: FakeJournalRepository(), photos: FakePhotoStore(), photoPicker: FakePhotoPicker(), careLogs: FakeCareLogRepository(), plants: repository),
      );

      await tester.tap(find.text('Add plant'));
      await tester.pumpAndSettle();
      expect(find.text('New plant'), findsOneWidget);

      await tester.enterText(field('Name'), 'Monstera');
      await tester.enterText(field('Species (optional)'), 'Monstera deliciosa');
      await tester.enterText(field('Location (optional)'), 'Living room');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.plants, hasLength(1));
      expect(repository.plants.single.name, 'Monstera');
      expect(repository.plants.single.species, 'Monstera deliciosa');
      expect(repository.plants.single.location, 'Living room');
      expect(find.text('New plant'), findsNothing);
      expect(find.text('Monstera'), findsOneWidget);
    });

    testWidgets('requires a name', (tester) async {
      final repository = FakePlantRepository();
      await tester.pumpApp(
        HomeScreen(journal: FakeJournalRepository(), photos: FakePhotoStore(), photoPicker: FakePhotoPicker(), careLogs: FakeCareLogRepository(), plants: repository),
      );

      await tester.tap(find.text('Add plant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a name'), findsOneWidget);
      expect(find.text('New plant'), findsOneWidget);
      expect(repository.plants, isEmpty);
    });
  });
}
