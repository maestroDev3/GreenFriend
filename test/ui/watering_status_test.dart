import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/theme.dart';

import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Plant plant(String name, {int? every, DateTime? lastWatered}) => Plant(
  id: name,
  name: name,
  wateringIntervalDays: every,
  lastWateredOn: lastWatered,
);

final plants = [
  plant('Aloe', every: 3, lastWatered: DateTime(2026, 9, 25)),
  plant('Begonia', every: 3, lastWatered: DateTime(2026, 9, 26)),
  plant('Calathea', every: 7, lastWatered: DateTime(2026, 9, 23)),
  plant('Dracaena', every: 2, lastWatered: DateTime(2026, 9, 29)),
  plant('Echeveria', every: 7, lastWatered: DateTime(2026, 9, 26)),
  plant('Ficus'),
];

Color? pillColor(WidgetTester tester, String text) {
  final box = tester.widget<DecoratedBox>(
    find
        .ancestor(of: find.text(text), matching: find.byType(DecoratedBox))
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}

void main() {
  group('watering status on the plant cards', () {
    testWidgets('shows overdue, today and upcoming in English', (
      tester,
    ) async {
      await tester.pumpApp(
        HomeScreen(plants: FakePlantRepository(plants), clock: fixedNow),
      );

      expect(find.text('Overdue by 2 days'), findsOneWidget);
      expect(find.text('Overdue by 1 day'), findsOneWidget);
      expect(find.text('Water today'), findsOneWidget);
      expect(find.text('Water in 1 day'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Water in 3 days'), 100);
      expect(find.text('Water in 3 days'), findsOneWidget);
    });

    testWidgets('shows the status in German', (tester) async {
      await tester.pumpApp(
        HomeScreen(plants: FakePlantRepository(plants), clock: fixedNow),
        locale: const Locale('de'),
      );

      expect(find.text('Seit 2 Tagen überfällig'), findsOneWidget);
      expect(find.text('Seit 1 Tag überfällig'), findsOneWidget);
      expect(find.text('Heute gießen'), findsOneWidget);
      expect(find.text('In 1 Tag gießen'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('In 3 Tagen gießen'), 100);
      expect(find.text('In 3 Tagen gießen'), findsOneWidget);
    });

    testWidgets('shows no status for plants without an interval', (
      tester,
    ) async {
      await tester.pumpApp(
        HomeScreen(
          plants: FakePlantRepository([plant('Ficus')]),
          clock: fixedNow,
        ),
      );

      expect(find.textContaining('Water'), findsNothing);
      expect(find.textContaining('Overdue'), findsNothing);
    });

    testWidgets('uses a terracotta pill for overdue and sage for today', (
      tester,
    ) async {
      await tester.pumpApp(
        HomeScreen(plants: FakePlantRepository(plants), clock: fixedNow),
      );

      final scheme = lightTheme.colorScheme;
      expect(pillColor(tester, 'Overdue by 2 days'), scheme.tertiaryContainer);
      expect(pillColor(tester, 'Water today'), scheme.secondaryContainer);
    });
  });
}
