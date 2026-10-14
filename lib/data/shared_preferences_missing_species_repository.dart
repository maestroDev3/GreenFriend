import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/missing_species.dart';

/// Keeps the missing species list as versioned JSON in the key-value store.
class SharedPreferencesMissingSpeciesRepository
    implements MissingSpeciesRepository {
  SharedPreferencesMissingSpeciesRepository(this._preferences) {
    _species = _read();
  }

  static const key = 'missingSpecies.v1';

  final SharedPreferences _preferences;
  final _changes = StreamController<List<MissingSpecies>>.broadcast();
  late List<MissingSpecies> _species;

  @override
  Stream<List<MissingSpecies>> watch() => Stream.multi((controller) {
    controller.add(_species);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> record({
    required String scientificName,
    String? commonName,
    required DateTime day,
  }) => _save(
    recordMissingSpecies(
      _species,
      scientificName: scientificName,
      commonName: commonName,
      day: day,
    ),
  );

  @override
  Future<void> clear() => _save(const []);

  Future<void> _save(List<MissingSpecies> species) async {
    _species = List.unmodifiable(species);
    await _preferences.setString(
      key,
      jsonEncode([
        for (final item in _species)
          {
            'scientificName': item.scientificName,
            'commonName': item.commonName,
            'count': item.count,
            'lastSeen': item.lastSeen.toIso8601String().substring(0, 10),
          },
      ]),
    );
    _changes.add(_species);
  }

  List<MissingSpecies> _read() {
    final stored = _preferences.getString(key);
    if (stored == null) return const [];
    try {
      return List.unmodifiable([
        for (final item in (jsonDecode(stored) as List<Object?>)
            .cast<Map<String, Object?>>())
          MissingSpecies(
            scientificName: item['scientificName'] as String,
            commonName: item['commonName'] as String?,
            count: item['count'] as int,
            lastSeen: DateTime.parse('${item['lastSeen']}T00:00:00Z'),
          ),
      ]);
    } on Object {
      return const [];
    }
  }
}
