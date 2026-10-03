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
    this.prune = const [],
  });

  /// Local date and time of the reminder.
  final DateTime at;

  /// Plants that need water.
  final List<String> plantNames;

  /// Plants that need fertilizer.
  final List<String> fertilize;

  /// Plants that need repotting.
  final List<String> repot;

  /// Plants that need pruning.
  final List<String> prune;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.at == at &&
      _sameNames(other.plantNames, plantNames) &&
      _sameNames(other.fertilize, fertilize) &&
      _sameNames(other.repot, repot) &&
      _sameNames(other.prune, prune);

  @override
  int get hashCode => Object.hash(
    at,
    Object.hashAll(plantNames),
    Object.hashAll(fertilize),
    Object.hashAll(repot),
    Object.hashAll(prune),
  );

  @override
  String toString() =>
      'PlannedReminder($at, $plantNames, $fertilize, $repot, $prune)';

  static bool _sameNames(List<String> a, List<String> b) =>
      a.length == b.length &&
      Iterable.generate(a.length).every((i) => a[i] == b[i]);
}

/// Plans one reminder per day for up to [days] days, starting today if
/// [time] is still ahead, otherwise tomorrow. Each lists the plants whose
/// watering, fertilizing, repotting or pruning is due or overdue that day, assuming
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
    final prune = _dueOn(sorted, const Prune(), day);
    if ([water, fertilize, repot, prune].every((names) => names.isEmpty)) {
      continue;
    }
    reminders.add(
      PlannedReminder(
        at: _localAt(day, time),
        plantNames: water,
        fertilize: fertilize,
        repot: repot,
        prune: prune,
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

/// The reminder for one plant on one day, listing the care due then.
class PlantReminder {
  const PlantReminder({
    required this.at,
    required this.plant,
    required this.kinds,
  });

  /// Local date and time to show the reminder.
  final DateTime at;
  final Plant plant;

  /// The care due or overdue that day, in the order of [CareKind.values].
  final List<CareKind> kinds;

  @override
  bool operator ==(Object other) =>
      other is PlantReminder &&
      other.at == at &&
      other.plant == plant &&
      other.kinds.length == kinds.length &&
      Iterable.generate(kinds.length).every((i) => other.kinds[i] == kinds[i]);

  @override
  int get hashCode => Object.hash(at, plant, Object.hashAll(kinds));

  @override
  String toString() => 'PlantReminder($at, ${plant.name}, $kinds)';
}

/// Plans one reminder per plant and day for up to [days] days (see
/// [plannedReminders] for the start day), so each notification can offer
/// buttons for exactly that plant's due care.
List<PlantReminder> plannedPlantReminders(
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
      for (final plant in sorted)
        if (_dueKinds(plant, today.add(Duration(days: offset)))
            case final kinds when kinds.isNotEmpty)
          PlantReminder(
            at: _localAt(today.add(Duration(days: offset)), time),
            plant: plant,
            kinds: kinds,
          ),
  ];
}

List<CareKind> _dueKinds(Plant plant, DateTime day) => [
  for (final kind in CareKind.values)
    if (careStatus(plant, kind, day) case DueToday() || Overdue()) kind,
];

const _careActionPrefix = 'care';

/// The id of the notification button that records [kind] for [plantId].
String careActionId(String plantId, CareKind kind) =>
    '$_careActionPrefix:${kind.name}:$plantId';

/// Reads an id made by [careActionId]; `null` for any other id.
({String plantId, CareKind kind})? parseCareActionId(String? id) {
  final parts = id?.split(':');
  if (parts == null || parts.length < 3 || parts[0] != _careActionPrefix) {
    return null;
  }
  final kind = CareKind.byName(parts[1]);
  final plantId = parts.sublist(2).join(':');
  if (kind == null || plantId.isEmpty) return null;
  return (plantId: plantId, kind: kind);
}
