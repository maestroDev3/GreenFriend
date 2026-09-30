import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/pump_app.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 10);

class Setup {
  Setup({List<JournalEntry> entries = const [], String? pickedPhoto})
    : journal = FakeJournalRepository(entries),
      picker = FakePhotoPicker(path: pickedPhoto ?? '/tmp/picked.jpg');

  final plants = FakePlantRepository([Plant(id: 'p', name: 'Monstera')]);
  final FakeJournalRepository journal;
  final photos = FakePhotoStore();
  final FakePhotoPicker picker;

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('en')}) {
    return tester.pumpApp(
      PlantDetailScreen(
        plants: plants,
        careLogs: FakeCareLogRepository(),
        journal: journal,
        photos: photos,
        photoPicker: picker,
        plantId: 'p',
        clock: fixedNow,
      ),
      locale: locale,
    );
  }
}

Finder get detailList => find.byType(Scrollable).first;

Future<void> scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 100, scrollable: detailList);

Future<void> openNewEntry(WidgetTester tester) async {
  await scrollTo(tester, find.text('Add entry'));
  await tester.tap(find.text('Add entry'));
  await tester.pumpAndSettle();
}

void main() {
  group('journal on the detail page', () {
    testWidgets('says when there are no entries yet', (tester) async {
      await Setup().pump(tester);

      await scrollTo(tester, find.text('Journal'));
      expect(find.text('No entries yet'), findsOneWidget);
    });

    testWidgets('adds a note-only entry', (tester) async {
      final setup = Setup();
      await setup.pump(tester);
      await openNewEntry(tester);

      expect(find.text('New entry'), findsOneWidget);
      final save = find.widgetWithText(FilledButton, 'Save');
      expect(tester.widget<FilledButton>(save).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'First new leaf');
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(setup.journal.entries.single.note, 'First new leaf');
      expect(setup.journal.entries.single.day, DateTime.utc(2026, 9, 30));
      await scrollTo(tester, find.text('First new leaf'));
      expect(find.text('Sep 30, 2026'), findsOneWidget);
    });

    testWidgets('adds an entry with a chosen photo', (tester) async {
      final setup = Setup();
      await setup.pump(tester);
      await openNewEntry(tester);

      await tester.tap(find.text('Choose photo'));
      await tester.pumpAndSettle();
      expect(setup.picker.requests, ['gallery']);
      expect(find.byKey(const ValueKey('photo-preview')), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final entry = setup.journal.entries.single;
      expect(entry.photo, 'photo-1.jpg');
      expect(setup.photos.stored, {'photo-1.jpg'});
      await scrollTo(tester, find.byKey(ValueKey('journal-photo-${entry.id}')));
    });

    testWidgets('can take a photo with the camera', (tester) async {
      final setup = Setup();
      await setup.pump(tester);
      await openNewEntry(tester);

      await tester.tap(find.text('Take photo'));
      await tester.pumpAndSettle();

      expect(setup.picker.requests, ['camera']);
    });

    testWidgets('deletes an entry after confirmation', (tester) async {
      final setup = Setup(
        entries: [
          JournalEntry(
            id: 'e1',
            plantId: 'p',
            day: DateTime(2026, 9, 20),
            note: 'Repotted into a bigger pot',
          ),
        ],
      );
      await setup.pump(tester);

      await scrollTo(tester, find.byTooltip('Delete entry'));
      await tester.tap(find.byTooltip('Delete entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(setup.journal.entries, isEmpty);
    });

    testWidgets('shows the journal in German', (tester) async {
      await Setup().pump(tester, locale: const Locale('de'));

      await scrollTo(tester, find.text('Tagebuch'));
      expect(find.text('Noch keine Einträge'), findsOneWidget);
      expect(find.text('Eintrag hinzufügen'), findsOneWidget);
    });
  });

  testWidgets('deleting a plant removes its journal and photos', (
    tester,
  ) async {
    final setup = Setup();
    final photo = await setup.photos.save('/tmp/leaf.jpg');
    await setup.journal.add(
      plantId: 'p',
      day: DateTime(2026, 9, 20),
      photo: photo,
    );
    await setup.pump(tester);

    await tester.tap(find.byTooltip('Edit plant'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete plant'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(setup.journal.entries, isEmpty);
    expect(setup.photos.stored, isEmpty);
  });
}
