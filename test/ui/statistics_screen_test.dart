import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/more_screen.dart';
import 'package:green_friend/ui/statistics_screen.dart';

import '../support/fake_backup.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 10, 13, 9);

final monstera = Plant(
  id: 'm',
  name: 'Monstera',
  wateringIntervalDays: 3,
  winterRest: false,
);

var _id = 0;
CareLog log(String plantId, int day) => CareLog(
  id: '${_id++}',
  plantId: plantId,
  kind: const Water(),
  day: DateTime(2026, 10, day),
);

Widget screen(List<CareLog> logs, {Locale? locale}) => StatisticsScreen(
  plants: FakePlantRepository([monstera]),
  careLogs: FakeCareLogRepository(logs),
  clock: fixedNow,
);

void main() {
  group('StatisticsScreen', () {
    testWidgets('shows streaks, months and the most cared-for plant', (
      tester,
    ) async {
      await tester.pumpApp(screen([log('m', 1), log('m', 4), log('m', 10)]));

      expect(find.text('Current streak'), findsOneWidget);
      expect(find.text('4 days'), findsOneWidget);
      expect(find.text('Best streak'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('Care per month'), findsOneWidget);
      expect(find.byKey(const ValueKey('month-bar-2026-10')), findsOneWidget);
      expect(find.text('Most cared for: Monstera (3×)'), findsOneWidget);
    });

    testWidgets('shows the texts in German', (tester) async {
      await tester.pumpApp(
        screen([log('m', 1), log('m', 4), log('m', 10)]),
        locale: const Locale('de'),
      );

      expect(find.text('Aktuelle Serie'), findsOneWidget);
      expect(find.text('4 Tage'), findsOneWidget);
    });

    testWidgets('explains itself without care history', (tester) async {
      await tester.pumpApp(screen(const []));

      expect(
        find.text('Your statistics appear here once you record care.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('More opens the statistics', (tester) async {
    await tester.pumpApp(
      MoreScreen(
        backupArchive: FakeBackupArchive(),
        fileSharing: FakeFileSharing(),
        plants: FakePlantRepository([monstera]),
        careLogs: FakeCareLogRepository(),
      ),
    );

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();

    expect(find.byType(StatisticsScreen), findsOneWidget);
  });
}
