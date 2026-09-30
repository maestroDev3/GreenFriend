import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/reminders.dart';

const nine = ReminderTime(9, 0);

Plant plant(String name, {int? every, DateTime? lastWatered}) => Plant(
  id: name,
  name: name,
  wateringIntervalDays: every,
  lastWateredOn: lastWatered,
);

void main() {
  group('ReminderTime', () {
    test('rejects invalid hours and minutes', () {
      expect(() => ReminderTime.checked(24, 0), throwsArgumentError);
      expect(() => ReminderTime.checked(8, 60), throwsArgumentError);
      expect(ReminderTime.checked(23, 59), const ReminderTime(23, 59));
    });
  });

  group('plannedReminders', () {
    test('lists the due plants per day at the chosen time', () {
      final reminders = plannedReminders(
        [
          plant('Pothos', every: 2, lastWatered: DateTime(2026, 9, 29)),
          plant('Aloe', every: 3, lastWatered: DateTime(2026, 9, 29)),
          plant('Ficus'),
        ],
        now: DateTime(2026, 9, 30, 7),
        time: nine,
        days: 3,
      );

      expect(reminders, [
        PlannedReminder(at: DateTime(2026, 10, 1, 9), plantNames: ['Pothos']),
        PlannedReminder(
          at: DateTime(2026, 10, 2, 9),
          plantNames: ['Aloe', 'Pothos'],
        ),
      ]);
    });

    test('starts tomorrow when the time has passed today', () {
      final reminders = plannedReminders(
        [plant('Pothos', every: 1, lastWatered: DateTime(2026, 9, 29))],
        now: DateTime(2026, 9, 30, 9, 0),
        time: nine,
        days: 2,
      );

      expect(reminders.map((reminder) => reminder.at), [
        DateTime(2026, 10, 1, 9),
      ]);
    });

    test('includes today when the time is still ahead', () {
      final reminders = plannedReminders(
        [plant('Pothos', every: 1, lastWatered: DateTime(2026, 9, 29))],
        now: DateTime(2026, 9, 30, 8, 59),
        time: nine,
        days: 2,
      );

      expect(reminders.first.at, DateTime(2026, 9, 30, 9));
    });

    test('plans at most 14 days ahead', () {
      final reminders = plannedReminders(
        [plant('Pothos', every: 1)],
        now: DateTime(2026, 9, 30, 7),
        time: nine,
      );

      expect(reminders, hasLength(14));
      expect(reminders.last.at, DateTime(2026, 10, 13, 9));
    });

    test('keeps the local time across the daylight saving switch', () {
      final reminders = plannedReminders(
        [plant('Pothos', every: 1, lastWatered: DateTime(2026, 10, 23))],
        now: DateTime(2026, 10, 24, 10),
        time: const ReminderTime(8, 30),
        days: 3,
      );

      expect(reminders.map((reminder) => reminder.at), [
        DateTime(2026, 10, 25, 8, 30),
        DateTime(2026, 10, 26, 8, 30),
      ]);
    });
  });
}
