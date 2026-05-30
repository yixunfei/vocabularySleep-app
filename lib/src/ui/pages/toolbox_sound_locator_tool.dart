import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_sound_locator_service.dart';
import '../../state/app_state_provider.dart';
import '../motion/app_motion.dart';
import '../theme/toolbox_colors.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import 'toolbox/toolbox_ui_components.dart';
import 'toolbox/toolbox_ui_tokens.dart';

const Color _soundLocatorAccent = ToolboxColors.locatorAccent;

class SoundLocatorToolPage extends ConsumerStatefulWidget {
  const SoundLocatorToolPage({super.key});

  @override
  ConsumerState<SoundLocatorToolPage> createState() =>
      _SoundLocatorToolPageState();
}

class _SoundLocatorToolPageState extends ConsumerState<SoundLocatorToolPage>
    with SingleTickerProviderStateMixin {
  static const int _sampleRate = 44100;
  static const int _fallbackChannels = 1;

  final AudioRecorder _recorder = AudioRecorder();
  final SoundLocatorService _locator = const SoundLocatorService();

  StreamSubscription<Uint8List>? _pcmSubscription;
  late final AnimationController _pulseController;

  SoundLocatorDeviceProfile _profile = SoundLocatorDeviceProfile.forPcmStream(
    sampleRate: _sampleRate,
    channelCount: _fallbackChannels,
  );
  SoundLocatorFrame? _frame;
  final List<SoundLocatorAnchorSample> _anchorSamples =
      <SoundLocatorAnchorSample>[];
  bool _monitoring = false;
  bool _starting = false;
  bool _showAdvancedDetails = false;
  bool _preferStereoFallback = true;
  String? _errorText;
  double _noiseFloor = 0.012;
  SoundLocatorMoveCue _nextMoveCue = SoundLocatorMoveCue.stay;

  @override
  void initState() {
    super.initState();
    _frame = SoundLocatorFrame.idle(_profile);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    unawaited(_pcmSubscription?.cancel());
    unawaited(_recorder.dispose());
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startMonitoring() async {
    if (_starting || _monitoring) {
      return;
    }
    setState(() {
      _starting = true;
      _errorText = null;
    });
    try {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        if (!mounted) {
          return;
        }
        setState(() {
          _starting = false;
          _errorText = _copy(key: 'toolbox.sound.locator.error_mic_denied');
        });
        return;
      }

      final channelCount = _preferStereoFallback ? 2 : 1;
      _profile = SoundLocatorDeviceProfile.forPcmStream(
        sampleRate: _sampleRate,
        channelCount: channelCount,
      );
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: channelCount,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
          streamBufferSize: 4096,
        ),
      );

      await _pcmSubscription?.cancel();
      _pcmSubscription = stream.listen(
        _handlePcmChunk,
        onError: (Object error, StackTrace stackTrace) {
          if (!mounted) {
            return;
          }
          setState(() {
            _errorText = '$error';
            _monitoring = false;
            _starting = false;
          });
        },
        cancelOnError: false,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _monitoring = true;
        _starting = false;
        _frame = SoundLocatorFrame.idle(_profile);
      });
      _pulseController.repeat();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _starting = false;
        _monitoring = false;
        _errorText = '$error';
        _profile = SoundLocatorDeviceProfile.forPcmStream(
          sampleRate: _sampleRate,
          channelCount: 1,
        );
        _frame = SoundLocatorFrame.idle(_profile);
      });
    }
  }

  Future<void> _stopMonitoring() async {
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() => _monitoring = false);
  }

  void _handlePcmChunk(Uint8List chunk) {
    final frame = _locator.analyzePcm16(
      pcmBytes: chunk,
      profile: _profile,
      previousNoiseFloor: _noiseFloor,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _noiseFloor = frame.noiseFloor;
      _frame = frame;
    });
  }

  void _captureAnchorSample() {
    final frame = _frame;
    if (frame == null || frame.inputRms <= 0) {
      setState(() {
        _errorText = _copy(key: 'toolbox.sound.locator.error_no_frame');
      });
      return;
    }
    final sample = _locator.sampleFromFrame(
      frame: frame,
      cue: _nextMoveCue,
      index: _anchorSamples.length + 1,
    );
    setState(() {
      _anchorSamples.add(sample);
      _nextMoveCue = _locator
          .confirmFromMovementSamples(_anchorSamples)
          .recommendedCue;
      _errorText = null;
    });
  }

  void _resetAnchorSamples() {
    setState(() {
      _anchorSamples.clear();
      _nextMoveCue = SoundLocatorMoveCue.stay;
    });
  }

  String _copy({required String key}) {
    final language = ref.read(appStateProvider).uiLanguage;
    return AppI18n(language).t(key);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final frame = _frame ?? SoundLocatorFrame.idle(_profile);
    final confirmation = _locator.confirmFromMovementSamples(_anchorSamples);
    return Scaffold(
      appBar: AppBar(title: Text(i18n.t('toolbox.sound.locator.page_title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          ToolboxUiTokens.pageHorizontalPadding,
          ToolboxUiTokens.pageTopPadding,
          ToolboxUiTokens.pageHorizontalPadding,
          ToolboxUiTokens.pageBottomPadding,
        ),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ToolboxUiTokens.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PageHeader(
                    eyebrow: i18n.t('toolbox.sound.locator.page_eyebrow'),
                    title: i18n.t('toolbox.sound.locator.page_title'),
                    subtitle: i18n.t('toolbox.sound.locator.page_subtitle'),
                  ),
                  const SizedBox(height: 16),
                  _LocatorHeroPanel(
                    frame: frame,
                    i18n: i18n,
                    monitoring: _monitoring,
                    starting: _starting,
                    errorText: _errorText,
                    animation: _pulseController,
                    onStart: _startMonitoring,
                    onStop: _stopMonitoring,
                    onCaptureAnchor: _captureAnchorSample,
                    canCaptureAnchor:
                        _monitoring && !_starting && frame.inputRms > 0,
                  ),
                  const SizedBox(height: ToolboxUiTokens.sectionSpacing),
                  _MovementConfirmationPanel(
                    confirmation: confirmation,
                    samples: _anchorSamples,
                    nextCue: _nextMoveCue,
                    i18n: i18n,
                    onCapture: _monitoring ? _captureAnchorSample : null,
                    onReset: _anchorSamples.isEmpty
                        ? null
                        : _resetAnchorSamples,
                  ),
                  const SizedBox(height: ToolboxUiTokens.sectionSpacing),
                  _CapabilityPanel(
                    frame: frame,
                    i18n: i18n,
                    preferStereoFallback: _preferStereoFallback,
                    onStereoChanged: _monitoring
                        ? null
                        : (value) {
                            setState(() {
                              _preferStereoFallback = value;
                              _profile = SoundLocatorDeviceProfile.forPcmStream(
                                sampleRate: _sampleRate,
                                channelCount: value ? 2 : 1,
                              );
                              _frame = SoundLocatorFrame.idle(_profile);
                            });
                          },
                  ),
                  const SizedBox(height: ToolboxUiTokens.sectionSpacing),
                  _SourcesPanel(frame: frame, i18n: i18n),
                  const SizedBox(height: ToolboxUiTokens.sectionSpacing),
                  _AdvancedRoutePanel(
                    i18n: i18n,
                    expanded: _showAdvancedDetails,
                    onToggle: () {
                      setState(() {
                        _showAdvancedDetails = !_showAdvancedDetails;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocatorHeroPanel extends StatelessWidget {
  const _LocatorHeroPanel({
    required this.frame,
    required this.i18n,
    required this.monitoring,
    required this.starting,
    required this.errorText,
    required this.animation,
    required this.onStart,
    required this.onStop,
    required this.onCaptureAnchor,
    required this.canCaptureAnchor,
  });

  final SoundLocatorFrame frame;
  final AppI18n i18n;
  final bool monitoring;
  final bool starting;
  final String? errorText;
  final Animation<double> animation;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onCaptureAnchor;
  final bool canCaptureAnchor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = frame.primarySource;
    final direction = primary == null
        ? i18n.t('toolbox.sound.locator.awaiting_source')
        : _directionLabel(i18n, primary.azimuthDegrees);
    return ToolboxSurfaceCard(
      padding: EdgeInsets.zero,
      radius: ToolboxUiTokens.sectionPanelRadius,
      color: colorScheme.surfaceContainerLowest,
      borderColor: _qualityColor(frame.quality).withValues(alpha: 0.34),
      shadowColor: _qualityColor(frame.quality),
      shadowOpacity: 0.08,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _qualityColor(frame.quality).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _qualityColor(
                        frame.quality,
                      ).withValues(alpha: 0.22),
                    ),
                  ),
                  child: Icon(
                    monitoring
                        ? Icons.sensors_rounded
                        : Icons.spatial_audio_rounded,
                    color: _qualityColor(frame.quality),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          ToolboxInfoPill(
                            text: _statusLabel(
                              i18n,
                              frame,
                              monitoring,
                              starting,
                            ),
                            accent: _qualityColor(frame.quality),
                            backgroundColor: _qualityColor(
                              frame.quality,
                            ).withValues(alpha: 0.10),
                            textColor: colorScheme.onSurface,
                          ),
                          ToolboxInfoPill(
                            text: _engineLabel(i18n, frame.profile.engineMode),
                            accent: _soundLocatorAccent,
                            backgroundColor: _soundLocatorAccent.withValues(
                              alpha: 0.10,
                            ),
                            textColor: colorScheme.onSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        direction,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _guidance(i18n, frame, monitoring),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _StatusNotice(
                icon: Icons.error_outline_rounded,
                tint: colorScheme.error,
                text: errorText!,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: AspectRatio(
              aspectRatio: 1.12,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _LocatorStagePainter(
                        frame: frame,
                        pulse: animation.value,
                        accent: _soundLocatorAccent,
                        surface: colorScheme.surfaceContainerLow,
                        grid: colorScheme.outlineVariant,
                        textColor: colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: starting
                        ? null
                        : monitoring
                        ? onStop
                        : onStart,
                    icon: Icon(
                      monitoring
                          ? Icons.stop_circle_rounded
                          : Icons.mic_rounded,
                    ),
                    label: Text(
                      monitoring
                          ? i18n.t('toolbox.sound.locator.btn_stop_monitor')
                          : starting
                          ? i18n.t('toolbox.sound.locator.btn_starting')
                          : i18n.t('toolbox.sound.locator.btn_start_locating'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: canCaptureAnchor ? onCaptureAnchor : null,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  tooltip: i18n.t('toolbox.sound.locator.btn_record_position'),
                ),
                const SizedBox(width: 10),
                _MetricTile(
                  label: i18n.t('toolbox.sound.locator.metric_snr'),
                  value: '${frame.snrDb.toStringAsFixed(1)} dB',
                  tint: _qualityColor(frame.quality),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _directionLabel(AppI18n i18n, double azimuth) {
    final abs = azimuth.abs();
    final side = azimuth > 8
        ? i18n.t('toolbox.sound.locator.direction_right')
        : azimuth < -8
        ? i18n.t('toolbox.sound.locator.direction_left')
        : i18n.t('toolbox.sound.locator.direction_front');
    if (abs <= 8) {
      return i18n.t('toolbox.sound.locator.source_in_front');
    }
    return i18n.t(
      'toolbox.sound.locator.source_offset',
      params: <String, Object?>{'side': side, 'deg': abs.toStringAsFixed(0)},
    );
  }

  String _statusLabel(
    AppI18n i18n,
    SoundLocatorFrame frame,
    bool monitoring,
    bool starting,
  ) {
    if (starting) {
      return i18n.t('toolbox.sound.locator.status_starting_capture');
    }
    if (!monitoring) {
      return i18n.t('toolbox.sound.locator.status_idle');
    }
    return switch (frame.quality) {
      SoundLocatorQuality.professional => i18n.t(
        'toolbox.sound.locator.status_professional',
      ),
      SoundLocatorQuality.strong => i18n.t(
        'toolbox.sound.locator.status_stable',
      ),
      SoundLocatorQuality.usable => i18n.t(
        'toolbox.sound.locator.status_usable',
      ),
      SoundLocatorQuality.poor => i18n.t(
        'toolbox.sound.locator.status_low_confidence',
      ),
      SoundLocatorQuality.unavailable => i18n.t(
        'toolbox.sound.locator.status_listening',
      ),
    };
  }

  String _engineLabel(AppI18n i18n, SoundLocatorEngineMode mode) {
    return switch (mode) {
      SoundLocatorEngineMode.mobileMove => i18n.t(
        'toolbox.sound.locator.engine_mobile_move',
      ),
      SoundLocatorEngineMode.mobileStereo => i18n.t(
        'toolbox.sound.locator.engine_mobile_stereo',
      ),
      SoundLocatorEngineMode.odasOptional => i18n.t(
        'toolbox.sound.locator.engine_array_optional',
      ),
    };
  }

  String _guidance(AppI18n i18n, SoundLocatorFrame frame, bool monitoring) {
    if (!monitoring) {
      return i18n.t('toolbox.sound.locator.guidance_idle');
    }
    if (!frame.profile.canEstimateDirection) {
      return i18n.t('toolbox.sound.locator.guidance_mono');
    }
    if (frame.reverbRisk > 0.72) {
      return i18n.t('toolbox.sound.locator.guidance_reverb');
    }
    if (frame.snrDb < 8) {
      return i18n.t('toolbox.sound.locator.guidance_low_snr');
    }
    return i18n.t('toolbox.sound.locator.guidance_normal');
  }
}

class _MovementConfirmationPanel extends StatelessWidget {
  const _MovementConfirmationPanel({
    required this.confirmation,
    required this.samples,
    required this.nextCue,
    required this.i18n,
    required this.onCapture,
    required this.onReset,
  });

  final SoundLocatorMoveConfirmation confirmation;
  final List<SoundLocatorAnchorSample> samples;
  final SoundLocatorMoveCue nextCue;
  final AppI18n i18n;
  final VoidCallback? onCapture;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tint = _confirmationColor(confirmation.confirmation);
    return ToolboxSurfaceCard(
      color: colorScheme.surfaceContainerLowest,
      borderColor: tint.withValues(alpha: 0.24),
      shadowColor: tint,
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.explore_rounded, color: tint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  i18n.t('toolbox.sound.locator.movement_confirmation'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ToolboxInfoPill(
                text: '${(confirmation.confidence * 100).round()}%',
                accent: tint,
                backgroundColor: tint.withValues(alpha: 0.10),
                textColor: colorScheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _localizedSummary(i18n, confirmation),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _StatusNotice(
            icon: Icons.directions_walk_rounded,
            tint: _soundLocatorAccent,
            text: _cueInstruction(i18n, nextCue, samples.length),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: Text(
                    i18n.t('toolbox.sound.locator.btn_record_position'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: i18n.t('toolbox.sound.locator.btn_reset_samples'),
              ),
            ],
          ),
          if (samples.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            for (final sample in samples)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AnchorSampleTile(sample: sample, i18n: i18n),
              ),
          ],
        ],
      ),
    );
  }

  String _localizedSummary(
    AppI18n i18n,
    SoundLocatorMoveConfirmation confirmation,
  ) {
    return switch (confirmation.confirmation) {
      SoundLocatorConfirmation.locked => i18n.t(
        'toolbox.sound.locator.confirm_locked',
      ),
      SoundLocatorConfirmation.tracking => i18n.t(
        'toolbox.sound.locator.confirm_tracking',
      ),
      SoundLocatorConfirmation.tentative => i18n.t(
        'toolbox.sound.locator.confirm_tentative',
      ),
      SoundLocatorConfirmation.unconfirmed => i18n.t(
        'toolbox.sound.locator.confirm_unconfirmed',
      ),
    };
  }

  String _cueInstruction(AppI18n i18n, SoundLocatorMoveCue cue, int count) {
    if (count == 0) {
      return i18n.t('toolbox.sound.locator.cue_step_0');
    }
    return switch (cue) {
      SoundLocatorMoveCue.stay => i18n.t('toolbox.sound.locator.cue_stay'),
      SoundLocatorMoveCue.stepLeft => i18n.t('toolbox.sound.locator.cue_left'),
      SoundLocatorMoveCue.stepRight => i18n.t(
        'toolbox.sound.locator.cue_right',
      ),
      SoundLocatorMoveCue.stepForward => i18n.t(
        'toolbox.sound.locator.cue_forward',
      ),
      SoundLocatorMoveCue.stepBack => i18n.t('toolbox.sound.locator.cue_back'),
    };
  }
}

class _AnchorSampleTile extends StatelessWidget {
  const _AnchorSampleTile({required this.sample, required this.i18n});

  final SoundLocatorAnchorSample sample;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quality = sample.qualityScore;
    final tint = quality >= 0.68
        ? const Color(0xFF16A34A)
        : quality >= 0.42
        ? const Color(0xFFF59E0B)
        : const Color(0xFF64748B);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: <Widget>[
            Icon(Icons.location_searching_rounded, color: tint, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_cueLabel(i18n, sample.cue)} / '
                '${(quality * 100).round()}% / '
                '${sample.snrDb.toStringAsFixed(1)} dB SNR',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _cueLabel(AppI18n i18n, SoundLocatorMoveCue cue) {
  return switch (cue) {
    SoundLocatorMoveCue.stay => i18n.t('toolbox.sound.locator.cue_label_stay'),
    SoundLocatorMoveCue.stepLeft => i18n.t(
      'toolbox.sound.locator.cue_label_left',
    ),
    SoundLocatorMoveCue.stepRight => i18n.t(
      'toolbox.sound.locator.cue_label_right',
    ),
    SoundLocatorMoveCue.stepForward => i18n.t(
      'toolbox.sound.locator.cue_label_forward',
    ),
    SoundLocatorMoveCue.stepBack => i18n.t(
      'toolbox.sound.locator.cue_label_back',
    ),
  };
}

class _CapabilityPanel extends StatelessWidget {
  const _CapabilityPanel({
    required this.frame,
    required this.i18n,
    required this.preferStereoFallback,
    required this.onStereoChanged,
  });

  final SoundLocatorFrame frame;
  final AppI18n i18n;
  final bool preferStereoFallback;
  final ValueChanged<bool>? onStereoChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ToolboxSurfaceCard(
      color: colorScheme.surfaceContainerLowest,
      borderColor: colorScheme.outlineVariant,
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.settings_input_component_rounded,
                color: _soundLocatorAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  i18n.t('toolbox.sound.locator.phone_mic'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetricTile(
                label: i18n.t('toolbox.sound.locator.metric_channels'),
                value: '${frame.profile.channelCount}',
                tint: _soundLocatorAccent,
              ),
              _MetricTile(
                label: i18n.t('toolbox.sound.locator.metric_sample_rate'),
                value: '${frame.profile.sampleRate ~/ 1000} kHz',
                tint: _soundLocatorAccent,
              ),
              _MetricTile(
                label: i18n.t('toolbox.sound.locator.metric_peak'),
                value: '${(frame.peak * 100).round()}%',
                tint: _qualityColor(frame.quality),
              ),
              _MetricTile(
                label: i18n.t('toolbox.sound.locator.metric_reverb'),
                value: '${(frame.reverbRisk * 100).round()}%',
                tint: frame.reverbRisk > 0.7
                    ? const Color(0xFFD97706)
                    : _soundLocatorAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: preferStereoFallback,
            onChanged: onStereoChanged,
            contentPadding: EdgeInsets.zero,
            title: Text(
              i18n.t('toolbox.sound.locator.try_stereo'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(i18n.t('toolbox.sound.locator.try_stereo_subtitle')),
          ),
          _StatusNotice(
            icon: Icons.info_outline_rounded,
            tint: _soundLocatorAccent,
            text: i18n.t('toolbox.sound.locator.mic_sufficient'),
          ),
        ],
      ),
    );
  }
}

class _SourcesPanel extends StatelessWidget {
  const _SourcesPanel({required this.frame, required this.i18n});

  final SoundLocatorFrame frame;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ToolboxSurfaceCard(
      color: colorScheme.surfaceContainerLowest,
      borderColor: colorScheme.outlineVariant,
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.radar_rounded, color: _soundLocatorAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  i18n.t('toolbox.sound.locator.source_candidates'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (frame.sources.isEmpty)
            Text(
              i18n.t('toolbox.sound.locator.no_stable_source'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final source in frame.sources)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SourceCandidateTile(source: source, i18n: i18n),
              ),
        ],
      ),
    );
  }
}

class _SourceCandidateTile extends StatelessWidget {
  const _SourceCandidateTile({required this.source, required this.i18n});

  final SoundLocatorSource source;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidenceColor = source.confidence >= 0.72
        ? const Color(0xFF16A34A)
        : source.confidence >= 0.42
        ? const Color(0xFFF59E0B)
        : const Color(0xFF64748B);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: confidenceColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: confidenceColor.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: confidenceColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.graphic_eq_rounded, color: confidenceColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _sourceTitle(i18n, source),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${source.azimuthDegrees.toStringAsFixed(0)} deg / '
                    '${(source.confidence * 100).round()}% / '
                    '${source.snrDb.toStringAsFixed(1)} dB SNR',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sourceTitle(AppI18n i18n, SoundLocatorSource source) {
    return switch (source.confirmation) {
      SoundLocatorConfirmation.locked => i18n.t(
        'toolbox.sound.locator.source_locked',
      ),
      SoundLocatorConfirmation.tracking => i18n.t(
        'toolbox.sound.locator.source_tracking',
      ),
      SoundLocatorConfirmation.tentative => i18n.t(
        'toolbox.sound.locator.source_candidate',
      ),
      SoundLocatorConfirmation.unconfirmed => i18n.t(
        'toolbox.sound.locator.source_activity',
      ),
    };
  }
}

class _AdvancedRoutePanel extends StatelessWidget {
  const _AdvancedRoutePanel({
    required this.i18n,
    required this.expanded,
    required this.onToggle,
  });

  final AppI18n i18n;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ToolboxSurfaceCard(
      color: colorScheme.surfaceContainerLowest,
      borderColor: _soundLocatorAccent.withValues(alpha: 0.24),
      shadowColor: _soundLocatorAccent,
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.hub_rounded, color: _soundLocatorAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  i18n.t('toolbox.sound.locator.advanced_odas'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onToggle,
                icon: Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(
                  expanded
                      ? i18n.t('toolbox.sound.locator.btn_less')
                      : i18n.t('toolbox.sound.locator.btn_details'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            i18n.t('toolbox.sound.locator.odas_description'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          AnimatedSize(
            duration: AppDurations.expand,
            curve: AppEasing.standard,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: <Widget>[
                        _StatusNotice(
                          icon: Icons.check_circle_outline_rounded,
                          tint: const Color(0xFF16A34A),
                          text: i18n.t(
                            'toolbox.sound.locator.odas_default_path',
                          ),
                        ),
                        const SizedBox(height: 10),
                        _RequirementList(i18n: i18n),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _RequirementList extends StatelessWidget {
  const _RequirementList({required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <String>[
      i18n.t('toolbox.sound.locator.requirement_1'),
      i18n.t('toolbox.sound.locator.requirement_2'),
      i18n.t('toolbox.sound.locator.requirement_3'),
      i18n.t('toolbox.sound.locator.requirement_4'),
    ];
    return Column(
      children: <Widget>[
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.task_alt_rounded,
                  size: 18,
                  color: _soundLocatorAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    required this.icon,
    required this.tint,
    required this.text,
  });

  final IconData icon;
  final Color tint;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: tint, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.tint,
  });

  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 92, minHeight: 52),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tint.withValues(alpha: 0.20)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocatorStagePainter extends CustomPainter {
  _LocatorStagePainter({
    required this.frame,
    required this.pulse,
    required this.accent,
    required this.surface,
    required this.grid,
    required this.textColor,
  });

  final SoundLocatorFrame frame;
  final double pulse;
  final Color accent;
  final Color surface;
  final Color grid;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = math.min(size.width, size.height) / 2;
    final center = rect.center;

    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          accent.withValues(alpha: 0.18),
          surface.withValues(alpha: 0.92),
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      backgroundPaint,
    );

    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    for (final factor in <double>[0.28, 0.52, 0.76]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2 * factor,
          height: radius * 1.18 * factor,
        ),
        gridPaint,
      );
    }
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.62),
      Offset(center.dx, center.dy + radius * 0.62),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.78, center.dy),
      Offset(center.dx + radius * 0.78, center.dy),
      gridPaint,
    );

    final listenerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final listenerBorder = Paint()
      ..color = accent.withValues(alpha: 0.78)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 12, listenerPaint);
    canvas.drawCircle(center, 12, listenerBorder);

    for (final source in frame.sources.reversed) {
      _drawSource(canvas, size, center, radius, source);
    }

    _drawLabel(canvas, center + Offset(0, radius * 0.72), 'FRONT');
  }

  void _drawSource(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    SoundLocatorSource source,
  ) {
    final vector = source.directionVector;
    final x = center.dx + vector.x * radius * 0.74;
    final y = center.dy - vector.z * radius * 0.38 - vector.y * radius * 0.24;
    final point = Offset(x, y);
    final confidence = source.confidence.clamp(0.0, 1.0);
    final sourceColor = confidence >= 0.7
        ? const Color(0xFF22C55E)
        : confidence >= 0.4
        ? const Color(0xFFF59E0B)
        : accent;
    final beamPaint = Paint()
      ..color = sourceColor.withValues(alpha: 0.24 + confidence * 0.28)
      ..strokeWidth = 3 + confidence * 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, point, beamPaint);

    final glowPaint = Paint()
      ..color = sourceColor.withValues(alpha: 0.18 * (1 - pulse * 0.38))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 26 + pulse * 14 * (0.4 + confidence), glowPaint);

    final sourcePaint = Paint()
      ..color = sourceColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 9 + confidence * 8, sourcePaint);
    canvas.drawCircle(
      point,
      9 + confidence * 8,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.82)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawLabel(Canvas canvas, Offset offset, String label) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.76),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset - Offset(textPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant _LocatorStagePainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.pulse != pulse ||
        oldDelegate.accent != accent ||
        oldDelegate.surface != surface ||
        oldDelegate.grid != grid ||
        oldDelegate.textColor != textColor;
  }
}

Color _qualityColor(SoundLocatorQuality quality) {
  return switch (quality) {
    SoundLocatorQuality.professional => const Color(0xFF0F766E),
    SoundLocatorQuality.strong => const Color(0xFF16A34A),
    SoundLocatorQuality.usable => _soundLocatorAccent,
    SoundLocatorQuality.poor => const Color(0xFFD97706),
    SoundLocatorQuality.unavailable => const Color(0xFF64748B),
  };
}

Color _confirmationColor(SoundLocatorConfirmation confirmation) {
  return switch (confirmation) {
    SoundLocatorConfirmation.locked => const Color(0xFF0F766E),
    SoundLocatorConfirmation.tracking => const Color(0xFF16A34A),
    SoundLocatorConfirmation.tentative => const Color(0xFFF59E0B),
    SoundLocatorConfirmation.unconfirmed => const Color(0xFF64748B),
  };
}
