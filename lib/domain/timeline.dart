import 'journal.dart';

/// One journal entry in the timeline, with its day counted from the first
/// entry (the first entry is day 1).
class TimelineItem {
  const TimelineItem({required this.entry, required this.dayNumber});

  final JournalEntry entry;
  final int dayNumber;
}

/// The timeline entries of one calendar month.
class TimelineMonth {
  const TimelineMonth({
    required this.year,
    required this.month,
    required this.items,
  });

  final int year;
  final int month;
  final List<TimelineItem> items;
}

/// Orders the journal oldest first and groups it by month.
List<TimelineMonth> journalTimeline(Iterable<JournalEntry> entries) {
  final ordered = newestEntriesFirst(entries).reversed.toList();
  if (ordered.isEmpty) return const [];
  final first = ordered.first.day;
  final months = <TimelineMonth>[];
  for (final entry in ordered) {
    final item = TimelineItem(
      entry: entry,
      dayNumber: entry.day.difference(first).inDays + 1,
    );
    final last = months.isEmpty ? null : months.last;
    if (last != null &&
        last.year == entry.day.year &&
        last.month == entry.day.month) {
      last.items.add(item);
    } else {
      months.add(
        TimelineMonth(
          year: entry.day.year,
          month: entry.day.month,
          items: [item],
        ),
      );
    }
  }
  return months;
}
