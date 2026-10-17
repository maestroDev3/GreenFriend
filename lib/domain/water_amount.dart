import 'dart:math';

import 'plant.dart';

/// How much water [plant] gets per watering in ml, from its pot size and
/// watering interval; `null` without pot size or watering interval.
///
/// A standard pot is about 0.9 times as high as wide. Plants watered every
/// 4 days or more often get 15 % of the pot volume, up to every 10 days 20 %,
/// rarer watering 25 %; rounded to 50 ml, at least 50 ml.
int? waterAmountMl(Plant plant) {
  final diameter = plant.potDiameterCm;
  final interval = plant.wateringIntervalDays;
  if (diameter == null || interval == null) return null;
  final radius = diameter / 2;
  final volumeMl = pi * radius * radius * 0.9 * diameter;
  final share = switch (interval) {
    <= 4 => 0.15,
    <= 10 => 0.2,
    _ => 0.25,
  };
  return max(50, (volumeMl * share / 50).round() * 50);
}
