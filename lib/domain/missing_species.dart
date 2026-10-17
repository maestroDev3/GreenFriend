import 'clock.dart';

/// An identified species that is not in the plant database yet.
class MissingSpecies {
  const MissingSpecies({
    required this.scientificName,
    required this.count,
    required this.lastSeen,
    this.commonName,
  });

  final String scientificName;
  final String? commonName;

  /// How often it was picked after a photo identification.
  final int count;

  /// Calendar day (UTC midnight) it was last picked.
  final DateTime lastSeen;

  @override
  bool operator ==(Object other) =>
      other is MissingSpecies &&
      other.scientificName == scientificName &&
      other.commonName == commonName &&
      other.count == count &&
      other.lastSeen == lastSeen;

  @override
  int get hashCode => Object.hash(scientificName, commonName, count, lastSeen);

  @override
  String toString() => 'MissingSpecies($scientificName, $count)';
}

/// Remembers identified species without a care profile, only on the phone,
/// so they can be added to the database later.
abstract interface class MissingSpeciesRepository {
  /// Emits the list (most recently seen first) now and after every change.
  Stream<List<MissingSpecies>> watch();

  Future<void> record({
    required String scientificName,
    String? commonName,
    required DateTime day,
  });

  Future<void> clear();
}

/// [list] with [scientificName] added or counted once more (case does not
/// matter); the species moves to the front.
List<MissingSpecies> recordMissingSpecies(
  List<MissingSpecies> list, {
  required String scientificName,
  String? commonName,
  required DateTime day,
}) {
  final key = scientificName.trim().toLowerCase();
  MissingSpecies? existing;
  final others = <MissingSpecies>[];
  for (final species in list) {
    if (species.scientificName.toLowerCase() == key) {
      existing = species;
    } else {
      others.add(species);
    }
  }
  return [
    MissingSpecies(
      scientificName: existing?.scientificName ?? scientificName.trim(),
      commonName: commonName ?? existing?.commonName,
      count: (existing?.count ?? 0) + 1,
      lastSeen: dayOf(day),
    ),
    ...others,
  ];
}
