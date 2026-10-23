import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// How the introduction was left.
enum OnboardingResult {
  /// Skipped or "Not now": go to the home screen.
  home,

  /// "Add your first plant": open the form for a new plant.
  addPlant,
}

/// A short introduction on the very first start: three pages on reminders,
/// photo identification and the calendar/weather/journal features.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final ValueChanged<OnboardingResult> onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  var _page = 0;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final last = _page == _pageCount - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _Page(
                    icon: Icons.water_drop_outlined,
                    title: l10n.onboardingRemindersTitle,
                    text: l10n.onboardingRemindersText,
                  ),
                  _Page(
                    icon: Icons.photo_camera_outlined,
                    title: l10n.onboardingPhotoTitle,
                    text: l10n.onboardingPhotoText,
                  ),
                  _Page(
                    icon: Icons.calendar_month_outlined,
                    title: l10n.onboardingCalendarTitle,
                    text: l10n.onboardingCalendarText,
                  ),
                ],
              ),
            ),
            _Dots(count: _pageCount, current: _page),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => widget.onDone(OnboardingResult.home),
                    child: Text(
                      last ? l10n.onboardingNotNow : l10n.onboardingSkip,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: last
                        ? () => widget.onDone(OnboardingResult.addPlant)
                        : _next,
                    child: Text(
                      last ? l10n.onboardingAddPlant : l10n.onboardingNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 64, 32, 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: scheme.primaryContainer,
            child: Icon(icon, size: 56, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: i == current ? 20 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i == current ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
