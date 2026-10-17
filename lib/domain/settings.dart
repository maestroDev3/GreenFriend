import 'frost.dart';
import 'reminders.dart';
import 'vacation.dart';
import 'weather.dart';

/// How the app chooses between light and dark colors.
enum AppThemeMode { system, light, dark }

/// Which language the app uses; [system] follows the device language.
enum AppLanguage { system, english, german }

/// The phone calendar the care plan is synced to.
typedef CalendarChoice = ({String id, String name});

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

  /// The day the user closed the tip of the day, or `null`.
  Future<DateTime?> loadTipDismissedOn();

  /// Remembers that the tip of the day was closed on [day].
  Future<void> saveTipDismissedOn(DateTime day);

  /// The phone calendar for the care plan, or `null` when the sync is off.
  Future<CalendarChoice?> loadPhoneCalendar();

  /// Stores [choice]; `null` switches the sync off.
  Future<void> savePhoneCalendar(CalendarChoice? choice);

  /// The place the weather is fetched for, or `null`.
  Future<WeatherLocation?> loadWeatherLocation();

  /// Stores [location]; `null` removes it.
  Future<void> saveWeatherLocation(WeatherLocation? location);

  /// The current or next vacation, or `null`.
  Future<Vacation?> loadVacation();

  /// Stores [vacation]; `null` removes it.
  Future<void> saveVacation(Vacation? vacation);

  /// The frost warnings of the last weather fetch; empty if none.
  Future<List<FrostWarning>> loadFrostWarnings();

  /// Stores [warnings]; an empty list removes them.
  Future<void> saveFrostWarnings(List<FrostWarning> warnings);
}

/// Trims an API key typed by the user; blank means no key.
String? normalizedApiKey(String? key) {
  final trimmed = key?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
