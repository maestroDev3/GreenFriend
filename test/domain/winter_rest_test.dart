import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/care_status.dart';
import 'package:green_friend/domain/care_tasks.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/season.dart';

Plant plant({
  bool winterRest = true,
  int? water,
  DateTime? lastWatered,
  int? fertilize,
  DateTime? lastFertilized,
  int? repot,
  DateTime? lastRepotted,
}) => Plant(
  id: '1',
  name: 'Monstera',
  winterRest: winterRest,
  wateringIntervalDays: water,
  lastWateredOn: lastWatered,
  fertilizingIntervalDays: fertilize,
  lastFertilizedOn: lastFertilized,
  repottingIntervalMonths: repot,
  lastRepottedOn: lastRepotted,
);

List<(String, DateTime)> summary(List<CareTask> tasks) => [
  for (final task in tasks) (task.kind.name, task.day),
];

void main() {
  group('isWinterRest', () {
    test('covers November 1 to the end of February', () {
      expect(isWinterRest(DateTime.utc(2026, 11, 1)), isTrue);
      expect(isWinterRest(DateTime.utc(2026, 12, 31)), isTrue);
      expect(isWinterRest(DateTime.utc(2027, 2, 28)), isTrue);
      expect(isWinterRest(DateTime.utc(2028, 2, 29)), isTrue);
    });

    test('does not cover March 1 to October 31', () {
      expect(isWinterRest(DateTime.utc(2027, 3, 1)), isFalse);
      expect(isWinterRest(DateTime.utc(2026, 7, 15)), isFalse);
      expect(isWinterRest(DateTime.utc(2026, 10, 31)), isFalse);
    });
  });

  group('winterRestEnd', () {
    test('is the next March 1', () {
      expect(winterRestEnd(DateTime.utc(2026, 12, 5)), DateTime.utc(2027, 3));
      expect(winterRestEnd(DateTime.utc(2027, 1, 10)), DateTime.utc(2027, 3));
    });
  });

  group('winterWateringInterval', () {
    test('is one and a half times the interval, rounded up', () {
      expect(winterWateringInterval(7), 11);
      expect(winterWateringInterval(4), 6);
      expect(winterWateringInterval(1), 2);
    });
  });

  group('careStatus with winter rest', () {
    test('stretches watering counted from a day in winter rest', () {
      final watered = plant(water: 7, lastWatered: DateTime.utc(2026, 12, 1));

      expect(
        careStatus(watered, const Water(), DateTime.utc(2026, 12, 2)),
        const DueIn(10),
      );
    });

    test('keeps watering counted from a day outside winter rest', () {
      final watered = plant(water: 7, lastWatered: DateTime.utc(2026, 10, 1));

      expect(
        careStatus(watered, const Water(), DateTime.utc(2026, 10, 2)),
        const DueIn(6),
      );
    });

    test('moves fertilizing due in winter rest to March 1', () {
      final fed = plant(
        fertilize: 30,
        lastFertilized: DateTime.utc(2026, 11, 10),
      );

      expect(
        careStatus(fed, const Fertilize(), DateTime.utc(2026, 12, 1)),
        const DueIn(90),
      );
    });

    test('does not count fertilizing as overdue during winter rest', () {
      final fed = plant(
        fertilize: 30,
        lastFertilized: DateTime.utc(2026, 9, 1),
      );

      expect(
        careStatus(fed, const Fertilize(), DateTime.utc(2027, 1, 10)),
        const DueIn(50),
      );
      expect(
        careStatus(fed, const Fertilize(), DateTime.utc(2026, 10, 20)),
        const Overdue(19),
      );
    });

    test('keeps all due dates when winter rest is off', () {
      final off = plant(
        winterRest: false,
        water: 7,
        lastWatered: DateTime.utc(2026, 12, 1),
        fertilize: 30,
        lastFertilized: DateTime.utc(2026, 11, 10),
      );
      final today = DateTime.utc(2026, 12, 2);

      expect(careStatus(off, const Water(), today), const DueIn(6));
      expect(careStatus(off, const Fertilize(), today), const DueIn(8));
    });

    test('does not change repotting', () {
      final repotted = plant(
        repot: 1,
        lastRepotted: DateTime.utc(2026, 11, 15),
      );

      expect(
        careStatus(repotted, const Repot(), DateTime.utc(2026, 12, 1)),
        const DueIn(14),
      );
    });
  });

  group('careTasksBetween with winter rest', () {
    test('plans stretched watering and no fertilizing in winter', () {
      final tasks = careTasksBetween(
        [
          plant(
            water: 7,
            lastWatered: DateTime.utc(2026, 10, 25),
            fertilize: 30,
            lastFertilized: DateTime.utc(2026, 10, 15),
          ),
        ],
        from: DateTime.utc(2026, 10, 26),
        to: DateTime.utc(2026, 12, 31),
        today: DateTime.utc(2026, 10, 26),
      );

      expect(summary(tasks), [
        ('water', DateTime.utc(2026, 11, 1)),
        ('water', DateTime.utc(2026, 11, 12)),
        ('water', DateTime.utc(2026, 11, 23)),
        ('water', DateTime.utc(2026, 12, 4)),
        ('water', DateTime.utc(2026, 12, 15)),
        ('water', DateTime.utc(2026, 12, 26)),
      ]);
    });

    test('returns to the normal rhythm in March', () {
      final tasks = careTasksBetween(
        [
          plant(
            water: 7,
            lastWatered: DateTime.utc(2027, 2, 20),
            fertilize: 30,
            lastFertilized: DateTime.utc(2027, 1, 20),
          ),
        ],
        from: DateTime.utc(2027, 2, 21),
        to: DateTime.utc(2027, 3, 20),
        today: DateTime.utc(2027, 2, 21),
      );

      expect(summary(tasks), [
        ('fertilize', DateTime.utc(2027, 3, 1)),
        ('water', DateTime.utc(2027, 3, 3)),
        ('water', DateTime.utc(2027, 3, 10)),
        ('water', DateTime.utc(2027, 3, 17)),
      ]);
    });

    test('plans the entered intervals when winter rest is off', () {
      final tasks = careTasksBetween(
        [
          plant(
            winterRest: false,
            water: 7,
            lastWatered: DateTime.utc(2026, 12, 1),
            fertilize: 14,
            lastFertilized: DateTime.utc(2026, 12, 1),
          ),
        ],
        from: DateTime.utc(2026, 12, 2),
        to: DateTime.utc(2026, 12, 20),
        today: DateTime.utc(2026, 12, 2),
      );

      expect(summary(tasks), [
        ('water', DateTime.utc(2026, 12, 8)),
        ('water', DateTime.utc(2026, 12, 15)),
        ('fertilize', DateTime.utc(2026, 12, 15)),
      ]);
    });
  });

  group('Plant.winterRest', () {
    test('is on by default and part of equality and copyWith', () {
      final monstera = Plant(id: '1', name: 'Monstera');

      expect(monstera.winterRest, isTrue);
      expect(monstera.copyWith(winterRest: false).winterRest, isFalse);
      expect(monstera, isNot(monstera.copyWith(winterRest: false)));
    });
  });
}
