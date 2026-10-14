import 'dart:async';

import 'package:green_friend/domain/missing_species.dart';

/// In-memory [MissingSpeciesRepository] for tests.
class FakeMissingSpeciesRepository implements MissingSpeciesRepository {
  FakeMissingSpeciesRepository([List<MissingSpecies> species = const []])
    : species = [...species];

  List<MissingSpecies> species;
  final _changes = StreamController<List<MissingSpecies>>.broadcast();

  @override
  Stream<List<MissingSpecies>> watch() => Stream.multi((controller) {
    controller.add(species);
    final subscription = _changes.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });

  @override
  Future<void> record({
    required String scientificName,
    String? commonName,
    required DateTime day,
  }) async {
    species = recordMissingSpecies(
      species,
      scientificName: scientificName,
      commonName: commonName,
      day: day,
    );
    _changes.add(species);
  }

  @override
  Future<void> clear() async {
    species = [];
    _changes.add(species);
  }
}
