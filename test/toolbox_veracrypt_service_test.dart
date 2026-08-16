import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:vocabulary_sleep_app/src/services/toolbox_veracrypt_crypto.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_veracrypt_primitives.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_veracrypt_service.dart';

void main() {
  group('ToolboxVeraCryptService', () {
    final service = ToolboxVeraCryptService();

    test('reports empty bytes as no file', () {
      final result = service.inspectBytes(
        bytes: Uint8List(0),
        fileName: 'empty.hc',
      );

      expect(result.fileSize, 0);
      expect(result.readiness, ToolboxVeraCryptReadiness.noFile);
      expect(result.containerKind, ToolboxVeraCryptContainerKind.veracrypt);
      expect(result.headerBytesAvailable, 0);
      expect(result.hasBackupHeader, isFalse);
      expect(result.sha256Preview, isEmpty);
      expect(result.notes, contains('toolbox.crypto.veracrypt.note.no_file'));
    });

    test(
      'reports containers below the VeraCrypt layout floor as too small',
      () {
        final bytes = Uint8List(ToolboxVeraCryptService.minContainerBytes - 1);
        final result = service.inspectBytes(bytes: bytes, fileName: 'tiny.hc');

        expect(result.readiness, ToolboxVeraCryptReadiness.tooSmall);
        expect(result.headerBytesAvailable, ToolboxVeraCryptService.headerSize);
        expect(result.hasBackupHeader, isFalse);
        expect(result.headerWindows.first.saltFingerprint, isNotEmpty);
        expect(
          result.notes,
          contains('toolbox.crypto.veracrypt.note.too_small'),
        );
      },
    );

    test('maps primary, hidden, and backup header offsets', () {
      final fileSize = ToolboxVeraCryptService.minContainerBytes + 4096;
      final bytes = Uint8List.fromList(
        List<int>.generate(fileSize, (index) => index & 0xff),
      );
      final result = service.inspectBytes(bytes: bytes, fileName: 'vault.hc');

      expect(result.readiness, ToolboxVeraCryptReadiness.readyForHeaderUnlock);
      expect(result.containerKind, ToolboxVeraCryptContainerKind.veracrypt);
      expect(result.containerExtension, '.hc');
      expect(result.primaryHeaderOffset, 0);
      expect(result.hiddenHeaderOffset, ToolboxVeraCryptService.headerAreaSize);
      expect(
        result.backupHeaderOffset,
        fileSize - ToolboxVeraCryptService.backupHeaderAreaSize,
      );
      expect(
        result.hiddenBackupHeaderOffset,
        fileSize - ToolboxVeraCryptService.headerAreaSize,
      );
      expect(result.hasPrimaryHeader, isTrue);
      expect(result.hasHiddenHeader, isTrue);
      expect(result.hasBackupHeader, isTrue);
      expect(result.hasHiddenBackupHeader, isTrue);
      expect(result.headerWindows, hasLength(4));
      expect(
        result.headerWindows
            .where((window) => window.hasSaltFingerprint)
            .length,
        4,
      );
      expect(
        result.notes,
        contains('toolbox.crypto.veracrypt.note.backup_header_present'),
      );
    });

    test(
      'inspects a seekable file without requiring full-file bytes',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'toolbox_veracrypt_',
        );
        addTearDown(() async {
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
        });
        final file = File('${directory.path}/large.hc');
        final bytes = Uint8List.fromList(
          List<int>.generate(
            ToolboxVeraCryptService.maxPreviewHashBytes + 8192,
            (index) => (index * 31) & 0xff,
          ),
        );
        await file.writeAsBytes(bytes, flush: true);

        final result = await service.inspectFile(
          file: file,
          fileName: 'large.hc',
        );

        final preview = Uint8List.sublistView(
          bytes,
          0,
          ToolboxVeraCryptService.maxPreviewHashBytes,
        );
        expect(result.fileSize, bytes.length);
        expect(
          result.sha256Preview,
          _hex(crypto.sha256.convert(preview).bytes),
        );
        expect(result.backupHeaderOffset, bytes.length - 131072);
      },
    );

    test('classifies supported and review-only container names', () {
      final bytes = Uint8List(ToolboxVeraCryptService.minContainerBytes);

      final extensionless = service.inspectBytes(
        bytes: bytes,
        fileName: 'vault',
      );
      final legacy = service.inspectBytes(bytes: bytes, fileName: 'old.tc');
      final review = service.inspectBytes(bytes: bytes, fileName: 'notes.bin');

      expect(
        extensionless.containerKind,
        ToolboxVeraCryptContainerKind.extensionless,
      );
      expect(
        extensionless.readiness,
        ToolboxVeraCryptReadiness.readyForHeaderUnlock,
      );
      expect(
        extensionless.notes,
        contains('toolbox.crypto.veracrypt.note.extensionless'),
      );
      expect(
        legacy.containerKind,
        ToolboxVeraCryptContainerKind.trueCryptLegacy,
      );
      expect(
        review.containerKind,
        ToolboxVeraCryptContainerKind.reviewExtension,
      );
      expect(review.readiness, ToolboxVeraCryptReadiness.inspectOnly);
      expect(
        review.notes,
        contains('toolbox.crypto.veracrypt.note.extension_review'),
      );
    });

    test('summarizes unlock material without retaining secrets', () {
      final keyFile = service.inspectKeyFileBytes(
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        fileName: 'vault.key',
      );

      final summary = service.summarizeUnlockMaterial(
        passphrase: 'correct horse',
        pim: '485',
        keyFile: keyFile,
      );

      expect(summary.hasPassphrase, isTrue);
      expect(summary.passphraseLength, 13);
      expect(summary.pimStatus, ToolboxVeraCryptPimStatus.valid);
      expect(summary.hasKeyFile, isTrue);
      expect(summary.canAttemptFutureHeaderUnlock, isTrue);
      expect(
        summary.notes,
        contains('toolbox.crypto.veracrypt.note.material_header_unlock_ready'),
      );
      expect(
        summary.candidateKdfLabelKeys,
        contains('toolbox.crypto.veracrypt.kdf.pbkdf2_all'),
      );
    });

    test('rejects invalid PIM in unlock material summary', () {
      final summary = service.summarizeUnlockMaterial(
        passphrase: 'passphrase',
        pim: '0x20',
      );

      expect(summary.pimStatus, ToolboxVeraCryptPimStatus.invalid);
      expect(summary.canAttemptFutureHeaderUnlock, isFalse);
      expect(
        summary.notes,
        contains('toolbox.crypto.veracrypt.note.pim_invalid'),
      );
    });

    test('hashes only a bounded keyfile preview', () {
      final bytes = Uint8List.fromList(
        List<int>.generate(
          ToolboxVeraCryptService.maxKeyFileHashBytes + 17,
          (index) => (index * 7) & 0xff,
        ),
      );

      final keyFile = service.inspectKeyFileBytes(
        bytes: bytes,
        fileName: 'large.key',
      );
      final expectedSample = Uint8List.sublistView(
        bytes,
        0,
        ToolboxVeraCryptService.maxKeyFileHashBytes,
      );

      expect(keyFile.fileSize, bytes.length);
      expect(keyFile.bytesHashed, ToolboxVeraCryptService.maxKeyFileHashBytes);
      expect(keyFile.isTruncated, isTrue);
      expect(keyFile.hasVeraCryptKeyfilePool, isTrue);
      expect(
        keyFile.veracryptLegacyKeyfilePool,
        hasLength(ToolboxVeraCryptHeaderCrypto.legacyKeyfilePoolSize),
      );
      expect(
        keyFile.sha256Preview,
        _hex(crypto.sha256.convert(expectedSample).bytes),
      );
    });

    test('performs AES-XTS encryption and decryption round trip', () {
      const cryptoEngine = ToolboxVeraCryptHeaderCrypto();
      final dataKey = Uint8List.fromList(
        List<int>.generate(32, (index) => (index * 3) & 0xff),
      );
      final tweakKey = Uint8List.fromList(
        List<int>.generate(32, (index) => (index * 5 + 7) & 0xff),
      );
      final plaintext = Uint8List.fromList(
        List<int>.generate(448, (index) => (index * 11 + 13) & 0xff),
      );

      final encrypted = cryptoEngine.aesXtsCrypt(
        input: plaintext,
        dataKey: dataKey,
        tweakKey: tweakKey,
        encrypt: true,
      );
      final decrypted = cryptoEngine.aesXtsCrypt(
        input: encrypted,
        dataKey: dataKey,
        tweakKey: tweakKey,
        encrypt: false,
      );

      expect(encrypted, isNot(plaintext));
      expect(decrypted, plaintext);
    });

    test('performs VeraCrypt data-unit AES-XTS round trip', () {
      const cryptoEngine = ToolboxVeraCryptHeaderCrypto();
      final masterKeyData = Uint8List.fromList(
        List<int>.generate(
          ToolboxVeraCryptHeaderCrypto.masterKeyDataSize,
          (index) => (index * 13 + 19) & 0xff,
        ),
      );
      final plaintext = Uint8List.fromList(
        List<int>.generate(1024, (index) => (index * 23 + 5) & 0xff),
      );

      final encrypted = cryptoEngine.cryptDataUnits(
        input: plaintext,
        masterKeyData: masterKeyData,
        sectorSize: 512,
        dataUnitStart: 7,
        encrypt: true,
      );
      final decrypted = cryptoEngine.cryptDataUnits(
        input: encrypted,
        masterKeyData: masterKeyData,
        sectorSize: 512,
        dataUnitStart: 7,
      );
      final wrongUnit = cryptoEngine.cryptDataUnits(
        input: encrypted,
        masterKeyData: masterKeyData,
        sectorSize: 512,
        dataUnitStart: 8,
      );

      expect(encrypted, isNot(plaintext));
      expect(decrypted, plaintext);
      expect(wrongUnit, isNot(plaintext));
    });

    test('performs VeraCrypt data-unit AES-Twofish XTS round trip', () {
      const cryptoEngine = ToolboxVeraCryptHeaderCrypto();
      final masterKeyData = Uint8List.fromList(
        List<int>.generate(
          ToolboxVeraCryptHeaderCrypto.masterKeyDataSize,
          (index) => (index * 29 + 31) & 0xff,
        ),
      );
      final plaintext = Uint8List.fromList(
        List<int>.generate(1024, (index) => (index * 37 + 11) & 0xff),
      );

      final encrypted = cryptoEngine.cryptDataUnits(
        input: plaintext,
        masterKeyData: masterKeyData,
        sectorSize: 512,
        dataUnitStart: 9,
        cipherChain: ToolboxVeraCryptCipherChain.aesTwofish,
        encrypt: true,
      );
      final decrypted = cryptoEngine.cryptDataUnits(
        input: encrypted,
        masterKeyData: masterKeyData,
        sectorSize: 512,
        dataUnitStart: 9,
        cipherChain: ToolboxVeraCryptCipherChain.aesTwofish,
      );
      final aesOnly = cryptoEngine.cryptDataUnits(
        input: encrypted,
        masterKeyData: masterKeyData,
        sectorSize: 512,
        dataUnitStart: 9,
      );

      expect(encrypted, isNot(plaintext));
      expect(decrypted, plaintext);
      expect(aesOnly, isNot(plaintext));
    });

    for (final cipherChain in <ToolboxVeraCryptCipherChain>[
      ToolboxVeraCryptCipherChain.serpent,
      ToolboxVeraCryptCipherChain.kuznyechik,
      ToolboxVeraCryptCipherChain.aesTwofishSerpent,
      ToolboxVeraCryptCipherChain.kuznyechikSerpentCamellia,
    ]) {
      test('performs VeraCrypt data-unit ${cipherChain.id} XTS round trip', () {
        const cryptoEngine = ToolboxVeraCryptHeaderCrypto();
        final masterKeyData = Uint8List.fromList(
          List<int>.generate(
            ToolboxVeraCryptHeaderCrypto.masterKeyDataSize,
            (index) => (index * 41 + 17) & 0xff,
          ),
        );
        final plaintext = Uint8List.fromList(
          List<int>.generate(1024, (index) => (index * 43 + 23) & 0xff),
        );

        final encrypted = cryptoEngine.cryptDataUnits(
          input: plaintext,
          masterKeyData: masterKeyData,
          sectorSize: 512,
          dataUnitStart: 11,
          cipherChain: cipherChain,
          encrypt: true,
        );
        final decrypted = cryptoEngine.cryptDataUnits(
          input: encrypted,
          masterKeyData: masterKeyData,
          sectorSize: 512,
          dataUnitStart: 11,
          cipherChain: cipherChain,
        );
        final aesOnly = cryptoEngine.cryptDataUnits(
          input: encrypted,
          masterKeyData: masterKeyData,
          sectorSize: 512,
          dataUnitStart: 11,
        );

        expect(encrypted, isNot(plaintext));
        expect(decrypted, plaintext);
        expect(aesOnly, isNot(plaintext));
      });
    }

    test('matches an independent AES-XTS 448-byte encryption vector', () {
      const cryptoEngine = ToolboxVeraCryptHeaderCrypto();
      final key = Uint8List.fromList(
        List<int>.generate(64, (index) => (index * 7 + 3) & 0xff),
      );
      final plaintext = Uint8List.fromList(
        List<int>.generate(448, (index) => (index * 11 + 13) & 0xff),
      );
      final expectedCiphertext = _hexToBytes(
        '48f469f294478387f37e0b56b775fcb884fe00f9335726665cbc8ab80a9e6db3'
        '9dc56b205cc9e4146ed3c88a60b1cea04c76c75728ea691a207ada21057b67'
        'ab19dcab823241827e2e78b9a91b83357d52a0ba14880d3793454bc661647'
        '30f02c61703f35ad0ed90d110568dbbb3505754c3abd0c5f80bbff279bbc'
        '9ffdb2fb3351d149e1ecff3b4e16f81594cc31d76e18b51fb9bd84a826'
        '6b19484fae0012ad2dcbf12ede571cab68cc5b2b32ed6cacb2609c0492f'
        'f3bf546f1fd0c693cb6f359b8016dc231be3d8fa6cf0c4437a0d1f604'
        'e41c0fc4a92f8635591ec870e6e95c02972d51527902b7c87e4b8b104'
        '3c3091e49e6210ef7a092f76e50bc2df76d3416d9d808b7eeb8302a495'
        '616d90c6c6fe23ca646bd97ec5be47f8142af68554f7bcbe73a8f130942'
        '1e46284f9f0464413453aa27398d09876dd5063ab118132d2259a3ed3b'
        '76376015525ec0682596f7d0a845eda8dd4820b00363045d9773397157b'
        '299a0da3b4fd54ee229827e904d104d33fa71ef6cdfc2cd9c142ced311'
        '22ae18e34a7b7812830cb9cecc7866eda67d6c4fec59435e2b3d30cdad'
        'da4c7a01ec83f61a80f1a67ee50a1797393fa34297b756977010b0754a'
        'ecbceaafc2',
      );

      final encrypted = cryptoEngine.aesXtsCrypt(
        input: plaintext,
        dataKey: Uint8List.sublistView(key, 0, 32),
        tweakKey: Uint8List.sublistView(key, 32, 64),
        encrypt: true,
      );
      final decrypted = cryptoEngine.aesXtsCrypt(
        input: expectedCiphertext,
        dataKey: Uint8List.sublistView(key, 0, 32),
        tweakKey: Uint8List.sublistView(key, 32, 64),
        encrypt: false,
      );

      expect(encrypted, expectedCiphertext);
      expect(decrypted, plaintext);
    });

    test('matches Serpent-256 zero-key block vector', () {
      final encryptor = ToolboxVeraCryptSerpentEngine()
        ..init(true, pc.KeyParameter(Uint8List(32)));
      final decryptor = ToolboxVeraCryptSerpentEngine()
        ..init(false, pc.KeyParameter(Uint8List(32)));
      final expected = _hexToBytes('49672ba898d98df95019180445491089');

      expect(encryptor.process(Uint8List(16)), expected);
      expect(decryptor.process(expected), Uint8List(16));
    });

    test('matches RFC 7801 Kuznyechik block vector', () {
      final key = _hexToBytes(
        '8899aabbccddeeff0011223344556677'
        'fedcba98765432100123456789abcdef',
      );
      final plaintext = _hexToBytes('1122334455667700ffeeddccbbaa9988');
      final ciphertext = _hexToBytes('7f679d90bebc24305a468d42b9d4edcd');
      final encryptor = ToolboxVeraCryptKuznyechikEngine()
        ..init(true, pc.KeyParameter(key));
      final decryptor = ToolboxVeraCryptKuznyechikEngine()
        ..init(false, pc.KeyParameter(key));

      expect(encryptor.process(plaintext), ciphertext);
      expect(decryptor.process(ciphertext), plaintext);
    });

    test('matches BLAKE2s-256 digest vectors', () {
      final digest = ToolboxVeraCryptBlake2sDigest();

      expect(
        digest.process(Uint8List(0)),
        _hexToBytes(
          '69217a3079908094e11121d042354a7'
          'c1f55b6482ca1a51e1b250dfd1ed0eef9',
        ),
      );
      expect(
        digest.process(Uint8List.fromList(utf8.encode('abc'))),
        _hexToBytes(
          '508c5e8c327c14e2e1a72ba34eeb452f'
          '37458b209ed63a294d999b4c86675982',
        ),
      );
    });

    test('matches VeraCrypt Streebog-512 digest byte order', () {
      final digest = ToolboxVeraCryptStreebog512Digest();
      final expected = _hexToBytes(
        '8a1a1c4cbf909f8ecb81cd1b5c713aba'
        'd26a4cac2a5fda3ce86e352855712f36'
        'a7f0be98eb6cf51553b507b73a87e979'
        '46aebc29859255049f86aa09a25d948e',
      );

      expect(digest.process(Uint8List(0)), expected);
      expect(
        Uint8List.sublistView(_reverseBytes(expected), 0, 8),
        _hexToBytes('8e945da209aa869f'),
      );
    });

    test('unlocks a synthetic AES-XTS PBKDF2-SHA512 header', () {
      final header = service.buildSyntheticAesXtsHeaderForTesting(
        passphrase: 'correct horse',
        kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
        iterationOverrideForTesting: 1000,
      );

      final result = service.attemptHeaderUnlockBytes(
        headerBytes: header,
        passphrase: 'correct horse',
        iterationOverrideForTesting: 1000,
      );

      expect(result.success, isTrue);
      expect(result.decodedHeader, isNotNull);
      expect(result.decodedHeader!.kdf, ToolboxVeraCryptKdf.pbkdf2Sha512);
      expect(ToolboxVeraCryptKdf.pbkdf2Sha512.iterationsForPim(0), 500000);
      expect(result.decodedHeader!.iterations, 1000);
      expect(result.decodedHeader!.headerVersion, 5);
      expect(result.decodedHeader!.sectorSize, 512);
      expect(
        result.notes,
        contains('toolbox.crypto.veracrypt.note.header_unlock_success'),
      );
    });

    test('unlocks a synthetic AES-XTS PBKDF2-SHA256 header with PIM', () {
      final header = service.buildSyntheticAesXtsHeaderForTesting(
        passphrase: 'correct horse',
        kdf: ToolboxVeraCryptKdf.pbkdf2Sha256,
        pim: 1,
        iterationOverrideForTesting: 1000,
      );

      final result = service.attemptHeaderUnlockBytes(
        headerBytes: header,
        passphrase: 'correct horse',
        pim: '1',
        iterationOverrideForTesting: 1000,
      );

      expect(result.success, isTrue);
      expect(result.decodedHeader!.kdf, ToolboxVeraCryptKdf.pbkdf2Sha256);
      expect(ToolboxVeraCryptKdf.pbkdf2Sha256.iterationsForPim(1), 16000);
      expect(result.decodedHeader!.iterations, 1000);
    });

    for (final cipherChain in <ToolboxVeraCryptCipherChain>[
      ToolboxVeraCryptCipherChain.serpent,
      ToolboxVeraCryptCipherChain.twofish,
      ToolboxVeraCryptCipherChain.camellia,
      ToolboxVeraCryptCipherChain.kuznyechik,
      ToolboxVeraCryptCipherChain.aesTwofishSerpent,
      ToolboxVeraCryptCipherChain.kuznyechikSerpentCamellia,
    ]) {
      test('unlocks a synthetic ${cipherChain.id} XTS header', () {
        final header = service.buildSyntheticAesXtsHeaderForTesting(
          passphrase: 'cipher chain',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          cipherChain: cipherChain,
          iterationOverrideForTesting: 100,
        );

        final result = service.attemptHeaderUnlockBytes(
          headerBytes: header,
          passphrase: 'cipher chain',
          iterationOverrideForTesting: 100,
        );

        expect(result.success, isTrue);
        expect(result.decodedHeader!.cipherChain, cipherChain);
        expect(result.decodedHeader!.kdf, ToolboxVeraCryptKdf.pbkdf2Sha512);
      });
    }

    for (final kdf in <ToolboxVeraCryptKdf>[
      ToolboxVeraCryptKdf.pbkdf2Whirlpool,
      ToolboxVeraCryptKdf.pbkdf2Blake2s,
      ToolboxVeraCryptKdf.pbkdf2Streebog,
    ]) {
      test('unlocks a synthetic ${kdf.labelKey} header', () {
        final header = service.buildSyntheticAesXtsHeaderForTesting(
          passphrase: 'kdf',
          kdf: kdf,
          iterationOverrideForTesting: 25,
        );

        final result = service.attemptHeaderUnlockBytes(
          headerBytes: header,
          passphrase: 'kdf',
          iterationOverrideForTesting: 25,
        );

        expect(result.success, isTrue);
        expect(result.decodedHeader!.kdf, kdf);
        expect(
          result.decodedHeader!.cipherChain,
          ToolboxVeraCryptCipherChain.aes,
        );
        expect(result.decodedHeader!.iterations, 25);
      });
    }

    test('unlocks a synthetic Argon2id header with test memory override', () {
      final header = service.buildSyntheticAesXtsHeaderForTesting(
        passphrase: 'argon',
        kdf: ToolboxVeraCryptKdf.argon2id,
        pim: 1,
        iterationOverrideForTesting: 1,
        argon2MemoryKiBOverrideForTesting: 32,
      );

      final result = service.attemptHeaderUnlockBytes(
        headerBytes: header,
        passphrase: 'argon',
        pim: '1',
        iterationOverrideForTesting: 1,
        argon2MemoryKiBOverrideForTesting: 32,
      );

      expect(result.success, isTrue);
      expect(result.decodedHeader!.kdf, ToolboxVeraCryptKdf.argon2id);
      expect(
        result.decodedHeader!.cipherChain,
        ToolboxVeraCryptCipherChain.aes,
      );
      expect(result.decodedHeader!.iterations, 1);
      expect(result.decodedHeader!.memoryKiB, 32);
      expect(ToolboxVeraCryptKdf.argon2id.iterationsForPim(1), 3);
      expect(ToolboxVeraCryptKdf.argon2id.memoryKiBForPim(1), 64 * 1024);
    });

    test('derives PBKDF2 header key prefixes from max material', () {
      const headerCrypto = ToolboxVeraCryptHeaderCrypto();
      final salt = Uint8List.fromList(
        List<int>.generate(
          ToolboxVeraCryptHeaderCrypto.saltSize,
          (index) => index,
        ),
      );
      final passwordBytes = Uint8List.fromList(utf8.encode('prefix'));
      final maxMaterial = headerCrypto.deriveHeaderKeyMaterial(
        passwordBytes: passwordBytes,
        salt: salt,
        kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
        pim: 0,
        outputSize: ToolboxVeraCryptHeaderCrypto.maxHeaderKeyMaterialSize,
        iterationOverride: 10,
      );
      final aesKey = headerCrypto.deriveHeaderKey(
        passwordBytes: passwordBytes,
        salt: salt,
        kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
        pim: 0,
        cipherChain: ToolboxVeraCryptCipherChain.aes,
        iterationOverride: 10,
      );
      final cascadeKey = headerCrypto.deriveHeaderKey(
        passwordBytes: passwordBytes,
        salt: salt,
        kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
        pim: 0,
        cipherChain: ToolboxVeraCryptCipherChain.serpentTwofishAes,
        iterationOverride: 10,
      );

      expect(maxMaterial.length, 192);
      expect(Uint8List.sublistView(maxMaterial, 0, aesKey.length), aesKey);
      expect(cascadeKey, maxMaterial);
    });

    test('derives Argon2id header key prefixes from fixed material', () {
      const headerCrypto = ToolboxVeraCryptHeaderCrypto();
      final salt = Uint8List.fromList(
        List<int>.generate(
          ToolboxVeraCryptHeaderCrypto.saltSize,
          (index) => (index * 3 + 7) & 0xff,
        ),
      );
      final passwordBytes = Uint8List.fromList(utf8.encode('argon prefix'));
      final maxMaterial = headerCrypto.deriveHeaderKeyMaterial(
        passwordBytes: passwordBytes,
        salt: salt,
        kdf: ToolboxVeraCryptKdf.argon2id,
        pim: 1,
        outputSize: ToolboxVeraCryptHeaderCrypto.maxHeaderKeyMaterialSize,
        iterationOverride: 1,
        argon2MemoryKiBOverride: 32,
      );
      final aesKey = headerCrypto.deriveHeaderKey(
        passwordBytes: passwordBytes,
        salt: salt,
        kdf: ToolboxVeraCryptKdf.argon2id,
        pim: 1,
        cipherChain: ToolboxVeraCryptCipherChain.aes,
        iterationOverride: 1,
        argon2MemoryKiBOverride: 32,
      );

      expect(maxMaterial.length, 192);
      expect(Uint8List.sublistView(maxMaterial, 0, aesKey.length), aesKey);
    });

    test('custom digest adapters reject invalid ranges', () {
      for (final digest in <pc.Digest>[
        ToolboxVeraCryptBlake2sDigest(),
        ToolboxVeraCryptStreebog512Digest(),
      ]) {
        expect(() => digest.update(Uint8List(1), -1, 1), throwsArgumentError);
        expect(() => digest.update(Uint8List(1), 0, 2), throwsArgumentError);
        digest.updateByte(1);
        expect(
          () => digest.doFinal(Uint8List(digest.digestSize - 1), 0),
          throwsArgumentError,
        );
      }
    });

    test('uses VeraCrypt keyfile pool when unlocking a synthetic header', () {
      final keyFile = service.inspectKeyFileBytes(
        bytes: Uint8List.fromList(<int>[9, 7, 5, 3, 1]),
        fileName: 'vault.key',
      );
      final header = service.buildSyntheticAesXtsHeaderForTesting(
        passphrase: 'with keyfile',
        kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
        keyFile: keyFile,
        iterationOverrideForTesting: 1000,
      );

      final withoutKeyfile = service.attemptHeaderUnlockBytes(
        headerBytes: header,
        passphrase: 'with keyfile',
        iterationOverrideForTesting: 1000,
      );
      final withKeyfile = service.attemptHeaderUnlockBytes(
        headerBytes: header,
        passphrase: 'with keyfile',
        keyFile: keyFile,
        iterationOverrideForTesting: 1000,
      );

      expect(withoutKeyfile.success, isFalse);
      expect(withKeyfile.success, isTrue);
      expect(withKeyfile.decodedHeader!.kdf, ToolboxVeraCryptKdf.pbkdf2Sha512);
    });

    test('reports failed unlock for a wrong passphrase', () {
      final header = service.buildSyntheticAesXtsHeaderForTesting(
        passphrase: 'correct horse',
        kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
        iterationOverrideForTesting: 1000,
      );

      final result = service.attemptHeaderUnlockBytes(
        headerBytes: header,
        passphrase: 'wrong horse',
        iterationOverrideForTesting: 1000,
      );

      expect(result.status, ToolboxVeraCryptHeaderUnlockStatus.failed);
      expect(result.success, isFalse);
      expect(result.decodedHeader, isNull);
    });

    test(
      'reports unsupported for a decoded header with invalid sector size',
      () {
        final header = service.buildSyntheticAesXtsHeaderForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          sectorSize: 7,
          iterationOverrideForTesting: 1000,
        );

        final result = service.attemptHeaderUnlockBytes(
          headerBytes: header,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );

        expect(
          result.status,
          ToolboxVeraCryptHeaderUnlockStatus.unsupportedMaterial,
        );
        expect(result.success, isFalse);
        expect(result.decodedHeader, isNotNull);
        expect(
          result.notes,
          contains(
            'toolbox.crypto.veracrypt.note.data_probe_unsupported_layout',
          ),
        );
      },
    );

    test('probes a synthetic AES-XTS data area after header unlock', () {
      final plaintextDataArea = _syntheticFat32DataArea();
      final container = service.buildSyntheticAesXtsContainerForTesting(
        passphrase: 'correct horse',
        kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
        plaintextDataArea: plaintextDataArea,
        iterationOverrideForTesting: 1000,
      );

      final result = service.probeDataAreaBytes(
        containerBytes: container,
        passphrase: 'correct horse',
        iterationOverrideForTesting: 1000,
      );

      expect(result.success, isTrue);
      expect(result.status, ToolboxVeraCryptDataProbeStatus.success);
      expect(result.headerUnlockResult.success, isTrue);
      expect(result.dataOffset, ToolboxVeraCryptService.dataAreaOffset);
      expect(result.bytesRead, plaintextDataArea.length);
      // VeraCrypt uses the absolute container sector number
      // (encryptedAreaStart / sectorSize) as the XTS data-unit base.
      // For the standard 131072-byte start that is 131072 ~/ 512 = 256.
      expect(
        result.dataUnitStart,
        ToolboxVeraCryptService.dataAreaOffset ~/ 512,
      );
      expect(result.dataUnitCount, plaintextDataArea.length ~/ 512);
      expect(result.likelyFat32BootSector, isTrue);
      expect(
        result.decryptedSha256,
        _hex(crypto.sha256.convert(plaintextDataArea).bytes),
      );
      expect(result.plaintextHexPreview, startsWith('eb5890'));
      expect(
        result.notes,
        contains('toolbox.crypto.veracrypt.note.data_probe_success'),
      );
    });

    test(
      'probes a synthetic AES-Twofish XTS data area after header unlock',
      () {
        final plaintextDataArea = _syntheticFat32DataArea();
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'cascade',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          cipherChain: ToolboxVeraCryptCipherChain.aesTwofish,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );

        final result = service.probeDataAreaBytes(
          containerBytes: container,
          passphrase: 'cascade',
          iterationOverrideForTesting: 1000,
        );

        expect(result.success, isTrue);
        expect(
          result.headerUnlockResult.decodedHeader!.cipherChain,
          ToolboxVeraCryptCipherChain.aesTwofish,
        );
        expect(result.likelyFat32BootSector, isTrue);
        expect(
          result.decryptedSha256,
          _hex(crypto.sha256.convert(plaintextDataArea).bytes),
        );
      },
    );

    test(
      'data probe uses the absolute container sector as the XTS data-unit base',
      () {
        // Regression guard for the real-container interop bug: VeraCrypt
        // derives the XTS tweak from the *absolute* container sector number
        // (fileOffset / sectorSize), not a 0-based index relative to the
        // encrypted area. A non-default encryptedAreaStart makes the two
        // conventions produce different tweaks, so this vector fails if the
        // implementation regresses to the relative 0-based base.
        const cryptoEngine = ToolboxVeraCryptHeaderCrypto();
        const customEncryptedAreaStart = 256 * 1024; // 262144 bytes
        const sectorSize = 512;
        final plaintextDataArea = _syntheticFat32DataArea();
        final masterKeyData = Uint8List.fromList(
          List<int>.generate(
            ToolboxVeraCryptHeaderCrypto.masterKeyDataSize,
            (index) => (index * 17 + 41) & 0xff,
          ),
        );

        // Encrypt the data area the way VeraCrypt would: with the absolute
        // data-unit base (customEncryptedAreaStart / sectorSize = 512).
        final encryptedDataArea = cryptoEngine.cryptDataUnits(
          input: plaintextDataArea,
          masterKeyData: masterKeyData,
          sectorSize: sectorSize,
          dataUnitStart: customEncryptedAreaStart ~/ sectorSize,
          encrypt: true,
        );

        final header = service.buildSyntheticAesXtsHeaderForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          encryptedAreaStart: customEncryptedAreaStart,
          volumeSize: plaintextDataArea.length,
          masterKeyData: masterKeyData,
          iterationOverrideForTesting: 1000,
        );
        final containerSize = math.max(
          ToolboxVeraCryptService.minContainerBytes,
          customEncryptedAreaStart + encryptedDataArea.length,
        );
        final container = Uint8List(containerSize)
          ..setRange(0, header.length, header)
          ..setRange(
            customEncryptedAreaStart,
            customEncryptedAreaStart + encryptedDataArea.length,
            encryptedDataArea,
          );

        final result = service.probeDataAreaBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );

        expect(result.success, isTrue);
        expect(result.dataOffset, customEncryptedAreaStart);
        // The probe must report the *absolute* data-unit base, not 0.
        expect(result.dataUnitStart, customEncryptedAreaStart ~/ sectorSize);
        expect(result.likelyFat32BootSector, isTrue);
        // The decrypted bytes must match the original plaintext, proving the
        // absolute-base convention round-trips correctly.
        expect(
          result.decryptedSha256,
          _hex(crypto.sha256.convert(plaintextDataArea).bytes),
        );
      },
    );

    test(
      'rejects unlocked sessions and probes when encrypted area exceeds file',
      () {
        final header = service.buildSyntheticAesXtsHeaderForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          encryptedAreaStart: ToolboxVeraCryptService.minContainerBytes,
          volumeSize: 4096,
          iterationOverrideForTesting: 1000,
        );
        final container = Uint8List(ToolboxVeraCryptService.minContainerBytes)
          ..setRange(0, header.length, header);

        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        expect(open.success, isFalse);
        expect(open.status, ToolboxVeraCryptSessionStatus.unsupportedMaterial);
        expect(open.session, isNull);
        expect(
          open.headerUnlockResult.notes,
          contains(
            'toolbox.crypto.veracrypt.note.data_probe_unsupported_layout',
          ),
        );

        final probe = service.probeDataAreaBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        expect(probe.success, isFalse);
        expect(probe.status, ToolboxVeraCryptDataProbeStatus.unsupportedLayout);
      },
    );

    test('reports data probe unlock failure for a wrong passphrase', () {
      final container = service.buildSyntheticAesXtsContainerForTesting(
        passphrase: 'correct horse',
        kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
        plaintextDataArea: _syntheticFat32DataArea(),
        iterationOverrideForTesting: 1000,
      );

      final result = service.probeDataAreaBytes(
        containerBytes: container,
        passphrase: 'wrong horse',
        iterationOverrideForTesting: 1000,
      );

      expect(result.success, isFalse);
      expect(result.status, ToolboxVeraCryptDataProbeStatus.unlockFailed);
      expect(
        result.headerUnlockResult.status,
        ToolboxVeraCryptHeaderUnlockStatus.failed,
      );
    });

    test(
      'rejects unlocked data probe when the encrypted area is too short',
      () {
        final header = service.buildSyntheticAesXtsHeaderForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          volumeSize: 128,
          iterationOverrideForTesting: 1000,
        );
        final container = Uint8List(ToolboxVeraCryptService.minContainerBytes)
          ..setRange(0, header.length, header);

        final result = service.probeDataAreaBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );

        expect(result.success, isFalse);
        expect(result.headerUnlockResult.success, isTrue);
        expect(
          result.status,
          ToolboxVeraCryptDataProbeStatus.unsupportedLayout,
        );
        expect(
          result.notes,
          contains(
            'toolbox.crypto.veracrypt.note.data_probe_unsupported_layout',
          ),
        );
      },
    );

    test('rejects header unlock when primary header is incomplete', () {
      final result = service.attemptHeaderUnlockBytes(
        headerBytes: Uint8List(200),
        passphrase: 'passphrase',
      );

      expect(result.status, ToolboxVeraCryptHeaderUnlockStatus.missingHeader);
      expect(result.attemptedKdfs, isEmpty);
    });

    test('creates an encrypted FAT container with a root file', () async {
      final payload = Uint8List.fromList(
        utf8.encode('created container payload'),
      );
      final secondPayload = Uint8List.fromList(utf8.encode('second file'));
      final created = service.createContainerBytes(
        passphrase: 'create me',
        files: <ToolboxVeraCryptCreateFileInput>[
          ToolboxVeraCryptCreateFileInput(name: 'hello.txt', bytes: payload),
          ToolboxVeraCryptCreateFileInput(
            name: 'notes.md',
            bytes: secondPayload,
          ),
        ],
        iterationOverrideForTesting: 1000,
      );

      expect(created.fatType, ToolboxVeraCryptFatType.fat12);
      expect(
        created.files.map((file) => file.storedName),
        containsAll(<String>['HELLO.TXT', 'NOTES.MD']),
      );
      expect(created.containerBytes.length, created.containerSize);
      final backupOffset =
          created.containerBytes.length -
          ToolboxVeraCryptService.backupHeaderAreaSize;
      final primaryHeader = Uint8List.sublistView(
        created.containerBytes,
        0,
        ToolboxVeraCryptService.headerSize,
      );
      final backupHeader = Uint8List.sublistView(
        created.containerBytes,
        backupOffset,
        backupOffset + ToolboxVeraCryptService.headerSize,
      );
      expect(backupHeader, isNot(equals(primaryHeader)));
      expect(
        _anyNonZeroRange(
          created.containerBytes,
          ToolboxVeraCryptService.headerSize,
          ToolboxVeraCryptService.dataAreaOffset,
        ),
        isTrue,
      );
      expect(
        _anyNonZeroRange(
          created.containerBytes,
          backupOffset + ToolboxVeraCryptService.headerSize,
          created.containerBytes.length,
        ),
        isTrue,
      );
      expect(_indexOfBytes(created.containerBytes, payload), -1);
      expect(_indexOfBytes(created.containerBytes, secondPayload), -1);
      final inspection = service.inspectBytes(
        bytes: created.containerBytes,
        fileName: 'created.hc',
      );
      expect(inspection.hasPrimaryHeader, isTrue);
      expect(inspection.hasBackupHeader, isTrue);

      final open = service.openSessionFromBytes(
        containerBytes: created.containerBytes,
        passphrase: 'create me',
        iterationOverrideForTesting: 1000,
      );
      expect(open.success, isTrue);
      final session = open.session!;
      addTearDown(session.close);
      final volume = await session.openFat32Volume();
      final root = await volume.listDirectory(dirCluster: volume.rootCluster);
      final hello = root.entries.firstWhere(
        (entry) => entry.displayName == 'HELLO.TXT',
      );
      final notes = root.entries.firstWhere(
        (entry) => entry.displayName == 'NOTES.MD',
      );
      expect((await volume.readFile(entry: hello)).bytes, payload);
      expect((await volume.readFile(entry: notes)).bytes, secondPayload);

      final wrong = service.openSessionFromBytes(
        containerBytes: created.containerBytes,
        passphrase: 'wrong',
        iterationOverrideForTesting: 1000,
      );
      expect(wrong.success, isFalse);

      final corruptedPrimary = Uint8List.fromList(created.containerBytes);
      for (var index = 0; index < ToolboxVeraCryptService.headerSize; index++) {
        corruptedPrimary[index] ^= 0xa5;
      }
      final backupOpen = service.openSessionFromBytes(
        containerBytes: corruptedPrimary,
        passphrase: 'create me',
        iterationOverrideForTesting: 1000,
      );
      expect(backupOpen.success, isTrue);
      expect(
        backupOpen.headerUnlockResult.headerWindowKind,
        ToolboxVeraCryptHeaderWindowKind.backup,
      );
      addTearDown(backupOpen.session!.close);
    });

    test(
      'creates larger root-file containers with wider FAT clusters',
      () async {
        final payload = Uint8List(33 * 1024 * 1024 + 1);
        payload[0] = 0x41;
        payload[payload.length - 1] = 0x5a;

        final created = service.createContainerBytes(
          passphrase: 'large create',
          files: <ToolboxVeraCryptCreateFileInput>[
            ToolboxVeraCryptCreateFileInput(name: 'large.bin', bytes: payload),
          ],
          iterationOverrideForTesting: 1000,
        );

        expect(created.fatType, ToolboxVeraCryptFatType.fat16);
        final open = service.openSessionFromBytes(
          containerBytes: created.containerBytes,
          passphrase: 'large create',
          iterationOverrideForTesting: 1000,
        );
        expect(open.success, isTrue);
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();
        expect(volume.fatType, ToolboxVeraCryptFatType.fat16);
        expect(volume.sectorsPerCluster, greaterThan(1));
        final root = await volume.listDirectory(dirCluster: volume.rootCluster);
        final large = root.entries.singleWhere(
          (entry) => entry.displayName == 'LARGE.BIN',
        );
        expect(large.size, payload.length);
      },
    );

    test('keeps system mount out of the support matrix', () {
      expect(
        ToolboxVeraCryptService.supportMatrix.any(
          (feature) => feature.labelKey.contains('system_mount'),
        ),
        isFalse,
      );
      expect(
        ToolboxVeraCryptService.supportMatrix.map(
          (feature) => feature.labelKey,
        ),
        containsAll(<String>[
          'toolbox.crypto.veracrypt.support.feature.cipher_chains',
          'toolbox.crypto.veracrypt.support.feature.kdf_primary',
        ]),
      );
      expect(
        ToolboxVeraCryptService.supportMatrix.any(
          (feature) => feature.labelKey.endsWith('.cipher_core_gaps'),
        ),
        isFalse,
      );
      expect(
        ToolboxVeraCryptService.supportMatrix.any(
          (feature) => feature.labelKey.endsWith('.kdf_core_gaps'),
        ),
        isFalse,
      );
    });

    test(
      'falls back to the standard backup header when the primary is corrupted',
      () {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        // Corrupt the primary header salt + encrypted area so the primary
        // unlock returns `failed` (CRC/magic will not validate). The standard
        // backup header lives at fileSize - backupHeaderAreaSize; this is a
        // fresh 512-byte header copy that VeraCrypt writes and our builder
        // does NOT emit, so we synthesize one here from the same parameters.
        for (var i = 0; i < ToolboxVeraCryptService.headerSize; i += 1) {
          container[i] = container[i] ^ 0xa5;
        }
        final backupOffset =
            container.length - ToolboxVeraCryptService.backupHeaderAreaSize;
        final backupHeader = service.buildSyntheticAesXtsHeaderForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          volumeSize: plaintextDataArea.length,
          encryptedAreaStart: ToolboxVeraCryptService.dataAreaOffset,
          iterationOverrideForTesting: 1000,
        );
        container.setRange(
          backupOffset,
          backupOffset + backupHeader.length,
          backupHeader,
        );

        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );

        // Primary unlock failed, so the service retries the backup header and
        // must succeed.
        expect(open.success, isTrue);
        expect(open.status, ToolboxVeraCryptSessionStatus.success);
        expect(open.session, isNotNull);
        expect(
          open.headerUnlockResult.headerWindowKind,
          ToolboxVeraCryptHeaderWindowKind.backup,
        );
        expect(
          open.headerUnlockResult.notes,
          contains('toolbox.crypto.veracrypt.note.header_unlock_via_backup'),
        );
      },
    );

    group('FAT browse session', () {
      test('opens a session and lists the FAT32 root directory', () async {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        expect(open.success, isTrue);
        expect(open.status, ToolboxVeraCryptSessionStatus.success);
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();
        expect(volume.bytesPerSector, 512);
        expect(volume.sectorsPerCluster, 1);
        expect(volume.rootCluster, 2);
        final root = await volume.listDirectory(dirCluster: volume.rootCluster);
        final names = root.entries.map((e) => e.displayName).toSet();
        expect(names, contains('README.TXT'));
        expect(names, contains('DOCS'));
      });

      test(
        'opens a FAT12 session and lists the fixed root directory',
        () async {
          final plaintextDataArea = _syntheticFat12DataAreaWithFiles();
          final container = service.buildSyntheticAesXtsContainerForTesting(
            passphrase: 'correct horse',
            kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
            plaintextDataArea: plaintextDataArea,
            iterationOverrideForTesting: 1000,
          );
          final open = service.openSessionFromBytes(
            containerBytes: container,
            passphrase: 'correct horse',
            iterationOverrideForTesting: 1000,
          );
          final session = open.session!;
          addTearDown(session.close);
          final volume = await session.openFat32Volume();
          expect(volume.fatType, ToolboxVeraCryptFatType.fat12);
          expect(volume.rootCluster, 0);
          final root = await volume.listDirectory(
            dirCluster: volume.rootCluster,
          );
          final names = root.entries.map((e) => e.displayName).toSet();
          expect(names, contains('ROOT.TXT'));
        },
      );

      test('reads and overwrites a FAT12 root file without resizing', () async {
        final plaintextDataArea = _syntheticFat12DataAreaWithFiles();
        final expectedPayload = _syntheticFat12FilePayload();
        final replacement = Uint8List.fromList(
          List<int>.generate(
            expectedPayload.length,
            (index) => 0x30 + (index % 10),
          ),
        );
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
          writable: true,
        );
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();
        final root = await volume.listDirectory(dirCluster: volume.rootCluster);
        final rootFile = root.entries.firstWhere(
          (e) => e.displayName == 'ROOT.TXT',
        );
        expect((await volume.readFile(entry: rootFile)).bytes, expectedPayload);

        final write = await volume.overwriteFileSameSize(
          entry: rootFile,
          bytes: replacement,
        );
        expect(write.bytesWritten, replacement.length);
        expect(write.clustersTouched, 1);
        expect((await volume.readFile(entry: rootFile)).bytes, replacement);
      });

      test('reads a single file back to its plaintext bytes', () async {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
        final expectedPayload = _syntheticFat32FilePayload();
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();
        final root = await volume.listDirectory(dirCluster: volume.rootCluster);
        final readme = root.entries.firstWhere(
          (e) => e.displayName == 'README.TXT',
        );
        final result = await volume.readFile(entry: readme);
        expect(result.bytes, equals(expectedPayload));
        expect(result.truncated, isFalse);
      });

      test('recurses into a subdirectory and lists its entries', () async {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();
        final root = await volume.listDirectory(dirCluster: volume.rootCluster);
        final docs = root.entries.firstWhere((e) => e.displayName == 'DOCS');
        expect(docs.isDirectory, isTrue);
        final inner = await volume.listDirectory(dirCluster: docs.firstCluster);
        final names = inner.entries.map((e) => e.displayName).toSet();
        expect(names, contains('NOTE.TXT'));
      });

      test('fails to open a session with a wrong passphrase', () {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'wrong passphrase',
          iterationOverrideForTesting: 1000,
        );
        expect(open.success, isFalse);
        expect(open.status, ToolboxVeraCryptSessionStatus.unlockFailed);
        expect(open.session, isNull);
      });

      test('rejects a FAT with a cyclic cluster chain', () async {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles(
          cyclicChain: true,
        );
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();
        final root = await volume.listDirectory(dirCluster: volume.rootCluster);
        final readme = root.entries.firstWhere(
          (e) => e.displayName == 'README.TXT',
        );
        expect(
          () => volume.readFile(entry: readme),
          throwsA(isA<ToolboxVeraCryptFat32Exception>()),
        );
      });

      test('bounds directory cluster-chain bytes before allocation', () async {
        final plaintextDataArea = _syntheticFat32OversizedDirectoryDataArea();
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();

        await expectLater(
          () => volume.listDirectory(dirCluster: volume.rootCluster),
          throwsA(
            isA<ToolboxVeraCryptFat32Exception>().having(
              (e) => e.code,
              'code',
              ToolboxVeraCryptFat32ErrorCode.directoryTooLarge,
            ),
          ),
        );
      });

      test('reconstructs long file names from LFN entries', () async {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles(
          longNames: true,
        );
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();
        final root = await volume.listDirectory(dirCluster: volume.rootCluster);
        final readme = root.entries.firstWhere((e) => e.name == 'README.TXT');
        expect(readme.longName, 'read me notes.txt');
        expect(readme.displayName, 'read me notes.txt');
      });

      test(
        'overwrites an existing file through encrypted data-area writes',
        () async {
          final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
          final originalPayload = _syntheticFat32FilePayload();
          final replacement = Uint8List.fromList(
            List<int>.generate(
              originalPayload.length,
              (index) => 0x41 + (index % 26),
            ),
          );
          final container = service.buildSyntheticAesXtsContainerForTesting(
            passphrase: 'correct horse',
            kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
            plaintextDataArea: plaintextDataArea,
            iterationOverrideForTesting: 1000,
          );
          final encryptedClusterOffset =
              ToolboxVeraCryptService.dataAreaOffset + _clusterToOffset(3);
          final encryptedBefore = Uint8List.fromList(
            container.sublist(
              encryptedClusterOffset,
              encryptedClusterOffset + _fat32BytesPerCluster,
            ),
          );

          final open = service.openSessionFromBytes(
            containerBytes: container,
            passphrase: 'correct horse',
            iterationOverrideForTesting: 1000,
            writable: true,
          );
          final session = open.session!;
          addTearDown(session.close);
          expect(session.isWritable, isTrue);
          final volume = await session.openFat32Volume();
          final root = await volume.listDirectory(
            dirCluster: volume.rootCluster,
          );
          final readme = root.entries.firstWhere(
            (e) => e.displayName == 'README.TXT',
          );
          expect((await volume.readFile(entry: readme)).bytes, originalPayload);

          final write = await volume.overwriteFileSameSize(
            entry: readme,
            bytes: replacement,
          );
          expect(write.bytesWritten, replacement.length);
          expect(write.clustersTouched, 1);
          expect((await volume.readFile(entry: readme)).bytes, replacement);

          final encryptedAfter = Uint8List.fromList(
            container.sublist(
              encryptedClusterOffset,
              encryptedClusterOffset + _fat32BytesPerCluster,
            ),
          );
          expect(encryptedAfter, isNot(encryptedBefore));

          await session.close();
          final reopened = service.openSessionFromBytes(
            containerBytes: container,
            passphrase: 'correct horse',
            iterationOverrideForTesting: 1000,
          );
          final readOnlySession = reopened.session!;
          addTearDown(readOnlySession.close);
          final reopenedVolume = await readOnlySession.openFat32Volume();
          final reopenedRoot = await reopenedVolume.listDirectory(
            dirCluster: reopenedVolume.rootCluster,
          );
          final reopenedReadme = reopenedRoot.entries.firstWhere(
            (e) => e.displayName == 'README.TXT',
          );
          expect(
            (await reopenedVolume.readFile(entry: reopenedReadme)).bytes,
            replacement,
          );
        },
      );

      test('rejects writes from a read-only unlocked session', () async {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        final session = open.session!;
        addTearDown(session.close);
        expect(session.isWritable, isFalse);
        await expectLater(
          () => session.writeDataAreaBytes(
            offsetInDataArea: _clusterToOffset(3),
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
          ),
          throwsA(isA<StateError>()),
        );
      });

      test('rejects same-file overwrite when the size would change', () async {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
          writable: true,
        );
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();
        final root = await volume.listDirectory(dirCluster: volume.rootCluster);
        final readme = root.entries.firstWhere(
          (e) => e.displayName == 'README.TXT',
        );

        await expectLater(
          () => volume.overwriteFileSameSize(
            entry: readme,
            bytes: Uint8List(readme.size + 1),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test(
        'writes through a seekable file session without truncating the container',
        () async {
          final directory = await Directory.systemTemp.createTemp(
            'toolbox_veracrypt_write_',
          );
          addTearDown(() async {
            if (await directory.exists()) {
              await directory.delete(recursive: true);
            }
          });
          final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
          final originalPayload = _syntheticFat32FilePayload();
          final replacement = Uint8List.fromList(
            List<int>.generate(
              originalPayload.length,
              (index) => 0x7a - (index % 26),
            ),
          );
          final container = service.buildSyntheticAesXtsContainerForTesting(
            passphrase: 'correct horse',
            kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
            plaintextDataArea: plaintextDataArea,
            iterationOverrideForTesting: 1000,
          );
          final file = File('${directory.path}/writable.hc');
          await file.writeAsBytes(container, flush: true);
          final originalLength = await file.length();

          final open = await service.openSession(
            file: file,
            passphrase: 'correct horse',
            iterationOverrideForTesting: 1000,
            writable: true,
          );
          final session = open.session!;
          addTearDown(session.close);
          final volume = await session.openFat32Volume();
          final root = await volume.listDirectory(
            dirCluster: volume.rootCluster,
          );
          final readme = root.entries.firstWhere(
            (e) => e.displayName == 'README.TXT',
          );
          await volume.overwriteFileSameSize(entry: readme, bytes: replacement);
          await session.close();
          expect(await file.length(), originalLength);

          final reopened = await service.openSession(
            file: file,
            passphrase: 'correct horse',
            iterationOverrideForTesting: 1000,
          );
          final readOnlySession = reopened.session!;
          addTearDown(readOnlySession.close);
          final reopenedVolume = await readOnlySession.openFat32Volume();
          final reopenedRoot = await reopenedVolume.listDirectory(
            dirCluster: reopenedVolume.rootCluster,
          );
          final reopenedReadme = reopenedRoot.entries.firstWhere(
            (e) => e.displayName == 'README.TXT',
          );
          expect(
            (await reopenedVolume.readFile(entry: reopenedReadme)).bytes,
            replacement,
          );
        },
      );

      test(
        'rejects a BPB whose total sectors exceed the unlocked data area',
        () async {
          final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
          final tooLarge = _fat32TotalSectors + 1;
          plaintextDataArea[32] = tooLarge & 0xff;
          plaintextDataArea[33] = (tooLarge >> 8) & 0xff;
          plaintextDataArea[34] = (tooLarge >> 16) & 0xff;
          plaintextDataArea[35] = (tooLarge >> 24) & 0xff;
          final container = service.buildSyntheticAesXtsContainerForTesting(
            passphrase: 'correct horse',
            kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
            plaintextDataArea: plaintextDataArea,
            iterationOverrideForTesting: 1000,
          );
          final open = service.openSessionFromBytes(
            containerBytes: container,
            passphrase: 'correct horse',
            iterationOverrideForTesting: 1000,
          );
          final session = open.session!;
          addTearDown(session.close);

          await expectLater(
            session.openFat32Volume,
            throwsA(
              isA<ToolboxVeraCryptFat32Exception>().having(
                (e) => e.code,
                'code',
                ToolboxVeraCryptFat32ErrorCode.implausibleBpb,
              ),
            ),
          );
        },
      );

      test('close zeroes the session and rejects further reads', () async {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        final session = open.session!;
        await session.close();
        expect(session.isClosed, isTrue);
        expect(
          () => session.readDataAreaBytes(offsetInDataArea: 0, length: 512),
          throwsA(isA<StateError>()),
        );
      });

      test('reads a zero-length file as empty bytes', () async {
        final plaintextDataArea = _syntheticFat32DataAreaWithFiles(
          zeroLengthFile: true,
        );
        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();
        final root = await volume.listDirectory(dirCluster: volume.rootCluster);
        final empty = root.entries.firstWhere(
          (e) => e.displayName == 'EMPTY.TXT',
        );
        expect(empty.size, 0);
        // A zero-length file must short-circuit and return empty bytes rather
        // than treating firstCluster=0 as an out-of-range error.
        final result = await volume.readFile(entry: empty);
        expect(result.bytes, isEmpty);
        expect(result.truncated, isFalse);
      });

      test(
        'reports a bad-cluster marker (0x0FFFFFF7) as a distinct error',
        () async {
          final plaintextDataArea = _syntheticFat32DataAreaWithFiles(
            badCluster: true,
          );
          final container = service.buildSyntheticAesXtsContainerForTesting(
            passphrase: 'correct horse',
            kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
            plaintextDataArea: plaintextDataArea,
            iterationOverrideForTesting: 1000,
          );
          final open = service.openSessionFromBytes(
            containerBytes: container,
            passphrase: 'correct horse',
            iterationOverrideForTesting: 1000,
          );
          final session = open.session!;
          addTearDown(session.close);
          final volume = await session.openFat32Volume();
          final root = await volume.listDirectory(
            dirCluster: volume.rootCluster,
          );
          final readme = root.entries.firstWhere(
            (e) => e.displayName == 'README.TXT',
          );
          // The bad-cluster sentinel must surface as badCluster, NOT the
          // pre-fix fatChainCycle misclassification.
          await expectLater(
            () => volume.readFile(entry: readme),
            throwsA(
              isA<ToolboxVeraCryptFat32Exception>().having(
                (e) => e.code,
                'code',
                ToolboxVeraCryptFat32ErrorCode.badCluster,
              ),
            ),
          );
        },
      );

      test('applies the NT lowercase case-info flag to 8.3 names', () async {
        final plaintextDataArea = Uint8List(
          _fat32TotalSectors * _fat32BytesPerSector,
        );
        _writeFat32BootSector(plaintextDataArea);
        _setFat32Entry(plaintextDataArea, 0, 0x0ffffff8);
        _setFat32Entry(plaintextDataArea, 1, 0x0fffffff);
        _setFat32Entry(plaintextDataArea, 2, 0x0fffffff);
        // Mirror into FAT #1.
        for (var cluster = 0; cluster <= 2; cluster++) {
          final base = _fat32ReservedSectors * _fat32BytesPerSector;
          final value =
              plaintextDataArea[base + cluster * 4] |
              (plaintextDataArea[base + cluster * 4 + 1] << 8) |
              (plaintextDataArea[base + cluster * 4 + 2] << 16) |
              (plaintextDataArea[base + cluster * 4 + 3] << 24);
          final mirror = base + _fat32BytesPerSector + cluster * 4;
          plaintextDataArea[mirror] = value & 0xff;
          plaintextDataArea[mirror + 1] = (value >> 8) & 0xff;
          plaintextDataArea[mirror + 2] = (value >> 16) & 0xff;
          plaintextDataArea[mirror + 3] = (value >> 24) & 0xff;
        }
        // Root dir: one short-only entry "lower.TXT" with both base + ext
        // lowercase flags set (0x08 | 0x10 = 0x18), no LFN.
        final rootOffset = _clusterToOffset(2);
        _writeShortDirEntry(
          plaintextDataArea,
          rootOffset,
          'LOWER',
          'TXT',
          0x20,
          0,
          0,
          ntCase: 0x18,
        );
        plaintextDataArea[rootOffset + 32] = 0x00;

        final container = service.buildSyntheticAesXtsContainerForTesting(
          passphrase: 'correct horse',
          kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
          plaintextDataArea: plaintextDataArea,
          iterationOverrideForTesting: 1000,
        );
        final open = service.openSessionFromBytes(
          containerBytes: container,
          passphrase: 'correct horse',
          iterationOverrideForTesting: 1000,
        );
        final session = open.session!;
        addTearDown(session.close);
        final volume = await session.openFat32Volume();
        final root = await volume.listDirectory(dirCluster: volume.rootCluster);
        final entry = root.entries.single;
        // Without the NT flag the parser returned "LOWER.TXT"; with 0x18 it
        // must render as the lowercase form.
        expect(entry.name, 'lower.txt');
        expect(entry.displayName, 'lower.txt');
      });

      test(
        'discards LFN slots whose checksum does not match the short entry',
        () async {
          final plaintextDataArea = _syntheticFat32DataAreaWithFiles();
          // Append a stray LFN sequence with a deliberately wrong checksum right
          // before a fresh short entry, simulating leftover LFN slots that were
          // not cleaned up. The parser must drop them and fall back to the short
          // name rather than emitting a contaminated long name.
          final docsOffset = _clusterToOffset(4);
          // NOTE.TXT short entry currently lives at docsOffset + 64. Move the
          // end-of-directory marker and insert a second short entry with orphan
          // LFN slots after it.
          final orphanOffset = docsOffset + 96; // first free slot in docs dir
          _writeLfnEntries(
            plaintextDataArea,
            orphanOffset,
            'poisoned wrong.txt',
            _lfnChecksum('NOTE     TXT') ^ 0xff, // intentionally wrong checksum
          );
          _writeShortDirEntry(
            plaintextDataArea,
            orphanOffset + 32,
            'OTHER',
            'TXT',
            0x20,
            5,
            _syntheticFat32NotePayload().length,
          );
          plaintextDataArea[orphanOffset + 64] = 0x00;

          final container = service.buildSyntheticAesXtsContainerForTesting(
            passphrase: 'correct horse',
            kdf: ToolboxVeraCryptKdf.pbkdf2Sha512,
            plaintextDataArea: plaintextDataArea,
            iterationOverrideForTesting: 1000,
          );
          final open = service.openSessionFromBytes(
            containerBytes: container,
            passphrase: 'correct horse',
            iterationOverrideForTesting: 1000,
          );
          final session = open.session!;
          addTearDown(session.close);
          final volume = await session.openFat32Volume();
          final docs = await volume.listDirectory(
            dirCluster: volume.rootCluster == 2 ? 4 : 4,
          );
          final other = docs.entries.firstWhere((e) => e.name == 'OTHER.TXT');
          // The orphaned LFN sequence (checksum mismatch) must NOT leak into the
          // short entry's longName.
          expect(other.longName, isEmpty);
          expect(other.displayName, 'OTHER.TXT');
        },
      );
    });
  });
}

Uint8List _syntheticFat32DataArea() {
  final bytes = Uint8List(4096);
  bytes[0] = 0xeb;
  bytes[1] = 0x58;
  bytes[2] = 0x90;
  const oem = <int>[77, 83, 68, 79, 83, 53, 46, 48];
  bytes.setRange(3, 11, oem);
  bytes[11] = 0x00;
  bytes[12] = 0x02;
  bytes[13] = 0x08;
  bytes[14] = 0x20;
  bytes[16] = 0x02;
  const fat32 = <int>[70, 65, 84, 51, 50, 32, 32, 32];
  bytes.setRange(82, 90, fat32);
  for (var index = 90; index < bytes.length - 2; index += 1) {
    bytes[index] = (index * 29 + 7) & 0xff;
  }
  bytes[510] = 0x55;
  bytes[511] = 0xaa;
  return bytes;
}

String _hex(List<int> bytes) {
  final buffer = StringBuffer();
  for (final byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

Uint8List _hexToBytes(String hex) {
  final bytes = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < bytes.length; i += 1) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

Uint8List _reverseBytes(Uint8List bytes) {
  return Uint8List.fromList(bytes.reversed.toList());
}

int _indexOfBytes(List<int> haystack, List<int> needle) {
  if (needle.isEmpty || haystack.length < needle.length) {
    return -1;
  }
  for (var start = 0; start <= haystack.length - needle.length; start += 1) {
    var matches = true;
    for (var offset = 0; offset < needle.length; offset += 1) {
      if (haystack[start + offset] != needle[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return start;
    }
  }
  return -1;
}

bool _anyNonZeroRange(Uint8List bytes, int start, int end) {
  for (var index = start; index < end; index += 1) {
    if (bytes[index] != 0) {
      return true;
    }
  }
  return false;
}

// === FAT32 synthetic data-area builders (PLAN_349) ===
//
// Builds a small but real FAT32 image as the encrypted data-area plaintext,
// so the VeraCrypt session + FAT32 volume parser can be exercised end-to-end
// without a real .hc container.
//
// Layout (bytesPerSector=512, sectorsPerCluster=1):
//   sector 0      : FAT32 boot sector (BPB)
//   sectors 1..31 : reserved (zeroed)
//   sector 32     : FAT #0 (1 sector, 128 entries)
//   sector 33     : FAT #1 (mirror, 1 sector)
//   sector 34     : cluster 2 -> root directory (README.TXT, docs/)
//   sector 35     : cluster 3 -> README.TXT file payload
//   sector 36     : cluster 4 -> docs/ directory (NOTE.TXT, plus "."/"..")
//   sector 37     : cluster 5 -> NOTE.TXT file payload
// Total: 64 sectors = 32768 bytes.

const int _fat32BytesPerSector = 512;
const int _fat32SectorsPerCluster = 1;
const int _fat32ReservedSectors = 32;
const int _fat32NumFats = 2;
const int _fat32SectorsPerFat = 1;
const int _fat32RootCluster = 2;
const int _fat32TotalSectors = 64;
const int _fat32ClusterRegionStart =
    (_fat32ReservedSectors + _fat32NumFats * _fat32SectorsPerFat) *
    _fat32BytesPerSector;
const int _fat32BytesPerCluster =
    _fat32BytesPerSector * _fat32SectorsPerCluster;

const int _fat12BytesPerSector = 512;
const int _fat12SectorsPerCluster = 1;
const int _fat12ReservedSectors = 1;
const int _fat12NumFats = 2;
const int _fat12RootEntryCount = 512;
const int _fat12SectorsPerFat = 5;
const int _fat12TotalSectors = 1536;
const int _fat12RootDirectorySectors =
    ((_fat12RootEntryCount * 32) + _fat12BytesPerSector - 1) ~/
    _fat12BytesPerSector;
const int _fat12RootDirectoryStart =
    (_fat12ReservedSectors + _fat12NumFats * _fat12SectorsPerFat) *
    _fat12BytesPerSector;
const int _fat12ClusterRegionStart =
    (_fat12ReservedSectors +
        _fat12NumFats * _fat12SectorsPerFat +
        _fat12RootDirectorySectors) *
    _fat12BytesPerSector;
const int _fat12BytesPerCluster =
    _fat12BytesPerSector * _fat12SectorsPerCluster;

Uint8List _syntheticFat32FilePayload() {
  // A short, recognizable, deterministic payload.
  final text = 'VeraCrypt FAT32 probe payload';
  return Uint8List.fromList(utf8.encode(text));
}

Uint8List _syntheticFat12FilePayload() {
  return Uint8List.fromList(utf8.encode('FAT12 hello!'));
}

Uint8List _syntheticFat32NotePayload() {
  return Uint8List.fromList(utf8.encode('nested note'));
}

Uint8List _syntheticFat12DataAreaWithFiles() {
  final bytes = Uint8List(_fat12TotalSectors * _fat12BytesPerSector);
  _writeFat12BootSector(bytes);
  for (var fat = 0; fat < _fat12NumFats; fat += 1) {
    final fatOffset =
        (_fat12ReservedSectors + fat * _fat12SectorsPerFat) *
        _fat12BytesPerSector;
    bytes[fatOffset] = 0xf8;
    bytes[fatOffset + 1] = 0xff;
    bytes[fatOffset + 2] = 0xff;
    _setFat12Entry(bytes, fatOffset: fatOffset, cluster: 2, value: 0x0fff);
  }
  final payload = _syntheticFat12FilePayload();
  _writeShortDirEntry(
    bytes,
    _fat12RootDirectoryStart,
    'ROOT',
    'TXT',
    0x20,
    2,
    payload.length,
  );
  bytes.setRange(
    _fat12ClusterToOffset(2),
    _fat12ClusterToOffset(2) + payload.length,
    payload,
  );
  return bytes;
}

void _writeFat32BootSector(Uint8List bytes) {
  bytes[0] = 0xeb;
  bytes[1] = 0x58;
  bytes[2] = 0x90;
  const oem = 'MSWIN4.1';
  for (var i = 0; i < oem.length; i++) {
    bytes[3 + i] = oem.codeUnitAt(i);
  }
  // bytesPerSector (LE u16 @ 11)
  bytes[11] = _fat32BytesPerSector & 0xff;
  bytes[12] = (_fat32BytesPerSector >> 8) & 0xff;
  // sectorsPerCluster (@ 13)
  bytes[13] = _fat32SectorsPerCluster;
  // reservedSectors (LE u16 @ 14)
  bytes[14] = _fat32ReservedSectors & 0xff;
  bytes[15] = (_fat32ReservedSectors >> 8) & 0xff;
  // numFats (@ 16)
  bytes[16] = _fat32NumFats;
  // rootEntries16 (@ 17..19) = 0 for FAT32
  bytes[17] = 0;
  bytes[18] = 0;
  // totalSectors16 (@ 19..21) = 0 -> use 32-bit field
  bytes[19] = 0;
  bytes[20] = 0;
  // media descriptor (@ 21)
  bytes[21] = 0xf8;
  // sectorsPerFat16 (@ 22..24) = 0 for FAT32
  bytes[22] = 0;
  bytes[23] = 0;
  // sectorsPerTrack (@ 24..26)
  bytes[24] = 1;
  bytes[25] = 0;
  // numHeads (@ 26..28)
  bytes[26] = 1;
  bytes[27] = 0;
  // hiddenSectors (@ 28..32) = 0
  // totalSectors32 (@ 32..36)
  bytes[32] = _fat32TotalSectors & 0xff;
  bytes[33] = (_fat32TotalSectors >> 8) & 0xff;
  bytes[34] = (_fat32TotalSectors >> 16) & 0xff;
  bytes[35] = (_fat32TotalSectors >> 24) & 0xff;
  // sectorsPerFat32 (@ 36..40)
  bytes[36] = _fat32SectorsPerFat & 0xff;
  bytes[37] = (_fat32SectorsPerFat >> 8) & 0xff;
  bytes[38] = (_fat32SectorsPerFat >> 16) & 0xff;
  bytes[39] = (_fat32SectorsPerFat >> 24) & 0xff;
  // flags (@ 40..44) = 0
  // rootCluster (@ 44..48)
  bytes[44] = _fat32RootCluster & 0xff;
  bytes[45] = (_fat32RootCluster >> 8) & 0xff;
  bytes[46] = (_fat32RootCluster >> 16) & 0xff;
  bytes[47] = (_fat32RootCluster >> 24) & 0xff;
  // fsinfo (@ 48..52) = 1
  bytes[48] = 1;
  // backupBootSector (@ 52..56) = 6
  bytes[52] = 6;
  // FS-type label "FAT32   " @ 82..90
  const fat32Label = [70, 65, 84, 51, 50, 32, 32, 32]; // "FAT32   "
  for (var i = 0; i < fat32Label.length; i++) {
    bytes[82 + i] = fat32Label[i];
  }
  // boot signature
  bytes[510] = 0x55;
  bytes[511] = 0xaa;
}

void _writeFat12BootSector(Uint8List bytes) {
  bytes[0] = 0xeb;
  bytes[1] = 0x3c;
  bytes[2] = 0x90;
  const oem = 'MSDOS5.0';
  for (var i = 0; i < oem.length; i++) {
    bytes[3 + i] = oem.codeUnitAt(i);
  }
  bytes[11] = _fat12BytesPerSector & 0xff;
  bytes[12] = (_fat12BytesPerSector >> 8) & 0xff;
  bytes[13] = _fat12SectorsPerCluster;
  bytes[14] = _fat12ReservedSectors & 0xff;
  bytes[15] = (_fat12ReservedSectors >> 8) & 0xff;
  bytes[16] = _fat12NumFats;
  bytes[17] = _fat12RootEntryCount & 0xff;
  bytes[18] = (_fat12RootEntryCount >> 8) & 0xff;
  bytes[19] = _fat12TotalSectors & 0xff;
  bytes[20] = (_fat12TotalSectors >> 8) & 0xff;
  bytes[21] = 0xf8;
  bytes[22] = _fat12SectorsPerFat & 0xff;
  bytes[23] = (_fat12SectorsPerFat >> 8) & 0xff;
  bytes[24] = 1;
  bytes[26] = 1;
  bytes[38] = 0x29;
  const label = 'NO NAME    ';
  for (var i = 0; i < label.length; i++) {
    bytes[43 + i] = label.codeUnitAt(i);
  }
  const fat12Label = 'FAT12   ';
  for (var i = 0; i < fat12Label.length; i++) {
    bytes[54 + i] = fat12Label.codeUnitAt(i);
  }
  bytes[510] = 0x55;
  bytes[511] = 0xaa;
}

void _setFat32Entry(Uint8List bytes, int cluster, int value) {
  final offset = _fat32ReservedSectors * _fat32BytesPerSector + cluster * 4;
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
  bytes[offset + 3] = (value >> 24) & 0xff;
}

void _setFat12Entry(
  Uint8List bytes, {
  required int fatOffset,
  required int cluster,
  required int value,
}) {
  final offset = fatOffset + cluster + (cluster ~/ 2);
  final current = bytes[offset] | (bytes[offset + 1] << 8);
  final packed = cluster.isEven
      ? (current & 0xf000) | (value & 0x0fff)
      : (current & 0x000f) | ((value & 0x0fff) << 4);
  bytes[offset] = packed & 0xff;
  bytes[offset + 1] = (packed >> 8) & 0xff;
}

int _clusterToOffset(int cluster) {
  return _fat32ClusterRegionStart + (cluster - 2) * _fat32BytesPerCluster;
}

int _fat12ClusterToOffset(int cluster) {
  return _fat12ClusterRegionStart + (cluster - 2) * _fat12BytesPerCluster;
}

void _writeShortDirEntry(
  Uint8List bytes,
  int offset,
  String name83,
  String ext,
  int attr,
  int firstCluster,
  int size, {
  int ntCase = 0,
}) {
  // Short name field is 11 bytes: 8 name + 3 ext, space-padded.
  final nameField = List<int>.filled(11, 0x20);
  final nameBytes = name83.codeUnits;
  for (var i = 0; i < nameBytes.length && i < 8; i++) {
    nameField[i] = nameBytes[i];
  }
  final extBytes = ext.codeUnits;
  for (var i = 0; i < extBytes.length && i < 3; i++) {
    nameField[8 + i] = extBytes[i];
  }
  for (var i = 0; i < 11; i++) {
    bytes[offset + i] = nameField[i];
  }
  bytes[offset + 11] = attr;
  // Offset +12 is the NT/reserved case-info byte: 0x08 base lowercased,
  // 0x10 extension lowercased. Used by the NT-lowercase test.
  bytes[offset + 12] = ntCase & 0xff;
  // createTime/date/access fields left zero
  bytes[offset + 20] = (firstCluster >> 16) & 0xff;
  bytes[offset + 21] = (firstCluster >> 24) & 0xff;
  bytes[offset + 26] = firstCluster & 0xff;
  bytes[offset + 27] = (firstCluster >> 8) & 0xff;
  bytes[offset + 28] = size & 0xff;
  bytes[offset + 29] = (size >> 8) & 0xff;
  bytes[offset + 30] = (size >> 16) & 0xff;
  bytes[offset + 31] = (size >> 24) & 0xff;
}

void _writeDotDotEntry(Uint8List bytes, int offset, int cluster, bool isDot) {
  final label = isDot ? '.' : '..';
  final nameField = List<int>.filled(11, 0x20);
  nameField[0] = label.codeUnitAt(0);
  if (!isDot) {
    nameField[1] = label.codeUnitAt(1);
  }
  for (var i = 0; i < 11; i++) {
    bytes[offset + i] = nameField[i];
  }
  bytes[offset + 11] = 0x10; // directory attribute
  if (cluster > 0) {
    bytes[offset + 20] = (cluster >> 16) & 0xff;
    bytes[offset + 21] = (cluster >> 24) & 0xff;
    bytes[offset + 26] = cluster & 0xff;
    bytes[offset + 27] = (cluster >> 8) & 0xff;
  }
}

Uint8List _syntheticFat32OversizedDirectoryDataArea() {
  const bytesPerSector = 4096;
  const sectorsPerCluster = 128;
  const reservedSectors = 1;
  const numFats = 1;
  const sectorsPerFat = 1;
  const rootCluster = 2;
  const clusterCount = 3;
  const totalSectors =
      reservedSectors +
      numFats * sectorsPerFat +
      clusterCount * sectorsPerCluster;
  final bytes = Uint8List(totalSectors * bytesPerSector);

  void writeLe16(int offset, int value) {
    bytes[offset] = value & 0xff;
    bytes[offset + 1] = (value >> 8) & 0xff;
  }

  void writeLe32(int offset, int value) {
    bytes[offset] = value & 0xff;
    bytes[offset + 1] = (value >> 8) & 0xff;
    bytes[offset + 2] = (value >> 16) & 0xff;
    bytes[offset + 3] = (value >> 24) & 0xff;
  }

  void setFat32Entry(int cluster, int value) {
    final offset = reservedSectors * bytesPerSector + cluster * 4;
    writeLe32(offset, value);
  }

  bytes[0] = 0xeb;
  bytes[1] = 0x58;
  bytes[2] = 0x90;
  const oem = 'MSWIN4.1';
  for (var i = 0; i < oem.length; i += 1) {
    bytes[3 + i] = oem.codeUnitAt(i);
  }
  writeLe16(11, bytesPerSector);
  bytes[13] = sectorsPerCluster;
  writeLe16(14, reservedSectors);
  bytes[16] = numFats;
  writeLe32(32, totalSectors);
  writeLe32(36, sectorsPerFat);
  writeLe32(44, rootCluster);
  const fat32Label = 'FAT32   ';
  for (var i = 0; i < fat32Label.length; i += 1) {
    bytes[82 + i] = fat32Label.codeUnitAt(i);
  }
  bytes[510] = 0x55;
  bytes[511] = 0xaa;

  setFat32Entry(0, 0x0ffffff8);
  setFat32Entry(1, 0x0fffffff);
  setFat32Entry(2, 3);
  setFat32Entry(3, 0x0fffffff);
  return bytes;
}

int _lfnChecksum(String shortName83) {
  // shortName83 must be the 11-byte 8.3 field (name+ext, space padded).
  var sum = 0;
  final padded = List<int>.filled(11, 0x20);
  final up = shortName83.toUpperCase();
  for (var i = 0; i < up.length && i < 11; i++) {
    padded[i] = up.codeUnitAt(i);
  }
  for (var i = 0; i < 11; i++) {
    sum = ((sum & 1) << 7) + (sum >> 1) + padded[i];
    sum = sum & 0xff;
  }
  return sum;
}

/// Writes LFN directory entries for [longName] immediately before the short
/// entry. Returns the number of 32-byte slots consumed.
int _writeLfnEntries(
  Uint8List bytes,
  int offset,
  String longName,
  int checksum,
) {
  final units = longName.codeUnits;
  // Pad with a terminating NUL then 0xffff fillers, FAT32 convention.
  final padded = <int>[...units, 0x0000];
  while (padded.length % 13 != 0) {
    padded.add(0xffff);
  }
  final chunkCount = padded.length ~/ 13;
  // Physical order: highest sequence first. Sequence values are 1-based.
  for (var chunk = chunkCount - 1; chunk >= 0; chunk--) {
    final physicalIndex = chunkCount - 1 - chunk;
    final entryOffset = offset + physicalIndex * 32;
    var seq = chunk + 1;
    if (chunk == chunkCount - 1) {
      seq |= 0x40; // last logical chunk = first physical chunk flag
    }
    bytes[entryOffset] = seq & 0xff;
    bytes[entryOffset + 11] = 0x0f; // LFN attribute
    bytes[entryOffset + 12] = 0; // type
    bytes[entryOffset + 13] = checksum & 0xff;
    // Name chars for this chunk: positions 0-4 at [1..11), 5-10 at [14..26),
    // 11-12 at [28..32).
    for (var i = 0; i < 5; i++) {
      final unit = padded[chunk * 13 + i];
      bytes[entryOffset + 1 + i * 2] = unit & 0xff;
      bytes[entryOffset + 2 + i * 2] = (unit >> 8) & 0xff;
    }
    for (var i = 0; i < 6; i++) {
      final unit = padded[chunk * 13 + 5 + i];
      bytes[entryOffset + 14 + i * 2] = unit & 0xff;
      bytes[entryOffset + 15 + i * 2] = (unit >> 8) & 0xff;
    }
    for (var i = 0; i < 2; i++) {
      final unit = padded[chunk * 13 + 11 + i];
      bytes[entryOffset + 28 + i * 2] = unit & 0xff;
      bytes[entryOffset + 29 + i * 2] = (unit >> 8) & 0xff;
    }
  }
  return chunkCount;
}

Uint8List _syntheticFat32DataAreaWithFiles({
  bool cyclicChain = false,
  bool longNames = false,
  bool zeroLengthFile = false,
  bool badCluster = false,
}) {
  final bytes = Uint8List(_fat32TotalSectors * _fat32BytesPerSector);
  _writeFat32BootSector(bytes);

  // Reserved FAT entries: cluster 0 (media descriptor + 0xffffff8 mask),
  // cluster 1 (EOC). Standard FAT32 convention.
  _setFat32Entry(bytes, 0, 0x0ffffff8);
  _setFat32Entry(bytes, 1, 0x0fffffff);

  // Cluster 2: root directory (EOC).
  _setFat32Entry(bytes, 2, 0x0fffffff);
  // Cluster 3: README.TXT payload. Mutually-exclusive fault flags: a cycle
  // (self-loop) wins over a bad-cluster marker so each test exercises exactly
  // one defensive branch.
  if (cyclicChain) {
    // Point cluster 3 back to itself -> self-loop cycle.
    _setFat32Entry(bytes, 3, 3);
  } else if (badCluster) {
    // Mark cluster 3 with the FAT32 bad-cluster sentinel 0x0FFFFFF7.
    _setFat32Entry(bytes, 3, 0x0ffffff7);
  } else {
    _setFat32Entry(bytes, 3, 0x0fffffff);
  }
  // Cluster 4: docs/ directory (EOC).
  _setFat32Entry(bytes, 4, 0x0fffffff);
  // Cluster 5: NOTE.TXT payload (EOC).
  _setFat32Entry(bytes, 5, 0x0fffffff);

  // Mirror the same entries into FAT #1 (sector 33).
  for (var cluster = 0; cluster <= 5; cluster++) {
    final value =
        bytes[_fat32ReservedSectors * _fat32BytesPerSector + cluster * 4] |
        (bytes[_fat32ReservedSectors * _fat32BytesPerSector +
                cluster * 4 +
                1] <<
            8) |
        (bytes[_fat32ReservedSectors * _fat32BytesPerSector +
                cluster * 4 +
                2] <<
            16) |
        (bytes[_fat32ReservedSectors * _fat32BytesPerSector +
                cluster * 4 +
                3] <<
            24);
    final mirrorOffset =
        (_fat32ReservedSectors + 1) * _fat32BytesPerSector + cluster * 4;
    bytes[mirrorOffset] = value & 0xff;
    bytes[mirrorOffset + 1] = (value >> 8) & 0xff;
    bytes[mirrorOffset + 2] = (value >> 16) & 0xff;
    bytes[mirrorOffset + 3] = (value >> 24) & 0xff;
  }

  // Root directory (cluster 2 @ sector 34): README.TXT + docs/.
  final rootOffset = _clusterToOffset(2);
  final readMe = _syntheticFat32FilePayload();
  var cursor = rootOffset;
  if (longNames) {
    final lfnSlots = _writeLfnEntries(
      bytes,
      cursor,
      'read me notes.txt',
      // 8.3 field = name padded to 8 + ext: 'README  ' + 'TXT' (2 spaces).
      _lfnChecksum('README  TXT'),
    );
    cursor += lfnSlots * 32;
  }
  _writeShortDirEntry(
    bytes,
    cursor,
    'README',
    'TXT',
    0x20, // archive attribute (file)
    3, // first cluster
    readMe.length,
  );
  cursor += 32;
  _writeShortDirEntry(
    bytes,
    cursor,
    'DOCS',
    '',
    0x10, // directory attribute
    4, // first cluster
    0,
  );
  cursor += 32;
  // Optional zero-length file: FAT32 convention size=0, firstCluster=0,
  // consuming no cluster. Lets the readFile zero-length short-circuit path be
  // exercised without triggering the cluster-out-of-range guard.
  if (zeroLengthFile) {
    _writeShortDirEntry(
      bytes,
      cursor,
      'EMPTY',
      'TXT',
      0x20, // archive attribute (file)
      0, // first cluster: 0 (no cluster allocated)
      0, // size: 0
    );
    cursor += 32;
  }
  // End-of-directory marker after the entries.
  bytes[cursor] = 0x00;

  // README.TXT payload (cluster 3 @ sector 35).
  final readMeOffset = _clusterToOffset(3);
  for (var i = 0; i < readMe.length; i++) {
    bytes[readMeOffset + i] = readMe[i];
  }

  // docs/ directory (cluster 4 @ sector 36): ".", "..", NOTE.TXT.
  final docsOffset = _clusterToOffset(4);
  _writeDotDotEntry(bytes, docsOffset, 4, true);
  _writeDotDotEntry(bytes, docsOffset + 32, _fat32RootCluster, false);
  final note = _syntheticFat32NotePayload();
  _writeShortDirEntry(
    bytes,
    docsOffset + 64,
    'NOTE',
    'TXT',
    0x20, // archive attribute (file)
    5, // first cluster
    note.length,
  );
  bytes[docsOffset + 96] = 0x00;

  // NOTE.TXT payload (cluster 5 @ sector 37).
  final noteOffset = _clusterToOffset(5);
  for (var i = 0; i < note.length; i++) {
    bytes[noteOffset + i] = note[i];
  }

  return bytes;
}
