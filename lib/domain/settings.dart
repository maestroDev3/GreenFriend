import 'reminders.dart';

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

  Future<ReminderSettings> loadReminder();

  Future<void> saveReminder(ReminderSettings reminder);

  /// The user's own plant.id API key, or `null` if none is stored.
  Future<String?> loadPlantIdApiKey();

  /// Stores [key] trimmed; `null` or a blank key removes it.
  Future<void> savePlantIdApiKey(String? key);
}

/// Trims an API key typed by the user; blank means no key.
String? normalizedApiKey(String? key) {
  final trimmed = key?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
