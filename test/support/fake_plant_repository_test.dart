import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';

import 'fake_plant_repository.dart';

void main() {
  group('FakePlantRepository', () {
    test('emits the current list first and after every change', () async {
      final repository = FakePlantRepository([
        Plant(id: 'a', name: 'Aloe'),
      ]);
      final emitted = <List<String>>[];
      final subscription = repository.watchPlants().listen(
        (plants) => emitted.add([for (final plant in plants) plant.name]),
      );
      await pumpEventQueue();

      final monstera = await repository.add(name: 'Monstera');
      await repository.update(monstera.copyWith(name: 'Big monstera'));
      await repository.delete('a');
      await pumpEventQueue();
      await subscription.cancel();

      expect(emitted, [
        ['Aloe'],
        ['Aloe', 'Monstera'],
        ['Aloe', 'Big monstera'],
        ['Big monstera'],
      ]);
    });

    test('throws for unknown plants', () async {
      final repository = FakePlantRepository();

      expect(
        () => repository.update(Plant(id: 'x', name: 'Ghost')),
        throwsStateError,
      );
      expect(() => repository.delete('x'), throwsStateError);
    });
  });
}
