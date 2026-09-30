import 'care_log.dart';
import 'care_status.dart';
import 'clock.dart';
import 'plant.dart';

/// One care task on a day, e.g. "water the Monstera on Oct 1".
class CareTask {
  const CareTask({
    required this.plant,
    required this.kind,
    required this.day,
    this.overdueDays = 0,
  });

  final Plant plant;
  final CareKind kind;

  /// Calendar day (UTC midnight) the task is planned for.
  final DateTime day;

  /// How many days the task is overdue (only for tasks on today).
  final int overdueDays;

  @override
  bool operator ==(Object other) =>
      other is CareTask &&
      other.plant == plant &&
      other.kind == kind &&
      other.day == day &&
      other.overdueDays == overdueDays;

  @override
  int get hashCode => Object.hash(plant, kind, day, overdueDays);

  @override
  String toString() => 'CareTask(${plant.name}, $kind, $day, $overdueDays)';
}

/// All care tasks from [from] to [to] (inclusive): for every scheduled care
/// kind the next due date and then every interval. Overdue care is planned
/// on [today], and its next occurrences are counted from today.
List<CareTask> careTasksBetween(
  Iterable<Plant> plants, {
  required DateTime from,
  required DateTime to,
  required DateTime today,
}) {
  final start = dayOf(from);
  final end = dayOf(to);
  final now = dayOf(today);
  final tasks = <CareTask>[];
  for (final plant in plants) {
    for (final kind in CareKind.values) {
      final interval = _interval(plant, kind);
      if (interval == null) continue;
      final (first, overdue) = switch (careStatus(plant, kind, now)) {
        NotScheduled() => (null, 0),
        DueToday() => (now, 0),
        Overdue(:final days) => (now, days),
        DueIn(:final days) => (now.add(Duration(days: days)), 0),
      };
      if (first == null) continue;
      for (var k = 0; ; k++) {
        final day = _occurrence(first, kind, interval * k);
        if (day.isAfter(end)) break;
        if (day.isBefore(start)) continue;
        tasks.add(
          CareTask(
            plant: plant,
            kind: kind,
            day: day,
            overdueDays: k == 0 ? overdue : 0,
          ),
        );
      }
    }
  }
  return tasks..sort(_byDayUrgencyNameKind);
}

int? _interval(Plant plant, CareKind kind) => switch (kind) {
  Water() => plant.wateringIntervalDays,
  Fertilize() => plant.fertilizingIntervalDays,
  Repot() => plant.repottingIntervalMonths,
};

DateTime _occurrence(DateTime first, CareKind kind, int offset) =>
    switch (kind) {
      Repot() => addMonths(first, offset),
      _ => first.add(Duration(days: offset)),
    };

int _byDayUrgencyNameKind(CareTask a, CareTask b) {
  final byDay = a.day.compareTo(b.day);
  if (byDay != 0) return byDay;
  final byOverdue = b.overdueDays.compareTo(a.overdueDays);
  if (byOverdue != 0) return byOverdue;
  final byName = a.plant.name.toLowerCase().compareTo(
    b.plant.name.toLowerCase(),
  );
  if (byName != 0) return byName;
  return CareKind.values
      .indexOf(a.kind)
      .compareTo(CareKind.values.indexOf(b.kind));
}
