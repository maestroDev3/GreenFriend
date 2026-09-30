import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/local_notification_scheduler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  group('toZonedTime', () {
    test('keeps the wall-clock time in the device time zone', () {
      final berlin = tz.getLocation('Europe/Berlin');

      final summer = toZonedTime(DateTime(2026, 10, 24, 8, 30), berlin);
      final winter = toZonedTime(DateTime(2026, 10, 25, 8, 30), berlin);

      expect([summer.hour, summer.minute], [8, 30]);
      expect(summer.timeZoneOffset, const Duration(hours: 2));
      expect([winter.hour, winter.minute], [8, 30]);
      expect(winter.timeZoneOffset, const Duration(hours: 1));
    });
  });

  group('locationOrUtc', () {
    test('finds a known time zone', () {
      expect(locationOrUtc('Europe/Berlin').name, 'Europe/Berlin');
    });

    test('falls back to UTC for an unknown time zone', () {
      expect(locationOrUtc('Mars/Olympus_Mons'), same(tz.UTC));
    });
  });
}
