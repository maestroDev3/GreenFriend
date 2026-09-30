import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/care_log.dart';
import '../domain/care_log_repository.dart';
import '../domain/care_status.dart';
import '../domain/care_tasks.dart';
import '../domain/clock.dart';
import '../domain/plant.dart';
import '../domain/plant_repository.dart';
import '../l10n/app_localizations.dart';
import 'watering_actions.dart';
import 'widgets/watering_label.dart';

/// What is due when: a strip of the next two weeks and the tasks of the
/// selected day and the days after it.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.plants,
    required this.careLogs,
    this.clock = DateTime.now,
  });

  final PlantRepository plants;
  final CareLogRepository careLogs;
  final Clock clock;

  static const stripDays = 14;
  static const listDays = 7;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final Stream<List<Plant>> _plants = widget.plants.watchPlants();
  late DateTime _selected = dayOf(widget.clock());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = dayOf(widget.clock());
    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarTitle)),
      body: StreamBuilder<List<Plant>>(
        stream: _plants,
        builder: (context, snapshot) {
          final tasks = careTasksBetween(
            snapshot.data ?? const [],
            from: today,
            to: today.add(
              const Duration(
                days: CalendarScreen.stripDays + CalendarScreen.listDays,
              ),
            ),
            today: today,
          );
          final taskDays = {for (final task in tasks) task.day};
          return Column(
            children: [
              _DayStrip(
                today: today,
                selected: _selected,
                taskDays: taskDays,
                onSelect: (day) => setState(() => _selected = day),
              ),
              Expanded(
                child: _TaskList(
                  today: today,
                  selected: _selected,
                  tasks: tasks,
                  onDone: (task) => careWithUndo(
                    context,
                    plants: widget.plants,
                    careLogs: widget.careLogs,
                    plant: task.plant,
                    kind: task.kind,
                    today: widget.clock(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _isoDay(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.today,
    required this.selected,
    required this.taskDays,
    required this.onSelect,
  });

  final DateTime today;
  final DateTime selected;
  final Set<DateTime> taskDays;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: CalendarScreen.stripDays,
        itemBuilder: (context, index) {
          final day = today.add(Duration(days: index));
          return _DayChip(
            day: day,
            selected: day == selected,
            hasTasks: taskDays.contains(day),
            onTap: () => onSelect(day),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.hasTasks,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool hasTasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: InkWell(
        key: ValueKey('day-${_isoDay(day)}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 52,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat.E(locale).format(day),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                ),
              ),
              Text(
                DateFormat.d(locale).format(day),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                ),
              ),
              const SizedBox(height: 4),
              if (hasTasks)
                Container(
                  key: ValueKey('marker-${_isoDay(day)}'),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? scheme.onPrimary : scheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.today,
    required this.selected,
    required this.tasks,
    required this.onDone,
  });

  final DateTime today;
  final DateTime selected;
  final List<CareTask> tasks;
  final ValueChanged<CareTask> onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = [
      for (var i = 0; i < CalendarScreen.listDays; i++)
        selected.add(Duration(days: i)),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final day in days)
          if (tasks.where((task) => task.day == day).toList()
              case final dayTasks when dayTasks.isNotEmpty || day == selected)
            ...[
              _DayHeader(day: day, today: today),
              if (dayTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(l10n.nothingToDo),
                ),
              for (final task in dayTasks)
                _TaskCard(
                  task: task,
                  onDone: task.day == today ? () => onDone(task) : null,
                ),
              const SizedBox(height: 8),
            ],
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.today});

  final DateTime day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final offset = day.difference(today).inDays;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        switch (offset) {
          0 => l10n.today,
          1 => l10n.tomorrow,
          _ => DateFormat.MMMEd(locale).format(day),
        },
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onDone});

  final CareTask task;

  /// `null` for tasks that are not due today.
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final plant = task.plant;
    final (title, interval, icon) = switch (task.kind) {
      Water() => (
        l10n.careTaskWater(plant.name),
        l10n.wateringEvery(plant.wateringIntervalDays ?? 0),
        Icons.water_drop_outlined,
      ),
      Fertilize() => (
        l10n.careTaskFertilize(plant.name),
        l10n.wateringEvery(plant.fertilizingIntervalDays ?? 0),
        Icons.science_outlined,
      ),
      Repot() => (
        l10n.careTaskRepot(plant.name),
        l10n.everyMonths(plant.repottingIntervalMonths ?? 0),
        Icons.yard_outlined,
      ),
    };
    final details = [
      interval,
      ?plant.location,
      if (task.overdueDays > 0)
        careStatusText(l10n, task.kind, Overdue(task.overdueDays)),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.secondaryContainer,
            foregroundColor: scheme.onSecondaryContainer,
            child: Icon(icon),
          ),
          title: Text(title),
          subtitle: Text(details),
          trailing: onDone == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: l10n.markDone,
                  onPressed: onDone,
                ),
        ),
      ),
    );
  }
}
