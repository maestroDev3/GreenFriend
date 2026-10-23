import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../domain/timelapse.dart';

/// Encodes the time-lapse as an animated GIF in a background isolate.
///
/// All frames get the size of the first photo, scaled down to at most
/// [maxWidth]; other photos are fitted in with black bars. Each frame shows
/// its label in the bottom left corner.
class GifTimelapseEncoder implements TimelapseEncoder {
  const GifTimelapseEncoder({
    this.maxWidth = 480,
    this.frameDuration = const Duration(milliseconds: 800),
  });

  final int maxWidth;
  final Duration frameDuration;

  @override
  Future<List<int>> encode(List<TimelapseFrame> frames) {
    final maxWidth = this.maxWidth;
    final milliseconds = frameDuration.inMilliseconds;
    return Isolate.run(() => _encodeGif(frames, maxWidth, milliseconds));
  }
}

List<int> _encodeGif(
  List<TimelapseFrame> frames,
  int maxWidth,
  int milliseconds,
) {
  // Photos are decoded one at a time and only their small frame is kept, so
  // many large photos do not exhaust the memory.
  img.Image? animation;
  var width = 0;
  var height = 0;
  for (final frame in frames) {
    final photo = _decode(frame.bytes);
    if (photo == null) continue;
    if (animation == null) {
      width = min(maxWidth, photo.width);
      height = max(1, (photo.height * width / photo.width).round());
    }
    final canvas = _fit(photo, width, height);
    _drawLabel(canvas, frame.label);
    canvas.frameDuration = milliseconds;
    if (animation == null) {
      animation = canvas;
    } else {
      animation.addFrame(canvas);
    }
  }
  if (animation == null) {
    throw const TimelapseException('None of the photos is readable.');
  }
  return img.encodeGif(animation);
}

img.Image? _decode(List<int> bytes) {
  try {
    final image = img.decodeImage(Uint8List.fromList(bytes));
    return image == null ? null : img.bakeOrientation(image);
  } on Object {
    return null;
  }
}

img.Image _fit(img.Image photo, int width, int height) {
  final scale = min(width / photo.width, height / photo.height);
  final scaledWidth = max(1, (photo.width * scale).round());
  final scaledHeight = max(1, (photo.height * scale).round());
  final scaled = img.copyResize(
    photo,
    width: scaledWidth,
    height: scaledHeight,
    interpolation: img.Interpolation.average,
  );
  final canvas = img.Image(width: width, height: height)
    ..clear(img.ColorRgb8(0, 0, 0));
  return img.compositeImage(
    canvas,
    scaled,
    dstX: (width - scaledWidth) ~/ 2,
    dstY: (height - scaledHeight) ~/ 2,
  );
}

void _drawLabel(img.Image canvas, String label) {
  final font = img.arial24;
  final top = max(0, canvas.height - font.lineHeight - 12);
  img.fillRect(
    canvas,
    x1: 0,
    y1: top,
    x2: canvas.width - 1,
    y2: canvas.height - 1,
    color: img.ColorRgba8(0, 0, 0, 150),
  );
  img.drawString(
    canvas,
    label,
    font: font,
    x: 8,
    y: top + 6,
    color: img.ColorRgb8(255, 255, 255),
  );
}
