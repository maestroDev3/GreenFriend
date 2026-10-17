import 'dart:async';

import 'package:flutter/widgets.dart';

import '../domain/clock.dart';
import '../domain/phone_calendar.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../l10n/app_localizations.dart';
import 'reminder_sync.dart';
import 'settings_controller.dart';

/// Keeps the care plan of the next [days] days in the phone calendar the
/// user chose; replans whenever a plant or a setting changes.
class CalendarSync {
  CalendarSync({
    required this.plants,
    required this.settings,
    required this.calendar,
    AppLocalizations Function()? localizations,
    this.clock = DateTime.now,
  }) : localizations = localizations ?? (() => appLocalizationsFor(settings));

  /// How far ahead events are kept in the calendar.
  static const days = 60;

  final PlantRepository plants;
  final SettingsController settings;
  final PhoneCalendar calendar;

  /// Texts in the app's current language.
  final AppLocalizations Function() localizations;
  final Clock clock;

  StreamSubscription<List<Plant>>? _subscription;
  List<Plant> _plants = const [];
  Future<void> _pending = Future.value();

  void start() {
    _subscription = plants.watchPlants().listen((plants) {
      _plants = plants;
      _enqueue(_sync);
    });
    settings.addListener(_onSettings);
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    settings.removeListener(_onSettings);
  }

  /// Completes when all pending work is done (used by tests).
  Future<void> get idle async {
    Future<void>? seen;
    while (!identical(seen, _pending)) {
      seen = _pending;
      await Future<void>.delayed(Duration.zero);
      await seen;
    }
  }

  /// Syncs once with [plants] (used outside the running app).
  Future<void> syncNow(List<Plant> plants) {
    _plants = plants;
    return _enqueue(_sync);
  }

  /// Deletes the upcoming Green Friend events from [calendarId], e.g. when
  /// the user switches the sync off; other events stay untouched.
  Future<void> removeUpcoming(String calendarId) => _enqueue(() async {
    final today = dayOf(clock());
    final existing = await calendar.eventsBetween(
      calendarId,
      from: today,
      to: today.add(const Duration(days: days)),
    );
    final changes = calendarChanges(existing: existing, wanted: const []);
    for (final id in changes.delete) {
      await calendar.delete(id);
    }
  });

  void _onSettings() => _enqueue(_sync);

  /// Runs [work] after the previous work, never in parallel; calendar
  /// errors (e.g. access withdrawn) end that run without crashing the app.
  Future<void> _enqueue(Future<void> Function() work) {
    _pending = _pending.then((_) async {
      try {
        await work();
      } on Object {
        // The next change tries again.
      }
    });
    return _pending;
  }

  Future<void> _sync() async {
    final choice = settings.phoneCalendar;
    if (choice == null) return;
    final today = dayOf(clock());
    final l10n = localizations();
    final wanted = [
      for (final planned in plannedCareDays(_plants, today: today, days: days))
        WantedCalendarEvent(
          day: planned.day,
          title: l10n.calendarEventTitle(
            planned.plant.name,
            planned.kinds.map((kind) => careVerb(l10n, kind)).join(', '),
          ),
          marker: calendarMarker(planned.plant.id, planned.day),
        ),
    ];
    final existing = await calendar.eventsBetween(
      choice.id,
      from: today,
      to: today.add(const Duration(days: days)),
    );
    final changes = calendarChanges(existing: existing, wanted: wanted);
    for (final id in changes.delete) {
      await calendar.delete(id);
    }
    for (final (:eventId, :title) in changes.update) {
      await calendar.updateTitle(eventId, title);
    }
    for (final event in changes.create) {
      await calendar.create(
        choice.id,
        day: event.day,
        title: event.title,
        description: '${l10n.calendarEventNote}\n${event.marker}',
      );
    }
  }
}

/// Makes the [CalendarSync] available to the settings screen; without it
/// the phone calendar option is hidden.
class CalendarScope extends InheritedWidget {
  const CalendarScope({super.key, required this.sync, required super.child});

  final CalendarSync sync;

  static CalendarSync? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CalendarScope>()?.sync;

  @override
  bool updateShouldNotify(CalendarScope oldWidget) => sync != oldWidget.sync;
}
