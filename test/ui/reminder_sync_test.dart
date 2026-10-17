import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_actions.dart';
import 'package:green_friend/domain/notification_scheduler.dart';
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
      expect(first.title, 'Monstera');
      expect(first.body, 'Due today: Water');
      expect(first.actions, const [
        NotificationAction(id: 'care:water:1', label: 'Watered'),
      ]);
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

    test('lists fertilizing and repotting separately', () async {
      final setup = Setup(
        plants: [
          monstera(),
          Plant(
            id: '2',
            name: 'Pothos',
            fertilizingIntervalDays: 10,
            lastFertilizedOn: DateTime(2026, 9, 20),
          ),
        ],
      );

      await setup.start();

      final firstDay = setup.scheduler.scheduled.where(
        (notification) => notification.at == DateTime(2026, 9, 30, 9),
      );
      expect(firstDay.map((notification) => notification.title), [
        'Monstera',
        'Pothos',
      ]);
      expect(firstDay.last.body, 'Due today: Fertilize');
      expect(firstDay.last.actions.single.label, 'Fertilized');
    });

    test('lists pruning separately', () async {
      final setup = Setup(
        plants: [
          monstera(),
          Plant(
            id: '2',
            name: 'Olive',
            pruningIntervalMonths: 6,
            lastPrunedOn: DateTime(2026, 3, 30),
          ),
        ],
      );

      await setup.start();

      final olive = setup.scheduler.scheduled.firstWhere(
        (notification) => notification.title == 'Olive',
      );
      expect(olive.body, 'Due today: Prune');
      expect(olive.actions.single.label, 'Pruned');
    });

    test('writes the reminder in German', () async {
      final setup = Setup(
        plants: [
          monstera(),
          Plant(
            id: '2',
            name: 'Pothos',
            repottingIntervalMonths: 12,
            lastRepottedOn: DateTime(2025, 9, 1),
          ),
        ],
      );
      final german = ReminderSync(
        plants: setup.plants,
        settings: setup.settings,
        scheduler: setup.scheduler,
        clock: fixedNow,
        localizations: () => lookupAppLocalizations(const Locale('de')),
      );

      await setup.settings.load();
      german.start();
      await german.idle;

      final firstDay = setup.scheduler.scheduled
          .where((notification) => notification.at == DateTime(2026, 9, 30, 9))
          .toList();
      expect(firstDay.first.body, 'Heute fällig: Gießen');
      expect(firstDay.first.actions.single.label, 'Gegossen');
      expect(firstDay.last.title, 'Pothos');
      expect(firstDay.last.body, 'Heute fällig: Umtopfen');
      expect(firstDay.last.actions.single.label, 'Umgetopft');
    });

    test('offers at most three buttons when more care is due', () async {
      final setup = Setup(
        plants: [
          Plant(
            id: '3',
            name: 'Olive',
            wateringIntervalDays: 7,
            lastWateredOn: DateTime(2026, 9, 1),
            fertilizingIntervalDays: 14,
            lastFertilizedOn: DateTime(2026, 9, 1),
            repottingIntervalMonths: 12,
            lastRepottedOn: DateTime(2025, 9, 1),
            pruningIntervalMonths: 6,
            lastPrunedOn: DateTime(2026, 3, 1),
          ),
        ],
      );

      await setup.start();

      final first = setup.scheduler.scheduled.first;
      expect(first.body, 'Due today: Water, Fertilize, Repot, Prune');
      expect(first.actions.map((action) => action.id), [
        'care:water:3',
        'care:fertilize:3',
        'care:repot:3',
      ]);
    });

    test('can run without asking for permission (background)', () async {
      final setup = Setup(plants: [monstera()]);
      final quiet = ReminderSync(
        plants: setup.plants,
        settings: setup.settings,
        scheduler: setup.scheduler,
        clock: fixedNow,
        localizations: () => lookupAppLocalizations(const Locale('en')),
        askPermission: false,
      );

      await setup.settings.load();
      quiet.start();
      await quiet.idle;

      expect(setup.scheduler.scheduled, isNotEmpty);
      expect(setup.scheduler.permissionRequests, 0);
    });
  });
}
