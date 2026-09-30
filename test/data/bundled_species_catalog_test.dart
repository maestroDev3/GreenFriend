import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/bundled_species_catalog.dart';

void main() {
  final catalog = BundledSpeciesCatalog();

  group('BundledSpeciesCatalog', () {
    test('contains at least 60 species', () {
      expect(catalog.all.length, greaterThanOrEqualTo(60));
    });

    test('has unique ids and scientific names', () {
      final ids = catalog.all.map((species) => species.id);
      final names = catalog.all.map((species) => species.scientificName);

      expect(ids.toSet(), hasLength(ids.length));
      expect(names.toSet(), hasLength(names.length));
    });

    test('names every species in English and German', () {
      for (final species in catalog.all) {
        expect(species.names['en'], isNotEmpty, reason: species.id);
        expect(species.names['de'], isNotEmpty, reason: species.id);
        for (final name in [...?species.names['en'], ...?species.names['de']]) {
          expect(name.trim(), name, reason: species.id);
          expect(name, isNotEmpty, reason: species.id);
        }
      }
    });

    test('uses ids made of lower-case words joined by hyphens', () {
      for (final species in catalog.all) {
        expect(species.id, matches(RegExp(r'^[a-z]+(-[a-z]+)*$')));
      }
    });

    test('finds every species by its id', () {
      for (final species in catalog.all) {
        expect(catalog.byId(species.id), same(species));
      }
      expect(catalog.byId('unknown'), isNull);
    });

    test('finds common species by name', () {
      expect(
        catalog.search('monstera', languageCode: 'de').first.id,
        'monstera-deliciosa',
      );
      expect(
        catalog.search('Bogenhanf', languageCode: 'de').first.id,
        'dracaena-trifasciata',
      );
      expect(
        catalog.search('snake plant', languageCode: 'en').first.id,
        'dracaena-trifasciata',
      );
      expect(
        catalog.search('Grünlilie', languageCode: 'de').single.id,
        'chlorophytum-comosum',
      );
    });

    test('shows German names in German', () {
      expect(catalog.byId('ficus-elastica')?.displayName('de'), 'Gummibaum');
    });
  });
}
