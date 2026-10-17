import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/channel_light_sensor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(ChannelLightSensor.infoChannel, null);
    messenger.setMockStreamHandler(ChannelLightSensor.luxChannel, null);
  });

  group('ChannelLightSensor', () {
    test('the channel sensor reports availability', () async {
      for (final available in [true, false]) {
        messenger.setMockMethodCallHandler(ChannelLightSensor.infoChannel, (
          call,
        ) async {
          expect(call.method, 'isAvailable');
          return available;
        });

        expect(await const ChannelLightSensor().isAvailable(), available);
      }
    });

    test('the channel sensor reports no sensor without the platform side', () async {
      expect(await const ChannelLightSensor().isAvailable(), isFalse);
    });

    test('the channel sensor streams the lux values from the platform', () async {
      messenger.setMockStreamHandler(
        ChannelLightSensor.luxChannel,
        MockStreamHandler.inline(
          onListen: (arguments, events) {
            events
              ..success(120.5)
              ..success(130)
              ..endOfStream();
          },
        ),
      );

      expect(await const ChannelLightSensor().luxStream().toList(), [
        120.5,
        130.0,
      ]);
    });
  });
}
