/// A notification to show at a local date and time.
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is ScheduledNotification &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body;

  @override
  int get hashCode => Object.hash(id, at, title, body);

  @override
  String toString() => 'ScheduledNotification($id, $at, $body)';
}

/// Shows notifications at planned times; implemented with the platform's
/// notification service.
abstract interface class NotificationScheduler {
  /// Asks the user for permission to show notifications; `true` if granted.
  Future<bool> requestPermission();

  /// Cancels all scheduled notifications and schedules [notifications].
  Future<void> replaceAll(List<ScheduledNotification> notifications);
}
