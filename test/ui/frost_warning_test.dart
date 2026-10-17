import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/frost.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/species.dart';
import 'package:green_friend/domain/weather.dart';
import 'package:green_friend/l10n/app_localizations.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/reminder_sync.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/weather_sync.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_notification_scheduler.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/fake_weather_service.dart';
import '../support/pump_app.dart';

const munich = WeatherLocation(name: 'Munich', latitude: 48.1, longitude: 11.6);

final lemonSpecies = Species(
  id: 'citrus-limon',
  scientificName: 'Citrus limon',
  names: const {
    'en': ['Lemon tree'],
  },
  wateringIntervalDays: 4,
  fertilizingIntervalDays: 14,
  repottingIntervalMonths: 24,
  light: Light.direct,
  humidity: Humidity.medium,
  minTemperature: 3,
);

final lemon = Plant(
  id: 'lemon',
  name: 'Lemon',
  speciesId: 'citrus-limon',
  outdoor: true,
);
final box = Plant(id: 'box', name: 'Box', outdoor: true, minTemperature: -20);

DateTime morning() => DateTime(2026, 10, 17, 9);

final frosty = [
  DailyWeather(day: DateTime.utc(2026, 10, 18), rainMm: 0, minTemperature: -2),
  DailyWeather(day: DateTime.utc(2026, 10, 19), rainMm: 0, minTemperature: 6),
];

final tonight = FrostWarning(
  day: DateTime.utc(2026, 10, 18),
  minTemperature: -2,
  plantNames: const ['Lemon'],
);

Future<(WeatherSync, FakeSettingsRepository)> refreshed({
  WeatherLocation? location = munich,
  List<FrostWarning> stored = const [],
}) async {
  final repository = FakeSettingsRepository(
    weatherLocation: location,
    frostWarnings: stored,
  );
  final settings = SettingsController(repository);
  await settings.load();
  final sync = WeatherSync(
    plants: FakePlantRepository([lemon, box]),
    careLogs: FakeCareLogRepository(),
    settings: settings,
    service: FakeWeatherService(weather: frosty),
    species: FakeSpeciesCatalog([lemonSpecies]),
    clock: morning,
  );
  await sync.refresh();
  return (sync, repository);
}

Widget home(
  SettingsController settings, {
  DateTime Function() clock = morning,
}) => HomeScreen(
  plants: FakePlantRepository([lemon, box]),
  careLogs: FakeCareLogRepository(),
  journal: FakeJournalRepository(),
  photos: FakePhotoStore(),
  photoPicker: FakePhotoPicker(),
  species: FakeSpeciesCatalog([lemonSpecies]),
  clock: clock,
);

Future<FakeNotificationScheduler> planned(DateTime now) async {
  final settings = SettingsController(
    FakeSettingsRepository(frostWarnings: [tonight]),
  );
  await settings.load();
  final scheduler = FakeNotificationScheduler();
  final sync = ReminderSync(
    plants: FakePlantRepository([lemon, box]),
    settings: settings,
    scheduler: scheduler,
    clock: () => now,
    localizations: () => lookupAppLocalizations(const Locale('en')),
  )..start();
  await sync.idle;
  return scheduler;
}

void main() {
  group('frost warning from the weather', () {
    test(
      'after a fetch with frost the warning names the plants at risk',
      () async {
        final (sync, repository) = await refreshed();

        expect(sync.settings.frostWarnings, [tonight]);
        expect(repository.frostWarnings, [tonight]);
      },
    );

    test('without a weather place no warning is stored', () async {
      final (sync, repository) = await refreshed(
        location: null,
        stored: [tonight],
      );

      expect(sync.settings.frostWarnings, isEmpty);
      expect(repository.frostWarnings, isEmpty);
    });
  });

  group('frost warning on the home screen', () {
    testWidgets('after a fetch with frost the home screen shows the card '
        'naming the plants', (tester) async {
      final (sync, _) = await refreshed();

      await tester.pumpApp(home(sync.settings), settings: sync.settings);

      expect(find.text('Frost tonight: down to -2 °C'), findsOneWidget);
      expect(find.text('Bring inside or protect: Lemon'), findsOneWidget);
    });

    testWidgets('shows the frost card in German', (tester) async {
      final (sync, _) = await refreshed();

      await tester.pumpApp(
        home(sync.settings),
        settings: sync.settings,
        locale: const Locale('de'),
      );

      expect(find.text('Heute Nacht Frost: bis -2 °C'), findsOneWidget);
      expect(find.text('Reinholen oder schützen: Lemon'), findsOneWidget);
    });

    testWidgets('names the night after tomorrow as tomorrow night', (
      tester,
    ) async {
      final settings = SettingsController(
        FakeSettingsRepository(
          weatherLocation: munich,
          frostWarnings: [
            FrostWarning(
              day: DateTime.utc(2026, 10, 19),
              minTemperature: -4.4,
              plantNames: const ['Lemon'],
            ),
          ],
        ),
      );
      await settings.load();

      await tester.pumpApp(home(settings), settings: settings);

      expect(find.text('Frost tomorrow night: down to -4 °C'), findsOneWidget);
    });

    testWidgets('without a weather place no warning is shown', (tester) async {
      final settings = SettingsController(
        FakeSettingsRepository(frostWarnings: [tonight]),
      );
      await settings.load();

      await tester.pumpApp(home(settings), settings: settings);

      expect(find.textContaining('Frost'), findsNothing);
    });

    testWidgets('old warnings are not shown', (tester) async {
      final settings = SettingsController(
        FakeSettingsRepository(
          weatherLocation: munich,
          frostWarnings: [tonight],
        ),
      );
      await settings.load();

      await tester.pumpApp(
        home(settings, clock: () => DateTime(2026, 10, 18, 9)),
        settings: settings,
      );

      expect(find.textContaining('Frost'), findsNothing);
    });
  });

  group('frost notification', () {
    test('the reminder plan contains a frost notification at 5 pm the '
        'evening before', () async {
      final scheduler = await planned(morning());

      final frost = scheduler.scheduled.where(
        (notification) => notification.id >= frostNotificationIdBase,
      );
      expect(frost.single.at, DateTime(2026, 10, 17, 17));
      expect(frost.single.title, 'Frost tonight: down to -2 °C');
      expect(frost.single.body, 'Bring inside or protect: Lemon');
    });

    test('the reminder plan has no frost notification when 5 pm has '
        'passed', () async {
      final scheduler = await planned(DateTime(2026, 10, 17, 18));

      expect(
        scheduler.scheduled.where(
          (notification) => notification.id >= frostNotificationIdBase,
        ),
        isEmpty,
      );
    });
  });
}
