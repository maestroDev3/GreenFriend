import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/calendar.dart';
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

/// What is due when: a strip of the next two weeks or a month grid, and the
/// tasks of the selected day and the days after it.
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

enum _CalendarView { week, month }

class _CalendarScreenState extends State<CalendarScreen> {
  late final Stream<List<Plant>> _plants = widget.plants.watchPlants();
  late DateTime _selected = dayOf(widget.clock());
  late DateTime _month = DateTime.utc(_selected.year, _selected.month);
  var _view = _CalendarView.week;

  void _showMonth(int offset) =>
      setState(() => _month = DateTime.utc(_month.year, _month.month + offset));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = dayOf(widget.clock());
    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarTitle)),
      body: StreamBuilder<List<Plant>>(
        stream: _plants,
        builder: (context, snapshot) {
          final plants = snapshot.data ?? const <Plant>[];
          final stripEnd = today.add(
            const Duration(
              days: CalendarScreen.stripDays + CalendarScreen.listDays,
            ),
          );
          final listEnd = _selected.add(
            const Duration(days: CalendarScreen.listDays),
          );
          final tasks = careTasksBetween(
            plants,
            from: today,
            to: listEnd.isAfter(stripEnd) ? listEnd : stripEnd,
            today: today,
          );
          final taskDays = {for (final task in tasks) task.day};
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SegmentedButton<_CalendarView>(
                  segments: [
                    ButtonSegment(
                      value: _CalendarView.week,
                      label: Text(l10n.calendarWeek),
                    ),
                    ButtonSegment(
                      value: _CalendarView.month,
                      label: Text(l10n.calendarMonth),
                    ),
                  ],
                  selected: {_view},
                  showSelectedIcon: false,
                  onSelectionChanged: (views) =>
                      setState(() => _view = views.single),
                ),
              ),
              switch (_view) {
                _CalendarView.week => _DayStrip(
                  today: today,
                  selected: _selected,
                  taskDays: taskDays,
                  onSelect: (day) => setState(() => _selected = day),
                ),
                _CalendarView.month => _MonthView(
                  month: _month,
                  today: today,
                  selected: _selected,
                  counts: careTaskCountsByDay(
                    plants,
                    month: _month,
                    today: today,
                  ),
                  onSelect: (day) => setState(() => _selected = day),
                  onPrevious: () => _showMonth(-1),
                  onNext: () => _showMonth(1),
                ),
              },
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
                style: theme.textTheme.labelMedium?.copyWith(color: foreground),
              ),
              Text(
                DateFormat.d(locale).format(day),
                style: theme.textTheme.titleMedium?.copyWith(color: foreground),
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

/// A month as a grid of days with markers on days that have care tasks.
class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.month,
    required this.today,
    required this.selected,
    required this.counts,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final Map<DateTime, int> counts;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final firstIndex = material.firstDayOfWeekIndex; // 0 = Sunday
    final weeks = monthGrid(
      month,
      firstWeekday: firstIndex == 0 ? DateTime.sunday : firstIndex,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: l10n.previousMonth,
                onPressed: onPrevious,
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(locale).format(month),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: l10n.nextMonth,
                onPressed: onNext,
              ),
            ],
          ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    material.narrowWeekdays[(firstIndex + i) % 7],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
            ],
          ),
          for (final week in weeks)
            Row(
              children: [
                for (final day in week)
                  Expanded(
                    child: day == null
                        ? const SizedBox(height: 44)
                        : _MonthDay(
                            day: day,
                            today: day == today,
                            selected: day == selected,
                            hasTasks: (counts[day] ?? 0) > 0,
                            onTap: () => onSelect(day),
                          ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MonthDay extends StatelessWidget {
  const _MonthDay({
    required this.day,
    required this.today,
    required this.selected,
    required this.hasTasks,
    required this.onTap,
  });

  final DateTime day;
  final bool today;
  final bool selected;
  final bool hasTasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    return InkWell(
      key: ValueKey('month-day-${_isoDay(day)}'),
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? scheme.primary : null,
              border: today && !selected
                  ? Border.all(color: scheme.primary)
                  : null,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
                if (hasTasks)
                  Container(
                    key: ValueKey('month-marker-${_isoDay(day)}'),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: selected ? scheme.onPrimary : scheme.tertiary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 5),
              ],
            ),
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
              case final dayTasks
              when dayTasks.isNotEmpty || day == selected) ...[
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
      child: Text(switch (offset) {
        0 => l10n.today,
        1 => l10n.tomorrow,
        _ => DateFormat.MMMEd(locale).format(day),
      }, style: Theme.of(context).textTheme.titleMedium),
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
