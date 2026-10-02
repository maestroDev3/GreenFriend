import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/species.dart';
import 'package:green_friend/domain/tips.dart';

import '../support/fake_species_catalog.dart';

final monsteraSpecies = Species(
  id: 'monstera-deliciosa',
  scientificName: 'Monstera deliciosa',
  names: const {
    'en': ['Swiss cheese plant'],
  },
  wateringIntervalDays: 7,
  fertilizingIntervalDays: 14,
  repottingIntervalMonths: 24,
  light: Light.brightIndirect,
  humidity: Humidity.medium,
);
final catalog = FakeSpeciesCatalog([monsteraSpecies]);

CareTip tip(String id, {String? genus}) =>
    CareTip(id: id, texts: {'en': 'Tip $id', 'de': 'Tipp $id'}, genus: genus);

final tips = [
  tip('general-1'),
  tip('general-2'),
  tip('general-3'),
  tip('monstera', genus: 'Monstera'),
  tip('ficus', genus: 'Ficus'),
];

final monty = Plant(id: 'm', name: 'Monty', speciesId: 'monstera-deliciosa');
final day = DateTime.utc(2026, 10, 2);
final nextDay = DateTime.utc(2026, 10, 3);

void main() {
  group('CareTip', () {
    test('needs an English text', () {
      expect(
        () => CareTip(id: 'x', texts: const {'de': 'Nur Deutsch'}),
        throwsArgumentError,
      );
    });

    test('falls back to English for other languages', () {
      final general = tip('general-1');

      expect(general.text('de'), 'Tipp general-1');
      expect(general.text('fr'), 'Tip general-1');
    });
  });

  group('tipOfTheDay', () {
    test('alternates between a tip for my plant and a general tip', () {
      final picks = [
        tipOfTheDay(tips, plants: [monty], species: catalog, today: day),
        tipOfTheDay(tips, plants: [monty], species: catalog, today: nextDay),
      ];

      final forPlant = picks.where((pick) => pick?.plant != null).single;
      expect(forPlant?.tip.id, 'monstera');
      expect(forPlant?.plant, monty);
      final general = picks.where((pick) => pick?.plant == null).single;
      expect(general?.tip.genus, isNull);
    });

    test('chooses a general tip without matching plants', () {
      final aloe = Plant(id: 'a', name: 'Aloe');

      for (final today in [day, nextDay]) {
        final pick = tipOfTheDay(
          tips,
          plants: [aloe],
          species: catalog,
          today: today,
        );
        expect(pick?.tip.genus, isNull);
        expect(pick?.plant, isNull);
      }
    });

    test('also matches the genus in a species typed by the user', () {
      final rubber = Plant(id: 'r', name: 'Rubber', species: 'Ficus elastica');

      final picks = [
        for (final today in [day, nextDay])
          tipOfTheDay(tips, plants: [rubber], species: catalog, today: today),
      ];

      expect(picks.map((pick) => pick?.tip.id), contains('ficus'));
    });

    test('gives no tip without plants', () {
      expect(
        tipOfTheDay(tips, plants: const [], species: catalog, today: day),
        isNull,
      );
    });

    test('keeps the same tip during a day', () {
      final morning = tipOfTheDay(
        tips,
        plants: [monty],
        species: catalog,
        today: DateTime(2026, 10, 2, 7),
      );
      final evening = tipOfTheDay(
        tips,
        plants: [monty],
        species: catalog,
        today: DateTime(2026, 10, 2, 22),
      );

      expect(evening?.tip, morning?.tip);
      expect(evening?.plant, morning?.plant);
    });

    test('changes the general tip from one day to the next', () {
      final aloe = Plant(id: 'a', name: 'Aloe');
      final first = tipOfTheDay(
        tips,
        plants: [aloe],
        species: catalog,
        today: day,
      );
      final second = tipOfTheDay(
        tips,
        plants: [aloe],
        species: catalog,
        today: nextDay,
      );

      expect(second?.tip, isNot(first?.tip));
    });
  });
}
