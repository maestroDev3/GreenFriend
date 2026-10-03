import 'dart:async';
import 'dart:ui';

import '../domain/care_log.dart';
import '../domain/clock.dart';
import '../domain/notification_scheduler.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../domain/reminders.dart';
import '../domain/settings.dart';
import '../l10n/app_localizations.dart';
import 'locale_resolution.dart';
import 'settings_controller.dart';

/// Keeps the scheduled reminders in line with the plants and the settings:
/// replans whenever a plant, its watering or a setting changes.
class ReminderSync {
  ReminderSync({
    required this.plants,
    required this.settings,
    required this.scheduler,
    required this.localizations,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
  final SettingsController settings;
  final NotificationScheduler scheduler;

  /// Texts in the app's current language.
  final AppLocalizations Function() localizations;
  final Clock clock;

  StreamSubscription<List<Plant>>? _subscription;
  List<Plant> _plants = const [];
  Future<void> _pending = Future.value();
  var _permissionAsked = false;

  void start() {
    _subscription = plants.watchPlants().listen((plants) {
      _plants = plants;
      _requestSync();
    });
    settings.addListener(_requestSync);
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    settings.removeListener(_requestSync);
  }

  /// Completes when all pending replanning is done (used by tests).
  Future<void> get idle async {
    Future<void>? seen;
    while (!identical(seen, _pending)) {
      seen = _pending;
      await Future<void>.delayed(Duration.zero);
      await seen;
    }
  }

  /// Runs one replanning after the previous one, never in parallel.
  void _requestSync() {
    _pending = _pending.then((_) => _sync());
  }

  Future<void> _sync() async {
    final reminder = settings.reminder;
    if (!reminder.enabled) {
      await scheduler.replaceAll(const []);
      return;
    }
    final planned = plannedPlantReminders(
      _plants,
      now: clock(),
      time: reminder.time,
    );
    if (planned.isNotEmpty && !_permissionAsked) {
      _permissionAsked = true;
      await scheduler.requestPermission();
    }
    final l10n = localizations();
    await scheduler.replaceAll([
      for (final (index, reminder) in planned.indexed)
        ScheduledNotification(
          id: index + 1,
          at: reminder.at,
          title: reminder.plant.name,
          body: l10n.reminderDueToday(
            reminder.kinds.map((kind) => careVerb(l10n, kind)).join(', '),
          ),
          actions: [
            for (final kind in reminder.kinds.take(3))
              NotificationAction(
                id: careActionId(reminder.plant.id, kind),
                label: careDoneLabel(l10n, kind),
              ),
          ],
        ),
    ]);
  }
}

/// "Water today: Monstera, Pothos" for watering only, otherwise the kinds
/// separately, e.g. "Water: Monstera · Fertilize: Pothos".
String reminderText(AppLocalizations l10n, PlannedReminder reminder) {
  if (reminder.fertilize.isEmpty &&
      reminder.repot.isEmpty &&
      reminder.prune.isEmpty) {
    return l10n.reminderBody(reminder.plantNames.join(', '));
  }
  return [
    if (reminder.plantNames.isNotEmpty)
      l10n.reminderWater(reminder.plantNames.join(', ')),
    if (reminder.fertilize.isNotEmpty)
      l10n.reminderFertilize(reminder.fertilize.join(', ')),
    if (reminder.repot.isNotEmpty)
      l10n.reminderRepot(reminder.repot.join(', ')),
    if (reminder.prune.isNotEmpty)
      l10n.reminderPrune(reminder.prune.join(', ')),
  ].join(' · ');
}

/// The task, e.g. "Water".
String careVerb(AppLocalizations l10n, CareKind kind) => switch (kind) {
  Water() => l10n.careVerbWater,
  Fertilize() => l10n.careVerbFertilize,
  Repot() => l10n.careVerbRepot,
  Prune() => l10n.careVerbPrune,
};

/// The task as done, e.g. "Watered" (also the notification button).
String careDoneLabel(AppLocalizations l10n, CareKind kind) => switch (kind) {
  Water() => l10n.watered,
  Fertilize() => l10n.fertilized,
  Repot() => l10n.repotted,
  Prune() => l10n.pruned,
};

/// The texts for the language chosen in the settings (or the device
/// language), for use outside of widgets.
AppLocalizations appLocalizationsFor(SettingsController settings) {
  final locale = switch (settings.language) {
    AppLanguage.system => resolveLocale(
      PlatformDispatcher.instance.locales,
      AppLocalizations.supportedLocales,
    ),
    AppLanguage.english => const Locale('en'),
    AppLanguage.german => const Locale('de'),
  };
  return lookupAppLocalizations(locale);
}
