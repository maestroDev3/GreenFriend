import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/identification.dart';
import 'package:green_friend/domain/species.dart';

import '../support/fake_species_catalog.dart';

IdentificationCandidate candidate(
  String scientificName, {
  double probability = 0.9,
  List<String> commonNames = const [],
}) => IdentificationCandidate(
  scientificName: scientificName,
  commonNames: commonNames,
  probability: probability,
);

Species species(String id, String scientificName) => Species(
  id: id,
  scientificName: scientificName,
  names: {
    'en': [id],
  },
  wateringIntervalDays: 7,
  fertilizingIntervalDays: 14,
  repottingIntervalMonths: 24,
  light: Light.brightIndirect,
  humidity: Humidity.medium,
);

void main() {
  group('topCandidates', () {
    test('sorts candidates by probability and keeps the best three', () {
      final result = topCandidates([
        candidate('A a', probability: 0.1),
        candidate('B b', probability: 0.7),
        candidate('C c', probability: 0.05),
        candidate('D d', probability: 0.4),
      ]);

      expect([for (final c in result) c.scientificName], ['B b', 'D d', 'A a']);
    });

    test('keeps fewer candidates when there are fewer than three', () {
      expect(topCandidates([candidate('A a')]), hasLength(1));
      expect(topCandidates(const []), isEmpty);
    });
  });

  group('isUncertain', () {
    test('counts a probability below 30 percent as uncertain', () {
      expect(isUncertain(0.29), isTrue);
      expect(isUncertain(0.3), isFalse);
      expect(isUncertain(0.95), isFalse);
    });
  });

  group('IdentificationCandidate', () {
    test('rejects a blank name and a probability outside 0 to 1', () {
      expect(() => candidate(' '), throwsArgumentError);
      expect(() => candidate('A a', probability: -0.1), throwsArgumentError);
      expect(() => candidate('A a', probability: 1.1), throwsArgumentError);
    });

    test('knows its genus', () {
      expect(candidate('Monstera deliciosa').genus, 'Monstera');
    });
  });

  group('matchSpecies', () {
    final monstera = species('monstera-deliciosa', 'Monstera deliciosa');
    final lyrata = species('ficus-lyrata', 'Ficus lyrata');
    final benjamina = species('ficus-benjamina', 'Ficus benjamina');
    final catalog = FakeSpeciesCatalog([monstera, lyrata, benjamina]);

    test('matches the species by scientific name, ignoring case', () {
      expect(
        matchSpecies(candidate('monstera DELICIOSA'), catalog),
        ExactSpecies(monstera),
      );
    });

    test('ignores cultivar and variety parts after the second word', () {
      expect(
        matchSpecies(
          candidate("Monstera deliciosa 'Thai Constellation'"),
          catalog,
        ),
        ExactSpecies(monstera),
      );
      expect(
        matchSpecies(candidate('Ficus lyrata var. bambino'), catalog),
        ExactSpecies(lyrata),
      );
    });

    test('uses a species of the same genus as a template', () {
      expect(
        matchSpecies(candidate('Ficus elastica'), catalog),
        SameGenus(benjamina),
      );
    });

    test('finds nothing without a species of the same genus', () {
      expect(matchSpecies(candidate('Aloe vera'), catalog), const NoSpecies());
    });
  });
}
