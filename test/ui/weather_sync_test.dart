import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/weather.dart';
import 'package:green_friend/ui/settings_controller.dart';
import 'package:green_friend/ui/weather_sync.dart';

import '../support/fake_care_log_repository.dart';
import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/fake_weather_service.dart';

const munich = WeatherLocation(name: 'Munich', latitude: 48.1, longitude: 11.6);

Plant lavender({bool outdoor = true}) => Plant(
  id: 'l',
  name: 'Lavender',
  outdoor: outdoor,
  wateringIntervalDays: 4,
  lastWateredOn: DateTime(2026, 10, 10),
);

final rainy = [
  DailyWeather(day: DateTime.utc(2026, 10, 12), rainMm: 9),
  DailyWeather(day: DateTime.utc(2026, 10, 14), rainMm: 0, maxTemperature: 31),
];

class Setup {
  Setup({
    List<Plant>? plants,
    WeatherLocation? location = munich,
    FakeWeatherService? service,
  }) : plants = FakePlantRepository(plants ?? [lavender()]),
       service = service ?? FakeWeatherService(weather: rainy),
       settings = SettingsController(
         FakeSettingsRepository(weatherLocation: location),
       );

  final FakePlantRepository plants;
  final logs = FakeCareLogRepository();
  final FakeWeatherService service;
  final SettingsController settings;
  var now = DateTime(2026, 10, 14, 9);
  late final sync = WeatherSync(
    plants: plants,
    careLogs: logs,
    settings: settings,
    service: service,
    clock: () => now,
  );

  Future<void> refresh() async {
    await settings.load();
    await sync.refresh();
  }
}

void main() {
  group('WeatherSync', () {
    test('records a rainy past day as watering for outdoor plants', () async {
      final setup = Setup();

      await setup.refresh();

      expect(
        setup.plants.plants.single.lastWateredOn,
        DateTime.utc(2026, 10, 12),
      );
      expect(setup.logs.logs.single.kind, const Water());
      expect(setup.logs.logs.single.day, DateTime.utc(2026, 10, 12));
      expect(setup.sync.hint, const Heat(31));
    });

    test('fetches nothing without a place or outdoor plants', () async {
      final noPlace = Setup(location: null);
      await noPlace.refresh();
      expect(noPlace.service.fetches, isEmpty);

      final indoor = Setup(plants: [lavender(outdoor: false)]);
      await indoor.refresh();
      expect(indoor.service.fetches, isEmpty);
      expect(indoor.sync.hint, isNull);
    });

    test('leaves everything unchanged when the weather fails', () async {
      final setup = Setup(service: FakeWeatherService(failing: true));

      await setup.refresh();

      expect(setup.plants.plants.single, lavender());
      expect(setup.logs.logs, isEmpty);
      expect(setup.sync.hint, isNull);
    });

    test(
      'fetches at most every three hours unless the place changes',
      () async {
        final setup = Setup();
        await setup.refresh();

        setup.now = DateTime(2026, 10, 14, 11);
        await setup.sync.refresh();
        expect(setup.service.fetches, hasLength(1));

        setup.now = DateTime(2026, 10, 14, 12, 30);
        await setup.sync.refresh();
        expect(setup.service.fetches, hasLength(2));

        await setup.settings.setWeatherLocation(
          const WeatherLocation(
            name: 'Berlin',
            latitude: 52.5,
            longitude: 13.4,
          ),
        );
        await setup.sync.refresh();
        expect(setup.service.fetches.last.name, 'Berlin');
      },
    );
  });
}
