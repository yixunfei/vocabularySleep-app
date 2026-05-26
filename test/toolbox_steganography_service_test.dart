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
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]),
        text: 'audio secret',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'right',
        sourceExtension: 'wav',
      );

      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.audio,
          carrierBytes: embedded.bytes,
          passphrase: 'wrong',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('embeds and reveals text in audio tail payload', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: Uint8List.fromList(
          List<int>.generate(128, (index) => index & 255),
        ),
        text: 'tail audio',
        encryption: ToolboxCryptoAlgorithm.aesTwofishGcm,
        passphrase: 'sound-key',
        sourceExtension: 'mp3',
      );

      expect(embedded.outputExtension, 'mp3');
      expect(embedded.bytes.length, greaterThan(128));

      final revealed = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: embedded.bytes,
        passphrase: 'sound-key',
      );
      expect(revealed.text, 'tail audio');
      expect(revealed.encryption, ToolboxCryptoAlgorithm.aesTwofishGcm);
    });

    test('uses optional key file for hidden payloads', () {
      final keyFile = Uint8List.fromList(<int>[8, 6, 7, 5, 3, 0, 9]);
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]),
        text: 'key file secret',
        encryption: ToolboxCryptoAlgorithm.twofishGcm,
        passphrase: 'right',
        keyFileBytes: keyFile,
        sourceExtension: 'wav',
      );

      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.audio,
          carrierBytes: embedded.bytes,
          passphrase: 'right',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );

      final revealed = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: embedded.bytes,
        passphrase: 'right',
        keyFileBytes: keyFile,
      );
      expect(revealed.text, 'key file secret');
      expect(revealed.encryption, ToolboxCryptoAlgorithm.twofishGcm);
    });

    test(
      'embeds and reveals text in video tail payload without encryption',
      () {
        final embedded = service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.video,
          carrierBytes: Uint8List.fromList(
            List<int>.generate(256, (index) => (index * 7) & 255),
          ),
          text: 'plain video secret',
          encryption: ToolboxCryptoAlgorithm.none,
          passphrase: '',
          sourceExtension: 'mp4',
        );

        final revealed = service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.video,
          carrierBytes: embedded.bytes,
          passphrase: '',
        );
        expect(revealed.text, 'plain video secret');
        expect(revealed.encryption, ToolboxCryptoAlgorithm.none);
      },
    );

    test(
      'embeds and reveals encrypted files in image audio and video carriers',
      () {
        final secretFile = Uint8List.fromList(
          List<int>.generate(48, (index) => (index * 13) & 255),
        );
        final cases =
            <({ToolboxSteganographyMediaKind kind, Uint8List carrier})>[
              (
                kind: ToolboxSteganographyMediaKind.image,
                carrier: _makePngCarrier(width: 160, height: 160),
              ),
              (
                kind: ToolboxSteganographyMediaKind.audio,
                carrier: Uint8List.fromList(
                  List<int>.generate(128, (index) => index & 255),
                ),
              ),
              (
                kind: ToolboxSteganographyMediaKind.video,
                carrier: Uint8List.fromList(
                  List<int>.generate(256, (index) => (index * 7) & 255),
                ),
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
      },
    );
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
