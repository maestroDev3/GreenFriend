import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/timeline.dart';

JournalEntry entry(String id, DateTime day) =>
    JournalEntry(id: id, plantId: 'p', day: day, note: id);

void main() {
  group('journalTimeline', () {
    test('groups the entries oldest first by month with day numbers', () {
      final timeline = journalTimeline([
        entry('jan', DateTime(2027, 1, 2)),
        entry('aug', DateTime(2026, 8, 20)),
        entry('sep', DateTime(2026, 9, 19)),
      ]);

      expect(
        [for (final month in timeline) (month.year, month.month)],
        [(2026, 8), (2026, 9), (2027, 1)],
      );
      expect(
        [
          for (final month in timeline)
            for (final item in month.items) (item.entry.id, item.dayNumber),
        ],
        [('aug', 1), ('sep', 31), ('jan', 136)],
      );
    });

    test('is empty without entries', () {
      expect(journalTimeline([]), isEmpty);
    });
  });
}
