import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/clock.dart';
import '../domain/journal.dart';
import '../domain/journal_repository.dart';

/// Keeps the journal entries as versioned JSON in the key-value storage; the
/// photos themselves are files (see `FilePhotoStore`).
class SharedPreferencesJournalRepository implements JournalRepository {
  SharedPreferencesJournalRepository(
    this._preferences, {
    this.clock = DateTime.now,
    Random? random,
  }) : _random = random ?? Random.secure() {
    _entries = _read();
  }

  /// Versioned key, so the stored format can change later with a migration.
  static const entriesKey = 'journal.v1';

  /// Unreadable data is kept here instead of being lost.
  static const backupKey = 'journal.v1.unreadable';

  /// Supplies the time used in generated ids.
  final Clock clock;

  final SharedPreferences _preferences;
  final Random _random;
  final _changes = StreamController<List<JournalEntry>>.broadcast();
  late List<JournalEntry> _entries;

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
  Future<List<JournalEntry>> entriesFor(String plantId) async =>
      _of(_entries, plantId);

  @override
  Future<JournalEntry> add({
    required String plantId,
    required DateTime day,
    String? note,
    String? photo,
  }) async {
    final entry = JournalEntry(
      id: _newId(),
      plantId: plantId,
      day: day,
      note: note,
      photo: photo,
    );
    await _save([..._entries, entry]);
    return entry;
  }

  @override
  Future<void> delete(String id) =>
      _save(_entries.where((entry) => entry.id != id));

  @override
  Future<void> deleteForPlant(String plantId) =>
      _save(_entries.where((entry) => entry.plantId != plantId));

  Future<void> _save(Iterable<JournalEntry> entries) async {
    _entries = entries.toList();
    await _preferences.setString(
      entriesKey,
      jsonEncode([for (final entry in _entries) _toJson(entry)]),
    );
    _changes.add(List.unmodifiable(_entries));
  }

  List<JournalEntry> _read() {
    final raw = _preferences.getString(entriesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [for (final item in list) _fromJson(item as Map<String, dynamic>)];
    } on FormatException {
      return _keepUnreadable(raw);
    } on TypeError {
      return _keepUnreadable(raw);
    } on ArgumentError {
      return _keepUnreadable(raw);
    }
  }

  List<JournalEntry> _keepUnreadable(String raw) {
    unawaited(_preferences.setString(backupKey, raw));
    return [];
  }

  String _newId() {
    final time = clock().microsecondsSinceEpoch.toRadixString(36);
    final noise = _random.nextInt(1 << 32).toRadixString(36);
    return '$time-$noise';
  }

  static Map<String, Object?> _toJson(JournalEntry entry) => {
    'id': entry.id,
    'plantId': entry.plantId,
    'day':
        '${entry.day.year.toString().padLeft(4, '0')}-'
        '${entry.day.month.toString().padLeft(2, '0')}-'
        '${entry.day.day.toString().padLeft(2, '0')}',
    'note': entry.note,
    'photo': entry.photo,
  };

  static JournalEntry _fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    plantId: json['plantId'] as String,
    day: DateTime.parse(json['day'] as String),
    note: json['note'] as String?,
    photo: json['photo'] as String?,
  );
}
