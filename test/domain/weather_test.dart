import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/weather.dart';

final today = DateTime(2026, 10, 14, 9);

DailyWeather day(int dayOfMonth, {double rain = 0, double? max}) =>
    DailyWeather(
      day: DateTime.utc(2026, 10, dayOfMonth),
      rainMm: rain,
      maxTemperature: max,
    );

Plant lavender({bool outdoor = true, DateTime? lastWatered}) => Plant(
  id: 'l',
  name: 'Lavender',
  outdoor: outdoor,
  wateringIntervalDays: 4,
  lastWateredOn: lastWatered ?? DateTime(2026, 10, 10),
);

void main() {
  group('rainWaterings', () {
    test('counts the latest rainy past day as watering', () {
      final result = rainWaterings(
        [lavender()],
        weather: [day(11, rain: 6), day(12, rain: 12), day(13, rain: 1)],
        today: today,
      );

      expect(result.single.plant.name, 'Lavender');
      expect(result.single.day, DateTime.utc(2026, 10, 12));
    });

    test('ignores light rain, rain before the last watering and today', () {
      expect(
        rainWaterings(
          [lavender()],
          weather: [day(9, rain: 20), day(11, rain: 4.9), day(14, rain: 30)],
          today: today,
        ),
        isEmpty,
      );
    });

    test('ignores indoor plants and plants without watering', () {
      expect(
        rainWaterings(
          [
            lavender(outdoor: false),
            Plant(id: 'x', name: 'Stone', outdoor: true),
          ],
          weather: [day(12, rain: 12)],
          today: today,
        ),
        isEmpty,
      );
    });

    test('counts rain for a plant never watered', () {
      final never = Plant(
        id: 'n',
        name: 'New',
        outdoor: true,
        wateringIntervalDays: 3,
      );

      final result = rainWaterings(
        [never],
        weather: [day(13, rain: 8)],
        today: today,
      );

      expect(result.single.day, DateTime.utc(2026, 10, 13));
    });
  });

  group('weatherHint', () {
    test('reports heat first, then rain, otherwise nothing', () {
      expect(
        weatherHint([day(14, rain: 8, max: 31)], today: today),
        const Heat(31),
      );
      expect(
        weatherHint([day(14, rain: 8, max: 22)], today: today),
        const RainToday(8),
      );
      expect(weatherHint([day(14, rain: 2, max: 22)], today: today), isNull);
      expect(weatherHint([day(13, rain: 20, max: 35)], today: today), isNull);
    });
  });
}
