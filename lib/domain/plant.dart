import 'clock.dart';

/// A plant the user takes care of.
class Plant {
  /// Creates a plant; texts are trimmed, empty optional texts become `null`.
  ///
  /// Throws [ArgumentError] if [name] is empty or the watering interval is
  /// outside 1 to 365 days.
  Plant({
    required this.id,
    required String name,
    String? species,
    String? location,
    int? wateringIntervalDays,
    DateTime? lastWateredOn,
  }) : name = _requireName(name),
       species = _optional(species),
       location = _optional(location),
       wateringIntervalDays = _checkInterval(wateringIntervalDays),
       lastWateredOn = lastWateredOn == null ? null : dayOf(lastWateredOn);

  final String id;
  final String name;
  final String? species;
  final String? location;

  /// Water every this many days; `null` means no watering schedule.
  final int? wateringIntervalDays;

  /// Calendar day (UTC midnight) of the last watering, if known.
  final DateTime? lastWateredOn;

  /// Returns a copy with the given values; `null` keeps the current value.
  Plant copyWith({
    String? name,
    String? species,
    String? location,
    int? wateringIntervalDays,
    DateTime? lastWateredOn,
  }) {
    return Plant(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      location: location ?? this.location,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      lastWateredOn: lastWateredOn ?? this.lastWateredOn,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Plant &&
      other.id == id &&
      other.name == name &&
      other.species == species &&
      other.location == location &&
      other.wateringIntervalDays == wateringIntervalDays &&
      other.lastWateredOn == lastWateredOn;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    species,
    location,
    wateringIntervalDays,
    lastWateredOn,
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

  static int? _checkInterval(int? days) {
    if (days != null && (days < 1 || days > 365)) {
      throw ArgumentError.value(days, 'wateringIntervalDays', 'must be 1-365');
    }
    return days;
  }

  static String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// Returns [plants] sorted by name, ignoring case, so lists are predictable.
List<Plant> sortedByName(Iterable<Plant> plants) {
  return [...plants]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
