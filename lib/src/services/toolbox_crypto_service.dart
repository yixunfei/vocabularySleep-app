import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart' as pc;

import 'toolbox_veracrypt_primitives.dart';

enum ToolboxCryptoAlgorithm {
  none,
  aesGcm,
  chacha20Poly1305,
  camelliaGcm,
  twofishGcm,
  serpentGcm,
  kuznyechikGcm,
  aesTwofishGcm,
  aesCamelliaGcm,
  aesTwofishCamelliaGcm,
  aesSerpentKuznyechikGcm,
  aesTwofishCamelliaSerpentKuznyechikGcm,
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
      ToolboxCryptoAlgorithm.chacha20Poly1305 => 'chacha20_poly1305',
      ToolboxCryptoAlgorithm.camelliaGcm => 'camellia_gcm',
      ToolboxCryptoAlgorithm.twofishGcm => 'twofish_gcm',
      ToolboxCryptoAlgorithm.serpentGcm => 'serpent_gcm',
      ToolboxCryptoAlgorithm.kuznyechikGcm => 'kuznyechik_gcm',
      ToolboxCryptoAlgorithm.aesTwofishGcm => 'aes_twofish_gcm',
      ToolboxCryptoAlgorithm.aesCamelliaGcm => 'aes_camellia_gcm',
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm =>
        'aes_twofish_camellia_gcm',
      ToolboxCryptoAlgorithm.aesSerpentKuznyechikGcm =>
        'aes_serpent_kuznyechik_gcm',
      ToolboxCryptoAlgorithm.aesTwofishCamelliaSerpentKuznyechikGcm =>
        'aes_twofish_camellia_serpent_kuznyechik_gcm',
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
      ToolboxCryptoAlgorithm.chacha20Poly1305 => 'ChaCha20-Poly1305',
      ToolboxCryptoAlgorithm.camelliaGcm => 'Camellia-GCM',
      ToolboxCryptoAlgorithm.twofishGcm => 'Twofish-GCM',
      ToolboxCryptoAlgorithm.serpentGcm => 'Serpent-GCM',
      ToolboxCryptoAlgorithm.kuznyechikGcm => 'Kuznyechik-GCM',
      ToolboxCryptoAlgorithm.aesTwofishGcm => 'AES + Twofish',
      ToolboxCryptoAlgorithm.aesCamelliaGcm => 'AES + Camellia',
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm =>
        'AES + Twofish + Camellia',
      ToolboxCryptoAlgorithm.aesSerpentKuznyechikGcm =>
        'AES + Serpent + Kuznyechik',
      ToolboxCryptoAlgorithm.aesTwofishCamelliaSerpentKuznyechikGcm =>
        'AES + Twofish + Camellia + Serpent + Kuznyechik',
      ToolboxCryptoAlgorithm.customCascade => 'Custom cascade',
      ToolboxCryptoAlgorithm.sha256Stream => 'SHA256 stream',
      ToolboxCryptoAlgorithm.rc4Legacy => 'RC4 legacy',
      ToolboxCryptoAlgorithm.sha256RsaSignature => 'Package-local RSA check',
      ToolboxCryptoAlgorithm.ecdsaSignature => 'Package-local ECDSA check',
      ToolboxCryptoAlgorithm.whirlpoolDigest => 'Whirlpool digest',
    };
  }

  bool get requiresSecret => this != ToolboxCryptoAlgorithm.none;

  bool get canEncrypt {
    return switch (this) {
      ToolboxCryptoAlgorithm.sha256Stream ||
      ToolboxCryptoAlgorithm.rc4Legacy => false,
      _ => true,
    };
  }

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
      ToolboxCryptoAlgorithm.chacha20Poly1305 => 256,
      ToolboxCryptoAlgorithm.camelliaGcm => 256,
      ToolboxCryptoAlgorithm.twofishGcm => 256,
      ToolboxCryptoAlgorithm.serpentGcm => 256,
      ToolboxCryptoAlgorithm.kuznyechikGcm => 256,
      ToolboxCryptoAlgorithm.aesTwofishGcm => 512,
      ToolboxCryptoAlgorithm.aesCamelliaGcm => 512,
      ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm => 768,
      ToolboxCryptoAlgorithm.aesSerpentKuznyechikGcm => 768,
      ToolboxCryptoAlgorithm.aesTwofishCamelliaSerpentKuznyechikGcm => 1024,
      ToolboxCryptoAlgorithm.customCascade => 256,
      ToolboxCryptoAlgorithm.sha256Stream => 256,
      ToolboxCryptoAlgorithm.rc4Legacy => 256,
      ToolboxCryptoAlgorithm.sha256RsaSignature => 256,
      ToolboxCryptoAlgorithm.ecdsaSignature => 256,
      ToolboxCryptoAlgorithm.whirlpoolDigest => 512,
    };
  }
}

enum ToolboxCryptoCascadeCipher {
  aes,
  chacha20,
  twofish,
  camellia,
  serpent,
  kuznyechik,
  sha256Stream,
}

extension ToolboxCryptoCascadeCipherInfo on ToolboxCryptoCascadeCipher {
  String get id {
    return switch (this) {
      ToolboxCryptoCascadeCipher.aes => 'aes_gcm',
      ToolboxCryptoCascadeCipher.chacha20 => 'chacha20_poly1305',
      ToolboxCryptoCascadeCipher.twofish => 'twofish_gcm',
      ToolboxCryptoCascadeCipher.camellia => 'camellia_gcm',
      ToolboxCryptoCascadeCipher.serpent => 'serpent_gcm',
      ToolboxCryptoCascadeCipher.kuznyechik => 'kuznyechik_gcm',
      ToolboxCryptoCascadeCipher.sha256Stream => 'sha256_stream',
    };
  }

  String get label {
    return switch (this) {
      ToolboxCryptoCascadeCipher.aes => 'AES-GCM',
      ToolboxCryptoCascadeCipher.chacha20 => 'ChaCha20-Poly1305',
      ToolboxCryptoCascadeCipher.twofish => 'Twofish-GCM',
      ToolboxCryptoCascadeCipher.camellia => 'Camellia-GCM',
      ToolboxCryptoCascadeCipher.serpent => 'Serpent-GCM',
      ToolboxCryptoCascadeCipher.kuznyechik => 'Kuznyechik-GCM',
      ToolboxCryptoCascadeCipher.sha256Stream => 'SHA256 stream (weak)',
    };
  }
}

enum ToolboxCryptoKeyBits { bits256, bits512, bits1024, bits2048, bits4096 }

extension ToolboxCryptoKeyBitsInfo on ToolboxCryptoKeyBits {
  String get id {
    return switch (this) {
      ToolboxCryptoKeyBits.bits256 => '256',
      ToolboxCryptoKeyBits.bits512 => '512',
      ToolboxCryptoKeyBits.bits1024 => '1024',
      ToolboxCryptoKeyBits.bits2048 => '2048',
      ToolboxCryptoKeyBits.bits4096 => '4096',
    };
  }

  int get bits {
    return switch (this) {
      ToolboxCryptoKeyBits.bits256 => 256,
      ToolboxCryptoKeyBits.bits512 => 512,
      ToolboxCryptoKeyBits.bits1024 => 1024,
      ToolboxCryptoKeyBits.bits2048 => 2048,
      ToolboxCryptoKeyBits.bits4096 => 4096,
    };
  }

  int get bytes => bits ~/ 8;
}

enum ToolboxCryptoSignatureMode { none, weakSha256, rsaSha256, ecdsaSha256 }

extension ToolboxCryptoSignatureModeInfo on ToolboxCryptoSignatureMode {
  String get id {
    return switch (this) {
      ToolboxCryptoSignatureMode.none => 'none',
      ToolboxCryptoSignatureMode.weakSha256 => 'weak_sha256',
      ToolboxCryptoSignatureMode.rsaSha256 => 'rsa_sha256',
      ToolboxCryptoSignatureMode.ecdsaSha256 => 'ecdsa_sha256',
    };
  }

  String get label {
    return switch (this) {
      ToolboxCryptoSignatureMode.none => 'No package check',
      ToolboxCryptoSignatureMode.weakSha256 => 'Weak SHA-256',
      ToolboxCryptoSignatureMode.rsaSha256 => 'Package-local RSA check',
      ToolboxCryptoSignatureMode.ecdsaSha256 => 'Package-local ECDSA check',
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
      ToolboxCryptoStrength.standard => 1 << 16,
      ToolboxCryptoStrength.strong => 1 << 17,
      ToolboxCryptoStrength.extreme => 1 << 18,
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
  md5,
  sha1,
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
      ToolboxCryptoHashAlgorithm.md5 => 'md5',
      ToolboxCryptoHashAlgorithm.sha1 => 'sha1',
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
      ToolboxCryptoHashAlgorithm.md5 => 'MD5',
      ToolboxCryptoHashAlgorithm.sha1 => 'SHA-1',
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

enum ToolboxCryptoAsymmetricAlgorithm { rsa2048, ecP256 }

extension ToolboxCryptoAsymmetricAlgorithmInfo
    on ToolboxCryptoAsymmetricAlgorithm {
  String get id {
    return switch (this) {
      ToolboxCryptoAsymmetricAlgorithm.rsa2048 => 'rsa_2048',
      ToolboxCryptoAsymmetricAlgorithm.ecP256 => 'ec_p256',
    };
  }

  String get label {
    return switch (this) {
      ToolboxCryptoAsymmetricAlgorithm.rsa2048 => 'RSA-2048',
      ToolboxCryptoAsymmetricAlgorithm.ecP256 => 'ECC P-256',
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

class ToolboxCryptoEnvelopeSizeEstimate {
  const ToolboxCryptoEnvelopeSizeEstimate({
    required this.minimumBytes,
    required this.recommendedBytes,
    required this.minimumCipherBytes,
    required this.recommendedCipherBytes,
  });

  final int minimumBytes;
  final int recommendedBytes;
  final int minimumCipherBytes;
  final int recommendedCipherBytes;
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

class ToolboxCryptoKeyFileInput {
  ToolboxCryptoKeyFileInput({required this.name, required Uint8List bytes})
    : bytes = Uint8List.fromList(bytes) {
    final digest = crypto.sha256.convert(this.bytes);
    sha256 = digest.toString();
    sha256Base64 = base64Encode(digest.bytes);
  }

  final String name;
  final Uint8List bytes;
  late final String sha256;
  late final String sha256Base64;
}

class ToolboxCryptoKeyFileEntryInfo {
  const ToolboxCryptoKeyFileEntryInfo({
    required this.name,
    required this.length,
    required this.sha256,
  });

  final String name;
  final int length;
  final String sha256;
}

class ToolboxCryptoCombinedKeyFileResult {
  const ToolboxCryptoCombinedKeyFileResult({
    required this.bytes,
    required this.length,
    required this.sha256,
    required this.fileName,
    required this.entries,
  });

  final Uint8List bytes;
  final int length;
  final String sha256;
  final String fileName;
  final List<ToolboxCryptoKeyFileEntryInfo> entries;
}

class ToolboxCryptoAsymmetricKeyPairResult {
  const ToolboxCryptoAsymmetricKeyPairResult({
    required this.algorithm,
    required this.publicKeyText,
    required this.privateKeyText,
    required this.publicKeyFingerprint,
  });

  final ToolboxCryptoAsymmetricAlgorithm algorithm;
  final String publicKeyText;
  final String privateKeyText;
  final String publicKeyFingerprint;
}

class ToolboxCryptoAsymmetricSignatureResult {
  const ToolboxCryptoAsymmetricSignatureResult({
    required this.algorithm,
    required this.signatureText,
    required this.publicKeyFingerprint,
  });

  final ToolboxCryptoAsymmetricAlgorithm algorithm;
  final String signatureText;
  final String publicKeyFingerprint;
}

class ToolboxCryptoAsymmetricVerifyResult {
  const ToolboxCryptoAsymmetricVerifyResult({
    required this.algorithm,
    required this.isValid,
    required this.publicKeyFingerprint,
  });

  final ToolboxCryptoAsymmetricAlgorithm algorithm;
  final bool isValid;
  final String publicKeyFingerprint;
}

class ToolboxCryptoAsymmetricCipherResult {
  const ToolboxCryptoAsymmetricCipherResult({
    required this.algorithm,
    required this.cipherText,
    required this.publicKeyFingerprint,
    required this.cipherBytes,
  });

  final ToolboxCryptoAsymmetricAlgorithm algorithm;
  final String cipherText;
  final String publicKeyFingerprint;
  final int cipherBytes;
}

class ToolboxCryptoService {
  static const int currentVersion = 5;
  static const int maxRsaOaepSha256PlainBytes = 190;
  static const int _legacyJsonVersion = 4;
  static const int maxPlainBytes = 256 * 1024 * 1024;
  static const int maxCipherBytes = maxPlainBytes + 2 * 1024 * 1024;
  static const int maxEnvelopeBytes = 384 * 1024 * 1024;
  static const int maxKeyFileBytes = 1024 * 1024;
  static const int maxCombinedKeyFileBytes = 8 * maxKeyFileBytes;
  static const int _maxProtectedMetadataBytes = 64 * 1024;
  static const int _maxProtectedMetadataCipherBytes =
      _maxProtectedMetadataBytes + 32;
  static const int _maxStageCount = 8;
  static const int _minScryptN = 1 << 16;
  static const int _minScryptR = 8;
  static const int _minScryptP = 1;
  static const int _maxScryptN = 1 << 18;
  static const int _maxScryptR = 8;
  static const int _maxScryptP = 2;
  static const int _maxSaltBytes = 64;
  static const int _maxNonceBytes = 32;
  static const int _maxSignatureBytes = 4096;
  static const int _maxPublicKeyBytes = 4096;
  static const int _maxAsymmetricJsonChars = 64 * 1024;
  static const int _maxAsymmetricTextBytes = 128 * 1024;
  static const String _asymmetricKeyFormat = 'vocabulary_sleep_asymmetric_key';
  static const String _asymmetricSignatureFormat =
      'vocabulary_sleep_asymmetric_signature';
  static const String _asymmetricCipherFormat =
      'vocabulary_sleep_asymmetric_cipher';
  static final math.Random _secureRandom = math.Random.secure();
  static final Uint8List _opaqueEnvelopeMagic = Uint8List.fromList(
    utf8.encode('VSCENC5!'),
  );
  static final List<int> _weakSignatureDomainKey = utf8.encode(
    'vocabulary_sleep_builtin_weak_signature_v1_not_a_private_key',
  );

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
    if (plainBytes.length > maxPlainBytes) {
      throw const ToolboxCryptoException('Input file is too large.');
    }
    if (!algorithm.canEncrypt) {
      throw const ToolboxCryptoException(
        'Legacy or weak algorithms can only decrypt existing payloads.',
      );
    }
    _validateAlgorithmAndSecret(
      algorithm: algorithm,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );

    final salt = _randomBytes(16);
    final kdfSettings = _KdfSettings.fromStrength(strength);
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
    final paddedPlain = _padPlainPayload(plainBytes);
    var activeBytes = Uint8List.fromList(paddedPlain);
    final stageMaps = <Map<String, Object?>>[];
    final rootKey = _deriveRootKey(
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      salt: salt,
      macAlgorithm: effectiveMacAlgorithm,
      kdfSettings: kdfSettings,
    );
    final keyMaterial = _expandRootKey(
      rootKey,
      'stage-key-${effectiveMacAlgorithm.id}',
      _keyMaterialLength(algorithm, stages: stages),
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
    final associatedData = _associatedData(
      version: currentVersion,
      algorithm: algorithm,
      strength: strength,
      keyBits: keyBits,
      macAlgorithm: effectiveMacAlgorithm,
      signatureMode: effectiveSignatureMode,
      salt: salt,
      stages: stageMaps,
      fileName: fileName,
      mediaType: mediaType,
      kdfSettings: kdfSettings,
      paddingMode: 'random-length-v1',
    );
    final macKey = _expandRootKey(
      rootKey,
      'mac-${effectiveMacAlgorithm.id}',
      32,
    );
    final mac = _hmacHex(
      algorithm: effectiveMacAlgorithm,
      key: macKey,
      bytes: <int>[...associatedData, 0, ...cipherBytes],
    );
    final signatureSeed =
        effectiveSignatureMode == ToolboxCryptoSignatureMode.none
        ? null
        : _expandRootKey(rootKey, 'signature-${effectiveMacAlgorithm.id}', 64);
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
    final protectedMetadata = <String, Object?>{
      'algorithm': algorithm.id,
      'strength': strength.id,
      'keyBits': keyBits.bits,
      'macAlgorithm': effectiveMacAlgorithm.id,
      'signatureMode': effectiveSignatureMode.id,
      'padding': <String, Object?>{
        'mode': 'random-length-v1',
        'cipherPlainBytes': paddedPlain.length,
      },
      'stages': stageMaps,
      'encoding': 'bytes',
      'fileName': fileName,
      'mediaType': mediaType,
      'mac': mac,
      'signature': signature,
      'signaturePublic': signaturePublic,
    };
    final headerRootKey =
        effectiveMacAlgorithm == ToolboxCryptoMacAlgorithm.sha256
        ? rootKey
        : _deriveRootKey(
            passphrase: passphrase,
            keyFileBytes: keyFileBytes,
            salt: salt,
            macAlgorithm: ToolboxCryptoMacAlgorithm.sha256,
            kdfSettings: kdfSettings,
          );
    final envelopeBytes = _encodeOpaqueEnvelopeV5(
      kdfSettings: kdfSettings,
      salt: salt,
      headerRootKey: headerRootKey,
      protectedMetadata: protectedMetadata,
      cipherBytes: cipherBytes,
    );

    return ToolboxCryptoEncryptResult(
      envelopeBytes: envelopeBytes,
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

  ToolboxCryptoEnvelopeSizeEstimate estimateEnvelopeSize({
    required int plainBytes,
    required ToolboxCryptoAlgorithm algorithm,
    required ToolboxCryptoStrength strength,
    String? fileName,
    String? mediaType,
    List<ToolboxCryptoCascadeCipher>? cascade,
    ToolboxCryptoKeyBits keyBits = ToolboxCryptoKeyBits.bits256,
    ToolboxCryptoMacAlgorithm macAlgorithm = ToolboxCryptoMacAlgorithm.sha256,
    ToolboxCryptoSignatureMode signatureMode = ToolboxCryptoSignatureMode.none,
  }) {
    if (plainBytes <= 0) {
      throw const ToolboxCryptoException('Input bytes are empty.');
    }
    if (plainBytes > maxPlainBytes) {
      throw const ToolboxCryptoException('Input file is too large.');
    }
    if (!algorithm.canEncrypt) {
      throw const ToolboxCryptoException(
        'Legacy or weak algorithms can only decrypt existing payloads.',
      );
    }

    final stages = _stagesFor(algorithm, cascade: cascade, keyBits: keyBits);
    final effectiveMacAlgorithm = _effectiveMacAlgorithm(
      algorithm,
      macAlgorithm,
    );
    final effectiveSignatureMode = _effectiveSignatureMode(
      algorithm,
      signatureMode,
    );
    final minimumCipherBytes = _estimatedCipherBytes(
      plainBytes: plainBytes,
      stages: stages,
      paddingLength: 16,
    );
    final recommendedCipherBytes = _estimatedCipherBytes(
      plainBytes: plainBytes,
      stages: stages,
      paddingLength: 255,
    );
    return ToolboxCryptoEnvelopeSizeEstimate(
      minimumBytes: _estimatedOpaqueEnvelopeBytes(
        algorithm: algorithm,
        strength: strength,
        keyBits: keyBits,
        macAlgorithm: effectiveMacAlgorithm,
        signatureMode: effectiveSignatureMode,
        stages: stages,
        cipherBytes: minimumCipherBytes,
        paddedPlainBytes: plainBytes + 11 + 16,
        fileName: fileName,
        mediaType: mediaType,
      ),
      recommendedBytes: _estimatedOpaqueEnvelopeBytes(
        algorithm: algorithm,
        strength: strength,
        keyBits: keyBits,
        macAlgorithm: effectiveMacAlgorithm,
        signatureMode: effectiveSignatureMode,
        stages: stages,
        cipherBytes: recommendedCipherBytes,
        paddedPlainBytes: plainBytes + 11 + 255,
        fileName: fileName,
        mediaType: mediaType,
      ),
      minimumCipherBytes: minimumCipherBytes,
      recommendedCipherBytes: recommendedCipherBytes,
    );
  }

  Uint8List deriveSteganographyLocatorSecret({
    required String passphrase,
    required Uint8List? keyFileBytes,
    required Uint8List salt,
    required ToolboxCryptoStrength strength,
    String purpose = 'steganography-locator-v5',
    int length = 64,
  }) {
    if (salt.isEmpty || salt.length > _maxSaltBytes) {
      throw const ToolboxCryptoException('Crypto KDF parameters are invalid.');
    }
    final kdfSettings = _KdfSettings.fromStrength(strength);
    _validateKdfSettings(kdfSettings);
    final rootKey = _deriveRootKey(
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      salt: salt,
      macAlgorithm: ToolboxCryptoMacAlgorithm.sha256,
      kdfSettings: kdfSettings,
    );
    return _expandRootKey(rootKey, purpose, length);
  }

  ToolboxCryptoDecryptResult decryptBytes({
    required Uint8List envelopeBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
  }) {
    if (envelopeBytes.isEmpty) {
      throw const ToolboxCryptoException('Input bytes are empty.');
    }
    if (_isOpaqueEnvelopeV5(envelopeBytes)) {
      return _decryptOpaqueEnvelopeV5(
        envelopeBytes: envelopeBytes,
        passphrase: passphrase,
        keyFileBytes: keyFileBytes,
      );
    }
    return _decryptLegacyJsonEnvelopeV4(
      envelopeBytes: envelopeBytes,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );
  }

  ToolboxCryptoDecryptResult _decryptLegacyJsonEnvelopeV4({
    required Uint8List envelopeBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
  }) {
    final map = _decodeEnvelope(envelopeBytes);
    final rawVersion = map['version'];
    final version = rawVersion is int ? rawVersion : null;
    if (version != _legacyJsonVersion) {
      throw const ToolboxCryptoException('Unsupported crypto version.');
    }
    final algorithm = _algorithmFromId(_readString(map, 'algorithm'));
    final strength = _strengthFromId(_readString(map, 'strength'));
    final kdfSettings = _readKdfSettings(map, strength);
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
    final salt = _readBase64(map, 'salt', maxBytes: _maxSaltBytes);
    final cipherBytes = _readBase64(
      map,
      'ciphertext',
      maxBytes: maxCipherBytes,
    );
    final mac = _readString(map, 'mac');
    final fileName = map['fileName'] as String?;
    final mediaType = map['mediaType'] as String?;
    final stageMaps = _readStages(map);
    final associatedData = _associatedData(
      version: version!,
      algorithm: algorithm,
      strength: strength,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
      salt: salt,
      stages: stageMaps,
      fileName: fileName,
      mediaType: mediaType,
      kdfSettings: kdfSettings,
      paddingMode: _readPaddingMode(map),
    );
    final rootKey = _deriveRootKey(
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      salt: salt,
      macAlgorithm: macAlgorithm,
      kdfSettings: kdfSettings,
    );
    final macBytes = _hexToBytes(mac);
    final expectedMac = _hmacBytes(
      algorithm: macAlgorithm,
      key: _expandRootKey(rootKey, 'mac-${macAlgorithm.id}', 32),
      bytes: <int>[...associatedData, 0, ...cipherBytes],
    );
    if (macBytes == null || !_constantTimeBytesEquals(macBytes, expectedMac)) {
      throw const ToolboxCryptoException(
        'Passphrase mismatch or payload is damaged.',
      );
    }
    final signatureSeed = signatureMode == ToolboxCryptoSignatureMode.none
        ? null
        : _expandRootKey(rootKey, 'signature-${macAlgorithm.id}', 64);
    _verifyEnvelopeSignature(
      mode: signatureMode,
      signature: map['signature'],
      publicKey: map['signaturePublic'],
      keySeed: signatureSeed,
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
    final keyMaterialLength = stages.fold<int>(
      0,
      (sum, stage) => sum + stage.keyBytes,
    );
    final keyMaterial = _expandRootKey(
      rootKey,
      'stage-key-${macAlgorithm.id}',
      keyMaterialLength,
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
        nonce: _readBase64(stageMap, 'nonce', maxBytes: _maxNonceBytes),
        strength: strength,
      );
    }

    final decryptedPayload = Uint8List.fromList(activeBytes);
    final output = _unpadPlainPayload(decryptedPayload);
    return ToolboxCryptoDecryptResult(
      plainBytes: output,
      algorithm: algorithm,
      strength: strength,
      cipherPreview: previewBase64(cipherBytes),
      keyFileSha256: _keyFileHash(keyFileBytes),
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

  ToolboxCryptoAsymmetricKeyPairResult generateAsymmetricKeyPair({
    required ToolboxCryptoAsymmetricAlgorithm algorithm,
  }) {
    return switch (algorithm) {
      ToolboxCryptoAsymmetricAlgorithm.rsa2048 => _generateRsa2048KeyPair(),
      ToolboxCryptoAsymmetricAlgorithm.ecP256 => _generateEcP256KeyPair(),
    };
  }

  ToolboxCryptoAsymmetricSignatureResult signBytes({
    required Uint8List bytes,
    required String privateKeyText,
  }) {
    _validateAsymmetricPayloadSize(bytes);
    final key = _decodeAsymmetricKeyText(privateKeyText);
    if (!key.isPrivate) {
      throw const ToolboxCryptoException('Private key is required.');
    }
    final signature = switch (key.algorithm) {
      ToolboxCryptoAsymmetricAlgorithm.rsa2048 => _rsaSignBytes(
        key.rsaPrivateKey!,
        bytes,
      ),
      ToolboxCryptoAsymmetricAlgorithm.ecP256 => _ecSignBytes(
        key.ecPrivateKey!,
        bytes,
      ),
    };
    final signatureText = _encodeAsymmetricSignature(
      algorithm: key.algorithm,
      publicKeyFingerprint: key.publicKeyFingerprint,
      signature: signature,
    );
    return ToolboxCryptoAsymmetricSignatureResult(
      algorithm: key.algorithm,
      signatureText: signatureText,
      publicKeyFingerprint: key.publicKeyFingerprint,
    );
  }

  ToolboxCryptoAsymmetricVerifyResult verifyBytes({
    required Uint8List bytes,
    required String publicKeyText,
    required String signatureText,
  }) {
    _validateAsymmetricPayloadSize(bytes);
    final key = _decodeAsymmetricKeyText(publicKeyText);
    final signature = _decodeAsymmetricSignatureText(signatureText);
    if (key.algorithm != signature.algorithm) {
      throw const ToolboxCryptoException(
        'Signature and public key algorithms do not match.',
      );
    }
    if (key.publicKeyFingerprint != signature.publicKeyFingerprint) {
      throw const ToolboxCryptoException(
        'Signature public key fingerprint does not match.',
      );
    }
    final ok = switch (key.algorithm) {
      ToolboxCryptoAsymmetricAlgorithm.rsa2048 => _rsaVerifyBytes(
        key.rsaPublicKey!,
        signature,
        bytes,
      ),
      ToolboxCryptoAsymmetricAlgorithm.ecP256 => _ecVerifyBytes(
        key.ecPublicKey!,
        signature,
        bytes,
      ),
    };
    return ToolboxCryptoAsymmetricVerifyResult(
      algorithm: key.algorithm,
      isValid: ok,
      publicKeyFingerprint: key.publicKeyFingerprint,
    );
  }

  ToolboxCryptoAsymmetricCipherResult encryptBytesWithPublicKey({
    required Uint8List plainBytes,
    required String publicKeyText,
  }) {
    if (plainBytes.isEmpty) {
      throw const ToolboxCryptoException('Input bytes are empty.');
    }
    final key = _decodeAsymmetricKeyText(publicKeyText);
    if (key.algorithm != ToolboxCryptoAsymmetricAlgorithm.rsa2048) {
      throw const ToolboxCryptoException(
        'ECC keys support signing only; use RSA for small-text encryption.',
      );
    }
    if (plainBytes.length > maxRsaOaepSha256PlainBytes) {
      throw const ToolboxCryptoException(
        'RSA small-text encryption supports up to 190 UTF-8 bytes.',
      );
    }
    final cipherBytes = _rsaOaepEncrypt(key.rsaPublicKey!, plainBytes);
    final cipherText = _encodeAsymmetricCipher(
      publicKeyFingerprint: key.publicKeyFingerprint,
      cipherBytes: cipherBytes,
    );
    return ToolboxCryptoAsymmetricCipherResult(
      algorithm: key.algorithm,
      cipherText: cipherText,
      publicKeyFingerprint: key.publicKeyFingerprint,
      cipherBytes: cipherBytes.length,
    );
  }

  Uint8List decryptBytesWithPrivateKey({
    required String cipherText,
    required String privateKeyText,
  }) {
    final key = _decodeAsymmetricKeyText(privateKeyText);
    if (!key.isPrivate) {
      throw const ToolboxCryptoException('Private key is required.');
    }
    if (key.algorithm != ToolboxCryptoAsymmetricAlgorithm.rsa2048) {
      throw const ToolboxCryptoException(
        'ECC keys support signing only; use RSA for small-text encryption.',
      );
    }
    final cipher = _decodeAsymmetricCipherText(cipherText);
    if (cipher.algorithm != key.algorithm) {
      throw const ToolboxCryptoException(
        'Cipher text and private key algorithms do not match.',
      );
    }
    if (key.publicKeyFingerprint != cipher.publicKeyFingerprint) {
      throw const ToolboxCryptoException(
        'Cipher text public key fingerprint does not match.',
      );
    }
    return _rsaOaepDecrypt(key.rsaPrivateKey!, cipher.cipherBytes);
  }

  ToolboxCryptoKeyFileResult generateKeyFile({
    required int length,
    String fileName = 'vocabulary_sleep_keyfile.bin',
  }) {
    if (length < 32 || length > maxKeyFileBytes) {
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

  ToolboxCryptoKeyFileResult deriveKeyFileFromPassphrase({
    required String passphrase,
    required int length,
    required ToolboxCryptoStrength strength,
    String saltText = 'vocabulary_sleep_keyfile_derived_v1',
    String fileName = 'vocabulary_sleep_derived_keyfile.bin',
  }) {
    if (passphrase.trim().isEmpty) {
      throw const ToolboxCryptoException('Passphrase is required.');
    }
    if (length < 32 || length > maxKeyFileBytes) {
      throw const ToolboxCryptoException(
        'Key file length must be between 32 bytes and 1 MB.',
      );
    }
    final normalizedSalt = saltText.trim().isEmpty
        ? 'vocabulary_sleep_keyfile_derived_v1'
        : saltText.trim();
    final salt = Uint8List.fromList(
      crypto.sha256.convert(<int>[
        ...utf8.encode('vocabulary_sleep_keyfile_derivation_v1'),
        0,
        ...utf8.encode(normalizedSalt),
      ]).bytes,
    );
    final kdfSettings = _KdfSettings.fromStrength(strength);
    _validateKdfSettings(kdfSettings);
    final derivator = pc.Scrypt()
      ..init(
        pc.ScryptParameters(
          kdfSettings.n,
          kdfSettings.r,
          kdfSettings.p,
          length,
          salt,
        ),
      );
    final bytes = derivator.process(
      Uint8List.fromList(<int>[
        ...utf8.encode('vocabulary_sleep_derived_keyfile_secret_v1'),
        0,
        ...utf8.encode(passphrase),
      ]),
    );
    return ToolboxCryptoKeyFileResult(
      bytes: bytes,
      length: bytes.length,
      sha256: _hexDigest(crypto.sha256.convert(bytes).bytes),
      fileName: fileName,
    );
  }

  ToolboxCryptoCombinedKeyFileResult combineKeyFiles(
    List<ToolboxCryptoKeyFileInput> entries, {
    String fileNamePrefix = 'vocabulary_sleep_key_bundle',
  }) {
    if (entries.isEmpty) {
      throw const ToolboxCryptoException('Key file is required.');
    }
    var totalBytes = 0;
    for (final entry in entries) {
      if (entry.bytes.isEmpty) {
        throw const ToolboxCryptoException('Key file is empty.');
      }
      if (entry.bytes.length > maxKeyFileBytes) {
        throw const ToolboxCryptoException(
          'Key file length must be between 32 bytes and 1 MB.',
        );
      }
      totalBytes += entry.bytes.length;
      if (totalBytes > maxCombinedKeyFileBytes) {
        throw const ToolboxCryptoException('Combined key files are too large.');
      }
    }
    final sorted = entries.toList(growable: false)..sort(_compareKeyFileInput);
    final bytes = sorted.length == 1
        ? Uint8List.fromList(sorted.first.bytes)
        : _bundleKeyFileEntries(sorted);
    if (bytes.length > maxCombinedKeyFileBytes + 4096) {
      throw const ToolboxCryptoException('Combined key files are too large.');
    }
    final digest = _hexDigest(crypto.sha256.convert(bytes).bytes);
    return ToolboxCryptoCombinedKeyFileResult(
      bytes: bytes,
      length: bytes.length,
      sha256: digest,
      fileName: sorted.length == 1
          ? sorted.first.name
          : '${fileNamePrefix}_${sorted.length}.bin',
      entries: sorted
          .map(
            (entry) => ToolboxCryptoKeyFileEntryInfo(
              name: entry.name,
              length: entry.bytes.length,
              sha256: entry.sha256,
            ),
          )
          .toList(growable: false),
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
    if (envelopeBytes.length > maxEnvelopeBytes) {
      throw const ToolboxCryptoException('Crypto envelope is too large.');
    }
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

  bool _isOpaqueEnvelopeV5(Uint8List envelopeBytes) {
    if (envelopeBytes.length < _opaqueEnvelopeMagic.length + 1) {
      return false;
    }
    for (var index = 0; index < _opaqueEnvelopeMagic.length; index += 1) {
      if (envelopeBytes[index] != _opaqueEnvelopeMagic[index]) {
        return false;
      }
    }
    return true;
  }

  Uint8List _encodeOpaqueEnvelopeV5({
    required _KdfSettings kdfSettings,
    required Uint8List salt,
    required Uint8List headerRootKey,
    required Map<String, Object?> protectedMetadata,
    required Uint8List cipherBytes,
  }) {
    _validateKdfSettings(kdfSettings);
    if (salt.isEmpty || salt.length > _maxSaltBytes || salt.length > 255) {
      throw const ToolboxCryptoException('Crypto KDF parameters are invalid.');
    }
    if (cipherBytes.isEmpty || cipherBytes.length > maxCipherBytes) {
      throw const ToolboxCryptoException('Crypto envelope is too large.');
    }
    final metadataBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(protectedMetadata)),
    );
    if (metadataBytes.length > _maxProtectedMetadataBytes) {
      throw const ToolboxCryptoException('Crypto envelope is too large.');
    }
    final headerNonce = _randomBytes(12);
    final metadataCipher = _gcmTransform(
      engine: pc.AESEngine(),
      engineId: 'opaque_metadata_v5',
      encrypt: true,
      input: metadataBytes,
      key: _expandRootKey(headerRootKey, 'opaque-metadata-v5', 32),
      nonce: headerNonce,
      associatedData: _opaqueBootAssociatedData(
        kdfSettings: kdfSettings,
        salt: salt,
      ),
    );
    if (metadataCipher.length > _maxProtectedMetadataCipherBytes) {
      throw const ToolboxCryptoException('Crypto envelope is too large.');
    }

    final builder = BytesBuilder(copy: false)
      ..add(_opaqueEnvelopeMagic)
      ..addByte(currentVersion)
      ..add(_uint32Bytes(kdfSettings.n))
      ..add(_uint32Bytes(kdfSettings.r))
      ..add(_uint32Bytes(kdfSettings.p))
      ..addByte(salt.length)
      ..add(salt)
      ..addByte(headerNonce.length)
      ..add(headerNonce)
      ..add(_uint32Bytes(metadataCipher.length))
      ..add(metadataCipher)
      ..add(cipherBytes);
    final output = builder.takeBytes();
    if (output.length > maxEnvelopeBytes) {
      throw const ToolboxCryptoException('Crypto envelope is too large.');
    }
    return output;
  }

  ToolboxCryptoDecryptResult _decryptOpaqueEnvelopeV5({
    required Uint8List envelopeBytes,
    required String passphrase,
    Uint8List? keyFileBytes,
  }) {
    final envelope = _readOpaqueEnvelopeV5(envelopeBytes);
    final headerRootKey = _deriveRootKey(
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      salt: envelope.salt,
      macAlgorithm: ToolboxCryptoMacAlgorithm.sha256,
      kdfSettings: envelope.kdfSettings,
    );
    final metadataPlain = _gcmTransform(
      engine: pc.AESEngine(),
      engineId: 'opaque_metadata_v5',
      encrypt: false,
      input: envelope.metadataCipher,
      key: _expandRootKey(headerRootKey, 'opaque-metadata-v5', 32),
      nonce: envelope.metadataNonce,
      associatedData: _opaqueBootAssociatedData(
        kdfSettings: envelope.kdfSettings,
        salt: envelope.salt,
      ),
    );
    final protectedMetadata = _decodeProtectedMetadataV5(metadataPlain);
    final algorithm = _algorithmFromId(
      _readString(protectedMetadata, 'algorithm'),
    );
    final strength = _strengthFromId(
      _readString(protectedMetadata, 'strength'),
    );
    final keyBits = _keyBitsFromValue(protectedMetadata['keyBits']);
    final macAlgorithm = _macAlgorithmFromId(
      _readString(protectedMetadata, 'macAlgorithm'),
    );
    final signatureMode = _signatureModeFromId(
      _readString(protectedMetadata, 'signatureMode'),
    );
    _validateAlgorithmAndSecret(
      algorithm: algorithm,
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
    );
    final fileName = protectedMetadata['fileName'] as String?;
    final mediaType = protectedMetadata['mediaType'] as String?;
    final stageMaps = _readStages(protectedMetadata);
    final paddingMode = _readPaddingMode(protectedMetadata);
    final associatedData = _associatedData(
      version: currentVersion,
      algorithm: algorithm,
      strength: strength,
      keyBits: keyBits,
      macAlgorithm: macAlgorithm,
      signatureMode: signatureMode,
      salt: envelope.salt,
      stages: stageMaps,
      fileName: fileName,
      mediaType: mediaType,
      kdfSettings: envelope.kdfSettings,
      paddingMode: paddingMode,
    );
    final rootKey = macAlgorithm == ToolboxCryptoMacAlgorithm.sha256
        ? headerRootKey
        : _deriveRootKey(
            passphrase: passphrase,
            keyFileBytes: keyFileBytes,
            salt: envelope.salt,
            macAlgorithm: macAlgorithm,
            kdfSettings: envelope.kdfSettings,
          );
    final mac = _readString(protectedMetadata, 'mac');
    final macBytes = _hexToBytes(mac);
    final expectedMac = _hmacBytes(
      algorithm: macAlgorithm,
      key: _expandRootKey(rootKey, 'mac-${macAlgorithm.id}', 32),
      bytes: <int>[...associatedData, 0, ...envelope.cipherBytes],
    );
    if (macBytes == null || !_constantTimeBytesEquals(macBytes, expectedMac)) {
      throw const ToolboxCryptoException(
        'Passphrase mismatch or payload is damaged.',
      );
    }
    final signatureSeed = signatureMode == ToolboxCryptoSignatureMode.none
        ? null
        : _expandRootKey(rootKey, 'signature-${macAlgorithm.id}', 64);
    _verifyEnvelopeSignature(
      mode: signatureMode,
      signature: protectedMetadata['signature'],
      publicKey: protectedMetadata['signaturePublic'],
      keySeed: signatureSeed,
      data: <int>[
        ...associatedData,
        0,
        ...envelope.cipherBytes,
        0,
        ...utf8.encode(mac),
      ],
    );

    final stages = stageMaps
        .map(
          (stageMap) => _stageFromId(
            _readString(stageMap, 'id'),
            keyBytes: _stageKeyBytesFromMap(stageMap),
          ),
        )
        .toList(growable: false);
    final keyMaterialLength = stages.fold<int>(
      0,
      (sum, stage) => sum + stage.keyBytes,
    );
    final keyMaterial = _expandRootKey(
      rootKey,
      'stage-key-${macAlgorithm.id}',
      keyMaterialLength,
    );
    var keyOffset = keyMaterial.length;
    var activeBytes = Uint8List.fromList(envelope.cipherBytes);
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
        nonce: _readBase64(stageMap, 'nonce', maxBytes: _maxNonceBytes),
        strength: strength,
      );
    }

    final decryptedPayload = Uint8List.fromList(activeBytes);
    final output = _unpadPlainPayload(decryptedPayload);
    return ToolboxCryptoDecryptResult(
      plainBytes: output,
      algorithm: algorithm,
      strength: strength,
      cipherPreview: previewBase64(envelope.cipherBytes),
      keyFileSha256: _keyFileHash(keyFileBytes),
      fileName: fileName,
      mediaType: mediaType,
    );
  }

  _OpaqueEnvelopeV5 _readOpaqueEnvelopeV5(Uint8List envelopeBytes) {
    if (envelopeBytes.length > maxEnvelopeBytes) {
      throw const ToolboxCryptoException('Crypto envelope is too large.');
    }
    var offset = _opaqueEnvelopeMagic.length;
    final version = _readEnvelopeByte(envelopeBytes, offset);
    offset += 1;
    if (version != currentVersion) {
      throw const ToolboxCryptoException('Unsupported crypto version.');
    }
    final kdfSettings = _KdfSettings(
      n: _readEnvelopeUint32(envelopeBytes, offset),
      r: _readEnvelopeUint32(envelopeBytes, offset + 4),
      p: _readEnvelopeUint32(envelopeBytes, offset + 8),
    );
    offset += 12;
    _validateKdfSettings(kdfSettings);
    final saltLength = _readEnvelopeByte(envelopeBytes, offset);
    offset += 1;
    if (saltLength <= 0 || saltLength > _maxSaltBytes) {
      throw const ToolboxCryptoException('Crypto KDF parameters are invalid.');
    }
    final salt = _readEnvelopeBytes(envelopeBytes, offset, saltLength);
    offset += saltLength;
    final nonceLength = _readEnvelopeByte(envelopeBytes, offset);
    offset += 1;
    if (nonceLength <= 0 || nonceLength > _maxNonceBytes) {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
    final metadataNonce = _readEnvelopeBytes(
      envelopeBytes,
      offset,
      nonceLength,
    );
    offset += nonceLength;
    final metadataLength = _readEnvelopeUint32(envelopeBytes, offset);
    offset += 4;
    if (metadataLength <= 0 ||
        metadataLength > _maxProtectedMetadataCipherBytes) {
      throw const ToolboxCryptoException('Crypto envelope is too large.');
    }
    final metadataCipher = _readEnvelopeBytes(
      envelopeBytes,
      offset,
      metadataLength,
    );
    offset += metadataLength;
    final cipherBytes = Uint8List.fromList(envelopeBytes.sublist(offset));
    if (cipherBytes.isEmpty || cipherBytes.length > maxCipherBytes) {
      throw const ToolboxCryptoException('Crypto envelope is too large.');
    }
    return _OpaqueEnvelopeV5(
      kdfSettings: kdfSettings,
      salt: salt,
      metadataNonce: metadataNonce,
      metadataCipher: metadataCipher,
      cipherBytes: cipherBytes,
    );
  }

  Map<String, Object?> _decodeProtectedMetadataV5(Uint8List metadataBytes) {
    if (metadataBytes.isEmpty ||
        metadataBytes.length > _maxProtectedMetadataBytes) {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
    try {
      final decoded = jsonDecode(utf8.decode(metadataBytes));
      if (decoded is Map) {
        return Map<String, Object?>.from(decoded);
      }
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    } on FormatException {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
  }

  Uint8List _opaqueBootAssociatedData({
    required _KdfSettings kdfSettings,
    required Uint8List salt,
  }) {
    final builder = BytesBuilder(copy: false)
      ..add(_opaqueEnvelopeMagic)
      ..addByte(currentVersion)
      ..add(_uint32Bytes(kdfSettings.n))
      ..add(_uint32Bytes(kdfSettings.r))
      ..add(_uint32Bytes(kdfSettings.p))
      ..addByte(salt.length)
      ..add(salt);
    return builder.takeBytes();
  }

  _KdfSettings _readKdfSettings(
    Map<String, Object?> map,
    ToolboxCryptoStrength strength,
  ) {
    final raw = map['kdf'];
    if (raw is Map<String, Object?>) {
      final id = raw['id'];
      if (id != null && id != 'scrypt') {
        throw const ToolboxCryptoException(
          'Crypto KDF parameters are invalid.',
        );
      }
      final settings = _KdfSettings(
        n: _readKdfInt(raw, 'n') ?? strength.scryptN,
        r: _readKdfInt(raw, 'r') ?? strength.scryptR,
        p: _readKdfInt(raw, 'p') ?? strength.scryptP,
      );
      _validateKdfSettings(settings);
      return settings;
    }
    final settings = _KdfSettings.fromStrength(strength);
    _validateKdfSettings(settings);
    return settings;
  }

  void _validateKdfSettings(_KdfSettings settings) {
    final n = settings.n;
    final isPowerOfTwo = n > 1 && (n & (n - 1)) == 0;
    if (!isPowerOfTwo ||
        n < _minScryptN ||
        n > _maxScryptN ||
        settings.r < _minScryptR ||
        settings.r > _maxScryptR ||
        settings.p < _minScryptP ||
        settings.p > _maxScryptP) {
      throw const ToolboxCryptoException('Crypto KDF parameters are invalid.');
    }
  }

  String _readPaddingMode(Map<String, Object?> map) {
    final raw = map['padding'];
    final mode = raw is Map<String, Object?> ? raw['mode'] : null;
    if (mode is String && mode == 'random-length-v1') {
      return mode;
    }
    throw const ToolboxCryptoException('Crypto envelope is invalid.');
  }

  int? _readPositiveInt(Object? value) {
    final parsed = value is int
        ? value
        : value is String
        ? int.tryParse(value)
        : null;
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  int? _readKdfInt(Map<String, Object?> map, String key) {
    if (!map.containsKey(key)) {
      return null;
    }
    final parsed = _readPositiveInt(map[key]);
    if (parsed == null) {
      throw const ToolboxCryptoException('Crypto KDF parameters are invalid.');
    }
    return parsed;
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
      ToolboxCryptoAlgorithm.chacha20Poly1305 => <_CryptoStage>[
        _CryptoStage.chacha20Poly1305(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.camelliaGcm => <_CryptoStage>[
        _CryptoStage.camelliaGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.twofishGcm => <_CryptoStage>[
        _CryptoStage.twofishGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.serpentGcm => <_CryptoStage>[
        _CryptoStage.serpentGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.kuznyechikGcm => <_CryptoStage>[
        _CryptoStage.kuznyechikGcm(keyBytes: keyBits.bytes),
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
      ToolboxCryptoAlgorithm.aesSerpentKuznyechikGcm => <_CryptoStage>[
        _CryptoStage.aesGcm(keyBytes: keyBits.bytes),
        _CryptoStage.serpentGcm(keyBytes: keyBits.bytes),
        _CryptoStage.kuznyechikGcm(keyBytes: keyBits.bytes),
      ],
      ToolboxCryptoAlgorithm.aesTwofishCamelliaSerpentKuznyechikGcm =>
        <_CryptoStage>[
          _CryptoStage.aesGcm(keyBytes: keyBits.bytes),
          _CryptoStage.twofishGcm(keyBytes: keyBits.bytes),
          _CryptoStage.camelliaGcm(keyBytes: keyBits.bytes),
          _CryptoStage.serpentGcm(keyBytes: keyBits.bytes),
          _CryptoStage.kuznyechikGcm(keyBytes: keyBits.bytes),
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
    if (selected.contains(ToolboxCryptoCascadeCipher.sha256Stream)) {
      throw const ToolboxCryptoException(
        'SHA256 stream can only decrypt existing legacy payloads.',
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
      ToolboxCryptoCascadeCipher.chacha20 => _CryptoStage.chacha20Poly1305(
        keyBytes: keyBytes,
      ),
      ToolboxCryptoCascadeCipher.twofish => _CryptoStage.twofishGcm(
        keyBytes: keyBytes,
      ),
      ToolboxCryptoCascadeCipher.camellia => _CryptoStage.camelliaGcm(
        keyBytes: keyBytes,
      ),
      ToolboxCryptoCascadeCipher.serpent => _CryptoStage.serpentGcm(
        keyBytes: keyBytes,
      ),
      ToolboxCryptoCascadeCipher.kuznyechik => _CryptoStage.kuznyechikGcm(
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

  int _estimatedCipherBytes({
    required int plainBytes,
    required List<_CryptoStage> stages,
    required int paddingLength,
  }) {
    var length = plainBytes + 11 + paddingLength;
    for (final stage in stages) {
      if (_stageAddsAeadTag(stage)) {
        length += 16;
      }
    }
    return length;
  }

  bool _stageAddsAeadTag(_CryptoStage stage) {
    return stage.id == 'aes_gcm' ||
        stage.id == 'chacha20_poly1305' ||
        stage.id == 'camellia_gcm' ||
        stage.id == 'twofish_gcm' ||
        stage.id == 'serpent_gcm' ||
        stage.id == 'kuznyechik_gcm';
  }

  int _estimatedOpaqueEnvelopeBytes({
    required ToolboxCryptoAlgorithm algorithm,
    required ToolboxCryptoStrength strength,
    required ToolboxCryptoKeyBits keyBits,
    required ToolboxCryptoMacAlgorithm macAlgorithm,
    required ToolboxCryptoSignatureMode signatureMode,
    required List<_CryptoStage> stages,
    required int cipherBytes,
    required int paddedPlainBytes,
    required String? fileName,
    required String? mediaType,
  }) {
    final stageMaps = stages
        .map(
          (stage) => <String, Object?>{
            'id': stage.id,
            'nonce': _placeholderBase64(stage.usesNonce ? 12 : 16),
            'keyBits': stage.keyBytes * 8,
          },
        )
        .toList(growable: false);
    final protectedMetadata = <String, Object?>{
      'algorithm': algorithm.id,
      'strength': strength.id,
      'keyBits': keyBits.bits,
      'macAlgorithm': macAlgorithm.id,
      'signatureMode': signatureMode.id,
      'padding': <String, Object?>{
        'mode': 'random-length-v1',
        'cipherPlainBytes': paddedPlainBytes,
      },
      'stages': stageMaps,
      'encoding': 'bytes',
      'fileName': fileName,
      'mediaType': mediaType,
      'mac': _placeholderHex(_macBytesLength(macAlgorithm)),
      'signature': _placeholderSignature(signatureMode),
      'signaturePublic': _placeholderSignaturePublic(signatureMode),
    };
    final metadataBytes = utf8.encode(jsonEncode(protectedMetadata)).length;
    final metadataCipherBytes = metadataBytes + 16;
    return _opaqueEnvelopeMagic.length +
        1 +
        12 +
        1 +
        16 +
        1 +
        12 +
        4 +
        metadataCipherBytes +
        cipherBytes;
  }

  Uint8List _deriveRootKey({
    required String passphrase,
    required Uint8List? keyFileBytes,
    required Uint8List salt,
    required ToolboxCryptoMacAlgorithm macAlgorithm,
    required _KdfSettings kdfSettings,
  }) {
    final secret = _secretBytesV3(passphrase, keyFileBytes);
    final derivedSalt = _derivePurposeSalt(salt, 'root-v3-${macAlgorithm.id}');
    final derivator = pc.Scrypt()
      ..init(
        pc.ScryptParameters(
          kdfSettings.n,
          kdfSettings.r,
          kdfSettings.p,
          64,
          derivedSalt,
        ),
      );
    return derivator.process(secret);
  }

  Uint8List _expandRootKey(Uint8List rootKey, String purpose, int length) {
    if (length == 0) {
      return Uint8List(0);
    }
    final output = BytesBuilder(copy: false);
    var counter = 0;
    while (output.length < length) {
      final block = crypto.Hmac(crypto.sha256, rootKey).convert(<int>[
        ...utf8.encode('vocabulary_sleep_crypto_v3_expand'),
        0,
        ...utf8.encode(purpose),
        0,
        ..._uint64Bytes(counter),
      ]);
      output.add(block.bytes);
      counter += 1;
    }
    return Uint8List.fromList(output.takeBytes().sublist(0, length));
  }

  Uint8List _padPlainPayload(Uint8List plainBytes) {
    final paddingLength = 16 + _secureRandom.nextInt(240);
    final padding = _randomBytes(paddingLength);
    final output = BytesBuilder(copy: false)
      ..add(<int>[1])
      ..add(_uint16Bytes(paddingLength))
      ..add(_uint64Bytes(plainBytes.length))
      ..add(plainBytes)
      ..add(padding);
    return output.takeBytes();
  }

  Uint8List _unpadPlainPayload(Uint8List paddedBytes) {
    const headerLength = 1 + 2 + 8;
    if (paddedBytes.length < headerLength || paddedBytes[0] != 1) {
      throw const ToolboxCryptoException('Payload padding is invalid.');
    }
    final paddingLength = _readUint16(paddedBytes, 1);
    final plainLength = _readUint64(paddedBytes, 3);
    final plainOffset = headerLength;
    final expectedLength = plainOffset + plainLength + paddingLength;
    if (plainLength < 0 ||
        plainLength > maxPlainBytes ||
        paddingLength < 0 ||
        expectedLength != paddedBytes.length) {
      throw const ToolboxCryptoException('Payload padding is invalid.');
    }
    return Uint8List.fromList(
      paddedBytes.sublist(plainOffset, plainOffset + plainLength),
    );
  }

  Uint8List _derivePurposeSalt(Uint8List salt, String purpose) {
    return Uint8List.fromList(
      crypto.sha256.convert(<int>[...salt, 0, ...utf8.encode(purpose)]).bytes,
    );
  }

  Uint8List _secretBytesV3(String passphrase, Uint8List? keyFileBytes) {
    final keyFileDigest = keyFileBytes == null
        ? Uint8List(0)
        : Uint8List.fromList(crypto.sha256.convert(keyFileBytes).bytes);
    final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
    final passphraseDigest = Uint8List.fromList(
      crypto.sha256.convert(passphraseBytes).bytes,
    );
    final builtInSalt = Uint8List.fromList(
      utf8.encode('vocabulary_sleep_crypto_v3_builtin_password_salt'),
    );
    final saltDigest = Uint8List.fromList(
      crypto.sha256.convert(builtInSalt).bytes,
    );
    final interleaved = <int>[];
    for (var index = 0; index < passphraseDigest.length; index += 1) {
      interleaved
        ..add(passphraseDigest[index])
        ..add(saltDigest[(index * 7) % saltDigest.length]);
    }
    return Uint8List.fromList(<int>[
      ...utf8.encode('vocabulary_sleep_crypto_v3'),
      0,
      ...passphraseDigest,
      0,
      ...interleaved,
      0,
      ...passphraseBytes,
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

  int _compareKeyFileInput(
    ToolboxCryptoKeyFileInput left,
    ToolboxCryptoKeyFileInput right,
  ) {
    final nameCompare = left.name.toLowerCase().compareTo(
      right.name.toLowerCase(),
    );
    if (nameCompare != 0) {
      return nameCompare;
    }
    final hashCompare = left.sha256.compareTo(right.sha256);
    if (hashCompare != 0) {
      return hashCompare;
    }
    return left.bytes.length.compareTo(right.bytes.length);
  }

  Uint8List _bundleKeyFileEntries(List<ToolboxCryptoKeyFileInput> entries) {
    final builder = BytesBuilder(copy: false)
      ..add(utf8.encode('vocabulary_sleep_keyfile_bundle_v1'))
      ..addByte(0);
    for (final entry in entries) {
      final nameBytes = utf8.encode(entry.name);
      final digestBytes = base64Decode(entry.sha256Base64);
      builder
        ..add(_uint32Bytes(nameBytes.length))
        ..add(nameBytes)
        ..add(_uint32Bytes(entry.bytes.length))
        ..add(digestBytes)
        ..add(entry.bytes);
    }
    return builder.takeBytes();
  }

  Uint8List _associatedData({
    required int version,
    required ToolboxCryptoAlgorithm algorithm,
    required ToolboxCryptoStrength strength,
    required ToolboxCryptoKeyBits keyBits,
    required ToolboxCryptoMacAlgorithm macAlgorithm,
    required ToolboxCryptoSignatureMode signatureMode,
    required Uint8List salt,
    required List<Map<String, Object?>> stages,
    required String? fileName,
    required String? mediaType,
    _KdfSettings? kdfSettings,
    String? paddingMode,
  }) {
    final map = <String, Object?>{
      'version': version,
      'algorithm': algorithm.id,
      'strength': strength.id,
      'keyBits': keyBits.bits,
      'macAlgorithm': macAlgorithm.id,
      'signatureMode': signatureMode.id,
      'salt': base64Encode(salt),
      'stages': stages,
      'fileName': fileName,
      'mediaType': mediaType,
    };
    if (kdfSettings != null) {
      map['kdf'] = kdfSettings.toJson();
    }
    if (paddingMode != null) {
      map['paddingMode'] = paddingMode;
    }
    return Uint8List.fromList(utf8.encode(jsonEncode(map)));
  }

  Uint8List _hashBytes(ToolboxCryptoHashAlgorithm algorithm, Uint8List bytes) {
    return switch (algorithm) {
      ToolboxCryptoHashAlgorithm.md5 => Uint8List.fromList(
        crypto.md5.convert(bytes).bytes,
      ),
      ToolboxCryptoHashAlgorithm.sha1 => Uint8List.fromList(
        crypto.sha1.convert(bytes).bytes,
      ),
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

  String _hmacHex({
    required ToolboxCryptoMacAlgorithm algorithm,
    required Uint8List key,
    required List<int> bytes,
  }) {
    return _hexDigest(_hmacBytes(algorithm: algorithm, key: key, bytes: bytes));
  }

  Uint8List _hmacBytes({
    required ToolboxCryptoMacAlgorithm algorithm,
    required Uint8List key,
    required List<int> bytes,
  }) {
    return switch (algorithm) {
      ToolboxCryptoMacAlgorithm.sha256 => Uint8List.fromList(
        crypto.Hmac(crypto.sha256, key).convert(bytes).bytes,
      ),
      ToolboxCryptoMacAlgorithm.whirlpool => _pointyHmac(
        pc.WhirlpoolDigest(),
        64,
        key,
        bytes,
      ),
    };
  }

  int _macBytesLength(ToolboxCryptoMacAlgorithm algorithm) {
    return switch (algorithm) {
      ToolboxCryptoMacAlgorithm.sha256 => 32,
      ToolboxCryptoMacAlgorithm.whirlpool => 64,
    };
  }

  String _placeholderBase64(int bytes) {
    return 'A' * (((bytes + 2) ~/ 3) * 4);
  }

  String _placeholderHex(int bytes) {
    return '0' * (bytes * 2);
  }

  Map<String, Object?>? _placeholderSignature(ToolboxCryptoSignatureMode mode) {
    return switch (mode) {
      ToolboxCryptoSignatureMode.none => null,
      ToolboxCryptoSignatureMode.weakSha256 => <String, Object?>{
        'mode': ToolboxCryptoSignatureMode.weakSha256.id,
        'nonce': _placeholderBase64(16),
        'padding': _placeholderBase64(16),
        'value': _placeholderBase64(32),
      },
      ToolboxCryptoSignatureMode.rsaSha256 => <String, Object?>{
        'mode': ToolboxCryptoSignatureMode.rsaSha256.id,
        'value': _placeholderBase64(256),
      },
      ToolboxCryptoSignatureMode.ecdsaSha256 => <String, Object?>{
        'mode': ToolboxCryptoSignatureMode.ecdsaSha256.id,
        'r': _placeholderBase64(32),
        's': _placeholderBase64(32),
      },
    };
  }

  Map<String, Object?>? _placeholderSignaturePublic(
    ToolboxCryptoSignatureMode mode,
  ) {
    return switch (mode) {
      ToolboxCryptoSignatureMode.none => null,
      ToolboxCryptoSignatureMode.weakSha256 => <String, Object?>{
        'mode': ToolboxCryptoSignatureMode.weakSha256.id,
        'public': false,
      },
      ToolboxCryptoSignatureMode.rsaSha256 => <String, Object?>{
        'n': _placeholderBase64(256),
        'e': _placeholderBase64(3),
      },
      ToolboxCryptoSignatureMode.ecdsaSha256 => <String, Object?>{
        'curve': 'prime256v1',
        'q': _placeholderBase64(65),
      },
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
      2048 => ToolboxCryptoKeyBits.bits2048,
      4096 => ToolboxCryptoKeyBits.bits4096,
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
      _CryptoStage.chacha20Poly1305(keyBytes: keyBytes ?? 32),
      _CryptoStage.camelliaGcm(keyBytes: keyBytes ?? 32),
      _CryptoStage.twofishGcm(keyBytes: keyBytes ?? 32),
      _CryptoStage.serpentGcm(keyBytes: keyBytes ?? 32),
      _CryptoStage.kuznyechikGcm(keyBytes: keyBytes ?? 32),
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
      2048 => 256,
      4096 => 512,
      _ => 32,
    };
  }

  List<Map<String, Object?>> _readStages(Map<String, Object?> map) {
    final raw = map['stages'];
    if (raw is! List<Object?> || raw.isEmpty || raw.length > _maxStageCount) {
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

  Uint8List _readBase64(Map<String, Object?> map, String key, {int? maxBytes}) {
    final text = _readString(map, key);
    if (maxBytes != null) {
      final maxBase64Length = ((maxBytes + 2) ~/ 3) * 4;
      if (text.length > maxBase64Length) {
        throw const ToolboxCryptoException('Crypto envelope is too large.');
      }
    }
    try {
      final decoded = Uint8List.fromList(base64Decode(text));
      if (maxBytes != null && decoded.length > maxBytes) {
        throw const ToolboxCryptoException('Crypto envelope is too large.');
      }
      return decoded;
    } on FormatException {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
  }

  Map<String, Object?>? _signEnvelope({
    required ToolboxCryptoSignatureMode mode,
    required Uint8List? keySeed,
    required List<int> data,
  }) {
    return switch (mode) {
      ToolboxCryptoSignatureMode.none => null,
      ToolboxCryptoSignatureMode.weakSha256 => _weakSignatureMap(
        keySeed: keySeed ?? Uint8List(0),
        data: data,
      ),
      ToolboxCryptoSignatureMode.rsaSha256 => _rsaSignatureMap(
        keySeed: keySeed ?? Uint8List(0),
        data: data,
      ),
      ToolboxCryptoSignatureMode.ecdsaSha256 => _ecdsaSignatureMap(
        keySeed: keySeed ?? Uint8List(0),
        data: data,
      ),
    };
  }

  Map<String, Object?>? _signaturePublicKey({
    required ToolboxCryptoSignatureMode mode,
    required Uint8List? keySeed,
  }) {
    return switch (mode) {
      ToolboxCryptoSignatureMode.none => null,
      ToolboxCryptoSignatureMode.weakSha256 => <String, Object?>{
        'mode': ToolboxCryptoSignatureMode.weakSha256.id,
        'public': false,
      },
      ToolboxCryptoSignatureMode.rsaSha256 => _rsaPublicKeyMap(
        keySeed ?? Uint8List(0),
      ),
      ToolboxCryptoSignatureMode.ecdsaSha256 => _ecdsaPublicKeyMap(
        keySeed ?? Uint8List(0),
      ),
    };
  }

  Map<String, Object?> _weakSignatureMap({
    required Uint8List keySeed,
    required List<int> data,
  }) {
    final nonce = _randomBytes(16);
    final padding = _randomBytes(16);
    final tag = _weakSignatureTag(
      keySeed: keySeed,
      nonce: nonce,
      padding: padding,
      data: data,
    );
    return <String, Object?>{
      'mode': ToolboxCryptoSignatureMode.weakSha256.id,
      'nonce': base64Encode(nonce),
      'padding': base64Encode(padding),
      'value': base64Encode(tag),
    };
  }

  Uint8List _weakSignatureTag({
    required Uint8List keySeed,
    required Uint8List nonce,
    required Uint8List padding,
    required List<int> data,
  }) {
    final signingKey = crypto.sha256.convert(<int>[
      ..._weakSignatureDomainKey,
      0,
      ...keySeed,
      0,
      ...nonce,
    ]).bytes;
    final digest = crypto.Hmac(
      crypto.sha256,
      signingKey,
    ).convert(<int>[...padding, 0, ...data]);
    return Uint8List.fromList(digest.bytes);
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
    required Uint8List? keySeed,
    required List<int> data,
  }) {
    switch (mode) {
      case ToolboxCryptoSignatureMode.none:
        return;
      case ToolboxCryptoSignatureMode.weakSha256:
        if (signature is! Map<String, Object?> || keySeed == null) {
          throw const ToolboxCryptoException('Signature is invalid.');
        }
        final nonce = _readBase64(signature, 'nonce', maxBytes: _maxNonceBytes);
        final padding = _readBase64(
          signature,
          'padding',
          maxBytes: _maxSignatureBytes,
        );
        final expected = _weakSignatureTag(
          keySeed: keySeed,
          nonce: nonce,
          padding: padding,
          data: data,
        );
        final actual = _readBase64(
          signature,
          'value',
          maxBytes: _maxSignatureBytes,
        );
        if (!_constantTimeBytesEquals(actual, expected)) {
          throw const ToolboxCryptoException('Signature verification failed.');
        }
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
          pc.RSASignature(
            _readBase64(signature, 'value', maxBytes: _maxSignatureBytes),
          ),
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
            _bigIntFromBase64(
              _readString(signature, 'r'),
              maxBytes: _maxSignatureBytes,
            ),
            _bigIntFromBase64(
              _readString(signature, 's'),
              maxBytes: _maxSignatureBytes,
            ),
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

  ToolboxCryptoAsymmetricKeyPairResult _generateRsa2048KeyPair() {
    final keyPair = _generateRsaKeyPair(bitStrength: 2048);
    final publicMap = _rsaPublicKeyMapFromKey(keyPair.publicKey);
    final privateMap = _rsaPrivateKeyMapFromKey(keyPair.privateKey);
    final fingerprint = _asymmetricPublicKeyFingerprint(
      ToolboxCryptoAsymmetricAlgorithm.rsa2048,
      publicMap,
    );
    return ToolboxCryptoAsymmetricKeyPairResult(
      algorithm: ToolboxCryptoAsymmetricAlgorithm.rsa2048,
      publicKeyText: _encodeAsymmetricKey(
        algorithm: ToolboxCryptoAsymmetricAlgorithm.rsa2048,
        kind: 'public',
        publicKey: publicMap,
      ),
      privateKeyText: _encodeAsymmetricKey(
        algorithm: ToolboxCryptoAsymmetricAlgorithm.rsa2048,
        kind: 'private',
        publicKey: publicMap,
        privateKey: privateMap,
      ),
      publicKeyFingerprint: fingerprint,
    );
  }

  ToolboxCryptoAsymmetricKeyPairResult _generateEcP256KeyPair() {
    final keyPair = _generateEcKeyPair(curveName: 'secp256r1');
    final publicMap = _ecPublicKeyMapFromKey(keyPair.publicKey);
    final privateMap = _ecPrivateKeyMapFromKey(keyPair.privateKey);
    final fingerprint = _asymmetricPublicKeyFingerprint(
      ToolboxCryptoAsymmetricAlgorithm.ecP256,
      publicMap,
    );
    return ToolboxCryptoAsymmetricKeyPairResult(
      algorithm: ToolboxCryptoAsymmetricAlgorithm.ecP256,
      publicKeyText: _encodeAsymmetricKey(
        algorithm: ToolboxCryptoAsymmetricAlgorithm.ecP256,
        kind: 'public',
        publicKey: publicMap,
      ),
      privateKeyText: _encodeAsymmetricKey(
        algorithm: ToolboxCryptoAsymmetricAlgorithm.ecP256,
        kind: 'private',
        publicKey: publicMap,
        privateKey: privateMap,
      ),
      publicKeyFingerprint: fingerprint,
    );
  }

  String _encodeAsymmetricKey({
    required ToolboxCryptoAsymmetricAlgorithm algorithm,
    required String kind,
    required Map<String, Object?> publicKey,
    Map<String, Object?>? privateKey,
  }) {
    final map = <String, Object?>{
      'format': _asymmetricKeyFormat,
      'version': 1,
      'kind': kind,
      'algorithm': algorithm.id,
      'public': publicKey,
    };
    if (privateKey != null) {
      map['private'] = privateKey;
    }
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  _AsymmetricKeyMaterial _decodeAsymmetricKeyText(String text) {
    final map = _decodeJsonObject(text);
    if (_readString(map, 'format') != _asymmetricKeyFormat ||
        map['version'] != 1) {
      throw const ToolboxCryptoException('Unsupported key format.');
    }
    final kind = _readString(map, 'kind');
    if (kind != 'public' && kind != 'private') {
      throw const ToolboxCryptoException('Unsupported key format.');
    }
    final algorithm = _asymmetricAlgorithmFromId(_readString(map, 'algorithm'));
    final publicMap = _jsonObject(map['public']);
    final publicKeyFingerprint = _asymmetricPublicKeyFingerprint(
      algorithm,
      publicMap,
    );
    return switch (algorithm) {
      ToolboxCryptoAsymmetricAlgorithm.rsa2048 => _decodeRsaKeyMaterial(
        publicMap: publicMap,
        privateMap: kind == 'private' ? _jsonObject(map['private']) : null,
        publicKeyFingerprint: publicKeyFingerprint,
      ),
      ToolboxCryptoAsymmetricAlgorithm.ecP256 => _decodeEcKeyMaterial(
        publicMap: publicMap,
        privateMap: kind == 'private' ? _jsonObject(map['private']) : null,
        publicKeyFingerprint: publicKeyFingerprint,
      ),
    };
  }

  _AsymmetricKeyMaterial _decodeRsaKeyMaterial({
    required Map<String, Object?> publicMap,
    required Map<String, Object?>? privateMap,
    required String publicKeyFingerprint,
  }) {
    final publicKey = _rsaPublicKeyFromMap(publicMap);
    final privateKey = privateMap == null
        ? null
        : _rsaPrivateKeyFromMap(publicKey: publicKey, privateMap: privateMap);
    return _AsymmetricKeyMaterial(
      algorithm: ToolboxCryptoAsymmetricAlgorithm.rsa2048,
      publicKeyFingerprint: publicKeyFingerprint,
      rsaPublicKey: publicKey,
      rsaPrivateKey: privateKey,
    );
  }

  _AsymmetricKeyMaterial _decodeEcKeyMaterial({
    required Map<String, Object?> publicMap,
    required Map<String, Object?>? privateMap,
    required String publicKeyFingerprint,
  }) {
    final publicKey = _ecdsaPublicKeyFromMap(publicMap);
    final privateKey = privateMap == null
        ? null
        : _ecdsaPrivateKeyFromMap(publicKey: publicKey, privateMap: privateMap);
    return _AsymmetricKeyMaterial(
      algorithm: ToolboxCryptoAsymmetricAlgorithm.ecP256,
      publicKeyFingerprint: publicKeyFingerprint,
      ecPublicKey: publicKey,
      ecPrivateKey: privateKey,
    );
  }

  Map<String, Object?> _rsaSignBytes(
    pc.RSAPrivateKey privateKey,
    Uint8List bytes,
  ) {
    final signer = pc.Signer('SHA-256/RSA')
      ..init(true, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey));
    final signature = signer.generateSignature(bytes) as pc.RSASignature;
    return <String, Object?>{'bytes': base64Encode(signature.bytes)};
  }

  bool _rsaVerifyBytes(
    pc.RSAPublicKey publicKey,
    _AsymmetricSignatureMaterial signature,
    Uint8List bytes,
  ) {
    final raw = signature.value['bytes'];
    if (raw is! String) {
      throw const ToolboxCryptoException('Signature is invalid.');
    }
    final signer = pc.Signer('SHA-256/RSA')
      ..init(false, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));
    try {
      return signer.verifySignature(
        bytes,
        pc.RSASignature(_base64ToBytes(raw, maxBytes: _maxSignatureBytes)),
      );
    } on Object {
      return false;
    }
  }

  Map<String, Object?> _ecSignBytes(
    pc.ECPrivateKey privateKey,
    Uint8List bytes,
  ) {
    final signer = pc.Signer('SHA-256/DET-ECDSA')
      ..init(true, pc.PrivateKeyParameter<pc.ECPrivateKey>(privateKey));
    final signature = signer.generateSignature(bytes) as pc.ECSignature;
    return <String, Object?>{
      'r': _bigIntToBase64(signature.r),
      's': _bigIntToBase64(signature.s),
    };
  }

  bool _ecVerifyBytes(
    pc.ECPublicKey publicKey,
    _AsymmetricSignatureMaterial signature,
    Uint8List bytes,
  ) {
    final r = signature.value['r'];
    final s = signature.value['s'];
    if (r is! String || s is! String) {
      throw const ToolboxCryptoException('Signature is invalid.');
    }
    final signer = pc.Signer('SHA-256/DET-ECDSA')
      ..init(false, pc.PublicKeyParameter<pc.ECPublicKey>(publicKey));
    try {
      return signer.verifySignature(
        bytes,
        pc.ECSignature(
          _bigIntFromBase64(r, maxBytes: _maxSignatureBytes),
          _bigIntFromBase64(s, maxBytes: _maxSignatureBytes),
        ),
      );
    } on Object {
      return false;
    }
  }

  String _encodeAsymmetricSignature({
    required ToolboxCryptoAsymmetricAlgorithm algorithm,
    required String publicKeyFingerprint,
    required Map<String, Object?> signature,
  }) {
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'format': _asymmetricSignatureFormat,
      'version': 1,
      'algorithm': algorithm.id,
      'digest': 'sha256',
      'publicKeyFingerprint': publicKeyFingerprint,
      'signature': signature,
    });
  }

  _AsymmetricSignatureMaterial _decodeAsymmetricSignatureText(String text) {
    final map = _decodeJsonObject(text);
    if (_readString(map, 'format') != _asymmetricSignatureFormat ||
        map['version'] != 1) {
      throw const ToolboxCryptoException('Unsupported signature format.');
    }
    final digest = _readString(map, 'digest');
    if (digest != 'sha256') {
      throw const ToolboxCryptoException('Unsupported signature digest.');
    }
    return _AsymmetricSignatureMaterial(
      algorithm: _asymmetricAlgorithmFromId(_readString(map, 'algorithm')),
      publicKeyFingerprint: _readFingerprint(map, 'publicKeyFingerprint'),
      value: _jsonObject(map['signature']),
    );
  }

  Uint8List _rsaOaepEncrypt(pc.RSAPublicKey publicKey, Uint8List plainBytes) {
    final cipher = pc.OAEPEncoding.withSHA256(pc.RSAEngine())
      ..init(
        true,
        pc.ParametersWithRandom<pc.PublicKeyParameter<pc.RSAPublicKey>>(
          pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey),
          _fortuna(_randomBytes(32)),
        ),
      );
    try {
      return cipher.process(plainBytes);
    } on Object catch (error) {
      throw ToolboxCryptoException('RSA encryption failed: $error');
    }
  }

  Uint8List _rsaOaepDecrypt(
    pc.RSAPrivateKey privateKey,
    Uint8List cipherBytes,
  ) {
    final cipher = pc.OAEPEncoding.withSHA256(pc.RSAEngine())
      ..init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey));
    try {
      return cipher.process(cipherBytes);
    } on Object {
      throw const ToolboxCryptoException(
        'Private key mismatch or cipher text is damaged.',
      );
    }
  }

  String _encodeAsymmetricCipher({
    required String publicKeyFingerprint,
    required Uint8List cipherBytes,
  }) {
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'format': _asymmetricCipherFormat,
      'version': 1,
      'algorithm': ToolboxCryptoAsymmetricAlgorithm.rsa2048.id,
      'padding': 'rsa_oaep_sha256_v2_0',
      'publicKeyFingerprint': publicKeyFingerprint,
      'ciphertext': base64Encode(cipherBytes),
    });
  }

  _AsymmetricCipherMaterial _decodeAsymmetricCipherText(String text) {
    final map = _decodeJsonObject(text);
    if (_readString(map, 'format') != _asymmetricCipherFormat ||
        map['version'] != 1) {
      throw const ToolboxCryptoException('Unsupported cipher text format.');
    }
    if (_readString(map, 'padding') != 'rsa_oaep_sha256_v2_0') {
      throw const ToolboxCryptoException('Unsupported RSA padding.');
    }
    return _AsymmetricCipherMaterial(
      algorithm: _asymmetricAlgorithmFromId(_readString(map, 'algorithm')),
      publicKeyFingerprint: _readFingerprint(map, 'publicKeyFingerprint'),
      cipherBytes: _readBase64(map, 'ciphertext', maxBytes: _maxPublicKeyBytes),
    );
  }

  pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey> _generateRsaKeyPair({
    required int bitStrength,
  }) {
    final generator = pc.RSAKeyGenerator()
      ..init(
        pc.ParametersWithRandom<pc.RSAKeyGeneratorParameters>(
          pc.RSAKeyGeneratorParameters(BigInt.from(65537), bitStrength, 12),
          _fortuna(_randomBytes(32)),
        ),
      );
    return generator.generateKeyPair();
  }

  pc.AsymmetricKeyPair<pc.ECPublicKey, pc.ECPrivateKey> _generateEcKeyPair({
    required String curveName,
  }) {
    final domain = pc.ECDomainParameters(curveName);
    final generator = pc.ECKeyGenerator()
      ..init(
        pc.ParametersWithRandom<pc.ECKeyGeneratorParameters>(
          pc.ECKeyGeneratorParameters(domain),
          _fortuna(_randomBytes(32)),
        ),
      );
    return generator.generateKeyPair();
  }

  Map<String, Object?> _rsaPublicKeyMapFromKey(pc.RSAPublicKey key) {
    return <String, Object?>{
      'n': _bigIntToBase64(key.modulus!),
      'e': _bigIntToBase64(key.publicExponent!),
    };
  }

  Map<String, Object?> _rsaPrivateKeyMapFromKey(pc.RSAPrivateKey key) {
    return <String, Object?>{
      'd': _bigIntToBase64(key.privateExponent!),
      'p': _bigIntToBase64(key.p!),
      'q': _bigIntToBase64(key.q!),
    };
  }

  Map<String, Object?> _ecPublicKeyMapFromKey(pc.ECPublicKey key) {
    return <String, Object?>{
      'curve': key.parameters!.domainName,
      'q': base64Encode(key.Q!.getEncoded(false)),
    };
  }

  Map<String, Object?> _ecPrivateKeyMapFromKey(pc.ECPrivateKey key) {
    return <String, Object?>{
      'curve': key.parameters!.domainName,
      'd': _bigIntToBase64(key.d!),
    };
  }

  String _asymmetricPublicKeyFingerprint(
    ToolboxCryptoAsymmetricAlgorithm algorithm,
    Map<String, Object?> publicKey,
  ) {
    final canonical = jsonEncode(<String, Object?>{
      'format': _asymmetricKeyFormat,
      'version': 1,
      'kind': 'public',
      'algorithm': algorithm.id,
      'public': publicKey,
    });
    return _hexDigest(crypto.sha256.convert(utf8.encode(canonical)).bytes);
  }

  ToolboxCryptoAsymmetricAlgorithm _asymmetricAlgorithmFromId(String id) {
    for (final algorithm in ToolboxCryptoAsymmetricAlgorithm.values) {
      if (algorithm.id == id) {
        return algorithm;
      }
    }
    throw const ToolboxCryptoException('Unsupported asymmetric algorithm.');
  }

  void _validateAsymmetricPayloadSize(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const ToolboxCryptoException('Input bytes are empty.');
    }
    if (bytes.length > _maxAsymmetricTextBytes) {
      throw const ToolboxCryptoException('Input text is too large.');
    }
  }

  Map<String, Object?> _decodeJsonObject(String text) {
    if (text.length > _maxAsymmetricJsonChars) {
      throw const ToolboxCryptoException('JSON payload is too large.');
    }
    try {
      final decoded = jsonDecode(text.trim());
      return _jsonObject(decoded);
    } on FormatException {
      throw const ToolboxCryptoException('JSON payload is invalid.');
    }
  }

  Map<String, Object?> _jsonObject(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    if (value is Map) {
      final output = <String, Object?>{};
      for (final entry in value.entries) {
        final key = entry.key;
        if (key is! String) {
          throw const ToolboxCryptoException('JSON payload is invalid.');
        }
        output[key] = entry.value;
      }
      return output;
    }
    throw const ToolboxCryptoException('JSON payload is invalid.');
  }

  Uint8List _base64ToBytes(String value, {required int maxBytes}) {
    final maxBase64Length = ((maxBytes + 2) ~/ 3) * 4;
    if (value.length > maxBase64Length) {
      throw const ToolboxCryptoException('Crypto payload is too large.');
    }
    try {
      final bytes = Uint8List.fromList(base64Decode(value));
      if (bytes.length > maxBytes) {
        throw const ToolboxCryptoException('Crypto payload is too large.');
      }
      return bytes;
    } on FormatException {
      throw const ToolboxCryptoException('Crypto payload is invalid.');
    }
  }

  pc.RSAPublicKey _rsaPublicKeyFromMap(Map<String, Object?> map) {
    final modulus = _bigIntFromBase64(_readString(map, 'n'));
    final exponent = _bigIntFromBase64(_readString(map, 'e'));
    _validateRsaPublicNumbers(modulus: modulus, exponent: exponent);
    return pc.RSAPublicKey(modulus, exponent);
  }

  pc.RSAPrivateKey _rsaPrivateKeyFromMap({
    required pc.RSAPublicKey publicKey,
    required Map<String, Object?> privateMap,
  }) {
    final modulus = publicKey.modulus!;
    final exponent = publicKey.publicExponent!;
    final privateExponent = _bigIntFromBase64(_readString(privateMap, 'd'));
    final p = _bigIntFromBase64(_readString(privateMap, 'p'));
    final q = _bigIntFromBase64(_readString(privateMap, 'q'));
    _validateRsaPrivateNumbers(
      modulus: modulus,
      exponent: exponent,
      privateExponent: privateExponent,
      p: p,
      q: q,
    );
    return pc.RSAPrivateKey(modulus, privateExponent, p, q);
  }

  pc.ECPublicKey _ecdsaPublicKeyFromMap(Map<String, Object?> map) {
    final domain = _p256DomainFromName(_readString(map, 'curve'));
    final qBytes = _readBase64(map, 'q', maxBytes: _maxPublicKeyBytes);
    if (qBytes.length != 65 || qBytes.first != 4) {
      throw const ToolboxCryptoException('Unsupported EC public key.');
    }
    final point = domain.curve.decodePoint(qBytes);
    if (point == null || point.isInfinity) {
      throw const ToolboxCryptoException('Unsupported EC public key.');
    }
    return pc.ECPublicKey(point, domain);
  }

  pc.ECPrivateKey _ecdsaPrivateKeyFromMap({
    required pc.ECPublicKey publicKey,
    required Map<String, Object?> privateMap,
  }) {
    final domain = _p256DomainFromName(_readString(privateMap, 'curve'));
    final d = _bigIntFromBase64(_readString(privateMap, 'd'));
    final n = domain.n;
    if (d <= BigInt.zero || d >= n) {
      throw const ToolboxCryptoException('Unsupported EC private key.');
    }
    final expectedPoint = domain.G * d;
    if (expectedPoint == null ||
        !_constantTimeBytesEquals(
          expectedPoint.getEncoded(false),
          publicKey.Q!.getEncoded(false),
        )) {
      throw const ToolboxCryptoException('EC private key does not match.');
    }
    return pc.ECPrivateKey(d, domain);
  }

  void _validateRsaPublicNumbers({
    required BigInt modulus,
    required BigInt exponent,
  }) {
    if (modulus.bitLength != 2048 || exponent != BigInt.from(65537)) {
      throw const ToolboxCryptoException('Unsupported RSA public key.');
    }
  }

  void _validateRsaPrivateNumbers({
    required BigInt modulus,
    required BigInt exponent,
    required BigInt privateExponent,
    required BigInt p,
    required BigInt q,
  }) {
    if (p <= BigInt.one ||
        q <= BigInt.one ||
        p * q != modulus ||
        privateExponent <= BigInt.one) {
      throw const ToolboxCryptoException('Unsupported RSA private key.');
    }
    final phiLcm = _lcm(p - BigInt.one, q - BigInt.one);
    if ((privateExponent * exponent) % phiLcm != BigInt.one) {
      throw const ToolboxCryptoException('RSA private key does not match.');
    }
  }

  BigInt _lcm(BigInt left, BigInt right) {
    return (left ~/ left.gcd(right)) * right;
  }

  pc.ECDomainParameters _p256DomainFromName(String curveName) {
    if (curveName != 'secp256r1' && curveName != 'prime256v1') {
      throw const ToolboxCryptoException('Unsupported EC curve.');
    }
    return pc.ECDomainParameters('secp256r1');
  }

  String _readFingerprint(Map<String, Object?> map, String key) {
    final value = _readString(map, key).toLowerCase();
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
      throw const ToolboxCryptoException('Public key fingerprint is invalid.');
    }
    return value;
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

  BigInt _bigIntFromBase64(String value, {int maxBytes = _maxPublicKeyBytes}) {
    final maxBase64Length = ((maxBytes + 2) ~/ 3) * 4;
    if (value.length > maxBase64Length) {
      throw const ToolboxCryptoException('Crypto envelope is too large.');
    }
    try {
      final bytes = base64Decode(value);
      if (bytes.length > maxBytes) {
        throw const ToolboxCryptoException('Crypto envelope is too large.');
      }
      return _decodeUnsignedBigInt(bytes);
    } on FormatException {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
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

  Uint8List _uint16Bytes(int value) {
    if (value < 0 || value > 0xffff) {
      throw const ToolboxCryptoException('Payload padding is invalid.');
    }
    return Uint8List.fromList(<int>[(value >> 8) & 255, value & 255]);
  }

  int _readUint16(Uint8List bytes, int offset) {
    if (offset < 0 || offset + 2 > bytes.length) {
      throw const ToolboxCryptoException('Payload padding is invalid.');
    }
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  int _readUint64(Uint8List bytes, int offset) {
    if (offset < 0 || offset + 8 > bytes.length) {
      throw const ToolboxCryptoException('Payload padding is invalid.');
    }
    var value = 0;
    for (var index = 0; index < 8; index += 1) {
      value = (value << 8) | bytes[offset + index];
    }
    return value;
  }

  int _readEnvelopeByte(Uint8List bytes, int offset) {
    if (offset < 0 || offset >= bytes.length) {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
    return bytes[offset];
  }

  int _readEnvelopeUint32(Uint8List bytes, int offset) {
    if (offset < 0 || offset + 4 > bytes.length) {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  Uint8List _readEnvelopeBytes(Uint8List bytes, int offset, int length) {
    if (length < 0 || offset < 0 || offset + length > bytes.length) {
      throw const ToolboxCryptoException('Crypto envelope is invalid.');
    }
    return Uint8List.fromList(bytes.sublist(offset, offset + length));
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _secureRandom.nextInt(256)),
    );
  }

  bool _constantTimeBytesEquals(List<int> left, List<int> right) {
    var diff = left.length ^ right.length;
    final maxLength = math.max(left.length, right.length);
    for (var i = 0; i < maxLength; i += 1) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      diff |= l ^ r;
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

  String _hexDigest(List<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

class _AsymmetricKeyMaterial {
  const _AsymmetricKeyMaterial({
    required this.algorithm,
    required this.publicKeyFingerprint,
    this.rsaPublicKey,
    this.rsaPrivateKey,
    this.ecPublicKey,
    this.ecPrivateKey,
  });

  final ToolboxCryptoAsymmetricAlgorithm algorithm;
  final String publicKeyFingerprint;
  final pc.RSAPublicKey? rsaPublicKey;
  final pc.RSAPrivateKey? rsaPrivateKey;
  final pc.ECPublicKey? ecPublicKey;
  final pc.ECPrivateKey? ecPrivateKey;

  bool get isPrivate => rsaPrivateKey != null || ecPrivateKey != null;
}

class _AsymmetricSignatureMaterial {
  const _AsymmetricSignatureMaterial({
    required this.algorithm,
    required this.publicKeyFingerprint,
    required this.value,
  });

  final ToolboxCryptoAsymmetricAlgorithm algorithm;
  final String publicKeyFingerprint;
  final Map<String, Object?> value;
}

class _AsymmetricCipherMaterial {
  const _AsymmetricCipherMaterial({
    required this.algorithm,
    required this.publicKeyFingerprint,
    required this.cipherBytes,
  });

  final ToolboxCryptoAsymmetricAlgorithm algorithm;
  final String publicKeyFingerprint;
  final Uint8List cipherBytes;
}

class _OpaqueEnvelopeV5 {
  const _OpaqueEnvelopeV5({
    required this.kdfSettings,
    required this.salt,
    required this.metadataNonce,
    required this.metadataCipher,
    required this.cipherBytes,
  });

  final _KdfSettings kdfSettings;
  final Uint8List salt;
  final Uint8List metadataNonce;
  final Uint8List metadataCipher;
  final Uint8List cipherBytes;
}

class _KdfSettings {
  const _KdfSettings({required this.n, required this.r, required this.p});

  factory _KdfSettings.fromStrength(ToolboxCryptoStrength strength) {
    return _KdfSettings(
      n: strength.scryptN,
      r: strength.scryptR,
      p: strength.scryptP,
    );
  }

  final int n;
  final int r;
  final int p;

  Map<String, Object?> toJson() {
    return <String, Object?>{'id': 'scrypt', 'n': n, 'r': r, 'p': p};
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

  const _CryptoStage.chacha20Poly1305({int keyBytes = 32})
    : this(
        id: 'chacha20_poly1305',
        keyBytes: keyBytes,
        usesNonce: true,
        transform: _chacha20Poly1305Transform,
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

  const _CryptoStage.serpentGcm({int keyBytes = 32})
    : this(
        id: 'serpent_gcm',
        keyBytes: keyBytes,
        usesNonce: true,
        transform: _serpentGcmTransform,
      );

  const _CryptoStage.kuznyechikGcm({int keyBytes = 32})
    : this(
        id: 'kuznyechik_gcm',
        keyBytes: keyBytes,
        usesNonce: true,
        transform: _kuznyechikGcmTransform,
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

Uint8List _chacha20Poly1305Transform({
  required bool encrypt,
  required Uint8List input,
  required Uint8List key,
  required Uint8List nonce,
  required ToolboxCryptoStrength strength,
}) {
  try {
    final cipher = pc.ChaCha20Poly1305(pc.ChaCha7539Engine(), pc.Poly1305())
      ..init(
        encrypt,
        pc.AEADParameters(
          pc.KeyParameter(_chacha20Key(key)),
          128,
          nonce,
          Uint8List(0),
        ),
      );
    final output = Uint8List(cipher.getOutputSize(input.length));
    var length = cipher.processBytes(input, 0, input.length, output, 0);
    length += cipher.doFinal(output, length);
    if (length == output.length) {
      return output;
    }
    return Uint8List.fromList(output.sublist(0, length));
  } on Object catch (error) {
    if (!encrypt) {
      throw const ToolboxCryptoException(
        'Passphrase mismatch or payload is damaged.',
      );
    }
    throw ToolboxCryptoException('Encryption failed: $error');
  }
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

Uint8List _serpentGcmTransform({
  required bool encrypt,
  required Uint8List input,
  required Uint8List key,
  required Uint8List nonce,
  required ToolboxCryptoStrength strength,
}) {
  return _gcmTransform(
    engine: ToolboxVeraCryptSerpentEngine(),
    engineId: 'serpent_gcm',
    encrypt: encrypt,
    input: input,
    key: key,
    nonce: nonce,
  );
}

Uint8List _kuznyechikGcmTransform({
  required bool encrypt,
  required Uint8List input,
  required Uint8List key,
  required Uint8List nonce,
  required ToolboxCryptoStrength strength,
}) {
  return _gcmTransform(
    engine: ToolboxVeraCryptKuznyechikEngine(),
    engineId: 'kuznyechik_gcm',
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
  List<int> associatedData = const <int>[],
}) {
  try {
    final cipher = pc.GCMBlockCipher(engine)
      ..init(
        encrypt,
        pc.AEADParameters(
          pc.KeyParameter(_gcmCipherKey(key, engineId)),
          128,
          nonce,
          Uint8List.fromList(associatedData),
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

Uint8List _chacha20Key(Uint8List key) {
  if (key.length == 32) {
    return key;
  }
  return Uint8List.fromList(
    crypto.sha256.convert(<int>[
      ...utf8.encode('chacha20_poly1305'),
      0,
      ...key,
    ]).bytes,
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

Uint8List _uint32Bytes(int value) {
  return Uint8List.fromList(
    List<int>.generate(4, (index) => (value >> ((3 - index) * 8)) & 255),
  );
}
