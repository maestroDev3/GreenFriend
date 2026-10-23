import 'package:green_friend/domain/frost.dart';
import 'package:green_friend/domain/reminders.dart';
import 'package:green_friend/domain/settings.dart';
import 'package:green_friend/domain/vacation.dart';
import 'package:green_friend/domain/weather.dart';

/// In-memory [SettingsRepository] for tests.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.system,
    this.reminder = ReminderSettings.defaults,
    this.plantIdApiKey,
    this.tipDismissedOn,
    this.phoneCalendar,
    this.weatherLocation,
    this.vacation,
    this.frostWarnings = const [],
    this.healthCheckConsent = false,
  });

  AppThemeMode themeMode;
  AppLanguage language;
  ReminderSettings reminder;
  String? plantIdApiKey;
  DateTime? tipDismissedOn;
  CalendarChoice? phoneCalendar;
  WeatherLocation? weatherLocation;
  Vacation? vacation;
  List<FrostWarning> frostWarnings;
  bool healthCheckConsent;

  @override
  Future<AppThemeMode> loadThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async => themeMode = mode;

  @override
  Future<AppLanguage> loadLanguage() async => language;

  @override
  Future<void> saveLanguage(AppLanguage value) async => language = value;

  @override
  Future<ReminderSettings> loadReminder() async => reminder;

  @override
  Future<void> saveReminder(ReminderSettings value) async => reminder = value;

  @override
  Future<String?> loadPlantIdApiKey() async => plantIdApiKey;

  @override
  Future<void> savePlantIdApiKey(String? key) async =>
      plantIdApiKey = (key == null || key.trim().isEmpty) ? null : key.trim();

  @override
  Future<DateTime?> loadTipDismissedOn() async => tipDismissedOn;

  @override
  Future<void> saveTipDismissedOn(DateTime day) async => tipDismissedOn = day;

  @override
  Future<CalendarChoice?> loadPhoneCalendar() async => phoneCalendar;

  @override
  Future<void> savePhoneCalendar(CalendarChoice? choice) async =>
      phoneCalendar = choice;

  @override
  Future<WeatherLocation?> loadWeatherLocation() async => weatherLocation;

  @override
  Future<void> saveWeatherLocation(WeatherLocation? location) async =>
      weatherLocation = location;

  @override
  Future<Vacation?> loadVacation() async => vacation;

  @override
  Future<void> saveVacation(Vacation? value) async => vacation = value;

  @override
  Future<bool> loadHealthCheckConsent() async => healthCheckConsent;

  @override
  Future<void> saveHealthCheckConsent(bool value) async =>
      healthCheckConsent = value;

  @override
  Future<List<FrostWarning>> loadFrostWarnings() async => frostWarnings;

  @override
  Future<void> saveFrostWarnings(List<FrostWarning> value) async =>
      frostWarnings = value;
}
