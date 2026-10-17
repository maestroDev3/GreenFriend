import 'package:green_friend/domain/phone_calendar.dart';

/// In-memory [PhoneCalendar] for tests.
class FakePhoneCalendar implements PhoneCalendar {
  FakePhoneCalendar({
    this.grantAccess = true,
    List<PhoneCalendarInfo>? calendars,
    List<PhoneCalendarEvent> events = const [],
  }) : calendars =
           calendars ??
           const [
             PhoneCalendarInfo(
               id: 'c1',
               name: 'Personal',
               account: 'me@example.com',
               writable: true,
             ),
           ],
       events = [...events];

  final bool grantAccess;
  final List<PhoneCalendarInfo> calendars;
  final List<PhoneCalendarEvent> events;
  var accessRequests = 0;
  var _nextId = 1;

  @override
  Future<bool> requestAccess() async {
    accessRequests++;
    return grantAccess;
  }

  @override
  Future<List<PhoneCalendarInfo>> writableCalendars() async => [
    for (final calendar in calendars)
      if (calendar.writable) calendar,
  ];

  @override
  Future<List<PhoneCalendarEvent>> eventsBetween(
    String calendarId, {
    required DateTime from,
    required DateTime to,
  }) async => [
    for (final event in events)
      if (event.calendarId == calendarId &&
          !event.day.isBefore(from) &&
          event.day.isBefore(to))
        event,
  ];

  @override
  Future<void> create(
    String calendarId, {
    required DateTime day,
    required String title,
    required String description,
  }) async {
    events.add(
      PhoneCalendarEvent(
        id: 'e${_nextId++}',
        calendarId: calendarId,
        day: day,
        title: title,
        description: description,
      ),
    );
  }

  @override
  Future<void> updateTitle(String eventId, String title) async {
    final index = events.indexWhere((event) => event.id == eventId);
    final old = events[index];
    events[index] = PhoneCalendarEvent(
      id: old.id,
      calendarId: old.calendarId,
      day: old.day,
      title: title,
      description: old.description,
    );
  }

  @override
  Future<void> delete(String eventId) async =>
      events.removeWhere((event) => event.id == eventId);
}
