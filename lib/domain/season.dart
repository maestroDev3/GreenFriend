import 'clock.dart';

/// Whether [day] lies in the winter rest of houseplants: November 1 to the
/// end of February (northern hemisphere), when they need less water and no
/// fertilizer.
bool isWinterRest(DateTime day) {
  final month = dayOf(day).month;
  return month >= 11 || month <= 2;
}

/// March 1 after the winter rest that [day] lies in.
DateTime winterRestEnd(DateTime day) {
  final normalized = dayOf(day);
  final year = normalized.month >= 11 ? normalized.year + 1 : normalized.year;
  return DateTime.utc(year, 3);
}

/// The watering interval during winter rest: one and a half times [days],
/// rounded up.
int winterWateringInterval(int days) => (days * 3 + 1) ~/ 2;
