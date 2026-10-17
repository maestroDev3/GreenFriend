import 'clock.dart';
import 'plant.dart';

/// A place the weather is fetched for.
class WeatherLocation {
  const WeatherLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.region,
  });

  final String name;

  /// E.g. "Bavaria, Germany", to tell places with the same name apart.
  final String? region;
  final double latitude;
  final double longitude;

  /// "Munich, Bavaria, Germany".
  String get label => region == null ? name : '$name, $region';

  @override
  bool operator ==(Object other) =>
      other is WeatherLocation &&
      other.name == name &&
      other.region == region &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(name, region, latitude, longitude);

  @override
  String toString() => 'WeatherLocation($label)';
}

/// The weather of one day.
class DailyWeather {
  const DailyWeather({
    required this.day,
    required this.rainMm,
    this.maxTemperature,
  });

  /// Calendar day (UTC midnight).
  final DateTime day;

  /// Precipitation of the whole day in millimetres.
  final double rainMm;

  /// Highest temperature in °C, if known.
  final double? maxTemperature;

  @override
  bool operator ==(Object other) =>
      other is DailyWeather &&
      other.day == day &&
      other.rainMm == rainMm &&
      other.maxTemperature == maxTemperature;

  @override
  int get hashCode => Object.hash(day, rainMm, maxTemperature);

  @override
  String toString() => 'DailyWeather($day, $rainMm mm, $maxTemperature °C)';
}

/// The weather service could not be reached or answered with an error.
class WeatherUnavailable implements Exception {
  const WeatherUnavailable([this.detail]);

  final String? detail;

  @override
  String toString() => 'WeatherUnavailable($detail)';
}

/// Finds places and daily weather; throws [WeatherUnavailable] on errors.
abstract interface class WeatherService {
  Future<List<WeatherLocation>> searchPlaces(
    String query, {
    required String languageCode,
  });

  /// The last few days and the next days for [location].
  Future<List<DailyWeather>> dailyWeather(WeatherLocation location);
}

/// From this much rain on a day an outdoor plant counts as watered.
const rainWateringMm = 5.0;

/// From this maximum temperature the home screen warns about heat.
const heatCelsius = 30.0;

/// The rain that counts as watering: for every outdoor plant with a watering
/// schedule, the latest **past** day after its last watering with at least
/// [rainWateringMm] of rain. Today is left out because its rain is only a
/// forecast.
List<({Plant plant, DateTime day})> rainWaterings(
  Iterable<Plant> plants, {
  required List<DailyWeather> weather,
  required DateTime today,
}) {
  final now = dayOf(today);
  final rainyDays = [
    for (final entry in weather)
      if (entry.rainMm >= rainWateringMm && entry.day.isBefore(now)) entry.day,
  ]..sort();
  return [
    for (final plant in plants)
      if (plant.outdoor && plant.wateringIntervalDays != null)
        if (_latestAfter(rainyDays, plant.lastWateredOn) case final day?)
          (plant: plant, day: day),
  ];
}

DateTime? _latestAfter(List<DateTime> sortedDays, DateTime? last) {
  for (final day in sortedDays.reversed) {
    if (last == null || day.isAfter(last)) return day;
  }
  return null;
}

/// A weather hint for outdoor plants on the home screen.
sealed class WeatherHint {
  const WeatherHint();
}

/// At least [rainWateringMm] of rain are expected today.
final class RainToday extends WeatherHint {
  const RainToday(this.mm);

  final double mm;

  @override
  bool operator ==(Object other) => other is RainToday && other.mm == mm;

  @override
  int get hashCode => Object.hash(RainToday, mm);

  @override
  String toString() => 'RainToday($mm)';
}

/// Today gets at least [heatCelsius] hot.
final class Heat extends WeatherHint {
  const Heat(this.celsius);

  final double celsius;

  @override
  bool operator ==(Object other) => other is Heat && other.celsius == celsius;

  @override
  int get hashCode => Object.hash(Heat, celsius);

  @override
  String toString() => 'Heat($celsius)';
}

/// Today's hint: heat comes first (outdoor plants dry out fast), then rain.
WeatherHint? weatherHint(
  List<DailyWeather> weather, {
  required DateTime today,
}) {
  final now = dayOf(today);
  for (final entry in weather) {
    if (entry.day != now) continue;
    if (entry.maxTemperature case final max? when max >= heatCelsius) {
      return Heat(max);
    }
    if (entry.rainMm >= rainWateringMm) return RainToday(entry.rainMm);
  }
  return null;
}
