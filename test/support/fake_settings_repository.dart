import 'package:green_friend/domain/settings.dart';

/// In-memory [SettingsRepository] for tests.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.system,
  });

  AppThemeMode themeMode;
  AppLanguage language;

  @override
  Future<AppThemeMode> loadThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async => themeMode = mode;

  @override
  Future<AppLanguage> loadLanguage() async => language;

  @override
  Future<void> saveLanguage(AppLanguage value) async => language = value;
}
