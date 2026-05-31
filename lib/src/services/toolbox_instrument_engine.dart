part of 'toolbox_audio_service.dart';

enum ToolboxInstrumentId {
  piano,
  guitar,
  flute,
  violin,
  harp,
  drumKit,
  triangle,
}

class ToolboxInstrumentBankSpec {
  const ToolboxInstrumentBankSpec({
    required this.id,
    required this.fileName,
    required this.license,
    required this.licenseUrl,
    required this.sourceUrl,
    this.remoteKey,
    this.sha256,
    this.sizeBytes,
  });

  final String id;
  final String fileName;
  final String license;
  final String licenseUrl;
  final String sourceUrl;
  final String? remoteKey;
  final String? sha256;
  final int? sizeBytes;
}

class ToolboxInstrumentPatch {
  const ToolboxInstrumentPatch({
    required this.id,
    required this.instrumentId,
    required this.program,
    this.channel = 0,
  });

  final String id;
  final ToolboxInstrumentId instrumentId;
  final int program;
  final int channel;
}

class ToolboxInstrumentBankCatalog {
  const ToolboxInstrumentBankCatalog._();

  static const String cacheSubdirectory = 'toolbox_instrument_banks';
  static const String fluidR3MonoGmRemoteKey =
      'instrument_banks/v1/fluidr3mono_gm/FluidR3Mono_GM.sf3';

  static const ToolboxInstrumentBankSpec
  museScoreGeneral = ToolboxInstrumentBankSpec(
    id: 'fluidr3mono_gm',
    fileName: 'FluidR3Mono_GM.sf3',
    license: 'MIT',
    licenseUrl:
        'https://github.com/musescore/MuseScore/blob/master/share/sound/FluidR3Mono_License.md',
    sourceUrl:
        'https://github.com/musescore/MuseScore/raw/2.1/share/sound/FluidR3Mono_GM.sf3',
    remoteKey: fluidR3MonoGmRemoteKey,
    sha256: 'cfcd66d89e8386823400eca64934b14fbea7bf48ba1f00d21189af1262794ec2',
    sizeBytes: 14563174,
  );

  static const ToolboxInstrumentPatch acousticGrandPiano =
      ToolboxInstrumentPatch(
        id: 'gm_acoustic_grand_piano',
        instrumentId: ToolboxInstrumentId.piano,
        program: 0,
      );
}

abstract class ToolboxMidiSynthAdapter {
  Future<bool> loadSoundfont(String path);
  Future<bool> unloadSoundfont();
  Future<void> playNote({
    required int note,
    required int velocity,
    required int channel,
  });
  Future<void> stopNote({
    required int note,
    required int velocity,
    required int channel,
  });
  Future<void> changeProgram({required int program, required int channel});
  Future<void> setVolume({required int volume, required int channel});
  Future<void> setReverb({
    required double roomSize,
    required double damping,
    required double width,
    required double level,
  });
  Future<void> stopAllNotes();
  Future<void> unmute();
}

class ToolboxFlutterMidiEngineAdapter implements ToolboxMidiSynthAdapter {
  ToolboxFlutterMidiEngineAdapter([FlutterMidiEngine? engine])
    : _engine = engine ?? FlutterMidiEngine();

  final FlutterMidiEngine _engine;

  @override
  Future<bool> loadSoundfont(String path) => _engine.loadSoundfont(path);

  @override
  Future<bool> unloadSoundfont() => _engine.unloadSoundfont();

  @override
  Future<void> playNote({
    required int note,
    required int velocity,
    required int channel,
  }) {
    return _engine.playNote(note: note, velocity: velocity, channel: channel);
  }

  @override
  Future<void> stopNote({
    required int note,
    required int velocity,
    required int channel,
  }) {
    return _engine.stopNote(note: note, velocity: velocity, channel: channel);
  }

  @override
  Future<void> changeProgram({required int program, required int channel}) {
    return _engine.changeProgram(program: program, channel: channel);
  }

  @override
  Future<void> setVolume({required int volume, required int channel}) {
    return _engine.setVolume(volume: volume, channel: channel);
  }

  @override
  Future<void> setReverb({
    required double roomSize,
    required double damping,
    required double width,
    required double level,
  }) {
    return _engine.setReverb(
      roomSize: roomSize,
      damping: damping,
      width: width,
      level: level,
    );
  }

  @override
  Future<void> stopAllNotes() => _engine.stopAllNotes();

  @override
  Future<void> unmute() => _engine.unmute();
}

class ToolboxInstrumentBankStore {
  const ToolboxInstrumentBankStore({this.debugDirectory});

  final String? debugDirectory;

  Future<File> localFileFor(ToolboxInstrumentBankSpec bank) async {
    final debugRoot = debugDirectory?.trim();
    if (debugRoot != null && debugRoot.isNotEmpty) {
      return File(p.join(debugRoot, bank.fileName));
    }
    final supportDir = await getApplicationSupportDirectory();
    final bankDir = Directory(
      p.join(supportDir.path, ToolboxInstrumentBankCatalog.cacheSubdirectory),
    );
    if (!await bankDir.exists()) {
      await bankDir.create(recursive: true);
    }
    return File(p.join(bankDir.path, bank.fileName));
  }
}

class ToolboxSoundFontInstrumentEngine {
  ToolboxSoundFontInstrumentEngine({
    ToolboxMidiSynthAdapter? synth,
    ToolboxInstrumentBankStore bankStore = const ToolboxInstrumentBankStore(),
    CstCloudResourceCacheService? resourceCache,
    bool Function()? platformSupported,
  }) : _synth = synth ?? ToolboxFlutterMidiEngineAdapter(),
       _bankStore = bankStore,
       _resourceCache = resourceCache,
       _platformSupported = platformSupported ?? _defaultPlatformSupported;

  final ToolboxMidiSynthAdapter _synth;
  final ToolboxInstrumentBankStore _bankStore;
  final CstCloudResourceCacheService? _resourceCache;
  final bool Function() _platformSupported;
  final AppLogService _log = AppLogService.instance;

  String? _loadedBankId;
  final Map<int, String> _selectedPatchByChannel = <int, String>{};
  bool _failed = false;

  bool get isLoaded => _loadedBankId != null;

  static bool _defaultPlatformSupported() {
    if (kIsWeb) {
      return false;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<bool> loadBank(ToolboxInstrumentBankSpec bank) async {
    if (_failed || !_platformSupported()) {
      return false;
    }
    if (_loadedBankId == bank.id) {
      return true;
    }
    try {
      final file = await _resolveValidatedBankFile(bank);
      if (file == null) {
        return false;
      }
      await _synth.unmute();
      final loaded = await _synth.loadSoundfont(file.path);
      if (!loaded) {
        _failed = true;
        return false;
      }
      _loadedBankId = bank.id;
      _selectedPatchByChannel.clear();
      return true;
    } catch (error, stackTrace) {
      _failed = true;
      _log.e(
        'toolbox_instrument',
        'soundfont bank load failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'bankId': bank.id},
      );
      return false;
    }
  }

  Future<File?> _resolveValidatedBankFile(
    ToolboxInstrumentBankSpec bank,
  ) async {
    final resourceCache = _resourceCache;
    final remoteKey = bank.remoteKey?.trim() ?? '';
    if (resourceCache != null && remoteKey.isNotEmpty) {
      try {
        final remoteFile = await resourceCache.ensureFileDownloaded(
          remoteKey,
          cacheRelativePath: remoteKey,
        );
        final remoteValid = await _isValidBankFile(
          remoteFile,
          bank,
          source: 'remote_cache',
          deleteInvalidFile: true,
        );
        if (remoteValid) {
          return remoteFile;
        }
      } catch (error, stackTrace) {
        _log.w(
          'toolbox_instrument',
          'soundfont remote download failed; trying local bank file',
          data: <String, Object?>{'bankId': bank.id, 'remoteKey': remoteKey},
        );
        _log.e(
          'toolbox_instrument',
          'soundfont remote download detail',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{'bankId': bank.id, 'remoteKey': remoteKey},
        );
      }
    }
    final localFile = await _bankStore.localFileFor(bank);
    final localValid = await _isValidBankFile(
      localFile,
      bank,
      source: 'local_bank',
    );
    return localValid ? localFile : null;
  }

  Future<bool> _isValidBankFile(
    File file,
    ToolboxInstrumentBankSpec bank, {
    required String source,
    bool deleteInvalidFile = false,
  }) async {
    if (!await file.exists()) {
      return false;
    }

    final actualSizeBytes = await file.length();
    final expectedSizeBytes = bank.sizeBytes;
    if (expectedSizeBytes != null &&
        expectedSizeBytes > 0 &&
        actualSizeBytes != expectedSizeBytes) {
      _log.w(
        'toolbox_instrument',
        'soundfont bank size mismatch',
        data: <String, Object?>{
          'bankId': bank.id,
          'source': source,
          'path': file.path,
          'expectedSizeBytes': expectedSizeBytes,
          'actualSizeBytes': actualSizeBytes,
        },
      );
      if (deleteInvalidFile) {
        await _deleteInvalidBankFile(file, bank, source);
      }
      return false;
    }

    final expectedSha256 = bank.sha256?.trim().toLowerCase();
    if (expectedSha256 != null && expectedSha256.isNotEmpty) {
      final actualSha256 = (await sha256.bind(file.openRead()).first)
          .toString()
          .toLowerCase();
      if (actualSha256 != expectedSha256) {
        _log.w(
          'toolbox_instrument',
          'soundfont bank sha256 mismatch',
          data: <String, Object?>{
            'bankId': bank.id,
            'source': source,
            'path': file.path,
            'expectedSha256': expectedSha256,
            'actualSha256': actualSha256,
          },
        );
        if (deleteInvalidFile) {
          await _deleteInvalidBankFile(file, bank, source);
        }
        return false;
      }
    }
    return true;
  }

  Future<void> _deleteInvalidBankFile(
    File file,
    ToolboxInstrumentBankSpec bank,
    String source,
  ) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error, stackTrace) {
      _log.e(
        'toolbox_instrument',
        'failed to delete invalid soundfont bank cache',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'bankId': bank.id,
          'source': source,
          'path': file.path,
        },
      );
    }
  }

  Future<bool> ensurePatch({
    required ToolboxInstrumentBankSpec bank,
    required ToolboxInstrumentPatch patch,
    double volume = 1.0,
    double reverb = 0.18,
  }) async {
    final loaded = await loadBank(bank);
    if (!loaded) {
      return false;
    }
    final channel = patch.channel.clamp(0, 15).toInt();
    if (_selectedPatchByChannel[channel] != patch.id) {
      await _synth.changeProgram(
        program: patch.program.clamp(0, 127).toInt(),
        channel: channel,
      );
      _selectedPatchByChannel[channel] = patch.id;
    }
    await _synth.setVolume(
      volume: (volume.clamp(0.0, 1.0) * 127).round().clamp(0, 127).toInt(),
      channel: channel,
    );
    await _synth.setReverb(
      roomSize: reverb.clamp(0.0, 1.0).toDouble(),
      damping: 0.42,
      width: 0.72,
      level: (reverb * 0.9).clamp(0.0, 0.55).toDouble(),
    );
    return true;
  }

  Future<bool> noteOn({
    required ToolboxInstrumentBankSpec bank,
    required ToolboxInstrumentPatch patch,
    required int midiNote,
    required double velocity,
    double volume = 1.0,
    double reverb = 0.18,
  }) async {
    final ready = await ensurePatch(
      bank: bank,
      patch: patch,
      volume: volume,
      reverb: reverb,
    );
    if (!ready) {
      return false;
    }
    await _synth.playNote(
      note: midiNote.clamp(0, 127).toInt(),
      velocity: (velocity.clamp(0.05, 1.0) * 127).round().clamp(1, 127).toInt(),
      channel: patch.channel.clamp(0, 15).toInt(),
    );
    return true;
  }

  Future<void> noteOff({
    required ToolboxInstrumentPatch patch,
    required int midiNote,
  }) {
    return _synth.stopNote(
      note: midiNote.clamp(0, 127).toInt(),
      velocity: 64,
      channel: patch.channel.clamp(0, 15).toInt(),
    );
  }

  Future<void> dispose() async {
    try {
      await _synth.stopAllNotes();
      await _synth.unloadSoundfont();
    } catch (_) {
      // Best-effort cleanup; fallback synthesis remains available.
    }
    _loadedBankId = null;
    _selectedPatchByChannel.clear();
  }
}

class ToolboxSampledMidiNotePlayer implements ToolboxNotePlayer {
  ToolboxSampledMidiNotePlayer({
    required this.engine,
    required this.bank,
    required this.patch,
    required this.midiNote,
    required this.velocity,
    required this.releaseAfter,
    this.volume = 1.0,
    this.reverb = 0.18,
  });

  final ToolboxSoundFontInstrumentEngine engine;
  final ToolboxInstrumentBankSpec bank;
  final ToolboxInstrumentPatch patch;
  final int midiNote;
  final double velocity;
  final Duration releaseAfter;
  final double volume;
  final double reverb;
  Timer? _releaseTimer;

  @override
  Future<void> play({double volume = 1.0, double playbackRate = 1.0}) async {
    _releaseTimer?.cancel();
    final played = await engine.noteOn(
      bank: bank,
      patch: patch,
      midiNote: midiNote,
      velocity: velocity * volume,
      volume: this.volume * volume,
      reverb: reverb,
    );
    if (!played) {
      return;
    }
    _releaseTimer = Timer(releaseAfter, () {
      unawaited(engine.noteOff(patch: patch, midiNote: midiNote));
    });
  }

  @override
  Future<void> warmUp() {
    return engine.ensurePatch(
      bank: bank,
      patch: patch,
      volume: volume,
      reverb: reverb,
    );
  }

  @override
  Future<void> stop() async {
    _releaseTimer?.cancel();
    _releaseTimer = null;
    await engine.noteOff(patch: patch, midiNote: midiNote);
  }

  @override
  Future<void> dispose() => stop();
}
