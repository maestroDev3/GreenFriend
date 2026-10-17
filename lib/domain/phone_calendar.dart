import 'care_log.dart';
import 'care_tasks.dart';
import 'clock.dart';
import 'plant.dart';

/// A calendar on the phone the user can pick for the care plan.
class PhoneCalendarInfo {
  const PhoneCalendarInfo({
    required this.id,
    required this.name,
    required this.writable,
    this.account,
  });

  final String id;
  final String name;

  /// The account the calendar belongs to, e.g. a Google address.
  final String? account;
  final bool writable;

  @override
  bool operator ==(Object other) =>
      other is PhoneCalendarInfo &&
      other.id == id &&
      other.name == name &&
      other.account == account &&
      other.writable == writable;

  @override
  int get hashCode => Object.hash(id, name, account, writable);

  @override
  String toString() => 'PhoneCalendarInfo($id, $name)';
}

/// An all-day event in a phone calendar.
class PhoneCalendarEvent {
  const PhoneCalendarEvent({
    required this.id,
    required this.calendarId,
    required this.day,
    required this.title,
    this.description,
  });

  final String id;
  final String calendarId;

  /// Calendar day (UTC midnight) of the event.
  final DateTime day;
  final String title;
  final String? description;

  @override
  String toString() => 'PhoneCalendarEvent($id, $day, $title)';
}

/// The calendars on the phone (Android Calendar Provider, later Apple's
/// calendar), behind an interface so the sync logic stays testable.
abstract interface class PhoneCalendar {
  /// Asks for calendar access if needed; `true` if it is granted.
  Future<bool> requestAccess();

  Future<List<PhoneCalendarInfo>> writableCalendars();

  /// All-day events of [calendarId] on days from [from] (inclusive) to [to]
  /// (exclusive).
  Future<List<PhoneCalendarEvent>> eventsBetween(
    String calendarId, {
    required DateTime from,
    required DateTime to,
  });

  /// Adds an all-day event without alarms.
  Future<void> create(
    String calendarId, {
    required DateTime day,
    required String title,
    required String description,
  });

  Future<void> updateTitle(String eventId, String title);

  Future<void> delete(String eventId);
}

/// The care due for one plant on one day.
class PlannedCareDay {
  const PlannedCareDay({
    required this.plant,
    required this.day,
    required this.kinds,
  });

  final Plant plant;

  /// Calendar day (UTC midnight).
  final DateTime day;

  /// In the order of [CareKind.values].
  final List<CareKind> kinds;

  @override
  bool operator ==(Object other) =>
      other is PlannedCareDay &&
      other.plant == plant &&
      other.day == day &&
      other.kinds.length == kinds.length &&
      Iterable.generate(kinds.length).every((i) => other.kinds[i] == kinds[i]);

  @override
  int get hashCode => Object.hash(plant, day, Object.hashAll(kinds));

  @override
  String toString() => 'PlannedCareDay(${plant.name}, $day, $kinds)';
}

/// The care plan for the next [days] days from [today], one entry per plant
/// and day; overdue care is planned on today (see [careTasksBetween]).
List<PlannedCareDay> plannedCareDays(
  Iterable<Plant> plants, {
  required DateTime today,
  int days = 60,
}) {
  final start = dayOf(today);
  final tasks = careTasksBetween(
    plants,
    from: start,
    to: start.add(Duration(days: days - 1)),
    today: start,
  );
  final grouped = <(String, DateTime), (Plant, Set<CareKind>)>{};
  for (final task in tasks) {
    final entry = grouped.putIfAbsent((
      task.plant.id,
      task.day,
    ), () => (task.plant, <CareKind>{}));
    entry.$2.add(task.kind);
  }
  final result = [
    for (final MapEntry(key: (_, day), value: (plant, kinds))
        in grouped.entries)
      PlannedCareDay(
        plant: plant,
        day: day,
        kinds: [
          for (final kind in CareKind.values)
            if (kinds.contains(kind)) kind,
        ],
      ),
  ];
  result.sort((a, b) {
    final byDay = a.day.compareTo(b.day);
    if (byDay != 0) return byDay;
    return a.plant.name.toLowerCase().compareTo(b.plant.name.toLowerCase());
  });
  return result;
}

const _markerPrefix = 'green-friend:';
final _markerPattern = RegExp(r'green-friend:(.+):(\d{4})-(\d{2})-(\d{2})');

/// Identifies a Green Friend event in its description, so the sync only
/// ever changes its own events.
String calendarMarker(String plantId, DateTime day) {
  final d = dayOf(day);
  return '$_markerPrefix$plantId:'
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Reads a [calendarMarker] from an event description; `null` if there is
/// none.
({String plantId, DateTime day})? parseCalendarMarker(String? description) {
  if (description == null) return null;
  final match = _markerPattern.firstMatch(description);
  if (match == null) return null;
  final [plantId, year, month, day] = [
    for (var group = 1; group <= 4; group++) match.group(group) ?? '',
  ];
  return (
    plantId: plantId,
    day: DateTime.utc(int.parse(year), int.parse(month), int.parse(day)),
  );
}

/// An event the calendar should contain.
class WantedCalendarEvent {
  const WantedCalendarEvent({
    required this.day,
    required this.title,
    required this.marker,
  });

  final DateTime day;
  final String title;

  /// See [calendarMarker].
  final String marker;

  @override
  String toString() => 'WantedCalendarEvent($day, $title)';
}

/// What to change in a calendar so it matches [wanted].
typedef CalendarChanges = ({
  List<WantedCalendarEvent> create,
  List<({String eventId, String title})> update,
  List<String> delete,
});

/// Compares the Green Friend events in [existing] with [wanted]: missing
/// ones are created, changed titles updated, obsolete ones and duplicates
/// deleted. Events without a marker belong to the user and are ignored.
CalendarChanges calendarChanges({
  required List<PhoneCalendarEvent> existing,
  required List<WantedCalendarEvent> wanted,
}) {
  final byMarker = {for (final event in wanted) event.marker: event};
  final seen = <String>{};
  final update = <({String eventId, String title})>[];
  final delete = <String>[];
  for (final event in existing) {
    final parsed = parseCalendarMarker(event.description);
    if (parsed == null) continue;
    final marker = calendarMarker(parsed.plantId, parsed.day);
    final target = byMarker[marker];
    if (target == null || !seen.add(marker)) {
      delete.add(event.id);
    } else if (event.title != target.title) {
      update.add((eventId: event.id, title: target.title));
    }
  }
  return (
    create: [
      for (final event in wanted)
        if (!seen.contains(event.marker)) event,
    ],
    update: update,
    delete: delete,
  );
}
