import 'species.dart';

/// A species the identification service thinks the photo shows.
class IdentificationCandidate {
  /// Throws [ArgumentError] if [scientificName] is blank or [probability] is
  /// outside 0 to 1.
  IdentificationCandidate({
    required String scientificName,
    required List<String> commonNames,
    required this.probability,
  }) : scientificName = _required(scientificName),
       commonNames = List.unmodifiable(
         commonNames.map((name) => name.trim()).where((n) => n.isNotEmpty),
       ) {
    if (probability < 0 || probability > 1) {
      throw ArgumentError.value(probability, 'probability', 'must be 0-1');
    }
  }

  final String scientificName;

  /// Common names in the requested language; may be empty.
  final List<String> commonNames;

  /// How sure the service is, from 0 to 1.
  final double probability;

  /// The first word of the scientific name, e.g. `Monstera`.
  String get genus => scientificName.split(RegExp(r'\s+')).first;

  /// The genus and species epithet without cultivar or variety parts, in
  /// lower case, e.g. `monstera deliciosa`.
  String get speciesKey => _speciesKey(scientificName);

  @override
  bool operator ==(Object other) =>
      other is IdentificationCandidate &&
      other.scientificName == scientificName &&
      other.probability == probability &&
      _sameList(other.commonNames, commonNames);

  @override
  int get hashCode => Object.hash(scientificName, probability);

  @override
  String toString() => 'IdentificationCandidate($scientificName, $probability)';

  static String _required(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'scientificName', 'must not be empty');
    }
    return trimmed;
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Why a photo could not be identified.
sealed class IdentificationFailure implements Exception {
  const IdentificationFailure();
}

/// No API key is stored in the settings.
final class MissingApiKey extends IdentificationFailure {
  const MissingApiKey();
}

/// The service rejected the API key.
final class InvalidApiKey extends IdentificationFailure {
  const InvalidApiKey();
}

/// The account has no identification credits left.
final class NoCredits extends IdentificationFailure {
  const NoCredits();
}

/// The photo does not show a plant.
final class NotAPlant extends IdentificationFailure {
  const NotAPlant();
}

/// The service could not be reached or answered with an error.
final class ServiceUnavailable extends IdentificationFailure {
  const ServiceUnavailable([this.detail]);

  /// Technical detail for debugging; not shown to the user.
  final String? detail;
}

/// Identifies the species on a photo with an online service.
abstract interface class PlantIdentifier {
  /// Returns the candidates for [photo] (JPEG bytes) with common names in
  /// [languageCode].
  ///
  /// Throws an [IdentificationFailure] if the photo cannot be identified.
  Future<List<IdentificationCandidate>> identify(
    List<int> photo, {
    required String apiKey,
    required String languageCode,
  });
}

/// The [count] most probable candidates, most probable first.
List<IdentificationCandidate> topCandidates(
  Iterable<IdentificationCandidate> candidates, {
  int count = 3,
}) {
  final sorted = [...candidates]
    ..sort((a, b) => b.probability.compareTo(a.probability));
  return sorted.take(count).toList();
}

/// Below this probability a candidate is shown as uncertain.
const uncertainBelow = 0.3;

/// Whether a candidate with [probability] should be marked as uncertain.
bool isUncertain(double probability) => probability < uncertainBelow;

/// How an identified species relates to the plant database.
sealed class SpeciesMatch {
  const SpeciesMatch();
}

/// The species itself is in the plant database.
final class ExactSpecies extends SpeciesMatch {
  const ExactSpecies(this.species);

  final Species species;

  @override
  bool operator ==(Object other) =>
      other is ExactSpecies && other.species == species;

  @override
  int get hashCode => Object.hash(ExactSpecies, species);

  @override
  String toString() => 'ExactSpecies(${species.id})';
}

/// Only a species of the same genus is known; its care profile serves as a
/// template.
final class SameGenus extends SpeciesMatch {
  const SameGenus(this.template);

  final Species template;

  @override
  bool operator ==(Object other) =>
      other is SameGenus && other.template == template;

  @override
  int get hashCode => Object.hash(SameGenus, template);

  @override
  String toString() => 'SameGenus(${template.id})';
}

/// Neither the species nor its genus is in the plant database.
final class NoSpecies extends SpeciesMatch {
  const NoSpecies();

  @override
  bool operator ==(Object other) => other is NoSpecies;

  @override
  int get hashCode => (NoSpecies).hashCode;
}

/// Finds the care profile for [candidate]: the same species (ignoring case
/// and cultivar or variety parts), otherwise the first species of the same
/// genus by scientific name.
SpeciesMatch matchSpecies(
  IdentificationCandidate candidate,
  SpeciesCatalog catalog,
) {
  final key = candidate.speciesKey;
  final genus = candidate.genus.toLowerCase();
  Species? template;
  for (final species in catalog.all) {
    final speciesKey = _speciesKey(species.scientificName);
    if (speciesKey == key) return ExactSpecies(species);
    final sameGenus = speciesKey.split(' ').first == genus;
    if (sameGenus && (template == null || _sortsBefore(species, template))) {
      template = species;
    }
  }
  if (template case final species?) return SameGenus(species);
  return const NoSpecies();
}

String _speciesKey(String scientificName) =>
    scientificName.toLowerCase().split(RegExp(r'\s+')).take(2).join(' ');

bool _sortsBefore(Species a, Species b) =>
    a.scientificName.compareTo(b.scientificName) < 0;
