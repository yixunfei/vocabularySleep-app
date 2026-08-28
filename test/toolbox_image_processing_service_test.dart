import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vocabulary_sleep_app/src/services/toolbox_image_processing_service.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_image_resource_policy.dart';

void main() {
  const service = ToolboxImageProcessingService();

  group('ToolboxImageResourcePolicy', () {
    test('rejects source files above the byte limit', () {
      expect(
        () => ToolboxImageResourcePolicy.validateSourceBytes(
          ToolboxImageResourcePolicy.maxSourceBytes + 1,
        ),
        throwsA(
          isA<ToolboxImageProcessingException>().having(
            (error) => error.code,
            'code',
            ToolboxImageProcessingErrorCode.sourceFileTooLarge,
          ),
        ),
      );
    });

    test('rejects source and output pixel limits independently', () {
      expect(
        () => ToolboxImageResourcePolicy.validateSourceDimensions(8000, 5001),
        throwsA(
          isA<ToolboxImageProcessingException>().having(
            (error) => error.code,
            'code',
            ToolboxImageProcessingErrorCode.sourceDimensionsTooLarge,
          ),
        ),
      );
      expect(
        () => ToolboxImageResourcePolicy.validateOutputDimensions(16385, 1),
        throwsA(
          isA<ToolboxImageProcessingException>().having(
            (error) => error.code,
            'code',
            ToolboxImageProcessingErrorCode.outputDimensionsTooLarge,
          ),
        ),
      );
    });
  });

  group('ToolboxImageProcessingService', () {
    test('prepares an oriented bounded preview', () async {
      final source = img.Image(width: 2400, height: 1200);
      source.exif.imageIfd.orientation = 6;
      final prepared = await service.prepareSource(
        Uint8List.fromList(img.encodeJpg(source)),
      );

      expect(prepared.width, 1200);
      expect(prepared.height, 2400);
      final preview = img.decodeImage(prepared.previewBytes)!;
      expect(preview.width, 800);
      expect(preview.height, ToolboxImageResourcePolicy.previewMaxSide);
    });

    test('rejects oversized metadata before decoding pixels', () async {
      await expectLater(
        service.prepareSource(_pngWithDimensions(8000, 5001)),
        throwsA(
          isA<ToolboxImageProcessingException>().having(
            (error) => error.code,
            'code',
            ToolboxImageProcessingErrorCode.sourceDimensionsTooLarge,
          ),
        ),
      );
    });

    test('compresses in a worker and returns a bounded preview', () async {
      final source = img.Image(width: 320, height: 160);
      source.clear(img.ColorRgb8(32, 96, 160));

      final result = await service.compress(
        ToolboxImageCompressInput(
          sourceBytes: Uint8List.fromList(img.encodePng(source)),
          targetWidth: 160,
          algorithm: ToolboxImageCompressAlgorithm.jpegBalanced,
          colorMode: ToolboxImageColorMode.grayscale,
          dpiMode: ToolboxImageDpiMode.keep,
          jpegQuality: 80,
          monochromeThreshold: 0.5,
          dpi: 144,
        ),
      );

      expect(result.width, 160);
      expect(result.height, 80);
      expect(result.format, ToolboxImageOutputFormat.jpg);
      expect(img.decodeImage(result.bytes), isNotNull);
      expect(img.decodeImage(result.previewBytes), isNotNull);
    });

    test('rejects oversized output before decoding source bytes', () async {
      final future = service.upscale(
        ToolboxImageUpscaleInput(
          sourceBytes: Uint8List.fromList(<int>[1, 2, 3]),
          targetWidth: ToolboxImageResourcePolicy.maxOutputSide + 1,
          targetHeight: 1,
          algorithm: ToolboxImageUpscaleAlgorithm.nearest,
          outputFormat: ToolboxImageOutputFormat.png,
          expandCanvas: false,
          canvasMode: ToolboxImageCanvasMode.edge,
          canvasColor: 0xffffff,
          jpegQuality: 92,
        ),
      );

      await expectLater(
        future,
        throwsA(
          isA<ToolboxImageProcessingException>().having(
            (error) => error.code,
            'code',
            ToolboxImageProcessingErrorCode.outputDimensionsTooLarge,
          ),
        ),
      );
    });
  });
}

Uint8List _pngWithDimensions(int width, int height) {
  final bytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 1, height: 1)),
  );
  final data = ByteData.sublistView(bytes);
  data.setUint32(16, width);
  data.setUint32(20, height);
  data.setUint32(29, getCrc32(bytes.sublist(12, 29)));
  return bytes;
}
