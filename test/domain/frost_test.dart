import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/frost.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/species.dart';
import 'package:green_friend/domain/weather.dart';

Species _species(int? minTemperature) => Species(
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
  minTemperature: minTemperature,
);

void main() {
  frostWarningTests();

  group('Species.minTemperature', () {
    test('a lowest temperature between -30 and 20 °C is kept', () {
      expect(_species(-30).minTemperature, -30);
      expect(_species(20).minTemperature, 20);
      expect(_species(null).minTemperature, isNull);
    });

    test('a lowest temperature outside -30 to 20 °C is rejected', () {
      expect(() => _species(-31), throwsArgumentError);
      expect(() => _species(21), throwsArgumentError);
    });

    test('species with a different lowest temperature are not equal', () {
      expect(_species(3), isNot(_species(5)));
      expect(_species(3), _species(3));
    });
  });

  group('toleratedMinimum', () {
    test("toleratedMinimum prefers the plant's value", () {
      final plant = Plant(id: 'p', name: 'Lemon', minTemperature: -2);

      expect(toleratedMinimum(plant, _species(3)), -2);
    });

    test('toleratedMinimum uses the species value without own value', () {
      final plant = Plant(id: 'p', name: 'Lemon');

      expect(toleratedMinimum(plant, _species(3)), 3);
    });

    test('toleratedMinimum falls back to 5 °C', () {
      final plant = Plant(id: 'p', name: 'Lemon');

      expect(defaultMinTemperature, 5);
      expect(toleratedMinimum(plant, null), 5);
      expect(toleratedMinimum(plant, _species(null)), 5);
    });

    test('a plant keeps its lowest temperature when copied', () {
      final plant = Plant(id: 'p', name: 'Lemon', minTemperature: 2);

      expect(plant.copyWith(name: 'Lime').minTemperature, 2);
      expect(plant.copyWith(minTemperature: -4).minTemperature, -4);
      expect(plant, isNot(plant.copyWith(minTemperature: -4)));
    });
  });
}

final _today = DateTime(2026, 10, 17, 9);

Plant _plant(String name, {bool outdoor = true, int? minTemperature}) => Plant(
  id: name,
  name: name,
  outdoor: outdoor,
  minTemperature: minTemperature,
);

DailyWeather _night(int offset, double? min) => DailyWeather(
  day: DateTime.utc(2026, 10, 17 + offset),
  rainMm: 0,
  minTemperature: min,
);

int _tolerance(Plant plant) => toleratedMinimum(plant, null);

void frostWarningTests() {
  group('frostWarnings', () {
    test('a night counts when its minimum is below an outdoor plant '
        'tolerated temperature; that plant is named', () {
      final warnings = frostWarnings(
        [
          _plant('Oleander', minTemperature: -5),
          _plant('Lemon', minTemperature: 3),
          _plant('Basil', minTemperature: 10),
        ],
        weather: [_night(1, 1.5), _night(2, -6)],
        tolerance: _tolerance,
        today: _today,
      );

      expect(warnings, [
        FrostWarning(
          day: DateTime.utc(2026, 10, 18),
          minTemperature: 1.5,
          plantNames: const ['Basil', 'Lemon'],
        ),
        FrostWarning(
          day: DateTime.utc(2026, 10, 19),
          minTemperature: -6,
          plantNames: const ['Basil', 'Lemon', 'Oleander'],
        ),
      ]);
    });

    test('indoor plants and plants tolerating the minimum are never named; '
        'today and later days are ignored', () {
      final warnings = frostWarnings(
        [
          _plant('Monstera', outdoor: false, minTemperature: 12),
          _plant('Box', minTemperature: -20),
        ],
        weather: [_night(0, -8), _night(1, -8), _night(2, 4), _night(3, -25)],
        tolerance: _tolerance,
        today: _today,
      );

      expect(warnings, isEmpty);
    });

    test('nights without a known minimum are ignored', () {
      expect(
        frostWarnings(
          [_plant('Lemon', minTemperature: 3)],
          weather: [_night(1, null)],
          tolerance: _tolerance,
          today: _today,
        ),
        isEmpty,
      );
    });
  });
}
