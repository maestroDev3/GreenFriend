import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/backup_files.dart';
import '../domain/clock.dart';
import '../domain/phone_calendar.dart';
import '../domain/plant_repository.dart';
import '../domain/reminders.dart';
import '../domain/sitter_plan.dart';
import '../domain/vacation.dart';
import '../domain/weather.dart';
import '../domain/settings.dart';
import '../l10n/app_localizations.dart';
import 'calendar_sync.dart';
import 'settings_controller.dart';
import 'sitter_plan_text.dart';
import 'weather_sync.dart';

/// Lets the user choose the app's appearance, language and reminders.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.clock = DateTime.now,
    this.plants,
    this.sharing,
  });

  /// Supplies today for the vacation picker.
  final Clock clock;

  /// With [sharing], offers the plant sitter plan during a vacation.
  final PlantRepository? plants;
  final FileSharing? sharing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = SettingsScope.of(context);
    final calendarSync = CalendarScope.maybeOf(context);
    final weatherSync = WeatherScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(l10n.appearanceSection),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final mode in AppThemeMode.values)
                  _ChoiceTile(
                    tileKey: ValueKey('theme-${mode.name}'),
                    label: switch (mode) {
                      AppThemeMode.system => l10n.themeModeSystem,
                      AppThemeMode.light => l10n.themeModeLight,
                      AppThemeMode.dark => l10n.themeModeDark,
                    },
                    selected: settings.themeMode == mode,
                    onTap: () => settings.setThemeMode(mode),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(l10n.languageSection),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final language in AppLanguage.values)
                  _ChoiceTile(
                    tileKey: ValueKey('language-${language.name}'),
                    label: switch (language) {
                      AppLanguage.system => l10n.languageSystem,
                      AppLanguage.english => l10n.languageEnglish,
                      AppLanguage.german => l10n.languageGerman,
                    },
                    selected: settings.language == language,
                    onTap: () => settings.setLanguage(language),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(l10n.remindersSection),
          Card(clipBehavior: Clip.antiAlias, child: _ReminderTiles(settings)),
          const SizedBox(height: 24),
          _SectionTitle(l10n.vacationSection),
          Card(
            clipBehavior: Clip.antiAlias,
            child: _VacationTiles(
              settings: settings,
              clock: clock,
              plants: plants,
              sharing: sharing,
            ),
          ),
          if (weatherSync != null) ...[
            const SizedBox(height: 24),
            _SectionTitle(l10n.weatherSection),
            Card(
              clipBehavior: Clip.antiAlias,
              child: _WeatherPlaceTiles(settings: settings, sync: weatherSync),
            ),
          ],
          if (calendarSync != null) ...[
            const SizedBox(height: 24),
            _SectionTitle(l10n.phoneCalendarSection),
            Card(
              clipBehavior: Clip.antiAlias,
              child: _PhoneCalendarTiles(
                settings: settings,
                sync: calendarSync,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _SectionTitle(l10n.plantIdSection),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ApiKeyField(settings),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.tileKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Identifies the option in tests.
  final Key tileKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      title: Text(label),
      selected: selected,
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}

class _ReminderTiles extends StatelessWidget {
  const _ReminderTiles(this.settings);

  final SettingsController settings;

  Future<void> _pickTime(BuildContext context) async {
    final current = settings.reminder;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.time.hour,
        minute: current.time.minute,
      ),
    );
    if (picked == null) return;
    await settings.setReminder(
      ReminderSettings(
        enabled: current.enabled,
        time: ReminderTime.checked(picked.hour, picked.minute),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reminder = settings.reminder;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: reminder.time.hour, minute: reminder.time.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return Column(
      children: [
        SwitchListTile(
          title: Text(l10n.dailyReminder),
          subtitle: Text(l10n.reminderChannelDescription),
          value: reminder.enabled,
          onChanged: (enabled) => settings.setReminder(
            ReminderSettings(enabled: enabled, time: reminder.time),
          ),
        ),
        ListTile(
          enabled: reminder.enabled,
          title: Text(l10n.reminderTimeLabel),
          trailing: Text(time),
          onTap: () => _pickTime(context),
        ),
      ],
    );
  }
}

/// Text field for the plant.id API key; the text is hidden unless the user
/// reveals it, and every change is saved right away.
class _ApiKeyField extends StatefulWidget {
  const _ApiKeyField(this.settings);

  final SettingsController settings;

  @override
  State<_ApiKeyField> createState() => _ApiKeyFieldState();
}

class _ApiKeyFieldState extends State<_ApiKeyField> {
  late final _controller = TextEditingController(
    text: widget.settings.plantIdApiKey,
  );
  var _hidden = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      key: const ValueKey('plant-id-api-key'),
      controller: _controller,
      obscureText: _hidden,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: l10n.plantIdApiKeyLabel,
        helperText: l10n.plantIdApiKeyHelp,
        helperMaxLines: 4,
        suffixIcon: IconButton(
          icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
          tooltip: _hidden ? l10n.showApiKey : l10n.hideApiKey,
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
      onChanged: widget.settings.setPlantIdApiKey,
    );
  }
}

/// Switches the phone calendar sync on (asking for access and a calendar)
/// or off (removing the upcoming events), and changes the calendar.
class _PhoneCalendarTiles extends StatefulWidget {
  const _PhoneCalendarTiles({required this.settings, required this.sync});

  final SettingsController settings;
  final CalendarSync sync;

  @override
  State<_PhoneCalendarTiles> createState() => _PhoneCalendarTilesState();
}

class _PhoneCalendarTilesState extends State<_PhoneCalendarTiles> {
  Future<void> _switch({required bool on}) async {
    final previous = widget.settings.phoneCalendar;
    if (!on) {
      await widget.settings.setPhoneCalendar(null);
      if (previous != null) await widget.sync.removeUpcoming(previous.id);
      return;
    }
    await _choose();
  }

  Future<void> _choose() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final calendar = widget.sync.calendar;
    if (!await calendar.requestAccess()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.calendarAccessDenied)),
      );
      return;
    }
    final calendars = await calendar.writableCalendars();
    if (!mounted) return;
    if (calendars.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noWritableCalendars)));
      return;
    }
    final chosen = await showModalBottomSheet<PhoneCalendarInfo>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CalendarPicker(calendars: calendars),
    );
    if (chosen == null) return;
    final previous = widget.settings.phoneCalendar;
    if (previous != null && previous.id != chosen.id) {
      await widget.sync.removeUpcoming(previous.id);
    }
    await widget.settings.setPhoneCalendar((id: chosen.id, name: chosen.name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choice = widget.settings.phoneCalendar;
    return Column(
      children: [
        SwitchListTile(
          title: Text(l10n.phoneCalendarSwitch),
          subtitle: Text(l10n.phoneCalendarHint),
          value: choice != null,
          onChanged: (on) => _switch(on: on),
        ),
        if (choice != null)
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: Text(l10n.phoneCalendarChosen(choice.name)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _choose,
          ),
      ],
    );
  }
}

class _CalendarPicker extends StatelessWidget {
  const _CalendarPicker({required this.calendars});

  final List<PhoneCalendarInfo> calendars;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l10n.chooseCalendar,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final calendar in calendars)
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(calendar.name),
                    subtitle: switch (calendar.account) {
                      final account? => Text(account),
                      null => null,
                    },
                    onTap: () => Navigator.of(context).pop(calendar),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the weather place with buttons to choose or remove it.
class _WeatherPlaceTiles extends StatelessWidget {
  const _WeatherPlaceTiles({required this.settings, required this.sync});

  final SettingsController settings;
  final WeatherSync sync;

  Future<void> _choose(BuildContext context) async {
    final place = await Navigator.of(context).push(
      MaterialPageRoute<WeatherLocation>(
        builder: (_) => PlaceSearchScreen(service: sync.service),
      ),
    );
    if (place == null) return;
    await settings.setWeatherLocation(place);
    await sync.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final place = settings.weatherLocation;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place?.label ?? l10n.noWeatherPlace,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.weatherPlaceHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _choose(context),
                icon: const Icon(Icons.search),
                label: Text(l10n.choosePlace),
              ),
              if (place != null)
                TextButton(
                  onPressed: () => settings.setWeatherLocation(null),
                  child: Text(l10n.removePlace),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Searches a place by name; pops with the chosen [WeatherLocation].
class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key, required this.service});

  final WeatherService service;

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  List<WeatherLocation>? _results;
  var _failed = false;
  var _searching = false;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    final language = Localizations.localeOf(context).languageCode;
    setState(() {
      _searching = true;
      _failed = false;
    });
    try {
      final results = await widget.service.searchPlaces(
        query.trim(),
        languageCode: language,
      );
      if (!mounted) return;
      setState(() => _results = results);
    } on WeatherUnavailable {
      if (!mounted) return;
      setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.choosePlace)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.searchPlaceLabel,
              prefixIcon: const Icon(Icons.search),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
          ),
          const SizedBox(height: 16),
          if (_searching) const LinearProgressIndicator(),
          if (_failed) Text(l10n.weatherUnavailable),
          if (results != null && results.isEmpty) Text(l10n.noPlacesFound),
          for (final place in results ?? const <WeatherLocation>[])
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(place.label),
              onTap: () => Navigator.of(context).pop(place),
            ),
        ],
      ),
    );
  }
}

/// Plans, changes or ends the vacation (reminders pause on its days).
class _VacationTiles extends StatelessWidget {
  const _VacationTiles({
    required this.settings,
    required this.clock,
    this.plants,
    this.sharing,
  });

  final SettingsController settings;
  final Clock clock;
  final PlantRepository? plants;
  final FileSharing? sharing;

  Future<void> _share(
    BuildContext context,
    PlantRepository plants,
    FileSharing sharing,
    Vacation vacation,
  ) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final plan = sitterPlan(
      await plants.allPlants(),
      vacation: vacation,
      today: clock(),
    );
    await sharing.shareText(
      sitterPlanText(l10n, locale, vacation, plan),
      subject: l10n.shareSitterPlan,
    );
  }

  /// The planned or running vacation; an ended one counts as none.
  Vacation? get _current => switch (settings.vacation) {
    final vacation? when !vacation.last.isBefore(dayOf(clock())) => vacation,
    _ => null,
  };

  Future<void> _pick(BuildContext context) async {
    final today = dayOf(clock());
    final current = _current;
    DateTime local(DateTime day) => DateTime(day.year, day.month, day.day);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: local(today),
      lastDate: DateTime(today.year + 1, today.month, today.day),
      currentDate: local(today),
      // The picker starts at today, so a running vacation is shown from today.
      initialDateRange: current == null
          ? null
          : DateTimeRange(
              start: local(
                current.first.isBefore(today) ? today : current.first,
              ),
              end: local(current.last),
            ),
    );
    if (picked == null) return;
    await settings.setVacation(Vacation(first: picked.start, last: picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final vacation = _current;
    final format = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vacation == null)
            Text(l10n.noVacation, style: text.bodyMedium)
          else ...[
            Text(
              l10n.vacationPeriod(
                format.format(vacation.first),
                format.format(vacation.last),
              ),
              style: text.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(l10n.vacationHint, style: text.bodySmall),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pick(context),
                icon: const Icon(Icons.beach_access_outlined),
                label: Text(
                  vacation == null ? l10n.planVacation : l10n.changeVacation,
                ),
              ),
              if (vacation != null)
                TextButton(
                  onPressed: () => settings.setVacation(null),
                  child: Text(l10n.endVacation),
                ),
              if ((vacation, plants, sharing) case (
                final vacation?,
                final plants?,
                final sharing?,
              ))
                FilledButton.tonalIcon(
                  onPressed: () => _share(context, plants, sharing, vacation),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l10n.shareSitterPlan),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
