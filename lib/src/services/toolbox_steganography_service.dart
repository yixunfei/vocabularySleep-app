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
  static final List<int> _riffMagic = ascii.encode('RIFF');
  static final List<int> _waveMagic = ascii.encode('WAVE');
  static final List<int> _wavFmtMagic = ascii.encode('fmt ');
  static final List<int> _wavDataMagic = ascii.encode('data');
  static final List<int> _mediaPolicyMagic = ascii.encode('VSSGM2');
  static final List<int> _mp4StegoBoxType = ascii.encode('free');
  static const int _protectedBlockTailLength = 16;
  static const int _imageMagicLength = 16;
  static const int _imageNonceLength = 16;
  static const int _imageHeaderLength =
      _imageMagicLength + _imageNonceLength + 4;
  static const int _imagePolicyChecksumLength = 16;
  static const int _imagePolicyHeaderLength = 23;
  static const int _mediaPolicyChecksumLength = 16;
  static const int _mediaPolicyHeaderLength = 23;
  static const int _mediaMagicLength = 16;
  static const int _mediaNonceLength = 16;
  static const int _mediaHeaderLength =
      _mediaMagicLength + _mediaNonceLength + 4;
  static const int _mp4StegoBoxOverhead = 8;
  static const int _mp4MaxPaddingLength = 255;
  static const int _mp4MaxBoxScanDepth = 128;
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
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
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
    int maxErrorAttempts = 0,
    int maxSuccessfulReveals = 0,
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
    _validateMediaWriteBackend(mediaKind);
    _validateMaxErrorAttempts(maxErrorAttempts);
    _validateMaxSuccessfulReveals(maxSuccessfulReveals);
    _ensureCarrierIsWritable(mediaKind: mediaKind, carrierBytes: carrierBytes);

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
        maxErrorAttempts: maxErrorAttempts,
        maxSuccessfulReveals: maxSuccessfulReveals,
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
        maxErrorAttempts: maxErrorAttempts,
        maxSuccessfulReveals: maxSuccessfulReveals,
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
      maxErrorAttempts: maxErrorAttempts,
      maxSuccessfulReveals: maxSuccessfulReveals,
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
      ToolboxSteganographyMediaKind.audio => _embedInAudio(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.video => _embedInVideo(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
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
      ToolboxSteganographyMediaKind.audio => _embedDualBlocksInAudio(
        carrierBytes: carrierBytes,
        coverBlock: coverBlock,
        hiddenBlock: hiddenBlock,
        hiddenCipherPreview: hiddenEnvelope.cipherPreview,
        sourceExtension: sourceExtension,
        coverPassphrase: coverPassphrase,
        hiddenPassphrase: hiddenPassphrase,
        hiddenKeyFileBytes: hiddenKeyFileBytes,
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
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
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
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
      ToolboxSteganographyMediaKind.audio => _embedInAudio(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ),
      ToolboxSteganographyMediaKind.video => _embedInVideo(
        carrierBytes: carrierBytes,
        block: block,
        envelope: envelope,
        sourceExtension: sourceExtension,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
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
    _validateMediaWriteBackend(mediaKind);
    _validateMaxErrorAttempts(maxErrorAttempts);
    _validateMaxSuccessfulReveals(maxSuccessfulReveals);
    _ensureCarrierIsWritable(mediaKind: mediaKind, carrierBytes: carrierBytes);

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
      ToolboxSteganographyMediaKind.image => _embedDualBlocksInImage(
        carrierBytes: carrierBytes,
        coverBlock: coverBlock,
        hiddenBlock: hiddenBlock,
        hiddenCipherPreview: hiddenEnvelope.cipherPreview,
        coverPassphrase: coverPassphrase,
        hiddenPassphrase: hiddenPassphrase,
        hiddenKeyFileBytes: hiddenKeyFileBytes,
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
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
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
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
        maxErrorAttempts: maxErrorAttempts,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
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
    if (mediaKind == ToolboxSteganographyMediaKind.audio) {
      final publicPolicy = _inspectAudioPolicyHeader(carrierBytes);
      if (publicPolicy != null) {
        return publicPolicy;
      }
    }
    if (mediaKind == ToolboxSteganographyMediaKind.video) {
      final publicPolicy = _inspectVideoPayload(carrierBytes)?.policy;
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
      ToolboxSteganographyMediaKind.audio =>
        _applySuccessfulAudioRevealProtection(
          carrierBytes,
          passphrase: passphrase,
          keyFileBytes: keyFileBytes,
          locatorAlgorithm: locatorAlgorithm,
          locatorStrength: locatorStrength,
        ),
      ToolboxSteganographyMediaKind.video =>
        _applySuccessfulVideoRevealProtection(
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
      ToolboxSteganographyMediaKind.audio =>
        _inspectAudioPolicyHeader(carrierBytes) != null ||
            _hasTailPayload(carrierBytes),
      ToolboxSteganographyMediaKind.video =>
        _inspectVideoPayload(carrierBytes) != null ||
            _hasTailPayload(carrierBytes),
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
    final wav = _parseWavCarrier(carrierBytes);
    final capacity = _wavBlockCapacity(wav);
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
      carrierLabel: 'WAV/PCM ${wav.bitsPerSample}-bit randomized sample LSB',
    );
  }

  ToolboxSteganographyCapacityCheck _checkDualAudioCapacity({
    required Uint8List carrierBytes,
    required int coverRequiredBytes,
    required int hiddenRequiredBytes,
  }) {
    final wav = _parseWavCarrier(carrierBytes);
    final policySamples = _wavPolicySamples(carrierBytes, wav);
    final coverCapacity = _wavSlotCapacity(
      wav,
      1,
      policySamples: policySamples,
    );
    final hiddenCapacity = _wavSlotCapacity(
      wav,
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
          'WAV/PCM ${wav.bitsPerSample}-bit dual randomized sample LSB',
    );
  }

  ToolboxSteganographyCapacityCheck _checkVideoCapacity({
    required Uint8List carrierBytes,
    required int requiredBytes,
  }) {
    final mp4 = _parseMp4Carrier(carrierBytes);
    final capacity = _mp4BlockCapacity(carrierBytes.length);
    if (capacity <= 0) {
      throw const ToolboxSteganographyException('Video carrier is too large.');
    }
    return ToolboxSteganographyCapacityCheck(
      dualLayer: false,
      mediaKind: ToolboxSteganographyMediaKind.video,
      width: 0,
      height: 0,
      capacityBytes: capacity,
      requiredBytes: requiredBytes,
      minimumPixels: 0,
      minimumCarrierBytes:
          carrierBytes.length +
          _mp4GrowthForBlock(requiredBytes, useMaxPadding: true),
      carrierLabel: mp4.majorBrand == null
          ? 'MP4/QuickTime container free box'
          : 'MP4/QuickTime ${mp4.majorBrand} container free box',
    );
  }

  ToolboxSteganographyCapacityCheck _checkDualVideoCapacity({
    required Uint8List carrierBytes,
    required int coverRequiredBytes,
    required int hiddenRequiredBytes,
  }) {
    final mp4 = _parseMp4Carrier(carrierBytes);
    final coverGrowth = _mp4GrowthForBlock(
      coverRequiredBytes,
      useMaxPadding: true,
    );
    final hiddenGrowth = _mp4GrowthForBlock(
      hiddenRequiredBytes,
      useMaxPadding: true,
    );
    final requiredBytes = coverGrowth + hiddenGrowth;
    final capacity = maxTailCarrierBytes - carrierBytes.length;
    if (capacity <= 0) {
      throw const ToolboxSteganographyException('Video carrier is too large.');
    }
    return ToolboxSteganographyCapacityCheck(
      dualLayer: true,
      mediaKind: ToolboxSteganographyMediaKind.video,
      width: 0,
      height: 0,
      capacityBytes: capacity,
      requiredBytes: requiredBytes,
      coverRequiredBytes: coverRequiredBytes,
      hiddenRequiredBytes: hiddenRequiredBytes,
      minimumPixels: 0,
      minimumCarrierBytes: carrierBytes.length + requiredBytes,
      carrierLabel: mp4.majorBrand == null
          ? 'MP4/QuickTime dual container free box'
          : 'MP4/QuickTime ${mp4.majorBrand} dual container free box',
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
    return _embedDualBlocksInImage(
      carrierBytes: carrierBytes,
      coverBlock: coverBlock,
      hiddenBlock: hiddenBlock,
      hiddenCipherPreview: hiddenEnvelope.cipherPreview,
      coverPassphrase: coverPassphrase,
      hiddenPassphrase: hiddenPassphrase,
      hiddenKeyFileBytes: hiddenKeyFileBytes,
      maxErrorAttempts: maxErrorAttempts,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
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
      cipherPreview: hiddenCipherPreview,
      carrierDetail:
          '${image.width}x${image.height}, dual-layer randomized LSB capacity ${_formatBytes(math.min(coverCapacity, hiddenCapacity))} per layer',
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
    required int maxErrorAttempts,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final wav = _parseWavCarrier(carrierBytes);
    final capacity = _wavBlockCapacity(wav);
    if (block.length > capacity) {
      throw ToolboxSteganographyException(
        'Secret payload is too large for this audio. Capacity: $capacity B, need: ${block.length} B.',
      );
    }
    final output = Uint8List.fromList(carrierBytes);
    _writeRandomizedWavBlock(
      output,
      wav,
      block,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      maxErrorAttempts: maxErrorAttempts,
    );
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: cleanExtension(sourceExtension) ?? 'wav',
      payloadBytes: block.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail:
          'WAV/PCM ${wav.bitsPerSample}-bit randomized sample LSB capacity ${_formatBytes(capacity)}',
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
    required int maxErrorAttempts,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final wav = _parseWavCarrier(carrierBytes);
    final policySamples = _wavPolicySamples(carrierBytes, wav);
    final coverCapacity = _wavSlotCapacity(
      wav,
      1,
      policySamples: policySamples,
    );
    final hiddenCapacity = _wavSlotCapacity(
      wav,
      0,
      policySamples: policySamples,
    );
    if (coverBlock.length > coverCapacity ||
        hiddenBlock.length > hiddenCapacity) {
      throw ToolboxSteganographyException(
        'Secret payload is too large for this audio. Capacity: ${math.min(coverCapacity, hiddenCapacity)} B per layer.',
      );
    }
    final output = Uint8List.fromList(carrierBytes);
    _writeRandomizedWavBlockInSlot(
      output,
      wav,
      hiddenBlock,
      passphrase: hiddenPassphrase,
      keyFileBytes: hiddenKeyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      slot: 0,
      policySamples: policySamples,
    );
    _writeRandomizedWavBlockInSlot(
      output,
      wav,
      coverBlock,
      passphrase: coverPassphrase,
      keyFileBytes: null,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      slot: 1,
      policySamples: policySamples,
    );
    _writeWavBytesAtSamples(
      output,
      wav,
      _buildMediaPolicyHeader(maxErrorAttempts: maxErrorAttempts),
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
          'WAV/PCM ${wav.bitsPerSample}-bit dual randomized sample LSB capacity ${_formatBytes(math.min(coverCapacity, hiddenCapacity))} per layer',
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
    required int maxErrorAttempts,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final mp4 = _parseMp4Carrier(carrierBytes);
    final capacity = _mp4BlockCapacity(carrierBytes.length);
    if (block.length > capacity) {
      throw ToolboxSteganographyException(
        'Secret payload is too large for this video. Capacity: $capacity B, need: ${block.length} B.',
      );
    }
    final output = _appendMp4StegoBox(
      carrierBytes: carrierBytes,
      block: block,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      maxErrorAttempts: maxErrorAttempts,
    );
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: cleanExtension(sourceExtension) ?? 'mp4',
      payloadBytes: block.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: envelope.cipherPreview,
      carrierDetail: mp4.majorBrand == null
          ? 'MP4/QuickTime free-box payload +${_formatBytes(output.length - carrierBytes.length)}'
          : 'MP4/QuickTime ${mp4.majorBrand} free-box payload +${_formatBytes(output.length - carrierBytes.length)}',
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
    required int maxErrorAttempts,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final mp4 = _parseMp4Carrier(carrierBytes);
    final basePrefixDigest = _mp4PrefixDigest(
      carrierBytes,
      carrierBytes.length,
    );
    final hiddenOutput = _appendMp4StegoBox(
      carrierBytes: carrierBytes,
      block: hiddenBlock,
      passphrase: hiddenPassphrase,
      keyFileBytes: hiddenKeyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      maxErrorAttempts: maxErrorAttempts,
      prefixDigest: basePrefixDigest,
    );
    final output = _appendMp4StegoBox(
      carrierBytes: hiddenOutput,
      block: coverBlock,
      passphrase: coverPassphrase,
      keyFileBytes: null,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      maxErrorAttempts: maxErrorAttempts,
      prefixDigest: basePrefixDigest,
    );
    return ToolboxSteganographyEmbedResult(
      bytes: output,
      outputExtension: cleanExtension(sourceExtension) ?? 'mp4',
      payloadBytes: coverBlock.length + hiddenBlock.length,
      sourceBytes: carrierBytes.length,
      outputBytes: output.length,
      cipherPreview: hiddenCipherPreview,
      carrierDetail: mp4.majorBrand == null
          ? 'MP4/QuickTime dual free-box payload +${_formatBytes(output.length - carrierBytes.length)}'
          : 'MP4/QuickTime ${mp4.majorBrand} dual free-box payload +${_formatBytes(output.length - carrierBytes.length)}',
      capacityBytes: maxTailCarrierBytes - carrierBytes.length,
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

  Uint8List _extractAudioBlock(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    try {
      final wav = _parseWavCarrier(carrierBytes);
      return _readRandomizedWavBlock(
        carrierBytes,
        wav,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      ).block;
    } on ToolboxSteganographyException {
      if (_hasTailPayload(carrierBytes)) {
        return _extractTailBlock(carrierBytes);
      }
      rethrow;
    }
  }

  Uint8List _extractVideoBlock(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final stegoBox = _readMp4StegoBox(
      carrierBytes,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    );
    if (stegoBox != null) {
      return stegoBox.block;
    }
    if (_hasTailPayload(carrierBytes)) {
      return _extractTailBlock(carrierBytes);
    }
    throw const ToolboxSteganographyException('No hidden payload found.');
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

  ToolboxSteganographySanitizeResult _stripAudioPayload(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    if (_hasTailPayload(carrierBytes)) {
      return _stripTailPayload(
        carrierBytes,
        mediaKind: ToolboxSteganographyMediaKind.audio,
      );
    }
    final wav = _parseWavCarrier(carrierBytes);
    final output = Uint8List.fromList(carrierBytes);
    var removed = false;
    try {
      removed = _clearRandomizedWavBlock(
        output,
        wav,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      );
    } on ToolboxSteganographyException {
      if (_readWavPolicyHeader(carrierBytes, wav) != null) {
        _clearAllWavSampleLsbs(output, wav);
        removed = true;
      }
    }
    return ToolboxSteganographySanitizeResult(
      bytes: removed ? output : Uint8List.fromList(carrierBytes),
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
    final stegoBox = _readMp4StegoBox(
      carrierBytes,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    );
    if (stegoBox != null) {
      return ToolboxSteganographySanitizeResult(
        bytes: _removeMp4Box(carrierBytes, stegoBox.offset, stegoBox.size),
        outputExtension: 'mp4',
        removed: true,
      );
    }
    if (_hasTailPayload(carrierBytes)) {
      return _stripTailPayload(
        carrierBytes,
        mediaKind: ToolboxSteganographyMediaKind.video,
      );
    }
    return ToolboxSteganographySanitizeResult(
      bytes: Uint8List.fromList(carrierBytes),
      outputExtension: 'mp4',
      removed: false,
    );
  }

  ToolboxSteganographySuccessfulRevealProtectionResult
  _applySuccessfulAudioRevealProtection(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    if (_hasTailPayload(carrierBytes)) {
      return _applySuccessfulTailRevealProtection(
        carrierBytes,
        mediaKind: ToolboxSteganographyMediaKind.audio,
      );
    }
    final wav = _parseWavCarrier(carrierBytes);
    final read = _readRandomizedWavBlock(
      carrierBytes,
      wav,
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
        outputExtension: 'wav',
        changed: false,
        removed: false,
        remainingSuccessfulReveals: 0,
      );
    }
    if (remaining == 1) {
      final stripped = _stripAudioPayload(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      );
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
    final output = Uint8List.fromList(carrierBytes);
    _writeWavBytesAtSamples(output, wav, updatedBlock, read.payloadSamples);
    return ToolboxSteganographySuccessfulRevealProtectionResult(
      bytes: output,
      outputExtension: 'wav',
      changed: true,
      removed: false,
      remainingSuccessfulReveals: remaining - 1,
    );
  }

  ToolboxSteganographySuccessfulRevealProtectionResult
  _applySuccessfulVideoRevealProtection(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final stegoBox = _readMp4StegoBox(
      carrierBytes,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    );
    if (stegoBox == null) {
      return _applySuccessfulTailRevealProtection(
        carrierBytes,
        mediaKind: ToolboxSteganographyMediaKind.video,
      );
    }
    final policy = _readBlockPolicy(stegoBox.block);
    final remaining = policy.remainingSuccessfulReveals;
    if (remaining <= 0) {
      return ToolboxSteganographySuccessfulRevealProtectionResult(
        bytes: Uint8List.fromList(carrierBytes),
        outputExtension: 'mp4',
        changed: false,
        removed: false,
        remainingSuccessfulReveals: 0,
      );
    }
    if (remaining == 1) {
      final stripped = _stripVideoPayload(
        carrierBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        locatorAlgorithm: locatorAlgorithm,
        locatorStrength: locatorStrength,
      );
      return ToolboxSteganographySuccessfulRevealProtectionResult(
        bytes: stripped.bytes,
        outputExtension: stripped.outputExtension,
        changed: stripped.removed,
        removed: stripped.removed,
        remainingSuccessfulReveals: 0,
      );
    }
    final updatedBlock = _managedBlockWithSuccessfulRevealCount(
      stegoBox.block,
      remaining - 1,
    );
    final updatedBox = _buildMp4StegoBox(
      block: updatedBlock,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      maxErrorAttempts: policy.maxErrorAttempts,
      prefixDigest: stegoBox.prefixDigest,
      nonce: stegoBox.nonce,
      paddingLength: stegoBox.paddingLength,
    );
    final output = Uint8List.fromList(carrierBytes);
    output.setRange(
      stegoBox.offset,
      stegoBox.offset + updatedBox.length,
      updatedBox,
    );
    return ToolboxSteganographySuccessfulRevealProtectionResult(
      bytes: output,
      outputExtension: 'mp4',
      changed: true,
      removed: false,
      remainingSuccessfulReveals: remaining - 1,
    );
  }

  _WavCarrierInfo _parseWavCarrier(Uint8List carrierBytes) {
    _validateTailCarrierSize(carrierBytes);
    if (carrierBytes.length < 44 ||
        !_rangeEquals(carrierBytes, 0, _riffMagic) ||
        !_rangeEquals(carrierBytes, 8, _waveMagic)) {
      throw const ToolboxSteganographyException(
        'Unsupported audio format. Pick WAV/PCM audio.',
      );
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
      throw const ToolboxSteganographyException(
        'Unsupported audio format. Pick WAV/PCM audio.',
      );
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

  int _wavBlockCapacity(_WavCarrierInfo wav) {
    return (wav.sampleCount -
            ((_mediaPolicyHeaderLength + _mediaHeaderLength) * 8)) ~/
        8;
  }

  int _minimumWavSamples(int requiredBytes) {
    return (requiredBytes * 8) +
        ((_mediaPolicyHeaderLength + _mediaHeaderLength) * 8);
  }

  int _minimumWavCarrierBytes(_WavCarrierInfo wav, int requiredBytes) {
    return wav.dataOffset +
        (_minimumWavSamples(requiredBytes) * wav.bytesPerSample);
  }

  int _wavSlotCapacity(
    _WavCarrierInfo wav,
    int slot, {
    required List<int> policySamples,
  }) {
    final slotSamples = (wav.sampleCount + (slot == 0 ? 1 : 0)) ~/ 2;
    final reservedPolicy = policySamples
        .where((sample) => sample.isEven == (slot == 0))
        .length;
    return (slotSamples - reservedPolicy - (_mediaHeaderLength * 8)) ~/ 8;
  }

  int _minimumDualWavSamples(int requiredBytes) {
    final policyBits = _mediaPolicyHeaderLength * 8;
    final requiredSlotBits =
        (requiredBytes * 8) +
        (_mediaHeaderLength * 8) +
        ((policyBits + 1) ~/ 2);
    return requiredSlotBits * 2;
  }

  int _minimumDualWavCarrierBytes(_WavCarrierInfo wav, int requiredBytes) {
    return wav.dataOffset +
        (_minimumDualWavSamples(requiredBytes) * wav.bytesPerSample);
  }

  void _writeRandomizedWavBlock(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
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
    final carrierDigest = _wavCarrierDigest(carrierBytes, wav);
    final nonce = _randomBytes(_mediaNonceLength);
    final policySamples = _wavPolicySamples(carrierBytes, wav);
    final header = _buildMediaHeader(
      locatorSecret: locatorSecret,
      nonce: nonce,
      payloadLength: block.length,
      carrierDigest: carrierDigest,
      purpose: 'audio',
    );
    final headerSamples = _selectPositions(
      total: wav.sampleCount,
      count: header.length * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: 'audio-header',
        carrierDigest: carrierDigest,
      ),
      excluded: Set<int>.from(policySamples),
    );
    final payloadSamples = _selectPositions(
      total: wav.sampleCount,
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
      _buildMediaPolicyHeader(maxErrorAttempts: maxErrorAttempts),
      policySamples,
    );
  }

  void _writeRandomizedWavBlockInSlot(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
    Uint8List block, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required int slot,
    required List<int> policySamples,
  }) {
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
    );
    final carrierDigest = _wavCarrierDigest(carrierBytes, wav);
    final nonce = _randomBytes(_mediaNonceLength);
    final header = _buildMediaHeader(
      locatorSecret: locatorSecret,
      nonce: nonce,
      payloadLength: block.length,
      carrierDigest: carrierDigest,
      purpose: 'audio-slot-$slot',
    );
    final headerSamples = _selectSlotPositions(
      total: wav.sampleCount,
      count: header.length * 8,
      seed: _mediaPositionSeed(
        locatorSecret: locatorSecret,
        purpose: 'audio-header-slot-$slot',
        carrierDigest: carrierDigest,
      ),
      slot: slot,
      excluded: Set<int>.from(policySamples),
    );
    final payloadSamples = _selectSlotPositions(
      total: wav.sampleCount,
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

  _WavBlockReadResult _readRandomizedWavBlock(
    Uint8List carrierBytes,
    _WavCarrierInfo wav, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final errors = <Object>[];
    for (final slot in <int?>[null, 0, 1]) {
      try {
        return _readRandomizedWavBlockDetails(
          carrierBytes,
          wav,
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
    throw const ToolboxSteganographyException('No hidden payload found.');
  }

  _WavBlockReadResult _readRandomizedWavBlockDetails(
    Uint8List carrierBytes,
    _WavCarrierInfo wav, {
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
    final carrierDigest = _wavCarrierDigest(carrierBytes, wav);
    final policySamples = _wavPolicySamples(carrierBytes, wav);
    final headerSeed = _mediaPositionSeed(
      locatorSecret: locatorSecret,
      purpose: slot == null ? 'audio-header' : 'audio-header-slot-$slot',
      carrierDigest: carrierDigest,
    );
    final headerSamples = slot == null
        ? _selectPositions(
            total: wav.sampleCount,
            count: _mediaHeaderLength * 8,
            seed: headerSeed,
            excluded: Set<int>.from(policySamples),
          )
        : _selectSlotPositions(
            total: wav.sampleCount,
            count: _mediaHeaderLength * 8,
            seed: headerSeed,
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
      purpose: slot == null ? 'audio' : 'audio-slot-$slot',
    );
    if (!_bytesEqual(header.sublist(0, _mediaMagicLength), expectedMagic)) {
      throw const ToolboxSteganographyException('No hidden payload found.');
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
          purpose: slot == null ? 'audio' : 'audio-slot-$slot',
        );
    final capacity = slot == null
        ? _wavBlockCapacity(wav)
        : _wavSlotCapacity(wav, slot, policySamples: policySamples);
    if (payloadLength <= 0 || payloadLength > capacity) {
      throw const ToolboxSteganographyException(
        'Hidden payload is damaged or incomplete.',
      );
    }
    final payloadSeed = _mediaPositionSeed(
      locatorSecret: locatorSecret,
      purpose: slot == null ? 'audio-payload' : 'audio-payload-slot-$slot',
      carrierDigest: carrierDigest,
      nonce: nonce,
    );
    final payloadSamples = slot == null
        ? _selectPositions(
            total: wav.sampleCount,
            count: payloadLength * 8,
            seed: payloadSeed,
            excluded: <int>{...policySamples, ...headerSamples},
          )
        : _selectSlotPositions(
            total: wav.sampleCount,
            count: payloadLength * 8,
            seed: payloadSeed,
            slot: slot,
            excluded: <int>{...policySamples, ...headerSamples},
          );
    return _WavBlockReadResult(
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

  bool _clearRandomizedWavBlock(
    Uint8List carrierBytes,
    _WavCarrierInfo wav, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    final read = _readRandomizedWavBlock(
      carrierBytes,
      wav,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
    );
    final samples = read.slot == null
        ? <int>[
            ...read.policySamples,
            ...read.headerSamples,
            ...read.payloadSamples,
          ]
        : <int>[...read.headerSamples, ...read.payloadSamples];
    for (final sample in samples) {
      _setWavLsbAtSample(carrierBytes, wav, sample, 0);
    }
    return true;
  }

  ToolboxSteganographyProtectionPolicy? _inspectAudioPolicyHeader(
    Uint8List carrierBytes,
  ) {
    try {
      final wav = _parseWavCarrier(carrierBytes);
      return _readWavPolicyHeader(carrierBytes, wav);
    } on ToolboxSteganographyException {
      return null;
    }
  }

  ToolboxSteganographyProtectionPolicy? _readWavPolicyHeader(
    Uint8List carrierBytes,
    _WavCarrierInfo wav,
  ) {
    try {
      final header = _readWavBytesAtSamples(
        carrierBytes,
        wav,
        byteCount: _mediaPolicyHeaderLength,
        samples: _wavPolicySamples(carrierBytes, wav),
      );
      return _readMediaPolicyHeader(header);
    } on ToolboxSteganographyException {
      return null;
    }
  }

  List<int> _wavPolicySamples(Uint8List carrierBytes, _WavCarrierInfo wav) {
    if (wav.sampleCount < _mediaPolicyHeaderLength * 8) {
      throw const ToolboxSteganographyException('Audio carrier is too small.');
    }
    return _selectPositions(
      total: wav.sampleCount,
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

  Uint8List _readWavBytesAtSamples(
    Uint8List carrierBytes,
    _WavCarrierInfo wav, {
    required int byteCount,
    required List<int> samples,
  }) {
    final totalBits = byteCount * 8;
    if (samples.length < totalBits) {
      throw const ToolboxSteganographyException(
        'Hidden payload is damaged or incomplete.',
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
        'Hidden payload is damaged or incomplete.',
      );
    }
    return carrierBytes[offset] & 1;
  }

  void _clearAllWavSampleLsbs(Uint8List carrierBytes, _WavCarrierInfo wav) {
    for (var sample = 0; sample < wav.sampleCount; sample += 1) {
      _setWavLsbAtSample(carrierBytes, wav, sample, 0);
    }
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

  _Mp4CarrierInfo _parseMp4Carrier(Uint8List carrierBytes) {
    _validateTailCarrierSize(carrierBytes);
    final boxes = _mp4TopLevelBoxes(carrierBytes);
    final ftyp = boxes.cast<_Mp4Box?>().firstWhere(
      (box) => box?.type == 'ftyp',
      orElse: () => null,
    );
    if (ftyp == null || ftyp.dataLength < 8) {
      throw const ToolboxSteganographyException(
        'Unsupported video format. Pick MP4/MOV video.',
      );
    }
    final majorBrand = _asciiBoxString(
      carrierBytes,
      ftyp.dataOffset,
      ftyp.dataOffset + 4,
    );
    return _Mp4CarrierInfo(majorBrand: majorBrand, boxes: boxes);
  }

  int _mp4BlockCapacity(int carrierLength) {
    return maxTailCarrierBytes -
        carrierLength -
        _mp4StegoBoxOverhead -
        _mediaPolicyHeaderLength -
        _mediaHeaderLength -
        _mp4MaxPaddingLength;
  }

  int _mp4GrowthForBlock(int blockLength, {required bool useMaxPadding}) {
    return _mp4StegoBoxOverhead +
        _mediaPolicyHeaderLength +
        _mediaHeaderLength +
        blockLength +
        (useMaxPadding ? _mp4MaxPaddingLength : 0);
  }

  Uint8List _appendMp4StegoBox({
    required Uint8List carrierBytes,
    required Uint8List block,
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required int maxErrorAttempts,
    Uint8List? prefixDigest,
  }) {
    final paddingLength = _secureRandom.nextInt(_mp4MaxPaddingLength + 1);
    final effectivePrefixDigest =
        prefixDigest ?? _mp4PrefixDigest(carrierBytes, carrierBytes.length);
    final box = _buildMp4StegoBox(
      block: block,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      locatorAlgorithm: locatorAlgorithm,
      locatorStrength: locatorStrength,
      maxErrorAttempts: maxErrorAttempts,
      prefixDigest: effectivePrefixDigest,
      nonce: _randomBytes(_mediaNonceLength),
      paddingLength: paddingLength,
      randomizePadding: true,
    );
    if (carrierBytes.length + box.length > maxTailCarrierBytes) {
      throw const ToolboxSteganographyException('Payload is too large.');
    }
    final output = Uint8List(carrierBytes.length + box.length);
    output.setRange(0, carrierBytes.length, carrierBytes);
    output.setRange(carrierBytes.length, output.length, box);
    return output;
  }

  Uint8List _buildMp4StegoBox({
    required Uint8List block,
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
    required int maxErrorAttempts,
    required Uint8List prefixDigest,
    required Uint8List nonce,
    required int paddingLength,
    bool randomizePadding = false,
  }) {
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
    );
    final header = _buildMediaHeader(
      locatorSecret: locatorSecret,
      nonce: nonce,
      payloadLength: block.length,
      carrierDigest: prefixDigest,
      purpose: 'video',
    );
    final maskedBlock = _maskMediaBlock(
      block,
      locatorSecret: locatorSecret,
      nonce: nonce,
      purpose: 'video',
    );
    final padding = randomizePadding
        ? _randomBytes(paddingLength)
        : Uint8List(paddingLength);
    final payload = Uint8List.fromList(<int>[
      ..._buildMediaPolicyHeader(
        maxErrorAttempts: maxErrorAttempts,
        magic: _mp4PolicyMagic(prefixDigest),
      ),
      ...header,
      ...maskedBlock,
      ...padding,
    ]);
    final size = _mp4StegoBoxOverhead + payload.length;
    if (size > 0xffffffff) {
      throw const ToolboxSteganographyException('Payload is too large.');
    }
    return Uint8List.fromList(<int>[
      ..._uint32Bytes(size),
      ..._mp4StegoBoxType,
      ...payload,
    ]);
  }

  _Mp4PublicPayload? _inspectVideoPayload(Uint8List carrierBytes) {
    try {
      _parseMp4Carrier(carrierBytes);
      final boxes = _mp4TopLevelBoxes(carrierBytes);
      for (final box in boxes) {
        if (box.type != 'free' ||
            box.dataLength < _mediaPolicyHeaderLength + _mediaHeaderLength) {
          continue;
        }
        for (final prefixDigest in _mp4PrefixDigestCandidates(
          carrierBytes,
          box,
          boxes,
        )) {
          final policy = _readMp4PolicyHeader(carrierBytes, box, prefixDigest);
          if (policy != null) {
            return _Mp4PublicPayload(
              offset: box.offset,
              size: box.size,
              prefixDigest: prefixDigest,
              policy: policy,
            );
          }
        }
      }
    } on ToolboxSteganographyException {
      return null;
    }
    return null;
  }

  _Mp4StegoBoxReadResult? _readMp4StegoBox(
    Uint8List carrierBytes, {
    required String passphrase,
    required Uint8List? keyFileBytes,
    required ToolboxSteganographyLocatorAlgorithm locatorAlgorithm,
    required ToolboxSteganographyLocatorStrength locatorStrength,
  }) {
    _parseMp4Carrier(carrierBytes);
    final locatorSecret = _locatorSecret(
      passphrase,
      keyFileBytes,
      algorithm: locatorAlgorithm,
      strength: locatorStrength,
    );
    final boxes = _mp4TopLevelBoxes(carrierBytes);
    for (final box in boxes.reversed) {
      if (box.type != 'free' ||
          box.dataLength < _mediaPolicyHeaderLength + _mediaHeaderLength) {
        continue;
      }
      for (final prefixDigest in _mp4PrefixDigestCandidates(
        carrierBytes,
        box,
        boxes,
      )) {
        final policy = _readMp4PolicyHeader(carrierBytes, box, prefixDigest);
        if (policy == null) {
          continue;
        }
        final headerOffset = box.dataOffset + _mediaPolicyHeaderLength;
        final header = Uint8List.fromList(
          carrierBytes.sublist(headerOffset, headerOffset + _mediaHeaderLength),
        );
        final nonce = Uint8List.fromList(
          header.sublist(
            _mediaMagicLength,
            _mediaMagicLength + _mediaNonceLength,
          ),
        );
        final expectedMagic = _mediaMagic(
          locatorSecret: locatorSecret,
          nonce: nonce,
          carrierDigest: prefixDigest,
          purpose: 'video',
        );
        if (!_bytesEqual(header.sublist(0, _mediaMagicLength), expectedMagic)) {
          continue;
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
              carrierDigest: prefixDigest,
              purpose: 'video',
            );
        final available =
            box.dataLength - _mediaPolicyHeaderLength - _mediaHeaderLength;
        if (payloadLength <= 0 || payloadLength > available) {
          throw const ToolboxSteganographyException(
            'Hidden payload is damaged or incomplete.',
          );
        }
        final payloadOffset = headerOffset + _mediaHeaderLength;
        final maskedBlock = Uint8List.fromList(
          carrierBytes.sublist(payloadOffset, payloadOffset + payloadLength),
        );
        return _Mp4StegoBoxReadResult(
          block: _maskMediaBlock(
            maskedBlock,
            locatorSecret: locatorSecret,
            nonce: nonce,
            purpose: 'video',
          ),
          offset: box.offset,
          size: box.size,
          nonce: nonce,
          paddingLength: available - payloadLength,
          prefixDigest: prefixDigest,
          policy: policy,
        );
      }
    }
    return null;
  }

  List<Uint8List> _mp4PrefixDigestCandidates(
    Uint8List carrierBytes,
    _Mp4Box box,
    List<_Mp4Box> boxes,
  ) {
    final offsets = <int>{box.offset};
    for (final previous in boxes) {
      if (previous.offset >= box.offset) {
        break;
      }
      offsets.add(previous.offset);
    }
    return offsets
        .map((offset) => _mp4PrefixDigest(carrierBytes, offset))
        .toList(growable: false);
  }

  ToolboxSteganographyProtectionPolicy? _readMp4PolicyHeader(
    Uint8List carrierBytes,
    _Mp4Box box,
    Uint8List prefixDigest,
  ) {
    try {
      final header = Uint8List.fromList(
        carrierBytes.sublist(
          box.dataOffset,
          box.dataOffset + _mediaPolicyHeaderLength,
        ),
      );
      return _readMediaPolicyHeader(
        header,
        magic: _mp4PolicyMagic(prefixDigest),
      );
    } on ToolboxSteganographyException {
      return null;
    }
  }

  Uint8List _removeMp4Box(Uint8List carrierBytes, int offset, int size) {
    if (offset < 0 || size <= 0 || offset + size > carrierBytes.length) {
      throw const ToolboxSteganographyException(
        'Hidden payload is damaged or incomplete.',
      );
    }
    return Uint8List.fromList(<int>[
      ...carrierBytes.sublist(0, offset),
      ...carrierBytes.sublist(offset + size),
    ]);
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
      throw const ToolboxSteganographyException(
        'Unsupported video format. Pick MP4/MOV video.',
      );
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

  Uint8List _mp4PrefixDigest(Uint8List bytes, int endOffset) {
    final output = _DigestSink();
    final input = sha256.startChunkedConversion(output);
    input.add(utf8.encode('vocabulary_sleep_stego_mp4_prefix_v1'));
    input.add(<int>[0, ..._uint32Bytes(endOffset)]);
    const chunkSize = 8192;
    for (var offset = 0; offset < endOffset; offset += chunkSize) {
      input.add(bytes.sublist(offset, math.min(offset + chunkSize, endOffset)));
    }
    input.close();
    return Uint8List.fromList(output.value.bytes);
  }

  Uint8List _mp4PolicyMagic(Uint8List prefixDigest) {
    return Uint8List.fromList(
      sha256
          .convert(<int>[
            ...utf8.encode('vocabulary_sleep_stego_mp4_policy_v1'),
            0,
            ...prefixDigest,
          ])
          .bytes
          .sublist(0, _mediaPolicyMagic.length),
    );
  }

  Uint8List _buildMediaPolicyHeader({
    required int maxErrorAttempts,
    List<int>? magic,
  }) {
    _validateMaxErrorAttempts(maxErrorAttempts);
    final prefix = Uint8List.fromList(<int>[
      ...(magic ?? _mediaPolicyMagic),
      maxErrorAttempts,
    ]);
    return Uint8List.fromList(<int>[
      ...prefix,
      ..._mediaPolicyChecksum(prefix),
    ]);
  }

  ToolboxSteganographyProtectionPolicy? _readMediaPolicyHeader(
    Uint8List header, {
    List<int>? magic,
  }) {
    final expectedMagic = magic ?? _mediaPolicyMagic;
    if (header.length != _mediaPolicyHeaderLength ||
        !_startsWith(header, expectedMagic)) {
      return null;
    }
    final maxAttempts = header[expectedMagic.length];
    final prefixLength = expectedMagic.length + 1;
    final prefix = header.sublist(0, prefixLength);
    final actualChecksum = header.sublist(prefixLength);
    if (!_bytesEqual(actualChecksum, _mediaPolicyChecksum(prefix))) {
      return null;
    }
    return ToolboxSteganographyProtectionPolicy(
      maxErrorAttempts: maxAttempts,
      hasTamperCheck: true,
    );
  }

  Uint8List _mediaPolicyChecksum(List<int> prefix) {
    return Uint8List.fromList(
      sha256
          .convert(<int>[
            ...utf8.encode('vocabulary_sleep_stego_media_policy_v1'),
            0,
            ...prefix,
          ])
          .bytes
          .sublist(0, _mediaPolicyChecksumLength),
    );
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
        if (nonce != null) ...nonce,
      ]).bytes,
    );
  }

  Uint8List _maskMediaBlock(
    Uint8List input, {
    required Uint8List locatorSecret,
    required Uint8List nonce,
    required String purpose,
  }) {
    final maskKey = Uint8List.fromList(
      sha256.convert(<int>[
        ...utf8.encode('vocabulary_sleep_stego_media_mask_v1'),
        0,
        ...utf8.encode(purpose),
        0,
        ...locatorSecret,
        0,
        ...nonce,
      ]).bytes,
    );
    return _xorWithSha256Stream(input, maskKey, nonce);
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

class _WavBlockReadResult {
  const _WavBlockReadResult({
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

class _Mp4CarrierInfo {
  const _Mp4CarrierInfo({required this.majorBrand, required this.boxes});

  final String? majorBrand;
  final List<_Mp4Box> boxes;
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

class _Mp4PublicPayload {
  const _Mp4PublicPayload({
    required this.offset,
    required this.size,
    required this.prefixDigest,
    required this.policy,
  });

  final int offset;
  final int size;
  final Uint8List prefixDigest;
  final ToolboxSteganographyProtectionPolicy policy;
}

class _Mp4StegoBoxReadResult {
  const _Mp4StegoBoxReadResult({
    required this.block,
    required this.offset,
    required this.size,
    required this.nonce,
    required this.paddingLength,
    required this.prefixDigest,
    required this.policy,
  });

  final Uint8List block;
  final int offset;
  final int size;
  final Uint8List nonce;
  final int paddingLength;
  final Uint8List prefixDigest;
  final ToolboxSteganographyProtectionPolicy policy;
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
