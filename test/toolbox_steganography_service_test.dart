import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vocabulary_sleep_app/src/services/toolbox_crypto_service.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_steganography_service.dart';

void main() {
  group('ToolboxSteganographyService', () {
    final service = ToolboxSteganographyService();

    test('embeds and reveals text in PNG image LSB payload', () {
      final carrier = _makePngCarrier();
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: carrier,
        text: 'sleepy secret \u4f60\u597d',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'moon-key',
      );

      expect(embedded.outputExtension, 'png');
      expect(embedded.payloadBytes, greaterThan(0));
      expect(embedded.capacityBytes, isNotNull);

      final revealed = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'moon-key',
      );
      expect(revealed.text, 'sleepy secret \u4f60\u597d');
      expect(revealed.encryption, ToolboxCryptoAlgorithm.aesGcm);
    });

    test('rejects wrong passphrase', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(),
        text: 'audio secret',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'right',
        sourceExtension: 'png',
      );

      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: embedded.bytes,
          passphrase: 'wrong',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test(
      'rejects new audio and video writes until real stego backends exist',
      () {
        for (final kind in <ToolboxSteganographyMediaKind>[
          ToolboxSteganographyMediaKind.audio,
          ToolboxSteganographyMediaKind.video,
        ]) {
          expect(
            () => service.embedText(
              mediaKind: kind,
              carrierBytes: Uint8List.fromList(
                List<int>.generate(128, (index) => index & 255),
              ),
              text: 'media secret',
              encryption: ToolboxCryptoAlgorithm.aesGcm,
              passphrase: 'media-key',
              sourceExtension: kind == ToolboxSteganographyMediaKind.audio
                  ? 'wav'
                  : 'mp4',
            ),
            throwsA(isA<ToolboxSteganographyException>()),
          );
        }
      },
    );

    test('normalizes extensions with shared service rule', () {
      expect(ToolboxSteganographyService.maxExtensionLength, 12);
      expect(
        ToolboxSteganographyService.cleanExtension('.APPINSTALLER'),
        'appinstaller',
      );
      expect(
        ToolboxSteganographyService.cleanExtension('.verylongextension'),
        isNull,
      );
      expect(ToolboxSteganographyService.cleanExtension('.---'), isNull);
      expect(ToolboxSteganographyService.cleanExtension(null), isNull);
    });

    test('uses optional key file for hidden payloads', () {
      final keyFile = Uint8List.fromList(<int>[8, 6, 7, 5, 3, 0, 9]);
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(),
        text: 'key file secret',
        encryption: ToolboxCryptoAlgorithm.twofishGcm,
        passphrase: 'right',
        keyFileBytes: keyFile,
        sourceExtension: 'png',
      );

      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: embedded.bytes,
          passphrase: 'right',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );

      final revealed = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'right',
        keyFileBytes: keyFile,
      );
      expect(revealed.text, 'key file secret');
      expect(revealed.encryption, ToolboxCryptoAlgorithm.twofishGcm);
    });

    test('rejects writing into an already occupied carrier', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(),
        text: 'first layer',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'first-key',
      );

      expect(
        () => service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: embedded.bytes,
          text: 'second layer',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          passphrase: 'second-key',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('embeds dual text layers and reveals only matching layer', () {
      final embedded = service.embedDualText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(width: 180, height: 180),
        coverText: 'cover note',
        hiddenText: 'real note',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        coverPassphrase: 'cover-key',
        hiddenPassphrase: 'hidden-key',
      );

      final cover = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'cover-key',
      );
      final hidden = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'hidden-key',
      );

      expect(cover.text, 'cover note');
      expect(hidden.text, 'real note');
      expect(
        () => service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: embedded.bytes,
          text: 'third layer',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          passphrase: 'third-key',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('consumes successful reveal limits and then clears payload', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(),
        text: 'read twice',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'success-key',
        maxSuccessfulReveals: 2,
      );

      expect(
        service
            .revealText(
              mediaKind: ToolboxSteganographyMediaKind.image,
              carrierBytes: embedded.bytes,
              passphrase: 'success-key',
            )
            .text,
        'read twice',
      );
      final firstConsume = service.applySuccessfulRevealProtection(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'success-key',
      );
      expect(firstConsume.changed, isTrue);
      expect(firstConsume.removed, isFalse);
      expect(firstConsume.remainingSuccessfulReveals, 1);

      expect(
        service
            .revealText(
              mediaKind: ToolboxSteganographyMediaKind.image,
              carrierBytes: firstConsume.bytes,
              passphrase: 'success-key',
            )
            .text,
        'read twice',
      );
      final secondConsume = service.applySuccessfulRevealProtection(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: firstConsume.bytes,
        passphrase: 'success-key',
      );
      expect(secondConsume.changed, isTrue);
      expect(secondConsume.removed, isTrue);
      expect(secondConsume.remainingSuccessfulReveals, 0);
      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: secondConsume.bytes,
          passphrase: 'success-key',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('embeds and reveals image text without encryption', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(),
        text: 'plain image secret',
        encryption: ToolboxCryptoAlgorithm.none,
        passphrase: '',
        sourceExtension: 'png',
      );

      final revealed = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: '',
      );
      expect(revealed.text, 'plain image secret');
      expect(revealed.encryption, ToolboxCryptoAlgorithm.none);
    });

    test('stores reveal protection policy and strips hidden image payload', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(),
        text: 'protected secret',
        encryption: ToolboxCryptoAlgorithm.none,
        passphrase: 'locator-key',
        maxErrorAttempts: 3,
        locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha512,
        locatorStrength: ToolboxSteganographyLocatorStrength.standard,
      );

      final policy = service.inspectProtectionPolicy(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'wrong-key',
        locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha512,
        locatorStrength: ToolboxSteganographyLocatorStrength.standard,
      );
      expect(policy.maxErrorAttempts, 3);
      expect(policy.hasTamperCheck, isTrue);
      expect(
        _readSequentialLsbBytes(embedded.bytes, 6),
        isNot(ascii.encode('VSSGP2')),
      );

      final stripped = service.stripHiddenData(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'wrong-key',
        locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha512,
        locatorStrength: ToolboxSteganographyLocatorStrength.standard,
      );
      expect(stripped.removed, isTrue);
      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: stripped.bytes,
          passphrase: 'locator-key',
          locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha512,
          locatorStrength: ToolboxSteganographyLocatorStrength.standard,
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('embeds and reveals encrypted files in image carriers', () {
      final secretFile = Uint8List.fromList(
        List<int>.generate(48, (index) => (index * 13) & 255),
      );
      final cases = <({ToolboxSteganographyMediaKind kind, Uint8List carrier})>[
        (
          kind: ToolboxSteganographyMediaKind.image,
          carrier: _makePngCarrier(width: 160, height: 160),
        ),
      ];

      for (final item in cases) {
        final embedded = service.embedFile(
          mediaKind: item.kind,
          carrierBytes: item.carrier,
          fileBytes: secretFile,
          fileName: 'payload.bin',
          encryption: ToolboxCryptoAlgorithm.customCascade,
          passphrase: 'file-key',
          sourceExtension: item.kind == ToolboxSteganographyMediaKind.image
              ? 'png'
              : item.kind == ToolboxSteganographyMediaKind.audio
              ? 'wav'
              : 'mp4',
          cascade: const <ToolboxCryptoCascadeCipher>[
            ToolboxCryptoCascadeCipher.aes,
            ToolboxCryptoCascadeCipher.twofish,
          ],
          keyBits: ToolboxCryptoKeyBits.bits512,
          macAlgorithm: ToolboxCryptoMacAlgorithm.whirlpool,
        );
        final revealed = service.revealFile(
          mediaKind: item.kind,
          carrierBytes: embedded.bytes,
          passphrase: 'file-key',
        );

        expect(revealed.bytes, secretFile);
        expect(revealed.fileName, 'payload.bin');
        expect(revealed.encryption, ToolboxCryptoAlgorithm.customCascade);
      }
    });

    test('uses hardened locator KDF rounds for new payloads', () {
      expect(ToolboxSteganographyLocatorStrength.standard.rounds, 4096);
      expect(ToolboxSteganographyLocatorStrength.strong.rounds, 12000);
      expect(ToolboxSteganographyLocatorStrength.extreme.rounds, 24000);
    });
  });
}

Uint8List _makePngCarrier({int width = 96, int height = 96}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      image.setPixelRgb(x, y, (x * 3) & 255, (y * 5) & 255, 180);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

List<int> _readSequentialLsbBytes(Uint8List pngBytes, int byteCount) {
  final image = img.decodeImage(pngBytes)!;
  final output = Uint8List(byteCount);
  var bitIndex = 0;
  for (var y = 0; y < image.height && bitIndex < byteCount * 8; y += 1) {
    for (var x = 0; x < image.width && bitIndex < byteCount * 8; x += 1) {
      final pixel = image.getPixel(x, y);
      for (final channel in <int>[
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
      ]) {
        if (bitIndex >= byteCount * 8) {
          return output;
        }
        output[bitIndex >> 3] |= (channel & 1) << (7 - (bitIndex & 7));
        bitIndex += 1;
      }
    }
  }
  return output;
}
