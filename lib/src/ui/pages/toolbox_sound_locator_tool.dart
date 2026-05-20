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
          _errorText = _copy(
            zh: '麦克风权限被拒绝，无法进行声源采集。',
            en: 'Microphone permission was denied.',
          );
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
        _errorText = _copy(
          zh: '还没有可记录的声音帧，请先开始监听并让目标声源持续发声。',
          en: 'No usable audio frame yet. Start listening and keep the target sound active.',
        );
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

  String _copy({required String zh, required String en}) {
    final language = ref.read(appStateProvider).uiLanguage;
    return pickUiText(AppI18n(language), zh: zh, en: en);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final frame = _frame ?? SoundLocatorFrame.idle(_profile);
    final confirmation = _locator.confirmFromMovementSamples(_anchorSamples);
    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '声源定位', en: 'Sound locator')),
      ),
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
                    eyebrow: pickUiText(
                      i18n,
                      zh: '工具箱 / 声学',
                      en: 'Toolbox / Acoustic',
                    ),
                    title: pickUiText(i18n, zh: '声源定位', en: 'Sound locator'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '使用手机自带麦克风监听目标声源，并引导你移动到多个位置逐步确认声源区域。',
                      en: 'Use the phone microphone, move through several positions, and confirm the source area step by step.',
                    ),
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
        ? pickUiText(i18n, zh: '等待声源', en: 'Awaiting source')
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
                          ? pickUiText(i18n, zh: '停止监听', en: 'Stop monitor')
                          : starting
                          ? pickUiText(i18n, zh: '启动中', en: 'Starting')
                          : pickUiText(i18n, zh: '开始定位', en: 'Start locating'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: canCaptureAnchor ? onCaptureAnchor : null,
                  icon: const Icon(Icons.add_location_alt_rounded),
                  tooltip: pickUiText(
                    i18n,
                    zh: '记录当前位置',
                    en: 'Record position',
                  ),
                ),
                const SizedBox(width: 10),
                _MetricTile(
                  label: pickUiText(i18n, zh: '信噪比', en: 'SNR'),
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
        ? pickUiText(i18n, zh: '右侧', en: 'right')
        : azimuth < -8
        ? pickUiText(i18n, zh: '左侧', en: 'left')
        : pickUiText(i18n, zh: '正前方', en: 'front');
    if (abs <= 8) {
      return pickUiText(i18n, zh: '声源在正前方', en: 'Source in front');
    }
    return pickUiText(
      i18n,
      zh: '声源偏$side ${abs.toStringAsFixed(0)} 度',
      en: 'Source ${abs.toStringAsFixed(0)} deg $side',
    );
  }

  String _statusLabel(
    AppI18n i18n,
    SoundLocatorFrame frame,
    bool monitoring,
    bool starting,
  ) {
    if (starting) {
      return pickUiText(i18n, zh: '启动采集', en: 'Starting capture');
    }
    if (!monitoring) {
      return pickUiText(i18n, zh: '待机', en: 'Idle');
    }
    return switch (frame.quality) {
      SoundLocatorQuality.professional => pickUiText(
        i18n,
        zh: '专业确认',
        en: 'Professional lock',
      ),
      SoundLocatorQuality.strong => pickUiText(i18n, zh: '稳定追踪', en: 'Stable'),
      SoundLocatorQuality.usable => pickUiText(i18n, zh: '可用估计', en: 'Usable'),
      SoundLocatorQuality.poor => pickUiText(
        i18n,
        zh: '低置信度',
        en: 'Low confidence',
      ),
      SoundLocatorQuality.unavailable => pickUiText(
        i18n,
        zh: '等待声源',
        en: 'Listening',
      ),
    };
  }

  String _engineLabel(AppI18n i18n, SoundLocatorEngineMode mode) {
    return switch (mode) {
      SoundLocatorEngineMode.mobileMove => pickUiText(
        i18n,
        zh: '手机移动确认',
        en: 'Phone movement',
      ),
      SoundLocatorEngineMode.mobileStereo => pickUiText(
        i18n,
        zh: '手机双声道',
        en: 'Phone stereo',
      ),
      SoundLocatorEngineMode.odasOptional => pickUiText(
        i18n,
        zh: '高级阵列可选',
        en: 'Array optional',
      ),
    };
  }

  String _guidance(AppI18n i18n, SoundLocatorFrame frame, bool monitoring) {
    if (!monitoring) {
      return pickUiText(
        i18n,
        zh: '点击开始后让目标声源持续发声，然后在当前位置记录一次采样。',
        en: 'Start listening, keep the target sound active, then record this position.',
      );
    }
    if (!frame.profile.canEstimateDirection) {
      return pickUiText(
        i18n,
        zh: '单声道也可以使用：请记录当前位置，然后向左、向右或向前移动一步继续采样。',
        en: 'Mono is still usable: record this spot, then move left, right, or forward and sample again.',
      );
    }
    if (frame.reverbRisk > 0.72) {
      return pickUiText(
        i18n,
        zh: '回响风险偏高，请靠近目标声源、避开墙角或降低背景噪声后重新确认。',
        en: 'Reverb risk is high. Move closer to the source, avoid corners, or lower background noise.',
      );
    }
    if (frame.snrDb < 8) {
      return pickUiText(
        i18n,
        zh: '信噪比偏低，多声源环境下请先让目标声源持续发声再锁定。',
        en: 'SNR is low. In multi-source scenes, keep the target source continuous before locking.',
      );
    }
    return pickUiText(
      i18n,
      zh: '方向估计正在更新；请记录多个位置，系统会结合强度、信噪比和方位稳定性确认声源区域。',
      en: 'Direction is updating. Record multiple positions so strength, SNR, and bearing stability can confirm the area.',
    );
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
                  pickUiText(i18n, zh: '移动确认', en: 'Movement confirmation'),
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
                    pickUiText(i18n, zh: '记录当前位置', en: 'Record position'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: pickUiText(i18n, zh: '重置采样', en: 'Reset samples'),
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
      SoundLocatorConfirmation.locked => pickUiText(
        i18n,
        zh: '已根据多个手机位置确认声源区域。复杂环境下仍建议再采一次反方向样本。',
        en: confirmation.summary,
      ),
      SoundLocatorConfirmation.tracking => pickUiText(
        i18n,
        zh: '声源区域正在收敛，请保持目标声源持续发声并补充一个新位置。',
        en: confirmation.summary,
      ),
      SoundLocatorConfirmation.tentative => pickUiText(
        i18n,
        zh: '已有早期线索，但还需要至少 3 个位置才能稳定确认。',
        en: confirmation.summary,
      ),
      SoundLocatorConfirmation.unconfirmed => pickUiText(
        i18n,
        zh: '请先记录当前位置，再移动到不同方向继续采样。',
        en: confirmation.summary,
      ),
    };
  }

  String _cueInstruction(AppI18n i18n, SoundLocatorMoveCue cue, int count) {
    if (count == 0) {
      return pickUiText(
        i18n,
        zh: '第一步：站在当前位置，保持手机朝向目标区域，记录一次。',
        en: 'Step 1: stay here, point the phone toward the suspected area, and record once.',
      );
    }
    return switch (cue) {
      SoundLocatorMoveCue.stay => pickUiText(
        i18n,
        zh: '下一步：保持目标声源持续发声，再在当前位置复测一次。',
        en: 'Next: keep the target active and record this spot once more.',
      ),
      SoundLocatorMoveCue.stepLeft => pickUiText(
        i18n,
        zh: '下一步：向左侧移动一小步，手机朝向不变，然后记录。',
        en: 'Next: step left, keep the phone facing the same way, then record.',
      ),
      SoundLocatorMoveCue.stepRight => pickUiText(
        i18n,
        zh: '下一步：向右侧移动一小步，手机朝向不变，然后记录。',
        en: 'Next: step right, keep the phone facing the same way, then record.',
      ),
      SoundLocatorMoveCue.stepForward => pickUiText(
        i18n,
        zh: '下一步：向目标方向靠近一步，然后记录。',
        en: 'Next: move one step toward the target area, then record.',
      ),
      SoundLocatorMoveCue.stepBack => pickUiText(
        i18n,
        zh: '下一步：后退一步做对照采样，然后记录。',
        en: 'Next: step back for a comparison sample, then record.',
      ),
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
    SoundLocatorMoveCue.stay => pickUiText(i18n, zh: '原地', en: 'Start'),
    SoundLocatorMoveCue.stepLeft => pickUiText(i18n, zh: '左移', en: 'Left'),
    SoundLocatorMoveCue.stepRight => pickUiText(i18n, zh: '右移', en: 'Right'),
    SoundLocatorMoveCue.stepForward => pickUiText(
      i18n,
      zh: '前移',
      en: 'Forward',
    ),
    SoundLocatorMoveCue.stepBack => pickUiText(i18n, zh: '后退', en: 'Back'),
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
                  pickUiText(i18n, zh: '手机麦克风能力', en: 'Phone microphone'),
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
                label: pickUiText(i18n, zh: '输入通道', en: 'Channels'),
                value: '${frame.profile.channelCount}',
                tint: _soundLocatorAccent,
              ),
              _MetricTile(
                label: pickUiText(i18n, zh: '采样率', en: 'Sample rate'),
                value: '${frame.profile.sampleRate ~/ 1000} kHz',
                tint: _soundLocatorAccent,
              ),
              _MetricTile(
                label: pickUiText(i18n, zh: '峰值', en: 'Peak'),
                value: '${(frame.peak * 100).round()}%',
                tint: _qualityColor(frame.quality),
              ),
              _MetricTile(
                label: pickUiText(i18n, zh: '回响风险', en: 'Reverb'),
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
              pickUiText(i18n, zh: '尝试双声道采集', en: 'Try stereo capture'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '如果平台只返回单声道或启动失败，可关闭此项改为稳定的单声道活动检查。',
                en: 'If the platform returns mono or fails to start, turn this off for stable activity checks.',
              ),
            ),
          ),
          _StatusNotice(
            icon: Icons.info_outline_rounded,
            tint: _soundLocatorAccent,
            text: pickUiText(
              i18n,
              zh: '手机自带麦克风足够用于移动确认流程：静止单点不可靠，但记录多个位置后可以逐步收敛声源区域。',
              en: 'The built-in phone mic is enough for movement confirmation: one static point is weak, but several positions can converge on the source area.',
            ),
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
                  pickUiText(i18n, zh: '多声源候选', en: 'Source candidates'),
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
              pickUiText(
                i18n,
                zh: '还没有稳定声源。请让目标声源持续发声 1-2 秒。',
                en: 'No stable source yet. Keep the target source active for 1-2 seconds.',
              ),
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
      SoundLocatorConfirmation.locked => pickUiText(
        i18n,
        zh: '已锁定主声源',
        en: 'Primary source locked',
      ),
      SoundLocatorConfirmation.tracking => pickUiText(
        i18n,
        zh: '正在追踪声源',
        en: 'Tracking source',
      ),
      SoundLocatorConfirmation.tentative => pickUiText(
        i18n,
        zh: '候选声源',
        en: 'Candidate source',
      ),
      SoundLocatorConfirmation.unconfirmed => pickUiText(
        i18n,
        zh: '声音活动',
        en: 'Sound activity',
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
                  pickUiText(
                    i18n,
                    zh: '高级参考: ODAS 可选',
                    en: 'Advanced reference: optional ODAS',
                  ),
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
                      ? pickUiText(i18n, zh: '收起', en: 'Less')
                      : pickUiText(i18n, zh: '展开', en: 'Details'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '手机端默认不要求外接同步麦克风。ODAS 只作为高级参考：当用户有专用阵列时，可把输出并入本页的确认模型。',
              en: 'External synchronized mics are not required. ODAS stays optional: if a dedicated array exists, its output can be merged into this confirmation model.',
            ),
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
                          text: pickUiText(
                            i18n,
                            zh: '默认路线是手机移动采样；高级模式可以通过原生插件或本地守护进程读取 ODAS tracked source JSON 作为附加证据。',
                            en: 'The default path is phone movement sampling; advanced mode can read ODAS tracked-source JSON as extra evidence.',
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
      pickUiText(
        i18n,
        zh: '手机麦克风权限与稳定 PCM 采集',
        en: 'Phone mic permission and stable PCM capture',
      ),
      pickUiText(
        i18n,
        zh: '至少 3 个不同位置的移动采样',
        en: 'At least 3 movement samples from different positions',
      ),
      pickUiText(
        i18n,
        zh: '目标声源在采样期间保持持续发声',
        en: 'Target sound remains active while sampling',
      ),
      pickUiText(
        i18n,
        zh: '可选 ODAS/阵列输出作为高级证据',
        en: 'Optional ODAS or array output as advanced evidence',
      ),
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
