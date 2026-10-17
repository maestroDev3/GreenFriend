import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/weather.dart';

/// Weather from Open-Meteo: free, no API key, based on national weather
/// services (in Germany the DWD). Uses `dart:io` only, no new package.
class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService({this.timeout = const Duration(seconds: 15)});

  final Duration timeout;

  @override
  Future<List<WeatherLocation>> searchPlaces(
    String query, {
    required String languageCode,
  }) async {
    final (status, body) = await _get(
      placeSearchUri(query, languageCode: languageCode),
    );
    return parsePlaces(status, body);
  }

  @override
  Future<List<DailyWeather>> dailyWeather(WeatherLocation location) async {
    final (status, body) = await _get(forecastUri(location));
    return parseDailyWeather(status, body);
  }

  Future<(int, String)> _get(Uri uri) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return (response.statusCode, body);
    } on IOException catch (error) {
      throw WeatherUnavailable('$error');
    } on TimeoutException {
      throw const WeatherUnavailable('timeout');
    } on FormatException catch (error) {
      throw WeatherUnavailable('$error');
    } finally {
      client.close();
    }
  }
}

/// Up to five places named like [query], with names in [languageCode].
Uri placeSearchUri(String query, {required String languageCode}) => Uri.https(
  'geocoding-api.open-meteo.com',
  '/v1/search',
  {'name': query, 'count': '5', 'language': languageCode, 'format': 'json'},
);

/// Daily rain and maximum temperature of the last three and next two days.
Uri forecastUri(WeatherLocation location) =>
    Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${location.latitude}',
      'longitude': '${location.longitude}',
      'daily': 'precipitation_sum,temperature_2m_max,temperature_2m_min',
      'past_days': '3',
      'forecast_days': '2',
      'timezone': 'auto',
    });

/// Reads a geocoding answer; no results give an empty list.
List<WeatherLocation> parsePlaces(int statusCode, String body) {
  final json = _decode(statusCode, body);
  try {
    final results = json['results'] as List<Object?>? ?? const [];
    return [
      for (final result in results.cast<Map<String, Object?>>())
        WeatherLocation(
          name: result['name'] as String,
          region: switch ([
            result['admin1'],
            result['country'],
          ].whereType<String>().join(', ')) {
            '' => null,
            final region => region,
          },
          latitude: (result['latitude'] as num).toDouble(),
          longitude: (result['longitude'] as num).toDouble(),
        ),
    ];
  } on Object catch (error) {
    throw WeatherUnavailable('unreadable places: $error');
  }
}

/// Reads a forecast answer into one [DailyWeather] per day; missing rain
/// counts as 0 mm, a missing temperature as unknown.
List<DailyWeather> parseDailyWeather(int statusCode, String body) {
  final json = _decode(statusCode, body);
  try {
    final daily = json['daily'] as Map<String, Object?>;
    final days = (daily['time'] as List<Object?>).cast<String>();
    final rain = daily['precipitation_sum'] as List<Object?>;
    final max = daily['temperature_2m_max'] as List<Object?>;
    final min = daily['temperature_2m_min'] as List<Object?>?;
    return [
      for (var i = 0; i < days.length; i++)
        DailyWeather(
          day: DateTime.parse('${days[i]}T00:00:00Z'),
          rainMm: (rain[i] as num?)?.toDouble() ?? 0,
          maxTemperature: (max[i] as num?)?.toDouble(),
          minTemperature: (min?[i] as num?)?.toDouble(),
        ),
    ];
  } on Object catch (error) {
    throw WeatherUnavailable('unreadable forecast: $error');
  }
}

Map<String, Object?> _decode(int statusCode, String body) {
  if (statusCode != 200) throw WeatherUnavailable('status $statusCode');
  try {
    return jsonDecode(body) as Map<String, Object?>;
  } on Object catch (error) {
    throw WeatherUnavailable('unreadable answer: $error');
  }
}
