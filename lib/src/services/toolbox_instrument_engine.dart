part of 'toolbox_audio_service.dart';

enum ToolboxInstrumentId {
  piano,
  guitar,
  flute,
  violin,
  kalimba,
  chimes,
  xylophone,
  vibraphone,
  marimba,
  glockenspiel,
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
  static const String fluidR3MonoGmRemoteKey = 'SoundFont/FluidR3Mono_GM.sf3';

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

  static const ToolboxInstrumentPatch acousticGuitarNylon =
      ToolboxInstrumentPatch(
        id: 'gm_acoustic_guitar_nylon',
        instrumentId: ToolboxInstrumentId.guitar,
        program: 24,
        channel: 1,
      );

  static const ToolboxInstrumentPatch violin = ToolboxInstrumentPatch(
    id: 'gm_violin',
    instrumentId: ToolboxInstrumentId.violin,
    program: 40,
    channel: 2,
  );

  static const ToolboxInstrumentPatch flute = ToolboxInstrumentPatch(
    id: 'gm_flute',
    instrumentId: ToolboxInstrumentId.flute,
    program: 73,
    channel: 3,
  );

  static const ToolboxInstrumentPatch orchestralHarp = ToolboxInstrumentPatch(
    id: 'gm_orchestral_harp',
    instrumentId: ToolboxInstrumentId.harp,
    program: 46,
    channel: 4,
  );

  static const ToolboxInstrumentPatch kalimba = ToolboxInstrumentPatch(
    id: 'gm_kalimba',
    instrumentId: ToolboxInstrumentId.kalimba,
    program: 108,
    channel: 5,
  );

  static const ToolboxInstrumentPatch tubularBells = ToolboxInstrumentPatch(
    id: 'gm_tubular_bells',
    instrumentId: ToolboxInstrumentId.chimes,
    program: 14,
    channel: 6,
  );

  static const ToolboxInstrumentPatch xylophone = ToolboxInstrumentPatch(
    id: 'gm_xylophone',
    instrumentId: ToolboxInstrumentId.xylophone,
    program: 13,
    channel: 7,
  );

  static const ToolboxInstrumentPatch vibraphone = ToolboxInstrumentPatch(
    id: 'gm_vibraphone',
    instrumentId: ToolboxInstrumentId.vibraphone,
    program: 11,
    channel: 8,
  );

  static const ToolboxInstrumentPatch marimba = ToolboxInstrumentPatch(
    id: 'gm_marimba',
    instrumentId: ToolboxInstrumentId.marimba,
    program: 12,
    channel: 9,
  );

  static const ToolboxInstrumentPatch glockenspiel = ToolboxInstrumentPatch(
    id: 'gm_glockenspiel',
    instrumentId: ToolboxInstrumentId.glockenspiel,
    program: 9,
    channel: 10,
  );
}

class ToolboxInstrumentPitch {
  const ToolboxInstrumentPitch._();

  static int midiFromFrequency(double frequency) {
    if (frequency <= 0 || frequency.isNaN || frequency.isInfinite) {
      return 60;
    }
    final midi = 69 + 12 * (math.log(frequency / 440.0) / math.ln2);
    return midi.round().clamp(0, 127).toInt();
  }
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
  Future<bool> unloadSoundfont() async {
    // flutter_midi_engine 0.1.3 logs MissingPluginException before returning
    // false on platforms that do not implement unloadSoundfont. Treat the
    // SoundFont as process-scoped and only stop active notes during dispose.
    return true;
  }

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
  final _ToolboxAsyncLock _configurationLock = _ToolboxAsyncLock();
  final Map<int, String> _selectedPatchByChannel = <int, String>{};
  final Map<int, int> _volumeByChannel = <int, int>{};
  double? _lastReverb;
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
      _volumeByChannel.clear();
      _lastReverb = null;
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
    return _configurationLock.synchronized(() async {
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
      final midiVolume = (volume.clamp(0.0, 1.0) * 127)
          .round()
          .clamp(0, 127)
          .toInt();
      if (_volumeByChannel[channel] != midiVolume) {
        await _synth.setVolume(volume: midiVolume, channel: channel);
        _volumeByChannel[channel] = midiVolume;
      }
      final normalizedReverb = reverb.clamp(0.0, 1.0).toDouble();
      if (_lastReverb == null ||
          (_lastReverb! - normalizedReverb).abs() >= 0.01) {
        await _synth.setReverb(
          roomSize: normalizedReverb,
          damping: 0.42,
          width: 0.72,
          level: (normalizedReverb * 0.9).clamp(0.0, 0.55).toDouble(),
        );
        _lastReverb = normalizedReverb;
      }
      return true;
    });
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
    _volumeByChannel.clear();
    _lastReverb = null;
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
  final _ToolboxAsyncLock _noteLock = _ToolboxAsyncLock();
  Timer? _releaseTimer;
  bool _noteActive = false;

  @override
  Future<void> play({double volume = 1.0, double playbackRate = 1.0}) {
    return _noteLock.synchronized(() async {
      _releaseTimer?.cancel();
      await _releaseActiveNote();
      final played = await engine.noteOn(
        bank: bank,
        patch: patch,
        midiNote: midiNote,
        velocity: velocity * volume,
        volume: this.volume,
        reverb: reverb,
      );
      if (!played) {
        return;
      }
      _noteActive = true;
      _releaseTimer = Timer(releaseAfter, () {
        unawaited(_releaseActiveNote());
      });
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
  Future<void> stop() {
    return _noteLock.synchronized(() async {
      _releaseTimer?.cancel();
      _releaseTimer = null;
      await _releaseActiveNote();
    });
  }

  @override
  Future<void> dispose() => stop();

  Future<void> _releaseActiveNote() async {
    if (!_noteActive) {
      return;
    }
    _noteActive = false;
    await engine.noteOff(patch: patch, midiNote: midiNote);
  }
}

class ToolboxSampledMidiSustainController {
  ToolboxSampledMidiSustainController({
    required this.engine,
    required this.bank,
    required this.patch,
    this.volume = 1.0,
    this.reverb = 0.18,
  });

  final ToolboxSoundFontInstrumentEngine engine;
  final ToolboxInstrumentBankSpec bank;
  final ToolboxInstrumentPatch patch;
  final double volume;
  final double reverb;
  final _ToolboxAsyncLock _noteLock = _ToolboxAsyncLock();

  int? _activeMidiNote;

  Future<void> warmUp() {
    return engine.ensurePatch(
      bank: bank,
      patch: patch,
      volume: volume,
      reverb: reverb,
    );
  }

  Future<bool> start({
    required int midiNote,
    required double velocity,
    double? volume,
    double? reverb,
  }) {
    return _noteLock.synchronized(() async {
      final normalizedNote = midiNote.clamp(0, 127).toInt();
      final normalizedVolume = (volume ?? this.volume)
          .clamp(0.0, 1.0)
          .toDouble();
      final normalizedReverb = (reverb ?? this.reverb)
          .clamp(0.0, 1.0)
          .toDouble();
      if (_activeMidiNote == normalizedNote) {
        return engine.ensurePatch(
          bank: bank,
          patch: patch,
          volume: normalizedVolume,
          reverb: normalizedReverb,
        );
      }
      await _releaseActiveNote();
      final played = await engine.noteOn(
        bank: bank,
        patch: patch,
        midiNote: normalizedNote,
        velocity: velocity,
        volume: normalizedVolume,
        reverb: normalizedReverb,
      );
      if (played) {
        _activeMidiNote = normalizedNote;
      }
      return played;
    });
  }

  Future<bool> update({double? volume, double? reverb}) {
    return _noteLock.synchronized(() {
      return engine.ensurePatch(
        bank: bank,
        patch: patch,
        volume: (volume ?? this.volume).clamp(0.0, 1.0).toDouble(),
        reverb: (reverb ?? this.reverb).clamp(0.0, 1.0).toDouble(),
      );
    });
  }

  Future<void> stop() {
    return _noteLock.synchronized(_releaseActiveNote);
  }

  Future<void> dispose() => stop();

  Future<void> _releaseActiveNote() async {
    final activeMidiNote = _activeMidiNote;
    if (activeMidiNote == null) {
      return;
    }
    _activeMidiNote = null;
    await engine.noteOff(patch: patch, midiNote: activeMidiNote);
  }
}
