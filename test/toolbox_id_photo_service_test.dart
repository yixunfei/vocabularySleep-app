import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vocabulary_sleep_app/src/services/toolbox_id_photo_service.dart';

void main() {
  group('ToolboxIdPhotoService', () {
    test('renders preset dimensions from millimeter and dpi', () async {
      final source = _fixturePortrait();

      final result = await const ToolboxIdPhotoService().render(
        ToolboxIdPhotoRenderInput(
          sourceBytes: source,
          preset: toolboxIdPhotoPresets.first,
          dpi: 300,
          replaceBackground: false,
          backgroundColor: 0xffffff,
        ),
      );

      expect(result.pixelWidth, 295);
      expect(result.pixelHeight, 413);
      expect(result.cropWidth / result.cropHeight, closeTo(25 / 35, 0.01));

      final decoded = img.decodeImage(result.bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 295);
      expect(decoded.height, 413);
    });

    test('replaces a sampled plain background with target color', () async {
      final source = _fixturePortrait();

      final result = await const ToolboxIdPhotoService().render(
        ToolboxIdPhotoRenderInput(
          sourceBytes: source,
          preset: toolboxIdPhotoPresets[5],
          dpi: 150,
          backgroundColor: 0x438bff,
          backgroundTolerance: 0.7,
          replacementStrength: 1,
        ),
      );

      expect(result.replacedPixels, greaterThan(0));
      final decoded = img.decodeImage(result.bytes)!;
      final corner = decoded.getPixel(0, 0);
      expect(corner.r, closeTo(0x43, 4));
      expect(corner.g, closeTo(0x8b, 4));
      expect(corner.b, closeTo(0xff, 4));
    });

    test('exports jpeg when requested', () async {
      final source = _fixturePortrait();

      final result = await const ToolboxIdPhotoService().render(
        ToolboxIdPhotoRenderInput(
          sourceBytes: source,
          preset: toolboxIdPhotoPresets[1],
          dpi: 240,
          outputFormat: ToolboxIdPhotoOutputFormat.jpg,
          jpegQuality: 88,
        ),
      );

      expect(result.outputFormat, ToolboxIdPhotoOutputFormat.jpg);
      expect(result.bytes.take(2), <int>[0xff, 0xd8]);
    });
  });
}

Uint8List _fixturePortrait() {
  final image = img.Image(width: 120, height: 160, numChannels: 4);
  image.clear(img.ColorRgba8(242, 242, 242, 255));
  for (var y = 34; y < 132; y += 1) {
    for (var x = 38; x < 82; x += 1) {
      image.setPixelRgba(x, y, 56, 48, 42, 255);
    }
  }
  for (var y = 16; y < 54; y += 1) {
    for (var x = 44; x < 76; x += 1) {
      final dx = x - 60;
      final dy = y - 35;
      if (dx * dx + dy * dy <= 18 * 18) {
        image.setPixelRgba(x, y, 214, 169, 132, 255);
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
