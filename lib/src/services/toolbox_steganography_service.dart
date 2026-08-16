import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

import 'toolbox_crypto_service.dart';

enum ToolboxSteganographyMediaKind { image, audio, video }

enum ToolboxSteganographyPayloadKind { text, file }

enum ToolboxSteganographyLocatorAlgorithm { sha256, sha512 }

extension ToolboxSteganographyLocatorAlgorithmInfo
    on ToolboxSteganographyLocatorAlgorithm {
  String get id {
    return switch (this) {
      ToolboxSteganographyLocatorAlgorithm.sha256 => 'sha256',
      ToolboxSteganographyLocatorAlgorithm.sha512 => 'sha512',
    };
  }

  String get label {
    return switch (this) {
      ToolboxSteganographyLocatorAlgorithm.sha256 => 'SHA-256',
      ToolboxSteganographyLocatorAlgorithm.sha512 => 'SHA-512',
    };
  }
}

enum ToolboxSteganographyLocatorStrength { standard, strong, extreme }

extension ToolboxSteganographyLocatorStrengthInfo
    on ToolboxSteganographyLocatorStrength {
  String get id {
    return switch (this) {
      ToolboxSteganographyLocatorStrength.standard => 'standard',
      ToolboxSteganographyLocatorStrength.strong => 'strong',
      ToolboxSteganographyLocatorStrength.extreme => 'extreme',
    };
  }

  int get rounds {
    return switch (this) {
      ToolboxSteganographyLocatorStrength.standard => 4096,
      ToolboxSteganographyLocatorStrength.strong => 12000,
      ToolboxSteganographyLocatorStrength.extreme => 24000,
    };
  }

  ToolboxCryptoStrength get cryptoStrength {
    return switch (this) {
      ToolboxSteganographyLocatorStrength.standard =>
        ToolboxCryptoStrength.standard,
      ToolboxSteganographyLocatorStrength.strong =>
        ToolboxCryptoStrength.strong,
      ToolboxSteganographyLocatorStrength.extreme =>
        ToolboxCryptoStrength.extreme,
    };
  }
}

enum ToolboxSteganographyCarrierProtectionMode { deniable, guarded }

extension ToolboxSteganographyCarrierProtectionModeInfo
    on ToolboxSteganographyCarrierProtectionMode {
  String get id {
    return switch (this) {
      ToolboxSteganographyCarrierProtectionMode.deniable => 'deniable',
      ToolboxSteganographyCarrierProtectionMode.guarded => 'guarded',
    };
  }
}

extension ToolboxSteganographyPayloadKindInfo
    on ToolboxSteganographyPayloadKind {
  String get id {
    return switch (this) {
      ToolboxSteganographyPayloadKind.text => 'text',
      ToolboxSteganographyPayloadKind.file => 'file',
    };
  }
}

class ToolboxSteganographyException implements Exception {
  const ToolboxSteganographyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ToolboxSteganographyCarrierFingerprint {
  const ToolboxSteganographyCarrierFingerprint({
    required this.version,
    required this.byteLength,
    required this.md5Hex,
    required this.sha256Hex,
    required this.mixedHex,
  });

  factory ToolboxSteganographyCarrierFingerprint.fromJson(
    Map<String, Object?> json,
  ) {
    final type = json['type'];
    final version = json['version'];
    final byteLength = json['byteLength'];
    final md5Hex = json['md5'];
    final sha256Hex = json['sha256'];
    final mixedHex = json['mixed'];
    if (type != 'vocabulary_sleep_stego_fingerprint' ||
        version is! int ||
        byteLength is! int ||
        md5Hex is! String ||
        sha256Hex is! String ||
        mixedHex is! String) {
      throw const ToolboxSteganographyException('Fingerprint file is invalid.');
    }
    return ToolboxSteganographyCarrierFingerprint(
      version: version,
      byteLength: byteLength,
      md5Hex: md5Hex,
      sha256Hex: sha256Hex,
      mixedHex: mixedHex,
    );
  }

  final int version;
  final int byteLength;
  final String md5Hex;
  final String sha256Hex;
  final String mixedHex;

  Map<String, Object?> toJson({String? fileName, DateTime? createdAt}) {
    return <String, Object?>{
      'type': 'vocabulary_sleep_stego_fingerprint',
      'version': version,
      'createdAt': (createdAt ?? DateTime.now().toUtc()).toIso8601String(),
      'fileName': fileName,
      'byteLength': byteLength,
      'md5': md5Hex,
      'sha256': sha256Hex,
      'mixed': mixedHex,
    };
  }

  String toCopyText() {
    return [
      'VSSIG-v1',
      'bytes=$byteLength',
      'md5=$md5Hex',
      'sha256=$sha256Hex',
      'mixed=$mixedHex',
    ].join('\n');
  }

  Uint8List toFileBytes({String? fileName, DateTime? createdAt}) {
    const encoder = JsonEncoder.withIndent('  ');
    return Uint8List.fromList(
      utf8.encode(
        '${encoder.convert(toJson(fileName: fileName, createdAt: createdAt))}\n',
      ),
    );
  }

  bool matchesBytes(Uint8List bytes) {
    final actual = ToolboxSteganographyService.carrierFingerprint(bytes);
    return byteLength == actual.byteLength &&
        md5Hex == actual.md5Hex &&
        sha256Hex == actual.sha256Hex &&
        mixedHex == actual.mixedHex;
  }
}

class ToolboxSteganographyEmbedResult {
  const ToolboxSteganographyEmbedResult({
    required this.bytes,
    required this.outputExtension,
    required this.payloadBytes,
    required this.sourceBytes,
    required this.outputBytes,
    required this.cipherPreview,
    required this.carrierDetail,
    required this.fingerprint,
    this.capacityBytes,
  });

  final Uint8List bytes;
  final String outputExtension;
  final int payloadBytes;
  final int sourceBytes;
  final int outputBytes;
  final String cipherPreview;
  final String carrierDetail;
  final ToolboxSteganographyCarrierFingerprint fingerprint;
  final int? capacityBytes;
}

class ToolboxSteganographyRevealResult {
  const ToolboxSteganographyRevealResult({
    required this.text,
    required this.encryption,
    required this.strength,
    required this.payloadBytes,
    required this.cipherPreview,
    required this.carrierDetail,
  });

  final String text;
  final ToolboxCryptoAlgorithm encryption;
  final ToolboxCryptoStrength strength;
  final int payloadBytes;
  final String cipherPreview;
  final String carrierDetail;
}

class ToolboxSteganographyFileRevealResult {
  const ToolboxSteganographyFileRevealResult({
    required this.bytes,
    required this.fileName,
    required this.mediaType,
    required this.encryption,
    required this.strength,
    required this.payloadBytes,
    required this.cipherPreview,
    required this.carrierDetail,
  });

  final Uint8List bytes;
  final String? fileName;
  final String? mediaType;
  final ToolboxCryptoAlgorithm encryption;
  final ToolboxCryptoStrength strength;
  final int payloadBytes;
  final String cipherPreview;
  final String carrierDetail;
}

class ToolboxSteganographySanitizeResult {
  const ToolboxSteganographySanitizeResult({
    required this.bytes,
    required this.outputExtension,
    required this.removed,
  });

  final Uint8List bytes;
  final String outputExtension;
  final bool removed;
}

class ToolboxSteganographyCapacityCheck {
  const ToolboxSteganographyCapacityCheck({
    required this.dualLayer,
    required this.width,
    required this.height,
    required this.capacityBytes,
    required this.requiredBytes,
    required this.minimumPixels,
    this.mediaKind = ToolboxSteganographyMediaKind.image,
    this.carrierLabel,
    this.minimumCarrierBytes,
    this.perLayerCapacityBytes,
    this.coverRequiredBytes,
    this.hiddenRequiredBytes,
  });

  final bool dualLayer;
  final ToolboxSteganographyMediaKind mediaKind;
  final int width;
  final int height;
  final int capacityBytes;
  final int requiredBytes;
  final int minimumPixels;
  final String? carrierLabel;
  final int? minimumCarrierBytes;
  final int? perLayerCapacityBytes;
  final int? coverRequiredBytes;
  final int? hiddenRequiredBytes;

  bool get fits {
    if (!dualLayer) {
      return requiredBytes <= capacityBytes;
    }
    final layerCapacity = perLayerCapacityBytes;
    if (layerCapacity == null) {
      return requiredBytes <= capacityBytes;
    }
    return (coverRequiredBytes ?? 0) <= layerCapacity &&
        (hiddenRequiredBytes ?? 0) <= layerCapacity;
  }
}

class ToolboxSteganographyService {
  ToolboxSteganographyService({ToolboxCryptoService? cryptoService})
    : _cryptoService = cryptoService ?? ToolboxCryptoService();

  static final List<int> _sealedBlockMagic = ascii.encode('VSSG4');
  static final List<int> _managedBlockMagic = ascii.encode('VSSG3');
  static const int maxExtensionLength = 12;
  static const int maxImageCarrierBytes = 128 * 1024 * 1024;
  static const int maxImagePixels = 24 * 1000 * 1000;
  static const int maxTailCarrierBytes = 512 * 1024 * 1024;
  static const int maxEmbeddedCryptoEnvelopeBytes =
      ToolboxCryptoService.maxEnvelopeBytes;
  static final List<int> _blockMagic = ascii.encode('VSSG1');
  static final List<int> _protectedBlockMagic = ascii.encode('VSSG2');
  static final List<int> _imagePolicyMagic = ascii.encode('VSSGP2');
  static final List<int> _imageOccupancyMagic = ascii.encode('VSSGO2');
  static final List<int> _riffMagic = ascii.encode('RIFF');
  static final List<int> _aviMagic = ascii.encode('AVI ');
  static final List<int> _waveMagic = ascii.encode('WAVE');
  static final List<int> _wavFmtMagic = ascii.encode('fmt ');
  static final List<int> _wavDataMagic = ascii.encode('data');
  static final List<int> _flacMagic = ascii.encode('fLaC');
  static final List<int> _oggMagic = ascii.encode('OggS');
  static final List<int> _id3Magic = ascii.encode('ID3');
  static final List<int> _amrMagic = ascii.encode('#!AMR');
  static final List<int> _flvMagic = ascii.encode('FLV');
  static final List<int> _mediaPolicyMagic = ascii.encode('VSSGM2');
  static final List<int> _mediaOccupancyMagic = ascii.encode('VSSMO2');
  static final List<int> _mp4StegoBoxType = ascii.encode('free');
  static const String _unsupportedAudioFormatMessage =
      'Unsupported audio format. Use WAV/PCM audio or ISO BMFF audio with existing free-space padding.';
  static const String _unsupportedCompressedAudioMessage =
      'Compressed audio bitstreams cannot be written safely. Use WAV/PCM audio or ISO BMFF audio with existing free-space padding.';
  static const String _unsupportedVideoFormatMessage =
      'Unsupported video format. Use ISO BMFF video with existing free-space padding.';
  static const String _unsupportedComplexVideoMessage =
      'Compressed or complex video containers cannot be written safely. Use ISO BMFF video with existing free-space padding.';
  static const String _isoBmffFreePaddingRequiredMessage =
      'ISO BMFF carrier needs an existing free-space padding box.';
  static const String _isoBmffLargerFreePaddingRequiredMessage =
      'ISO BMFF carrier needs a larger free-space padding box.';
  static const int _protectedBlockTailLength = 16;
  static const int _imageMagicLength = 16;
  static const int _imageNonceLength = 16;
  static const int _imageHeaderLength =
      _imageMagicLength + _imageNonceLength + 4;
  static const int _imagePolicyHeaderLength = 23;
  static const int _locatorSaltLength = 16;
  static const int _locatorSettingsCount = 6;
  static const int _mediaPolicyHeaderLength = 23;
  static const int _mediaMagicLength = 16;
  static const int _mediaNonceLength = 16;
  static const int _mediaHeaderLength =
      _mediaMagicLength + _mediaNonceLength + 4;
  static const int _mp4MaxBoxScanDepth = 128;
  static const double _wavMaxStegoSampleRatio = 0.15;
  static const double _mp4FreeBoxMaxStegoByteRatio = 0.25;
  static const int _mp4MinimumFreeBoxDataBytes = 1024;
  static final math.Random _secureRandom = math.Random.secure();
  final ToolboxCryptoService _cryptoService;

  static String? cleanExtension(String? extension) {
    final value = extension?.replaceFirst('.', '').trim().toLowerCase();
    if (value == null || value.isEmpty || value.length > maxExtensionLength) {
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return cleaned.isEmpty ? null : cleaned;
  }

  static ToolboxSteganographyCarrierFingerprint carrierFingerprint(
    Uint8List bytes,
  ) {
    final md5Bytes = md5.convert(bytes).bytes;
    final sha256Bytes = sha256.convert(bytes).bytes;
    final mixedBuilder = BytesBuilder(copy: false)
      ..add(utf8.encode('vocabulary_sleep_stego_fingerprint_v1'))
      ..addByte(0)
      ..add(_uint64Bytes(bytes.length))
      ..addByte(0);
    for (var index = 0; index < sha256Bytes.length; index += 1) {
      mixedBuilder.addByte(
        sha256Bytes[(index * 7) % sha256Bytes.length] ^
            md5Bytes[(index * 5) % md5Bytes.length] ^
            index,
      );
    }
    final mixed = sha256.convert(mixedBuilder.takeBytes()).bytes;
    return ToolboxSteganographyCarrierFingerprint(
      version: 1,
      byteLength: bytes.length,
      md5Hex: _hexDigest(md5Bytes),
      sha256Hex: _hexDigest(sha256Bytes),
      mixedHex: _hexDigest(mixed),
    );
  }

  static ToolboxSteganographyCarrierFingerprint parseFingerprintBytes(
    Uint8List bytes,
  ) {
    final text = utf8.decode(bytes).trim();
    if (text.startsWith('{')) {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, Object?>) {
        throw const ToolboxSteganographyException(
          'Fingerprint file is invalid.',
        );
      }
      return ToolboxSteganographyCarrierFingerprint.fromJson(decoded);
    }
    final values = <String, String>{};
    for (final line in const LineSplitter().convert(text)) {
      final separator = line.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      values[line.substring(0, separator).trim()] = line
          .substring(separator + 1)
          .trim();
    }
    final byteLength = int.tryParse(values['bytes'] ?? '');
    final md5Hex = values['md5'];
    final sha256Hex = values['sha256'];
    final mixedHex = values['mixed'];
    if (byteLength == null ||
        md5Hex == null ||
        sha256Hex == null ||
        mixedHex == null) {
      throw const ToolboxSteganographyException('Fingerprint file is invalid.');
    }
    return ToolboxSteganographyCarrierFingerprint(
      version: 1,
      byteLength: byteLength,
      md5Hex: md5Hex,
      sha256Hex: sha256Hex,
      mixedHex: mixedHex,
    );
  }

  ToolboxSteganographyCapacityCheck checkTextWriteCapacity({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required String text,
    required bool dualLayerEnabled,
    String coverText = '',
    required ToolboxCryptoAlgorithm encryption,
    required String passphrase,
    String coverPassphrase = '',
    ToolboxCryptoStrength strength = ToolboxCryptoStrength.standard,
    Uint8List? keyFileBytes,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }
    if (dualLayerEnabled) {
      if (coverText.isEmpty || text.isEmpty) {
        throw const ToolboxSteganographyException('Secret text is empty.');
      }
      if (coverPassphrase.trim().isEmpty || passphrase.trim().isEmpty) {
        throw const ToolboxSteganographyException(
          'Dual-layer mode requires both passphrases.',
        );
      }
      if (coverPassphrase == passphrase) {
        throw const ToolboxSteganographyException(
          'Dual-layer passphrases must be different.',
        );
      }
    } else if (text.isEmpty) {
      throw const ToolboxSteganographyException('Secret text is empty.');
    }
    if (encryption.requiresSecret &&
        passphrase.trim().isEmpty &&
        (keyFileBytes == null || keyFileBytes.isEmpty)) {
      throw const ToolboxSteganographyException(
        'This encryption mode requires a passphrase or key file.',
      );
    }
    _validateStegoWriteSecurity(
      encryption: encryption,
      strength: strength,
      keyFileBytes: keyFileBytes,
    );
    _validateMediaWriteBackend(mediaKind);

    if (dualLayerEnabled) {
      final coverRequired = _estimatedBlockLength(
        payloadKind: ToolboxSteganographyPayloadKind.text,
        plainBytesLength: utf8.encode(coverText).length,
        encryption: encryption,
        strength: strength,
        cascade: cascade,
        keyBits: keyBits,
        macAlgorithm: macAlgorithm,
        signatureMode: signatureMode,
      );
      final hiddenRequired = _estimatedBlockLength(
        payloadKind: ToolboxSteganographyPayloadKind.text,
        plainBytesLength: utf8.encode(text).length,
        encryption: encryption,
        strength: strength,
        cascade: cascade,
        keyBits: keyBits,
        macAlgorithm: macAlgorithm,
        signatureMode: signatureMode,
      );
      return _checkDualCapacity(
        mediaKind: mediaKind,
        carrierBytes: carrierBytes,
        coverRequiredBytes: coverRequired,
        hiddenRequiredBytes: hiddenRequired,
      );
    }

    final requiredBytes = _estimatedBlockLength(
      payloadKind: ToolboxSteganographyPayloadKind.text,
      plainBytesLength: utf8.encode(text).length,
      encryption: encryption,
      strength: strength,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _checkSingleImageCapacity(
        carrierBytes: carrierBytes,
        requiredBytes: requiredBytes,
      ),
      ToolboxSteganographyMediaKind.audio => _checkAudioCapacity(
        carrierBytes: carrierBytes,
        requiredBytes: requiredBytes,
      ),
      ToolboxSteganographyMediaKind.video => _checkVideoCapacity(
        carrierBytes: carrierBytes,
        requiredBytes: requiredBytes,
      ),
    };
  }

  ToolboxSteganographyCapacityCheck checkFileWriteCapacity({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required Uint8List fileBytes,
    bool dualLayerEnabled = false,
    Uint8List? coverFileBytes,
    required ToolboxCryptoAlgorithm encryption,
    required String passphrase,
    String coverPassphrase = '',
    ToolboxCryptoStrength strength = ToolboxCryptoStrength.standard,
    Uint8List? keyFileBytes,
    String? fileName,
    String? mediaType,
    String? coverFileName,
    String? coverMediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }
    if (fileBytes.isEmpty) {
      throw const ToolboxSteganographyException('Secret file is empty.');
    }
    if (dualLayerEnabled) {
      if (coverFileBytes == null || coverFileBytes.isEmpty) {
        throw const ToolboxSteganographyException('Cover file is empty.');
      }
      if (coverPassphrase.trim().isEmpty || passphrase.trim().isEmpty) {
        throw const ToolboxSteganographyException(
          'Dual-layer mode requires both passphrases.',
        );
      }
      if (coverPassphrase == passphrase) {
        throw const ToolboxSteganographyException(
          'Dual-layer passphrases must be different.',
        );
      }
    }
    if (encryption.requiresSecret &&
        passphrase.trim().isEmpty &&
        (keyFileBytes == null || keyFileBytes.isEmpty)) {
      throw const ToolboxSteganographyException(
        'This encryption mode requires a passphrase or key file.',
      );
    }
    _validateStegoWriteSecurity(
      encryption: encryption,
      strength: strength,
      keyFileBytes: keyFileBytes,
    );
    _validateMediaWriteBackend(mediaKind);

    if (dualLayerEnabled) {
      final coverRequired = _estimatedBlockLength(
        payloadKind: ToolboxSteganographyPayloadKind.file,
        plainBytesLength: coverFileBytes!.length,
        encryption: encryption,
        strength: strength,
        fileName: coverFileName,
        mediaType: coverMediaType,
        cascade: cascade,
        keyBits: keyBits,
        macAlgorithm: macAlgorithm,
        signatureMode: signatureMode,
      );
      final hiddenRequired = _estimatedBlockLength(
        payloadKind: ToolboxSteganographyPayloadKind.file,
        plainBytesLength: fileBytes.length,
        encryption: encryption,
        strength: strength,
        fileName: fileName,
        mediaType: mediaType,
        cascade: cascade,
        keyBits: keyBits,
        macAlgorithm: macAlgorithm,
        signatureMode: signatureMode,
      );
      return _checkDualCapacity(
        mediaKind: mediaKind,
        carrierBytes: carrierBytes,
        coverRequiredBytes: coverRequired,
        hiddenRequiredBytes: hiddenRequired,
      );
    }

    final requiredBytes = _estimatedBlockLength(
      payloadKind: ToolboxSteganographyPayloadKind.file,
      plainBytesLength: fileBytes.length,
      encryption: encryption,
      strength: strength,
      fileName: fileName,
      mediaType: mediaType,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _checkSingleImageCapacity(
        carrierBytes: carrierBytes,
        requiredBytes: requiredBytes,
      ),
      ToolboxSteganographyMediaKind.audio => _checkAudioCapacity(
        carrierBytes: carrierBytes,
        requiredBytes: requiredBytes,
      ),
      ToolboxSteganographyMediaKind.video => _checkVideoCapacity(
        carrierBytes: carrierBytes,
        requiredBytes: requiredBytes,
      ),
    };
  }

  ToolboxSteganographyEmbedResult embedText({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required String text,
    required ToolboxCryptoAlgorithm encryption,
    required String passphrase,
    ToolboxCryptoStrength strength = ToolboxCryptoStrength.standard,
    Uint8List? keyFileBytes,
    String? sourceExtension,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
    ToolboxSteganographyLocatorAlgorithm locatorAlgorithm =
        ToolboxSteganographyLocatorAlgorithm.sha256,
    ToolboxSteganographyLocatorStrength locatorStrength =
        ToolboxSteganographyLocatorStrength.standard,
    ToolboxSteganographyCarrierProtectionMode carrierProtectionMode =
        ToolboxSteganographyCarrierProtectionMode.deniable,
    bool allowCarrierOverwrite = false,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }
    if (text.isEmpty) {
      throw const ToolboxSteganographyException('Secret text is empty.');
    }
    if (encryption.requiresSecret &&
        passphrase.trim().isEmpty &&
        (keyFileBytes == null || keyFileBytes.isEmpty)) {
      throw const ToolboxSteganographyException(
        'This encryption mode requires a passphrase or key file.',
      );
    }
    _validateStegoWriteSecurity(
      encryption: encryption,
      strength: strength,
      keyFileBytes: keyFileBytes,
    );
    _validateMediaWriteBackend(mediaKind);

    final envelope = _buildEnvelope(
      payloadKind: ToolboxSteganographyPayloadKind.text,
      text: text,
      encryption: encryption,
      passphrase: passphrase,
      strength: strength,
      keyFileBytes: keyFileBytes,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final block = _buildBlock(envelope.jsonBytes);

    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _embedInImage(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
      ToolboxSteganographyMediaKind.audio => _embedInAudio(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
      ToolboxSteganographyMediaKind.video => _embedInVideo(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
    };
  }

  ToolboxSteganographyEmbedResult embedDualText({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required String coverText,
    required String hiddenText,
    required ToolboxCryptoAlgorithm encryption,
    required String coverPassphrase,
    required String hiddenPassphrase,
    ToolboxCryptoStrength strength = ToolboxCryptoStrength.standard,
    Uint8List? hiddenKeyFileBytes,
    String? sourceExtension,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
    ToolboxSteganographyLocatorAlgorithm locatorAlgorithm =
        ToolboxSteganographyLocatorAlgorithm.sha256,
    ToolboxSteganographyLocatorStrength locatorStrength =
        ToolboxSteganographyLocatorStrength.standard,
    ToolboxSteganographyCarrierProtectionMode carrierProtectionMode =
        ToolboxSteganographyCarrierProtectionMode.deniable,
    bool allowCarrierOverwrite = false,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }
    if (coverText.isEmpty || hiddenText.isEmpty) {
      throw const ToolboxSteganographyException('Secret text is empty.');
    }
    if (coverPassphrase.trim().isEmpty || hiddenPassphrase.trim().isEmpty) {
      throw const ToolboxSteganographyException(
        'Dual-layer mode requires both passphrases.',
      );
    }
    if (coverPassphrase == hiddenPassphrase) {
      throw const ToolboxSteganographyException(
        'Dual-layer passphrases must be different.',
      );
    }
    if (encryption.requiresSecret &&
        hiddenPassphrase.trim().isEmpty &&
        (hiddenKeyFileBytes == null || hiddenKeyFileBytes.isEmpty)) {
      throw const ToolboxSteganographyException(
        'This encryption mode requires a passphrase or key file.',
      );
    }
    _validateStegoWriteSecurity(
      encryption: encryption,
      strength: strength,
      keyFileBytes: hiddenKeyFileBytes,
    );
    _validateMediaWriteBackend(mediaKind);

    final coverEnvelope = _buildEnvelope(
      payloadKind: ToolboxSteganographyPayloadKind.text,
      text: coverText,
      encryption: encryption,
      passphrase: coverPassphrase,
      strength: strength,
      keyFileBytes: null,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final hiddenEnvelope = _buildEnvelope(
      payloadKind: ToolboxSteganographyPayloadKind.text,
      text: hiddenText,
      encryption: encryption,
      passphrase: hiddenPassphrase,
      strength: strength,
      keyFileBytes: hiddenKeyFileBytes,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final coverBlock = _buildBlock(coverEnvelope.jsonBytes);
    final hiddenBlock = _buildBlock(hiddenEnvelope.jsonBytes);

    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _embedDualTextInImage(
        carrierBytes: carrierBytes,
        coverBlock: coverBlock,
        hiddenBlock: hiddenBlock,
        hiddenEnvelope: hiddenEnvelope,
        coverPassphrase: coverPassphrase,
        hiddenPassphrase: hiddenPassphrase,
        hiddenKeyFileBytes: hiddenKeyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
      ToolboxSteganographyMediaKind.audio => _embedDualBlocksInAudio(
        carrierBytes: carrierBytes,
        coverBlock: coverBlock,
        hiddenBlock: hiddenBlock,
        hiddenCipherPreview: hiddenEnvelope.cipherPreview,
        sourceExtension: sourceExtension,
        coverPassphrase: coverPassphrase,
        hiddenPassphrase: hiddenPassphrase,
        hiddenKeyFileBytes: hiddenKeyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
      ToolboxSteganographyMediaKind.video => _embedDualBlocksInVideo(
        carrierBytes: carrierBytes,
        coverBlock: coverBlock,
        hiddenBlock: hiddenBlock,
        hiddenCipherPreview: hiddenEnvelope.cipherPreview,
        sourceExtension: sourceExtension,
        coverPassphrase: coverPassphrase,
        hiddenPassphrase: hiddenPassphrase,
        hiddenKeyFileBytes: hiddenKeyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
    };
  }

  ToolboxSteganographyEmbedResult embedFile({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required Uint8List fileBytes,
    required ToolboxCryptoAlgorithm encryption,
    required String passphrase,
    ToolboxCryptoStrength strength = ToolboxCryptoStrength.standard,
    Uint8List? keyFileBytes,
    String? sourceExtension,
    String? fileName,
    String? mediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
    ToolboxSteganographyLocatorAlgorithm locatorAlgorithm =
        ToolboxSteganographyLocatorAlgorithm.sha256,
    ToolboxSteganographyLocatorStrength locatorStrength =
        ToolboxSteganographyLocatorStrength.standard,
    ToolboxSteganographyCarrierProtectionMode carrierProtectionMode =
        ToolboxSteganographyCarrierProtectionMode.deniable,
    bool allowCarrierOverwrite = false,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }
    if (fileBytes.isEmpty) {
      throw const ToolboxSteganographyException('Secret file is empty.');
    }
    if (encryption.requiresSecret &&
        passphrase.trim().isEmpty &&
        (keyFileBytes == null || keyFileBytes.isEmpty)) {
      throw const ToolboxSteganographyException(
        'This encryption mode requires a passphrase or key file.',
      );
    }
    _validateStegoWriteSecurity(
      encryption: encryption,
      strength: strength,
      keyFileBytes: keyFileBytes,
    );
    _validateMediaWriteBackend(mediaKind);

    final envelope = _buildEnvelope(
      payloadKind: ToolboxSteganographyPayloadKind.file,
      plainBytes: fileBytes,
      encryption: encryption,
      passphrase: passphrase,
      strength: strength,
      keyFileBytes: keyFileBytes,
      fileName: fileName,
      mediaType: mediaType,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final block = _buildBlock(envelope.jsonBytes);

    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _embedInImage(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
      ToolboxSteganographyMediaKind.audio => _embedInAudio(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
      ToolboxSteganographyMediaKind.video => _embedInVideo(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
    };
  }

  ToolboxSteganographyEmbedResult embedDualFile({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required Uint8List coverFileBytes,
    required Uint8List hiddenFileBytes,
    required ToolboxCryptoAlgorithm encryption,
    required String coverPassphrase,
    required String hiddenPassphrase,
    ToolboxCryptoStrength strength = ToolboxCryptoStrength.standard,
    Uint8List? hiddenKeyFileBytes,
    String? sourceExtension,
    String? coverFileName,
    String? coverMediaType,
    String? hiddenFileName,
    String? hiddenMediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
    ToolboxSteganographyLocatorAlgorithm locatorAlgorithm =
        ToolboxSteganographyLocatorAlgorithm.sha256,
    ToolboxSteganographyLocatorStrength locatorStrength =
        ToolboxSteganographyLocatorStrength.standard,
    ToolboxSteganographyCarrierProtectionMode carrierProtectionMode =
        ToolboxSteganographyCarrierProtectionMode.deniable,
    bool allowCarrierOverwrite = false,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }
    if (coverFileBytes.isEmpty || hiddenFileBytes.isEmpty) {
      throw const ToolboxSteganographyException('Secret file is empty.');
    }
    if (coverPassphrase.trim().isEmpty || hiddenPassphrase.trim().isEmpty) {
      throw const ToolboxSteganographyException(
        'Dual-layer mode requires both passphrases.',
      );
    }
    if (coverPassphrase == hiddenPassphrase) {
      throw const ToolboxSteganographyException(
        'Dual-layer passphrases must be different.',
      );
    }
    if (encryption.requiresSecret &&
        hiddenPassphrase.trim().isEmpty &&
        (hiddenKeyFileBytes == null || hiddenKeyFileBytes.isEmpty)) {
      throw const ToolboxSteganographyException(
        'This encryption mode requires a passphrase or key file.',
      );
    }
    _validateStegoWriteSecurity(
      encryption: encryption,
      strength: strength,
      keyFileBytes: hiddenKeyFileBytes,
    );
    _validateMediaWriteBackend(mediaKind);

    final coverEnvelope = _buildEnvelope(
      payloadKind: ToolboxSteganographyPayloadKind.file,
      plainBytes: coverFileBytes,
      encryption: encryption,
      passphrase: coverPassphrase,
      strength: strength,
      keyFileBytes: null,
      fileName: coverFileName,
      mediaType: coverMediaType,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final hiddenEnvelope = _buildEnvelope(
      payloadKind: ToolboxSteganographyPayloadKind.file,
      plainBytes: hiddenFileBytes,
      encryption: encryption,
      passphrase: hiddenPassphrase,
      strength: strength,
      keyFileBytes: hiddenKeyFileBytes,
      fileName: hiddenFileName,
      mediaType: hiddenMediaType,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final coverBlock = _buildBlock(coverEnvelope.jsonBytes);
    final hiddenBlock = _buildBlock(hiddenEnvelope.jsonBytes);

    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _embedDualBlocksInImage(
        carrierBytes: carrierBytes,
        coverBlock: coverBlock,
        hiddenBlock: hiddenBlock,
        hiddenCipherPreview: hiddenEnvelope.cipherPreview,
        coverPassphrase: coverPassphrase,
        hiddenPassphrase: hiddenPassphrase,
        hiddenKeyFileBytes: hiddenKeyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
      ToolboxSteganographyMediaKind.audio => _embedDualBlocksInAudio(
        carrierBytes: carrierBytes,
        coverBlock: coverBlock,
        hiddenBlock: hiddenBlock,
        hiddenCipherPreview: hiddenEnvelope.cipherPreview,
        sourceExtension: sourceExtension,
        coverPassphrase: coverPassphrase,
        hiddenPassphrase: hiddenPassphrase,
        hiddenKeyFileBytes: hiddenKeyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
      ToolboxSteganographyMediaKind.video => _embedDualBlocksInVideo(
        carrierBytes: carrierBytes,
        coverBlock: coverBlock,
        hiddenBlock: hiddenBlock,
        hiddenCipherPreview: hiddenEnvelope.cipherPreview,
        sourceExtension: sourceExtension,
        coverPassphrase: coverPassphrase,
        hiddenPassphrase: hiddenPassphrase,
        hiddenKeyFileBytes: hiddenKeyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      ),
    };
  }

  ToolboxSteganographyRevealResult revealText({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
    ToolboxSteganographyLocatorAlgorithm locatorAlgorithm =
        ToolboxSteganographyLocatorAlgorithm.sha256,
    ToolboxSteganographyLocatorStrength locatorStrength =
        ToolboxSteganographyLocatorStrength.standard,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }

    final block = switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _extractImageBlock(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.audio => _extractAudioBlock(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.video => _extractVideoBlock(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
    };
    final map = _parseBlock(block);
    final envelope = _parseEnvelope(
      map,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );

    return ToolboxSteganographyRevealResult(
      text: envelope.text,
      encryption: envelope.encryption,
      strength: envelope.strength,
      payloadBytes: block.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail: _carrierDetailForReveal(mediaKind, carrierBytes),
    );
  }

  ToolboxSteganographyFileRevealResult revealFile({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
    ToolboxSteganographyLocatorAlgorithm locatorAlgorithm =
        ToolboxSteganographyLocatorAlgorithm.sha256,
    ToolboxSteganographyLocatorStrength locatorStrength =
        ToolboxSteganographyLocatorStrength.standard,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }

    final block = switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _extractImageBlock(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.audio => _extractAudioBlock(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.video => _extractVideoBlock(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
    };
    final map = _parseBlock(block);
    final envelope = _parseFileEnvelope(
      map,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );

    return ToolboxSteganographyFileRevealResult(
      bytes: envelope.bytes,
      fileName: envelope.fileName,
      mediaType: envelope.mediaType,
      encryption: envelope.encryption,
      strength: envelope.strength,
      payloadBytes: block.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail: _carrierDetailForReveal(mediaKind, carrierBytes),
    );
  }

  ToolboxSteganographySanitizeResult stripHiddenData({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
    ToolboxSteganographyLocatorAlgorithm locatorAlgorithm =
        ToolboxSteganographyLocatorAlgorithm.sha256,
    ToolboxSteganographyLocatorStrength locatorStrength =
        ToolboxSteganographyLocatorStrength.standard,
  }) {
    if (carrierBytes.isEmpty) {
      throw const ToolboxSteganographyException('Source media is empty.');
    }
    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _stripImagePayload(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.audio => _stripAudioPayload(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.video => _stripVideoPayload(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
    };
  }

  void _validateMediaWriteBackend(ToolboxSteganographyMediaKind mediaKind) {
    switch (mediaKind) {
      case ToolboxSteganographyMediaKind.image:
      case ToolboxSteganographyMediaKind.audio:
      case ToolboxSteganographyMediaKind.video:
        return;
    }
  }

  void _validateStegoWriteSecurity({
    required ToolboxCryptoAlgorithm encryption,
    required ToolboxCryptoStrength strength,
    required Uint8List? keyFileBytes,
  }) {
    if (!_isStegoWriteAead(encryption)) {
      throw const ToolboxSteganographyException(
        'Steganography writes require AEAD encryption; plaintext and signature-only modes are disabled.',
      );
    }
    if (strength == ToolboxCryptoStrength.extreme &&
        (keyFileBytes == null || keyFileBytes.isEmpty)) {
      throw const ToolboxSteganographyException(
        'High security steganography requires a key file.',
      );
    }
  }

  bool _isStegoWriteAead(ToolboxCryptoAlgorithm algorithm) {
    return switch (algorithm) {
      ToolboxCryptoAlgorithm.aesGcm ||
      ToolboxCryptoAlgorithm.chacha20Poly1305 ||
      ToolboxCryptoAlgorithm.camelliaGcm ||
      ToolboxCryptoAlgorithm.twofishGcm ||
      ToolboxCryptoAlgorithm.aesTwofishGcm ||
      ToolboxCryptoAlgorithm.aesCamelliaGcm ||
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm ||
      ToolboxCryptoAlgorithm.customCascade => true,
      _ => false,
    };
  }

  img.Image _decodeCarrierImage(
    Uint8List carrierBytes, {
    required String failureMessage,
  }) {
    if (carrierBytes.length > maxImageCarrierBytes) {
      throw const ToolboxSteganographyException('Image file is too large.');
    }
    final decoded = img.decodeImage(carrierBytes);
    if (decoded == null) {
      throw ToolboxSteganographyException(failureMessage);
    }
    final image = img.bakeOrientation(decoded);
    _validateImageDimensions(image);
    return image;
  }

  void _validateImageDimensions(img.Image image) {
    final pixels = image.width * image.height;
    if (pixels > maxImagePixels) {
      throw const ToolboxSteganographyException(
        'Image dimensions are too large.',
      );
    }
  }

  void _validateTailCarrierSize(Uint8List carrierBytes) {
    if (carrierBytes.length > maxTailCarrierBytes) {
      throw const ToolboxSteganographyException('Source media is too large.');
    }
  }

  void _ensureImageWriteAllowed(
    img.Image image, {
    required List<_ImageWriteCredential> credentials,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required bool allowCarrierOverwrite,
  }) {
    if (allowCarrierOverwrite) {
      return;
    }
    for (final credential in credentials) {
      try {
        final read = _readAnyRandomizedLsbBlockDetails(
          image,
          passphrase: credential.passphrase,
          keyFileBytes: credential.keyFileBytes,
          locatorAlgorithm: locatorAlgorithm,
          locatorStrength: locatorStrength,
        );
        _parseBlock(read.block);
        throw const ToolboxSteganographyException(
          'Carrier already contains a payload readable with the current credential. Enable overwrite only if you intentionally want to replace it.',
        );
      } on ToolboxSteganographyException catch (error) {
        if (error.message ==
            'Carrier already contains a payload readable with the current credential. Enable overwrite only if you intentionally want to replace it.') {
          rethrow;
        }
      }
    }
  }

  void _ensureAudioWriteAllowed(
    Uint8List carrierBytes, {
    required List<_ImageWriteCredential> credentials,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required bool allowCarrierOverwrite,
  }) {
    if (allowCarrierOverwrite) {
      return;
    }
    final audioCarrier = _parseAudioCarrier(carrierBytes);
    for (final credential in credentials) {
      try {
        final read = _readAnyAudioBlockDetails(
          passphrase: credential.passphrase,
          keyFileBytes: credential.keyFileBytes,
          locatorAlgorithm: locatorAlgorithm,
          locatorStrength: locatorStrength,
          carrierBytes: carrierBytes,
          carrier: audioCarrier,
        );
        _parseBlock(read.block);
        throw const ToolboxSteganographyException(
          'Carrier already contains a payload readable with the current credential. Enable overwrite only if you intentionally want to replace it.',
        );
      } on ToolboxSteganographyException catch (error) {
        if (error.message ==
            'Carrier already contains a payload readable with the current credential. Enable overwrite only if you intentionally want to replace it.') {
          rethrow;
        }
      }
    }
  }

  void _ensureVideoWriteAllowed(
    Uint8List carrierBytes, {
    required List<_ImageWriteCredential> credentials,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required bool allowCarrierOverwrite,
  }) {
    if (allowCarrierOverwrite) {
      return;
    }
    final videoCarrier = _parseVideoCarrier(carrierBytes);
    for (final credential in credentials) {
      try {
        final read = _readAnyIsoBmffFreeBoxBlockDetails(
          passphrase: credential.passphrase,
          keyFileBytes: credential.keyFileBytes,
          locatorAlgorithm: locatorAlgorithm,
          locatorStrength: locatorStrength,
          carrierBytes: carrierBytes,
          carrier: videoCarrier,
        );
        _parseBlock(read.block);
        throw const ToolboxSteganographyException(
          'Carrier already contains a payload readable with the current credential. Enable overwrite only if you intentionally want to replace it.',
        );
      } on ToolboxSteganographyException catch (error) {
        if (error.message ==
            'Carrier already contains a payload readable with the current credential. Enable overwrite only if you intentionally want to replace it.') {
          rethrow;
        }
      }
    }
  }

  ToolboxSteganographyCapacityCheck _checkSingleImageCapacity({
    required Uint8List carrierBytes,
    required int requiredBytes,
  }) {
    final image = _decodeCarrierImage(
      carrierBytes,
      failureMessage:
          'Unsupported image format. Pick PNG/JPG/WebP/GIF style images.',
    );
    final totalPositions = image.width * image.height * 3;
    final reservedHeaderBytes = _imageHeaderLength + _imagePolicyHeaderLength;
    final capacity = (totalPositions - (reservedHeaderBytes * 8)) ~/ 8;
    if (capacity <= 0) {
      throw const ToolboxSteganographyException('Image is too small.');
    }
    return ToolboxSteganographyCapacityCheck(
      dualLayer: false,
      mediaKind: ToolboxSteganographyMediaKind.image,
      width: image.width,
      height: image.height,
      capacityBytes: capacity,
      requiredBytes: requiredBytes,
      minimumPixels: _minimumSingleLayerPixels(requiredBytes),
      carrierLabel: 'PNG image randomized LSB',
    );
  }

  ToolboxSteganographyCapacityCheck _checkDualImageCapacity({
    required Uint8List carrierBytes,
    required int coverRequiredBytes,
    required int hiddenRequiredBytes,
  }) {
    final image = _decodeCarrierImage(
      carrierBytes,
      failureMessage:
          'Unsupported image format. Pick PNG/JPG/WebP/GIF style images.',
    );
    final totalPositions = image.width * image.height * 3;
    final policyPositions = _imagePolicyPositions(
      image,
      headerLength: _imagePolicyHeaderLength,
    );
    final coverCapacity = _imageSlotCapacity(
      totalPositions: totalPositions,
      policyPositions: policyPositions,
      slot: 1,
    );
    final hiddenCapacity = _imageSlotCapacity(
      totalPositions: totalPositions,
      policyPositions: policyPositions,
      slot: 0,
    );
    final perLayerCapacity = math.min(coverCapacity, hiddenCapacity);
    final requiredBytes = math.max(coverRequiredBytes, hiddenRequiredBytes);
    return ToolboxSteganographyCapacityCheck(
      dualLayer: true,
      mediaKind: ToolboxSteganographyMediaKind.image,
      width: image.width,
      height: image.height,
      capacityBytes: coverCapacity + hiddenCapacity,
      requiredBytes: requiredBytes,
      perLayerCapacityBytes: perLayerCapacity,
      coverRequiredBytes: coverRequiredBytes,
      hiddenRequiredBytes: hiddenRequiredBytes,
      minimumPixels: _minimumDualLayerPixels(requiredBytes),
      carrierLabel: 'PNG image dual randomized LSB',
    );
  }

  ToolboxSteganographyCapacityCheck _checkDualCapacity({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required int coverRequiredBytes,
    required int hiddenRequiredBytes,
  }) {
    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _checkDualImageCapacity(
        carrierBytes: carrierBytes,
        coverRequiredBytes: coverRequiredBytes,
        hiddenRequiredBytes: hiddenRequiredBytes,
      ),
      ToolboxSteganographyMediaKind.audio => _checkDualAudioCapacity(
        carrierBytes: carrierBytes,
        coverRequiredBytes: coverRequiredBytes,
        hiddenRequiredBytes: hiddenRequiredBytes,
      ),
      ToolboxSteganographyMediaKind.video => _checkDualVideoCapacity(
        carrierBytes: carrierBytes,
        coverRequiredBytes: coverRequiredBytes,
        hiddenRequiredBytes: hiddenRequiredBytes,
      ),
    };
  }

  ToolboxSteganographyCapacityCheck _checkAudioCapacity({
    required Uint8List carrierBytes,
    required int requiredBytes,
  }) {
    final carrier = _parseAudioCarrier(carrierBytes);
    final wav = carrier.wav;
    if (wav == null) {
      final isoBmff = carrier.isoBmff!;
      final region = _largestWritableMp4FreeRegion(isoBmff);
      final capacity = _mp4FreeBoxBlockCapacity(region);
      if (capacity <= 0) {
        throw const ToolboxSteganographyException(
          _isoBmffFreePaddingRequiredMessage,
        );
      }
      return ToolboxSteganographyCapacityCheck(
        dualLayer: false,
        mediaKind: ToolboxSteganographyMediaKind.audio,
        width: 0,
        height: 0,
        capacityBytes: capacity,
        requiredBytes: requiredBytes,
        minimumPixels: 0,
        minimumCarrierBytes: carrierBytes.length,
        carrierLabel:
            '${_isoBmffCarrierLabel(isoBmff)} audio existing free-space LSB',
      );
    }
    final profile = _wavStegoProfile(carrierBytes, wav);
    final policySamples = _wavPolicySamples(carrierBytes, wav, profile);
    final capacity = _wavBlockCapacity(profile, policySamples: policySamples);
    if (capacity <= 0) {
      throw const ToolboxSteganographyException('Audio carrier is too small.');
    }
    return ToolboxSteganographyCapacityCheck(
      dualLayer: false,
      mediaKind: ToolboxSteganographyMediaKind.audio,
      width: 0,
      height: 0,
      capacityBytes: capacity,
      requiredBytes: requiredBytes,
      minimumPixels: _minimumWavSamples(requiredBytes),
      minimumCarrierBytes: _minimumWavCarrierBytes(wav, requiredBytes),
      carrierLabel:
          'WAV/PCM ${wav.bitsPerSample}-bit low-density randomized sample LSB',
    );
  }

  ToolboxSteganographyCapacityCheck _checkDualAudioCapacity({
    required Uint8List carrierBytes,
    required int coverRequiredBytes,
    required int hiddenRequiredBytes,
  }) {
    final carrier = _parseAudioCarrier(carrierBytes);
    final wav = carrier.wav;
    if (wav == null) {
      final isoBmff = carrier.isoBmff!;
      final region = _largestWritableMp4FreeRegion(isoBmff);
      final policyPositions = _mp4FreePolicyPositions(
        carrierBytes,
        region,
        _mp4FreeCarrierDigest(
          carrierBytes,
          region,
          purpose: 'video-free-public-policy',
        ),
      );
      final coverCapacity = _mp4FreeBoxSlotCapacity(
        region,
        1,
        policyPositions: policyPositions,
      );
      final hiddenCapacity = _mp4FreeBoxSlotCapacity(
        region,
        0,
        policyPositions: policyPositions,
      );
      final capacity = coverCapacity + hiddenCapacity;
      final perLayerCapacity = math.min(coverCapacity, hiddenCapacity);
      final requiredBytes = math.max(coverRequiredBytes, hiddenRequiredBytes);
      if (perLayerCapacity <= 0) {
        throw const ToolboxSteganographyException(
          _isoBmffFreePaddingRequiredMessage,
        );
      }
      return ToolboxSteganographyCapacityCheck(
        dualLayer: true,
        mediaKind: ToolboxSteganographyMediaKind.audio,
        width: 0,
        height: 0,
        capacityBytes: capacity,
        requiredBytes: requiredBytes,
        perLayerCapacityBytes: perLayerCapacity,
        coverRequiredBytes: coverRequiredBytes,
        hiddenRequiredBytes: hiddenRequiredBytes,
        minimumPixels: 0,
        minimumCarrierBytes: carrierBytes.length,
        carrierLabel:
            '${_isoBmffCarrierLabel(isoBmff)} audio dual existing free-space LSB',
      );
    }
    final profile = _wavStegoProfile(carrierBytes, wav);
    final policySamples = _wavPolicySamples(carrierBytes, wav, profile);
    final coverCapacity = _wavSlotCapacity(
      profile,
      1,
      policySamples: policySamples,
    );
    final hiddenCapacity = _wavSlotCapacity(
      profile,
      0,
      policySamples: policySamples,
    );
    final capacity = coverCapacity + hiddenCapacity;
    final perLayerCapacity = math.min(coverCapacity, hiddenCapacity);
    final requiredBytes = math.max(coverRequiredBytes, hiddenRequiredBytes);
    if (perLayerCapacity <= 0) {
      throw const ToolboxSteganographyException('Audio carrier is too small.');
    }
    return ToolboxSteganographyCapacityCheck(
      dualLayer: true,
      mediaKind: ToolboxSteganographyMediaKind.audio,
      width: 0,
      height: 0,
      capacityBytes: capacity,
      requiredBytes: requiredBytes,
      perLayerCapacityBytes: perLayerCapacity,
      coverRequiredBytes: coverRequiredBytes,
      hiddenRequiredBytes: hiddenRequiredBytes,
      minimumPixels: _minimumDualWavSamples(requiredBytes),
      minimumCarrierBytes: _minimumDualWavCarrierBytes(wav, requiredBytes),
      carrierLabel:
          'WAV/PCM ${wav.bitsPerSample}-bit dual low-density randomized sample LSB',
    );
  }

  ToolboxSteganographyCapacityCheck _checkVideoCapacity({
    required Uint8List carrierBytes,
    required int requiredBytes,
  }) {
    final mp4 = _parseVideoCarrier(carrierBytes);
    final region = _largestWritableMp4FreeRegion(mp4);
    final capacity = _mp4FreeBoxBlockCapacity(region);
    if (capacity <= 0) {
      throw const ToolboxSteganographyException(
        _isoBmffFreePaddingRequiredMessage,
      );
    }
    return ToolboxSteganographyCapacityCheck(
      dualLayer: false,
      mediaKind: ToolboxSteganographyMediaKind.video,
      width: 0,
      height: 0,
      capacityBytes: capacity,
      requiredBytes: requiredBytes,
      minimumPixels: 0,
      minimumCarrierBytes: carrierBytes.length,
      carrierLabel:
          '${_isoBmffCarrierLabel(mp4)} video existing free-space LSB',
    );
  }

  ToolboxSteganographyCapacityCheck _checkDualVideoCapacity({
    required Uint8List carrierBytes,
    required int coverRequiredBytes,
    required int hiddenRequiredBytes,
  }) {
    final mp4 = _parseVideoCarrier(carrierBytes);
    final region = _largestWritableMp4FreeRegion(mp4);
    final policyPositions = _mp4FreePolicyPositions(
      carrierBytes,
      region,
      _mp4FreeCarrierDigest(
        carrierBytes,
        region,
        purpose: 'video-free-public-policy',
      ),
    );
    final coverCapacity = _mp4FreeBoxSlotCapacity(
      region,
      1,
      policyPositions: policyPositions,
    );
    final hiddenCapacity = _mp4FreeBoxSlotCapacity(
      region,
      0,
      policyPositions: policyPositions,
    );
    final capacity = coverCapacity + hiddenCapacity;
    final perLayerCapacity = math.min(coverCapacity, hiddenCapacity);
    final requiredBytes = math.max(coverRequiredBytes, hiddenRequiredBytes);
    if (perLayerCapacity <= 0) {
      throw const ToolboxSteganographyException(
        _isoBmffFreePaddingRequiredMessage,
      );
    }
    return ToolboxSteganographyCapacityCheck(
      dualLayer: true,
      mediaKind: ToolboxSteganographyMediaKind.video,
      width: 0,
      height: 0,
      capacityBytes: capacity,
      requiredBytes: requiredBytes,
      perLayerCapacityBytes: perLayerCapacity,
      coverRequiredBytes: coverRequiredBytes,
      hiddenRequiredBytes: hiddenRequiredBytes,
      minimumPixels: 0,
      minimumCarrierBytes: carrierBytes.length,
      carrierLabel:
          '${_isoBmffCarrierLabel(mp4)} video dual existing free-space LSB',
    );
  }

  int _estimatedBlockLength({
    required ToolboxSteganographyPayloadKind payloadKind,
    required int plainBytesLength,
    required ToolboxCryptoAlgorithm encryption,
    required ToolboxCryptoStrength strength,
    String? fileName,
    String? mediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
  }) {
    final cryptoEstimate = _cryptoService.estimateEnvelopeSize(
      plainBytes: plainBytesLength,
      algorithm: encryption,
      strength: strength,
      fileName: fileName,
      mediaType: mediaType,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final envelope = <String, Object?>{
      'version': 3,
      'payloadKind': payloadKind.id,
      'encoding': payloadKind == ToolboxSteganographyPayloadKind.text
          ? 'utf8'
          : 'bytes',
      'fileName': fileName,
      'mediaType': mediaType,
      'cryptoEnvelope': _placeholderBase64(cryptoEstimate.recommendedBytes),
    };
    final jsonBytes = utf8.encode(jsonEncode(envelope)).length;
    return _sealedBlockMagic.length + 4 + jsonBytes + _protectedBlockTailLength;
  }

  int _minimumSingleLayerPixels(int requiredBytes) {
    final requiredBits =
        (requiredBytes * 8) +
        ((_imageHeaderLength + _imagePolicyHeaderLength) * 8);
    return (requiredBits + 2) ~/ 3;
  }

  int _minimumDualLayerPixels(int requiredBytes) {
    final policyBits = _imagePolicyHeaderLength * 8;
    final requiredSlotBits =
        (requiredBytes * 8) +
        (_imageHeaderLength * 8) +
        ((policyBits + 1) ~/ 2);
    return ((requiredSlotBits * 2) + 2) ~/ 3;
  }

  String _placeholderBase64(int bytes) {
    return 'A' * (((bytes + 2) ~/ 3) * 4);
  }

  ToolboxSteganographyEmbedResult _embedInImage({
    required Uint8List carrierBytes,
    required Uint8List block,
    required _EnvelopeBuildResult envelope,
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
    required bool allowCarrierOverwrite,
  }) {
    final image = _decodeCarrierImage(
      carrierBytes,
      failureMessage:
          'Unsupported image format. Pick PNG/JPG/WebP/GIF style images.',
    );
    final totalPositions = image.width * image.height * 3;
    final reservedHeaderBytes = _imageHeaderLength + _imagePolicyHeaderLength;
    final capacity = (totalPositions - (reservedHeaderBytes * 8)) ~/ 8;
    if (capacity <= 0) {
      throw const ToolboxSteganographyException('Image is too small.');
    }
    if (block.length > capacity) {
      throw ToolboxSteganographyException(
        'Secret payload is too large for this image. Capacity: $capacity B, need: ${block.length} B.',
      );
    }
    _ensureImageWriteAllowed(
      image,
      credentials: <_ImageWriteCredential>[
        _ImageWriteCredential(
          passphrase: passphrase,
          keyFileBytes: keyFileBytes,
        ),
      ],
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      allowCarrierOverwrite: allowCarrierOverwrite,
    );

    final stegoImage = img.Image.from(image);
    _writeRandomizedLsbBlock(
      stegoImage,
      block,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      carrierProtectionMode: carrierProtectionMode,
    );
    final output = Uint8List.fromList(img.encodePng(stegoImage, level: 6));
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: 'png',
      payloadBytes: block.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail:
          '${image.width}x${image.height}, randomized LSB capacity ${_formatBytes(capacity)}',
      fingerprint: carrierFingerprint(output),
      capacityBytes: capacity,
    );
  }

  ToolboxSteganographyEmbedResult _embedDualTextInImage({
    required Uint8List carrierBytes,
    required Uint8List coverBlock,
    required Uint8List hiddenBlock,
    required _EnvelopeBuildResult hiddenEnvelope,
    required String coverPassphrase,
    required String hiddenPassphrase,
    required Uint8List? hiddenKeyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
    required bool allowCarrierOverwrite,
  }) {
    return _embedDualBlocksInImage(
      carrierBytes: carrierBytes,
      coverBlock: coverBlock,
      hiddenBlock: hiddenBlock,
      hiddenCipherPreview: hiddenEnvelope.cipherPreview,
      coverPassphrase: coverPassphrase,
      hiddenPassphrase: hiddenPassphrase,
      hiddenKeyFileBytes: hiddenKeyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      carrierProtectionMode: carrierProtectionMode,
      allowCarrierOverwrite: allowCarrierOverwrite,
    );
  }

  ToolboxSteganographyEmbedResult _embedDualBlocksInImage({
    required Uint8List carrierBytes,
    required Uint8List coverBlock,
    required Uint8List hiddenBlock,
    required String hiddenCipherPreview,
    required String coverPassphrase,
    required String hiddenPassphrase,
    required Uint8List? hiddenKeyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
    required bool allowCarrierOverwrite,
  }) {
    final image = _decodeCarrierImage(
      carrierBytes,
      failureMessage:
          'Unsupported image format. Pick PNG/JPG/WebP/GIF style images.',
    );
    final totalPositions = image.width * image.height * 3;
    final policyPositions = _imagePolicyPositions(
      image,
      headerLength: _imagePolicyHeaderLength,
    );
    final coverCapacity = _imageSlotCapacity(
      totalPositions: totalPositions,
      policyPositions: policyPositions,
      slot: 1,
    );
    final hiddenCapacity = _imageSlotCapacity(
      totalPositions: totalPositions,
      policyPositions: policyPositions,
      slot: 0,
    );
    if (coverBlock.length > coverCapacity ||
        hiddenBlock.length > hiddenCapacity) {
      throw ToolboxSteganographyException(
        'Secret payload is too large for this image. Capacity: ${math.min(coverCapacity, hiddenCapacity)} B per layer.',
      );
    }
    _ensureImageWriteAllowed(
      image,
      credentials: <_ImageWriteCredential>[
        _ImageWriteCredential(passphrase: coverPassphrase),
        _ImageWriteCredential(
          passphrase: hiddenPassphrase,
          keyFileBytes: hiddenKeyFileBytes,
        ),
      ],
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      allowCarrierOverwrite: allowCarrierOverwrite,
    );

    final locatorSalt = _randomLocatorSalt(carrierProtectionMode);
    final stegoImage = img.Image.from(image);
    _writeRandomizedLsbBlockInSlot(
      stegoImage,
      hiddenBlock,
      passphrase: hiddenPassphrase,
      keyFileBytes: hiddenKeyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      locatorSalt: locatorSalt,
      slot: 0,
      policyPositions: policyPositions,
    );
    _writeRandomizedLsbBlockInSlot(
      stegoImage,
      coverBlock,
      passphrase: coverPassphrase,
      keyFileBytes: null,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      locatorSalt: locatorSalt,
      slot: 1,
      policyPositions: policyPositions,
    );
    _writeImageLocatorHeader(
      stegoImage,
      locatorSalt: locatorSalt,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      carrierProtectionMode: carrierProtectionMode,
      positions: policyPositions,
    );
    final output = Uint8List.fromList(img.encodePng(stegoImage, level: 6));
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: 'png',
      payloadBytes: coverBlock.length + hiddenBlock.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: hiddenCipherPreview,
      carrierDetail:
          '${image.width}x${image.height}, dual-layer randomized LSB capacity ${_formatBytes(math.min(coverCapacity, hiddenCapacity))} per layer',
      fingerprint: carrierFingerprint(output),
      capacityBytes: coverCapacity + hiddenCapacity,
    );
  }

  ToolboxSteganographyEmbedResult _embedInAudio({
    required Uint8List carrierBytes,
    required Uint8List block,
    required _EnvelopeBuildResult envelope,
    String? sourceExtension,
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
    required bool allowCarrierOverwrite,
  }) {
    final carrier = _parseAudioCarrier(carrierBytes);
    final wav = carrier.wav;
    if (wav == null) {
      return _embedInIsoBmffCarrier(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: carrierBytes,
        block: block,
        cipherPreview: envelope.cipherPreview,
        sourceExtension: sourceExtension,
        defaultExtension: _defaultIsoBmffAudioExtension(carrier.isoBmff!),
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      );
    }
    final profile = _wavStegoProfile(carrierBytes, wav);
    final policySamples = _wavPolicySamples(carrierBytes, wav, profile);
    final capacity = _wavBlockCapacity(profile, policySamples: policySamples);
    if (block.length > capacity) {
      throw ToolboxSteganographyException(
        'Secret payload is too large for this audio. Capacity: $capacity B, need: ${block.length} B.',
      );
    }
    _ensureAudioWriteAllowed(
      carrierBytes,
      credentials: <_ImageWriteCredential>[
        _ImageWriteCredential(
          passphrase: passphrase,
          keyFileBytes: keyFileBytes,
        ),
      ],
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      allowCarrierOverwrite: allowCarrierOverwrite,
    );
    final output = Uint8List.fromList(carrierBytes);
    _writeRandomizedWavBlock(
      output,
      wav,
      profile,
      policySamples,
      block,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      carrierProtectionMode: carrierProtectionMode,
    );
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: cleanExtension(sourceExtension) ?? 'wav',
      payloadBytes: block.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail:
          'WAV/PCM ${wav.bitsPerSample}-bit low-density randomized sample LSB capacity ${_formatBytes(capacity)}',
      fingerprint: carrierFingerprint(output),
      capacityBytes: capacity,
    );
  }

  ToolboxSteganographyEmbedResult _embedDualBlocksInAudio({
    required Uint8List carrierBytes,
    required Uint8List coverBlock,
    required Uint8List hiddenBlock,
    required String hiddenCipherPreview,
    String? sourceExtension,
    required String coverPassphrase,
    required String hiddenPassphrase,
    required Uint8List? hiddenKeyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
    required bool allowCarrierOverwrite,
  }) {
    final carrier = _parseAudioCarrier(carrierBytes);
    final wav = carrier.wav;
    if (wav == null) {
      return _embedDualBlocksInIsoBmffCarrier(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: carrierBytes,
        coverBlock: coverBlock,
        hiddenBlock: hiddenBlock,
        hiddenCipherPreview: hiddenCipherPreview,
        sourceExtension: sourceExtension,
        defaultExtension: _defaultIsoBmffAudioExtension(carrier.isoBmff!),
        coverPassphrase: coverPassphrase,
        hiddenPassphrase: hiddenPassphrase,
        hiddenKeyFileBytes: hiddenKeyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
        allowCarrierOverwrite: allowCarrierOverwrite,
      );
    }
    final profile = _wavStegoProfile(carrierBytes, wav);
    final policySamples = _wavPolicySamples(carrierBytes, wav, profile);
    final coverCapacity = _wavSlotCapacity(
      profile,
      1,
      policySamples: policySamples,
    );
    final hiddenCapacity = _wavSlotCapacity(
      profile,
      0,
      policySamples: policySamples,
    );
    if (coverBlock.length > coverCapacity ||
        hiddenBlock.length > hiddenCapacity) {
      throw ToolboxSteganographyException(
        'Secret payload is too large for this audio. Capacity: ${math.min(coverCapacity, hiddenCapacity)} B per layer.',
      );
    }
    _ensureAudioWriteAllowed(
      carrierBytes,
      credentials: <_ImageWriteCredential>[
        _ImageWriteCredential(passphrase: coverPassphrase),
        _ImageWriteCredential(
          passphrase: hiddenPassphrase,
          keyFileBytes: hiddenKeyFileBytes,
        ),
      ],
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      allowCarrierOverwrite: allowCarrierOverwrite,
    );
    final locatorSalt = _randomMediaLocatorSalt(carrierProtectionMode);
    final output = Uint8List.fromList(carrierBytes);
    _writeRandomizedWavBlockInSlot(
      output,
      wav,
      profile,
      hiddenBlock,
      passphrase: hiddenPassphrase,
      keyFileBytes: hiddenKeyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      locatorSalt: locatorSalt,
      slot: 0,
      policySamples: policySamples,
    );
    _writeRandomizedWavBlockInSlot(
      output,
      wav,
      profile,
      coverBlock,
      passphrase: coverPassphrase,
      keyFileBytes: null,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      locatorSalt: locatorSalt,
      slot: 1,
      policySamples: policySamples,
    );
    _writeWavBytesAtSamples(
      output,
      wav,
      _buildMediaLocatorHeader(
        locatorSalt,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
      ),
      policySamples,
    );
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: cleanExtension(sourceExtension) ?? 'wav',
      payloadBytes: coverBlock.length + hiddenBlock.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: hiddenCipherPreview,
      carrierDetail:
          'WAV/PCM ${wav.bitsPerSample}-bit dual low-density randomized sample LSB capacity ${_formatBytes(math.min(coverCapacity, hiddenCapacity))} per layer',
      fingerprint: carrierFingerprint(output),
      capacityBytes: coverCapacity + hiddenCapacity,
    );
  }

  ToolboxSteganographyEmbedResult _embedInVideo({
    required Uint8List carrierBytes,
    required Uint8List block,
    required _EnvelopeBuildResult envelope,
    String? sourceExtension,
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
    required bool allowCarrierOverwrite,
  }) {
    return _embedInIsoBmffCarrier(
      mediaKind: ToolboxSteganographyMediaKind.video,
      carrierBytes: carrierBytes,
      block: block,
      cipherPreview: envelope.cipherPreview,
      sourceExtension: sourceExtension,
      defaultExtension: _defaultIsoBmffVideoExtension(carrierBytes),
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      carrierProtectionMode: carrierProtectionMode,
      allowCarrierOverwrite: allowCarrierOverwrite,
    );
  }

  ToolboxSteganographyEmbedResult _embedInIsoBmffCarrier({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required Uint8List block,
    required String cipherPreview,
    String? sourceExtension,
    required String defaultExtension,
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
    required bool allowCarrierOverwrite,
  }) {
    final mp4 = mediaKind == ToolboxSteganographyMediaKind.audio
        ? _parseIsoBmffCarrier(
            carrierBytes,
            unsupportedMessage: _unsupportedAudioFormatMessage,
          )
        : _parseVideoCarrier(carrierBytes);
    final region = _largestWritableMp4FreeRegion(mp4);
    final capacity = _mp4FreeBoxBlockCapacity(region);
    if (block.length > capacity) {
      throw ToolboxSteganographyException(
        'Secret payload is too large for this ${mediaKind == ToolboxSteganographyMediaKind.audio ? 'audio' : 'video'}. Capacity: $capacity B, need: ${block.length} B.',
      );
    }
    if (mediaKind == ToolboxSteganographyMediaKind.audio) {
      _ensureAudioWriteAllowed(
        carrierBytes,
        credentials: <_ImageWriteCredential>[
          _ImageWriteCredential(
            passphrase: passphrase,
            keyFileBytes: keyFileBytes,
          ),
        ],
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        allowCarrierOverwrite: allowCarrierOverwrite,
      );
    } else {
      _ensureVideoWriteAllowed(
        carrierBytes,
        credentials: <_ImageWriteCredential>[
          _ImageWriteCredential(
            passphrase: passphrase,
            keyFileBytes: keyFileBytes,
          ),
        ],
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        allowCarrierOverwrite: allowCarrierOverwrite,
      );
    }
    final output = Uint8List.fromList(carrierBytes);
    _writeRandomizedMp4FreeBoxBlock(
      output,
      region,
      block: block,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      carrierProtectionMode: carrierProtectionMode,
    );
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: cleanExtension(sourceExtension) ?? defaultExtension,
      payloadBytes: block.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: cipherPreview,
      carrierDetail:
          '${_isoBmffCarrierLabel(mp4)} ${mediaKind == ToolboxSteganographyMediaKind.audio ? 'audio' : 'video'} existing free-space LSB capacity ${_formatBytes(capacity)}',
      fingerprint: carrierFingerprint(output),
      capacityBytes: capacity,
    );
  }

  ToolboxSteganographyEmbedResult _embedDualBlocksInVideo({
    required Uint8List carrierBytes,
    required Uint8List coverBlock,
    required Uint8List hiddenBlock,
    required String hiddenCipherPreview,
    String? sourceExtension,
    required String coverPassphrase,
    required String hiddenPassphrase,
    required Uint8List? hiddenKeyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
    required bool allowCarrierOverwrite,
  }) {
    return _embedDualBlocksInIsoBmffCarrier(
      mediaKind: ToolboxSteganographyMediaKind.video,
      carrierBytes: carrierBytes,
      coverBlock: coverBlock,
      hiddenBlock: hiddenBlock,
      hiddenCipherPreview: hiddenCipherPreview,
      sourceExtension: sourceExtension,
      defaultExtension: _defaultIsoBmffVideoExtension(carrierBytes),
      coverPassphrase: coverPassphrase,
      hiddenPassphrase: hiddenPassphrase,
      hiddenKeyFileBytes: hiddenKeyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      carrierProtectionMode: carrierProtectionMode,
      allowCarrierOverwrite: allowCarrierOverwrite,
    );
  }

  ToolboxSteganographyEmbedResult _embedDualBlocksInIsoBmffCarrier({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required Uint8List coverBlock,
    required Uint8List hiddenBlock,
    required String hiddenCipherPreview,
    String? sourceExtension,
    required String defaultExtension,
    required String coverPassphrase,
    required String hiddenPassphrase,
    required Uint8List? hiddenKeyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
    required bool allowCarrierOverwrite,
  }) {
    final mp4 = mediaKind == ToolboxSteganographyMediaKind.audio
        ? _parseIsoBmffCarrier(
            carrierBytes,
            unsupportedMessage: _unsupportedAudioFormatMessage,
          )
        : _parseVideoCarrier(carrierBytes);
    final region = _largestWritableMp4FreeRegion(mp4);
    final policyDigest = _mp4FreeCarrierDigest(
      carrierBytes,
      region,
      purpose: 'video-free-public-policy',
    );
    final policyPositions = _mp4FreePolicyPositions(
      carrierBytes,
      region,
      policyDigest,
    );
    final coverCapacity = _mp4FreeBoxSlotCapacity(
      region,
      1,
      policyPositions: policyPositions,
    );
    final hiddenCapacity = _mp4FreeBoxSlotCapacity(
      region,
      0,
      policyPositions: policyPositions,
    );
    if (coverBlock.length > coverCapacity ||
        hiddenBlock.length > hiddenCapacity) {
      throw ToolboxSteganographyException(
        'Secret payload is too large for this ${mediaKind == ToolboxSteganographyMediaKind.audio ? 'audio' : 'video'}. Capacity: ${math.min(coverCapacity, hiddenCapacity)} B per layer.',
      );
    }
    final credentials = <_ImageWriteCredential>[
      _ImageWriteCredential(passphrase: coverPassphrase),
      _ImageWriteCredential(
        passphrase: hiddenPassphrase,
        keyFileBytes: hiddenKeyFileBytes,
      ),
    ];
    if (mediaKind == ToolboxSteganographyMediaKind.audio) {
      _ensureAudioWriteAllowed(
        carrierBytes,
        credentials: credentials,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        allowCarrierOverwrite: allowCarrierOverwrite,
      );
    } else {
      _ensureVideoWriteAllowed(
        carrierBytes,
        credentials: credentials,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        allowCarrierOverwrite: allowCarrierOverwrite,
      );
    }
    final locatorSalt = _randomMediaLocatorSalt(carrierProtectionMode);
    final output = Uint8List.fromList(carrierBytes);
    _writeRandomizedMp4FreeBoxBlockInSlot(
      output,
      region,
      hiddenBlock,
      passphrase: hiddenPassphrase,
      keyFileBytes: hiddenKeyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      locatorSalt: locatorSalt,
      slot: 0,
      policyPositions: policyPositions,
    );
    _writeRandomizedMp4FreeBoxBlockInSlot(
      output,
      region,
      coverBlock,
      passphrase: coverPassphrase,
      keyFileBytes: null,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      locatorSalt: locatorSalt,
      slot: 1,
      policyPositions: policyPositions,
    );
    _writeLsbBytesAtByteOffsets(
      output,
      _buildMediaLocatorHeader(
        locatorSalt,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
      ),
      _absoluteMp4FreeOffsets(region, policyPositions),
    );
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: cleanExtension(sourceExtension) ?? defaultExtension,
      payloadBytes: coverBlock.length + hiddenBlock.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: hiddenCipherPreview,
      carrierDetail:
          '${_isoBmffCarrierLabel(mp4)} ${mediaKind == ToolboxSteganographyMediaKind.audio ? 'audio' : 'video'} dual existing free-space LSB capacity ${_formatBytes(math.min(coverCapacity, hiddenCapacity))} per layer',
      fingerprint: carrierFingerprint(output),
      capacityBytes: coverCapacity + hiddenCapacity,
    );
  }

  Uint8List _extractImageBlock(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final image = _decodeCarrierImage(
      carrierBytes,
      failureMessage: 'Unsupported image format or no hidden payload found.',
    );
    return _readRandomizedLsbBlock(
      image,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    );
  }

  Uint8List _extractAudioBlock(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final carrier = _parseAudioCarrier(carrierBytes);
    return _readAnyAudioBlockDetails(
      carrierBytes: carrierBytes,
      carrier: carrier,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    ).block;
  }

  Uint8List _extractVideoBlock(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    return _readAnyIsoBmffFreeBoxBlockDetails(
      carrierBytes: carrierBytes,
      carrier: _parseVideoCarrier(carrierBytes),
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    ).block;
  }

  ToolboxSteganographySanitizeResult _stripImagePayload(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final image = _decodeCarrierImage(
      carrierBytes,
      failureMessage: 'Unsupported image format or no hidden payload found.',
    );
    final stegoImage = img.Image.from(image);
    var removed = false;
    try {
      removed = _clearRandomizedLsbBlock(
        stegoImage,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      );
    } on ToolboxSteganographyException {
      removed = false;
    }
    if (!removed) {
      return ToolboxSteganographySanitizeResult(
        bytes: Uint8List.fromList(carrierBytes),
        outputExtension: 'png',
        removed: false,
      );
    }
    return ToolboxSteganographySanitizeResult(
      bytes: Uint8List.fromList(img.encodePng(stegoImage, level: 6)),
      outputExtension: 'png',
      removed: true,
    );
  }

  ToolboxSteganographySanitizeResult _stripAudioPayload(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final carrier = _parseAudioCarrier(carrierBytes);
    final wav = carrier.wav;
    if (wav == null) {
      final output = Uint8List.fromList(carrierBytes);
      final removed = _clearIsoBmffPayload(
        output,
        carrier.isoBmff!,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      );
      return ToolboxSteganographySanitizeResult(
        bytes: output,
        outputExtension: _defaultIsoBmffAudioExtension(carrier.isoBmff!),
        removed: removed,
      );
    }
    final output = Uint8List.fromList(carrierBytes);
    var removed = false;
    try {
      final read = _readAnyRandomizedWavBlockDetails(
        output,
        wav,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      );
      final clearSamples = <int>{
        ...read.policySamples,
        ...read.headerSamples,
        ...read.payloadSamples,
      };
      for (final sample in clearSamples) {
        _setWavLsbAtSample(output, wav, sample, 0);
      }
      removed = true;
    } on ToolboxSteganographyException {
      removed = false;
    }
    return ToolboxSteganographySanitizeResult(
      bytes: output,
      outputExtension: 'wav',
      removed: removed,
    );
  }

  ToolboxSteganographySanitizeResult _stripVideoPayload(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final isoBmff = _parseVideoCarrier(carrierBytes);
    final output = Uint8List.fromList(carrierBytes);
    final removed = _clearIsoBmffPayload(
      output,
      isoBmff,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    );
    return ToolboxSteganographySanitizeResult(
      bytes: output,
      outputExtension: _defaultIsoBmffVideoExtension(carrierBytes),
      removed: removed,
    );
  }

  bool _clearIsoBmffPayload(
    Uint8List output,
    _Mp4CarrierInfo isoBmff, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    try {
      final read = _readAnyIsoBmffFreeBoxBlockDetails(
        carrierBytes: output,
        carrier: isoBmff,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      );
      final clearOffsets = <int>{
        ...read.policyOffsets,
        ...read.headerOffsets,
        ...read.payloadOffsets,
      };
      for (final offset in clearOffsets) {
        output[offset] &= 0xfe;
      }
      return true;
    } on ToolboxSteganographyException {
      return false;
    }
  }

  _WavCarrierInfo _parseWavCarrier(Uint8List carrierBytes) {
    _validateTailCarrierSize(carrierBytes);
    if (carrierBytes.length < 44 ||
        !_rangeEquals(carrierBytes, 0, _riffMagic) ||
        !_rangeEquals(carrierBytes, 8, _waveMagic)) {
      throw const ToolboxSteganographyException(_unsupportedAudioFormatMessage);
    }

    int? audioFormat;
    int? channels;
    int? blockAlign;
    int? bitsPerSample;
    int? dataOffset;
    int? dataLength;
    var offset = 12;
    while (offset + 8 <= carrierBytes.length) {
      final chunkSize = _readUint32Little(carrierBytes, offset + 4);
      final chunkDataOffset = offset + 8;
      final nextOffset =
          chunkDataOffset + chunkSize + (chunkSize.isOdd ? 1 : 0);
      if (chunkSize < 0 || chunkDataOffset + chunkSize > carrierBytes.length) {
        throw const ToolboxSteganographyException(
          'Audio carrier is damaged or incomplete.',
        );
      }
      if (_rangeEquals(carrierBytes, offset, _wavFmtMagic)) {
        if (chunkSize < 16) {
          throw const ToolboxSteganographyException(
            'Audio carrier is damaged or incomplete.',
          );
        }
        audioFormat = _readUint16Little(carrierBytes, chunkDataOffset);
        channels = _readUint16Little(carrierBytes, chunkDataOffset + 2);
        blockAlign = _readUint16Little(carrierBytes, chunkDataOffset + 12);
        bitsPerSample = _readUint16Little(carrierBytes, chunkDataOffset + 14);
      } else if (_rangeEquals(carrierBytes, offset, _wavDataMagic)) {
        dataOffset ??= chunkDataOffset;
        dataLength ??= chunkSize;
      }
      offset = nextOffset;
    }

    if (audioFormat != 1 ||
        channels == null ||
        channels <= 0 ||
        blockAlign == null ||
        blockAlign <= 0 ||
        bitsPerSample == null ||
        bitsPerSample % 8 != 0 ||
        !<int>{8, 16, 24, 32}.contains(bitsPerSample) ||
        dataOffset == null ||
        dataLength == null ||
        dataLength <= 0) {
      throw const ToolboxSteganographyException(_unsupportedAudioFormatMessage);
    }
    final bytesPerSample = bitsPerSample ~/ 8;
    if (dataLength < bytesPerSample) {
      throw const ToolboxSteganographyException('Audio carrier is too small.');
    }
    return _WavCarrierInfo(
      dataOffset: dataOffset,
      dataLength: dataLength,
      channels: channels,
      blockAlign: blockAlign,
      bitsPerSample: bitsPerSample,
      bytesPerSample: bytesPerSample,
      sampleCount: dataLength ~/ bytesPerSample,
    );
  }

  _AudioCarrierInfo _parseAudioCarrier(Uint8List carrierBytes) {
    _validateTailCarrierSize(carrierBytes);
    if (_looksLikeWav(carrierBytes)) {
      return _AudioCarrierInfo.wav(_parseWavCarrier(carrierBytes));
    }
    if (_looksLikeIsoBmff(carrierBytes)) {
      return _AudioCarrierInfo.isoBmff(
        _parseIsoBmffCarrier(
          carrierBytes,
          unsupportedMessage: _unsupportedAudioFormatMessage,
        ),
      );
    }
    if (_looksLikeCompressedAudio(carrierBytes)) {
      throw const ToolboxSteganographyException(
        _unsupportedCompressedAudioMessage,
      );
    }
    throw const ToolboxSteganographyException(_unsupportedAudioFormatMessage);
  }

  _AudioBlockReadResult _readAnyAudioBlockDetails({
    required Uint8List carrierBytes,
    required _AudioCarrierInfo carrier,
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final wav = carrier.wav;
    if (wav != null) {
      return _readAnyRandomizedWavBlockDetails(
        carrierBytes,
        wav,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      );
    }
    final videoRead = _readAnyIsoBmffFreeBoxBlockDetails(
      carrierBytes: carrierBytes,
      carrier: carrier.isoBmff!,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    );
    return _AudioBlockReadResult(
      block: videoRead.block,
      headerSamples: videoRead.headerOffsets,
      payloadSamples: videoRead.payloadOffsets,
      policySamples: videoRead.policyOffsets,
      slot: videoRead.slot,
    );
  }

  _Mp4CarrierInfo _parseVideoCarrier(Uint8List carrierBytes) {
    _validateTailCarrierSize(carrierBytes);
    if (_looksLikeIsoBmff(carrierBytes)) {
      return _parseIsoBmffCarrier(
        carrierBytes,
        unsupportedMessage: _unsupportedVideoFormatMessage,
      );
    }
    if (_looksLikeComplexVideoContainer(carrierBytes)) {
      throw const ToolboxSteganographyException(
        _unsupportedComplexVideoMessage,
      );
    }
    throw const ToolboxSteganographyException(_unsupportedVideoFormatMessage);
  }

  bool _looksLikeWav(Uint8List bytes) {
    return bytes.length >= 12 &&
        _rangeEquals(bytes, 0, _riffMagic) &&
        _rangeEquals(bytes, 8, _waveMagic);
  }

  bool _looksLikeIsoBmff(Uint8List bytes) {
    if (bytes.length < 12) {
      return false;
    }
    final size = _readUint32(bytes, 0);
    return size >= 8 &&
        size <= bytes.length &&
        _asciiBoxString(bytes, 4, 8) == 'ftyp';
  }

  bool _looksLikeCompressedAudio(Uint8List bytes) {
    if (_startsWith(bytes, _id3Magic) ||
        _startsWith(bytes, _flacMagic) ||
        _startsWith(bytes, _oggMagic) ||
        _startsWith(bytes, _amrMagic)) {
      return true;
    }
    if (bytes.length >= 2) {
      final first = bytes[0];
      final second = bytes[1];
      final mp3FrameSync = first == 0xff && (second & 0xe0) == 0xe0;
      final aacAdtsSync = first == 0xff && (second & 0xf6) == 0xf0;
      if (mp3FrameSync || aacAdtsSync) {
        return true;
      }
    }
    return _looksLikeAsf(bytes) || _looksLikeAiff(bytes);
  }

  bool _looksLikeComplexVideoContainer(Uint8List bytes) {
    return _looksLikeMatroska(bytes) ||
        _looksLikeAsf(bytes) ||
        _looksLikeAvi(bytes) ||
        _startsWith(bytes, _flvMagic);
  }

  bool _looksLikeAvi(Uint8List bytes) {
    return bytes.length >= 12 &&
        _rangeEquals(bytes, 0, _riffMagic) &&
        _rangeEquals(bytes, 8, _aviMagic);
  }

  bool _looksLikeAiff(Uint8List bytes) {
    return bytes.length >= 12 &&
        _asciiBoxString(bytes, 0, 4) == 'FORM' &&
        <String>{'AIFF', 'AIFC'}.contains(_asciiBoxString(bytes, 8, 12));
  }

  bool _looksLikeMatroska(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x1a &&
        bytes[1] == 0x45 &&
        bytes[2] == 0xdf &&
        bytes[3] == 0xa3;
  }

  bool _looksLikeAsf(Uint8List bytes) {
    const asfGuid = <int>[
      0x30,
      0x26,
      0xb2,
      0x75,
      0x8e,
      0x66,
      0xcf,
      0x11,
      0xa6,
      0xd9,
      0x00,
      0xaa,
      0x00,
      0x62,
      0xce,
      0x6c,
    ];
    return _rangeEquals(bytes, 0, asfGuid);
  }

  String _isoBmffCarrierLabel(_Mp4CarrierInfo carrier) {
    final majorBrand = carrier.majorBrand;
    if (majorBrand == null || majorBrand.isEmpty) {
      return 'ISO BMFF';
    }
    return 'ISO BMFF $majorBrand';
  }

  String _defaultIsoBmffAudioExtension(_Mp4CarrierInfo carrier) {
    final majorBrand = carrier.majorBrand?.trim().toLowerCase();
    if (majorBrand == 'm4a' || majorBrand == 'm4b') {
      return majorBrand!;
    }
    if (majorBrand != null && majorBrand.startsWith('3gp')) {
      return '3gp';
    }
    return 'm4a';
  }

  String _defaultIsoBmffVideoExtension(Uint8List carrierBytes) {
    try {
      final carrier = _parseIsoBmffCarrier(
        carrierBytes,
        unsupportedMessage: _unsupportedVideoFormatMessage,
      );
      final majorBrand = carrier.majorBrand?.trim().toLowerCase();
      if (majorBrand == 'm4v') {
        return 'm4v';
      }
      if (majorBrand != null && majorBrand.startsWith('3gp')) {
        return '3gp';
      }
      if (majorBrand != null && majorBrand.startsWith('3g2')) {
        return '3g2';
      }
      if (majorBrand == 'heic' || majorBrand == 'heif') {
        return majorBrand!;
      }
    } on ToolboxSteganographyException {
      return 'mp4';
    }
    return 'mp4';
  }

  _WavStegoProfile _wavStegoProfile(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
  ) {
    var usable = 0;
    var evenUsable = 0;
    for (var sample = 0; sample < wav.sampleCount; sample += 1) {
      if (_isWavStegoSample(carrierBytes, wav, sample)) {
        usable += 1;
        if (sample.isEven) {
          evenUsable += 1;
        }
      }
    }
    if (usable < (_mediaPolicyHeaderLength + _mediaHeaderLength) * 8) {
      throw const ToolboxSteganographyException(
        'Audio carrier needs more non-silent PCM samples.',
      );
    }
    return _WavStegoProfile(
      usableSamples: usable,
      evenUsableSamples: evenUsable,
      oddUsableSamples: usable - evenUsable,
    );
  }

  bool _isWavStegoSample(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
    int sample,
  ) {
    final offset = wav.dataOffset + (sample * wav.bytesPerSample);
    if (sample < 0 ||
        offset < wav.dataOffset ||
        offset >= carrierBytes.length) {
      return false;
    }
    final magnitude = _wavSampleMagnitudeWithLsbCleared(
      carrierBytes,
      offset,
      wav.bitsPerSample,
      wav.bytesPerSample,
    );
    final maxMagnitude = wav.bitsPerSample == 8
        ? 128
        : 1 << (wav.bitsPerSample - 1);
    final quietFloor = math.max(4, maxMagnitude ~/ 128);
    final clipGuard = math.max(4, maxMagnitude ~/ 256);
    return magnitude >= quietFloor && magnitude <= maxMagnitude - clipGuard;
  }

  int _wavSampleMagnitudeWithLsbCleared(
    Uint8List bytes,
    int offset,
    int bitsPerSample,
    int bytesPerSample,
  ) {
    if (bitsPerSample == 8) {
      return ((bytes[offset] & 0xfe) - 128).abs();
    }
    var value = 0;
    for (var index = 0; index < bytesPerSample; index += 1) {
      final byte = index == 0 ? bytes[offset] & 0xfe : bytes[offset + index];
      value |= byte << (8 * index);
    }
    final signBit = 1 << (bitsPerSample - 1);
    final fullRange = 1 << bitsPerSample;
    if ((value & signBit) != 0) {
      value -= fullRange;
    }
    return value.abs();
  }

  List<int> _selectWavStegoSamples({
    required Uint8List carrierBytes,
    required _WavCarrierInfo wav,
    required int count,
    required Uint8List seed,
    int? slot,
    Set<int>? excluded,
  }) {
    final unavailable = excluded == null ? <int>{} : Set<int>.from(excluded);
    final rng = _HmacSha256Csprng(seed);
    final samples = <int>[];
    final maxAttempts = math.max(1024, count * 32);
    var attempts = 0;
    bool accepts(int sample) {
      if (slot != null && sample.isEven != (slot == 0)) {
        return false;
      }
      return _isWavStegoSample(carrierBytes, wav, sample);
    }

    while (samples.length < count && attempts < maxAttempts) {
      attempts += 1;
      final candidate = rng.nextInt(wav.sampleCount);
      if (unavailable.contains(candidate) || !accepts(candidate)) {
        continue;
      }
      unavailable.add(candidate);
      samples.add(candidate);
    }
    if (samples.length == count) {
      return samples;
    }

    final remaining = <int>[];
    for (var sample = 0; sample < wav.sampleCount; sample += 1) {
      if (!unavailable.contains(sample) && accepts(sample)) {
        remaining.add(sample);
      }
    }
    for (var index = remaining.length - 1; index > 0; index -= 1) {
      final swapIndex = rng.nextInt(index + 1);
      final temp = remaining[index];
      remaining[index] = remaining[swapIndex];
      remaining[swapIndex] = temp;
    }
    samples.addAll(remaining.take(count - samples.length));
    if (samples.length != count) {
      throw const ToolboxSteganographyException(
        'Hidden audio payload is damaged or incomplete.',
      );
    }
    return samples;
  }

  int _wavBlockCapacity(
    _WavStegoProfile profile, {
    required List<int> policySamples,
  }) {
    final budget = _densityLimitedPositionBudget(
      profile.usableSamples,
      _wavMaxStegoSampleRatio,
    );
    return (budget - policySamples.length - (_mediaHeaderLength * 8)) ~/ 8;
  }

  int _minimumWavSamples(int requiredBytes) {
    final requiredPositions =
        (requiredBytes * 8) +
        ((_mediaPolicyHeaderLength + _mediaHeaderLength) * 8);
    return (requiredPositions / _wavMaxStegoSampleRatio).ceil();
  }

  int _minimumWavCarrierBytes(_WavCarrierInfo wav, int requiredBytes) {
    return wav.dataOffset +
        (_minimumWavSamples(requiredBytes) * wav.bytesPerSample);
  }

  int _wavSlotCapacity(
    _WavStegoProfile profile,
    int slot, {
    required List<int> policySamples,
  }) {
    final slotBudget = _densityLimitedPositionBudget(
      profile.usableSamplesForSlot(slot),
      _wavMaxStegoSampleRatio,
    );
    final reservedPolicy = policySamples
        .where((sample) => sample.isEven == (slot == 0))
        .length;
    return (slotBudget - reservedPolicy - (_mediaHeaderLength * 8)) ~/ 8;
  }

  int _minimumDualWavSamples(int requiredBytes) {
    final policyBits = _mediaPolicyHeaderLength * 8;
    final requiredSlotBits =
        (requiredBytes * 8) +
        (_mediaHeaderLength * 8) +
        ((policyBits + 1) ~/ 2);
    return ((requiredSlotBits / _wavMaxStegoSampleRatio).ceil()) * 2;
  }

  int _minimumDualWavCarrierBytes(_WavCarrierInfo wav, int requiredBytes) {
    return wav.dataOffset +
        (_minimumDualWavSamples(requiredBytes) * wav.bytesPerSample);
  }

  int _densityLimitedPositionBudget(int positions, double ratio) {
    if (positions <= 0) {
      return 0;
    }
    return math.max(0, (positions * ratio).floor());
  }

  void _writeRandomizedWavBlock(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
    _WavStegoProfile profile,
    List<int> policySamples,
    Uint8List block, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
  }) {
    final locatorSalt = _randomMediaLocatorSalt(carrierProtectionMode);
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
      salt: locatorSalt,
    );
    final carrierDigest = _wavCarrierDigest(carrierBytes, wav);
    final nonce = _randomBytes(_mediaNonceLength);
    final usedPositions =
        policySamples.length + (_mediaHeaderLength * 8) + (block.length * 8);
    final budget = _densityLimitedPositionBudget(
      profile.usableSamples,
      _wavMaxStegoSampleRatio,
    );
    if (usedPositions > budget) {
      throw const ToolboxSteganographyException('Payload is too large.');
    }
    final header = _buildMediaHeader(
      locatorSecret: locatorSecret,
      nonce: nonce,
      payloadLength: block.length,
      carrierDigest: carrierDigest,
      purpose: 'audio',
    );
    final headerSamples = _selectWavStegoSamples(
      carrierBytes: carrierBytes,
      wav: wav,
      count: header.length * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: 'audio-header',
        carrierDigest: carrierDigest,
      ),
      excluded: Set<int>.from(policySamples),
    );
    final payloadSamples = _selectWavStegoSamples(
      carrierBytes: carrierBytes,
      wav: wav,
      count: block.length * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: 'audio-payload',
        carrierDigest: carrierDigest,
        nonce: nonce,
      ),
      excluded: <int>{...policySamples, ...headerSamples},
    );
    _writeWavBytesAtSamples(carrierBytes, wav, header, headerSamples);
    _writeWavBytesAtSamples(carrierBytes, wav, block, payloadSamples);
    _writeWavBytesAtSamples(
      carrierBytes,
      wav,
      _buildMediaLocatorHeader(
        locatorSalt,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
      ),
      policySamples,
    );
  }

  void _writeRandomizedWavBlockInSlot(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
    _WavStegoProfile profile,
    Uint8List block, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required Uint8List locatorSalt,
    required int slot,
    required List<int> policySamples,
  }) {
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
      salt: locatorSalt,
    );
    final carrierDigest = _wavCarrierDigest(carrierBytes, wav);
    final nonce = _randomBytes(_mediaNonceLength);
    final reservedPolicy = policySamples
        .where((sample) => sample.isEven == (slot == 0))
        .length;
    final usedPositions =
        reservedPolicy + (_mediaHeaderLength * 8) + (block.length * 8);
    final budget = _densityLimitedPositionBudget(
      profile.usableSamplesForSlot(slot),
      _wavMaxStegoSampleRatio,
    );
    if (usedPositions > budget) {
      throw const ToolboxSteganographyException('Payload is too large.');
    }
    final header = _buildMediaHeader(
      locatorSecret: locatorSecret,
      nonce: nonce,
      payloadLength: block.length,
      carrierDigest: carrierDigest,
      purpose: 'audio-slot-$slot',
    );
    final headerSamples = _selectWavStegoSamples(
      carrierBytes: carrierBytes,
      wav: wav,
      count: header.length * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: 'audio-header-slot-$slot',
        carrierDigest: carrierDigest,
      ),
      slot: slot,
      excluded: Set<int>.from(policySamples),
    );
    final payloadSamples = _selectWavStegoSamples(
      carrierBytes: carrierBytes,
      wav: wav,
      count: block.length * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: 'audio-payload-slot-$slot',
        carrierDigest: carrierDigest,
        nonce: nonce,
      ),
      slot: slot,
      excluded: <int>{...policySamples, ...headerSamples},
    );
    _writeWavBytesAtSamples(carrierBytes, wav, header, headerSamples);
    _writeWavBytesAtSamples(carrierBytes, wav, block, payloadSamples);
  }

  List<int> _wavPolicySamples(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
    _WavStegoProfile profile,
  ) {
    if (profile.usableSamples < _mediaPolicyHeaderLength * 8) {
      throw const ToolboxSteganographyException('Audio carrier is too small.');
    }
    return _selectWavStegoSamples(
      carrierBytes: carrierBytes,
      wav: wav,
      count: _mediaPolicyHeaderLength * 8,
      seed: _wavCarrierDigest(
        carrierBytes,
        wav,
        purpose: 'audio-public-policy',
      ),
    );
  }

  void _writeWavBytesAtSamples(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
    Uint8List bytes,
    List<int> samples,
  ) {
    final totalBits = bytes.length * 8;
    if (samples.length < totalBits) {
      throw const ToolboxSteganographyException(
        'Hidden payload is damaged or incomplete.',
      );
    }
    for (var bitIndex = 0; bitIndex < totalBits; bitIndex += 1) {
      _setWavLsbAtSample(
        carrierBytes,
        wav,
        samples[bitIndex],
        _bitAt(bytes, bitIndex),
      );
    }
  }

  _AudioBlockReadResult _readAnyRandomizedWavBlockDetails(
    Uint8List carrierBytes,
    _WavCarrierInfo wav, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final errors = <Object>[];
    final profile = _wavStegoProfile(carrierBytes, wav);
    final policySamples = _wavPolicySamples(carrierBytes, wav, profile);
    final policyHeader = _readWavBytesAtSamples(
      carrierBytes,
      wav,
      byteCount: _mediaPolicyHeaderLength,
      samples: policySamples,
    );
    final candidates = _mediaLocatorReadCandidates(
      policyHeader,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    );
    for (final candidate in candidates) {
      final locatorSecret = _locatorSecret(
        passphrase,
        keyFileBytes,
        algorithm: candidate.algorithm,
        strength: candidate.strength,
        salt: candidate.salt,
      );
      for (final slot in <int?>[null, 0, 1]) {
        try {
          return _readRandomizedWavBlockWithPolicyReservation(
            carrierBytes,
            wav,
            profile,
            locatorSecret: locatorSecret,
            slot: slot,
            policySamples: policySamples,
          );
        } on Object catch (error) {
          errors.add(error);
        }
      }
    }
    final last = errors.isEmpty ? null : errors.last;
    if (last is ToolboxSteganographyException) {
      throw last;
    }
    throw const ToolboxSteganographyException('No hidden audio payload found.');
  }

  _AudioBlockReadResult _readRandomizedWavBlockWithPolicyReservation(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
    _WavStegoProfile profile, {
    required Uint8List locatorSecret,
    required int? slot,
    required List<int> policySamples,
  }) {
    final carrierDigest = _wavCarrierDigest(carrierBytes, wav);
    final purpose = slot == null ? 'audio' : 'audio-slot-$slot';
    final headerSamples = _selectWavStegoSamples(
      carrierBytes: carrierBytes,
      wav: wav,
      count: _mediaHeaderLength * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: slot == null ? 'audio-header' : 'audio-header-slot-$slot',
        carrierDigest: carrierDigest,
      ),
      slot: slot,
      excluded: Set<int>.from(policySamples),
    );
    final header = _readWavBytesAtSamples(
      carrierBytes,
      wav,
      byteCount: _mediaHeaderLength,
      samples: headerSamples,
    );
    final nonce = Uint8List.fromList(
      header.sublist(_mediaMagicLength, _mediaMagicLength + _mediaNonceLength),
    );
    final expectedMagic = _mediaMagic(
      locatorSecret: locatorSecret,
      nonce: nonce,
      carrierDigest: carrierDigest,
      purpose: purpose,
    );
    if (!_bytesEqual(header.sublist(0, _mediaMagicLength), expectedMagic)) {
      throw const ToolboxSteganographyException(
        'No hidden audio payload found.',
      );
    }
    final maskedLength = _readUint32(
      header,
      _mediaMagicLength + _mediaNonceLength,
    );
    final payloadLength =
        maskedLength ^
        _mediaLengthMask(
          locatorSecret: locatorSecret,
          nonce: nonce,
          carrierDigest: carrierDigest,
          purpose: purpose,
        );
    final capacity = slot == null
        ? _wavBlockCapacity(profile, policySamples: policySamples)
        : _wavSlotCapacity(profile, slot, policySamples: policySamples);
    if (payloadLength <= 0 || payloadLength > capacity) {
      throw const ToolboxSteganographyException(
        'Hidden audio payload is damaged or incomplete.',
      );
    }
    final payloadSamples = _selectWavStegoSamples(
      carrierBytes: carrierBytes,
      wav: wav,
      count: payloadLength * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: slot == null ? 'audio-payload' : 'audio-payload-slot-$slot',
        carrierDigest: carrierDigest,
        nonce: nonce,
      ),
      slot: slot,
      excluded: <int>{...policySamples, ...headerSamples},
    );
    return _AudioBlockReadResult(
      block: _readWavBytesAtSamples(
        carrierBytes,
        wav,
        byteCount: payloadLength,
        samples: payloadSamples,
      ),
      headerSamples: headerSamples,
      payloadSamples: payloadSamples,
      policySamples: policySamples,
      slot: slot,
    );
  }

  Uint8List _readWavBytesAtSamples(
    Uint8List carrierBytes,
    _WavCarrierInfo wav, {
    required int byteCount,
    required List<int> samples,
  }) {
    final totalBits = byteCount * 8;
    if (samples.length < totalBits) {
      throw const ToolboxSteganographyException(
        'Hidden audio payload is incomplete.',
      );
    }
    final output = Uint8List(byteCount);
    for (var bitIndex = 0; bitIndex < totalBits; bitIndex += 1) {
      output[bitIndex >> 3] |=
          _wavLsbAtSample(carrierBytes, wav, samples[bitIndex]) <<
          (7 - (bitIndex & 7));
    }
    return output;
  }

  void _setWavLsbAtSample(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
    int sample,
    int bit,
  ) {
    final offset = wav.dataOffset + (sample * wav.bytesPerSample);
    if (sample < 0 || offset >= wav.dataOffset + wav.dataLength) {
      throw const ToolboxSteganographyException(
        'Hidden payload is damaged or incomplete.',
      );
    }
    carrierBytes[offset] = (carrierBytes[offset] & 0xfe) | bit;
  }

  int _wavLsbAtSample(Uint8List carrierBytes, _WavCarrierInfo wav, int sample) {
    final offset = wav.dataOffset + (sample * wav.bytesPerSample);
    if (sample < 0 || offset >= wav.dataOffset + wav.dataLength) {
      throw const ToolboxSteganographyException(
        'Hidden audio payload is damaged or incomplete.',
      );
    }
    return carrierBytes[offset] & 1;
  }

  Uint8List _wavCarrierDigest(
    Uint8List carrierBytes,
    _WavCarrierInfo wav, {
    String purpose = 'audio-carrier',
  }) {
    final output = _DigestSink();
    final input = sha256.startChunkedConversion(output);
    input.add(<int>[
      ...utf8.encode('vocabulary_sleep_stego_wav_digest_v1'),
      0,
      ...utf8.encode(purpose),
      0,
      ..._uint32Bytes(wav.channels),
      ..._uint32Bytes(wav.bitsPerSample),
      ..._uint32Bytes(wav.blockAlign),
      ..._uint32Bytes(wav.dataLength),
      0,
    ]);
    if (wav.dataOffset > 0) {
      input.add(carrierBytes.sublist(0, wav.dataOffset));
    }
    const chunkSize = 8192;
    final dataEnd = wav.dataOffset + wav.dataLength;
    for (var offset = wav.dataOffset; offset < dataEnd; offset += chunkSize) {
      final end = math.min(offset + chunkSize, dataEnd).toInt();
      final chunk = Uint8List.fromList(carrierBytes.sublist(offset, end));
      for (
        var sampleOffset = 0;
        sampleOffset < chunk.length;
        sampleOffset += wav.bytesPerSample
      ) {
        chunk[sampleOffset] &= 0xfe;
      }
      input.add(chunk);
    }
    if (dataEnd < carrierBytes.length) {
      input.add(carrierBytes.sublist(dataEnd));
    }
    input.close();
    return Uint8List.fromList(output.value.bytes);
  }

  _Mp4CarrierInfo _parseIsoBmffCarrier(
    Uint8List carrierBytes, {
    required String unsupportedMessage,
  }) {
    _validateTailCarrierSize(carrierBytes);
    final boxes = _mp4TopLevelBoxes(carrierBytes);
    final ftyp = boxes.cast<_Mp4Box?>().firstWhere(
      (box) => box?.type == 'ftyp',
      orElse: () => null,
    );
    if (ftyp == null || ftyp.dataLength < 8) {
      throw ToolboxSteganographyException(unsupportedMessage);
    }
    final majorBrand = _asciiBoxString(
      carrierBytes,
      ftyp.dataOffset,
      ftyp.dataOffset + 4,
    );
    return _Mp4CarrierInfo(majorBrand: majorBrand, boxes: boxes);
  }

  _Mp4FreeRegion _largestWritableMp4FreeRegion(_Mp4CarrierInfo mp4) {
    final regions = _mp4WritableFreeRegions(mp4);
    if (regions.isEmpty) {
      throw const ToolboxSteganographyException(
        _isoBmffFreePaddingRequiredMessage,
      );
    }
    regions.sort(
      (left, right) => _mp4FreeBoxBlockCapacity(
        right,
      ).compareTo(_mp4FreeBoxBlockCapacity(left)),
    );
    final selected = regions.first;
    if (_mp4FreeBoxBlockCapacity(selected) <= 0) {
      throw const ToolboxSteganographyException(
        _isoBmffLargerFreePaddingRequiredMessage,
      );
    }
    return selected;
  }

  List<_Mp4FreeRegion> _mp4WritableFreeRegions(_Mp4CarrierInfo mp4) {
    return mp4.boxes
        .where(
          (box) =>
              box.type == ascii.decode(_mp4StegoBoxType) &&
              box.dataLength >= _mp4MinimumFreeBoxDataBytes,
        )
        .map(
          (box) => _Mp4FreeRegion(
            offset: box.offset,
            dataOffset: box.dataOffset,
            dataLength: box.dataLength,
          ),
        )
        .toList();
  }

  int _mp4FreeBoxBlockCapacity(_Mp4FreeRegion region) {
    final budget = _densityLimitedPositionBudget(
      region.dataLength,
      _mp4FreeBoxMaxStegoByteRatio,
    );
    return (budget - ((_mediaPolicyHeaderLength + _mediaHeaderLength) * 8)) ~/
        8;
  }

  int _mp4FreeBoxSlotCapacity(
    _Mp4FreeRegion region,
    int slot, {
    required List<int> policyPositions,
  }) {
    final slotBytes = (region.dataLength + (slot == 0 ? 1 : 0)) ~/ 2;
    final slotBudget = _densityLimitedPositionBudget(
      slotBytes,
      _mp4FreeBoxMaxStegoByteRatio,
    );
    final reservedPolicy = policyPositions
        .where((position) => position.isEven == (slot == 0))
        .length;
    return (slotBudget - reservedPolicy - (_mediaHeaderLength * 8)) ~/ 8;
  }

  List<int> _mp4FreePolicyPositions(
    Uint8List carrierBytes,
    _Mp4FreeRegion region,
    Uint8List seed,
  ) {
    if (region.dataLength < _mediaPolicyHeaderLength * 8 ||
        region.dataEnd > carrierBytes.length) {
      throw const ToolboxSteganographyException(
        _isoBmffLargerFreePaddingRequiredMessage,
      );
    }
    return _selectPositions(
      total: region.dataLength,
      count: _mediaPolicyHeaderLength * 8,
      seed: seed,
    );
  }

  void _writeRandomizedMp4FreeBoxBlock(
    Uint8List carrierBytes,
    _Mp4FreeRegion region, {
    required Uint8List block,
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
  }) {
    final locatorSalt = _randomMediaLocatorSalt(carrierProtectionMode);
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
      salt: locatorSalt,
    );
    final carrierDigest = _mp4FreeCarrierDigest(carrierBytes, region);
    final policyPositions = _mp4FreePolicyPositions(
      carrierBytes,
      region,
      _mp4FreeCarrierDigest(
        carrierBytes,
        region,
        purpose: 'video-free-public-policy',
      ),
    );
    final usedPositions =
        policyPositions.length + (_mediaHeaderLength * 8) + (block.length * 8);
    final budget = _densityLimitedPositionBudget(
      region.dataLength,
      _mp4FreeBoxMaxStegoByteRatio,
    );
    if (usedPositions > budget) {
      throw const ToolboxSteganographyException('Payload is too large.');
    }
    final nonce = _randomBytes(_mediaNonceLength);
    final header = _buildMediaHeader(
      locatorSecret: locatorSecret,
      nonce: nonce,
      payloadLength: block.length,
      carrierDigest: carrierDigest,
      purpose: 'video-free',
    );
    final headerPositions = _selectPositions(
      total: region.dataLength,
      count: header.length * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: 'video-free-header',
        carrierDigest: carrierDigest,
      ),
      excluded: Set<int>.from(policyPositions),
    );
    final payloadPositions = _selectPositions(
      total: region.dataLength,
      count: block.length * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: 'video-free-payload',
        carrierDigest: carrierDigest,
        nonce: nonce,
      ),
      excluded: <int>{...policyPositions, ...headerPositions},
    );
    _writeLsbBytesAtByteOffsets(
      carrierBytes,
      header,
      _absoluteMp4FreeOffsets(region, headerPositions),
    );
    _writeLsbBytesAtByteOffsets(
      carrierBytes,
      block,
      _absoluteMp4FreeOffsets(region, payloadPositions),
    );
    _writeLsbBytesAtByteOffsets(
      carrierBytes,
      _buildMediaLocatorHeader(
        locatorSalt,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
      ),
      _absoluteMp4FreeOffsets(region, policyPositions),
    );
  }

  void _writeRandomizedMp4FreeBoxBlockInSlot(
    Uint8List carrierBytes,
    _Mp4FreeRegion region,
    Uint8List block, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required Uint8List locatorSalt,
    required int slot,
    required List<int> policyPositions,
  }) {
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
      salt: locatorSalt,
    );
    final carrierDigest = _mp4FreeCarrierDigest(carrierBytes, region);
    final reservedPolicy = policyPositions
        .where((position) => position.isEven == (slot == 0))
        .length;
    final usedPositions =
        reservedPolicy + (_mediaHeaderLength * 8) + (block.length * 8);
    final slotBytes = (region.dataLength + (slot == 0 ? 1 : 0)) ~/ 2;
    final budget = _densityLimitedPositionBudget(
      slotBytes,
      _mp4FreeBoxMaxStegoByteRatio,
    );
    if (usedPositions > budget) {
      throw const ToolboxSteganographyException('Payload is too large.');
    }
    final nonce = _randomBytes(_mediaNonceLength);
    final header = _buildMediaHeader(
      locatorSecret: locatorSecret,
      nonce: nonce,
      payloadLength: block.length,
      carrierDigest: carrierDigest,
      purpose: 'video-free-slot-$slot',
    );
    final headerPositions = _selectSlotPositions(
      total: region.dataLength,
      count: header.length * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: 'video-free-header-slot-$slot',
        carrierDigest: carrierDigest,
      ),
      slot: slot,
      excluded: Set<int>.from(policyPositions),
    );
    final payloadPositions = _selectSlotPositions(
      total: region.dataLength,
      count: block.length * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: 'video-free-payload-slot-$slot',
        carrierDigest: carrierDigest,
        nonce: nonce,
      ),
      slot: slot,
      excluded: <int>{...policyPositions, ...headerPositions},
    );
    _writeLsbBytesAtByteOffsets(
      carrierBytes,
      header,
      _absoluteMp4FreeOffsets(region, headerPositions),
    );
    _writeLsbBytesAtByteOffsets(
      carrierBytes,
      block,
      _absoluteMp4FreeOffsets(region, payloadPositions),
    );
  }

  _VideoBlockReadResult _readAnyIsoBmffFreeBoxBlockDetails({
    required Uint8List carrierBytes,
    required _Mp4CarrierInfo carrier,
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final regions = _mp4WritableFreeRegions(carrier)
      ..sort(
        (left, right) => _mp4FreeBoxBlockCapacity(
          right,
        ).compareTo(_mp4FreeBoxBlockCapacity(left)),
      );
    final errors = <Object>[];
    for (final region in regions) {
      try {
        final policyPositions = _mp4FreePolicyPositions(
          carrierBytes,
          region,
          _mp4FreeCarrierDigest(
            carrierBytes,
            region,
            purpose: 'video-free-public-policy',
          ),
        );
        final policyOffsets = _absoluteMp4FreeOffsets(region, policyPositions);
        final policyHeader = _readLsbBytesAtByteOffsets(
          carrierBytes,
          byteCount: _mediaPolicyHeaderLength,
          offsets: policyOffsets,
        );
        final candidates = _mediaLocatorReadCandidates(
          policyHeader,
          locatorAlgorithm: locatorAlgorithm,
          locatorStrength: locatorStrength,
        );
        for (final candidate in candidates) {
          final locatorSecret = _locatorSecret(
            passphrase,
            keyFileBytes,
            algorithm: candidate.algorithm,
            strength: candidate.strength,
            salt: candidate.salt,
          );
          for (final slot in <int?>[null, 0, 1]) {
            try {
              return _readMp4FreeBoxBlockWithPolicyReservation(
                carrierBytes,
                region,
                locatorSecret: locatorSecret,
                slot: slot,
                policyPositions: policyPositions,
                policyOffsets: policyOffsets,
              );
            } on Object catch (error) {
              errors.add(error);
            }
          }
        }
      } on Object catch (error) {
        errors.add(error);
      }
    }
    final last = errors.isEmpty ? null : errors.last;
    if (last is ToolboxSteganographyException) {
      throw last;
    }
    throw const ToolboxSteganographyException('No hidden video payload found.');
  }

  _VideoBlockReadResult _readMp4FreeBoxBlockWithPolicyReservation(
    Uint8List carrierBytes,
    _Mp4FreeRegion region, {
    required Uint8List locatorSecret,
    required int? slot,
    required List<int> policyPositions,
    required List<int> policyOffsets,
  }) {
    final carrierDigest = _mp4FreeCarrierDigest(carrierBytes, region);
    final purpose = slot == null ? 'video-free' : 'video-free-slot-$slot';
    final headerPositions = slot == null
        ? _selectPositions(
            total: region.dataLength,
            count: _mediaHeaderLength * 8,
            seed: _mediaPositionSeed(
              locatorSecret: locatorSecret,
              purpose: 'video-free-header',
              carrierDigest: carrierDigest,
            ),
            excluded: Set<int>.from(policyPositions),
          )
        : _selectSlotPositions(
            total: region.dataLength,
            count: _mediaHeaderLength * 8,
            seed: _mediaPositionSeed(
              locatorSecret: locatorSecret,
              purpose: 'video-free-header-slot-$slot',
              carrierDigest: carrierDigest,
            ),
            slot: slot,
            excluded: Set<int>.from(policyPositions),
          );
    final headerOffsets = _absoluteMp4FreeOffsets(region, headerPositions);
    final header = _readLsbBytesAtByteOffsets(
      carrierBytes,
      byteCount: _mediaHeaderLength,
      offsets: headerOffsets,
    );
    final nonce = Uint8List.fromList(
      header.sublist(_mediaMagicLength, _mediaMagicLength + _mediaNonceLength),
    );
    final expectedMagic = _mediaMagic(
      locatorSecret: locatorSecret,
      nonce: nonce,
      carrierDigest: carrierDigest,
      purpose: purpose,
    );
    if (!_bytesEqual(header.sublist(0, _mediaMagicLength), expectedMagic)) {
      throw const ToolboxSteganographyException(
        'No hidden video payload found.',
      );
    }
    final maskedLength = _readUint32(
      header,
      _mediaMagicLength + _mediaNonceLength,
    );
    final payloadLength =
        maskedLength ^
        _mediaLengthMask(
          locatorSecret: locatorSecret,
          nonce: nonce,
          carrierDigest: carrierDigest,
          purpose: purpose,
        );
    final capacity = slot == null
        ? _mp4FreeBoxBlockCapacity(region)
        : _mp4FreeBoxSlotCapacity(
            region,
            slot,
            policyPositions: policyPositions,
          );
    if (payloadLength <= 0 || payloadLength > capacity) {
      throw const ToolboxSteganographyException(
        'Hidden video payload is damaged or incomplete.',
      );
    }
    final payloadPositions = slot == null
        ? _selectPositions(
            total: region.dataLength,
            count: payloadLength * 8,
            seed: _mediaPositionSeed(
              locatorSecret: locatorSecret,
              purpose: 'video-free-payload',
              carrierDigest: carrierDigest,
              nonce: nonce,
            ),
            excluded: <int>{...policyPositions, ...headerPositions},
          )
        : _selectSlotPositions(
            total: region.dataLength,
            count: payloadLength * 8,
            seed: _mediaPositionSeed(
              locatorSecret: locatorSecret,
              purpose: 'video-free-payload-slot-$slot',
              carrierDigest: carrierDigest,
              nonce: nonce,
            ),
            slot: slot,
            excluded: <int>{...policyPositions, ...headerPositions},
          );
    final payloadOffsets = _absoluteMp4FreeOffsets(region, payloadPositions);
    return _VideoBlockReadResult(
      block: _readLsbBytesAtByteOffsets(
        carrierBytes,
        byteCount: payloadLength,
        offsets: payloadOffsets,
      ),
      headerOffsets: headerOffsets,
      payloadOffsets: payloadOffsets,
      policyOffsets: policyOffsets,
      slot: slot,
    );
  }

  Uint8List _mp4FreeCarrierDigest(
    Uint8List carrierBytes,
    _Mp4FreeRegion region, {
    String purpose = 'video-free-carrier',
  }) {
    final output = _DigestSink();
    final input = sha256.startChunkedConversion(output);
    input.add(<int>[
      ...utf8.encode('vocabulary_sleep_stego_mp4_free_digest_v1'),
      0,
      ...utf8.encode(purpose),
      0,
      ..._uint64Bytes(carrierBytes.length),
      ..._uint64Bytes(region.offset),
      ..._uint64Bytes(region.dataOffset),
      ..._uint64Bytes(region.dataLength),
      0,
    ]);
    const chunkSize = 8192;
    for (var offset = 0; offset < carrierBytes.length; offset += chunkSize) {
      final end = math.min(offset + chunkSize, carrierBytes.length).toInt();
      if (end <= region.dataOffset || offset >= region.dataEnd) {
        input.add(carrierBytes.sublist(offset, end));
        continue;
      }
      final chunk = Uint8List.fromList(carrierBytes.sublist(offset, end));
      final maskStart = math.max(region.dataOffset, offset) - offset;
      final maskEnd = math.min(region.dataEnd, end) - offset;
      for (var index = maskStart; index < maskEnd; index += 1) {
        chunk[index] &= 0xfe;
      }
      input.add(chunk);
    }
    input.close();
    return Uint8List.fromList(output.value.bytes);
  }

  List<int> _absoluteMp4FreeOffsets(
    _Mp4FreeRegion region,
    List<int> relativePositions,
  ) {
    return relativePositions
        .map((position) => region.dataOffset + position)
        .toList(growable: false);
  }

  void _writeLsbBytesAtByteOffsets(
    Uint8List carrierBytes,
    Uint8List bytes,
    List<int> offsets,
  ) {
    final totalBits = bytes.length * 8;
    if (offsets.length < totalBits) {
      throw const ToolboxSteganographyException(
        'Hidden video payload is damaged or incomplete.',
      );
    }
    for (var bitIndex = 0; bitIndex < totalBits; bitIndex += 1) {
      final offset = offsets[bitIndex];
      if (offset < 0 || offset >= carrierBytes.length) {
        throw const ToolboxSteganographyException(
          'Hidden video payload is damaged or incomplete.',
        );
      }
      carrierBytes[offset] =
          (carrierBytes[offset] & 0xfe) | _bitAt(bytes, bitIndex);
    }
  }

  Uint8List _readLsbBytesAtByteOffsets(
    Uint8List carrierBytes, {
    required int byteCount,
    required List<int> offsets,
  }) {
    final totalBits = byteCount * 8;
    if (offsets.length < totalBits) {
      throw const ToolboxSteganographyException(
        'Hidden video payload is incomplete.',
      );
    }
    final output = Uint8List(byteCount);
    for (var bitIndex = 0; bitIndex < totalBits; bitIndex += 1) {
      final offset = offsets[bitIndex];
      if (offset < 0 || offset >= carrierBytes.length) {
        throw const ToolboxSteganographyException(
          'Hidden video payload is damaged or incomplete.',
        );
      }
      output[bitIndex >> 3] |=
          (carrierBytes[offset] & 1) << (7 - (bitIndex & 7));
    }
    return output;
  }

  List<_Mp4Box> _mp4TopLevelBoxes(Uint8List carrierBytes) {
    final boxes = <_Mp4Box>[];
    var offset = 0;
    while (offset + 8 <= carrierBytes.length &&
        boxes.length < _mp4MaxBoxScanDepth) {
      final size32 = _readUint32(carrierBytes, offset);
      final type = _asciiBoxString(carrierBytes, offset + 4, offset + 8);
      var headerLength = 8;
      var size = size32;
      if (size32 == 1) {
        if (offset + 16 > carrierBytes.length) {
          throw const ToolboxSteganographyException(
            'Video carrier is damaged or incomplete.',
          );
        }
        size = _readUint64(carrierBytes, offset + 8);
        headerLength = 16;
      } else if (size32 == 0) {
        size = carrierBytes.length - offset;
      }
      if (size < headerLength || offset + size > carrierBytes.length) {
        throw const ToolboxSteganographyException(
          'Video carrier is damaged or incomplete.',
        );
      }
      boxes.add(
        _Mp4Box(
          offset: offset,
          size: size,
          type: type,
          dataOffset: offset + headerLength,
        ),
      );
      offset += size;
    }
    if (boxes.isEmpty) {
      throw const ToolboxSteganographyException(_unsupportedVideoFormatMessage);
    }
    return boxes;
  }

  String _asciiBoxString(Uint8List bytes, int start, int end) {
    if (start < 0 || end > bytes.length || start >= end) {
      throw const ToolboxSteganographyException(
        'Video carrier is damaged or incomplete.',
      );
    }
    final chars = bytes.sublist(start, end);
    if (chars.any((byte) => byte < 0x20 || byte > 0x7e)) {
      return '';
    }
    return ascii.decode(chars);
  }

  Uint8List _buildMediaHeader({
    required Uint8List locatorSecret,
    required Uint8List nonce,
    required int payloadLength,
    required Uint8List carrierDigest,
    required String purpose,
  }) {
    final maskedLength =
        payloadLength ^
        _mediaLengthMask(
          locatorSecret: locatorSecret,
          nonce: nonce,
          carrierDigest: carrierDigest,
          purpose: purpose,
        );
    return Uint8List.fromList(<int>[
      ..._mediaMagic(
        locatorSecret: locatorSecret,
        nonce: nonce,
        carrierDigest: carrierDigest,
        purpose: purpose,
      ),
      ...nonce,
      ..._uint32Bytes(maskedLength),
    ]);
  }

  Uint8List _mediaMagic({
    required Uint8List locatorSecret,
    required Uint8List nonce,
    required Uint8List carrierDigest,
    required String purpose,
  }) {
    return Uint8List.fromList(
      sha256
          .convert(<int>[
            ...locatorSecret,
            0,
            ...nonce,
            0,
            ...carrierDigest,
            0,
            ...utf8.encode('$purpose-magic'),
          ])
          .bytes
          .sublist(0, _mediaMagicLength),
    );
  }

  int _mediaLengthMask({
    required Uint8List locatorSecret,
    required Uint8List nonce,
    required Uint8List carrierDigest,
    required String purpose,
  }) {
    final digest = sha256.convert(<int>[
      ...locatorSecret,
      0,
      ...nonce,
      0,
      ...carrierDigest,
      0,
      ...utf8.encode('$purpose-length'),
    ]).bytes;
    return _readUint32(digest, 0);
  }

  Uint8List _mediaPositionSeed({
    required Uint8List locatorSecret,
    required String purpose,
    required Uint8List carrierDigest,
    Uint8List? nonce,
  }) {
    return Uint8List.fromList(
      sha256.convert(<int>[
        ...locatorSecret,
        0,
        ...utf8.encode(purpose),
        0,
        ...carrierDigest,
        0,
        ...?nonce,
      ]).bytes,
    );
  }

  _EnvelopeBuildResult _buildEnvelope({
    required ToolboxSteganographyPayloadKind payloadKind,
    String? text,
    Uint8List? plainBytes,
    required ToolboxCryptoAlgorithm encryption,
    required String passphrase,
    required ToolboxCryptoStrength strength,
    required Uint8List? keyFileBytes,
    String? fileName,
    String? mediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
  }) {
    final bytes = plainBytes ?? Uint8List.fromList(utf8.encode(text ?? ''));
    final encrypted = _cryptoService.encryptBytes(
      plainBytes: bytes,
      algorithm: encryption,
      strength: strength,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      fileName: fileName,
      mediaType: mediaType,
      cascade: cascade,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
    );
    final envelope = <String, Object?>{
      'version': 3,
      'payloadKind': payloadKind.id,
      'encoding': payloadKind == ToolboxSteganographyPayloadKind.text
          ? 'utf8'
          : 'bytes',
      'fileName': fileName,
      'mediaType': mediaType,
      'cryptoEnvelope': base64Encode(encrypted.envelopeBytes),
    };
    final jsonBytes = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
    return _EnvelopeBuildResult(
      jsonBytes: jsonBytes,
      cipherPreview: encrypted.cipherPreview,
    );
  }

  _EnvelopeParseResult _parseEnvelope(
    Map<String, Object?> map, {
    required String passphrase,
    required Uint8List? keyFileBytes,
  }) {
    final version = map['version'];
    if (version == 2 || version == 3) {
      final payloadKind = map['payloadKind'] as String? ?? 'text';
      if (payloadKind != ToolboxSteganographyPayloadKind.text.id) {
        throw const ToolboxSteganographyException(
          'Hidden payload is not text.',
        );
      }
      final envelopeText = map['cryptoEnvelope'];
      if (envelopeText is! String) {
        throw const ToolboxSteganographyException('Hidden payload is invalid.');
      }
      final decrypted = _runCryptoDecrypt(
        envelopeBytes: _decodeEmbeddedCryptoEnvelope(envelopeText),
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
      );
      try {
        return _EnvelopeParseResult(
          text: utf8.decode(decrypted.plainBytes),
          encryption: decrypted.algorithm,
          strength: decrypted.strength,
          cipherPreview: decrypted.cipherPreview,
        );
      } on FormatException {
        throw const ToolboxSteganographyException(
          'Payload text is not valid UTF-8.',
        );
      }
    }
    if (version != 1) {
      throw const ToolboxSteganographyException('Unsupported payload version.');
    }
    return _parseLegacyEnvelope(map, passphrase);
  }

  _FileEnvelopeParseResult _parseFileEnvelope(
    Map<String, Object?> map, {
    required String passphrase,
    required Uint8List? keyFileBytes,
  }) {
    final version = map['version'];
    if (version != 2 && version != 3) {
      throw const ToolboxSteganographyException(
        'This payload does not contain a hidden file.',
      );
    }
    final payloadKind = map['payloadKind'] as String? ?? 'text';
    if (payloadKind != ToolboxSteganographyPayloadKind.file.id) {
      throw const ToolboxSteganographyException(
        'This payload does not contain a hidden file.',
      );
    }
    final envelopeText = map['cryptoEnvelope'];
    if (envelopeText is! String) {
      throw const ToolboxSteganographyException('Hidden payload is invalid.');
    }
    final decrypted = _runCryptoDecrypt(
      envelopeBytes: _decodeEmbeddedCryptoEnvelope(envelopeText),
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );
    return _FileEnvelopeParseResult(
      bytes: decrypted.plainBytes,
      fileName: decrypted.fileName ?? map['fileName'] as String?,
      mediaType: decrypted.mediaType ?? map['mediaType'] as String?,
      encryption: decrypted.algorithm,
      strength: decrypted.strength,
      cipherPreview: decrypted.cipherPreview,
    );
  }

  Uint8List _decodeEmbeddedCryptoEnvelope(String text) {
    final maxBase64Length = ((maxEmbeddedCryptoEnvelopeBytes + 2) ~/ 3) * 4;
    if (text.length > maxBase64Length) {
      throw const ToolboxSteganographyException(
        'Crypto envelope is too large.',
      );
    }
    try {
      final bytes = Uint8List.fromList(base64Decode(text));
      if (bytes.length > maxEmbeddedCryptoEnvelopeBytes) {
        throw const ToolboxSteganographyException(
          'Crypto envelope is too large.',
        );
      }
      return bytes;
    } on FormatException {
      throw const ToolboxSteganographyException('Hidden payload is invalid.');
    }
  }

  _EnvelopeParseResult _parseLegacyEnvelope(
    Map<String, Object?> map,
    String passphrase,
  ) {
    final cipherId = map['cipher'];
    final nonceText = map['nonce'];
    final cipherText = map['ciphertext'];
    final plainSha = map['plainSha256'];
    final mac = map['mac'];
    if (cipherId is! String ||
        nonceText is! String ||
        cipherText is! String ||
        plainSha is! String ||
        mac is! String) {
      throw const ToolboxSteganographyException('Hidden payload is invalid.');
    }
    final encryption = _legacyAlgorithmFromId(cipherId);
    if (encryption.requiresSecret && passphrase.trim().isEmpty) {
      throw const ToolboxSteganographyException(
        'This payload requires a passphrase.',
      );
    }
    final nonce = Uint8List.fromList(base64Decode(nonceText));
    final cipherBytes = Uint8List.fromList(base64Decode(cipherText));
    if (encryption.requiresSecret) {
      final macBytes = _hexToBytes(mac);
      final expectedMac = _legacyHmacBytes(
        passphrase: passphrase,
        nonce: nonce,
        cipherId: encryption.id,
        cipherBytes: cipherBytes,
      );
      if (macBytes == null || !_bytesEqual(macBytes, expectedMac)) {
        throw const ToolboxSteganographyException(
          'Passphrase mismatch or payload is damaged.',
        );
      }
    } else {
      final macBytes = _hexToBytes(mac);
      final expectedMac = sha256.convert(cipherBytes).bytes;
      if (macBytes == null || !_bytesEqual(macBytes, expectedMac)) {
        throw const ToolboxSteganographyException('Payload is damaged.');
      }
    }

    final plainBytes = switch (encryption) {
      ToolboxCryptoAlgorithm.none => cipherBytes,
      ToolboxCryptoAlgorithm.sha256Stream => _xorWithSha256Stream(
        cipherBytes,
        _legacyDeriveKey(passphrase, nonce, 'sha256-stream'),
        nonce,
      ),
      ToolboxCryptoAlgorithm.rc4Legacy => _rc4(
        cipherBytes,
        _legacyDeriveKey(passphrase, nonce, 'rc4-legacy'),
      ),
      _ => throw const ToolboxSteganographyException(
        'Unsupported encryption algorithm.',
      ),
    };
    final plainShaBytes = _hexToBytes(plainSha);
    final actualSha = sha256.convert(plainBytes).bytes;
    if (plainShaBytes == null || !_bytesEqual(actualSha, plainShaBytes)) {
      throw const ToolboxSteganographyException('Payload checksum failed.');
    }

    try {
      return _EnvelopeParseResult(
        text: utf8.decode(plainBytes),
        encryption: encryption,
        strength: ToolboxCryptoStrength.standard,
        cipherPreview: _previewBase64(cipherBytes),
      );
    } on FormatException {
      throw const ToolboxSteganographyException(
        'Payload text is not valid UTF-8.',
      );
    }
  }

  Uint8List _buildBlock(Uint8List jsonBytes) {
    final prefix = BytesBuilder(copy: false)
      ..add(_sealedBlockMagic)
      ..add(_uint32Bytes(jsonBytes.length))
      ..add(jsonBytes);
    final prefixBytes = prefix.takeBytes();
    final tail = _protectedBlockTail(prefixBytes);
    return Uint8List.fromList(<int>[...prefixBytes, ...tail]);
  }

  Map<String, Object?> _parseBlock(Uint8List block) {
    final jsonBytes = _blockJsonBytes(block);
    final decoded = jsonDecode(utf8.decode(jsonBytes));
    if (decoded is! Map<String, Object?>) {
      throw const ToolboxSteganographyException(
        'Hidden payload body is invalid.',
      );
    }
    return decoded;
  }

  Uint8List _blockJsonBytes(Uint8List block) {
    if (_startsWith(block, _sealedBlockMagic)) {
      return _protectedBlockJsonBytes(block);
    }
    if (_startsWith(block, _managedBlockMagic)) {
      return _protectedBlockJsonBytes(block);
    }
    if (_startsWith(block, _protectedBlockMagic)) {
      return _protectedBlockJsonBytes(block);
    }
    if (_startsWith(block, _blockMagic)) {
      return _legacyBlockJsonBytes(block);
    }
    return block;
  }

  Uint8List _protectedBlockJsonBytes(Uint8List block) {
    final isSealedBlock = _startsWith(block, _sealedBlockMagic);
    final isManagedBlock = _startsWith(block, _managedBlockMagic);
    final magicLength = isSealedBlock
        ? _sealedBlockMagic.length
        : isManagedBlock
        ? _managedBlockMagic.length
        : _protectedBlockMagic.length;
    final policyBytes = isSealedBlock
        ? 0
        : isManagedBlock
        ? 2
        : 1;
    final headerLength = magicLength + policyBytes + 4;
    if (block.length < headerLength + _protectedBlockTailLength ||
        (!isSealedBlock &&
            !isManagedBlock &&
            !_startsWith(block, _protectedBlockMagic))) {
      throw const ToolboxSteganographyException(
        'Hidden payload header is invalid.',
      );
    }
    final jsonLength = _readUint32(block, magicLength + policyBytes);
    final jsonOffset = headerLength;
    final tailOffset = jsonOffset + jsonLength;
    if (jsonLength <= 0 ||
        tailOffset + _protectedBlockTailLength != block.length) {
      throw const ToolboxSteganographyException(
        'Hidden payload length is invalid.',
      );
    }
    final prefix = Uint8List.fromList(block.sublist(0, tailOffset));
    final expectedTail = _protectedBlockTail(prefix);
    final actualTail = block.sublist(tailOffset);
    if (!_bytesEqual(actualTail, expectedTail)) {
      throw const ToolboxSteganographyException(
        'Hidden payload tamper check failed.',
      );
    }
    return Uint8List.fromList(block.sublist(jsonOffset, tailOffset));
  }

  Uint8List _legacyBlockJsonBytes(Uint8List block) {
    if (block.length < _blockMagic.length + 4 ||
        !_startsWith(block, _blockMagic)) {
      throw const ToolboxSteganographyException(
        'Hidden payload header is invalid.',
      );
    }
    final jsonLength = _readUint32(block, _blockMagic.length);
    final jsonOffset = _blockMagic.length + 4;
    if (jsonLength <= 0 || jsonOffset + jsonLength != block.length) {
      throw const ToolboxSteganographyException(
        'Hidden payload length is invalid.',
      );
    }
    return Uint8List.fromList(block.sublist(jsonOffset));
  }

  Uint8List _protectedBlockTail(Uint8List prefixBytes) {
    return Uint8List.fromList(
      sha256
          .convert(<int>[
            ...utf8.encode('vocabulary_sleep_stego_tamper_tail_v1'),
            0,
            ...prefixBytes,
          ])
          .bytes
          .sublist(0, _protectedBlockTailLength),
    );
  }

  void _writeRandomizedLsbBlock(
    img.Image image,
    Uint8List block, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
  }) {
    final locatorSalt = _randomLocatorSalt(carrierProtectionMode);
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
      salt: locatorSalt,
    );
    final nonce = _randomBytes(_imageNonceLength);
    final totalPositions = image.width * image.height * 3;
    final policyPositions = _imagePolicyPositions(
      image,
      headerLength: _imagePolicyHeaderLength,
    );
    final header = _buildImageHeader(
      locatorSecret: locatorSecret,
      nonce: nonce,
      payloadLength: block.length,
      width: image.width,
      height: image.height,
    );
    final headerPositions = _selectPositions(
      total: totalPositions,
      count: header.length * 8,
      seed: _positionSeed(
        locatorSecret: locatorSecret,
        purpose: 'image-header',
        width: image.width,
        height: image.height,
      ),
      excluded: Set<int>.from(policyPositions),
    );
    final payloadPositions = _selectPositions(
      total: totalPositions,
      count: block.length * 8,
      seed: _positionSeed(
        locatorSecret: locatorSecret,
        purpose: 'image-payload',
        width: image.width,
        height: image.height,
        nonce: nonce,
      ),
      excluded: <int>{...policyPositions, ...headerPositions},
    );
    _writeLsbBytesAtPositions(image, header, headerPositions);
    _writeLsbBytesAtPositions(image, block, payloadPositions);
    _writeImageLocatorHeader(
      image,
      locatorSalt: locatorSalt,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      carrierProtectionMode: carrierProtectionMode,
      positions: policyPositions,
    );
  }

  void _writeRandomizedLsbBlockInSlot(
    img.Image image,
    Uint8List block, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required Uint8List locatorSalt,
    required int slot,
    required List<int> policyPositions,
  }) {
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
      salt: locatorSalt,
    );
    final nonce = _randomBytes(_imageNonceLength);
    final totalPositions = image.width * image.height * 3;
    final header = _buildImageHeader(
      locatorSecret: locatorSecret,
      nonce: nonce,
      payloadLength: block.length,
      width: image.width,
      height: image.height,
    );
    final headerPositions = _selectSlotPositions(
      total: totalPositions,
      count: header.length * 8,
      seed: _positionSeed(
        locatorSecret: locatorSecret,
        purpose: 'image-header-slot-$slot',
        width: image.width,
        height: image.height,
      ),
      slot: slot,
      excluded: Set<int>.from(policyPositions),
    );
    final payloadPositions = _selectSlotPositions(
      total: totalPositions,
      count: block.length * 8,
      seed: _positionSeed(
        locatorSecret: locatorSecret,
        purpose: 'image-payload-slot-$slot',
        width: image.width,
        height: image.height,
        nonce: nonce,
      ),
      slot: slot,
      excluded: <int>{...policyPositions, ...headerPositions},
    );
    _writeLsbBytesAtPositions(image, header, headerPositions);
    _writeLsbBytesAtPositions(image, block, payloadPositions);
  }

  Uint8List _readRandomizedLsbBlock(
    img.Image image, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    return _readAnyRandomizedLsbBlockDetails(
      image,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    ).block;
  }

  _ImageBlockReadResult _readAnyRandomizedLsbBlockDetails(
    img.Image image, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final errors = <Object>[];
    final policyPositions = _imagePolicyPositions(
      image,
      headerLength: _imagePolicyHeaderLength,
    );
    final candidates = _imageLocatorReadCandidates(
      image,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      policyPositions: policyPositions,
      includeLegacyCandidates: false,
    );
    for (final candidate in candidates) {
      final locatorSecret = _locatorSecret(
        passphrase,
        keyFileBytes,
        algorithm: candidate.algorithm,
        strength: candidate.strength,
        salt: candidate.salt,
      );
      for (final slot in <int?>[null, 0, 1]) {
        try {
          return _readRandomizedLsbBlockWithPolicyReservation(
            image,
            locatorSecret: locatorSecret,
            slot: slot,
            policyPositions: policyPositions,
          );
        } on Object catch (error) {
          errors.add(error);
        }
      }
    }
    final last = errors.isEmpty ? null : errors.last;
    if (last is ToolboxSteganographyException) {
      throw last;
    }
    throw const ToolboxSteganographyException('No hidden image payload found.');
  }

  List<_ImageLocatorCandidate> _imageLocatorReadCandidates(
    img.Image image, {
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required List<int> policyPositions,
    required bool includeLegacyCandidates,
  }) {
    final candidates = <_ImageLocatorCandidate>[];
    try {
      final header = _readLsbBytesAtPositions(
        image,
        byteCount: _imagePolicyHeaderLength,
        positions: policyPositions,
      );
      final salt = _imageLocatorSaltFromHeader(header);
      if (salt != null) {
        candidates.add(
          _ImageLocatorCandidate(
            algorithm: locatorAlgorithm,
            strength: locatorStrength,
            salt: salt,
          ),
        );
      }
    } on ToolboxSteganographyException {
      // Fall through to the legacy locator candidate below.
    }
    if (!includeLegacyCandidates) {
      return candidates;
    }
    for (final settings in _locatorSettingAttempts(
      preferredAlgorithm: locatorAlgorithm,
      preferredStrength: locatorStrength,
    )) {
      candidates.add(
        _ImageLocatorCandidate(
          algorithm: settings.algorithm,
          strength: settings.strength,
        ),
      );
    }
    return candidates;
  }

  Uint8List? _imageLocatorSaltFromHeader(Uint8List header) {
    if (header.length != _imagePolicyHeaderLength) {
      return null;
    }
    if (_startsWith(header, _imageOccupancyMagic)) {
      final saltStart = _imageOccupancyMagic.length;
      final saltEnd = saltStart + _locatorSaltLength;
      final salt = Uint8List.fromList(header.sublist(saltStart, saltEnd));
      if (salt.every((byte) => byte == 0)) {
        return null;
      }
      return salt;
    }
    if (_startsWith(header, _imagePolicyMagic)) {
      return null;
    }
    final salt = Uint8List.fromList(header.sublist(0, _locatorSaltLength));
    if (salt.every((byte) => byte == 0)) {
      return null;
    }
    return salt;
  }

  int _maskedLocatorSettingsHintByte({
    required Uint8List locatorSalt,
    required _LocatorSettings settings,
  }) {
    final index = _locatorSettingsIndex(settings);
    var candidate = _secureRandom.nextInt(256);
    while (((candidate ^ locatorSalt[0]) % _locatorSettingsCount) != index) {
      candidate = _secureRandom.nextInt(256);
    }
    return candidate;
  }

  List<_LocatorSettings> _locatorSettingAttempts({
    required ToolboxSteganographyLocatorAlgorithm preferredAlgorithm,
    required ToolboxSteganographyLocatorStrength preferredStrength,
    _LocatorSettings? hinted,
    bool includeFallbacks = true,
  }) {
    final attempts = <_LocatorSettings>[];
    void add(_LocatorSettings settings) {
      if (attempts.any(
        (item) =>
            item.algorithm == settings.algorithm &&
            item.strength == settings.strength,
      )) {
        return;
      }
      attempts.add(settings);
    }

    if (hinted != null) {
      add(hinted);
    }
    add(
      _LocatorSettings(
        algorithm: preferredAlgorithm,
        strength: preferredStrength,
      ),
    );
    if (!includeFallbacks) {
      return attempts;
    }
    for (final strength in ToolboxSteganographyLocatorStrength.values) {
      for (final algorithm in ToolboxSteganographyLocatorAlgorithm.values) {
        add(_LocatorSettings(algorithm: algorithm, strength: strength));
      }
    }
    return attempts;
  }

  int _locatorSettingsIndex(_LocatorSettings settings) {
    return (settings.strength.index *
            ToolboxSteganographyLocatorAlgorithm.values.length) +
        settings.algorithm.index;
  }

  _ImageBlockReadResult _readRandomizedLsbBlockWithPolicyReservation(
    img.Image image, {
    required Uint8List locatorSecret,
    required int? slot,
    required List<int> policyPositions,
  }) {
    final totalPositions = image.width * image.height * 3;
    final headerSeed = _positionSeed(
      locatorSecret: locatorSecret,
      purpose: slot == null ? 'image-header' : 'image-header-slot-$slot',
      width: image.width,
      height: image.height,
    );
    final headerPositions = slot == null
        ? _selectPositions(
            total: totalPositions,
            count: _imageHeaderLength * 8,
            seed: headerSeed,
            excluded: Set<int>.from(policyPositions),
          )
        : _selectSlotPositions(
            total: totalPositions,
            count: _imageHeaderLength * 8,
            seed: headerSeed,
            slot: slot,
            excluded: Set<int>.from(policyPositions),
          );
    final header = _readLsbBytesAtPositions(
      image,
      byteCount: _imageHeaderLength,
      positions: headerPositions,
    );
    final nonce = Uint8List.fromList(
      header.sublist(_imageMagicLength, _imageMagicLength + _imageNonceLength),
    );
    final expectedMagic = _imageMagic(
      locatorSecret: locatorSecret,
      nonce: nonce,
      width: image.width,
      height: image.height,
    );
    if (!_bytesEqual(header.sublist(0, _imageMagicLength), expectedMagic)) {
      throw const ToolboxSteganographyException(
        'No hidden image payload found.',
      );
    }
    final maskedLength = _readUint32(
      header,
      _imageMagicLength + _imageNonceLength,
    );
    final payloadLength =
        maskedLength ^
        _lengthMask(
          locatorSecret: locatorSecret,
          nonce: nonce,
          width: image.width,
          height: image.height,
        );
    final capacity = slot == null
        ? (totalPositions -
                  ((_imageHeaderLength * 8) + policyPositions.length)) ~/
              8
        : _imageSlotCapacity(
            totalPositions: totalPositions,
            policyPositions: policyPositions,
            slot: slot,
          );
    if (payloadLength <= 0 || payloadLength > capacity) {
      throw const ToolboxSteganographyException(
        'Hidden image payload is damaged or incomplete.',
      );
    }
    final payloadSeed = _positionSeed(
      locatorSecret: locatorSecret,
      purpose: slot == null ? 'image-payload' : 'image-payload-slot-$slot',
      width: image.width,
      height: image.height,
      nonce: nonce,
    );
    final payloadPositions = slot == null
        ? _selectPositions(
            total: totalPositions,
            count: payloadLength * 8,
            seed: payloadSeed,
            excluded: <int>{...policyPositions, ...headerPositions},
          )
        : _selectSlotPositions(
            total: totalPositions,
            count: payloadLength * 8,
            seed: payloadSeed,
            slot: slot,
            excluded: <int>{...policyPositions, ...headerPositions},
          );
    return _ImageBlockReadResult(
      block: _readLsbBytesAtPositions(
        image,
        byteCount: payloadLength,
        positions: payloadPositions,
      ),
      headerPositions: headerPositions,
      payloadPositions: payloadPositions,
      policyPositions: policyPositions,
      slot: slot,
    );
  }

  bool _clearRandomizedLsbBlock(
    img.Image image, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final policyPositions = _imagePolicyPositions(
      image,
      headerLength: _imagePolicyHeaderLength,
    );
    final errors = <Object>[];
    final candidates = _imageLocatorReadCandidates(
      image,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      policyPositions: policyPositions,
      includeLegacyCandidates: false,
    );
    for (final candidate in candidates) {
      final locatorSecret = _locatorSecret(
        passphrase,
        keyFileBytes,
        algorithm: candidate.algorithm,
        strength: candidate.strength,
        salt: candidate.salt,
      );
      try {
        return _clearRandomizedLsbBlockWithPolicyReservation(
          image,
          locatorSecret: locatorSecret,
          policyPositions: policyPositions,
        );
      } on Object catch (error) {
        errors.add(error);
      }
    }
    final last = errors.isEmpty ? null : errors.last;
    if (last is ToolboxSteganographyException) {
      throw last;
    }
    throw const ToolboxSteganographyException('No hidden image payload found.');
  }

  bool _clearRandomizedLsbBlockWithPolicyReservation(
    img.Image image, {
    required Uint8List locatorSecret,
    required List<int> policyPositions,
  }) {
    final totalPositions = image.width * image.height * 3;
    final headerPositions = _selectPositions(
      total: totalPositions,
      count: _imageHeaderLength * 8,
      seed: _positionSeed(
        locatorSecret: locatorSecret,
        purpose: 'image-header',
        width: image.width,
        height: image.height,
      ),
      excluded: Set<int>.from(policyPositions),
    );
    final header = _readLsbBytesAtPositions(
      image,
      byteCount: _imageHeaderLength,
      positions: headerPositions,
    );
    final nonce = Uint8List.fromList(
      header.sublist(_imageMagicLength, _imageMagicLength + _imageNonceLength),
    );
    final expectedMagic = _imageMagic(
      locatorSecret: locatorSecret,
      nonce: nonce,
      width: image.width,
      height: image.height,
    );
    if (!_bytesEqual(header.sublist(0, _imageMagicLength), expectedMagic)) {
      throw const ToolboxSteganographyException(
        'No hidden image payload found.',
      );
    }
    final maskedLength = _readUint32(
      header,
      _imageMagicLength + _imageNonceLength,
    );
    final payloadLength =
        maskedLength ^
        _lengthMask(
          locatorSecret: locatorSecret,
          nonce: nonce,
          width: image.width,
          height: image.height,
        );
    final reservedBits = (_imageHeaderLength * 8) + policyPositions.length;
    final capacity = (totalPositions - reservedBits) ~/ 8;
    final clearPositions = <int>[...policyPositions, ...headerPositions];
    if (payloadLength > 0 && payloadLength <= capacity) {
      clearPositions.addAll(
        _selectPositions(
          total: totalPositions,
          count: payloadLength * 8,
          seed: _positionSeed(
            locatorSecret: locatorSecret,
            purpose: 'image-payload',
            width: image.width,
            height: image.height,
            nonce: nonce,
          ),
          excluded: <int>{...policyPositions, ...headerPositions},
        ),
      );
    }
    for (final position in clearPositions) {
      _setLsbAtPosition(image, position, 0);
    }
    return true;
  }

  Uint8List _randomLocatorSalt(
    ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
  ) {
    while (true) {
      final salt = _randomBytes(_locatorSaltLength);
      if (carrierProtectionMode ==
          ToolboxSteganographyCarrierProtectionMode.guarded) {
        return salt;
      }
      if (!_startsWith(salt, _imageOccupancyMagic) &&
          !_startsWith(salt, _imagePolicyMagic)) {
        return salt;
      }
    }
  }

  List<int> _imagePolicyPositions(
    img.Image image, {
    required int headerLength,
  }) {
    final totalPositions = image.width * image.height * 3;
    final count = headerLength * 8;
    if (totalPositions < count) {
      throw const ToolboxSteganographyException('Image is too small.');
    }
    return _selectPositions(
      total: totalPositions,
      count: count,
      seed: _imagePolicyPositionSeed(image),
    );
  }

  void _writeImageLocatorHeader(
    img.Image image, {
    required Uint8List locatorSalt,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
    required List<int> positions,
  }) {
    if (locatorSalt.length != _locatorSaltLength) {
      throw const ToolboxSteganographyException(
        'Crypto KDF parameters are invalid.',
      );
    }
    _writeLsbBytesAtPositions(
      image,
      _buildImageLocatorHeader(
        locatorSalt,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
        carrierProtectionMode: carrierProtectionMode,
      ),
      positions,
    );
  }

  Uint8List _buildImageLocatorHeader(
    Uint8List locatorSalt, {
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
  }) {
    final hint = _maskedLocatorSettingsHintByte(
      locatorSalt: locatorSalt,
      settings: _LocatorSettings(
        algorithm: locatorAlgorithm,
        strength: locatorStrength,
      ),
    );
    if (carrierProtectionMode ==
        ToolboxSteganographyCarrierProtectionMode.guarded) {
      return Uint8List.fromList(<int>[
        ..._imageOccupancyMagic,
        ...locatorSalt,
        hint,
      ]);
    }
    return Uint8List.fromList(<int>[
      ...locatorSalt,
      hint,
      ..._randomBytes(_imagePolicyHeaderLength - _locatorSaltLength - 1),
    ]);
  }

  Uint8List _randomMediaLocatorSalt(
    ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
  ) {
    while (true) {
      final salt = _randomBytes(_locatorSaltLength);
      if (carrierProtectionMode ==
          ToolboxSteganographyCarrierProtectionMode.guarded) {
        return salt;
      }
      if (!_startsWith(salt, _mediaOccupancyMagic) &&
          !_startsWith(salt, _mediaPolicyMagic)) {
        return salt;
      }
    }
  }

  Uint8List _buildMediaLocatorHeader(
    Uint8List locatorSalt, {
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required ToolboxSteganographyCarrierProtectionMode carrierProtectionMode,
  }) {
    if (locatorSalt.length != _locatorSaltLength) {
      throw const ToolboxSteganographyException(
        'Crypto KDF parameters are invalid.',
      );
    }
    final hint = _maskedLocatorSettingsHintByte(
      locatorSalt: locatorSalt,
      settings: _LocatorSettings(
        algorithm: locatorAlgorithm,
        strength: locatorStrength,
      ),
    );
    if (carrierProtectionMode ==
        ToolboxSteganographyCarrierProtectionMode.guarded) {
      return Uint8List.fromList(<int>[
        ..._mediaOccupancyMagic,
        ...locatorSalt,
        hint,
      ]);
    }
    return Uint8List.fromList(<int>[
      ...locatorSalt,
      hint,
      ..._randomBytes(_mediaPolicyHeaderLength - _locatorSaltLength - 1),
    ]);
  }

  List<_ImageLocatorCandidate> _mediaLocatorReadCandidates(
    Uint8List header, {
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final salt = _mediaLocatorSaltFromHeader(header);
    if (salt == null) {
      return const <_ImageLocatorCandidate>[];
    }
    return <_ImageLocatorCandidate>[
      _ImageLocatorCandidate(
        algorithm: locatorAlgorithm,
        strength: locatorStrength,
        salt: salt,
      ),
    ];
  }

  Uint8List? _mediaLocatorSaltFromHeader(Uint8List header) {
    if (header.length != _mediaPolicyHeaderLength) {
      return null;
    }
    if (_startsWith(header, _mediaOccupancyMagic)) {
      final saltStart = _mediaOccupancyMagic.length;
      final saltEnd = saltStart + _locatorSaltLength;
      final salt = Uint8List.fromList(header.sublist(saltStart, saltEnd));
      if (salt.every((byte) => byte == 0)) {
        return null;
      }
      return salt;
    }
    if (_startsWith(header, _mediaPolicyMagic)) {
      return null;
    }
    final salt = Uint8List.fromList(header.sublist(0, _locatorSaltLength));
    if (salt.every((byte) => byte == 0)) {
      return null;
    }
    return salt;
  }

  Uint8List _imagePolicyPositionSeed(img.Image image) {
    final builder = BytesBuilder(copy: false)
      ..add(utf8.encode('vocabulary_sleep_stego_public_policy_positions_v2'))
      ..addByte(0)
      ..add(_uint32Bytes(image.width))
      ..add(_uint32Bytes(image.height))
      ..addByte(0);
    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        builder
          ..addByte(pixel.r.toInt() & 0xfe)
          ..addByte(pixel.g.toInt() & 0xfe)
          ..addByte(pixel.b.toInt() & 0xfe)
          ..addByte(pixel.a.toInt());
      }
    }
    return Uint8List.fromList(sha256.convert(builder.takeBytes()).bytes);
  }

  Uint8List _buildImageHeader({
    required Uint8List locatorSecret,
    required Uint8List nonce,
    required int payloadLength,
    required int width,
    required int height,
  }) {
    final maskedLength =
        payloadLength ^
        _lengthMask(
          locatorSecret: locatorSecret,
          nonce: nonce,
          width: width,
          height: height,
        );
    return Uint8List.fromList(<int>[
      ..._imageMagic(
        locatorSecret: locatorSecret,
        nonce: nonce,
        width: width,
        height: height,
      ),
      ...nonce,
      ..._uint32Bytes(maskedLength),
    ]);
  }

  Uint8List _locatorSecret(
    String passphrase,
    Uint8List? keyFileBytes, {
    required ToolboxSteganographyLocatorAlgorithm algorithm,
    required ToolboxSteganographyLocatorStrength strength,
    Uint8List? salt,
  }) {
    if (salt != null) {
      try {
        return _cryptoService.deriveSteganographyLocatorSecret(
          passphrase: passphrase,
          keyFileBytes: keyFileBytes,
          salt: salt,
          strength: strength.cryptoStrength,
          purpose: 'stego-${algorithm.id}-${strength.id}-locator-v5',
          length: algorithm == ToolboxSteganographyLocatorAlgorithm.sha512
              ? 64
              : 32,
        );
      } on ToolboxCryptoException catch (error) {
        throw ToolboxSteganographyException(error.message);
      }
    }
    final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
    final passphraseDigest = _locatorDigest(
      passphraseBytes,
      algorithm: algorithm,
      strength: strength,
      purpose: 'passphrase',
    );
    final saltDigest = _locatorDigest(
      Uint8List.fromList(utf8.encode('vocabulary_sleep_stego_v4_locator_salt')),
      algorithm: algorithm,
      strength: strength,
      purpose: 'salt',
    );
    final interleaved = <int>[];
    for (var index = 0; index < passphraseDigest.length; index += 1) {
      interleaved
        ..add(passphraseDigest[index])
        ..add(saltDigest[(index * 5) % saltDigest.length]);
    }
    final keyFileDigest = (keyFileBytes == null || keyFileBytes.isEmpty)
        ? <int>[]
        : _locatorDigest(
            keyFileBytes,
            algorithm: algorithm,
            strength: strength,
            purpose: 'key-file',
          );
    return _locatorDigest(
      Uint8List.fromList(<int>[
        ...utf8.encode('vocabulary_sleep_stego_locator_v4'),
        0,
        ...utf8.encode(algorithm.id),
        0,
        ...utf8.encode(strength.id),
        0,
        ...passphraseDigest,
        0,
        ...interleaved,
        0,
        ...passphraseBytes,
        0,
        ...keyFileDigest,
      ]),
      algorithm: algorithm,
      strength: strength,
      purpose: 'locator-secret',
    );
  }

  Uint8List _locatorDigest(
    Uint8List input, {
    required ToolboxSteganographyLocatorAlgorithm algorithm,
    required ToolboxSteganographyLocatorStrength strength,
    required String purpose,
  }) {
    var state = Uint8List.fromList(input);
    for (var round = 0; round < strength.rounds; round += 1) {
      final bytes = <int>[
        ...utf8.encode('vocabulary_sleep_stego_locator_digest_v1'),
        0,
        ...utf8.encode(algorithm.id),
        0,
        ...utf8.encode(purpose),
        0,
        ..._uint32Bytes(round),
        0,
        ...state,
      ];
      state = switch (algorithm) {
        ToolboxSteganographyLocatorAlgorithm.sha256 => Uint8List.fromList(
          sha256.convert(bytes).bytes,
        ),
        ToolboxSteganographyLocatorAlgorithm.sha512 => Uint8List.fromList(
          sha512.convert(bytes).bytes,
        ),
      };
    }
    return state;
  }

  Uint8List _imageMagic({
    required Uint8List locatorSecret,
    required Uint8List nonce,
    required int width,
    required int height,
  }) {
    return Uint8List.fromList(
      sha256
          .convert(<int>[
            ...locatorSecret,
            0,
            ...nonce,
            0,
            ..._uint32Bytes(width),
            ..._uint32Bytes(height),
            0,
            ...utf8.encode('image-magic'),
          ])
          .bytes
          .sublist(0, _imageMagicLength),
    );
  }

  int _lengthMask({
    required Uint8List locatorSecret,
    required Uint8List nonce,
    required int width,
    required int height,
  }) {
    final digest = sha256.convert(<int>[
      ...locatorSecret,
      0,
      ...nonce,
      0,
      ..._uint32Bytes(width),
      ..._uint32Bytes(height),
      0,
      ...utf8.encode('image-length'),
    ]).bytes;
    return _readUint32(digest, 0);
  }

  Uint8List _positionSeed({
    required Uint8List locatorSecret,
    required String purpose,
    required int width,
    required int height,
    Uint8List? nonce,
  }) {
    return Uint8List.fromList(
      sha256.convert(<int>[
        ...locatorSecret,
        0,
        ...utf8.encode(purpose),
        0,
        ..._uint32Bytes(width),
        ..._uint32Bytes(height),
        0,
        ...?nonce,
      ]).bytes,
    );
  }

  List<int> _selectPositions({
    required int total,
    required int count,
    required Uint8List seed,
    Set<int>? excluded,
  }) {
    final unavailable = excluded == null ? <int>{} : Set<int>.from(excluded);
    if (count < 0 || count > total - unavailable.length) {
      throw const ToolboxSteganographyException(
        'Hidden image payload is damaged or incomplete.',
      );
    }
    final rng = _HmacSha256Csprng(seed);
    final positions = <int>[];
    final maxAttempts = math.max(256, count * 8);
    var attempts = 0;
    while (positions.length < count && attempts < maxAttempts) {
      attempts += 1;
      final candidate = rng.nextInt(total);
      if (unavailable.add(candidate)) {
        positions.add(candidate);
      }
    }
    if (positions.length == count) {
      return positions;
    }

    final remaining = <int>[];
    for (var index = 0; index < total; index += 1) {
      if (!unavailable.contains(index)) {
        remaining.add(index);
      }
    }
    for (var index = remaining.length - 1; index > 0; index -= 1) {
      final swapIndex = rng.nextInt(index + 1);
      final temp = remaining[index];
      remaining[index] = remaining[swapIndex];
      remaining[swapIndex] = temp;
    }
    positions.addAll(remaining.take(count - positions.length));
    return positions;
  }

  int _imageSlotCapacity({
    required int totalPositions,
    required List<int> policyPositions,
    required int slot,
  }) {
    final slotPositions = (totalPositions + (slot == 0 ? 1 : 0)) ~/ 2;
    final reservedPolicy = policyPositions
        .where((position) => position.isEven == (slot == 0))
        .length;
    return (slotPositions - reservedPolicy - (_imageHeaderLength * 8)) ~/ 8;
  }

  List<int> _selectSlotPositions({
    required int total,
    required int count,
    required Uint8List seed,
    required int slot,
    Set<int>? excluded,
  }) {
    final unavailable = excluded == null ? <int>{} : Set<int>.from(excluded);
    final candidates = <int>[];
    for (var position = slot; position < total; position += 2) {
      if (!unavailable.contains(position)) {
        candidates.add(position);
      }
    }
    if (count < 0 || count > candidates.length) {
      throw const ToolboxSteganographyException(
        'Hidden image payload is damaged or incomplete.',
      );
    }
    final rng = _HmacSha256Csprng(seed);
    final positions = <int>[];
    final usedIndexes = <int>{};
    final maxAttempts = math.max(256, count * 8);
    var attempts = 0;
    while (positions.length < count && attempts < maxAttempts) {
      attempts += 1;
      final index = rng.nextInt(candidates.length);
      if (usedIndexes.add(index)) {
        positions.add(candidates[index]);
      }
    }
    if (positions.length == count) {
      return positions;
    }
    final remaining = <int>[];
    for (var index = 0; index < candidates.length; index += 1) {
      if (!usedIndexes.contains(index)) {
        remaining.add(candidates[index]);
      }
    }
    for (var index = remaining.length - 1; index > 0; index -= 1) {
      final swapIndex = rng.nextInt(index + 1);
      final temp = remaining[index];
      remaining[index] = remaining[swapIndex];
      remaining[swapIndex] = temp;
    }
    positions.addAll(remaining.take(count - positions.length));
    return positions;
  }

  void _writeLsbBytesAtPositions(
    img.Image image,
    Uint8List bytes,
    List<int> positions,
  ) {
    final totalBits = bytes.length * 8;
    if (positions.length < totalBits) {
      throw const ToolboxSteganographyException(
        'Hidden image payload is damaged or incomplete.',
      );
    }
    for (var bitIndex = 0; bitIndex < totalBits; bitIndex += 1) {
      _setLsbAtPosition(image, positions[bitIndex], _bitAt(bytes, bitIndex));
    }
  }

  Uint8List _readLsbBytesAtPositions(
    img.Image image, {
    required int byteCount,
    required List<int> positions,
  }) {
    final totalBits = byteCount * 8;
    if (positions.length < totalBits) {
      throw const ToolboxSteganographyException(
        'Hidden payload is incomplete.',
      );
    }
    final output = Uint8List(byteCount);
    for (var bitIndex = 0; bitIndex < totalBits; bitIndex += 1) {
      output[bitIndex >> 3] |=
          _lsbAtPosition(image, positions[bitIndex]) << (7 - (bitIndex & 7));
    }
    return output;
  }

  void _setLsbAtPosition(img.Image image, int position, int bit) {
    final pixelIndex = position ~/ 3;
    final x = pixelIndex % image.width;
    final y = pixelIndex ~/ image.width;
    final channel = position % 3;
    final pixel = image.getPixel(x, y);
    var r = pixel.r.toInt();
    var g = pixel.g.toInt();
    var b = pixel.b.toInt();
    final a = pixel.a.toInt();
    switch (channel) {
      case 0:
        r = (r & 0xfe) | bit;
      case 1:
        g = (g & 0xfe) | bit;
      case 2:
        b = (b & 0xfe) | bit;
    }
    image.setPixelRgba(x, y, r, g, b, a);
  }

  int _lsbAtPosition(img.Image image, int position) {
    final pixelIndex = position ~/ 3;
    final x = pixelIndex % image.width;
    final y = pixelIndex ~/ image.width;
    final channel = position % 3;
    final pixel = image.getPixel(x, y);
    return switch (channel) {
      0 => pixel.r.toInt() & 1,
      1 => pixel.g.toInt() & 1,
      _ => pixel.b.toInt() & 1,
    };
  }

  int _bitAt(Uint8List bytes, int bitIndex) {
    return (bytes[bitIndex >> 3] >> (7 - (bitIndex & 7))) & 1;
  }

  Uint8List _xorWithSha256Stream(
    Uint8List input,
    Uint8List key,
    Uint8List nonce,
  ) {
    final output = Uint8List(input.length);
    var offset = 0;
    var counter = 0;
    while (offset < input.length) {
      final streamBlock = sha256.convert(<int>[
        ...key,
        ...nonce,
        ..._uint64Bytes(counter),
      ]).bytes;
      for (var i = 0; i < streamBlock.length && offset < input.length; i += 1) {
        output[offset] = input[offset] ^ streamBlock[i];
        offset += 1;
      }
      counter += 1;
    }
    return output;
  }

  Uint8List _rc4(Uint8List input, Uint8List key) {
    final s = List<int>.generate(256, (index) => index);
    var j = 0;
    for (var i = 0; i < 256; i += 1) {
      j = (j + s[i] + key[i % key.length]) & 255;
      final temp = s[i];
      s[i] = s[j];
      s[j] = temp;
    }
    var i = 0;
    j = 0;
    final output = Uint8List(input.length);
    for (var k = 0; k < input.length; k += 1) {
      i = (i + 1) & 255;
      j = (j + s[i]) & 255;
      final temp = s[i];
      s[i] = s[j];
      s[j] = temp;
      output[k] = input[k] ^ s[(s[i] + s[j]) & 255];
    }
    return output;
  }

  ToolboxCryptoDecryptResult _runCryptoDecrypt({
    required Uint8List envelopeBytes,
    required String passphrase,
    required Uint8List? keyFileBytes,
  }) {
    try {
      return _cryptoService.decryptBytes(
        envelopeBytes: envelopeBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
      );
    } on ToolboxCryptoException catch (error) {
      throw ToolboxSteganographyException(error.message);
    }
  }

  Uint8List _legacyDeriveKey(
    String passphrase,
    Uint8List nonce,
    String purpose,
  ) {
    var state = Uint8List.fromList(
      sha256.convert(<int>[
        ...utf8.encode('vocabulary_sleep_steganography_v1'),
        0,
        ...utf8.encode(purpose),
        0,
        ...nonce,
        0,
        ...utf8.encode(passphrase),
      ]).bytes,
    );
    for (var round = 0; round < 4096; round += 1) {
      state = Uint8List.fromList(
        sha256.convert(<int>[
          ...state,
          ...nonce,
          round & 255,
          (round >> 8) & 255,
        ]).bytes,
      );
    }
    return state;
  }

  Uint8List _legacyHmacBytes({
    required String passphrase,
    required Uint8List nonce,
    required String cipherId,
    required Uint8List cipherBytes,
  }) {
    final key = _legacyDeriveKey(passphrase, nonce, 'mac-$cipherId');
    final digest = Hmac(
      sha256,
      key,
    ).convert(<int>[...utf8.encode(cipherId), 0, ...nonce, 0, ...cipherBytes]);
    return Uint8List.fromList(digest.bytes);
  }

  ToolboxCryptoAlgorithm _legacyAlgorithmFromId(String id) {
    return switch (id) {
      'none' => ToolboxCryptoAlgorithm.none,
      'sha256_stream' => ToolboxCryptoAlgorithm.sha256Stream,
      'rc4_legacy' => ToolboxCryptoAlgorithm.rc4Legacy,
      _ => throw const ToolboxSteganographyException(
        'Unsupported encryption algorithm.',
      ),
    };
  }

  Uint8List _uint32Bytes(int value) {
    if (value < 0 || value > 0xffffffff) {
      throw const ToolboxSteganographyException('Payload is too large.');
    }
    return Uint8List.fromList(<int>[
      (value >> 24) & 255,
      (value >> 16) & 255,
      (value >> 8) & 255,
      value & 255,
    ]);
  }

  int _readUint16Little(List<int> bytes, int offset) {
    if (offset < 0 || offset + 2 > bytes.length) {
      throw const ToolboxSteganographyException('Payload length is missing.');
    }
    return bytes[offset] | (bytes[offset + 1] << 8);
  }

  int _readUint32Little(List<int> bytes, int offset) {
    if (offset < 0 || offset + 4 > bytes.length) {
      throw const ToolboxSteganographyException('Payload length is missing.');
    }
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  int _readUint64(List<int> bytes, int offset) {
    if (offset < 0 || offset + 8 > bytes.length) {
      throw const ToolboxSteganographyException('Payload length is missing.');
    }
    var value = 0;
    for (var index = 0; index < 8; index += 1) {
      value = (value << 8) | bytes[offset + index];
    }
    return value;
  }

  static Uint8List _uint64Bytes(int value) {
    return Uint8List.fromList(
      List<int>.generate(8, (index) => (value >> ((7 - index) * 8)) & 255),
    );
  }

  int _readUint32(List<int> bytes, int offset) {
    if (offset < 0 || offset + 4 > bytes.length) {
      throw const ToolboxSteganographyException('Payload length is missing.');
    }
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  bool _startsWith(List<int> bytes, List<int> prefix) {
    return bytes.length >= prefix.length && _rangeEquals(bytes, 0, prefix);
  }

  bool _rangeEquals(List<int> bytes, int offset, List<int> expected) {
    if (offset < 0 || offset + expected.length > bytes.length) {
      return false;
    }
    for (var i = 0; i < expected.length; i += 1) {
      if (bytes[offset + i] != expected[i]) {
        return false;
      }
    }
    return true;
  }

  bool _bytesEqual(List<int> a, List<int> b) {
    var diff = a.length ^ b.length;
    final maxLength = math.max(a.length, b.length);
    for (var index = 0; index < maxLength; index += 1) {
      final left = index < a.length ? a[index] : 0;
      final right = index < b.length ? b[index] : 0;
      diff |= left ^ right;
    }
    return diff == 0;
  }

  Uint8List? _hexToBytes(String value) {
    if (value.length.isOdd) {
      return null;
    }
    final output = Uint8List(value.length ~/ 2);
    for (var index = 0; index < value.length; index += 2) {
      final byte = int.tryParse(value.substring(index, index + 2), radix: 16);
      if (byte == null) {
        return null;
      }
      output[index ~/ 2] = byte;
    }
    return output;
  }

  static String _hexDigest(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _secureRandom.nextInt(256)),
    );
  }

  String _previewBase64(Uint8List bytes) {
    final text = base64Encode(bytes);
    if (text.length <= 96) {
      return text;
    }
    return '${text.substring(0, 96)}...';
  }

  String _carrierDetailForReveal(
    ToolboxSteganographyMediaKind mediaKind,
    Uint8List carrierBytes,
  ) {
    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image =>
        'image ${_formatBytes(carrierBytes.length)}',
      ToolboxSteganographyMediaKind.audio =>
        'audio ${_formatBytes(carrierBytes.length)}',
      ToolboxSteganographyMediaKind.video =>
        'video ${_formatBytes(carrierBytes.length)}',
    };
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }
}

class _EnvelopeBuildResult {
  const _EnvelopeBuildResult({
    required this.jsonBytes,
    required this.cipherPreview,
  });

  final Uint8List jsonBytes;
  final String cipherPreview;
}

class _ImageLocatorCandidate {
  const _ImageLocatorCandidate({
    required this.algorithm,
    required this.strength,
    this.salt,
  });

  final ToolboxSteganographyLocatorAlgorithm algorithm;
  final ToolboxSteganographyLocatorStrength strength;
  final Uint8List? salt;
}

class _LocatorSettings {
  const _LocatorSettings({required this.algorithm, required this.strength});

  final ToolboxSteganographyLocatorAlgorithm algorithm;
  final ToolboxSteganographyLocatorStrength strength;
}

class _ImageWriteCredential {
  const _ImageWriteCredential({required this.passphrase, this.keyFileBytes});

  final String passphrase;
  final Uint8List? keyFileBytes;
}

class _ImageBlockReadResult {
  const _ImageBlockReadResult({
    required this.block,
    required this.headerPositions,
    required this.payloadPositions,
    required this.policyPositions,
    required this.slot,
  });

  final Uint8List block;
  final List<int> headerPositions;
  final List<int> payloadPositions;
  final List<int> policyPositions;
  final int? slot;
}

class _WavCarrierInfo {
  const _WavCarrierInfo({
    required this.dataOffset,
    required this.dataLength,
    required this.channels,
    required this.blockAlign,
    required this.bitsPerSample,
    required this.bytesPerSample,
    required this.sampleCount,
  });

  final int dataOffset;
  final int dataLength;
  final int channels;
  final int blockAlign;
  final int bitsPerSample;
  final int bytesPerSample;
  final int sampleCount;
}

class _WavStegoProfile {
  const _WavStegoProfile({
    required this.usableSamples,
    required this.evenUsableSamples,
    required this.oddUsableSamples,
  });

  final int usableSamples;
  final int evenUsableSamples;
  final int oddUsableSamples;

  int usableSamplesForSlot(int slot) {
    return slot == 0 ? evenUsableSamples : oddUsableSamples;
  }
}

class _AudioBlockReadResult {
  const _AudioBlockReadResult({
    required this.block,
    required this.headerSamples,
    required this.payloadSamples,
    required this.policySamples,
    required this.slot,
  });

  final Uint8List block;
  final List<int> headerSamples;
  final List<int> payloadSamples;
  final List<int> policySamples;
  final int? slot;
}

class _AudioCarrierInfo {
  const _AudioCarrierInfo._({this.wav, this.isoBmff});

  const _AudioCarrierInfo.wav(_WavCarrierInfo wav) : this._(wav: wav);

  const _AudioCarrierInfo.isoBmff(_Mp4CarrierInfo isoBmff)
    : this._(isoBmff: isoBmff);

  final _WavCarrierInfo? wav;
  final _Mp4CarrierInfo? isoBmff;
}

class _Mp4CarrierInfo {
  const _Mp4CarrierInfo({required this.majorBrand, required this.boxes});

  final String? majorBrand;
  final List<_Mp4Box> boxes;
}

class _Mp4FreeRegion {
  const _Mp4FreeRegion({
    required this.offset,
    required this.dataOffset,
    required this.dataLength,
  });

  final int offset;
  final int dataOffset;
  final int dataLength;

  int get dataEnd => dataOffset + dataLength;
}

class _Mp4Box {
  const _Mp4Box({
    required this.offset,
    required this.size,
    required this.type,
    required this.dataOffset,
  });

  final int offset;
  final int size;
  final String type;
  final int dataOffset;

  int get dataLength => size - (dataOffset - offset);
}

class _VideoBlockReadResult {
  const _VideoBlockReadResult({
    required this.block,
    required this.headerOffsets,
    required this.payloadOffsets,
    required this.policyOffsets,
    required this.slot,
  });

  final Uint8List block;
  final List<int> headerOffsets;
  final List<int> payloadOffsets;
  final List<int> policyOffsets;
  final int? slot;
}

class _EnvelopeParseResult {
  const _EnvelopeParseResult({
    required this.text,
    required this.encryption,
    required this.strength,
    required this.cipherPreview,
  });

  final String text;
  final ToolboxCryptoAlgorithm encryption;
  final ToolboxCryptoStrength strength;
  final String cipherPreview;
}

class _FileEnvelopeParseResult {
  const _FileEnvelopeParseResult({
    required this.bytes,
    required this.fileName,
    required this.mediaType,
    required this.encryption,
    required this.strength,
    required this.cipherPreview,
  });

  final Uint8List bytes;
  final String? fileName;
  final String? mediaType;
  final ToolboxCryptoAlgorithm encryption;
  final ToolboxCryptoStrength strength;
  final String cipherPreview;
}

class _HmacSha256Csprng {
  _HmacSha256Csprng(this._seed);

  final Uint8List _seed;
  Uint8List _buffer = Uint8List(0);
  var _offset = 0;
  var _counter = 0;

  int nextInt(int max) {
    if (max <= 0 || max > 0x100000000) {
      throw const ToolboxSteganographyException(
        'Hidden image payload is damaged or incomplete.',
      );
    }
    final bucket = 0x100000000;
    final limit = bucket - (bucket % max);
    while (true) {
      final value = _nextUint32();
      if (value < limit) {
        return value % max;
      }
    }
  }

  int _nextUint32() {
    if (_offset + 4 > _buffer.length) {
      _buffer = Uint8List.fromList(
        Hmac(sha256, _seed).convert(_counterBytes(_counter)).bytes,
      );
      _counter += 1;
      _offset = 0;
    }
    final value =
        (_buffer[_offset] << 24) |
        (_buffer[_offset + 1] << 16) |
        (_buffer[_offset + 2] << 8) |
        _buffer[_offset + 3];
    _offset += 4;
    return value;
  }

  Uint8List _counterBytes(int value) {
    return Uint8List.fromList(
      List<int>.generate(8, (index) => (value >> ((7 - index) * 8)) & 255),
    );
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value!;

  @override
  void add(Digest data) {
    if (_value != null) {
      throw StateError('Digest added more than once.');
    }
    _value = data;
  }

  @override
  void close() {
    if (_value == null) {
      throw StateError('Digest was not added.');
    }
  }
}
