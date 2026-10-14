import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/device_phone_calendar.dart';
import 'package:green_friend/domain/phone_calendar.dart';

void main() {
  group('phoneCalendarInfoOf', () {
    test('maps id, name, account and writability', () {
      expect(
        phoneCalendarInfoOf(
          const Calendar(
            id: '3',
            name: 'Personal',
            readOnly: false,
            accountName: 'me@example.com',
          ),
        ),
        const PhoneCalendarInfo(
          id: '3',
          name: 'Personal',
          account: 'me@example.com',
          writable: true,
        ),
      );
      expect(
        phoneCalendarInfoOf(
          const Calendar(id: '4', name: 'Holidays', readOnly: true),
        ).writable,
        isFalse,
      );
    });
  });

  group('calendarDayOf', () {
    test('reads the floating date of an all-day event', () {
      expect(calendarDayOf(DateTime(2026, 10, 31)), DateTime.utc(2026, 10, 31));
    });
  });
}
