import 'package:flutter/widgets.dart';

import '../domain/clock.dart';
import '../domain/reminders.dart';
import '../domain/settings.dart';

/// Holds the current app settings for the UI and saves every change.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;
  AppThemeMode _themeMode = AppThemeMode.system;
  AppLanguage _language = AppLanguage.system;
  ReminderSettings _reminder = ReminderSettings.defaults;
  String? _plantIdApiKey;
  DateTime? _tipDismissedOn;

  AppThemeMode get themeMode => _themeMode;

  AppLanguage get language => _language;

  ReminderSettings get reminder => _reminder;

  /// The user's plant.id API key; `null` hides photo identification.
  String? get plantIdApiKey => _plantIdApiKey;

  /// The day the tip of the day was closed; it stays hidden that day.
  DateTime? get tipDismissedOn => _tipDismissedOn;

  /// Reads the stored settings; call once before the app starts.
  Future<void> load() async {
    _themeMode = await _repository.loadThemeMode();
    _language = await _repository.loadLanguage();
    _reminder = await _repository.loadReminder();
    _plantIdApiKey = await _repository.loadPlantIdApiKey();
    _tipDismissedOn = await _repository.loadTipDismissedOn();
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

  Future<void> setReminder(ReminderSettings reminder) async {
    if (reminder == _reminder) return;
    _reminder = reminder;
    notifyListeners();
    await _repository.saveReminder(reminder);
  }

  /// Saves [key] trimmed; a blank key removes it.
  Future<void> setPlantIdApiKey(String? key) async {
    final normalized = normalizedApiKey(key);
    if (normalized == _plantIdApiKey) return;
    _plantIdApiKey = normalized;
    notifyListeners();
    await _repository.savePlantIdApiKey(normalized);
  }

  /// Hides the tip of the day until the day after [today].
  Future<void> dismissTip(DateTime today) async {
    final day = dayOf(today);
    if (day == _tipDismissedOn) return;
    _tipDismissedOn = day;
    notifyListeners();
    await _repository.saveTipDismissedOn(day);
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
