/// How the app chooses between light and dark colors.
enum AppThemeMode { system, light, dark }

/// Stores the user's app settings, so they survive an app restart.
abstract interface class SettingsRepository {
  Future<AppThemeMode> loadThemeMode();

  Future<void> saveThemeMode(AppThemeMode mode);
}
