import 'package:green_friend/domain/weather.dart';

/// Returns prepared places and weather instead of calling Open-Meteo.
class FakeWeatherService implements WeatherService {
  FakeWeatherService({
    this.places = const [],
    this.weather = const [],
    this.failing = false,
  });

  List<WeatherLocation> places;
  List<DailyWeather> weather;
  bool failing;
  final searches = <String>[];
  final fetches = <WeatherLocation>[];

  @override
  Future<List<WeatherLocation>> searchPlaces(
    String query, {
    required String languageCode,
  }) async {
    searches.add(query);
    if (failing) throw const WeatherUnavailable();
    return places;
  }

  @override
  Future<List<DailyWeather>> dailyWeather(WeatherLocation location) async {
    fetches.add(location);
    if (failing) throw const WeatherUnavailable();
    return weather;
  }
}
