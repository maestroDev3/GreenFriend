import 'package:device_calendar_plus/device_calendar_plus.dart';

import '../domain/phone_calendar.dart';

/// The phone's calendars through `device_calendar_plus` (Android Calendar
/// Provider; Apple EventKit once the app runs on iOS).
///
/// Care events are all-day, marked as free and have no alarms, because the
/// app reminds on its own.
class DevicePhoneCalendar implements PhoneCalendar {
  DevicePhoneCalendar([DeviceCalendar? plugin])
    : _plugin = plugin ?? DeviceCalendar.instance;

  final DeviceCalendar _plugin;

  @override
  Future<bool> requestAccess() async =>
      await _plugin.requestPermissions() == CalendarPermissionStatus.granted;

  @override
  Future<List<PhoneCalendarInfo>> writableCalendars() async => [
    for (final calendar in await _plugin.listCalendars())
      if (!calendar.readOnly && !calendar.hidden) phoneCalendarInfoOf(calendar),
  ];

  @override
  Future<List<PhoneCalendarEvent>> eventsBetween(
    String calendarId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final events = await _plugin.listEvents(
      _localDay(from),
      _localDay(to),
      calendarIds: [calendarId],
    );
    return [
      for (final event in events)
        if (event.isAllDay)
          PhoneCalendarEvent(
            id: event.eventId,
            calendarId: event.calendarId,
            day: calendarDayOf(event.startDate),
            title: event.title,
            description: event.description,
          ),
    ];
  }

  @override
  Future<void> create(
    String calendarId, {
    required DateTime day,
    required String title,
    required String description,
  }) async {
    final start = _localDay(day);
    await _plugin.createEvent(
      calendarId: calendarId,
      title: title,
      startDate: start,
      endDate: DateTime(start.year, start.month, start.day + 1),
      isAllDay: true,
      description: description,
      availability: EventAvailability.free,
    );
  }

  @override
  Future<void> updateTitle(String eventId, String title) =>
      _plugin.updateEvent(eventId: eventId, title: title);

  @override
  Future<void> delete(String eventId) => _plugin.deleteEvent(eventId: eventId);
}

/// The calendar as the app shows it in the picker.
PhoneCalendarInfo phoneCalendarInfoOf(Calendar calendar) => PhoneCalendarInfo(
  id: calendar.id,
  name: calendar.name,
  account: calendar.accountName,
  writable: !calendar.readOnly,
);

/// The calendar day of an all-day event's floating start date.
DateTime calendarDayOf(DateTime start) =>
    DateTime.utc(start.year, start.month, start.day);

DateTime _localDay(DateTime day) => DateTime(day.year, day.month, day.day);
