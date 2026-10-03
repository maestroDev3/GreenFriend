/// A button in a notification; [id] tells the app what to do.
class NotificationAction {
  const NotificationAction({required this.id, required this.label});

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is NotificationAction && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);

  @override
  String toString() => 'NotificationAction($id, $label)';
}

/// A notification to show at a local date and time.
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    this.actions = const [],
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// Buttons shown with the notification (Android allows up to three).
  final List<NotificationAction> actions;

  @override
  bool operator ==(Object other) =>
      other is ScheduledNotification &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body &&
      other.actions.length == actions.length &&
      Iterable.generate(
        actions.length,
      ).every((i) => other.actions[i] == actions[i]);

  @override
  int get hashCode => Object.hash(id, at, title, body, Object.hashAll(actions));

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
