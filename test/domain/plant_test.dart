import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';

void main() {
  group('Plant', () {
    test('trims name, species and location', () {
      final plant = Plant(
        id: 'p1',
        name: '  Monstera ',
        species: ' Monstera deliciosa ',
        location: ' Living room ',
      );

      expect(plant.name, 'Monstera');
      expect(plant.species, 'Monstera deliciosa');
      expect(plant.location, 'Living room');
    });

    test('turns empty species and location into null', () {
      final plant = Plant(id: 'p1', name: 'Pothos', species: ' ', location: '');

      expect(plant.species, isNull);
      expect(plant.location, isNull);
    });

    test('keeps an optional species id, trimmed, empty becomes null', () {
      expect(Plant(id: 'p1', name: 'M').speciesId, isNull);
      expect(
        Plant(id: 'p1', name: 'M', speciesId: ' monstera-deliciosa ').speciesId,
        'monstera-deliciosa',
      );
      expect(Plant(id: 'p1', name: 'M', speciesId: ' ').speciesId, isNull);
    });

    test('compares the species id', () {
      expect(
        Plant(id: 'p1', name: 'M', speciesId: 'a'),
        isNot(Plant(id: 'p1', name: 'M', speciesId: 'b')),
      );
      expect(
        Plant(id: 'p1', name: 'M', speciesId: 'a').copyWith(name: 'N'),
        Plant(id: 'p1', name: 'N', speciesId: 'a'),
      );
    });

    test('keeps a pruning schedule with the day normalized', () {
      final plant = Plant(
        id: 'p1',
        name: 'Olive',
        pruningIntervalMonths: 12,
        lastPrunedOn: DateTime(2026, 3, 14, 17, 30),
      );

      expect(plant.pruningIntervalMonths, 12);
      expect(plant.lastPrunedOn, DateTime.utc(2026, 3, 14));
      expect(
        plant.copyWith(name: 'Olea'),
        Plant(
          id: 'p1',
          name: 'Olea',
          pruningIntervalMonths: 12,
          lastPrunedOn: DateTime.utc(2026, 3, 14),
        ),
      );
      expect(plant, isNot(plant.copyWith(pruningIntervalMonths: 6)));
      expect(
        plant,
        isNot(plant.copyWith(lastPrunedOn: DateTime.utc(2026, 3, 15))),
      );
    });

    test('rejects pruning intervals outside 1 to 60 months', () {
      expect(
        () => Plant(id: 'p1', name: 'O', pruningIntervalMonths: 0),
        throwsArgumentError,
      );
      expect(
        () => Plant(id: 'p1', name: 'O', pruningIntervalMonths: 61),
        throwsArgumentError,
      );
      expect(
        Plant(id: 'p1', name: 'O', pruningIntervalMonths: 60),
        isA<Plant>(),
      );
    });

    test('rejects an empty or blank name', () {
      expect(() => Plant(id: 'p1', name: ''), throwsArgumentError);
      expect(() => Plant(id: 'p1', name: '   '), throwsArgumentError);
    });

    test('compares by value', () {
      expect(
        Plant(id: 'p1', name: 'Pothos', location: 'Kitchen'),
        Plant(id: 'p1', name: 'Pothos', location: 'Kitchen'),
      );
      expect(
        Plant(id: 'p1', name: 'Pothos'),
        isNot(Plant(id: 'p2', name: 'Pothos')),
      );
    });

    test('copyWith returns a changed copy and keeps the original', () {
      final original = Plant(id: 'p1', name: 'Pothos', location: 'Kitchen');

      final renamed = original.copyWith(name: 'Golden pothos');

      expect(renamed.name, 'Golden pothos');
      expect(renamed.id, 'p1');
      expect(renamed.location, 'Kitchen');
      expect(original.name, 'Pothos');
    });
  });

  group('sortedByName', () {
    test('sorts plants by name ignoring case', () {
      final plants = [
        Plant(id: '1', name: 'zamioculcas'),
        Plant(id: '2', name: 'Aloe'),
        Plant(id: '3', name: 'monstera'),
      ];

      expect(sortedByName(plants).map((plant) => plant.name), [
        'Aloe',
        'monstera',
        'zamioculcas',
      ]);
    });
  });
}
