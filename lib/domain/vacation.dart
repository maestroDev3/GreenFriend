import 'clock.dart';

/// A period the user is away; no reminders are shown on its days.
class Vacation {
  /// Throws [ArgumentError] if [last] is before [first]; both are
  /// normalized to calendar days.
  Vacation({required DateTime first, required DateTime last})
    : first = dayOf(first),
      last = dayOf(last) {
    if (this.last.isBefore(this.first)) {
      throw ArgumentError.value(last, 'last', 'must not be before first');
    }
  }

  /// First day away (UTC midnight).
  final DateTime first;

  /// Last day away (UTC midnight), inclusive.
  final DateTime last;

  /// Whether [day] lies within the vacation.
  bool covers(DateTime day) {
    final normalized = dayOf(day);
    return !normalized.isBefore(first) && !normalized.isAfter(last);
  }

  @override
  bool operator ==(Object other) =>
      other is Vacation && other.first == first && other.last == last;

  @override
  int get hashCode => Object.hash(first, last);

  @override
  String toString() => 'Vacation($first – $last)';
}
