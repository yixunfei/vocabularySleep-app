part of 'toolbox_veracrypt_service.dart';

class _VeraCryptHeaderUnlockWorkProduct {
  const _VeraCryptHeaderUnlockWorkProduct({
    required this.result,
    this.decryptedHeader,
  });

  final ToolboxVeraCryptHeaderUnlockResult result;
  final Uint8List? decryptedHeader;
}

class ToolboxVeraCryptCreateFileInput {
  const ToolboxVeraCryptCreateFileInput({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}

class ToolboxVeraCryptCreatedFileInfo {
  const ToolboxVeraCryptCreatedFileInfo({
    required this.originalName,
    required this.storedName,
    required this.size,
    required this.firstCluster,
    required this.clusterCount,
  });

  final String originalName;
  final String storedName;
  final int size;
  final int firstCluster;
  final int clusterCount;
}

class ToolboxVeraCryptCreateContainerResult {
  const ToolboxVeraCryptCreateContainerResult({
    required this.containerBytes,
    required this.containerSize,
    required this.encryptedAreaLength,
    required this.fatType,
    required this.files,
  });

  final Uint8List containerBytes;
  final int containerSize;
  final int encryptedAreaLength;
  final ToolboxVeraCryptFatType fatType;
  final List<ToolboxVeraCryptCreatedFileInfo> files;
}

extension ToolboxVeraCryptDataOperations on ToolboxVeraCryptService {
  Future<ToolboxVeraCryptDataProbeResult> probePrimaryDataArea({
    required File file,
    required String passphrase,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
  }) async {
    final fileSize = await file.length();
    final randomAccessFile = await file.open();
    try {
      final headerBytes = await _readFileWindow(
        randomAccessFile,
        fileSize: fileSize,
        offset: 0,
        length: ToolboxVeraCryptService.headerSize,
      );
      var workProduct = _attemptHeaderUnlockBytesInternal(
        headerBytes: headerBytes,
        passphrase: passphrase,
        pim: pim,
        keyFile: keyFile,
        iterationOverrideForTesting: iterationOverrideForTesting,
        argon2MemoryKiBOverrideForTesting: argon2MemoryKiBOverrideForTesting,
      );
      // Fallback to the standard backup header when the primary header is
      // present but failed to decode (corruption/garble). Matches openSession.
      if (workProduct.result.status ==
          ToolboxVeraCryptHeaderUnlockStatus.failed) {
        final backupWorkProduct = await _attemptBackupHeaderUnlock(
          randomAccessFile: randomAccessFile,
          fileSize: fileSize,
          passphrase: passphrase,
          pim: pim,
          keyFile: keyFile,
          iterationOverrideForTesting: iterationOverrideForTesting,
          argon2MemoryKiBOverrideForTesting: argon2MemoryKiBOverrideForTesting,
        );
        if (backupWorkProduct != null) {
          workProduct = backupWorkProduct;
        }
      }
      if (!workProduct.result.success) {
        return _dataProbeResultFromUnlockFailure(workProduct.result);
      }
      return await _probeUnlockedDataAreaFromFile(
        file: randomAccessFile,
        fileSize: fileSize,
        workProduct: workProduct,
      );
    } finally {
      await randomAccessFile.close();
    }
  }

  ToolboxVeraCryptDataProbeResult probeDataAreaBytes({
    required Uint8List containerBytes,
    required String passphrase,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
  }) {
    final headerBytes = _readBytesWindow(
      containerBytes,
      offset: 0,
      length: ToolboxVeraCryptService.headerSize,
    );
    var workProduct = _attemptHeaderUnlockBytesInternal(
      headerBytes: headerBytes,
      passphrase: passphrase,
      pim: pim,
      keyFile: keyFile,
      iterationOverrideForTesting: iterationOverrideForTesting,
      argon2MemoryKiBOverrideForTesting: argon2MemoryKiBOverrideForTesting,
    );
    if (workProduct.result.status ==
        ToolboxVeraCryptHeaderUnlockStatus.failed) {
      final backupWorkProduct = _attemptBackupHeaderUnlockBytes(
        containerBytes: containerBytes,
        passphrase: passphrase,
        pim: pim,
        keyFile: keyFile,
        iterationOverrideForTesting: iterationOverrideForTesting,
        argon2MemoryKiBOverrideForTesting: argon2MemoryKiBOverrideForTesting,
      );
      if (backupWorkProduct != null) {
        workProduct = backupWorkProduct;
      }
    }
    if (!workProduct.result.success) {
      return _dataProbeResultFromUnlockFailure(workProduct.result);
    }
    return _probeUnlockedDataAreaFromBytes(
      containerBytes: containerBytes,
      workProduct: workProduct,
    );
  }

  Uint8List buildSyntheticAesXtsContainerForTesting({
    required String passphrase,
    required ToolboxVeraCryptKdf kdf,
    required Uint8List plaintextDataArea,
    ToolboxVeraCryptCipherChain cipherChain = ToolboxVeraCryptCipherChain.aes,
    int pim = 0,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    Uint8List? salt,
    Uint8List? masterKeyData,
    int encryptedAreaStart = ToolboxVeraCryptService.dataAreaOffset,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
  }) {
    const sectorSize = 512;
    if (plaintextDataArea.length < sectorSize ||
        plaintextDataArea.length % sectorSize != 0) {
      throw ArgumentError.value(
        plaintextDataArea.length,
        'plaintextDataArea.length',
      );
    }
    final resolvedMasterKeyData =
        masterKeyData ??
        Uint8List.fromList(
          List<int>.generate(
            ToolboxVeraCryptHeaderCrypto.masterKeyDataSize,
            (index) => (index * 17 + 41) & 0xff,
          ),
        );
    if (resolvedMasterKeyData.length !=
        ToolboxVeraCryptHeaderCrypto.masterKeyDataSize) {
      throw ArgumentError.value(
        resolvedMasterKeyData.length,
        'masterKeyData.length',
      );
    }
    final header = ToolboxVeraCryptService._headerCrypto
        .buildSyntheticHeaderForTesting(
          passphrase: passphrase,
          kdf: kdf,
          cipherChain: cipherChain,
          pim: pim,
          iterationOverride: iterationOverrideForTesting,
          argon2MemoryKiBOverride: argon2MemoryKiBOverrideForTesting,
          keyfilePool: keyFile?.poolForPasswordLength(
            utf8.encode(passphrase).length,
          ),
          salt: salt,
          volumeSize: plaintextDataArea.length,
          encryptedAreaStart: encryptedAreaStart,
          masterKeyData: resolvedMasterKeyData,
        );
    final encryptedData = ToolboxVeraCryptService._headerCrypto.cryptDataUnits(
      input: plaintextDataArea,
      masterKeyData: resolvedMasterKeyData,
      sectorSize: sectorSize,
      cipherChain: cipherChain,
      // Mirror VeraCrypt: the XTS tweak uses the absolute container sector
      // number (fileOffset / sectorSize). The first encrypted sector lives
      // at file offset `encryptedAreaStart`, so its data-unit number is
      // `encryptedAreaStart / sectorSize`. Encrypting with the same base the
      // production decrypt path now uses keeps the synthetic container
      // bit-for-bit compatible with real VeraCrypt volumes.
      dataUnitStart: encryptedAreaStart ~/ sectorSize,
      encrypt: true,
    );
    final containerSize = math.max(
      ToolboxVeraCryptService.minContainerBytes,
      encryptedAreaStart + encryptedData.length,
    );
    final container = Uint8List(containerSize)
      ..setRange(0, header.length, header)
      ..setRange(
        encryptedAreaStart,
        encryptedAreaStart + encryptedData.length,
        encryptedData,
      );
    return container;
  }

  ToolboxVeraCryptCreateContainerResult createContainerBytes({
    required String passphrase,
    required List<ToolboxVeraCryptCreateFileInput> files,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    ToolboxVeraCryptKdf kdf = ToolboxVeraCryptKdf.pbkdf2Sha512,
    ToolboxVeraCryptCipherChain cipherChain = ToolboxVeraCryptCipherChain.aes,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
  }) {
    if (passphrase.isEmpty) {
      throw ArgumentError.value('', 'passphrase', 'must not be empty');
    }
    final pimValue = _parsePimForUnlock(pim);
    if (pimValue == null) {
      throw ArgumentError.value(pim, 'pim', 'invalid VeraCrypt PIM');
    }
    if (files.isEmpty) {
      throw ArgumentError.value(files.length, 'files.length');
    }
    if (files.length > _fatRootEntryCount) {
      throw ArgumentError.value(
        files.length,
        'files.length',
        'exceeds FAT root directory entry capacity',
      );
    }
    var totalPayloadBytes = 0;
    for (final file in files) {
      if (file.name.trim().isEmpty) {
        throw ArgumentError.value(file.name, 'file.name');
      }
      totalPayloadBytes += file.bytes.length;
      if (totalPayloadBytes > ToolboxVeraCryptService.maxFat32ReadBytes) {
        throw ArgumentError.value(
          totalPayloadBytes,
          'totalPayloadBytes',
          'exceeds mobile VeraCrypt create limit',
        );
      }
    }

    final plan = _planFatRootContainer(files);
    final plaintextDataArea = _buildFatRootDataArea(files: files, plan: plan);
    final masterKeyData = _secureRandomBytes(
      ToolboxVeraCryptHeaderCrypto.masterKeyDataSize,
    );
    final salt = _secureRandomBytes(ToolboxVeraCryptHeaderCrypto.saltSize);
    final keyfilePool = keyFile?.poolForPasswordLength(
      utf8.encode(passphrase).length,
    );
    final header = ToolboxVeraCryptService._headerCrypto
        .buildSyntheticHeaderForTesting(
          passphrase: passphrase,
          kdf: kdf,
          cipherChain: cipherChain,
          pim: pimValue,
          iterationOverride: iterationOverrideForTesting,
          argon2MemoryKiBOverride: argon2MemoryKiBOverrideForTesting,
          keyfilePool: keyfilePool,
          salt: salt,
          volumeSize: plaintextDataArea.length,
          encryptedAreaStart: ToolboxVeraCryptService.dataAreaOffset,
          masterKeyData: masterKeyData,
        );
    final backupHeader = ToolboxVeraCryptService._headerCrypto
        .buildSyntheticHeaderForTesting(
          passphrase: passphrase,
          kdf: kdf,
          cipherChain: cipherChain,
          pim: pimValue,
          iterationOverride: iterationOverrideForTesting,
          argon2MemoryKiBOverride: argon2MemoryKiBOverrideForTesting,
          keyfilePool: keyfilePool,
          salt: _secureRandomBytes(ToolboxVeraCryptHeaderCrypto.saltSize),
          volumeSize: plaintextDataArea.length,
          encryptedAreaStart: ToolboxVeraCryptService.dataAreaOffset,
          masterKeyData: masterKeyData,
        );
    final encryptedData = ToolboxVeraCryptService._headerCrypto.cryptDataUnits(
      input: plaintextDataArea,
      masterKeyData: masterKeyData,
      sectorSize: _fatBytesPerSector,
      cipherChain: cipherChain,
      dataUnitStart:
          ToolboxVeraCryptService.dataAreaOffset ~/ _fatBytesPerSector,
      encrypt: true,
    );
    final backupHeaderOffset =
        ToolboxVeraCryptService.dataAreaOffset + encryptedData.length;
    final containerSize =
        backupHeaderOffset + ToolboxVeraCryptService.backupHeaderAreaSize;
    final container = Uint8List(containerSize);
    _fillSecureRandomRange(
      container,
      0,
      ToolboxVeraCryptService.dataAreaOffset,
    );
    _fillSecureRandomRange(container, backupHeaderOffset, containerSize);
    container
      ..setRange(0, header.length, header)
      ..setRange(
        ToolboxVeraCryptService.dataAreaOffset,
        ToolboxVeraCryptService.dataAreaOffset + encryptedData.length,
        encryptedData,
      )
      ..setRange(
        backupHeaderOffset,
        backupHeaderOffset + backupHeader.length,
        backupHeader,
      );
    return ToolboxVeraCryptCreateContainerResult(
      containerBytes: container,
      containerSize: container.length,
      encryptedAreaLength: plaintextDataArea.length,
      fatType: plan.fatType,
      files: plan.files,
    );
  }

  Future<ToolboxVeraCryptDataProbeResult> _probeUnlockedDataAreaFromFile({
    required RandomAccessFile file,
    required int fileSize,
    required _VeraCryptHeaderUnlockWorkProduct workProduct,
  }) async {
    final layout = _resolveDataProbeLayout(
      workProduct: workProduct,
      containerSize: fileSize,
    );
    if (layout == null) {
      return _unsupportedDataProbeLayout(workProduct.result);
    }
    final encryptedBytes = await _readFileWindow(
      file,
      fileSize: fileSize,
      offset: layout.dataOffset,
      length: layout.bytesToRead,
    );
    if (encryptedBytes.length != layout.bytesToRead) {
      return _unsupportedDataProbeLayout(workProduct.result);
    }
    return _decryptResolvedDataProbe(
      encryptedBytes: encryptedBytes,
      layout: layout,
      workProduct: workProduct,
    );
  }

  ToolboxVeraCryptDataProbeResult _probeUnlockedDataAreaFromBytes({
    required Uint8List containerBytes,
    required _VeraCryptHeaderUnlockWorkProduct workProduct,
  }) {
    final layout = _resolveDataProbeLayout(
      workProduct: workProduct,
      containerSize: containerBytes.length,
    );
    if (layout == null) {
      return _unsupportedDataProbeLayout(workProduct.result);
    }
    final encryptedBytes = _readBytesWindow(
      containerBytes,
      offset: layout.dataOffset,
      length: layout.bytesToRead,
    );
    if (encryptedBytes.length != layout.bytesToRead) {
      return _unsupportedDataProbeLayout(workProduct.result);
    }
    return _decryptResolvedDataProbe(
      encryptedBytes: encryptedBytes,
      layout: layout,
      workProduct: workProduct,
    );
  }

  _VeraCryptDataProbeLayout? _resolveDataProbeLayout({
    required _VeraCryptHeaderUnlockWorkProduct workProduct,
    required int containerSize,
  }) {
    final decoded = workProduct.result.decodedHeader;
    final decryptedHeader = workProduct.decryptedHeader;
    if (decoded == null || decryptedHeader == null) {
      return null;
    }
    if (_validateVeraCryptDecodedLayout(
          decoded,
          containerSize: containerSize,
        ) !=
        null) {
      return null;
    }
    final availableBytes = math.min(
      decoded.encryptedAreaLength,
      containerSize - decoded.encryptedAreaStart,
    );
    final boundedBytes = math.min(
      ToolboxVeraCryptService.maxDataProbeBytes,
      availableBytes,
    );
    final bytesToRead =
        (boundedBytes ~/ decoded.sectorSize) * decoded.sectorSize;
    if (bytesToRead < decoded.sectorSize) {
      return null;
    }
    return _VeraCryptDataProbeLayout(
      dataOffset: decoded.encryptedAreaStart,
      bytesToRead: bytesToRead,
      sectorSize: decoded.sectorSize,
      // VeraCrypt uses the absolute container sector number
      // (fileOffset / sectorSize) as the XTS tweak, not a 0-based index
      // relative to the encrypted area. For a standard file container the
      // first encrypted data-area sector therefore starts at data-unit
      // number `encryptedAreaStart / sectorSize` (typically 256). This
      // matches VeraCrypt EncryptedIoQueue.c:
      //   dataUnit.Value = (request->Offset + request->EncryptedOffset)
      //                    / ENCRYPTION_DATA_UNIT_SIZE;
      dataUnitStart: decoded.encryptedAreaStart ~/ decoded.sectorSize,
      cipherChain: decoded.cipherChain,
      masterKeyData: ToolboxVeraCryptService._headerCrypto
          .dataCipherKeyFromDecryptedHeader(
            fullHeader: decryptedHeader,
            cipherChain: decoded.cipherChain,
          ),
    );
  }

  ToolboxVeraCryptDataProbeResult _decryptResolvedDataProbe({
    required Uint8List encryptedBytes,
    required _VeraCryptDataProbeLayout layout,
    required _VeraCryptHeaderUnlockWorkProduct workProduct,
  }) {
    final plaintext = ToolboxVeraCryptService._headerCrypto.cryptDataUnits(
      input: encryptedBytes,
      masterKeyData: layout.masterKeyData,
      sectorSize: layout.sectorSize,
      cipherChain: layout.cipherChain,
      dataUnitStart: layout.dataUnitStart,
    );
    final likelyFat = _looksLikeSupportedFatBootSector(plaintext);
    return ToolboxVeraCryptDataProbeResult(
      status: ToolboxVeraCryptDataProbeStatus.success,
      headerUnlockResult: workProduct.result,
      decodedHeader: workProduct.result.decodedHeader,
      dataOffset: layout.dataOffset,
      bytesRead: plaintext.length,
      decryptedSha256: _sha256Preview(plaintext),
      plaintextHexPreview: _hexDigest(
        Uint8List.sublistView(plaintext, 0, math.min(64, plaintext.length)),
      ),
      dataUnitStart: layout.dataUnitStart,
      dataUnitCount: plaintext.length ~/ layout.sectorSize,
      likelyFat32BootSector: likelyFat,
      notes: <String>[
        'toolbox.crypto.veracrypt.note.data_probe_success',
        'toolbox.crypto.veracrypt.note.data_probe_boundary',
        if (likelyFat)
          'toolbox.crypto.veracrypt.note.data_probe_fat32_detected'
        else
          'toolbox.crypto.veracrypt.note.data_probe_filesystem_unconfirmed',
      ],
    );
  }

  ToolboxVeraCryptDataProbeResult _dataProbeResultFromUnlockFailure(
    ToolboxVeraCryptHeaderUnlockResult result,
  ) {
    return ToolboxVeraCryptDataProbeResult(
      status: _dataProbeStatusForHeaderUnlock(result.status),
      headerUnlockResult: result,
      notes: result.notes,
    );
  }

  ToolboxVeraCryptDataProbeResult _unsupportedDataProbeLayout(
    ToolboxVeraCryptHeaderUnlockResult headerUnlockResult,
  ) {
    return ToolboxVeraCryptDataProbeResult(
      status: ToolboxVeraCryptDataProbeStatus.unsupportedLayout,
      headerUnlockResult: headerUnlockResult,
      decodedHeader: headerUnlockResult.decodedHeader,
      notes: const <String>[
        'toolbox.crypto.veracrypt.note.data_probe_unsupported_layout',
        'toolbox.crypto.veracrypt.note.data_probe_boundary',
      ],
    );
  }

  ToolboxVeraCryptDataProbeStatus _dataProbeStatusForHeaderUnlock(
    ToolboxVeraCryptHeaderUnlockStatus status,
  ) {
    return switch (status) {
      ToolboxVeraCryptHeaderUnlockStatus.success =>
        ToolboxVeraCryptDataProbeStatus.success,
      ToolboxVeraCryptHeaderUnlockStatus.missingHeader =>
        ToolboxVeraCryptDataProbeStatus.missingHeader,
      ToolboxVeraCryptHeaderUnlockStatus.missingMaterial =>
        ToolboxVeraCryptDataProbeStatus.missingMaterial,
      ToolboxVeraCryptHeaderUnlockStatus.invalidPim =>
        ToolboxVeraCryptDataProbeStatus.invalidPim,
      ToolboxVeraCryptHeaderUnlockStatus.unsupportedMaterial =>
        ToolboxVeraCryptDataProbeStatus.unsupportedMaterial,
      ToolboxVeraCryptHeaderUnlockStatus.failed =>
        ToolboxVeraCryptDataProbeStatus.unlockFailed,
    };
  }

  bool _looksLikeSupportedFatBootSector(Uint8List bytes) {
    if (bytes.length < 512) {
      return false;
    }
    final bytesPerSector = bytes[11] | (bytes[12] << 8);
    final plausibleSectorSize =
        bytesPerSector == 512 ||
        bytesPerSector == 1024 ||
        bytesPerSector == 2048 ||
        bytesPerSector == 4096;
    final hasBootSignature = bytes[510] == 0x55 && bytes[511] == 0xaa;
    final rootEntryCount = bytes[17] | (bytes[18] << 8);
    final sectorsPerFat16 = bytes[22] | (bytes[23] << 8);
    final hasFat12Or16Label =
        bytes.length >= 62 && _matchesFatLabel(bytes, offset: 54);
    final hasFat32Label =
        bytes.length >= 90 && _matchesFatLabel(bytes, offset: 82);
    final fat12Or16Bpb = rootEntryCount > 0 && sectorsPerFat16 > 0;
    final fat32Bpb = rootEntryCount == 0 && sectorsPerFat16 == 0;
    return plausibleSectorSize &&
        hasBootSignature &&
        ((fat12Or16Bpb && hasFat12Or16Label) || (fat32Bpb && hasFat32Label));
  }

  bool _matchesFatLabel(Uint8List bytes, {required int offset}) {
    const fatPrefix = <int>[70, 65, 84]; // "FAT"
    return Iterable<int>.generate(
      fatPrefix.length,
    ).every((index) => bytes[offset + index] == fatPrefix[index]);
  }

  _VeraCryptFatCreatePlan _planFatRootContainer(
    List<ToolboxVeraCryptCreateFileInput> files,
  ) {
    var requiredClusters = 0;
    for (final sectorsPerCluster in _fatCreateSectorsPerClusterOptions) {
      final bytesPerCluster = _fatBytesPerSector * sectorsPerCluster;
      requiredClusters = 0;
      final assigned = <ToolboxVeraCryptCreatedFileInfo>[];
      var nextCluster = 2;
      final usedNames = <String>{};
      for (var index = 0; index < files.length; index += 1) {
        final input = files[index];
        final clusterCount =
            (input.bytes.length + bytesPerCluster - 1) ~/ bytesPerCluster;
        requiredClusters += clusterCount;
        final storedName = _uniqueShortName(input.name, usedNames);
        assigned.add(
          ToolboxVeraCryptCreatedFileInfo(
            originalName: input.name,
            storedName: storedName,
            size: input.bytes.length,
            firstCluster: clusterCount == 0 ? 0 : nextCluster,
            clusterCount: clusterCount,
          ),
        );
        nextCluster += clusterCount;
      }
      final fatType = requiredClusters < 4085
          ? ToolboxVeraCryptFatType.fat12
          : ToolboxVeraCryptFatType.fat16;
      final minClusterCount = fatType == ToolboxVeraCryptFatType.fat12
          ? 16
          : 4085;
      final clusterCount = math.max(requiredClusters + 16, minClusterCount);
      if (fatType == ToolboxVeraCryptFatType.fat12 && clusterCount > 4084) {
        continue;
      }
      if (clusterCount > 65524) {
        continue;
      }
      final sectorsPerFat = _sectorsPerFat(fatType, clusterCount);
      return _VeraCryptFatCreatePlan(
        fatType: fatType,
        files: assigned,
        clusterCount: clusterCount,
        sectorsPerCluster: sectorsPerCluster,
        sectorsPerFat: sectorsPerFat,
        rootDirectorySectors: _fatRootDirectorySectors,
      );
    }
    throw ArgumentError.value(
      requiredClusters,
      'requiredClusters',
      'FAT root container is too large for this creator',
    );
  }

  Uint8List _buildFatRootDataArea({
    required List<ToolboxVeraCryptCreateFileInput> files,
    required _VeraCryptFatCreatePlan plan,
  }) {
    final totalSectors =
        _fatReservedSectors +
        _fatNumFats * plan.sectorsPerFat +
        plan.rootDirectorySectors +
        plan.clusterCount * plan.sectorsPerCluster;
    final bytes = Uint8List(totalSectors * _fatBytesPerSector);
    _writeFatBootSector(bytes, plan: plan, totalSectors: totalSectors);
    for (var fat = 0; fat < _fatNumFats; fat += 1) {
      final fatOffset =
          (_fatReservedSectors + fat * plan.sectorsPerFat) * _fatBytesPerSector;
      _initializeFat(bytes, fatOffset: fatOffset, fatType: plan.fatType);
      for (final file in plan.files) {
        if (file.clusterCount == 0) {
          continue;
        }
        for (var i = 0; i < file.clusterCount; i += 1) {
          final cluster = file.firstCluster + i;
          final value = i == file.clusterCount - 1
              ? plan.fatType.entryMask
              : cluster + 1;
          _setFatEntry(
            bytes,
            fatOffset: fatOffset,
            fatType: plan.fatType,
            cluster: cluster,
            value: value,
          );
        }
      }
    }

    final rootDirectoryOffset =
        (_fatReservedSectors + _fatNumFats * plan.sectorsPerFat) *
        _fatBytesPerSector;
    for (var index = 0; index < plan.files.length; index += 1) {
      final file = plan.files[index];
      _writeShortDirectoryEntry(
        bytes,
        rootDirectoryOffset + index * 32,
        storedName: file.storedName,
        firstCluster: file.firstCluster,
        size: file.size,
      );
    }

    final clusterRegionOffset =
        rootDirectoryOffset + plan.rootDirectorySectors * _fatBytesPerSector;
    for (var index = 0; index < plan.files.length; index += 1) {
      final file = plan.files[index];
      if (file.clusterCount == 0) {
        continue;
      }
      final input = files[index];
      final fileOffset =
          clusterRegionOffset + (file.firstCluster - 2) * plan.bytesPerCluster;
      bytes.setRange(fileOffset, fileOffset + input.bytes.length, input.bytes);
    }
    return bytes;
  }
}

class _VeraCryptFatCreatePlan {
  const _VeraCryptFatCreatePlan({
    required this.fatType,
    required this.files,
    required this.clusterCount,
    required this.sectorsPerCluster,
    required this.sectorsPerFat,
    required this.rootDirectorySectors,
  });

  final ToolboxVeraCryptFatType fatType;
  final List<ToolboxVeraCryptCreatedFileInfo> files;
  final int clusterCount;
  final int sectorsPerCluster;
  final int sectorsPerFat;
  final int rootDirectorySectors;
  int get bytesPerCluster => _fatBytesPerSector * sectorsPerCluster;
}

const int _fatBytesPerSector = 512;
const List<int> _fatCreateSectorsPerClusterOptions = <int>[
  1,
  2,
  4,
  8,
  16,
  32,
  64,
  128,
];
const int _fatReservedSectors = 1;
const int _fatNumFats = 2;
const int _fatRootEntryCount = 512;
const int _fatRootDirectorySectors =
    ((_fatRootEntryCount * 32) + _fatBytesPerSector - 1) ~/ _fatBytesPerSector;

int _sectorsPerFat(ToolboxVeraCryptFatType fatType, int clusterCount) {
  final entries = clusterCount + 2;
  return switch (fatType) {
    ToolboxVeraCryptFatType.fat12 =>
      ((entries * 3 + 1) ~/ 2 + _fatBytesPerSector - 1) ~/ _fatBytesPerSector,
    ToolboxVeraCryptFatType.fat16 =>
      (entries * 2 + _fatBytesPerSector - 1) ~/ _fatBytesPerSector,
    ToolboxVeraCryptFatType.fat32 =>
      (entries * 4 + _fatBytesPerSector - 1) ~/ _fatBytesPerSector,
  };
}

Uint8List _secureRandomBytes(int length) {
  final random = math.Random.secure();
  return Uint8List.fromList(
    List<int>.generate(length, (_) => random.nextInt(256)),
  );
}

void _fillSecureRandomRange(Uint8List bytes, int start, int end) {
  if (start < 0 || end < start || end > bytes.length) {
    throw RangeError.range(end, start, bytes.length, 'end');
  }
  final random = math.Random.secure();
  for (var index = start; index < end; index += 1) {
    bytes[index] = random.nextInt(256);
  }
}

String _uniqueShortName(String originalName, Set<String> usedNames) {
  final cleaned = originalName.split(RegExp(r'[\\/]')).last.trim();
  final dot = cleaned.lastIndexOf('.');
  final rawBase = dot > 0 ? cleaned.substring(0, dot) : cleaned;
  final rawExt = dot > 0 && dot < cleaned.length - 1
      ? cleaned.substring(dot + 1)
      : '';
  final base = _sanitizeShortNamePart(rawBase, fallback: 'FILE');
  final ext = _sanitizeShortNamePart(rawExt, fallback: '');
  for (var attempt = 0; attempt < 1000; attempt += 1) {
    final suffix = attempt == 0 ? '' : '~$attempt';
    final baseLimit = math.max(1, 8 - suffix.length);
    final candidateBase =
        '${base.substring(0, math.min(base.length, baseLimit))}$suffix';
    final candidateExt = ext.substring(0, math.min(ext.length, 3));
    final candidate = candidateExt.isEmpty
        ? candidateBase
        : '$candidateBase.$candidateExt';
    if (usedNames.add(candidate)) {
      return candidate;
    }
  }
  throw ArgumentError.value(originalName, 'name', 'could not create 8.3 name');
}

String _sanitizeShortNamePart(String value, {required String fallback}) {
  final buffer = StringBuffer();
  for (final unit in value.toUpperCase().codeUnits) {
    final isDigit = unit >= 0x30 && unit <= 0x39;
    final isUpper = unit >= 0x41 && unit <= 0x5a;
    if (isDigit || isUpper) {
      buffer.writeCharCode(unit);
    } else if (unit == 0x5f || unit == 0x2d) {
      buffer.writeCharCode(unit);
    }
  }
  final out = buffer.toString();
  return out.isEmpty ? fallback : out;
}

void _writeFatBootSector(
  Uint8List bytes, {
  required _VeraCryptFatCreatePlan plan,
  required int totalSectors,
}) {
  bytes[0] = 0xeb;
  bytes[1] = 0x3c;
  bytes[2] = 0x90;
  const oem = 'MSDOS5.0';
  for (var i = 0; i < oem.length; i += 1) {
    bytes[3 + i] = oem.codeUnitAt(i);
  }
  _writeLeUint16(bytes, 11, _fatBytesPerSector);
  bytes[13] = plan.sectorsPerCluster;
  _writeLeUint16(bytes, 14, _fatReservedSectors);
  bytes[16] = _fatNumFats;
  _writeLeUint16(bytes, 17, _fatRootEntryCount);
  if (totalSectors <= 0xffff) {
    _writeLeUint16(bytes, 19, totalSectors);
  } else {
    _writeLeUint32(bytes, 32, totalSectors);
  }
  bytes[21] = 0xf8;
  _writeLeUint16(bytes, 22, plan.sectorsPerFat);
  _writeLeUint16(bytes, 24, 1);
  _writeLeUint16(bytes, 26, 1);
  bytes[38] = 0x29;
  _writeLeUint32(bytes, 39, 0x43564458);
  const label = 'NO NAME    ';
  for (var i = 0; i < label.length; i += 1) {
    bytes[43 + i] = label.codeUnitAt(i);
  }
  final fatLabel = plan.fatType == ToolboxVeraCryptFatType.fat12
      ? 'FAT12   '
      : 'FAT16   ';
  for (var i = 0; i < fatLabel.length; i += 1) {
    bytes[54 + i] = fatLabel.codeUnitAt(i);
  }
  bytes[510] = 0x55;
  bytes[511] = 0xaa;
}

void _initializeFat(
  Uint8List bytes, {
  required int fatOffset,
  required ToolboxVeraCryptFatType fatType,
}) {
  bytes[fatOffset] = 0xf8;
  switch (fatType) {
    case ToolboxVeraCryptFatType.fat12:
      bytes[fatOffset + 1] = 0xff;
      bytes[fatOffset + 2] = 0xff;
    case ToolboxVeraCryptFatType.fat16:
      bytes[fatOffset + 1] = 0xff;
      bytes[fatOffset + 2] = 0xff;
      bytes[fatOffset + 3] = 0xff;
    case ToolboxVeraCryptFatType.fat32:
      bytes[fatOffset + 1] = 0xff;
      bytes[fatOffset + 2] = 0xff;
      bytes[fatOffset + 3] = 0x0f;
      bytes[fatOffset + 4] = 0xff;
      bytes[fatOffset + 5] = 0xff;
      bytes[fatOffset + 6] = 0xff;
      bytes[fatOffset + 7] = 0x0f;
  }
}

void _setFatEntry(
  Uint8List bytes, {
  required int fatOffset,
  required ToolboxVeraCryptFatType fatType,
  required int cluster,
  required int value,
}) {
  switch (fatType) {
    case ToolboxVeraCryptFatType.fat12:
      final offset = fatOffset + cluster + (cluster ~/ 2);
      final current = bytes[offset] | (bytes[offset + 1] << 8);
      final packed = cluster.isEven
          ? (current & 0xf000) | (value & 0x0fff)
          : (current & 0x000f) | ((value & 0x0fff) << 4);
      bytes[offset] = packed & 0xff;
      bytes[offset + 1] = (packed >> 8) & 0xff;
    case ToolboxVeraCryptFatType.fat16:
      final offset = fatOffset + cluster * 2;
      _writeLeUint16(bytes, offset, value & 0xffff);
    case ToolboxVeraCryptFatType.fat32:
      final offset = fatOffset + cluster * 4;
      _writeLeUint32(bytes, offset, value & 0x0fffffff);
  }
}

void _writeShortDirectoryEntry(
  Uint8List bytes,
  int offset, {
  required String storedName,
  required int firstCluster,
  required int size,
}) {
  final parts = storedName.split('.');
  final base = parts.first;
  final ext = parts.length > 1 ? parts.last : '';
  final nameField = List<int>.filled(11, 0x20);
  for (var i = 0; i < base.length && i < 8; i += 1) {
    nameField[i] = base.codeUnitAt(i);
  }
  for (var i = 0; i < ext.length && i < 3; i += 1) {
    nameField[8 + i] = ext.codeUnitAt(i);
  }
  for (var i = 0; i < nameField.length; i += 1) {
    bytes[offset + i] = nameField[i];
  }
  bytes[offset + 11] = 0x20;
  _writeLeUint16(bytes, offset + 26, firstCluster);
  _writeLeUint32(bytes, offset + 28, size);
}

void _writeLeUint16(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
}

void _writeLeUint32(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
  bytes[offset + 3] = (value >> 24) & 0xff;
}

class _VeraCryptDataProbeLayout {
  const _VeraCryptDataProbeLayout({
    required this.dataOffset,
    required this.bytesToRead,
    required this.sectorSize,
    required this.dataUnitStart,
    required this.cipherChain,
    required this.masterKeyData,
  });

  final int dataOffset;
  final int bytesToRead;
  final int sectorSize;
  final int dataUnitStart;
  final ToolboxVeraCryptCipherChain cipherChain;
  final Uint8List masterKeyData;
}
