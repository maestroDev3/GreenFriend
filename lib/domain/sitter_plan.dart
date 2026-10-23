import 'care_log.dart';
import 'care_tasks.dart';
import 'clock.dart';
import 'plant.dart';
import 'vacation.dart';

/// One plant's care on a day of the sitter plan.
class SitterEntry {
  const SitterEntry({
    required this.plantName,
    required this.kinds,
    this.location,
  });

  final String plantName;
  final String? location;

  /// In the order of [CareKind.values].
  final List<CareKind> kinds;
}

/// A day of the sitter plan with the plants to care for.
class SitterDay {
  const SitterDay({required this.day, required this.entries});

  /// Calendar day (UTC midnight).
  final DateTime day;

  /// Sorted by plant name.
  final List<SitterEntry> entries;
}

/// The care during [vacation], day by day, for someone looking after the
/// plants; it assumes everything is done on time. Care overdue when the
/// vacation starts lands on its first day; days without care are left out.
List<SitterDay> sitterPlan(
  Iterable<Plant> plants, {
  required Vacation vacation,
  required DateTime today,
}) {
  final now = dayOf(today);
  final start = vacation.first.isAfter(now) ? vacation.first : now;
  final tasks = careTasksBetween(
    plants,
    from: start,
    to: vacation.last,
    today: start,
  );
  final byDay = <DateTime, Map<String, (Plant, Set<CareKind>)>>{};
  for (final task in tasks) {
    final plantsOfDay = byDay.putIfAbsent(task.day, () => {});
    plantsOfDay
        .putIfAbsent(task.plant.id, () => (task.plant, {}))
        .$2
        .add(task.kind);
  }
  final days = byDay.keys.toList()..sort();
  return [
    for (final day in days)
      SitterDay(
        day: day,
        entries: [
          for (final (plant, kinds) in sortedByName(
            byDay[day]!.values.map((entry) => entry.$1),
          ).map((plant) => byDay[day]![plant.id]!))
            SitterEntry(
              plantName: plant.name,
              location: plant.location,
              kinds: [
                for (final kind in CareKind.values)
                  if (kinds.contains(kind)) kind,
              ],
            ),
        ],
      ),
  ];
}
