import 'dart:async';

import 'package:green_friend/domain/care_log.dart';
import 'package:green_friend/domain/care_log_repository.dart';

/// In-memory [CareLogRepository] for tests.
class FakeCareLogRepository implements CareLogRepository {
  FakeCareLogRepository([List<CareLog> logs = const []]) : _logs = [...logs];

  final List<CareLog> _logs;
  final _changes = StreamController<void>.broadcast();
  var _nextId = 1;

  List<CareLog> get logs => newestFirst(_logs);

  List<CareLog> _of(String plantId) =>
      newestFirst(_logs.where((log) => log.plantId == plantId));

  @override
  Stream<List<CareLog>> watchLogs(String plantId) => Stream.multi((controller) {
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
    final log = CareLog(
      id: 'log-${_nextId++}',
      plantId: plantId,
      kind: kind,
      day: day,
    );
    _logs.add(log);
    _changes.add(null);
    return log;
  }

  @override
  Future<void> delete(String id) async {
    _logs.removeWhere((log) => log.id == id);
    _changes.add(null);
  }

  @override
  Future<void> deleteForPlant(String plantId) async {
    _logs.removeWhere((log) => log.plantId == plantId);
    _changes.add(null);
  }
}
