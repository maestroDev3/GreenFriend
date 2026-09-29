import 'package:flutter/widgets.dart';

import '../domain/settings.dart';

/// Holds the current app settings for the UI and saves every change.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;
  AppThemeMode _themeMode = AppThemeMode.system;
  AppLanguage _language = AppLanguage.system;

  AppThemeMode get themeMode => _themeMode;

  AppLanguage get language => _language;

  /// Reads the stored settings; call once before the app starts.
  Future<void> load() async {
    _themeMode = await _repository.loadThemeMode();
    _language = await _repository.loadLanguage();
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _repository.saveThemeMode(mode);
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    await _repository.saveLanguage(language);
  }
}

/// Makes the [SettingsController] available to all screens and rebuilds
/// them when a setting changes.
class SettingsScope extends InheritedNotifier<SettingsController> {
  const SettingsScope({
    super.key,
    required SettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static SettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    if (scope?.notifier case final controller?) return controller;
    throw StateError('No SettingsScope above this context.');
  }
}
