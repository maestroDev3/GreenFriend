import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/backup_files.dart';
import '../domain/health.dart';
import '../domain/light_check.dart';
import '../domain/timelapse.dart';
import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/journal_repository.dart';
import '../domain/photos.dart';
import '../domain/clock.dart';
import '../domain/frost.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../domain/species.dart';
import '../domain/tips.dart';
import '../domain/weather.dart';
import '../domain/urgency.dart';
import '../domain/care_status.dart';
import '../l10n/app_localizations.dart';
import 'calendar_screen.dart';
import 'frost_texts.dart';
import 'plant_detail_screen.dart';
import 'plant_form_screen.dart';
import 'settings_controller.dart';
import 'weather_sync.dart';
import 'settings_screen.dart';
import 'watering_actions.dart';
import 'widgets/care_button.dart';
import 'widgets/watering_label.dart';

/// The start screen: the user's plants, or a friendly hint while there are
/// none yet.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.plants,
    required this.careLogs,
    required this.journal,
    required this.photos,
    required this.species,
    required this.photoPicker,
    this.fileSharing,
    this.timelapseEncoder,
    this.healthChecker,
    this.lightSensor,
    this.tips,
    this.weather,
    this.clock = DateTime.now,
    this.showActions = true,
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;
  final JournalRepository journal;
  final PhotoStore photos;

  /// The plant database used to suggest species and their care profile.
  final SpeciesCatalog species;
  final PhotoPicker photoPicker;

  /// Used to share a plant's time-lapse; both `null` hide sharing.
  final FileSharing? fileSharing;
  final TimelapseEncoder? timelapseEncoder;

  /// Checks a plant's health on a photo; `null` hides the health check.
  final PlantHealthChecker? healthChecker;

  /// Measures the light at a spot; `null` hides the light check.
  final LightSensor? lightSensor;

  /// Care tips for the "Tip of the day" card; `null` hides the card.
  final TipCatalog? tips;

  /// Today's weather hint for outdoor plants; `null` hides it.
  final WeatherSync? weather;

  /// Own add button, calendar and settings; off inside the app shell, which
  /// has them in its bottom bar.
  final bool showActions;

  /// Supplies today's date for watering defaults and due dates.
  final Clock clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Plant>> _plants = widget.plants.watchPlants();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          if (widget.showActions) ...[
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: l10n.calendarTitle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CalendarScreen(
                    plants: widget.plants,
                    careLogs: widget.careLogs,
                    clock: widget.clock,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: l10n.settingsTitle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: !widget.showActions
          ? null
          : FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add),
              label: Text(l10n.addPlant),
            ),
      body: StreamBuilder<List<Plant>>(
        stream: _plants,
        builder: (context, snapshot) => switch (snapshot.data) {
          null => const SizedBox.shrink(),
          [] => _EmptyHint(l10n.emptyPlantsHint),
          final plants => _PlantOverview(
            plants: plants,
            vacation: _vacationBanner(),
            tip: _tipCard(plants),
            frost: _frostCard(),
            weatherHint: _weatherCard(plants),
            today: widget.clock(),
            onOpen: _openDetail,
            onWatered: _water,
          ),
        },
      ),
    );
  }

  Widget? _vacationBanner() {
    final settings = SettingsScope.of(context);
    final vacation = settings.vacation;
    if (vacation == null || !vacation.covers(widget.clock())) return null;
    return _VacationBanner(
      until: vacation.last,
      onEnd: () => settings.setVacation(null),
    );
  }

  /// The next frost warning from the last weather fetch, if any.
  Widget? _frostCard() {
    final today = dayOf(widget.clock());
    final settings = SettingsScope.of(context);
    if (settings.weatherLocation == null) return null;
    final next = settings.frostWarnings
        .where((warning) => warning.day.isAfter(today))
        .firstOrNull;
    if (next == null) return null;
    return _FrostCard(
      warning: next,
      tonight: next.day == today.add(const Duration(days: 1)),
    );
  }

  Widget? _weatherCard(List<Plant> plants) {
    final weather = widget.weather;
    if (weather == null || !plants.any((plant) => plant.outdoor)) return null;
    return ListenableBuilder(
      listenable: weather,
      builder: (context, _) => switch (weather.hint) {
        null => const SizedBox.shrink(),
        final hint => _WeatherCard(hint),
      },
    );
  }

  Widget? _tipCard(List<Plant> plants) {
    final tips = widget.tips;
    if (tips == null) return null;
    final settings = SettingsScope.of(context);
    final today = dayOf(widget.clock());
    if (settings.tipDismissedOn == today) return null;
    final pick = tipOfTheDay(
      tips.all,
      plants: plants,
      species: widget.species,
      today: today,
    );
    if (pick == null) return null;
    return _TipCard(pick: pick, onDismiss: () => settings.dismissTip(today));
  }

  Future<void> _water(Plant plant) => waterWithUndo(
    context,
    plants: widget.plants,
    careLogs: widget.careLogs,
    plant: plant,
    today: widget.clock(),
  );

  void _openForm() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantFormScreen(
          species: widget.species,
          plants: widget.plants,
          careLogs: widget.careLogs,
          journal: widget.journal,
          photos: widget.photos,
          clock: widget.clock,
        ),
      ),
    );
  }

  void _openDetail(Plant plant) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantDetailScreen(
          species: widget.species,
          plants: widget.plants,
          careLogs: widget.careLogs,
          journal: widget.journal,
          photos: widget.photos,
          photoPicker: widget.photoPicker,
          plantId: plant.id,
          fileSharing: widget.fileSharing,
          timelapseEncoder: widget.timelapseEncoder,
          healthChecker: widget.healthChecker,
          lightSensor: widget.lightSensor,
          clock: widget.clock,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// Greeting, today's summary and all plants, the most urgent first.
class _PlantOverview extends StatelessWidget {
  const _PlantOverview({
    required this.plants,
    required this.vacation,
    required this.tip,
    required this.weatherHint,
    required this.frost,
    required this.today,
    required this.onOpen,
    required this.onWatered,
  });

  final List<Plant> plants;

  /// The tip of the day card, if there is one today.
  /// Banner while the user is on vacation.
  final Widget? vacation;
  final Widget? tip;

  /// The weather hint for outdoor plants, if any.
  final Widget? weatherHint;

  /// The frost warning for outdoor plants, if any.
  final Widget? frost;
  final DateTime today;
  final ValueChanged<Plant> onOpen;
  final ValueChanged<Plant> onWatered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final sorted = sortedByUrgency(plants, today);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList.list(
            children: [
              Text(l10n.greeting, style: text.headlineLarge),
              const SizedBox(height: 4),
              Text(l10n.greetingSubtitle, style: text.bodyLarge),
              const SizedBox(height: 20),
              if (vacation case final banner?) ...[
                banner,
                const SizedBox(height: 12),
              ],
              _SummaryCard(
                l10n.attentionSummary(
                  needingAttention(plants, today),
                  plants.length,
                ),
              ),
              ?frost,
              ?weatherHint,
              if (tip case final tip?) ...[const SizedBox(height: 12), tip],
              const SizedBox(height: 28),
              Text(l10n.myPlants, style: text.titleLarge),
              const SizedBox(height: 12),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          sliver: SliverList.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlantCard(
                sorted[index],
                today: today,
                status: wateringStatus(sorted[index], today),
                otherDue: [
                  for (final kind in const [Fertilize(), Repot(), Prune()])
                    if (careStatus(sorted[index], kind, today) case final status
                        when status is DueToday || status is Overdue)
                      (kind, status),
                ],
                onTap: () => onOpen(sorted[index]),
                onWatered: () => onWatered(sorted[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown while reminders pause for a vacation.
class _VacationBanner extends StatelessWidget {
  const _VacationBanner({required this.until, required this.onEnd});

  final DateTime until;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(until);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              Icons.beach_access_outlined,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.onVacationUntil(date),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            TextButton(onPressed: onEnd, child: Text(l10n.endVacation)),
          ],
        ),
      ),
    );
  }
}

/// Frost in one of the next two nights, naming the plants at risk.
class _FrostCard extends StatelessWidget {
  const _FrostCard({required this.warning, required this.tonight});

  final FrostWarning warning;
  final bool tonight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.ac_unit, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      frostTitle(l10n, warning, tonight: tonight),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      frostPlantsText(l10n, warning),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rain or heat today, for users with outdoor plants.
class _WeatherCard extends StatelessWidget {
  const _WeatherCard(this.hint);

  final WeatherHint hint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (icon, text) = switch (hint) {
      Heat(:final celsius) => (
        Icons.wb_sunny_outlined,
        l10n.weatherHeat(celsius.round()),
      ),
      RainToday(:final mm) => (
        Icons.umbrella_outlined,
        l10n.weatherRain(mm.round()),
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: theme.colorScheme.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short care tip; can be closed until tomorrow.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.pick, required this.onDismiss});

  final TipOfTheDay pick;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final onContainer = theme.colorScheme.onSecondaryContainer;
    final language = Localizations.localeOf(context).languageCode;
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.lightbulb_outline, color: onContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.tipOfTheDay,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: onContainer,
                    ),
                  ),
                  if (pick.plant case final plant?)
                    Text(
                      l10n.tipForPlant(plant.name),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: onContainer,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    pick.tip.text(language),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.dismissTip,
              color: onContainer,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.water_drop_outlined, color: onPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(color: onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlantCard extends StatelessWidget {
  const _PlantCard(
    this.plant, {
    required this.today,
    required this.status,
    required this.otherDue,
    required this.onTap,
    required this.onWatered,
  });

  final Plant plant;
  final DateTime today;
  final CareStatus status;
  final List<(CareKind, CareStatus)> otherDue;
  final VoidCallback onTap;
  final VoidCallback onWatered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
                child: const Icon(Icons.eco_outlined),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PlantTexts(
                  plant,
                  today: today,
                  status: status,
                  otherDue: otherDue,
                  onWatered: onWatered,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantTexts extends StatelessWidget {
  const _PlantTexts(
    this.plant, {
    required this.today,
    required this.status,
    required this.otherDue,
    required this.onWatered,
  });

  final Plant plant;
  final DateTime today;
  final CareStatus status;
  final List<(CareKind, CareStatus)> otherDue;
  final VoidCallback onWatered;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plant.name, style: text.titleMedium),
        if (plant.species case final species?)
          Text(
            species,
            style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
        if (plant.location case final location?)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, size: 16),
                const SizedBox(width: 4),
                Expanded(child: Text(location, style: text.bodySmall)),
              ],
            ),
          ),
        if (status is! NotScheduled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(child: CareLabel(status)),
                CareButton(
                  kind: const Water(),
                  doneToday: isSameDay(plant.lastWateredOn, today),
                  onPressed: onWatered,
                ),
              ],
            ),
          ),
        if (otherDue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (kind, status) in otherDue)
                  CareLabel(status, kind: kind),
              ],
            ),
          ),
      ],
    );
  }
}
