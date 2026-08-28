part of 'toolbox_archive_processing_service.dart';

_ArchiveWorkerResponse _encodeArchiveWorker(
  _ArchiveEncodeWorkerRequest request,
) {
  return _guardArchiveWorker(() {
    final entries = request.entries
        .map(
          (entry) => ToolboxArchiveInput(
            relativePath: entry.relativePath,
            bytes: entry.bytes.materialize().asUint8List(),
            fromFolder: false,
          ),
        )
        .toList(growable: false);
    final normalized = _validateAndNormalizeInputs(entries);
    final format = ToolboxArchiveCreateFormat.values.byName(request.format);
    final level = ToolboxArchiveCompressionLevel.values.byName(
      request.compressionLevel,
    );
    final zipAlgorithm = ToolboxArchiveZipAlgorithm.values.byName(
      request.zipAlgorithm,
    );
    final archive = Archive();
    for (final input in normalized) {
      final entry = ArchiveFile.bytes(input.relativePath, input.bytes);
      if (format.isZip) {
        entry.compression = _compressionType(zipAlgorithm);
        if (zipAlgorithm == ToolboxArchiveZipAlgorithm.deflate) {
          entry.compressionLevel = level.deflateLevel;
        }
      }
      archive.addFile(entry);
    }
    final encoded = _encodeArchiveBytes(
      archive: archive,
      singleInput: normalized.singleOrNull?.bytes,
      format: format,
      level: level.deflateLevel,
      password: request.password,
    );
    return _ArchiveWorkerResponse.success(
      encodedBytes: TransferableTypedData.fromList(<Uint8List>[encoded]),
    );
  });
}

_ArchiveWorkerResponse _decodeArchiveWorker(
  _ArchiveDecodeWorkerRequest request,
) {
  return _guardArchiveWorker(() {
    final bytes = request.bytes.materialize().asUint8List();
    ToolboxArchiveResourcePolicy.validateArchiveBytes(bytes.length);
    final format = ToolboxArchiveFormat.values.byName(request.format);
    if (!format.isSupported) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.unsupportedFormat,
        cause: format.name,
      );
    }

    final archive = _decodeArchiveContainer(
      fileName: request.fileName,
      bytes: bytes,
      format: format,
      password: request.password,
    );
    try {
      final entries = _materializeArchiveEntries(
        archive,
        sourceByteLength: bytes.length,
      );
      return _ArchiveWorkerResponse.success(
        decodedEntries: entries,
        format: format.name,
        totalEntryCount: archive.length,
      );
    } finally {
      archive.clearSync();
    }
  });
}

_ArchiveWorkerResponse _guardArchiveWorker(
  _ArchiveWorkerResponse Function() operation,
) {
  try {
    return operation();
  } on ToolboxArchiveProcessingException catch (error) {
    return _ArchiveWorkerResponse.failure(
      errorCode: error.code.name,
      actualValue: error.actualValue,
      limitValue: error.limitValue,
      entryPath: error.entryPath,
      errorCause: error.cause,
    );
  } catch (error) {
    return _ArchiveWorkerResponse.failure(
      errorCode: ToolboxArchiveErrorCode.invalidArchive.name,
      errorCause: error.toString(),
    );
  }
}

Uint8List _encodeArchiveBytes({
  required Archive archive,
  required Uint8List? singleInput,
  required ToolboxArchiveCreateFormat format,
  required int level,
  required String? password,
}) {
  if (format.singleFileOnly && singleInput == null) {
    throw const ToolboxArchiveProcessingException(
      ToolboxArchiveErrorCode.invalidArchive,
      cause: 'Single-file stream format received multiple entries',
    );
  }
  final output = _BoundedOutputStream(
    maxBytes: ToolboxArchiveResourcePolicy.maxArchiveBytes,
    overflowCode: ToolboxArchiveErrorCode.archiveTooLarge,
  );
  switch (format) {
    case ToolboxArchiveCreateFormat.zip:
      ZipEncoder(
        password: password,
      ).encodeStream(archive, output, level: level);
      break;
    case ToolboxArchiveCreateFormat.tar:
      TarEncoder().encodeStream(archive, output);
      break;
    case ToolboxArchiveCreateFormat.tarGzip:
      _encodeCompressedStream(
        _encodeTarIntermediate(archive),
        output,
        format,
        level,
      );
      break;
    case ToolboxArchiveCreateFormat.tarBzip2:
      _encodeCompressedStream(
        _encodeTarIntermediate(archive),
        output,
        format,
        level,
      );
      break;
    case ToolboxArchiveCreateFormat.tarXz:
      _encodeCompressedStream(
        _encodeTarIntermediate(archive),
        output,
        format,
        level,
      );
      break;
    case ToolboxArchiveCreateFormat.gzip:
    case ToolboxArchiveCreateFormat.bzip2:
    case ToolboxArchiveCreateFormat.xz:
      _encodeCompressedStream(singleInput!, output, format, level);
      break;
  }
  final bytes = output.getBytes();
  ToolboxArchiveResourcePolicy.validateArchiveBytes(bytes.length);
  return bytes;
}

Uint8List _encodeTarIntermediate(Archive archive) {
  const maxTarOverheadBytes = ToolboxArchiveResourcePolicy.maxEntryCount * 2048;
  final output = _BoundedOutputStream(
    maxBytes:
        ToolboxArchiveResourcePolicy.maxTotalContentBytes + maxTarOverheadBytes,
    overflowCode: ToolboxArchiveErrorCode.totalContentTooLarge,
  );
  TarEncoder().encodeStream(archive, output);
  return output.getBytes();
}

void _encodeCompressedStream(
  Uint8List inputBytes,
  OutputStream output,
  ToolboxArchiveCreateFormat format,
  int level,
) {
  final input = InputMemoryStream(inputBytes);
  switch (format) {
    case ToolboxArchiveCreateFormat.tarGzip:
    case ToolboxArchiveCreateFormat.gzip:
      const GZipEncoder().encodeStream(input, output, level: level);
      break;
    case ToolboxArchiveCreateFormat.tarBzip2:
    case ToolboxArchiveCreateFormat.bzip2:
      final success = BZip2Encoder().encodeStream(input, output);
      if (!success) {
        throw const ToolboxArchiveProcessingException(
          ToolboxArchiveErrorCode.processingFailed,
          cause: 'BZip2 encoder rejected the input',
        );
      }
      break;
    case ToolboxArchiveCreateFormat.tarXz:
    case ToolboxArchiveCreateFormat.xz:
      XZEncoder().encodeStream(input, output);
      break;
    case ToolboxArchiveCreateFormat.zip:
    case ToolboxArchiveCreateFormat.tar:
      throw ArgumentError.value(format);
  }
}

Archive _decodeArchiveContainer({
  required String fileName,
  required Uint8List bytes,
  required ToolboxArchiveFormat format,
  required String? password,
}) {
  switch (format) {
    case ToolboxArchiveFormat.zip:
      _preflightZip(bytes, password: password);
      return ZipDecoder().decodeBytes(bytes, password: password);
    case ToolboxArchiveFormat.tar:
      return _decodeTar(bytes);
    case ToolboxArchiveFormat.tarGzip:
      return _decodeTar(_decodeCompressedContainer(bytes, format));
    case ToolboxArchiveFormat.gzip:
      return _singleFileArchive(
        _stripCompressionExtension(fileName, '.gz', '.gzip'),
        _decodeSingleCompressedFile(bytes, format),
      );
    case ToolboxArchiveFormat.tarBzip2:
      return _decodeTar(_decodeCompressedContainer(bytes, format));
    case ToolboxArchiveFormat.bzip2:
      return _singleFileArchive(
        _stripCompressionExtension(fileName, '.bz2'),
        _decodeSingleCompressedFile(bytes, format),
      );
    case ToolboxArchiveFormat.tarXz:
      return _decodeTar(_decodeCompressedContainer(bytes, format));
    case ToolboxArchiveFormat.xz:
      return _singleFileArchive(
        _stripCompressionExtension(fileName, '.xz'),
        _decodeSingleCompressedFile(bytes, format),
      );
    case ToolboxArchiveFormat.rar:
    case ToolboxArchiveFormat.sevenZip:
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.unsupportedFormat,
        cause: format.name,
      );
  }
}

Archive _decodeTar(Uint8List bytes) {
  final usedPaths = <String>{};
  var entryCount = 0;
  var totalBytes = 0;
  return TarDecoder().decodeBytes(
    bytes,
    verify: true,
    callback: (entry) {
      entryCount += 1;
      ToolboxArchiveResourcePolicy.validateEntryCount(entryCount);
      final safePath = ToolboxArchivePathPolicy.normalizeSafeRelativePath(
        entry.name,
      );
      final collisionKey = ToolboxArchivePathPolicy.collisionKey(safePath);
      if (!usedPaths.add(collisionKey)) {
        throw ToolboxArchiveProcessingException(
          ToolboxArchiveErrorCode.duplicatePath,
          entryPath: safePath,
        );
      }
      if (entry.isSymbolicLink) {
        throw ToolboxArchiveProcessingException(
          ToolboxArchiveErrorCode.symbolicLink,
          entryPath: safePath,
        );
      }
      if (!entry.isFile) {
        return;
      }
      ToolboxArchiveResourcePolicy.validateEntryBytes(
        entry.size,
        entryPath: safePath,
      );
      totalBytes += entry.size;
      ToolboxArchiveResourcePolicy.validateTotalContentBytes(totalBytes);
    },
  );
}

void _preflightZip(Uint8List bytes, {String? password}) {
  final directory = ZipDirectory()
    ..read(InputMemoryStream(bytes), password: password);
  if (directory.filePosition < 0) {
    throw const ToolboxArchiveProcessingException(
      ToolboxArchiveErrorCode.invalidArchive,
      cause: 'ZIP central directory is missing',
    );
  }
  ToolboxArchiveResourcePolicy.validateEntryCount(
    directory.totalCentralDirectoryEntries,
  );
  ToolboxArchiveResourcePolicy.validateEntryCount(directory.fileHeaders.length);
  if (directory.totalCentralDirectoryEntries != directory.fileHeaders.length) {
    throw ToolboxArchiveProcessingException(
      ToolboxArchiveErrorCode.invalidArchive,
      actualValue: directory.fileHeaders.length,
      limitValue: directory.totalCentralDirectoryEntries,
      cause: 'ZIP central-directory entry count mismatch',
    );
  }
  final usedPaths = <String>{};
  var totalBytes = 0;
  for (final header in directory.fileHeaders) {
    final safePath = ToolboxArchivePathPolicy.normalizeSafeRelativePath(
      header.filename,
    );
    final collisionKey = ToolboxArchivePathPolicy.collisionKey(safePath);
    if (!usedPaths.add(collisionKey)) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.duplicatePath,
        entryPath: safePath,
      );
    }
    final fileType = (header.externalFileAttributes >> 16) & 0xf000;
    if (fileType == 0xa000) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.symbolicLink,
        entryPath: safePath,
      );
    }
    final isDirectory =
        header.filename.endsWith('/') || header.filename.endsWith('\\');
    if (isDirectory) {
      continue;
    }
    if (header.compressionMethod != ZipFile.zipCompressionStore &&
        header.compressionMethod != ZipFile.zipCompressionDeflate &&
        header.compressionMethod != ZipFile.zipCompressionBZip2 &&
        header.compressionMethod != ZipFile.zipCompressionAexEncryption) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.invalidArchive,
        entryPath: safePath,
        cause: 'Unsupported ZIP compression method',
      );
    }
    ToolboxArchiveResourcePolicy.validateEntryBytes(
      header.uncompressedSize,
      entryPath: safePath,
    );
    totalBytes += header.uncompressedSize;
    ToolboxArchiveResourcePolicy.validateTotalContentBytes(totalBytes);
    ToolboxArchiveResourcePolicy.validateCompressionRatio(
      compressedBytes: header.compressedSize,
      uncompressedBytes: header.uncompressedSize,
      entryPath: safePath,
    );
  }
  ToolboxArchiveResourcePolicy.validateCompressionRatio(
    compressedBytes: bytes.length,
    uncompressedBytes: totalBytes,
  );
}

Uint8List _decodeCompressedContainer(
  Uint8List bytes,
  ToolboxArchiveFormat format,
) {
  const maxTarOverheadBytes = ToolboxArchiveResourcePolicy.maxEntryCount * 2048;
  return _decodeCompressedBytes(
    bytes,
    format,
    maxOutputBytes:
        ToolboxArchiveResourcePolicy.maxTotalContentBytes + maxTarOverheadBytes,
    overflowCode: ToolboxArchiveErrorCode.totalContentTooLarge,
  );
}

Uint8List _decodeSingleCompressedFile(
  Uint8List bytes,
  ToolboxArchiveFormat format,
) {
  final ratioLimit =
      bytes.length * ToolboxArchiveResourcePolicy.maxCompressionRatio;
  final maxOutputBytes = math.min(
    ToolboxArchiveResourcePolicy.maxEntryBytes,
    ratioLimit,
  );
  final overflowCode = ratioLimit < ToolboxArchiveResourcePolicy.maxEntryBytes
      ? ToolboxArchiveErrorCode.compressionRatioTooHigh
      : ToolboxArchiveErrorCode.entryTooLarge;
  final decoded = _decodeCompressedBytes(
    bytes,
    format,
    maxOutputBytes: maxOutputBytes,
    overflowCode: overflowCode,
  );
  ToolboxArchiveResourcePolicy.validateEntryBytes(decoded.length);
  ToolboxArchiveResourcePolicy.validateCompressionRatio(
    compressedBytes: bytes.length,
    uncompressedBytes: decoded.length,
  );
  return decoded;
}

Uint8List _decodeCompressedBytes(
  Uint8List bytes,
  ToolboxArchiveFormat format, {
  required int maxOutputBytes,
  required ToolboxArchiveErrorCode overflowCode,
}) {
  final output = _BoundedOutputStream(
    maxBytes: maxOutputBytes,
    overflowCode: overflowCode,
  );
  final input = InputMemoryStream(bytes);
  final success = switch (format) {
    ToolboxArchiveFormat.tarGzip || ToolboxArchiveFormat.gzip =>
      const GZipDecoder().decodeStream(input, output, verify: true),
    ToolboxArchiveFormat.tarBzip2 || ToolboxArchiveFormat.bzip2 =>
      BZip2Decoder().decodeStream(input, output, verify: true),
    ToolboxArchiveFormat.tarXz || ToolboxArchiveFormat.xz =>
      XZDecoder().decodeStream(input, output, verify: true),
    _ => throw ArgumentError.value(format),
  };
  if (!success) {
    throw const ToolboxArchiveProcessingException(
      ToolboxArchiveErrorCode.invalidArchive,
      cause: 'Compressed stream decoder rejected the input',
    );
  }
  return output.getBytes();
}

List<_ArchiveDecodedWorkerEntry> _materializeArchiveEntries(
  Archive archive, {
  required int sourceByteLength,
}) {
  ToolboxArchiveResourcePolicy.validateEntryCount(archive.length);
  final result = <_ArchiveDecodedWorkerEntry>[];
  final usedPaths = <String>{};
  var totalBytes = 0;
  for (final entry in archive.files) {
    final safePath = ToolboxArchivePathPolicy.normalizeSafeRelativePath(
      entry.name,
    );
    final collisionKey = ToolboxArchivePathPolicy.collisionKey(safePath);
    if (!usedPaths.add(collisionKey)) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.duplicatePath,
        entryPath: safePath,
      );
    }
    if (entry.isSymbolicLink) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.symbolicLink,
        entryPath: safePath,
      );
    }
    if (!entry.isFile) {
      result.add(
        _ArchiveDecodedWorkerEntry(
          relativePath: safePath,
          isFile: false,
          bytes: null,
        ),
      );
      continue;
    }

    ToolboxArchiveResourcePolicy.validateEntryBytes(
      entry.size,
      entryPath: safePath,
    );
    final remainingTotal =
        ToolboxArchiveResourcePolicy.maxTotalContentBytes - totalBytes;
    final compressedBytes = entry.rawContent?.length ?? entry.size;
    final ratioLimit =
        compressedBytes * ToolboxArchiveResourcePolicy.maxCompressionRatio;
    final outputLimit = math.min(
      ToolboxArchiveResourcePolicy.maxEntryBytes,
      math.min(remainingTotal, ratioLimit),
    );
    final overflowCode = outputLimit == ratioLimit
        ? ToolboxArchiveErrorCode.compressionRatioTooHigh
        : outputLimit == remainingTotal
        ? ToolboxArchiveErrorCode.totalContentTooLarge
        : ToolboxArchiveErrorCode.entryTooLarge;
    final output = _BoundedOutputStream(
      maxBytes: outputLimit,
      overflowCode: overflowCode,
      entryPath: safePath,
    );
    entry.decompress(output);
    final decodedBytes = output.getBytes();
    ToolboxArchiveResourcePolicy.validateEntryBytes(
      decodedBytes.length,
      entryPath: safePath,
    );
    ToolboxArchiveResourcePolicy.validateCompressionRatio(
      compressedBytes: compressedBytes,
      uncompressedBytes: decodedBytes.length,
      entryPath: safePath,
    );
    if (entry.size != decodedBytes.length) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.invalidArchive,
        actualValue: decodedBytes.length,
        limitValue: entry.size,
        entryPath: safePath,
        cause: 'Decoded size does not match archive metadata',
      );
    }
    if (entry.crc32 != null && getCrc32(decodedBytes) != entry.crc32) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.invalidArchive,
        entryPath: safePath,
        cause: 'Archive entry checksum mismatch',
      );
    }
    totalBytes += decodedBytes.length;
    ToolboxArchiveResourcePolicy.validateTotalContentBytes(totalBytes);
    result.add(
      _ArchiveDecodedWorkerEntry(
        relativePath: safePath,
        isFile: true,
        bytes: TransferableTypedData.fromList(<Uint8List>[decodedBytes]),
      ),
    );
  }
  ToolboxArchiveResourcePolicy.validateCompressionRatio(
    compressedBytes: sourceByteLength,
    uncompressedBytes: totalBytes,
  );
  return result;
}

CompressionType _compressionType(ToolboxArchiveZipAlgorithm algorithm) {
  return switch (algorithm) {
    ToolboxArchiveZipAlgorithm.store => CompressionType.none,
    ToolboxArchiveZipAlgorithm.deflate => CompressionType.deflate,
    ToolboxArchiveZipAlgorithm.bzip2 => CompressionType.bzip2,
  };
}

Archive _singleFileArchive(String fileName, Uint8List bytes) {
  final archive = Archive();
  final safeName = ToolboxArchivePathPolicy.normalizeSafeRelativePath(fileName);
  archive.addFile(ArchiveFile.bytes(safeName, bytes));
  return archive;
}

String _stripCompressionExtension(
  String fileName,
  String extension, [
  String? alternativeExtension,
]) {
  final lowerName = fileName.toLowerCase();
  if (lowerName.endsWith(extension)) {
    return fileName.substring(0, fileName.length - extension.length);
  }
  if (alternativeExtension != null &&
      lowerName.endsWith(alternativeExtension)) {
    return fileName.substring(0, fileName.length - alternativeExtension.length);
  }
  return '$fileName.out';
}

String _uniqueRelativePath(String path, Set<String> usedPaths) {
  var candidate = path;
  var index = 2;
  while (!usedPaths.add(ToolboxArchivePathPolicy.collisionKey(candidate))) {
    final slashIndex = path.lastIndexOf('/');
    final directory = slashIndex < 0 ? '' : path.substring(0, slashIndex + 1);
    final fileName = slashIndex < 0 ? path : path.substring(slashIndex + 1);
    final extension = _compoundExtension(fileName);
    final baseName = extension.isEmpty
        ? fileName
        : fileName.substring(0, fileName.length - extension.length);
    candidate = '$directory${baseName}_$index$extension';
    index += 1;
  }
  return candidate;
}

String _compoundExtension(String fileName) {
  final lowerName = fileName.toLowerCase();
  for (final extension in const <String>['.tar.gz', '.tar.bz2', '.tar.xz']) {
    if (lowerName.endsWith(extension)) {
      return fileName.substring(fileName.length - extension.length);
    }
  }
  final dotIndex = fileName.lastIndexOf('.');
  return dotIndex <= 0 ? '' : fileName.substring(dotIndex);
}

bool _hasPrefix(List<int> bytes, List<int> prefix) {
  if (bytes.length < prefix.length) {
    return false;
  }
  for (var index = 0; index < prefix.length; index += 1) {
    if (bytes[index] != prefix[index]) {
      return false;
    }
  }
  return true;
}

bool _looksLikeTar(List<int> bytes) {
  if (bytes.length < 262) {
    return false;
  }
  return bytes[257] == 0x75 &&
      bytes[258] == 0x73 &&
      bytes[259] == 0x74 &&
      bytes[260] == 0x61 &&
      bytes[261] == 0x72;
}

class _BoundedOutputStream extends OutputStream {
  _BoundedOutputStream({
    required this.maxBytes,
    required this.overflowCode,
    this.entryPath,
    super.byteOrder = ByteOrder.littleEndian,
  });

  final int maxBytes;
  final ToolboxArchiveErrorCode overflowCode;
  final String? entryPath;
  final BytesBuilder _builder = BytesBuilder(copy: false);

  @override
  int get length => _builder.length;

  @override
  void clear() => _builder.clear();

  @override
  void flush() {}

  @override
  void writeByte(int value) {
    _reserve(1);
    _builder.addByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    final writeLength = length ?? bytes.length;
    if (writeLength < 0 || writeLength > bytes.length) {
      throw RangeError.range(writeLength, 0, bytes.length, 'length');
    }
    _reserve(writeLength);
    if (writeLength == bytes.length) {
      _builder.add(bytes);
    } else {
      _builder.add(bytes.sublist(0, writeLength));
    }
  }

  @override
  void writeStream(InputStream stream) {
    while (!stream.isEOS) {
      final chunkLength = math.min(64 * 1024, stream.length);
      if (chunkLength <= 0) {
        break;
      }
      writeBytes(stream.readBytes(chunkLength).toUint8List());
    }
  }

  @override
  Uint8List subset(int start, [int? end]) {
    final bytes = _builder.toBytes();
    final resolvedStart = start < 0 ? bytes.length + start : start;
    final rawEnd = end ?? bytes.length;
    final resolvedEnd = rawEnd < 0 ? bytes.length + rawEnd : rawEnd;
    RangeError.checkValidRange(resolvedStart, resolvedEnd, bytes.length);
    return Uint8List.sublistView(bytes, resolvedStart, resolvedEnd);
  }

  @override
  Uint8List getBytes() => _builder.toBytes();

  void _reserve(int additionalBytes) {
    final nextLength = length + additionalBytes;
    if (nextLength > maxBytes) {
      throw ToolboxArchiveProcessingException(
        overflowCode,
        actualValue: nextLength,
        limitValue: maxBytes,
        entryPath: entryPath,
      );
    }
  }
}

extension<T> on List<T> {
  T? get singleOrNull => length == 1 ? first : null;
}
