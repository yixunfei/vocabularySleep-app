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

    test('embeds and reveals text in WAV/PCM audio carriers', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: _makeWavCarrier(samples: 24000),
        text: 'audio carrier secret',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'audio-key',
        sourceExtension: 'wav',
      );

      expect(embedded.outputExtension, 'wav');
      expect(embedded.capacityBytes, greaterThan(embedded.payloadBytes));
      expect(embedded.outputBytes, embedded.sourceBytes);
      expect(embedded.bytes.sublist(0, 4), ascii.encode('RIFF'));

      final revealed = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: embedded.bytes,
        passphrase: 'audio-key',
      );
      expect(revealed.text, 'audio carrier secret');
      expect(revealed.encryption, ToolboxCryptoAlgorithm.aesGcm);
    });

    test('embeds and reveals text in MP4 container free boxes', () {
      final carrier = _makeMp4Carrier();
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.video,
        carrierBytes: carrier,
        text: 'video carrier secret',
        encryption: ToolboxCryptoAlgorithm.chacha20Poly1305,
        passphrase: 'video-key',
        sourceExtension: 'mp4',
      );

      expect(embedded.outputExtension, 'mp4');
      expect(embedded.outputBytes, greaterThan(embedded.sourceBytes));
      expect(embedded.bytes.sublist(4, 8), ascii.encode('ftyp'));

      final revealed = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.video,
        carrierBytes: embedded.bytes,
        passphrase: 'video-key',
      );
      expect(revealed.text, 'video carrier secret');
      expect(revealed.encryption, ToolboxCryptoAlgorithm.chacha20Poly1305);
    });

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

    test('reports image capacity before writing payload', () {
      final check = service.checkTextWriteCapacity(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(width: 20, height: 20),
        text: 'capacity' * 200,
        dualLayerEnabled: false,
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'capacity-key',
      );

      expect(check.fits, isFalse);
      expect(check.requiredBytes, greaterThan(check.capacityBytes));
      expect(check.minimumPixels, greaterThan(20 * 20));
    });

    test('embeds dual text layers and reveals only matching layer', () {
      final cases = <({ToolboxSteganographyMediaKind kind, Uint8List carrier})>[
        (
          kind: ToolboxSteganographyMediaKind.image,
          carrier: _makePngCarrier(width: 180, height: 180),
        ),
        (
          kind: ToolboxSteganographyMediaKind.audio,
          carrier: _makeWavCarrier(samples: 52000),
        ),
        (kind: ToolboxSteganographyMediaKind.video, carrier: _makeMp4Carrier()),
      ];

      for (final item in cases) {
        final embedded = service.embedDualText(
          mediaKind: item.kind,
          carrierBytes: item.carrier,
          coverText: 'cover note',
          hiddenText: 'real note',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          coverPassphrase: 'cover-key',
          hiddenPassphrase: 'hidden-key',
          sourceExtension: item.kind == ToolboxSteganographyMediaKind.image
              ? 'png'
              : item.kind == ToolboxSteganographyMediaKind.audio
              ? 'wav'
              : 'mp4',
        );

        final cover = service.revealText(
          mediaKind: item.kind,
          carrierBytes: embedded.bytes,
          passphrase: 'cover-key',
        );
        final hidden = service.revealText(
          mediaKind: item.kind,
          carrierBytes: embedded.bytes,
          passphrase: 'hidden-key',
        );

        expect(cover.text, 'cover note');
        expect(hidden.text, 'real note');
        expect(
          () => service.embedText(
            mediaKind: item.kind,
            carrierBytes: embedded.bytes,
            text: 'third layer',
            encryption: ToolboxCryptoAlgorithm.aesGcm,
            passphrase: 'third-key',
          ),
          throwsA(isA<ToolboxSteganographyException>()),
        );
      }
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
        (
          kind: ToolboxSteganographyMediaKind.audio,
          carrier: _makeWavCarrier(samples: 26000),
        ),
        (kind: ToolboxSteganographyMediaKind.video, carrier: _makeMp4Carrier()),
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

    test('embeds dual encrypted files and reveals matching file layer', () {
      final coverFile = Uint8List.fromList(
        List<int>.generate(32, (index) => (index * 7) & 255),
      );
      final hiddenFile = Uint8List.fromList(
        List<int>.generate(40, (index) => (index * 19) & 255),
      );
      final cases = <({ToolboxSteganographyMediaKind kind, Uint8List carrier})>[
        (
          kind: ToolboxSteganographyMediaKind.image,
          carrier: _makePngCarrier(width: 220, height: 220),
        ),
        (
          kind: ToolboxSteganographyMediaKind.audio,
          carrier: _makeWavCarrier(samples: 72000),
        ),
        (kind: ToolboxSteganographyMediaKind.video, carrier: _makeMp4Carrier()),
      ];

      for (final item in cases) {
        final embedded = service.embedDualFile(
          mediaKind: item.kind,
          carrierBytes: item.carrier,
          coverFileBytes: coverFile,
          hiddenFileBytes: hiddenFile,
          coverFileName: 'cover.bin',
          hiddenFileName: 'hidden.bin',
          encryption: ToolboxCryptoAlgorithm.aesTwofishGcm,
          coverPassphrase: 'cover-file-key',
          hiddenPassphrase: 'hidden-file-key',
          sourceExtension: item.kind == ToolboxSteganographyMediaKind.image
              ? 'png'
              : item.kind == ToolboxSteganographyMediaKind.audio
              ? 'wav'
              : 'mp4',
        );

        final cover = service.revealFile(
          mediaKind: item.kind,
          carrierBytes: embedded.bytes,
          passphrase: 'cover-file-key',
        );
        final hidden = service.revealFile(
          mediaKind: item.kind,
          carrierBytes: embedded.bytes,
          passphrase: 'hidden-file-key',
        );

        expect(cover.bytes, coverFile);
        expect(cover.fileName, 'cover.bin');
        expect(hidden.bytes, hiddenFile);
        expect(hidden.fileName, 'hidden.bin');
        expect(
          () => service.revealFile(
            mediaKind: item.kind,
            carrierBytes: embedded.bytes,
            passphrase: 'cover-file-key',
            keyFileBytes: Uint8List.fromList(<int>[1, 2, 3]),
          ),
          throwsA(isA<ToolboxSteganographyException>()),
        );
      }
    });

    test('cleans WAV payload after successful reveal limit is consumed', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: _makeWavCarrier(samples: 22000),
        text: 'single audio reveal',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'audio-once',
        maxSuccessfulReveals: 1,
      );

      expect(
        service
            .revealText(
              mediaKind: ToolboxSteganographyMediaKind.audio,
              carrierBytes: embedded.bytes,
              passphrase: 'audio-once',
            )
            .text,
        'single audio reveal',
      );
      final consumed = service.applySuccessfulRevealProtection(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: embedded.bytes,
        passphrase: 'audio-once',
      );
      expect(consumed.changed, isTrue);
      expect(consumed.removed, isTrue);
      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.audio,
          carrierBytes: consumed.bytes,
          passphrase: 'audio-once',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('rejects writing into occupied MP4 carriers', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.video,
        carrierBytes: _makeMp4Carrier(),
        text: 'first video layer',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'video-first',
      );

      expect(
        () => service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.video,
          carrierBytes: embedded.bytes,
          text: 'second video layer',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          passphrase: 'video-second',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('reports WAV capacity before writing payload', () {
      final check = service.checkTextWriteCapacity(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: _makeWavCarrier(samples: 1200),
        text: 'capacity' * 100,
        dualLayerEnabled: false,
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'audio-capacity',
      );

      expect(check.mediaKind, ToolboxSteganographyMediaKind.audio);
      expect(check.fits, isFalse);
      expect(check.minimumCarrierBytes, greaterThan(0));
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

Uint8List _makeWavCarrier({int samples = 18000}) {
  final dataBytes = samples * 2;
  final totalBytes = 44 + dataBytes;
  final bytes = Uint8List(totalBytes);
  bytes.setRange(0, 4, ascii.encode('RIFF'));
  _writeUint32Little(bytes, 4, totalBytes - 8);
  bytes.setRange(8, 12, ascii.encode('WAVE'));
  bytes.setRange(12, 16, ascii.encode('fmt '));
  _writeUint32Little(bytes, 16, 16);
  _writeUint16Little(bytes, 20, 1);
  _writeUint16Little(bytes, 22, 1);
  _writeUint32Little(bytes, 24, 44100);
  _writeUint32Little(bytes, 28, 44100 * 2);
  _writeUint16Little(bytes, 32, 2);
  _writeUint16Little(bytes, 34, 16);
  bytes.setRange(36, 40, ascii.encode('data'));
  _writeUint32Little(bytes, 40, dataBytes);
  for (var index = 0; index < samples; index += 1) {
    final value = ((mathSin(index / 12) * 12000).round()) & 0xffff;
    final offset = 44 + (index * 2);
    bytes[offset] = value & 255;
    bytes[offset + 1] = (value >> 8) & 255;
  }
  return bytes;
}

Uint8List _makeMp4Carrier() {
  final ftypPayload = <int>[
    ...ascii.encode('isom'),
    0,
    0,
    2,
    0,
    ...ascii.encode('isom'),
    ...ascii.encode('mp42'),
  ];
  final mdatPayload = List<int>.generate(2048, (index) => (index * 31) & 255);
  return Uint8List.fromList(<int>[
    ..._mp4Box('ftyp', ftypPayload),
    ..._mp4Box('mdat', mdatPayload),
  ]);
}

List<int> _mp4Box(String type, List<int> payload) {
  return <int>[
    ..._uint32Bytes(8 + payload.length),
    ...ascii.encode(type),
    ...payload,
  ];
}

List<int> _uint32Bytes(int value) {
  return <int>[
    (value >> 24) & 255,
    (value >> 16) & 255,
    (value >> 8) & 255,
    value & 255,
  ];
}

void _writeUint16Little(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = (value >> 8) & 255;
}

void _writeUint32Little(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 255;
  bytes[offset + 1] = (value >> 8) & 255;
  bytes[offset + 2] = (value >> 16) & 255;
  bytes[offset + 3] = (value >> 24) & 255;
}

double mathSin(double value) {
  // Small deterministic sine approximation is enough for a non-silent carrier.
  var x = value % 6.283185307179586;
  if (x > 3.141592653589793) {
    x -= 6.283185307179586;
  }
  return x - ((x * x * x) / 6) + ((x * x * x * x * x) / 120);
}
