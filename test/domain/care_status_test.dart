import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_actions.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/care_status.dart';
import 'package:green_friend/domain/plant.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';

final today = DateTime(2026, 9, 30, 9);

void main() {
  group('addMonths', () {
    test('keeps the day of the month', () {
      expect(addMonths(DateTime.utc(2026, 12, 15), 2), DateTime.utc(2027, 2, 15));
    });

    test('clamps to the last day of shorter months', () {
      expect(addMonths(DateTime.utc(2027, 1, 31), 1), DateTime.utc(2027, 2, 28));
      expect(addMonths(DateTime.utc(2028, 1, 31), 1), DateTime.utc(2028, 2, 29));
    });
  });

  group('Plant care intervals', () {
    test('rejects fertilizing intervals outside 1 to 365 days', () {
      expect(
        () => Plant(id: '1', name: 'A', fertilizingIntervalDays: 0),
        throwsArgumentError,
      );
      expect(
        () => Plant(id: '1', name: 'A', fertilizingIntervalDays: 366),
        throwsArgumentError,
      );
    });

    test('rejects repotting intervals outside 1 to 60 months', () {
      expect(
        () => Plant(id: '1', name: 'A', repottingIntervalMonths: 0),
        throwsArgumentError,
      );
      expect(
        () => Plant(id: '1', name: 'A', repottingIntervalMonths: 61),
        throwsArgumentError,
      );
    });

    test('normalizes the last fertilizing and repotting days', () {
      final plant = Plant(
        id: '1',
        name: 'A',
        lastFertilizedOn: DateTime(2026, 9, 20, 18),
        lastRepottedOn: DateTime(2025, 4, 2, 7),
      );

      expect(plant.lastFertilizedOn, DateTime.utc(2026, 9, 20));
      expect(plant.lastRepottedOn, DateTime.utc(2025, 4, 2));
    });
  });

  group('careStatus', () {
    test('counts fertilizing in days', () {
      final plant = Plant(
        id: '1',
        name: 'Pothos',
        fertilizingIntervalDays: 14,
        lastFertilizedOn: DateTime(2026, 9, 20),
      );

      expect(careStatus(plant, const Fertilize(), today), const DueIn(4));
    });

    test('counts repotting in calendar months', () {
      Plant repotted(DateTime last) => Plant(
        id: '1',
        name: 'Pothos',
        repottingIntervalMonths: 12,
        lastRepottedOn: last,
      );

      expect(
        careStatus(repotted(DateTime(2025, 9, 29)), const Repot(), today),
        const Overdue(1),
      );
      expect(
        careStatus(repotted(DateTime(2025, 10, 5)), const Repot(), today),
        const DueIn(5),
      );
    });

    test('is not scheduled without an interval and due when never done', () {
      final plant = Plant(id: '1', name: 'Pothos', repottingIntervalMonths: 24);

      expect(careStatus(plant, const Fertilize(), today), const NotScheduled());
      expect(careStatus(plant, const Repot(), today), const DueToday());
    });

    test('matches the watering status for water', () {
      final plant = Plant(
        id: '1',
        name: 'Pothos',
        wateringIntervalDays: 3,
        lastWateredOn: DateTime(2026, 9, 25),
      );

      expect(careStatus(plant, const Water(), today), const Overdue(2));
      expect(wateringStatus(plant, today), const Overdue(2));
    });
  });

  group('confirmCare', () {
    test('sets the matching day, logs the kind and can be undone', () async {
      final plant = Plant(
        id: '1',
        name: 'Pothos',
        fertilizingIntervalDays: 14,
        lastFertilizedOn: DateTime(2026, 9, 1),
      );
      final plants = FakePlantRepository([plant]);
      final logs = FakeCareLogRepository();

      final confirmation = await confirmCare(
        plants: plants,
        careLogs: logs,
        plant: plant,
        kind: const Fertilize(),
        today: today,
      );

      expect(plants.plants.single.lastFertilizedOn, DateTime.utc(2026, 9, 30));
      expect(plants.plants.single.lastWateredOn, isNull);
      expect(logs.logs.single.kind, const Fertilize());

      await undoCare(
        plants: plants,
        careLogs: logs,
        confirmation: confirmation,
      );

      expect(plants.plants.single, plant);
      expect(logs.logs, isEmpty);
    });
  });
}
