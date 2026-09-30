import 'dart:async';

import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/domain/plant_repository.dart';

/// In-memory [PlantRepository] for tests.
class FakePlantRepository implements PlantRepository {
  FakePlantRepository([List<Plant> plants = const []]) : _plants = [...plants];

  final List<Plant> _plants;
  final _changes = StreamController<List<Plant>>.broadcast();
  var _nextId = 1;

  List<Plant> get plants => sortedByName(_plants);

  @override
  Stream<List<Plant>> watchPlants() => Stream.multi((controller) {
    controller.add(plants);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<List<Plant>> allPlants() async => plants;

  @override
  Future<void> replaceAll(List<Plant> plants) async {
    _plants
      ..clear()
      ..addAll(plants);
    _changes.add(this.plants);
  }

  @override
  Future<Plant> add({
    required String name,
    String? species,
    String? speciesId,
    String? location,
    int? wateringIntervalDays,
    DateTime? lastWateredOn,
    int? fertilizingIntervalDays,
    DateTime? lastFertilizedOn,
    int? repottingIntervalMonths,
    DateTime? lastRepottedOn,
    int? pruningIntervalMonths,
    DateTime? lastPrunedOn,
  }) async {
    final plant = Plant(
      id: 'fake-${_nextId++}',
      name: name,
      species: species,
      speciesId: speciesId,
      location: location,
      wateringIntervalDays: wateringIntervalDays,
      lastWateredOn: lastWateredOn,
      fertilizingIntervalDays: fertilizingIntervalDays,
      lastFertilizedOn: lastFertilizedOn,
      repottingIntervalMonths: repottingIntervalMonths,
      lastRepottedOn: lastRepottedOn,
      pruningIntervalMonths: pruningIntervalMonths,
      lastPrunedOn: lastPrunedOn,
    );
    _plants.add(plant);
    _changes.add(plants);
    return plant;
  }

  @override
  Future<void> update(Plant plant) async {
    final index = _plants.indexWhere((existing) => existing.id == plant.id);
    if (index < 0) throw StateError('Unknown plant ${plant.id}');
    _plants[index] = plant;
    _changes.add(plants);
  }

  @override
  Future<void> delete(String id) async {
    final before = _plants.length;
    _plants.removeWhere((plant) => plant.id == id);
    if (_plants.length == before) throw StateError('Unknown plant $id');
    _changes.add(plants);
  }
}
