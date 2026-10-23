import '../domain/plant_repository.dart';
import 'settings_controller.dart';

/// People who used the app before the introduction existed already have
/// plants; for them the introduction counts as done.
Future<void> skipOnboardingForExistingUsers(
  SettingsController settings,
  PlantRepository plants,
) async {
  if (settings.onboardingDone) return;
  if ((await plants.allPlants()).isNotEmpty) await settings.finishOnboarding();
}
