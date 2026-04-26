import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/toolbox_audio_service.dart';
import '../../services/toolbox_singing_bowls_prefs_service.dart';
import '../motion/app_motion.dart';
import 'toolbox/toolbox_ui_components.dart';

part 'toolbox_singing_bowls_tool_specs.dart';
part 'toolbox_singing_bowls_tool_painters.dart';
part 'toolbox_singing_bowls_tool_stage.dart';
part 'toolbox_singing_bowls_tool_sheet.dart';
part 'toolbox_singing_bowls_tool_sheet_controls.dart';
part 'toolbox_singing_bowls_tool_layout.dart';
part 'toolbox_singing_bowls_tool_wide.dart';
part 'toolbox_singing_bowls_tool_wide_tiles.dart';

// [风险] 本次（PLAN_045）仅进行 UI-only 精修与展示层文件拆分：
// - 所有 `ToolboxSingingBowlsPrefsService` 调用、音频播放器构建、事件触发语义保持不变；
// - `_frequencyId`/`_voiceId`/`_autoPlayIntervalMs` 默认值与持久化结构保持不变；
// - `_bowlFrequencySpecs` 中的 id/note/frequency/文案保持不变，仅改 accent/glow/gradient；
// - `_bowlVoiceSpecs` 的 id 与 baseVolume 保持不变。
// 任何触碰以上不变项的改动都应另起计划，避免"样式重构顺手改逻辑"。

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

class SingingBowlsPracticeCard extends StatefulWidget {
  const SingingBowlsPracticeCard({super.key});

  @override
  State<SingingBowlsPracticeCard> createState() =>
      _SingingBowlsPracticeCardState();
}

class _SingingBowlsPracticeCardState extends State<SingingBowlsPracticeCard>
    with TickerProviderStateMixin {
  static const Duration _strikeMotionDuration = Duration(milliseconds: 800);
  static const Duration _ambientMotionDuration = Duration(seconds: 8);
  static const int minAutoPlayMs = 2000;
  static const int maxAutoPlayMs = 30000;
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
  bool _pressing = false;
  int _playerBuildNonce = 0;
  List<_SpectrumBurst> _bursts = const <_SpectrumBurst>[];

  bool get isZh => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('zh');

  _SingingBowlFrequencySpec get frequencySpec =>
      _bowlFrequencyById[_frequencyId] ?? _bowlFrequencySpecs[3];

  _SingingBowlVoiceSpec get voiceSpec =>
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
      duration: _ambientMotionDuration,
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
          frequency: frequencySpec.frequency,
          style: voiceSpec.id,
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
      unawaited(strikeBowl(fromAutoPlay: true));
    }
    _autoPlayTimer = Timer.periodic(
      Duration(milliseconds: _autoPlayIntervalMs),
      (_) => unawaited(strikeBowl(fromAutoPlay: true)),
    );
  }

  // ============ 对外（extension）调用入口：事件方法 ============

  void setFrequency(String id) {
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

  void setVoice(String id) {
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

  void setAutoPlayInterval(int value) {
    final next = value.clamp(minAutoPlayMs, maxAutoPlayMs).toInt();
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

  void toggleAutoPlay() {
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

  void toggleSound() {
    final next = !_soundEnabled;
    setState(() {
      _soundEnabled = next;
    });
    if (!next) {
      unawaited(_stopVoices());
    }
    _schedulePersist();
  }

  void toggleHaptics(bool value) {
    setState(() {
      _hapticsEnabled = value;
    });
    _schedulePersist();
  }

  void stopResonance() {
    setState(() {
      _autoPlayEnabled = false;
    });
    _autoPlayTimer?.cancel();
    unawaited(_stopVoices());
  }

  void setPressing(bool value) {
    if (_pressing == value) {
      return;
    }
    setState(() {
      _pressing = value;
    });
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

  void removeBurst(int id) {
    if (!mounted) {
      return;
    }
    setState(() {
      _bursts = _bursts
          .where((burst) => burst.id != id)
          .toList(growable: false);
    });
  }

  Future<void> strikeBowl({bool fromAutoPlay = false}) async {
    _addBurst();
    _strikeController.forward(from: 0);
    if (!fromAutoPlay && _hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (!_soundEnabled) {
      return;
    }
    try {
      await _player?.play(baseVolume: voiceSpec.baseVolume);
    } catch (_) {}
  }

  String t(String zh, String en) => isZh ? zh : en;

  String formatFrequency(double value) {
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
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                frequencySpec.gradient[0],
                frequencySpec.gradient[1],
                frequencySpec.gradient[2],
              ],
            ),
          ),
          child: CustomPaint(
            painter: _SingingBowlBackdropPainter(
              accent: frequencySpec.accent,
              glow: frequencySpec.glow,
              ambientValue: _ambientController,
              strikeValue: _strikeController,
            ),
            child: isPhone
                ? buildMobileLayout(context, constraints)
                : buildWideLayout(context),
          ),
        );
      },
    );
  }
}
