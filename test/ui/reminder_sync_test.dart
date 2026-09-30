import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_actions.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/reminders.dart';
import 'package:green_friend/l10n/app_localizations.dart';
import 'package:green_friend/ui/reminder_sync.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_notification_scheduler.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';

DateTime fixedNow() => DateTime(2026, 9, 30, 7);

Plant monstera() => Plant(
  id: '1',
  name: 'Monstera',
  wateringIntervalDays: 7,
  lastWateredOn: DateTime(2026, 9, 23),
);

class Setup {
  Setup({List<Plant> plants = const [], ReminderSettings? reminder})
    : plants = FakePlantRepository(plants),
      settings = SettingsController(
        FakeSettingsRepository(reminder: reminder ?? ReminderSettings.defaults),
      );

  final FakePlantRepository plants;
  final SettingsController settings;
  final scheduler = FakeNotificationScheduler();
  late final sync = ReminderSync(
    plants: plants,
    settings: settings,
    scheduler: scheduler,
    clock: fixedNow,
    localizations: () => lookupAppLocalizations(const Locale('en')),
  );

  Future<void> start() async {
    await settings.load();
    sync.start();
    await sync.idle;
  }
}

void main() {
  group('ReminderSync', () {
    test('schedules the daily reminders with localized texts', () async {
      final setup = Setup(plants: [monstera()]);

      await setup.start();

      final first = setup.scheduler.scheduled.first;
      expect(first.at, DateTime(2026, 9, 30, 9));
      expect(first.title, 'Time to water');
      expect(first.body, 'Water today: Monstera');
      expect(setup.scheduler.scheduled, hasLength(14));
      expect(
        setup.scheduler.scheduled.map((notification) => notification.id),
        List.generate(14, (i) => i + 1),
      );
    });

    test('reschedules after the plant was watered', () async {
      final setup = Setup(plants: [monstera()]);
      await setup.start();

      await confirmWatering(
        plants: setup.plants,
        careLogs: FakeCareLogRepository(),
        plant: monstera(),
        today: fixedNow(),
      );
      await setup.sync.idle;

      expect(setup.scheduler.scheduled.first.at, DateTime(2026, 10, 7, 9));
    });

    test('schedules nothing when the reminder is off', () async {
      final setup = Setup(plants: [monstera()]);
      await setup.start();

      await setup.settings.setReminder(
        const ReminderSettings(enabled: false, time: ReminderTime(9, 0)),
      );
      await setup.sync.idle;

      expect(setup.scheduler.scheduled, isEmpty);
    });

    test('uses the chosen reminder time', () async {
      final setup = Setup(
        plants: [monstera()],
        reminder: const ReminderSettings(
          enabled: true,
          time: ReminderTime(18, 30),
        ),
      );

      await setup.start();

      expect(setup.scheduler.scheduled.first.at, DateTime(2026, 9, 30, 18, 30));
    });

    test(
      'asks for permission once when there is something to remind',
      () async {
        final setup = Setup();
        await setup.start();
        expect(setup.scheduler.permissionRequests, 0);

        await setup.plants.add(
          name: 'Pothos',
          wateringIntervalDays: 3,
          lastWateredOn: DateTime(2026, 9, 29),
        );
        await setup.sync.idle;
        await setup.plants.add(name: 'Aloe', wateringIntervalDays: 5);
        await setup.sync.idle;

        expect(setup.scheduler.permissionRequests, 1);
      },
    );
  });
}
