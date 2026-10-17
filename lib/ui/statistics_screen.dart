import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/care_statistics.dart';
import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../l10n/app_localizations.dart';

/// Care streaks, care per month and the most cared-for plant, to keep the
/// user motivated.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.plants,
    required this.careLogs,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;
  final Clock clock;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final Future<(List<Plant>, List<CareLog>)> _data = (
    widget.plants.allPlants(),
    widget.careLogs.allLogs(),
  ).wait;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statisticsTitle)),
      body: FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) return const SizedBox.shrink();
          final (plants, logs) = data;
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.statisticsEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }
          final today = widget.clock();
          final streak = careStreak(plants, logs, today: today);
          final most = mostCaredPlant(plants, logs, today: today);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StreakCard(
                      label: l10n.currentStreak,
                      days: streak.current,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StreakCard(
                      label: l10n.bestStreak,
                      days: streak.best,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MonthChart(counts: careCountsByMonth(logs, today: today)),
              if (most != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite_outline),
                    title: Text(l10n.mostCaredFor(most.plant.name, most.count)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.label, required this.days});

  final String label;
  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.labelLarge),
            const SizedBox(height: 8),
            Text(l10n.dayCount(days), style: text.headlineSmall),
          ],
        ),
      ),
    );
  }
}

/// Twelve bars, one per month, in the theme's primary colour.
class _MonthChart extends StatelessWidget {
  const _MonthChart({required this.counts});

  static const _maxBarHeight = 120.0;

  final List<({int year, int month, int count})> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final initial = DateFormat('MMMMM', locale);
    final name = DateFormat.yMMM(locale);
    final highest = counts.fold(
      1,
      (max, entry) => entry.count > max ? entry.count : max,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.carePerMonth, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final entry in counts)
                  Expanded(
                    child: Semantics(
                      label: l10n.monthCareCount(
                        name.format(DateTime(entry.year, entry.month)),
                        entry.count,
                      ),
                      child: Column(
                        children: [
                          Container(
                            key: ValueKey(
                              'month-bar-${entry.year}-'
                              '${entry.month.toString().padLeft(2, '0')}',
                            ),
                            height: 4 + _maxBarHeight * entry.count / highest,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: entry.count == 0
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            initial.format(DateTime(entry.year, entry.month)),
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
