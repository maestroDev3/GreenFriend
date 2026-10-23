import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/care_statistics.dart';
import 'package:green_friend/domain/plant.dart';

final monstera = Plant(
  id: 'm',
  name: 'Monstera',
  wateringIntervalDays: 3,
  winterRest: false,
);
final aloe = Plant(id: 'a', name: 'Aloe', wateringIntervalDays: 14);

var _id = 0;
CareLog log(
  String plantId,
  int month,
  int day, [
  CareKind kind = const Water(),
]) => CareLog(
  id: '${_id++}',
  plantId: plantId,
  kind: kind,
  day: DateTime(2026, month, day),
);

final logs = [
  log('m', 10, 1),
  log('m', 10, 4),
  log('m', 10, 10),
  log('a', 10, 2),
];

void main() {
  group('overdueDays', () {
    test('counts the days after a due date until the care was done', () {
      expect(overdueDays([monstera], logs, today: DateTime(2026, 10, 13)), {
        DateTime.utc(2026, 10, 8),
        DateTime.utc(2026, 10, 9),
      });
    });

    test('counts days after the last due date up to today', () {
      expect(
        overdueDays([monstera], logs, today: DateTime(2026, 10, 15)),
        contains(DateTime.utc(2026, 10, 14)),
      );
      expect(
        overdueDays([monstera], logs, today: DateTime(2026, 10, 15)),
        contains(DateTime.utc(2026, 10, 15)),
      );
    });
  });

  group('careStreak', () {
    test('counts the current and the best run without overdue days', () {
      final streak = careStreak(
        [monstera, aloe],
        logs,
        today: DateTime(2026, 10, 13),
      );

      expect(streak.current, 4);
      expect(streak.best, 7);
    });

    test('is zero without care logs', () {
      final streak = careStreak(
        [monstera],
        const [],
        today: DateTime(2026, 10, 13),
      );

      expect(streak.current, 0);
      expect(streak.best, 0);
    });
  });

  group('careCountsByMonth', () {
    test('covers the last 12 months, oldest first, with empty months', () {
      final counts = careCountsByMonth([
        ...logs,
        log('a', 8, 20),
      ], today: DateTime(2026, 10, 13));

      expect(counts, hasLength(12));
      expect(counts.first, (year: 2025, month: 11, count: 0));
      expect(counts[9], (year: 2026, month: 8, count: 1));
      expect(counts.last, (year: 2026, month: 10, count: 4));
    });
  });

  group('mostCaredPlant', () {
    test('names the plant with the most care in the last 12 months', () {
      final most = mostCaredPlant(
        [monstera, aloe],
        logs,
        today: DateTime(2026, 10, 13),
      );

      expect(most?.plant, monstera);
      expect(most?.count, 3);
    });

    test('is null without care logs', () {
      expect(
        mostCaredPlant([monstera], const [], today: DateTime(2026, 10, 13)),
        isNull,
      );
    });
  });

  test('an overdue plant without care log produces overdue days', () {
    final plant = Plant(
      id: 'never-logged',
      name: 'Fern',
      wateringIntervalDays: 3,
      lastWateredOn: DateTime(2026, 10, 10),
      winterRest: false,
    );

    expect(overdueDays([plant], const [], today: DateTime(2026, 10, 17)), {
      DateTime.utc(2026, 10, 14),
      DateTime.utc(2026, 10, 15),
      DateTime.utc(2026, 10, 16),
      DateTime.utc(2026, 10, 17),
    });
  });
}
