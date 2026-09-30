import 'journal.dart';

/// Stores the growth journal of the plants.
abstract interface class JournalRepository {
  /// Emits the entries of [plantId] (newest first) immediately and again
  /// after every change.
  Stream<List<JournalEntry>> watchEntries(String plantId);

  /// Throws [ArgumentError] if there is neither a note nor a photo.
  Future<JournalEntry> add({
    required String plantId,
    required DateTime day,
    String? note,
    String? photo,
  });

  Future<void> delete(String id);

  /// Removes all entries of a plant (the photos via [deleteJournalForPlant]).
  Future<void> deleteForPlant(String plantId);
}
