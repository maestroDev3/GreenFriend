import 'care_log.dart';
import 'care_status.dart';
import 'clock.dart';
import 'plant.dart';
import 'urgency.dart';

/// A plant with care due today, as listed in the home-screen widget.
class CareWidgetRow {
  const CareWidgetRow({
    required this.plantId,
    required this.plantName,
    required this.kinds,
  });

  final String plantId;
  final String plantName;

  /// Care due or overdue today, in the order of [CareKind.values].
  final List<CareKind> kinds;

  @override
  bool operator ==(Object other) =>
      other is CareWidgetRow &&
      other.plantId == plantId &&
      other.plantName == plantName &&
      other.kinds.length == kinds.length &&
      Iterable.generate(kinds.length).every((i) => other.kinds[i] == kinds[i]);

  @override
  int get hashCode => Object.hash(plantId, plantName, Object.hashAll(kinds));

  @override
  String toString() => 'CareWidgetRow($plantName, $kinds)';
}

/// The plants needing care today (due or overdue), most urgent first.
List<CareWidgetRow> careWidgetRows(
  Iterable<Plant> plants, {
  required DateTime today,
}) {
  final day = dayOf(today);
  return [
    for (final plant in sortedByUrgency(plants, day))
      if ([
            for (final kind in CareKind.values)
              if (careStatus(plant, kind, day) case DueToday() || Overdue())
                kind,
          ]
          case final kinds when kinds.isNotEmpty)
        CareWidgetRow(plantId: plant.id, plantName: plant.name, kinds: kinds),
  ];
}

/// One line of the widget with its texts already in the app language.
class CareWidgetLine {
  const CareWidgetLine({
    required this.plantId,
    required this.name,
    required this.tasks,
    required this.kinds,
  });

  final String plantId;
  final String name;

  /// E.g. "Water, Fertilize".
  final String tasks;
  final List<CareKind> kinds;
}

/// What the home-screen widget shows.
class CareWidgetContent {
  const CareWidgetContent({
    required this.title,
    required this.emptyText,
    required this.staleText,
    required this.day,
    required this.lines,
  });

  final String title;

  /// Shown when [lines] is empty.
  final String emptyText;

  /// Shown when the widget is looked at on a later day than [day].
  final String staleText;

  /// Calendar day (UTC midnight) the content is for.
  final DateTime day;
  final List<CareWidgetLine> lines;
}

/// The home-screen widget of the platform.
abstract interface class CareWidget {
  Future<void> show(CareWidgetContent content);
}
