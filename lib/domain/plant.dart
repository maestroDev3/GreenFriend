import 'clock.dart';

/// A plant the user takes care of.
class Plant {
  /// Creates a plant; texts are trimmed, empty optional texts become `null`,
  /// last-done dates are normalized to their calendar day.
  ///
  /// Throws [ArgumentError] if [name] is empty or an interval is out of range
  /// (watering and fertilizing 1–365 days, repotting 1–60 months).
  Plant({
    required this.id,
    required String name,
    String? species,
    String? speciesId,
    String? location,
    int? wateringIntervalDays,
    DateTime? lastWateredOn,
    int? fertilizingIntervalDays,
    DateTime? lastFertilizedOn,
    int? repottingIntervalMonths,
    DateTime? lastRepottedOn,
    int? pruningIntervalMonths,
    DateTime? lastPrunedOn,
    this.winterRest = true,
    this.outdoor = false,
    int? minTemperature,
  }) : name = _requireName(name),
       minTemperature = checkMinTemperature(minTemperature, 'minTemperature'),
       species = _optional(species),
       speciesId = _optional(speciesId),
       location = _optional(location),
       wateringIntervalDays = _checkRange(
         wateringIntervalDays,
         'wateringIntervalDays',
         365,
       ),
       lastWateredOn = _day(lastWateredOn),
       fertilizingIntervalDays = _checkRange(
         fertilizingIntervalDays,
         'fertilizingIntervalDays',
         365,
       ),
       lastFertilizedOn = _day(lastFertilizedOn),
       repottingIntervalMonths = _checkRange(
         repottingIntervalMonths,
         'repottingIntervalMonths',
         60,
       ),
       lastRepottedOn = _day(lastRepottedOn),
       pruningIntervalMonths = _checkRange(
         pruningIntervalMonths,
         'pruningIntervalMonths',
         60,
       ),
       lastPrunedOn = _day(lastPrunedOn);

  final String id;
  final String name;
  final String? species;

  /// Id of the care profile in the plant database, if the species was picked
  /// from it.
  final String? speciesId;
  final String? location;

  /// Water every this many days; `null` means no watering schedule.
  final int? wateringIntervalDays;

  /// Calendar day (UTC midnight) of the last watering, if known.
  final DateTime? lastWateredOn;

  /// Fertilize every this many days; `null` means no schedule.
  final int? fertilizingIntervalDays;

  /// Calendar day (UTC midnight) of the last fertilizing, if known.
  final DateTime? lastFertilizedOn;

  /// Repot every this many months; `null` means no schedule.
  final int? repottingIntervalMonths;

  /// Calendar day (UTC midnight) of the last repotting, if known.
  final DateTime? lastRepottedOn;

  /// Prune every this many months; `null` means no schedule.
  final int? pruningIntervalMonths;

  /// Calendar day (UTC midnight) of the last pruning, if known.
  final DateTime? lastPrunedOn;

  /// Whether watering and fertilizing slow down from November to February
  /// (see `season.dart`).
  final bool winterRest;

  /// Whether the plant lives outdoors (balcony, garden), so the weather
  /// counts (see `weather.dart`).
  final bool outdoor;

  /// The lowest temperature in °C this plant tolerates, if set for it; see
  /// `toleratedMinimum`.
  final int? minTemperature;

  /// Returns a copy with the given values; `null` keeps the current value.
  Plant copyWith({
    String? name,
    String? species,
    String? speciesId,
    String? location,
    int? wateringIntervalDays,
    DateTime? lastWateredOn,
    int? fertilizingIntervalDays,
    DateTime? lastFertilizedOn,
    int? repottingIntervalMonths,
    DateTime? lastRepottedOn,
    int? pruningIntervalMonths,
    DateTime? lastPrunedOn,
    bool? winterRest,
    bool? outdoor,
    int? minTemperature,
  }) {
    return Plant(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      speciesId: speciesId ?? this.speciesId,
      location: location ?? this.location,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      lastWateredOn: lastWateredOn ?? this.lastWateredOn,
      fertilizingIntervalDays:
          fertilizingIntervalDays ?? this.fertilizingIntervalDays,
      lastFertilizedOn: lastFertilizedOn ?? this.lastFertilizedOn,
      repottingIntervalMonths:
          repottingIntervalMonths ?? this.repottingIntervalMonths,
      lastRepottedOn: lastRepottedOn ?? this.lastRepottedOn,
      pruningIntervalMonths:
          pruningIntervalMonths ?? this.pruningIntervalMonths,
      lastPrunedOn: lastPrunedOn ?? this.lastPrunedOn,
      winterRest: winterRest ?? this.winterRest,
      outdoor: outdoor ?? this.outdoor,
      minTemperature: minTemperature ?? this.minTemperature,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Plant &&
      other.id == id &&
      other.name == name &&
      other.species == species &&
      other.speciesId == speciesId &&
      other.location == location &&
      other.wateringIntervalDays == wateringIntervalDays &&
      other.lastWateredOn == lastWateredOn &&
      other.fertilizingIntervalDays == fertilizingIntervalDays &&
      other.lastFertilizedOn == lastFertilizedOn &&
      other.repottingIntervalMonths == repottingIntervalMonths &&
      other.lastRepottedOn == lastRepottedOn &&
      other.pruningIntervalMonths == pruningIntervalMonths &&
      other.lastPrunedOn == lastPrunedOn &&
      other.winterRest == winterRest &&
      other.outdoor == outdoor &&
      other.minTemperature == minTemperature;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    species,
    speciesId,
    location,
    wateringIntervalDays,
    lastWateredOn,
    fertilizingIntervalDays,
    lastFertilizedOn,
    repottingIntervalMonths,
    lastRepottedOn,
    pruningIntervalMonths,
    lastPrunedOn,
    winterRest,
    outdoor,
    minTemperature,
  );

  @override
  String toString() => 'Plant($id, $name)';

  static String _requireName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    return trimmed;
  }

  static int? _checkRange(int? value, String name, int max) {
    if (value != null && (value < 1 || value > max)) {
      throw ArgumentError.value(value, name, 'must be 1-$max');
    }
    return value;
  }

  static DateTime? _day(DateTime? value) => value == null ? null : dayOf(value);

  static String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// Lowest temperatures in °C a plant or species can have.
const minTemperatureRange = (min: -30, max: 20);

/// Returns [value]; throws [ArgumentError] if it is outside
/// [minTemperatureRange].
int? checkMinTemperature(int? value, String name) {
  if (value != null &&
      (value < minTemperatureRange.min || value > minTemperatureRange.max)) {
    throw ArgumentError.value(
      value,
      name,
      'must be ${minTemperatureRange.min} to ${minTemperatureRange.max}',
    );
  }
  return value;
}

/// Returns [plants] sorted by name, ignoring case, so lists are predictable.
List<Plant> sortedByName(Iterable<Plant> plants) {
  return [...plants]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
