import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:vocabulary_sleep_app/src/services/audio_player_source_helper.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform({required this.temporaryPath});

  final String temporaryPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late Directory tempDir;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    tempDir = await Directory.systemTemp.createTemp(
      'audio-player-source-helper-',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      temporaryPath: tempDir.path,
    );
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    if (await tempDir.exists()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  test(
    'temp byte file keeps source extension hints for soothing tracks',
    () async {
      final bytes = Uint8List.fromList(<int>[
        0,
        0,
        0,
        0,
        0x66,
        0x74,
        0x79,
        0x70,
        0,
        0,
        0,
        0,
      ]);

      final path = await AudioPlayerSourceHelper.debugTempFilePathForBytes(
        bytes,
        mimeType: 'audio/mp4',
        data: const <String, Object?>{'trackAssetPath': 'music/study.m4a'},
      );

      expect(p.extension(path), '.m4a');
      expect(await File(path).readAsBytes(), bytes);
    },
  );

  test(
    'temp byte file falls back to mime type when no path hint exists',
    () async {
      final bytes = Uint8List.fromList(<int>[
        0x52,
        0x49,
        0x46,
        0x46,
        0,
        0,
        0,
        0,
        0x57,
        0x41,
        0x56,
        0x45,
      ]);

      final path = await AudioPlayerSourceHelper.debugTempFilePathForBytes(
        bytes,
        mimeType: 'audio/wav',
      );

      expect(p.extension(path), '.wav');
      expect(await File(path).readAsBytes(), bytes);
    },
  );
}
