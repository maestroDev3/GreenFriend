import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_tasks.dart';
import 'package:green_friend/domain/plant.dart';

final today = DateTime(2026, 9, 30, 10);

List<(String, String, DateTime, int)> summary(List<CareTask> tasks) => [
  for (final task in tasks)
    (task.plant.name, task.kind.name, task.day, task.overdueDays),
];

void main() {
  group('careTasksBetween', () {
    test('repeats a schedule every interval from the next due date', () {
      final tasks = careTasksBetween(
        [
          Plant(
            id: '1',
            name: 'Pothos',
            wateringIntervalDays: 3,
            lastWateredOn: DateTime(2026, 9, 28),
          ),
        ],
        from: today,
        to: DateTime(2026, 10, 7),
        today: today,
      );

      expect(summary(tasks), [
        ('Pothos', 'water', DateTime.utc(2026, 10, 1), 0),
        ('Pothos', 'water', DateTime.utc(2026, 10, 4), 0),
        ('Pothos', 'water', DateTime.utc(2026, 10, 7), 0),
      ]);
    });

    test('lists overdue care on today and counts on from today', () {
      final tasks = careTasksBetween(
        [
          Plant(
            id: '1',
            name: 'Pothos',
            wateringIntervalDays: 3,
            lastWateredOn: DateTime(2026, 9, 25),
          ),
        ],
        from: today,
        to: DateTime(2026, 10, 7),
        today: today,
      );

      expect(summary(tasks), [
        ('Pothos', 'water', DateTime.utc(2026, 9, 30), 2),
        ('Pothos', 'water', DateTime.utc(2026, 10, 3), 0),
        ('Pothos', 'water', DateTime.utc(2026, 10, 6), 0),
      ]);
    });

    test('uses calendar months for repotting', () {
      final tasks = careTasksBetween(
        [
          Plant(
            id: '1',
            name: 'Ficus',
            repottingIntervalMonths: 1,
            lastRepottedOn: DateTime(2026, 8, 30),
          ),
        ],
        from: today,
        to: DateTime(2026, 12, 31),
        today: today,
      );

      expect(tasks.map((task) => task.day), [
        DateTime.utc(2026, 9, 30),
        DateTime.utc(2026, 10, 30),
        DateTime.utc(2026, 11, 30),
        DateTime.utc(2026, 12, 30),
      ]);
    });

    test('sorts by day, overdue first, then by name and care kind', () {
      final tasks = careTasksBetween(
        [
          Plant(
            id: 'a',
            name: 'Aloe',
            wateringIntervalDays: 7,
            lastWateredOn: DateTime(2026, 9, 23),
            fertilizingIntervalDays: 7,
            lastFertilizedOn: DateTime(2026, 9, 23),
          ),
          Plant(
            id: 'b',
            name: 'Begonia',
            wateringIntervalDays: 2,
            lastWateredOn: DateTime(2026, 9, 27),
          ),
        ],
        from: today,
        to: today,
        today: today,
      );

      expect(summary(tasks), [
        ('Begonia', 'water', DateTime.utc(2026, 9, 30), 1),
        ('Aloe', 'water', DateTime.utc(2026, 9, 30), 0),
        ('Aloe', 'fertilize', DateTime.utc(2026, 9, 30), 0),
      ]);
    });

    test('only returns tasks inside the range', () {
      final tasks = careTasksBetween(
        [
          Plant(
            id: '1',
            name: 'Pothos',
            wateringIntervalDays: 3,
            lastWateredOn: DateTime(2026, 9, 25),
          ),
        ],
        from: DateTime(2026, 10, 2),
        to: DateTime(2026, 10, 5),
        today: today,
      );

      expect(tasks.map((task) => task.day), [DateTime.utc(2026, 10, 3)]);
    });
  });
}
