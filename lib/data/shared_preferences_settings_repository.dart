import 'package:shared_preferences/shared_preferences.dart';

import '../domain/clock.dart';
import '../domain/reminders.dart';
import '../domain/settings.dart';

/// Keeps the app settings in the platform's key-value storage.
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._preferences);

  /// Versioned key, so the stored format can change later with a migration.
  static const themeModeKey = 'settings.v1.themeMode';
  static const languageKey = 'settings.v1.language';
  static const reminderEnabledKey = 'settings.v1.reminderEnabled';
  static const reminderTimeKey = 'settings.v1.reminderTime';

  /// Not part of the backup, so the key never leaves the phone.
  static const plantIdApiKeyKey = 'settings.v1.plantIdApiKey';
  static const tipDismissedOnKey = 'settings.v1.tipDismissedOn';

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

  @override
  Future<AppLanguage> loadLanguage() async {
    final stored = _preferences.getString(languageKey);
    return AppLanguage.values.asNameMap()[stored] ?? AppLanguage.system;
  }

  @override
  Future<void> saveLanguage(AppLanguage language) async {
    await _preferences.setString(languageKey, language.name);
  }

  @override
  Future<ReminderSettings> loadReminder() async {
    return ReminderSettings(
      enabled:
          _preferences.getBool(reminderEnabledKey) ??
          ReminderSettings.defaults.enabled,
      time:
          _parseTime(_preferences.getString(reminderTimeKey)) ??
          ReminderSettings.defaults.time,
    );
  }

  @override
  Future<void> saveReminder(ReminderSettings reminder) async {
    final time = reminder.time;
    await _preferences.setBool(reminderEnabledKey, reminder.enabled);
    await _preferences.setString(
      reminderTimeKey,
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Future<String?> loadPlantIdApiKey() async =>
      normalizedApiKey(_preferences.getString(plantIdApiKeyKey));

  @override
  Future<void> savePlantIdApiKey(String? key) async {
    final normalized = normalizedApiKey(key);
    if (normalized == null) {
      await _preferences.remove(plantIdApiKeyKey);
    } else {
      await _preferences.setString(plantIdApiKeyKey, normalized);
    }
  }

  @override
  Future<DateTime?> loadTipDismissedOn() async {
    final stored = _preferences.getString(tipDismissedOnKey);
    if (stored == null) return null;
    final parsed = DateTime.tryParse(stored);
    return parsed == null ? null : dayOf(parsed);
  }

  @override
  Future<void> saveTipDismissedOn(DateTime day) async {
    final normalized = dayOf(day);
    await _preferences.setString(
      tipDismissedOnKey,
      '${normalized.year.toString().padLeft(4, '0')}-'
      '${normalized.month.toString().padLeft(2, '0')}-'
      '${normalized.day.toString().padLeft(2, '0')}',
    );
  }

  /// Reads "HH:MM"; `null` for missing or invalid values.
  static ReminderTime? _parseTime(String? stored) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(stored ?? '');
    if (match == null) return null;
    try {
      return ReminderTime.checked(
        int.parse(match.group(1) ?? ''),
        int.parse(match.group(2) ?? ''),
      );
    } on ArgumentError {
      return null;
    }
  }
}
