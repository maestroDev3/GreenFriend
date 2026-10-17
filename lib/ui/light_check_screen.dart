import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/light_check.dart';
import '../domain/species.dart';
import '../l10n/app_localizations.dart';

/// Measures the light at a spot with the phone's light sensor and says
/// whether it suits the plant.
class LightCheckScreen extends StatefulWidget {
  const LightCheckScreen({
    super.key,
    required this.sensor,
    required this.plantName,
    this.need,
    this.duration = const Duration(seconds: 3),
  });

  final LightSensor sensor;
  final String plantName;

  /// The light need of the plant's species; `null` shows only the lux value.
  final Light? need;

  /// How long one measurement takes.
  final Duration duration;

  @override
  State<LightCheckScreen> createState() => _LightCheckScreenState();
}

enum _Phase { starting, measuring, done, noSensor }

class _LightCheckScreenState extends State<LightCheckScreen> {
  var _phase = _Phase.starting;
  final _samples = <double>[];
  double? _current;
  double? _result;
  StreamSubscription<double>? _subscription;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  Future<void> _start() async {
    final available = await widget.sensor.isAvailable();
    if (!mounted) return;
    if (!available) {
      setState(() => _phase = _Phase.noSensor);
      return;
    }
    _measure();
  }

  void _measure() {
    _samples.clear();
    setState(() {
      _phase = _Phase.measuring;
      _current = null;
      _result = null;
    });
    _subscription = widget.sensor.luxStream().listen(
      (lux) => setState(() {
        _samples.add(lux);
        _current = lux;
      }),
      onError: (Object _) {
        _stop();
        if (mounted) setState(() => _phase = _Phase.noSensor);
      },
    );
    _timer = Timer(widget.duration, _finish);
  }

  void _finish() {
    _stop();
    if (!mounted) return;
    setState(() {
      _result = averageLux(_samples);
      _phase = _Phase.done;
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    String luxText(double lux) => l10n.luxValue(number.format(lux.round()));
    final shown = _phase == _Phase.done ? _result : _current;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lightCheckTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_phase) {
            _Phase.starting => const SizedBox.shrink(),
            _Phase.noSensor => Center(
              child: Text(
                l10n.lightNoSensor,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            _Phase.measuring || _Phase.done => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.lightCheckHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                Icon(
                  Icons.light_mode_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  shown == null ? '–' : luxText(shown),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: 16),
                if (_phase == _Phase.measuring)
                  Text(
                    l10n.lightMeasuring,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  )
                else if (_result case final lux?)
                  _Verdict(lux: lux, need: widget.need, plant: widget.plantName),
                const Spacer(),
                if (_phase == _Phase.done)
                  FilledButton.icon(
                    onPressed: _measure,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.lightMeasureAgain),
                  ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.lux, required this.need, required this.plant});

  final double lux;
  final Light? need;
  final String plant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final need = this.need;
    if (need == null) {
      return Text(
        switch (lux) {
          < 1000 => l10n.lightShadySpot,
          < 10000 => l10n.lightBrightSpot,
          _ => l10n.lightSunnySpot,
        },
        textAlign: TextAlign.center,
        style: text.titleLarge,
      );
    }
    return Column(
      children: [
        Text(
          switch (lightVerdict(lux, need)) {
            LightVerdict.tooDark => l10n.lightTooDark(plant),
            LightVerdict.fine => l10n.lightFine(plant),
            LightVerdict.tooBright => l10n.lightTooBright(plant),
          },
          textAlign: TextAlign.center,
          style: text.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.lightNeeds(switch (need) {
            Light.low => l10n.lightLow,
            Light.medium => l10n.lightMedium,
            Light.brightIndirect => l10n.lightBrightIndirect,
            Light.direct => l10n.lightDirect,
          }),
          textAlign: TextAlign.center,
          style: text.bodyMedium,
        ),
      ],
    );
  }
}
