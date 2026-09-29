import 'package:green_friend/domain/settings.dart';

/// In-memory [SettingsRepository] for tests.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({this.themeMode = AppThemeMode.system});

  AppThemeMode themeMode;

  @override
  Future<AppThemeMode> loadThemeMode() async => themeMode;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async => themeMode = mode;
}
