import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/journal_actions.dart';

import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';

void main() {
  healthFlagTests();

  group('JournalEntry', () {
    test('needs a note or a photo', () {
      expect(
        () => JournalEntry(id: '1', plantId: 'p', day: DateTime(2026, 9, 30)),
        throwsArgumentError,
      );
      expect(
        () => JournalEntry(
          id: '1',
          plantId: 'p',
          day: DateTime(2026, 9, 30),
          note: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('trims the note and normalizes the day', () {
      final entry = JournalEntry(
        id: '1',
        plantId: 'p',
        day: DateTime(2026, 9, 30, 18, 20),
        note: '  New leaf! ',
      );

      expect(entry.note, 'New leaf!');
      expect(entry.day, DateTime.utc(2026, 9, 30));
      expect(entry.photo, isNull);
    });
  });

  group('FakeJournalRepository', () {
    test('emits the entries of a plant newest first', () async {
      final journal = FakeJournalRepository();
      final emitted = <List<String?>>[];
      final subscription = journal
          .watchEntries('p')
          .listen((entries) => emitted.add([for (final e in entries) e.note]));
      await pumpEventQueue();

      await journal.add(plantId: 'p', day: DateTime(2026, 9, 1), note: 'old');
      await journal.add(plantId: 'p', day: DateTime(2026, 9, 20), note: 'new');
      await journal.add(plantId: 'x', day: DateTime(2026, 9, 25), note: 'x');
      await pumpEventQueue();
      await subscription.cancel();

      expect(emitted, [
        <String?>[],
        ['old'],
        ['new', 'old'],
        ['new', 'old'],
      ]);
    });
  });

  group('journal actions', () {
    test('deleting an entry also deletes its photo', () async {
      final journal = FakeJournalRepository();
      final photos = FakePhotoStore();
      final photo = await photos.save('/tmp/leaf.jpg');
      final entry = await journal.add(
        plantId: 'p',
        day: DateTime(2026, 9, 30),
        photo: photo,
      );

      await deleteJournalEntry(journal: journal, photos: photos, entry: entry);

      expect(journal.entries, isEmpty);
      expect(photos.stored, isEmpty);
    });

    test(
      'deleting the journal of a plant removes entries and photos',
      () async {
        final journal = FakeJournalRepository();
        final photos = FakePhotoStore();
        final photo = await photos.save('/tmp/leaf.jpg');
        final other = await photos.save('/tmp/other.jpg');
        await journal.add(
          plantId: 'p',
          day: DateTime(2026, 9, 1),
          photo: photo,
        );
        await journal.add(
          plantId: 'p',
          day: DateTime(2026, 9, 2),
          note: 'note',
        );
        await journal.add(
          plantId: 'x',
          day: DateTime(2026, 9, 3),
          photo: other,
        );

        await deleteJournalForPlant(
          journal: journal,
          photos: photos,
          plantId: 'p',
        );

        expect(journal.entries.map((entry) => entry.plantId), ['x']);
        expect(photos.stored, {other});
      },
    );
  });
}

void healthFlagTests() {
  test('a journal entry is no health check by default; the flag counts for '
      'equality', () {
    final day = DateTime(2026, 10, 17);
    final plain = JournalEntry(id: '1', plantId: 'p', day: day, note: 'x');
    final check = JournalEntry(
      id: '1',
      plantId: 'p',
      day: day,
      note: 'x',
      healthCheck: true,
    );

    expect(plain.healthCheck, isFalse);
    expect(check.healthCheck, isTrue);
    expect(check, isNot(plain));
  });
}
