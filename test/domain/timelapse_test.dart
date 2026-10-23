import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/timelapse.dart';

JournalEntry _entry(String id, DateTime day, {String? photo, String? note}) =>
    JournalEntry(id: id, plantId: 'p', day: day, photo: photo, note: note);

void main() {
  group('timelapseEntries', () {
    test('only entries with a photo are used, oldest first', () {
      final entries = [
        _entry('c', DateTime(2026, 9, 3), photo: 'c.jpg'),
        _entry('note', DateTime(2026, 9, 2), note: 'Watered'),
        _entry('a', DateTime(2026, 8, 1), photo: 'a.jpg', note: 'New leaf'),
        _entry('b', DateTime(2026, 8, 20), photo: 'b.jpg'),
      ];

      expect(timelapseEntries(entries).map((entry) => entry.id), [
        'a',
        'b',
        'c',
      ]);
    });

    test('only entries with a photo are used: keeps the order of one day', () {
      final day = DateTime(2026, 9, 1);
      final entries = [
        _entry('first', day, photo: '1.jpg'),
        _entry('second', day, photo: '2.jpg'),
      ];

      expect(timelapseEntries(entries).map((entry) => entry.id), [
        'first',
        'second',
      ]);
    });
  });
}
