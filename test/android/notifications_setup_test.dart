import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  group('Android setup for reminders', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');

    test('declares the notification and reboot permissions', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    });

    test('does not ask for exact alarms', () {
      expect(manifest, isNot(contains('SCHEDULE_EXACT_ALARM')));
      expect(manifest, isNot(contains('USE_EXACT_ALARM')));
    });

    test('declares the receivers of the notification plugin', () {
      expect(manifest, contains('ScheduledNotificationReceiver'));
      expect(manifest, contains('ScheduledNotificationBootReceiver'));
      expect(manifest, contains('android.intent.action.BOOT_COMPLETED'));
    });

    test('enables core library desugaring', () {
      final gradle = read('android/app/build.gradle.kts');

      expect(gradle, contains('isCoreLibraryDesugaringEnabled = true'));
      expect(gradle, contains('desugar_jdk_libs'));
    });
  });
}
