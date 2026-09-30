import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../domain/watering.dart';
import '../l10n/app_localizations.dart';
import 'plant_form_screen.dart';
import 'widgets/watering_label.dart';

/// Everything about one plant: its details, its watering and when it needs
/// water next.
class PlantDetailScreen extends StatefulWidget {
  const PlantDetailScreen({
    super.key,
    required this.plants,
    required this.plantId,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
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

  Future<void> _edit(Plant plant) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlantFormScreen(
          plants: widget.plants,
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
                  status: wateringStatus(plant, widget.clock()),
                ),
        );
      },
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.plant, required this.status});

  final Plant plant;
  final WateringStatus status;

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
                ],
              ),
            ),
          ),
        ],
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
