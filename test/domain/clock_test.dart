import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/clock.dart';

void main() {
  group('dayOf', () {
    test('returns UTC midnight of the calendar date', () {
      final day = dayOf(DateTime(2026, 9, 29, 17, 45));

      expect(day, DateTime.utc(2026, 9, 29));
      expect(day.isUtc, isTrue);
    });

    test('keeps the calendar date of a UTC input', () {
      expect(dayOf(DateTime.utc(2026, 9, 29, 23, 30)), DateTime.utc(2026, 9, 29));
    });

    test('maps two times on the same day to the same value', () {
      expect(
        dayOf(DateTime(2026, 9, 29, 0, 0, 1)),
        dayOf(DateTime(2026, 9, 29, 23, 59, 59)),
      );
    });

    test('lets consecutive days differ by exactly one day', () {
      final monday = dayOf(DateTime(2026, 9, 28, 22));
      final thursday = dayOf(DateTime(2026, 10, 1, 6));

      expect(dayOf(DateTime(2026, 9, 29, 7)).difference(monday),
          const Duration(days: 1));
      expect(thursday.difference(monday), const Duration(days: 3));
    });

    test('counts whole days across the spring daylight saving switch', () {
      final before = dayOf(DateTime(2026, 3, 28, 12));
      final after = dayOf(DateTime(2026, 3, 30, 12));

      expect(after.difference(before), const Duration(days: 2));
    });

    test('counts whole days across the autumn daylight saving switch', () {
      final before = dayOf(DateTime(2026, 10, 24, 12));
      final after = dayOf(DateTime(2026, 10, 26, 12));

      expect(after.difference(before), const Duration(days: 2));
    });
  });

  group('Clock', () {
    test('can be replaced by a fixed time in tests', () {
      DateTime fixed() => DateTime(2026, 9, 29, 8);
      final Clock clock = fixed;

      expect(dayOf(clock()), DateTime.utc(2026, 9, 29));
    });
  });
}
