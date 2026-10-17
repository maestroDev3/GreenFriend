import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/reminders.dart';
import 'package:green_friend/domain/vacation.dart';

void main() {
  group('Vacation', () {
    final vacation = Vacation(
      first: DateTime(2026, 10, 20, 15),
      last: DateTime(2026, 10, 25),
    );

    test('covers its first and last day and the days between', () {
      expect(vacation.first, DateTime.utc(2026, 10, 20));
      expect(vacation.covers(DateTime(2026, 10, 20, 7)), isTrue);
      expect(vacation.covers(DateTime(2026, 10, 22)), isTrue);
      expect(vacation.covers(DateTime(2026, 10, 25, 23)), isTrue);
      expect(vacation.covers(DateTime(2026, 10, 19)), isFalse);
      expect(vacation.covers(DateTime(2026, 10, 26)), isFalse);
    });

    test('rejects a last day before the first', () {
      expect(
        () => Vacation(
          first: DateTime(2026, 10, 25),
          last: DateTime(2026, 10, 20),
        ),
        throwsArgumentError,
      );
    });
  });

  group('plannedPlantReminders during a vacation', () {
    test('skips vacation days and reminds on the day after', () {
      final pothos = Plant(
        id: 'p',
        name: 'Pothos',
        wateringIntervalDays: 2,
        lastWateredOn: DateTime(2026, 10, 18),
      );

      final reminders = plannedPlantReminders(
        [pothos],
        now: DateTime(2026, 10, 19, 7),
        time: const ReminderTime(9, 0),
        days: 9,
        vacation: Vacation(
          first: DateTime(2026, 10, 20),
          last: DateTime(2026, 10, 25),
        ),
      );

      expect(reminders.map((reminder) => reminder.at), [
        DateTime(2026, 10, 26, 9),
        DateTime(2026, 10, 27, 9),
      ]);
    });
  });
}
