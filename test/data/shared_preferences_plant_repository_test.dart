import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/shared_preferences_plant_repository.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferencesPlantRepository> openRepository() async =>
    SharedPreferencesPlantRepository(await SharedPreferences.getInstance());

Future<List<Plant>> currentPlants(SharedPreferencesPlantRepository repo) =>
    repo.watchPlants().first;

void main() {
  group('SharedPreferencesPlantRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('starts empty', () async {
      expect(await currentPlants(await openRepository()), isEmpty);
    });

    test('keeps plants across a restart', () async {
      final plant = await (await openRepository()).add(
        name: 'Monstera',
        species: 'Monstera deliciosa',
        location: 'Living room',
      );

      expect(await currentPlants(await openRepository()), [plant]);
    });

    test('keeps the species id across a restart', () async {
      final plant = await (await openRepository()).add(
        name: 'Monstera',
        speciesId: 'monstera-deliciosa',
      );

      final loaded = (await currentPlants(await openRepository())).single;
      expect(loaded.speciesId, 'monstera-deliciosa');
      expect(loaded, plant);
    });

    test('loads plants stored before the species id existed', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPlantRepository.plantsKey:
            '[{"id":"a","name":"Aloe","species":"Aloe vera",'
            '"location":null,"wateringIntervalDays":14}]',
      });

      final plant = (await currentPlants(await openRepository())).single;

      expect(plant.speciesId, isNull);
      expect(plant.species, 'Aloe vera');
      expect(plant.wateringIntervalDays, 14);
    });

    test('generates unique ids', () async {
      final repository = await openRepository();

      final first = await repository.add(name: 'Aloe');
      final second = await repository.add(name: 'Aloe');

      expect(first.id, isNot(second.id));
    });

    test('updates and deletes plants', () async {
      final repository = await openRepository();
      final aloe = await repository.add(name: 'Aloe');
      final pothos = await repository.add(name: 'Pothos');

      await repository.update(aloe.copyWith(location: 'Bathroom'));
      await repository.delete(pothos.id);

      expect(await currentPlants(await openRepository()), [
        aloe.copyWith(location: 'Bathroom'),
      ]);
    });

    test('throws for unknown plants', () async {
      final repository = await openRepository();

      expect(
        () => repository.update(Plant(id: 'x', name: 'Ghost')),
        throwsStateError,
      );
      expect(() => repository.delete('x'), throwsStateError);
    });

    test('emits the list on subscription and after every change', () async {
      final repository = await openRepository();
      final emitted = <List<String>>[];
      final subscription = repository.watchPlants().listen(
        (plants) => emitted.add([for (final plant in plants) plant.name]),
      );
      await pumpEventQueue();

      final pothos = await repository.add(name: 'Pothos');
      await repository.add(name: 'aloe');
      await repository.update(pothos.copyWith(name: 'Zebra plant'));
      await repository.delete(pothos.id);
      await pumpEventQueue();
      await subscription.cancel();

      expect(emitted, [
        <String>[],
        ['Pothos'],
        ['aloe', 'Pothos'],
        ['aloe', 'Zebra plant'],
        ['aloe'],
      ]);
    });

    test('starts empty on corrupt data and keeps a backup of it', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPlantRepository.plantsKey: 'not json',
      });

      final repository = await openRepository();
      final preferences = await SharedPreferences.getInstance();

      expect(await currentPlants(repository), isEmpty);
      expect(
        preferences.getString(SharedPreferencesPlantRepository.backupKey),
        'not json',
      );
    });

    test('keeps the watering schedule across a restart', () async {
      final plant = await (await openRepository()).add(
        name: 'Monstera',
        wateringIntervalDays: 7,
        lastWateredOn: DateTime(2026, 9, 28),
      );

      final loaded = (await currentPlants(await openRepository())).single;

      expect(loaded, plant);
      expect(loaded.wateringIntervalDays, 7);
      expect(loaded.lastWateredOn, DateTime.utc(2026, 9, 28));
    });

    test('stores the last watering as an ISO calendar day', () async {
      await (await openRepository()).add(
        name: 'Monstera',
        wateringIntervalDays: 7,
        lastWateredOn: DateTime(2026, 9, 28, 21, 45),
      );
      final preferences = await SharedPreferences.getInstance();

      expect(
        preferences.getString(SharedPreferencesPlantRepository.plantsKey),
        contains('"lastWateredOn":"2026-09-28"'),
      );
    });

    test('loads plants stored before the watering fields existed', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPlantRepository.plantsKey:
            '[{"id":"a","name":"Aloe","species":null,"location":"Kitchen"}]',
      });

      final plant = (await currentPlants(await openRepository())).single;

      expect(plant.name, 'Aloe');
      expect(plant.location, 'Kitchen');
      expect(plant.wateringIntervalDays, isNull);
      expect(plant.lastWateredOn, isNull);
    });

    test(
      'keeps fertilizing and repotting schedules across a restart',
      () async {
        final plant = await (await openRepository()).add(
          name: 'Pothos',
          fertilizingIntervalDays: 14,
          lastFertilizedOn: DateTime(2026, 9, 20),
          repottingIntervalMonths: 18,
          lastRepottedOn: DateTime(2025, 4, 2),
        );

        final loaded = (await currentPlants(await openRepository())).single;

        expect(loaded, plant);
        expect(loaded.fertilizingIntervalDays, 14);
        expect(loaded.lastFertilizedOn, DateTime.utc(2026, 9, 20));
        expect(loaded.repottingIntervalMonths, 18);
        expect(loaded.lastRepottedOn, DateTime.utc(2025, 4, 2));
      },
    );

    test(
      'loads plants stored before fertilizing and repotting existed',
      () async {
        SharedPreferences.setMockInitialValues({
          SharedPreferencesPlantRepository.plantsKey:
              '[{"id":"a","name":"Aloe","wateringIntervalDays":7,'
              '"lastWateredOn":"2026-09-28"}]',
        });

        final plant = (await currentPlants(await openRepository())).single;

        expect(plant.wateringIntervalDays, 7);
        expect(plant.fertilizingIntervalDays, isNull);
        expect(plant.lastFertilizedOn, isNull);
        expect(plant.repottingIntervalMonths, isNull);
        expect(plant.lastRepottedOn, isNull);
      },
    );

    test('lists and replaces all plants', () async {
      final repository = await openRepository();
      await repository.add(name: 'Old');

      await repository.replaceAll([Plant(id: 'x', name: 'Aloe')]);

      expect(await (await openRepository()).allPlants(), [
        Plant(id: 'x', name: 'Aloe'),
      ]);
    });
  });
}
