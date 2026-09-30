import 'dart:async';

import 'package:green_friend/domain/journal.dart';
import 'package:green_friend/domain/journal_repository.dart';

/// In-memory [JournalRepository] for tests.
class FakeJournalRepository implements JournalRepository {
  FakeJournalRepository([List<JournalEntry> entries = const []])
    : _entries = [...entries];

  final List<JournalEntry> _entries;
  final _changes = StreamController<List<JournalEntry>>.broadcast();
  var _nextId = 1;

  List<JournalEntry> get entries => newestEntriesFirst(_entries);

  static List<JournalEntry> _of(Iterable<JournalEntry> all, String plantId) =>
      newestEntriesFirst(all.where((entry) => entry.plantId == plantId));

  @override
  Stream<List<JournalEntry>> watchEntries(String plantId) =>
      Stream.multi((controller) {
        controller.add(_of(_entries, plantId));
        final subscription = _changes.stream.listen(
          (all) => controller.add(_of(all, plantId)),
        );
        controller.onCancel = subscription.cancel;
      });

  @override
  Future<JournalEntry> add({
    required String plantId,
    required DateTime day,
    String? note,
    String? photo,
  }) async {
    final entry = JournalEntry(
      id: 'entry-${_nextId++}',
      plantId: plantId,
      day: day,
      note: note,
      photo: photo,
    );
    _entries.add(entry);
    _changes.add(List.unmodifiable(_entries));
    return entry;
  }

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
    _changes.add(List.unmodifiable(_entries));
  }

  @override
  Future<void> deleteForPlant(String plantId) async {
    _entries.removeWhere((entry) => entry.plantId == plantId);
    _changes.add(List.unmodifiable(_entries));
  }
}
