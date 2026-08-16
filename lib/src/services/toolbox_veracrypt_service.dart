import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'toolbox_veracrypt_crypto.dart';

part 'toolbox_veracrypt_data.dart';
part 'toolbox_veracrypt_fat32.dart';

enum ToolboxVeraCryptReadiness {
  noFile,
  tooSmall,
  inspectOnly,
  readyForHeaderUnlock,
}

extension ToolboxVeraCryptReadinessInfo on ToolboxVeraCryptReadiness {
  String get id {
    return switch (this) {
      ToolboxVeraCryptReadiness.noFile => 'no_file',
      ToolboxVeraCryptReadiness.tooSmall => 'too_small',
      ToolboxVeraCryptReadiness.inspectOnly => 'inspect_only',
      ToolboxVeraCryptReadiness.readyForHeaderUnlock =>
        'ready_for_header_unlock',
    };
  }
}

enum ToolboxVeraCryptContainerKind {
  veracrypt,
  trueCryptLegacy,
  extensionless,
  reviewExtension,
}

extension ToolboxVeraCryptContainerKindInfo on ToolboxVeraCryptContainerKind {
  String get id {
    return switch (this) {
      ToolboxVeraCryptContainerKind.veracrypt => 'veracrypt',
      ToolboxVeraCryptContainerKind.trueCryptLegacy => 'truecrypt_legacy',
      ToolboxVeraCryptContainerKind.extensionless => 'extensionless',
      ToolboxVeraCryptContainerKind.reviewExtension => 'review_extension',
    };
  }

  String get labelKey {
    return switch (this) {
      ToolboxVeraCryptContainerKind.veracrypt =>
        'toolbox.crypto.veracrypt.container_kind_hc',
      ToolboxVeraCryptContainerKind.trueCryptLegacy =>
        'toolbox.crypto.veracrypt.container_kind_tc',
      ToolboxVeraCryptContainerKind.extensionless =>
        'toolbox.crypto.veracrypt.container_kind_extensionless',
      ToolboxVeraCryptContainerKind.reviewExtension =>
        'toolbox.crypto.veracrypt.container_kind_review',
    };
  }

  String get noteKey {
    return switch (this) {
      ToolboxVeraCryptContainerKind.veracrypt =>
        'toolbox.crypto.veracrypt.note.extension_hc',
      ToolboxVeraCryptContainerKind.trueCryptLegacy =>
        'toolbox.crypto.veracrypt.note.extension_tc',
      ToolboxVeraCryptContainerKind.extensionless =>
        'toolbox.crypto.veracrypt.note.extensionless',
      ToolboxVeraCryptContainerKind.reviewExtension =>
        'toolbox.crypto.veracrypt.note.extension_review',
    };
  }

  bool get isExpectedContainerName {
    return switch (this) {
      ToolboxVeraCryptContainerKind.veracrypt ||
      ToolboxVeraCryptContainerKind.trueCryptLegacy ||
      ToolboxVeraCryptContainerKind.extensionless => true,
      ToolboxVeraCryptContainerKind.reviewExtension => false,
    };
  }
}

enum ToolboxVeraCryptHeaderWindowKind {
  primary,
  hiddenCandidate,
  backup,
  hiddenBackupCandidate,
}

extension ToolboxVeraCryptHeaderWindowKindInfo
    on ToolboxVeraCryptHeaderWindowKind {
  String get id {
    return switch (this) {
      ToolboxVeraCryptHeaderWindowKind.primary => 'primary',
      ToolboxVeraCryptHeaderWindowKind.hiddenCandidate => 'hidden_candidate',
      ToolboxVeraCryptHeaderWindowKind.backup => 'backup',
      ToolboxVeraCryptHeaderWindowKind.hiddenBackupCandidate =>
        'hidden_backup_candidate',
    };
  }

  String get labelKey {
    return switch (this) {
      ToolboxVeraCryptHeaderWindowKind.primary =>
        'toolbox.crypto.veracrypt.primary_header',
      ToolboxVeraCryptHeaderWindowKind.hiddenCandidate =>
        'toolbox.crypto.veracrypt.hidden_header',
      ToolboxVeraCryptHeaderWindowKind.backup =>
        'toolbox.crypto.veracrypt.standard_backup_header',
      ToolboxVeraCryptHeaderWindowKind.hiddenBackupCandidate =>
        'toolbox.crypto.veracrypt.hidden_backup_header',
    };
  }
}

enum ToolboxVeraCryptSupportLevel { planned, partial, unsupported }

extension ToolboxVeraCryptSupportLevelInfo on ToolboxVeraCryptSupportLevel {
  String get id {
    return switch (this) {
      ToolboxVeraCryptSupportLevel.planned => 'planned',
      ToolboxVeraCryptSupportLevel.partial => 'partial',
      ToolboxVeraCryptSupportLevel.unsupported => 'unsupported',
    };
  }
}

enum ToolboxVeraCryptFeatureCategory { cipher, kdf, filesystem, workflow }

extension ToolboxVeraCryptFeatureCategoryInfo
    on ToolboxVeraCryptFeatureCategory {
  String get id {
    return switch (this) {
      ToolboxVeraCryptFeatureCategory.cipher => 'cipher',
      ToolboxVeraCryptFeatureCategory.kdf => 'kdf',
      ToolboxVeraCryptFeatureCategory.filesystem => 'filesystem',
      ToolboxVeraCryptFeatureCategory.workflow => 'workflow',
    };
  }
}

enum ToolboxVeraCryptPimStatus { none, valid, invalid }

extension ToolboxVeraCryptPimStatusInfo on ToolboxVeraCryptPimStatus {
  String get id {
    return switch (this) {
      ToolboxVeraCryptPimStatus.none => 'none',
      ToolboxVeraCryptPimStatus.valid => 'valid',
      ToolboxVeraCryptPimStatus.invalid => 'invalid',
    };
  }
}

class ToolboxVeraCryptFeatureSupport {
  const ToolboxVeraCryptFeatureSupport({
    required this.labelKey,
    required this.category,
    required this.level,
    required this.noteKey,
  });

  final String labelKey;
  final ToolboxVeraCryptFeatureCategory category;
  final ToolboxVeraCryptSupportLevel level;
  final String noteKey;
}

class ToolboxVeraCryptHeaderWindow {
  const ToolboxVeraCryptHeaderWindow({
    required this.kind,
    required this.offset,
    required this.bytesAvailable,
    required this.expectedBytes,
    required this.saltFingerprint,
  });

  final ToolboxVeraCryptHeaderWindowKind kind;
  final int? offset;
  final int bytesAvailable;
  final int expectedBytes;
  final String saltFingerprint;

  bool get isReadable => offset != null && bytesAvailable > 0;

  bool get isComplete => bytesAvailable == expectedBytes;

  bool get hasSaltFingerprint => saltFingerprint.isNotEmpty;
}

class ToolboxVeraCryptKeyFileInspectionResult {
  const ToolboxVeraCryptKeyFileInspectionResult({
    required this.fileName,
    required this.fileSize,
    required this.bytesHashed,
    required this.maxBytesHashed,
    required this.sha256Preview,
    required this.veracryptKeyfilePool,
    required this.veracryptLegacyKeyfilePool,
  });

  final String fileName;
  final int fileSize;
  final int bytesHashed;
  final int maxBytesHashed;
  final String sha256Preview;
  final Uint8List? veracryptKeyfilePool;
  final Uint8List? veracryptLegacyKeyfilePool;

  bool get isEmpty => fileSize == 0;

  bool get isTruncated => fileSize > bytesHashed;

  bool get hasVeraCryptKeyfilePool =>
      veracryptKeyfilePool != null &&
      veracryptKeyfilePool!.length ==
          ToolboxVeraCryptHeaderCrypto.keyfilePoolSize;

  Uint8List? poolForPasswordLength(int passwordBytes) {
    if (passwordBytes <= ToolboxVeraCryptHeaderCrypto.legacyKeyfilePoolSize) {
      return veracryptLegacyKeyfilePool;
    }
    return veracryptKeyfilePool;
  }
}

class ToolboxVeraCryptUnlockMaterialSummary {
  const ToolboxVeraCryptUnlockMaterialSummary({
    required this.hasPassphrase,
    required this.passphraseLength,
    required this.pimStatus,
    required this.hasKeyFile,
    required this.keyFile,
    required this.candidateKdfLabelKeys,
    required this.notes,
  });

  final bool hasPassphrase;
  final int passphraseLength;
  final ToolboxVeraCryptPimStatus pimStatus;
  final bool hasKeyFile;
  final ToolboxVeraCryptKeyFileInspectionResult? keyFile;
  final List<String> candidateKdfLabelKeys;
  final List<String> notes;

  bool get hasAnySecretMaterial => hasPassphrase || hasKeyFile;

  bool get canAttemptFutureHeaderUnlock {
    return hasAnySecretMaterial &&
        pimStatus != ToolboxVeraCryptPimStatus.invalid;
  }
}

class ToolboxVeraCryptInspectionResult {
  const ToolboxVeraCryptInspectionResult({
    required this.fileName,
    required this.fileSize,
    required this.containerKind,
    required this.containerExtension,
    required this.headerWindows,
    required this.minContainerBytes,
    required this.readiness,
    required this.sha256Preview,
    required this.notes,
    required this.supportMatrix,
  });

  final String fileName;
  final int fileSize;
  final ToolboxVeraCryptContainerKind containerKind;
  final String containerExtension;
  final List<ToolboxVeraCryptHeaderWindow> headerWindows;
  final int minContainerBytes;
  final ToolboxVeraCryptReadiness readiness;
  final String sha256Preview;
  final List<String> notes;
  final List<ToolboxVeraCryptFeatureSupport> supportMatrix;

  int get headerBytesAvailable =>
      _window(ToolboxVeraCryptHeaderWindowKind.primary).bytesAvailable;
  int get hiddenHeaderBytesAvailable =>
      _window(ToolboxVeraCryptHeaderWindowKind.hiddenCandidate).bytesAvailable;
  int get backupHeaderBytesAvailable =>
      _window(ToolboxVeraCryptHeaderWindowKind.backup).bytesAvailable;
  int get hiddenBackupHeaderBytesAvailable => _window(
    ToolboxVeraCryptHeaderWindowKind.hiddenBackupCandidate,
  ).bytesAvailable;

  int get primaryHeaderOffset =>
      _window(ToolboxVeraCryptHeaderWindowKind.primary).offset ?? 0;
  int? get hiddenHeaderOffset =>
      _window(ToolboxVeraCryptHeaderWindowKind.hiddenCandidate).offset;
  int? get backupHeaderOffset =>
      _window(ToolboxVeraCryptHeaderWindowKind.backup).offset;
  int? get hiddenBackupHeaderOffset =>
      _window(ToolboxVeraCryptHeaderWindowKind.hiddenBackupCandidate).offset;

  bool get hasPrimaryHeader =>
      headerBytesAvailable == ToolboxVeraCryptService.headerSize;
  bool get hasHiddenHeader =>
      hiddenHeaderBytesAvailable == ToolboxVeraCryptService.headerSize;
  bool get hasBackupHeader =>
      backupHeaderBytesAvailable == ToolboxVeraCryptService.headerSize;
  bool get hasHiddenBackupHeader =>
      hiddenBackupHeaderBytesAvailable == ToolboxVeraCryptService.headerSize;

  bool get extensionLooksCompatible => containerKind.isExpectedContainerName;

  ToolboxVeraCryptHeaderWindow _window(ToolboxVeraCryptHeaderWindowKind kind) {
    return headerWindows.singleWhere((window) => window.kind == kind);
  }
}

enum ToolboxVeraCryptHeaderUnlockStatus {
  success,
  missingHeader,
  missingMaterial,
  invalidPim,
  unsupportedMaterial,
  failed,
}

extension ToolboxVeraCryptHeaderUnlockStatusInfo
    on ToolboxVeraCryptHeaderUnlockStatus {
  String get id {
    return switch (this) {
      ToolboxVeraCryptHeaderUnlockStatus.success => 'success',
      ToolboxVeraCryptHeaderUnlockStatus.missingHeader => 'missing_header',
      ToolboxVeraCryptHeaderUnlockStatus.missingMaterial => 'missing_material',
      ToolboxVeraCryptHeaderUnlockStatus.invalidPim => 'invalid_pim',
      ToolboxVeraCryptHeaderUnlockStatus.unsupportedMaterial =>
        'unsupported_material',
      ToolboxVeraCryptHeaderUnlockStatus.failed => 'failed',
    };
  }

  String get labelKey {
    return switch (this) {
      ToolboxVeraCryptHeaderUnlockStatus.success =>
        'toolbox.crypto.veracrypt.header_unlock_status_success',
      ToolboxVeraCryptHeaderUnlockStatus.missingHeader =>
        'toolbox.crypto.veracrypt.header_unlock_status_missing_header',
      ToolboxVeraCryptHeaderUnlockStatus.missingMaterial =>
        'toolbox.crypto.veracrypt.header_unlock_status_missing_material',
      ToolboxVeraCryptHeaderUnlockStatus.invalidPim =>
        'toolbox.crypto.veracrypt.header_unlock_status_invalid_pim',
      ToolboxVeraCryptHeaderUnlockStatus.unsupportedMaterial =>
        'toolbox.crypto.veracrypt.header_unlock_status_unsupported_material',
      ToolboxVeraCryptHeaderUnlockStatus.failed =>
        'toolbox.crypto.veracrypt.header_unlock_status_failed',
    };
  }
}

class ToolboxVeraCryptHeaderUnlockResult {
  const ToolboxVeraCryptHeaderUnlockResult({
    required this.status,
    required this.headerWindowKind,
    required this.attemptedKdfs,
    required this.notes,
    this.decodedHeader,
  });

  final ToolboxVeraCryptHeaderUnlockStatus status;
  final ToolboxVeraCryptHeaderWindowKind headerWindowKind;
  final List<ToolboxVeraCryptKdf> attemptedKdfs;
  final List<String> notes;
  final ToolboxVeraCryptDecodedHeader? decodedHeader;

  bool get success => status == ToolboxVeraCryptHeaderUnlockStatus.success;
}

enum ToolboxVeraCryptDataProbeStatus {
  success,
  missingHeader,
  missingMaterial,
  invalidPim,
  unsupportedMaterial,
  unlockFailed,
  unsupportedLayout,
}

extension ToolboxVeraCryptDataProbeStatusInfo
    on ToolboxVeraCryptDataProbeStatus {
  String get labelKey {
    return switch (this) {
      ToolboxVeraCryptDataProbeStatus.success =>
        'toolbox.crypto.veracrypt.data_probe_status_success',
      ToolboxVeraCryptDataProbeStatus.missingHeader =>
        'toolbox.crypto.veracrypt.data_probe_status_missing_header',
      ToolboxVeraCryptDataProbeStatus.missingMaterial =>
        'toolbox.crypto.veracrypt.data_probe_status_missing_material',
      ToolboxVeraCryptDataProbeStatus.invalidPim =>
        'toolbox.crypto.veracrypt.data_probe_status_invalid_pim',
      ToolboxVeraCryptDataProbeStatus.unsupportedMaterial =>
        'toolbox.crypto.veracrypt.data_probe_status_unsupported_material',
      ToolboxVeraCryptDataProbeStatus.unlockFailed =>
        'toolbox.crypto.veracrypt.data_probe_status_unlock_failed',
      ToolboxVeraCryptDataProbeStatus.unsupportedLayout =>
        'toolbox.crypto.veracrypt.data_probe_status_unsupported_layout',
    };
  }
}

class ToolboxVeraCryptDataProbeResult {
  const ToolboxVeraCryptDataProbeResult({
    required this.status,
    required this.headerUnlockResult,
    required this.notes,
    this.decodedHeader,
    this.dataOffset,
    this.bytesRead = 0,
    this.decryptedSha256 = '',
    this.plaintextHexPreview = '',
    this.dataUnitStart = 0,
    this.dataUnitCount = 0,
    this.likelyFat32BootSector = false,
  });

  final ToolboxVeraCryptDataProbeStatus status;
  final ToolboxVeraCryptHeaderUnlockResult headerUnlockResult;
  final ToolboxVeraCryptDecodedHeader? decodedHeader;
  final int? dataOffset;
  final int bytesRead;
  final String decryptedSha256;
  final String plaintextHexPreview;
  final int dataUnitStart;
  final int dataUnitCount;
  final bool likelyFat32BootSector;
  final List<String> notes;

  bool get success => status == ToolboxVeraCryptDataProbeStatus.success;
}

class ToolboxVeraCryptService {
  static const int headerSize = 512;
  static const int saltSize = 64;
  static const int headerAreaSize = 64 * 1024;
  static const int dataAreaOffset = headerAreaSize * 2;
  static const int backupHeaderAreaSize = headerAreaSize * 2;
  static const int minContainerBytes = dataAreaOffset + backupHeaderAreaSize;
  static const int maxPreviewHashBytes = 1024 * 1024;
  static const int maxKeyFileHashBytes = 1024 * 1024;
  static const int maxDataProbeBytes = 4096;
  static const int maxPimValue = 2147468;
  static const int maxPassphraseBytes = 128;

  // Read-only FAT32 browse/export defensive limits (PLAN_349).
  /// Upper bound on a single FAT cluster chain length we will follow.
  static const int maxFat32ClusterChain = 1 << 16; // 65536 clusters
  /// Upper bound on directory entries scanned per directory.
  static const int maxFat32DirectoryEntries = 1 << 14; // 16384
  /// Upper bound on bytes returned by a single read-only file read.
  static const int maxFat32ReadBytes = 64 * 1024 * 1024; // 64 MiB
  /// Upper bound on directory bytes materialized from a cluster chain.
  static const int maxFat32DirectoryBytes = maxFat32DirectoryEntries * 32;

  /// Upper bound on FAT32 cluster count we treat as plausibly sane.
  static const int maxFat32ClusterCount = 1 << 24; // ~16.7M clusters
  /// Upper bound for automatic Argon2id header-unlock attempts on mobile.
  static const int maxArgon2HeaderUnlockMemoryKiB = 128 * 1024;

  static const ToolboxVeraCryptHeaderCrypto _headerCrypto =
      ToolboxVeraCryptHeaderCrypto();

  static const List<ToolboxVeraCryptCipherChain> candidateCipherChains =
      <ToolboxVeraCryptCipherChain>[
        ToolboxVeraCryptCipherChain.aes,
        ToolboxVeraCryptCipherChain.serpent,
        ToolboxVeraCryptCipherChain.twofish,
        ToolboxVeraCryptCipherChain.camellia,
        ToolboxVeraCryptCipherChain.kuznyechik,
        ToolboxVeraCryptCipherChain.aesTwofish,
        ToolboxVeraCryptCipherChain.aesTwofishSerpent,
        ToolboxVeraCryptCipherChain.serpentAes,
        ToolboxVeraCryptCipherChain.serpentTwofishAes,
        ToolboxVeraCryptCipherChain.twofishSerpent,
        ToolboxVeraCryptCipherChain.camelliaKuznyechik,
        ToolboxVeraCryptCipherChain.kuznyechikTwofish,
        ToolboxVeraCryptCipherChain.camelliaSerpent,
        ToolboxVeraCryptCipherChain.kuznyechikAes,
        ToolboxVeraCryptCipherChain.kuznyechikSerpentCamellia,
      ];

  static const List<ToolboxVeraCryptKdf> candidateKdfs = <ToolboxVeraCryptKdf>[
    ToolboxVeraCryptKdf.pbkdf2Sha512,
    ToolboxVeraCryptKdf.pbkdf2Sha256,
    ToolboxVeraCryptKdf.pbkdf2Whirlpool,
    ToolboxVeraCryptKdf.pbkdf2Blake2s,
    ToolboxVeraCryptKdf.pbkdf2Streebog,
    ToolboxVeraCryptKdf.argon2id,
  ];

  static const List<ToolboxVeraCryptFeatureSupport> supportMatrix =
      <ToolboxVeraCryptFeatureSupport>[
        ToolboxVeraCryptFeatureSupport(
          labelKey: 'toolbox.crypto.veracrypt.support.feature.cipher_chains',
          category: ToolboxVeraCryptFeatureCategory.cipher,
          level: ToolboxVeraCryptSupportLevel.partial,
          noteKey: 'toolbox.crypto.veracrypt.note.cipher_chains_supported',
        ),
        ToolboxVeraCryptFeatureSupport(
          labelKey: 'toolbox.crypto.veracrypt.support.feature.kdf_primary',
          category: ToolboxVeraCryptFeatureCategory.kdf,
          level: ToolboxVeraCryptSupportLevel.partial,
          noteKey: 'toolbox.crypto.veracrypt.note.kdf_primary_supported',
        ),
        ToolboxVeraCryptFeatureSupport(
          labelKey: 'toolbox.crypto.veracrypt.support.feature.fat32_read_only',
          category: ToolboxVeraCryptFeatureCategory.filesystem,
          level: ToolboxVeraCryptSupportLevel.partial,
          noteKey: 'toolbox.crypto.veracrypt.note.fat32_partial',
        ),
        ToolboxVeraCryptFeatureSupport(
          labelKey:
              'toolbox.crypto.veracrypt.support.feature.fat32_same_size_write',
          category: ToolboxVeraCryptFeatureCategory.filesystem,
          level: ToolboxVeraCryptSupportLevel.partial,
          noteKey:
              'toolbox.crypto.veracrypt.note.fat32_same_size_write_partial',
        ),
        ToolboxVeraCryptFeatureSupport(
          labelKey: 'toolbox.crypto.veracrypt.support.feature.create_container',
          category: ToolboxVeraCryptFeatureCategory.workflow,
          level: ToolboxVeraCryptSupportLevel.partial,
          noteKey: 'toolbox.crypto.veracrypt.note.create_container_partial',
        ),
      ];

  static const List<String> candidateKdfLabelKeys = <String>[
    'toolbox.crypto.veracrypt.kdf.pbkdf2_all',
    'toolbox.crypto.veracrypt.kdf.argon2id',
    'toolbox.crypto.veracrypt.kdf.pim_keyfile_mix',
  ];

  Future<ToolboxVeraCryptInspectionResult> inspectFile({
    required File file,
    required String fileName,
    int? fileSize,
  }) async {
    final resolvedSize = fileSize ?? await file.length();
    final randomAccessFile = await file.open();
    try {
      final primaryHeader = await _readFileWindow(
        randomAccessFile,
        fileSize: resolvedSize,
        offset: 0,
        length: headerSize,
      );
      final hiddenHeader = await _readFileWindow(
        randomAccessFile,
        fileSize: resolvedSize,
        offset: _hiddenHeaderOffsetFor(resolvedSize),
        length: headerSize,
      );
      final backupHeader = await _readFileWindow(
        randomAccessFile,
        fileSize: resolvedSize,
        offset: _backupHeaderOffsetFor(resolvedSize),
        length: headerSize,
      );
      final hiddenBackupHeader = await _readFileWindow(
        randomAccessFile,
        fileSize: resolvedSize,
        offset: _hiddenBackupHeaderOffsetFor(resolvedSize),
        length: headerSize,
      );
      final previewBytes = await _readFileWindow(
        randomAccessFile,
        fileSize: resolvedSize,
        offset: 0,
        length: math.min(maxPreviewHashBytes, resolvedSize),
      );
      return _buildResult(
        fileName: fileName,
        fileSize: resolvedSize,
        primaryHeader: primaryHeader,
        hiddenHeader: hiddenHeader,
        backupHeader: backupHeader,
        hiddenBackupHeader: hiddenBackupHeader,
        sha256Preview: _sha256Preview(previewBytes),
      );
    } finally {
      await randomAccessFile.close();
    }
  }

  ToolboxVeraCryptInspectionResult inspectBytes({
    required Uint8List bytes,
    required String fileName,
  }) {
    final fileSize = bytes.length;
    final primaryHeader = _readBytesWindow(
      bytes,
      offset: 0,
      length: headerSize,
    );
    final hiddenHeader = _readBytesWindow(
      bytes,
      offset: _hiddenHeaderOffsetFor(fileSize),
      length: headerSize,
    );
    final backupHeader = _readBytesWindow(
      bytes,
      offset: _backupHeaderOffsetFor(fileSize),
      length: headerSize,
    );
    final hiddenBackupHeader = _readBytesWindow(
      bytes,
      offset: _hiddenBackupHeaderOffsetFor(fileSize),
      length: headerSize,
    );
    final sampleLength = math.min(fileSize, maxPreviewHashBytes);
    final sample = sampleLength == 0
        ? Uint8List(0)
        : Uint8List.sublistView(bytes, 0, sampleLength);
    return _buildResult(
      fileName: fileName,
      fileSize: fileSize,
      primaryHeader: primaryHeader,
      hiddenHeader: hiddenHeader,
      backupHeader: backupHeader,
      hiddenBackupHeader: hiddenBackupHeader,
      sha256Preview: _sha256Preview(sample),
    );
  }

  Future<ToolboxVeraCryptKeyFileInspectionResult> inspectKeyFile({
    required File file,
    required String fileName,
    int? fileSize,
  }) async {
    final resolvedSize = fileSize ?? await file.length();
    final limit = math.min(resolvedSize, maxKeyFileHashBytes);
    final digestSink = _VeraCryptDigestSink();
    final inputSink = crypto.sha256.startChunkedConversion(digestSink);
    final keyfilePool = Uint8List(ToolboxVeraCryptHeaderCrypto.keyfilePoolSize);
    final legacyKeyfilePool = Uint8List(
      ToolboxVeraCryptHeaderCrypto.legacyKeyfilePoolSize,
    );
    final poolState = _VeraCryptKeyfilePoolState(
      keyfilePool: keyfilePool,
      legacyKeyfilePool: legacyKeyfilePool,
    );
    var bytesHashed = 0;
    try {
      await for (final chunk in file.openRead(0, limit)) {
        inputSink.add(chunk);
        for (final byte in chunk) {
          _mixKeyfileByte(poolState, byte);
        }
        bytesHashed += chunk.length;
      }
    } finally {
      inputSink.close();
    }
    return ToolboxVeraCryptKeyFileInspectionResult(
      fileName: fileName,
      fileSize: resolvedSize,
      bytesHashed: bytesHashed,
      maxBytesHashed: maxKeyFileHashBytes,
      sha256Preview: bytesHashed == 0 ? '' : digestSink.digest.toString(),
      veracryptKeyfilePool: bytesHashed == 0 ? null : keyfilePool,
      veracryptLegacyKeyfilePool: bytesHashed == 0 ? null : legacyKeyfilePool,
    );
  }

  ToolboxVeraCryptKeyFileInspectionResult inspectKeyFileBytes({
    required Uint8List bytes,
    required String fileName,
  }) {
    final bytesHashed = math.min(bytes.length, maxKeyFileHashBytes);
    final sample = bytesHashed == 0
        ? Uint8List(0)
        : Uint8List.sublistView(bytes, 0, bytesHashed);
    return ToolboxVeraCryptKeyFileInspectionResult(
      fileName: fileName,
      fileSize: bytes.length,
      bytesHashed: bytesHashed,
      maxBytesHashed: maxKeyFileHashBytes,
      sha256Preview: _sha256Preview(sample),
      veracryptKeyfilePool: sample.isEmpty
          ? null
          : _headerCrypto.buildKeyfilePool(
              sample,
              poolSize: ToolboxVeraCryptHeaderCrypto.keyfilePoolSize,
            ),
      veracryptLegacyKeyfilePool: sample.isEmpty
          ? null
          : _headerCrypto.buildKeyfilePool(
              sample,
              poolSize: ToolboxVeraCryptHeaderCrypto.legacyKeyfilePoolSize,
            ),
    );
  }

  ToolboxVeraCryptUnlockMaterialSummary summarizeUnlockMaterial({
    required String passphrase,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
  }) {
    final trimmedPim = pim?.trim() ?? '';
    final decimalPim = RegExp(r'^[0-9]+$').hasMatch(trimmedPim);
    final parsedPim = decimalPim ? int.tryParse(trimmedPim) : null;
    final pimStatus = trimmedPim.isEmpty
        ? ToolboxVeraCryptPimStatus.none
        : parsedPim != null && parsedPim > 0 && parsedPim <= maxPimValue
        ? ToolboxVeraCryptPimStatus.valid
        : ToolboxVeraCryptPimStatus.invalid;
    final hasPassphrase = passphrase.isNotEmpty;
    final hasKeyFile = keyFile != null && !keyFile.isEmpty;

    return ToolboxVeraCryptUnlockMaterialSummary(
      hasPassphrase: hasPassphrase,
      passphraseLength: passphrase.runes.length,
      pimStatus: pimStatus,
      hasKeyFile: hasKeyFile,
      keyFile: keyFile,
      candidateKdfLabelKeys: candidateKdfLabelKeys,
      notes: <String>[
        if (hasPassphrase)
          'toolbox.crypto.veracrypt.note.passphrase_present'
        else
          'toolbox.crypto.veracrypt.note.passphrase_missing',
        switch (pimStatus) {
          ToolboxVeraCryptPimStatus.none =>
            'toolbox.crypto.veracrypt.note.pim_default',
          ToolboxVeraCryptPimStatus.valid =>
            'toolbox.crypto.veracrypt.note.pim_valid',
          ToolboxVeraCryptPimStatus.invalid =>
            'toolbox.crypto.veracrypt.note.pim_invalid',
        },
        if (keyFile == null)
          'toolbox.crypto.veracrypt.note.keyfile_none'
        else if (keyFile.isEmpty)
          'toolbox.crypto.veracrypt.note.keyfile_empty'
        else
          'toolbox.crypto.veracrypt.note.keyfile_ready',
        if ((hasPassphrase || hasKeyFile) &&
            pimStatus != ToolboxVeraCryptPimStatus.invalid)
          'toolbox.crypto.veracrypt.note.material_header_unlock_ready',
      ],
    );
  }

  Future<ToolboxVeraCryptHeaderUnlockResult> attemptPrimaryHeaderUnlock({
    required File file,
    required String passphrase,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
  }) async {
    final randomAccessFile = await file.open();
    try {
      final fileSize = await file.length();
      final headerBytes = await _readFileWindow(
        randomAccessFile,
        fileSize: fileSize,
        offset: 0,
        length: headerSize,
      );
      final workProduct = _attemptHeaderUnlockBytesInternal(
        headerBytes: headerBytes,
        passphrase: passphrase,
        pim: pim,
        keyFile: keyFile,
      );
      return _validateHeaderUnlockResultForLayout(
        workProduct.result,
        containerSize: fileSize,
      );
    } finally {
      await randomAccessFile.close();
    }
  }

  ToolboxVeraCryptHeaderUnlockResult attemptHeaderUnlockBytes({
    required Uint8List headerBytes,
    required String passphrase,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
  }) {
    final workProduct = _attemptHeaderUnlockBytesInternal(
      headerBytes: headerBytes,
      passphrase: passphrase,
      pim: pim,
      keyFile: keyFile,
      iterationOverrideForTesting: iterationOverrideForTesting,
      argon2MemoryKiBOverrideForTesting: argon2MemoryKiBOverrideForTesting,
    );
    return _validateHeaderUnlockResultForLayout(workProduct.result);
  }

  /// Opens a stateful session against an on-disk VeraCrypt container.
  ///
  /// The session keeps the underlying `RandomAccessFile` open and retains the
  /// derived data-area master key in private memory (never exposed to callers,
  /// logs or UI). By default it is read-only; pass [writable] only when the
  /// caller is deliberately performing a bounded write operation.
  /// Call [ToolboxVeraCryptUnlockedSession.close] when done (and on UI
  /// `dispose`) to close the file handle and zero the key material.
  Future<ToolboxVeraCryptSessionOpenResult> openSession({
    required File file,
    required String passphrase,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    bool writable = false,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
  }) async {
    final fileSize = await file.length();
    final randomAccessFile = await file.open(
      // FileMode.append opens without truncating and still permits
      // setPosition-based random writes, unlike FileMode.write.
      mode: writable ? FileMode.append : FileMode.read,
    );
    try {
      final headerBytes = await _readFileWindow(
        randomAccessFile,
        fileSize: fileSize,
        offset: 0,
        length: headerSize,
      );
      var workProduct = _attemptHeaderUnlockBytesInternal(
        headerBytes: headerBytes,
        passphrase: passphrase,
        pim: pim,
        keyFile: keyFile,
        iterationOverrideForTesting: iterationOverrideForTesting,
        argon2MemoryKiBOverrideForTesting: argon2MemoryKiBOverrideForTesting,
      );
      // If the primary header simply failed to decode (corrupted/garbled main
      // header) but the credentials look valid, retry against the standard
      // backup header at the tail of the container. Material/PIM errors are NOT
      // retried (they would fail identically on the backup header).
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
        await randomAccessFile.close();
        return ToolboxVeraCryptSessionOpenResult(
          status: _sessionStatusForHeaderUnlock(workProduct.result.status),
          headerUnlockResult: workProduct.result,
        );
      }
      final layoutCheckedResult = _validateHeaderUnlockResultForLayout(
        workProduct.result,
        containerSize: fileSize,
      );
      if (!layoutCheckedResult.success) {
        await randomAccessFile.close();
        return ToolboxVeraCryptSessionOpenResult(
          status: _sessionStatusForHeaderUnlock(layoutCheckedResult.status),
          headerUnlockResult: layoutCheckedResult,
        );
      }
      return _materializeSession(
        randomAccessFile: randomAccessFile,
        fileSize: fileSize,
        workProduct: workProduct,
        writable: writable,
      );
    } on Object {
      // On any unexpected failure ensure the file handle is not leaked.
      try {
        await randomAccessFile.close();
      } on Object {
        // Best-effort close; the original exception is what matters.
      }
      rethrow;
    }
  }

  /// Reads the standard backup header at the container tail (offset
  /// `fileSize - backupHeaderAreaSize`) and attempts to unlock it. Returns null
  /// when the container is too small to host a backup header or the read is
  /// incomplete. Only invoked as a fallback after the primary header failed.
  Future<_VeraCryptHeaderUnlockWorkProduct?> _attemptBackupHeaderUnlock({
    required RandomAccessFile randomAccessFile,
    required int fileSize,
    required String passphrase,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
  }) async {
    final offset = _backupHeaderOffsetFor(fileSize);
    if (offset == null) {
      return null;
    }
    final headerBytes = await _readFileWindow(
      randomAccessFile,
      fileSize: fileSize,
      offset: offset,
      length: headerSize,
    );
    if (headerBytes.length < headerSize) {
      return null;
    }
    final workProduct = _attemptHeaderUnlockBytesInternal(
      headerBytes: headerBytes,
      passphrase: passphrase,
      pim: pim,
      keyFile: keyFile,
      iterationOverrideForTesting: iterationOverrideForTesting,
      argon2MemoryKiBOverrideForTesting: argon2MemoryKiBOverrideForTesting,
      headerWindowKind: ToolboxVeraCryptHeaderWindowKind.backup,
    );
    return _annotateBackupResult(workProduct);
  }

  /// In-memory variant of [_attemptBackupHeaderUnlock] used by tests.
  _VeraCryptHeaderUnlockWorkProduct? _attemptBackupHeaderUnlockBytes({
    required Uint8List containerBytes,
    required String passphrase,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
  }) {
    final offset = _backupHeaderOffsetFor(containerBytes.length);
    if (offset == null) {
      return null;
    }
    final headerBytes = _readBytesWindow(
      containerBytes,
      offset: offset,
      length: headerSize,
    );
    if (headerBytes.length < headerSize) {
      return null;
    }
    final workProduct = _attemptHeaderUnlockBytesInternal(
      headerBytes: headerBytes,
      passphrase: passphrase,
      pim: pim,
      keyFile: keyFile,
      iterationOverrideForTesting: iterationOverrideForTesting,
      argon2MemoryKiBOverrideForTesting: argon2MemoryKiBOverrideForTesting,
      headerWindowKind: ToolboxVeraCryptHeaderWindowKind.backup,
    );
    return _annotateBackupResult(workProduct);
  }

  /// Appends the backup-fallback note to a successful backup-header unlock so
  /// the UI can distinguish it from a normal primary-header success.
  _VeraCryptHeaderUnlockWorkProduct _annotateBackupResult(
    _VeraCryptHeaderUnlockWorkProduct workProduct,
  ) {
    final result = workProduct.result;
    if (!result.success) {
      return workProduct;
    }
    return _VeraCryptHeaderUnlockWorkProduct(
      result: ToolboxVeraCryptHeaderUnlockResult(
        status: result.status,
        headerWindowKind: result.headerWindowKind,
        attemptedKdfs: result.attemptedKdfs,
        decodedHeader: result.decodedHeader,
        notes: <String>[
          ...result.notes,
          'toolbox.crypto.veracrypt.note.header_unlock_via_backup',
        ],
      ),
      decryptedHeader: workProduct.decryptedHeader,
    );
  }

  /// In-memory variant of [openSession] used by tests (no file IO).
  ToolboxVeraCryptSessionOpenResult openSessionFromBytes({
    required Uint8List containerBytes,
    required String passphrase,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
    bool writable = false,
  }) {
    final headerBytes = _readBytesWindow(
      containerBytes,
      offset: 0,
      length: headerSize,
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
      return ToolboxVeraCryptSessionOpenResult(
        status: _sessionStatusForHeaderUnlock(workProduct.result.status),
        headerUnlockResult: workProduct.result,
      );
    }
    final layoutCheckedResult = _validateHeaderUnlockResultForLayout(
      workProduct.result,
      containerSize: containerBytes.length,
    );
    if (!layoutCheckedResult.success) {
      return ToolboxVeraCryptSessionOpenResult(
        status: _sessionStatusForHeaderUnlock(layoutCheckedResult.status),
        headerUnlockResult: layoutCheckedResult,
      );
    }
    return _materializeSession(
      byteSource: containerBytes,
      workProduct: workProduct,
      writable: writable,
    );
  }

  ToolboxVeraCryptHeaderUnlockResult _validateHeaderUnlockResultForLayout(
    ToolboxVeraCryptHeaderUnlockResult result, {
    int? containerSize,
  }) {
    final decoded = result.decodedHeader;
    if (!result.success || decoded == null) {
      return result;
    }
    final problem = _validateVeraCryptDecodedLayout(
      decoded,
      containerSize: containerSize,
    );
    if (problem == null) {
      return result;
    }
    return ToolboxVeraCryptHeaderUnlockResult(
      status: ToolboxVeraCryptHeaderUnlockStatus.unsupportedMaterial,
      headerWindowKind: result.headerWindowKind,
      attemptedKdfs: result.attemptedKdfs,
      decodedHeader: decoded,
      notes: const <String>[
        'toolbox.crypto.veracrypt.note.data_probe_unsupported_layout',
      ],
    );
  }

  ToolboxVeraCryptSessionOpenResult _materializeSession({
    RandomAccessFile? randomAccessFile,
    Uint8List? byteSource,
    int? fileSize,
    required _VeraCryptHeaderUnlockWorkProduct workProduct,
    bool writable = false,
  }) {
    final decoded = workProduct.result.decodedHeader!;
    final decryptedHeader = workProduct.decryptedHeader!;
    final masterKeyData = Uint8List.fromList(
      _headerCrypto.dataCipherKeyFromDecryptedHeader(
        fullHeader: decryptedHeader,
        cipherChain: decoded.cipherChain,
      ),
    );
    final session = ToolboxVeraCryptUnlockedSession._(
      service: this,
      randomAccessFile: randomAccessFile,
      byteSource: byteSource,
      fileSize: fileSize ?? byteSource!.length,
      decoded: decoded,
      masterKeyData: masterKeyData,
      writable: writable,
    );
    return ToolboxVeraCryptSessionOpenResult(
      status: ToolboxVeraCryptSessionStatus.success,
      headerUnlockResult: workProduct.result,
      session: session,
    );
  }

  ToolboxVeraCryptSessionStatus _sessionStatusForHeaderUnlock(
    ToolboxVeraCryptHeaderUnlockStatus status,
  ) {
    return switch (status) {
      ToolboxVeraCryptHeaderUnlockStatus.success =>
        ToolboxVeraCryptSessionStatus.success,
      ToolboxVeraCryptHeaderUnlockStatus.missingHeader =>
        ToolboxVeraCryptSessionStatus.missingHeader,
      ToolboxVeraCryptHeaderUnlockStatus.missingMaterial =>
        ToolboxVeraCryptSessionStatus.missingMaterial,
      ToolboxVeraCryptHeaderUnlockStatus.invalidPim =>
        ToolboxVeraCryptSessionStatus.invalidPim,
      ToolboxVeraCryptHeaderUnlockStatus.unsupportedMaterial =>
        ToolboxVeraCryptSessionStatus.unsupportedMaterial,
      ToolboxVeraCryptHeaderUnlockStatus.failed =>
        ToolboxVeraCryptSessionStatus.unlockFailed,
    };
  }

  _VeraCryptHeaderUnlockWorkProduct _attemptHeaderUnlockBytesInternal({
    required Uint8List headerBytes,
    required String passphrase,
    String? pim,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
    ToolboxVeraCryptHeaderWindowKind headerWindowKind =
        ToolboxVeraCryptHeaderWindowKind.primary,
  }) {
    if (headerBytes.length < headerSize) {
      return const _VeraCryptHeaderUnlockWorkProduct(
        result: ToolboxVeraCryptHeaderUnlockResult(
          status: ToolboxVeraCryptHeaderUnlockStatus.missingHeader,
          headerWindowKind: ToolboxVeraCryptHeaderWindowKind.primary,
          attemptedKdfs: <ToolboxVeraCryptKdf>[],
          notes: <String>[
            'toolbox.crypto.veracrypt.note.header_unlock_missing_header',
          ],
        ),
      );
    }

    final summary = summarizeUnlockMaterial(
      passphrase: passphrase,
      pim: pim,
      keyFile: keyFile,
    );
    if (!summary.canAttemptFutureHeaderUnlock) {
      return _VeraCryptHeaderUnlockWorkProduct(
        result: ToolboxVeraCryptHeaderUnlockResult(
          status: summary.pimStatus == ToolboxVeraCryptPimStatus.invalid
              ? ToolboxVeraCryptHeaderUnlockStatus.invalidPim
              : ToolboxVeraCryptHeaderUnlockStatus.missingMaterial,
          headerWindowKind: headerWindowKind,
          attemptedKdfs: const <ToolboxVeraCryptKdf>[],
          notes: <String>[
            if (summary.pimStatus == ToolboxVeraCryptPimStatus.invalid)
              'toolbox.crypto.veracrypt.note.header_unlock_invalid_pim'
            else
              'toolbox.crypto.veracrypt.note.header_unlock_missing_material',
          ],
        ),
      );
    }

    final pimValue = _parsePimForUnlock(pim);
    if (pimValue == null) {
      return _VeraCryptHeaderUnlockWorkProduct(
        result: ToolboxVeraCryptHeaderUnlockResult(
          status: ToolboxVeraCryptHeaderUnlockStatus.invalidPim,
          headerWindowKind: headerWindowKind,
          attemptedKdfs: const <ToolboxVeraCryptKdf>[],
          notes: const <String>[
            'toolbox.crypto.veracrypt.note.header_unlock_invalid_pim',
          ],
        ),
      );
    }

    if (utf8.encode(passphrase).length > maxPassphraseBytes) {
      return _VeraCryptHeaderUnlockWorkProduct(
        result: ToolboxVeraCryptHeaderUnlockResult(
          status: ToolboxVeraCryptHeaderUnlockStatus.unsupportedMaterial,
          headerWindowKind: headerWindowKind,
          attemptedKdfs: const <ToolboxVeraCryptKdf>[],
          notes: const <String>[
            'toolbox.crypto.veracrypt.note.header_unlock_passphrase_too_long',
          ],
        ),
      );
    }

    final header = Uint8List.sublistView(headerBytes, 0, headerSize);
    final salt = Uint8List.sublistView(header, 0, saltSize);
    final encryptedPayload = Uint8List.sublistView(
      header,
      ToolboxVeraCryptHeaderCrypto.encryptedHeaderOffset,
      ToolboxVeraCryptHeaderCrypto.headerSize,
    );
    final rawPasswordBytes = Uint8List.fromList(utf8.encode(passphrase));
    final passwordBytes = _headerCrypto.applyKeyfilePoolToBytes(
      passwordBytes: rawPasswordBytes,
      keyfilePool: keyFile?.poolForPasswordLength(rawPasswordBytes.length),
    );
    final attemptedKdfs = candidateKdfs;
    final headerKeyMaterialCache = <String, Uint8List>{};

    try {
      for (final kdf in attemptedKdfs) {
        final argon2MemoryKiB = kdf == ToolboxVeraCryptKdf.argon2id
            ? argon2MemoryKiBOverrideForTesting ?? kdf.memoryKiBForPim(pimValue)
            : 0;
        if (kdf == ToolboxVeraCryptKdf.argon2id) {
          if (argon2MemoryKiB > maxArgon2HeaderUnlockMemoryKiB) {
            continue;
          }
        }
        final headerKeyMaterialCacheKey = <Object?>[
          kdf.index,
          pimValue,
          iterationOverrideForTesting,
          argon2MemoryKiB,
        ].join(':');
        final headerKeyMaterial =
            headerKeyMaterialCache[headerKeyMaterialCacheKey] ??
            _headerCrypto.deriveHeaderKeyMaterial(
              passwordBytes: passwordBytes,
              salt: salt,
              kdf: kdf,
              pim: pimValue,
              outputSize: ToolboxVeraCryptHeaderCrypto.maxHeaderKeyMaterialSize,
              iterationOverride: iterationOverrideForTesting,
              argon2MemoryKiBOverride: argon2MemoryKiBOverrideForTesting,
            );
        headerKeyMaterialCache[headerKeyMaterialCacheKey] = headerKeyMaterial;
        for (final cipherChain in candidateCipherChains) {
          if (cipherChain.xtsKeySize > headerKeyMaterial.length) {
            continue;
          }
          final headerKey = Uint8List.sublistView(
            headerKeyMaterial,
            0,
            cipherChain.xtsKeySize,
          );
          final decryptedPayload = _headerCrypto.decryptHeaderPayload(
            encryptedPayload: encryptedPayload,
            headerKey: headerKey,
            cipherChain: cipherChain,
          );
          final decryptedHeader = Uint8List(headerSize)
            ..setRange(0, saltSize, salt)
            ..setRange(
              ToolboxVeraCryptHeaderCrypto.encryptedHeaderOffset,
              ToolboxVeraCryptHeaderCrypto.headerSize,
              decryptedPayload,
            );
          final decoded = _headerCrypto.decodeDecryptedHeader(
            fullHeader: decryptedHeader,
            kdf: kdf,
            cipherChain: cipherChain,
            iterations:
                iterationOverrideForTesting ?? kdf.iterationsForPim(pimValue),
            memoryKiB: argon2MemoryKiB,
          );
          if (decoded != null) {
            return _VeraCryptHeaderUnlockWorkProduct(
              result: ToolboxVeraCryptHeaderUnlockResult(
                status: ToolboxVeraCryptHeaderUnlockStatus.success,
                headerWindowKind: headerWindowKind,
                attemptedKdfs: attemptedKdfs,
                decodedHeader: decoded,
                notes: const <String>[
                  'toolbox.crypto.veracrypt.note.header_unlock_success',
                  'toolbox.crypto.veracrypt.note.header_unlock_boundary',
                ],
              ),
              decryptedHeader: decryptedHeader,
            );
          }
          decryptedPayload.fillRange(0, decryptedPayload.length, 0);
          decryptedHeader.fillRange(
            ToolboxVeraCryptHeaderCrypto.encryptedHeaderOffset,
            ToolboxVeraCryptHeaderCrypto.headerSize,
            0,
          );
        }
      }

      return _VeraCryptHeaderUnlockWorkProduct(
        result: ToolboxVeraCryptHeaderUnlockResult(
          status: ToolboxVeraCryptHeaderUnlockStatus.failed,
          headerWindowKind: headerWindowKind,
          attemptedKdfs: attemptedKdfs,
          notes: const <String>[
            'toolbox.crypto.veracrypt.note.header_unlock_failed',
            'toolbox.crypto.veracrypt.note.header_unlock_failed_scope',
          ],
        ),
      );
    } finally {
      for (final keyMaterial in headerKeyMaterialCache.values) {
        keyMaterial.fillRange(0, keyMaterial.length, 0);
      }
      if (!identical(passwordBytes, rawPasswordBytes)) {
        passwordBytes.fillRange(0, passwordBytes.length, 0);
      }
      rawPasswordBytes.fillRange(0, rawPasswordBytes.length, 0);
    }
  }

  Uint8List buildSyntheticAesXtsHeaderForTesting({
    required String passphrase,
    required ToolboxVeraCryptKdf kdf,
    ToolboxVeraCryptCipherChain cipherChain = ToolboxVeraCryptCipherChain.aes,
    int pim = 0,
    ToolboxVeraCryptKeyFileInspectionResult? keyFile,
    Uint8List? salt,
    int volumeSize = 8 * 1024 * 1024,
    int encryptedAreaStart = dataAreaOffset,
    int? encryptedAreaLength,
    int sectorSize = 512,
    Uint8List? masterKeyData,
    int? iterationOverrideForTesting,
    int? argon2MemoryKiBOverrideForTesting,
  }) {
    return _headerCrypto.buildSyntheticHeaderForTesting(
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
      volumeSize: volumeSize,
      encryptedAreaStart: encryptedAreaStart,
      encryptedAreaLength: encryptedAreaLength,
      sectorSize: sectorSize,
      masterKeyData: masterKeyData,
    );
  }

  ToolboxVeraCryptInspectionResult _buildResult({
    required String fileName,
    required int fileSize,
    required Uint8List primaryHeader,
    required Uint8List hiddenHeader,
    required Uint8List backupHeader,
    required Uint8List hiddenBackupHeader,
    required String sha256Preview,
  }) {
    final containerKind = _containerKindFor(fileName);
    final readiness = _readinessFor(fileSize, containerKind);
    final notes = <String>[
      containerKind.noteKey,
      if (fileSize == 0)
        'toolbox.crypto.veracrypt.note.no_file'
      else if (fileSize < minContainerBytes)
        'toolbox.crypto.veracrypt.note.too_small'
      else ...<String>[
        'toolbox.crypto.veracrypt.note.primary_header_present',
        'toolbox.crypto.veracrypt.note.hidden_header_area_present',
        'toolbox.crypto.veracrypt.note.backup_header_present',
        'toolbox.crypto.veracrypt.note.salt_fingerprint_boundary',
        'toolbox.crypto.veracrypt.note.inspect_only_phase',
      ],
      'toolbox.crypto.veracrypt.note.mobile_no_system_mount',
    ];

    return ToolboxVeraCryptInspectionResult(
      fileName: fileName,
      fileSize: fileSize,
      containerKind: containerKind,
      containerExtension: _fileExtensionFor(fileName),
      headerWindows: <ToolboxVeraCryptHeaderWindow>[
        _buildHeaderWindow(
          kind: ToolboxVeraCryptHeaderWindowKind.primary,
          offset: 0,
          bytes: primaryHeader,
        ),
        _buildHeaderWindow(
          kind: ToolboxVeraCryptHeaderWindowKind.hiddenCandidate,
          offset: fileSize >= headerAreaSize + headerSize
              ? headerAreaSize
              : null,
          bytes: hiddenHeader,
        ),
        _buildHeaderWindow(
          kind: ToolboxVeraCryptHeaderWindowKind.backup,
          offset: _backupHeaderOffsetFor(fileSize),
          bytes: backupHeader,
        ),
        _buildHeaderWindow(
          kind: ToolboxVeraCryptHeaderWindowKind.hiddenBackupCandidate,
          offset: _hiddenBackupHeaderOffsetFor(fileSize),
          bytes: hiddenBackupHeader,
        ),
      ],
      minContainerBytes: minContainerBytes,
      readiness: readiness,
      sha256Preview: sha256Preview,
      notes: notes,
      supportMatrix: supportMatrix,
    );
  }

  ToolboxVeraCryptHeaderWindow _buildHeaderWindow({
    required ToolboxVeraCryptHeaderWindowKind kind,
    required int? offset,
    required Uint8List bytes,
  }) {
    return ToolboxVeraCryptHeaderWindow(
      kind: kind,
      offset: offset,
      bytesAvailable: bytes.length,
      expectedBytes: headerSize,
      saltFingerprint: _saltFingerprint(bytes),
    );
  }

  ToolboxVeraCryptReadiness _readinessFor(
    int fileSize,
    ToolboxVeraCryptContainerKind containerKind,
  ) {
    if (fileSize == 0) {
      return ToolboxVeraCryptReadiness.noFile;
    }
    if (fileSize < minContainerBytes) {
      return ToolboxVeraCryptReadiness.tooSmall;
    }
    if (!containerKind.isExpectedContainerName) {
      return ToolboxVeraCryptReadiness.inspectOnly;
    }
    return ToolboxVeraCryptReadiness.readyForHeaderUnlock;
  }

  ToolboxVeraCryptContainerKind _containerKindFor(String fileName) {
    final extension = _fileExtensionFor(fileName);
    return switch (extension) {
      '.hc' => ToolboxVeraCryptContainerKind.veracrypt,
      '.tc' => ToolboxVeraCryptContainerKind.trueCryptLegacy,
      '' => ToolboxVeraCryptContainerKind.extensionless,
      _ => ToolboxVeraCryptContainerKind.reviewExtension,
    };
  }

  String _fileExtensionFor(String fileName) {
    final normalized = fileName.replaceAll('\\', '/');
    final baseName = normalized.split('/').last.trim();
    final dotIndex = baseName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == baseName.length - 1) {
      return '';
    }
    return baseName.substring(dotIndex).toLowerCase();
  }

  int? _hiddenHeaderOffsetFor(int fileSize) {
    return fileSize >= headerAreaSize + headerSize ? headerAreaSize : null;
  }

  int? _backupHeaderOffsetFor(int fileSize) {
    return fileSize >= minContainerBytes
        ? fileSize - backupHeaderAreaSize
        : null;
  }

  int? _hiddenBackupHeaderOffsetFor(int fileSize) {
    return fileSize >= minContainerBytes ? fileSize - headerAreaSize : null;
  }

  Future<Uint8List> _readFileWindow(
    RandomAccessFile file, {
    required int fileSize,
    required int? offset,
    required int length,
  }) async {
    if (offset == null || length <= 0 || offset >= fileSize) {
      return Uint8List(0);
    }
    final readableLength = math.min(length, fileSize - offset);
    await file.setPosition(offset);
    return file.read(readableLength);
  }

  Uint8List _readBytesWindow(
    Uint8List bytes, {
    required int? offset,
    required int length,
  }) {
    if (offset == null || length <= 0 || offset >= bytes.length) {
      return Uint8List(0);
    }
    final end = math.min(bytes.length, offset + length);
    return Uint8List.sublistView(bytes, offset, end);
  }

  String _saltFingerprint(Uint8List headerBytes) {
    if (headerBytes.length < saltSize) {
      return '';
    }
    return _hexDigest(
      crypto.sha256
          .convert(Uint8List.sublistView(headerBytes, 0, saltSize))
          .bytes,
    );
  }

  String _sha256Preview(Uint8List bytes) {
    if (bytes.isEmpty) {
      return '';
    }
    return _hexDigest(crypto.sha256.convert(bytes).bytes);
  }

  String _hexDigest(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  int? _parsePimForUnlock(String? pim) {
    final trimmed = pim?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 0;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return null;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed <= 0 || parsed > maxPimValue) {
      return null;
    }
    return parsed;
  }
}

class _VeraCryptDigestSink implements Sink<crypto.Digest> {
  crypto.Digest? _digest;

  crypto.Digest get digest => _digest!;

  @override
  void add(crypto.Digest data) {
    _digest = data;
  }

  @override
  void close() {}
}

class _VeraCryptKeyfilePoolState {
  _VeraCryptKeyfilePoolState({
    required this.keyfilePool,
    required this.legacyKeyfilePool,
  });

  final Uint8List keyfilePool;
  final Uint8List legacyKeyfilePool;
  int crc = 0xffffffff;
  int writePos = 0;
  int legacyWritePos = 0;
}

void _mixKeyfileByte(_VeraCryptKeyfilePoolState state, int byte) {
  state.crc = ToolboxVeraCryptService._headerCrypto.updateCrc32(
    byte,
    state.crc,
  );
  _mixKeyfilePoolCrcByte(state, (state.crc >> 24) & 0xff);
  _mixKeyfilePoolCrcByte(state, (state.crc >> 16) & 0xff);
  _mixKeyfilePoolCrcByte(state, (state.crc >> 8) & 0xff);
  _mixKeyfilePoolCrcByte(state, state.crc & 0xff);
}

void _mixKeyfilePoolCrcByte(_VeraCryptKeyfilePoolState state, int value) {
  state.keyfilePool[state.writePos] =
      (state.keyfilePool[state.writePos] + value) & 0xff;
  state.writePos =
      (state.writePos + 1) % ToolboxVeraCryptHeaderCrypto.keyfilePoolSize;
  state.legacyKeyfilePool[state.legacyWritePos] =
      (state.legacyKeyfilePool[state.legacyWritePos] + value) & 0xff;
  state.legacyWritePos =
      (state.legacyWritePos + 1) %
      ToolboxVeraCryptHeaderCrypto.legacyKeyfilePoolSize;
}

const Set<int> _plausibleVeraCryptSectorSizes = <int>{512, 1024, 2048, 4096};

String? _validateVeraCryptDecodedLayout(
  ToolboxVeraCryptDecodedHeader decoded, {
  int? containerSize,
}) {
  final sectorSize = decoded.sectorSize;
  if (!_plausibleVeraCryptSectorSizes.contains(sectorSize)) {
    return 'sectorSize';
  }
  if (decoded.encryptedAreaStart < 0 ||
      decoded.encryptedAreaLength <= 0 ||
      decoded.volumeSize <= 0) {
    return 'encryptedArea';
  }
  if (decoded.encryptedAreaStart % sectorSize != 0 ||
      decoded.encryptedAreaLength % sectorSize != 0 ||
      decoded.volumeSize % sectorSize != 0) {
    return 'alignment';
  }
  if (decoded.encryptedAreaLength < sectorSize ||
      decoded.volumeSize > decoded.encryptedAreaLength) {
    return 'encryptedArea';
  }
  if (containerSize != null) {
    if (containerSize <= 0 || decoded.encryptedAreaStart >= containerSize) {
      return 'bounds';
    }
    final availableBytes = containerSize - decoded.encryptedAreaStart;
    if (decoded.encryptedAreaLength > availableBytes) {
      return 'bounds';
    }
  }
  return null;
}
