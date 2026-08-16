import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pc;

import 'toolbox_veracrypt_primitives.dart';

enum ToolboxVeraCryptKdf {
  pbkdf2Sha512,
  pbkdf2Sha256,
  pbkdf2Whirlpool,
  pbkdf2Blake2s,
  pbkdf2Streebog,
  argon2id,
}

extension ToolboxVeraCryptKdfInfo on ToolboxVeraCryptKdf {
  String get labelKey {
    return switch (this) {
      ToolboxVeraCryptKdf.pbkdf2Sha512 =>
        'toolbox.crypto.veracrypt.kdf.pbkdf2_sha512',
      ToolboxVeraCryptKdf.pbkdf2Sha256 =>
        'toolbox.crypto.veracrypt.kdf.pbkdf2_sha256',
      ToolboxVeraCryptKdf.pbkdf2Whirlpool =>
        'toolbox.crypto.veracrypt.kdf.pbkdf2_whirlpool',
      ToolboxVeraCryptKdf.pbkdf2Blake2s =>
        'toolbox.crypto.veracrypt.kdf.pbkdf2_blake2s',
      ToolboxVeraCryptKdf.pbkdf2Streebog =>
        'toolbox.crypto.veracrypt.kdf.pbkdf2_streebog',
      ToolboxVeraCryptKdf.argon2id => 'toolbox.crypto.veracrypt.kdf.argon2id',
    };
  }

  int iterationsForPim(int pim) {
    return switch (this) {
      ToolboxVeraCryptKdf.argon2id => ToolboxVeraCryptArgon2Params.forPim(
        pim,
      ).iterations,
      _ => pim == 0 ? 500000 : 15000 + pim * 1000,
    };
  }

  int memoryKiBForPim(int pim) {
    return switch (this) {
      ToolboxVeraCryptKdf.argon2id => ToolboxVeraCryptArgon2Params.forPim(
        pim,
      ).memoryKiB,
      _ => 0,
    };
  }
}

class ToolboxVeraCryptArgon2Params {
  const ToolboxVeraCryptArgon2Params({
    required this.iterations,
    required this.memoryKiB,
  });

  factory ToolboxVeraCryptArgon2Params.forPim(int pim) {
    final normalizedPim = pim <= 0 ? 12 : pim;
    final memoryMiB = (64 + (normalizedPim - 1) * 32).clamp(64, 1024).toInt();
    final iterations = normalizedPim <= 31
        ? 3 + ((normalizedPim - 1) ~/ 3)
        : 13 + (normalizedPim - 31);
    return ToolboxVeraCryptArgon2Params(
      iterations: iterations,
      memoryKiB: memoryMiB * 1024,
    );
  }

  final int iterations;
  final int memoryKiB;
}

enum ToolboxVeraCryptCipher { aes, serpent, twofish, camellia, kuznyechik }

extension ToolboxVeraCryptCipherInfo on ToolboxVeraCryptCipher {
  String get id {
    return switch (this) {
      ToolboxVeraCryptCipher.aes => 'aes',
      ToolboxVeraCryptCipher.serpent => 'serpent',
      ToolboxVeraCryptCipher.twofish => 'twofish',
      ToolboxVeraCryptCipher.camellia => 'camellia',
      ToolboxVeraCryptCipher.kuznyechik => 'kuznyechik',
    };
  }
}

enum ToolboxVeraCryptCipherChain {
  aes,
  serpent,
  twofish,
  camellia,
  kuznyechik,
  aesTwofish,
  aesTwofishSerpent,
  serpentAes,
  serpentTwofishAes,
  twofishSerpent,
  camelliaKuznyechik,
  kuznyechikTwofish,
  camelliaSerpent,
  kuznyechikAes,
  kuznyechikSerpentCamellia,
}

extension ToolboxVeraCryptCipherChainInfo on ToolboxVeraCryptCipherChain {
  String get id {
    return switch (this) {
      ToolboxVeraCryptCipherChain.aes => 'aes',
      ToolboxVeraCryptCipherChain.serpent => 'serpent',
      ToolboxVeraCryptCipherChain.twofish => 'twofish',
      ToolboxVeraCryptCipherChain.camellia => 'camellia',
      ToolboxVeraCryptCipherChain.kuznyechik => 'kuznyechik',
      ToolboxVeraCryptCipherChain.aesTwofish => 'aes_twofish',
      ToolboxVeraCryptCipherChain.aesTwofishSerpent => 'aes_twofish_serpent',
      ToolboxVeraCryptCipherChain.serpentAes => 'serpent_aes',
      ToolboxVeraCryptCipherChain.serpentTwofishAes => 'serpent_twofish_aes',
      ToolboxVeraCryptCipherChain.twofishSerpent => 'twofish_serpent',
      ToolboxVeraCryptCipherChain.camelliaKuznyechik => 'camellia_kuznyechik',
      ToolboxVeraCryptCipherChain.kuznyechikTwofish => 'kuznyechik_twofish',
      ToolboxVeraCryptCipherChain.camelliaSerpent => 'camellia_serpent',
      ToolboxVeraCryptCipherChain.kuznyechikAes => 'kuznyechik_aes',
      ToolboxVeraCryptCipherChain.kuznyechikSerpentCamellia =>
        'kuznyechik_serpent_camellia',
    };
  }

  String get labelKey {
    return switch (this) {
      ToolboxVeraCryptCipherChain.aes => 'toolbox.crypto.veracrypt.cipher.aes',
      ToolboxVeraCryptCipherChain.serpent =>
        'toolbox.crypto.veracrypt.cipher.serpent',
      ToolboxVeraCryptCipherChain.twofish =>
        'toolbox.crypto.veracrypt.cipher.twofish',
      ToolboxVeraCryptCipherChain.camellia =>
        'toolbox.crypto.veracrypt.cipher.camellia',
      ToolboxVeraCryptCipherChain.kuznyechik =>
        'toolbox.crypto.veracrypt.cipher.kuznyechik',
      ToolboxVeraCryptCipherChain.aesTwofish =>
        'toolbox.crypto.veracrypt.cipher.aes_twofish',
      ToolboxVeraCryptCipherChain.aesTwofishSerpent =>
        'toolbox.crypto.veracrypt.cipher.aes_twofish_serpent',
      ToolboxVeraCryptCipherChain.serpentAes =>
        'toolbox.crypto.veracrypt.cipher.serpent_aes',
      ToolboxVeraCryptCipherChain.serpentTwofishAes =>
        'toolbox.crypto.veracrypt.cipher.serpent_twofish_aes',
      ToolboxVeraCryptCipherChain.twofishSerpent =>
        'toolbox.crypto.veracrypt.cipher.twofish_serpent',
      ToolboxVeraCryptCipherChain.camelliaKuznyechik =>
        'toolbox.crypto.veracrypt.cipher.camellia_kuznyechik',
      ToolboxVeraCryptCipherChain.kuznyechikTwofish =>
        'toolbox.crypto.veracrypt.cipher.kuznyechik_twofish',
      ToolboxVeraCryptCipherChain.camelliaSerpent =>
        'toolbox.crypto.veracrypt.cipher.camellia_serpent',
      ToolboxVeraCryptCipherChain.kuznyechikAes =>
        'toolbox.crypto.veracrypt.cipher.kuznyechik_aes',
      ToolboxVeraCryptCipherChain.kuznyechikSerpentCamellia =>
        'toolbox.crypto.veracrypt.cipher.kuznyechik_serpent_camellia',
    };
  }

  List<ToolboxVeraCryptCipher> get encryptionOrder {
    return switch (this) {
      ToolboxVeraCryptCipherChain.aes => const <ToolboxVeraCryptCipher>[
        ToolboxVeraCryptCipher.aes,
      ],
      ToolboxVeraCryptCipherChain.serpent => const <ToolboxVeraCryptCipher>[
        ToolboxVeraCryptCipher.serpent,
      ],
      ToolboxVeraCryptCipherChain.twofish => const <ToolboxVeraCryptCipher>[
        ToolboxVeraCryptCipher.twofish,
      ],
      ToolboxVeraCryptCipherChain.camellia => const <ToolboxVeraCryptCipher>[
        ToolboxVeraCryptCipher.camellia,
      ],
      ToolboxVeraCryptCipherChain.kuznyechik => const <ToolboxVeraCryptCipher>[
        ToolboxVeraCryptCipher.kuznyechik,
      ],
      // VeraCrypt stores the cipher list in encryption order and displays
      // cascades by walking it backwards. "AES-Twofish" is {Twofish, AES}.
      ToolboxVeraCryptCipherChain.aesTwofish => const <ToolboxVeraCryptCipher>[
        ToolboxVeraCryptCipher.twofish,
        ToolboxVeraCryptCipher.aes,
      ],
      ToolboxVeraCryptCipherChain.aesTwofishSerpent =>
        const <ToolboxVeraCryptCipher>[
          ToolboxVeraCryptCipher.serpent,
          ToolboxVeraCryptCipher.twofish,
          ToolboxVeraCryptCipher.aes,
        ],
      ToolboxVeraCryptCipherChain.serpentAes => const <ToolboxVeraCryptCipher>[
        ToolboxVeraCryptCipher.aes,
        ToolboxVeraCryptCipher.serpent,
      ],
      ToolboxVeraCryptCipherChain.serpentTwofishAes =>
        const <ToolboxVeraCryptCipher>[
          ToolboxVeraCryptCipher.aes,
          ToolboxVeraCryptCipher.twofish,
          ToolboxVeraCryptCipher.serpent,
        ],
      ToolboxVeraCryptCipherChain.twofishSerpent =>
        const <ToolboxVeraCryptCipher>[
          ToolboxVeraCryptCipher.serpent,
          ToolboxVeraCryptCipher.twofish,
        ],
      ToolboxVeraCryptCipherChain.camelliaKuznyechik =>
        const <ToolboxVeraCryptCipher>[
          ToolboxVeraCryptCipher.kuznyechik,
          ToolboxVeraCryptCipher.camellia,
        ],
      ToolboxVeraCryptCipherChain.kuznyechikTwofish =>
        const <ToolboxVeraCryptCipher>[
          ToolboxVeraCryptCipher.twofish,
          ToolboxVeraCryptCipher.kuznyechik,
        ],
      ToolboxVeraCryptCipherChain.camelliaSerpent =>
        const <ToolboxVeraCryptCipher>[
          ToolboxVeraCryptCipher.serpent,
          ToolboxVeraCryptCipher.camellia,
        ],
      ToolboxVeraCryptCipherChain.kuznyechikAes =>
        const <ToolboxVeraCryptCipher>[
          ToolboxVeraCryptCipher.aes,
          ToolboxVeraCryptCipher.kuznyechik,
        ],
      ToolboxVeraCryptCipherChain.kuznyechikSerpentCamellia =>
        const <ToolboxVeraCryptCipher>[
          ToolboxVeraCryptCipher.camellia,
          ToolboxVeraCryptCipher.serpent,
          ToolboxVeraCryptCipher.kuznyechik,
        ],
    };
  }

  int get primaryKeySize =>
      encryptionOrder.length * ToolboxVeraCryptHeaderCrypto.cipherKeySize;

  int get xtsKeySize => primaryKeySize * 2;
}

class ToolboxVeraCryptHeaderCrypto {
  const ToolboxVeraCryptHeaderCrypto();

  static const int headerSize = 512;
  static const int saltSize = 64;
  static const int encryptedHeaderOffset = 64;
  static const int encryptedHeaderSize = 448;
  static const int masterKeyDataOffset = 256;
  static const int masterKeyDataSize = 256;
  static const int cipherKeySize = 32;
  static const int dataAesXtsKeySize = 64;
  static const int aesXtsKeySize = 64;
  static const int argon2HeaderKeyDataSize = 192;
  static const int maxHeaderKeyMaterialSize = argon2HeaderKeyDataSize;
  static const int keyfilePoolSize = 128;
  static const int legacyKeyfilePoolSize = 64;
  static const int maxKeyfileReadBytes = 1024 * 1024;

  static const int magicOffset = 64;
  static const int versionOffset = 68;
  static const int requiredVersionOffset = 70;
  static const int keyAreaCrcOffset = 72;
  static const int hiddenVolumeSizeOffset = 92;
  static const int volumeSizeOffset = 100;
  static const int encryptedAreaStartOffset = 108;
  static const int encryptedAreaLengthOffset = 116;
  static const int flagsOffset = 124;
  static const int sectorSizeOffset = 128;
  static const int headerCrcOffset = 252;

  static final List<int> _crc32Table = _buildCrc32Table();

  Uint8List deriveHeaderKey({
    required Uint8List passwordBytes,
    required Uint8List salt,
    required ToolboxVeraCryptKdf kdf,
    required int pim,
    ToolboxVeraCryptCipherChain cipherChain = ToolboxVeraCryptCipherChain.aes,
    int? iterationOverride,
    int? argon2MemoryKiBOverride,
  }) {
    return deriveHeaderKeyMaterial(
      passwordBytes: passwordBytes,
      salt: salt,
      kdf: kdf,
      pim: pim,
      outputSize: cipherChain.xtsKeySize,
      iterationOverride: iterationOverride,
      argon2MemoryKiBOverride: argon2MemoryKiBOverride,
    );
  }

  Uint8List deriveHeaderKeyMaterial({
    required Uint8List passwordBytes,
    required Uint8List salt,
    required ToolboxVeraCryptKdf kdf,
    required int pim,
    required int outputSize,
    int? iterationOverride,
    int? argon2MemoryKiBOverride,
  }) {
    if (salt.length != saltSize) {
      throw ArgumentError.value(salt.length, 'salt.length');
    }
    if (outputSize <= 0 || outputSize > maxHeaderKeyMaterialSize) {
      throw ArgumentError.value(outputSize, 'outputSize');
    }
    if (iterationOverride != null && iterationOverride <= 0) {
      throw ArgumentError.value(iterationOverride, 'iterationOverride');
    }
    if (argon2MemoryKiBOverride != null && argon2MemoryKiBOverride <= 0) {
      throw ArgumentError.value(
        argon2MemoryKiBOverride,
        'argon2MemoryKiBOverride',
      );
    }
    if (kdf == ToolboxVeraCryptKdf.argon2id) {
      final params = ToolboxVeraCryptArgon2Params.forPim(pim);
      // VeraCrypt derives a fixed 192-byte Argon2 header buffer, then slices it
      // for the candidate chain being tested.
      const argon2OutputSize = argon2HeaderKeyDataSize;
      final derivator = pc.Argon2BytesGenerator()
        ..init(
          pc.Argon2Parameters(
            pc.Argon2Parameters.ARGON2_id,
            salt,
            desiredKeyLength: argon2OutputSize,
            iterations: iterationOverride ?? params.iterations,
            memory: argon2MemoryKiBOverride ?? params.memoryKiB,
            lanes: 1,
          ),
        );
      final output = derivator.process(passwordBytes);
      if (outputSize == argon2OutputSize) {
        return output;
      }
      final sliced = Uint8List.fromList(
        Uint8List.sublistView(output, 0, outputSize),
      );
      output.fillRange(0, output.length, 0);
      return sliced;
    }
    final iterations = iterationOverride ?? kdf.iterationsForPim(pim);
    final mac = switch (kdf) {
      ToolboxVeraCryptKdf.pbkdf2Sha512 => pc.HMac(pc.SHA512Digest(), 128),
      ToolboxVeraCryptKdf.pbkdf2Sha256 => pc.HMac(pc.SHA256Digest(), 64),
      ToolboxVeraCryptKdf.pbkdf2Whirlpool => pc.HMac(pc.WhirlpoolDigest(), 64),
      ToolboxVeraCryptKdf.pbkdf2Blake2s => pc.HMac(
        ToolboxVeraCryptBlake2sDigest(),
        64,
      ),
      ToolboxVeraCryptKdf.pbkdf2Streebog => pc.HMac(
        ToolboxVeraCryptStreebog512Digest(),
        64,
      ),
      ToolboxVeraCryptKdf.argon2id => throw StateError('unreachable'),
    };
    final derivator = pc.PBKDF2KeyDerivator(mac)
      ..init(pc.Pbkdf2Parameters(salt, iterations, outputSize));
    return derivator.process(passwordBytes);
  }

  Uint8List passwordBytesForKdf({
    required String passphrase,
    Uint8List? keyfilePool,
  }) {
    final passwordBytes = Uint8List.fromList(utf8.encode(passphrase));
    return applyKeyfilePoolToBytes(
      passwordBytes: passwordBytes,
      keyfilePool: keyfilePool,
    );
  }

  Uint8List applyKeyfilePoolToBytes({
    required Uint8List passwordBytes,
    Uint8List? keyfilePool,
  }) {
    if (keyfilePool == null || keyfilePool.isEmpty) {
      return passwordBytes;
    }
    if (keyfilePool.length != legacyKeyfilePoolSize &&
        keyfilePool.length != keyfilePoolSize) {
      throw ArgumentError.value(keyfilePool.length, 'keyfilePool.length');
    }
    final poolSize = keyfilePool.length;
    final result = Uint8List(
      poolSize > passwordBytes.length ? poolSize : passwordBytes.length,
    );
    result.setRange(0, passwordBytes.length, passwordBytes);
    for (var i = 0; i < poolSize; i += 1) {
      result[i] = (result[i] + keyfilePool[i]) & 0xff;
    }
    return result;
  }

  Uint8List buildKeyfilePool(
    Uint8List bytes, {
    int poolSize = keyfilePoolSize,
  }) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes.length, 'bytes.length');
    }
    if (poolSize != legacyKeyfilePoolSize && poolSize != keyfilePoolSize) {
      throw ArgumentError.value(poolSize, 'poolSize');
    }
    final pool = Uint8List(poolSize);
    final readLength = bytes.length > maxKeyfileReadBytes
        ? maxKeyfileReadBytes
        : bytes.length;
    var crc = 0xffffffff;
    var writePos = 0;
    for (var i = 0; i < readLength; i += 1) {
      crc = updateCrc32(bytes[i], crc);
      pool[writePos] = (pool[writePos] + ((crc >> 24) & 0xff)) & 0xff;
      writePos = (writePos + 1) % poolSize;
      pool[writePos] = (pool[writePos] + ((crc >> 16) & 0xff)) & 0xff;
      writePos = (writePos + 1) % poolSize;
      pool[writePos] = (pool[writePos] + ((crc >> 8) & 0xff)) & 0xff;
      writePos = (writePos + 1) % poolSize;
      pool[writePos] = (pool[writePos] + (crc & 0xff)) & 0xff;
      writePos = (writePos + 1) % poolSize;
    }
    return pool;
  }

  Uint8List decryptHeaderPayload({
    required Uint8List encryptedPayload,
    required Uint8List headerKey,
    ToolboxVeraCryptCipherChain cipherChain = ToolboxVeraCryptCipherChain.aes,
  }) {
    return xtsCrypt(
      input: encryptedPayload,
      keyMaterial: headerKey,
      cipherChain: cipherChain,
      encrypt: false,
    );
  }

  Uint8List encryptHeaderPayload({
    required Uint8List plaintextPayload,
    required Uint8List headerKey,
    ToolboxVeraCryptCipherChain cipherChain = ToolboxVeraCryptCipherChain.aes,
  }) {
    return xtsCrypt(
      input: plaintextPayload,
      keyMaterial: headerKey,
      cipherChain: cipherChain,
      encrypt: true,
    );
  }

  Uint8List dataAesXtsKeyFromDecryptedHeader({required Uint8List fullHeader}) {
    return dataCipherKeyFromDecryptedHeader(
      fullHeader: fullHeader,
      cipherChain: ToolboxVeraCryptCipherChain.aes,
    );
  }

  Uint8List dataCipherKeyFromDecryptedHeader({
    required Uint8List fullHeader,
    required ToolboxVeraCryptCipherChain cipherChain,
  }) {
    if (fullHeader.length != headerSize) {
      throw ArgumentError.value(fullHeader.length, 'fullHeader.length');
    }
    return Uint8List.sublistView(
      fullHeader,
      masterKeyDataOffset,
      masterKeyDataOffset + cipherChain.xtsKeySize,
    );
  }

  Uint8List cryptDataUnits({
    required Uint8List input,
    required Uint8List masterKeyData,
    required int sectorSize,
    required int dataUnitStart,
    ToolboxVeraCryptCipherChain cipherChain = ToolboxVeraCryptCipherChain.aes,
    bool encrypt = false,
  }) {
    if (sectorSize <= 0 || sectorSize % 16 != 0) {
      throw ArgumentError.value(sectorSize, 'sectorSize');
    }
    if (input.length % sectorSize != 0) {
      throw ArgumentError.value(input.length, 'input.length');
    }
    if (dataUnitStart < 0) {
      throw ArgumentError.value(dataUnitStart, 'dataUnitStart');
    }
    if (masterKeyData.length < cipherChain.xtsKeySize) {
      throw ArgumentError.value(masterKeyData.length, 'masterKeyData.length');
    }

    final output = Uint8List(input.length);
    final keyMaterial = Uint8List.sublistView(
      masterKeyData,
      0,
      cipherChain.xtsKeySize,
    );
    var dataUnitNo = dataUnitStart;
    for (var offset = 0; offset < input.length; offset += sectorSize) {
      final transformed = xtsCrypt(
        input: Uint8List.sublistView(input, offset, offset + sectorSize),
        keyMaterial: keyMaterial,
        cipherChain: cipherChain,
        encrypt: encrypt,
        dataUnitNo: dataUnitNo,
      );
      output.setRange(offset, offset + sectorSize, transformed);
      dataUnitNo += 1;
    }
    return output;
  }

  Uint8List xtsCrypt({
    required Uint8List input,
    required Uint8List keyMaterial,
    required ToolboxVeraCryptCipherChain cipherChain,
    bool encrypt = false,
    int dataUnitNo = 0,
  }) {
    if (keyMaterial.length != cipherChain.xtsKeySize) {
      throw ArgumentError.value(keyMaterial.length, 'keyMaterial.length');
    }
    var output = Uint8List.fromList(input);
    final stages = _xtsStageKeys(keyMaterial, cipherChain);
    final orderedStages = encrypt ? stages : stages.reversed;
    for (final stage in orderedStages) {
      output = _singleCipherXtsCrypt(
        input: output,
        cipher: stage.cipher,
        dataKey: stage.dataKey,
        tweakKey: stage.tweakKey,
        encrypt: encrypt,
        dataUnitNo: dataUnitNo,
      );
    }
    return output;
  }

  Uint8List aesXtsCrypt({
    required Uint8List input,
    required Uint8List dataKey,
    required Uint8List tweakKey,
    bool encrypt = false,
    int dataUnitNo = 0,
  }) {
    return _singleCipherXtsCrypt(
      input: input,
      cipher: ToolboxVeraCryptCipher.aes,
      dataKey: dataKey,
      tweakKey: tweakKey,
      encrypt: encrypt,
      dataUnitNo: dataUnitNo,
    );
  }

  Uint8List _singleCipherXtsCrypt({
    required Uint8List input,
    required ToolboxVeraCryptCipher cipher,
    required Uint8List dataKey,
    required Uint8List tweakKey,
    bool encrypt = false,
    int dataUnitNo = 0,
  }) {
    if (input.length % 16 != 0) {
      throw ArgumentError.value(input.length, 'input.length');
    }
    if (dataKey.length != 32 || tweakKey.length != 32) {
      throw ArgumentError('VeraCrypt XTS requires two 256-bit keys.');
    }

    final dataCipher = _blockCipherFor(cipher)
      ..init(encrypt, pc.KeyParameter(dataKey));
    final tweakCipher = _blockCipherFor(cipher)
      ..init(true, pc.KeyParameter(tweakKey));
    final output = Uint8List(input.length);
    final unitNoBytes = Uint8List(16);
    _writeLeUint64(unitNoBytes, 0, dataUnitNo);
    var tweak = Uint8List(16);
    tweakCipher.processBlock(unitNoBytes, 0, tweak, 0);

    for (var offset = 0; offset < input.length; offset += 16) {
      final block = Uint8List(16);
      for (var i = 0; i < 16; i += 1) {
        block[i] = input[offset + i] ^ tweak[i];
      }
      final transformed = Uint8List(16);
      dataCipher.processBlock(block, 0, transformed, 0);
      for (var i = 0; i < 16; i += 1) {
        output[offset + i] = transformed[i] ^ tweak[i];
      }
      tweak = _multiplyByX(tweak);
    }

    return output;
  }

  List<_VeraCryptXtsStageKey> _xtsStageKeys(
    Uint8List keyMaterial,
    ToolboxVeraCryptCipherChain cipherChain,
  ) {
    final ciphers = cipherChain.encryptionOrder;
    final primaryKeySize = cipherChain.primaryKeySize;
    return List<_VeraCryptXtsStageKey>.generate(ciphers.length, (index) {
      final primaryOffset = index * cipherKeySize;
      final secondaryOffset = primaryKeySize + index * cipherKeySize;
      return _VeraCryptXtsStageKey(
        cipher: ciphers[index],
        dataKey: Uint8List.sublistView(
          keyMaterial,
          primaryOffset,
          primaryOffset + cipherKeySize,
        ),
        tweakKey: Uint8List.sublistView(
          keyMaterial,
          secondaryOffset,
          secondaryOffset + cipherKeySize,
        ),
      );
    });
  }

  pc.BlockCipher _blockCipherFor(ToolboxVeraCryptCipher cipher) {
    return switch (cipher) {
      ToolboxVeraCryptCipher.aes => pc.AESEngine(),
      ToolboxVeraCryptCipher.serpent => ToolboxVeraCryptSerpentEngine(),
      ToolboxVeraCryptCipher.twofish => pc.TwofishEngine(),
      ToolboxVeraCryptCipher.camellia => pc.CamelliaEngine(),
      ToolboxVeraCryptCipher.kuznyechik => ToolboxVeraCryptKuznyechikEngine(),
    };
  }

  ToolboxVeraCryptDecodedHeader? decodeDecryptedHeader({
    required Uint8List fullHeader,
    required ToolboxVeraCryptKdf kdf,
    required ToolboxVeraCryptCipherChain cipherChain,
    required int iterations,
    int memoryKiB = 0,
  }) {
    if (fullHeader.length != headerSize) {
      throw ArgumentError.value(fullHeader.length, 'fullHeader.length');
    }
    if (_readBeUint32(fullHeader, magicOffset) != 0x56455241) {
      return null;
    }
    final headerVersion = _readBeUint16(fullHeader, versionOffset);
    if (headerVersion > 5) {
      return null;
    }
    final expectedHeaderCrc = _readBeUint32(fullHeader, headerCrcOffset);
    final actualHeaderCrc = crc32(
      Uint8List.sublistView(fullHeader, magicOffset, headerCrcOffset),
    );
    if (expectedHeaderCrc != actualHeaderCrc) {
      return null;
    }
    final expectedKeyAreaCrc = _readBeUint32(fullHeader, keyAreaCrcOffset);
    final actualKeyAreaCrc = crc32(
      Uint8List.sublistView(
        fullHeader,
        masterKeyDataOffset,
        masterKeyDataOffset + masterKeyDataSize,
      ),
    );
    if (expectedKeyAreaCrc != actualKeyAreaCrc) {
      return null;
    }

    final hiddenVolumeSize = _readBeUint64(fullHeader, hiddenVolumeSizeOffset);
    return ToolboxVeraCryptDecodedHeader(
      kdf: kdf,
      cipherChain: cipherChain,
      iterations: iterations,
      memoryKiB: memoryKiB,
      headerVersion: headerVersion,
      requiredProgramVersion: _readBeUint16(fullHeader, requiredVersionOffset),
      hiddenVolume: hiddenVolumeSize > 0,
      hiddenVolumeSize: hiddenVolumeSize,
      volumeSize: _readBeUint64(fullHeader, volumeSizeOffset),
      encryptedAreaStart: _readBeUint64(fullHeader, encryptedAreaStartOffset),
      encryptedAreaLength: _readBeUint64(fullHeader, encryptedAreaLengthOffset),
      flags: _readBeUint32(fullHeader, flagsOffset),
      sectorSize: _readBeUint32(fullHeader, sectorSizeOffset),
    );
  }

  Uint8List buildSyntheticHeaderForTesting({
    required String passphrase,
    required ToolboxVeraCryptKdf kdf,
    ToolboxVeraCryptCipherChain cipherChain = ToolboxVeraCryptCipherChain.aes,
    int pim = 0,
    int? iterationOverride,
    int? argon2MemoryKiBOverride,
    Uint8List? keyfilePool,
    Uint8List? salt,
    int volumeSize = 8 * 1024 * 1024,
    int encryptedAreaStart = 131072,
    int? encryptedAreaLength,
    int sectorSize = 512,
    Uint8List? masterKeyData,
  }) {
    final resolvedSalt =
        salt ?? Uint8List.fromList(List<int>.generate(saltSize, (i) => i));
    final passwordBytes = passwordBytesForKdf(
      passphrase: passphrase,
      keyfilePool: keyfilePool,
    );
    final headerKey = deriveHeaderKey(
      passwordBytes: passwordBytes,
      salt: resolvedSalt,
      kdf: kdf,
      pim: pim,
      cipherChain: cipherChain,
      iterationOverride: iterationOverride,
      argon2MemoryKiBOverride: argon2MemoryKiBOverride,
    );
    final header = Uint8List(headerSize);
    header.setRange(0, saltSize, resolvedSalt);
    _writeBeUint32(header, magicOffset, 0x56455241);
    _writeBeUint16(header, versionOffset, 5);
    _writeBeUint16(header, requiredVersionOffset, 0x010b);
    _writeBeUint64(header, volumeSizeOffset, volumeSize);
    _writeBeUint64(header, encryptedAreaStartOffset, encryptedAreaStart);
    _writeBeUint64(
      header,
      encryptedAreaLengthOffset,
      encryptedAreaLength ?? volumeSize,
    );
    _writeBeUint32(header, sectorSizeOffset, sectorSize);
    final resolvedMasterKeyData =
        masterKeyData ??
        Uint8List.fromList(
          List<int>.generate(masterKeyDataSize, (i) => (i * 29 + 11) & 0xff),
        );
    if (resolvedMasterKeyData.length != masterKeyDataSize) {
      throw ArgumentError.value(
        resolvedMasterKeyData.length,
        'masterKeyData.length',
      );
    }
    header.setRange(
      masterKeyDataOffset,
      masterKeyDataOffset + masterKeyDataSize,
      resolvedMasterKeyData,
    );
    _writeBeUint32(
      header,
      keyAreaCrcOffset,
      crc32(
        Uint8List.sublistView(
          header,
          masterKeyDataOffset,
          masterKeyDataOffset + masterKeyDataSize,
        ),
      ),
    );
    _writeBeUint32(
      header,
      headerCrcOffset,
      crc32(Uint8List.sublistView(header, magicOffset, headerCrcOffset)),
    );
    final encryptedPayload = encryptHeaderPayload(
      plaintextPayload: Uint8List.sublistView(
        header,
        encryptedHeaderOffset,
        headerSize,
      ),
      headerKey: headerKey,
      cipherChain: cipherChain,
    );
    header.setRange(encryptedHeaderOffset, headerSize, encryptedPayload);
    return header;
  }

  int crc32(Uint8List bytes) {
    var crc = 0xffffffff;
    for (final byte in bytes) {
      crc = updateCrc32(byte, crc);
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }

  int updateCrc32(int byte, int crc) {
    return ((crc >> 8) ^ _crc32Table[(crc ^ byte) & 0xff]) & 0xffffffff;
  }

  static List<int> _buildCrc32Table() {
    return List<int>.generate(256, (index) {
      var crc = index;
      for (var i = 0; i < 8; i += 1) {
        if ((crc & 1) == 1) {
          crc = (crc >> 1) ^ 0xedb88320;
        } else {
          crc >>= 1;
        }
      }
      return crc & 0xffffffff;
    });
  }

  static Uint8List _multiplyByX(Uint8List tweak) {
    final result = Uint8List.fromList(tweak);
    final finalCarry = (result[15] & 0x80) != 0 ? 0x87 : 0;
    for (var i = 15; i > 0; i -= 1) {
      final carry = (result[i - 1] & 0x80) != 0 ? 1 : 0;
      result[i] = ((result[i] << 1) & 0xff) | carry;
    }
    result[0] = ((result[0] << 1) & 0xff) ^ finalCarry;
    return result;
  }

  static int _readBeUint16(Uint8List bytes, int offset) {
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  static int _readBeUint32(Uint8List bytes, int offset) {
    return ((bytes[offset] << 24) |
            (bytes[offset + 1] << 16) |
            (bytes[offset + 2] << 8) |
            bytes[offset + 3]) &
        0xffffffff;
  }

  static int _readBeUint64(Uint8List bytes, int offset) {
    var value = 0;
    for (var i = 0; i < 8; i += 1) {
      value = (value << 8) | bytes[offset + i];
    }
    return value;
  }

  static void _writeBeUint16(Uint8List bytes, int offset, int value) {
    bytes[offset] = (value >> 8) & 0xff;
    bytes[offset + 1] = value & 0xff;
  }

  static void _writeBeUint32(Uint8List bytes, int offset, int value) {
    bytes[offset] = (value >> 24) & 0xff;
    bytes[offset + 1] = (value >> 16) & 0xff;
    bytes[offset + 2] = (value >> 8) & 0xff;
    bytes[offset + 3] = value & 0xff;
  }

  static void _writeBeUint64(Uint8List bytes, int offset, int value) {
    for (var i = 7; i >= 0; i -= 1) {
      bytes[offset + i] = value & 0xff;
      value >>= 8;
    }
  }

  static void _writeLeUint64(Uint8List bytes, int offset, int value) {
    for (var i = 0; i < 8; i += 1) {
      bytes[offset + i] = value & 0xff;
      value >>= 8;
    }
  }
}

class _VeraCryptXtsStageKey {
  const _VeraCryptXtsStageKey({
    required this.cipher,
    required this.dataKey,
    required this.tweakKey,
  });

  final ToolboxVeraCryptCipher cipher;
  final Uint8List dataKey;
  final Uint8List tweakKey;
}

class ToolboxVeraCryptDecodedHeader {
  const ToolboxVeraCryptDecodedHeader({
    required this.kdf,
    required this.cipherChain,
    required this.iterations,
    required this.memoryKiB,
    required this.headerVersion,
    required this.requiredProgramVersion,
    required this.hiddenVolume,
    required this.hiddenVolumeSize,
    required this.volumeSize,
    required this.encryptedAreaStart,
    required this.encryptedAreaLength,
    required this.flags,
    required this.sectorSize,
  });

  final ToolboxVeraCryptKdf kdf;
  final ToolboxVeraCryptCipherChain cipherChain;
  final int iterations;
  final int memoryKiB;
  final int headerVersion;
  final int requiredProgramVersion;
  final bool hiddenVolume;
  final int hiddenVolumeSize;
  final int volumeSize;
  final int encryptedAreaStart;
  final int encryptedAreaLength;
  final int flags;
  final int sectorSize;
}
