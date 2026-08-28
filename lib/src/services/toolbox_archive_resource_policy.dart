enum ToolboxArchiveErrorCode {
  emptyInput,
  archiveTooLarge,
  tooManyEntries,
  entryTooLarge,
  totalContentTooLarge,
  compressionRatioTooHigh,
  unsafePath,
  duplicatePath,
  symbolicLink,
  unsupportedFormat,
  invalidArchive,
  processingFailed,
}

class ToolboxArchiveProcessingException implements Exception {
  const ToolboxArchiveProcessingException(
    this.code, {
    this.actualValue,
    this.limitValue,
    this.entryPath,
    this.cause,
  });

  final ToolboxArchiveErrorCode code;
  final int? actualValue;
  final int? limitValue;
  final String? entryPath;
  final String? cause;

  @override
  String toString() {
    final actual = actualValue == null ? '' : ', actual=$actualValue';
    final limit = limitValue == null ? '' : ', limit=$limitValue';
    final path = entryPath == null ? '' : ', path=$entryPath';
    final reason = cause == null || cause!.isEmpty ? '' : ', cause=$cause';
    return 'ToolboxArchiveProcessingException('
        '${code.name}$actual$limit$path$reason)';
  }
}

abstract final class ToolboxArchiveResourcePolicy {
  static const int maxArchiveBytes = 256 * 1024 * 1024;
  static const int maxEntryCount = 10000;
  static const int maxEntryBytes = 256 * 1024 * 1024;
  static const int maxTotalContentBytes = 1024 * 1024 * 1024;
  static const int maxCompressionRatio = 200;

  static const String maxArchiveBytesLabel = '256 MiB';
  static const String maxEntryCountLabel = '10,000';
  static const String maxEntryBytesLabel = '256 MiB';
  static const String maxTotalContentBytesLabel = '1 GiB';
  static const String maxCompressionRatioLabel = '200:1';

  static void validateArchiveBytes(int byteLength) {
    if (byteLength <= 0) {
      throw const ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.emptyInput,
      );
    }
    if (byteLength > maxArchiveBytes) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.archiveTooLarge,
        actualValue: byteLength,
        limitValue: maxArchiveBytes,
      );
    }
  }

  static void validateEntryCount(int count) {
    if (count > maxEntryCount) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.tooManyEntries,
        actualValue: count,
        limitValue: maxEntryCount,
      );
    }
  }

  static void validateEntryBytes(int byteLength, {String? entryPath}) {
    if (byteLength < 0 || byteLength > maxEntryBytes) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.entryTooLarge,
        actualValue: byteLength,
        limitValue: maxEntryBytes,
        entryPath: entryPath,
      );
    }
  }

  static void validateTotalContentBytes(int byteLength) {
    if (byteLength < 0 || byteLength > maxTotalContentBytes) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.totalContentTooLarge,
        actualValue: byteLength,
        limitValue: maxTotalContentBytes,
      );
    }
  }

  static void validateCompressionRatio({
    required int compressedBytes,
    required int uncompressedBytes,
    String? entryPath,
  }) {
    if (uncompressedBytes <= 0) {
      return;
    }
    if (compressedBytes <= 0 ||
        uncompressedBytes > compressedBytes * maxCompressionRatio) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.compressionRatioTooHigh,
        actualValue: uncompressedBytes,
        limitValue: compressedBytes <= 0
            ? 0
            : compressedBytes * maxCompressionRatio,
        entryPath: entryPath,
      );
    }
  }
}

abstract final class ToolboxArchivePathPolicy {
  static final RegExp _drivePrefix = RegExp(r'^[A-Za-z]:');
  static final RegExp _invalidSegmentChars = RegExp(r'[\x00-\x1f<>:"|?*]');
  static final RegExp _trailingDotsOrSpaces = RegExp(r'[. ]+$');
  static final RegExp _windowsDeviceName = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
    caseSensitive: false,
  );

  static String normalizeSafeRelativePath(String rawPath) {
    final trimmedPath = rawPath.trim();
    final slashPath = trimmedPath.replaceAll('\\', '/');
    if (slashPath.isEmpty ||
        slashPath.contains('\u0000') ||
        slashPath.startsWith('/') ||
        slashPath.startsWith('//') ||
        _drivePrefix.hasMatch(slashPath)) {
      throw _unsafePath(rawPath);
    }

    final withoutTrailingSlash = slashPath.replaceFirst(RegExp(r'/+$'), '');
    final rawSegments = withoutTrailingSlash.split('/');
    if (rawSegments.isEmpty || rawSegments.any((segment) => segment.isEmpty)) {
      throw _unsafePath(rawPath);
    }

    final safeSegments = <String>[];
    for (final rawSegment in rawSegments) {
      final trimmedSegment = rawSegment.trim();
      if (trimmedSegment.isEmpty ||
          trimmedSegment == '.' ||
          trimmedSegment == '..') {
        throw _unsafePath(rawPath);
      }
      var safeSegment = trimmedSegment
          .replaceAll(_invalidSegmentChars, '_')
          .replaceAll(_trailingDotsOrSpaces, '');
      if (safeSegment.isEmpty || safeSegment == '.' || safeSegment == '..') {
        throw _unsafePath(rawPath);
      }
      if (_windowsDeviceName.hasMatch(safeSegment)) {
        safeSegment = '_$safeSegment';
      }
      safeSegments.add(safeSegment);
    }
    return safeSegments.join('/');
  }

  static String collisionKey(String safeRelativePath) {
    return safeRelativePath.toLowerCase();
  }

  static ToolboxArchiveProcessingException _unsafePath(String path) {
    return ToolboxArchiveProcessingException(
      ToolboxArchiveErrorCode.unsafePath,
      entryPath: path,
    );
  }
}
