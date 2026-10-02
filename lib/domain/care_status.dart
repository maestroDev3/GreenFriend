import 'care_log.dart';
import 'clock.dart';
import 'plant.dart';
import 'season.dart';

/// When a care task (watering, fertilizing, repotting) is due next,
/// relative to today.
sealed class CareStatus {
  const CareStatus();
}

/// The plant has no interval for this care.
final class NotScheduled extends CareStatus {
  const NotScheduled();

  @override
  bool operator ==(Object other) => other is NotScheduled;

  @override
  int get hashCode => (NotScheduled).hashCode;
}

/// The care is due today.
final class DueToday extends CareStatus {
  const DueToday();

  @override
  bool operator ==(Object other) => other is DueToday;

  @override
  int get hashCode => (DueToday).hashCode;
}

/// The care is due in [days] days (at least 1).
final class DueIn extends CareStatus {
  const DueIn(this.days);

  final int days;

  @override
  bool operator ==(Object other) => other is DueIn && other.days == days;

  @override
  int get hashCode => Object.hash(DueIn, days);

  @override
  String toString() => 'DueIn($days)';
}

/// The care should have been done [days] days ago (at least 1).
final class Overdue extends CareStatus {
  const Overdue(this.days);

  final int days;

  @override
  bool operator ==(Object other) => other is Overdue && other.days == days;

  @override
  int get hashCode => Object.hash(Overdue, days);

  @override
  String toString() => 'Overdue($days)';
}

/// Works out when [kind] of care is due for [plant]; care that was never
/// done is due today. Repotting and pruning intervals are calendar months.
///
/// With [Plant.winterRest], watering counted from a day in winter rest takes
/// 1.5 times as long, and fertilizing is never due during winter rest but on
/// March 1 instead.
CareStatus careStatus(Plant plant, CareKind kind, DateTime today) {
  final (interval, last) = switch (kind) {
    Water() => (plant.wateringIntervalDays, plant.lastWateredOn),
    Fertilize() => (plant.fertilizingIntervalDays, plant.lastFertilizedOn),
    Repot() => (plant.repottingIntervalMonths, plant.lastRepottedOn),
    Prune() => (plant.pruningIntervalMonths, plant.lastPrunedOn),
  };
  if (interval == null) return const NotScheduled();
  if (last == null) return const DueToday();

  final now = dayOf(today);
  var dueOn = nextCareDay(plant, kind, last, interval);
  if (kind is Fertilize &&
      plant.winterRest &&
      dueOn.isBefore(now) &&
      isWinterRest(now)) {
    dueOn = winterRestEnd(now);
  }
  final days = dueOn.difference(now).inDays;
  if (days > 0) return DueIn(days);
  if (days == 0) return const DueToday();
  return Overdue(-days);
}

/// The day after [day] on which [kind] of care is due again with
/// [interval], following the winter rest of [plant].
DateTime nextCareDay(Plant plant, CareKind kind, DateTime day, int interval) {
  final from = dayOf(day);
  switch (kind) {
    case Repot() || Prune():
      return addMonths(from, interval);
    case Water():
      final days = plant.winterRest && isWinterRest(from)
          ? winterWateringInterval(interval)
          : interval;
      return from.add(Duration(days: days));
    case Fertilize():
      final next = from.add(Duration(days: interval));
      return plant.winterRest && isWinterRest(next)
          ? winterRestEnd(next)
          : next;
  }
}

/// When [plant] needs water next.
CareStatus wateringStatus(Plant plant, DateTime today) =>
    careStatus(plant, const Water(), today);

/// Adds calendar months to a UTC day; the day is clamped to the last day of
/// shorter months (Jan 31 + 1 month = Feb 28/29).
DateTime addMonths(DateTime day, int months) {
  final monthIndex = day.month - 1 + months;
  final year = day.year + monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, day.day < lastDay ? day.day : lastDay);
}

/// Reads an interval typed by the user: empty means no schedule, otherwise
/// a whole number from 1 to [max].
({bool valid, int? days}) parseInterval(String text, {required int max}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return (valid: true, days: null);
  final value = int.tryParse(trimmed);
  if (value == null || value < 1 || value > max) {
    return (valid: false, days: null);
  }
  return (valid: true, days: value);
}

/// Reads a watering interval (1 to 365 days) typed by the user.
({bool valid, int? days}) parseWateringInterval(String text) =>
    parseInterval(text, max: 365);
