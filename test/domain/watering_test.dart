import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/care_status.dart';

final today = DateTime(2026, 9, 30, 9, 15);

Plant plant({int? every, DateTime? lastWatered}) => Plant(
  id: 'p1',
  name: 'Monstera',
  wateringIntervalDays: every,
  lastWateredOn: lastWatered,
);

void main() {
  group('Plant watering fields', () {
    test('accepts intervals from 1 to 365 days', () {
      expect(plant(every: 1).wateringIntervalDays, 1);
      expect(plant(every: 365).wateringIntervalDays, 365);
    });

    test('rejects intervals outside 1 to 365 days', () {
      expect(() => plant(every: 0), throwsArgumentError);
      expect(() => plant(every: 366), throwsArgumentError);
    });

    test('normalizes the last watering to its calendar day', () {
      expect(
        plant(
          every: 7,
          lastWatered: DateTime(2026, 9, 28, 18, 30),
        ).lastWateredOn,
        DateTime.utc(2026, 9, 28),
      );
    });
  });

  group('wateringStatus', () {
    test('is not scheduled without an interval', () {
      expect(wateringStatus(plant(), today), const NotScheduled());
    });

    test('is due today when the plant was never watered', () {
      expect(wateringStatus(plant(every: 7), today), const DueToday());
    });

    test('counts the days until the next watering', () {
      final status = wateringStatus(
        plant(every: 7, lastWatered: DateTime(2026, 9, 28)),
        today,
      );

      expect(status, const DueIn(5));
    });

    test('is due today when the interval ends today', () {
      final status = wateringStatus(
        plant(every: 7, lastWatered: DateTime(2026, 9, 23, 22)),
        today,
      );

      expect(status, const DueToday());
    });

    test('counts overdue days as a positive number', () {
      final status = wateringStatus(
        plant(every: 3, lastWatered: DateTime(2026, 9, 25)),
        today,
      );

      expect(status, const Overdue(2));
    });

    test('counts whole days across the autumn daylight saving switch', () {
      final status = wateringStatus(
        plant(every: 3, lastWatered: DateTime(2026, 10, 24, 20)),
        DateTime(2026, 10, 26, 7),
      );

      expect(status, const DueIn(1));
    });
  });
}
