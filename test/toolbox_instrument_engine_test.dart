import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/cstcloud_resource_cache_service.dart';
import 'package:vocabulary_sleep_app/src/services/toolbox_audio_service.dart';

void main() {
  group('ToolboxSoundFontInstrumentEngine', () {
    test('catalog maps first SoundFont patches to stable GM programs', () {
      expect(ToolboxInstrumentBankCatalog.acousticGrandPiano.program, 0);
      expect(ToolboxInstrumentBankCatalog.acousticGrandPiano.channel, 0);
      expect(ToolboxInstrumentBankCatalog.acousticGuitarNylon.program, 24);
      expect(ToolboxInstrumentBankCatalog.acousticGuitarNylon.channel, 1);
      expect(ToolboxInstrumentBankCatalog.violin.program, 40);
      expect(ToolboxInstrumentBankCatalog.violin.channel, 2);
      expect(ToolboxInstrumentBankCatalog.flute.program, 73);
      expect(ToolboxInstrumentBankCatalog.flute.channel, 3);
      expect(ToolboxInstrumentBankCatalog.orchestralHarp.program, 46);
      expect(ToolboxInstrumentBankCatalog.orchestralHarp.channel, 4);
      expect(ToolboxInstrumentBankCatalog.kalimba.program, 108);
      expect(ToolboxInstrumentBankCatalog.kalimba.channel, 5);
      expect(ToolboxInstrumentBankCatalog.tubularBells.program, 14);
      expect(ToolboxInstrumentBankCatalog.tubularBells.channel, 6);
      expect(ToolboxInstrumentPitch.midiFromFrequency(440), 69);
      expect(ToolboxInstrumentPitch.midiFromFrequency(261.63), 60);
      expect(ToolboxInstrumentPitch.midiFromFrequency(0), 60);
    });

    test('stays unavailable on unsupported platforms', () async {
      final synth = _FakeMidiSynthAdapter();
      final engine = ToolboxSoundFontInstrumentEngine(
        synth: synth,
        bankStore: const ToolboxInstrumentBankStore(debugDirectory: 'missing'),
        platformSupported: () => false,
      );

      final ready = await engine.loadBank(
        ToolboxInstrumentBankCatalog.museScoreGeneral,
      );

      expect(ready, isFalse);
      expect(synth.calls, isEmpty);
    });

    test('loads bank and sends program and note messages', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'toolbox_instrument_engine_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final bankFile = File(
        '${tempDir.path}${Platform.pathSeparator}'
        '${ToolboxInstrumentBankCatalog.museScoreGeneral.fileName}',
      );
      await bankFile.writeAsBytes(<int>[0, 1, 2, 3]);
      final bank = _testBankSpec(
        fileName: ToolboxInstrumentBankCatalog.museScoreGeneral.fileName,
        bytes: const <int>[0, 1, 2, 3],
      );

      final synth = _FakeMidiSynthAdapter();
      final engine = ToolboxSoundFontInstrumentEngine(
        synth: synth,
        bankStore: ToolboxInstrumentBankStore(debugDirectory: tempDir.path),
        platformSupported: () => true,
      );

      final played = await engine.noteOn(
        bank: bank,
        patch: ToolboxInstrumentBankCatalog.acousticGrandPiano,
        midiNote: 60,
        velocity: 0.75,
        volume: 0.8,
        reverb: 0.2,
      );
      await engine.noteOff(
        patch: ToolboxInstrumentBankCatalog.acousticGrandPiano,
        midiNote: 60,
      );

      expect(played, isTrue);
      expect(synth.calls.first, 'unmute');
      expect(synth.calls, contains('load:${bankFile.path}'));
      expect(synth.calls, contains('program:0:0'));
      expect(synth.calls, contains('volume:102:0'));
      expect(synth.calls, contains('noteOn:60:95:0'));
      expect(synth.calls, contains('noteOff:60:64:0'));
    });

    test('reuses channel configuration across repeated note on', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'toolbox_instrument_config_cache_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final bank = await _writeTestBank(tempDir, fileName: 'Config.sf3');

      final synth = _FakeMidiSynthAdapter();
      final engine = ToolboxSoundFontInstrumentEngine(
        synth: synth,
        bankStore: ToolboxInstrumentBankStore(debugDirectory: tempDir.path),
        platformSupported: () => true,
      );

      await engine.noteOn(
        bank: bank,
        patch: ToolboxInstrumentBankCatalog.acousticGrandPiano,
        midiNote: 60,
        velocity: 0.5,
        volume: 0.8,
        reverb: 0.2,
      );
      await engine.noteOn(
        bank: bank,
        patch: ToolboxInstrumentBankCatalog.acousticGrandPiano,
        midiNote: 64,
        velocity: 0.6,
        volume: 0.8,
        reverb: 0.2,
      );

      expect(synth.calls.where((call) => call.startsWith('program:')), <String>[
        'program:0:0',
      ]);
      expect(synth.calls.where((call) => call.startsWith('volume:')), <String>[
        'volume:102:0',
      ]);
      expect(synth.calls.where((call) => call.startsWith('reverb:')), <String>[
        'reverb:0.20',
      ]);
      expect(synth.calls.where((call) => call.startsWith('noteOn:')), <String>[
        'noteOn:60:64:0',
        'noteOn:64:76:0',
      ]);
    });

    test('sampled note player keeps dynamics on velocity path', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'toolbox_instrument_sampled_player_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final bank = await _writeTestBank(tempDir, fileName: 'Sampled.sf3');

      final synth = _FakeMidiSynthAdapter();
      final engine = ToolboxSoundFontInstrumentEngine(
        synth: synth,
        bankStore: ToolboxInstrumentBankStore(debugDirectory: tempDir.path),
        platformSupported: () => true,
      );
      final player = ToolboxSampledMidiNotePlayer(
        engine: engine,
        bank: bank,
        patch: ToolboxInstrumentBankCatalog.acousticGrandPiano,
        midiNote: 60,
        velocity: 0.5,
        releaseAfter: const Duration(seconds: 30),
        volume: 0.8,
        reverb: 0.2,
      );
      addTearDown(player.dispose);

      await player.play(volume: 0.5);
      await player.play(volume: 1.0);

      expect(synth.calls.where((call) => call.startsWith('volume:')), <String>[
        'volume:102:0',
      ]);
      expect(synth.calls.where((call) => call.startsWith('noteOn:')), <String>[
        'noteOn:60:32:0',
        'noteOn:60:64:0',
      ]);
    });

    test(
      'sampled sustain controller keeps note held until target changes',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'toolbox_instrument_sustain_controller_test_',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });
        final bank = await _writeTestBank(tempDir, fileName: 'Sustain.sf3');

        final synth = _FakeMidiSynthAdapter();
        final engine = ToolboxSoundFontInstrumentEngine(
          synth: synth,
          bankStore: ToolboxInstrumentBankStore(debugDirectory: tempDir.path),
          platformSupported: () => true,
        );
        final controller = ToolboxSampledMidiSustainController(
          engine: engine,
          bank: bank,
          patch: ToolboxInstrumentBankCatalog.flute,
          volume: 0.8,
          reverb: 0.2,
        );
        addTearDown(controller.dispose);

        final first = await controller.start(
          midiNote: 72,
          velocity: 0.6,
          volume: 0.8,
          reverb: 0.2,
        );
        final update = await controller.update(volume: 0.4, reverb: 0.3);
        final second = await controller.start(
          midiNote: 74,
          velocity: 0.7,
          volume: 0.4,
          reverb: 0.3,
        );
        await controller.stop();

        expect(first, isTrue);
        expect(update, isTrue);
        expect(second, isTrue);
        expect(
          synth.calls.where((call) => call.startsWith('program:')),
          <String>['program:73:3'],
        );
        expect(
          synth.calls.where((call) => call.startsWith('volume:')),
          <String>['volume:102:3', 'volume:51:3'],
        );
        expect(
          synth.calls.where((call) => call.startsWith('reverb:')),
          <String>['reverb:0.20', 'reverb:0.30'],
        );
        expect(synth.calls.where((call) => call.startsWith('note')), <String>[
          'noteOn:72:76:3',
          'noteOff:72:64:3',
          'noteOn:74:89:3',
          'noteOff:74:64:3',
        ]);
      },
    );

    test('rejects local bank with mismatched metadata', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'toolbox_instrument_bad_bank_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final bank = _testBankSpec(fileName: 'BadLocal.sf3');
      final bankFile = File(
        '${tempDir.path}${Platform.pathSeparator}${bank.fileName}',
      );
      await bankFile.writeAsBytes(<int>[9], flush: true);

      final synth = _FakeMidiSynthAdapter();
      final engine = ToolboxSoundFontInstrumentEngine(
        synth: synth,
        bankStore: ToolboxInstrumentBankStore(debugDirectory: tempDir.path),
        platformSupported: () => true,
      );

      final ready = await engine.loadBank(bank);

      expect(ready, isFalse);
      expect(synth.calls, isEmpty);
      expect(await bankFile.exists(), isTrue);
    });

    test('loads valid bank from resource cache', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'toolbox_instrument_remote_bank_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final remoteFile = File(
        '${tempDir.path}${Platform.pathSeparator}Remote.sf3',
      );
      await remoteFile.writeAsBytes(_testBankBytes, flush: true);
      final cache = _FakeInstrumentCacheService(remoteFile);
      final bank = _testBankSpec(
        fileName: 'MissingLocal.sf3',
        remoteKey: 'instrument_banks/v1/test/Remote.sf3',
      );

      final synth = _FakeMidiSynthAdapter();
      final engine = ToolboxSoundFontInstrumentEngine(
        synth: synth,
        bankStore: ToolboxInstrumentBankStore(
          debugDirectory: '${tempDir.path}${Platform.pathSeparator}missing',
        ),
        resourceCache: cache,
        platformSupported: () => true,
      );

      final ready = await engine.loadBank(bank);

      expect(ready, isTrue);
      expect(cache.remoteKeys, <String>[bank.remoteKey!]);
      expect(cache.cacheRelativePaths, <String?>[bank.remoteKey]);
      expect(synth.calls, contains('load:${remoteFile.path}'));
    });

    test('falls back to local bank when remote cache is invalid', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'toolbox_instrument_remote_fallback_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final remoteFile = File(
        '${tempDir.path}${Platform.pathSeparator}RemoteBad.sf3',
      );
      await remoteFile.writeAsBytes(<int>[9], flush: true);
      final localDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}local',
      );
      await localDir.create();
      final bank = _testBankSpec(
        fileName: 'LocalGood.sf3',
        remoteKey: 'instrument_banks/v1/test/LocalGood.sf3',
      );
      final localFile = File(
        '${localDir.path}${Platform.pathSeparator}${bank.fileName}',
      );
      await localFile.writeAsBytes(_testBankBytes, flush: true);

      final synth = _FakeMidiSynthAdapter();
      final engine = ToolboxSoundFontInstrumentEngine(
        synth: synth,
        bankStore: ToolboxInstrumentBankStore(debugDirectory: localDir.path),
        resourceCache: _FakeInstrumentCacheService(remoteFile),
        platformSupported: () => true,
      );

      final ready = await engine.loadBank(bank);

      expect(ready, isTrue);
      expect(await remoteFile.exists(), isFalse);
      expect(synth.calls, contains('load:${localFile.path}'));
    });
  });
}

const List<int> _testBankBytes = <int>[0, 1, 2, 3];

Future<ToolboxInstrumentBankSpec> _writeTestBank(
  Directory directory, {
  required String fileName,
}) async {
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(_testBankBytes, flush: true);
  return _testBankSpec(fileName: fileName);
}

ToolboxInstrumentBankSpec _testBankSpec({
  required String fileName,
  List<int> bytes = _testBankBytes,
  String? remoteKey,
}) {
  return ToolboxInstrumentBankSpec(
    id: fileName,
    fileName: fileName,
    license: 'MIT',
    licenseUrl: 'https://example.com/license',
    sourceUrl: 'https://example.com/source',
    remoteKey: remoteKey,
    sha256: sha256.convert(bytes).toString(),
    sizeBytes: bytes.length,
  );
}

class _FakeInstrumentCacheService extends CstCloudResourceCacheService {
  _FakeInstrumentCacheService(this.file);

  final File file;
  final List<String> remoteKeys = <String>[];
  final List<String?> cacheRelativePaths = <String?>[];

  @override
  Future<File> ensureFileDownloaded(
    String remoteKey, {
    String? cacheRelativePath,
    ResourceDownloadProgressCallback? onProgress,
  }) async {
    remoteKeys.add(remoteKey);
    cacheRelativePaths.add(cacheRelativePath);
    final length = await file.length();
    onProgress?.call(
      ResourceDownloadProgress(receivedBytes: length, totalBytes: length),
    );
    return file;
  }
}

class _FakeMidiSynthAdapter implements ToolboxMidiSynthAdapter {
  final List<String> calls = <String>[];

  @override
  Future<bool> loadSoundfont(String path) async {
    calls.add('load:$path');
    return true;
  }

  @override
  Future<bool> unloadSoundfont() async {
    calls.add('unload');
    return true;
  }

  @override
  Future<void> playNote({
    required int note,
    required int velocity,
    required int channel,
  }) async {
    calls.add('noteOn:$note:$velocity:$channel');
  }

  @override
  Future<void> stopNote({
    required int note,
    required int velocity,
    required int channel,
  }) async {
    calls.add('noteOff:$note:$velocity:$channel');
  }

  @override
  Future<void> changeProgram({
    required int program,
    required int channel,
  }) async {
    calls.add('program:$program:$channel');
  }

  @override
  Future<void> setVolume({required int volume, required int channel}) async {
    calls.add('volume:$volume:$channel');
  }

  @override
  Future<void> setReverb({
    required double roomSize,
    required double damping,
    required double width,
    required double level,
  }) async {
    calls.add('reverb:${roomSize.toStringAsFixed(2)}');
  }

  @override
  Future<void> stopAllNotes() async {
    calls.add('allNotesOff');
  }

  @override
  Future<void> unmute() async {
    calls.add('unmute');
  }
}
