import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'toolbox_image_resource_policy.dart';

enum ToolboxImageCompressAlgorithm {
  jpegBalanced,
  jpegAggressive,
  pngLossless,
  gifIndexed,
  autoBest,
}

enum ToolboxImageColorMode { original, grayscale, monochrome }

enum ToolboxImageDpiMode { keep, pngMetadata }

enum ToolboxImageOutputFormat { jpg, png, gif }

extension ToolboxImageOutputFormatFileExtension on ToolboxImageOutputFormat {
  String get fileExtension => switch (this) {
    ToolboxImageOutputFormat.jpg => 'jpg',
    ToolboxImageOutputFormat.png => 'png',
    ToolboxImageOutputFormat.gif => 'gif',
  };
}

enum ToolboxImageUpscaleAlgorithm { duplicate, nearest, linear, cubic, average }

enum ToolboxImageCanvasMode { transparent, edge, mirror, solid }

class ToolboxImageSourcePreview {
  const ToolboxImageSourcePreview({
    required this.previewBytes,
    required this.width,
    required this.height,
  });

  final Uint8List previewBytes;
  final int width;
  final int height;
}

class ToolboxImageCompressInput {
  const ToolboxImageCompressInput({
    required this.sourceBytes,
    required this.targetWidth,
    required this.algorithm,
    required this.colorMode,
    required this.dpiMode,
    required this.jpegQuality,
    required this.monochromeThreshold,
    required this.dpi,
  });

  final Uint8List sourceBytes;
  final int targetWidth;
  final ToolboxImageCompressAlgorithm algorithm;
  final ToolboxImageColorMode colorMode;
  final ToolboxImageDpiMode dpiMode;
  final int jpegQuality;
  final double monochromeThreshold;
  final int dpi;
}

class ToolboxImageCompressResult {
  const ToolboxImageCompressResult({
    required this.bytes,
    required this.previewBytes,
    required this.width,
    required this.height,
    required this.algorithm,
    required this.format,
    required this.detail,
  });

  final Uint8List bytes;
  final Uint8List previewBytes;
  final int width;
  final int height;
  final ToolboxImageCompressAlgorithm algorithm;
  final ToolboxImageOutputFormat format;
  final String detail;
}

class ToolboxImageUpscaleInput {
  const ToolboxImageUpscaleInput({
    required this.sourceBytes,
    required this.targetWidth,
    required this.targetHeight,
    required this.algorithm,
    required this.outputFormat,
    required this.expandCanvas,
    required this.canvasMode,
    required this.canvasColor,
    required this.jpegQuality,
  });

  final Uint8List sourceBytes;
  final int targetWidth;
  final int targetHeight;
  final ToolboxImageUpscaleAlgorithm algorithm;
  final ToolboxImageOutputFormat outputFormat;
  final bool expandCanvas;
  final ToolboxImageCanvasMode canvasMode;
  final int canvasColor;
  final int jpegQuality;
}

class ToolboxImageUpscaleResult {
  const ToolboxImageUpscaleResult({
    required this.bytes,
    required this.previewBytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final Uint8List previewBytes;
  final int width;
  final int height;
}

class ToolboxImageProcessingService {
  const ToolboxImageProcessingService();

  Future<ToolboxImageSourcePreview> prepareSource(Uint8List sourceBytes) async {
    ToolboxImageResourcePolicy.validateSourceBytes(sourceBytes.length);
    final response = await _computeSafely(
      _prepareImageSourceWorker,
      _ImageWorkerRequest.source(sourceBytes),
      debugLabel: 'toolbox-image-source-preview',
    );
    final bytes = _materializeSuccessfulBytes(response);
    return ToolboxImageSourcePreview(
      previewBytes: bytes,
      width: response.width,
      height: response.height,
    );
  }

  Future<ToolboxImageCompressResult> compress(
    ToolboxImageCompressInput input,
  ) async {
    ToolboxImageResourcePolicy.validateSourceBytes(input.sourceBytes.length);
    final response = await _computeSafely(
      _compressImageWorker,
      _ImageWorkerRequest.compress(input),
      debugLabel: 'toolbox-image-compress',
    );
    final bytes = _materializeSuccessfulBytes(response);
    return ToolboxImageCompressResult(
      bytes: bytes,
      previewBytes: _materializePreviewBytes(response),
      width: response.width,
      height: response.height,
      algorithm: ToolboxImageCompressAlgorithm.values.byName(
        response.algorithm!,
      ),
      format: ToolboxImageOutputFormat.values.byName(response.format!),
      detail: response.detail!,
    );
  }

  Future<ToolboxImageUpscaleResult> upscale(
    ToolboxImageUpscaleInput input,
  ) async {
    ToolboxImageResourcePolicy.validateSourceBytes(input.sourceBytes.length);
    ToolboxImageResourcePolicy.validateOutputDimensions(
      input.targetWidth,
      input.targetHeight,
    );
    final response = await _computeSafely(
      _upscaleImageWorker,
      _ImageWorkerRequest.upscale(input),
      debugLabel: 'toolbox-image-upscale',
    );
    return ToolboxImageUpscaleResult(
      bytes: _materializeSuccessfulBytes(response),
      previewBytes: _materializePreviewBytes(response),
      width: response.width,
      height: response.height,
    );
  }
}

class _ImageWorkerRequest {
  _ImageWorkerRequest({
    required this.sourceBytes,
    this.targetWidth = 0,
    this.targetHeight = 0,
    this.algorithm = '',
    this.colorMode = '',
    this.dpiMode = '',
    this.outputFormat = '',
    this.expandCanvas = false,
    this.canvasMode = '',
    this.canvasColor = 0,
    this.jpegQuality = 92,
    this.monochromeThreshold = 0.5,
    this.dpi = 144,
  });

  factory _ImageWorkerRequest.source(Uint8List bytes) => _ImageWorkerRequest(
    sourceBytes: TransferableTypedData.fromList(<Uint8List>[bytes]),
  );

  factory _ImageWorkerRequest.compress(ToolboxImageCompressInput input) {
    return _ImageWorkerRequest(
      sourceBytes: TransferableTypedData.fromList(<Uint8List>[
        input.sourceBytes,
      ]),
      targetWidth: input.targetWidth,
      algorithm: input.algorithm.name,
      colorMode: input.colorMode.name,
      dpiMode: input.dpiMode.name,
      jpegQuality: input.jpegQuality,
      monochromeThreshold: input.monochromeThreshold,
      dpi: input.dpi,
    );
  }

  factory _ImageWorkerRequest.upscale(ToolboxImageUpscaleInput input) {
    return _ImageWorkerRequest(
      sourceBytes: TransferableTypedData.fromList(<Uint8List>[
        input.sourceBytes,
      ]),
      targetWidth: input.targetWidth,
      targetHeight: input.targetHeight,
      algorithm: input.algorithm.name,
      outputFormat: input.outputFormat.name,
      expandCanvas: input.expandCanvas,
      canvasMode: input.canvasMode.name,
      canvasColor: input.canvasColor,
      jpegQuality: input.jpegQuality,
    );
  }

  final TransferableTypedData sourceBytes;
  final int targetWidth;
  final int targetHeight;
  final String algorithm;
  final String colorMode;
  final String dpiMode;
  final String outputFormat;
  final bool expandCanvas;
  final String canvasMode;
  final int canvasColor;
  final int jpegQuality;
  final double monochromeThreshold;
  final int dpi;
}

class _ImageWorkerResponse {
  const _ImageWorkerResponse.success({
    required this.bytes,
    required this.width,
    required this.height,
    this.previewBytes,
    this.algorithm,
    this.format,
    this.detail,
  }) : errorCode = null,
       actualBytes = null,
       errorCause = null;

  const _ImageWorkerResponse.failure({
    required this.errorCode,
    this.actualBytes,
    this.width = 0,
    this.height = 0,
    this.errorCause,
  }) : bytes = null,
       previewBytes = null,
       algorithm = null,
       format = null,
       detail = null;

  final TransferableTypedData? bytes;
  final TransferableTypedData? previewBytes;
  final int width;
  final int height;
  final String? algorithm;
  final String? format;
  final String? detail;
  final String? errorCode;
  final int? actualBytes;
  final String? errorCause;
}

Future<_ImageWorkerResponse> _computeSafely(
  ComputeCallback<_ImageWorkerRequest, _ImageWorkerResponse> callback,
  _ImageWorkerRequest request, {
  required String debugLabel,
}) async {
  try {
    return await compute(callback, request, debugLabel: debugLabel);
  } catch (error) {
    throw ToolboxImageProcessingException(
      ToolboxImageProcessingErrorCode.processingFailed,
      cause: error.toString(),
    );
  }
}

Uint8List _materializeSuccessfulBytes(_ImageWorkerResponse response) {
  final errorCode = response.errorCode;
  if (errorCode != null) {
    throw ToolboxImageProcessingException(
      ToolboxImageProcessingErrorCode.values.byName(errorCode),
      actualBytes: response.actualBytes,
      width: response.width == 0 ? null : response.width,
      height: response.height == 0 ? null : response.height,
      cause: response.errorCause,
    );
  }
  final bytes = response.bytes;
  if (bytes == null) {
    throw const ToolboxImageProcessingException(
      ToolboxImageProcessingErrorCode.processingFailed,
    );
  }
  return bytes.materialize().asUint8List();
}

Uint8List _materializePreviewBytes(_ImageWorkerResponse response) {
  final bytes = response.previewBytes;
  if (bytes == null) {
    throw const ToolboxImageProcessingException(
      ToolboxImageProcessingErrorCode.processingFailed,
    );
  }
  return bytes.materialize().asUint8List();
}

_ImageWorkerResponse _prepareImageSourceWorker(_ImageWorkerRequest request) {
  return _guardWorker(() {
    final source = _decodeValidatedSource(request.sourceBytes);
    final longestSide = math.max(source.width, source.height);
    final preview = longestSide <= ToolboxImageResourcePolicy.previewMaxSide
        ? source
        : img.copyResize(
            source,
            width: source.width >= source.height
                ? ToolboxImageResourcePolicy.previewMaxSide
                : null,
            height: source.height > source.width
                ? ToolboxImageResourcePolicy.previewMaxSide
                : null,
            interpolation: img.Interpolation.average,
          );
    final bytes = Uint8List.fromList(
      img.encodePng(preview, level: 1, filter: img.PngFilter.paeth),
    );
    return _successResponse(bytes, source.width, source.height);
  });
}

_ImageWorkerResponse _compressImageWorker(_ImageWorkerRequest request) {
  return _guardWorker(() {
    final source = _decodeValidatedSource(request.sourceBytes);
    final requestedWidth = math.max(1, request.targetWidth);
    final targetWidth = math.min(source.width, requestedWidth);
    final targetHeight = math.max(
      1,
      (source.height * targetWidth / source.width).round(),
    );
    ToolboxImageResourcePolicy.validateOutputDimensions(
      targetWidth,
      targetHeight,
    );
    final resized = targetWidth == source.width
        ? source
        : img.copyResize(
            source,
            width: targetWidth,
            interpolation: img.Interpolation.average,
          );
    final colorMode = ToolboxImageColorMode.values.byName(request.colorMode);
    final preprocessed = _preprocessImage(
      resized,
      colorMode,
      request.monochromeThreshold,
    );
    final algorithm = ToolboxImageCompressAlgorithm.values.byName(
      request.algorithm,
    );
    final candidate = _encodeCompression(preprocessed, algorithm, request);
    return _successResponse(
      candidate.bytes,
      preprocessed.width,
      preprocessed.height,
      previewBytes: _encodePreview(preprocessed),
      algorithm: candidate.algorithm.name,
      format: candidate.format.name,
      detail: candidate.detail,
    );
  });
}

_ImageWorkerResponse _upscaleImageWorker(_ImageWorkerRequest request) {
  return _guardWorker(() {
    ToolboxImageResourcePolicy.validateOutputDimensions(
      request.targetWidth,
      request.targetHeight,
    );
    final source = _decodeValidatedSource(request.sourceBytes);
    final algorithm = ToolboxImageUpscaleAlgorithm.values.byName(
      request.algorithm,
    );
    final output = request.expandCanvas
        ? _expandImageCanvas(source, request, algorithm)
        : _resizeImage(
            source,
            request.targetWidth,
            request.targetHeight,
            algorithm,
          );
    final format = ToolboxImageOutputFormat.values.byName(request.outputFormat);
    final bytes = _encodeUpscaledImage(output, format, request.jpegQuality);
    return _successResponse(
      bytes,
      output.width,
      output.height,
      previewBytes: _encodePreview(output),
    );
  });
}

_ImageWorkerResponse _guardWorker(_ImageWorkerResponse Function() operation) {
  try {
    return operation();
  } on ToolboxImageProcessingException catch (error) {
    return _ImageWorkerResponse.failure(
      errorCode: error.code.name,
      actualBytes: error.actualBytes,
      width: error.width ?? 0,
      height: error.height ?? 0,
      errorCause: error.cause,
    );
  } catch (error) {
    return _ImageWorkerResponse.failure(
      errorCode: ToolboxImageProcessingErrorCode.processingFailed.name,
      errorCause: error.toString(),
    );
  }
}

_ImageWorkerResponse _successResponse(
  Uint8List bytes,
  int width,
  int height, {
  Uint8List? previewBytes,
  String? algorithm,
  String? format,
  String? detail,
}) {
  return _ImageWorkerResponse.success(
    bytes: TransferableTypedData.fromList(<Uint8List>[bytes]),
    previewBytes: previewBytes == null
        ? null
        : TransferableTypedData.fromList(<Uint8List>[previewBytes]),
    width: width,
    height: height,
    algorithm: algorithm,
    format: format,
    detail: detail,
  );
}

Uint8List _encodePreview(img.Image source) {
  final longestSide = math.max(source.width, source.height);
  final preview = longestSide <= ToolboxImageResourcePolicy.previewMaxSide
      ? source
      : img.copyResize(
          source,
          width: source.width >= source.height
              ? ToolboxImageResourcePolicy.previewMaxSide
              : null,
          height: source.height > source.width
              ? ToolboxImageResourcePolicy.previewMaxSide
              : null,
          interpolation: img.Interpolation.average,
        );
  return Uint8List.fromList(
    img.encodePng(preview, level: 1, filter: img.PngFilter.paeth),
  );
}

img.Image _decodeValidatedSource(TransferableTypedData transferableBytes) {
  final bytes = transferableBytes.materialize().asUint8List();
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
  ToolboxImageResourcePolicy.validateSourceDimensions(info.width, info.height);
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
  final oriented = img.bakeOrientation(decoded);
  ToolboxImageResourcePolicy.validateSourceDimensions(
    oriented.width,
    oriented.height,
  );
  return oriented;
}

img.Image _preprocessImage(
  img.Image source,
  ToolboxImageColorMode colorMode,
  double threshold,
) {
  final image = img.Image.from(source);
  return switch (colorMode) {
    ToolboxImageColorMode.original => image,
    ToolboxImageColorMode.grayscale => img.grayscale(image),
    ToolboxImageColorMode.monochrome => img.luminanceThreshold(
      image,
      threshold: threshold.clamp(0.0, 1.0),
    ),
  };
}

class _CompressionCandidate {
  const _CompressionCandidate({
    required this.bytes,
    required this.algorithm,
    required this.format,
    required this.detail,
  });

  final Uint8List bytes;
  final ToolboxImageCompressAlgorithm algorithm;
  final ToolboxImageOutputFormat format;
  final String detail;
}

_CompressionCandidate _encodeCompression(
  img.Image image,
  ToolboxImageCompressAlgorithm algorithm,
  _ImageWorkerRequest request,
) {
  if (algorithm != ToolboxImageCompressAlgorithm.autoBest) {
    return _encodeCompressionCandidate(image, algorithm, request);
  }
  _CompressionCandidate? selected;
  for (final candidateAlgorithm in ToolboxImageCompressAlgorithm.values) {
    if (candidateAlgorithm == ToolboxImageCompressAlgorithm.autoBest) {
      continue;
    }
    final candidate = _encodeCompressionCandidate(
      image,
      candidateAlgorithm,
      request,
    );
    if (selected == null || candidate.bytes.length < selected.bytes.length) {
      selected = candidate;
    }
  }
  final winner = selected!;
  return _CompressionCandidate(
    bytes: winner.bytes,
    algorithm: winner.algorithm,
    format: winner.format,
    detail: 'auto -> ${winner.detail}',
  );
}

_CompressionCandidate _encodeCompressionCandidate(
  img.Image image,
  ToolboxImageCompressAlgorithm algorithm,
  _ImageWorkerRequest request,
) {
  final options = _compressionOptionDetail(request);
  String detail(String value) =>
      <String>[value, ...options].where((part) => part.isNotEmpty).join(' | ');

  switch (algorithm) {
    case ToolboxImageCompressAlgorithm.jpegBalanced:
      final quality = request.jpegQuality.clamp(20, 100);
      return _CompressionCandidate(
        bytes: Uint8List.fromList(
          img.encodeJpg(image, quality: quality, chroma: img.JpegChroma.yuv444),
        ),
        algorithm: algorithm,
        format: ToolboxImageOutputFormat.jpg,
        detail: detail('q$quality yuv444'),
      );
    case ToolboxImageCompressAlgorithm.jpegAggressive:
      final quality = math.max(20, request.jpegQuality - 20).clamp(20, 90);
      return _CompressionCandidate(
        bytes: Uint8List.fromList(
          img.encodeJpg(image, quality: quality, chroma: img.JpegChroma.yuv420),
        ),
        algorithm: algorithm,
        format: ToolboxImageOutputFormat.jpg,
        detail: detail('q$quality yuv420'),
      );
    case ToolboxImageCompressAlgorithm.pngLossless:
      final pixelDimensions =
          request.dpiMode == ToolboxImageDpiMode.pngMetadata.name
          ? img.PngPhysicalPixelDimensions.dpi(request.dpi.clamp(72, 600))
          : null;
      final encoder = img.PngEncoder(
        filter: img.PngFilter.paeth,
        level: 9,
        pixelDimensions: pixelDimensions,
      );
      return _CompressionCandidate(
        bytes: Uint8List.fromList(encoder.encode(image, singleFrame: true)),
        algorithm: algorithm,
        format: ToolboxImageOutputFormat.png,
        detail: detail(
          pixelDimensions == null
              ? 'level9 paeth'
              : 'level9 paeth dpi${request.dpi}',
        ),
      );
    case ToolboxImageCompressAlgorithm.gifIndexed:
      return _CompressionCandidate(
        bytes: Uint8List.fromList(
          img.encodeGif(
            image,
            samplingFactor: 32,
            dither: img.DitherKernel.none,
            ditherSerpentine: false,
          ),
        ),
        algorithm: algorithm,
        format: ToolboxImageOutputFormat.gif,
        detail: detail('indexed256 no-dither'),
      );
    case ToolboxImageCompressAlgorithm.autoBest:
      throw StateError('autoBest must be resolved before encoding');
  }
}

List<String> _compressionOptionDetail(_ImageWorkerRequest request) {
  final colorMode = ToolboxImageColorMode.values.byName(request.colorMode);
  final colorDetail = switch (colorMode) {
    ToolboxImageColorMode.original => 'color',
    ToolboxImageColorMode.grayscale => 'gray',
    ToolboxImageColorMode.monochrome =>
      'bw@${request.monochromeThreshold.toStringAsFixed(2)}',
  };
  final dpiDetail = request.dpiMode == ToolboxImageDpiMode.pngMetadata.name
      ? 'dpi${request.dpi}(png-only)'
      : '';
  return <String>[colorDetail, dpiDetail];
}

img.Image _expandImageCanvas(
  img.Image source,
  _ImageWorkerRequest request,
  ToolboxImageUpscaleAlgorithm algorithm,
) {
  final resized =
      source.width == request.targetWidth &&
          source.height == request.targetHeight
      ? img.Image.from(source)
      : _resizeImage(
          source,
          math.min(source.width, request.targetWidth),
          math.min(source.height, request.targetHeight),
          algorithm,
        );
  final canvasMode = ToolboxImageCanvasMode.values.byName(request.canvasMode);
  if (canvasMode == ToolboxImageCanvasMode.transparent) {
    return img.copyExpandCanvas(
      resized,
      newWidth: request.targetWidth,
      newHeight: request.targetHeight,
    );
  }
  if (canvasMode == ToolboxImageCanvasMode.solid) {
    return img.copyExpandCanvas(
      resized,
      newWidth: request.targetWidth,
      newHeight: request.targetHeight,
      backgroundColor: img.ColorRgb8(
        (request.canvasColor >> 16) & 0xff,
        (request.canvasColor >> 8) & 0xff,
        request.canvasColor & 0xff,
      ),
    );
  }
  return _sampledCanvas(
    resized,
    request.targetWidth,
    request.targetHeight,
    mirror: canvasMode == ToolboxImageCanvasMode.mirror,
  );
}

img.Image _resizeImage(
  img.Image source,
  int width,
  int height,
  ToolboxImageUpscaleAlgorithm algorithm,
) {
  return img.copyResize(
    source,
    width: math.max(1, width),
    height: math.max(1, height),
    interpolation: _interpolationFor(algorithm),
  );
}

img.Interpolation _interpolationFor(ToolboxImageUpscaleAlgorithm algorithm) {
  return switch (algorithm) {
    ToolboxImageUpscaleAlgorithm.duplicate => img.Interpolation.nearest,
    ToolboxImageUpscaleAlgorithm.nearest => img.Interpolation.nearest,
    ToolboxImageUpscaleAlgorithm.linear => img.Interpolation.linear,
    ToolboxImageUpscaleAlgorithm.cubic => img.Interpolation.cubic,
    ToolboxImageUpscaleAlgorithm.average => img.Interpolation.average,
  };
}

img.Image _sampledCanvas(
  img.Image source,
  int width,
  int height, {
  required bool mirror,
}) {
  final canvas = img.Image(
    width: width,
    height: height,
    numChannels: source.numChannels,
  );
  final offsetX = (width - source.width) ~/ 2;
  final offsetY = (height - source.height) ~/ 2;
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final relativeX = x - offsetX;
      final relativeY = y - offsetY;
      final sampleX = mirror
          ? _mirrorSample(relativeX, source.width)
          : relativeX.clamp(0, source.width - 1);
      final sampleY = mirror
          ? _mirrorSample(relativeY, source.height)
          : relativeY.clamp(0, source.height - 1);
      canvas.setPixel(x, y, source.getPixel(sampleX, sampleY));
    }
  }
  return canvas;
}

int _mirrorSample(int value, int length) {
  if (length <= 1) {
    return 0;
  }
  final period = (length - 1) * 2;
  var sample = value % period;
  if (sample < 0) {
    sample += period;
  }
  if (sample >= length) {
    sample = period - sample;
  }
  return sample.clamp(0, length - 1);
}

Uint8List _encodeUpscaledImage(
  img.Image image,
  ToolboxImageOutputFormat format,
  int jpegQuality,
) {
  return switch (format) {
    ToolboxImageOutputFormat.png => Uint8List.fromList(
      img.encodePng(image, level: 6, filter: img.PngFilter.paeth),
    ),
    ToolboxImageOutputFormat.jpg => Uint8List.fromList(
      img.encodeJpg(
        image,
        quality: jpegQuality.clamp(60, 100),
        chroma: img.JpegChroma.yuv444,
      ),
    ),
    ToolboxImageOutputFormat.gif => throw ArgumentError.value(format),
  };
}
