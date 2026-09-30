import 'journal.dart';
import 'journal_repository.dart';
import 'photos.dart';

/// Deletes a journal entry together with its photo.
Future<void> deleteJournalEntry({
  required JournalRepository journal,
  required PhotoStore photos,
  required JournalEntry entry,
}) async {
  if (entry.photo case final photo?) await photos.delete(photo);
  await journal.delete(entry.id);
}

/// Deletes all journal entries of a plant and their photos, e.g. when the
/// plant is deleted.
Future<void> deleteJournalForPlant({
  required JournalRepository journal,
  required PhotoStore photos,
  required String plantId,
}) async {
  final entries = await journal.entriesFor(plantId);
  for (final entry in entries) {
    if (entry.photo case final photo?) await photos.delete(photo);
  }
  await journal.deleteForPlant(plantId);
}
