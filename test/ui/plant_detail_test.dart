import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Plant monstera({int? every = 7}) => Plant(
  id: '1',
  name: 'Monstera',
  species: 'Monstera deliciosa',
  location: 'Living room',
  wateringIntervalDays: every,
  lastWateredOn: DateTime(2026, 9, 28),
);

Future<void> pumpDetail(
  WidgetTester tester,
  FakePlantRepository repository, {
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    PlantDetailScreen(
      careLogs: FakeCareLogRepository(),
      plants: repository,
      plantId: '1',
      clock: fixedNow,
    ),
    locale: locale,
  );
}

void main() {
  group('PlantDetailScreen', () {
    testWidgets('shows the plant and its watering', (tester) async {
      await pumpDetail(tester, FakePlantRepository([monstera()]));

      expect(find.text('Monstera'), findsOneWidget);
      expect(find.text('Monstera deliciosa'), findsOneWidget);
      expect(find.text('Living room'), findsOneWidget);
      expect(find.text('Every 7 days'), findsOneWidget);
      expect(find.text('Water in 5 days'), findsOneWidget);
    });

    testWidgets('shows "No schedule" without an interval', (tester) async {
      await pumpDetail(tester, FakePlantRepository([monstera(every: null)]));

      expect(find.text('No schedule'), findsOneWidget);
      expect(find.text('Next watering'), findsNothing);
    });

    testWidgets('says "Every day" for an interval of one day', (tester) async {
      await pumpDetail(tester, FakePlantRepository([monstera(every: 1)]));

      expect(find.text('Every day'), findsOneWidget);
    });

    testWidgets('shows the texts in German', (tester) async {
      await pumpDetail(
        tester,
        FakePlantRepository([monstera()]),
        locale: const Locale('de'),
      );

      expect(find.text('Wasser'), findsOneWidget);
      expect(find.text('Alle 7 Tage'), findsOneWidget);
      expect(find.text('In 5 Tagen gießen'), findsOneWidget);
    });

    testWidgets('opens the form and shows the changes after saving', (
      tester,
    ) async {
      final repository = FakePlantRepository([monstera()]);
      await pumpDetail(tester, repository);

      await tester.tap(find.byTooltip('Edit plant'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Monstera'),
        'Big monstera',
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(PlantDetailScreen), findsOneWidget);
      expect(find.text('Big monstera'), findsOneWidget);
    });
  });
}
