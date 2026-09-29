/// A plant the user takes care of.
class Plant {
  /// Creates a plant; texts are trimmed, empty optional texts become `null`.
  ///
  /// Throws [ArgumentError] if [name] is empty.
  Plant({
    required this.id,
    required String name,
    String? species,
    String? location,
  }) : name = _requireName(name),
       species = _optional(species),
       location = _optional(location);

  final String id;
  final String name;
  final String? species;
  final String? location;

  /// Returns a copy with the given values; `null` keeps the current value.
  Plant copyWith({String? name, String? species, String? location}) {
    return Plant(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      location: location ?? this.location,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Plant &&
      other.id == id &&
      other.name == name &&
      other.species == species &&
      other.location == location;

  @override
  int get hashCode => Object.hash(id, name, species, location);

  @override
  String toString() => 'Plant($id, $name)';

  static String _requireName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    return trimmed;
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
