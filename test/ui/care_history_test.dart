import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';

import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';
import '../support/fake_species_catalog.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

Plant monstera() => Plant(
  id: '1',
  name: 'Monstera',
  wateringIntervalDays: 7,
  lastWateredOn: DateTime(2026, 9, 28),
);

CareLog waterLog(String id, DateTime day, {String plantId = '1'}) =>
    CareLog(id: id, plantId: plantId, kind: const Water(), day: day);

Future<void> pumpDetail(
  WidgetTester tester,
  FakeCareLogRepository logs, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpApp(
    PlantDetailScreen(
      species: FakeSpeciesCatalog(const []),
      journal: FakeJournalRepository(),
      photos: FakePhotoStore(),
      photoPicker: FakePhotoPicker(),
      plants: FakePlantRepository([monstera()]),
      careLogs: logs,
      plantId: '1',
      clock: fixedNow,
    ),
    locale: locale,
  );
}

void main() {
  group('care history on the detail page', () {
    testWidgets('lists the logged days newest first', (tester) async {
      await pumpDetail(
        tester,
        FakeCareLogRepository([
          waterLog('a', DateTime(2026, 9, 20)),
          waterLog('b', DateTime(2026, 9, 28)),
          waterLog('other', DateTime(2026, 9, 29), plantId: '2'),
        ]),
      );
      await tester.scrollUntilVisible(find.text('History'), 100);
      await tester.scrollUntilVisible(find.text('Sep 20, 2026'), 100);

      expect(find.text('Sep 29, 2026'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Sep 28, 2026')).dy,
        lessThan(tester.getTopLeft(find.text('Sep 20, 2026')).dy),
      );
    });

    testWidgets('shows at most ten entries', (tester) async {
      await pumpDetail(
        tester,
        FakeCareLogRepository([
          for (var day = 1; day <= 12; day++)
            waterLog('$day', DateTime(2026, 9, day)),
        ]),
      );
      await tester.scrollUntilVisible(find.text('History'), 100);

      expect(find.textContaining(', 2026'), findsNWidgets(10));
      expect(find.text('Sep 1, 2026'), findsNothing);
    });

    testWidgets('says when nothing was logged yet', (tester) async {
      await pumpDetail(tester, FakeCareLogRepository());
      await tester.scrollUntilVisible(find.text('History'), 100);

      expect(find.text('No care logged yet'), findsOneWidget);
    });

    testWidgets('shows the history in German', (tester) async {
      await pumpDetail(
        tester,
        FakeCareLogRepository(),
        locale: const Locale('de'),
      );
      await tester.scrollUntilVisible(find.text('Verlauf'), 100);

      expect(find.text('Noch keine Pflege eingetragen'), findsOneWidget);
    });
  });

  testWidgets('deleting a plant removes its care logs', (tester) async {
    final logs = FakeCareLogRepository([
      waterLog('a', DateTime(2026, 9, 20)),
      waterLog('other', DateTime(2026, 9, 21), plantId: '2'),
    ]);
    await tester.pumpApp(
      HomeScreen(
        species: FakeSpeciesCatalog(const []),
        journal: FakeJournalRepository(),
        photos: FakePhotoStore(),
        photoPicker: FakePhotoPicker(),
        plants: FakePlantRepository([monstera()]),
        careLogs: logs,
        clock: fixedNow,
      ),
    );

    await tester.tap(find.text('Monstera'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit plant'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete plant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(logs.logs.map((log) => log.id), ['other']);
  });
}
