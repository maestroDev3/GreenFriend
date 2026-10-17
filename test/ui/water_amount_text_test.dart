import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/l10n/app_localizations.dart';
import 'package:green_friend/ui/calendar_sync.dart';
import 'package:green_friend/ui/plant_detail_screen.dart';
import 'package:green_friend/ui/reminder_sync.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_notification_scheduler.dart';
import '../support/fake_phone_calendar.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/pump_app.dart';

DateTime now() => DateTime(2026, 10, 17, 7);

Plant monty({int? pot = 14}) => Plant(
  id: 'm',
  name: 'Monty',
  wateringIntervalDays: 7,
  lastWateredOn: DateTime(2026, 10, 10),
  winterRest: false,
  potDiameterCm: pot,
);

Future<String> reminderBody(Plant plant, Locale locale) async {
  final settings = SettingsController(FakeSettingsRepository());
  await settings.load();
  final scheduler = FakeNotificationScheduler();
  final sync = ReminderSync(
    plants: FakePlantRepository([plant]),
    settings: settings,
    scheduler: scheduler,
    clock: now,
    localizations: () => lookupAppLocalizations(locale),
    askPermission: false,
  )..start();
  await sync.idle;
  return scheduler.scheduled.first.body;
}

Future<String> calendarTitle(Plant plant, Locale locale) async {
  final settings = SettingsController(
    FakeSettingsRepository(phoneCalendar: (id: 'c1', name: 'Personal')),
  );
  await settings.load();
  final calendar = FakePhoneCalendar();
  final sync = CalendarSync(
    plants: FakePlantRepository([plant]),
    settings: settings,
    calendar: calendar,
    clock: now,
    localizations: () => lookupAppLocalizations(locale),
  )..start();
  await sync.idle;
  return calendar.events.first.title;
}

void main() {
  group('water amount in reminder and calendar', () {
    test('with pot size the reminder body and the calendar title show the '
        'amount', () async {
      expect(
        await reminderBody(monty(), const Locale('en')),
        'Due today: Water (about 400 ml)',
      );
      expect(
        await calendarTitle(monty(), const Locale('en')),
        'Monty: Water (about 400 ml)',
      );
    });

    test('with pot size the texts show the amount in German', () async {
      expect(
        await calendarTitle(monty(), const Locale('de')),
        'Monty: Gießen (etwa 400 ml)',
      );
    });

    test('without pot size the texts stay as before', () async {
      expect(
        await reminderBody(monty(pot: null), const Locale('en')),
        'Due today: Water',
      );
      expect(
        await calendarTitle(monty(pot: null), const Locale('en')),
        'Monty: Water',
      );
    });
  });

  group('water amount on the detail page', () {
    Future<void> pumpDetail(WidgetTester tester, Plant plant) => tester.pumpApp(
      PlantDetailScreen(
        species: FakeSpeciesCatalog(const []),
        plants: FakePlantRepository([plant]),
        careLogs: FakeCareLogRepository(),
        journal: FakeJournalRepository(),
        photos: FakePhotoStore(),
        photoPicker: FakePhotoPicker(),
        plantId: 'm',
        clock: now,
      ),
    );

    testWidgets('with pot size the detail page shows the amount', (
      tester,
    ) async {
      await pumpDetail(tester, monty());

      expect(find.text('Every 7 days · about 400 ml'), findsOneWidget);
    });

    testWidgets('without pot size the detail page stays as before', (
      tester,
    ) async {
      await pumpDetail(tester, monty(pot: null));

      expect(find.text('Every 7 days'), findsOneWidget);
    });
  });
}
