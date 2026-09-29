/// How the app chooses between light and dark colors.
enum AppThemeMode { system, light, dark }

/// Which language the app uses; [system] follows the device language.
enum AppLanguage { system, english, german }

/// Stores the user's app settings, so they survive an app restart.
abstract interface class SettingsRepository {
  Future<AppThemeMode> loadThemeMode();

  Future<void> saveThemeMode(AppThemeMode mode);

  Future<AppLanguage> loadLanguage();

  Future<void> saveLanguage(AppLanguage language);
}
