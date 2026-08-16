import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_audio_service.dart';
import '../../services/toolbox_free_chimes_controller.dart';
import '../../services/toolbox_free_chimes_prefs_service.dart';
import '../../services/toolbox_free_chimes_wind_mic_service.dart';
import '../../state/app_state_provider.dart';
import '../motion/app_motion.dart';
import '../theme/toolbox_colors.dart';
import '../widgets/section_header.dart';
import 'toolbox/toolbox_ui_components.dart';
import 'toolbox/toolbox_ui_tokens.dart';
import 'toolbox_tool_shell.dart';

class ToolboxFreeChimesToolPage extends ConsumerStatefulWidget {
  const ToolboxFreeChimesToolPage({super.key});

  @override
  ConsumerState<ToolboxFreeChimesToolPage> createState() =>
      _ToolboxFreeChimesToolPageState();
}

class _ToolboxFreeChimesToolPageState
    extends ConsumerState<ToolboxFreeChimesToolPage> {
  static const Color _accent = ToolboxColors.soundAccent;
  static const int _maxCachedEffectPlayers = 12;
  static const int _maxConcurrentPlaybackSlots = 3;

  final ToolboxFreeChimeController _controller = ToolboxFreeChimeController();
  final ToolboxFreeChimePlaybackLimiter _playbackLimiter =
      ToolboxFreeChimePlaybackLimiter(maxSlots: _maxConcurrentPlaybackSlots);
  final ToolboxFreeChimeWindMicService _windMicService =
      ToolboxFreeChimeWindMicService();
  final Map<ToolboxFreeChimeLayer, double> _layerAmounts =
      <ToolboxFreeChimeLayer, double>{
        for (final mix in ToolboxFreeChimeController.defaultMixes)
          mix.layer: mix.amount,
      };
  final Map<String, ToolboxNotePlayer> _players = <String, ToolboxNotePlayer>{};
  Map<ToolboxFreeChimeLayer, double>? _customPresetAmounts;

  StreamSubscription<UserAccelerometerEvent>? _motionSub;
  StreamSubscription<ToolboxFreeChimeWindMicSample>? _windMicSub;
  ToolboxFreeChimeIntensityBand _band = ToolboxFreeChimeIntensityBand.idle;
  ToolboxFreeChimePlayMode _mode = ToolboxFreeChimePlayMode.free;
  DateTime? _lastVisualAt;
  DateTime? _lastNaturalWindVisualAt;
  DateTime? _lastNaturalWindTriggerAt;
  ToolboxFreeChimeWindMicSample? _lastNaturalWindSample;
  String _presetId = 'balanced';
  double _intensity = 0;
  double _magnitude = 0;
  double _naturalWindLevel = 0;
  double _naturalWindNoiseFloor = 0;
  double _naturalWindConfidence = 0;
  double _naturalWindMix = 0.48;
  double _naturalWindBreezeBoost = 0.62;
  double _sensitivity = 1.0;
  double _masterVolume = 0.72;
  double _forceVolumeResponse = 0.72;
  double? _tempoBpm;
  int _lastHitCount = 0;
  int _pulse = 0;
  bool _listening = false;
  bool _sensorsAvailable = true;
  bool _naturalWindEnabled = false;
  bool _naturalWindAvailable = true;
  bool _naturalWindStarting = false;
  bool _disposed = false;
  bool _prefsLoaded = false;

  List<ToolboxFreeChimeLayerMix> get _mixes {
    return <ToolboxFreeChimeLayerMix>[
      for (final entry in _layerAmounts.entries)
        ToolboxFreeChimeLayerMix(layer: entry.key, amount: entry.value),
    ];
  }

  int get _activeLayerCount {
    return _layerAmounts.values.where((value) => value > 0.02).length;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadPrefs());
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_motionSub?.cancel());
    unawaited(_windMicSub?.cancel());
    unawaited(_windMicService.dispose());
    _playbackLimiter.reset();
    _disposePlayers();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await ToolboxFreeChimesPrefsService.load();
    if (!mounted) return;
    setState(() {
      _prefsLoaded = true;
      if (prefs.hasCustomPreset) {
        _customPresetAmounts = Map<ToolboxFreeChimeLayer, double>.from(
          prefs.customLayerAmounts,
        );
      }
      _naturalWindEnabled = prefs.naturalWindEnabled;
      _naturalWindMix = prefs.naturalWindMix;
      _naturalWindBreezeBoost = prefs.naturalWindBreezeBoost;
    });
  }

  AppI18n _i18n(BuildContext context) {
    try {
      return AppI18n(ref.watch(appStateProvider).uiLanguage);
    } on StateError {
      return AppI18n(Localizations.localeOf(context).languageCode);
    }
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _stopListening();
      return;
    }
    await _startListening();
  }

  Future<void> _startListening() async {
    _controller.resetTiming();
    final motionStarted = await _startMotionListening();
    final windStarted = _naturalWindEnabled
        ? await _startNaturalWindListening()
        : false;
    if (!mounted) return;
    setState(() {
      _listening = motionStarted || windStarted;
    });
    if (motionStarted || windStarted) {
      unawaited(_warmActivePlayers());
    }
  }

  Future<bool> _startMotionListening() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      if (mounted) {
        setState(() {
          _sensorsAvailable = false;
        });
      }
      return false;
    }
    await _motionSub?.cancel();
    try {
      _motionSub =
          userAccelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 55),
          ).listen(
            _handleMotion,
            onError: (_) {
              if (!mounted) return;
              setState(() {
                _sensorsAvailable = false;
                if (!_windMicService.isRunning) {
                  _listening = false;
                }
              });
              unawaited(_motionSub?.cancel());
              _motionSub = null;
            },
            cancelOnError: true,
          );
      if (mounted) {
        setState(() => _sensorsAvailable = true);
      }
      return true;
    } on MissingPluginException {
      if (mounted) {
        setState(() => _sensorsAvailable = false);
      }
      return false;
    }
  }

  Future<bool> _startNaturalWindListening() async {
    if (_naturalWindStarting || _windMicService.isRunning) {
      return _windMicService.isRunning;
    }
    if (mounted) {
      setState(() {
        _naturalWindStarting = true;
        _naturalWindAvailable = true;
      });
    }
    await _windMicSub?.cancel();
    _windMicSub = _windMicService.samples.listen(_handleNaturalWindSample);
    final started = await _windMicService.start();
    if (!mounted) return started;
    setState(() {
      _naturalWindStarting = false;
      _naturalWindAvailable = started;
      if (!started) {
        _naturalWindLevel = 0;
        _naturalWindNoiseFloor = 0;
        _naturalWindConfidence = 0;
      }
    });
    if (!started) {
      await _windMicSub?.cancel();
      _windMicSub = null;
    }
    return started;
  }

  Future<void> _stopListening() async {
    await _motionSub?.cancel();
    _motionSub = null;
    await _stopNaturalWindListening(resetUi: true);
    _controller.resetTiming();
    _playbackLimiter.reset();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _band = ToolboxFreeChimeIntensityBand.idle;
      _intensity = 0;
      _magnitude = 0;
      _naturalWindLevel = 0;
      _naturalWindNoiseFloor = 0;
      _naturalWindConfidence = 0;
      _tempoBpm = null;
    });
  }

  Future<void> _stopNaturalWindListening({required bool resetUi}) async {
    await _windMicSub?.cancel();
    _windMicSub = null;
    await _windMicService.stop();
    _lastNaturalWindSample = null;
    _lastNaturalWindTriggerAt = null;
    if (resetUi && mounted) {
      setState(() {
        _naturalWindStarting = false;
        _naturalWindLevel = 0;
        _naturalWindNoiseFloor = 0;
        _naturalWindConfidence = 0;
      });
    }
  }

  void _handleMotion(UserAccelerometerEvent event) {
    if (!_listening || _disposed) {
      return;
    }
    final timestamp = DateTime.now();
    final sample = ToolboxFreeChimeMotionSample(
      timestamp: timestamp,
      x: event.x,
      y: event.y,
      z: event.z,
    );
    final visualIntensity = _controller.intensityForMagnitude(
      sample.magnitude,
      sensitivity: _sensitivity,
    );
    final visualBand = _controller.bandForIntensity(visualIntensity);
    final trigger = _controller.evaluate(
      sample,
      mixes: _mixes,
      sensitivity: _sensitivity,
      mode: _mode,
    );

    final shouldRefreshVisual =
        _lastVisualAt == null ||
        timestamp.difference(_lastVisualAt!) >
            const Duration(milliseconds: 90) ||
        trigger != null;
    if (shouldRefreshVisual && mounted) {
      _lastVisualAt = timestamp;
      setState(() {
        _magnitude = sample.magnitude;
        _intensity = trigger?.intensity ?? visualIntensity;
        _band = trigger?.band ?? visualBand;
        if (trigger != null) {
          _lastHitCount = trigger.hits.length;
          _tempoBpm = trigger.tempoBpm;
          _pulse += 1;
        }
      });
    }

    if (trigger != null) {
      _playTrigger(trigger);
    }
  }

  void _handleNaturalWindSample(ToolboxFreeChimeWindMicSample sample) {
    if (!_listening || !_naturalWindEnabled || _disposed) {
      return;
    }
    _lastNaturalWindSample = sample;
    final shouldRefreshVisual =
        _lastNaturalWindVisualAt == null ||
        sample.timestamp.difference(_lastNaturalWindVisualAt!) >
            const Duration(milliseconds: 140);
    if (shouldRefreshVisual && mounted) {
      _lastNaturalWindVisualAt = sample.timestamp;
      setState(() {
        _naturalWindLevel = sample.level;
        _naturalWindNoiseFloor = sample.noiseFloor;
        _naturalWindConfidence = sample.confidence;
        if (_motionSub == null && sample.isWindLike) {
          _intensity = math.max(_intensity * 0.82, sample.level * 0.72);
          _band = _controller.bandForIntensity(_intensity);
        }
      });
    }

    final trigger = _naturalWindTriggerFor(sample);
    if (trigger != null) {
      _playTrigger(trigger);
    }
  }

  ToolboxFreeChimeTrigger? _naturalWindTriggerFor(
    ToolboxFreeChimeWindMicSample sample,
  ) {
    if (!sample.isWindLike || sample.level <= 0.024) {
      return null;
    }
    final previous = _lastNaturalWindTriggerAt;
    final cooldown = Duration(
      milliseconds: (880 - sample.level * 420 - sample.gust * 120)
          .round()
          .clamp(360, 920),
    );
    if (previous != null && sample.timestamp.difference(previous) < cooldown) {
      return null;
    }
    final mixes = _naturalWindMixes();
    if (mixes.isEmpty) {
      return null;
    }
    final breezeGain = 0.82 + _naturalWindBreezeBoost * 0.48;
    final intensity =
        (sample.level * breezeGain + sample.gust * 0.1 + sample.texture * 0.08)
            .clamp(0.08, 0.72)
            .toDouble();
    _lastNaturalWindTriggerAt = sample.timestamp;
    return _controller.preview(
      timestamp: sample.timestamp,
      intensity: intensity,
      mixes: mixes,
      mode: ToolboxFreeChimePlayMode.free,
    );
  }

  List<ToolboxFreeChimeLayerMix> _naturalWindMixes() {
    final windAmount = (_layerAmounts[ToolboxFreeChimeLayer.windChime] ?? 0)
        .clamp(0.0, 1.0);
    final leavesAmount = (_layerAmounts[ToolboxFreeChimeLayer.leaves] ?? 0)
        .clamp(0.0, 1.0);
    final waterAmount = (_layerAmounts[ToolboxFreeChimeLayer.water] ?? 0).clamp(
      0.0,
      1.0,
    );
    final rainAmount = (_layerAmounts[ToolboxFreeChimeLayer.rain] ?? 0).clamp(
      0.0,
      1.0,
    );
    final shakerAmount = (_layerAmounts[ToolboxFreeChimeLayer.shaker] ?? 0)
        .clamp(0.0, 1.0);
    final mixes = <ToolboxFreeChimeLayerMix>[
      if (windAmount > 0.02)
        ToolboxFreeChimeLayerMix(
          layer: ToolboxFreeChimeLayer.windChime,
          amount: (windAmount * (0.78 + _naturalWindMix * 0.22))
              .clamp(0.0, 1.0)
              .toDouble(),
        ),
      if (leavesAmount > 0.02)
        ToolboxFreeChimeLayerMix(
          layer: ToolboxFreeChimeLayer.leaves,
          amount: (leavesAmount * _naturalWindMix * 0.72)
              .clamp(0.0, 1.0)
              .toDouble(),
        ),
      if (waterAmount > 0.02)
        ToolboxFreeChimeLayerMix(
          layer: ToolboxFreeChimeLayer.water,
          amount: (waterAmount * _naturalWindMix * 0.44)
              .clamp(0.0, 1.0)
              .toDouble(),
        ),
      if (rainAmount > 0.02)
        ToolboxFreeChimeLayerMix(
          layer: ToolboxFreeChimeLayer.rain,
          amount: (rainAmount * _naturalWindMix * 0.38)
              .clamp(0.0, 1.0)
              .toDouble(),
        ),
      if (shakerAmount > 0.02)
        ToolboxFreeChimeLayerMix(
          layer: ToolboxFreeChimeLayer.shaker,
          amount: (shakerAmount * _naturalWindMix * 0.34)
              .clamp(0.0, 1.0)
              .toDouble(),
        ),
    ];
    return mixes.where((mix) => mix.amount > 0.02).toList(growable: false);
  }

  void _playTrigger(ToolboxFreeChimeTrigger trigger) {
    if (_disposed || trigger.hits.isEmpty) return;
    final prioritizedHits = trigger.hits.toList(growable: false)
      ..sort((a, b) => b.volume.compareTo(a.volume));
    final claimedSlots = _playbackLimiter.claim(prioritizedHits.length);
    if (claimedSlots <= 0) {
      return;
    }
    final playableHits = prioritizedHits
        .take(claimedSlots)
        .toList(growable: false);
    final feedback = switch (trigger.band) {
      ToolboxFreeChimeIntensityBand.strong => HapticFeedback.mediumImpact(),
      ToolboxFreeChimeIntensityBand.lively => HapticFeedback.lightImpact(),
      _ => HapticFeedback.selectionClick(),
    };
    unawaited(feedback);
    Timer(_slotHoldForHits(playableHits), () {
      _playbackLimiter.release(claimedSlots);
    });
    unawaited(
      Future.wait<void>(<Future<void>>[
        for (final hit in playableHits)
          _playerForHit(hit).play(
            volume: _volumeForHit(hit, trigger),
            playbackRate: _playbackRateForHit(hit),
          ),
      ], eagerError: false).catchError((_) => <void>[]),
    );
  }

  Future<void> _warmActivePlayers() async {
    final activeLayers = _layerAmounts.entries
        .where((entry) => entry.value > 0.02)
        .map((entry) => entry.key)
        .toList(growable: false);
    if (activeLayers.isEmpty) return;
    await Future.wait<void>(<Future<void>>[
      for (final layer in activeLayers.take(4)) _playerForLayer(layer).warmUp(),
    ], eagerError: false);
  }

  double _volumeForHit(
    ToolboxFreeChimeHit hit,
    ToolboxFreeChimeTrigger trigger,
  ) {
    final response = _forceVolumeResponse.clamp(0.0, 1.0).toDouble();
    final dynamicScale =
        1 -
        response * 0.36 +
        trigger.intensity.clamp(0.0, 1.0) * response * 0.52;
    final windCorrection = _naturalWindCorrectionFor(hit);
    return (hit.volume * _masterVolume * dynamicScale * windCorrection).clamp(
      0.0,
      1.0,
    );
  }

  double _playbackRateForHit(ToolboxFreeChimeHit hit) {
    final sample = _recentNaturalWindSample();
    if (sample == null || hit.layer != ToolboxFreeChimeLayer.windChime) {
      return hit.playbackRate;
    }
    final drift =
        (sample.texture * 0.05 + sample.gust * 0.025 + sample.level * 0.018) *
        _naturalWindMix;
    return (hit.playbackRate + drift).clamp(0.92, 1.08).toDouble();
  }

  double _naturalWindCorrectionFor(ToolboxFreeChimeHit hit) {
    final sample = _recentNaturalWindSample();
    if (sample == null || hit.layer != ToolboxFreeChimeLayer.windChime) {
      return 1.0;
    }
    return (1.0 + sample.level * _naturalWindMix * 0.18).clamp(1.0, 1.16);
  }

  ToolboxFreeChimeWindMicSample? _recentNaturalWindSample() {
    if (!_naturalWindEnabled) {
      return null;
    }
    final sample = _lastNaturalWindSample;
    if (sample == null || !sample.isWindLike) {
      return null;
    }
    if (DateTime.now().difference(sample.timestamp) >
        const Duration(milliseconds: 1600)) {
      return null;
    }
    return sample;
  }

  Duration _slotHoldForHits(List<ToolboxFreeChimeHit> hits) {
    var milliseconds = 420;
    for (final hit in hits) {
      milliseconds = math.max(milliseconds, _slotHoldForLayer(hit.layer));
    }
    return Duration(milliseconds: milliseconds);
  }

  int _slotHoldForLayer(ToolboxFreeChimeLayer layer) {
    return switch (layer) {
      ToolboxFreeChimeLayer.windChime => 420,
      ToolboxFreeChimeLayer.gongDrum => 1100,
      ToolboxFreeChimeLayer.water => 720,
      ToolboxFreeChimeLayer.rain => 680,
      ToolboxFreeChimeLayer.marble => 620,
      ToolboxFreeChimeLayer.bubbles => 560,
      ToolboxFreeChimeLayer.leaves => 520,
      ToolboxFreeChimeLayer.shaker => 460,
      ToolboxFreeChimeLayer.impact => 430,
      ToolboxFreeChimeLayer.kuaiban => 360,
    };
  }

  ToolboxNotePlayer _playerForLayer(ToolboxFreeChimeLayer layer) {
    const variantBucket = 0;
    final key = layer.id;
    final existing = _players[key];
    if (existing != null) {
      return existing;
    }
    while (_players.length >= _maxCachedEffectPlayers) {
      final firstKey = _players.keys.first;
      final removed = _players.remove(firstKey);
      if (removed != null) {
        unawaited(removed.dispose());
      }
    }
    final player = ToolboxEffectPlayer(
      ToolboxAudioBank.freeChimeLayer(
        layer.id,
        intensity: 0.86,
        variant: variantBucket,
      ),
      maxPlayers: _maxVoicesForLayer(layer),
      allowOverflow: false,
    );
    _players[key] = player;
    return player;
  }

  int _maxVoicesForLayer(ToolboxFreeChimeLayer layer) {
    return switch (layer) {
      ToolboxFreeChimeLayer.windChime => 4,
      _ => 1,
    };
  }

  ToolboxNotePlayer _playerForHit(ToolboxFreeChimeHit hit) {
    return _playerForLayer(hit.layer);
  }

  void _disposePlayers() {
    for (final player in _players.values) {
      unawaited(player.stop().whenComplete(player.dispose));
    }
    _players.clear();
  }

  void _preview(double intensity) {
    final trigger = _controller.preview(
      timestamp: DateTime.now(),
      intensity: intensity,
      mixes: _mixes,
      mode: _mode,
    );
    setState(() {
      _intensity = trigger.intensity;
      _magnitude = trigger.magnitude;
      _band = trigger.band;
      _tempoBpm = trigger.tempoBpm;
      _lastHitCount = trigger.hits.length;
      _pulse += 1;
    });
    _playTrigger(trigger);
  }

  void _applyPreset(String id) {
    final values = switch (id) {
      'calm' => <ToolboxFreeChimeLayer, double>{
        ToolboxFreeChimeLayer.shaker: 0.46,
        ToolboxFreeChimeLayer.water: 0.72,
        ToolboxFreeChimeLayer.windChime: 0.86,
        ToolboxFreeChimeLayer.leaves: 0.52,
        ToolboxFreeChimeLayer.bubbles: 0.36,
        ToolboxFreeChimeLayer.rain: 0.48,
        ToolboxFreeChimeLayer.impact: 0.08,
        ToolboxFreeChimeLayer.kuaiban: 0.04,
        ToolboxFreeChimeLayer.gongDrum: 0.0,
        ToolboxFreeChimeLayer.marble: 0.18,
      },
      'rhythm' => <ToolboxFreeChimeLayer, double>{
        ToolboxFreeChimeLayer.shaker: 0.66,
        ToolboxFreeChimeLayer.water: 0.28,
        ToolboxFreeChimeLayer.windChime: 0.52,
        ToolboxFreeChimeLayer.leaves: 0.22,
        ToolboxFreeChimeLayer.bubbles: 0.26,
        ToolboxFreeChimeLayer.rain: 0.24,
        ToolboxFreeChimeLayer.impact: 0.72,
        ToolboxFreeChimeLayer.kuaiban: 0.86,
        ToolboxFreeChimeLayer.gongDrum: 0.58,
        ToolboxFreeChimeLayer.marble: 0.64,
      },
      'custom' => _customPresetAmounts,
      _ => <ToolboxFreeChimeLayer, double>{
        for (final mix in ToolboxFreeChimeController.defaultMixes)
          mix.layer: mix.amount,
      },
    };
    if (values == null) {
      return;
    }
    setState(() {
      _presetId = id;
      _layerAmounts
        ..clear()
        ..addAll(values);
    });
    _playbackLimiter.reset();
  }

  void _saveCustomPreset() {
    final customAmounts = Map<ToolboxFreeChimeLayer, double>.from(
      _layerAmounts,
    );
    setState(() {
      _presetId = 'custom';
      _customPresetAmounts = customAmounts;
    });
    unawaited(_savePrefs(customLayerAmounts: customAmounts));
  }

  Future<void> _savePrefs({
    Map<ToolboxFreeChimeLayer, double>? customLayerAmounts,
  }) {
    final customAmounts =
        customLayerAmounts ??
        _customPresetAmounts ??
        const <ToolboxFreeChimeLayer, double>{};
    return ToolboxFreeChimesPrefsService.save(
      FreeChimesPrefsState(
        customLayerAmounts: customAmounts,
        naturalWindEnabled: _naturalWindEnabled,
        naturalWindMix: _naturalWindMix,
        naturalWindBreezeBoost: _naturalWindBreezeBoost,
      ),
    );
  }

  Future<void> _toggleNaturalWind(bool value) async {
    setState(() {
      _naturalWindEnabled = value;
      _naturalWindAvailable = true;
    });
    unawaited(_savePrefs(customLayerAmounts: _customPresetAmounts));
    if (!_listening) {
      return;
    }
    if (value) {
      final started = await _startNaturalWindListening();
      if (!started && mounted) {
        setState(() => _naturalWindAvailable = false);
      }
      return;
    }
    await _stopNaturalWindListening(resetUi: true);
  }

  void _setNaturalWindMix(double value) {
    setState(() => _naturalWindMix = value.clamp(0.0, 1.0).toDouble());
    unawaited(_savePrefs(customLayerAmounts: _customPresetAmounts));
  }

  void _setNaturalWindBreezeBoost(double value) {
    setState(() {
      _naturalWindBreezeBoost = value.clamp(0.0, 1.0).toDouble();
    });
    unawaited(_savePrefs(customLayerAmounts: _customPresetAmounts));
  }

  void _turnAllLayersOff() {
    setState(() {
      _presetId = 'custom';
      for (final layer in ToolboxFreeChimeLayer.values) {
        _layerAmounts[layer] = 0;
      }
      _band = ToolboxFreeChimeIntensityBand.idle;
      _intensity = 0;
      _magnitude = 0;
      _tempoBpm = null;
      _lastHitCount = 0;
    });
    _controller.resetTiming();
    _playbackLimiter.reset();
    _disposePlayers();
  }

  void _setLayerAmount(ToolboxFreeChimeLayer layer, double amount) {
    setState(() {
      _presetId = 'custom';
      _layerAmounts[layer] = amount.clamp(0.0, 1.0).toDouble();
    });
  }

  String _bandLabel(AppI18n i18n, ToolboxFreeChimeIntensityBand band) {
    return switch (band) {
      ToolboxFreeChimeIntensityBand.idle => i18n.t(
        'toolbox.free_chimes.band.idle',
      ),
      ToolboxFreeChimeIntensityBand.gentle => i18n.t(
        'toolbox.free_chimes.band.gentle',
      ),
      ToolboxFreeChimeIntensityBand.flowing => i18n.t(
        'toolbox.free_chimes.band.flowing',
      ),
      ToolboxFreeChimeIntensityBand.lively => i18n.t(
        'toolbox.free_chimes.band.lively',
      ),
      ToolboxFreeChimeIntensityBand.strong => i18n.t(
        'toolbox.free_chimes.band.strong',
      ),
    };
  }

  String _layerLabel(AppI18n i18n, ToolboxFreeChimeLayer layer) {
    return i18n.t('toolbox.free_chimes.layer.${layer.id}');
  }

  String _layerSubtitle(AppI18n i18n, ToolboxFreeChimeLayer layer) {
    return i18n.t('toolbox.free_chimes.layer.${layer.id}.sub');
  }

  IconData _layerIcon(ToolboxFreeChimeLayer layer) {
    return switch (layer) {
      ToolboxFreeChimeLayer.shaker => Icons.grain_rounded,
      ToolboxFreeChimeLayer.water => Icons.water_drop_rounded,
      ToolboxFreeChimeLayer.windChime => Icons.air_rounded,
      ToolboxFreeChimeLayer.leaves => Icons.eco_rounded,
      ToolboxFreeChimeLayer.bubbles => Icons.bubble_chart_rounded,
      ToolboxFreeChimeLayer.rain => Icons.umbrella_rounded,
      ToolboxFreeChimeLayer.impact => Icons.adjust_rounded,
      ToolboxFreeChimeLayer.kuaiban => Icons.view_week_rounded,
      ToolboxFreeChimeLayer.gongDrum => Icons.album_rounded,
      ToolboxFreeChimeLayer.marble => Icons.toys_rounded,
    };
  }

  Color _layerColor(ToolboxFreeChimeLayer layer) {
    return switch (layer) {
      ToolboxFreeChimeLayer.shaker => const Color(0xFFD69E2E),
      ToolboxFreeChimeLayer.water => const Color(0xFF2F80ED),
      ToolboxFreeChimeLayer.windChime => const Color(0xFF26A69A),
      ToolboxFreeChimeLayer.leaves => const Color(0xFF5E9F47),
      ToolboxFreeChimeLayer.bubbles => const Color(0xFF6C8AE4),
      ToolboxFreeChimeLayer.rain => const Color(0xFF64748B),
      ToolboxFreeChimeLayer.impact => const Color(0xFFB45309),
      ToolboxFreeChimeLayer.kuaiban => const Color(0xFF92400E),
      ToolboxFreeChimeLayer.gongDrum => const Color(0xFFB91C1C),
      ToolboxFreeChimeLayer.marble => const Color(0xFF7C3AED),
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _i18n(context);
    return ToolboxToolPage(
      title: i18n.t('toolbox.free_chimes.title'),
      subtitle: i18n.t('toolbox.free_chimes.subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStage(context, i18n),
          const SizedBox(height: ToolboxUiTokens.sectionSpacing),
          _buildModePanel(context, i18n),
          const SizedBox(height: ToolboxUiTokens.sectionSpacing),
          _buildNaturalWindPanel(context, i18n),
          const SizedBox(height: ToolboxUiTokens.sectionSpacing),
          _buildPresetPanel(context, i18n),
          const SizedBox(height: ToolboxUiTokens.sectionSpacing),
          _buildLayerPanel(context, i18n),
          const SizedBox(height: ToolboxUiTokens.sectionSpacing),
          _buildTuningPanel(context, i18n),
          if (!_sensorsAvailable) ...<Widget>[
            const SizedBox(height: ToolboxUiTokens.sectionSpacing),
            _buildSensorFallback(context, i18n),
          ],
        ],
      ),
    );
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final statusText = !_sensorsAvailable
        ? i18n.t('toolbox.free_chimes.state.sensor_unavailable')
        : _listening
        ? i18n.t('toolbox.free_chimes.state.listening')
        : i18n.t('toolbox.free_chimes.state.paused');
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          const Color(0xFFE0F2FE).withValues(alpha: 0.9),
          const Color(0xFFFFF7ED).withValues(alpha: 0.88),
          theme.colorScheme.surface,
        ],
      ),
      borderColor: _accent.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.phonelink_ring_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _bandLabel(i18n, _band),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ToolboxInfoPill(
                text: '${(_intensity * 100).round()}%',
                accent: _accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: AnimatedScale(
              scale: 1 + (_pulse.isEven ? 0.018 : 0.034) * _intensity,
              duration: AppDurations.quick,
              curve: AppEasing.snappy,
              child: CustomPaint(
                painter: _FreeChimesStagePainter(
                  intensity: _intensity,
                  pulse: _pulse,
                  accent: _accent,
                  theme: theme,
                  activeLayerColors: _activeLayerColors(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxMetricCard(
                label: i18n.t('toolbox.free_chimes.metric.intensity'),
                value: '${(_intensity * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: i18n.t('toolbox.free_chimes.metric.magnitude'),
                value: _magnitude.toStringAsFixed(1),
              ),
              ToolboxMetricCard(
                label: i18n.t('toolbox.free_chimes.metric.layers'),
                value: '$_activeLayerCount',
              ),
              ToolboxMetricCard(
                label: i18n.t('toolbox.free_chimes.metric.hits'),
                value: '$_lastHitCount',
              ),
              if (_mode == ToolboxFreeChimePlayMode.allegro)
                ToolboxMetricCard(
                  label: i18n.t('toolbox.free_chimes.metric.tempo'),
                  value: _tempoBpm == null ? '--' : '${_tempoBpm!.round()}',
                ),
              if (_naturalWindEnabled)
                ToolboxMetricCard(
                  label: i18n.t('toolbox.free_chimes.metric.wind'),
                  value: '${(_naturalWindLevel * 100).round()}%',
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _toggleListening,
                icon: Icon(
                  _listening ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  _listening
                      ? i18n.t('toolbox.free_chimes.action.stop')
                      : i18n.t('toolbox.free_chimes.action.start'),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _preview(0.28),
                icon: const Icon(Icons.spa_rounded),
                label: Text(
                  i18n.t('toolbox.free_chimes.action.preview_gentle'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _preview(0.86),
                icon: const Icon(Icons.bolt_rounded),
                label: Text(
                  i18n.t('toolbox.free_chimes.action.preview_strong'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _activeLayerColors() {
    return <Color>[
      for (final entry in _layerAmounts.entries)
        if (entry.value > 0.02) _layerColor(entry.key),
    ];
  }

  Widget _buildModePanel(BuildContext context, AppI18n i18n) {
    return ToolboxSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: i18n.t('toolbox.free_chimes.mode.title'),
            subtitle: i18n.t('toolbox.free_chimes.mode.subtitle'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _PresetChip(
                label: i18n.t('toolbox.free_chimes.mode.free'),
                icon: Icons.all_inclusive_rounded,
                selected: _mode == ToolboxFreeChimePlayMode.free,
                onSelected: () => _setMode(ToolboxFreeChimePlayMode.free),
              ),
              _PresetChip(
                label: i18n.t('toolbox.free_chimes.mode.allegro'),
                icon: Icons.flash_on_rounded,
                selected: _mode == ToolboxFreeChimePlayMode.allegro,
                onSelected: () => _setMode(ToolboxFreeChimePlayMode.allegro),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNaturalWindPanel(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final statusText = !_naturalWindEnabled
        ? i18n.t('toolbox.free_chimes.wind.status.off')
        : _naturalWindStarting
        ? i18n.t('toolbox.free_chimes.wind.status.starting')
        : !_naturalWindAvailable
        ? i18n.t('toolbox.free_chimes.wind.status.unavailable')
        : _windMicService.isRunning
        ? i18n.t('toolbox.free_chimes.wind.status.listening')
        : i18n.t('toolbox.free_chimes.wind.status.ready');
    final helperText = _naturalWindEnabled
        ? i18n.t(
            'toolbox.free_chimes.wind.helper_active',
            params: <String, Object?>{
              'level': (_naturalWindLevel * 100).round(),
              'floor': (_naturalWindNoiseFloor * 100).round(),
              'confidence': (_naturalWindConfidence * 100).round(),
            },
          )
        : i18n.t('toolbox.free_chimes.wind.helper_idle');
    return ToolboxSurfaceCard(
      borderColor: _accent.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: i18n.t('toolbox.free_chimes.wind.title'),
            subtitle: i18n.t('toolbox.free_chimes.wind.subtitle'),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              Icons.air_rounded,
              color: _naturalWindEnabled
                  ? _accent
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(i18n.t('toolbox.free_chimes.wind.enable')),
            subtitle: Text(statusText),
            value: _naturalWindEnabled,
            onChanged: _toggleNaturalWind,
          ),
          const SizedBox(height: 8),
          Text(
            helperText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _buildSliderLabel(
            context,
            i18n.t(
              'toolbox.free_chimes.wind.mix',
              params: <String, Object?>{
                'value': (_naturalWindMix * 100).round(),
              },
            ),
          ),
          Slider(
            value: _naturalWindMix,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: _naturalWindEnabled ? _setNaturalWindMix : null,
          ),
          _buildSliderLabel(
            context,
            i18n.t(
              'toolbox.free_chimes.wind.breeze_boost',
              params: <String, Object?>{
                'value': (_naturalWindBreezeBoost * 100).round(),
              },
            ),
          ),
          Slider(
            value: _naturalWindBreezeBoost,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: _naturalWindEnabled ? _setNaturalWindBreezeBoost : null,
          ),
        ],
      ),
    );
  }

  void _setMode(ToolboxFreeChimePlayMode mode) {
    setState(() {
      _mode = mode;
      _tempoBpm = null;
    });
    _controller.resetTiming();
  }

  Widget _buildPresetPanel(BuildContext context, AppI18n i18n) {
    return ToolboxSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: i18n.t('toolbox.free_chimes.presets.title'),
            subtitle: i18n.t('toolbox.free_chimes.presets.subtitle'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _PresetChip(
                label: i18n.t('toolbox.free_chimes.preset.calm'),
                icon: Icons.self_improvement_rounded,
                selected: _presetId == 'calm',
                onSelected: () => _applyPreset('calm'),
              ),
              _PresetChip(
                label: i18n.t('toolbox.free_chimes.preset.balanced'),
                icon: Icons.tune_rounded,
                selected: _presetId == 'balanced',
                onSelected: () => _applyPreset('balanced'),
              ),
              _PresetChip(
                label: i18n.t('toolbox.free_chimes.preset.rhythm'),
                icon: Icons.graphic_eq_rounded,
                selected: _presetId == 'rhythm',
                onSelected: () => _applyPreset('rhythm'),
              ),
              if (_customPresetAmounts != null || _presetId == 'custom')
                _PresetChip(
                  label: i18n.t('toolbox.free_chimes.preset.custom'),
                  icon: Icons.edit_rounded,
                  selected: _presetId == 'custom',
                  onSelected: () => _applyPreset('custom'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _saveCustomPreset,
                icon: const Icon(Icons.bookmark_add_rounded),
                label: Text(i18n.t('toolbox.free_chimes.action.save_custom')),
              ),
              OutlinedButton.icon(
                onPressed: !_prefsLoaded || _customPresetAmounts == null
                    ? null
                    : () => _applyPreset('custom'),
                icon: const Icon(Icons.bookmarks_rounded),
                label: Text(i18n.t('toolbox.free_chimes.action.use_custom')),
              ),
              OutlinedButton.icon(
                onPressed: _turnAllLayersOff,
                icon: const Icon(Icons.volume_off_rounded),
                label: Text(i18n.t('toolbox.free_chimes.action.all_off')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLayerPanel(BuildContext context, AppI18n i18n) {
    return ToolboxSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: i18n.t('toolbox.free_chimes.layers.title'),
            subtitle: i18n.t('toolbox.free_chimes.layers.subtitle'),
          ),
          const SizedBox(height: 12),
          for (final layer in ToolboxFreeChimeLayer.values) ...<Widget>[
            _FreeChimeLayerRow(
              icon: _layerIcon(layer),
              color: _layerColor(layer),
              title: _layerLabel(i18n, layer),
              subtitle: _layerSubtitle(i18n, layer),
              amount: _layerAmounts[layer] ?? 0,
              onChanged: (value) => _setLayerAmount(layer, value),
            ),
            if (layer != ToolboxFreeChimeLayer.values.last)
              const Divider(height: 18),
          ],
        ],
      ),
    );
  }

  Widget _buildTuningPanel(BuildContext context, AppI18n i18n) {
    return ToolboxSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: i18n.t('toolbox.free_chimes.tuning.title'),
            subtitle: i18n.t('toolbox.free_chimes.tuning.subtitle'),
          ),
          const SizedBox(height: 12),
          _buildSliderLabel(
            context,
            i18n.t(
              'toolbox.free_chimes.tuning.sensitivity',
              params: <String, Object?>{'value': (_sensitivity * 100).round()},
            ),
          ),
          Slider(
            value: _sensitivity,
            min: 0.55,
            max: 1.65,
            divisions: 22,
            onChanged: (value) => setState(() => _sensitivity = value),
          ),
          _buildSliderLabel(
            context,
            i18n.t(
              'toolbox.free_chimes.tuning.volume',
              params: <String, Object?>{'value': (_masterVolume * 100).round()},
            ),
          ),
          Slider(
            value: _masterVolume,
            min: 0.2,
            max: 1.0,
            divisions: 16,
            onChanged: (value) => setState(() => _masterVolume = value),
          ),
          _buildSliderLabel(
            context,
            i18n.t(
              'toolbox.free_chimes.tuning.force_volume',
              params: <String, Object?>{
                'value': (_forceVolumeResponse * 100).round(),
              },
            ),
          ),
          Slider(
            value: _forceVolumeResponse,
            min: 0,
            max: 1,
            divisions: 20,
            onChanged: (value) => setState(() => _forceVolumeResponse = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  Widget _buildSensorFallback(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      borderColor: theme.colorScheme.error.withValues(alpha: 0.28),
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.sensors_off_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  i18n.t('toolbox.free_chimes.sensor_fallback.title'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  i18n.t('toolbox.free_chimes.sensor_fallback.body'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _FreeChimeLayerRow extends StatelessWidget {
  const _FreeChimeLayerRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final double amount;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = amount > 0.02;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: enabled ? 0.16 : 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: enabled ? color : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: (value) =>
                  onChanged(value ? math.max(amount, 0.55) : 0),
            ),
          ],
        ),
        Slider(
          value: amount,
          min: 0,
          max: 1,
          divisions: 20,
          label: '${(amount * 100).round()}%',
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FreeChimesStagePainter extends CustomPainter {
  const _FreeChimesStagePainter({
    required this.intensity,
    required this.pulse,
    required this.accent,
    required this.theme,
    required this.activeLayerColors,
  });

  final double intensity;
  final int pulse;
  final Color accent;
  final ThemeData theme;
  final List<Color> activeLayerColors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;
    final normalized = intensity.clamp(0.0, 1.0).toDouble();
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = accent.withValues(alpha: 0.24 + normalized * 0.28);
    for (var i = 0; i < 4; i += 1) {
      final r = radius * (0.58 + i * 0.18 + normalized * 0.06);
      canvas.drawCircle(center, r, ringPaint);
    }

    final cordPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.46);
    final barPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final colors = activeLayerColors.isEmpty
        ? <Color>[accent]
        : activeLayerColors.take(7).toList(growable: false);
    final top = center.dy - radius * 0.82;
    final sway = math.sin((pulse % 16) * 0.7) * normalized * 10;
    for (var i = 0; i < colors.length; i += 1) {
      final x =
          center.dx -
          (colors.length - 1) * 18 / 2 +
          i * 18 +
          math.sin(i + pulse * 0.2) * normalized * 6;
      final y1 = top + (i.isEven ? 0 : 10);
      final y2 = y1 + 48 + normalized * 18 - i % 3 * 5;
      canvas.drawLine(
        Offset(x + sway * 0.2, top - 18),
        Offset(x, y1),
        cordPaint,
      );
      barPaint.color = colors[i].withValues(alpha: 0.72);
      canvas.drawLine(Offset(x, y1), Offset(x + sway, y2), barPaint);
    }

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          accent.withValues(alpha: 0.28 + normalized * 0.28),
          Colors.white.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius * (0.78 + normalized * 0.1), corePaint);

    final beadPaint = Paint()..color = accent.withValues(alpha: 0.52);
    final beadCount = 5 + (normalized * 7).round();
    for (var i = 0; i < beadCount; i += 1) {
      final angle = math.pi * 2 * i / beadCount + pulse * 0.11;
      final orbit = radius * (0.84 + 0.16 * math.sin(i + normalized));
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * orbit,
          center.dy + math.sin(angle) * orbit,
        ),
        3.0 + normalized * 2.4,
        beadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FreeChimesStagePainter oldDelegate) {
    return intensity != oldDelegate.intensity ||
        pulse != oldDelegate.pulse ||
        accent != oldDelegate.accent ||
        theme.colorScheme != oldDelegate.theme.colorScheme ||
        !listEquals(activeLayerColors, oldDelegate.activeLayerColors);
  }
}
