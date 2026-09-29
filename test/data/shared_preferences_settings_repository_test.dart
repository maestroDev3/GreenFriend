import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/shared_preferences_settings_repository.dart';
import 'package:green_friend/domain/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferencesSettingsRepository> repository() async =>
    SharedPreferencesSettingsRepository(await SharedPreferences.getInstance());

void main() {
  group('SharedPreferencesSettingsRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('returns System without a stored theme mode', () async {
      expect(await (await repository()).loadThemeMode(), AppThemeMode.system);
    });

    test('stores and reads the theme mode', () async {
      await (await repository()).saveThemeMode(AppThemeMode.dark);

      expect(await (await repository()).loadThemeMode(), AppThemeMode.dark);
    });

    test('falls back to System for an unknown stored value', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesSettingsRepository.themeModeKey: 'purple',
      });

      expect(await (await repository()).loadThemeMode(), AppThemeMode.system);
    });

    test('returns System without a stored language', () async {
      expect(await (await repository()).loadLanguage(), AppLanguage.system);
    });

    test('stores and reads the language', () async {
      await (await repository()).saveLanguage(AppLanguage.german);

      expect(await (await repository()).loadLanguage(), AppLanguage.german);
    });

    test('falls back to System for an unknown stored language', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesSettingsRepository.languageKey: 'klingon',
      });

      expect(await (await repository()).loadLanguage(), AppLanguage.system);
    });
  });
}
