import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:vocabulary_sleep_app/src/ui/pages/toolbox_crypto_security.dart';

void main() {
  group('fingerprint sidecar path protection', () {
    test(
      'redirects sidecar when picker returns the protected carrier path',
      () {
        final resolved = resolveStegoFingerprintSidecarPath(
          pickedPath: p.join('C:', 'exports', 'photo_stego.png'),
          protectedCarrierPath: p.join('C:', 'exports', 'photo_stego.png'),
          sidecarFileName: 'photo_stego_fingerprint.vssig',
        );

        expect(
          resolved,
          p.join('C:', 'exports', 'photo_stego_fingerprint.vssig'),
        );
      },
    );

    test('keeps sidecar path when it differs from the protected carrier', () {
      final pickedPath = p.join('C:', 'exports', 'photo_sidecar.vssig');

      final resolved = resolveStegoFingerprintSidecarPath(
        pickedPath: pickedPath,
        protectedCarrierPath: p.join('C:', 'exports', 'photo_stego.png'),
        sidecarFileName: 'photo_stego_fingerprint.vssig',
      );

      expect(resolved, pickedPath);
    });

    test('keeps null and empty picker results unchanged', () {
      expect(
        resolveStegoFingerprintSidecarPath(
          pickedPath: null,
          protectedCarrierPath: p.join('C:', 'exports', 'photo_stego.png'),
          sidecarFileName: 'photo_stego_fingerprint.vssig',
        ),
        isNull,
      );
      expect(
        resolveStegoFingerprintSidecarPath(
          pickedPath: '   ',
          protectedCarrierPath: p.join('C:', 'exports', 'photo_stego.png'),
          sidecarFileName: 'photo_stego_fingerprint.vssig',
        ),
        '   ',
      );
    });

    test('redirects case-only path collisions conservatively', () {
      final resolved = resolveStegoFingerprintSidecarPath(
        pickedPath: p.join('C:', 'exports', 'PHOTO_STEGO.PNG'),
        protectedCarrierPath: p.join('C:', 'exports', 'photo_stego.png'),
        sidecarFileName: 'photo_stego_fingerprint.vssig',
      );

      expect(
        resolved,
        p.join('C:', 'exports', 'photo_stego_fingerprint.vssig'),
      );
    });

    test(
      'uses fallback sidecar name if requested sidecar name matches carrier',
      () {
        final resolved = resolveStegoFingerprintSidecarPath(
          pickedPath: p.join('C:', 'exports', 'carrier.vssig'),
          protectedCarrierPath: p.join('C:', 'exports', 'carrier.vssig'),
          sidecarFileName: 'carrier.vssig',
        );

        expect(resolved, p.join('C:', 'exports', 'carrier_fingerprint.vssig'));
      },
    );
  });

  test('local vault path lookup does not create trace directories', () async {
    final tempDir = await Directory.systemTemp.createTemp('stego-vault-paths-');
    try {
      final paths = ToolboxStegoLocalVaultPaths(
        documentsDirectoryProvider: () async => tempDir,
      );
      final lifeToolsDirectory = Directory(p.join(tempDir.path, 'life_tools'));
      final stegoDirectory = Directory(
        p.join(lifeToolsDirectory.path, 'steganography'),
      );

      final pathOnlyFile = await paths.file(createDirectory: false);
      expect(pathOnlyFile.path, endsWith('local_stego_vault.json'));
      expect(await lifeToolsDirectory.exists(), isFalse);
      expect(await stegoDirectory.exists(), isFalse);

      final writableFile = await paths.file(createDirectory: true);
      expect(writableFile.path, pathOnlyFile.path);
      expect(await lifeToolsDirectory.exists(), isTrue);
      expect(await stegoDirectory.exists(), isTrue);
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  test('local vault clearing removes empty trace directories', () async {
    final tempDir = await Directory.systemTemp.createTemp('stego-vault-clear-');
    try {
      final paths = ToolboxStegoLocalVaultPaths(
        documentsDirectoryProvider: () async => tempDir,
      );
      final vaultFile = await paths.file(createDirectory: true);
      final stegoDirectory = vaultFile.parent;
      final lifeToolsDirectory = stegoDirectory.parent;
      await vaultFile.writeAsString('[]');

      await vaultFile.delete();
      await paths.deleteEmptyParents(vaultFile);

      expect(await vaultFile.exists(), isFalse);
      expect(await stegoDirectory.exists(), isFalse);
      expect(await lifeToolsDirectory.exists(), isFalse);
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });

  test('local vault clearing keeps non-empty parent directories', () async {
    final tempDir = await Directory.systemTemp.createTemp('stego-vault-keep-');
    try {
      final paths = ToolboxStegoLocalVaultPaths(
        documentsDirectoryProvider: () async => tempDir,
      );
      final vaultFile = await paths.file(createDirectory: true);
      final stegoDirectory = vaultFile.parent;
      final lifeToolsDirectory = stegoDirectory.parent;
      await vaultFile.writeAsString('[]');
      await File(p.join(stegoDirectory.path, 'keep.txt')).writeAsString('x');

      await vaultFile.delete();
      await paths.deleteEmptyParents(vaultFile);

      expect(await vaultFile.exists(), isFalse);
      expect(await stegoDirectory.exists(), isTrue);
      expect(await lifeToolsDirectory.exists(), isTrue);
    } finally {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
