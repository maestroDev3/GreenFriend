/// How much light a species needs at its spot indoors.
enum Light {
  /// Tolerates shade, e.g. a north window or the back of a room.
  low,

  /// Some distance from a window or an east/west window.
  medium,

  /// Close to a bright window without direct midday sun.
  brightIndirect,

  /// Full sun, e.g. a south window.
  direct,
}

/// How humid the air around a species should be.
enum Humidity { low, medium, high }

/// The care profile of a plant species, used to set up a plant's care plan
/// automatically.
///
/// Intervals are typical indoor values for the growing season.
class Species {
  /// Creates a care profile.
  ///
  /// Throws [ArgumentError] if [id] or [scientificName] is empty, there is no
  /// English name, or an interval is out of the plant ranges (1–365 days,
  /// 1–60 months).
  Species({
    required String id,
    required String scientificName,
    required Map<String, List<String>> names,
    required this.wateringIntervalDays,
    required this.fertilizingIntervalDays,
    required this.repottingIntervalMonths,
    required this.light,
    required this.humidity,
  }) : id = _required(id, 'id'),
       scientificName = _required(scientificName, 'scientificName'),
       names = Map.unmodifiable({
         for (final MapEntry(:key, :value) in names.entries)
           key: List<String>.unmodifiable(value),
       }) {
    if (this.names['en']?.isEmpty ?? true) {
      throw ArgumentError.value(names, 'names', 'needs an English name');
    }
    _checkRange(wateringIntervalDays, 'wateringIntervalDays', 365);
    _checkRange(fertilizingIntervalDays, 'fertilizingIntervalDays', 365);
    _checkRange(repottingIntervalMonths, 'repottingIntervalMonths', 60);
  }

  /// Stable key stored with a plant, e.g. `monstera-deliciosa`.
  final String id;
  final String scientificName;

  /// Common names per language code; the first one is the display name.
  final Map<String, List<String>> names;

  final int wateringIntervalDays;
  final int fertilizingIntervalDays;
  final int repottingIntervalMonths;
  final Light light;
  final Humidity humidity;

  /// The name shown to the user: the first name in [languageCode], otherwise
  /// the first English name.
  String displayName(String languageCode) {
    if (names[languageCode] case [final first, ...]) return first;
    return names['en']!.first;
  }

  @override
  bool operator ==(Object other) =>
      other is Species &&
      other.id == id &&
      other.scientificName == scientificName &&
      _sameNames(other.names, names) &&
      other.wateringIntervalDays == wateringIntervalDays &&
      other.fertilizingIntervalDays == fertilizingIntervalDays &&
      other.repottingIntervalMonths == repottingIntervalMonths &&
      other.light == light &&
      other.humidity == humidity;

  @override
  int get hashCode => Object.hash(
    id,
    scientificName,
    wateringIntervalDays,
    fertilizingIntervalDays,
    repottingIntervalMonths,
    light,
    humidity,
  );

  @override
  String toString() => 'Species($id)';

  static String _required(String value, String name) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
    return trimmed;
  }

  static void _checkRange(int value, String name, int max) {
    if (value < 1 || value > max) {
      throw ArgumentError.value(value, name, 'must be 1-$max');
    }
  }

  static bool _sameNames(
    Map<String, List<String>> a,
    Map<String, List<String>> b,
  ) {
    if (a.length != b.length) return false;
    for (final MapEntry(:key, :value) in a.entries) {
      final other = b[key];
      if (other == null || other.length != value.length) return false;
      for (var i = 0; i < value.length; i++) {
        if (other[i] != value[i]) return false;
      }
    }
    return true;
  }
}

/// The plant database: care profiles of known species.
abstract interface class SpeciesCatalog {
  List<Species> get all;

  /// The species with [id], or `null` if it is unknown.
  Species? byId(String id);

  /// Species matching [query], see [searchSpecies].
  List<Species> search(String query, {required String languageCode});
}

/// Finds species whose names contain [query].
///
/// Searched are the common names in [languageCode], the English names and the
/// scientific name, ignoring case and accents. Species with a name starting
/// with the query come first; within each group they are sorted by display
/// name. A blank query finds nothing.
List<Species> searchSpecies(
  Iterable<Species> species,
  String query, {
  required String languageCode,
}) {
  final needle = _fold(query.trim());
  if (needle.isEmpty) return const [];
  final matches = <(Species, bool)>[];
  for (final candidate in species) {
    final names = [
      ...?candidate.names[languageCode],
      if (languageCode != 'en') ...?candidate.names['en'],
      candidate.scientificName,
    ].map(_fold);
    if (names.any((name) => name.startsWith(needle))) {
      matches.add((candidate, true));
    } else if (names.any((name) => name.contains(needle))) {
      matches.add((candidate, false));
    }
  }
  matches.sort((a, b) {
    if (a.$2 != b.$2) return a.$2 ? -1 : 1;
    return _fold(a.$1.displayName(languageCode))
        .compareTo(_fold(b.$1.displayName(languageCode)));
  });
  return [for (final (match, _) in matches) match];
}

const _accents = {
  'ä': 'a',
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ö': 'o',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ü': 'u',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ç': 'c',
  'ñ': 'n',
  'ß': 'ss',
};

/// Lower-cases [text] and replaces accented letters by their base letter.
String _fold(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}
