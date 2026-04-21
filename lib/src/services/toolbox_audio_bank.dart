part of 'toolbox_audio_service.dart';

class _ToolboxAudioLruCache {
  _ToolboxAudioLruCache({
    int capacity = _defaultCapacity,
    int maxBytes = _defaultMaxBytes,
  })
    : _capacity = capacity.clamp(_minCapacity, _maxCapacity).toInt(),
      _maxBytes = maxBytes.clamp(_minMaxBytes, _maxMaxBytes).toInt();

  static const int _defaultCapacity = 320;
  static const int _minCapacity = 1;
  static const int _maxCapacity = 4096;
  static const int _defaultMaxBytes = 48 * 1024 * 1024;
  static const int _minMaxBytes = 256 * 1024;
  static const int _maxMaxBytes = 512 * 1024 * 1024;

  final LinkedHashMap<String, Uint8List> _entries =
      LinkedHashMap<String, Uint8List>();
  int _capacity;
  int _maxBytes;
  int _bytesEstimate = 0;

  int get capacity => _capacity;

  set capacity(int value) {
    _capacity = value.clamp(_minCapacity, _maxCapacity).toInt();
    _evictIfNeeded();
  }

  int get maxBytes => _maxBytes;

  set maxBytes(int value) {
    _maxBytes = value.clamp(_minMaxBytes, _maxMaxBytes).toInt();
    _evictIfNeeded();
  }

  int get length => _entries.length;

  int get bytesEstimate => _bytesEstimate;

  Uint8List putIfAbsent(String key, Uint8List Function() ifAbsent) {
    final existing = _entries.remove(key);
    if (existing != null) {
      _entries[key] = existing;
      return existing;
    }
    final value = ifAbsent();
    _entries[key] = value;
    _bytesEstimate += value.lengthInBytes;
    _evictIfNeeded();
    return value;
  }

  int clearDomain(String domain) {
    if (domain.isEmpty) return 0;
    final prefix = '$domain:';
    final targets = _entries.keys
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
    for (final key in targets) {
      final removed = _entries.remove(key);
      if (removed != null) {
        _bytesEstimate -= removed.lengthInBytes;
      }
    }
    _bytesEstimate = _bytesEstimate.clamp(0, _maxMaxBytes).toInt();
    return targets.length;
  }

  void clear() {
    _entries.clear();
    _bytesEstimate = 0;
  }

  void _evictIfNeeded() {
    while (_entries.length > _capacity || _bytesEstimate > _maxBytes) {
      final iterator = _entries.entries.iterator;
      if (!iterator.moveNext()) {
        return;
      }
      final eldest = iterator.current;
      _entries.remove(eldest.key);
      _bytesEstimate -= eldest.value.lengthInBytes;
    }
    _bytesEstimate = _bytesEstimate.clamp(0, _maxMaxBytes).toInt();
  }
}

class ToolboxAudioBank {
  ToolboxAudioBank._();

  static final _ToolboxAudioLruCache _cache = _ToolboxAudioLruCache();

  static int get cacheCapacity => _cache.capacity;

  static int get cacheEntryCount => _cache.length;

  static int get cacheBytesEstimate => _cache.bytesEstimate;

  static int get cacheMaxBytes => _cache.maxBytes;

  static void configureCache({int? maxEntries, int? maxBytes}) {
    if (maxEntries != null) {
      _cache.capacity = maxEntries;
    }
    if (maxBytes != null) {
      _cache.maxBytes = maxBytes;
    }
  }

  static void clearCache() {
    _cache.clear();
  }

  static int clearDomainCache(String domain) {
    final normalized = domain.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 0;
    }
    return _cache.clearDomain(normalized);
  }

  static Uint8List soothingLoop(String presetId) {
    return _cache.putIfAbsent(
      'soothing:$presetId',
      () => _buildSoothingLoop(presetId),
    );
  }

  static Uint8List soothingSceneLoop(String sceneId) {
    return _cache.putIfAbsent(
      'scene:$sceneId',
      () => _buildSoothingSceneLoop(sceneId),
    );
  }

  static Uint8List harpNote(
    double frequency, {
    String style = 'silk',
    double reverb = 0.24,
    double decay = 1.0,
    int variant = 0,
  }) {
    final normalizedStyle = switch (style) {
      'warm' => 'warm',
      'crystal' => 'crystal',
      'bright' => 'bright',
      'nylon' => 'nylon',
      'glass' => 'glass',
      'concert' => 'concert',
      'steel' => 'steel',
      _ => 'silk',
    };
    final normalizedReverb = reverb.clamp(0.0, 0.8).toDouble();
    final normalizedDecay = (decay.clamp(0.55, 1.35) * 20).round() / 20;
    final normalizedVariant = variant.clamp(0, 31).toInt();
    final key =
        'harp:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '${normalizedReverb.toStringAsFixed(2)}:'
        '${normalizedDecay.toStringAsFixed(2)}:$normalizedVariant';
    return _cache.putIfAbsent(
      key,
      () => _buildPluckNote(
        frequency: frequency,
        durationSeconds: 2.4,
        style: normalizedStyle,
        reverb: normalizedReverb,
        decay: normalizedDecay.toDouble(),
        variant: normalizedVariant,
      ),
    );
  }

  static Uint8List pianoNote(
    double frequency, {
    String style = 'concert',
    double reverb = 0.12,
    double decay = 1.0,
    double velocity = 0.7,
    int variant = 0,
  }) {
    final normalizedStyle = switch (style) {
      'bright' => 'bright',
      'felt' => 'felt',
      'upright' => 'upright',
      _ => 'concert',
    };
    final normalizedReverb = (reverb.clamp(0.0, 0.55) * 20).round() / 20;
    final normalizedDecay = (decay.clamp(0.7, 1.8) * 20).round() / 20;
    final normalizedVelocity = (velocity.clamp(0.2, 1.0) * 20).round() / 20;
    final normalizedVariant = variant.clamp(0, 31).toInt();
    final key =
        'piano:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '${normalizedReverb.toStringAsFixed(2)}:'
        '${normalizedDecay.toStringAsFixed(2)}:'
        '${normalizedVelocity.toStringAsFixed(2)}:$normalizedVariant';
    return _cache.putIfAbsent(
      key,
      () => _buildPianoNote(
        frequency,
        normalizedStyle,
        reverb: normalizedReverb.toDouble(),
        decay: normalizedDecay.toDouble(),
        velocity: normalizedVelocity.toDouble(),
        variant: normalizedVariant,
      ),
    );
  }

  static Uint8List fluteNote(
    double frequency, {
    String style = 'airy',
    String material = 'wood',
    double breath = 0.6,
    double reverb = 0.22,
    double tail = 0.5,
    bool sustained = false,
  }) {
    final normalizedStyle = _normalizeFluteStyle(style);
    final normalizedMaterial = _normalizeFluteMaterial(material);
    final normalizedBreath = (breath.clamp(0.18, 1.0) * 20).round() / 20;
    final normalizedReverb = (reverb.clamp(0.0, 0.5) * 20).round() / 20;
    final normalizedTail = (tail.clamp(0.15, 1.0) * 20).round() / 20;
    final key =
        'flute:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '$normalizedMaterial:${normalizedBreath.toStringAsFixed(2)}:'
        '${normalizedReverb.toStringAsFixed(2)}:'
        '${normalizedTail.toStringAsFixed(2)}:${sustained ? 'sus' : 'shot'}';
    return _cache.putIfAbsent(
      key,
      () => _buildFluteNote(
        frequency,
        normalizedStyle,
        material: normalizedMaterial,
        breath: normalizedBreath.toDouble(),
        reverb: normalizedReverb.toDouble(),
        tail: normalizedTail.toDouble(),
        sustained: sustained,
      ),
    );
  }

  static Uint8List fluteSustainCore(
    double frequency, {
    String style = 'airy',
    String material = 'wood',
  }) {
    final normalizedStyle = _normalizeFluteStyle(style);
    final normalizedMaterial = _normalizeFluteMaterial(material);
    final key =
        'flute:sustain:core:${frequency.toStringAsFixed(2)}:$normalizedStyle:$normalizedMaterial';
    return _cache.putIfAbsent(
      key,
      () => _buildFluteSustainLayer(
        frequency,
        normalizedStyle,
        material: normalizedMaterial,
        layer: 'core',
      ),
    );
  }

  static Uint8List fluteSustainAir(
    double frequency, {
    String style = 'airy',
    String material = 'wood',
  }) {
    final normalizedStyle = _normalizeFluteStyle(style);
    final normalizedMaterial = _normalizeFluteMaterial(material);
    final key =
        'flute:sustain:air:${frequency.toStringAsFixed(2)}:$normalizedStyle:$normalizedMaterial';
    return _cache.putIfAbsent(
      key,
      () => _buildFluteSustainLayer(
        frequency,
        normalizedStyle,
        material: normalizedMaterial,
        layer: 'air',
      ),
    );
  }

  static Uint8List fluteSustainEdge(
    double frequency, {
    String style = 'airy',
    String material = 'wood',
  }) {
    final normalizedStyle = _normalizeFluteStyle(style);
    final normalizedMaterial = _normalizeFluteMaterial(material);
    final key =
        'flute:sustain:edge:${frequency.toStringAsFixed(2)}:$normalizedStyle:$normalizedMaterial';
    return _cache.putIfAbsent(
      key,
      () => _buildFluteSustainLayer(
        frequency,
        normalizedStyle,
        material: normalizedMaterial,
        layer: 'edge',
      ),
    );
  }

  static Uint8List guitarNote(
    double frequency, {
    String style = 'steel',
    double resonance = 0.5,
    double pickPosition = 0.55,
    double velocity = 0.8,
    bool palmMute = false,
  }) {
    final normalizedStyle = switch (style) {
      'nylon' => 'nylon',
      'ambient' => 'ambient',
      'twelve' => 'twelve',
      _ => 'steel',
    };
    final normalizedResonance = (resonance.clamp(0.0, 1.0) * 10).round() / 10;
    final normalizedPickPosition =
        (pickPosition.clamp(0.05, 0.95) * 10).round() / 10;
    final normalizedVelocity = (velocity.clamp(0.2, 1.0) * 10).round() / 10;
    final key =
        'guitar:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '${normalizedResonance.toStringAsFixed(1)}:'
        '${normalizedPickPosition.toStringAsFixed(1)}:'
        '${normalizedVelocity.toStringAsFixed(1)}:${palmMute ? 'mute' : 'open'}';
    return _cache.putIfAbsent(
      key,
      () => _buildGuitarNote(
        frequency: frequency,
        style: normalizedStyle,
        resonance: normalizedResonance.toDouble(),
        pickPosition: normalizedPickPosition.toDouble(),
        velocity: normalizedVelocity.toDouble(),
        palmMute: palmMute,
      ),
    );
  }

  static Uint8List drumHit(
    String kind, {
    String kit = 'acoustic',
    double tone = 0.5,
    double tail = 0.42,
    String material = 'wood',
  }) {
    final normalizedKind = switch (kind) {
      'kick' => 'kick',
      'snare' => 'snare',
      'hihat' => 'hihat',
      'openhat' => 'openhat',
      'clap' => 'clap',
      'tom' => 'tom',
      _ => 'kick',
    };
    final normalizedKit = switch (kit) {
      'electro' => 'electro',
      'lofi' => 'lofi',
      _ => 'acoustic',
    };
    final normalizedTone = (tone.clamp(0.0, 1.0) * 10).round() / 10;
    final normalizedTail = (tail.clamp(0.0, 1.0) * 10).round() / 10;
    final normalizedMaterial = switch (material) {
      'metal' => 'metal',
      'hybrid' => 'hybrid',
      _ => 'wood',
    };
    final key =
        'drum:$normalizedKind:$normalizedKit:'
        '${normalizedTone.toStringAsFixed(1)}:'
        '${normalizedTail.toStringAsFixed(1)}:$normalizedMaterial';
    return _cache.putIfAbsent(
      key,
      () => _buildDrumHit(
        normalizedKind,
        normalizedKit,
        normalizedTone.toDouble(),
        normalizedTail.toDouble(),
        normalizedMaterial,
      ),
    );
  }

  static Uint8List triangleHit({
    String style = 'orchestral',
    String material = 'steel',
    double strike = 0.65,
    double damping = 0.2,
  }) {
    final normalizedStyle = switch (style) {
      'soft' => 'soft',
      'bright' => 'bright',
      _ => 'orchestral',
    };
    final normalizedMaterial = switch (material) {
      'brass' => 'brass',
      'aluminum' => 'aluminum',
      _ => 'steel',
    };
    final normalizedStrike = (strike.clamp(0.0, 1.0) * 10).round() / 10;
    final normalizedDamping = (damping.clamp(0.0, 1.0) * 10).round() / 10;
    final key =
        'triangle:hit:$normalizedStyle:$normalizedMaterial:'
        '${normalizedStrike.toStringAsFixed(1)}:'
        '${normalizedDamping.toStringAsFixed(1)}';
    return _cache.putIfAbsent(
      key,
      () => _buildTriangleHit(
        normalizedStyle,
        normalizedMaterial,
        normalizedStrike.toDouble(),
        normalizedDamping.toDouble(),
      ),
    );
  }

  static Uint8List guqinNote(
    double frequency, {
    String style = 'silk',
    double resonance = 0.62,
    double slide = 0,
  }) {
    final normalizedStyle = switch (style) {
      'bright' => 'bright',
      'hollow' => 'hollow',
      _ => 'silk',
    };
    final normalizedResonance = (resonance.clamp(0.0, 1.0) * 10).round() / 10;
    final normalizedSlide = (slide.clamp(-1.0, 1.0) * 10).round() / 10;
    final key =
        'guqin:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '${normalizedResonance.toStringAsFixed(1)}:'
        '${normalizedSlide.toStringAsFixed(1)}';
    return _cache.putIfAbsent(
      key,
      () => _buildGuqinNote(
        frequency: frequency,
        style: normalizedStyle,
        resonance: normalizedResonance.toDouble(),
        slide: normalizedSlide.toDouble(),
      ),
    );
  }

  static Uint8List violinNote(
    double frequency, {
    String style = 'solo',
    String variant = 'a',
    double bow = 0.65,
    double reverb = 0.24,
  }) {
    final normalizedStyle = switch (style) {
      'warm' => 'warm',
      'glass' => 'glass',
      _ => 'solo',
    };
    final normalizedVariant = variant == 'b' ? 'b' : 'a';
    final normalizedBow = (bow.clamp(0.15, 1.0) * 20).round() / 20;
    final normalizedReverb = (reverb.clamp(0.0, 0.5) * 20).round() / 20;
    final key =
        'violin:${frequency.toStringAsFixed(2)}:$normalizedStyle:$normalizedVariant:'
        '${normalizedBow.toStringAsFixed(2)}:'
        '${normalizedReverb.toStringAsFixed(2)}';
    return _cache.putIfAbsent(
      key,
      () => _buildViolinNote(
        frequency: frequency,
        style: normalizedStyle,
        variant: normalizedVariant,
        bow: normalizedBow.toDouble(),
        reverb: normalizedReverb.toDouble(),
      ),
    );
  }

  static Uint8List violinSustainCore(
    double frequency, {
    String style = 'solo',
    String variant = 'a',
    double bow = 0.65,
  }) {
    final normalizedStyle = switch (style) {
      'warm' => 'warm',
      'glass' => 'glass',
      _ => 'solo',
    };
    final normalizedVariant = variant == 'b' ? 'b' : 'a';
    final normalizedBow = (bow.clamp(0.15, 1.0) * 20).round() / 20;
    final key =
        'violin:sustain:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '$normalizedVariant:${normalizedBow.toStringAsFixed(2)}';
    return _cache.putIfAbsent(
      key,
      () => _buildViolinSustainCore(
        frequency: frequency,
        style: normalizedStyle,
        variant: normalizedVariant,
        bow: normalizedBow.toDouble(),
      ),
    );
  }

  static Uint8List violinBowAttack(
    double frequency, {
    String style = 'solo',
    String variant = 'a',
    double bow = 0.65,
  }) {
    final normalizedStyle = switch (style) {
      'warm' => 'warm',
      'glass' => 'glass',
      _ => 'solo',
    };
    final normalizedVariant = variant == 'b' ? 'b' : 'a';
    final normalizedBow = (bow.clamp(0.15, 1.0) * 20).round() / 20;
    final key =
        'violin:attack:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '$normalizedVariant:${normalizedBow.toStringAsFixed(2)}';
    return _cache.putIfAbsent(
      key,
      () => _buildViolinBowAttack(
        frequency: frequency,
        style: normalizedStyle,
        variant: normalizedVariant,
        bow: normalizedBow.toDouble(),
      ),
    );
  }

  static Uint8List violinRoomTail(
    double frequency, {
    String style = 'solo',
    String variant = 'a',
    double bow = 0.65,
    double reverb = 0.24,
  }) {
    final normalizedStyle = switch (style) {
      'warm' => 'warm',
      'glass' => 'glass',
      _ => 'solo',
    };
    final normalizedVariant = variant == 'b' ? 'b' : 'a';
    final normalizedBow = (bow.clamp(0.15, 1.0) * 20).round() / 20;
    final normalizedReverb = (reverb.clamp(0.0, 0.5) * 20).round() / 20;
    final key =
        'violin:tail:${frequency.toStringAsFixed(2)}:$normalizedStyle:'
        '$normalizedVariant:${normalizedBow.toStringAsFixed(2)}:'
        '${normalizedReverb.toStringAsFixed(2)}';
    return _cache.putIfAbsent(
      key,
      () => _buildViolinRoomTail(
        frequency: frequency,
        style: normalizedStyle,
        variant: normalizedVariant,
        bow: normalizedBow.toDouble(),
        reverb: normalizedReverb.toDouble(),
      ),
    );
  }

  static Uint8List metronomeClick({required bool accent}) {
    final key = accent ? 'metronome:accent' : 'metronome:regular';
    return _cache.putIfAbsent(
      key,
      () => _buildClick(
        accent ? 1560.0 : 1080.0,
        overtone: accent ? 1960.0 : 1420.0,
        durationSeconds: accent ? 0.11 : 0.085,
      ),
    );
  }

  static Uint8List focusBeatClick({
    required String style,
    required int layer,
    int variant = 0,
  }) {
    final normalizedStyle = switch (style) {
      'hypno' => 'hypno',
      'dew' => 'dew',
      'gear' => 'gear',
      'steps' => 'steps',
      _ => 'pendulum',
    };
    final normalizedLayer = layer.clamp(0, 3).toInt();
    final normalizedVariant = variant.clamp(0, 31).toInt();
    final key =
        'focus_beat:$normalizedStyle:$normalizedLayer:$normalizedVariant';
    return _cache.putIfAbsent(
      key,
      () => _buildFocusBeatClick(
        style: normalizedStyle,
        layer: normalizedLayer,
        variant: normalizedVariant,
      ),
    );
  }

  static Uint8List prayerBeadClick({
    String style = 'sandalwood',
    bool accent = false,
    int variant = 0,
  }) {
    final normalizedStyle = switch (style) {
      'jade' => 'jade',
      'lapis' => 'lapis',
      'bodhi' => 'bodhi',
      'obsidian' => 'obsidian',
      _ => 'sandalwood',
    };
    final normalizedVariant = variant.clamp(0, 31).toInt();
    final key =
        'prayer_bead:$normalizedStyle:${accent ? 1 : 0}:$normalizedVariant';
    return _cache.putIfAbsent(
      key,
      () => _buildPrayerBeadClick(
        style: normalizedStyle,
        accent: accent,
        variant: normalizedVariant,
      ),
    );
  }

  static Uint8List singingBowlTone({
    required double frequency,
    String style = 'crystal',
    int variant = 0,
  }) {
    final normalizedFrequency = frequency.clamp(80.0, 1200.0).toDouble();
    final normalizedStyle = switch (style) {
      'brass' => 'brass',
      'deep' => 'deep',
      'pure' => 'pure',
      _ => 'crystal',
    };
    final normalizedVariant = variant.clamp(0, 31).toInt();
    final key =
        'singing_bowl:${normalizedFrequency.toStringAsFixed(2)}:'
        '$normalizedStyle:$normalizedVariant';
    return _cache.putIfAbsent(
      key,
      () => _buildSingingBowlTone(
        frequency: normalizedFrequency,
        style: normalizedStyle,
        variant: normalizedVariant,
      ),
    );
  }

  static Uint8List woodfishClick({
    String style = 'temple',
    double resonance = 0.7,
    double brightness = 0.48,
    double pitch = 0.0,
    double strike = 0.55,
    bool accent = false,
    int variant = 0,
  }) {
    final normalizedStyle = switch (style) {
      'sandal' => 'sandal',
      'bright' => 'bright',
      'hollow' => 'hollow',
      'night' => 'night',
      _ => 'temple',
    };
    final normalizedResonance = (resonance.clamp(0.0, 1.0) * 20).round() / 20;
    final normalizedBrightness = (brightness.clamp(0.0, 1.0) * 20).round() / 20;
    final normalizedPitch = (pitch.clamp(-6.0, 6.0) * 2).round() / 2;
    final normalizedStrike = (strike.clamp(0.0, 1.0) * 20).round() / 20;
    final normalizedVariant = variant.clamp(0, 31).toInt();
    final key =
        'woodfish:$normalizedStyle:${normalizedResonance.toStringAsFixed(2)}:'
        '${normalizedBrightness.toStringAsFixed(2)}:'
        '${normalizedPitch.toStringAsFixed(1)}:'
        '${normalizedStrike.toStringAsFixed(2)}:'
        '${accent ? 1 : 0}:$normalizedVariant';
    return _cache.putIfAbsent(
      key,
      () => _buildWoodfishClick(
        style: normalizedStyle,
        resonance: normalizedResonance.toDouble(),
        brightness: normalizedBrightness.toDouble(),
        pitch: normalizedPitch.toDouble(),
        strike: normalizedStrike.toDouble(),
        accent: accent,
        variant: normalizedVariant,
      ),
    );
  }
}
