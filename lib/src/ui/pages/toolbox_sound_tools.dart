import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_audio_service.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'toolbox_tool_shell.dart';

class SoothingMusicToolPage extends StatelessWidget {
  const SoothingMusicToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '舒缓轻音', en: 'Soothing music'),
      subtitle: pickUiText(
        i18n,
        zh: '本地合成的柔和氛围音色，用来安静下来、放慢节奏。',
        en: 'Locally synthesized soft textures for slowing down and settling your rhythm.',
      ),
      child: const _SoothingMusicTool(),
    );
  }
}

class HarpToolPage extends StatelessWidget {
  const HarpToolPage({super.key, this.fullScreen = false});

  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    if (fullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _HarpTool(
          fullScreen: true,
          onExitFullScreen: () => Navigator.of(context).pop(),
        ),
      );
    }
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '空灵竖琴', en: 'Ethereal harp'),
      subtitle: pickUiText(
        i18n,
        zh: '轻扫琴弦或单独点弦，做一个安静的触感乐器。',
        en: 'Glide across the strings or pluck them one by one like a tactile calm instrument.',
      ),
      child: const _HarpTool(),
    );
  }
}

class FocusBeatsToolPage extends StatelessWidget {
  const FocusBeatsToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '专注节拍', en: 'Focus beats'),
      subtitle: pickUiText(
        i18n,
        zh: '可调 BPM 的本地节拍器，适合写作、学习或呼吸同步。',
        en: 'A local BPM-adjustable metronome for writing, study, or breath syncing.',
      ),
      child: const _FocusBeatsTool(),
    );
  }
}

class WoodfishToolPage extends StatelessWidget {
  const WoodfishToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '电子木鱼', en: 'Digital woodfish'),
      subtitle: pickUiText(
        i18n,
        zh: '轻敲一下，记一次数，也给自己一个短暂的停顿。',
        en: 'Tap once for a count and give yourself a short reset in the middle of the day.',
      ),
      child: const _WoodfishTool(),
    );
  }
}

class _SoothingPreset {
  const _SoothingPreset({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

class _SoothingMusicTool extends StatefulWidget {
  const _SoothingMusicTool();

  @override
  State<_SoothingMusicTool> createState() => _SoothingMusicToolState();
}

class _SoothingMusicToolState extends State<_SoothingMusicTool>
    with SingleTickerProviderStateMixin {
  static const List<_SoothingPreset> _presets = <_SoothingPreset>[
    _SoothingPreset(id: 'moon', title: 'Moon', subtitle: 'Soft floating bed'),
    _SoothingPreset(id: 'mist', title: 'Mist', subtitle: 'Airy and slow'),
    _SoothingPreset(
      id: 'harbor',
      title: 'Harbor',
      subtitle: 'Brighter for evening focus',
    ),
  ];

  final ToolboxLoopController _loop = ToolboxLoopController();
  late final AnimationController _pulseController;

  String _presetId = _presets.first.id;
  double _volume = 0.56;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    unawaited(_loop.dispose());
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_playing) {
      await _loop.stop();
      _pulseController.stop();
      setState(() {
        _playing = false;
      });
      return;
    }
    await _loop.play(ToolboxAudioBank.soothingLoop(_presetId), volume: _volume);
    _pulseController.repeat();
    setState(() {
      _playing = true;
    });
  }

  Future<void> _selectPreset(String presetId) async {
    if (_presetId == presetId) return;
    setState(() {
      _presetId = presetId;
    });
    if (_playing) {
      await _loop.play(
        ToolboxAudioBank.soothingLoop(_presetId),
        volume: _volume,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preset = _presets.firstWhere((item) => item.id == _presetId);

    return Column(
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 220,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final t = _playing ? _pulseController.value : 0.0;
                      final scale = 0.94 + math.sin(t * math.pi * 2) * 0.04;
                      final glow = 0.18 + math.sin(t * math.pi * 2) * 0.08;
                      return Center(
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: <Color>[
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.24 + glow,
                                  ),
                                  theme.colorScheme.primaryContainer,
                                  theme.colorScheme.surfaceContainerHighest,
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12 + glow,
                                  ),
                                  blurRadius: 32,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  _playing
                                      ? Icons.graphic_eq_rounded
                                      : Icons.spa_rounded,
                                  size: 42,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  preset.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preset.subtitle,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _togglePlayback,
                  icon: Icon(
                    _playing
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                  ),
                  label: Text(_playing ? 'Pause ambience' : 'Start ambience'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionHeader(
                  title: 'Preset',
                  subtitle:
                      'Switch between three locally synthesized textures.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets
                      .map((item) {
                        final selected = item.id == _presetId;
                        return ChoiceChip(
                          label: Text(item.title),
                          selected: selected,
                          onSelected: (_) => _selectPreset(item.id),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
                Text(
                  'Volume ${(100 * _volume).round()}%',
                  style: theme.textTheme.labelLarge,
                ),
                Slider(
                  value: _volume,
                  min: 0.15,
                  max: 1,
                  onChanged: (value) async {
                    setState(() {
                      _volume = value;
                    });
                    if (_playing) {
                      await _loop.setVolume(value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HarpTool extends StatefulWidget {
  const _HarpTool({this.fullScreen = false, this.onExitFullScreen});

  final bool fullScreen;
  final VoidCallback? onExitFullScreen;

  @override
  State<_HarpTool> createState() => _HarpToolState();
}

class _HarpScalePreset {
  const _HarpScalePreset({
    required this.id,
    required this.label,
    required this.notes,
  });

  final String id;
  final String label;
  final List<double> notes;
}

class _HarpChordPreset {
  const _HarpChordPreset({
    required this.id,
    required this.label,
    required this.intervals,
  });

  final String id;
  final String label;
  final List<int> intervals;
}

class _HarpPalettePreset {
  const _HarpPalettePreset({
    required this.id,
    required this.label,
    required this.colors,
  });

  final String id;
  final String label;
  final List<Color> colors;
}

class _HarpPluckPreset {
  const _HarpPluckPreset({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class _HarpPatternPreset {
  const _HarpPatternPreset({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class _HarpRealismPreset {
  const _HarpRealismPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.scaleId,
    required this.chordId,
    required this.pluckStyleId,
    required this.patternId,
    required this.paletteId,
    required this.reverb,
    required this.damping,
    required this.swipeThreshold,
    required this.chordResonanceEnabled,
  });

  final String id;
  final String label;
  final String description;
  final String scaleId;
  final String chordId;
  final String pluckStyleId;
  final String patternId;
  final String paletteId;
  final double reverb;
  final double damping;
  final double swipeThreshold;
  final bool chordResonanceEnabled;
}

class _HarpToolState extends State<_HarpTool>
    with SingleTickerProviderStateMixin {
  static const int _stringCount = 12;
  static const double _springStiffness = 34;
  static const List<_HarpScalePreset> _scalePresets = <_HarpScalePreset>[
    _HarpScalePreset(
      id: 'c_major',
      label: 'C Major',
      notes: <double>[
        130.81,
        146.83,
        164.81,
        196.0,
        220.0,
        261.63,
        293.66,
        329.63,
        392.0,
        440.0,
        523.25,
        587.33,
      ],
    ),
    _HarpScalePreset(
      id: 'a_minor',
      label: 'A Minor',
      notes: <double>[
        110.0,
        130.81,
        146.83,
        164.81,
        196.0,
        220.0,
        261.63,
        293.66,
        329.63,
        392.0,
        440.0,
        523.25,
      ],
    ),
    _HarpScalePreset(
      id: 'd_dorian',
      label: 'D Dorian',
      notes: <double>[
        146.83,
        164.81,
        174.61,
        196.0,
        220.0,
        261.63,
        293.66,
        329.63,
        349.23,
        392.0,
        440.0,
        523.25,
      ],
    ),
    _HarpScalePreset(
      id: 'zen',
      label: 'Zen Pentatonic',
      notes: <double>[
        130.81,
        138.59,
        155.56,
        196.0,
        207.65,
        261.63,
        277.18,
        311.13,
        392.0,
        415.3,
        523.25,
        554.37,
      ],
    ),
    _HarpScalePreset(
      id: 'c_lydian',
      label: 'C Lydian',
      notes: <double>[
        130.81,
        146.83,
        164.81,
        185.0,
        196.0,
        220.0,
        246.94,
        261.63,
        293.66,
        329.63,
        369.99,
        392.0,
      ],
    ),
    _HarpScalePreset(
      id: 'hirajoshi',
      label: 'Hirajoshi',
      notes: <double>[
        130.81,
        138.59,
        174.61,
        196.0,
        233.08,
        261.63,
        277.18,
        349.23,
        392.0,
        466.16,
        523.25,
        554.37,
      ],
    ),
  ];
  static const List<_HarpChordPreset> _chordPresets = <_HarpChordPreset>[
    _HarpChordPreset(
      id: 'major',
      label: 'Major',
      intervals: <int>[0, 4, 7, 12],
    ),
    _HarpChordPreset(
      id: 'minor',
      label: 'Minor',
      intervals: <int>[0, 3, 7, 12],
    ),
    _HarpChordPreset(id: 'sus2', label: 'Sus2', intervals: <int>[0, 2, 7, 12]),
    _HarpChordPreset(id: 'add9', label: 'Add9', intervals: <int>[0, 4, 7, 14]),
    _HarpChordPreset(id: 'sus4', label: 'Sus4', intervals: <int>[0, 5, 7, 12]),
    _HarpChordPreset(id: 'maj7', label: 'Maj7', intervals: <int>[0, 4, 7, 11]),
    _HarpChordPreset(id: 'min7', label: 'Min7', intervals: <int>[0, 3, 7, 10]),
  ];
  static const List<_HarpPluckPreset> _pluckPresets = <_HarpPluckPreset>[
    _HarpPluckPreset(
      id: 'silk',
      label: 'Silk',
      description: 'Balanced and soft.',
    ),
    _HarpPluckPreset(
      id: 'warm',
      label: 'Warm',
      description: 'More body and slower tail.',
    ),
    _HarpPluckPreset(
      id: 'crystal',
      label: 'Crystal',
      description: 'Sharper upper harmonics.',
    ),
    _HarpPluckPreset(
      id: 'bright',
      label: 'Bright',
      description: 'Clear attack for active strum.',
    ),
    _HarpPluckPreset(
      id: 'nylon',
      label: 'Nylon',
      description: 'Round body with light transient.',
    ),
    _HarpPluckPreset(
      id: 'glass',
      label: 'Glass',
      description: 'Thin body and sparkling top.',
    ),
    _HarpPluckPreset(
      id: 'concert',
      label: 'Concert',
      description: 'Pedal-harp like balance and sustain.',
    ),
    _HarpPluckPreset(
      id: 'steel',
      label: 'Steel',
      description: 'Stronger core and brighter attack.',
    ),
  ];
  static const List<_HarpPatternPreset> _patternPresets = <_HarpPatternPreset>[
    _HarpPatternPreset(
      id: 'glide',
      label: 'Glide',
      description: 'Ascending sweep.',
    ),
    _HarpPatternPreset(
      id: 'cascade',
      label: 'Cascade',
      description: 'Up then down.',
    ),
    _HarpPatternPreset(
      id: 'chord',
      label: 'Chord',
      description: 'Pulse active chord tones.',
    ),
  ];
  static const List<_HarpPalettePreset> _palettePresets = <_HarpPalettePreset>[
    _HarpPalettePreset(
      id: 'moon',
      label: 'Moon',
      colors: <Color>[Color(0xFF8B5CF6), Color(0xFF60A5FA), Color(0xFF22D3EE)],
    ),
    _HarpPalettePreset(
      id: 'aurora',
      label: 'Aurora',
      colors: <Color>[Color(0xFF0EA5E9), Color(0xFF22C55E), Color(0xFFFDE047)],
    ),
    _HarpPalettePreset(
      id: 'ember',
      label: 'Ember',
      colors: <Color>[Color(0xFFFB7185), Color(0xFFFB923C), Color(0xFFFACC15)],
    ),
    _HarpPalettePreset(
      id: 'jade',
      label: 'Jade',
      colors: <Color>[Color(0xFF10B981), Color(0xFF2DD4BF), Color(0xFF7DD3FC)],
    ),
  ];
  static const List<_HarpRealismPreset> _realismPresets = <_HarpRealismPreset>[
    _HarpRealismPreset(
      id: 'concert_nylon',
      label: 'Concert Nylon',
      description: 'Round body with controlled hall tail.',
      scaleId: 'c_major',
      chordId: 'major',
      pluckStyleId: 'nylon',
      patternId: 'glide',
      paletteId: 'jade',
      reverb: 0.2,
      damping: 11.8,
      swipeThreshold: 1.0,
      chordResonanceEnabled: false,
    ),
    _HarpRealismPreset(
      id: 'pedal_harp',
      label: 'Pedal Harp',
      description: 'Balanced sustain for melodic passages.',
      scaleId: 'c_lydian',
      chordId: 'maj7',
      pluckStyleId: 'concert',
      patternId: 'cascade',
      paletteId: 'moon',
      reverb: 0.26,
      damping: 10.4,
      swipeThreshold: 1.2,
      chordResonanceEnabled: false,
    ),
    _HarpRealismPreset(
      id: 'steel_studio',
      label: 'Steel Studio',
      description: 'Tight transient and clear note separation.',
      scaleId: 'd_dorian',
      chordId: 'sus2',
      pluckStyleId: 'steel',
      patternId: 'glide',
      paletteId: 'aurora',
      reverb: 0.16,
      damping: 12.8,
      swipeThreshold: 0.9,
      chordResonanceEnabled: false,
    ),
    _HarpRealismPreset(
      id: 'chamber_soft',
      label: 'Chamber Soft',
      description: 'Soft finger-pluck with gentle bloom.',
      scaleId: 'a_minor',
      chordId: 'minor',
      pluckStyleId: 'warm',
      patternId: 'chord',
      paletteId: 'ember',
      reverb: 0.3,
      damping: 9.6,
      swipeThreshold: 1.4,
      chordResonanceEnabled: false,
    ),
  ];

  final Map<String, ToolboxEffectPlayer> _playersByKey =
      <String, ToolboxEffectPlayer>{};
  final List<double> _stringOffsets = List<double>.filled(_stringCount, 0);
  final List<double> _stringVelocities = List<double>.filled(_stringCount, 0);
  final List<int> _lastPluckAtMillis = List<int>.filled(_stringCount, 0);
  late final Ticker _vibrationTicker;

  Offset? _lastDragPoint;
  int? _lastDragStringIndex;
  int? _focusedString;
  int? _lastTickMicros;
  bool _muted = false;
  String _scaleId = _scalePresets.first.id;
  String _chordId = _chordPresets.first.id;
  String _pluckStyleId = _pluckPresets.first.id;
  String _patternId = _patternPresets.first.id;
  String _paletteId = _palettePresets.first.id;
  int _chordRootIndex = 0;
  bool _chordResonanceEnabled = false;
  double _reverbUi = 0.24;
  double _reverbForAudio = 0.24;
  double _damping = 10;
  double _swipeThreshold = 1.2;
  String? _activeRealismPresetId;

  @override
  void initState() {
    super.initState();
    _vibrationTicker = createTicker(_tickStrings);
    _applyRealismPreset(_realismPresets.first, withSetState: false);
    if (widget.fullScreen) {
      unawaited(_enterImmersiveMode());
    }
  }

  _HarpScalePreset get _activeScale =>
      _scalePresets.firstWhere((preset) => preset.id == _scaleId);

  _HarpChordPreset get _activeChord =>
      _chordPresets.firstWhere((preset) => preset.id == _chordId);

  _HarpPalettePreset get _activePalette =>
      _palettePresets.firstWhere((preset) => preset.id == _paletteId);

  List<double> get _activeNotes => _activeScale.notes;

  bool get _isHorizontalLayout => widget.fullScreen;

  Future<void> _enterImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  Future<void> _exitImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _markRealismCustom() {
    _activeRealismPresetId = null;
  }

  void _applyRealismPreset(
    _HarpRealismPreset preset, {
    bool withSetState = true,
  }) {
    void applyValues() {
      _scaleId = preset.scaleId;
      _chordId = preset.chordId;
      _pluckStyleId = preset.pluckStyleId;
      _patternId = preset.patternId;
      _paletteId = preset.paletteId;
      _reverbUi = preset.reverb;
      _reverbForAudio = preset.reverb;
      _damping = preset.damping;
      _swipeThreshold = preset.swipeThreshold;
      _chordResonanceEnabled = preset.chordResonanceEnabled;
      _activeRealismPresetId = preset.id;
    }

    if (withSetState && mounted) {
      setState(applyValues);
    } else {
      applyValues();
    }
    _invalidateAudioPlayers();
  }

  void _invalidateAudioPlayers() {
    for (final player in _playersByKey.values) {
      unawaited(player.dispose());
    }
    _playersByKey.clear();
  }

  ToolboxEffectPlayer _playerForFrequency(double frequency) {
    final key =
        '${frequency.toStringAsFixed(2)}|$_pluckStyleId|${_reverbForAudio.toStringAsFixed(2)}';
    final existing = _playersByKey[key];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.harpNote(
        frequency,
        style: _pluckStyleId,
        reverb: _reverbForAudio,
      ),
      maxPlayers: 8,
    );
    _playersByKey[key] = created;
    return created;
  }

  double _stringTrackAt(
    int index,
    Size size, {
    required bool horizontalLayout,
  }) {
    final leadingInset = horizontalLayout
        ? size.height * 0.14
        : size.width * 0.14;
    final trailingInset = horizontalLayout
        ? size.height * 0.14
        : size.width * 0.14;
    final totalSpan = horizontalLayout ? size.height : size.width;
    final usableSpan = math.max(1.0, totalSpan - leadingInset - trailingInset);
    if (_stringCount == 1) {
      return horizontalLayout ? size.height / 2 : size.width / 2;
    }
    return leadingInset + usableSpan * (index / (_stringCount - 1));
  }

  int _nearestStringByPosition(
    Offset point,
    Size size, {
    required bool horizontalLayout,
  }) {
    final axisValue = horizontalLayout ? point.dy : point.dx;
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < _stringCount; i += 1) {
      final distance =
          (_stringTrackAt(i, size, horizontalLayout: horizontalLayout) -
                  axisValue)
              .abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  List<int> _crossedStrings(
    Offset previous,
    Offset current,
    Size size, {
    required bool horizontalLayout,
  }) {
    final startIndex = _nearestStringByPosition(
      previous,
      size,
      horizontalLayout: horizontalLayout,
    );
    final endIndex = _nearestStringByPosition(
      current,
      size,
      horizontalLayout: horizontalLayout,
    );
    if (startIndex == endIndex) {
      return const <int>[];
    }
    final step = endIndex > startIndex ? 1 : -1;
    final indexes = <int>[];
    for (var i = startIndex + step; i != endIndex + step; i += step) {
      indexes.add(i);
    }
    return indexes;
  }

  double _swipeIntensity(Offset delta) {
    final effectiveDistance = math.max(0.0, delta.distance - _swipeThreshold);
    return (effectiveDistance / 52).clamp(0.18, 1.0).toDouble();
  }

  double _swipeDirection(Offset delta, {required bool horizontalLayout}) {
    final axisDelta = horizontalLayout ? delta.dy : delta.dx;
    return axisDelta >= 0 ? 1.0 : -1.0;
  }

  void _startVibrationTicker() {
    if (_vibrationTicker.isActive) return;
    _lastTickMicros = null;
    _vibrationTicker.start();
  }

  void _tickStrings(Duration elapsed) {
    final currentMicros = elapsed.inMicroseconds;
    final previousMicros = _lastTickMicros;
    _lastTickMicros = currentMicros;
    if (previousMicros == null) return;

    var deltaSeconds =
        (currentMicros - previousMicros) / Duration.microsecondsPerSecond;
    if (deltaSeconds <= 0 || deltaSeconds > 0.08) {
      deltaSeconds = 1 / 60;
    }

    var hasMotion = false;
    for (var i = 0; i < _stringOffsets.length; i += 1) {
      final offset = _stringOffsets[i];
      final velocity = _stringVelocities[i];
      final acceleration = (-_springStiffness * offset) - (_damping * velocity);
      final nextVelocity = velocity + acceleration * deltaSeconds;
      final nextOffset = offset + nextVelocity * deltaSeconds;

      if (nextOffset.abs() < 0.02 && nextVelocity.abs() < 0.02) {
        _stringOffsets[i] = 0;
        _stringVelocities[i] = 0;
        continue;
      }

      _stringOffsets[i] = nextOffset;
      _stringVelocities[i] = nextVelocity;
      hasMotion = true;
    }

    if (!hasMotion) {
      _vibrationTicker.stop();
      _lastTickMicros = null;
      if (_focusedString != null && mounted) {
        setState(() {
          _focusedString = null;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _pluckString(
    int index, {
    required double intensity,
    required double direction,
    bool force = false,
    double? frequencyOverride,
    bool applyChordResonance = true,
  }) {
    if (index < 0 || index >= _stringCount) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _lastPluckAtMillis[index] < 28) return;
    _lastPluckAtMillis[index] = now;

    final frequency = frequencyOverride ?? _activeNotes[index];
    final clampedIntensity = intensity.clamp(0.18, 1.0).toDouble();
    if (!_muted) {
      final volume = (0.22 + clampedIntensity * 0.78).clamp(0.0, 1.0);
      unawaited(_playerForFrequency(frequency).play(volume: volume.toDouble()));
    }

    _stringOffsets[index] += direction * (1.8 + clampedIntensity * 2.4);
    _stringVelocities[index] += direction * (42 + clampedIntensity * 68);
    if (applyChordResonance && _chordResonanceEnabled) {
      _triggerChordResonance(
        sourceIndex: index,
        baseFrequency: frequency,
        intensity: clampedIntensity,
        direction: direction,
      );
    }
    _startVibrationTicker();
    if (mounted) {
      setState(() {
        _focusedString = index;
      });
    }
  }

  void _handleTap(Offset localPosition, Size size) {
    final index = _nearestStringByPosition(
      localPosition,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    _pluckString(
      index,
      intensity: 0.46,
      direction: 1,
      force: true,
      applyChordResonance: false,
    );
  }

  void _handlePanStart(DragStartDetails details, Size size) {
    _lastDragPoint = details.localPosition;
    final startIndex = _nearestStringByPosition(
      details.localPosition,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    _lastDragStringIndex = startIndex;
    _pluckString(
      startIndex,
      intensity: 0.32,
      direction: 1,
      force: true,
      applyChordResonance: false,
    );
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    final current = details.localPosition;
    final previous = _lastDragPoint;
    _lastDragPoint = current;
    if (previous == null) return;

    final delta = current - previous;
    if (delta.distance <= _swipeThreshold) return;

    final intensity = _swipeIntensity(delta);
    final direction = _swipeDirection(
      delta,
      horizontalLayout: _isHorizontalLayout,
    );
    final crossed = _crossedStrings(
      previous,
      current,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    if (crossed.isEmpty) {
      final nearest = _nearestStringByPosition(
        current,
        size,
        horizontalLayout: _isHorizontalLayout,
      );
      if (nearest == _lastDragStringIndex) return;
      _lastDragStringIndex = nearest;
      _pluckString(
        nearest,
        intensity: intensity,
        direction: direction,
        applyChordResonance: false,
      );
      return;
    }
    for (final index in crossed) {
      if (index == _lastDragStringIndex) continue;
      _lastDragStringIndex = index;
      _pluckString(
        index,
        intensity: intensity,
        direction: direction,
        applyChordResonance: false,
      );
    }
  }

  void _handlePanEnd() {
    _lastDragPoint = null;
    _lastDragStringIndex = null;
  }

  int _nearestStringByFrequency(double frequency) {
    var bestIndex = 0;
    var bestDistance = double.infinity;
    final notes = _activeNotes;
    for (var i = 0; i < notes.length; i += 1) {
      final distance = (notes[i] - frequency).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  List<double> _activeChordFrequencies() {
    final root = _activeNotes[_chordRootIndex.clamp(0, _stringCount - 1)];
    return _activeChord.intervals
        .map((step) => root * math.pow(2.0, step / 12.0).toDouble())
        .toList(growable: false);
  }

  void _triggerChordResonance({
    required int sourceIndex,
    required double baseFrequency,
    required double intensity,
    required double direction,
  }) {
    // Only on strong strums; avoid accidental multi-trigger on regular taps.
    if (intensity < 0.72) return;
    final resonanceIntervals = _activeChord.intervals.where((step) => step > 0);
    var slot = 0;
    for (final step in resonanceIntervals) {
      if (slot >= 1) break;
      final frequency = baseFrequency * math.pow(2.0, step / 12.0).toDouble();
      final index = _nearestStringByFrequency(frequency);
      if (index == sourceIndex) continue;
      final strength = (0.035 + intensity * 0.08) / (slot + 1);
      if (!_muted) {
        unawaited(
          _playerForFrequency(
            frequency,
          ).play(volume: strength.clamp(0.02, 0.12).toDouble()),
        );
      }
      _stringOffsets[index] += direction * (0.16 + strength * 0.8);
      _stringVelocities[index] += direction * (3 + strength * 12);
      slot += 1;
    }
  }

  Future<void> _playArpeggio() async {
    if (_patternId == 'chord') {
      final chordNotes = _activeChordFrequencies();
      final extended = <double>[...chordNotes, chordNotes.first * 2];
      for (var pass = 0; pass < 2; pass += 1) {
        final forward = pass == 0;
        final sequence = forward
            ? extended
            : extended.reversed.toList(growable: false);
        for (var i = 0; i < sequence.length; i += 1) {
          final frequency = sequence[i];
          final visualIndex = _nearestStringByFrequency(frequency);
          final intensity = (0.55 + (1 - i / sequence.length) * 0.26).clamp(
            0.35,
            0.9,
          );
          _pluckString(
            visualIndex,
            intensity: intensity.toDouble(),
            direction: forward ? 1.0 : -1.0,
            force: true,
            frequencyOverride: frequency,
            applyChordResonance: false,
          );
          await Future<void>.delayed(const Duration(milliseconds: 44));
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      return;
    }

    final ascending = List<int>.generate(_stringCount, (index) => index);
    final sequence = switch (_patternId) {
      'cascade' => <int>[
        ...ascending,
        ...List<int>.generate(_stringCount - 2, (i) => _stringCount - 2 - i),
      ],
      _ => ascending,
    };
    final delay = _patternId == 'cascade' ? 68 : 86;
    for (final index in sequence) {
      _pluckString(
        index,
        intensity: 0.68,
        direction: 1,
        force: true,
        applyChordResonance: false,
      );
      await Future<void>.delayed(Duration(milliseconds: delay));
    }
  }

  @override
  void dispose() {
    if (widget.fullScreen) {
      unawaited(_exitImmersiveMode());
    }
    _vibrationTicker.dispose();
    _invalidateAudioPlayers();
    super.dispose();
  }

  void _openFullScreen() {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HarpToolPage(fullScreen: true),
      ),
    );
  }

  Widget _buildHarpSurface({
    required BuildContext context,
    required Size size,
    required bool rounded,
  }) {
    final gestures = <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(debugOwner: this),
            (TapGestureRecognizer instance) {
              instance.onTapUp = (TapUpDetails details) {
                _handleTap(details.localPosition, size);
              };
            },
          ),
      if (_isHorizontalLayout)
        VerticalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(debugOwner: this),
              (VerticalDragGestureRecognizer instance) {
                instance.onStart = (DragStartDetails details) {
                  _handlePanStart(details, size);
                };
                instance.onUpdate = (DragUpdateDetails details) {
                  _handlePanUpdate(details, size);
                };
                instance.onEnd = (_) => _handlePanEnd();
                instance.onCancel = _handlePanEnd;
              },
            )
      else
        HorizontalDragGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              HorizontalDragGestureRecognizer
            >(() => HorizontalDragGestureRecognizer(debugOwner: this), (
              HorizontalDragGestureRecognizer instance,
            ) {
              instance.onStart = (DragStartDetails details) {
                _handlePanStart(details, size);
              };
              instance.onUpdate = (DragUpdateDetails details) {
                _handlePanUpdate(details, size);
              };
              instance.onEnd = (_) => _handlePanEnd();
              instance.onCancel = _handlePanEnd;
            }),
    };
    Widget content = RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: gestures,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: CustomPaint(
          painter: _HarpPainter(
            stringCount: _stringCount,
            noteFrequencies: _activeNotes,
            stringOffsets: _stringOffsets,
            focusedString: _focusedString,
            colorScheme: Theme.of(context).colorScheme,
            paletteColors: _activePalette.colors,
            pluckStyleId: _pluckStyleId,
            horizontalLayout: _isHorizontalLayout,
          ),
        ),
      ),
    );
    if (rounded) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: content,
      );
    }
    return content;
  }

  Widget _buildFullScreenBody(BuildContext context) {
    final theme = Theme.of(context);
    final reverbPercent = (_reverbUi * 100).round();
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final activePreset = _realismPresets.where((preset) {
      return preset.id == _activeRealismPresetId;
    });
    final presetLabel = activePreset.isEmpty
        ? 'Custom'
        : activePreset.first.label;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return _buildHarpSurface(
                context: context,
                size: size,
                rounded: false,
              );
            },
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: topInset + 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed:
                      widget.onExitFullScreen ??
                      () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Ethereal Harp',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _muted = !_muted),
                  icon: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  ),
                  label: Text(_muted ? 'Muted' : 'Sound'),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomInset + 10,
          child: Row(
            children: <Widget>[
              _CompactMetric(label: 'Layout', value: 'Horizontal'),
              const SizedBox(width: 8),
              _CompactMetric(label: 'Preset', value: presetLabel),
              const SizedBox(width: 8),
              _CompactMetric(label: 'Reverb', value: '$reverbPercent%'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reverbPercent = (_reverbUi * 100).round();
    if (widget.fullScreen) {
      return _buildFullScreenBody(context);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(
              title: 'Strings',
              subtitle:
                  'Second-pass harp with exposed tone, harmony, and gesture feel controls.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                const ToolboxMetricCard(label: 'Strings', value: '12'),
                ToolboxMetricCard(label: 'Scale', value: _activeScale.label),
                ToolboxMetricCard(label: 'Reverb', value: '$reverbPercent%'),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _muted = !_muted),
                  icon: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  ),
                  label: Text(_muted ? 'Muted' : 'Sound on'),
                ),
                OutlinedButton.icon(
                  onPressed: _openFullScreen,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: const Text('Full screen'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final size = Size(width, math.max(260, width * 0.86));
                return _buildHarpSurface(
                  context: context,
                  size: size,
                  rounded: true,
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _playArpeggio,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Auto arpeggio'),
                ),
                Text(
                  'Tip: a wider, faster swipe creates a brighter strum.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const SectionHeader(
              title: 'High Realism Presets',
              subtitle:
                  'Preset bundles tuned for realistic string behavior and room response.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _realismPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(preset.label),
                      selected: _activeRealismPresetId == preset.id,
                      tooltip: preset.description,
                      onSelected: (_) {
                        _applyRealismPreset(preset);
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            const SectionHeader(
              title: 'Tone & Palette',
              subtitle:
                  'String color, pluck timbre, and reverb are all local and real-time.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _pluckPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(preset.label),
                      selected: _pluckStyleId == preset.id,
                      tooltip: preset.description,
                      onSelected: (_) {
                        if (_pluckStyleId == preset.id) return;
                        setState(() {
                          _pluckStyleId = preset.id;
                          _markRealismCustom();
                        });
                        _invalidateAudioPlayers();
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _palettePresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(preset.label),
                      selected: _paletteId == preset.id,
                      onSelected: (_) {
                        if (_paletteId == preset.id) return;
                        setState(() {
                          _paletteId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text('Reverb $reverbPercent%'),
            Slider(
              value: _reverbUi,
              min: 0.0,
              max: 0.8,
              divisions: 16,
              onChanged: (value) {
                setState(() {
                  _reverbUi = value;
                  _markRealismCustom();
                });
              },
              onChangeEnd: (value) {
                final quantized = (value * 20).round() / 20;
                setState(() {
                  _reverbUi = quantized;
                  _reverbForAudio = quantized;
                  _markRealismCustom();
                });
                _invalidateAudioPlayers();
              },
            ),
            const SizedBox(height: 8),
            const SectionHeader(
              title: 'Scale & Chord',
              subtitle:
                  'Expose mode, chord voicing, and arpeggio pattern from the same harp deck.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _scalePresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(preset.label),
                      selected: _scaleId == preset.id,
                      onSelected: (_) {
                        if (_scaleId == preset.id) return;
                        setState(() {
                          _scaleId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _chordPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(preset.label),
                      selected: _chordId == preset.id,
                      onSelected: (_) {
                        if (_chordId == preset.id) return;
                        setState(() {
                          _chordId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _patternPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(preset.label),
                      selected: _patternId == preset.id,
                      tooltip: preset.description,
                      onSelected: (_) {
                        if (_patternId == preset.id) return;
                        setState(() {
                          _patternId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: const Text('Chord resonance'),
              selected: _chordResonanceEnabled,
              onSelected: (selected) {
                setState(() {
                  _chordResonanceEnabled = selected;
                  _markRealismCustom();
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Chord root ${_chordRootIndex + 1} / $_stringCount'),
            Slider(
              value: _chordRootIndex.toDouble(),
              min: 0,
              max: (_stringCount - 1).toDouble(),
              divisions: _stringCount - 1,
              onChanged: (value) {
                setState(() {
                  _chordRootIndex = value.round();
                });
              },
            ),
            const SizedBox(height: 8),
            const SectionHeader(
              title: 'Feel',
              subtitle:
                  'Expose damping and trigger threshold for touch sensitivity tuning.',
            ),
            const SizedBox(height: 10),
            Text('Damping ${_damping.toStringAsFixed(1)}'),
            Slider(
              value: _damping,
              min: 4,
              max: 18,
              divisions: 28,
              onChanged: (value) {
                setState(() {
                  _damping = value;
                  _markRealismCustom();
                });
              },
            ),
            const SizedBox(height: 6),
            Text('Trigger threshold ${_swipeThreshold.toStringAsFixed(1)} px'),
            Slider(
              value: _swipeThreshold,
              min: 0.4,
              max: 8,
              divisions: 38,
              onChanged: (value) {
                setState(() {
                  _swipeThreshold = value;
                  _markRealismCustom();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusBeatsTool extends StatefulWidget {
  const _FocusBeatsTool();

  @override
  State<_FocusBeatsTool> createState() => _FocusBeatsToolState();
}

class _FocusBeatsToolState extends State<_FocusBeatsTool>
    with SingleTickerProviderStateMixin {
  late final ToolboxEffectPlayer _accentPlayer;
  late final ToolboxEffectPlayer _regularPlayer;
  late final AnimationController _pulseController;

  Timer? _timer;
  int _bpm = 72;
  int _beatsPerBar = 4;
  int _activeBeat = -1;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _accentPlayer = ToolboxEffectPlayer(
      ToolboxAudioBank.metronomeClick(accent: true),
      maxPlayers: 4,
    );
    _regularPlayer = ToolboxEffectPlayer(
      ToolboxAudioBank.metronomeClick(accent: false),
      maxPlayers: 4,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    unawaited(_accentPlayer.dispose());
    unawaited(_regularPlayer.dispose());
    super.dispose();
  }

  Duration get _interval => Duration(milliseconds: (60000 / _bpm).round());

  Future<void> _tick() async {
    final nextBeat = (_activeBeat + 1) % _beatsPerBar;
    if (nextBeat == 0) {
      await _accentPlayer.play(volume: 0.95);
    } else {
      await _regularPlayer.play(volume: 0.8);
    }
    if (!mounted) return;
    _pulseController
      ..stop()
      ..forward(from: 0);
    setState(() {
      _activeBeat = nextBeat;
    });
  }

  void _start() {
    _timer?.cancel();
    _running = true;
    _tick();
    _timer = Timer.periodic(_interval, (_) {
      unawaited(_tick());
    });
    setState(() {});
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _activeBeat = -1;
    setState(() {});
  }

  void _restartIfNeeded() {
    if (_running) {
      _start();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBeat = _activeBeat < 0 ? '--' : '${_activeBeat + 1}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(label: 'BPM', value: '$_bpm'),
                ToolboxMetricCard(label: 'Bar', value: '$_beatsPerBar beats'),
                ToolboxMetricCard(label: 'Beat', value: currentBeat),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final pulse = 1 + (1 - _pulseController.value) * 0.08;
                return Center(
                  child: Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.9),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.16),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        currentBeat,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _running ? _stop : _start,
              icon: Icon(
                _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(_running ? 'Stop beats' : 'Start beats'),
            ),
            const SizedBox(height: 14),
            Text('Tempo $_bpm BPM'),
            Slider(
              value: _bpm.toDouble(),
              min: 40,
              max: 160,
              divisions: 120,
              onChanged: (value) {
                _bpm = value.round();
                _restartIfNeeded();
              },
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: <int>[2, 3, 4, 6]
                  .map(
                    (count) => ChoiceChip(
                      label: Text('$count / bar'),
                      selected: _beatsPerBar == count,
                      onSelected: (_) {
                        _beatsPerBar = count;
                        _activeBeat = -1;
                        _restartIfNeeded();
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _WoodfishTool extends StatefulWidget {
  const _WoodfishTool();

  @override
  State<_WoodfishTool> createState() => _WoodfishToolState();
}

class _WoodfishToolState extends State<_WoodfishTool> {
  late final ToolboxEffectPlayer _player;
  int _count = 0;
  int _flashCounter = 0;

  @override
  void initState() {
    super.initState();
    _player = ToolboxEffectPlayer(
      ToolboxAudioBank.woodfishClick(),
      maxPlayers: 6,
    );
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _hit() async {
    HapticFeedback.mediumImpact();
    await _player.play(volume: 1.0);
    if (!mounted) return;
    setState(() {
      _count += 1;
      _flashCounter += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(label: 'Today', value: '$_count taps'),
                const ToolboxMetricCard(label: 'Mode', value: 'Single strike'),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _hit,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 1.35,
                    child: CustomPaint(
                      painter: _WoodfishPainter(
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '$_count',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          '+1',
                          key: ValueKey<int>(_flashCounter),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _hit,
                  icon: const Icon(Icons.pan_tool_alt_rounded),
                  label: const Text('Strike once'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _count = 0),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset count'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HarpPainter extends CustomPainter {
  const _HarpPainter({
    required this.stringCount,
    required this.noteFrequencies,
    required this.stringOffsets,
    required this.focusedString,
    required this.colorScheme,
    required this.paletteColors,
    required this.pluckStyleId,
    required this.horizontalLayout,
  });

  final int stringCount;
  final List<double> noteFrequencies;
  final List<double> stringOffsets;
  final int? focusedString;
  final ColorScheme colorScheme;
  final List<Color> paletteColors;
  final String pluckStyleId;
  final bool horizontalLayout;

  double _stringTrackAt(int index, Size size) {
    final leadingInset = horizontalLayout
        ? size.height * 0.14
        : size.width * 0.14;
    final trailingInset = horizontalLayout
        ? size.height * 0.14
        : size.width * 0.14;
    final totalSpan = horizontalLayout ? size.height : size.width;
    final usableSpan = math.max(1.0, totalSpan - leadingInset - trailingInset);
    if (stringCount == 1) return totalSpan / 2;
    return leadingInset + usableSpan * (index / (stringCount - 1));
  }

  Color _paletteColorAt(double t) {
    if (paletteColors.isEmpty) return colorScheme.primary;
    if (paletteColors.length == 1) return paletteColors.first;
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (paletteColors.length - 1);
    final index = scaled.floor().clamp(0, paletteColors.length - 1);
    final next = math.min(index + 1, paletteColors.length - 1);
    final localT = scaled - index;
    return Color.lerp(paletteColors[index], paletteColors[next], localT) ??
        paletteColors[index];
  }

  int _pitchClassFromFrequency(double frequency) {
    final midi = (69 + 12 * (math.log(frequency / 440.0) / math.ln2)).round();
    return ((midi % 12) + 12) % 12;
  }

  String _noteName(int pitchClass) {
    const names = <String>[
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    return names[pitchClass];
  }

  Color _pitchColor(int pitchClass) {
    const pitchColors = <Color>[
      Color(0xFFEF4444),
      Color(0xFFF97316),
      Color(0xFFF59E0B),
      Color(0xFFEAB308),
      Color(0xFF84CC16),
      Color(0xFF22C55E),
      Color(0xFF14B8A6),
      Color(0xFF06B6D4),
      Color(0xFF3B82F6),
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFD946EF),
    ];
    return pitchColors[pitchClass.clamp(0, 11)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final styleCurve = switch (pluckStyleId) {
      'warm' => 0.78,
      'crystal' => 1.18,
      'bright' => 1.05,
      'glass' => 1.24,
      'nylon' => 0.72,
      'concert' => 0.82,
      'steel' => 0.98,
      _ => 0.9,
    };
    final idleStroke = switch (pluckStyleId) {
      'warm' => 2.2,
      'crystal' => 1.75,
      'bright' => 1.95,
      'glass' => 1.62,
      'nylon' => 2.35,
      'concert' => 2.08,
      'steel' => 1.88,
      _ => 1.9,
    };

    final topGradient = Color.lerp(
      _paletteColorAt(0),
      const Color(0xFF020617),
      0.58,
    );
    final bottomGradient = Color.lerp(
      _paletteColorAt(1),
      const Color(0xFF0F172A),
      0.35,
    );
    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          topGradient ?? const Color(0xFF0F172A),
          (topGradient ?? colorScheme.primary).withValues(alpha: 0.88),
          bottomGradient ?? const Color(0xFF1E1B4B),
        ],
      ).createShader(Offset.zero & size);
    final borderPaint = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    );
    canvas.drawRRect(frame, framePaint);
    canvas.drawRRect(frame, borderPaint);

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              _paletteColorAt(0.5).withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.42),
              radius: size.width * 0.42,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.42),
      size.width * 0.42,
      glowPaint,
    );

    final topY = size.height * 0.08;
    final bottomY = size.height * 0.92;
    final leftX = size.width * 0.08;
    final rightX = size.width * 0.92;
    final midY = (topY + bottomY) / 2;
    final midX = (leftX + rightX) / 2;
    final textScale = horizontalLayout
        ? (size.height / 520).clamp(0.72, 1.06)
        : (size.width / 420).clamp(0.72, 1.0);
    for (var index = 0; index < stringCount; index += 1) {
      final track = _stringTrackAt(index, size);
      final frequency = noteFrequencies[index % noteFrequencies.length];
      final pitchClass = _pitchClassFromFrequency(frequency);
      final noteColor = _pitchColor(pitchClass);
      final sway = (index < stringOffsets.length ? stringOffsets[index] : 0.0)
          .clamp(-22.0, 22.0)
          .toDouble();
      final activity = (sway.abs() / 22).clamp(0.0, 1.0).toDouble();
      final active = focusedString == index || activity > 0.04;
      final paletteColor = _paletteColorAt(index / (stringCount - 1));
      final baseColor = Color.lerp(noteColor, paletteColor, 0.22) ?? noteColor;
      final idleColor =
          Color.lerp(baseColor.withValues(alpha: 0.92), Colors.white, 0.42) ??
          baseColor.withValues(alpha: 0.92);
      final strokeColor = Color.lerp(
        idleColor,
        Colors.white,
        active ? (0.52 + activity * 0.48).clamp(0.0, 1.0) : 0.0,
      );
      final skeletonPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.26)
        ..strokeWidth = math.max(1.35, idleStroke - 0.72)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final basePaint = Paint()
        ..color = baseColor.withValues(alpha: 0.86)
        ..strokeWidth = math.max(1.5, idleStroke - 0.42)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final basePath = horizontalLayout
          ? (Path()
              ..moveTo(leftX, track)
              ..quadraticBezierTo(midX, track, rightX, track))
          : (Path()
              ..moveTo(track, topY)
              ..quadraticBezierTo(track, midY, track, bottomY));
      canvas.drawPath(basePath, skeletonPaint);
      canvas.drawPath(basePath, basePaint);
      final paint = Paint()
        ..color = strokeColor ?? colorScheme.primary
        ..strokeWidth = active ? idleStroke + 1.2 + activity * 0.95 : idleStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (active) {
        final underGlow = Paint()
          ..color = baseColor.withValues(alpha: 0.2)
          ..strokeWidth = 5.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(basePath, underGlow);

        final glow = Paint()
          ..color = (strokeColor ?? colorScheme.primary).withValues(alpha: 0.28)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        final glowPath = horizontalLayout
            ? (Path()
                ..moveTo(leftX, track)
                ..quadraticBezierTo(
                  midX,
                  track + sway * styleCurve,
                  rightX,
                  track,
                ))
            : (Path()
                ..moveTo(track, topY)
                ..quadraticBezierTo(
                  track + sway * styleCurve,
                  midY,
                  track,
                  bottomY,
                ));
        canvas.drawPath(glowPath, glow);
      }

      final path = horizontalLayout
          ? (Path()
              ..moveTo(leftX, track)
              ..quadraticBezierTo(
                midX,
                track + sway * styleCurve,
                rightX,
                track,
              ))
          : (Path()
              ..moveTo(track, topY)
              ..quadraticBezierTo(
                track + sway * styleCurve,
                midY,
                track,
                bottomY,
              ));
      canvas.drawPath(path, paint);

      final anchorPaint = Paint()
        ..color = (strokeColor ?? colorScheme.primary).withValues(alpha: 0.75);
      if (horizontalLayout) {
        canvas.drawCircle(Offset(leftX, track), 2.5, anchorPaint);
        canvas.drawCircle(Offset(rightX, track), 2.2, anchorPaint);
      } else {
        canvas.drawCircle(Offset(track, topY), 2.5, anchorPaint);
        canvas.drawCircle(Offset(track, bottomY), 2.2, anchorPaint);
      }

      final activeDot = Paint()
        ..color = baseColor.withValues(alpha: active ? 0.96 : 0.5);
      final activeDotOffset = horizontalLayout
          ? Offset(rightX, track)
          : Offset(track, bottomY);
      canvas.drawCircle(activeDotOffset, active ? 3.4 : 2.4, activeDot);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: _noteName(pitchClass),
          style: TextStyle(
            color: (strokeColor ?? noteColor).withValues(alpha: 0.9),
            fontSize: 9.5 * textScale,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelOffset = horizontalLayout
          ? Offset(
              leftX - labelPainter.width - 8,
              track - labelPainter.height / 2,
            )
          : Offset(track - labelPainter.width / 2, topY - 16 * textScale);
      labelPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _HarpPainter oldDelegate) {
    return true;
  }
}

class _WoodfishPainter extends CustomPainter {
  const _WoodfishPainter({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.72,
      height: size.height * 0.44,
    );
    final body = RRect.fromRectAndRadius(bodyRect, const Radius.circular(999));
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFFC78743),
          Color(0xFF9C5B21),
          Color(0xFF6E3D18),
        ],
      ).createShader(bodyRect);
    canvas.drawRRect(body, paint);
    canvas.drawRRect(
      body,
      Paint()
        ..color = colorScheme.outline.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final groovePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromCenter(
        center: bodyRect.center,
        width: bodyRect.width * 0.42,
        height: bodyRect.height * 0.35,
      ),
      0.2,
      math.pi - 0.4,
      false,
      groovePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WoodfishPainter oldDelegate) => false;
}
