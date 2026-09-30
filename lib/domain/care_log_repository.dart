import 'care_log.dart';

/// Stores what care was done when; the history of each plant.
abstract interface class CareLogRepository {
  /// Emits the logs of [plantId] (newest first) immediately and again after
  /// every change.
  Stream<List<CareLog>> watchLogs(String plantId);

  /// All logs of all plants.
  Future<List<CareLog>> allLogs();

  /// Replaces all logs, e.g. when restoring a backup.
  Future<void> replaceAll(List<CareLog> logs);

  Future<CareLog> add({
    required String plantId,
    required CareKind kind,
    required DateTime day,
  });

  Future<void> delete(String id);

  /// Removes all logs of a plant, e.g. when the plant is deleted.
  Future<void> deleteForPlant(String plantId);
}
