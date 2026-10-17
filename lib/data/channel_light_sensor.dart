import 'package:flutter/services.dart';

import '../domain/light_check.dart';

/// Reads the Android light sensor through the app's own platform channels
/// (`LightSensorHandler` in Kotlin).
class ChannelLightSensor implements LightSensor {
  const ChannelLightSensor();

  static const infoChannel = MethodChannel(
    'de.maestrodev.green_friend/light_info',
  );
  static const luxChannel = EventChannel('de.maestrodev.green_friend/light');

  @override
  Future<bool> isAvailable() async {
    try {
      return await infoChannel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Stream<double> luxStream() => luxChannel.receiveBroadcastStream().map(
    (value) => (value as num).toDouble(),
  );
}
