import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';

/// Keeps all plants as versioned JSON in the platform's key-value storage.
///
/// Chosen over a database for now: the data is small and easy to export;
/// the [PlantRepository] interface allows switching later.
class SharedPreferencesPlantRepository implements PlantRepository {
  SharedPreferencesPlantRepository(
    this._preferences, {
    this.clock = DateTime.now,
    Random? random,
  }) : _random = random ?? Random.secure() {
    _plants = _read();
  }

  /// Versioned key, so the stored format can change later with a migration.
  static const plantsKey = 'plants.v1';

  /// Unreadable data is kept here instead of being lost.
  static const backupKey = 'plants.v1.unreadable';

  /// Supplies the time used in generated ids.
  final Clock clock;

  final SharedPreferences _preferences;
  final Random _random;
  final _changes = StreamController<List<Plant>>.broadcast();
  late List<Plant> _plants;

  @override
  Stream<List<Plant>> watchPlants() => Stream.multi((controller) {
    controller.add(_plants);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<Plant> add({
    required String name,
    String? species,
    String? location,
  }) async {
    final plant = Plant(
      id: _newId(),
      name: name,
      species: species,
      location: location,
    );
    await _save([..._plants, plant]);
    return plant;
  }

  @override
  Future<void> update(Plant plant) async {
    _requireExisting(plant.id);
    await _save([
      for (final existing in _plants)
        existing.id == plant.id ? plant : existing,
    ]);
  }

  @override
  Future<void> delete(String id) async {
    _requireExisting(id);
    await _save(_plants.where((plant) => plant.id != id));
  }

  void _requireExisting(String id) {
    if (!_plants.any((plant) => plant.id == id)) {
      throw StateError('Unknown plant $id');
    }
  }

  Future<void> _save(Iterable<Plant> plants) async {
    _plants = sortedByName(plants);
    await _preferences.setString(
      plantsKey,
      jsonEncode([for (final plant in _plants) _toJson(plant)]),
    );
    _changes.add(_plants);
  }

  List<Plant> _read() {
    final raw = _preferences.getString(plantsKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return sortedByName([
        for (final entry in list) _fromJson(entry as Map<String, dynamic>),
      ]);
    } on FormatException {
      return _keepUnreadable(raw);
    } on TypeError {
      return _keepUnreadable(raw);
    } on ArgumentError {
      return _keepUnreadable(raw);
    }
  }

  List<Plant> _keepUnreadable(String raw) {
    unawaited(_preferences.setString(backupKey, raw));
    return const [];
  }

  String _newId() {
    final time = clock().microsecondsSinceEpoch.toRadixString(36);
    final noise = _random.nextInt(1 << 32).toRadixString(36);
    return '$time-$noise';
  }

  static Map<String, Object?> _toJson(Plant plant) => {
    'id': plant.id,
    'name': plant.name,
    'species': plant.species,
    'location': plant.location,
  };

  static Plant _fromJson(Map<String, dynamic> json) => Plant(
    id: json['id'] as String,
    name: json['name'] as String,
    species: json['species'] as String?,
    location: json['location'] as String?,
  );
}
