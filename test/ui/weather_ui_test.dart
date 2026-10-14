import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/weather.dart';
import 'package:green_friend/ui/home_screen.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/settings_screen.dart';
import 'package:green_friend/ui/weather_sync.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_journal_repository.dart';
import '../support/fake_photos.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_species_catalog.dart';
import '../support/fake_weather_service.dart';
import '../support/pump_app.dart';

const munich = WeatherLocation(
  name: 'Munich',
  region: 'Bavaria, Germany',
  latitude: 48.1,
  longitude: 11.6,
);

Plant lavender({bool outdoor = true}) => Plant(
  id: 'l',
  name: 'Lavender',
  outdoor: outdoor,
  wateringIntervalDays: 4,
  lastWateredOn: DateTime(2026, 10, 13),
);

Future<(WeatherSync, FakeSettingsRepository)> weatherSync({
  required FakePlantRepository plants,
  WeatherLocation? location = munich,
  List<DailyWeather> weather = const [],
}) async {
  final repository = FakeSettingsRepository(weatherLocation: location);
  final settings = SettingsController(repository);
  await settings.load();
  final sync = WeatherSync(
    plants: plants,
    careLogs: FakeCareLogRepository(),
    settings: settings,
    service: FakeWeatherService(places: const [munich], weather: weather),
    clock: () => DateTime(2026, 10, 14, 9),
  );
  await sync.refresh();
  return (sync, repository);
}

Widget home(FakePlantRepository plants, WeatherSync sync) => HomeScreen(
  plants: plants,
  careLogs: FakeCareLogRepository(),
  journal: FakeJournalRepository(),
  photos: FakePhotoStore(),
  photoPicker: FakePhotoPicker(),
  species: FakeSpeciesCatalog(const []),
  weather: sync,
  clock: () => DateTime(2026, 10, 14, 9),
);

void main() {
  group('weather hint on the home screen', () {
    testWidgets('warns about heat', (tester) async {
      final plants = FakePlantRepository([lavender()]);
      final (sync, _) = await weatherSync(
        plants: plants,
        weather: [
          DailyWeather(
            day: DateTime.utc(2026, 10, 14),
            rainMm: 0,
            maxTemperature: 31,
          ),
        ],
      );

      await tester.pumpApp(home(plants, sync), settings: sync.settings);

      expect(
        find.text('Hot today (31 °C) – check your outdoor plants'),
        findsOneWidget,
      );
    });

    testWidgets('announces rain', (tester) async {
      final plants = FakePlantRepository([lavender()]);
      final (sync, _) = await weatherSync(
        plants: plants,
        weather: [DailyWeather(day: DateTime.utc(2026, 10, 14), rainMm: 8)],
      );

      await tester.pumpApp(home(plants, sync), settings: sync.settings);

      expect(
        find.text('Rain expected today (8 mm) – outdoor plants get water'),
        findsOneWidget,
      );
    });

    testWidgets('stays away without outdoor plants', (tester) async {
      final plants = FakePlantRepository([lavender(outdoor: false)]);
      final (sync, _) = await weatherSync(
        plants: plants,
        weather: [
          DailyWeather(
            day: DateTime.utc(2026, 10, 14),
            rainMm: 0,
            maxTemperature: 31,
          ),
        ],
      );

      await tester.pumpApp(home(plants, sync), settings: sync.settings);

      expect(find.textContaining('Hot today'), findsNothing);
    });
  });

  group('weather place in the settings', () {
    Future<FakeSettingsRepository> pumpSettings(
      WidgetTester tester, {
      WeatherLocation? location,
    }) async {
      final (sync, repository) = await weatherSync(
        plants: FakePlantRepository(),
        location: location,
      );
      await tester.pumpApp(
        WeatherScope(sync: sync, child: const SettingsScreen()),
        settings: sync.settings,
      );
      await tester.scrollUntilVisible(
        find.text('Choose place'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      return repository;
    }

    testWidgets('searches and chooses a place', (tester) async {
      final repository = await pumpSettings(tester);
      expect(find.text('Munich, Bavaria, Germany'), findsOneWidget);
      await tester.tap(find.text('Remove place'));
      await tester.pumpAndSettle();
      expect(repository.weatherLocation, isNull);

      await tester.tap(find.text('Choose place'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Munich');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Munich, Bavaria, Germany'));
      await tester.pumpAndSettle();

      expect(repository.weatherLocation, munich);
      expect(find.text('Munich, Bavaria, Germany'), findsOneWidget);
    });
  });
}
