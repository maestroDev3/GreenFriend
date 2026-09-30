import 'plant.dart';
import 'watering.dart';

/// Returns [plants] with the most urgent first: overdue (longest first), due
/// today, upcoming (soonest first), then plants without a schedule; ties are
/// ordered by name.
List<Plant> sortedByUrgency(Iterable<Plant> plants, DateTime today) {
  final ranked = [
    for (final plant in sortedByName(plants))
      (plant: plant, rank: _rank(wateringStatus(plant, today))),
  ];
  // List.sort is not stable, so the name order is kept via the index.
  final indexed = ranked.indexed.toList()
    ..sort((a, b) {
      final byRank = a.$2.rank.compareTo(b.$2.rank);
      return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
    });
  return [for (final (_, entry) in indexed) entry.plant];
}

/// How many plants need water today or are overdue.
int needingAttention(Iterable<Plant> plants, DateTime today) {
  return plants
      .map((plant) => wateringStatus(plant, today))
      .where((status) => status is Overdue || status is DueToday)
      .length;
}

/// Lower is more urgent.
int _rank(WateringStatus status) => switch (status) {
  Overdue(:final days) => -days,
  DueToday() => 0,
  DueIn(:final days) => days,
  NotScheduled() => 1000,
};
