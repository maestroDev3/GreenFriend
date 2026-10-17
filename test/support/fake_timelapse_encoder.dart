import 'package:green_friend/domain/timelapse.dart';

/// Records the frames and returns a few fixed bytes instead of a real GIF.
class FakeTimelapseEncoder implements TimelapseEncoder {
  FakeTimelapseEncoder({this.error});

  /// Thrown by [encode] if set, e.g. a [TimelapseException].
  final Object? error;
  final encoded = <List<TimelapseFrame>>[];

  static const gif = [71, 73, 70];

  @override
  Future<List<int>> encode(List<TimelapseFrame> frames) async {
    encoded.add(frames);
    if (error case final error?) throw error;
    return gif;
  }
}
