import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/water_amount.dart';

Plant plant({int? pot, int? every}) => Plant(
  id: 'p',
  name: 'Monstera',
  potDiameterCm: pot,
  wateringIntervalDays: every,
);

void main() {
  group('waterAmountMl', () {
    test('the amount follows the decided formula and rounding', () {
      // Standard pot: height 0.9 × diameter; 15 % up to every 4 days, 20 %
      // up to every 10 days, 25 % for rarer watering; 50 ml steps.
      expect(waterAmountMl(plant(pot: 14, every: 7)), 400);
      expect(waterAmountMl(plant(pot: 12, every: 7)), 250);
      expect(waterAmountMl(plant(pot: 10, every: 3)), 100);
      expect(waterAmountMl(plant(pot: 10, every: 4)), 100);
      expect(waterAmountMl(plant(pot: 20, every: 14)), 1400);
      expect(waterAmountMl(plant(pot: 20, every: 10)), 1150);
    });

    test('the amount is at least 50 ml', () {
      expect(waterAmountMl(plant(pot: 5, every: 21)), 50);
    });

    test('the amount is null without pot size or interval', () {
      expect(waterAmountMl(plant(every: 7)), isNull);
      expect(waterAmountMl(plant(pot: 14)), isNull);
    });
  });

  group('Plant.potDiameterCm', () {
    test('a pot diameter from 5 to 100 cm is kept and copied', () {
      final small = plant(pot: 5);

      expect(small.potDiameterCm, 5);
      expect(plant(pot: 100).potDiameterCm, 100);
      expect(small.copyWith(name: 'x').potDiameterCm, 5);
      expect(small.copyWith(potDiameterCm: 12).potDiameterCm, 12);
      expect(small, isNot(small.copyWith(potDiameterCm: 12)));
    });

    test('a pot diameter outside 5 to 100 cm is rejected', () {
      expect(() => plant(pot: 4), throwsArgumentError);
      expect(() => plant(pot: 101), throwsArgumentError);
    });
  });
}
