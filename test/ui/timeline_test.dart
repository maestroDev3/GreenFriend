import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';
import 'package:green_friend/ui/timeline_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';
import '../support/fake_species_catalog.dart';

final entries = [
  JournalEntry(
    id: 'a',
    plantId: 'p',
    day: DateTime(2026, 8, 20),
    note: 'Bought it',
  ),
  JournalEntry(
    id: 'b',
    plantId: 'p',
    day: DateTime(2026, 9, 19),
    note: 'New leaf',
  ),
];

Future<void> pumpTimeline(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    TimelineScreen(
      plantId: 'p',
      journal: FakeJournalRepository(entries),
      photos: FakePhotoStore(),
    ),
    locale: locale,
  );
}

Future<void> pumpDetail(WidgetTester tester, List<JournalEntry> entries) {
  return tester.pumpApp(
    PlantDetailScreen(
      species: FakeSpeciesCatalog(const []),
      plants: FakePlantRepository([Plant(id: 'p', name: 'Monstera')]),
      careLogs: FakeCareLogRepository(),
      journal: FakeJournalRepository(entries),
      photos: FakePhotoStore(),
      photoPicker: FakePhotoPicker(),
      plantId: 'p',
      clock: () => DateTime(2026, 9, 30),
    ),
  );
}

Future<void> scrollTo(WidgetTester tester, Finder finder) => tester
    .scrollUntilVisible(finder, 100, scrollable: find.byType(Scrollable).first);

void main() {
  group('TimelineScreen', () {
    testWidgets('shows the entries oldest first by month', (tester) async {
      await pumpTimeline(tester);

      expect(find.text('Timeline'), findsOneWidget);
      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);
      await scrollTo(tester, find.text('New leaf'));
      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('Day 31'), findsOneWidget);
    });

    testWidgets('shows the timeline in German', (tester) async {
      await pumpTimeline(tester, locale: const Locale('de'));

      expect(find.text('Zeitleiste'), findsOneWidget);
      expect(find.text('Tag 1'), findsOneWidget);
      expect(find.text('August 2026'), findsOneWidget);
    });
  });

  group('Timeline button', () {
    testWidgets('is hidden without journal entries', (tester) async {
      await pumpDetail(tester, const []);
      await scrollTo(tester, find.text('Journal'));

      expect(find.text('Timeline'), findsNothing);
    });

    testWidgets('opens the timeline', (tester) async {
      await pumpDetail(tester, entries);
      await scrollTo(tester, find.text('Timeline'));

      await tester.tap(find.text('Timeline'));
      await tester.pumpAndSettle();

      expect(find.byType(TimelineScreen), findsOneWidget);
    });
  });
}
