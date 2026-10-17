import 'dart:async';

import '../domain/care_widget.dart';
import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../l10n/app_localizations.dart';
import 'reminder_sync.dart';
import 'settings_controller.dart';

/// Keeps the home-screen widget in line with today's care; updates whenever
/// a plant or a setting (e.g. the language) changes.
class WidgetSync {
  WidgetSync({
    required this.plants,
    required this.settings,
    required this.widget,
    AppLocalizations Function()? localizations,
    this.clock = DateTime.now,
  }) : localizations = localizations ?? (() => appLocalizationsFor(settings));

  final PlantRepository plants;
  final SettingsController settings;
  final CareWidget widget;

  /// Texts in the app's current language.
  final AppLocalizations Function() localizations;
  final Clock clock;

  StreamSubscription<List<Plant>>? _subscription;
  List<Plant> _plants = const [];
  Future<void> _pending = Future.value();

  void start() {
    _subscription = plants.watchPlants().listen((plants) {
      _plants = plants;
      _enqueue();
    });
    settings.addListener(_enqueue);
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    settings.removeListener(_enqueue);
  }

  /// Completes when all pending updates are done (used by tests).
  Future<void> get idle async {
    Future<void>? seen;
    while (!identical(seen, _pending)) {
      seen = _pending;
      await Future<void>.delayed(Duration.zero);
      await seen;
    }
  }

  /// Updates once with [plants] (used outside the running app).
  Future<void> syncNow(List<Plant> plants) {
    _plants = plants;
    _enqueue();
    return _pending;
  }

  void _enqueue() {
    _pending = _pending.then((_) async {
      try {
        await _show();
      } on Object {
        // A missing widget host must not break the app.
      }
    });
  }

  Future<void> _show() {
    final l10n = localizations();
    final today = dayOf(clock());
    return widget.show(
      CareWidgetContent(
        title: l10n.widgetTitle,
        emptyText: l10n.widgetAllHappy,
        staleText: l10n.widgetOpenToRefresh,
        day: today,
        lines: [
          for (final row in careWidgetRows(_plants, today: today))
            CareWidgetLine(
              plantId: row.plantId,
              name: row.plantName,
              tasks: row.kinds.map((kind) => careVerb(l10n, kind)).join(', '),
              kinds: row.kinds,
            ),
        ],
      ),
    );
  }
}
