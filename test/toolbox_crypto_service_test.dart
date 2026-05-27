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
      );

      expect(encrypted.envelopeBytes.length, greaterThan(plain.length));
      expect(encrypted.cipherBytes.length, greaterThan(plain.length));
      expect(encrypted.cipherPreview, isNotEmpty);
      final envelope = jsonDecode(utf8.decode(encrypted.envelopeBytes));
      expect(envelope['version'], 3);
      expect(envelope['kdf']['n'], 1 << 16);
      expect(envelope['padding']['mode'], 'random-length-v1');

      final decrypted = service.decryptBytes(
        envelopeBytes: encrypted.envelopeBytes,
        passphrase: 'moon-key',
      );
      expect(utf8.decode(decrypted.plainBytes), 'secret text 你好');
      expect(decrypted.algorithm, ToolboxCryptoAlgorithm.aesGcm);
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

    test('encrypts and decrypts bytes with ChaCha20-Poly1305', () {
      final plain = Uint8List.fromList(utf8.encode('chacha payload'));
      final encrypted = service.encryptBytes(
        plainBytes: plain,
        algorithm: ToolboxCryptoAlgorithm.chacha20Poly1305,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'chacha-key',
      );

      final envelope = jsonDecode(utf8.decode(encrypted.envelopeBytes));
      expect(envelope['algorithm'], 'chacha20_poly1305');
      expect((envelope['stages'] as List<Object?>).single, isA<Map>());

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

      final envelope = jsonDecode(utf8.decode(encrypted.envelopeBytes));
      expect(envelope['keyBits'], 512);
      expect(envelope['macAlgorithm'], ToolboxCryptoMacAlgorithm.whirlpool.id);
      expect((envelope['stages'] as List<Object?>).length, 3);

      final decrypted = service.decryptBytes(
        envelopeBytes: encrypted.envelopeBytes,
        passphrase: 'custom-key',
      );
      expect(decrypted.plainBytes, plain);
      expect(decrypted.algorithm, ToolboxCryptoAlgorithm.customCascade);
    });

    test('supports weak, RSA, and ECDSA signature envelope verification', () {
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
        final envelope = jsonDecode(utf8.decode(encrypted.envelopeBytes));
        expect(envelope['signatureMode'], mode.id);
        if (mode == ToolboxCryptoSignatureMode.weakSha256) {
          expect(envelope['signaturePublic'], <String, Object?>{
            'mode': ToolboxCryptoSignatureMode.weakSha256.id,
            'public': false,
          });
        }
        final decrypted = service.decryptBytes(
          envelopeBytes: encrypted.envelopeBytes,
          passphrase: 'sign-key',
        );
        expect(utf8.decode(decrypted.plainBytes), 'signed payload');

        if (mode == ToolboxCryptoSignatureMode.weakSha256) {
          final tamperedEnvelope = Map<String, Object?>.from(envelope as Map);
          final signature = Map<String, Object?>.from(
            tamperedEnvelope['signature']! as Map,
          );
          final tag = base64Decode(signature['value']! as String);
          tag[0] ^= 0x01;
          signature['value'] = base64Encode(tag);
          tamperedEnvelope['signature'] = signature;
          expect(
            () => service.decryptBytes(
              envelopeBytes: Uint8List.fromList(
                utf8.encode(jsonEncode(tamperedEnvelope)),
              ),
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
