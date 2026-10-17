import 'journal.dart';

/// The journal entries that make up a plant's growth time-lapse: those with a
/// photo, oldest first (entries of the same day keep their order).
List<JournalEntry> timelapseEntries(Iterable<JournalEntry> entries) {
  final withPhoto = [
    for (final entry in entries)
      if (entry.photo != null) entry,
  ];
  // List.sort is not stable, so ties are ordered by the original index.
  final indexed = withPhoto.indexed.toList()
    ..sort((a, b) {
      final byDay = a.$2.day.compareTo(b.$2.day);
      return byDay != 0 ? byDay : a.$1.compareTo(b.$1);
    });
  return [for (final (_, entry) in indexed) entry];
}

/// One photo of the time-lapse with the text drawn onto it (its date).
class TimelapseFrame {
  const TimelapseFrame({required this.bytes, required this.label});

  /// The encoded photo (JPEG, PNG, …).
  final List<int> bytes;
  final String label;
}

/// Thrown when no time-lapse can be made, e.g. no photo is readable.
class TimelapseException implements Exception {
  const TimelapseException(this.message);

  final String message;

  @override
  String toString() => 'TimelapseException: $message';
}

/// Turns photos into an animation file, e.g. an animated GIF.
abstract interface class TimelapseEncoder {
  /// Encodes one frame per readable photo; unreadable photos are skipped.
  /// Throws [TimelapseException] if none is readable.
  Future<List<int>> encode(List<TimelapseFrame> frames);
}
