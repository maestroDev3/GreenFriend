import 'package:green_friend/domain/species.dart';

/// In-memory [SpeciesCatalog] for tests.
class FakeSpeciesCatalog implements SpeciesCatalog {
  FakeSpeciesCatalog(this.all);

  @override
  final List<Species> all;

  @override
  Species? byId(String id) {
    for (final species in all) {
      if (species.id == id) return species;
    }
    return null;
  }

  @override
  List<Species> search(String query, {required String languageCode}) =>
      searchSpecies(all, query, languageCode: languageCode);
}
