import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_archive_processing_service.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_archive_resource_policy.dart';

void main() {
  const service = ToolboxArchiveProcessingService();

  group('ToolboxArchiveResourcePolicy', () {
    test('enforces archive, entry count, entry, and cumulative limits', () {
      expect(
        () => ToolboxArchiveResourcePolicy.validateArchiveBytes(
          ToolboxArchiveResourcePolicy.maxArchiveBytes + 1,
        ),
        _throwsCode(ToolboxArchiveErrorCode.archiveTooLarge),
      );
      expect(
        () => ToolboxArchiveResourcePolicy.validateEntryCount(
          ToolboxArchiveResourcePolicy.maxEntryCount + 1,
        ),
        _throwsCode(ToolboxArchiveErrorCode.tooManyEntries),
      );
      expect(
        () => ToolboxArchiveResourcePolicy.validateEntryBytes(
          ToolboxArchiveResourcePolicy.maxEntryBytes + 1,
        ),
        _throwsCode(ToolboxArchiveErrorCode.entryTooLarge),
      );
      expect(
        () => ToolboxArchiveResourcePolicy.validateTotalContentBytes(
          ToolboxArchiveResourcePolicy.maxTotalContentBytes + 1,
        ),
        _throwsCode(ToolboxArchiveErrorCode.totalContentTooLarge),
      );
    });

    test('rejects traversal and absolute paths', () {
      for (final unsafePath in <String>[
        '../escape.txt',
        'folder/../escape.txt',
        r'C:\escape.txt',
        '/absolute.txt',
        r'\\server\share\escape.txt',
      ]) {
        expect(
          () => ToolboxArchivePathPolicy.normalizeSafeRelativePath(unsafePath),
          _throwsCode(ToolboxArchiveErrorCode.unsafePath),
          reason: unsafePath,
        );
      }
    });

    test('normalizes portable relative paths and device names', () {
      expect(
        ToolboxArchivePathPolicy.normalizeSafeRelativePath(
          r'folder\report:2026.txt',
        ),
        'folder/report_2026.txt',
      );
      expect(
        ToolboxArchivePathPolicy.normalizeSafeRelativePath('CON.txt'),
        '_CON.txt',
      );
    });
  });

  group('ToolboxArchiveProcessingService', () {
    test('encodes and decodes ZIP in a worker', () async {
      final encoded = await service.encode(
        ToolboxArchiveEncodeRequest(
          entries: <ToolboxArchiveInput>[
            _input('notes/readme.txt', <int>[1, 2, 3, 4]),
            _input('notes/empty.txt', const <int>[]),
          ],
          format: ToolboxArchiveCreateFormat.zip,
          compressionLevel: ToolboxArchiveCompressionLevel.balanced,
          zipAlgorithm: ToolboxArchiveZipAlgorithm.deflate,
        ),
      );

      final decoded = await service.decode(
        fileName: 'bundle.zip',
        bytes: encoded,
      );

      expect(decoded.format, ToolboxArchiveFormat.zip);
      expect(decoded.fileCount, 2);
      expect(decoded.totalContentBytes, 4);
      expect(
        decoded.entries
            .firstWhere((entry) => entry.relativePath == 'notes/readme.txt')
            .bytes,
        <int>[1, 2, 3, 4],
      );
      expect(() => decoded.validateForExtraction(), returnsNormally);
    });

    test('round-trips TAR.GZ and single-file GZip formats', () async {
      final tarGzip = await service.encode(
        ToolboxArchiveEncodeRequest(
          entries: <ToolboxArchiveInput>[
            _input('one.txt', <int>[10, 20]),
            _input('nested/two.txt', <int>[30, 40, 50]),
          ],
          format: ToolboxArchiveCreateFormat.tarGzip,
          compressionLevel: ToolboxArchiveCompressionLevel.fast,
          zipAlgorithm: ToolboxArchiveZipAlgorithm.deflate,
        ),
      );
      final tarResult = await service.decode(
        fileName: 'bundle.tar.gz',
        bytes: tarGzip,
      );
      expect(tarResult.format, ToolboxArchiveFormat.tarGzip);
      expect(tarResult.fileCount, 2);
      expect(tarResult.totalContentBytes, 5);

      final gzip = await service.encode(
        ToolboxArchiveEncodeRequest(
          entries: <ToolboxArchiveInput>[
            _input('note.txt', <int>[7, 8, 9]),
          ],
          format: ToolboxArchiveCreateFormat.gzip,
          compressionLevel: ToolboxArchiveCompressionLevel.balanced,
          zipAlgorithm: ToolboxArchiveZipAlgorithm.deflate,
        ),
      );
      final gzipResult = await service.decode(
        fileName: 'note.txt.gz',
        bytes: gzip,
      );
      expect(gzipResult.format, ToolboxArchiveFormat.gzip);
      expect(gzipResult.entries.single.relativePath, 'note.txt');
      expect(gzipResult.entries.single.bytes, <int>[7, 8, 9]);
    });

    test(
      'rejects ZIP path traversal before materializing entry bytes',
      () async {
        final archive = Archive()
          ..addFile(ArchiveFile.bytes('../escape.txt', <int>[1, 2, 3]));
        final bytes = Uint8List.fromList(ZipEncoder().encodeBytes(archive));

        await expectLater(
          service.decode(fileName: 'unsafe.zip', bytes: bytes),
          _throwsCode(ToolboxArchiveErrorCode.unsafePath),
        );
      },
    );

    test('rejects normalized path collisions', () async {
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('Report.txt', <int>[1]))
        ..addFile(ArchiveFile.bytes('report.txt', <int>[2]));
      final bytes = Uint8List.fromList(ZipEncoder().encodeBytes(archive));

      await expectLater(
        service.decode(fileName: 'duplicates.zip', bytes: bytes),
        _throwsCode(ToolboxArchiveErrorCode.duplicatePath),
      );
    });

    test('rejects TAR traversal and symbolic-link entries', () async {
      final traversalArchive = Archive()
        ..addFile(ArchiveFile.bytes('../escape.txt', <int>[1]));
      final traversalBytes = Uint8List.fromList(
        TarEncoder().encodeBytes(traversalArchive),
      );
      await expectLater(
        service.decode(fileName: 'unsafe.tar', bytes: traversalBytes),
        _throwsCode(ToolboxArchiveErrorCode.unsafePath),
      );

      final linkArchive = Archive()
        ..addFile(ArchiveFile.symlink('link.txt', '../outside.txt'));
      final linkBytes = Uint8List.fromList(
        TarEncoder().encodeBytes(linkArchive),
      );
      await expectLater(
        service.decode(fileName: 'link.tar', bytes: linkBytes),
        _throwsCode(ToolboxArchiveErrorCode.symbolicLink),
      );
    });

    test('rejects ZIP entries above the compression-ratio limit', () async {
      final archive = Archive()
        ..addFile(ArchiveFile.bytes('zeros.bin', Uint8List(1024 * 1024)));
      final bytes = Uint8List.fromList(
        ZipEncoder().encodeBytes(archive, level: 9),
      );

      await expectLater(
        service.decode(fileName: 'ratio.zip', bytes: bytes),
        _throwsCode(ToolboxArchiveErrorCode.compressionRatioTooHigh),
      );
    });

    test('revalidates decoded entries before extraction', () {
      final forged = ToolboxArchiveDecodeResult(
        format: ToolboxArchiveFormat.zip,
        entries: <ToolboxArchiveDecodedEntry>[
          ToolboxArchiveDecodedEntry(
            relativePath: 'safe.txt',
            isFile: true,
            bytes: Uint8List.fromList(<int>[1]),
          ),
          ToolboxArchiveDecodedEntry(
            relativePath: 'SAFE.txt',
            isFile: true,
            bytes: Uint8List.fromList(<int>[2]),
          ),
        ],
        sourceByteLength: 100,
        totalEntryCount: 2,
      );

      expect(
        forged.validateForExtraction,
        _throwsCode(ToolboxArchiveErrorCode.duplicatePath),
      );
    });
  });
}

ToolboxArchiveInput _input(String path, List<int> bytes) {
  return ToolboxArchiveInput(
    relativePath: path,
    bytes: Uint8List.fromList(bytes),
    fromFolder: path.contains('/'),
  );
}

Matcher _throwsCode(ToolboxArchiveErrorCode code) {
  return throwsA(
    isA<ToolboxArchiveProcessingException>().having(
      (error) => error.code,
      'code',
      code,
    ),
  );
}
