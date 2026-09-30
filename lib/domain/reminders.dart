import 'clock.dart';
import 'plant.dart';
import 'watering.dart';

/// Time of day for the daily reminder.
class ReminderTime {
  /// For trusted constants; use [ReminderTime.checked] for other values.
  const ReminderTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// Validating constructor for values from outside (storage, UI); throws
  /// [ArgumentError] for an invalid hour or minute.
  factory ReminderTime.checked(int hour, int minute) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'must be 0-23');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'must be 0-59');
    }
    return ReminderTime(hour, minute);
  }

  static const defaultTime = ReminderTime(9, 0);

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'ReminderTime($hour:$minute)';
}

/// Whether and when the daily reminder is shown.
class ReminderSettings {
  const ReminderSettings({required this.enabled, required this.time});

  /// On at 9:00.
  static const defaults = ReminderSettings(
    enabled: true,
    time: ReminderTime.defaultTime,
  );

  final bool enabled;
  final ReminderTime time;

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.time == time;

  @override
  int get hashCode => Object.hash(enabled, time);

  @override
  String toString() => 'ReminderSettings($enabled, $time)';
}

/// One daily reminder: when it fires and which plants need water.
class PlannedReminder {
  const PlannedReminder({required this.at, required this.plantNames});

  /// Local date and time of the reminder.
  final DateTime at;
  final List<String> plantNames;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.at == at &&
      other.plantNames.length == plantNames.length &&
      Iterable.generate(plantNames.length)
          .every((i) => other.plantNames[i] == plantNames[i]);

  @override
  int get hashCode => Object.hash(at, Object.hashAll(plantNames));

  @override
  String toString() => 'PlannedReminder($at, $plantNames)';
}

/// Plans one reminder per day for up to [days] days, starting today if
/// [time] is still ahead, otherwise tomorrow. Each lists the plants that are
/// due or overdue that day, assuming nobody waters in between; days without
/// such plants get no reminder.
List<PlannedReminder> plannedReminders(
  Iterable<Plant> plants, {
  required DateTime now,
  required ReminderTime time,
  int days = 14,
}) {
  final today = dayOf(now);
  final passed =
      now.hour > time.hour ||
      (now.hour == time.hour && now.minute >= time.minute);
  final sorted = sortedByName(plants);
  return [
    for (var offset = passed ? 1 : 0; offset < days; offset++)
      if (_dueOn(sorted, today.add(Duration(days: offset))) case final names
          when names.isNotEmpty)
        PlannedReminder(
          at: _localAt(today.add(Duration(days: offset)), time),
          plantNames: names,
        ),
  ];
}

List<String> _dueOn(List<Plant> plants, DateTime day) => [
  for (final plant in plants)
    if (wateringStatus(plant, day) case DueToday() || Overdue()) plant.name,
];

DateTime _localAt(DateTime day, ReminderTime time) =>
    DateTime(day.year, day.month, day.day, time.hour, time.minute);
