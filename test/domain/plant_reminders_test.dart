import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_actions.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/reminders.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';

const nine = ReminderTime(9, 0);

void main() {
  group('plannedPlantReminders', () {
    test('plans one reminder per due plant and day with its due care', () {
      final pothos = Plant(
        id: 'p',
        name: 'Pothos',
        wateringIntervalDays: 2,
        lastWateredOn: DateTime(2026, 9, 29),
        fertilizingIntervalDays: 2,
        lastFertilizedOn: DateTime(2026, 9, 29),
      );
      final aloe = Plant(
        id: 'a',
        name: 'Aloe',
        wateringIntervalDays: 3,
        lastWateredOn: DateTime(2026, 9, 29),
      );
      final ficus = Plant(id: 'f', name: 'Ficus');

      final reminders = plannedPlantReminders(
        [pothos, aloe, ficus],
        now: DateTime(2026, 9, 30, 7),
        time: nine,
        days: 3,
      );

      expect(reminders, [
        PlantReminder(
          at: DateTime(2026, 10, 1, 9),
          plant: pothos,
          kinds: const [Water(), Fertilize()],
        ),
        PlantReminder(
          at: DateTime(2026, 10, 2, 9),
          plant: aloe,
          kinds: const [Water()],
        ),
        PlantReminder(
          at: DateTime(2026, 10, 2, 9),
          plant: pothos,
          kinds: const [Water(), Fertilize()],
        ),
      ]);
    });

    test('starts tomorrow when the time has passed today', () {
      final reminders = plannedPlantReminders(
        [
          Plant(
            id: 'p',
            name: 'Pothos',
            wateringIntervalDays: 1,
            lastWateredOn: DateTime(2026, 9, 29),
          ),
        ],
        now: DateTime(2026, 9, 30, 9),
        time: nine,
        days: 2,
      );

      expect(reminders.map((reminder) => reminder.at), [
        DateTime(2026, 10, 1, 9),
      ]);
    });
  });

  group('care action ids', () {
    test('round-trip plant id and care kind', () {
      final id = careActionId('plant:1', const Fertilize());

      expect(parseCareActionId(id), (
        plantId: 'plant:1',
        kind: const Fertilize(),
      ));
    });

    test('give null for other ids', () {
      expect(parseCareActionId(null), isNull);
      expect(parseCareActionId('open'), isNull);
      expect(parseCareActionId('care:dance:1'), isNull);
      expect(parseCareActionId('care:water:'), isNull);
    });
  });

  group('completeCareFromAction', () {
    final today = DateTime(2026, 10, 3, 9, 5);
    Plant monstera() => Plant(
      id: 'm',
      name: 'Monstera',
      wateringIntervalDays: 7,
      lastWateredOn: DateTime(2026, 9, 26),
    );

    test('records the care of the action', () async {
      final plants = FakePlantRepository([monstera()]);
      final logs = FakeCareLogRepository();

      final done = await completeCareFromAction(
        plants: plants,
        careLogs: logs,
        actionId: careActionId('m', const Water()),
        today: today,
      );

      expect(done, isTrue);
      expect(plants.plants.single.lastWateredOn, DateTime.utc(2026, 10, 3));
      expect(logs.logs.single.kind, const Water());
    });

    test('changes nothing for unknown plants or ids', () async {
      final plants = FakePlantRepository([monstera()]);
      final logs = FakeCareLogRepository();

      for (final id in [careActionId('x', const Water()), 'open', null]) {
        final done = await completeCareFromAction(
          plants: plants,
          careLogs: logs,
          actionId: id,
          today: today,
        );
        expect(done, isFalse);
      }
      expect(plants.plants.single, monstera());
      expect(logs.logs, isEmpty);
    });

    test('does not record the same care twice on one day', () async {
      final plants = FakePlantRepository([monstera()]);
      final logs = FakeCareLogRepository();
      final id = careActionId('m', const Water());

      await completeCareFromAction(
        plants: plants,
        careLogs: logs,
        actionId: id,
        today: today,
      );
      final again = await completeCareFromAction(
        plants: plants,
        careLogs: logs,
        actionId: id,
        today: today,
      );

      expect(again, isFalse);
      expect(logs.logs, hasLength(1));
    });
  });
}
