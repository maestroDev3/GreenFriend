import 'plant.dart';

/// Stores the user's plants; the only way the app reads or changes them.
abstract interface class PlantRepository {
  /// Emits the current plants (sorted by name) immediately and again after
  /// every change.
  Stream<List<Plant>> watchPlants();

  /// All plants, sorted by name.
  Future<List<Plant>> allPlants();

  /// Replaces all plants, e.g. when restoring a backup.
  Future<void> replaceAll(List<Plant> plants);

  /// Adds a new plant and returns it with its generated id.
  Future<Plant> add({
    required String name,
    String? species,
    String? location,
    int? wateringIntervalDays,
    DateTime? lastWateredOn,
    int? fertilizingIntervalDays,
    DateTime? lastFertilizedOn,
    int? repottingIntervalMonths,
    DateTime? lastRepottedOn,
  });

  /// Replaces the stored plant with the same id; throws [StateError] if the
  /// plant does not exist.
  Future<void> update(Plant plant);

  /// Removes the plant; throws [StateError] if it does not exist.
  Future<void> delete(String id);
}
