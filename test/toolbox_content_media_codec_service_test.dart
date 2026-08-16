import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_content_media_codec_service.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_crypto_service.dart';

void main() {
  group('ToolboxContentMediaCodecService', () {
    final service = ToolboxContentMediaCodecService();

    test('encrypts text to PNG color blocks and restores it', () {
      final plain = Uint8List.fromList(utf8.encode('secret media text'));
      final encoded = service.encryptToPngImage(
        plainBytes: plain,
        algorithm: ToolboxCryptoAlgorithm.aesGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'media-passphrase',
        fileName: 'note.txt',
        mediaType: 'text/plain',
      );

      expect(encoded.bytes.length, greaterThan(encoded.envelopeBytes.length));
      expect(encoded.fileName.endsWith('.png'), isTrue);
      expect(encoded.imageWidth, isNotNull);
      expect(encoded.imageHeight, isNotNull);
      expect(encoded.envelopeSha256.length, 64);

      final decoded = service.decryptFromPngImage(
        imageBytes: encoded.bytes,
        passphrase: 'media-passphrase',
      );
      expect(decoded.format, ToolboxContentMediaFormat.imagePng);
      expect(decoded.fileName, 'note.txt');
      expect(decoded.mediaType, 'text/plain');
      expect(decoded.plainBytes, plain);
      expect(decoded.envelopeSha256, encoded.envelopeSha256);
    });

    test('honors minimum PNG size and restores naturalized payload', () {
      final plain = Uint8List.fromList(utf8.encode('natural media text'));
      final encoded = service.encryptToPngImage(
        plainBytes: plain,
        algorithm: ToolboxCryptoAlgorithm.chacha20Poly1305,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'natural-passphrase',
        minimumImageWidth: 192,
        minimumImageHeight: 128,
        fillMode: ToolboxContentMediaImageFillMode.paperGrain,
      );

      expect(encoded.imageWidth, greaterThanOrEqualTo(192));
      expect(encoded.imageHeight, greaterThanOrEqualTo(128));

      final decoded = service.decryptFromPngImage(
        imageBytes: encoded.bytes,
        passphrase: 'natural-passphrase',
      );
      expect(decoded.plainBytes, plain);
      expect(decoded.envelopeSha256, encoded.envelopeSha256);
    });

    test('simulates PNG transfer damage without touching hidden payload', () {
      final plain = Uint8List.fromList(utf8.encode('damaged but restorable'));
      final encoded = service.encryptToPngImage(
        plainBytes: plain,
        algorithm: ToolboxCryptoAlgorithm.aesGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'damage-passphrase',
        minimumImageWidth: 160,
        minimumImageHeight: 160,
      );
      final damaged = service.simulatePngTransferDamage(
        imageBytes: encoded.bytes,
        level: ToolboxContentMediaDamageLevel.medium,
      );

      expect(damaged, isNot(encoded.bytes));
      final decoded = service.decryptFromPngImage(
        imageBytes: damaged,
        passphrase: 'damage-passphrase',
      );
      expect(decoded.plainBytes, plain);
      expect(decoded.envelopeSha256, encoded.envelopeSha256);
    });

    test('encrypts bytes to WAV spectrum samples and restores them', () {
      final plain = Uint8List.fromList(
        List<int>.generate(1024, (index) => (index * 29) & 255),
      );
      final keyFile = Uint8List.fromList(<int>[8, 6, 7, 5, 3, 0, 9]);
      final encoded = service.encryptToWavAudio(
        plainBytes: plain,
        algorithm: ToolboxCryptoAlgorithm.serpentGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'media-passphrase',
        keyFileBytes: keyFile,
        fileName: 'payload.bin',
      );

      expect(ascii.decode(encoded.bytes.sublist(0, 4)), 'RIFF');
      expect(ascii.decode(encoded.bytes.sublist(8, 12)), 'WAVE');
      expect(encoded.fileName.endsWith('.wav'), isTrue);
      expect(encoded.duration, isNotNull);

      final decoded = service.decryptFromWavAudio(
        wavBytes: encoded.bytes,
        passphrase: 'media-passphrase',
        keyFileBytes: keyFile,
      );
      expect(decoded.format, ToolboxContentMediaFormat.audioWav);
      expect(decoded.fileName, 'payload.bin');
      expect(decoded.algorithm, ToolboxCryptoAlgorithm.serpentGcm);
      expect(decoded.plainBytes, plain);
    });

    test('requires matching key file for generated media', () {
      final encoded = service.encryptToPngImage(
        plainBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        algorithm: ToolboxCryptoAlgorithm.twofishGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'keyed-media',
        keyFileBytes: Uint8List.fromList(<int>[1, 1, 2, 3]),
      );

      expect(
        () => service.decryptFromPngImage(
          imageBytes: encoded.bytes,
          passphrase: 'keyed-media',
          keyFileBytes: Uint8List.fromList(<int>[3, 2, 1, 1]),
        ),
        throwsA(isA<ToolboxCryptoException>()),
      );
    });

    test('rejects tampered PNG payload before decrypting envelope', () {
      final encoded = service.encryptToPngImage(
        plainBytes: Uint8List.fromList(utf8.encode('tamper me')),
        algorithm: ToolboxCryptoAlgorithm.aesGcm,
        strength: ToolboxCryptoStrength.standard,
        passphrase: 'tamper-media',
      );
      final tampered = Uint8List.fromList(encoded.bytes);
      tampered[tampered.length - 16] ^= 0x01;

      expect(
        () => service.decryptFromPngImage(
          imageBytes: tampered,
          passphrase: 'tamper-media',
        ),
        throwsA(isA<ToolboxContentMediaException>()),
      );
    });

    test('rejects unsupported media bytes', () {
      expect(
        () => service.decryptFromMediaBytes(
          mediaBytes: Uint8List.fromList(utf8.encode('not media')),
          passphrase: 'x',
        ),
        throwsA(isA<ToolboxContentMediaException>()),
      );
    });

    test('tracks attempt limits and random-overwrites sensitive bytes', () {
      const policy = ToolboxContentMediaAttemptPolicy(
        maxDecrypts: 2,
        maxErrors: 3,
        successfulDecrypts: 1,
        failedAttempts: 2,
      );

      expect(policy.blocksBeforeDecrypt, isFalse);
      expect(policy.clearsAfterDecryptSuccess, isTrue);
      expect(policy.clearsAfterDecryptFailure, isTrue);

      final sensitive = Uint8List.fromList(
        List<int>.generate(64, (index) => index),
      );
      final before = Uint8List.fromList(sensitive);
      ToolboxContentMediaSecureWiper.randomOverwrite(sensitive, passes: 2);
      expect(sensitive, isNot(before));
    });

    test('validates network image URLs and PNG response hints', () {
      final uri = ToolboxContentMediaCodecService.normalizeNetworkImageUri(
        'https://uguu.se/example.png',
      );
      expect(uri.scheme, 'https');
      expect(
        ToolboxContentMediaCodecService.networkImageFileName(uri),
        'example.png',
      );
      expect(
        ToolboxContentMediaCodecService.networkImageFileName(
          Uri.parse('https://example.com/download/temporary'),
        ),
        'temporary.png',
      );
      expect(
        ToolboxContentMediaCodecService.networkImageFileName(
          Uri.parse('https://example.com/download/%2E%2E%5Csecret?.png'),
        ),
        '.._secret.png',
      );
      expect(
        ToolboxContentMediaCodecService.allowsNetworkImageContentType(
          'image/png; charset=binary',
        ),
        isTrue,
      );
      expect(
        ToolboxContentMediaCodecService.allowsNetworkImageContentType(
          'image/jpeg',
        ),
        isFalse,
      );
      expect(
        ToolboxContentMediaCodecService.hasPngSignature(
          Uint8List.fromList(<int>[137, 80, 78, 71, 13, 10, 26, 10, 0]),
        ),
        isTrue,
      );

      expect(
        () => ToolboxContentMediaCodecService.normalizeNetworkImageUri(
          'http://example.com/payload.png',
        ),
        throwsA(isA<ToolboxContentMediaException>()),
      );
      expect(
        () => ToolboxContentMediaCodecService.normalizeNetworkImageUri(
          'https://127.0.0.1/payload.png',
        ),
        throwsA(isA<ToolboxContentMediaException>()),
      );
      expect(
        () => ToolboxContentMediaCodecService.normalizeNetworkImageUri(
          'https://192.168.1.2/payload.png',
        ),
        throwsA(isA<ToolboxContentMediaException>()),
      );
      expect(
        ToolboxContentMediaCodecService.isBlockedNetworkImageHost(
          'fcdn.example.com',
        ),
        isFalse,
      );
    });
  });
}
