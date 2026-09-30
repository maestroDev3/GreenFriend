import 'package:flutter/material.dart';

import '../../domain/care_log.dart';
import '../../domain/care_status.dart';
import '../../l10n/app_localizations.dart';

/// Tells when [kind] of care is due; overdue and today stand out as pills.
class CareLabel extends StatelessWidget {
  const CareLabel(this.status, {super.key, this.kind = const Water()});

  final CareStatus status;
  final CareKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = careStatusText(l10n, kind, status);
    final icon = switch (kind) {
      Water() => Icons.water_drop_outlined,
      Fertilize() => Icons.science_outlined,
      Repot() => Icons.yard_outlined,
      Prune() => Icons.content_cut,
    };
    return switch (status) {
      NotScheduled() => const SizedBox.shrink(),
      Overdue() => StatusPill(
        text: text,
        icon: Icons.error_outline,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
      DueToday() => StatusPill(
        text: text,
        icon: icon,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      DueIn() => Row(
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    };
  }
}

/// The status text, e.g. "Water in 3 days" or "Repotting overdue by 2
/// months"; repotting and pruning are counted in months from 30 days on.
String careStatusText(AppLocalizations l10n, CareKind kind, CareStatus status) {
  return switch ((kind, status)) {
    (_, NotScheduled()) => '',
    (Water(), DueToday()) => l10n.waterToday,
    (Water(), DueIn(:final days)) => l10n.waterInDays(days),
    (Water(), Overdue(:final days)) => l10n.overdueDays(days),
    (Fertilize(), DueToday()) => l10n.fertilizeToday,
    (Fertilize(), DueIn(:final days)) => l10n.fertilizeInDays(days),
    (Fertilize(), Overdue(:final days)) => l10n.fertilizingOverdueDays(days),
    (Repot(), DueToday()) => l10n.repotToday,
    (Repot(), DueIn(:final days)) =>
      days < 30 ? l10n.repotInDays(days) : l10n.repotInMonths(days ~/ 30),
    (Repot(), Overdue(:final days)) =>
      days < 30
          ? l10n.repottingOverdueDays(days)
          : l10n.repottingOverdueMonths(days ~/ 30),
    (Prune(), DueToday()) => l10n.pruneToday,
    (Prune(), DueIn(:final days)) =>
      days < 30 ? l10n.pruneInDays(days) : l10n.pruneInMonths(days ~/ 30),
    (Prune(), Overdue(:final days)) =>
      days < 30
          ? l10n.pruningOverdueDays(days)
          : l10n.pruningOverdueMonths(days ~/ 30),
  };
}

/// A small rounded label that makes a status stand out.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String text;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
