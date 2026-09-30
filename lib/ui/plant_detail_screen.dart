import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../domain/care_status.dart';
import '../l10n/app_localizations.dart';
import 'plant_form_screen.dart';
import 'watering_actions.dart';
import 'widgets/watering_label.dart';

/// Everything about one plant: its details, its watering and when it needs
/// water next.
class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({
    super.key,
    required this.plants,
    required this.careLogs,
    required this.plantId,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;
  final String plantId;

  /// Supplies today's date for the next watering.
  final Clock clock;

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late final Stream<Plant?> _plant = widget.plants.watchPlants().map(
    (plants) => plants.where((plant) => plant.id == widget.plantId).firstOrNull,
  );
  late final Stream<List<CareLog>> _logs = widget.careLogs.watchLogs(
    widget.plantId,
  );

  Future<void> _edit(Plant plant) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlantFormScreen(
          plants: widget.plants,
          careLogs: widget.careLogs,
          plant: plant,
          clock: widget.clock,
        ),
      ),
    );
    if (deleted != true || !mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<Plant?>(
      stream: _plant,
      builder: (context, snapshot) {
        final plant = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (plant != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.editPlantTitle,
                  onPressed: () => _edit(plant),
                ),
            ],
          ),
          body: plant == null
              ? const SizedBox.shrink()
              : _Details(
                  plant: plant,
                  history: StreamBuilder<List<CareLog>>(
                    stream: _logs,
                    builder: (context, snapshot) =>
                        _History(snapshot.data ?? const []),
                  ),
                  status: wateringStatus(plant, widget.clock()),
                  onWatered: () => waterWithUndo(
                    context,
                    plants: widget.plants,
                    careLogs: widget.careLogs,
                    plant: plant,
                    today: widget.clock(),
                  ),
                ),
        );
      },
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.plant,
    required this.status,
    required this.onWatered,
    required this.history,
  });

  final Plant plant;
  final CareStatus status;
  final VoidCallback onWatered;
  final Widget history;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const _Header(),
        const SizedBox(height: 20),
        Text(plant.name, style: text.headlineMedium),
        if (plant.species case final species?)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              species,
              style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        if (plant.location case final location?)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(location, style: text.bodyMedium)),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _CareTile(
          icon: Icons.water_drop_outlined,
          title: l10n.wateringTileTitle,
          value: switch (plant.wateringIntervalDays) {
            final days? => l10n.wateringEvery(days),
            null => l10n.noWateringSchedule,
          },
        ),
        if (status is! NotScheduled) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.nextWatering, style: text.titleMedium),
                  const SizedBox(height: 8),
                  WateringLabel(status),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onWatered,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.watered),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        history,
      ],
    );
  }
}

/// The most recent care, newest first.
class _History extends StatelessWidget {
  const _History(this.logs);

  static const maxEntries = 10;

  final List<CareLog> logs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dates = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.history, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (logs.isEmpty)
          Text(l10n.noCareLogged, style: theme.textTheme.bodyMedium)
        else
          Card(
            child: Column(
              children: [
                for (final log in logs.take(maxEntries))
                  ListTile(
                    leading: Icon(switch (log.kind) {
                      Water() => Icons.water_drop_outlined,
                      Fertilize() => Icons.science_outlined,
                      Repot() => Icons.yard_outlined,
                    }, color: theme.colorScheme.primary),
                    title: Text(dates.format(log.day)),
                    subtitle: Text(switch (log.kind) {
                      Water() => l10n.watered,
                      Fertilize() => l10n.fertilized,
                      Repot() => l10n.repotted,
                    }),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Placeholder until plants have photos.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(
          Icons.eco_outlined,
          size: 96,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _CareTile extends StatelessWidget {
  const _CareTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.labelMedium),
                  Text(value, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
