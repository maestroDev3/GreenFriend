import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/calendar.dart';
import 'package:green_friend/domain/plant.dart';

final today = DateTime.utc(2026, 9, 30);

DateTime day(int year, int month, int day) => DateTime.utc(year, month, day);

List<int?> daysOf(List<DateTime?> week) => [for (final d in week) d?.day];

void main() {
  group('monthGrid', () {
    test('starts weeks on Monday and pads days outside the month', () {
      // September 2026 starts on a Tuesday.
      final weeks = monthGrid(day(2026, 9, 1), firstWeekday: DateTime.monday);

      expect(weeks, hasLength(5));
      expect(daysOf(weeks.first), [null, 1, 2, 3, 4, 5, 6]);
      expect(daysOf(weeks.last), [28, 29, 30, null, null, null, null]);
    });

    test('starts weeks on Sunday', () {
      final weeks = monthGrid(day(2026, 9, 15), firstWeekday: DateTime.sunday);

      expect(daysOf(weeks.first), [null, null, 1, 2, 3, 4, 5]);
      expect(weeks.first[2], day(2026, 9, 1));
    });

    test('needs no padding when the month starts on the first weekday', () {
      // June 2026 starts on a Monday.
      final weeks = monthGrid(day(2026, 6, 1), firstWeekday: DateTime.monday);

      expect(daysOf(weeks.first), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('contains every day of a leap February once', () {
      final weeks = monthGrid(day(2028, 2, 1), firstWeekday: DateTime.monday);
      final days = [for (final week in weeks) ...week.nonNulls];

      expect(days, [for (var d = 1; d <= 29; d++) day(2028, 2, d)]);
      expect(weeks.every((week) => week.length == 7), isTrue);
    });

    test('uses six weeks when the month needs them', () {
      // August 2026 starts on a Saturday and has 31 days.
      final weeks = monthGrid(day(2026, 8, 1), firstWeekday: DateTime.monday);

      expect(weeks, hasLength(6));
      expect(daysOf(weeks.last), [31, null, null, null, null, null, null]);
    });
  });

  group('careTaskCountsByDay', () {
    final weekly = Plant(
      id: 'w',
      name: 'Weekly',
      wateringIntervalDays: 7,
      lastWateredOn: day(2026, 9, 28),
    );
    final overdue = Plant(
      id: 'o',
      name: 'Overdue',
      wateringIntervalDays: 20,
      lastWateredOn: day(2026, 9, 1),
    );

    test('counts the planned tasks per day of the month', () {
      final counts = careTaskCountsByDay(
        [weekly],
        month: day(2026, 10, 1),
        today: today,
      );

      expect(counts, {
        day(2026, 10, 5): 1,
        day(2026, 10, 12): 1,
        day(2026, 10, 19): 1,
        day(2026, 10, 26): 1,
      });
    });

    test('plans overdue care on today and nothing before today', () {
      final counts = careTaskCountsByDay(
        [weekly, overdue],
        month: day(2026, 9, 1),
        today: today,
      );

      expect(counts, {day(2026, 9, 30): 1});
    });

    test('adds up tasks of several plants on the same day', () {
      final counts = careTaskCountsByDay(
        [weekly, weekly.copyWith(name: 'Twin')],
        month: day(2026, 10, 1),
        today: today,
      );

      expect(counts[day(2026, 10, 5)], 2);
    });
  });

  group('careTaskCountsByMonth', () {
    test('counts the planned tasks per month of a year', () {
      final weekly = Plant(
        id: 'w',
        name: 'Weekly',
        wateringIntervalDays: 7,
        lastWateredOn: day(2026, 9, 28),
        winterRest: false,
      );

      expect(careTaskCountsByMonth([weekly], year: 2026, today: today), {
        10: 4,
        11: 5,
        12: 4,
      });
    });

    test('shows yearly repotting in its month', () {
      final repot = Plant(
        id: 'r',
        name: 'Repot',
        repottingIntervalMonths: 12,
        lastRepottedOn: day(2026, 3, 15),
      );

      expect(careTaskCountsByMonth([repot], year: 2026, today: today), isEmpty);
      expect(careTaskCountsByMonth([repot], year: 2027, today: today), {3: 1});
    });
  });
}
