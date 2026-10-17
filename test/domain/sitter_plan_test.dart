import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/sitter_plan.dart';
import 'package:green_friend/domain/vacation.dart';

final vacation = Vacation(
  first: DateTime(2026, 10, 20),
  last: DateTime(2026, 10, 25),
);

Plant monstera() => Plant(
  id: 'm',
  name: 'Monstera',
  location: 'Living room',
  wateringIntervalDays: 3,
  lastWateredOn: DateTime(2026, 10, 18),
  fertilizingIntervalDays: 30,
  lastFertilizedOn: DateTime(2026, 9, 24),
);

void main() {
  group('sitterPlan', () {
    test('lists the days with care, each plant with location and kinds', () {
      final plan = sitterPlan(
        [
          monstera(),
          Plant(
            id: 'a',
            name: 'Aloe',
            wateringIntervalDays: 14,
            lastWateredOn: DateTime(2026, 10, 10),
          ),
          Plant(id: 's', name: 'Stone'),
        ],
        vacation: vacation,
        today: DateTime(2026, 10, 17),
      );

      expect(
        [for (final day in plan) day.day],
        [DateTime.utc(2026, 10, 21), DateTime.utc(2026, 10, 24)],
      );
      final first = plan.first.entries;
      expect(first.map((entry) => entry.plantName), ['Monstera']);
      expect(first.single.location, 'Living room');
      expect(first.single.kinds, const [Water()]);
      expect(plan.last.entries.map((entry) => entry.plantName), [
        'Aloe',
        'Monstera',
      ]);
      expect(plan.last.entries.last.kinds, const [Water(), Fertilize()]);
    });

    test('puts care overdue at the start on the first day', () {
      final plan = sitterPlan(
        [
          Plant(
            id: 'p',
            name: 'Pothos',
            wateringIntervalDays: 7,
            lastWateredOn: DateTime(2026, 10, 1),
          ),
        ],
        vacation: vacation,
        today: DateTime(2026, 10, 17),
      );

      expect(plan.first.day, DateTime.utc(2026, 10, 20));
    });
  });
}
