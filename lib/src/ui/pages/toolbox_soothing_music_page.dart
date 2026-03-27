import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_audio_service.dart';
import '../ui_copy.dart';
import 'toolbox_tool_shell.dart';

final AudioContext _soothingAudioContext = AudioContextConfig(
  focus: AudioContextConfigFocus.mixWithOthers,
).build();

class SoothingMusicExperiencePage extends StatefulWidget {
  const SoothingMusicExperiencePage({super.key});

  @override
  State<SoothingMusicExperiencePage> createState() =>
      _SoothingMusicExperiencePageState();
}

enum _SoothingSourceKind { remote, local }

class _SoothingMode {
  const _SoothingMode({
    required this.id,
    required this.zhTitle,
    required this.enTitle,
    required this.zhSubtitle,
    required this.enSubtitle,
    required this.icon,
    required this.accent,
    required this.visualizerSpeed,
    required this.sourceKind,
    this.remoteUrl,
    this.localSceneId,
  });

  final String id;
  final String zhTitle;
  final String enTitle;
  final String zhSubtitle;
  final String enSubtitle;
  final IconData icon;
  final Color accent;
  final double visualizerSpeed;
  final _SoothingSourceKind sourceKind;
  final String? remoteUrl;
  final String? localSceneId;

  String title(AppI18n i18n) => pickUiText(i18n, zh: zhTitle, en: enTitle);

  String subtitle(AppI18n i18n) =>
      pickUiText(i18n, zh: zhSubtitle, en: enSubtitle);
}

class _SoothingMusicExperiencePageState
    extends State<SoothingMusicExperiencePage>
    with SingleTickerProviderStateMixin {
  static const List<_SoothingMode> _modes = <_SoothingMode>[
    // External reference streams from the source site. Replace with owned
    // assets before redistributing publicly.
    _SoothingMode(
      id: 'chill',
      zhTitle: '轻松',
      enTitle: 'Relax',
      zhSubtitle: 'Lofi Chill',
      enSubtitle: 'Lofi Chill',
      icon: Icons.music_note_rounded,
      accent: Color(0xFF7D8CFF),
      visualizerSpeed: 0.042,
      sourceKind: _SoothingSourceKind.remote,
      remoteUrl: 'https://www.ppbzy.com/audio/Lofi/Chill/Lofi%20chill%201.m4a',
    ),
    _SoothingMode(
      id: 'study',
      zhTitle: '学习',
      enTitle: 'Study',
      zhSubtitle: 'Lofi Study',
      enSubtitle: 'Lofi Study',
      icon: Icons.radio_button_checked_rounded,
      accent: Color(0xFF62A5FF),
      visualizerSpeed: 0.05,
      sourceKind: _SoothingSourceKind.remote,
      remoteUrl: 'https://www.ppbzy.com/audio/Lofi/Study/Lofi%20study%201.m4a',
    ),
    _SoothingMode(
      id: 'sleep',
      zhTitle: '助眠',
      enTitle: 'Sleep',
      zhSubtitle: 'Lofi Sleep',
      enSubtitle: 'Lofi Sleep',
      icon: Icons.nightlight_round_rounded,
      accent: Color(0xFFB57CFF),
      visualizerSpeed: 0.024,
      sourceKind: _SoothingSourceKind.remote,
      remoteUrl: 'https://www.ppbzy.com/audio/Lofi/Sleep/Lofi%20sleep%201.m4a',
    ),
    _SoothingMode(
      id: 'jazz',
      zhTitle: '爵士',
      enTitle: 'Jazz',
      zhSubtitle: 'Lofi Jazz',
      enSubtitle: 'Lofi Jazz',
      icon: Icons.mic_external_on_rounded,
      accent: Color(0xFFFF8B7B),
      visualizerSpeed: 0.04,
      sourceKind: _SoothingSourceKind.remote,
      remoteUrl: 'https://www.ppbzy.com/audio/Lofi/Jazz/Lofi%20jazz%201.m4a',
    ),
    _SoothingMode(
      id: 'piano',
      zhTitle: '钢琴',
      enTitle: 'Piano',
      zhSubtitle: 'Lofi Piano',
      enSubtitle: 'Lofi Piano',
      icon: Icons.piano_rounded,
      accent: Color(0xFFB9C3D6),
      visualizerSpeed: 0.03,
      sourceKind: _SoothingSourceKind.remote,
      remoteUrl: 'https://www.ppbzy.com/audio/Lofi/Piano/Lofi%20piano%201.m4a',
    ),
    _SoothingMode(
      id: 'motion',
      zhTitle: '运动',
      enTitle: 'Motion',
      zhSubtitle: 'Local Motion Flow',
      enSubtitle: 'Local Motion Flow',
      icon: Icons.directions_run_rounded,
      accent: Color(0xFF32C8A8),
      visualizerSpeed: 0.07,
      sourceKind: _SoothingSourceKind.local,
      localSceneId: 'motion',
    ),
    _SoothingMode(
      id: 'harp',
      zhTitle: '竖琴',
      enTitle: 'Harp',
      zhSubtitle: 'Local Harp Loop',
      enSubtitle: 'Local Harp Loop',
      icon: Icons.auto_awesome_rounded,
      accent: Color(0xFF8F93FF),
      visualizerSpeed: 0.032,
      sourceKind: _SoothingSourceKind.local,
      localSceneId: 'harp_scene',
    ),
    _SoothingMode(
      id: 'music_box',
      zhTitle: '八音盒',
      enTitle: 'Music Box',
      zhSubtitle: 'Local Music Box',
      enSubtitle: 'Local Music Box',
      icon: Icons.toys_rounded,
      accent: Color(0xFFFFB061),
      visualizerSpeed: 0.028,
      sourceKind: _SoothingSourceKind.local,
      localSceneId: 'music_box',
    ),
  ];

  final AudioPlayer _player = AudioPlayer();
  late final AnimationController _orbitController;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  _SoothingMode _mode = _modes[1];
  bool _playing = false;
  bool _muted = false;
  bool _loading = false;
  double _volume = 0.6;
  double? _draggingRatio;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 2);
  String? _audioError;
  String? _loadedTrackId;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _positionSubscription = _player.onPositionChanged.listen((value) {
      if (!mounted) return;
      setState(() {
        _position = value;
      });
    });
    _durationSubscription = _player.onDurationChanged.listen((value) {
      if (!mounted || value.inMilliseconds <= 0) return;
      setState(() {
        _duration = value;
      });
    });
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final isPlaying = state == PlayerState.playing;
      if (_playing == isPlaying) return;
      setState(() {
        _playing = isPlaying;
      });
      if (isPlaying) {
        _orbitController.repeat();
      } else {
        _orbitController.stop();
      }
    });
    unawaited(_configurePlayer());
  }

  Future<void> _configurePlayer() async {
    await _player.setAudioContext(_soothingAudioContext);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_muted ? 0 : _volume);
    await _loadMode(_mode, autoplay: false);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _orbitController.dispose();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _loadMode(_SoothingMode mode, {required bool autoplay}) async {
    if (_loadedTrackId == mode.id && (!autoplay || _playing)) {
      return;
    }
    setState(() {
      _loading = true;
      _audioError = null;
      _mode = mode;
      _position = Duration.zero;
      _draggingRatio = null;
    });

    try {
      switch (mode.sourceKind) {
        case _SoothingSourceKind.remote:
          await _player.setSourceUrl(mode.remoteUrl!);
          break;
        case _SoothingSourceKind.local:
          await _player.setSourceBytes(
            ToolboxAudioBank.soothingSceneLoop(mode.localSceneId!),
            mimeType: 'audio/wav',
          );
          break;
      }
      _loadedTrackId = mode.id;
      await _player.setVolume(_muted ? 0 : _volume);
      if (autoplay) {
        await _player.resume();
      } else {
        await _player.stop();
      }
    } catch (error) {
      _loadedTrackId = null;
      setState(() {
        _audioError = 'Unable to load ${mode.enTitle}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_loading) return;
    if (_loadedTrackId != _mode.id) {
      await _loadMode(_mode, autoplay: true);
      return;
    }
    if (_playing) {
      await _player.pause();
      _orbitController.stop();
      return;
    }
    await _player.resume();
    _orbitController.repeat();
  }

  Future<void> _setMode(_SoothingMode mode) async {
    if (_mode.id == mode.id) return;
    final autoplay = _playing;
    await _loadMode(mode, autoplay: autoplay);
  }

  Future<void> _setMuted(bool value) async {
    setState(() {
      _muted = value;
    });
    await _player.setVolume(value ? 0 : _volume);
  }

  Future<void> _setVolume(double value) async {
    setState(() {
      _volume = value;
    });
    if (!_muted) {
      await _player.setVolume(value);
    }
  }

  Future<void> _seekToRatio(double ratio) async {
    if (_duration.inMilliseconds <= 0) return;
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * ratio).round(),
    );
    await _player.seek(target);
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(1, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progressRatio {
    final effective = _draggingRatio;
    if (effective != null) return effective;
    if (_duration.inMilliseconds <= 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Scaffold(
      backgroundColor: const Color(0xFF09111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09111D),
        foregroundColor: Colors.white,
        title: Text(pickUiText(i18n, zh: '舒缓轻音', en: 'Soothing music')),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFF0C1728), Color(0xFF08111D)],
              ),
            ),
            child: SafeArea(
              top: false,
              child: wide
                  ? Row(
                      children: <Widget>[
                        SizedBox(
                          width: 320,
                          child: _buildModePanel(context, i18n, compact: false),
                        ),
                        Expanded(child: _buildMainStage(context, i18n)),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        _buildModePanel(context, i18n, compact: true),
                        Expanded(child: _buildMainStage(context, i18n)),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModePanel(
    BuildContext context,
    AppI18n i18n, {
    required bool compact,
  }) {
    final panel = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A2A).withValues(alpha: 0.96),
        border: Border(
          right: compact
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF1C2B42)),
          bottom: compact
              ? const BorderSide(color: Color(0xFF1C2B42))
              : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, compact ? 10 : 18, 16, 16),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(i18n, zh: '播放列表', en: 'Playlist'),
                  style: const TextStyle(
                    color: Color(0xFF7C8FA9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _modes.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => SizedBox(
                      width: 148,
                      child: _buildModeTile(_modes[index], i18n),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(i18n, zh: '精选轻音', en: 'Curated modes'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pickUiText(
                    i18n,
                    zh: '参考站点的 Lofi 结构，叠加本地补充模式与更强的核心动效。',
                    en: 'Reference-inspired lofi structure with local extra modes and a stronger central animation.',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF7C8FA9),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: _modes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildModeTile(_modes[index], i18n),
                  ),
                ),
              ],
            ),
    );
    return compact ? panel : SafeArea(top: false, bottom: false, child: panel);
  }

  Widget _buildModeTile(_SoothingMode mode, AppI18n i18n) {
    final selected = _mode.id == mode.id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _setMode(mode),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF18273B) : const Color(0xFF101B2B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF334D71)
                  : const Color(0xFF1C2B42),
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: mode.accent.withValues(alpha: 0.16),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? mode.accent.withValues(alpha: 0.12)
                      : const Color(0xFF121F31),
                  border: Border.all(
                    color: selected
                        ? mode.accent.withValues(alpha: 0.5)
                        : const Color(0xFF24344E),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(mode.icon, color: mode.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      mode.title(i18n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.subtitle(i18n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7C8FA9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainStage(BuildContext context, AppI18n i18n) {
    final accent = _mode.accent;
    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.06),
                      radius: 0.72,
                      colors: <Color>[
                        accent.withValues(alpha: 0.08),
                        const Color(0x00131E2E),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _orbitController,
                  builder: (context, _) {
                    final phase = _orbitController.value * math.pi * 2;
                    return CustomPaint(
                      painter: _SoothingOrbPainter(
                        phase: phase,
                        energy: _playing ? 1.0 : 0.26,
                        accent: accent,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              _mode.title(i18n),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 46,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _mode.enTitle.toUpperCase(),
                              style: TextStyle(
                                color: accent.withValues(alpha: 0.86),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.2,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _mode.subtitle(i18n),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF8FA6C6),
                                fontSize: 13,
                              ),
                            ),
                            if ((_audioError ?? '').isNotEmpty) ...<Widget>[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF402127),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _audioError!,
                                  style: const TextStyle(
                                    color: Color(0xFFFFB4B4),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 108,
          decoration: const BoxDecoration(
            color: Color(0xFF0B1524),
            border: Border(top: BorderSide(color: Color(0xFF1C2B42))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final progress = _progressRatio;
              final positionLabel = _format(
                Duration(
                  milliseconds: (_duration.inMilliseconds * progress)
                      .round()
                      .clamp(0, _duration.inMilliseconds),
                ),
              );
              final durationLabel = _format(_duration);

              final left = Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    onPressed: () => _setMuted(!_muted),
                    icon: Icon(
                      _muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: const Color(0xFFA7BCD7),
                    ),
                  ),
                  SizedBox(
                    width: compact ? 120 : 170,
                    child: Slider(
                      value: _muted ? 0 : _volume,
                      min: 0,
                      max: 1,
                      onChanged: (value) => _setVolume(value),
                    ),
                  ),
                ],
              );

              final center = FilledButton(
                onPressed: _togglePlayback,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1CC9C0),
                  foregroundColor: const Color(0xFF052336),
                  minimumSize: const Size(72, 72),
                  shape: const CircleBorder(),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 34,
                      ),
              );

              final right = Column(
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    '$positionLabel / $durationLabel',
                    style: const TextStyle(
                      color: Color(0xFFD7E4F2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: compact ? constraints.maxWidth - 56 : 240,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: progress,
                        min: 0,
                        max: 1,
                        onChangeStart: _duration.inMilliseconds <= 0
                            ? null
                            : (value) {
                                setState(() {
                                  _draggingRatio = value;
                                });
                              },
                        onChanged: _duration.inMilliseconds <= 0
                            ? null
                            : (value) {
                                setState(() {
                                  _draggingRatio = value;
                                });
                              },
                        onChangeEnd: _duration.inMilliseconds <= 0
                            ? null
                            : (value) async {
                                setState(() {
                                  _draggingRatio = null;
                                });
                                await _seekToRatio(value);
                              },
                      ),
                    ),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[left, center],
                    ),
                    const SizedBox(height: 6),
                    right,
                  ],
                );
              }
              return Row(
                children: <Widget>[
                  left,
                  Expanded(child: Center(child: center)),
                  right,
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SoothingOrbPainter extends CustomPainter {
  const _SoothingOrbPainter({
    required this.phase,
    required this.energy,
    required this.accent,
  });

  final double phase;
  final double energy;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * 0.19;
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: 0.38 + energy * 0.16),
          accent.withValues(alpha: 0.16 + energy * 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.9));
    canvas.drawCircle(center, radius * 1.65, corePaint);

    for (var ring = 0; ring < 4; ring += 1) {
      final ringRadius = radius * (1.45 + ring * 0.35);
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = accent.withValues(alpha: 0.025 * (4 - ring))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16,
      );
    }

    _drawOrbit(
      canvas,
      center,
      radius * 2.2,
      accent.withValues(alpha: 0.98),
      phase,
      1.0,
    );
    _drawOrbit(
      canvas,
      center,
      radius * 2.45,
      Color.lerp(accent, const Color(0xFFFFB15C), 0.35)!,
      phase + 1.35,
      -0.9,
    );
  }

  void _drawOrbit(
    Canvas canvas,
    Offset center,
    double baseRadius,
    Color color,
    double phase,
    double direction,
  ) {
    final path = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i += 1) {
      final t = i / steps;
      final angle = t * math.pi * 2;
      final wave =
          math.sin(angle * 6 + phase * direction) * baseRadius * 0.12 +
          math.cos(angle * 3.6 - phase * 0.7) * baseRadius * 0.06;
      final currentRadius = baseRadius + wave;
      final point = Offset(
        center.dx + math.cos(angle) * currentRadius,
        center.dy + math.sin(angle) * currentRadius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SoothingOrbPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.energy != energy ||
        oldDelegate.accent != accent;
  }
}
