import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

void main() {
  group('plant list navigation', () {
    testWidgets('opens the detail page when a plant is tapped', (tester) async {
      await tester.pumpApp(
        HomeScreen(
          careLogs: FakeCareLogRepository(),
          plants: FakePlantRepository([Plant(id: '1', name: 'Monstera')]),
        ),
      );

      await tester.tap(find.text('Monstera'));
      await tester.pumpAndSettle();

      expect(find.byType(PlantDetailScreen), findsOneWidget);
    });

    testWidgets('returns to the list after deleting from the detail page', (
      tester,
    ) async {
      final repository = FakePlantRepository([
        Plant(id: '1', name: 'Monstera'),
      ]);
      await tester.pumpApp(
        HomeScreen(careLogs: FakeCareLogRepository(), plants: repository),
      );

      await tester.tap(find.text('Monstera'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit plant'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete plant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(repository.plants, isEmpty);
      expect(find.byType(PlantDetailScreen), findsNothing);
      expect(
        find.text('No plants yet – add your first plant.'),
        findsOneWidget,
      );
    });
  });
}
