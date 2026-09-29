import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/home_screen.dart';

import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

FakePlantRepository repositoryWithMonstera() => FakePlantRepository([
  Plant(
    id: '1',
    name: 'Monstera',
    species: 'Monstera deliciosa',
    location: 'Living room',
  ),
]);

Future<void> openMonstera(WidgetTester tester) async {
  await tester.tap(find.text('Monstera'));
  await tester.pumpAndSettle();
}

void main() {
  group('editing a plant', () {
    testWidgets('opens the form with the plant values', (tester) async {
      await tester.pumpApp(HomeScreen(plants: repositoryWithMonstera()));

      await openMonstera(tester);

      expect(find.text('Edit plant'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Monstera'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Monstera deliciosa'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextFormField, 'Living room'), findsOneWidget);
    });

    testWidgets('saves the changes and shows them in the list', (
      tester,
    ) async {
      final repository = repositoryWithMonstera();
      await tester.pumpApp(HomeScreen(plants: repository));
      await openMonstera(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monstera'),
        'Big monstera',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Living room'),
        '',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repository.plants.single.name, 'Big monstera');
      expect(repository.plants.single.id, '1');
      expect(repository.plants.single.location, isNull);
      expect(find.text('Big monstera'), findsOneWidget);
      expect(find.text('Edit plant'), findsNothing);
    });

    testWidgets('shows the edit texts in German', (tester) async {
      await tester.pumpApp(
        HomeScreen(plants: repositoryWithMonstera()),
        locale: const Locale('de'),
      );

      await openMonstera(tester);

      expect(find.text('Pflanze bearbeiten'), findsOneWidget);
      expect(find.byTooltip('Pflanze löschen'), findsOneWidget);
    });
  });

  group('deleting a plant', () {
    testWidgets('asks for confirmation and keeps the plant on Cancel', (
      tester,
    ) async {
      final repository = repositoryWithMonstera();
      await tester.pumpApp(HomeScreen(plants: repository));
      await openMonstera(tester);

      await tester.tap(find.byTooltip('Delete plant'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Monstera?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.plants, hasLength(1));
      expect(find.text('Edit plant'), findsOneWidget);
    });

    testWidgets('removes the plant on Delete and returns to the list', (
      tester,
    ) async {
      final repository = repositoryWithMonstera();
      await tester.pumpApp(HomeScreen(plants: repository));
      await openMonstera(tester);

      await tester.tap(find.byTooltip('Delete plant'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(repository.plants, isEmpty);
      expect(find.text('Edit plant'), findsNothing);
      expect(
        find.text('No plants yet – add your first plant.'),
        findsOneWidget,
      );
    });
  });
}
