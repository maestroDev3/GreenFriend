import 'dart:math';

import 'package:home_widget/home_widget.dart';

import '../domain/care_widget.dart';

/// Data keys shared with `CareWidgetProvider.kt`, which draws the widget.
abstract final class CareWidgetKeys {
  static const title = 'care_title';
  static const empty = 'care_empty';
  static const stale = 'care_stale';
  static const day = 'care_day';
  static const count = 'care_count';
  static const rowPrefix = 'care_row_';

  /// The widget has room for this many plants.
  static const maxRows = 5;

  static const androidProvider =
      'de.maestrodev.green_friend.CareWidgetProvider';

  static String name(int row) => '$rowPrefix${row}_name';

  static String tasks(int row) => '$rowPrefix${row}_tasks';

  static String uri(int row) => '$rowPrefix${row}_uri';
}

/// The Android home-screen widget through `home_widget`: saves the content
/// as key-value data and asks the widget to redraw.
class HomeCareWidget implements CareWidget {
  @override
  Future<void> show(CareWidgetContent content) async {
    final rows = min(content.lines.length, CareWidgetKeys.maxRows);
    final day = content.day.toIso8601String().substring(0, 10);
    await HomeWidget.saveWidgetData<String>(
      CareWidgetKeys.title,
      content.title,
    );
    await HomeWidget.saveWidgetData<String>(
      CareWidgetKeys.empty,
      content.emptyText,
    );
    await HomeWidget.saveWidgetData<String>(
      CareWidgetKeys.stale,
      content.staleText,
    );
    await HomeWidget.saveWidgetData<String>(CareWidgetKeys.day, day);
    await HomeWidget.saveWidgetData<int>(CareWidgetKeys.count, rows);
    for (var row = 0; row < rows; row++) {
      final line = content.lines[row];
      await HomeWidget.saveWidgetData<String>(
        CareWidgetKeys.name(row),
        line.name,
      );
      await HomeWidget.saveWidgetData<String>(
        CareWidgetKeys.tasks(row),
        line.tasks,
      );
      await HomeWidget.saveWidgetData<String>(
        CareWidgetKeys.uri(row),
        careWidgetUri(line.plantId, line.kinds).toString(),
      );
    }
    await HomeWidget.updateWidget(
      qualifiedAndroidName: CareWidgetKeys.androidProvider,
    );
  }
}
