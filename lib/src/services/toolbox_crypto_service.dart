import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart' as pc;

enum ToolboxCryptoAlgorithm {
  none,
  aesGcm,
  camelliaGcm,
  twofishGcm,
  aesTwofishGcm,
  aesCamelliaGcm,
  aesTwofishCamelliaGcm,
  customCascade,
  sha256Stream,
  rc4Legacy,
  sha256RsaSignature,
  ecdsaSignature,
  whirlpoolDigest,
}

extension ToolboxCryptoAlgorithmInfo on ToolboxCryptoAlgorithm {
  String get id {
    return switch (this) {
      ToolboxCryptoAlgorithm.none => 'none',
      ToolboxCryptoAlgorithm.aesGcm => 'aes_gcm',
      ToolboxCryptoAlgorithm.camelliaGcm => 'camellia_gcm',
      ToolboxCryptoAlgorithm.twofishGcm => 'twofish_gcm',
      ToolboxCryptoAlgorithm.aesTwofishGcm => 'aes_twofish_gcm',
      ToolboxCryptoAlgorithm.aesCamelliaGcm => 'aes_camellia_gcm',
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm =>
        'aes_twofish_camellia_gcm',
      ToolboxCryptoAlgorithm.customCascade => 'custom_cascade',
      ToolboxCryptoAlgorithm.sha256Stream => 'sha256_stream',
      ToolboxCryptoAlgorithm.rc4Legacy => 'rc4_legacy',
      ToolboxCryptoAlgorithm.sha256RsaSignature => 'sha256_rsa_signature',
      ToolboxCryptoAlgorithm.ecdsaSignature => 'ecdsa_signature',
      ToolboxCryptoAlgorithm.whirlpoolDigest => 'whirlpool_digest',
    };
  }

  String get label {
    return switch (this) {
      ToolboxCryptoAlgorithm.none => 'No encryption',
      ToolboxCryptoAlgorithm.aesGcm => 'AES-GCM',
      ToolboxCryptoAlgorithm.camelliaGcm => 'Camellia-GCM',
      ToolboxCryptoAlgorithm.twofishGcm => 'Twofish-GCM',
      ToolboxCryptoAlgorithm.aesTwofishGcm => 'AES + Twofish',
      ToolboxCryptoAlgorithm.aesCamelliaGcm => 'AES + Camellia',
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm =>
        'AES + Twofish + Camellia',
      ToolboxCryptoAlgorithm.customCascade => 'Custom cascade',
      ToolboxCryptoAlgorithm.sha256Stream => 'SHA256 stream',
      ToolboxCryptoAlgorithm.rc4Legacy => 'RC4 legacy',
      ToolboxCryptoAlgorithm.sha256RsaSignature => 'SHA-256/RSA signature',
      ToolboxCryptoAlgorithm.ecdsaSignature => 'ECDSA signature',
      ToolboxCryptoAlgorithm.whirlpoolDigest => 'Whirlpool digest',
    };
  }

  bool get requiresSecret => this != ToolboxCryptoAlgorithm.none;

  bool get isAvailable => true;

  bool get isLegacy {
    return switch (this) {
      ToolboxCryptoAlgorithm.sha256Stream ||
      ToolboxCryptoAlgorithm.rc4Legacy => true,
      _ => false,
    };
  }

  int get defaultKeyBits {
    return switch (this) {
      ToolboxCryptoAlgorithm.none => 0,
      ToolboxCryptoAlgorithm.aesGcm => 256,
      ToolboxCryptoAlgorithm.camelliaGcm => 256,
      ToolboxCryptoAlgorithm.twofishGcm => 256,
      ToolboxCryptoAlgorithm.aesTwofishGcm => 512,
      ToolboxCryptoAlgorithm.aesCamelliaGcm => 512,
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm => 768,
      ToolboxCryptoAlgorithm.customCascade => 256,
      ToolboxCryptoAlgorithm.sha256Stream => 256,
      ToolboxCryptoAlgorithm.rc4Legacy => 256,
      ToolboxCryptoAlgorithm.sha256RsaSignature => 256,
      ToolboxCryptoAlgorithm.ecdsaSignature => 256,
      ToolboxCryptoAlgorithm.whirlpoolDigest => 512,
    };
  }
}

enum ToolboxCryptoCascadeCipher { aes, twofish, camellia, sha256Stream }

extension ToolboxCryptoCascadeCipherInfo on ToolboxCryptoCascadeCipher {
  String get id {
    return switch (this) {
      ToolboxCryptoCascadeCipher.aes => 'aes_gcm',
      ToolboxCryptoCascadeCipher.twofish => 'twofish_gcm',
      ToolboxCryptoCascadeCipher.camellia => 'camellia_gcm',
      ToolboxCryptoCascadeCipher.sha256Stream => 'sha256_stream',
    };
  }

  String get label {
    return switch (this) {
      ToolboxCryptoCascadeCipher.aes => 'AES-GCM',
      ToolboxCryptoCascadeCipher.twofish => 'Twofish-GCM',
      ToolboxCryptoCascadeCipher.camellia => 'Camellia-GCM',
      ToolboxCryptoCascadeCipher.sha256Stream => 'SHA256 stream',
    };
  }
}

enum ToolboxCryptoKeyBits { bits256, bits512, bits1024 }

extension ToolboxCryptoKeyBitsInfo on ToolboxCryptoKeyBits {
  String get id {
    return switch (this) {
      ToolboxCryptoKeyBits.bits256 => '256',
      ToolboxCryptoKeyBits.bits512 => '512',
      ToolboxCryptoKeyBits.bits1024 => '1024',
    };
  }

  int get bits {
    return switch (this) {
      ToolboxCryptoKeyBits.bits256 => 256,
      ToolboxCryptoKeyBits.bits512 => 512,
      ToolboxCryptoKeyBits.bits1024 => 1024,
    };
  }

  int get bytes => bits ~/ 8;
}

enum ToolboxCryptoSignatureMode { none, rsaSha256, ecdsaSha256 }

extension ToolboxCryptoSignatureModeInfo on ToolboxCryptoSignatureMode {
  String get id {
    return switch (this) {
      ToolboxCryptoSignatureMode.none => 'none',
      ToolboxCryptoSignatureMode.rsaSha256 => 'rsa_sha256',
      ToolboxCryptoSignatureMode.ecdsaSha256 => 'ecdsa_sha256',
    };
  }

  String get label {
    return switch (this) {
      ToolboxCryptoSignatureMode.none => 'No signature',
      ToolboxCryptoSignatureMode.rsaSha256 => 'SHA-256/RSA',
      ToolboxCryptoSignatureMode.ecdsaSha256 => 'ECDSA',
    };
  }
}

enum ToolboxCryptoMacAlgorithm { sha256, whirlpool }

extension ToolboxCryptoMacAlgorithmInfo on ToolboxCryptoMacAlgorithm {
  String get id {
    return switch (this) {
      ToolboxCryptoMacAlgorithm.sha256 => 'sha256',
      ToolboxCryptoMacAlgorithm.whirlpool => 'whirlpool',
    };
  }
}

enum ToolboxCryptoStrength { standard, strong, extreme }

extension ToolboxCryptoStrengthInfo on ToolboxCryptoStrength {
  String get id {
    return switch (this) {
      ToolboxCryptoStrength.standard => 'standard',
      ToolboxCryptoStrength.strong => 'strong',
      ToolboxCryptoStrength.extreme => 'extreme',
    };
  }

  String get label {
    return switch (this) {
      ToolboxCryptoStrength.standard => 'Standard',
      ToolboxCryptoStrength.strong => 'Strong',
      ToolboxCryptoStrength.extreme => 'Extreme',
    };
  }

  int get scryptN {
    return switch (this) {
      ToolboxCryptoStrength.standard => 1 << 12,
      ToolboxCryptoStrength.strong => 1 << 14,
      ToolboxCryptoStrength.extreme => 1 << 15,
    };
  }

  int get scryptR {
    return switch (this) {
      ToolboxCryptoStrength.standard => 8,
      ToolboxCryptoStrength.strong => 8,
      ToolboxCryptoStrength.extreme => 8,
    };
  }

  int get scryptP {
    return switch (this) {
      ToolboxCryptoStrength.standard => 1,
      ToolboxCryptoStrength.strong => 1,
      ToolboxCryptoStrength.extreme => 2,
    };
  }

  int get legacyRounds {
    return switch (this) {
      ToolboxCryptoStrength.standard => 4096,
      ToolboxCryptoStrength.strong => 12000,
      ToolboxCryptoStrength.extreme => 24000,
    };
  }
}

enum ToolboxCryptoHashAlgorithm {
  sha256,
  sha512,
  sha3_256,
  sha3_512,
  blake2b256,
  blake2b512,
  whirlpool,
}

extension ToolboxCryptoHashAlgorithmInfo on ToolboxCryptoHashAlgorithm {
  String get id {
    return switch (this) {
      ToolboxCryptoHashAlgorithm.sha256 => 'sha256',
      ToolboxCryptoHashAlgorithm.sha512 => 'sha512',
      ToolboxCryptoHashAlgorithm.sha3_256 => 'sha3_256',
      ToolboxCryptoHashAlgorithm.sha3_512 => 'sha3_512',
      ToolboxCryptoHashAlgorithm.blake2b256 => 'blake2b_256',
      ToolboxCryptoHashAlgorithm.blake2b512 => 'blake2b_512',
      ToolboxCryptoHashAlgorithm.whirlpool => 'whirlpool',
    };
  }

  String get label {
    return switch (this) {
      ToolboxCryptoHashAlgorithm.sha256 => 'SHA-256',
      ToolboxCryptoHashAlgorithm.sha512 => 'SHA-512',
      ToolboxCryptoHashAlgorithm.sha3_256 => 'SHA3-256',
      ToolboxCryptoHashAlgorithm.sha3_512 => 'SHA3-512',
      ToolboxCryptoHashAlgorithm.blake2b256 => 'BLAKE2b-256',
      ToolboxCryptoHashAlgorithm.blake2b512 => 'BLAKE2b-512',
      ToolboxCryptoHashAlgorithm.whirlpool => 'Whirlpool',
    };
  }
}

class ToolboxCryptoException implements Exception {
  const ToolboxCryptoException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ToolboxCryptoEncryptResult {
  const ToolboxCryptoEncryptResult({
    required this.envelopeBytes,
    required this.cipherBytes,
    required this.algorithm,
    required this.strength,
    required this.cipherPreview,
    required this.plainBytes,
    required this.keyFileSha256,
    this.fileName,
    this.mediaType,
  });

  final Uint8List envelopeBytes;
  final Uint8List cipherBytes;
  final ToolboxCryptoAlgorithm algorithm;
  final ToolboxCryptoStrength strength;
  final String cipherPreview;
  final int plainBytes;
  final String? keyFileSha256;
  final String? fileName;
  final String? mediaType;
}

class ToolboxCryptoDecryptResult {
  const ToolboxCryptoDecryptResult({
    required this.plainBytes,
    required this.algorithm,
    required this.strength,
    required this.cipherPreview,
    required this.keyFileSha256,
    this.fileName,
    this.mediaType,
  });

  final Uint8List plainBytes;
  final ToolboxCryptoAlgorithm algorithm;
  final ToolboxCryptoStrength strength;
  final String cipherPreview;
  final String? keyFileSha256;
  final String? fileName;
  final String? mediaType;
}

class ToolboxCryptoHashResult {
  const ToolboxCryptoHashResult({
    required this.algorithm,
    required this.hex,
    required this.base64,
  });

  final ToolboxCryptoHashAlgorithm algorithm;
  final String hex;
  final String base64;
}

class ToolboxCryptoKeyFileResult {
  const ToolboxCryptoKeyFileResult({
    required this.bytes,
    required this.length,
    required this.sha256,
    required this.fileName,
  });

  final Uint8List bytes;
  final int length;
  final String sha256;
  final String fileName;
}

class ToolboxCryptoService {
  static const int currentVersion = 2;
  static final math.Random _secureRandom = math.Random.secure();

  ToolboxCryptoEncryptResult encryptBytes({
    required Uint8List plainBytes,
    required ToolboxCryptoAlgorithm algorithm,
    required ToolboxCryptoStrength strength,
    required String passphrase,
    Uint8List? keyFileBytes,
    String? fileName,
    String? mediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
  }) {
    if (plainBytes.isEmpty) {
      throw const ToolboxCryptoException('Input bytes are empty.');
    }
    _validateAlgorithmAndSecret(
      algorithm: algorithm,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );

    final salt = _randomBytes(16);
    final keyFileHash = _keyFileHash(keyFileBytes);
    final stages = _stagesFor(algorithm, cascade: cascade, keyBits: keyBits);
    final effectiveMacAlgorithm = _effectiveMacAlgorithm(
      algorithm,
      macAlgorithm,
    );
    final effectiveSignatureMode = _effectiveSignatureMode(
      algorithm,
      signatureMode,
    );
    var activeBytes = Uint8List.fromList(plainBytes);
    final stageMaps = <Map<String, Object?>>[];
    final keyMaterial = _deriveKeyMaterial(
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      salt: salt,
      strength: strength,
      macAlgorithm: effectiveMacAlgorithm,
      length: _keyMaterialLength(algorithm, stages: stages),
    );
    var keyOffset = 0;

    for (var index = 0; index < stages.length; index += 1) {
      final stage = stages[index];
      final nonce = stage.usesNonce ? _randomBytes(12) : _randomBytes(16);
      final keyLength = stage.keyBytes;
      final key = Uint8List.sublistView(
        keyMaterial,
        keyOffset,
        keyOffset + keyLength,
      );
      keyOffset += keyLength;
      activeBytes = stage.transform(
        encrypt: true,
        input: activeBytes,
        key: Uint8List.fromList(key),
        nonce: nonce,
        strength: strength,
      );
      stageMaps.add(<String, Object?>{
        'id': stage.id,
        'nonce': base64Encode(nonce),
        'keyBits': keyLength * 8,
      });
    }

    final cipherBytes = Uint8List.fromList(activeBytes);
    final plainSha = _hashHex(ToolboxCryptoHashAlgorithm.sha256, plainBytes);
    final associatedData = _associatedData(
      version: currentVersion,
      algorithm: algorithm,
      strength: strength,
      keyBits: keyBits,
      macAlgorithm: effectiveMacAlgorithm,
      signatureMode: effectiveSignatureMode,
      salt: salt,
      plainSha256: plainSha,
      stages: stageMaps,
      keyFileSha256: keyFileHash,
      fileName: fileName,
      mediaType: mediaType,
    );
    final macKey = _deriveMacKey(
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      salt: salt,
      strength: strength,
      macAlgorithm: effectiveMacAlgorithm,
    );
    final mac = _hmacHex(
      algorithm: effectiveMacAlgorithm,
      key: macKey,
      bytes: <int>[...associatedData, 0, ...cipherBytes],
    );
    final signatureSeed = _deriveSignatureSeed(
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      salt: salt,
      strength: strength,
      macAlgorithm: effectiveMacAlgorithm,
    );
    final signedBytes = <int>[
      ...associatedData,
      0,
      ...cipherBytes,
      0,
      ...utf8.encode(mac),
    ];
    final signature = _signEnvelope(
      mode: effectiveSignatureMode,
      keySeed: signatureSeed,
      data: signedBytes,
    );
    final signaturePublic = _signaturePublicKey(
      mode: effectiveSignatureMode,
      keySeed: signatureSeed,
    );
    final envelope = <String, Object?>{
      'format': 'vocabulary_sleep_crypto',
      'version': currentVersion,
      'algorithm': algorithm.id,
      'strength': strength.id,
      'keyBits': keyBits.bits,
      'macAlgorithm': effectiveMacAlgorithm.id,
      'signatureMode': effectiveSignatureMode.id,
      'kdf': <String, Object?>{
        'id': 'scrypt',
        'n': strength.scryptN,
        'r': strength.scryptR,
        'p': strength.scryptP,
      },
      'salt': base64Encode(salt),
      'stages': stageMaps,
      'encoding': 'bytes',
      'fileName': fileName,
      'mediaType': mediaType,
      'keyFileSha256': keyFileHash,
      'plainSha256': plainSha,
      'ciphertext': base64Encode(cipherBytes),
      'mac': mac,
      'signature': signature,
      'signaturePublic': signaturePublic,
    };

    return ToolboxCryptoEncryptResult(
      envelopeBytes: Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
      cipherBytes: cipherBytes,
      algorithm: algorithm,
      strength: strength,
      cipherPreview: previewBase64(cipherBytes),
      plainBytes: plainBytes.length,
      keyFileSha256: keyFileHash,
      fileName: fileName,
      mediaType: mediaType,
    );
  }

  ToolboxCryptoDecryptResult decryptBytes({
    required Uint8List envelopeBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
  }) {
    if (envelopeBytes.isEmpty) {
      throw const ToolboxCryptoException('Input bytes are empty.');
    }
    final map = _decodeEnvelope(envelopeBytes);
    final version = map['version'];
    if (version != currentVersion) {
      throw const ToolboxCryptoException('Unsupported crypto version.');
    }
    final algorithm = _algorithmFromId(_readString(map, 'algorithm'));
    final strength = _strengthFromId(_readString(map, 'strength'));
    final keyBits = _keyBitsFromValue(map['keyBits']);
    final macAlgorithm = _macAlgorithmFromId(
      map['macAlgorithm'] as String? ?? ToolboxCryptoMacAlgorithm.sha256.id,
    );
    final signatureMode = _signatureModeFromId(
      map['signatureMode'] as String? ?? ToolboxCryptoSignatureMode.none.id,
    );
    _validateAlgorithmAndSecret(
      algorithm: algorithm,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );
    final salt = _readBase64(map, 'salt');
    final cipherBytes = _readBase64(map, 'ciphertext');
    final mac = _readString(map, 'mac');
    final plainSha = _readString(map, 'plainSha256');
    final keyFileHash = map['keyFileSha256'] as String?;
    final fileName = map['fileName'] as String?;
    final mediaType = map['mediaType'] as String?;
    final actualKeyFileHash = _keyFileHash(keyFileBytes);
    if (keyFileHash != actualKeyFileHash) {
      throw const ToolboxCryptoException(
        'Key file mismatch or missing key file.',
      );
    }
    final stageMaps = _readStages(map);
    final associatedData = _associatedData(
      version: currentVersion,
      algorithm: algorithm,
      strength: strength,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
      salt: salt,
      plainSha256: plainSha,
      stages: stageMaps,
      keyFileSha256: keyFileHash,
      fileName: fileName,
      mediaType: mediaType,
    );
    final expectedMac = _hmacHex(
      algorithm: macAlgorithm,
      key: _deriveMacKey(
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
        salt: salt,
        strength: strength,
        macAlgorithm: macAlgorithm,
      ),
      bytes: <int>[...associatedData, 0, ...cipherBytes],
    );
    if (!_constantTimeEquals(mac, expectedMac)) {
      throw const ToolboxCryptoException(
        'Passphrase mismatch or payload is damaged.',
      );
    }
    _verifyEnvelopeSignature(
      mode: signatureMode,
      signature: map['signature'],
      publicKey: map['signaturePublic'],
      data: <int>[...associatedData, 0, ...cipherBytes, 0, ...utf8.encode(mac)],
    );

    final stages = stageMaps
        .map(
          (stageMap) => _stageFromId(
            _readString(stageMap, 'id'),
            keyBytes: _stageKeyBytesFromMap(stageMap),
          ),
        )
        .toList(growable: false);
    final keyMaterial = _deriveKeyMaterial(
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      salt: salt,
      strength: strength,
      macAlgorithm: macAlgorithm,
      length: stages.fold<int>(0, (sum, stage) => sum + stage.keyBytes),
    );
    var keyOffset = keyMaterial.length;
    var activeBytes = Uint8List.fromList(cipherBytes);
    for (var index = stages.length - 1; index >= 0; index -= 1) {
      final stage = stages[index];
      final stageMap = stageMaps[index];
      final keyLength = stage.keyBytes;
      keyOffset -= keyLength;
      final key = Uint8List.sublistView(
        keyMaterial,
        keyOffset,
        keyOffset + keyLength,
      );
      activeBytes = stage.transform(
        encrypt: false,
        input: activeBytes,
        key: Uint8List.fromList(key),
        nonce: _readBase64(stageMap, 'nonce'),
        strength: strength,
      );
    }

    final output = Uint8List.fromList(activeBytes);
    final actualSha = _hashHex(ToolboxCryptoHashAlgorithm.sha256, output);
    if (!_constantTimeEquals(actualSha, plainSha)) {
      throw const ToolboxCryptoException('Payload checksum failed.');
    }
    return ToolboxCryptoDecryptResult(
      plainBytes: output,
      algorithm: algorithm,
      strength: strength,
      cipherPreview: previewBase64(cipherBytes),
      keyFileSha256: keyFileHash,
      fileName: fileName,
      mediaType: mediaType,
    );
  }

  ToolboxCryptoHashResult hashBytes({
    required Uint8List bytes,
    required ToolboxCryptoHashAlgorithm algorithm,
  }) {
    final digest = _hashBytes(algorithm, bytes);
    return ToolboxCryptoHashResult(
      algorithm: algorithm,
      hex: _hexDigest(digest),
      base64: base64Encode(digest),
    );
  }

  ToolboxCryptoKeyFileResult generateKeyFile({
    required int length,
    String fileName = 'vocabulary_sleep_keyfile.bin',
  }) {
    if (length < 32 || length > 1024 * 1024) {
      throw const ToolboxCryptoException(
        'Key file length must be between 32 bytes and 1 MB.',
      );
    }
    final bytes = _randomBytes(length);
    return ToolboxCryptoKeyFileResult(
      bytes: bytes,
      length: bytes.length,
      sha256: _hexDigest(crypto.sha256.convert(bytes).bytes),
      fileName: fileName,
    );
  }

  String previewBase64(Uint8List bytes, {int limit = 96}) {
    final text = base64Encode(bytes);
    if (text.length <= limit) {
      return text;
    }
    return '${text.substring(0, limit)}...';
  }

  Map<String, Object?> _decodeEnvelope(Uint8List envelopeBytes) {
    try {
      final decoded = jsonDecode(utf8.decode(envelopeBytes));
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    } on FormatException {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
  }

  void _validateAlgorithmAndSecret({
    required ToolboxCryptoAlgorithm algorithm,
    required String passphrase,
    required Uint8List? keyFileBytes,
  }) {
    if (!algorithm.isAvailable) {
      throw ToolboxCryptoException('${algorithm.label} is not available yet.');
    }
    if (algorithm.requiresSecret &&
        passphrase.trim().isEmpty &&
        (keyFileBytes == null || keyFileBytes.isEmpty)) {
      throw const ToolboxCryptoException('Passphrase or key file is required.');
    }
  }

  ToolboxCryptoMacAlgorithm _effectiveMacAlgorithm(
    ToolboxCryptoAlgorithm algorithm,
    ToolboxCryptoMacAlgorithm selected,
  ) {
    if (algorithm == ToolboxCryptoAlgorithm.whirlpoolDigest) {
      return ToolboxCryptoMacAlgorithm.whirlpool;
    }
    return selected;
  }

  ToolboxCryptoSignatureMode _effectiveSignatureMode(
    ToolboxCryptoAlgorithm algorithm,
    ToolboxCryptoSignatureMode selected,
  ) {
    return switch (algorithm) {
      ToolboxCryptoAlgorithm.sha256RsaSignature =>
        ToolboxCryptoSignatureMode.rsaSha256,
      ToolboxCryptoAlgorithm.ecdsaSignature =>
        ToolboxCryptoSignatureMode.ecdsaSha256,
      _ => selected,
    };
  }

  List<_CryptoStage> _stagesFor(
    ToolboxCryptoAlgorithm algorithm, {
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
  }) {
    return switch (algorithm) {
      ToolboxCryptoAlgorithm.none => const <_CryptoStage>[_CryptoStage.none()],
      ToolboxCryptoAlgorithm.aesGcm => <_CryptoStage>[
        _CryptoStage.aesGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.camelliaGcm => <_CryptoStage>[
        _CryptoStage.camelliaGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.twofishGcm => <_CryptoStage>[
        _CryptoStage.twofishGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.aesTwofishGcm => <_CryptoStage>[
        _CryptoStage.aesGcm(keyBytes: keyBits.bytes),
        _CryptoStage.twofishGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.aesCamelliaGcm => <_CryptoStage>[
        _CryptoStage.aesGcm(keyBytes: keyBits.bytes),
        _CryptoStage.camelliaGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm => <_CryptoStage>[
        _CryptoStage.aesGcm(keyBytes: keyBits.bytes),
        _CryptoStage.twofishGcm(keyBytes: keyBits.bytes),
        _CryptoStage.camelliaGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.customCascade => _customStages(
        cascade: cascade,
        keyBits: keyBits,
      ),
      ToolboxCryptoAlgorithm.sha256RsaSignature ||
      ToolboxCryptoAlgorithm.ecdsaSignature ||
      ToolboxCryptoAlgorithm.whirlpoolDigest => <_CryptoStage>[
        _CryptoStage.aesGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.sha256Stream => <_CryptoStage>[
        _CryptoStage.sha256Stream(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.rc4Legacy => const <_CryptoStage>[
        _CryptoStage.rc4Legacy(),
      ],
    };
  }

  List<_CryptoStage> _customStages({
    required List<ToolboxCryptoCascadeCipher>? cascade,
    required ToolboxCryptoKeyBits keyBits,
  }) {
    final selected = (cascade == null || cascade.isEmpty)
        ? const <ToolboxCryptoCascadeCipher>[ToolboxCryptoCascadeCipher.aes]
        : cascade;
    if (selected.length > 6) {
      throw const ToolboxCryptoException(
        'Custom cascade supports up to 6 stages.',
      );
    }
    return selected
        .map((cipher) => _stageForCascadeCipher(cipher, keyBits.bytes))
        .toList(growable: false);
  }

  _CryptoStage _stageForCascadeCipher(
    ToolboxCryptoCascadeCipher cipher,
    int keyBytes,
  ) {
    return switch (cipher) {
      ToolboxCryptoCascadeCipher.aes => _CryptoStage.aesGcm(keyBytes: keyBytes),
      ToolboxCryptoCascadeCipher.twofish => _CryptoStage.twofishGcm(
        keyBytes: keyBytes,
      ),
      ToolboxCryptoCascadeCipher.camellia => _CryptoStage.camelliaGcm(
        keyBytes: keyBytes,
      ),
      ToolboxCryptoCascadeCipher.sha256Stream => _CryptoStage.sha256Stream(
        keyBytes: keyBytes,
      ),
    };
  }

  int _keyMaterialLength(
    ToolboxCryptoAlgorithm algorithm, {
    required List<_CryptoStage> stages,
  }) {
    return stages.fold<int>(0, (sum, stage) => sum + stage.keyBytes);
  }

  Uint8List _deriveKeyMaterial({
    required String passphrase,
    required Uint8List? keyFileBytes,
    required Uint8List salt,
    required ToolboxCryptoStrength strength,
    required ToolboxCryptoMacAlgorithm macAlgorithm,
    required int length,
  }) {
    if (length == 0) {
      return Uint8List(0);
    }
    final secret = _secretBytes(passphrase, keyFileBytes);
    final derivedSalt = _derivePurposeSalt(salt, 'key-${macAlgorithm.id}');
    final derivator = pc.Scrypt()
      ..init(
        pc.ScryptParameters(
          strength.scryptN,
          strength.scryptR,
          strength.scryptP,
          length,
          derivedSalt,
        ),
      );
    return derivator.process(secret);
  }

  Uint8List _deriveMacKey({
    required String passphrase,
    required Uint8List? keyFileBytes,
    required Uint8List salt,
    required ToolboxCryptoStrength strength,
    required ToolboxCryptoMacAlgorithm macAlgorithm,
  }) {
    final macSalt = _derivePurposeSalt(salt, 'mac-${macAlgorithm.id}');
    final derivator = pc.Scrypt()
      ..init(
        pc.ScryptParameters(
          strength.scryptN,
          strength.scryptR,
          strength.scryptP,
          32,
          macSalt,
        ),
      );
    return derivator.process(_secretBytes(passphrase, keyFileBytes));
  }

  Uint8List _deriveSignatureSeed({
    required String passphrase,
    required Uint8List? keyFileBytes,
    required Uint8List salt,
    required ToolboxCryptoStrength strength,
    required ToolboxCryptoMacAlgorithm macAlgorithm,
  }) {
    final signatureSalt = _derivePurposeSalt(
      salt,
      'signature-${macAlgorithm.id}',
    );
    final derivator = pc.Scrypt()
      ..init(
        pc.ScryptParameters(
          strength.scryptN,
          strength.scryptR,
          strength.scryptP,
          64,
          signatureSalt,
        ),
      );
    return derivator.process(_secretBytes(passphrase, keyFileBytes));
  }

  Uint8List _derivePurposeSalt(Uint8List salt, String purpose) {
    return Uint8List.fromList(
      crypto.sha256.convert(<int>[...salt, 0, ...utf8.encode(purpose)]).bytes,
    );
  }

  Uint8List _secretBytes(String passphrase, Uint8List? keyFileBytes) {
    final keyFileDigest = keyFileBytes == null
        ? Uint8List(0)
        : Uint8List.fromList(crypto.sha256.convert(keyFileBytes).bytes);
    return Uint8List.fromList(<int>[
      ...utf8.encode('vocabulary_sleep_crypto_v2'),
      0,
      ...utf8.encode(passphrase),
      0,
      ...keyFileDigest,
    ]);
  }

  String? _keyFileHash(Uint8List? keyFileBytes) {
    if (keyFileBytes == null || keyFileBytes.isEmpty) {
      return null;
    }
    return _hexDigest(crypto.sha256.convert(keyFileBytes).bytes);
  }

  Uint8List _associatedData({
    required int version,
    required ToolboxCryptoAlgorithm algorithm,
    required ToolboxCryptoStrength strength,
    required ToolboxCryptoKeyBits keyBits,
    required ToolboxCryptoMacAlgorithm macAlgorithm,
    required ToolboxCryptoSignatureMode signatureMode,
    required Uint8List salt,
    required String plainSha256,
    required List<Map<String, Object?>> stages,
    required String? keyFileSha256,
    required String? fileName,
    required String? mediaType,
  }) {
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'version': version,
          'algorithm': algorithm.id,
          'strength': strength.id,
          'keyBits': keyBits.bits,
          'macAlgorithm': macAlgorithm.id,
          'signatureMode': signatureMode.id,
          'salt': base64Encode(salt),
          'plainSha256': plainSha256,
          'stages': stages,
          'keyFileSha256': keyFileSha256,
          'fileName': fileName,
          'mediaType': mediaType,
        }),
      ),
    );
  }

  Uint8List _hashBytes(ToolboxCryptoHashAlgorithm algorithm, Uint8List bytes) {
    return switch (algorithm) {
      ToolboxCryptoHashAlgorithm.sha256 => Uint8List.fromList(
        crypto.sha256.convert(bytes).bytes,
      ),
      ToolboxCryptoHashAlgorithm.sha512 => Uint8List.fromList(
        crypto.sha512.convert(bytes).bytes,
      ),
      ToolboxCryptoHashAlgorithm.sha3_256 => pc.SHA3Digest(256).process(bytes),
      ToolboxCryptoHashAlgorithm.sha3_512 => pc.SHA3Digest(512).process(bytes),
      ToolboxCryptoHashAlgorithm.blake2b256 => pc.Blake2bDigest(
        digestSize: 32,
      ).process(bytes),
      ToolboxCryptoHashAlgorithm.blake2b512 => pc.Blake2bDigest(
        digestSize: 64,
      ).process(bytes),
      ToolboxCryptoHashAlgorithm.whirlpool => pc.WhirlpoolDigest().process(
        bytes,
      ),
    };
  }

  String _hashHex(ToolboxCryptoHashAlgorithm algorithm, Uint8List bytes) {
    return _hexDigest(_hashBytes(algorithm, bytes));
  }

  String _hmacHex({
    required ToolboxCryptoMacAlgorithm algorithm,
    required Uint8List key,
    required List<int> bytes,
  }) {
    return switch (algorithm) {
      ToolboxCryptoMacAlgorithm.sha256 => _hexDigest(
        crypto.Hmac(crypto.sha256, key).convert(bytes).bytes,
      ),
      ToolboxCryptoMacAlgorithm.whirlpool => _hexDigest(
        _pointyHmac(pc.WhirlpoolDigest(), 64, key, bytes),
      ),
    };
  }

  ToolboxCryptoAlgorithm _algorithmFromId(String id) {
    for (final algorithm in ToolboxCryptoAlgorithm.values) {
      if (algorithm.id == id) {
        return algorithm;
      }
    }
    throw const ToolboxCryptoException('Unsupported encryption algorithm.');
  }

  ToolboxCryptoStrength _strengthFromId(String id) {
    for (final strength in ToolboxCryptoStrength.values) {
      if (strength.id == id) {
        return strength;
      }
    }
    throw const ToolboxCryptoException('Unsupported encryption strength.');
  }

  ToolboxCryptoKeyBits _keyBitsFromValue(Object? value) {
    final bits = value is int
        ? value
        : value is String
        ? int.tryParse(value)
        : null;
    return switch (bits) {
      512 => ToolboxCryptoKeyBits.bits512,
      1024 => ToolboxCryptoKeyBits.bits1024,
      _ => ToolboxCryptoKeyBits.bits256,
    };
  }

  ToolboxCryptoMacAlgorithm _macAlgorithmFromId(String id) {
    for (final algorithm in ToolboxCryptoMacAlgorithm.values) {
      if (algorithm.id == id) {
        return algorithm;
      }
    }
    throw const ToolboxCryptoException('Unsupported MAC algorithm.');
  }

  ToolboxCryptoSignatureMode _signatureModeFromId(String id) {
    for (final mode in ToolboxCryptoSignatureMode.values) {
      if (mode.id == id) {
        return mode;
      }
    }
    throw const ToolboxCryptoException('Unsupported signature algorithm.');
  }

  _CryptoStage _stageFromId(String id, {int? keyBytes}) {
    final stages = <_CryptoStage>[
      const _CryptoStage.none(),
      _CryptoStage.aesGcm(keyBytes: keyBytes ?? 32),
      _CryptoStage.camelliaGcm(keyBytes: keyBytes ?? 32),
      _CryptoStage.twofishGcm(keyBytes: keyBytes ?? 32),
      _CryptoStage.sha256Stream(keyBytes: keyBytes ?? 32),
      const _CryptoStage.rc4Legacy(),
    ];
    for (final stage in stages) {
      if (stage.id == id) {
        return stage;
      }
    }
    throw const ToolboxCryptoException('Unsupported encryption stage.');
  }

  int _stageKeyBytesFromMap(Map<String, Object?> map) {
    final raw = map['keyBits'];
    final bits = raw is int
        ? raw
        : raw is String
        ? int.tryParse(raw)
        : null;
    return switch (bits) {
      512 => 64,
      1024 => 128,
      _ => 32,
    };
  }

  List<Map<String, Object?>> _readStages(Map<String, Object?> map) {
    final raw = map['stages'];
    if (raw is! List<Object?> || raw.isEmpty) {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
    return raw
        .map((item) {
          if (item is Map<String, Object?>) {
            return item;
          }
          throw const ToolboxCryptoException('Crypto envelope is invalid.');
        })
        .toList(growable: false);
  }

  String _readString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String) {
      return value;
    }
    throw const ToolboxCryptoException('Crypto envelope is invalid.');
  }

  Uint8List _readBase64(Map<String, Object?> map, String key) {
    try {
      return Uint8List.fromList(base64Decode(_readString(map, key)));
    } on FormatException {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
  }

  Map<String, Object?>? _signEnvelope({
    required ToolboxCryptoSignatureMode mode,
    required Uint8List keySeed,
    required List<int> data,
  }) {
    return switch (mode) {
      ToolboxCryptoSignatureMode.none => null,
      ToolboxCryptoSignatureMode.rsaSha256 => _rsaSignatureMap(
        keySeed: keySeed,
        data: data,
      ),
      ToolboxCryptoSignatureMode.ecdsaSha256 => _ecdsaSignatureMap(
        keySeed: keySeed,
        data: data,
      ),
    };
  }

  Map<String, Object?>? _signaturePublicKey({
    required ToolboxCryptoSignatureMode mode,
    required Uint8List keySeed,
  }) {
    return switch (mode) {
      ToolboxCryptoSignatureMode.none => null,
      ToolboxCryptoSignatureMode.rsaSha256 => _rsaPublicKeyMap(keySeed),
      ToolboxCryptoSignatureMode.ecdsaSha256 => _ecdsaPublicKeyMap(keySeed),
    };
  }

  Map<String, Object?> _rsaSignatureMap({
    required Uint8List keySeed,
    required List<int> data,
  }) {
    final keyPair = _rsaKeyPair(keySeed);
    final signer = pc.Signer(
      'SHA-256/RSA',
    )..init(true, pc.PrivateKeyParameter<pc.RSAPrivateKey>(keyPair.privateKey));
    final signature =
        signer.generateSignature(Uint8List.fromList(data)) as pc.RSASignature;
    return <String, Object?>{
      'mode': ToolboxCryptoSignatureMode.rsaSha256.id,
      'value': base64Encode(signature.bytes),
    };
  }

  Map<String, Object?> _ecdsaSignatureMap({
    required Uint8List keySeed,
    required List<int> data,
  }) {
    final keyPair = _ecKeyPair(keySeed);
    final signer = pc.Signer('SHA-256/DET-ECDSA')
      ..init(true, pc.PrivateKeyParameter<pc.ECPrivateKey>(keyPair.privateKey));
    final signature =
        signer.generateSignature(Uint8List.fromList(data)) as pc.ECSignature;
    return <String, Object?>{
      'mode': ToolboxCryptoSignatureMode.ecdsaSha256.id,
      'r': _bigIntToBase64(signature.r),
      's': _bigIntToBase64(signature.s),
    };
  }

  void _verifyEnvelopeSignature({
    required ToolboxCryptoSignatureMode mode,
    required Object? signature,
    required Object? publicKey,
    required List<int> data,
  }) {
    switch (mode) {
      case ToolboxCryptoSignatureMode.none:
        return;
      case ToolboxCryptoSignatureMode.rsaSha256:
        if (signature is! Map<String, Object?> ||
            publicKey is! Map<String, Object?>) {
          throw const ToolboxCryptoException('Signature is invalid.');
        }
        final key = _rsaPublicKeyFromMap(publicKey);
        final signer = pc.Signer('SHA-256/RSA')
          ..init(false, pc.PublicKeyParameter<pc.RSAPublicKey>(key));
        final ok = signer.verifySignature(
          Uint8List.fromList(data),
          pc.RSASignature(_readBase64(signature, 'value')),
        );
        if (!ok) {
          throw const ToolboxCryptoException('Signature verification failed.');
        }
        return;
      case ToolboxCryptoSignatureMode.ecdsaSha256:
        if (signature is! Map<String, Object?> ||
            publicKey is! Map<String, Object?>) {
          throw const ToolboxCryptoException('Signature is invalid.');
        }
        final key = _ecdsaPublicKeyFromMap(publicKey);
        final signer = pc.Signer('SHA-256/DET-ECDSA')
          ..init(false, pc.PublicKeyParameter<pc.ECPublicKey>(key));
        final ok = signer.verifySignature(
          Uint8List.fromList(data),
          pc.ECSignature(
            _bigIntFromBase64(_readString(signature, 'r')),
            _bigIntFromBase64(_readString(signature, 's')),
          ),
        );
        if (!ok) {
          throw const ToolboxCryptoException('Signature verification failed.');
        }
        return;
    }
  }

  pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey> _rsaKeyPair(
    Uint8List seed,
  ) {
    final random = _fortuna(seed);
    final generator = pc.RSAKeyGenerator()
      ..init(
        pc.ParametersWithRandom<pc.RSAKeyGeneratorParameters>(
          pc.RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 12),
          random,
        ),
      );
    return generator.generateKeyPair();
  }

  pc.AsymmetricKeyPair<pc.ECPublicKey, pc.ECPrivateKey> _ecKeyPair(
    Uint8List seed,
  ) {
    final domain = pc.ECDomainParameters('secp256r1');
    final generator = pc.ECKeyGenerator()
      ..init(
        pc.ParametersWithRandom<pc.ECKeyGeneratorParameters>(
          pc.ECKeyGeneratorParameters(domain),
          _fortuna(seed),
        ),
      );
    return generator.generateKeyPair();
  }

  Map<String, Object?> _rsaPublicKeyMap(Uint8List keySeed) {
    final key = _rsaKeyPair(keySeed).publicKey;
    return <String, Object?>{
      'n': _bigIntToBase64(key.modulus!),
      'e': _bigIntToBase64(key.publicExponent!),
    };
  }

  Map<String, Object?> _ecdsaPublicKeyMap(Uint8List keySeed) {
    final key = _ecKeyPair(keySeed).publicKey;
    return <String, Object?>{
      'curve': key.parameters!.domainName,
      'q': base64Encode(key.Q!.getEncoded(false)),
    };
  }

  pc.RSAPublicKey _rsaPublicKeyFromMap(Map<String, Object?> map) {
    return pc.RSAPublicKey(
      _bigIntFromBase64(_readString(map, 'n')),
      _bigIntFromBase64(_readString(map, 'e')),
    );
  }

  pc.ECPublicKey _ecdsaPublicKeyFromMap(Map<String, Object?> map) {
    final domain = pc.ECDomainParameters(_readString(map, 'curve'));
    return pc.ECPublicKey(
      domain.curve.decodePoint(_readBase64(map, 'q')),
      domain,
    );
  }

  pc.FortunaRandom _fortuna(Uint8List seed) {
    final normalizedSeed = Uint8List.fromList(
      crypto.sha256.convert(seed).bytes,
    );
    return pc.FortunaRandom()..seed(pc.KeyParameter(normalizedSeed));
  }

  Uint8List _pointyHmac(
    pc.Digest digest,
    int blockLength,
    Uint8List key,
    List<int> bytes,
  ) {
    final mac = pc.HMac(digest, blockLength)..init(pc.KeyParameter(key));
    return mac.process(Uint8List.fromList(bytes));
  }

  String _bigIntToBase64(BigInt value) {
    return base64Encode(_encodeUnsignedBigInt(value));
  }

  BigInt _bigIntFromBase64(String value) {
    return _decodeUnsignedBigInt(base64Decode(value));
  }

  Uint8List _encodeUnsignedBigInt(BigInt value) {
    if (value == BigInt.zero) {
      return Uint8List.fromList(<int>[0]);
    }
    final bytes = <int>[];
    var active = value;
    while (active > BigInt.zero) {
      bytes.add((active & BigInt.from(0xff)).toInt());
      active = active >> 8;
    }
    return Uint8List.fromList(bytes.reversed.toList(growable: false));
  }

  BigInt _decodeUnsignedBigInt(List<int> bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte & 0xff);
    }
    return result;
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _secureRandom.nextInt(256)),
    );
  }

  bool _constantTimeEquals(String a, String b) {
    final left = a.codeUnits;
    final right = b.codeUnits;
    var diff = left.length ^ right.length;
    final maxLength = math.max(left.length, right.length);
    for (var i = 0; i < maxLength; i += 1) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      diff |= l ^ r;
    }
    return diff == 0;
  }

  String _hexDigest(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

class _CryptoStage {
  const _CryptoStage({
    required this.id,
    required this.keyBytes,
    required this.usesNonce,
    required this.transform,
  });

  const _CryptoStage.none()
    : this(
        id: 'none',
        keyBytes: 0,
        usesNonce: false,
        transform: _noneTransform,
      );

  const _CryptoStage.aesGcm({int keyBytes = 32})
    : this(
        id: 'aes_gcm',
        keyBytes: keyBytes,
        usesNonce: true,
        transform: _aesGcmTransform,
      );

  const _CryptoStage.camelliaGcm({int keyBytes = 32})
    : this(
        id: 'camellia_gcm',
        keyBytes: keyBytes,
        usesNonce: true,
        transform: _camelliaGcmTransform,
      );

  const _CryptoStage.twofishGcm({int keyBytes = 32})
    : this(
        id: 'twofish_gcm',
        keyBytes: keyBytes,
        usesNonce: true,
        transform: _twofishGcmTransform,
      );

  const _CryptoStage.sha256Stream({int keyBytes = 32})
    : this(
        id: 'sha256_stream',
        keyBytes: keyBytes,
        usesNonce: true,
        transform: _sha256StreamTransform,
      );

  const _CryptoStage.rc4Legacy()
    : this(
        id: 'rc4_legacy',
        keyBytes: 32,
        usesNonce: true,
        transform: _rc4LegacyTransform,
      );

  final String id;
  final int keyBytes;
  final bool usesNonce;
  final _CryptoStageTransform transform;
}

typedef _CryptoStageTransform =
    Uint8List Function({
      required bool encrypt,
      required Uint8List input,
      required Uint8List key,
      required Uint8List nonce,
      required ToolboxCryptoStrength strength,
    });

Uint8List _noneTransform({
  required bool encrypt,
  required Uint8List input,
  required Uint8List key,
  required Uint8List nonce,
  required ToolboxCryptoStrength strength,
}) {
  return Uint8List.fromList(input);
}

Uint8List _aesGcmTransform({
  required bool encrypt,
  required Uint8List input,
  required Uint8List key,
  required Uint8List nonce,
  required ToolboxCryptoStrength strength,
}) {
  return _gcmTransform(
    engine: pc.AESEngine(),
    engineId: 'aes_gcm',
    encrypt: encrypt,
    input: input,
    key: key,
    nonce: nonce,
  );
}

Uint8List _camelliaGcmTransform({
  required bool encrypt,
  required Uint8List input,
  required Uint8List key,
  required Uint8List nonce,
  required ToolboxCryptoStrength strength,
}) {
  return _gcmTransform(
    engine: pc.CamelliaEngine(),
    engineId: 'camellia_gcm',
    encrypt: encrypt,
    input: input,
    key: key,
    nonce: nonce,
  );
}

Uint8List _twofishGcmTransform({
  required bool encrypt,
  required Uint8List input,
  required Uint8List key,
  required Uint8List nonce,
  required ToolboxCryptoStrength strength,
}) {
  return _gcmTransform(
    engine: pc.TwofishEngine(),
    engineId: 'twofish_gcm',
    encrypt: encrypt,
    input: input,
    key: key,
    nonce: nonce,
  );
}

Uint8List _gcmTransform({
  required pc.BlockCipher engine,
  required String engineId,
  required bool encrypt,
  required Uint8List input,
  required Uint8List key,
  required Uint8List nonce,
}) {
  try {
    final cipher = pc.GCMBlockCipher(engine)
      ..init(
        encrypt,
        pc.AEADParameters(
          pc.KeyParameter(_gcmCipherKey(key, engineId)),
          128,
          nonce,
          Uint8List(0),
        ),
      );
    return cipher.process(input);
  } on Object catch (error) {
    if (error is pc.InvalidCipherTextException) {
      throw const ToolboxCryptoException(
        'Passphrase mismatch or payload is damaged.',
      );
    }
    throw ToolboxCryptoException('Encryption failed: $error');
  }
}

Uint8List _gcmCipherKey(Uint8List key, String engineId) {
  if (key.length == 16 || key.length == 24 || key.length == 32) {
    return key;
  }
  return Uint8List.fromList(
    crypto.sha256.convert(<int>[...utf8.encode(engineId), 0, ...key]).bytes,
  );
}

Uint8List _sha256StreamTransform({
  required bool encrypt,
  required Uint8List input,
  required Uint8List key,
  required Uint8List nonce,
  required ToolboxCryptoStrength strength,
}) {
  final output = Uint8List(input.length);
  var offset = 0;
  var counter = 0;
  while (offset < input.length) {
    final streamBlock = crypto.sha256.convert(<int>[
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

Uint8List _rc4LegacyTransform({
  required bool encrypt,
  required Uint8List input,
  required Uint8List key,
  required Uint8List nonce,
  required ToolboxCryptoStrength strength,
}) {
  return _rc4(input, Uint8List.fromList(<int>[...key, ...nonce]));
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

Uint8List _uint64Bytes(int value) {
  return Uint8List.fromList(
    List<int>.generate(8, (index) => (value >> ((7 - index) * 8)) & 255),
  );
}
