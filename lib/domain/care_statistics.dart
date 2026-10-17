import 'care_log.dart';
import 'care_status.dart';
import 'clock.dart';
import 'plant.dart';

/// Days on which some plant's watering or fertilizing was overdue, judged
/// from the care history and the current intervals (winter rest included):
/// the days after a due date until the care was done, and up to [today] for
/// care still open.
Set<DateTime> overdueDays(
  Iterable<Plant> plants,
  Iterable<CareLog> logs, {
  required DateTime today,
}) {
  final now = dayOf(today);
  final days = <DateTime>{};
  for (final plant in plants) {
    for (final kind in const [Water(), Fertilize()]) {
      final interval = switch (kind) {
        Water() => plant.wateringIntervalDays,
        _ => plant.fertilizingIntervalDays,
      };
      if (interval == null) continue;
      final done = {
        for (final log in logs)
          if (log.plantId == plant.id && log.kind == kind) log.day,
      }.toList()..sort();
      for (var i = 0; i < done.length; i++) {
        final due = nextCareDay(plant, kind, done[i], interval);
        final until = i + 1 < done.length
            ? done[i + 1].subtract(const Duration(days: 1))
            : now;
        for (
          var day = due.add(const Duration(days: 1));
          !day.isAfter(until);
          day = day.add(const Duration(days: 1))
        ) {
          days.add(day);
        }
      }
    }
  }
  return days;
}

/// Days in a row without overdue care: [current] ends today, [best] is the
/// longest run since the first care log.
typedef CareStreak = ({int current, int best});

/// See [CareStreak]; zero without any care log.
CareStreak careStreak(
  Iterable<Plant> plants,
  Iterable<CareLog> logs, {
  required DateTime today,
}) {
  if (logs.isEmpty) return (current: 0, best: 0);
  final now = dayOf(today);
  final start = logs.map((log) => log.day).reduce((a, b) => a.isBefore(b) ? a : b);
  final overdue = overdueDays(plants, logs, today: now);
  var run = 0;
  var best = 0;
  for (
    var day = start;
    !day.isAfter(now);
    day = day.add(const Duration(days: 1))
  ) {
    run = overdue.contains(day) ? 0 : run + 1;
    if (run > best) best = run;
  }
  return (current: run, best: best);
}

/// Care actions per month for the last [months] months up to [today],
/// oldest first, including months without care.
List<({int year, int month, int count})> careCountsByMonth(
  Iterable<CareLog> logs, {
  required DateTime today,
  int months = 12,
}) {
  final now = dayOf(today);
  return [
    for (var back = months - 1; back >= 0; back--)
      if (DateTime.utc(now.year, now.month - back) case final month)
        (
          year: month.year,
          month: month.month,
          count: logs
              .where(
                (log) =>
                    log.day.year == month.year && log.day.month == month.month,
              )
              .length,
        ),
  ];
}

/// The plant with the most care actions in the last year, or `null`.
({Plant plant, int count})? mostCaredPlant(
  Iterable<Plant> plants,
  Iterable<CareLog> logs, {
  required DateTime today,
}) {
  final since = dayOf(today).subtract(const Duration(days: 365));
  ({Plant plant, int count})? best;
  for (final plant in sortedByName(plants)) {
    final count = logs
        .where((log) => log.plantId == plant.id && log.day.isAfter(since))
        .length;
    if (count > 0 && (best == null || count > best.count)) {
      best = (plant: plant, count: count);
    }
  }
  return best;
}
