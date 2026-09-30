import 'package:flutter/material.dart';

import '../../domain/watering.dart';
import '../../l10n/app_localizations.dart';

/// Tells when the plant needs water; overdue and today stand out as pills.
class WateringLabel extends StatelessWidget {
  const WateringLabel(this.status, {super.key});

  final WateringStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      NotScheduled() => const SizedBox.shrink(),
      Overdue(:final days) => StatusPill(
        text: l10n.overdueDays(days),
        icon: Icons.error_outline,
        background: scheme.tertiaryContainer,
        foreground: scheme.onTertiaryContainer,
      ),
      DueToday() => StatusPill(
        text: l10n.waterToday,
        icon: Icons.water_drop_outlined,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ),
      DueIn(:final days) => Row(
        children: [
          Icon(Icons.water_drop_outlined, size: 16, color: scheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.waterInDays(days),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    };
  }
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
