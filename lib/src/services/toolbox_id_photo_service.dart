import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'toolbox_image_resource_policy.dart';

enum ToolboxIdPhotoOutputFormat { png, jpg }

class ToolboxIdPhotoPreset {
  const ToolboxIdPhotoPreset({
    required this.id,
    required this.labelKey,
    required this.mmWidth,
    required this.mmHeight,
    this.noteKey = '',
  });

  final String id;
  final String labelKey;
  final double mmWidth;
  final double mmHeight;
  final String noteKey;

  int pixelWidth(double dpi) => _millimeterToPixel(mmWidth, dpi);

  int pixelHeight(double dpi) => _millimeterToPixel(mmHeight, dpi);

  String pixelPair(double dpi) => '${pixelWidth(dpi)}x${pixelHeight(dpi)}';
}

const List<ToolboxIdPhotoPreset> toolboxIdPhotoPresets = <ToolboxIdPhotoPreset>[
  ToolboxIdPhotoPreset(
    id: 'one_inch',
    labelKey: 'life.id_photo.preset.one_inch',
    mmWidth: 25,
    mmHeight: 35,
  ),
  ToolboxIdPhotoPreset(
    id: 'small_one_inch',
    labelKey: 'life.id_photo.preset.small_one_inch',
    mmWidth: 22,
    mmHeight: 32,
  ),
  ToolboxIdPhotoPreset(
    id: 'large_one_inch',
    labelKey: 'life.id_photo.preset.large_one_inch',
    mmWidth: 33,
    mmHeight: 48,
  ),
  ToolboxIdPhotoPreset(
    id: 'two_inch',
    labelKey: 'life.id_photo.preset.two_inch',
    mmWidth: 35,
    mmHeight: 49,
  ),
  ToolboxIdPhotoPreset(
    id: 'passport',
    labelKey: 'life.id_photo.preset.passport',
    mmWidth: 33,
    mmHeight: 48,
    noteKey: 'life.id_photo.preset.passport.note',
  ),
  ToolboxIdPhotoPreset(
    id: 'visa_2x2',
    labelKey: 'life.id_photo.preset.visa_2x2',
    mmWidth: 50.8,
    mmHeight: 50.8,
    noteKey: 'life.id_photo.preset.visa_2x2.note',
  ),
];

class ToolboxIdPhotoRenderInput {
  const ToolboxIdPhotoRenderInput({
    required this.sourceBytes,
    required this.preset,
    this.dpi = 300,
    this.backgroundColor = 0x438BFF,
    this.outputFormat = ToolboxIdPhotoOutputFormat.png,
    this.jpegQuality = 92,
    this.zoom = 1.18,
    this.offsetX = 0,
    this.offsetY = -0.06,
    this.replaceBackground = true,
    this.backgroundTolerance = 0.44,
    this.replacementStrength = 0.82,
  });

  final Uint8List sourceBytes;
  final ToolboxIdPhotoPreset preset;
  final double dpi;
  final int backgroundColor;
  final ToolboxIdPhotoOutputFormat outputFormat;
  final int jpegQuality;
  final double zoom;
  final double offsetX;
  final double offsetY;
  final bool replaceBackground;
  final double backgroundTolerance;
  final double replacementStrength;
}

class ToolboxIdPhotoRenderResult {
  const ToolboxIdPhotoRenderResult({
    required this.bytes,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
    required this.replacedPixels,
    required this.outputFormat,
  });

  final Uint8List bytes;
  final int pixelWidth;
  final int pixelHeight;
  final int sourceWidth;
  final int sourceHeight;
  final int cropX;
  final int cropY;
  final int cropWidth;
  final int cropHeight;
  final int replacedPixels;
  final ToolboxIdPhotoOutputFormat outputFormat;
}

class ToolboxIdPhotoService {
  const ToolboxIdPhotoService();

  Future<ToolboxIdPhotoRenderResult> render(
    ToolboxIdPhotoRenderInput input,
  ) async {
    ToolboxImageResourcePolicy.validateSourceBytes(input.sourceBytes.length);
    final dpi = input.dpi.clamp(72.0, 600.0).toDouble();
    ToolboxImageResourcePolicy.validateOutputDimensions(
      input.preset.pixelWidth(dpi),
      input.preset.pixelHeight(dpi),
    );
    _IdPhotoWorkerResponse response;
    try {
      response = await compute(
        _renderIdPhotoWorker,
        _IdPhotoWorkerRequest.fromInput(input),
        debugLabel: 'toolbox-id-photo-render',
      );
    } catch (error) {
      throw ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.processingFailed,
        cause: error.toString(),
      );
    }
    return response.materializeResult();
  }

  ToolboxIdPhotoRenderResult _renderSynchronously(
    ToolboxIdPhotoRenderInput input,
  ) {
    final source = _decodeValidatedSource(input.sourceBytes);

    final dpi = input.dpi.clamp(72.0, 600.0).toDouble();
    final targetWidth = input.preset.pixelWidth(dpi);
    final targetHeight = input.preset.pixelHeight(dpi);
    ToolboxImageResourcePolicy.validateOutputDimensions(
      targetWidth,
      targetHeight,
    );
    final crop = _resolveCrop(
      sourceWidth: source.width,
      sourceHeight: source.height,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      zoom: input.zoom,
      offsetX: input.offsetX,
      offsetY: input.offsetY,
    );

    final cropped = img.copyCrop(
      source,
      x: crop.x,
      y: crop.y,
      width: crop.width,
      height: crop.height,
    );
    final resized = img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
    final normalized = resized.convert(numChannels: 4);
    final replacedPixels = _applyBackground(
      normalized,
      backgroundColor: input.backgroundColor,
      enabled: input.replaceBackground,
      tolerance: input.backgroundTolerance,
      strength: input.replacementStrength,
    );
    final bytes = _encode(normalized, input);

    return ToolboxIdPhotoRenderResult(
      bytes: Uint8List.fromList(bytes),
      pixelWidth: targetWidth,
      pixelHeight: targetHeight,
      sourceWidth: source.width,
      sourceHeight: source.height,
      cropX: crop.x,
      cropY: crop.y,
      cropWidth: crop.width,
      cropHeight: crop.height,
      replacedPixels: replacedPixels,
      outputFormat: input.outputFormat,
    );
  }

  img.Image _decodeValidatedSource(Uint8List bytes) {
    ToolboxImageResourcePolicy.validateSourceBytes(bytes.length);
    final decoder = img.findDecoderForData(bytes);
    if (decoder == null) {
      throw const ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.unsupportedFormat,
      );
    }
    img.DecodeInfo? info;
    try {
      info = decoder.startDecode(bytes);
    } catch (error) {
      throw ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.unsupportedFormat,
        cause: error.toString(),
      );
    }
    if (info == null) {
      throw const ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.unsupportedFormat,
      );
    }
    ToolboxImageResourcePolicy.validateSourceDimensions(
      info.width,
      info.height,
    );
    img.Image? decoded;
    try {
      decoded = decoder.decodeFrame(0);
    } catch (error) {
      throw ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.unsupportedFormat,
        width: info.width,
        height: info.height,
        cause: error.toString(),
      );
    }
    if (decoded == null) {
      throw ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.unsupportedFormat,
        width: info.width,
        height: info.height,
      );
    }
    final source = img.bakeOrientation(decoded);
    ToolboxImageResourcePolicy.validateSourceDimensions(
      source.width,
      source.height,
    );
    return source;
  }

  List<int> _encode(img.Image image, ToolboxIdPhotoRenderInput input) {
    switch (input.outputFormat) {
      case ToolboxIdPhotoOutputFormat.png:
        final encoder = img.PngEncoder(
          level: 6,
          filter: img.PngFilter.paeth,
          pixelDimensions: img.PngPhysicalPixelDimensions.dpi(
            input.dpi.round().clamp(72, 600),
          ),
        );
        return encoder.encode(image, singleFrame: true);
      case ToolboxIdPhotoOutputFormat.jpg:
        return img.encodeJpg(
          image,
          quality: input.jpegQuality.clamp(60, 100),
          chroma: img.JpegChroma.yuv444,
        );
    }
  }

  _IdPhotoCrop _resolveCrop({
    required int sourceWidth,
    required int sourceHeight,
    required int targetWidth,
    required int targetHeight,
    required double zoom,
    required double offsetX,
    required double offsetY,
  }) {
    final targetAspect = targetWidth / targetHeight;
    final sourceAspect = sourceWidth / sourceHeight;

    double baseWidth;
    double baseHeight;
    if (sourceAspect > targetAspect) {
      baseHeight = sourceHeight.toDouble();
      baseWidth = sourceHeight * targetAspect;
    } else {
      baseWidth = sourceWidth.toDouble();
      baseHeight = sourceWidth / targetAspect;
    }

    final safeZoom = zoom.clamp(1.0, 3.0).toDouble();
    final cropWidth = math.max(1.0, baseWidth / safeZoom);
    final cropHeight = math.max(1.0, baseHeight / safeZoom);
    final freeX = math.max(0.0, sourceWidth - cropWidth);
    final freeY = math.max(0.0, sourceHeight - cropHeight);
    final x = (freeX / 2 + offsetX.clamp(-1.0, 1.0) * freeX / 2)
        .round()
        .clamp(0, math.max(0, sourceWidth - cropWidth.round()))
        .toInt();
    final y = (freeY / 2 + offsetY.clamp(-1.0, 1.0) * freeY / 2)
        .round()
        .clamp(0, math.max(0, sourceHeight - cropHeight.round()))
        .toInt();

    return _IdPhotoCrop(
      x: x,
      y: y,
      width: cropWidth.round().clamp(1, sourceWidth),
      height: cropHeight.round().clamp(1, sourceHeight),
    );
  }

  int _applyBackground(
    img.Image image, {
    required int backgroundColor,
    required bool enabled,
    required double tolerance,
    required double strength,
  }) {
    final bg = _Rgb.fromInt(backgroundColor);
    final sample = _sampleBackground(image);
    final safeStrength = strength.clamp(0.0, 1.0).toDouble();
    final threshold = 18 + tolerance.clamp(0.0, 1.0) * 150;
    final feather = 28 + tolerance.clamp(0.0, 1.0) * 42;
    var changed = 0;

    for (final pixel in image) {
      var factor = 0.0;
      final alpha = pixel.a.toDouble().clamp(0.0, 255.0);
      if (alpha < 255) {
        factor = math.max(factor, 1 - alpha / 255);
      }
      if (enabled) {
        final distance = _rgbDistance(
          pixel.r.toDouble(),
          pixel.g.toDouble(),
          pixel.b.toDouble(),
          sample,
        );
        if (distance <= threshold) {
          factor = math.max(factor, safeStrength);
        } else if (distance <= threshold + feather) {
          final featherFactor = 1 - (distance - threshold) / feather;
          factor = math.max(factor, safeStrength * featherFactor);
        }
      }

      if (factor <= 0) {
        pixel.a = 255;
        continue;
      }
      changed += 1;
      pixel.setRgba(
        _mix(pixel.r.toDouble(), bg.r, factor),
        _mix(pixel.g.toDouble(), bg.g, factor),
        _mix(pixel.b.toDouble(), bg.b, factor),
        255,
      );
    }
    return changed;
  }

  _Rgb _sampleBackground(img.Image image) {
    final extent = math.max(2, math.min(image.width, image.height) ~/ 12);
    var r = 0.0;
    var g = 0.0;
    var b = 0.0;
    var count = 0;

    void collect(int startX, int startY) {
      final maxX = math.min(image.width, startX + extent);
      final maxY = math.min(image.height, startY + extent);
      for (var y = startY; y < maxY; y += 1) {
        for (var x = startX; x < maxX; x += 1) {
          final pixel = image.getPixel(x, y);
          if (pixel.a < 16) {
            continue;
          }
          r += pixel.r.toDouble();
          g += pixel.g.toDouble();
          b += pixel.b.toDouble();
          count += 1;
        }
      }
    }

    collect(0, 0);
    collect(math.max(0, image.width - extent), 0);
    collect(0, math.max(0, image.height - extent));
    collect(
      math.max(0, image.width - extent),
      math.max(0, image.height - extent),
    );

    if (count == 0) {
      return const _Rgb(255, 255, 255);
    }
    return _Rgb(r / count, g / count, b / count);
  }

  double _rgbDistance(double r, double g, double b, _Rgb target) {
    final dr = r - target.r;
    final dg = g - target.g;
    final db = b - target.b;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  int _mix(double source, double target, double factor) {
    final mixed = source + (target - source) * factor.clamp(0.0, 1.0);
    return mixed.round().clamp(0, 255);
  }
}

class _IdPhotoWorkerRequest {
  _IdPhotoWorkerRequest.fromInput(ToolboxIdPhotoRenderInput input)
    : sourceBytes = TransferableTypedData.fromList(<Uint8List>[
        input.sourceBytes,
      ]),
      preset = input.preset,
      dpi = input.dpi,
      backgroundColor = input.backgroundColor,
      outputFormat = input.outputFormat,
      jpegQuality = input.jpegQuality,
      zoom = input.zoom,
      offsetX = input.offsetX,
      offsetY = input.offsetY,
      replaceBackground = input.replaceBackground,
      backgroundTolerance = input.backgroundTolerance,
      replacementStrength = input.replacementStrength;

  final TransferableTypedData sourceBytes;
  final ToolboxIdPhotoPreset preset;
  final double dpi;
  final int backgroundColor;
  final ToolboxIdPhotoOutputFormat outputFormat;
  final int jpegQuality;
  final double zoom;
  final double offsetX;
  final double offsetY;
  final bool replaceBackground;
  final double backgroundTolerance;
  final double replacementStrength;

  ToolboxIdPhotoRenderInput materializeInput() {
    return ToolboxIdPhotoRenderInput(
      sourceBytes: sourceBytes.materialize().asUint8List(),
      preset: preset,
      dpi: dpi,
      backgroundColor: backgroundColor,
      outputFormat: outputFormat,
      jpegQuality: jpegQuality,
      zoom: zoom,
      offsetX: offsetX,
      offsetY: offsetY,
      replaceBackground: replaceBackground,
      backgroundTolerance: backgroundTolerance,
      replacementStrength: replacementStrength,
    );
  }
}

class _IdPhotoWorkerResponse {
  const _IdPhotoWorkerResponse.success({
    required this.bytes,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.cropX,
    required this.cropY,
    required this.cropWidth,
    required this.cropHeight,
    required this.replacedPixels,
    required this.outputFormat,
  }) : errorCode = null,
       errorWidth = null,
       errorHeight = null,
       errorCause = null;

  const _IdPhotoWorkerResponse.failure({
    required this.errorCode,
    this.errorWidth,
    this.errorHeight,
    this.errorCause,
  }) : bytes = null,
       pixelWidth = 0,
       pixelHeight = 0,
       sourceWidth = 0,
       sourceHeight = 0,
       cropX = 0,
       cropY = 0,
       cropWidth = 0,
       cropHeight = 0,
       replacedPixels = 0,
       outputFormat = ToolboxIdPhotoOutputFormat.png;

  factory _IdPhotoWorkerResponse.fromResult(ToolboxIdPhotoRenderResult result) {
    return _IdPhotoWorkerResponse.success(
      bytes: TransferableTypedData.fromList(<Uint8List>[result.bytes]),
      pixelWidth: result.pixelWidth,
      pixelHeight: result.pixelHeight,
      sourceWidth: result.sourceWidth,
      sourceHeight: result.sourceHeight,
      cropX: result.cropX,
      cropY: result.cropY,
      cropWidth: result.cropWidth,
      cropHeight: result.cropHeight,
      replacedPixels: result.replacedPixels,
      outputFormat: result.outputFormat,
    );
  }

  final TransferableTypedData? bytes;
  final int pixelWidth;
  final int pixelHeight;
  final int sourceWidth;
  final int sourceHeight;
  final int cropX;
  final int cropY;
  final int cropWidth;
  final int cropHeight;
  final int replacedPixels;
  final ToolboxIdPhotoOutputFormat outputFormat;
  final String? errorCode;
  final int? errorWidth;
  final int? errorHeight;
  final String? errorCause;

  ToolboxIdPhotoRenderResult materializeResult() {
    final failureCode = errorCode;
    if (failureCode != null) {
      throw ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.values.byName(failureCode),
        width: errorWidth,
        height: errorHeight,
        cause: errorCause,
      );
    }
    return ToolboxIdPhotoRenderResult(
      bytes: bytes!.materialize().asUint8List(),
      pixelWidth: pixelWidth,
      pixelHeight: pixelHeight,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      cropX: cropX,
      cropY: cropY,
      cropWidth: cropWidth,
      cropHeight: cropHeight,
      replacedPixels: replacedPixels,
      outputFormat: outputFormat,
    );
  }
}

_IdPhotoWorkerResponse _renderIdPhotoWorker(_IdPhotoWorkerRequest request) {
  try {
    final result = const ToolboxIdPhotoService()._renderSynchronously(
      request.materializeInput(),
    );
    return _IdPhotoWorkerResponse.fromResult(result);
  } on ToolboxImageProcessingException catch (error) {
    return _IdPhotoWorkerResponse.failure(
      errorCode: error.code.name,
      errorWidth: error.width,
      errorHeight: error.height,
      errorCause: error.cause,
    );
  } catch (error) {
    return _IdPhotoWorkerResponse.failure(
      errorCode: ToolboxImageProcessingErrorCode.processingFailed.name,
      errorCause: error.toString(),
    );
  }
}

class _IdPhotoCrop {
  const _IdPhotoCrop({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

class _Rgb {
  const _Rgb(this.r, this.g, this.b);

  factory _Rgb.fromInt(int color) {
    return _Rgb(
      ((color >> 16) & 0xff).toDouble(),
      ((color >> 8) & 0xff).toDouble(),
      (color & 0xff).toDouble(),
    );
  }

  final double r;
  final double g;
  final double b;
}

int _millimeterToPixel(double millimeter, double dpi) {
  return math.max(1, ((millimeter / 25.4) * dpi).round());
}
