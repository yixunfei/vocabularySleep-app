import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/toolbox_audio_service.dart';
import '../../services/toolbox_singing_bowls_prefs_service.dart';

class SingingBowlsToolPage extends StatelessWidget {
  const SingingBowlsToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF3EFE8),
      body: SafeArea(bottom: false, child: SingingBowlsPracticeCard()),
    );
  }
}

enum _SingingBowlGroup { chakra, resonance }

class _SingingBowlFrequencySpec {
  const _SingingBowlFrequencySpec({
    required this.id,
    required this.group,
    required this.note,
    required this.frequency,
    required this.nameZh,
    required this.nameEn,
    required this.subtitleZh,
    required this.subtitleEn,
    required this.descriptionZh,
    required this.descriptionEn,
    required this.accent,
    required this.glow,
    required this.gradient,
  });

  final String id;
  final _SingingBowlGroup group;
  final String note;
  final double frequency;
  final String nameZh;
  final String nameEn;
  final String subtitleZh;
  final String subtitleEn;
  final String descriptionZh;
  final String descriptionEn;
  final Color accent;
  final Color glow;
  final List<Color> gradient;

  String name(bool isZh) => isZh ? nameZh : nameEn;

  String subtitle(bool isZh) => isZh ? subtitleZh : subtitleEn;

  String description(bool isZh) => isZh ? descriptionZh : descriptionEn;
}

class _SingingBowlVoiceSpec {
  const _SingingBowlVoiceSpec({
    required this.id,
    required this.icon,
    required this.nameZh,
    required this.nameEn,
    required this.descriptionZh,
    required this.descriptionEn,
    required this.baseVolume,
  });

  final String id;
  final IconData icon;
  final String nameZh;
  final String nameEn;
  final String descriptionZh;
  final String descriptionEn;
  final double baseVolume;

  String name(bool isZh) => isZh ? nameZh : nameEn;

  String description(bool isZh) => isZh ? descriptionZh : descriptionEn;
}

class _SpectrumBurst {
  const _SpectrumBurst({required this.id, required this.seed});

  final int id;
  final double seed;
}

const List<_SingingBowlFrequencySpec>
_bowlFrequencySpecs = <_SingingBowlFrequencySpec>[
  _SingingBowlFrequencySpec(
    id: 'root',
    group: _SingingBowlGroup.chakra,
    note: 'C',
    frequency: 396,
    nameZh: '安定',
    nameEn: 'Stability',
    subtitleZh: '根轮共振',
    subtitleEn: 'Root chakra',
    descriptionZh: '释放焦虑与恐惧，让呼吸和身体重新落地，回到稳稳托住自己的根基。',
    descriptionEn:
        'Releases anxious tension and helps the body settle into grounded stability.',
    accent: Color(0xFFEF4444),
    glow: Color(0xFFF7A89D),
    gradient: <Color>[Color(0xFFF8F0EC), Color(0xFFF4E2D8), Color(0xFFEBCDC3)],
  ),
  _SingingBowlFrequencySpec(
    id: 'sacral',
    group: _SingingBowlGroup.chakra,
    note: 'D',
    frequency: 417,
    nameZh: '活力',
    nameEn: 'Vitality',
    subtitleZh: '脐轮流动',
    subtitleEn: 'Sacral flow',
    descriptionZh: '松开压抑的情绪结块，让能量重新流动，带回温暖、柔软和生机。',
    descriptionEn:
        'Loosens emotional heaviness and restores warmth, softness, and flow.',
    accent: Color(0xFFF97316),
    glow: Color(0xFFF7C089),
    gradient: <Color>[Color(0xFFF9F1E7), Color(0xFFF3E2CF), Color(0xFFEBCFB4)],
  ),
  _SingingBowlFrequencySpec(
    id: 'solar',
    group: _SingingBowlGroup.chakra,
    note: 'E',
    frequency: 528,
    nameZh: '自信',
    nameEn: 'Confidence',
    subtitleZh: '太阳神经丛',
    subtitleEn: 'Solar plexus',
    descriptionZh: '著名的“奇迹频率”，带来更清晰的内在中心感，扶起行动力与自信。',
    descriptionEn:
        'The well-known miracle tone that brightens the center and lifts confidence.',
    accent: Color(0xFFEAB308),
    glow: Color(0xFFF0D989),
    gradient: <Color>[Color(0xFFF8F5E8), Color(0xFFF1E9C9), Color(0xFFE8DCAB)],
  ),
  _SingingBowlFrequencySpec(
    id: 'heart',
    group: _SingingBowlGroup.chakra,
    note: 'F',
    frequency: 639,
    nameZh: '和谐',
    nameEn: 'Harmony',
    subtitleZh: '心轮开阔',
    subtitleEn: 'Heart chakra',
    descriptionZh: '促进人与自己、人与外界之间更柔和的联结，适合久听与沉静放松。',
    descriptionEn:
        'Softens inner and outer connection, making it especially suited to longer listening.',
    accent: Color(0xFF10B981),
    glow: Color(0xFF9FD9BC),
    gradient: <Color>[Color(0xFFF0F6F1), Color(0xFFE0ECE3), Color(0xFFCFE0D4)],
  ),
  _SingingBowlFrequencySpec(
    id: 'throat',
    group: _SingingBowlGroup.chakra,
    note: 'G',
    frequency: 741,
    nameZh: '表达',
    nameEn: 'Expression',
    subtitleZh: '喉轮澄明',
    subtitleEn: 'Throat chakra',
    descriptionZh: '清理纷乱思绪，带来通透与轻盈，更自由地表达真实的感受与声音。',
    descriptionEn:
        'Clears mental noise and encourages a lighter, freer sense of expression.',
    accent: Color(0xFF06B6D4),
    glow: Color(0xFF99DCE6),
    gradient: <Color>[Color(0xFFEFF7F8), Color(0xFFDDEAF0), Color(0xFFCADFE9)],
  ),
  _SingingBowlFrequencySpec(
    id: 'third_eye',
    group: _SingingBowlGroup.chakra,
    note: 'A',
    frequency: 852,
    nameZh: '洞察',
    nameEn: 'Insight',
    subtitleZh: '眉心观照',
    subtitleEn: 'Third eye',
    descriptionZh: '让注意力从外界收回到内在，保持冷静、清澈的观察感与直觉。',
    descriptionEn:
        'Draws attention inward and supports calm, lucid observation and intuition.',
    accent: Color(0xFF6366F1),
    glow: Color(0xFFBAC0F5),
    gradient: <Color>[Color(0xFFF2F2F9), Color(0xFFE3E5F3), Color(0xFFD3D7EC)],
  ),
  _SingingBowlFrequencySpec(
    id: 'crown',
    group: _SingingBowlGroup.chakra,
    note: 'B',
    frequency: 963,
    nameZh: '升华',
    nameEn: 'Transcendence',
    subtitleZh: '顶轮宁静',
    subtitleEn: 'Crown chakra',
    descriptionZh: '收束杂音、回到纯净的精神秩序，适合更冥想、更空灵的停留。',
    descriptionEn:
        'Invites a more spacious, meditative stillness with a lighter and more transcendental halo.',
    accent: Color(0xFFA855F7),
    glow: Color(0xFFD5B8F6),
    gradient: <Color>[Color(0xFFF4F0F8), Color(0xFFE9E0F2), Color(0xFFDCCFED)],
  ),
  _SingingBowlFrequencySpec(
    id: '174',
    group: _SingingBowlGroup.resonance,
    note: 'F3',
    frequency: 174,
    nameZh: '镇痛',
    nameEn: 'Pain Relief',
    subtitleZh: '低频安抚',
    subtitleEn: 'Low resonance',
    descriptionZh: '更低、更厚、更靠近身体感，适合夜里、疲惫时或压力沉重的时候。',
    descriptionEn:
        'A lower, denser resonance for heavy, tired moments that need deeper grounding.',
    accent: Color(0xFF78716C),
    glow: Color(0xFFC8BBB0),
    gradient: <Color>[Color(0xFFF3F0EC), Color(0xFFE6DFD7), Color(0xFFD7CEC5)],
  ),
  _SingingBowlFrequencySpec(
    id: '285',
    group: _SingingBowlGroup.resonance,
    note: 'D4',
    frequency: 285,
    nameZh: '修复',
    nameEn: 'Restoration',
    subtitleZh: '修复频带',
    subtitleEn: 'Restoration',
    descriptionZh: '像一条柔和的修复带，在低频和中心频率之间架起更平衡的过渡。',
    descriptionEn:
        'Feels like a restorative bridge between the lower field and the more centered tones.',
    accent: Color(0xFF14B8A6),
    glow: Color(0xFF9EDFD7),
    gradient: <Color>[Color(0xFFEFF6F5), Color(0xFFDDECEA), Color(0xFFC9E0DC)],
  ),
  _SingingBowlFrequencySpec(
    id: 'om',
    group: _SingingBowlGroup.resonance,
    note: 'C#',
    frequency: 136.1,
    nameZh: '地球',
    nameEn: 'Om / Earth',
    subtitleZh: '地球原音',
    subtitleEn: 'Earth tone',
    descriptionZh: '像更慢、更深的一层冥想底床，接地、安静，带着沉稳的归属感。',
    descriptionEn:
        'A slower, deeper meditative bed that feels grounded, calm, and belonging.',
    accent: Color(0xFF059669),
    glow: Color(0xFF9FD4C1),
    gradient: <Color>[Color(0xFFEEF6F2), Color(0xFFDBE9E2), Color(0xFFC6DDD4)],
  ),
  _SingingBowlFrequencySpec(
    id: '432',
    group: _SingingBowlGroup.resonance,
    note: 'A4',
    frequency: 432,
    nameZh: '自然',
    nameEn: 'Universal',
    subtitleZh: '自然调谐',
    subtitleEn: '432 Hz',
    descriptionZh: '与更自然的呼吸和节律贴近，适合当作长时间背景共振慢慢陪伴。',
    descriptionEn:
        'A more natural-feeling tuning that settles into longer, softer background resonance.',
    accent: Color(0xFF0EA5E9),
    glow: Color(0xFF9DD7F1),
    gradient: <Color>[Color(0xFFEDF5F9), Color(0xFFDCEAF2), Color(0xFFC8DDEA)],
  ),
];

const List<_SingingBowlVoiceSpec> _bowlVoiceSpecs = <_SingingBowlVoiceSpec>[
  _SingingBowlVoiceSpec(
    id: 'crystal',
    icon: Icons.auto_awesome_rounded,
    nameZh: '水晶',
    nameEn: 'Crystal',
    descriptionZh: '空灵清脆，带着更明亮、更通透的泛音边缘。',
    descriptionEn: 'Airy and bright, with a clearer crystalline overtone edge.',
    baseVolume: 0.76,
  ),
  _SingingBowlVoiceSpec(
    id: 'brass',
    icon: Icons.album_rounded,
    nameZh: '铜钵',
    nameEn: 'Brass',
    descriptionZh: '泛音饱满，金属体感更厚，尾音更稳、更宽。',
    descriptionEn: 'Fuller metallic overtones with a broader, steadier tail.',
    baseVolume: 0.84,
  ),
  _SingingBowlVoiceSpec(
    id: 'deep',
    icon: Icons.nights_stay_rounded,
    nameZh: '深邃',
    nameEn: 'Deep',
    descriptionZh: '低沉厚重，下潜感更强，更适合夜晚与深度放松。',
    descriptionEn:
        'Lower and weightier, suited to night listening and deep unwinding.',
    baseVolume: 0.88,
  ),
  _SingingBowlVoiceSpec(
    id: 'pure',
    icon: Icons.circle_outlined,
    nameZh: '纯净',
    nameEn: 'Pure',
    descriptionZh: '极简正弦，只保留最核心的频率与朴素的回响。',
    descriptionEn:
        'Minimal and pure, focused almost entirely on the core tone.',
    baseVolume: 0.7,
  ),
];

final Map<String, _SingingBowlFrequencySpec> _bowlFrequencyById =
    <String, _SingingBowlFrequencySpec>{
      for (final spec in _bowlFrequencySpecs) spec.id: spec,
    };

final Map<String, _SingingBowlVoiceSpec> _bowlVoiceById =
    <String, _SingingBowlVoiceSpec>{
      for (final spec in _bowlVoiceSpecs) spec.id: spec,
    };

class SingingBowlsPracticeCard extends StatefulWidget {
  const SingingBowlsPracticeCard({super.key});

  @override
  State<SingingBowlsPracticeCard> createState() =>
      _SingingBowlsPracticeCardState();
}

class _SingingBowlsPracticeCardState extends State<SingingBowlsPracticeCard>
    with TickerProviderStateMixin {
  static const Duration _strikeMotionDuration = Duration(milliseconds: 1400);
  static const int _minAutoPlayMs = 2000;
  static const int _maxAutoPlayMs = 30000;
  static const List<int> _audioVariants = <int>[0, 1, 2, 3];

  late final AnimationController _ambientController;
  late final AnimationController _strikeController;

  Timer? _autoPlayTimer;
  Timer? _persistTimer;
  ToolboxRealisticEffectPlayer? _player;

  String _frequencyId = 'heart';
  String _voiceId = 'crystal';
  int _autoPlayIntervalMs = 5000;
  bool _autoPlayEnabled = false;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _controlsExpanded = false;
  bool _pressing = false;
  int _playerBuildNonce = 0;
  List<_SpectrumBurst> _bursts = const <_SpectrumBurst>[];

  bool get _isZh => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('zh');

  _SingingBowlFrequencySpec get _frequencySpec =>
      _bowlFrequencyById[_frequencyId] ?? _bowlFrequencySpecs[3];

  _SingingBowlVoiceSpec get _voiceSpec =>
      _bowlVoiceById[_voiceId] ?? _bowlVoiceSpecs[0];

  SingingBowlsPrefsState get _prefsState => SingingBowlsPrefsState(
    frequencyId: _frequencyId,
    voiceId: _voiceId,
    autoPlayIntervalMs: _autoPlayIntervalMs,
    soundEnabled: _soundEnabled,
    hapticsEnabled: _hapticsEnabled,
  );

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _strikeController = AnimationController(
      vsync: this,
      duration: _strikeMotionDuration,
    );
    unawaited(_loadPrefs());
    unawaited(_rebuildPlayer());
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _persistTimer?.cancel();
    _ambientController.dispose();
    _strikeController.dispose();
    final player = _player;
    if (player != null) {
      unawaited(player.dispose());
    }
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await ToolboxSingingBowlsPrefsService.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _frequencyId = prefs.frequencyId;
      _voiceId = prefs.voiceId;
      _autoPlayIntervalMs = prefs.autoPlayIntervalMs;
      _soundEnabled = prefs.soundEnabled;
      _hapticsEnabled = prefs.hapticsEnabled;
    });
    await _rebuildPlayer();
  }

  Future<void> _rebuildPlayer() async {
    final buildNonce = ++_playerBuildNonce;
    try {
      final nextPlayer = ToolboxRealisticEffectPlayer.build(
        variants: _audioVariants,
        bytesForVariant: (int variant) => ToolboxAudioBank.singingBowlTone(
          frequency: _frequencySpec.frequency,
          style: _voiceSpec.id,
          variant: variant,
        ),
        maxPlayers: 4,
        volumeJitter: 0.018,
      );
      await nextPlayer.warmUp();
      if (!mounted || buildNonce != _playerBuildNonce) {
        await nextPlayer.dispose();
        return;
      }
      final oldPlayer = _player;
      _player = nextPlayer;
      if (oldPlayer != null) {
        unawaited(oldPlayer.dispose());
      }
    } catch (_) {
      // Best-effort audio warmup.
    }
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 240), () {
      unawaited(ToolboxSingingBowlsPrefsService.save(_prefsState));
    });
  }

  Future<void> _stopVoices() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  void _restartAutoPlay({required bool strikeNow}) {
    _autoPlayTimer?.cancel();
    if (!_autoPlayEnabled) {
      return;
    }
    if (strikeNow) {
      unawaited(_strikeBowl(fromAutoPlay: true));
    }
    _autoPlayTimer = Timer.periodic(
      Duration(milliseconds: _autoPlayIntervalMs),
      (_) => unawaited(_strikeBowl(fromAutoPlay: true)),
    );
  }

  void _setFrequency(String id) {
    if (_frequencyId == id) {
      return;
    }
    final shouldResume = _autoPlayEnabled;
    _autoPlayTimer?.cancel();
    setState(() {
      _frequencyId = id;
    });
    unawaited(_stopVoices());
    _schedulePersist();
    unawaited(
      _rebuildPlayer().then((_) {
        if (!mounted || !shouldResume) {
          return;
        }
        _restartAutoPlay(strikeNow: true);
      }),
    );
  }

  void _setVoice(String id) {
    if (_voiceId == id) {
      return;
    }
    final shouldResume = _autoPlayEnabled;
    _autoPlayTimer?.cancel();
    setState(() {
      _voiceId = id;
    });
    unawaited(_stopVoices());
    _schedulePersist();
    unawaited(
      _rebuildPlayer().then((_) {
        if (!mounted || !shouldResume) {
          return;
        }
        _restartAutoPlay(strikeNow: true);
      }),
    );
  }

  void _setAutoPlayInterval(int value) {
    final next = value.clamp(_minAutoPlayMs, _maxAutoPlayMs).toInt();
    if (next == _autoPlayIntervalMs) {
      return;
    }
    setState(() {
      _autoPlayIntervalMs = next;
    });
    if (_autoPlayEnabled) {
      _restartAutoPlay(strikeNow: false);
    }
    _schedulePersist();
  }

  void _toggleAutoPlay() {
    final next = !_autoPlayEnabled;
    setState(() {
      _autoPlayEnabled = next;
    });
    if (next) {
      _restartAutoPlay(strikeNow: true);
    } else {
      _autoPlayTimer?.cancel();
    }
  }

  void _toggleSound() {
    final next = !_soundEnabled;
    setState(() {
      _soundEnabled = next;
    });
    if (!next) {
      unawaited(_stopVoices());
    }
    _schedulePersist();
  }

  void _toggleHaptics(bool value) {
    setState(() {
      _hapticsEnabled = value;
    });
    _schedulePersist();
  }

  void _toggleControlsExpanded() {
    setState(() {
      _controlsExpanded = !_controlsExpanded;
    });
  }

  void _stopResonance() {
    setState(() {
      _autoPlayEnabled = false;
    });
    _autoPlayTimer?.cancel();
    unawaited(_stopVoices());
  }

  void _addBurst() {
    final id = DateTime.now().microsecondsSinceEpoch;
    final seed = ((id % 100000) / 100000.0) * math.pi * 2;
    setState(() {
      final next = <_SpectrumBurst>[
        ..._bursts,
        _SpectrumBurst(id: id, seed: seed),
      ];
      _bursts = next.length > 4 ? next.sublist(next.length - 4) : next;
    });
  }

  void _removeBurst(int id) {
    if (!mounted) {
      return;
    }
    setState(() {
      _bursts = _bursts
          .where((burst) => burst.id != id)
          .toList(growable: false);
    });
  }

  Future<void> _strikeBowl({bool fromAutoPlay = false}) async {
    _addBurst();
    _strikeController.forward(from: 0);
    if (!fromAutoPlay && _hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (!_soundEnabled) {
      return;
    }
    try {
      await _player?.play(baseVolume: _voiceSpec.baseVolume);
    } catch (_) {}
  }

  String _t(String zh, String en) => _isZh ? zh : en;

  String _formatFrequency(double value) {
    if ((value - value.round()).abs() < 0.001) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final isPhone = constraints.maxWidth < 760;
        final mobileDrawerHeight = isPhone
            ? ((_controlsExpanded
                      ? math.min(constraints.maxHeight * 0.54, 430.0)
                      : 188.0)
                  .toDouble())
            : 0.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                _frequencySpec.gradient[0],
                _frequencySpec.gradient[1],
                _frequencySpec.gradient[2],
              ],
            ),
          ),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _SingingBowlBackdropPainter(
                    accent: _frequencySpec.accent,
                    glow: _frequencySpec.glow,
                    ambientValue: _ambientController,
                    strikeValue: _strikeController,
                  ),
                  child: isPhone
                      ? _buildMobileLayout(
                          context,
                          constraints,
                          reservedBottom: mobileDrawerHeight + 18,
                        )
                      : _buildWideLayout(context),
                ),
              ),
              if (isPhone)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _buildMobileDrawer(context, constraints),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    BoxConstraints constraints, {
    required double reservedBottom,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 10, 14, reservedBottom),
      child: Column(
        children: <Widget>[
          _buildMobileHeader(context),
          const SizedBox(height: 12),
          _buildSummaryCard(context, compact: true),
          const SizedBox(height: 10),
          Expanded(child: _buildStage(context, compact: true)),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: <Widget>[
          SizedBox(width: 308, child: _buildSidebar(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    _buildActionButton(
                      context,
                      icon: _soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      active: _soundEnabled,
                      tooltip: _soundEnabled
                          ? _t('点击静音', 'Mute')
                          : _t('点击恢复声音', 'Enable sound'),
                      onTap: _toggleSound,
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(
                      context,
                      icon: _autoPlayEnabled
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      active: _autoPlayEnabled,
                      tooltip: _autoPlayEnabled
                          ? _t('暂停自动敲击', 'Pause autoplay')
                          : _t('开始自动敲击', 'Start autoplay'),
                      onTap: _toggleAutoPlay,
                    ),
                    const SizedBox(width: 10),
                    _buildActionButton(
                      context,
                      icon: Icons.stop_circle_outlined,
                      active: false,
                      tooltip: _t('停止余振', 'Stop resonance'),
                      onTap: _stopResonance,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: _buildSummaryCard(context, compact: false),
                ),
                const SizedBox(height: 18),
                Expanded(child: _buildStage(context, compact: false)),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(child: _buildFooterCard(context)),
                    const SizedBox(width: 16),
                    SizedBox(width: 320, child: _buildSettingsCard(context)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Row(
      children: <Widget>[
        _buildPillIconButton(
          context,
          icon: Icons.arrow_back_rounded,
          active: false,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _t('疗愈音钵', 'Healing bowls'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                _t(
                  '频率、音色与空间尾韵的移动端重构。',
                  'Reference-matched tones rebuilt for mobile.',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _buildPillIconButton(
          context,
          icon: _soundEnabled
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          active: _soundEnabled,
          onTap: _toggleSound,
        ),
        const SizedBox(width: 8),
        _buildPillIconButton(
          context,
          icon: _autoPlayEnabled
              ? Icons.pause_circle_filled_rounded
              : Icons.play_circle_fill_rounded,
          active: _autoPlayEnabled,
          onTap: _toggleAutoPlay,
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _buildPillIconButton(
                  context,
                  icon: Icons.arrow_back_rounded,
                  active: false,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t('返回工具箱', 'Back to toolbox'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _t('疗愈音钵', 'Healing bowls'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _t(
                '对照参考页重构了 11 组频率与 4 套音色，并把手机端交互压缩成更顺手的卡片式控制流。',
                'Eleven reference-matched frequencies and four bowl voices, rebuilt into a more fluid mobile-first control flow.',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            _buildSectionTitle(
              context,
              title: _t('音色', 'Voices'),
              subtitle: _t(
                '与参考页一致的 4 套钵体谐波',
                'Four reference-aligned harmonic profiles',
              ),
            ),
            const SizedBox(height: 10),
            _buildVoiceGrid(context, compact: false),
            const SizedBox(height: 18),
            _buildSectionTitle(
              context,
              title: _t('频率菜单', 'Frequency menu'),
              subtitle: _t('七脉轮与古典共振频率', 'Chakra and resonance tones'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _bowlFrequencySpecs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final spec = _bowlFrequencySpecs[index];
                  return _buildFrequencyListTile(context, spec);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required bool compact}) {
    return DecoratedBox(
      decoration: _panelDecoration(
        context,
        alpha: compact ? 0.74 : 0.68,
        radius: 28,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 18 : 22,
          compact ? 16 : 18,
          compact ? 18 : 22,
          compact ? 16 : 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _buildInfoPill(
                  context,
                  text:
                      '${_frequencySpec.note} • ${_formatFrequency(_frequencySpec.frequency)} Hz',
                  accent: _frequencySpec.accent,
                ),
                _buildInfoPill(
                  context,
                  text: _voiceSpec.name(_isZh),
                  accent: _frequencySpec.glow,
                ),
                if (_autoPlayEnabled)
                  _buildInfoPill(
                    context,
                    text: _t(
                      '每 ${_autoPlayIntervalMs ~/ 1000} 秒自动敲击',
                      'Autoplay every ${_autoPlayIntervalMs ~/ 1000}s',
                    ),
                    accent: _frequencySpec.accent.withValues(alpha: 0.8),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _frequencySpec.name(_isZh),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_frequencySpec.subtitle(_isZh)} • ${_voiceSpec.description(_isZh)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _frequencySpec.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _frequencySpec.description(_isZh),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.52,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage(BuildContext context, {required bool compact}) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final baseSize = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final bowlSize = compact
                    ? baseSize.clamp(220.0, 296.0).toDouble()
                    : baseSize.clamp(300.0, 440.0).toDouble();
                return GestureDetector(
                  onTapDown: (_) {
                    setState(() {
                      _pressing = true;
                    });
                  },
                  onTapCancel: () {
                    setState(() {
                      _pressing = false;
                    });
                  },
                  onTapUp: (_) {
                    setState(() {
                      _pressing = false;
                    });
                  },
                  onTap: () => unawaited(_strikeBowl()),
                  child: Semantics(
                    button: true,
                    label: _t('敲击音钵', 'Strike bowl'),
                    child: SizedBox(
                      width: bowlSize * 2.2,
                      height: bowlSize * 2.2,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          for (final burst in _bursts)
                            _buildBurstWave(
                              burst: burst,
                              bowlSize: bowlSize * 2.02,
                            ),
                          AnimatedBuilder(
                            animation: Listenable.merge(<Listenable>[
                              _ambientController,
                              _strikeController,
                            ]),
                            builder: (BuildContext context, Widget? child) {
                              final strike = Curves.easeOutCubic.transform(
                                _strikeController.value,
                              );
                              final pulse =
                                  0.5 +
                                  0.5 *
                                      math.sin(
                                        _ambientController.value * math.pi * 2,
                                      );
                              final scale =
                                  1 -
                                  strike * 0.042 -
                                  (_pressing ? 0.02 : 0) +
                                  pulse * 0.004;
                              final yOffset = strike * 8.5;
                              return Transform.translate(
                                offset: Offset(0, yOffset),
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: SizedBox.square(
                              dimension: bowlSize,
                              child: CustomPaint(
                                painter: _SingingBowlPainter(
                                  accent: _frequencySpec.accent,
                                  glow: _frequencySpec.glow,
                                  voice: _voiceSpec,
                                  ambientValue: _ambientController.value,
                                  strikeValue: _strikeController.value,
                                  pressing: _pressing,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: _frequencySpec.accent,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _t(
                    '轻触中央音钵，听它从敲击、扩散到归静。',
                    'Tap the bowl and let it bloom, spread, and settle.',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterCard(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(context, alpha: 0.64, radius: 26),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _t('当前共振建议', 'Current listening note'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              _t(
                '如果你在夜里使用，优先尝试“深邃 + 地球 / 174 Hz”；如果是白天做短时调息，“水晶 + 和谐 / 528 Hz / 639 Hz”会更轻一些。',
                'At night, try Deep with Om / Earth or 174 Hz. For lighter daytime reset sessions, Crystal with Harmony, 528 Hz, or 639 Hz feels gentler.',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.52,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _buildInfoPill(
                  context,
                  text: _t('参考页同源频率体系', 'Reference-aligned tones'),
                  accent: _frequencySpec.accent,
                ),
                _buildInfoPill(
                  context,
                  text: _t('动态扩散衰减动画', 'Dynamic spectral decay'),
                  accent: _frequencySpec.glow,
                ),
                _buildInfoPill(
                  context,
                  text: _t('移动端抽屉卡片操作', 'Mobile drawer controls'),
                  accent: _frequencySpec.accent.withValues(alpha: 0.8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration(context, alpha: 0.7, radius: 26),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle(
              context,
              title: _t('自动播放', 'Autoplay'),
              subtitle: _t('慢而宽地重复，不要急促敲击', 'Slow, spacious repetition'),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _t('间隔时间', 'Interval'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${_autoPlayIntervalMs ~/ 1000}s',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _frequencySpec.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _frequencySpec.accent,
                inactiveTrackColor: _frequencySpec.accent.withValues(
                  alpha: 0.16,
                ),
                thumbColor: _frequencySpec.accent,
                overlayColor: _frequencySpec.accent.withValues(alpha: 0.12),
              ),
              child: Slider(
                min: _minAutoPlayMs.toDouble(),
                max: _maxAutoPlayMs.toDouble(),
                divisions: ((_maxAutoPlayMs - _minAutoPlayMs) / 1000).round(),
                value: _autoPlayIntervalMs.toDouble(),
                onChanged: (double value) =>
                    _setAutoPlayInterval(value.round()),
              ),
            ),
            Row(
              children: <Widget>[
                Text('2s', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text('30s', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _hapticsEnabled,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(_t('触感反馈', 'Haptics')),
              subtitle: Text(
                _t('手动敲击时提供轻微反馈', 'Add a light pulse on manual strike'),
              ),
              onChanged: _toggleHaptics,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: _toggleAutoPlay,
                  icon: Icon(
                    _autoPlayEnabled
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                  ),
                  label: Text(
                    _autoPlayEnabled
                        ? _t('暂停自动敲击', 'Pause autoplay')
                        : _t('开始自动敲击', 'Start autoplay'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _stopResonance,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(_t('停止余振', 'Stop resonance')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, BoxConstraints constraints) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final targetHeight =
        ((_controlsExpanded
                ? math.min(constraints.maxHeight * 0.54, 430.0)
                : 188.0)
            .toDouble()) +
        bottomPadding;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      height: targetHeight,
      decoration: _panelDecoration(context, alpha: 0.88, radius: 30),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomPadding),
      child: Column(
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleControlsExpanded,
            child: Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _frequencySpec.name(_isZh),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_frequencySpec.note} • ${_formatFrequency(_frequencySpec.frequency)} Hz • ${_voiceSpec.name(_isZh)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildPillIconButton(
                context,
                icon: _controlsExpanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                active: _controlsExpanded,
                onTap: _toggleControlsExpanded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: 72, child: _buildFrequencyStrip(context)),
          if (_controlsExpanded) ...<Widget>[
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    _buildSectionCard(
                      context,
                      title: _t('当前频率', 'Current tone'),
                      subtitle: _frequencySpec.subtitle(_isZh),
                      child: Text(
                        _frequencySpec.description(_isZh),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      context,
                      title: _t('音色抽屉', 'Voice drawer'),
                      subtitle: _t('四套钵体谐波', 'Four bowl harmonics'),
                      child: _buildVoiceGrid(context, compact: true),
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      context,
                      title: _t('自动播放', 'Autoplay'),
                      subtitle: _t(
                        '抽屉卡片里完成节奏调整',
                        'Adjust interval and haptics here',
                      ),
                      child: _buildAutoplayControls(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoplayControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _t('间隔时间', 'Interval'),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${_autoPlayIntervalMs ~/ 1000}s',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: _frequencySpec.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _frequencySpec.accent,
            inactiveTrackColor: _frequencySpec.accent.withValues(alpha: 0.16),
            thumbColor: _frequencySpec.accent,
            overlayColor: _frequencySpec.accent.withValues(alpha: 0.12),
          ),
          child: Slider(
            min: _minAutoPlayMs.toDouble(),
            max: _maxAutoPlayMs.toDouble(),
            divisions: ((_maxAutoPlayMs - _minAutoPlayMs) / 1000).round(),
            value: _autoPlayIntervalMs.toDouble(),
            onChanged: (double value) => _setAutoPlayInterval(value.round()),
          ),
        ),
        Row(
          children: <Widget>[
            Text('2s', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text('30s', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: _hapticsEnabled,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(_t('触感反馈', 'Haptics')),
          subtitle: Text(
            _t('手动敲击时给一点轻微反馈', 'Add a light pulse on manual strike'),
          ),
          onChanged: _toggleHaptics,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: _toggleAutoPlay,
              icon: Icon(
                _autoPlayEnabled
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
              ),
              label: Text(
                _autoPlayEnabled
                    ? _t('暂停', 'Pause')
                    : _t('开始自动敲击', 'Start autoplay'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _stopResonance,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(_t('停止余振', 'Stop resonance')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyStrip(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      itemCount: _bowlFrequencySpecs.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (BuildContext context, int index) {
        final spec = _bowlFrequencySpecs[index];
        final selected = spec.id == _frequencyId;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _setFrequency(spec.id),
            child: Ink(
              width: selected ? 82 : 62,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.96)
                    : Colors.white.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? spec.accent
                      : Colors.white.withValues(alpha: 0.82),
                ),
                boxShadow: <BoxShadow>[
                  if (selected)
                    BoxShadow(
                      color: spec.glow.withValues(alpha: 0.24),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    spec.note,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: selected
                          ? spec.accent
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selected
                        ? _formatFrequency(spec.frequency)
                        : '${spec.frequency.round()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? spec.accent
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceGrid(BuildContext context, {required bool compact}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final spacing = 10.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _bowlVoiceSpecs
              .map((spec) {
                final selected = spec.id == _voiceId;
                return SizedBox(
                  width: itemWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _setVoice(spec.id),
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? _frequencySpec.accent
                                : Colors.white.withValues(alpha: 0.78),
                          ),
                          boxShadow: <BoxShadow>[
                            if (selected)
                              BoxShadow(
                                color: _frequencySpec.glow.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Icon(
                                  spec.icon,
                                  size: 18,
                                  color: selected
                                      ? _frequencySpec.accent
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    spec.name(_isZh),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              spec.description(_isZh),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    height: 1.42,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildFrequencyListTile(
    BuildContext context,
    _SingingBowlFrequencySpec spec,
  ) {
    final selected = spec.id == _frequencyId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _setFrequency(spec.id),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.92)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? spec.accent
                  : Colors.white.withValues(alpha: 0.24),
            ),
            boxShadow: <BoxShadow>[
              if (selected)
                BoxShadow(
                  color: spec.glow.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? spec.accent
                      : Colors.white.withValues(alpha: 0.78),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    spec.note,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: selected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      spec.name(_isZh),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatFrequency(spec.frequency)} Hz • ${spec.subtitle(_isZh)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spec.description(_isZh),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Icon(Icons.graphic_eq_rounded, color: spec.accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBurstWave({
    required _SpectrumBurst burst,
    required double bowlSize,
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(burst.id),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 4600),
      curve: Curves.easeOutCubic,
      onEnd: () => _removeBurst(burst.id),
      builder: (BuildContext context, double value, Widget? child) {
        return IgnorePointer(
          child: SizedBox.square(
            dimension: bowlSize * 2.1,
            child: CustomPaint(
              painter: _SpectrumBurstPainter(
                accent: _frequencySpec.accent,
                glow: _frequencySpec.glow,
                progress: value,
                seed: burst.seed,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle(context, title: title, subtitle: subtitle),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required bool active,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: _buildPillIconButton(
        context,
        icon: icon,
        active: active,
        onTap: onTap,
      ),
    );
  }

  Widget _buildPillIconButton(
    BuildContext context, {
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active
                ? _frequencySpec.accent.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? _frequencySpec.accent
                  : Colors.white.withValues(alpha: 0.82),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: active
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPill(
    BuildContext context, {
    required String text,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration(
    BuildContext context, {
    double alpha = 0.74,
    double radius = 30,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 30,
          offset: const Offset(0, 16),
        ),
      ],
    );
  }
}

class _SingingBowlBackdropPainter extends CustomPainter {
  _SingingBowlBackdropPainter({
    required this.accent,
    required this.glow,
    required this.ambientValue,
    required this.strikeValue,
  }) : super(
         repaint: Listenable.merge(<Listenable>[ambientValue, strikeValue]),
       );

  final Color accent;
  final Color glow;
  final Animation<double> ambientValue;
  final Animation<double> strikeValue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pulse = 0.5 + 0.5 * math.sin(ambientValue.value * math.pi * 2);
    final strike = Curves.easeOut.transform(strikeValue.value);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.16),
        width: size.width * 0.9,
        height: size.shortestSide * 0.52,
      ),
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.34 + pulse * 0.05),
            glow.withValues(alpha: 0.14 + pulse * 0.06),
            glow.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.52, 1],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 58),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.82),
        width: size.width * 0.58,
        height: size.shortestSide * 0.22,
      ),
      Paint()
        ..color = accent.withValues(alpha: 0.05 + pulse * 0.02 + strike * 0.02)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 56),
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = accent.withValues(alpha: 0.026);
    const step = 28.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        linePaint,
      );
    }
    for (double x = 0; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.16),
            Colors.transparent,
            accent.withValues(alpha: 0.05),
          ],
          stops: const <double>[0, 0.42, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _SingingBowlBackdropPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.glow != glow ||
        oldDelegate.ambientValue != ambientValue ||
        oldDelegate.strikeValue != strikeValue;
  }
}

class _SpectrumBurstPainter extends CustomPainter {
  const _SpectrumBurstPainter({
    required this.accent,
    required this.glow,
    required this.progress,
    required this.seed,
  });

  final Color accent;
  final Color glow;
  final double progress;
  final double seed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide * 0.18;
    const ringCount = 5;

    for (var ring = 0; ring < ringCount; ring += 1) {
      final localProgress = (progress - ring * 0.09) / (1 - ring * 0.09);
      if (localProgress < 0 || localProgress > 1) {
        continue;
      }
      final eased = Curves.easeOut.transform(localProgress);
      final opacity =
          math.pow(1 - localProgress, 1.7).toDouble() * (0.26 - ring * 0.03);
      final radius = lerpDouble(
        baseRadius,
        size.shortestSide * (0.44 + ring * 0.035),
        eased,
      )!;
      final ellipse = 0.9 + ring * 0.03;
      final path = Path();
      const steps = 72;
      for (var step = 0; step <= steps; step += 1) {
        final theta = step / steps * math.pi * 2;
        final wobble =
            math.sin(theta * (3 + ring * 0.6) + seed + progress * 7.5) *
                size.shortestSide *
                0.012 *
                (1 - localProgress) +
            math.cos(theta * 5.2 - seed * 0.7 + progress * 5.0) *
                size.shortestSide *
                0.005 *
                (1 - localProgress);
        final r = radius + wobble;
        final point = Offset(
          center.dx + math.cos(theta) * r,
          center.dy + math.sin(theta) * r * ellipse,
        );
        if (step == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lerpDouble(2.2, 0.18, localProgress)!
          ..color = glow.withValues(alpha: opacity * 0.82)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lerpDouble(1.4, 0.12, localProgress)!
          ..color = accent.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumBurstPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.glow != glow ||
        oldDelegate.progress != progress ||
        oldDelegate.seed != seed;
  }
}

class _SingingBowlPainter extends CustomPainter {
  const _SingingBowlPainter({
    required this.accent,
    required this.glow,
    required this.voice,
    required this.ambientValue,
    required this.strikeValue,
    required this.pressing,
  });

  final Color accent;
  final Color glow;
  final _SingingBowlVoiceSpec voice;
  final double ambientValue;
  final double strikeValue;
  final bool pressing;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center.translate(0, size.height * 0.02);
    final pulse = 0.5 + 0.5 * math.sin(ambientValue * math.pi * 2);
    final strike = Curves.easeOutCubic.transform(strikeValue);
    final width = size.width * 0.76;
    final height = size.height * 0.42;
    final rimTop = center.dy - height * 0.34;
    final bowlPath = Path()
      ..moveTo(center.dx - width * 0.46, rimTop)
      ..quadraticBezierTo(
        center.dx - width * 0.54,
        center.dy + height * 0.74,
        center.dx,
        center.dy + height * 0.92,
      )
      ..quadraticBezierTo(
        center.dx + width * 0.54,
        center.dy + height * 0.74,
        center.dx + width * 0.46,
        rimTop,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + height * 0.10,
        center.dx - width * 0.46,
        rimTop,
      );
    final bowlBounds = bowlPath.getBounds();
    final topRimRect = Rect.fromCenter(
      center: Offset(center.dx, rimTop),
      width: width,
      height: height * 0.28,
    );
    final innerRimRect = Rect.fromCenter(
      center: Offset(center.dx, rimTop + height * 0.01),
      width: width * 0.86,
      height: height * 0.16,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, height * 0.98),
        width: width * 0.88,
        height: height * 0.22,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08 + strike * 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    canvas.drawCircle(
      center.translate(0, -height * 0.02),
      width * 0.42,
      Paint()
        ..color = glow.withValues(alpha: 0.12 + strike * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );

    canvas.drawPath(
      bowlPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.72),
            accent.withValues(alpha: 0.18 + strike * 0.08),
            accent.withValues(alpha: 0.10),
          ],
          stops: const <double>[0, 0.18, 0.72, 1],
        ).createShader(bowlBounds),
    );

    canvas.drawPath(
      bowlPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.52),
    );

    canvas.drawOval(
      topRimRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.92),
            accent.withValues(alpha: 0.22 + strike * 0.08),
          ],
        ).createShader(topRimRect),
    );
    canvas.drawOval(
      innerRimRect,
      Paint()..color = Colors.white.withValues(alpha: 0.84),
    );

    canvas.drawPath(
      Path()..addArc(
        Rect.fromCenter(
          center: center.translate(-width * 0.06, height * 0.16),
          width: width * 0.82,
          height: height * 0.7,
        ),
        -math.pi * 0.94,
        math.pi * 0.55,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.2 + strike * 0.08),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(width * 0.18, 0),
        width: width * 0.16,
        height: height * 0.56,
      ),
      Paint()
        ..color = accent.withValues(
          alpha: 0.16 + strike * 0.1 + (pressing ? 0.03 : 0),
        ),
    );

    final ringCount = switch (voice.id) {
      'pure' => 1,
      'deep' => 4,
      'brass' => 4,
      _ => 3,
    };
    for (var index = 0; index < ringCount; index += 1) {
      final ratio = ringCount == 1 ? 0.0 : index / (ringCount - 1);
      final ringRect = Rect.fromCenter(
        center: center.translate(0, height * 0.04),
        width: lerpDouble(width * 0.36, width * 0.74, ratio)!,
        height: lerpDouble(height * 0.12, height * 0.34, ratio)!,
      );
      canvas.drawOval(
        ringRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lerpDouble(1.4, 0.8, ratio)!
          ..color = glow.withValues(
            alpha: (0.08 + pulse * 0.04 + strike * 0.04) * (1 - ratio * 0.28),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SingingBowlPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.glow != glow ||
        oldDelegate.voice != voice ||
        oldDelegate.ambientValue != ambientValue ||
        oldDelegate.strikeValue != strikeValue ||
        oldDelegate.pressing != pressing;
  }
}
