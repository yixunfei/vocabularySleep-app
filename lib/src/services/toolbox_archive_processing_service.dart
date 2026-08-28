import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import 'toolbox_archive_resource_policy.dart';

part 'toolbox_archive_processing_worker.dart';

enum ToolboxArchiveCreateFormat {
  zip(fileExtension: 'zip'),
  tar(fileExtension: 'tar'),
  tarGzip(fileExtension: 'tar.gz'),
  tarBzip2(fileExtension: 'tar.bz2'),
  tarXz(fileExtension: 'tar.xz'),
  gzip(fileExtension: 'gz', singleFileOnly: true),
  bzip2(fileExtension: 'bz2', singleFileOnly: true),
  xz(fileExtension: 'xz', singleFileOnly: true);

  const ToolboxArchiveCreateFormat({
    required this.fileExtension,
    this.singleFileOnly = false,
  });

  final String fileExtension;
  final bool singleFileOnly;

  bool get isZip => this == ToolboxArchiveCreateFormat.zip;
}

enum ToolboxArchiveCompressionLevel {
  store(0),
  fast(1),
  balanced(6),
  bestSize(9);

  const ToolboxArchiveCompressionLevel(this.deflateLevel);

  final int deflateLevel;
}

enum ToolboxArchiveZipAlgorithm { store, deflate, bzip2 }

enum ToolboxArchiveFormat {
  zip('ZIP'),
  tar('TAR'),
  tarGzip('TAR.GZ'),
  gzip('GZip'),
  tarBzip2('TAR.BZ2'),
  bzip2('BZip2'),
  tarXz('TAR.XZ'),
  xz('XZ'),
  rar('RAR'),
  sevenZip('7z');

  const ToolboxArchiveFormat(this.label);

  final String label;

  bool get isSupported => this != rar && this != sevenZip;
}

class ToolboxArchiveInput {
  const ToolboxArchiveInput({
    required this.relativePath,
    required this.bytes,
    required this.fromFolder,
  });

  final String relativePath;
  final Uint8List bytes;
  final bool fromFolder;

  int get size => bytes.length;

  ToolboxArchiveInput copyWith({String? relativePath}) {
    return ToolboxArchiveInput(
      relativePath: relativePath ?? this.relativePath,
      bytes: bytes,
      fromFolder: fromFolder,
    );
  }
}

class ToolboxArchiveDecodedEntry {
  const ToolboxArchiveDecodedEntry({
    required this.relativePath,
    required this.isFile,
    this.bytes,
  });

  final String relativePath;
  final bool isFile;
  final Uint8List? bytes;

  int get size => bytes?.length ?? 0;
}

class ToolboxArchiveDecodeResult {
  const ToolboxArchiveDecodeResult({
    required this.format,
    required this.entries,
    required this.sourceByteLength,
    required this.totalEntryCount,
  });

  final ToolboxArchiveFormat format;
  final List<ToolboxArchiveDecodedEntry> entries;
  final int sourceByteLength;
  final int totalEntryCount;

  int get fileCount => entries.where((entry) => entry.isFile).length;

  int get totalContentBytes => entries.fold<int>(
    0,
    (total, entry) => total + (entry.isFile ? entry.size : 0),
  );

  void validateForExtraction() {
    ToolboxArchiveResourcePolicy.validateArchiveBytes(sourceByteLength);
    ToolboxArchiveResourcePolicy.validateEntryCount(totalEntryCount);
    ToolboxArchiveResourcePolicy.validateEntryCount(entries.length);
    if (entries.length != totalEntryCount) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.invalidArchive,
        actualValue: entries.length,
        limitValue: totalEntryCount,
        cause: 'Decoded entry count does not match archive metadata',
      );
    }
    final usedPaths = <String>{};
    var totalBytes = 0;
    for (final entry in entries) {
      final safePath = ToolboxArchivePathPolicy.normalizeSafeRelativePath(
        entry.relativePath,
      );
      final collisionKey = ToolboxArchivePathPolicy.collisionKey(safePath);
      if (!usedPaths.add(collisionKey)) {
        throw ToolboxArchiveProcessingException(
          ToolboxArchiveErrorCode.duplicatePath,
          entryPath: safePath,
        );
      }
      if (!entry.isFile) {
        continue;
      }
      ToolboxArchiveResourcePolicy.validateEntryBytes(
        entry.size,
        entryPath: safePath,
      );
      totalBytes += entry.size;
      ToolboxArchiveResourcePolicy.validateTotalContentBytes(totalBytes);
    }
    ToolboxArchiveResourcePolicy.validateCompressionRatio(
      compressedBytes: sourceByteLength,
      uncompressedBytes: totalBytes,
    );
  }
}

class ToolboxArchiveEncodeRequest {
  const ToolboxArchiveEncodeRequest({
    required this.entries,
    required this.format,
    required this.compressionLevel,
    required this.zipAlgorithm,
    this.password,
  });

  final List<ToolboxArchiveInput> entries;
  final ToolboxArchiveCreateFormat format;
  final ToolboxArchiveCompressionLevel compressionLevel;
  final ToolboxArchiveZipAlgorithm zipAlgorithm;
  final String? password;
}

class ToolboxArchiveProcessingService {
  const ToolboxArchiveProcessingService();

  static ToolboxArchiveCreateFormat resolveCreateFormat(
    ToolboxArchiveCreateFormat requested,
    int inputCount,
  ) {
    if (inputCount <= 1 || !requested.singleFileOnly) {
      return requested;
    }
    return switch (requested) {
      ToolboxArchiveCreateFormat.gzip => ToolboxArchiveCreateFormat.tarGzip,
      ToolboxArchiveCreateFormat.bzip2 => ToolboxArchiveCreateFormat.tarBzip2,
      ToolboxArchiveCreateFormat.xz => ToolboxArchiveCreateFormat.tarXz,
      _ => requested,
    };
  }

  static ToolboxArchiveFormat detectFormat(String fileName, List<int> bytes) {
    final lowerName = fileName.toLowerCase();
    if (_hasPrefix(bytes, const <int>[0x37, 0x7a, 0xbc, 0xaf, 0x27, 0x1c]) ||
        lowerName.endsWith('.7z')) {
      return ToolboxArchiveFormat.sevenZip;
    }
    if (_hasPrefix(bytes, const <int>[0x52, 0x61, 0x72, 0x21, 0x1a, 0x07]) ||
        lowerName.endsWith('.rar')) {
      return ToolboxArchiveFormat.rar;
    }
    if (lowerName.endsWith('.tar.gz') || lowerName.endsWith('.tgz')) {
      return ToolboxArchiveFormat.tarGzip;
    }
    if (lowerName.endsWith('.tar.bz2') ||
        lowerName.endsWith('.tbz') ||
        lowerName.endsWith('.tbz2')) {
      return ToolboxArchiveFormat.tarBzip2;
    }
    if (lowerName.endsWith('.tar.xz') || lowerName.endsWith('.txz')) {
      return ToolboxArchiveFormat.tarXz;
    }
    if (_hasPrefix(bytes, const <int>[0x50, 0x4b]) ||
        lowerName.endsWith('.zip')) {
      return ToolboxArchiveFormat.zip;
    }
    if (_hasPrefix(bytes, const <int>[0x1f, 0x8b]) ||
        lowerName.endsWith('.gz') ||
        lowerName.endsWith('.gzip')) {
      return ToolboxArchiveFormat.gzip;
    }
    if (_hasPrefix(bytes, const <int>[0x42, 0x5a, 0x68]) ||
        lowerName.endsWith('.bz2')) {
      return ToolboxArchiveFormat.bzip2;
    }
    if (_hasPrefix(bytes, const <int>[0xfd, 0x37, 0x7a, 0x58, 0x5a, 0x00]) ||
        lowerName.endsWith('.xz')) {
      return ToolboxArchiveFormat.xz;
    }
    if (_looksLikeTar(bytes) || lowerName.endsWith('.tar')) {
      return ToolboxArchiveFormat.tar;
    }
    return ToolboxArchiveFormat.zip;
  }

  static List<ToolboxArchiveInput> normalizeSelectedInputs(
    Iterable<ToolboxArchiveInput> entries,
  ) {
    final normalized = <ToolboxArchiveInput>[];
    final usedPaths = <String>{};
    var totalBytes = 0;
    for (final entry in entries) {
      ToolboxArchiveResourcePolicy.validateEntryCount(normalized.length + 1);
      ToolboxArchiveResourcePolicy.validateEntryBytes(
        entry.size,
        entryPath: entry.relativePath,
      );
      totalBytes += entry.size;
      ToolboxArchiveResourcePolicy.validateTotalContentBytes(totalBytes);
      final safePath = ToolboxArchivePathPolicy.normalizeSafeRelativePath(
        entry.relativePath,
      );
      final uniquePath = _uniqueRelativePath(safePath, usedPaths);
      normalized.add(entry.copyWith(relativePath: uniquePath));
    }
    return List<ToolboxArchiveInput>.unmodifiable(normalized);
  }

  Future<Uint8List> encode(ToolboxArchiveEncodeRequest request) async {
    final entries = _validateAndNormalizeInputs(request.entries);
    final effectiveFormat = resolveCreateFormat(request.format, entries.length);
    final response = await _computeSafely(
      _encodeArchiveWorker,
      _ArchiveEncodeWorkerRequest(
        entries: entries
            .map(
              (entry) => _ArchiveInputWorkerEntry(
                relativePath: entry.relativePath,
                bytes: TransferableTypedData.fromList(<Uint8List>[entry.bytes]),
              ),
            )
            .toList(growable: false),
        format: effectiveFormat.name,
        compressionLevel: request.compressionLevel.name,
        zipAlgorithm: request.zipAlgorithm.name,
        password: request.password,
      ),
      debugLabel: 'toolbox-archive-encode',
    );
    return _materializeEncodedBytes(response);
  }

  Future<Uint8List> encodeDecodedEntriesAsZip(
    ToolboxArchiveDecodeResult archive, {
    required ToolboxArchiveCompressionLevel compressionLevel,
  }) {
    archive.validateForExtraction();
    final entries = archive.entries
        .where((entry) => entry.isFile)
        .map(
          (entry) => ToolboxArchiveInput(
            relativePath: entry.relativePath,
            bytes: entry.bytes!,
            fromFolder: false,
          ),
        )
        .toList(growable: false);
    return encode(
      ToolboxArchiveEncodeRequest(
        entries: entries,
        format: ToolboxArchiveCreateFormat.zip,
        compressionLevel: compressionLevel,
        zipAlgorithm: ToolboxArchiveZipAlgorithm.deflate,
      ),
    );
  }

  Future<ToolboxArchiveDecodeResult> decode({
    required String fileName,
    required Uint8List bytes,
    String? password,
  }) async {
    ToolboxArchiveResourcePolicy.validateArchiveBytes(bytes.length);
    final format = detectFormat(fileName, bytes);
    if (!format.isSupported) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.unsupportedFormat,
        cause: format.name,
      );
    }
    final response = await _computeSafely(
      _decodeArchiveWorker,
      _ArchiveDecodeWorkerRequest(
        fileName: fileName,
        bytes: TransferableTypedData.fromList(<Uint8List>[bytes]),
        format: format.name,
        password: password,
      ),
      debugLabel: 'toolbox-archive-decode',
    );
    final result = _materializeDecodeResult(response, bytes.length);
    result.validateForExtraction();
    return result;
  }
}

class _ArchiveInputWorkerEntry {
  const _ArchiveInputWorkerEntry({
    required this.relativePath,
    required this.bytes,
  });

  final String relativePath;
  final TransferableTypedData bytes;
}

class _ArchiveEncodeWorkerRequest {
  const _ArchiveEncodeWorkerRequest({
    required this.entries,
    required this.format,
    required this.compressionLevel,
    required this.zipAlgorithm,
    required this.password,
  });

  final List<_ArchiveInputWorkerEntry> entries;
  final String format;
  final String compressionLevel;
  final String zipAlgorithm;
  final String? password;
}

class _ArchiveDecodeWorkerRequest {
  const _ArchiveDecodeWorkerRequest({
    required this.fileName,
    required this.bytes,
    required this.format,
    required this.password,
  });

  final String fileName;
  final TransferableTypedData bytes;
  final String format;
  final String? password;
}

class _ArchiveDecodedWorkerEntry {
  const _ArchiveDecodedWorkerEntry({
    required this.relativePath,
    required this.isFile,
    required this.bytes,
  });

  final String relativePath;
  final bool isFile;
  final TransferableTypedData? bytes;
}

class _ArchiveWorkerResponse {
  const _ArchiveWorkerResponse.success({
    this.encodedBytes,
    this.decodedEntries,
    this.format,
    this.totalEntryCount,
  }) : errorCode = null,
       actualValue = null,
       limitValue = null,
       entryPath = null,
       errorCause = null;

  const _ArchiveWorkerResponse.failure({
    required this.errorCode,
    this.actualValue,
    this.limitValue,
    this.entryPath,
    this.errorCause,
  }) : encodedBytes = null,
       decodedEntries = null,
       format = null,
       totalEntryCount = null;

  final TransferableTypedData? encodedBytes;
  final List<_ArchiveDecodedWorkerEntry>? decodedEntries;
  final String? format;
  final int? totalEntryCount;
  final String? errorCode;
  final int? actualValue;
  final int? limitValue;
  final String? entryPath;
  final String? errorCause;
}

Future<_ArchiveWorkerResponse> _computeSafely<Q>(
  ComputeCallback<Q, _ArchiveWorkerResponse> callback,
  Q request, {
  required String debugLabel,
}) async {
  try {
    return await compute(callback, request, debugLabel: debugLabel);
  } catch (error) {
    throw ToolboxArchiveProcessingException(
      ToolboxArchiveErrorCode.processingFailed,
      cause: error.toString(),
    );
  }
}

List<ToolboxArchiveInput> _validateAndNormalizeInputs(
  List<ToolboxArchiveInput> entries,
) {
  if (entries.isEmpty) {
    throw const ToolboxArchiveProcessingException(
      ToolboxArchiveErrorCode.emptyInput,
    );
  }
  ToolboxArchiveResourcePolicy.validateEntryCount(entries.length);
  final normalized = <ToolboxArchiveInput>[];
  final usedPaths = <String>{};
  var totalBytes = 0;
  for (final entry in entries) {
    final safePath = ToolboxArchivePathPolicy.normalizeSafeRelativePath(
      entry.relativePath,
    );
    final collisionKey = ToolboxArchivePathPolicy.collisionKey(safePath);
    if (!usedPaths.add(collisionKey)) {
      throw ToolboxArchiveProcessingException(
        ToolboxArchiveErrorCode.duplicatePath,
        entryPath: safePath,
      );
    }
    ToolboxArchiveResourcePolicy.validateEntryBytes(
      entry.size,
      entryPath: safePath,
    );
    totalBytes += entry.size;
    ToolboxArchiveResourcePolicy.validateTotalContentBytes(totalBytes);
    normalized.add(entry.copyWith(relativePath: safePath));
  }
  return normalized;
}

Uint8List _materializeEncodedBytes(_ArchiveWorkerResponse response) {
  _throwWorkerFailure(response);
  final encodedBytes = response.encodedBytes;
  if (encodedBytes == null) {
    throw const ToolboxArchiveProcessingException(
      ToolboxArchiveErrorCode.processingFailed,
    );
  }
  final bytes = encodedBytes.materialize().asUint8List();
  ToolboxArchiveResourcePolicy.validateArchiveBytes(bytes.length);
  return bytes;
}

ToolboxArchiveDecodeResult _materializeDecodeResult(
  _ArchiveWorkerResponse response,
  int sourceByteLength,
) {
  _throwWorkerFailure(response);
  final formatName = response.format;
  final workerEntries = response.decodedEntries;
  final totalEntryCount = response.totalEntryCount;
  if (formatName == null || workerEntries == null || totalEntryCount == null) {
    throw const ToolboxArchiveProcessingException(
      ToolboxArchiveErrorCode.processingFailed,
    );
  }
  return ToolboxArchiveDecodeResult(
    format: ToolboxArchiveFormat.values.byName(formatName),
    entries: workerEntries
        .map(
          (entry) => ToolboxArchiveDecodedEntry(
            relativePath: entry.relativePath,
            isFile: entry.isFile,
            bytes: entry.bytes?.materialize().asUint8List(),
          ),
        )
        .toList(growable: false),
    sourceByteLength: sourceByteLength,
    totalEntryCount: totalEntryCount,
  );
}

void _throwWorkerFailure(_ArchiveWorkerResponse response) {
  final errorCode = response.errorCode;
  if (errorCode == null) {
    return;
  }
  throw ToolboxArchiveProcessingException(
    ToolboxArchiveErrorCode.values.byName(errorCode),
    actualValue: response.actualValue,
    limitValue: response.limitValue,
    entryPath: response.entryPath,
    cause: response.errorCause,
  );
}
