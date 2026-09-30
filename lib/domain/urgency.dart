import 'care_log.dart';
import 'care_status.dart';
import 'plant.dart';

/// Returns [plants] with the most urgent first: overdue (longest first), due
/// today, upcoming (soonest first), then plants without a schedule; ties are
/// ordered by name. The most urgent care kind of each plant counts.
List<Plant> sortedByUrgency(Iterable<Plant> plants, DateTime today) {
  final ranked = [
    for (final plant in sortedByName(plants))
      (plant: plant, rank: _plantRank(plant, today)),
  ];
  // List.sort is not stable, so the name order is kept via the index.
  final indexed = ranked.indexed.toList()
    ..sort((a, b) {
      final byRank = a.$2.rank.compareTo(b.$2.rank);
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
  return [for (final (_, entry) in indexed) entry.plant];
}

/// How many plants need any care today or are overdue.
int needingAttention(Iterable<Plant> plants, DateTime today) {
  return plants.where((plant) => needsAttention(plant, today)).length;
}

/// Whether any care of [plant] is due today or overdue.
bool needsAttention(Plant plant, DateTime today) => CareKind.values.any(
  (kind) =>
      careStatus(plant, kind, today) is Overdue ||
      careStatus(plant, kind, today) is DueToday,
);

int _plantRank(Plant plant, DateTime today) => CareKind.values
    .map((kind) => _rank(careStatus(plant, kind, today)))
    .reduce((a, b) => a < b ? a : b);

/// Lower is more urgent.
int _rank(CareStatus status) => switch (status) {
  Overdue(:final days) => -days,
  DueToday() => 0,
  DueIn(:final days) => days,
  NotScheduled() => 1000,
};
