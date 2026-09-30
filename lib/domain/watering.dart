import 'clock.dart';
import 'plant.dart';

/// When a plant needs water next, relative to today.
sealed class WateringStatus {
  const WateringStatus();
}

/// The plant has no watering interval.
final class NotScheduled extends WateringStatus {
  const NotScheduled();

  @override
  bool operator ==(Object other) => other is NotScheduled;

  @override
  int get hashCode => (NotScheduled).hashCode;
}

/// The plant needs water today.
final class DueToday extends WateringStatus {
  const DueToday();

  @override
  bool operator ==(Object other) => other is DueToday;

  @override
  int get hashCode => (DueToday).hashCode;
}

/// The plant needs water in [days] days (at least 1).
final class DueIn extends WateringStatus {
  const DueIn(this.days);

  final int days;

  @override
  bool operator ==(Object other) => other is DueIn && other.days == days;

  @override
  int get hashCode => Object.hash(DueIn, days);

  @override
  String toString() => 'DueIn($days)';
}

/// The plant should have been watered [days] days ago (at least 1).
final class Overdue extends WateringStatus {
  const Overdue(this.days);

  final int days;

  @override
  bool operator ==(Object other) => other is Overdue && other.days == days;

  @override
  int get hashCode => Object.hash(Overdue, days);

  @override
  String toString() => 'Overdue($days)';
}

/// Works out when [plant] needs water next; a plant that was never watered
/// is due today.
WateringStatus wateringStatus(Plant plant, DateTime today) {
  final interval = plant.wateringIntervalDays;
  if (interval == null) return const NotScheduled();
  final last = plant.lastWateredOn;
  if (last == null) return const DueToday();

  final dueOn = last.add(Duration(days: interval));
  final days = dueOn.difference(dayOf(today)).inDays;
  if (days > 0) return DueIn(days);
  if (days == 0) return const DueToday();
  return Overdue(-days);
}
