import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_actions.dart';
import 'package:green_friend/domain/phone_calendar.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/settings.dart';
import 'package:green_friend/l10n/app_localizations.dart';
import 'package:green_friend/ui/calendar_sync.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_phone_calendar.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';

DateTime fixedNow() => DateTime(2026, 10, 14, 8);

Plant monstera() => Plant(
  id: 'm',
  name: 'Monstera',
  wateringIntervalDays: 30,
  lastWateredOn: DateTime(2026, 10, 1),
  winterRest: false,
);

class Setup {
  Setup({
    List<Plant> plants = const [],
    CalendarChoice? choice = (id: 'c1', name: 'Personal'),
    List<PhoneCalendarEvent> events = const [],
    this.locale = const Locale('en'),
  }) : plants = FakePlantRepository(plants),
       calendar = FakePhoneCalendar(events: events),
       settings = SettingsController(
         FakeSettingsRepository(phoneCalendar: choice),
       );

  final FakePlantRepository plants;
  final FakePhoneCalendar calendar;
  final SettingsController settings;
  final Locale locale;
  late final sync = CalendarSync(
    plants: plants,
    settings: settings,
    calendar: calendar,
    clock: fixedNow,
    localizations: () => lookupAppLocalizations(locale),
  );

  Future<void> start() async {
    await settings.load();
    sync.start();
    await sync.idle;
  }

  List<(DateTime, String)> get shown =>
      [for (final event in calendar.events) (event.day, event.title)]
        ..sort((a, b) => a.$1.compareTo(b.$1));
}

void main() {
  group('CalendarSync', () {
    test('adds the care plan of the next 60 days', () async {
      final setup = Setup(plants: [monstera()]);

      await setup.start();

      expect(setup.shown, [
        (DateTime.utc(2026, 10, 31), 'Monstera: Water'),
        (DateTime.utc(2026, 11, 30), 'Monstera: Water'),
      ]);
      expect(
        setup.calendar.events.first.description,
        contains(calendarMarker('m', DateTime.utc(2026, 10, 31))),
      );
    });

    test('moves the events after watering', () async {
      final setup = Setup(plants: [monstera()]);
      await setup.start();

      await confirmWatering(
        plants: setup.plants,
        careLogs: FakeCareLogRepository(),
        plant: monstera(),
        today: fixedNow(),
      );
      await setup.sync.idle;

      expect(setup.shown, [(DateTime.utc(2026, 11, 13), 'Monstera: Water')]);
    });

    test('follows new and deleted plants', () async {
      final setup = Setup(plants: [monstera()]);
      await setup.start();

      final aloe = await setup.plants.add(
        name: 'Aloe',
        wateringIntervalDays: 50,
        lastWateredOn: DateTime(2026, 10, 1),
        winterRest: false,
      );
      await setup.sync.idle;
      expect(
        setup.shown,
        contains((DateTime.utc(2026, 11, 20), 'Aloe: Water')),
      );

      await setup.plants.delete(aloe.id);
      await setup.sync.idle;
      expect(
        setup.shown.where((event) => event.$2.startsWith('Aloe')),
        isEmpty,
      );
    });

    test('writes the titles in German', () async {
      final setup = Setup(plants: [monstera()], locale: const Locale('de'));

      await setup.start();

      expect(setup.shown.first.$2, 'Monstera: Gießen');
    });

    test('does nothing without a chosen calendar', () async {
      final setup = Setup(plants: [monstera()], choice: null);

      await setup.start();

      expect(setup.calendar.events, isEmpty);
    });

    test('removes only its own upcoming events when switched off', () async {
      final dentist = PhoneCalendarEvent(
        id: 'mine',
        calendarId: 'c1',
        day: DateTime.utc(2026, 10, 20),
        title: 'Dentist',
      );
      final setup = Setup(plants: [monstera()], events: [dentist]);
      await setup.start();
      expect(setup.calendar.events, hasLength(3));

      await setup.sync.removeUpcoming('c1');

      expect(setup.calendar.events.single.title, 'Dentist');
    });
  });
}
