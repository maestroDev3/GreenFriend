import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/open_meteo_weather_service.dart';
import 'package:green_friend/domain/weather.dart';

void main() {
  group('request URLs', () {
    test('search places by name in the app language', () {
      final uri = placeSearchUri('München', languageCode: 'de');

      expect(uri.host, 'geocoding-api.open-meteo.com');
      expect(uri.queryParameters['name'], 'München');
      expect(uri.queryParameters['language'], 'de');
      expect(uri.queryParameters['count'], '5');
    });

    test('ask for rain and maximum temperature of past and next days', () {
      final uri = forecastUri(
        const WeatherLocation(
          name: 'Munich',
          latitude: 48.14,
          longitude: 11.58,
        ),
      );

      expect(uri.host, 'api.open-meteo.com');
      expect(uri.queryParameters['latitude'], '48.14');
      expect(
        uri.queryParameters['daily'],
        'precipitation_sum,temperature_2m_max',
      );
      expect(uri.queryParameters['past_days'], '3');
      expect(uri.queryParameters['timezone'], 'auto');
    });
  });

  group('parsePlaces', () {
    test('reads name, region and coordinates', () {
      final places = parsePlaces(
        200,
        jsonEncode({
          'results': [
            {
              'name': 'München',
              'latitude': 48.13743,
              'longitude': 11.57549,
              'admin1': 'Bayern',
              'country': 'Deutschland',
            },
            {'name': 'Munich', 'latitude': 46.1, 'longitude': -94.1},
          ],
        }),
      );

      expect(places, const [
        WeatherLocation(
          name: 'München',
          region: 'Bayern, Deutschland',
          latitude: 48.13743,
          longitude: 11.57549,
        ),
        WeatherLocation(name: 'Munich', latitude: 46.1, longitude: -94.1),
      ]);
    });

    test('gives an empty list without results', () {
      expect(parsePlaces(200, '{"generationtime_ms":0.5}'), isEmpty);
    });
  });

  group('parseDailyWeather', () {
    test('reads one entry per day; missing values count as nothing', () {
      final days = parseDailyWeather(
        200,
        jsonEncode({
          'daily': {
            'time': ['2026-10-13', '2026-10-14'],
            'precipitation_sum': [6.4, null],
            'temperature_2m_max': [18.2, 21],
          },
        }),
      );

      expect(days, [
        DailyWeather(
          day: DateTime.utc(2026, 10, 13),
          rainMm: 6.4,
          maxTemperature: 18.2,
        ),
        DailyWeather(
          day: DateTime.utc(2026, 10, 14),
          rainMm: 0,
          maxTemperature: 21,
        ),
      ]);
    });

    test('raises WeatherUnavailable for errors and unreadable answers', () {
      expect(
        () => parseDailyWeather(400, '{"error":true}'),
        throwsA(isA<WeatherUnavailable>()),
      );
      expect(
        () => parseDailyWeather(200, 'oops'),
        throwsA(isA<WeatherUnavailable>()),
      );
      expect(() => parsePlaces(500, ''), throwsA(isA<WeatherUnavailable>()));
    });
  });
}
