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

class ToolboxSteganographyEmbedResult {
  const ToolboxSteganographyEmbedResult({
    required this.bytes,
    required this.outputExtension,
    required this.payloadBytes,
    required this.sourceBytes,
    required this.outputBytes,
    required this.cipherPreview,
    required this.carrierDetail,
    this.capacityBytes,
  });

  final Uint8List bytes;
  final String outputExtension;
  final int payloadBytes;
  final int sourceBytes;
  final int outputBytes;
  final String cipherPreview;
  final String carrierDetail;
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

class ToolboxSteganographyProtectionPolicy {
  const ToolboxSteganographyProtectionPolicy({
    required this.maxErrorAttempts,
    required this.hasTamperCheck,
    this.remainingSuccessfulReveals = 0,
  });

  final int maxErrorAttempts;
  final bool hasTamperCheck;
  final int remainingSuccessfulReveals;
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

class ToolboxSteganographySuccessfulRevealProtectionResult {
  const ToolboxSteganographySuccessfulRevealProtectionResult({
    required this.bytes,
    required this.outputExtension,
    required this.changed,
    required this.removed,
    required this.remainingSuccessfulReveals,
  });

  final Uint8List bytes;
  final String outputExtension;
  final bool changed;
  final bool removed;
  final int remainingSuccessfulReveals;
}

class ToolboxSteganographyCapacityCheck {
  const ToolboxSteganographyCapacityCheck({
    required this.dualLayer,
    required this.width,
    required this.height,
    required this.capacityBytes,
    required this.requiredBytes,
    required this.minimumPixels,
    this.perLayerCapacityBytes,
    this.coverRequiredBytes,
    this.hiddenRequiredBytes,
  });

  final bool dualLayer;
  final int width;
  final int height;
  final int capacityBytes;
  final int requiredBytes;
  final int minimumPixels;
  final int? perLayerCapacityBytes;
  final int? coverRequiredBytes;
  final int? hiddenRequiredBytes;

  bool get fits {
    if (!dualLayer) {
      return requiredBytes <= capacityBytes;
    }
    final layerCapacity = perLayerCapacityBytes ?? 0;
    return (coverRequiredBytes ?? 0) <= layerCapacity &&
        (hiddenRequiredBytes ?? 0) <= layerCapacity;
  }
}

class ToolboxSteganographyService {
  static final List<int> _managedBlockMagic = ascii.encode('VSSG3');
  static const int maxExtensionLength = 12;
  static const int maxImageCarrierBytes = 128 * 1024 * 1024;
  static const int maxImagePixels = 24 * 1000 * 1000;
  static const int maxTailCarrierBytes = 512 * 1024 * 1024;
  static const int maxEmbeddedCryptoEnvelopeBytes =
      ToolboxCryptoService.maxEnvelopeBytes;
  static final List<int> _blockMagic = ascii.encode('VSSG1');
  static final List<int> _protectedBlockMagic = ascii.encode('VSSG2');
  static final List<int> _tailMagic = ascii.encode('VSSGT1');
  static final List<int> _imagePolicyMagic = ascii.encode('VSSGP2');
  static const int _protectedBlockTailLength = 16;
  static const int _imageMagicLength = 16;
  static const int _imageNonceLength = 16;
  static const int _imageHeaderLength =
      _imageMagicLength + _imageNonceLength + 4;
  static const int _imagePolicyChecksumLength = 16;
  static const int _imagePolicyHeaderLength = 23;
  static final math.Random _secureRandom = math.Random.secure();
  final ToolboxCryptoService _cryptoService = ToolboxCryptoService();

  static String? cleanExtension(String? extension) {
    final value = extension?.replaceFirst('.', '').trim().toLowerCase();
    if (value == null || value.isEmpty || value.length > maxExtensionLength) {
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return cleaned.isEmpty ? null : cleaned;
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
    int maxErrorAttempts = 0,
    int maxSuccessfulReveals = 0,
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
      if (mediaKind != ToolboxSteganographyMediaKind.image) {
        throw const ToolboxSteganographyException(
          'Dual-layer mode currently supports image carriers only.',
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
    _validateMediaWriteBackend(mediaKind);
    _validateMaxErrorAttempts(maxErrorAttempts);
    _validateMaxSuccessfulReveals(maxSuccessfulReveals);
    _ensureCarrierIsWritable(mediaKind: mediaKind, carrierBytes: carrierBytes);

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
        maxErrorAttempts: maxErrorAttempts,
        maxSuccessfulReveals: maxSuccessfulReveals,
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
        maxErrorAttempts: maxErrorAttempts,
        maxSuccessfulReveals: maxSuccessfulReveals,
      );
      return _checkDualImageCapacity(
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
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
    );
    return _checkSingleImageCapacity(
      carrierBytes: carrierBytes,
      requiredBytes: requiredBytes,
    );
  }

  ToolboxSteganographyCapacityCheck checkFileWriteCapacity({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required Uint8List fileBytes,
    required ToolboxCryptoAlgorithm encryption,
    required String passphrase,
    ToolboxCryptoStrength strength = ToolboxCryptoStrength.standard,
    Uint8List? keyFileBytes,
    String? fileName,
    String? mediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
    int maxErrorAttempts = 0,
    int maxSuccessfulReveals = 0,
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
    _validateMediaWriteBackend(mediaKind);
    _validateMaxErrorAttempts(maxErrorAttempts);
    _validateMaxSuccessfulReveals(maxSuccessfulReveals);
    _ensureCarrierIsWritable(mediaKind: mediaKind, carrierBytes: carrierBytes);

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
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
    );
    return _checkSingleImageCapacity(
      carrierBytes: carrierBytes,
      requiredBytes: requiredBytes,
    );
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
    int maxErrorAttempts = 0,
    int maxSuccessfulReveals = 0,
    ToolboxSteganographyLocatorAlgorithm locatorAlgorithm =
        ToolboxSteganographyLocatorAlgorithm.sha256,
    ToolboxSteganographyLocatorStrength locatorStrength =
        ToolboxSteganographyLocatorStrength.standard,
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
    _validateMediaWriteBackend(mediaKind);
    _validateMaxErrorAttempts(maxErrorAttempts);
    _validateMaxSuccessfulReveals(maxSuccessfulReveals);
    _ensureCarrierIsWritable(mediaKind: mediaKind, carrierBytes: carrierBytes);

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
    final block = _buildBlock(
      envelope.jsonBytes,
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
    );

    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _embedInImage(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _embedInTail(
        mediaKind: mediaKind,
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
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
    int maxErrorAttempts = 0,
    int maxSuccessfulReveals = 0,
    ToolboxSteganographyLocatorAlgorithm locatorAlgorithm =
        ToolboxSteganographyLocatorAlgorithm.sha256,
    ToolboxSteganographyLocatorStrength locatorStrength =
        ToolboxSteganographyLocatorStrength.standard,
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
    _validateMediaWriteBackend(mediaKind);
    _validateMaxErrorAttempts(maxErrorAttempts);
    _validateMaxSuccessfulReveals(maxSuccessfulReveals);
    _ensureCarrierIsWritable(mediaKind: mediaKind, carrierBytes: carrierBytes);

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
    final coverBlock = _buildBlock(
      coverEnvelope.jsonBytes,
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
    );
    final hiddenBlock = _buildBlock(
      hiddenEnvelope.jsonBytes,
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
    );

    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _embedDualTextInImage(
        carrierBytes: carrierBytes,
        coverBlock: coverBlock,
        hiddenBlock: hiddenBlock,
        hiddenEnvelope: hiddenEnvelope,
        coverPassphrase: coverPassphrase,
        hiddenPassphrase: hiddenPassphrase,
        hiddenKeyFileBytes: hiddenKeyFileBytes,
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video =>
        throw const ToolboxSteganographyException(
          'Dual-layer mode currently supports image carriers only.',
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
    int maxErrorAttempts = 0,
    int maxSuccessfulReveals = 0,
    ToolboxSteganographyLocatorAlgorithm locatorAlgorithm =
        ToolboxSteganographyLocatorAlgorithm.sha256,
    ToolboxSteganographyLocatorStrength locatorStrength =
        ToolboxSteganographyLocatorStrength.standard,
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
    _validateMediaWriteBackend(mediaKind);
    _validateMaxErrorAttempts(maxErrorAttempts);
    _validateMaxSuccessfulReveals(maxSuccessfulReveals);
    _ensureCarrierIsWritable(mediaKind: mediaKind, carrierBytes: carrierBytes);

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
    final block = _buildBlock(
      envelope.jsonBytes,
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
    );

    return switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _embedInImage(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _embedInTail(
        mediaKind: mediaKind,
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
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
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _extractTailBlock(carrierBytes),
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
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _extractTailBlock(carrierBytes),
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

  ToolboxSteganographyProtectionPolicy inspectProtectionPolicy({
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
    if (mediaKind == ToolboxSteganographyMediaKind.image) {
      final publicPolicy = _inspectImagePolicyHeader(carrierBytes);
      if (publicPolicy != null) {
        return publicPolicy;
      }
    }
    final block = switch (mediaKind) {
      ToolboxSteganographyMediaKind.image => _extractImageBlock(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _extractTailBlock(carrierBytes),
    };
    return _readBlockPolicy(block);
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
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _stripTailPayload(
        carrierBytes,
        mediaKind: mediaKind,
      ),
    };
  }

  ToolboxSteganographySuccessfulRevealProtectionResult
  applySuccessfulRevealProtection({
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
      ToolboxSteganographyMediaKind.image =>
        _applySuccessfulImageRevealProtection(
          carrierBytes,
          passphrase: passphrase,
          keyFileBytes: keyFileBytes,
          locatorAlgorithm: locatorAlgorithm,
          locatorStrength: locatorStrength,
        ),
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video =>
        _applySuccessfulTailRevealProtection(
          carrierBytes,
          mediaKind: mediaKind,
        ),
    };
  }

  void _validateMediaWriteBackend(ToolboxSteganographyMediaKind mediaKind) {
    switch (mediaKind) {
      case ToolboxSteganographyMediaKind.image:
        return;
      case ToolboxSteganographyMediaKind.audio:
        throw const ToolboxSteganographyException(
          'Audio steganography requires a frequency-domain backend before new payloads can be generated.',
        );
      case ToolboxSteganographyMediaKind.video:
        throw const ToolboxSteganographyException(
          'Video steganography requires a frame-level or motion-vector backend before new payloads can be generated.',
        );
    }
  }

  void _validateMaxErrorAttempts(int value) {
    if (value < 0 || value > 255) {
      throw const ToolboxSteganographyException(
        'Max error attempts must be between 0 and 255.',
      );
    }
  }

  void _validateMaxSuccessfulReveals(int value) {
    if (value < 0 || value > 255) {
      throw const ToolboxSteganographyException(
        'Max successful reveals must be between 0 and 255.',
      );
    }
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

  img.Image? _tryDecodeCarrierImage(Uint8List carrierBytes) {
    if (carrierBytes.length > maxImageCarrierBytes) {
      throw const ToolboxSteganographyException('Image file is too large.');
    }
    final decoded = img.decodeImage(carrierBytes);
    if (decoded == null) {
      return null;
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

  void _ensureCarrierIsWritable({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
  }) {
    final occupied = switch (mediaKind) {
      ToolboxSteganographyMediaKind.image =>
        _inspectImagePolicyHeader(carrierBytes) != null,
      ToolboxSteganographyMediaKind.audio ||
      ToolboxSteganographyMediaKind.video => _hasTailPayload(carrierBytes),
    };
    if (occupied) {
      throw const ToolboxSteganographyException(
        'Carrier already contains hidden data. Use the original carrier, clear the hidden data, or embed the encrypted file as a new payload.',
      );
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
      width: image.width,
      height: image.height,
      capacityBytes: capacity,
      requiredBytes: requiredBytes,
      minimumPixels: _minimumSingleLayerPixels(requiredBytes),
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
      width: image.width,
      height: image.height,
      capacityBytes: coverCapacity + hiddenCapacity,
      requiredBytes: requiredBytes,
      perLayerCapacityBytes: perLayerCapacity,
      coverRequiredBytes: coverRequiredBytes,
      hiddenRequiredBytes: hiddenRequiredBytes,
      minimumPixels: _minimumDualLayerPixels(requiredBytes),
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
    required int maxErrorAttempts,
    required int maxSuccessfulReveals,
  }) {
    _validateMaxErrorAttempts(maxErrorAttempts);
    _validateMaxSuccessfulReveals(maxSuccessfulReveals);
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
    return _managedBlockMagic.length +
        2 +
        4 +
        jsonBytes +
        _protectedBlockTailLength;
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
    required int maxErrorAttempts,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
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

    final stegoImage = img.Image.from(image);
    _writeRandomizedLsbBlock(
      stegoImage,
      block,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      maxErrorAttempts: maxErrorAttempts,
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
    required int maxErrorAttempts,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
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

    final stegoImage = img.Image.from(image);
    _writeRandomizedLsbBlockInSlot(
      stegoImage,
      hiddenBlock,
      passphrase: hiddenPassphrase,
      keyFileBytes: hiddenKeyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
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
      slot: 1,
      policyPositions: policyPositions,
    );
    _writeImagePolicyHeader(
      stegoImage,
      maxErrorAttempts: maxErrorAttempts,
      positions: policyPositions,
    );
    final output = Uint8List.fromList(img.encodePng(stegoImage, level: 6));
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: 'png',
      payloadBytes: coverBlock.length + hiddenBlock.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: hiddenEnvelope.cipherPreview,
      carrierDetail:
          '${image.width}x${image.height}, dual-layer randomized LSB capacity ${_formatBytes(math.min(coverCapacity, hiddenCapacity))} per layer',
      capacityBytes: coverCapacity + hiddenCapacity,
    );
  }

  ToolboxSteganographyEmbedResult _embedInTail({
    required ToolboxSteganographyMediaKind mediaKind,
    required Uint8List carrierBytes,
    required Uint8List block,
    required _EnvelopeBuildResult envelope,
    String? sourceExtension,
  }) {
    _validateTailCarrierSize(carrierBytes);
    final output = Uint8List(
      carrierBytes.length + block.length + 4 + _tailMagic.length,
    );
    var offset = 0;
    output.setRange(offset, offset + carrierBytes.length, carrierBytes);
    offset += carrierBytes.length;
    output.setRange(offset, offset + block.length, block);
    offset += block.length;
    output.setRange(offset, offset + 4, _uint32Bytes(block.length));
    offset += 4;
    output.setRange(offset, offset + _tailMagic.length, _tailMagic);

    final fallbackExtension = mediaKind == ToolboxSteganographyMediaKind.audio
        ? 'wav'
        : 'mp4';
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: cleanExtension(sourceExtension) ?? fallbackExtension,
      payloadBytes: block.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail: 'tail payload +${_formatBytes(block.length)}',
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

  Uint8List _extractTailBlock(Uint8List carrierBytes) {
    final tailInfo = _tailBlockRange(carrierBytes);
    if (tailInfo == null) {
      throw const ToolboxSteganographyException('No hidden payload found.');
    }
    return Uint8List.fromList(
      carrierBytes.sublist(tailInfo.offset, tailInfo.offset + tailInfo.length),
    );
  }

  bool _hasTailPayload(Uint8List carrierBytes) {
    return _tailBlockRange(carrierBytes) != null;
  }

  _TailBlockRange? _tailBlockRange(Uint8List carrierBytes) {
    _validateTailCarrierSize(carrierBytes);
    final minimum = _tailMagic.length + 4 + _blockMagic.length + 4;
    if (carrierBytes.length < minimum) {
      return null;
    }
    final magicOffset = carrierBytes.length - _tailMagic.length;
    if (!_rangeEquals(carrierBytes, magicOffset, _tailMagic)) {
      return null;
    }
    final lengthOffset = magicOffset - 4;
    final blockLength = _readUint32(carrierBytes, lengthOffset);
    final blockOffset = lengthOffset - blockLength;
    if (blockLength <= 0 || blockOffset < 0) {
      throw const ToolboxSteganographyException(
        'Hidden payload is damaged or incomplete.',
      );
    }
    return _TailBlockRange(offset: blockOffset, length: blockLength);
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
      if (_readImagePolicyHeader(image) != null) {
        _clearAllImageLsbs(stegoImage);
        removed = true;
      }
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

  ToolboxSteganographySanitizeResult _clearImageSlotPayload(
    img.Image image,
    _ImageBlockReadResult read,
  ) {
    final stegoImage = img.Image.from(image);
    for (final position in <int>[
      ...read.headerPositions,
      ...read.payloadPositions,
    ]) {
      _setLsbAtPosition(stegoImage, position, 0);
    }
    return ToolboxSteganographySanitizeResult(
      bytes: Uint8List.fromList(img.encodePng(stegoImage, level: 6)),
      outputExtension: 'png',
      removed: true,
    );
  }

  ToolboxSteganographySuccessfulRevealProtectionResult
  _applySuccessfulImageRevealProtection(
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
    final read = _readAnyRandomizedLsbBlockDetails(
      image,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    );
    final policy = _readBlockPolicy(read.block);
    final remaining = policy.remainingSuccessfulReveals;
    if (remaining <= 0) {
      return ToolboxSteganographySuccessfulRevealProtectionResult(
        bytes: Uint8List.fromList(carrierBytes),
        outputExtension: 'png',
        changed: false,
        removed: false,
        remainingSuccessfulReveals: 0,
      );
    }
    if (remaining == 1) {
      final stripped = read.slot == null
          ? _stripImagePayload(
              carrierBytes,
              passphrase: passphrase,
              keyFileBytes: keyFileBytes,
              locatorAlgorithm: locatorAlgorithm,
              locatorStrength: locatorStrength,
            )
          : _clearImageSlotPayload(image, read);
      return ToolboxSteganographySuccessfulRevealProtectionResult(
        bytes: stripped.bytes,
        outputExtension: stripped.outputExtension,
        changed: stripped.removed,
        removed: stripped.removed,
        remainingSuccessfulReveals: 0,
      );
    }
    final updatedBlock = _managedBlockWithSuccessfulRevealCount(
      read.block,
      remaining - 1,
    );
    final stegoImage = img.Image.from(image);
    _writeLsbBytesAtPositions(stegoImage, updatedBlock, read.payloadPositions);
    return ToolboxSteganographySuccessfulRevealProtectionResult(
      bytes: Uint8List.fromList(img.encodePng(stegoImage, level: 6)),
      outputExtension: 'png',
      changed: true,
      removed: false,
      remainingSuccessfulReveals: remaining - 1,
    );
  }

  ToolboxSteganographySanitizeResult _stripTailPayload(
    Uint8List carrierBytes, {
    required ToolboxSteganographyMediaKind mediaKind,
  }) {
    final fallbackExtension = mediaKind == ToolboxSteganographyMediaKind.audio
        ? 'wav'
        : 'mp4';
    final minimum = _tailMagic.length + 4 + _blockMagic.length + 4;
    if (carrierBytes.length < minimum) {
      return ToolboxSteganographySanitizeResult(
        bytes: Uint8List.fromList(carrierBytes),
        outputExtension: fallbackExtension,
        removed: false,
      );
    }
    final magicOffset = carrierBytes.length - _tailMagic.length;
    if (!_rangeEquals(carrierBytes, magicOffset, _tailMagic)) {
      return ToolboxSteganographySanitizeResult(
        bytes: Uint8List.fromList(carrierBytes),
        outputExtension: fallbackExtension,
        removed: false,
      );
    }
    final lengthOffset = magicOffset - 4;
    final blockLength = _readUint32(carrierBytes, lengthOffset);
    final blockOffset = lengthOffset - blockLength;
    if (blockLength <= 0 || blockOffset < 0) {
      throw const ToolboxSteganographyException(
        'Hidden payload is damaged or incomplete.',
      );
    }
    return ToolboxSteganographySanitizeResult(
      bytes: Uint8List.fromList(carrierBytes.sublist(0, blockOffset)),
      outputExtension: fallbackExtension,
      removed: true,
    );
  }

  ToolboxSteganographySuccessfulRevealProtectionResult
  _applySuccessfulTailRevealProtection(
    Uint8List carrierBytes, {
    required ToolboxSteganographyMediaKind mediaKind,
  }) {
    final fallbackExtension = mediaKind == ToolboxSteganographyMediaKind.audio
        ? 'wav'
        : 'mp4';
    final tailInfo = _tailBlockRange(carrierBytes);
    if (tailInfo == null) {
      throw const ToolboxSteganographyException('No hidden payload found.');
    }
    final block = Uint8List.fromList(
      carrierBytes.sublist(tailInfo.offset, tailInfo.offset + tailInfo.length),
    );
    final policy = _readBlockPolicy(block);
    final remaining = policy.remainingSuccessfulReveals;
    if (remaining <= 0) {
      return ToolboxSteganographySuccessfulRevealProtectionResult(
        bytes: Uint8List.fromList(carrierBytes),
        outputExtension: fallbackExtension,
        changed: false,
        removed: false,
        remainingSuccessfulReveals: 0,
      );
    }
    if (remaining == 1) {
      final stripped = _stripTailPayload(carrierBytes, mediaKind: mediaKind);
      return ToolboxSteganographySuccessfulRevealProtectionResult(
        bytes: stripped.bytes,
        outputExtension: stripped.outputExtension,
        changed: stripped.removed,
        removed: stripped.removed,
        remainingSuccessfulReveals: 0,
      );
    }
    final updatedBlock = _managedBlockWithSuccessfulRevealCount(
      block,
      remaining - 1,
    );
    final output = Uint8List.fromList(carrierBytes);
    output.setRange(
      tailInfo.offset,
      tailInfo.offset + updatedBlock.length,
      updatedBlock,
    );
    return ToolboxSteganographySuccessfulRevealProtectionResult(
      bytes: output,
      outputExtension: fallbackExtension,
      changed: true,
      removed: false,
      remainingSuccessfulReveals: remaining - 1,
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

  Uint8List _buildBlock(
    Uint8List jsonBytes, {
    required int maxErrorAttempts,
    required int maxSuccessfulReveals,
  }) {
    _validateMaxErrorAttempts(maxErrorAttempts);
    _validateMaxSuccessfulReveals(maxSuccessfulReveals);
    final prefix = BytesBuilder(copy: false)
      ..add(_managedBlockMagic)
      ..addByte(maxErrorAttempts)
      ..addByte(maxSuccessfulReveals)
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

  ToolboxSteganographyProtectionPolicy _readBlockPolicy(Uint8List block) {
    if (_startsWith(block, _managedBlockMagic)) {
      _protectedBlockJsonBytes(block);
      return ToolboxSteganographyProtectionPolicy(
        maxErrorAttempts: block[_managedBlockMagic.length],
        hasTamperCheck: true,
        remainingSuccessfulReveals: block[_managedBlockMagic.length + 1],
      );
    }
    if (_startsWith(block, _protectedBlockMagic)) {
      _protectedBlockJsonBytes(block);
      return ToolboxSteganographyProtectionPolicy(
        maxErrorAttempts: block[_protectedBlockMagic.length],
        hasTamperCheck: true,
      );
    }
    if (_startsWith(block, _blockMagic)) {
      _legacyBlockJsonBytes(block);
    } else {
      jsonDecode(utf8.decode(block));
    }
    return const ToolboxSteganographyProtectionPolicy(
      maxErrorAttempts: 0,
      hasTamperCheck: false,
    );
  }

  Uint8List _protectedBlockJsonBytes(Uint8List block) {
    final isManagedBlock = _startsWith(block, _managedBlockMagic);
    final magicLength = isManagedBlock
        ? _managedBlockMagic.length
        : _protectedBlockMagic.length;
    final headerLength = magicLength + (isManagedBlock ? 2 : 1) + 4;
    if (block.length < headerLength + _protectedBlockTailLength ||
        (!isManagedBlock && !_startsWith(block, _protectedBlockMagic))) {
      throw const ToolboxSteganographyException(
        'Hidden payload header is invalid.',
      );
    }
    final jsonLength = _readUint32(
      block,
      magicLength + (isManagedBlock ? 2 : 1),
    );
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

  Uint8List _managedBlockWithSuccessfulRevealCount(
    Uint8List block,
    int remainingSuccessfulReveals,
  ) {
    _validateMaxSuccessfulReveals(remainingSuccessfulReveals);
    if (!_startsWith(block, _managedBlockMagic)) {
      throw const ToolboxSteganographyException(
        'Hidden payload does not support successful reveal limits.',
      );
    }
    _protectedBlockJsonBytes(block);
    final jsonLength = _readUint32(block, _managedBlockMagic.length + 2);
    final tailOffset = _managedBlockMagic.length + 2 + 4 + jsonLength;
    final output = Uint8List.fromList(block);
    output[_managedBlockMagic.length + 1] = remainingSuccessfulReveals;
    final prefix = Uint8List.fromList(output.sublist(0, tailOffset));
    final tail = _protectedBlockTail(prefix);
    output.setRange(tailOffset, tailOffset + tail.length, tail);
    return output;
  }

  void _writeRandomizedLsbBlock(
    img.Image image,
    Uint8List block, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required int maxErrorAttempts,
  }) {
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
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
    _writeImagePolicyHeader(
      image,
      maxErrorAttempts: maxErrorAttempts,
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
    required int slot,
    required List<int> policyPositions,
  }) {
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
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
    for (final slot in <int?>[null, 0, 1]) {
      try {
        return _readRandomizedLsbBlockDetails(
          image,
          passphrase: passphrase,
          keyFileBytes: keyFileBytes,
          locatorAlgorithm: locatorAlgorithm,
          locatorStrength: locatorStrength,
          slot: slot,
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

  _ImageBlockReadResult _readRandomizedLsbBlockDetails(
    img.Image image, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    int? slot,
  }) {
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
    );
    return _readRandomizedLsbBlockWithPolicyReservation(
      image,
      locatorSecret: locatorSecret,
      slot: slot,
      policyPositions: _imagePolicyPositions(
        image,
        headerLength: _imagePolicyHeaderLength,
      ),
    );
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
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
    );
    return _clearRandomizedLsbBlockWithPolicyReservation(
      image,
      locatorSecret: locatorSecret,
      policyPositions: _imagePolicyPositions(
        image,
        headerLength: _imagePolicyHeaderLength,
      ),
    );
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

  ToolboxSteganographyProtectionPolicy? _inspectImagePolicyHeader(
    Uint8List carrierBytes,
  ) {
    final image = _tryDecodeCarrierImage(carrierBytes);
    if (image == null) {
      return null;
    }
    return _readImagePolicyHeader(image);
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

  void _writeImagePolicyHeader(
    img.Image image, {
    required int maxErrorAttempts,
    required List<int> positions,
  }) {
    _writeLsbBytesAtPositions(
      image,
      _buildImagePolicyHeader(maxErrorAttempts: maxErrorAttempts),
      positions,
    );
  }

  ToolboxSteganographyProtectionPolicy? _readImagePolicyHeader(
    img.Image image,
  ) {
    try {
      final positions = _imagePolicyPositions(
        image,
        headerLength: _imagePolicyHeaderLength,
      );
      final header = _readLsbBytesAtPositions(
        image,
        byteCount: _imagePolicyHeaderLength,
        positions: positions,
      );
      if (!_startsWith(header, _imagePolicyMagic)) {
        return null;
      }
      final maxAttempts = header[_imagePolicyMagic.length];
      final prefixLength = _imagePolicyMagic.length + 1;
      final prefix = header.sublist(0, prefixLength);
      final actualChecksum = header.sublist(prefixLength);
      if (actualChecksum.length != _imagePolicyChecksumLength) {
        return null;
      }
      final expectedChecksum = _imagePolicyChecksum(
        prefix,
        checksumLength: _imagePolicyChecksumLength,
      );
      if (!_bytesEqual(actualChecksum, expectedChecksum)) {
        return null;
      }
      return ToolboxSteganographyProtectionPolicy(
        maxErrorAttempts: maxAttempts,
        hasTamperCheck: true,
      );
    } on ToolboxSteganographyException {
      return null;
    }
  }

  Uint8List _buildImagePolicyHeader({required int maxErrorAttempts}) {
    _validateMaxErrorAttempts(maxErrorAttempts);
    final prefix = Uint8List.fromList(<int>[
      ..._imagePolicyMagic,
      maxErrorAttempts,
    ]);
    return Uint8List.fromList(<int>[
      ...prefix,
      ..._imagePolicyChecksum(
        prefix,
        checksumLength: _imagePolicyChecksumLength,
      ),
    ]);
  }

  Uint8List _imagePolicyChecksum(
    List<int> prefix, {
    required int checksumLength,
  }) {
    final versionLabel = _startsWith(prefix, _imagePolicyMagic)
        ? 'vocabulary_sleep_stego_public_policy_v2'
        : 'vocabulary_sleep_stego_public_policy_v1';
    return Uint8List.fromList(
      sha256
          .convert(<int>[...utf8.encode(versionLabel), 0, ...prefix])
          .bytes
          .sublist(0, checksumLength),
    );
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

  void _clearAllImageLsbs(img.Image image) {
    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        image.setPixelRgba(
          x,
          y,
          pixel.r.toInt() & 0xfe,
          pixel.g.toInt() & 0xfe,
          pixel.b.toInt() & 0xfe,
          pixel.a.toInt(),
        );
      }
    }
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
  }) {
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
        if (nonce != null) ...nonce,
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

  Uint8List _uint64Bytes(int value) {
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

class _TailBlockRange {
  const _TailBlockRange({required this.offset, required this.length});

  final int offset;
  final int length;
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
