import 'clock.dart';
import 'plant.dart';
import 'species.dart';

/// A short care tip, either general or for the plants of one genus.
class CareTip {
  /// Throws [ArgumentError] if [id] is blank or there is no English text.
  CareTip({required this.id, required Map<String, String> texts, this.genus})
    : texts = Map.unmodifiable(texts) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (texts['en']?.trim().isEmpty ?? true) {
      throw ArgumentError.value(texts, 'texts', 'needs an English text');
    }
  }

  final String id;

  /// The tip per language code.
  final Map<String, String> texts;

  /// The genus the tip is about, e.g. `Monstera`; `null` for general tips.
  final String? genus;

  /// The tip in [languageCode], otherwise in English.
  String text(String languageCode) => texts[languageCode] ?? texts['en']!;

  @override
  String toString() => 'CareTip($id)';
}

/// The care tips the app knows.
abstract interface class TipCatalog {
  List<CareTip> get all;
}

/// The tip shown today and, for a genus tip, the user's plant it is about.
typedef TipOfTheDay = ({CareTip tip, Plant? plant});

/// Chooses today's tip for [plants].
///
/// When a tip fits the genus of one of the plants, such tips and general
/// tips take turns day by day, so a single fitting tip does not show up
/// every day. The choice only depends on the calendar day. Without plants
/// there is no tip.
TipOfTheDay? tipOfTheDay(
  List<CareTip> tips, {
  required List<Plant> plants,
  required SpeciesCatalog species,
  required DateTime today,
}) {
  if (plants.isEmpty) return null;
  final fitting = <TipOfTheDay>[];
  for (final tip in tips) {
    final genus = tip.genus?.toLowerCase();
    if (genus == null) continue;
    for (final plant in sortedByName(plants)) {
      if (_genusOf(plant, species) == genus) {
        fitting.add((tip: tip, plant: plant));
        break;
      }
    }
  }
  final general = [
    for (final tip in tips)
      if (tip.genus == null) (tip: tip, plant: null),
  ];
  final dayNumber = dayOf(today).difference(DateTime.utc(2000)).inDays;
  if (fitting.isEmpty || general.isEmpty) {
    final pool = fitting.isEmpty ? general : fitting;
    return pool.isEmpty ? null : pool[dayNumber % pool.length];
  }
  final pool = dayNumber.isEven ? fitting : general;
  return pool[(dayNumber ~/ 2) % pool.length];
}

/// The genus of [plant] in lower case: from its linked care profile, or the
/// first word of the species the user typed.
String? _genusOf(Plant plant, SpeciesCatalog species) {
  final name = switch (plant.speciesId) {
    final id? => species.byId(id)?.scientificName ?? plant.species,
    null => plant.species,
  };
  if (name == null) return null;
  return name.trim().split(RegExp(r'\s+')).first.toLowerCase();
}
