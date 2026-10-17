import 'package:flutter/widgets.dart';

import '../domain/care_actions.dart';
import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/clock.dart';
import '../domain/frost.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../domain/species.dart';
import '../domain/weather.dart';
import 'settings_controller.dart';

/// Fetches the weather for outdoor plants when the app starts or comes back:
/// records rain as watering and keeps today's hint for the home screen.
class WeatherSync extends ChangeNotifier {
  WeatherSync({
    required this.plants,
    required this.careLogs,
    required this.settings,
    required this.service,
    this.species,
    this.clock = DateTime.now,
    this.minInterval = const Duration(hours: 3),
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;
  final SettingsController settings;
  final WeatherService service;

  /// Supplies the tolerated minimum of a plant's species for frost warnings.
  final SpeciesCatalog? species;
  final Clock clock;

  /// The weather is fetched at most this often for the same place.
  final Duration minInterval;

  WeatherHint? _hint;
  DateTime? _fetchedAt;
  WeatherLocation? _fetchedFor;

  /// Today's rain or heat hint, if any.
  WeatherHint? get hint => _hint;

  /// Fetches the weather if there is a place and an outdoor plant, unless it
  /// was fetched for the same place less than [minInterval] ago. Errors leave
  /// everything as it was.
  Future<void> refresh() async {
    final location = settings.weatherLocation;
    final all = await plants.allPlants();
    if (location == null || !all.any((plant) => plant.outdoor)) {
      _setHint(null);
      await settings.setFrostWarnings(const []);
      return;
    }
    final now = clock();
    final fetched = _fetchedAt;
    if (location == _fetchedFor &&
        fetched != null &&
        now.difference(fetched) < minInterval) {
      return;
    }
    final List<DailyWeather> weather;
    try {
      weather = await service.dailyWeather(location);
    } on WeatherUnavailable {
      return;
    }
    _fetchedAt = now;
    _fetchedFor = location;
    for (final (:plant, :day) in rainWaterings(
      all,
      weather: weather,
      today: now,
    )) {
      await confirmCare(
        plants: plants,
        careLogs: careLogs,
        plant: plant,
        kind: const Water(),
        today: dayOf(day),
      );
    }
    _setHint(weatherHint(weather, today: now));
    await settings.setFrostWarnings(
      frostWarnings(all, weather: weather, tolerance: _tolerance, today: now),
    );
  }

  int _tolerance(Plant plant) => toleratedMinimum(
    plant,
    switch (plant.speciesId) {
      final id? => species?.byId(id),
      null => null,
    },
  );

  void _setHint(WeatherHint? hint) {
    if (hint == _hint) return;
    _hint = hint;
    notifyListeners();
  }
}

/// Makes the [WeatherSync] available to the settings screen; without it the
/// weather section is hidden.
class WeatherScope extends InheritedWidget {
  const WeatherScope({super.key, required this.sync, required super.child});

  final WeatherSync sync;

  static WeatherSync? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WeatherScope>()?.sync;

  @override
  bool updateShouldNotify(WeatherScope oldWidget) => sync != oldWidget.sync;
}
