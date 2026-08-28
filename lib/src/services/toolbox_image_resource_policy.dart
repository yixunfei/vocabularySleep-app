enum ToolboxImageProcessingErrorCode {
  emptySource,
  sourceFileTooLarge,
  unsupportedFormat,
  sourceDimensionsTooLarge,
  outputDimensionsTooLarge,
  processingFailed,
}

class ToolboxImageProcessingException implements Exception {
  const ToolboxImageProcessingException(
    this.code, {
    this.actualBytes,
    this.width,
    this.height,
    this.cause,
  });

  final ToolboxImageProcessingErrorCode code;
  final int? actualBytes;
  final int? width;
  final int? height;
  final String? cause;

  @override
  String toString() {
    final dimensions = width == null || height == null
        ? ''
        : ', dimensions=${width}x$height';
    final bytes = actualBytes == null ? '' : ', bytes=$actualBytes';
    final reason = cause == null || cause!.isEmpty ? '' : ', cause=$cause';
    return 'ToolboxImageProcessingException(${code.name}$bytes$dimensions$reason)';
  }
}

abstract final class ToolboxImageResourcePolicy {
  static const int maxSourceBytes = 32 * 1024 * 1024;
  static const int maxSourcePixels = 40 * 1000 * 1000;
  static const int maxOutputPixels = 64 * 1000 * 1000;
  static const int maxOutputSide = 16384;
  static const int previewMaxSide = 1600;

  static const String maxSourceBytesLabel = '32 MiB';
  static const String maxSourcePixelsLabel = '40,000,000';
  static const String maxOutputPixelsLabel = '64,000,000';
  static const String maxOutputSideLabel = '16,384';

  static void validateSourceBytes(int byteLength) {
    if (byteLength <= 0) {
      throw const ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.emptySource,
      );
    }
    if (byteLength > maxSourceBytes) {
      throw ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.sourceFileTooLarge,
        actualBytes: byteLength,
      );
    }
  }

  static void validateSourceDimensions(int width, int height) {
    if (width <= 0 || height <= 0) {
      throw ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.unsupportedFormat,
        width: width,
        height: height,
      );
    }
    if (width * height > maxSourcePixels) {
      throw ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.sourceDimensionsTooLarge,
        width: width,
        height: height,
      );
    }
  }

  static void validateOutputDimensions(int width, int height) {
    if (width <= 0 ||
        height <= 0 ||
        width > maxOutputSide ||
        height > maxOutputSide ||
        width * height > maxOutputPixels) {
      throw ToolboxImageProcessingException(
        ToolboxImageProcessingErrorCode.outputDimensionsTooLarge,
        width: width,
        height: height,
      );
    }
  }
}
