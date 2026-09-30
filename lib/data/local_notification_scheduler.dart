import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/notification_scheduler.dart';

/// Shows the reminders as Android notifications in the device time zone.
///
/// Scheduling is inexact (may be a few minutes late), so the app needs no
/// exact-alarm permission; the plugin restores notifications after a reboot.
class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler._(this._plugin, this._location, this._details);

  /// Initializes the plugin and time zones; [channelName] and
  /// [channelDescription] appear in the system notification settings.
  static Future<LocalNotificationScheduler> create({
    required String channelName,
    required String channelDescription,
  }) async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    final location = locationOrUtc(zone.identifier);
    tz.setLocalLocation(location);

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(
          '@drawable/ic_launcher_monochrome',
        ),
      ),
    );
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder',
        channelName,
        channelDescription: channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    return LocalNotificationScheduler._(plugin, location, details);
  }

  final FlutterLocalNotificationsPlugin _plugin;
  final tz.Location _location;
  final NotificationDetails _details;

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {
    await _plugin.cancelAllPendingNotifications();
    for (final notification in notifications) {
      await _plugin.zonedSchedule(
        id: notification.id,
        scheduledDate: toZonedTime(notification.at, _location),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: notification.title,
        body: notification.body,
      );
    }
  }
}

/// The wall-clock time of [local] in [location] (e.g. 8:30 stays 8:30 across
/// a daylight saving switch).
tz.TZDateTime toZonedTime(DateTime local, tz.Location location) {
  return tz.TZDateTime(
    location,
    local.year,
    local.month,
    local.day,
    local.hour,
    local.minute,
  );
}

/// The time zone named [identifier], or UTC if it is unknown.
tz.Location locationOrUtc(String identifier) {
  try {
    return tz.getLocation(identifier);
  } on tz.LocationNotFoundException {
    return tz.UTC;
  }
}
