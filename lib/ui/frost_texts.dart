import '../domain/frost.dart';
import '../l10n/app_localizations.dart';

/// "Frost tonight: down to -2 °C" (or "tomorrow night"); "Cold …" when the
/// minimum stays above zero.
String frostTitle(
  AppLocalizations l10n,
  FrostWarning warning, {
  required bool tonight,
}) {
  final celsius = warning.minTemperature.round();
  final frost = warning.minTemperature < 0;
  return switch ((tonight, frost)) {
    (true, true) => l10n.frostTonight(celsius),
    (false, true) => l10n.frostTomorrowNight(celsius),
    (true, false) => l10n.coldTonight(celsius),
    (false, false) => l10n.coldTomorrowNight(celsius),
  };
}

/// "Bring inside or protect: Lemon, Oleander".
String frostPlantsText(AppLocalizations l10n, FrostWarning warning) =>
    l10n.frostPlants(warning.plantNames.join(', '));
