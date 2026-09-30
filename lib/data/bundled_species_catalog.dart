import '../domain/species.dart';
import 'bundled_species.dart';

/// The plant database bundled with the app; works offline.
class BundledSpeciesCatalog implements SpeciesCatalog {
  BundledSpeciesCatalog() : _byId = {for (final s in bundledSpecies) s.id: s};

  final Map<String, Species> _byId;

  @override
  List<Species> get all => bundledSpecies;

  @override
  Species? byId(String id) => _byId[id];

  @override
  List<Species> search(String query, {required String languageCode}) =>
      searchSpecies(all, query, languageCode: languageCode);
}
