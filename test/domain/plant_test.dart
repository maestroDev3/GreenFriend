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
