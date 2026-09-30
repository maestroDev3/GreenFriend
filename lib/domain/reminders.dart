import 'care_log.dart';
import 'care_status.dart';
import 'clock.dart';
import 'plant.dart';

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

/// One daily reminder: when it fires and which plants need which care.
class PlannedReminder {
  const PlannedReminder({
    required this.at,
    required this.plantNames,
    this.fertilize = const [],
    this.repot = const [],
  });

  /// Local date and time of the reminder.
  final DateTime at;

  /// Plants that need water.
  final List<String> plantNames;

  /// Plants that need fertilizer.
  final List<String> fertilize;

  /// Plants that need repotting.
  final List<String> repot;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.at == at &&
      _sameNames(other.plantNames, plantNames) &&
      _sameNames(other.fertilize, fertilize) &&
      _sameNames(other.repot, repot);

  @override
  int get hashCode => Object.hash(
    at,
    Object.hashAll(plantNames),
    Object.hashAll(fertilize),
    Object.hashAll(repot),
  );

  @override
  String toString() => 'PlannedReminder($at, $plantNames, $fertilize, $repot)';

  static bool _sameNames(List<String> a, List<String> b) =>
      a.length == b.length &&
      Iterable.generate(a.length).every((i) => a[i] == b[i]);
}

/// Plans one reminder per day for up to [days] days, starting today if
/// [time] is still ahead, otherwise tomorrow. Each lists the plants whose
/// watering, fertilizing or repotting is due or overdue that day, assuming
/// nothing is done in between; days without such plants get no reminder.
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
  final reminders = <PlannedReminder>[];
  for (var offset = passed ? 1 : 0; offset < days; offset++) {
    final day = today.add(Duration(days: offset));
    final water = _dueOn(sorted, const Water(), day);
    final fertilize = _dueOn(sorted, const Fertilize(), day);
    final repot = _dueOn(sorted, const Repot(), day);
    if (water.isEmpty && fertilize.isEmpty && repot.isEmpty) continue;
    reminders.add(
      PlannedReminder(
        at: _localAt(day, time),
        plantNames: water,
        fertilize: fertilize,
        repot: repot,
      ),
    );
  }
  return reminders;
}

List<String> _dueOn(List<Plant> plants, CareKind kind, DateTime day) => [
  for (final plant in plants)
    if (careStatus(plant, kind, day) case DueToday() || Overdue()) plant.name,
];

DateTime _localAt(DateTime day, ReminderTime time) =>
    DateTime(day.year, day.month, day.day, time.hour, time.minute);
