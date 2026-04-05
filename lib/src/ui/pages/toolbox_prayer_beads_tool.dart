import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_audio_service.dart';
import '../../services/toolbox_prayer_beads_prefs_service.dart';
import '../ui_copy.dart';
import 'toolbox_tool_shell.dart';

const String _beadTextureAsset = 'assets/toolbox/beads/wood_texture.webp';

enum _PrayerBeadsMaterial {
  sandalwood,
  jade,
  lapis,
  bodhi,
  obsidian;

  String get id => name;
}

class _PrayerBeadsPalette {
  const _PrayerBeadsPalette({
    required this.stageGradient,
    required this.stageGlow,
    required this.beadColors,
    required this.beadShadow,
    required this.beadBorder,
    required this.threadDark,
    required this.threadLight,
    required this.accent,
    required this.secondaryAccent,
    required this.textureOpacity,
    required this.soundStyle,
  });

  final List<Color> stageGradient;
  final Color stageGlow;
  final List<Color> beadColors;
  final Color beadShadow;
  final Color beadBorder;
  final Color threadDark;
  final Color threadLight;
  final Color accent;
  final Color secondaryAccent;
  final double textureOpacity;
  final String soundStyle;
}

_PrayerBeadsPalette _paletteFor(_PrayerBeadsMaterial material) {
  return switch (material) {
    _PrayerBeadsMaterial.jade => const _PrayerBeadsPalette(
      stageGradient: <Color>[
        Color(0xFFF3F8F3),
        Color(0xFFE3EFE7),
        Color(0xFFD4E3DA),
      ],
      stageGlow: Color(0xFF9AD4BA),
      beadColors: <Color>[
        Color(0xFFEFFCF3),
        Color(0xFFBFE5C9),
        Color(0xFF7AB894),
      ],
      beadShadow: Color(0xFF84B89A),
      beadBorder: Color(0xFF5A8D76),
      threadDark: Color(0xFF557768),
      threadLight: Color(0xFFD8EFE2),
      accent: Color(0xFF1C8D65),
      secondaryAccent: Color(0xFF5FBBA8),
      textureOpacity: 0.08,
      soundStyle: 'jade',
    ),
    _PrayerBeadsMaterial.lapis => const _PrayerBeadsPalette(
      stageGradient: <Color>[
        Color(0xFFF1F5FF),
        Color(0xFFE3EBFD),
        Color(0xFFD5DDF6),
      ],
      stageGlow: Color(0xFF8EB0F0),
      beadColors: <Color>[
        Color(0xFFBFD6FF),
        Color(0xFF517AC8),
        Color(0xFF183B74),
      ],
      beadShadow: Color(0xFF476EBC),
      beadBorder: Color(0xFF13315D),
      threadDark: Color(0xFF2A3E68),
      threadLight: Color(0xFFD6E4FF),
      accent: Color(0xFF2F6BDF),
      secondaryAccent: Color(0xFF70A3FF),
      textureOpacity: 0.16,
      soundStyle: 'lapis',
    ),
    _PrayerBeadsMaterial.bodhi => const _PrayerBeadsPalette(
      stageGradient: <Color>[
        Color(0xFFFDF7EC),
        Color(0xFFF4E8D2),
        Color(0xFFE9D6B2),
      ],
      stageGlow: Color(0xFFDDBA6B),
      beadColors: <Color>[
        Color(0xFFF9E9BD),
        Color(0xFFD4A24E),
        Color(0xFF925F25),
      ],
      beadShadow: Color(0xFFA97634),
      beadBorder: Color(0xFF7E4E1B),
      threadDark: Color(0xFF71502A),
      threadLight: Color(0xFFF6E8C4),
      accent: Color(0xFFB96D15),
      secondaryAccent: Color(0xFFE4A547),
      textureOpacity: 0.24,
      soundStyle: 'bodhi',
    ),
    _PrayerBeadsMaterial.obsidian => const _PrayerBeadsPalette(
      stageGradient: <Color>[
        Color(0xFFF3F2F6),
        Color(0xFFE4E1E8),
        Color(0xFFD7D1D9),
      ],
      stageGlow: Color(0xFF9A8FA4),
      beadColors: <Color>[
        Color(0xFF6D6675),
        Color(0xFF2F2836),
        Color(0xFF141118),
      ],
      beadShadow: Color(0xFF3D3545),
      beadBorder: Color(0xFF0E0B11),
      threadDark: Color(0xFF2B2331),
      threadLight: Color(0xFFEAE1EF),
      accent: Color(0xFF4D3A5E),
      secondaryAccent: Color(0xFF8B6DA4),
      textureOpacity: 0.12,
      soundStyle: 'obsidian',
    ),
    _ => const _PrayerBeadsPalette(
      stageGradient: <Color>[
        Color(0xFFFDF8F1),
        Color(0xFFF2E8D7),
        Color(0xFFE4D2B8),
      ],
      stageGlow: Color(0xFFDCAA71),
      beadColors: <Color>[
        Color(0xFF8B4B24),
        Color(0xFF5F2911),
        Color(0xFF341407),
      ],
      beadShadow: Color(0xFF6A331A),
      beadBorder: Color(0xFF2A0D03),
      threadDark: Color(0xFF533320),
      threadLight: Color(0xFFF5E7D5),
      accent: Color(0xFF9C4E23),
      secondaryAccent: Color(0xFFD99861),
      textureOpacity: 0.28,
      soundStyle: 'sandalwood',
    ),
  };
}

_PrayerBeadsMaterial _materialFromId(String? value) {
  return switch (value) {
    'jade' => _PrayerBeadsMaterial.jade,
    'lapis' => _PrayerBeadsMaterial.lapis,
    'bodhi' => _PrayerBeadsMaterial.bodhi,
    'obsidian' => _PrayerBeadsMaterial.obsidian,
    _ => _PrayerBeadsMaterial.sandalwood,
  };
}

class _StageBeadLayout {
  const _StageBeadLayout({
    required this.slot,
    required this.size,
    required this.center,
    required this.opacity,
    required this.label,
    required this.active,
    required this.interaction,
    required this.focus,
  });

  final int slot;
  final double size;
  final Offset center;
  final double opacity;
  final int label;
  final bool active;
  final double interaction;
  final double focus;
}

class PrayerBeadsPracticeCard extends StatefulWidget {
  const PrayerBeadsPracticeCard({super.key});

  @override
  State<PrayerBeadsPracticeCard> createState() =>
      _PrayerBeadsPracticeCardState();
}

class _PrayerBeadsPracticeCardState extends State<PrayerBeadsPracticeCard>
    with TickerProviderStateMixin {
  static const List<int> _beadPresets = <int>[27, 54, 108];
  static const List<int> _visibleSlots = <int>[-4, -3, -2, -1, 0, 1, 2, 3, 4];
  static const SpringDescription _strandSpring = SpringDescription(
    mass: 1,
    stiffness: 360,
    damping: 34,
  );

  final Stopwatch _sessionStopwatch = Stopwatch();
  Timer? _elapsedTimer;
  Timer? _persistTimer;
  Timer? _bannerTimer;

  late final AnimationController _interactionController;
  late final AnimationController _strandController;

  ToolboxEffectPlayer? _regularPlayer;
  ToolboxEffectPlayer? _accentPlayer;

  _PrayerBeadsMaterial _material = _PrayerBeadsMaterial.sandalwood;
  int _beadCount = 108;
  int _sessionCount = 0;
  int _allTimeCount = 0;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _hasInteracted = false;
  int _advanceDirection = 1;
  bool _didAdvanceThisGesture = false;

  double _dragStep = 96;
  Duration _elapsed = Duration.zero;
  String? _momentLabel;

  PrayerBeadsPrefsState get _prefsState => PrayerBeadsPrefsState(
    materialId: _material.id,
    beadCount: _beadCount,
    sessionCount: _sessionCount,
    allTimeCount: _allTimeCount,
    soundEnabled: _soundEnabled,
    hapticsEnabled: _hapticsEnabled,
  );

  _PrayerBeadsPalette get _palette => _paletteFor(_material);
  int get _rounds => _sessionCount ~/ _beadCount;

  int get _cycleCount {
    if (_sessionCount == 0) {
      return 0;
    }
    final remainder = _sessionCount % _beadCount;
    return remainder == 0 ? _beadCount : remainder;
  }

  int get _activeIndex {
    if (_beadCount <= 0) {
      return 0;
    }
    return _sessionCount % _beadCount;
  }

  double get _cycleProgress => _cycleCount / _beadCount;

  double get _strandOffset => _strandController.value;
  double get _strandVelocity => _strandController.velocity;
  int get _layoutDirection => _advanceDirection >= 0 ? 1 : -1;

  @override
  void initState() {
    super.initState();
    _interactionController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 280),
        )..addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
    _strandController =
        AnimationController.unbounded(
          vsync: this,
          animationBehavior: AnimationBehavior.normal,
        )..addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
    unawaited(_loadPrefs());
    unawaited(_rebuildPlayers());
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _persistTimer?.cancel();
    _bannerTimer?.cancel();
    _sessionStopwatch.stop();
    _interactionController.dispose();
    _strandController.dispose();
    final regular = _regularPlayer;
    final accent = _accentPlayer;
    if (regular != null) {
      unawaited(regular.dispose());
    }
    if (accent != null) {
      unawaited(accent.dispose());
    }
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await ToolboxPrayerBeadsPrefsService.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _material = _materialFromId(prefs.materialId);
      _beadCount = prefs.beadCount;
      _sessionCount = prefs.sessionCount;
      _allTimeCount = prefs.allTimeCount;
      _soundEnabled = prefs.soundEnabled;
      _hapticsEnabled = prefs.hapticsEnabled;
      _hasInteracted = _sessionCount > 0;
    });
    if (_sessionCount > 0) {
      _ensureElapsedTimer();
      _sessionStopwatch.start();
    }
    await _rebuildPlayers();
  }

  Future<void> _rebuildPlayers() async {
    try {
      final regular = ToolboxEffectPlayer(
        ToolboxAudioBank.prayerBeadClick(style: _palette.soundStyle),
      );
      final accent = ToolboxEffectPlayer(
        ToolboxAudioBank.prayerBeadClick(
          style: _palette.soundStyle,
          accent: true,
        ),
      );
      await Future.wait(<Future<void>>[regular.warmUp(), accent.warmUp()]);
      final oldRegular = _regularPlayer;
      final oldAccent = _accentPlayer;
      _regularPlayer = regular;
      _accentPlayer = accent;
      if (oldRegular != null) {
        unawaited(oldRegular.dispose());
      }
      if (oldAccent != null) {
        unawaited(oldAccent.dispose());
      }
    } catch (_) {
      // Audio is best-effort and may be unavailable in tests or unsupported
      // environments.
    }
  }

  void _ensureElapsedTimer() {
    if (_elapsedTimer != null) {
      return;
    }
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_sessionStopwatch.isRunning) {
        return;
      }
      setState(() {
        _elapsed = _sessionStopwatch.elapsed;
      });
    });
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 220), () {
      unawaited(ToolboxPrayerBeadsPrefsService.save(_prefsState));
    });
  }

  void _showMoment(String label) {
    _bannerTimer?.cancel();
    setState(() {
      _momentLabel = label;
    });
    _bannerTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _momentLabel = null;
      });
    });
  }

  Future<void> _playAdvanceEffect({required bool accent}) async {
    if (!_soundEnabled) {
      return;
    }
    try {
      final player = accent ? _accentPlayer : _regularPlayer;
      await player?.play(volume: accent ? 0.92 : 0.82);
    } catch (_) {}
  }

  void _stopStrandMotion() {
    if (_strandController.isAnimating) {
      _strandController.stop();
    }
  }

  void _setStrandOffset(double offset) {
    _strandController.value = offset;
  }

  void _resetStrandOffset([double offset = 0]) {
    _stopStrandMotion();
    _didAdvanceThisGesture = false;
    _setStrandOffset(offset);
  }

  void _animateStrandToRest({double releaseVelocity = 0}) {
    final currentOffset = _strandOffset;
    if (currentOffset.abs() < 0.35 && releaseVelocity.abs() < 14) {
      _setStrandOffset(0);
      return;
    }
    final simulation = SpringSimulation(
      _strandSpring,
      currentOffset,
      0,
      releaseVelocity,
      tolerance: const Tolerance(distance: 0.3, velocity: 12),
    );
    _strandController.animateWith(simulation);
  }

  double _dragResistanceFor(int direction) {
    return direction > 0 ? 0.62 : 0.86;
  }

  double _releaseVelocityFactorFor(int direction) {
    return direction > 0 ? 0.24 : 0.34;
  }

  double _completionThresholdFor(int direction) {
    return direction > 0 ? 0.74 : 0.62;
  }

  double _clampPostAdvanceOffset(double offset, {required int direction}) {
    final min = direction > 0 ? -_dragStep * 0.14 : -_dragStep * 0.34;
    final max = direction > 0 ? _dragStep * 0.34 : _dragStep * 0.14;
    return offset.clamp(min, max);
  }

  void _handleAdvance({required String source}) {
    final completesRound = (_sessionCount + 1) % _beadCount == 0;
    if (!_sessionStopwatch.isRunning) {
      _sessionStopwatch.start();
      _ensureElapsedTimer();
    }
    if (_hapticsEnabled) {
      if (completesRound) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    setState(() {
      _hasInteracted = true;
      _sessionCount += 1;
      _allTimeCount += 1;
    });
    _interactionController.forward(from: 0);
    if (completesRound) {
      _showMoment(_t(zh: '已完成一圈', en: 'Round complete'));
    }
    _schedulePersist();
    unawaited(_playAdvanceEffect(accent: completesRound));
  }

  void _handleTapAdvance() {
    _stopStrandMotion();
    _advanceDirection = 1;
    _didAdvanceThisGesture = true;
    _handleAdvance(source: 'tap');
    final slideInOffset = (_dragStep * 0.28).clamp(18.0, 34.0);
    _setStrandOffset(-slideInOffset);
    _animateStrandToRest(releaseVelocity: _dragStep * 7.2);
    _didAdvanceThisGesture = false;
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    _stopStrandMotion();
    _didAdvanceThisGesture = false;
  }

  void _undo() {
    if (_sessionCount == 0) {
      return;
    }
    _resetStrandOffset();
    setState(() {
      _sessionCount = math.max(0, _sessionCount - 1);
      _allTimeCount = math.max(0, _allTimeCount - 1);
    });
    if (_sessionCount == 0) {
      _sessionStopwatch
        ..stop()
        ..reset();
      _elapsed = Duration.zero;
    }
    _schedulePersist();
  }

  void _resetSession() {
    _resetStrandOffset();
    setState(() {
      _sessionCount = 0;
      _momentLabel = null;
      _hasInteracted = false;
      _elapsed = Duration.zero;
    });
    _sessionStopwatch
      ..stop()
      ..reset();
    _schedulePersist();
  }

  void _setMaterial(_PrayerBeadsMaterial material) {
    if (_material == material) {
      return;
    }
    setState(() {
      _material = material;
    });
    _schedulePersist();
    unawaited(_rebuildPlayers());
  }

  void _setBeadCount(int beadCount) {
    if (_beadCount == beadCount) {
      return;
    }
    _resetStrandOffset();
    setState(() {
      _beadCount = beadCount;
      _sessionCount = 0;
      _momentLabel = null;
      _elapsed = Duration.zero;
      _hasInteracted = false;
    });
    _sessionStopwatch
      ..stop()
      ..reset();
    _schedulePersist();
  }

  void _toggleSound(bool enabled) {
    setState(() {
      _soundEnabled = enabled;
    });
    _schedulePersist();
  }

  void _toggleHaptics(bool enabled) {
    setState(() {
      _hapticsEnabled = enabled;
    });
    _schedulePersist();
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    _stopStrandMotion();
    final rawDelta = details.primaryDelta ?? 0;
    if (rawDelta.abs() <= 0.01) {
      return;
    }
    final direction = rawDelta >= 0 ? 1 : -1;
    if (!_didAdvanceThisGesture) {
      _advanceDirection = direction;
    }
    final delta = rawDelta * _dragResistanceFor(direction);

    if (_didAdvanceThisGesture) {
      final easedOffset = _strandOffset + delta * 0.42;
      _setStrandOffset(
        _clampPostAdvanceOffset(easedOffset, direction: _advanceDirection),
      );
      return;
    }

    var nextOffset = (_strandOffset + delta).clamp(
      -_dragStep * 1.08,
      _dragStep * 1.08,
    );
    final crossedStep = direction > 0
        ? nextOffset >= _dragStep
        : nextOffset <= -_dragStep;
    if (crossedStep) {
      _advanceDirection = direction;
      _didAdvanceThisGesture = true;
      _handleAdvance(source: 'drag');
      nextOffset = _clampPostAdvanceOffset(
        (nextOffset - direction * _dragStep) * 0.46,
        direction: direction,
      );
    }

    _setStrandOffset(nextOffset);
    if (!_hasInteracted) {
      setState(() {
        _hasInteracted = true;
      });
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    _stopStrandMotion();
    var currentOffset = _strandOffset;
    final direction = currentOffset == 0
        ? _layoutDirection
        : (currentOffset > 0 ? 1 : -1);
    final velocityY = details.velocity.pixelsPerSecond.dy;
    if (!_didAdvanceThisGesture && currentOffset != 0) {
      final progress = (currentOffset.abs() / math.max(_dragStep, 1)).clamp(
        0.0,
        1.0,
      );
      final projectedOffset = currentOffset + velocityY * 0.07;
      final velocityAligned = direction > 0
          ? velocityY > 780
          : velocityY < -620;
      final projectedAligned = direction > 0
          ? projectedOffset > _dragStep * 0.66
          : projectedOffset < -_dragStep * 0.58;
      if (progress > _completionThresholdFor(direction) ||
          projectedAligned ||
          velocityAligned ||
          currentOffset.abs() >=
              (direction > 0 ? _dragStep * 0.94 : _dragStep * 0.88)) {
        _advanceDirection = direction;
        _didAdvanceThisGesture = true;
        _handleAdvance(source: 'drag');
        currentOffset = _clampPostAdvanceOffset(
          (currentOffset - direction * _dragStep) * 0.46,
          direction: direction,
        );
        _setStrandOffset(currentOffset);
      }
    }
    _setStrandOffset(currentOffset);
    _animateStrandToRest(
      releaseVelocity:
          velocityY *
          _releaseVelocityFactorFor(
            _didAdvanceThisGesture ? _advanceDirection : direction,
          ),
    );
    _didAdvanceThisGesture = false;
  }

  String _t({required String zh, required String en}) {
    return pickUiText(
      AppI18n(Localizations.localeOf(context).languageCode),
      zh: zh,
      en: en,
    );
  }

  String _materialLabel(_PrayerBeadsMaterial material) {
    return switch (material) {
      _PrayerBeadsMaterial.jade => _t(zh: '白玉', en: 'Jade'),
      _PrayerBeadsMaterial.lapis => _t(zh: '青金', en: 'Lapis'),
      _PrayerBeadsMaterial.bodhi => _t(zh: '菩提', en: 'Bodhi'),
      _PrayerBeadsMaterial.obsidian => _t(zh: '黑曜', en: 'Obsidian'),
      _ => _t(zh: '檀木', en: 'Sandalwood'),
    };
  }

  String _materialHint(_PrayerBeadsMaterial material) {
    return switch (material) {
      _PrayerBeadsMaterial.jade => _t(
        zh: '更清润，回响更轻。',
        en: 'Softer and cleaner with a lighter ring.',
      ),
      _PrayerBeadsMaterial.lapis => _t(
        zh: '更凝练，带一点石感。',
        en: 'Denser and slightly stone-like.',
      ),
      _PrayerBeadsMaterial.bodhi => _t(
        zh: '更温暖，颗粒感更明显。',
        en: 'Warmer with a more tactile seed feel.',
      ),
      _PrayerBeadsMaterial.obsidian => _t(
        zh: '更沉静，声音更收束。',
        en: 'Darker and more contained in tone.',
      ),
      _ => _t(
        zh: '参考檀木材质，触感最自然。',
        en: 'Warm wood character with a natural tactile feel.',
      ),
    };
  }

  String _formatElapsed(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeroCard(context),
        const SizedBox(height: 16),
        _buildStageCard(context),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            ToolboxMetricCard(
              label: _t(zh: '本轮进度', en: 'Cycle'),
              value: '$_cycleCount / $_beadCount',
            ),
            ToolboxMetricCard(
              label: _t(zh: '已完成圈数', en: 'Rounds'),
              value: '$_rounds',
            ),
            ToolboxMetricCard(
              label: _t(zh: '累计拨动', en: 'All-time'),
              value: '$_allTimeCount',
            ),
            ToolboxMetricCard(
              label: _t(zh: '本次时长', en: 'Session'),
              value: _formatElapsed(_elapsed),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(context),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _palette.stageGradient,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _palette.stageGlow.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _materialLabel(_material),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _palette.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _t(zh: '静心念珠练习', en: 'Prayer bead practice'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF23180F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              zh: '轻点或向下拨动中位念珠，也可以向上推拨，让下一颗珠子自然滑入中位。',
              en: 'Tap or pull the center bead downward. Upward strokes also work and the next bead will slide into center.',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: const Color(0xFF4F3D2F),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _materialHint(_material),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6E5B49)),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _cycleProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.45),
              valueColor: AlwaysStoppedAnimation<Color>(_palette.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _cycleCount == 0
                ? _t(zh: '尚未开始', en: 'Not started yet')
                : _t(
                    zh: '当前已拨 $_cycleCount / $_beadCount 颗',
                    en: '$_cycleCount of $_beadCount beads in this cycle',
                  ),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF4B3A2C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _palette.stageGlow.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final stageHeight = math.min(
              560.0,
              math.max(400.0, constraints.maxWidth * 1.18),
            );
            final beadSize = math.min(88.0, constraints.maxWidth * 0.22);
            final beadSpacing = beadSize * 1.12;
            _dragStep = beadSpacing;
            final snapValue =
                1 - Curves.easeOutCubic.transform(_interactionController.value);
            final strandOffset = _strandOffset;
            final strandVelocity = _strandVelocity;
            final layouts = _visibleSlots
                .map(
                  (slot) => _buildStageBeadLayout(
                    slot: slot,
                    beadSize: beadSize,
                    beadSpacing: beadSpacing,
                    stageHeight: stageHeight,
                    strandOffset: strandOffset,
                    strandVelocity: strandVelocity,
                    snapValue: snapValue,
                  ),
                )
                .toList(growable: false);

            return Container(
              key: const Key('prayer-beads-stage'),
              height: stageHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _palette.stageGradient,
                ),
              ),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PrayerBeadsStagePainter(
                        palette: _palette,
                        interaction: snapValue,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PrayerBeadsThreadPainter(
                        layouts: layouts,
                        palette: _palette,
                        strandOffset: strandOffset,
                        strandVelocity: strandVelocity,
                        beadSpacing: beadSpacing,
                      ),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleTapAdvance,
                    onVerticalDragStart: _handleVerticalDragStart,
                    onVerticalDragUpdate: _handleVerticalDragUpdate,
                    onVerticalDragEnd: _handleVerticalDragEnd,
                    onVerticalDragCancel: () =>
                        _handleVerticalDragEnd(DragEndDetails()),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        for (final layout in layouts)
                          _buildStageBead(context, layout: layout),
                        if (_momentLabel != null)
                          Positioned(
                            top: 26,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _momentLabel == null ? 0 : 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _palette.accent.withValues(
                                      alpha: 0.22,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _momentLabel!,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: _palette.accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: _hasInteracted ? 0 : 1,
                          child: IgnorePointer(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.swipe_down_alt_rounded,
                                      color: const Color(
                                        0xFF8B7767,
                                      ).withValues(alpha: 0.8),
                                      size: 22,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _t(
                                        zh: '轻点或向下拨动中位念珠',
                                        en: 'Tap or pull the center bead down',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: const Color(0xFF695749),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  _StageBeadLayout _buildStageBeadLayout({
    required int slot,
    required double beadSize,
    required double beadSpacing,
    required double stageHeight,
    required double strandOffset,
    required double strandVelocity,
    required double snapValue,
  }) {
    final centerLine = stageHeight * 0.5;
    final centerY = centerLine + slot * beadSpacing + strandOffset;
    final slotDistance = slot.abs();
    final scaleBase = math.max(0.72, 1 - slotDistance * 0.07);
    final distanceRatio = ((centerY - centerLine).abs() / beadSpacing).clamp(
      0.0,
      1.35,
    );
    final focus = Curves.easeOutCubic.transform(
      (1 - distanceRatio.clamp(0.0, 1.0)).toDouble(),
    );
    final opacity = (0.18 + (1 - slotDistance * 0.14) + focus * 0.22).clamp(
      0.18,
      1.0,
    );
    final size =
        beadSize *
        scaleBase *
        (1 + focus * 0.12 + (slot == 0 ? snapValue * 0.04 : 0));
    final dragRatio = (strandOffset / math.max(beadSpacing, 1)).clamp(
      -1.0,
      1.0,
    );
    final velocityRatio = (strandVelocity / math.max(beadSpacing * 12, 1))
        .clamp(-1.0, 1.0);
    final centerX =
        (slot == 0
                ? dragRatio * 1.8 + velocityRatio * 1.2
                : math.sin((_activeIndex - slot * _layoutDirection) * 0.68) *
                          7 *
                          (1 - slotDistance * 0.08) +
                      dragRatio * (2.4 - slotDistance * 0.24) +
                      velocityRatio * (1.8 - slotDistance * 0.16))
            .toDouble();
    final beadIndex = (_activeIndex - slot * _layoutDirection) % _beadCount;
    final normalizedIndex = beadIndex < 0 ? beadIndex + _beadCount : beadIndex;
    final isActive = slot == 0;

    return _StageBeadLayout(
      slot: slot,
      size: size,
      center: Offset(centerX, centerY),
      opacity: opacity,
      label: normalizedIndex + 1,
      active: isActive,
      interaction: snapValue * (0.3 + focus * 0.7),
      focus: focus,
    );
  }

  Widget _buildStageBead(
    BuildContext context, {
    required _StageBeadLayout layout,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      top: layout.center.dy - layout.size / 2,
      child: IgnorePointer(
        child: Transform.translate(
          offset: Offset(layout.center.dx, 0),
          child: Opacity(
            opacity: layout.opacity,
            child: Center(
              child: _PrayerBeadWidget(
                size: layout.size,
                palette: _palette,
                active: layout.active,
                interaction: layout.interaction,
                focus: layout.focus,
                label: layout.label,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _t(zh: '练习设置', en: 'Practice settings'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              _t(
                zh: '念珠颗数决定一圈长度，材质同时影响视觉和拨珠声的质感。',
                en: 'Bead count changes the cycle length, and material changes both visuals and click character.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              _t(zh: '圈数规格', en: 'Cycle size'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _beadPresets
                  .map(
                    (count) => ChoiceChip(
                      key: Key('prayer-beads-preset-$count'),
                      label: Text('$count'),
                      selected: _beadCount == count,
                      onSelected: (_) => _setBeadCount(count),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            Text(
              _t(zh: '材质主题', en: 'Material'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Column(
              children: _PrayerBeadsMaterial.values
                  .map((material) => _buildMaterialTile(context, material))
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              key: const Key('prayer-beads-sound-switch'),
              value: _soundEnabled,
              contentPadding: EdgeInsets.zero,
              title: Text(_t(zh: '拨珠声音', en: 'Bead sound')),
              subtitle: Text(
                _t(
                  zh: '每次推进一颗时播放短促拨动声。',
                  en: 'Play a short tactile click on each advance.',
                ),
              ),
              onChanged: _toggleSound,
            ),
            SwitchListTile.adaptive(
              key: const Key('prayer-beads-haptics-switch'),
              value: _hapticsEnabled,
              contentPadding: EdgeInsets.zero,
              title: Text(_t(zh: '触觉反馈', en: 'Haptics')),
              subtitle: Text(
                _t(
                  zh: '完整一圈时会给更明显的完成反馈。',
                  en: 'A stronger haptic is used when a cycle completes.',
                ),
              ),
              onChanged: _toggleHaptics,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  key: const Key('prayer-beads-undo'),
                  onPressed: _sessionCount == 0 ? null : _undo,
                  icon: const Icon(Icons.undo_rounded),
                  label: Text(_t(zh: '撤回一颗', en: 'Undo one')),
                ),
                OutlinedButton.icon(
                  key: const Key('prayer-beads-reset'),
                  onPressed: _sessionCount == 0 ? null : _resetSession,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_t(zh: '重置本轮', en: 'Reset session')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialTile(
    BuildContext context,
    _PrayerBeadsMaterial material,
  ) {
    final palette = _paletteFor(material);
    final selected = _material == material;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('prayer-beads-material-${material.id}'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => _setMaterial(material),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? palette.accent
                    : Theme.of(context).colorScheme.outlineVariant,
                width: selected ? 1.6 : 1,
              ),
              color: selected
                  ? palette.accent.withValues(alpha: 0.08)
                  : Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            child: Row(
              children: <Widget>[
                _PrayerBeadWidget(
                  size: 34,
                  palette: palette,
                  active: selected,
                  interaction: selected ? 0.6 : 0,
                  focus: selected ? 0.8 : 0.24,
                  label: 0,
                  showHole: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _materialLabel(material),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _materialHint(material),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: palette.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrayerBeadWidget extends StatelessWidget {
  const _PrayerBeadWidget({
    required this.size,
    required this.palette,
    required this.active,
    required this.interaction,
    required this.focus,
    required this.label,
    this.showHole = true,
  });

  final double size;
  final _PrayerBeadsPalette palette;
  final bool active;
  final double interaction;
  final double focus;
  final int label;
  final bool showHole;

  @override
  Widget build(BuildContext context) {
    final emphasis = (focus * 0.86 + (active ? 0.18 : 0.0)).clamp(0.0, 1.0);
    final glow = (focus * 0.22 + interaction * 0.18).clamp(0.0, 0.42);
    final labelOpacity = (0.28 + focus * 0.72).clamp(0.0, 1.0);
    final holeRim = Color.lerp(palette.threadLight, palette.beadBorder, 0.38)!;
    final holeCavity = Color.lerp(palette.beadBorder, Colors.black, 0.54)!;

    Widget buildHole({required bool top}) {
      return Align(
        alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
        child: Container(
          width: size * 0.24,
          height: size * 0.106,
          margin: EdgeInsets.only(
            top: top ? size * 0.028 : 0,
            bottom: top ? 0 : size * 0.028,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: <Color>[
                holeRim.withValues(alpha: 0.88),
                palette.beadBorder.withValues(alpha: 0.62),
              ],
            ),
            border: Border.all(
              color: palette.beadBorder.withValues(alpha: 0.46 + focus * 0.16),
              width: size * 0.012,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14 + focus * 0.08),
                blurRadius: size * 0.045,
                offset: Offset(0, top ? 1.1 : -1.1),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: size * 0.136,
              height: size * 0.05,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                  end: top ? Alignment.bottomCenter : Alignment.topCenter,
                  colors: <Color>[
                    holeCavity.withValues(alpha: 0.72),
                    Colors.black.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.beadShadow.withValues(alpha: 0.16 + emphasis * 0.2),
            blurRadius: 10 + emphasis * 12,
            offset: Offset(0, 7 + emphasis * 2),
          ),
          if (glow > 0.02)
            BoxShadow(
              color: palette.stageGlow.withValues(alpha: glow),
              blurRadius: 18 + emphasis * 14,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.25, -0.32),
                  radius: 1.05,
                  colors: <Color>[
                    Color.lerp(
                      palette.beadColors[0],
                      Colors.white,
                      0.18 + focus * 0.08,
                    )!,
                    palette.beadColors[0],
                    palette.beadColors[1],
                    palette.beadColors[2],
                  ],
                  stops: const <double>[0.0, 0.25, 0.62, 1.0],
                ),
                border: Border.all(
                  color: palette.beadBorder.withValues(alpha: 0.75),
                ),
              ),
            ),
            Opacity(
              opacity: palette.textureOpacity,
              child: Image.asset(_beadTextureAsset, fit: BoxFit.cover),
            ),
            Positioned(
              left: size * 0.17,
              top: size * 0.14,
              child: Container(
                width: size * 0.28,
                height: size * 0.16,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18 + focus * 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.34, 0.42),
                    radius: 0.88,
                    colors: <Color>[
                      Colors.transparent,
                      palette.beadBorder.withValues(alpha: 0.08 + focus * 0.04),
                    ],
                    stops: const <double>[0.56, 1.0],
                  ),
                ),
              ),
            ),
            if (showHole) ...<Widget>[
              buildHole(top: true),
              buildHole(top: false),
            ],
            if (active && label > 0)
              Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: labelOpacity,
                  child: Text(
                    '$label',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrayerBeadsStagePainter extends CustomPainter {
  const _PrayerBeadsStagePainter({
    required this.palette,
    required this.interaction,
  });

  final _PrayerBeadsPalette palette;
  final double interaction;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawCircle(
      Offset(centerX, centerY),
      size.width * 0.24,
      Paint()
        ..color = palette.stageGlow.withValues(alpha: 0.16 + interaction * 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );

    final dustPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i += 1) {
      final dx = (math.sin(i * 1.7) * 0.4 + 0.5) * size.width;
      final dy = (math.cos(i * 0.9) * 0.35 + 0.5) * size.height;
      canvas.drawCircle(Offset(dx, dy), i.isEven ? 1.2 : 0.8, dustPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PrayerBeadsStagePainter oldDelegate) {
    return oldDelegate.palette != palette ||
        oldDelegate.interaction != interaction;
  }
}

class _PrayerBeadsThreadPainter extends CustomPainter {
  const _PrayerBeadsThreadPainter({
    required this.layouts,
    required this.palette,
    required this.strandOffset,
    required this.strandVelocity,
    required this.beadSpacing,
  });

  final List<_StageBeadLayout> layouts;
  final _PrayerBeadsPalette palette;
  final double strandOffset;
  final double strandVelocity;
  final double beadSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    if (layouts.length < 2) {
      return;
    }
    final sortedLayouts = layouts.toList()
      ..sort((a, b) => a.center.dy.compareTo(b.center.dy));
    final strandProgress = (strandOffset.abs() / math.max(beadSpacing, 1))
        .clamp(0.0, 1.0);
    final velocityInfluence =
        (strandVelocity.abs() / math.max(beadSpacing * 10, 1)).clamp(0.0, 1.0);

    for (var index = 0; index < sortedLayouts.length - 1; index += 1) {
      final current = sortedLayouts[index];
      final next = sortedLayouts[index + 1];
      final start = Offset(
        size.width / 2 + current.center.dx,
        current.center.dy + current.size * 0.425,
      );
      final end = Offset(
        size.width / 2 + next.center.dx,
        next.center.dy - next.size * 0.425,
      );
      final span = end.dy - start.dy;
      if (span <= 0) {
        continue;
      }
      final midY = (start.dy + end.dy) / 2;
      final centerInfluence =
          (1 -
                  ((midY - size.height / 2).abs() /
                      math.max(size.height * 0.5, 1)))
              .clamp(0.0, 1.0);
      final tension = (strandProgress * (0.56 + centerInfluence * 0.44)).clamp(
        0.0,
        1.0,
      );
      final dynamicTension = (tension * 0.74 + velocityInfluence * 0.26).clamp(
        0.0,
        1.0,
      );
      final bowDirection = math.sin(
        (current.slot + next.slot) * 0.72 +
            strandOffset / math.max(beadSpacing, 1),
      );
      final bowX =
          bowDirection *
          (5.6 + centerInfluence * 3.6) *
          (1 - dynamicTension * 0.82);
      final slackRatio = 0.27 + (1 - dynamicTension) * 0.1;
      final threadWidth = 2.7 + centerInfluence * 0.55 - dynamicTension * 0.32;
      final shadowWidth = threadWidth + 2.7;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + bowX,
          start.dy + span * slackRatio,
          end.dx + bowX,
          end.dy - span * slackRatio,
          end.dx,
          end.dy,
        );
      final shadowPaint = Paint()
        ..color = palette.threadDark.withValues(
          alpha: 0.14 + centerInfluence * 0.06,
        )
        ..strokeWidth = shadowWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final threadPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            palette.threadLight.withValues(alpha: 0.96),
            palette.threadDark.withValues(alpha: 0.96),
          ],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = threadWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final highlightPaint = Paint()
        ..color = palette.threadLight.withValues(
          alpha: 0.26 + centerInfluence * 0.12,
        )
        ..strokeWidth = threadWidth * 0.36
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, threadPaint);
      canvas.drawPath(path, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PrayerBeadsThreadPainter oldDelegate) {
    return oldDelegate.layouts != layouts ||
        oldDelegate.palette != palette ||
        oldDelegate.strandOffset != strandOffset ||
        oldDelegate.strandVelocity != strandVelocity ||
        oldDelegate.beadSpacing != beadSpacing;
  }
}
