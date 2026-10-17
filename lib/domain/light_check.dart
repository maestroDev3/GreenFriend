import 'species.dart';

/// How the measured light suits a plant.
enum LightVerdict { tooDark, fine, tooBright }

/// Rough lux ranges per light need (bright daylight indoors is a few
/// thousand lux, direct sun 30,000 and more); `null` means no upper limit.
const lightRanges = {
  Light.low: (min: 250, max: 15000),
  Light.medium: (min: 1000, max: 20000),
  Light.brightIndirect: (min: 2500, max: 25000),
  Light.direct: (min: 10000, max: null),
};

/// Whether [lux] is too dark, fine or too bright for a plant with [need].
LightVerdict lightVerdict(double lux, Light need) {
  final range = lightRanges[need]!;
  if (lux < range.min) return LightVerdict.tooDark;
  if (range.max case final max? when lux > max) return LightVerdict.tooBright;
  return LightVerdict.fine;
}

/// The mean of the valid (not negative) [samples]; `null` if there is none.
double? averageLux(Iterable<double> samples) {
  final valid = samples.where((lux) => lux >= 0).toList();
  if (valid.isEmpty) return null;
  return valid.reduce((a, b) => a + b) / valid.length;
}

/// The phone's ambient light sensor.
abstract interface class LightSensor {
  /// Whether the phone has a light sensor.
  Future<bool> isAvailable();

  /// Illuminance in lux while listened to.
  Stream<double> luxStream();
}
