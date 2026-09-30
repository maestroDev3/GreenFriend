import 'care_tasks.dart';
import 'clock.dart';
import 'plant.dart';

/// The weeks of the month containing [month], for a month grid.
///
/// Every week has seven entries starting on [firstWeekday]
/// (`DateTime.monday` … `DateTime.sunday`); entries outside the month are
/// `null`. Days are calendar days (UTC midnight).
List<List<DateTime?>> monthGrid(DateTime month, {required int firstWeekday}) {
  if (firstWeekday < DateTime.monday || firstWeekday > DateTime.sunday) {
    throw ArgumentError.value(firstWeekday, 'firstWeekday', 'must be 1-7');
  }
  final first = DateTime.utc(month.year, month.month);
  final length = DateTime.utc(month.year, month.month + 1, 0).day;
  final leading = (first.weekday - firstWeekday) % 7;
  final cells = <DateTime?>[
    for (var i = 0; i < leading; i++) null,
    for (var d = 1; d <= length; d++) DateTime.utc(month.year, month.month, d),
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return [for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7)];
}

/// Number of planned care tasks per day of the month containing [month].
///
/// Only days with tasks are included. Nothing is planned before [today];
/// overdue care counts on [today] (see [careTasksBetween]).
Map<DateTime, int> careTaskCountsByDay(
  Iterable<Plant> plants, {
  required DateTime month,
  required DateTime today,
}) {
  final counts = <DateTime, int>{};
  for (final task in careTasksBetween(
    plants,
    from: DateTime.utc(month.year, month.month),
    to: DateTime.utc(month.year, month.month + 1, 0),
    today: dayOf(today),
  )) {
    counts.update(task.day, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

/// Number of planned care tasks per month (1–12) of [year].
///
/// Only months with tasks are included; see [careTaskCountsByDay].
Map<int, int> careTaskCountsByMonth(
  Iterable<Plant> plants, {
  required int year,
  required DateTime today,
}) {
  final counts = <int, int>{};
  for (final task in careTasksBetween(
    plants,
    from: DateTime.utc(year),
    to: DateTime.utc(year, 12, 31),
    today: dayOf(today),
  )) {
    counts.update(task.day.month, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}
