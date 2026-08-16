import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
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
      'default deniable image carriers can be overwritten by another key',
      () {
        final embedded = service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: _makePngCarrier(),
          text: 'existing payload',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          passphrase: 'first-key',
        );

        expect(
          _readPolicyLsbBytes(embedded.bytes, 6),
          isNot(ascii.encode('VSSGO2')),
        );

        final replacement = service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: embedded.bytes,
          text: 'replacement payload',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          passphrase: 'attacker-key',
        );

        expect(
          service
              .revealText(
                mediaKind: ToolboxSteganographyMediaKind.image,
                carrierBytes: replacement.bytes,
                passphrase: 'attacker-key',
              )
              .text,
          'replacement payload',
        );
        expect(
          () => service.revealText(
            mediaKind: ToolboxSteganographyMediaKind.image,
            carrierBytes: replacement.bytes,
            passphrase: 'first-key',
          ),
          throwsA(isA<ToolboxSteganographyException>()),
        );
      },
    );

    test(
      'blocks accidental overwrite when current credential can read payload',
      () {
        final embedded = service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: _makePngCarrier(),
          text: 'existing payload',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          passphrase: 'same-key',
        );

        expect(
          () => service.embedText(
            mediaKind: ToolboxSteganographyMediaKind.image,
            carrierBytes: embedded.bytes,
            text: 'replacement payload',
            encryption: ToolboxCryptoAlgorithm.aesGcm,
            passphrase: 'same-key',
          ),
          throwsA(
            isA<ToolboxSteganographyException>().having(
              (error) => error.message,
              'message',
              contains('payload readable with the current credential'),
            ),
          ),
        );

        final replacement = service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: embedded.bytes,
          text: 'replacement payload',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          passphrase: 'same-key',
          allowCarrierOverwrite: true,
        );
        expect(
          service
              .revealText(
                mediaKind: ToolboxSteganographyMediaKind.image,
                carrierBytes: replacement.bytes,
                passphrase: 'same-key',
              )
              .text,
          'replacement payload',
        );
      },
    );

    test('guarded occupancy marker is visible but not trusted', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(),
        text: 'guarded payload',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'guard-key',
        carrierProtectionMode:
            ToolboxSteganographyCarrierProtectionMode.guarded,
      );

      expect(_readPolicyLsbBytes(embedded.bytes, 6), ascii.encode('VSSGO2'));

      final replacement = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        text: 'blind replacement',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'other-key',
      );
      expect(
        service
            .revealText(
              mediaKind: ToolboxSteganographyMediaKind.image,
              carrierBytes: replacement.bytes,
              passphrase: 'other-key',
            )
            .text,
        'blind replacement',
      );
      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: replacement.bytes,
          passphrase: 'guard-key',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('forged guarded marker does not block clean carrier writes', () {
      final forged = _makeForgedGuardedPngCarrier();
      expect(_readPolicyLsbBytes(forged, 6), ascii.encode('VSSGO2'));

      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: forged,
        text: 'fresh payload',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'fresh-key',
      );

      expect(
        service
            .revealText(
              mediaKind: ToolboxSteganographyMediaKind.image,
              carrierBytes: embedded.bytes,
              passphrase: 'fresh-key',
            )
            .text,
        'fresh payload',
      );
    });

    test('forged locator hint does not select higher KDF strength', () {
      final crypto = _CountingToolboxCryptoService();
      final countingService = ToolboxSteganographyService(
        cryptoService: crypto,
      );
      final embedded = countingService.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(),
        text: 'hint payload',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'hint-key',
        locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha256,
        locatorStrength: ToolboxSteganographyLocatorStrength.standard,
      );

      final forged = _withDeniableLocatorHintIndex(
        embedded.bytes,
        5, // extreme + sha512 under the legacy hint index layout.
      );
      crypto.locatorStrengths.clear();

      final revealed = countingService.revealText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: forged,
        passphrase: 'hint-key',
        locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha256,
        locatorStrength: ToolboxSteganographyLocatorStrength.standard,
      );

      expect(revealed.text, 'hint payload');
      expect(crypto.locatorStrengths, <ToolboxCryptoStrength>[
        ToolboxCryptoStrength.standard,
      ]);
    });

    test('embeds and reveals text in WAV/PCM audio carriers', () {
      final carrier = _makeWavCarrier(samples: 160000);
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: carrier,
        text: 'audio payload',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'audio-key',
        sourceExtension: 'wav',
      );

      expect(embedded.outputExtension, 'wav');
      expect(embedded.outputBytes, carrier.length);
      expect(embedded.capacityBytes, greaterThan(embedded.payloadBytes));

      final revealed = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: embedded.bytes,
        passphrase: 'audio-key',
      );
      expect(revealed.text, 'audio payload');
      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.audio,
          carrierBytes: embedded.bytes,
          passphrase: 'wrong-audio-key',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('embeds and reveals text in existing MP4 free padding', () {
      final carrier = _makeMp4Carrier(freePaddingBytes: 64000);
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.video,
        carrierBytes: carrier,
        text: 'video payload',
        encryption: ToolboxCryptoAlgorithm.chacha20Poly1305,
        passphrase: 'video-key',
        sourceExtension: 'mp4',
      );

      expect(embedded.outputExtension, 'mp4');
      expect(embedded.outputBytes, carrier.length);
      expect(embedded.capacityBytes, greaterThan(embedded.payloadBytes));

      final revealed = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.video,
        carrierBytes: embedded.bytes,
        passphrase: 'video-key',
      );
      expect(revealed.text, 'video payload');
    });

    test('embeds and reveals text in ISO BMFF audio free padding', () {
      final carrier = _makeMp4Carrier(
        freePaddingBytes: 64000,
        majorBrand: 'M4A ',
        compatibleBrands: const <String>['M4A ', 'isom', 'mp42'],
      );
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: carrier,
        text: 'm4a payload',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'm4a-key',
        sourceExtension: 'm4a',
      );

      expect(embedded.outputExtension, 'm4a');
      expect(embedded.outputBytes, carrier.length);

      final revealed = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: embedded.bytes,
        passphrase: 'm4a-key',
      );
      expect(revealed.text, 'm4a payload');
    });

    test('embeds and reveals text in ISO BMFF video variants', () {
      for (final item in <({String brand, String extension})>[
        (brand: 'M4V ', extension: 'm4v'),
        (brand: '3gp5', extension: '3gp'),
      ]) {
        final carrier = _makeMp4Carrier(
          freePaddingBytes: 64000,
          majorBrand: item.brand,
          compatibleBrands: <String>[item.brand, 'isom', 'mp42'],
        );
        final embedded = service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.video,
          carrierBytes: carrier,
          text: '${item.extension} payload',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          passphrase: '${item.extension}-key',
          sourceExtension: item.extension,
        );

        expect(embedded.outputExtension, item.extension);
        expect(embedded.outputBytes, carrier.length);

        final revealed = service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.video,
          carrierBytes: embedded.bytes,
          passphrase: '${item.extension}-key',
        );
        expect(revealed.text, '${item.extension} payload');
      }
    });

    test('rejects compressed audio formats without bitstream backends', () {
      for (final carrier in <Uint8List>[
        Uint8List.fromList(<int>[...ascii.encode('ID3'), 4, 0, 0, 0, 0, 0, 0]),
        Uint8List.fromList(<int>[0xff, 0xfb, 0x90, 0x64, 0, 0, 0, 0]),
        Uint8List.fromList(<int>[...ascii.encode('fLaC'), 0, 0, 0, 0]),
        Uint8List.fromList(<int>[...ascii.encode('OggS'), 0, 2, 0, 0]),
      ]) {
        expect(
          () => service.embedText(
            mediaKind: ToolboxSteganographyMediaKind.audio,
            carrierBytes: carrier,
            text: 'blocked audio',
            encryption: ToolboxCryptoAlgorithm.aesGcm,
            passphrase: 'blocked-audio-key',
          ),
          throwsA(
            isA<ToolboxSteganographyException>().having(
              (error) => error.message,
              'message',
              contains('Compressed audio bitstreams cannot be written safely'),
            ),
          ),
        );
      }
    });

    test('rejects complex video containers without safe parsers', () {
      for (final carrier in <Uint8List>[
        Uint8List.fromList(<int>[0x1a, 0x45, 0xdf, 0xa3, 0x93, 0x42, 0x82]),
        Uint8List.fromList(<int>[
          ...ascii.encode('RIFF'),
          0x24,
          0,
          0,
          0,
          ...ascii.encode('AVI '),
          0,
          0,
        ]),
        Uint8List.fromList(<int>[...ascii.encode('FLV'), 1, 5, 0, 0]),
      ]) {
        expect(
          () => service.embedText(
            mediaKind: ToolboxSteganographyMediaKind.video,
            carrierBytes: carrier,
            text: 'blocked video',
            encryption: ToolboxCryptoAlgorithm.aesGcm,
            passphrase: 'blocked-video-key',
          ),
          throwsA(
            isA<ToolboxSteganographyException>().having(
              (error) => error.message,
              'message',
              contains(
                'Compressed or complex video containers cannot be written safely',
              ),
            ),
          ),
        );
      }
    });

    test('audio and video payloads fail after carrier LSB tampering', () {
      final audio = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: _makeWavCarrier(samples: 160000),
        text: 'tamper audio',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'tamper-key',
      );
      final tamperedAudio = Uint8List.fromList(audio.bytes);
      for (var offset = 44; offset < tamperedAudio.length; offset += 2) {
        tamperedAudio[offset] ^= 1;
      }
      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.audio,
          carrierBytes: tamperedAudio,
          passphrase: 'tamper-key',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );

      final videoCarrier = _makeMp4Carrier(freePaddingBytes: 64000);
      final video = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.video,
        carrierBytes: videoCarrier,
        text: 'tamper video',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'tamper-key',
      );
      final tamperedVideo = Uint8List.fromList(video.bytes);
      final freeRange = _firstMp4FreeDataRange(tamperedVideo);
      for (var offset = freeRange.start; offset < freeRange.end; offset += 1) {
        tamperedVideo[offset] ^= 1;
      }
      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.video,
          carrierBytes: tamperedVideo,
          passphrase: 'tamper-key',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('rejects video carriers without existing free padding', () {
      expect(
        () => service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.video,
          carrierBytes: _makeMp4Carrier(),
          text: 'blocked payload',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          passphrase: 'blocked-key',
        ),
        throwsA(
          isA<ToolboxSteganographyException>().having(
            (error) => error.message,
            'message',
            contains('free-space padding'),
          ),
        ),
      );
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
      final embedded = service.embedDualText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(width: 180, height: 180),
        coverText: 'cover note',
        hiddenText: 'real note',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        coverPassphrase: 'cover-key',
        hiddenPassphrase: 'hidden-key',
        sourceExtension: 'png',
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
    });

    test('rejects plaintext image payload writes', () {
      expect(
        () => service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: _makePngCarrier(),
          text: 'plain image secret',
          encryption: ToolboxCryptoAlgorithm.none,
          passphrase: '',
          sourceExtension: 'png',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('strips hidden image payload only with the current credential', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(),
        text: 'protected secret',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'locator-key',
        locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha512,
        locatorStrength: ToolboxSteganographyLocatorStrength.strong,
      );

      final revealedWithSelectedLocator = service.revealText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'locator-key',
        locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha512,
        locatorStrength: ToolboxSteganographyLocatorStrength.strong,
      );
      expect(revealedWithSelectedLocator.text, 'protected secret');
      expect(
        _readSequentialLsbBytes(embedded.bytes, 6),
        isNot(ascii.encode('VSSGP2')),
      );

      final stripped = service.stripHiddenData(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'wrong-key',
        locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha512,
        locatorStrength: ToolboxSteganographyLocatorStrength.strong,
      );
      expect(stripped.removed, isFalse);
      expect(
        service
            .revealText(
              mediaKind: ToolboxSteganographyMediaKind.image,
              carrierBytes: embedded.bytes,
              passphrase: 'locator-key',
              locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha512,
              locatorStrength: ToolboxSteganographyLocatorStrength.strong,
            )
            .text,
        'protected secret',
      );
      final strippedWithKey = service.stripHiddenData(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'locator-key',
        locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha512,
        locatorStrength: ToolboxSteganographyLocatorStrength.strong,
      );
      expect(strippedWithKey.removed, isTrue);
      expect(
        () => service.revealText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: strippedWithKey.bytes,
          passphrase: 'locator-key',
          locatorAlgorithm: ToolboxSteganographyLocatorAlgorithm.sha512,
          locatorStrength: ToolboxSteganographyLocatorStrength.strong,
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('legacy public policy wipe is removed', () {
      final legacyImage = _makeLegacyPublicPolicyPngCarrier();
      final defaultStrip = service.stripHiddenData(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: legacyImage,
        passphrase: 'wrong-key',
      );
      expect(defaultStrip.removed, isFalse);
    });

    test('legacy WAV policy wipe has been removed', () {
      final stripped = service.stripHiddenData(
        mediaKind: ToolboxSteganographyMediaKind.audio,
        carrierBytes: _makeLegacyPublicPolicyWavCarrier(),
        passphrase: 'wrong-key',
      );
      expect(stripped.removed, isFalse);
    });

    test('keeps legacy audio and video reads removed', () {
      for (final item
          in <({ToolboxSteganographyMediaKind kind, Uint8List carrier})>[
            (
              kind: ToolboxSteganographyMediaKind.audio,
              carrier: _makeWavCarrier(samples: 22000),
            ),
            (
              kind: ToolboxSteganographyMediaKind.video,
              carrier: _makeMp4Carrier(),
            ),
          ]) {
        expect(
          () => service.revealText(
            mediaKind: item.kind,
            carrierBytes: item.carrier,
            passphrase: 'legacy-key',
          ),
          throwsA(isA<ToolboxSteganographyException>()),
        );
      }
    });

    test('embeds and reveals encrypted files in image carriers', () {
      final secretFile = Uint8List.fromList(
        List<int>.generate(48, (index) => (index * 13) & 255),
      );
      final embedded = service.embedFile(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(width: 160, height: 160),
        fileBytes: secretFile,
        fileName: 'payload.bin',
        encryption: ToolboxCryptoAlgorithm.customCascade,
        passphrase: 'file-key',
        sourceExtension: 'png',
        cascade: const <ToolboxCryptoCascadeCipher>[
          ToolboxCryptoCascadeCipher.aes,
          ToolboxCryptoCascadeCipher.twofish,
        ],
        keyBits: ToolboxCryptoKeyBits.bits512,
        macAlgorithm: ToolboxCryptoMacAlgorithm.whirlpool,
      );
      final revealed = service.revealFile(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'file-key',
      );

      expect(revealed.bytes, secretFile);
      expect(revealed.fileName, 'payload.bin');
      expect(revealed.encryption, ToolboxCryptoAlgorithm.customCascade);
    });

    test('embeds dual encrypted files and reveals matching file layer', () {
      final coverFile = Uint8List.fromList(
        List<int>.generate(32, (index) => (index * 7) & 255),
      );
      final hiddenFile = Uint8List.fromList(
        List<int>.generate(40, (index) => (index * 19) & 255),
      );
      final embedded = service.embedDualFile(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(width: 220, height: 220),
        coverFileBytes: coverFile,
        hiddenFileBytes: hiddenFile,
        coverFileName: 'cover.bin',
        hiddenFileName: 'hidden.bin',
        encryption: ToolboxCryptoAlgorithm.aesTwofishGcm,
        coverPassphrase: 'cover-file-key',
        hiddenPassphrase: 'hidden-file-key',
        sourceExtension: 'png',
      );

      final cover = service.revealFile(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'cover-file-key',
      );
      final hidden = service.revealFile(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: embedded.bytes,
        passphrase: 'hidden-file-key',
      );

      expect(cover.bytes, coverFile);
      expect(cover.fileName, 'cover.bin');
      expect(hidden.bytes, hiddenFile);
      expect(hidden.fileName, 'hidden.bin');
      expect(
        () => service.revealFile(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: embedded.bytes,
          passphrase: 'cover-file-key',
          keyFileBytes: Uint8List.fromList(<int>[1, 2, 3]),
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('embeds and reveals files in audio and video carriers', () {
      final secretFile = Uint8List.fromList(
        List<int>.generate(64, (index) => (index * 11) & 255),
      );
      for (final item
          in <({ToolboxSteganographyMediaKind kind, Uint8List carrier})>[
            (
              kind: ToolboxSteganographyMediaKind.audio,
              carrier: _makeWavCarrier(samples: 180000),
            ),
            (
              kind: ToolboxSteganographyMediaKind.video,
              carrier: _makeMp4Carrier(freePaddingBytes: 64000),
            ),
          ]) {
        final embedded = service.embedFile(
          mediaKind: item.kind,
          carrierBytes: item.carrier,
          fileBytes: secretFile,
          fileName: 'payload.bin',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          passphrase: 'file-media-key',
        );
        expect(embedded.outputBytes, item.carrier.length);

        final revealed = service.revealFile(
          mediaKind: item.kind,
          carrierBytes: embedded.bytes,
          passphrase: 'file-media-key',
        );
        expect(revealed.bytes, secretFile);
        expect(revealed.fileName, 'payload.bin');
      }
    });

    test('requires a key file for extreme-strength image writes', () {
      expect(
        () => service.embedText(
          mediaKind: ToolboxSteganographyMediaKind.image,
          carrierBytes: _makePngCarrier(),
          text: 'extreme secret',
          encryption: ToolboxCryptoAlgorithm.aesGcm,
          strength: ToolboxCryptoStrength.extreme,
          passphrase: 'extreme-key',
        ),
        throwsA(isA<ToolboxSteganographyException>()),
      );
    });

    test('maps locator strengths to scrypt-backed crypto strengths', () {
      expect(
        ToolboxSteganographyLocatorStrength.standard.cryptoStrength,
        ToolboxCryptoStrength.standard,
      );
      expect(
        ToolboxSteganographyLocatorStrength.strong.cryptoStrength,
        ToolboxCryptoStrength.strong,
      );
      expect(
        ToolboxSteganographyLocatorStrength.extreme.cryptoStrength,
        ToolboxCryptoStrength.extreme,
      );
    });

    test('carrier fingerprint round trips and detects modified output', () {
      final embedded = service.embedText(
        mediaKind: ToolboxSteganographyMediaKind.image,
        carrierBytes: _makePngCarrier(),
        text: 'fingerprinted payload',
        encryption: ToolboxCryptoAlgorithm.aesGcm,
        passphrase: 'fingerprint-key',
      );

      final fingerprint = embedded.fingerprint;
      expect(fingerprint.matchesBytes(embedded.bytes), isTrue);
      expect(
        ToolboxSteganographyService.parseFingerprintBytes(
          fingerprint.toFileBytes(fileName: 'carrier.png'),
        ).mixedHex,
        fingerprint.mixedHex,
      );
      expect(
        ToolboxSteganographyService.parseFingerprintBytes(
          Uint8List.fromList(utf8.encode(fingerprint.toCopyText())),
        ).sha256Hex,
        fingerprint.sha256Hex,
      );

      final modified = Uint8List.fromList(embedded.bytes);
      modified[modified.length - 1] ^= 1;
      expect(fingerprint.matchesBytes(modified), isFalse);
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

Uint8List _makeLegacyPublicPolicyPngCarrier() {
  final image = img.decodeImage(_makePngCarrier())!;
  _writeLsbBytesAtPositions(
    image,
    _buildLegacyImagePolicyHeader(policyByte: 3),
    _imagePolicyPositions(image),
  );
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _makeForgedGuardedPngCarrier() {
  final image = img.decodeImage(_makePngCarrier())!;
  _writeLsbBytesAtPositions(
    image,
    Uint8List.fromList(<int>[
      ...ascii.encode('VSSGO2'),
      ...List<int>.filled(17, 0),
    ]),
    _imagePolicyPositions(image),
  );
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _withDeniableLocatorHintIndex(Uint8List pngBytes, int hintIndex) {
  final image = img.decodeImage(pngBytes)!;
  final header = Uint8List.fromList(_readPolicyLsbBytes(pngBytes, 23));
  header[16] = header[0] ^ hintIndex;
  _writeLsbBytesAtPositions(image, header, _imagePolicyPositions(image));
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

List<int> _readPolicyLsbBytes(Uint8List pngBytes, int byteCount) {
  final image = img.decodeImage(pngBytes)!;
  final output = Uint8List(byteCount);
  final positions = _imagePolicyPositions(image);
  for (var bitIndex = 0; bitIndex < byteCount * 8; bitIndex += 1) {
    final position = positions[bitIndex];
    final pixelIndex = position ~/ 3;
    final channel = position % 3;
    final x = pixelIndex % image.width;
    final y = pixelIndex ~/ image.width;
    final pixel = image.getPixel(x, y);
    final value = switch (channel) {
      0 => pixel.r.toInt(),
      1 => pixel.g.toInt(),
      _ => pixel.b.toInt(),
    };
    if ((value & 1) != 0) {
      output[bitIndex >> 3] |= 1 << (7 - (bitIndex & 7));
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

Uint8List _makeLegacyPublicPolicyWavCarrier() {
  final bytes = _makeWavCarrier(samples: 22000);
  _writeWavBytesAtSamples(
    bytes,
    _buildLegacyMediaPolicyHeader(policyByte: 4),
    _wavPolicySamples(bytes),
  );
  return bytes;
}

Uint8List _makeMp4Carrier({
  int freePaddingBytes = 0,
  String majorBrand = 'isom',
  List<String> compatibleBrands = const <String>['isom', 'mp42'],
}) {
  final ftypPayload = <int>[
    ...ascii.encode(majorBrand.padRight(4).substring(0, 4)),
    0,
    0,
    2,
    0,
    for (final brand in compatibleBrands)
      ...ascii.encode(brand.padRight(4).substring(0, 4)),
  ];
  final mdatPayload = List<int>.generate(2048, (index) => (index * 31) & 255);
  final freePayload = List<int>.generate(
    freePaddingBytes,
    (index) => (index * 17 + 23) & 255,
  );
  return Uint8List.fromList(<int>[
    ..._mp4Box('ftyp', ftypPayload),
    if (freePaddingBytes > 0) ..._mp4Box('free', freePayload),
    ..._mp4Box('mdat', mdatPayload),
  ]);
}

({int start, int end}) _firstMp4FreeDataRange(Uint8List bytes) {
  var offset = 0;
  while (offset + 8 <= bytes.length) {
    final size =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
    if (type == 'free') {
      return (start: offset + 8, end: offset + size);
    }
    offset += size;
  }
  throw StateError('No free box in test carrier.');
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

Uint8List _buildLegacyImagePolicyHeader({required int policyByte}) {
  final prefix = Uint8List.fromList(<int>[
    ...ascii.encode('VSSGP2'),
    policyByte,
  ]);
  return Uint8List.fromList(<int>[
    ...prefix,
    ..._policyChecksum(
      prefix,
      versionLabel: 'vocabulary_sleep_stego_public_policy_v2',
      checksumLength: 16,
    ),
  ]);
}

Uint8List _buildLegacyMediaPolicyHeader({required int policyByte}) {
  final prefix = Uint8List.fromList(<int>[
    ...ascii.encode('VSSGM2'),
    policyByte,
  ]);
  return Uint8List.fromList(<int>[
    ...prefix,
    ..._policyChecksum(
      prefix,
      versionLabel: 'vocabulary_sleep_stego_media_policy_v1',
      checksumLength: 16,
    ),
  ]);
}

List<int> _policyChecksum(
  List<int> prefix, {
  required String versionLabel,
  required int checksumLength,
}) {
  return sha256
      .convert(<int>[...utf8.encode(versionLabel), 0, ...prefix])
      .bytes
      .sublist(0, checksumLength);
}

List<int> _imagePolicyPositions(img.Image image) {
  final totalPositions = image.width * image.height * 3;
  return _selectPositions(
    total: totalPositions,
    count: 23 * 8,
    seed: _imagePolicyPositionSeed(image),
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

List<int> _wavPolicySamples(Uint8List bytes) {
  return _selectPositions(
    total: _wavSampleCount(bytes),
    count: 23 * 8,
    seed: _wavCarrierDigest(bytes, purpose: 'audio-public-policy'),
  );
}

Uint8List _wavCarrierDigest(
  Uint8List bytes, {
  String purpose = 'audio-carrier',
}) {
  final input = BytesBuilder(copy: false)
    ..add(<int>[
      ...utf8.encode('vocabulary_sleep_stego_wav_digest_v1'),
      0,
      ...utf8.encode(purpose),
      0,
      ..._uint32Bytes(1),
      ..._uint32Bytes(16),
      ..._uint32Bytes(2),
      ..._uint32Bytes(bytes.length - 44),
      0,
    ])
    ..add(bytes.sublist(0, 44));
  final data = Uint8List.fromList(bytes.sublist(44));
  for (var offset = 0; offset < data.length; offset += 2) {
    data[offset] &= 0xfe;
  }
  input.add(data);
  return Uint8List.fromList(sha256.convert(input.takeBytes()).bytes);
}

int _wavSampleCount(Uint8List bytes) => (bytes.length - 44) ~/ 2;

void _writeLsbBytesAtPositions(
  img.Image image,
  Uint8List bytes,
  List<int> positions,
) {
  for (var bitIndex = 0; bitIndex < bytes.length * 8; bitIndex += 1) {
    _setImageLsbAtPosition(image, positions[bitIndex], _bitAt(bytes, bitIndex));
  }
}

void _setImageLsbAtPosition(img.Image image, int position, int bit) {
  final pixelIndex = position ~/ 3;
  final channel = position % 3;
  final x = pixelIndex % image.width;
  final y = pixelIndex ~/ image.width;
  final pixel = image.getPixel(x, y);
  final r = pixel.r.toInt();
  final g = pixel.g.toInt();
  final b = pixel.b.toInt();
  image.setPixelRgba(
    x,
    y,
    channel == 0 ? ((r & 0xfe) | bit) : r,
    channel == 1 ? ((g & 0xfe) | bit) : g,
    channel == 2 ? ((b & 0xfe) | bit) : b,
    pixel.a.toInt(),
  );
}

void _writeWavBytesAtSamples(
  Uint8List bytes,
  Uint8List payload,
  List<int> samples,
) {
  for (var bitIndex = 0; bitIndex < payload.length * 8; bitIndex += 1) {
    final offset = 44 + (samples[bitIndex] * 2);
    bytes[offset] = (bytes[offset] & 0xfe) | _bitAt(payload, bitIndex);
  }
}

int _bitAt(Uint8List bytes, int bitIndex) {
  return (bytes[bitIndex >> 3] >> (7 - (bitIndex & 7))) & 1;
}

List<int> _selectPositions({
  required int total,
  required int count,
  required Uint8List seed,
}) {
  final unavailable = <int>{};
  final rng = _HmacSha256Csprng(seed);
  final positions = <int>[];
  final maxAttempts = count * 8 > 256 ? count * 8 : 256;
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

class _HmacSha256Csprng {
  _HmacSha256Csprng(this._seed);

  final Uint8List _seed;
  Uint8List _buffer = Uint8List(0);
  var _offset = 0;
  var _counter = 0;

  int nextInt(int max) {
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

double mathSin(double value) {
  // Small deterministic sine approximation is enough for a non-silent carrier.
  var x = value % 6.283185307179586;
  if (x > 3.141592653589793) {
    x -= 6.283185307179586;
  }
  return x - ((x * x * x) / 6) + ((x * x * x * x * x) / 120);
}

class _CountingToolboxCryptoService extends ToolboxCryptoService {
  final locatorStrengths = <ToolboxCryptoStrength>[];

  @override
  Uint8List deriveSteganographyLocatorSecret({
    required String passphrase,
    required Uint8List? keyFileBytes,
    required Uint8List salt,
    required ToolboxCryptoStrength strength,
    String purpose = 'steganography-locator-v5',
    int length = 64,
  }) {
    locatorStrengths.add(strength);
    return super.deriveSteganographyLocatorSecret(
      passphrase: passphrase,
      keyFileBytes: keyFileBytes,
      salt: salt,
      strength: strength,
      purpose: purpose,
      length: length,
    );
  }
}
