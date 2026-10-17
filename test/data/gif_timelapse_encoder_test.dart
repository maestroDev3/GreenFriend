import 'package:flutter_test/flutter_test.dart';
import 'package:green_friend/data/gif_timelapse_encoder.dart';
import 'package:green_friend/domain/timelapse.dart';
import 'package:image/image.dart' as img;

List<int> _jpeg(int width, int height) => img.encodeJpg(
  img.Image(width: width, height: height)
    ..clear(img.ColorRgb8(30, 140, 60)),
);

List<int> _png(int width, int height) => img.encodePng(
  img.Image(width: width, height: height)
    ..clear(img.ColorRgb8(200, 200, 40)),
);

void main() {
  const encoder = GifTimelapseEncoder();

  test('the encoder produces a GIF with one frame per photo', () async {
    final gif = await encoder.encode([
      TimelapseFrame(bytes: _jpeg(960, 720), label: '1 Aug 2026'),
      TimelapseFrame(bytes: _png(640, 480), label: '20 Aug 2026'),
      TimelapseFrame(bytes: _jpeg(800, 600), label: '3 Sep 2026'),
    ]);

    final decoded = img.decodeGif(Uint8List.fromList(gif))!;
    expect(decoded.numFrames, 3);
  });

  test('the encoder produces frames at most 480 px wide', () async {
    final gif = await encoder.encode([
      TimelapseFrame(bytes: _jpeg(1600, 1200), label: '1 Aug 2026'),
      TimelapseFrame(bytes: _jpeg(1200, 1600), label: '2 Aug 2026'),
    ]);

    final decoded = img.decodeGif(Uint8List.fromList(gif))!;
    expect(decoded.width, 480);
    expect(decoded.height, 360);
  });

  test('the encoder keeps small photos at their size (at most 480 px)', () async {
    final gif = await encoder.encode([
      TimelapseFrame(bytes: _png(200, 100), label: '1 Aug 2026'),
      TimelapseFrame(bytes: _png(200, 100), label: '2 Aug 2026'),
    ]);

    final decoded = img.decodeGif(Uint8List.fromList(gif))!;
    expect(decoded.width, 200);
    expect(decoded.height, 100);
  });

  test('unreadable photos are skipped instead of failing', () async {
    final gif = await encoder.encode([
      TimelapseFrame(bytes: const [1, 2, 3, 4], label: 'broken'),
      TimelapseFrame(bytes: _jpeg(640, 480), label: '1 Aug 2026'),
      TimelapseFrame(bytes: _jpeg(640, 480), label: '2 Aug 2026'),
    ]);

    final decoded = img.decodeGif(Uint8List.fromList(gif))!;
    expect(decoded.numFrames, 2);
  });

  test('unreadable photos are skipped: none readable throws', () async {
    await expectLater(
      encoder.encode([
        TimelapseFrame(bytes: const [1, 2, 3], label: 'broken'),
      ]),
      throwsA(isA<TimelapseException>()),
    );
  });
}
