import 'dart:async';

import 'package:green_friend/domain/light_check.dart';

/// A light sensor whose readings the test sends with [emit].
class FakeLightSensor implements LightSensor {
  FakeLightSensor({this.available = true});

  final bool available;
  final _controller = StreamController<double>.broadcast();
  var listens = 0;

  void emit(double lux) => _controller.add(lux);

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<double> luxStream() {
    listens++;
    return _controller.stream;
  }
}
