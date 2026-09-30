import 'package:green_friend/domain/notification_scheduler.dart';

/// Records what the app would schedule instead of showing notifications.
class FakeNotificationScheduler implements NotificationScheduler {
  FakeNotificationScheduler({this.grantPermission = true});

  final bool grantPermission;
  var permissionRequests = 0;
  List<ScheduledNotification> scheduled = [];

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grantPermission;
  }

  @override
  Future<void> replaceAll(List<ScheduledNotification> notifications) async {
    scheduled = [...notifications];
  }
}
