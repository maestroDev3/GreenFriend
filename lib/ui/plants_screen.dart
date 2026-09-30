import 'package:flutter/material.dart';

import '../domain/care_log_repository.dart';
import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../l10n/app_localizations.dart';
import 'plant_detail_screen.dart';

/// All plants in alphabetical order.
class PlantsScreen extends StatefulWidget {
  const PlantsScreen({
    super.key,
    required this.plants,
    required this.careLogs,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;
  final Clock clock;

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  late final Stream<List<Plant>> _plants = widget.plants.watchPlants();

  void _open(Plant plant) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlantDetailScreen(
          plants: widget.plants,
          careLogs: widget.careLogs,
          plantId: plant.id,
          clock: widget.clock,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myPlants)),
      body: StreamBuilder<List<Plant>>(
        stream: _plants,
        builder: (context, snapshot) => switch (snapshot.data) {
          null => const SizedBox.shrink(),
          [] => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.emptyPlantsHint, textAlign: TextAlign.center),
            ),
          ),
          final plants => _PlantList(sortedByName(plants), onOpen: _open),
        },
      ),
    );
  }
}

class _PlantList extends StatelessWidget {
  const _PlantList(this.plants, {required this.onOpen});

  final List<Plant> plants;
  final ValueChanged<Plant> onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];
        final details = [?plant.species, ?plant.location].join(' · ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.secondaryContainer,
                foregroundColor: scheme.onSecondaryContainer,
                child: const Icon(Icons.eco_outlined),
              ),
              title: Text(plant.name),
              subtitle: details.isEmpty ? null : Text(details),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpen(plant),
            ),
          ),
        );
      },
    );
  }
}
