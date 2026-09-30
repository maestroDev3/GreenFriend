import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/clock.dart';

/// Keeps all care logs as versioned JSON in the platform's key-value storage.
class SharedPreferencesCareLogRepository implements CareLogRepository {
  SharedPreferencesCareLogRepository(
    this._preferences, {
    this.clock = DateTime.now,
    Random? random,
  }) : _random = random ?? Random.secure() {
    _logs = _read();
  }

  /// Versioned key, so the stored format can change later with a migration.
  static const logsKey = 'careLogs.v1';

  /// Unreadable data is kept here instead of being lost.
  static const backupKey = 'careLogs.v1.unreadable';

  /// Supplies the time used in generated ids.
  final Clock clock;

  final SharedPreferences _preferences;
  final Random _random;
  final _changes = StreamController<void>.broadcast();
  late List<CareLog> _logs;

  List<CareLog> _of(String plantId) =>
      newestFirst(_logs.where((log) => log.plantId == plantId));

  @override
  Stream<List<CareLog>> watchLogs(String plantId) =>
      Stream.multi((controller) {
        controller.add(_of(plantId));
        final subscription = _changes.stream.listen(
          (_) => controller.add(_of(plantId)),
        );
        controller.onCancel = subscription.cancel;
      });

  @override
  Future<CareLog> add({
    required String plantId,
    required CareKind kind,
    required DateTime day,
  }) async {
    final log = CareLog(id: _newId(), plantId: plantId, kind: kind, day: day);
    await _save([..._logs, log]);
    return log;
  }

  @override
  Future<void> delete(String id) =>
      _save(_logs.where((log) => log.id != id));

  @override
  Future<void> deleteForPlant(String plantId) =>
      _save(_logs.where((log) => log.plantId != plantId));

  Future<void> _save(Iterable<CareLog> logs) async {
    _logs = logs.toList();
    await _preferences.setString(
      logsKey,
      jsonEncode([for (final log in _logs) _toJson(log)]),
    );
    _changes.add(null);
  }

  List<CareLog> _read() {
    final raw = _preferences.getString(logsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final entry in list)
          if (_fromJson(entry as Map<String, dynamic>) case final log?) log,
      ];
    } on FormatException {
      return _keepUnreadable(raw);
    } on TypeError {
      return _keepUnreadable(raw);
    }
  }

  List<CareLog> _keepUnreadable(String raw) {
    unawaited(_preferences.setString(backupKey, raw));
    return [];
  }

  String _newId() {
    final time = clock().microsecondsSinceEpoch.toRadixString(36);
    final noise = _random.nextInt(1 << 32).toRadixString(36);
    return '$time-$noise';
  }

  static Map<String, Object?> _toJson(CareLog log) => {
    'id': log.id,
    'plantId': log.plantId,
    'kind': log.kind.name,
    'day': _isoDay(log.day),
  };

  /// Returns `null` for a log with an unknown kind (e.g. from a newer app
  /// version), so it is skipped instead of breaking all logs.
  static CareLog? _fromJson(Map<String, dynamic> json) {
    final kind = CareKind.byName(json['kind'] as String);
    if (kind == null) return null;
    return CareLog(
      id: json['id'] as String,
      plantId: json['plantId'] as String,
      kind: kind,
      day: DateTime.parse(json['day'] as String),
    );
  }

  static String _isoDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
