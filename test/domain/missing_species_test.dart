import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/missing_species.dart';

void main() {
  group('recordMissingSpecies', () {
    test('adds a new species with count 1', () {
      final list = recordMissingSpecies(
        const [],
        scientificName: 'Aloe aristata',
        commonName: 'Lace aloe',
        day: DateTime(2026, 10, 14, 9),
      );

      expect(list, [
        MissingSpecies(
          scientificName: 'Aloe aristata',
          commonName: 'Lace aloe',
          count: 1,
          lastSeen: DateTime.utc(2026, 10, 14),
        ),
      ]);
    });

    test('counts the same species again and puts it first', () {
      var list = recordMissingSpecies(
        const [],
        scientificName: 'Aloe aristata',
        day: DateTime(2026, 10, 10),
      );
      list = recordMissingSpecies(
        list,
        scientificName: 'Ficus elastica Tineke',
        day: DateTime(2026, 10, 11),
      );
      list = recordMissingSpecies(
        list,
        scientificName: 'aloe ARISTATA',
        commonName: 'Lace aloe',
        day: DateTime(2026, 10, 12),
      );

      expect(list.map((species) => species.scientificName), [
        'Aloe aristata',
        'Ficus elastica Tineke',
      ]);
      expect(list.first.count, 2);
      expect(list.first.lastSeen, DateTime.utc(2026, 10, 12));
      expect(list.first.commonName, 'Lace aloe');
    });
  });
}
