import 'plant.dart';
import 'species.dart';

/// The lowest temperature in °C assumed for a plant whose own value and
/// species value are unknown.
const defaultMinTemperature = 5;

/// The lowest temperature in °C [plant] tolerates: its own value, else the
/// value of its [species], else [defaultMinTemperature].
int toleratedMinimum(Plant plant, Species? species) =>
    plant.minTemperature ?? species?.minTemperature ?? defaultMinTemperature;
