import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
  const HarpToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
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
    _SoothingPreset(id: 'moon', title: '月白', subtitle: '最柔和的漂浮底色'),
    _SoothingPreset(id: 'mist', title: '薄雾', subtitle: '更空一点，更慢一点'),
    _SoothingPreset(id: 'harbor', title: '夜航', subtitle: '更亮一些，适合晚间专注'),
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
  const _HarpTool();

  @override
  State<_HarpTool> createState() => _HarpToolState();
}

class _HarpToolState extends State<_HarpTool> {
  static const List<double> _notes = <double>[
    261.63,
    293.66,
    329.63,
    392.00,
    440.00,
    523.25,
    587.33,
  ];

  final List<ToolboxEffectPlayer?> _players = List<ToolboxEffectPlayer?>.filled(
    _notes.length,
    null,
  );

  int? _highlightedString;
  int? _draggedString;

  ToolboxEffectPlayer _playerFor(int index) {
    final existing = _players[index];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.harpNote(_notes[index]),
    );
    _players[index] = created;
    return created;
  }

  Future<void> _playString(int index) async {
    if (index < 0 || index >= _notes.length) return;
    await _playerFor(index).play(volume: 0.92);
    if (!mounted) return;
    setState(() {
      _highlightedString = index;
    });
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted || _highlightedString != index) return;
      setState(() {
        _highlightedString = null;
      });
    });
  }

  int _stringAt(Offset localPosition, Size size) {
    final stringWidth = size.width / _notes.length;
    return (localPosition.dx / stringWidth).floor().clamp(0, _notes.length - 1);
  }

  Future<void> _playArpeggio() async {
    for (var i = 0; i < _notes.length; i += 1) {
      await _playString(i);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  @override
  void dispose() {
    for (final player in _players) {
      if (player != null) {
        unawaited(player.dispose());
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(
              title: 'Strings',
              subtitle:
                  'Tap one string or glide sideways to strum a local harp patch.',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final size = Size(width, math.max(240, width * 0.82));
                return GestureDetector(
                  onTapDown: (details) =>
                      _playString(_stringAt(details.localPosition, size)),
                  onPanStart: (details) {
                    final index = _stringAt(details.localPosition, size);
                    _draggedString = index;
                    unawaited(_playString(index));
                  },
                  onPanUpdate: (details) {
                    final index = _stringAt(details.localPosition, size);
                    if (_draggedString == index) return;
                    _draggedString = index;
                    unawaited(_playString(index));
                  },
                  onPanEnd: (_) => _draggedString = null,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: CustomPaint(
                      painter: _HarpPainter(
                        stringCount: _notes.length,
                        highlightedString: _highlightedString,
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _playArpeggio,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Auto arpeggio'),
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
    required this.highlightedString,
    required this.colorScheme,
  });

  final int stringCount;
  final int? highlightedString;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final framePaint = Paint()
      ..color = colorScheme.surfaceContainerHighest
      ..style = PaintingStyle.fill;
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

    final stringSpacing = size.width / stringCount;
    for (var index = 0; index < stringCount; index += 1) {
      final x = stringSpacing * (index + 0.5);
      final active = highlightedString == index;
      final paint = Paint()
        ..color = active
            ? colorScheme.primary
            : colorScheme.outline.withValues(alpha: 0.9)
        ..strokeWidth = active ? 3.2 : 2
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(x, size.height * 0.08)
        ..quadraticBezierTo(
          x + (index.isEven ? 6 : -6),
          size.height * 0.45,
          x,
          size.height * 0.92,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HarpPainter oldDelegate) {
    return oldDelegate.highlightedString != highlightedString;
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
