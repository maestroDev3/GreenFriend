import 'clock.dart';
import 'plant.dart';
import 'species.dart';
import 'weather.dart';

/// The lowest temperature in °C assumed for a plant whose own value and
/// species value are unknown.
const defaultMinTemperature = 5;

/// The lowest temperature in °C [plant] tolerates: its own value, else the
/// value of its [species], else [defaultMinTemperature].
int toleratedMinimum(Plant plant, Species? species) =>
    plant.minTemperature ?? species?.minTemperature ?? defaultMinTemperature;

/// A night forecast colder than some outdoor plants tolerate.
class FrostWarning {
  FrostWarning({
    required DateTime day,
    required this.minTemperature,
    required List<String> plantNames,
  }) : day = dayOf(day),
       plantNames = List.unmodifiable(plantNames);

  /// Calendar day (UTC midnight) whose minimum temperature is forecast; the
  /// cold comes in the night before it.
  final DateTime day;
  final double minTemperature;

  /// The plants at risk, sorted by name.
  final List<String> plantNames;

  @override
  bool operator ==(Object other) =>
      other is FrostWarning &&
      other.day == day &&
      other.minTemperature == minTemperature &&
      other.plantNames.length == plantNames.length &&
      Iterable.generate(plantNames.length)
          .every((i) => other.plantNames[i] == plantNames[i]);

  @override
  int get hashCode =>
      Object.hash(day, minTemperature, Object.hashAll(plantNames));

  @override
  String toString() => 'FrostWarning($day, $minTemperature °C, $plantNames)';
}

/// Warnings for the next two nights (minimums of tomorrow and the day after):
/// a night counts when its forecast minimum is below the [tolerance] of an
/// outdoor plant. Indoor plants are never named.
List<FrostWarning> frostWarnings(
  Iterable<Plant> plants, {
  required List<DailyWeather> weather,
  required int Function(Plant plant) tolerance,
  required DateTime today,
}) {
  final now = dayOf(today);
  final nights = {
    now.add(const Duration(days: 1)),
    now.add(const Duration(days: 2)),
  };
  final outdoor = sortedByName(plants.where((plant) => plant.outdoor));
  return [
    for (final entry in weather)
      if (nights.contains(entry.day))
        if (entry.minTemperature case final min?)
          if ([
                for (final plant in outdoor)
                  if (min < tolerance(plant)) plant.name,
              ]
              case final names when names.isNotEmpty)
            FrostWarning(
              day: entry.day,
              minTemperature: min,
              plantNames: names,
            ),
  ];
}
