import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/phone_calendar.dart';
import 'package:green_friend/domain/plant.dart';

final today = DateTime(2026, 10, 14, 8);

PhoneCalendarEvent event(
  String id, {
  required DateTime day,
  String title = 'Monstera: Water',
  String? description,
}) => PhoneCalendarEvent(
  id: id,
  calendarId: 'c1',
  day: day,
  title: title,
  description: description,
);

void main() {
  group('plannedCareDays', () {
    test('lists each plant and day with all its due care for 60 days', () {
      final monstera = Plant(
        id: 'm',
        name: 'Monstera',
        wateringIntervalDays: 30,
        lastWateredOn: DateTime(2026, 10, 1),
        fertilizingIntervalDays: 30,
        lastFertilizedOn: DateTime(2026, 10, 1),
        winterRest: false,
      );

      final days = plannedCareDays([monstera], today: today);

      expect(days, [
        PlannedCareDay(
          plant: monstera,
          day: DateTime.utc(2026, 10, 31),
          kinds: const [Water(), Fertilize()],
        ),
        PlannedCareDay(
          plant: monstera,
          day: DateTime.utc(2026, 11, 30),
          kinds: const [Water(), Fertilize()],
        ),
      ]);
    });

    test('puts overdue care on today', () {
      final aloe = Plant(
        id: 'a',
        name: 'Aloe',
        wateringIntervalDays: 100,
        lastWateredOn: DateTime(2026, 6, 1),
      );

      final days = plannedCareDays([aloe], today: today, days: 1);

      expect(days.single.day, DateTime.utc(2026, 10, 14));
      expect(days.single.kinds, const [Water()]);
    });
  });

  group('calendar markers', () {
    test('round-trip plant id and day inside a description', () {
      final marker = calendarMarker('plant:1', DateTime.utc(2026, 10, 31));

      expect(marker, 'green-friend:plant:1:2026-10-31');
      expect(parseCalendarMarker('Planned by Green Friend\n$marker'), (
        plantId: 'plant:1',
        day: DateTime.utc(2026, 10, 31),
      ));
    });

    test('give null for other descriptions', () {
      expect(parseCalendarMarker(null), isNull);
      expect(parseCalendarMarker('Dentist'), isNull);
      expect(parseCalendarMarker('green-friend:x:not-a-date'), isNull);
    });
  });

  group('calendarChanges', () {
    WantedCalendarEvent wanted(String plantId, DateTime day, String title) =>
        WantedCalendarEvent(
          day: day,
          title: title,
          marker: calendarMarker(plantId, day),
        );

    test('creates missing events', () {
      final day = DateTime.utc(2026, 10, 20);

      final changes = calendarChanges(
        existing: const [],
        wanted: [wanted('m', day, 'Monstera: Water')],
      );

      expect(changes.create.single.title, 'Monstera: Water');
      expect(changes.update, isEmpty);
      expect(changes.delete, isEmpty);
    });

    test('keeps matching events and updates changed titles', () {
      final day = DateTime.utc(2026, 10, 20);
      final other = DateTime.utc(2026, 10, 21);

      final changes = calendarChanges(
        existing: [
          event('e1', day: day, description: calendarMarker('m', day)),
          event(
            'e2',
            day: other,
            title: 'Monstera: Water',
            description: calendarMarker('m', other),
          ),
        ],
        wanted: [
          wanted('m', day, 'Monstera: Water'),
          wanted('m', other, 'Monstera: Gießen'),
        ],
      );

      expect(changes.create, isEmpty);
      expect(changes.update, [(eventId: 'e2', title: 'Monstera: Gießen')]);
      expect(changes.delete, isEmpty);
    });

    test('deletes events that are no longer planned and duplicates', () {
      final day = DateTime.utc(2026, 10, 20);
      final marker = calendarMarker('m', day);

      final changes = calendarChanges(
        existing: [
          event('e1', day: day, description: marker),
          event('e2', day: day, description: marker),
          event(
            'e3',
            day: DateTime.utc(2026, 10, 22),
            description: calendarMarker('gone', DateTime.utc(2026, 10, 22)),
          ),
        ],
        wanted: [wanted('m', day, 'Monstera: Water')],
      );

      expect(changes.create, isEmpty);
      expect(changes.delete, ['e2', 'e3']);
    });

    test('never touches events without a Green Friend marker', () {
      final changes = calendarChanges(
        existing: [
          event(
            'mine',
            day: DateTime.utc(2026, 10, 20),
            title: 'Dentist',
            description: 'Bring the card',
          ),
          event('bare', day: DateTime.utc(2026, 10, 21), title: 'Water'),
        ],
        wanted: const [],
      );

      expect(changes.delete, isEmpty);
      expect(changes.update, isEmpty);
    });
  });
}
