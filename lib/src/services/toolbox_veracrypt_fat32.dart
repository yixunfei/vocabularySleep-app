part of 'toolbox_veracrypt_service.dart';

/// Outcome of [ToolboxVeraCryptService.openSession].
class ToolboxVeraCryptSessionOpenResult {
  const ToolboxVeraCryptSessionOpenResult({
    required this.status,
    required this.headerUnlockResult,
    this.session,
  });

  final ToolboxVeraCryptSessionStatus status;
  final ToolboxVeraCryptHeaderUnlockResult headerUnlockResult;
  final ToolboxVeraCryptUnlockedSession? session;

  bool get success =>
      status == ToolboxVeraCryptSessionStatus.success && session != null;
}

enum ToolboxVeraCryptSessionStatus {
  success,
  missingHeader,
  missingMaterial,
  invalidPim,
  unsupportedMaterial,
  unlockFailed,
}

/// Outcome of a low-level encrypted data-area write.
class ToolboxVeraCryptDataWriteResult {
  const ToolboxVeraCryptDataWriteResult({
    required this.offsetInDataArea,
    required this.bytesWritten,
    required this.sectorSize,
    required this.sectorStart,
    required this.sectorCount,
  });

  final int offsetInDataArea;
  final int bytesWritten;
  final int sectorSize;
  final int sectorStart;
  final int sectorCount;
}

enum ToolboxVeraCryptFatType { fat12, fat16, fat32 }

extension ToolboxVeraCryptFatTypeInfo on ToolboxVeraCryptFatType {
  int get entryMask {
    return switch (this) {
      ToolboxVeraCryptFatType.fat12 => 0x0fff,
      ToolboxVeraCryptFatType.fat16 => 0xffff,
      ToolboxVeraCryptFatType.fat32 => 0x0fffffff,
    };
  }

  int get endOfChainMin {
    return switch (this) {
      ToolboxVeraCryptFatType.fat12 => 0x0ff8,
      ToolboxVeraCryptFatType.fat16 => 0xfff8,
      ToolboxVeraCryptFatType.fat32 => 0x0ffffff8,
    };
  }

  int get badClusterValue {
    return switch (this) {
      ToolboxVeraCryptFatType.fat12 => 0x0ff7,
      ToolboxVeraCryptFatType.fat16 => 0xfff7,
      ToolboxVeraCryptFatType.fat32 => 0x0ffffff7,
    };
  }
}

extension ToolboxVeraCryptSessionStatusInfo on ToolboxVeraCryptSessionStatus {
  String get labelKey {
    return switch (this) {
      ToolboxVeraCryptSessionStatus.success =>
        'toolbox.crypto.veracrypt.session_status_success',
      ToolboxVeraCryptSessionStatus.missingHeader =>
        'toolbox.crypto.veracrypt.session_status_missing_header',
      ToolboxVeraCryptSessionStatus.missingMaterial =>
        'toolbox.crypto.veracrypt.session_status_missing_material',
      ToolboxVeraCryptSessionStatus.invalidPim =>
        'toolbox.crypto.veracrypt.session_status_invalid_pim',
      ToolboxVeraCryptSessionStatus.unsupportedMaterial =>
        'toolbox.crypto.veracrypt.session_status_unsupported_material',
      ToolboxVeraCryptSessionStatus.unlockFailed =>
        'toolbox.crypto.veracrypt.session_status_unlock_failed',
    };
  }
}

/// A stateful session over an unlocked VeraCrypt container.
///
/// The session retains either an open [RandomAccessFile] (on-disk containers)
/// or an in-memory byte buffer (test containers), plus the data-area master
/// key. It exposes byte-range read primitives and, when explicitly opened as
/// writable, bounded write primitives. FAT32 structure is handled by
/// [ToolboxVeraCryptFat32Volume]. Master key material is never returned to
/// callers and is zeroed on [close].
class ToolboxVeraCryptUnlockedSession {
  ToolboxVeraCryptUnlockedSession._({
    required this._service,
    required this._randomAccessFile,
    required this._byteSource,
    required this.fileSize,
    required this._decoded,
    required this._masterKeyData,
    required this._writable,
  });

  final ToolboxVeraCryptService _service;
  final RandomAccessFile? _randomAccessFile;
  final Uint8List? _byteSource;
  final int fileSize;
  final Uint8List _masterKeyData;
  final bool _writable;
  bool _closed = false;

  final ToolboxVeraCryptDecodedHeader _decoded;
  ToolboxVeraCryptDecodedHeader get decodedHeader => _decoded;

  /// True when this session reads from an in-memory byte buffer (test path)
  /// rather than a live file handle.
  bool get hasByteSource => _byteSource != null;

  int get sectorSize => _decoded.sectorSize;
  int get encryptedAreaStart => _decoded.encryptedAreaStart;
  int get encryptedAreaLength => _decoded.encryptedAreaLength;
  int get volumeSize => _decoded.volumeSize;
  bool get isClosed => _closed;
  bool get isWritable => _writable;

  /// Reads [length] plaintext bytes starting at [offsetInDataArea] (an offset
  /// relative to the start of the encrypted data area, i.e. the FAT32 volume).
  ///
  /// The read is rounded up to whole sectors for decryption then trimmed to
  /// the requested [length]. Returns fewer than [length] bytes if the range
  /// exceeds the available encrypted area.
  Future<Uint8List> readDataAreaBytes({
    required int offsetInDataArea,
    required int length,
  }) async {
    _ensureOpen();
    final sector = sectorSize;
    if (length <= 0) {
      return Uint8List(0);
    }
    RangeError.checkNotNegative(offsetInDataArea, 'offsetInDataArea');
    final availableLength = encryptedAreaLength - offsetInDataArea;
    if (availableLength <= 0) {
      return Uint8List(0);
    }
    final effectiveLength = math.min(length, availableLength);
    final sectorStart = offsetInDataArea ~/ sector;
    final endByte = offsetInDataArea + effectiveLength;
    final sectorEndExclusive = (endByte + sector - 1) ~/ sector;
    final sectorCount = sectorEndExclusive - sectorStart;
    final byteOffsetInArea = sectorStart * sector;
    final readLength = sectorCount * sector;
    final encrypted = await _readEncrypted(
      offsetInDataArea: byteOffsetInArea,
      length: readLength,
    );
    if (encrypted.isEmpty) {
      return Uint8List(0);
    }
    // VeraCrypt derives the XTS tweak from the *absolute* container sector
    // number (file offset / sectorSize), not a sector index relative to the
    // encrypted area. For file-hosted containers FirstDataUnitNo is 0, so the
    // first encrypted data-area sector (at file offset encryptedAreaStart)
    // uses data-unit number `encryptedAreaStart / sectorSize` (e.g. 256 for the
    // standard 131072-byte start). See VeraCrypt EncryptedIoQueue.c:
    //   dataUnit.Value = (request->Offset + request->EncryptedOffset)
    //                    / ENCRYPTION_DATA_UNIT_SIZE;
    // Using a relative 0-based index decrypts synthetic self-consistent
    // containers but produces garbage on real VeraCrypt volumes.
    final absoluteDataUnitStart = (encryptedAreaStart ~/ sector) + sectorStart;
    final plaintext = ToolboxVeraCryptService._headerCrypto.cryptDataUnits(
      input: encrypted,
      masterKeyData: _masterKeyData,
      sectorSize: sector,
      cipherChain: _decoded.cipherChain,
      dataUnitStart: absoluteDataUnitStart,
    );
    final trimStart = offsetInDataArea - byteOffsetInArea;
    final trimEnd = trimStart + effectiveLength;
    return Uint8List.sublistView(plaintext, trimStart, trimEnd);
  }

  /// Synchronous in-memory variant (only valid for byte-source sessions).
  Uint8List readDataAreaBytesSync({
    required int offsetInDataArea,
    required int length,
  }) {
    _ensureOpen();
    if (_byteSource == null) {
      throw StateError(
        'readDataAreaBytesSync requires an in-memory byte source',
      );
    }
    final sector = sectorSize;
    if (length <= 0) {
      return Uint8List(0);
    }
    RangeError.checkNotNegative(offsetInDataArea, 'offsetInDataArea');
    final availableLength = encryptedAreaLength - offsetInDataArea;
    if (availableLength <= 0) {
      return Uint8List(0);
    }
    final effectiveLength = math.min(length, availableLength);
    final sectorStart = offsetInDataArea ~/ sector;
    final endByte = offsetInDataArea + effectiveLength;
    final sectorEndExclusive = (endByte + sector - 1) ~/ sector;
    final sectorCount = sectorEndExclusive - sectorStart;
    final byteOffsetInArea = sectorStart * sector;
    final readLength = sectorCount * sector;
    final encrypted = Uint8List.fromList(
      _service._readBytesWindow(
        _byteSource,
        offset: encryptedAreaStart + byteOffsetInArea,
        length: readLength,
      ),
    );
    if (encrypted.isEmpty) {
      return Uint8List(0);
    }
    // See readDataAreaBytes: VeraCrypt uses the absolute container sector
    // number as the XTS data-unit base, not a 0-based relative index.
    final absoluteDataUnitStart = (encryptedAreaStart ~/ sector) + sectorStart;
    final plaintext = ToolboxVeraCryptService._headerCrypto.cryptDataUnits(
      input: encrypted,
      masterKeyData: _masterKeyData,
      sectorSize: sector,
      cipherChain: _decoded.cipherChain,
      dataUnitStart: absoluteDataUnitStart,
    );
    final trimStart = offsetInDataArea - byteOffsetInArea;
    final trimEnd = trimStart + effectiveLength;
    return Uint8List.sublistView(plaintext, trimStart, trimEnd);
  }

  /// Writes [bytes] as plaintext into the encrypted data area.
  ///
  /// The method performs a sector read-modify-write for unaligned ranges:
  /// affected sectors are decrypted, patched in plaintext, re-encrypted with
  /// the same absolute VeraCrypt data-unit numbering used by reads, then
  /// written back. The session must have been opened with `writable: true`.
  Future<ToolboxVeraCryptDataWriteResult> writeDataAreaBytes({
    required int offsetInDataArea,
    required Uint8List bytes,
  }) async {
    _ensureOpen();
    _ensureWritable();
    RangeError.checkNotNegative(offsetInDataArea, 'offsetInDataArea');
    if (bytes.isEmpty) {
      return ToolboxVeraCryptDataWriteResult(
        offsetInDataArea: offsetInDataArea,
        bytesWritten: 0,
        sectorSize: sectorSize,
        sectorStart: offsetInDataArea ~/ sectorSize,
        sectorCount: 0,
      );
    }
    final endInDataArea = offsetInDataArea + bytes.length;
    if (endInDataArea > encryptedAreaLength) {
      throw RangeError.range(
        endInDataArea,
        0,
        encryptedAreaLength,
        'offsetInDataArea + bytes.length',
      );
    }

    final sector = sectorSize;
    final sectorStart = offsetInDataArea ~/ sector;
    final sectorEndExclusive = (endInDataArea + sector - 1) ~/ sector;
    final sectorCount = sectorEndExclusive - sectorStart;
    final byteOffsetInArea = sectorStart * sector;
    final readLength = sectorCount * sector;
    final encrypted = await _readEncrypted(
      offsetInDataArea: byteOffsetInArea,
      length: readLength,
    );
    if (encrypted.length != readLength) {
      throw StateError('short encrypted read during VeraCrypt write');
    }

    final absoluteDataUnitStart = (encryptedAreaStart ~/ sector) + sectorStart;
    final plaintext = ToolboxVeraCryptService._headerCrypto.cryptDataUnits(
      input: encrypted,
      masterKeyData: _masterKeyData,
      sectorSize: sector,
      cipherChain: _decoded.cipherChain,
      dataUnitStart: absoluteDataUnitStart,
    );
    final trimStart = offsetInDataArea - byteOffsetInArea;
    plaintext.setRange(trimStart, trimStart + bytes.length, bytes);
    final encryptedOut = ToolboxVeraCryptService._headerCrypto.cryptDataUnits(
      input: plaintext,
      masterKeyData: _masterKeyData,
      sectorSize: sector,
      cipherChain: _decoded.cipherChain,
      dataUnitStart: absoluteDataUnitStart,
      encrypt: true,
    );
    await _writeEncrypted(
      offsetInDataArea: byteOffsetInArea,
      bytes: encryptedOut,
    );

    return ToolboxVeraCryptDataWriteResult(
      offsetInDataArea: offsetInDataArea,
      bytesWritten: bytes.length,
      sectorSize: sector,
      sectorStart: sectorStart,
      sectorCount: sectorCount,
    );
  }

  Future<Uint8List> _readEncrypted({
    required int offsetInDataArea,
    required int length,
  }) async {
    final absoluteOffset = encryptedAreaStart + offsetInDataArea;
    if (_randomAccessFile != null) {
      return _service._readFileWindow(
        _randomAccessFile,
        fileSize: fileSize,
        offset: absoluteOffset,
        length: length,
      );
    }
    return Uint8List.fromList(
      _service._readBytesWindow(
        _byteSource!,
        offset: absoluteOffset,
        length: length,
      ),
    );
  }

  Future<void> _writeEncrypted({
    required int offsetInDataArea,
    required Uint8List bytes,
  }) async {
    final absoluteOffset = encryptedAreaStart + offsetInDataArea;
    if (_randomAccessFile != null) {
      await _randomAccessFile.setPosition(absoluteOffset);
      await _randomAccessFile.writeFrom(bytes);
      await _randomAccessFile.flush();
      return;
    }
    _byteSource!.setRange(absoluteOffset, absoluteOffset + bytes.length, bytes);
  }

  /// Lazily opens the FAT32 volume view over this session.
  ///
  /// Throws [ToolboxVeraCryptFat32Exception] when the boot sector is missing,
  /// not FAT32, or the BPB is implausible. The returned volume borrows this
  /// session's read primitives and does not copy the key.
  Future<ToolboxVeraCryptFat32Volume> openFat32Volume() async {
    _ensureOpen();
    return ToolboxVeraCryptFat32Volume._open(this);
  }

  /// Closes the underlying file handle (if any) and zeroes the master key.
  /// Calling [close] more than once is a no-op.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    if (_masterKeyData.isNotEmpty) {
      _masterKeyData.fillRange(0, _masterKeyData.length, 0);
    }
    if (_randomAccessFile != null) {
      try {
        await _randomAccessFile.close();
      } on Object {
        // Best-effort close; surface nothing to callers.
      }
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('VeraCrypt session is closed');
    }
  }

  void _ensureWritable() {
    if (!_writable) {
      throw StateError('VeraCrypt session is read-only');
    }
  }
}

/// A directory or file entry discovered inside a FAT32 volume.
class ToolboxVeraCryptFat32Entry {
  const ToolboxVeraCryptFat32Entry({
    required this.name,
    required this.longName,
    required this.isDirectory,
    required this.size,
    required this.firstCluster,
  });

  /// Best short (8.3) name, never empty.
  final String name;

  /// Long file name when present; empty when the entry only has an 8.3 name.
  final String longName;

  /// Display name: the long name when available, otherwise the short name.
  String get displayName => longName.isNotEmpty ? longName : name;

  final bool isDirectory;
  final int size;
  final int firstCluster;
}

/// Outcome of a directory listing over a FAT volume.
class ToolboxVeraCryptFat32DirectoryResult {
  const ToolboxVeraCryptFat32DirectoryResult({
    required this.entries,
    required this.notes,
  });

  final List<ToolboxVeraCryptFat32Entry> entries;
  final List<String> notes;
}

/// Outcome of a read-only file read over a FAT volume.
class ToolboxVeraCryptFat32FileResult {
  const ToolboxVeraCryptFat32FileResult({
    required this.entry,
    required this.bytes,
    required this.notes,
    required this.truncated,
  });

  final ToolboxVeraCryptFat32Entry entry;
  final Uint8List bytes;
  final List<String> notes;

  /// True when the file exceeded [ToolboxVeraCryptService.maxFat32ReadBytes]
  /// and was clipped.
  final bool truncated;
}

/// Outcome of a same-size overwrite of an existing FAT file.
class ToolboxVeraCryptFat32FileWriteResult {
  const ToolboxVeraCryptFat32FileWriteResult({
    required this.entry,
    required this.bytesWritten,
    required this.clustersTouched,
  });

  final ToolboxVeraCryptFat32Entry entry;
  final int bytesWritten;
  final int clustersTouched;
}

enum ToolboxVeraCryptFat32ErrorCode {
  missingBootSector,
  notFat32,
  implausibleBpb,
  fatChainTooLong,
  fatChainCycle,
  badCluster,
  clusterOutOfRange,
  directoryTooLarge,
  ioFailure,
}

class ToolboxVeraCryptFat32Exception implements Exception {
  const ToolboxVeraCryptFat32Exception(this.code, [this.message]);

  final ToolboxVeraCryptFat32ErrorCode code;
  final String? message;

  String get noteKey {
    return switch (code) {
      ToolboxVeraCryptFat32ErrorCode.missingBootSector =>
        'toolbox.crypto.veracrypt.fs.note.missing_boot_sector',
      ToolboxVeraCryptFat32ErrorCode.notFat32 =>
        'toolbox.crypto.veracrypt.fs.note.not_fat32',
      ToolboxVeraCryptFat32ErrorCode.implausibleBpb =>
        'toolbox.crypto.veracrypt.fs.note.implausible_bpb',
      ToolboxVeraCryptFat32ErrorCode.fatChainTooLong =>
        'toolbox.crypto.veracrypt.fs.note.fat_chain_too_long',
      ToolboxVeraCryptFat32ErrorCode.fatChainCycle =>
        'toolbox.crypto.veracrypt.fs.note.fat_chain_cycle',
      ToolboxVeraCryptFat32ErrorCode.badCluster =>
        'toolbox.crypto.veracrypt.fs.note.bad_cluster',
      ToolboxVeraCryptFat32ErrorCode.clusterOutOfRange =>
        'toolbox.crypto.veracrypt.fs.note.cluster_out_of_range',
      ToolboxVeraCryptFat32ErrorCode.directoryTooLarge =>
        'toolbox.crypto.veracrypt.fs.note.directory_too_large',
      ToolboxVeraCryptFat32ErrorCode.ioFailure =>
        'toolbox.crypto.veracrypt.fs.note.io_failure',
    };
  }

  @override
  String toString() => 'ToolboxVeraCryptFat32Exception($code, $message)';
}

/// FAT volume view over an unlocked VeraCrypt session.
///
/// The volume reads sectors/clusters through the parent session's
/// decrypt-on-read primitives. Writable sessions may also overwrite existing
/// file content without resizing the file or allocating clusters. FAT12/16 use
/// the fixed root-directory area, while FAT32 uses the root cluster from the
/// BPB. FAT chain following, long file name (LFN) reconstruction and directory
/// traversal are bounded by the defensive limits declared on
/// [ToolboxVeraCryptService] to keep damaged or hostile containers from
/// exhausting mobile memory.
class ToolboxVeraCryptFat32Volume {
  ToolboxVeraCryptFat32Volume._({
    required this.session,
    required this.fatType,
    required this.bytesPerSector,
    required this.sectorsPerCluster,
    required this.reservedSectorCount,
    required this.numFats,
    required this.sectorsPerFat,
    required this.rootEntryCount,
    required this.rootDirectorySectors,
    required this.rootCluster,
    required this.clusterCount,
    required this.bytesPerCluster,
  });

  final ToolboxVeraCryptUnlockedSession session;
  final ToolboxVeraCryptFatType fatType;
  final int bytesPerSector;
  final int sectorsPerCluster;
  final int reservedSectorCount;
  final int numFats;
  final int sectorsPerFat;
  final int rootEntryCount;
  final int rootDirectorySectors;
  final int rootCluster;
  final int clusterCount;
  final int bytesPerCluster;

  /// Backward-compatible FAT32 BPB field exposure. FAT12/16 return 0 because
  /// their BPB stores the value in the 16-bit sectors-per-FAT field.
  int get sectorsPerFat32 =>
      fatType == ToolboxVeraCryptFatType.fat32 ? sectorsPerFat : 0;

  /// Offset (within the FAT volume / encrypted data area) where the first
  /// FAT begins.
  int get fat0Offset => reservedSectorCount * bytesPerSector;

  /// Offset of the fixed root directory area used by FAT12/16.
  int get rootDirectoryOffset =>
      (reservedSectorCount + numFats * sectorsPerFat) * bytesPerSector;

  /// Offset where the cluster region begins (cluster 2 lives here).
  int get clusterRegionOffset =>
      (reservedSectorCount + numFats * sectorsPerFat + rootDirectorySectors) *
      bytesPerSector;

  /// Converts a cluster number to its byte offset within the data area.
  int clusterToDataAreaOffset(int cluster) {
    return clusterRegionOffset + (cluster - 2) * bytesPerCluster;
  }

  static Future<ToolboxVeraCryptFat32Volume> _open(
    ToolboxVeraCryptUnlockedSession session,
  ) async {
    // FAT boot sector is always the first sector of the encrypted volume.
    final boot = session.hasByteSource
        ? session.readDataAreaBytesSync(offsetInDataArea: 0, length: 512)
        : await session.readDataAreaBytes(offsetInDataArea: 0, length: 512);
    if (boot.length < 512) {
      throw ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.missingBootSector,
        'decrypted ${boot.length}/512 bytes; '
        'encryptedAreaStart=${session.encryptedAreaStart} '
        'encryptedAreaLength=${session.encryptedAreaLength} '
        'sectorSize=${session.sectorSize}',
      );
    }
    if (!(boot[510] == 0x55 && boot[511] == 0xaa)) {
      final hex = StringBuffer();
      for (var i = 0; i < 32; i += 1) {
        hex.write(boot[i].toRadixString(16).padLeft(2, '0'));
      }
      throw ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.missingBootSector,
        'no FAT boot signature 0x55AA; '
        'bytes[510..511]=0x'
        '${boot[510].toRadixString(16).padLeft(2, '0')}'
        '${boot[511].toRadixString(16).padLeft(2, '0')}; '
        'first 32 decrypted bytes=0x$hex; '
        'encryptedAreaStart=${session.encryptedAreaStart} '
        'sectorSize=${session.sectorSize}',
      );
    }
    final bytesPerSector = boot[11] | (boot[12] << 8);
    final sectorsPerCluster = boot[13];
    final reservedSectorCount = boot[14] | (boot[15] << 8);
    final numFats = boot[16];
    final rootEntryCount = boot[17] | (boot[18] << 8);
    final totalSectors16 = boot[19] | (boot[20] << 8);
    final sectorsPerFat16 = boot[22] | (boot[23] << 8);
    final totalSectors32 =
        boot[32] | (boot[33] << 8) | (boot[34] << 16) | (boot[35] << 24);
    final sectorsPerFat32 =
        boot[36] | (boot[37] << 8) | (boot[38] << 16) | (boot[39] << 24);
    final rootCluster =
        boot[44] | (boot[45] << 8) | (boot[46] << 16) | (boot[47] << 24);
    final totalSectors = totalSectors16 != 0 ? totalSectors16 : totalSectors32;
    final fat32StyleBpb = rootEntryCount == 0 && sectorsPerFat16 == 0;
    final sectorsPerFat = fat32StyleBpb ? sectorsPerFat32 : sectorsPerFat16;
    if (bytesPerSector == 0 ||
        sectorsPerCluster == 0 ||
        reservedSectorCount == 0 ||
        numFats == 0 ||
        totalSectors == 0 ||
        sectorsPerFat == 0) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
      );
    }
    const plausibleSectorSizes = <int>{512, 1024, 2048, 4096};
    if (!plausibleSectorSizes.contains(bytesPerSector)) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.notFat32,
      );
    }
    if (sectorsPerCluster & (sectorsPerCluster - 1) != 0 ||
        sectorsPerCluster > 128) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
      );
    }
    if (numFats < 1 || numFats > 2) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
      );
    }
    if (fat32StyleBpb && sectorsPerFat32 == 0) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
      );
    }
    if (!fat32StyleBpb && rootEntryCount == 0) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
      );
    }
    final bytesPerCluster = bytesPerSector * sectorsPerCluster;
    final volumeSectors = session.encryptedAreaLength ~/ bytesPerSector;
    if (totalSectors > volumeSectors) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
      );
    }
    final rootDirectorySectors =
        ((rootEntryCount * 32) + bytesPerSector - 1) ~/ bytesPerSector;
    final clusterRegionSector =
        reservedSectorCount + numFats * sectorsPerFat + rootDirectorySectors;
    if (clusterRegionSector >= totalSectors) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
      );
    }
    final dataSectors = totalSectors - clusterRegionSector;
    final clusterCount = dataSectors ~/ sectorsPerCluster;
    if (clusterCount <= 0 ||
        clusterCount > ToolboxVeraCryptService.maxFat32ClusterCount) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
      );
    }
    final fatType = fat32StyleBpb
        ? ToolboxVeraCryptFatType.fat32
        : clusterCount < 4085
        ? ToolboxVeraCryptFatType.fat12
        : ToolboxVeraCryptFatType.fat16;
    if (fatType == ToolboxVeraCryptFatType.fat32 &&
        (rootCluster < 2 || rootCluster - 2 >= clusterCount)) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
      );
    }
    final fatEntryCapacity = switch (fatType) {
      ToolboxVeraCryptFatType.fat12 =>
        (sectorsPerFat * bytesPerSector * 2) ~/ 3,
      ToolboxVeraCryptFatType.fat16 => (sectorsPerFat * bytesPerSector) ~/ 2,
      ToolboxVeraCryptFatType.fat32 => (sectorsPerFat * bytesPerSector) ~/ 4,
    };
    if (clusterCount + 2 > fatEntryCapacity) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
      );
    }
    return ToolboxVeraCryptFat32Volume._(
      session: session,
      fatType: fatType,
      bytesPerSector: bytesPerSector,
      sectorsPerCluster: sectorsPerCluster,
      reservedSectorCount: reservedSectorCount,
      numFats: numFats,
      sectorsPerFat: sectorsPerFat,
      rootEntryCount: rootEntryCount,
      rootDirectorySectors: rootDirectorySectors,
      rootCluster: fatType == ToolboxVeraCryptFatType.fat32 ? rootCluster : 0,
      clusterCount: clusterCount,
      bytesPerCluster: bytesPerCluster,
    );
  }

  /// Reads the FAT entry for [cluster] using the active FAT12/16/32 packing.
  Future<int> _fatEntry(int cluster) async {
    final (offset, length) = switch (fatType) {
      ToolboxVeraCryptFatType.fat12 => (
        fat0Offset + cluster + (cluster ~/ 2),
        2,
      ),
      ToolboxVeraCryptFatType.fat16 => (fat0Offset + cluster * 2, 2),
      ToolboxVeraCryptFatType.fat32 => (fat0Offset + cluster * 4, 4),
    };
    final raw = session.hasByteSource
        ? session.readDataAreaBytesSync(
            offsetInDataArea: offset,
            length: length,
          )
        : await session.readDataAreaBytes(
            offsetInDataArea: offset,
            length: length,
          );
    if (raw.length < length) {
      throw ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.ioFailure,
        'short FAT read for cluster $cluster',
      );
    }
    return switch (fatType) {
      ToolboxVeraCryptFatType.fat12 =>
        cluster.isEven
            ? (raw[0] | (raw[1] << 8)) & 0x0fff
            : ((raw[0] | (raw[1] << 8)) >> 4) & 0x0fff,
      ToolboxVeraCryptFatType.fat16 => raw[0] | (raw[1] << 8),
      ToolboxVeraCryptFatType.fat32 =>
        (raw[0] | (raw[1] << 8) | (raw[2] << 16) | (raw[3] << 24)) & 0x0fffffff,
    };
  }

  bool _isEndOfChain(int entry) {
    final masked = entry & fatType.entryMask;
    return masked >= fatType.endOfChainMin && masked <= fatType.entryMask;
  }

  /// Follows a cluster chain starting at [firstCluster], returning the list of
  /// cluster numbers in walk order. Defensive against cycles and overlong
  /// chains.
  Future<List<int>> _followChain(
    int firstCluster, {
    int maxClusters = ToolboxVeraCryptService.maxFat32ClusterChain,
    ToolboxVeraCryptFat32ErrorCode limitErrorCode =
        ToolboxVeraCryptFat32ErrorCode.fatChainTooLong,
  }) async {
    if (maxClusters <= 0) {
      throw ToolboxVeraCryptFat32Exception(limitErrorCode);
    }
    if (firstCluster < 2 || firstCluster - 2 >= clusterCount) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.clusterOutOfRange,
      );
    }
    final chain = <int>[firstCluster];
    final visited = <int>{firstCluster};
    var current = firstCluster;
    while (chain.length < maxClusters) {
      final next = (await _fatEntry(current)) & fatType.entryMask;
      if (next == fatType.badClusterValue) {
        throw const ToolboxVeraCryptFat32Exception(
          ToolboxVeraCryptFat32ErrorCode.badCluster,
        );
      }
      if (_isEndOfChain(next)) {
        return chain;
      }
      if (next < 2 || next - 2 >= clusterCount) {
        throw const ToolboxVeraCryptFat32Exception(
          ToolboxVeraCryptFat32ErrorCode.clusterOutOfRange,
        );
      }
      if (!visited.add(next)) {
        throw const ToolboxVeraCryptFat32Exception(
          ToolboxVeraCryptFat32ErrorCode.fatChainCycle,
        );
      }
      chain.add(next);
      current = next;
    }
    throw ToolboxVeraCryptFat32Exception(limitErrorCode);
  }

  /// Lists the contents of the directory whose first cluster is [dirCluster].
  /// Pass [rootCluster] to list the root. For FAT12/16, [rootCluster] is 0 and
  /// maps to the fixed root-directory area outside the cluster region.
  Future<ToolboxVeraCryptFat32DirectoryResult> listDirectory({
    required int dirCluster,
  }) async {
    final bytes = _isFixedRootDirectory(dirCluster)
        ? await _readFixedRootDirectoryBytes()
        : await _readClusterChainBytes(dirCluster);
    final entries = _parseDirectoryBytes(bytes);
    return ToolboxVeraCryptFat32DirectoryResult(
      entries: entries,
      notes: const <String>[
        'toolbox.crypto.veracrypt.fs.note.read_only_directory',
      ],
    );
  }

  bool _isFixedRootDirectory(int dirCluster) {
    return fatType != ToolboxVeraCryptFatType.fat32 &&
        dirCluster == rootCluster;
  }

  Future<Uint8List> _readFixedRootDirectoryBytes() async {
    final length = rootEntryCount * 32;
    if (length > ToolboxVeraCryptService.maxFat32DirectoryBytes) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.directoryTooLarge,
      );
    }
    final chunk = session.hasByteSource
        ? session.readDataAreaBytesSync(
            offsetInDataArea: rootDirectoryOffset,
            length: length,
          )
        : await session.readDataAreaBytes(
            offsetInDataArea: rootDirectoryOffset,
            length: length,
          );
    if (chunk.length != length) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.ioFailure,
      );
    }
    return chunk;
  }

  Future<Uint8List> _readClusterChainBytes(int firstCluster) async {
    final maxBytes = ToolboxVeraCryptService.maxFat32DirectoryBytes;
    if (bytesPerCluster > maxBytes) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.directoryTooLarge,
      );
    }
    final maxClustersForDirectory = math.min(
      ToolboxVeraCryptService.maxFat32ClusterChain,
      maxBytes ~/ bytesPerCluster,
    );
    final chain = await _followChain(
      firstCluster,
      maxClusters: maxClustersForDirectory,
      limitErrorCode: ToolboxVeraCryptFat32ErrorCode.directoryTooLarge,
    );
    final out = Uint8List(chain.length * bytesPerCluster);
    for (var i = 0; i < chain.length; i += 1) {
      final cluster = chain[i];
      final offset = clusterToDataAreaOffset(cluster);
      final chunk = session.hasByteSource
          ? session.readDataAreaBytesSync(
              offsetInDataArea: offset,
              length: bytesPerCluster,
            )
          : await session.readDataAreaBytes(
              offsetInDataArea: offset,
              length: bytesPerCluster,
            );
      if (chunk.length != bytesPerCluster) {
        throw const ToolboxVeraCryptFat32Exception(
          ToolboxVeraCryptFat32ErrorCode.ioFailure,
        );
      }
      out.setRange(i * bytesPerCluster, (i + 1) * bytesPerCluster, chunk);
    }
    return out;
  }

  List<ToolboxVeraCryptFat32Entry> _parseDirectoryBytes(Uint8List bytes) {
    final entries = <ToolboxVeraCryptFat32Entry>[];
    // LFN components accumulate here, most recent (highest seq) first.
    final lfnParts = <String>[];
    // Checksum of the current LFN sequence (0 means none accumulated). The FAT
    // spec requires every LFN slot of a name to share one checksum that must
    // equal the checksum computed from the following 8.3 short entry. Mismatch
    // means the LFN slots are orphaned (e.g. leftovers across a delete) and
    // must be discarded rather than contaminating the short name.
    var lfnChecksum = 0;
    final maxEntries = ToolboxVeraCryptService.maxFat32DirectoryEntries;
    for (
      var offset = 0;
      offset + 32 <= bytes.length && entries.length < maxEntries;
      offset += 32
    ) {
      final first = bytes[offset];
      if (first == 0x00) {
        // End-of-directory marker; no further entries exist.
        break;
      }
      if (first == 0xe5) {
        // Deleted entry; reset any orphaned LFN sequence.
        lfnParts.clear();
        lfnChecksum = 0;
        continue;
      }
      final attr = bytes[offset + 11];
      final isLfn = attr == 0x0f;
      if (isLfn) {
        final slotChecksum = bytes[offset + 13] & 0xff;
        if (lfnParts.isEmpty) {
          lfnChecksum = slotChecksum;
        } else if (slotChecksum != lfnChecksum) {
          // New LFN sequence began under a different checksum; drop the old one.
          lfnParts.clear();
          lfnChecksum = slotChecksum;
        }
        lfnParts.insert(0, _decodeLfnEntry(bytes, offset));
        continue;
      }
      final isVolumeLabel = (attr & 0x08) != 0;
      if (isVolumeLabel) {
        lfnParts.clear();
        lfnChecksum = 0;
        continue;
      }
      final isDirectory = (attr & 0x10) != 0;
      final name = _decodeShortName(bytes, offset);
      if (name.isEmpty || name == '.' || name == '..') {
        // "." and ".." are navigation-only; skip from listing.
        lfnParts.clear();
        lfnChecksum = 0;
        continue;
      }
      // Validate the accumulated LFN sequence against this short entry's
      // checksum. Mismatch -> discard the LFN and fall back to the short name.
      if (lfnParts.isNotEmpty &&
          lfnChecksum != _shortNameChecksum(bytes, offset)) {
        lfnParts.clear();
      }
      final firstClusterHigh = bytes[offset + 20] | (bytes[offset + 21] << 8);
      final firstClusterLow = bytes[offset + 26] | (bytes[offset + 27] << 8);
      final firstCluster = fatType == ToolboxVeraCryptFatType.fat32
          ? (firstClusterHigh << 16) | firstClusterLow
          : firstClusterLow;
      final size =
          bytes[offset + 28] |
          (bytes[offset + 29] << 8) |
          (bytes[offset + 30] << 16) |
          (bytes[offset + 31] << 24);
      final longName = _joinLfn(lfnParts);
      lfnParts.clear();
      lfnChecksum = 0;
      entries.add(
        ToolboxVeraCryptFat32Entry(
          name: name,
          longName: longName,
          isDirectory: isDirectory,
          size: isDirectory ? 0 : size,
          firstCluster: firstCluster,
        ),
      );
    }
    if (entries.length >= maxEntries) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.directoryTooLarge,
      );
    }
    return entries;
  }

  /// FAT32 long-file-name checksum over the 11-byte 8.3 field at [offset].
  /// Algorithm per Microsoft FAT spec (the same one VeraCrypt's keyfile code is
  /// unrelated to; this is the directory-entry LFN checksum).
  int _shortNameChecksum(Uint8List bytes, int offset) {
    var sum = 0;
    for (var i = 0; i < 11; i += 1) {
      // (sum >> 1) + (sum << 7) on 8 bits; the & 0xff keeps it in a byte.
      sum = (((sum & 1) << 7) | (sum >> 1)) + bytes[offset + i];
      sum &= 0xff;
    }
    return sum;
  }

  String _decodeShortName(Uint8List bytes, int offset) {
    final nameBytes = bytes.sublist(offset, offset + 8);
    final extBytes = bytes.sublist(offset + 8, offset + 11);
    // Offset +12 is the NT/Reserved "case info" byte. Bit 0x08 = base name
    // lowercased, bit 0x10 = extension lowercased. Only meaningful for NT-generated
    // volumes; ignored when a long name is present (LFN path is authoritative).
    final caseInfo = bytes[offset + 12];
    final baseLower = (caseInfo & 0x08) != 0;
    final extLower = (caseInfo & 0x10) != 0;
    String trimTrailing(Uint8List region) {
      final cut = region.indexWhere((b) => b == 0x20);
      final end = cut < 0 ? region.length : cut;
      return String.fromCharCodes(
        region.sublist(0, end).where((b) => b != 0).toList(growable: false),
      );
    }

    final base = trimTrailing(nameBytes);
    final ext = trimTrailing(extBytes);
    if (base.isEmpty) {
      return '';
    }
    final baseFinal = baseLower ? base.toLowerCase() : base;
    final extFinal = ext.isEmpty ? '' : (extLower ? ext.toLowerCase() : ext);
    return extFinal.isEmpty ? baseFinal : '$baseFinal.$extFinal';
  }

  String _decodeLfnEntry(Uint8List bytes, int offset) {
    // LFN entry layout: chars at [1..5], [14..17], [28..31], each 2 bytes LE.
    int readChar(int pos) {
      return bytes[pos] | (bytes[pos + 1] << 8);
    }

    final units = <int>[];
    for (var i = 1; i <= 9; i += 2) {
      final ch = readChar(offset + i);
      if (ch == 0 || ch == 0xffff) {
        return String.fromCharCodes(units);
      }
      units.add(ch);
    }
    for (var i = 14; i <= 24; i += 2) {
      final ch = readChar(offset + i);
      if (ch == 0 || ch == 0xffff) {
        return String.fromCharCodes(units);
      }
      units.add(ch);
    }
    for (var i = 28; i <= 30; i += 2) {
      final ch = readChar(offset + i);
      if (ch == 0 || ch == 0xffff) {
        return String.fromCharCodes(units);
      }
      units.add(ch);
    }
    return String.fromCharCodes(units);
  }

  String _joinLfn(List<String> parts) {
    if (parts.isEmpty) {
      return '';
    }
    final joined = parts.join();
    // Strip trailing 0/0xffff sentinels that may survive concatenation.
    return joined.replaceAll(RegExp(r'[\x00\uffff]'), '');
  }

  /// Reads up to [ToolboxVeraCryptService.maxFat32ReadBytes] bytes of the file
  /// described by [entry]. If the file is larger, the result is truncated and
  /// flagged.
  Future<ToolboxVeraCryptFat32FileResult> readFile({
    required ToolboxVeraCryptFat32Entry entry,
  }) async {
    if (entry.isDirectory) {
      throw ArgumentError.value(entry.name, 'entry', 'is a directory');
    }
    final maxBytes = ToolboxVeraCryptService.maxFat32ReadBytes;
    final truncated = entry.size > maxBytes;
    final readLength = truncated ? maxBytes : entry.size;
    // FAT32 zero-length files carry firstCluster=0 and consume no cluster.
    // size>0 with firstCluster<2 stays a damaged-volume case and is handled
    // below by _followChain (which rejects clusters < 2 as out of range).
    if (readLength == 0) {
      return ToolboxVeraCryptFat32FileResult(
        entry: entry,
        bytes: Uint8List(0),
        notes: const <String>[
          'toolbox.crypto.veracrypt.fs.note.read_only_file',
        ],
        truncated: false,
      );
    }
    final chain = await _followChain(entry.firstCluster);
    final out = Uint8List(readLength);
    var written = 0;
    for (final cluster in chain) {
      if (written >= readLength) {
        break;
      }
      final offset = clusterToDataAreaOffset(cluster);
      final chunk = session.hasByteSource
          ? session.readDataAreaBytesSync(
              offsetInDataArea: offset,
              length: bytesPerCluster,
            )
          : await session.readDataAreaBytes(
              offsetInDataArea: offset,
              length: bytesPerCluster,
            );
      final copyLength = math.min(chunk.length, readLength - written);
      out.setRange(written, written + copyLength, chunk);
      written += copyLength;
    }
    final notes = <String>[
      'toolbox.crypto.veracrypt.fs.note.read_only_file',
      if (truncated) 'toolbox.crypto.veracrypt.fs.note.file_truncated',
    ];
    return ToolboxVeraCryptFat32FileResult(
      entry: entry,
      bytes: Uint8List.sublistView(out, 0, written),
      notes: notes,
      truncated: truncated,
    );
  }

  /// Overwrites the existing content of [entry] without changing FAT metadata.
  ///
  /// This is intentionally narrower than full FAT32 write support: the target
  /// must be a regular file, [bytes.length] must exactly match [entry.size],
  /// and the existing cluster chain must already have enough capacity. The
  /// method does not create directory entries, allocate clusters, free clusters,
  /// update FSInfo, or change timestamps.
  Future<ToolboxVeraCryptFat32FileWriteResult> overwriteFileSameSize({
    required ToolboxVeraCryptFat32Entry entry,
    required Uint8List bytes,
  }) async {
    if (entry.isDirectory) {
      throw ArgumentError.value(entry.name, 'entry', 'is a directory');
    }
    if (bytes.length != entry.size) {
      throw ArgumentError.value(
        bytes.length,
        'bytes.length',
        'must equal the existing FAT32 file size',
      );
    }
    if (bytes.isEmpty) {
      return ToolboxVeraCryptFat32FileWriteResult(
        entry: entry,
        bytesWritten: 0,
        clustersTouched: 0,
      );
    }
    final chain = await _followChain(entry.firstCluster);
    final capacity = chain.length * bytesPerCluster;
    if (bytes.length > capacity) {
      throw const ToolboxVeraCryptFat32Exception(
        ToolboxVeraCryptFat32ErrorCode.ioFailure,
        'file size exceeds its existing cluster chain capacity',
      );
    }

    var readOffset = 0;
    var clustersTouched = 0;
    for (final cluster in chain) {
      if (readOffset >= bytes.length) {
        break;
      }
      final copyLength = math.min(bytesPerCluster, bytes.length - readOffset);
      final offset = clusterToDataAreaOffset(cluster);
      await session.writeDataAreaBytes(
        offsetInDataArea: offset,
        bytes: Uint8List.sublistView(
          bytes,
          readOffset,
          readOffset + copyLength,
        ),
      );
      readOffset += copyLength;
      clustersTouched += 1;
    }
    return ToolboxVeraCryptFat32FileWriteResult(
      entry: entry,
      bytesWritten: readOffset,
      clustersTouched: clustersTouched,
    );
  }
}
