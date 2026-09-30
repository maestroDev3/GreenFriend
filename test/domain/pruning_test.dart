import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_actions.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/care_status.dart';
import 'package:green_friend/domain/care_tasks.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/reminders.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';

final today = DateTime.utc(2026, 9, 30);

Plant olive({DateTime? lastPrunedOn, int? every = 6}) => Plant(
  id: 'o',
  name: 'Olive',
  pruningIntervalMonths: every,
  lastPrunedOn: lastPrunedOn,
);

void main() {
  group('Prune', () {
    test('is a care kind stored as "prune"', () {
      expect(CareKind.values.last, const Prune());
      expect(CareKind.byName('prune'), const Prune());
      expect(const Prune().name, 'prune');
    });
  });

  group('careStatus for pruning', () {
    test('counts calendar months from the last pruning', () {
      expect(
        careStatus(
          olive(lastPrunedOn: DateTime.utc(2026, 3, 30)),
          const Prune(),
          today,
        ),
        const DueToday(),
      );
      expect(
        careStatus(
          olive(lastPrunedOn: DateTime.utc(2026, 4, 15)),
          const Prune(),
          today,
        ),
        const DueIn(15),
      );
      expect(
        careStatus(
          olive(lastPrunedOn: DateTime.utc(2026, 3, 1)),
          const Prune(),
          today,
        ),
        const Overdue(29),
      );
    });

    test('is due today when never pruned and unscheduled without interval', () {
      expect(careStatus(olive(), const Prune(), today), const DueToday());
      expect(
        careStatus(olive(every: null), const Prune(), today),
        const NotScheduled(),
      );
    });
  });

  test('careTasksBetween plans pruning every interval in months', () {
    final tasks = careTasksBetween(
      [olive(every: 3, lastPrunedOn: DateTime.utc(2026, 8, 15))],
      from: today,
      to: DateTime.utc(2027, 3, 31),
      today: today,
    );

    expect([for (final task in tasks) (task.kind, task.day)], [
      (const Prune(), DateTime.utc(2026, 11, 15)),
      (const Prune(), DateTime.utc(2027, 2, 15)),
    ]);
  });

  test('confirming pruning logs it and can be undone', () async {
    final before = olive(lastPrunedOn: DateTime.utc(2026, 3, 1));
    final plants = FakePlantRepository([before]);
    final logs = FakeCareLogRepository();

    final confirmation = await confirmCare(
      plants: plants,
      careLogs: logs,
      plant: before,
      kind: const Prune(),
      today: today,
    );

    expect(plants.plants.single.lastPrunedOn, today);
    expect(logs.logs.single.kind, const Prune());

    await undoCare(plants: plants, careLogs: logs, confirmation: confirmation);

    expect(plants.plants.single, before);
    expect(logs.logs, isEmpty);
  });

  test('plannedReminders lists plants to prune', () {
    final reminders = plannedReminders(
      [olive(lastPrunedOn: DateTime.utc(2026, 3, 30))],
      now: DateTime(2026, 9, 30, 7),
      time: const ReminderTime(9, 0),
      days: 1,
    );

    expect(reminders.single.prune, ['Olive']);
    expect(reminders.single.plantNames, isEmpty);
  });
}
