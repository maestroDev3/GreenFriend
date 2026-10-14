import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/shared_preferences_missing_species_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferencesMissingSpeciesRepository> openRepository() async =>
    SharedPreferencesMissingSpeciesRepository(
      await SharedPreferences.getInstance(),
    );

void main() {
  group('SharedPreferencesMissingSpeciesRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('keeps the list across a restart', () async {
      await (await openRepository()).record(
        scientificName: 'Aloe aristata',
        commonName: 'Lace aloe',
        day: DateTime(2026, 10, 14),
      );

      final loaded = await (await openRepository()).watch().first;

      expect(loaded.single.scientificName, 'Aloe aristata');
      expect(loaded.single.commonName, 'Lace aloe');
      expect(loaded.single.count, 1);
      expect(loaded.single.lastSeen, DateTime.utc(2026, 10, 14));
    });

    test('clears the list', () async {
      final repository = await openRepository();
      await repository.record(
        scientificName: 'Aloe aristata',
        day: DateTime(2026, 10, 14),
      );

      await repository.clear();

      expect(await (await openRepository()).watch().first, isEmpty);
    });

    test('starts empty on unreadable data', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesMissingSpeciesRepository.key: 'not json',
      });

      expect(await (await openRepository()).watch().first, isEmpty);
    });
  });
}
