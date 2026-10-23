import 'package:intl/intl.dart';

import '../domain/sitter_plan.dart';
import '../domain/vacation.dart';
import '../l10n/app_localizations.dart';
import 'reminder_sync.dart';

/// The sitter plan as plain text for the share sheet, e.g.
/// "Wed, Oct 21 / • Monstera (Living room): Water, Fertilize".
String sitterPlanText(
  AppLocalizations l10n,
  String locale,
  Vacation vacation,
  List<SitterDay> plan,
) {
  final period = DateFormat.yMMMd(locale);
  final day = DateFormat.MMMEd(locale);
  final buffer = StringBuffer()
    ..writeln(
      l10n.sitterPlanTitle(
        period.format(vacation.first),
        period.format(vacation.last),
      ),
    );
  if (plan.isEmpty) {
    buffer
      ..writeln()
      ..writeln(l10n.sitterPlanEmpty);
  }
  for (final entry in plan) {
    buffer
      ..writeln()
      ..writeln(day.format(entry.day));
    for (final plant in entry.entries) {
      final name = switch (plant.location) {
        final location? => '${plant.plantName} ($location)',
        null => plant.plantName,
      };
      final tasks = plant.kinds.map((kind) => careVerb(l10n, kind)).join(', ');
      buffer.writeln('• $name: $tasks');
    }
  }
  return buffer.toString();
}
