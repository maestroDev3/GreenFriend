import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/timeline.dart';
import 'package:green_friend/ui/compare_screen.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

JournalEntry photoEntry(String id, DateTime day) =>
    JournalEntry(id: id, plantId: 'p', day: day, photo: '$id.jpg');

final entries = [
  photoEntry('middle', DateTime(2026, 9, 15)),
  photoEntry('first', DateTime(2026, 9, 1)),
  JournalEntry(
    id: 'note',
    plantId: 'p',
    day: DateTime(2026, 10, 20),
    note: 'Only a note',
  ),
  photoEntry('last', DateTime(2026, 10, 13)),
];

Future<void> pumpCompare(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
}) {
  return tester.pumpApp(
    CompareScreen(
      plantId: 'p',
      journal: FakeJournalRepository(entries),
      photos: FakePhotoStore(),
    ),
    locale: locale,
  );
}

double revealed(WidgetTester tester) =>
    tester.widget<Align>(find.byKey(const ValueKey('before-clip'))).widthFactor ??
    1;

void main() {
  group('defaultComparison', () {
    test('compares the oldest and the newest photo', () {
      final pair = defaultComparison(entries);

      expect(pair?.before.id, 'first');
      expect(pair?.after.id, 'last');
    });

    test('needs at least two photos', () {
      expect(defaultComparison([photoEntry('only', DateTime(2026, 9, 1))]), isNull);
    });
  });

  group('CompareScreen', () {
    testWidgets('labels both photos and the days between', (tester) async {
      await pumpCompare(tester);

      expect(find.text('Before · Sep 1, 2026'), findsOneWidget);
      expect(find.text('After · Oct 13, 2026'), findsOneWidget);
      expect(find.text('42 days later'), findsOneWidget);
    });

    testWidgets('the slider reveals more or less of the before photo', (
      tester,
    ) async {
      await pumpCompare(tester);
      expect(revealed(tester), 0.5);

      await tester.drag(find.byType(Slider), const Offset(-120, 0));
      await tester.pumpAndSettle();

      expect(revealed(tester), lessThan(0.5));
    });

    testWidgets('another before photo can be chosen', (tester) async {
      await pumpCompare(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Sep 15, 2026').first);
      await tester.pumpAndSettle();

      expect(find.text('Before · Sep 15, 2026'), findsOneWidget);
      expect(find.text('28 days later'), findsOneWidget);
    });

    testWidgets('shows the texts in German', (tester) async {
      await pumpCompare(tester, locale: const Locale('de'));

      expect(find.text('Vergleich'), findsOneWidget);
      expect(find.text('42 Tage später'), findsOneWidget);
    });
  });

  group('Compare button', () {
    Future<void> pumpDetail(WidgetTester tester, List<JournalEntry> list) =>
        tester.pumpApp(
          PlantDetailScreen(
            plants: FakePlantRepository([Plant(id: 'p', name: 'Monstera')]),
            careLogs: FakeCareLogRepository(),
            journal: FakeJournalRepository(list),
            photos: FakePhotoStore(),
            photoPicker: FakePhotoPicker(),
            plantId: 'p',
          ),
        );

    Future<void> scrollToJournal(WidgetTester tester) =>
        tester.scrollUntilVisible(
          find.text('Add entry'),
          100,
          scrollable: find.byType(Scrollable).first,
        );

    testWidgets('needs two photos', (tester) async {
      await pumpDetail(tester, [photoEntry('only', DateTime(2026, 9, 1))]);
      await scrollToJournal(tester);

      expect(find.text('Compare'), findsNothing);
    });

    testWidgets('opens the comparison', (tester) async {
      await pumpDetail(tester, entries);
      await scrollToJournal(tester);

      await tester.tap(find.text('Compare'));
      await tester.pumpAndSettle();

      expect(find.byType(CompareScreen), findsOneWidget);
    });
  });
}
