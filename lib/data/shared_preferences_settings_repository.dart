import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings.dart';

/// Keeps the app settings in the platform's key-value storage.
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._preferences);

  /// Versioned key, so the stored format can change later with a migration.
  static const themeModeKey = 'settings.v1.themeMode';

  final SharedPreferences _preferences;

  @override
  Future<AppThemeMode> loadThemeMode() async {
    final stored = _preferences.getString(themeModeKey);
    return AppThemeMode.values.asNameMap()[stored] ?? AppThemeMode.system;
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    await _preferences.setString(themeModeKey, mode.name);
  }
}
