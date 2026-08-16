import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_crypto_service.dart';

void main() {
  group('ToolboxCryptoService', () {
    final service = ToolboxCryptoService();

    test('encrypts and decrypts bytes with AES-GCM', () {
      final plain = Uint8List.fromList(utf8.encode('secret text 你好'));
      final encrypted = service.encryptBytes(
        plainBytes: plain,
        algorithm: ToolboxCryptoAlgorithm.aesGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'moon-key',
        fileName: 'secret_plan.txt',
        mediaType: 'text/plain',
      );

      expect(encrypted.envelopeBytes.length, greaterThan(plain.length));
      expect(encrypted.cipherBytes.length, greaterThan(plain.length));
      expect(encrypted.cipherPreview, isNotEmpty);
      _expectOpaqueV5Envelope(
        encrypted.envelopeBytes,
        hiddenText: const <String>[
          'algorithm',
          'aes_gcm',
          'padding',
          'secret_plan.txt',
          'text/plain',
          'plainSha256',
          'keyFileSha256',
        ],
      );

      final decrypted = service.decryptBytes(
        envelopeBytes: encrypted.envelopeBytes,
        passphrase: 'moon-key',
      );
      expect(utf8.decode(decrypted.plainBytes), 'secret text 你好');
      expect(decrypted.algorithm, ToolboxCryptoAlgorithm.aesGcm);
      expect(decrypted.fileName, 'secret_plan.txt');
      expect(decrypted.mediaType, 'text/plain');
    });

    test('rejects malicious envelope resource parameters before KDF work', () {
      final encrypted = service.encryptBytes(
        plainBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        algorithm: ToolboxCryptoAlgorithm.aesGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'bounded-key',
      );
      final highCostEnvelope = _copyWithUint32(
        encrypted.envelopeBytes,
        9,
        1 << 30,
      );
      expect(
        () => service.decryptBytes(
          envelopeBytes: highCostEnvelope,
          passphrase: 'bounded-key',
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );

      final lowCostEnvelope = _copyWithUint32(encrypted.envelopeBytes, 9, 2);
      expect(
        () => service.decryptBytes(
          envelopeBytes: lowCostEnvelope,
          passphrase: 'bounded-key',
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );

      final oversizedMetadataEnvelope = _copyWithUint32(
        encrypted.envelopeBytes,
        _opaqueMetadataLengthOffset(encrypted.envelopeBytes),
        128 * 1024,
      );
      expect(
        () => service.decryptBytes(
          envelopeBytes: oversizedMetadataEnvelope,
          passphrase: 'bounded-key',
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );
    });

    test('rejects unpublished legacy crypto envelope versions', () {
      for (final staleVersion in <int>[2, 3, 5]) {
        final staleEnvelope = <String, Object?>{
          'format': 'vocabulary_sleep_crypto',
          'version': staleVersion,
        };
        expect(
          () => service.decryptBytes(
            envelopeBytes: Uint8List.fromList(
              utf8.encode(jsonEncode(staleEnvelope)),
            ),
            passphrase: 'version-key',
          ),
          throwsA(isA<ToolboxCryptoException>()),
        );
      }
    });

    test('supports combination encryption pipeline', () {
      final plain = Uint8List.fromList(
        List<int>.generate(512, (index) => (index * 17) & 255),
      );
      final encrypted = service.encryptBytes(
        plainBytes: plain,
        algorithm: ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'combo-key',
      );
      final decrypted = service.decryptBytes(
        envelopeBytes: encrypted.envelopeBytes,
        passphrase: 'combo-key',
      );

      expect(decrypted.plainBytes, plain);
      expect(decrypted.algorithm, ToolboxCryptoAlgorithm.aesTwofishCamelliaGcm);
    });

    test('encrypts and decrypts bytes with Serpent-GCM and Kuznyechik-GCM', () {
      final plain = Uint8List.fromList(
        List<int>.generate(257, (index) => (index * 19) & 255),
      );
      for (final algorithm in <ToolboxCryptoAlgorithm>[
        ToolboxCryptoAlgorithm.serpentGcm,
        ToolboxCryptoAlgorithm.kuznyechikGcm,
      ]) {
        final encrypted = service.encryptBytes(
          plainBytes: plain,
          algorithm: algorithm,
          strength: ToolboxCryptoStrength.standard,
          passphrase: 'eastern-cipher-key',
        );
        _expectOpaqueV5Envelope(
          encrypted.envelopeBytes,
          hiddenText: <String>['algorithm', algorithm.id, 'stages'],
        );

        final decrypted = service.decryptBytes(
          envelopeBytes: encrypted.envelopeBytes,
          passphrase: 'eastern-cipher-key',
        );
        expect(decrypted.plainBytes, plain);
        expect(decrypted.algorithm, algorithm);
      }
    });

    test('supports full custom cascade and fixed high-strength cascade', () {
      final plain = Uint8List.fromList(
        List<int>.generate(401, (index) => (index * 23) & 255),
      );
      final custom = service.encryptBytes(
        plainBytes: plain,
        algorithm: ToolboxCryptoAlgorithm.customCascade,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'full-cascade-key',
        cascade: const <ToolboxCryptoCascadeCipher>[
          ToolboxCryptoCascadeCipher.aes,
          ToolboxCryptoCascadeCipher.twofish,
          ToolboxCryptoCascadeCipher.camellia,
          ToolboxCryptoCascadeCipher.serpent,
          ToolboxCryptoCascadeCipher.kuznyechik,
          ToolboxCryptoCascadeCipher.chacha20,
        ],
        keyBits: ToolboxCryptoKeyBits.bits512,
      );
      _expectOpaqueV5Envelope(
        custom.envelopeBytes,
        hiddenText: const <String>[
          'custom_cascade',
          'stages',
          'serpent_gcm',
          'kuznyechik_gcm',
        ],
      );
      expect(
        service
            .decryptBytes(
              envelopeBytes: custom.envelopeBytes,
              passphrase: 'full-cascade-key',
            )
            .plainBytes,
        plain,
      );

      final fixed = service.encryptBytes(
        plainBytes: plain,
        algorithm:
            ToolboxCryptoAlgorithm.aesTwofishCamelliaSerpentKuznyechikGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'fixed-cascade-key',
      );
      _expectOpaqueV5Envelope(
        fixed.envelopeBytes,
        hiddenText: const <String>[
          'aes_twofish_camellia_serpent_kuznyechik_gcm',
          'stages',
          'serpent_gcm',
          'kuznyechik_gcm',
        ],
      );
      expect(
        service
            .decryptBytes(
              envelopeBytes: fixed.envelopeBytes,
              passphrase: 'fixed-cascade-key',
            )
            .plainBytes,
        plain,
      );
    });

    test('encrypts and decrypts bytes with ChaCha20-Poly1305', () {
      final plain = Uint8List.fromList(utf8.encode('chacha payload'));
      final encrypted = service.encryptBytes(
        plainBytes: plain,
        algorithm: ToolboxCryptoAlgorithm.chacha20Poly1305,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'chacha-key',
      );

      _expectOpaqueV5Envelope(
        encrypted.envelopeBytes,
        hiddenText: const <String>['algorithm', 'chacha20_poly1305', 'stages'],
      );

      final decrypted = service.decryptBytes(
        envelopeBytes: encrypted.envelopeBytes,
        passphrase: 'chacha-key',
      );
      expect(decrypted.plainBytes, plain);
      expect(decrypted.algorithm, ToolboxCryptoAlgorithm.chacha20Poly1305);
    });

    test('requires matching key file when one is used', () {
      final encrypted = service.encryptBytes(
        plainBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        algorithm: ToolboxCryptoAlgorithm.twofishGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'file-key',
        keyFileBytes: Uint8List.fromList(<int>[9, 8, 7]),
      );

      expect(
        () => service.decryptBytes(
          envelopeBytes: encrypted.envelopeBytes,
          passphrase: 'file-key',
          keyFileBytes: Uint8List.fromList(<int>[7, 8, 9]),
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );

      final decrypted = service.decryptBytes(
        envelopeBytes: encrypted.envelopeBytes,
        passphrase: 'file-key',
        keyFileBytes: Uint8List.fromList(<int>[9, 8, 7]),
      );
      expect(decrypted.plainBytes, Uint8List.fromList(<int>[1, 2, 3, 4]));
    });

    test('combines multiple key files without depending on import order', () {
      final first = ToolboxCryptoKeyFileInput(
        name: 'beta.key',
        bytes: Uint8List.fromList(<int>[9, 8, 7, 6]),
      );
      final second = ToolboxCryptoKeyFileInput(
        name: 'alpha.key',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
      );
      final left = service.combineKeyFiles(<ToolboxCryptoKeyFileInput>[
        first,
        second,
      ]);
      final right = service.combineKeyFiles(<ToolboxCryptoKeyFileInput>[
        second,
        first,
      ]);

      expect(left.sha256, right.sha256);
      expect(left.bytes, right.bytes);
      expect(left.entries.map((entry) => entry.name), <String>[
        'alpha.key',
        'beta.key',
      ]);

      final encrypted = service.encryptBytes(
        plainBytes: Uint8List.fromList(utf8.encode('orderless key files')),
        algorithm: ToolboxCryptoAlgorithm.serpentGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'orderless',
        keyFileBytes: left.bytes,
      );
      final decrypted = service.decryptBytes(
        envelopeBytes: encrypted.envelopeBytes,
        passphrase: 'orderless',
        keyFileBytes: right.bytes,
      );
      expect(utf8.decode(decrypted.plainBytes), 'orderless key files');
    });

    test('derives passphrase key files and rejects tampered envelopes', () {
      final keyFile = service.deriveKeyFileFromPassphrase(
        passphrase: 'derive-key-file-passphrase',
        length: 64,
        strength: ToolboxCryptoStrength.standard,
        saltText: 'user-export-context',
      );
      final repeated = service.deriveKeyFileFromPassphrase(
        passphrase: 'derive-key-file-passphrase',
        length: 64,
        strength: ToolboxCryptoStrength.standard,
        saltText: 'user-export-context',
      );
      expect(keyFile.sha256, repeated.sha256);
      expect(keyFile.bytes.length, 64);

      final encrypted = service.encryptBytes(
        plainBytes: Uint8List.fromList(utf8.encode('tamper checked')),
        algorithm: ToolboxCryptoAlgorithm.kuznyechikGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'tamper-key',
        keyFileBytes: keyFile.bytes,
        signatureMode: ToolboxCryptoSignatureMode.ecdsaSha256,
      );
      _expectOpaqueV5Envelope(
        encrypted.envelopeBytes,
        hiddenText: const <String>[
          'kuznyechik_gcm',
          'ecdsa_sha256',
          'signature',
        ],
      );
      final tampered = Uint8List.fromList(encrypted.envelopeBytes);
      tampered[tampered.length - 1] ^= 0x01;
      expect(
        () => service.decryptBytes(
          envelopeBytes: tampered,
          passphrase: 'tamper-key',
          keyFileBytes: keyFile.bytes,
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );
    });

    test('hashes bytes with selectable algorithms', () {
      final sha = service.hashBytes(
        bytes: Uint8List.fromList(utf8.encode('abc')),
        algorithm: ToolboxCryptoHashAlgorithm.sha256,
      );
      final blake = service.hashBytes(
        bytes: Uint8List.fromList(utf8.encode('abc')),
        algorithm: ToolboxCryptoHashAlgorithm.blake2b256,
      );

      expect(
        sha.hex,
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(blake.hex.length, 64);
    });

    test('supports custom cascade with 512-bit stage material', () {
      final plain = Uint8List.fromList(
        List<int>.generate(333, (index) => (index * 31) & 255),
      );
      final encrypted = service.encryptBytes(
        plainBytes: plain,
        algorithm: ToolboxCryptoAlgorithm.customCascade,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'custom-key',
        cascade: const <ToolboxCryptoCascadeCipher>[
          ToolboxCryptoCascadeCipher.aes,
          ToolboxCryptoCascadeCipher.twofish,
          ToolboxCryptoCascadeCipher.camellia,
        ],
        keyBits: ToolboxCryptoKeyBits.bits512,
        macAlgorithm: ToolboxCryptoMacAlgorithm.whirlpool,
      );

      _expectOpaqueV5Envelope(
        encrypted.envelopeBytes,
        hiddenText: const <String>[
          'keyBits',
          'whirlpool',
          'stages',
          'twofish_gcm',
        ],
      );

      final decrypted = service.decryptBytes(
        envelopeBytes: encrypted.envelopeBytes,
        passphrase: 'custom-key',
      );
      expect(decrypted.plainBytes, plain);
      expect(decrypted.algorithm, ToolboxCryptoAlgorithm.customCascade);
    });

    test('supports 2048 and 4096-bit derived stage material', () {
      expect(ToolboxCryptoKeyBits.bits2048.bits, 2048);
      expect(ToolboxCryptoKeyBits.bits2048.bytes, 256);
      expect(ToolboxCryptoKeyBits.bits4096.bits, 4096);
      expect(ToolboxCryptoKeyBits.bits4096.bytes, 512);

      final plain = Uint8List.fromList(
        List<int>.generate(193, (index) => (index * 37) & 255),
      );
      for (final keyBits in <ToolboxCryptoKeyBits>[
        ToolboxCryptoKeyBits.bits2048,
        ToolboxCryptoKeyBits.bits4096,
      ]) {
        final encrypted = service.encryptBytes(
          plainBytes: plain,
          algorithm: ToolboxCryptoAlgorithm.aesGcm,
          strength: ToolboxCryptoStrength.standard,
          passphrase: 'wide-key-material-${keyBits.id}',
          keyBits: keyBits,
        );
        _expectOpaqueV5Envelope(
          encrypted.envelopeBytes,
          hiddenText: const <String>['keyBits', 'stages'],
        );

        final decrypted = service.decryptBytes(
          envelopeBytes: encrypted.envelopeBytes,
          passphrase: 'wide-key-material-${keyBits.id}',
        );
        expect(decrypted.plainBytes, plain);
        expect(decrypted.algorithm, ToolboxCryptoAlgorithm.aesGcm);
      }
    });

    test('supports package-local weak, RSA, and ECDSA integrity checks', () {
      for (final mode in <ToolboxCryptoSignatureMode>[
        ToolboxCryptoSignatureMode.weakSha256,
        ToolboxCryptoSignatureMode.rsaSha256,
        ToolboxCryptoSignatureMode.ecdsaSha256,
      ]) {
        final encrypted = service.encryptBytes(
          plainBytes: Uint8List.fromList(utf8.encode('signed payload')),
          algorithm: ToolboxCryptoAlgorithm.aesGcm,
          strength: ToolboxCryptoStrength.standard,
          passphrase: 'sign-key',
          signatureMode: mode,
        );
        _expectOpaqueV5Envelope(
          encrypted.envelopeBytes,
          hiddenText: <String>['signatureMode', mode.id, 'signaturePublic'],
        );
        final decrypted = service.decryptBytes(
          envelopeBytes: encrypted.envelopeBytes,
          passphrase: 'sign-key',
        );
        expect(utf8.decode(decrypted.plainBytes), 'signed payload');

        if (mode == ToolboxCryptoSignatureMode.weakSha256) {
          final tamperedEnvelope = Uint8List.fromList(encrypted.envelopeBytes);
          final metadataOffset = _opaqueMetadataLengthOffset(tamperedEnvelope);
          tamperedEnvelope[metadataOffset + 5] ^= 0x01;
          expect(
            () => service.decryptBytes(
              envelopeBytes: tamperedEnvelope,
              passphrase: 'sign-key',
            ),
            throwsA(isA<ToolboxCryptoException>()),
          );
        }
      }
    });

    test('hashes with Whirlpool and generates random key files', () {
      final whirlpool = service.hashBytes(
        bytes: Uint8List.fromList(utf8.encode('abc')),
        algorithm: ToolboxCryptoHashAlgorithm.whirlpool,
      );
      final keyFile = service.generateKeyFile(length: 64);

      expect(whirlpool.hex.length, 128);
      expect(keyFile.bytes.length, 64);
      expect(keyFile.sha256.length, 64);
    });

    test('hashes common MD5 and SHA known vectors', () {
      final bytes = Uint8List.fromList(utf8.encode('abc'));

      expect(
        service
            .hashBytes(bytes: bytes, algorithm: ToolboxCryptoHashAlgorithm.md5)
            .hex,
        '900150983cd24fb0d6963f7d28e17f72',
      );
      expect(
        service
            .hashBytes(bytes: bytes, algorithm: ToolboxCryptoHashAlgorithm.sha1)
            .hex,
        'a9993e364706816aba3e25717850c26c9cd0d89d',
      );
      expect(
        service
            .hashBytes(
              bytes: bytes,
              algorithm: ToolboxCryptoHashAlgorithm.sha256,
            )
            .hex,
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('generates RSA keys, signs, verifies, and encrypts small text', () {
      final keyPair = service.generateAsymmetricKeyPair(
        algorithm: ToolboxCryptoAsymmetricAlgorithm.rsa2048,
      );
      final message = Uint8List.fromList(utf8.encode('rsa message'));
      final tampered = Uint8List.fromList(utf8.encode('rsa message!'));

      final signature = service.signBytes(
        bytes: message,
        privateKeyText: keyPair.privateKeyText,
      );
      expect(signature.algorithm, ToolboxCryptoAsymmetricAlgorithm.rsa2048);
      expect(signature.publicKeyFingerprint, keyPair.publicKeyFingerprint);
      expect(
        service
            .verifyBytes(
              bytes: message,
              publicKeyText: keyPair.publicKeyText,
              signatureText: signature.signatureText,
            )
            .isValid,
        isTrue,
      );
      expect(
        service
            .verifyBytes(
              bytes: tampered,
              publicKeyText: keyPair.publicKeyText,
              signatureText: signature.signatureText,
            )
            .isValid,
        isFalse,
      );

      final cipher = service.encryptBytesWithPublicKey(
        plainBytes: message,
        publicKeyText: keyPair.publicKeyText,
      );
      expect(cipher.algorithm, ToolboxCryptoAsymmetricAlgorithm.rsa2048);
      expect(cipher.publicKeyFingerprint, keyPair.publicKeyFingerprint);
      expect(cipher.cipherBytes, greaterThan(message.length));
      final decrypted = service.decryptBytesWithPrivateKey(
        cipherText: cipher.cipherText,
        privateKeyText: keyPair.privateKeyText,
      );
      expect(decrypted, message);
    });

    test('rejects asymmetric fingerprint and key strength mismatches', () {
      final firstKeyPair = service.generateAsymmetricKeyPair(
        algorithm: ToolboxCryptoAsymmetricAlgorithm.rsa2048,
      );
      final secondKeyPair = service.generateAsymmetricKeyPair(
        algorithm: ToolboxCryptoAsymmetricAlgorithm.rsa2048,
      );
      final message = Uint8List.fromList(utf8.encode('bound message'));
      final signature = service.signBytes(
        bytes: message,
        privateKeyText: firstKeyPair.privateKeyText,
      );

      expect(
        () => service.verifyBytes(
          bytes: message,
          publicKeyText: secondKeyPair.publicKeyText,
          signatureText: signature.signatureText,
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );

      final cipher = service.encryptBytesWithPublicKey(
        plainBytes: message,
        publicKeyText: firstKeyPair.publicKeyText,
      );
      expect(
        () => service.decryptBytesWithPrivateKey(
          cipherText: cipher.cipherText,
          privateKeyText: secondKeyPair.privateKeyText,
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );

      final weakPublicKey = _jsonMapFromText(firstKeyPair.publicKeyText);
      final weakPublic = weakPublicKey['public']! as Map<String, Object?>;
      weakPublic['n'] = _bigIntToBase64(BigInt.from(3233));
      expect(
        () => service.verifyBytes(
          bytes: message,
          publicKeyText: jsonEncode(weakPublicKey),
          signatureText: signature.signatureText,
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );
    });

    test('generates ECC P-256 keys for signing and rejects ECC encryption', () {
      final keyPair = service.generateAsymmetricKeyPair(
        algorithm: ToolboxCryptoAsymmetricAlgorithm.ecP256,
      );
      final message = Uint8List.fromList(utf8.encode('ecc message'));

      final signature = service.signBytes(
        bytes: message,
        privateKeyText: keyPair.privateKeyText,
      );
      expect(signature.algorithm, ToolboxCryptoAsymmetricAlgorithm.ecP256);
      expect(
        service
            .verifyBytes(
              bytes: message,
              publicKeyText: keyPair.publicKeyText,
              signatureText: signature.signatureText,
            )
            .isValid,
        isTrue,
      );
      expect(
        service
            .verifyBytes(
              bytes: Uint8List.fromList(utf8.encode('ecc message!')),
              publicKeyText: keyPair.publicKeyText,
              signatureText: signature.signatureText,
            )
            .isValid,
        isFalse,
      );
      expect(
        () => service.encryptBytesWithPublicKey(
          plainBytes: message,
          publicKeyText: keyPair.publicKeyText,
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );
    });

    test('rejects non-P-256 asymmetric EC keys', () {
      final keyPair = service.generateAsymmetricKeyPair(
        algorithm: ToolboxCryptoAsymmetricAlgorithm.ecP256,
      );
      final malformedPrivateKey = _jsonMapFromText(keyPair.privateKeyText);
      final publicMap = malformedPrivateKey['public']! as Map<String, Object?>;
      final privateMap =
          malformedPrivateKey['private']! as Map<String, Object?>;
      publicMap['curve'] = 'secp256k1';
      privateMap['curve'] = 'secp256k1';

      expect(
        () => service.signBytes(
          bytes: Uint8List.fromList(utf8.encode('wrong curve')),
          privateKeyText: jsonEncode(malformedPrivateKey),
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );
    });

    test('keeps weak algorithms decrypt-only for new envelopes', () {
      final plain = Uint8List.fromList(utf8.encode('legacy blocked'));
      for (final algorithm in <ToolboxCryptoAlgorithm>[
        ToolboxCryptoAlgorithm.sha256Stream,
        ToolboxCryptoAlgorithm.rc4Legacy,
      ]) {
        expect(
          () => service.encryptBytes(
            plainBytes: plain,
            algorithm: algorithm,
            strength: ToolboxCryptoStrength.standard,
            passphrase: 'weak-key',
          ),
          throwsA(isA<ToolboxCryptoException>()),
        );
      }

      expect(
        () => service.encryptBytes(
          plainBytes: plain,
          algorithm: ToolboxCryptoAlgorithm.customCascade,
          strength: ToolboxCryptoStrength.standard,
          passphrase: 'weak-key',
          cascade: const <ToolboxCryptoCascadeCipher>[
            ToolboxCryptoCascadeCipher.aes,
            ToolboxCryptoCascadeCipher.sha256Stream,
          ],
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );
    });
  });
}

void _expectOpaqueV5Envelope(
  Uint8List bytes, {
  required Iterable<String> hiddenText,
}) {
  expect(utf8.decode(bytes.sublist(0, 8)), 'VSCENC5!');
  expect(bytes[8], ToolboxCryptoService.currentVersion);
  expect(() => jsonDecode(utf8.decode(bytes)), throwsA(anything));
  final lossyText = utf8.decode(bytes, allowMalformed: true);
  for (final text in hiddenText) {
    expect(lossyText, isNot(contains(text)));
  }
}

Uint8List _copyWithUint32(Uint8List bytes, int offset, int value) {
  final output = Uint8List.fromList(bytes);
  output[offset] = (value >> 24) & 255;
  output[offset + 1] = (value >> 16) & 255;
  output[offset + 2] = (value >> 8) & 255;
  output[offset + 3] = value & 255;
  return output;
}

int _opaqueMetadataLengthOffset(Uint8List bytes) {
  var offset = 8 + 1 + 12;
  final saltLength = bytes[offset];
  offset += 1 + saltLength;
  final nonceLength = bytes[offset];
  offset += 1 + nonceLength;
  return offset;
}

Map<String, Object?> _jsonMapFromText(String text) {
  final decoded = jsonDecode(text) as Map<String, dynamic>;
  return decoded.cast<String, Object?>();
}

String _bigIntToBase64(BigInt value) {
  if (value == BigInt.zero) {
    return base64Encode(<int>[0]);
  }
  final bytes = <int>[];
  var active = value;
  while (active > BigInt.zero) {
    bytes.add((active & BigInt.from(0xff)).toInt());
    active = active >> 8;
  }
  return base64Encode(bytes.reversed.toList(growable: false));
}
