import 'clock.dart';

/// A note and/or photo that documents how a plant develops.
class JournalEntry {
  /// Throws [ArgumentError] if there is neither a note nor a photo.
  JournalEntry({
    required this.id,
    required this.plantId,
    required DateTime day,
    String? note,
    this.photo,
    this.healthCheck = false,
  }) : day = dayOf(day),
       note = _optional(note) {
    if (this.note == null && photo == null) {
      throw ArgumentError('A journal entry needs a note or a photo.');
    }
  }

  final String id;
  final String plantId;

  /// Calendar day (UTC midnight) of the entry.
  final DateTime day;
  final String? note;

  /// File name of the photo in the app's photo folder.
  final String? photo;

  /// Whether the entry records a health check (shown with a health icon).
  final bool healthCheck;

  @override
  bool operator ==(Object other) =>
      other is JournalEntry &&
      other.id == id &&
      other.plantId == plantId &&
      other.day == day &&
      other.note == note &&
      other.photo == photo &&
      other.healthCheck == healthCheck;

  @override
  int get hashCode => Object.hash(id, plantId, day, note, photo, healthCheck);

  @override
  String toString() => 'JournalEntry($id, $plantId, $day)';

  static String? _optional(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// Returns [entries] with the most recent day first.
List<JournalEntry> newestEntriesFirst(Iterable<JournalEntry> entries) {
  return [...entries]..sort((a, b) => b.day.compareTo(a.day));
}
