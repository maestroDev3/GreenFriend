import 'clock.dart';

/// What kind of care was done.
sealed class CareKind {
  const CareKind(this.name);

  /// Stable identifier used for storage.
  final String name;

  static const values = <CareKind>[Water(), Fertilize(), Repot(), Prune()];

  /// The kind stored under [name], or `null` if unknown.
  static CareKind? byName(String name) {
    for (final kind in values) {
      if (kind.name == name) return kind;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is CareKind && other.runtimeType == runtimeType;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

final class Water extends CareKind {
  const Water() : super('water');
}

final class Fertilize extends CareKind {
  const Fertilize() : super('fertilize');
}

final class Repot extends CareKind {
  const Repot() : super('repot');
}

final class Prune extends CareKind {
  const Prune() : super('prune');
}

/// One care task that was done for a plant on a day.
class CareLog {
  CareLog({
    required this.id,
    required this.plantId,
    required this.kind,
    required DateTime day,
  }) : day = dayOf(day);

  final String id;
  final String plantId;
  final CareKind kind;

  /// Calendar day (UTC midnight) the care was done.
  final DateTime day;

  @override
  bool operator ==(Object other) =>
      other is CareLog &&
      other.id == id &&
      other.plantId == plantId &&
      other.kind == kind &&
      other.day == day;

  @override
  int get hashCode => Object.hash(id, plantId, kind, day);

  @override
  String toString() => 'CareLog($id, $plantId, $kind, $day)';
}

/// Returns [logs] with the most recent day first.
List<CareLog> newestFirst(Iterable<CareLog> logs) {
  return [...logs]..sort((a, b) => b.day.compareTo(a.day));
}
