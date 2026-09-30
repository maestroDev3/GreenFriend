import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/species.dart';

import '../support/fake_species_catalog.dart';

Species species({
  String id = 'monstera-deliciosa',
  String scientificName = 'Monstera deliciosa',
  Map<String, List<String>> names = const {
    'en': ['Swiss cheese plant', 'Monstera'],
    'de': ['Fensterblatt', 'Monstera'],
  },
  int wateringIntervalDays = 7,
  int fertilizingIntervalDays = 14,
  int repottingIntervalMonths = 24,
}) => Species(
  id: id,
  scientificName: scientificName,
  names: names,
  wateringIntervalDays: wateringIntervalDays,
  fertilizingIntervalDays: fertilizingIntervalDays,
  repottingIntervalMonths: repottingIntervalMonths,
  light: Light.brightIndirect,
  humidity: Humidity.medium,
);

void main() {
  group('Species', () {
    test('compares by value', () {
      expect(species(), species());
      expect(species(), isNot(species(wateringIntervalDays: 8)));
    });

    test('keeps its names unmodifiable', () {
      expect(() => species().names['en']!.add('x'), throwsUnsupportedError);
      expect(() => species().names['fr'] = ['x'], throwsUnsupportedError);
    });

    test('rejects intervals outside the plant ranges', () {
      expect(() => species(wateringIntervalDays: 0), throwsArgumentError);
      expect(() => species(wateringIntervalDays: 366), throwsArgumentError);
      expect(() => species(fertilizingIntervalDays: 0), throwsArgumentError);
      expect(() => species(fertilizingIntervalDays: 366), throwsArgumentError);
      expect(() => species(repottingIntervalMonths: 0), throwsArgumentError);
      expect(() => species(repottingIntervalMonths: 61), throwsArgumentError);
    });

    test('rejects an empty id or scientific name', () {
      expect(() => species(id: ' '), throwsArgumentError);
      expect(() => species(scientificName: ''), throwsArgumentError);
    });

    test('requires an English name', () {
      expect(
        () => species(
          names: const {
            'de': ['Fensterblatt'],
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => species(names: const {'en': <String>[]}),
        throwsArgumentError,
      );
    });

    test('shows the first name in the language, falling back to English', () {
      expect(species().displayName('de'), 'Fensterblatt');
      expect(species().displayName('en'), 'Swiss cheese plant');
      expect(species().displayName('fr'), 'Swiss cheese plant');
    });
  });

  group('searchSpecies', () {
    final monstera = species();
    final snake = species(
      id: 'dracaena-trifasciata',
      scientificName: 'Dracaena trifasciata',
      names: const {
        'en': ['Snake plant', "Mother-in-law's tongue"],
        'de': ['Bogenhanf', 'Schwiegermutterzunge'],
      },
    );
    final peace = species(
      id: 'spathiphyllum-wallisii',
      scientificName: 'Spathiphyllum wallisii',
      names: const {
        'en': ['Peace lily'],
        'de': ['Einblatt', 'Friedenslilie'],
      },
    );
    final grape = species(
      id: 'cissus-rhombifolia',
      scientificName: 'Cissus rhombifolia',
      names: const {
        'en': ['Grape ivy'],
        'de': ['Königswein', 'Zimmerrebe'],
      },
    );
    final all = [monstera, snake, peace, grape];

    test('matches names in the language case-insensitively', () {
      expect(searchSpecies(all, 'bogen', languageCode: 'de'), [snake]);
      expect(searchSpecies(all, 'FENSTER', languageCode: 'de'), [monstera]);
    });

    test('also matches English and scientific names', () {
      expect(searchSpecies(all, 'snake', languageCode: 'de'), [snake]);
      expect(searchSpecies(all, 'dracaena', languageCode: 'en'), [snake]);
    });

    test('does not match names of other languages than en and the given one',
        () {
      expect(searchSpecies(all, 'bogenhanf', languageCode: 'fr'), isEmpty);
    });

    test('ignores accents and umlauts', () {
      expect(searchSpecies(all, 'konigswein', languageCode: 'de'), [grape]);
      expect(searchSpecies(all, 'KÖNIG', languageCode: 'de'), [grape]);
    });

    test('puts results starting with the query before others', () {
      final starts = species(
        id: 'a',
        scientificName: 'Aaa',
        names: const {
          'en': ['Lipstick plant'],
        },
      );
      final contains = species(
        id: 'b',
        scientificName: 'Bbb',
        names: const {
          'en': ['Aloe lila'],
        },
      );

      expect(searchSpecies([contains, starts], 'li', languageCode: 'en'), [
        starts,
        contains,
      ]);
    });

    test('sorts ties by display name', () {
      // Only "Einblatt" starts with "e"; the rest merely contain it.
      expect(searchSpecies(all, 'e', languageCode: 'de'), [
        peace,
        snake, // Bogenhanf
        monstera, // Fensterblatt
        grape, // Königswein
      ]);
    });

    test('returns nothing for an empty or blank query', () {
      expect(searchSpecies(all, '', languageCode: 'de'), isEmpty);
      expect(searchSpecies(all, '   ', languageCode: 'de'), isEmpty);
    });

    test('lists each species once even if several names match', () {
      expect(searchSpecies(all, 'monstera', languageCode: 'de'), [monstera]);
    });
  });

  group('FakeSpeciesCatalog', () {
    final catalog = FakeSpeciesCatalog([species()]);

    test('finds species by id', () {
      expect(catalog.byId('monstera-deliciosa'), species());
      expect(catalog.byId('unknown'), isNull);
    });

    test('searches with searchSpecies', () {
      expect(catalog.search('fenster', languageCode: 'de'), [species()]);
    });
  });
}
