import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/domain/plant.dart';
import 'package:green_friend/ui/onboarding.dart';
import 'package:green_friend/ui/settings_controller.dart';

import '../support/fake_plant_repository.dart';
import '../support/fake_settings_repository.dart';

Future<(SettingsController, FakeSettingsRepository)> fresh() async {
  final repository = FakeSettingsRepository(onboardingDone: false);
  final settings = SettingsController(repository);
  await settings.load();
  return (settings, repository);
}

void main() {
  group('skipOnboardingForExistingUsers', () {
    test('with existing plants the introduction counts as done', () async {
      final (settings, repository) = await fresh();

      await skipOnboardingForExistingUsers(
        settings,
        FakePlantRepository([Plant(id: '1', name: 'Monstera')]),
      );

      expect(settings.onboardingDone, isTrue);
      expect(repository.onboardingDone, isTrue);
    });

    test('without plants the introduction stays open', () async {
      final (settings, repository) = await fresh();

      await skipOnboardingForExistingUsers(settings, FakePlantRepository());

      expect(settings.onboardingDone, isFalse);
      expect(repository.onboardingDone, isFalse);
    });

    test('finishOnboarding stores the flag', () async {
      final (settings, repository) = await fresh();

      await settings.finishOnboarding();

      expect(settings.onboardingDone, isTrue);
      expect(repository.onboardingDone, isTrue);
    });
  });
}
