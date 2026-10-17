import 'package:flutter/material.dart';

import '../../domain/care_log.dart';
import '../../l10n/app_localizations.dart';

/// Records [kind] of care: a subdued button with the task ("Water") while it
/// is still to do, and a check with the past tense ("Watered") once it was
/// done today, so the button never looks done before it is.
class CareButton extends StatelessWidget {
  const CareButton({
    super.key,
    required this.kind,
    required this.doneToday,
    required this.onPressed,
  });

  final CareKind kind;
  final bool doneToday;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (doneToday) {
      final done = switch (kind) {
        Water() => l10n.watered,
        Fertilize() => l10n.fertilized,
        Repot() => l10n.repotted,
        Prune() => l10n.pruned,
      };
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 20, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              done,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
              ),
            ),
          ],
        ),
      );
    }
    final (verb, icon) = switch (kind) {
      Water() => (l10n.careVerbWater, Icons.water_drop_outlined),
      Fertilize() => (l10n.careVerbFertilize, Icons.science_outlined),
      Repot() => (l10n.careVerbRepot, Icons.yard_outlined),
      Prune() => (l10n.careVerbPrune, Icons.content_cut),
    };
    return TextButton(
      style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(verb)],
      ),
    );
  }
}

/// Whether [last] (a last-done day) is the same calendar day as [today].
bool isSameDay(DateTime? last, DateTime today) =>
    last != null &&
    last.year == today.year &&
    last.month == today.month &&
    last.day == today.day;
