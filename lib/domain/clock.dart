/// Supplies the current time, so time-dependent logic can be tested with
/// fixed dates instead of the real clock.
typedef Clock = DateTime Function();

/// Normalizes [dateTime] to its calendar day, so day arithmetic is never
/// shifted by daylight saving time.
///
/// Returns UTC midnight of the date components of [dateTime].
DateTime dayOf(DateTime dateTime) =>
    DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
