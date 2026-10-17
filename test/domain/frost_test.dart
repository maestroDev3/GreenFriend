import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/frost.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/species.dart';

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
