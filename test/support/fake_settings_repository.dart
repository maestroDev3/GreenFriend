import 'package:green_friend/domain/reminders.dart';
import 'package:green_friend/domain/settings.dart';

/// In-memory [SettingsRepository] for tests.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.system,
    this.reminder = ReminderSettings.defaults,
    this.plantIdApiKey,
    this.tipDismissedOn,
  });

  AppThemeMode themeMode;
  AppLanguage language;
  ReminderSettings reminder;
  String? plantIdApiKey;
  DateTime? tipDismissedOn;

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
}
