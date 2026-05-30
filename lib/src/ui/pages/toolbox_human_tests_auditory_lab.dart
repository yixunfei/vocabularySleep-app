part of 'toolbox_human_tests.dart';

enum _MicLabMode { low, high, sustain, noise }

class AuditoryLabPanel extends StatelessWidget {
  const AuditoryLabPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory_lab.volume_calibration_fdaebf',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory_lab.set_playback_volume_to_a_comfortable_range_before_freque_58c901',
          ),
        ),
        const SizedBox(height: 10),
        const _AuditoryVolumeReadinessCard(),
        const SizedBox(height: 12),
        const _AuditoryTestCard(),
      ],
    );
  }
}

class AcousticExperimentTestPage extends StatelessWidget {
  const AcousticExperimentTestPage({super.key});

  static const Color _accent = Color(0xFF7F8B55);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.acoustic_experiment_36e23d',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.record_low_tone_high_tone_vocal_sustain_and_ambient_nois_de584e',
      ),
      accent: _accent,
      icon: Icons.mic_external_on_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.next_allow_microphone_access_choose_a_mode_and_start_sam_061745',
      ),
      child: const AcousticExperimentPanel(),
    );
  }
}

class AcousticExperimentPanel extends StatelessWidget {
  const AcousticExperimentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory_lab.mic_acoustic_lab_829792',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory_lab.complete_each_sampling_mode_to_review_level_pitch_stabil_a673c8',
          ),
        ),
        const SizedBox(height: 10),
        _HumanSettingsSection(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory_lab.acoustic_metrics_8bd0b8',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory_lab.tracks_dbfs_peak_pitch_stability_sustain_smoothness_and_e7cdd6',
          ),
          initiallyExpanded: true,
          child: const _AuditoryMicLabCard(),
        ),
      ],
    );
  }
}

class _AuditoryVolumeReadinessCard extends StatefulWidget {
  const _AuditoryVolumeReadinessCard();

  @override
  State<_AuditoryVolumeReadinessCard> createState() =>
      _AuditoryVolumeReadinessCardState();
}

class _AuditoryVolumeReadinessCardState
    extends State<_AuditoryVolumeReadinessCard> {
  ToolboxAudioVolumeSnapshot? _snapshot;
  bool _loading = true;
  bool _applying = false;
  bool _promptShown = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshVolumeState());
    });
  }

  Future<void> _refreshVolumeState() async {
    if (!mounted) {
      return;
    }
    if (!_isAutoAdjustEnabled(context)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = null;
        _loading = false;
        _applying = false;
        _statusText = 'auto_disabled';
      });
      return;
    }
    setState(() {
      _loading = true;
      _statusText = null;
    });
    try {
      final snapshot = await ToolboxAudioVolumeService.inspectPlaybackVolume(
        recommendedRatio: 0.65,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _statusText = snapshot.message ?? 'ok';
      });
      if (!_isAutoAdjustEnabled(context)) {
        setState(() => _statusText = 'auto_disabled');
        return;
      }
      if (snapshot.needsAdjustment && snapshot.canAutoApply) {
        if (!mounted) {
          return;
        }
        setState(() => _statusText = 'auto_applying');
        await _applyRecommendedVolume();
      } else if (!snapshot.canAutoApply &&
          snapshot.needsAdjustment &&
          !_promptShown) {
        _promptShown = true;
        await _showManualAdjustmentPrompt(snapshot);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _statusText = 'read_failed';
      });
    }
  }

  Future<void> _applyRecommendedVolume() async {
    final snapshot = _snapshot;
    if (snapshot == null || !snapshot.canAutoApply || _applying) {
      return;
    }
    if (!_isAutoAdjustEnabled(context)) {
      setState(() => _statusText = 'auto_disabled');
      return;
    }
    setState(() => _applying = true);
    try {
      final applied =
          await ToolboxAudioVolumeService.applyRecommendedPlaybackVolume(
            recommendedRatio: snapshot.recommendedRatio,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = applied;
        _applying = false;
        _statusText =
            applied.message ?? (applied.needsAdjustment ? 'auto_failed' : 'ok');
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _applying = false;
        _statusText = 'auto_failed';
      });
    }
  }

  bool _isAutoAdjustEnabled(BuildContext context) {
    try {
      return ProviderScope.containerOf(
        context,
        listen: false,
      ).read(appStateProvider).toolboxAutoAdjustSystemVolumeEnabled;
    } catch (_) {
      return false;
    }
  }

  void _setAutoAdjustEnabled(BuildContext context, bool enabled) {
    try {
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(appStateProvider).setToolboxAutoAdjustSystemVolumeEnabled(enabled);
    } catch (_) {
      // Tests and standalone embeddings may not provide AppState.
    }
  }

  Future<void> _showManualAdjustmentPrompt(
    ToolboxAudioVolumeSnapshot snapshot,
  ) async {
    if (!mounted) {
      return;
    }
    final context = this.context;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory_lab.adjust_system_volume_manually_88517b',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.this_device_cannot_change_the_system_media_volume_automa_09488f',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.current_snapshot_currentratio_100_round_recommended_snap_13fabd',
                  params: <String, Object?>{
                    'snapshotCurrentRatio': (snapshot.currentRatio * 100)
                        .round(),
                    'snapshotRecommendedRatio':
                        (snapshot.recommendedRatio * 100).round(),
                  },
                ),
              ),
              if (snapshot.currentIndex != null &&
                  snapshot.maxIndex != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory_lab.system_volume_index_snapshot_currentindex_snapshot_maxin_6a70ab',
                    params: <String, Object?>{
                      'snapshotCurrentIndex': snapshot.currentIndex,
                      'snapshotMaxIndex': snapshot.maxIndex,
                    },
                  ),
                ),
              ],
              if (snapshot.currentDb != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory_lab.reference_output_snapshot_currentdb_tostringasfixed_1_db_b0be84',
                    params: <String, Object?>{
                      'snapshotCurrentDb': snapshot.currentDb!.toStringAsFixed(
                        1,
                      ),
                    },
                  ),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_place_map_panel.later_b5566f',
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _refreshVolumeState();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.i_adjusted_it_d27a29',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _volumeStatusMessage(
    AppI18n i18n,
    ToolboxAudioVolumeSnapshot? snapshot,
  ) {
    if (_statusText == 'auto_disabled') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.automatic_system_media_volume_adjustment_is_off_enable_i_01b1e1',
      );
    }
    if (_statusText == 'auto_applying') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.adjusting_system_media_volume_automatically_e5e735',
      );
    }
    if (_statusText == 'read_failed') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.cannot_read_system_media_volume_set_media_volume_near_65_5eb958',
      );
    }
    if (_statusText == 'auto_failed') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.automatic_adjustment_did_not_complete_adjust_media_volum_e6929c',
      );
    }
    if (snapshot == null) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.waiting_for_volume_check_fe21b6',
      );
    }
    if (!snapshot.isSupported) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.this_platform_cannot_report_system_volume_calibrate_manu_befff5',
      );
    }
    if (snapshot.needsAdjustment) {
      return snapshot.canAutoApply
          ? i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory_lab.volume_is_outside_the_recommended_range_use_auto_adjust_e71d26',
            )
          : i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory_lab.volume_is_outside_the_recommended_range_set_it_manually_74717b',
            );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory_lab.system_media_volume_is_in_the_recommended_range_7fcae9',
    );
  }

  Widget _buildAutoAdjustDisabledCard(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.70),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.volume_off_rounded,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_auditory_lab.auto_system_volume_adjustment_is_off_b8bada',
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_auditory_lab.the_acoustic_test_will_not_change_your_system_media_volu_ceed3b',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () async {
                  _setAutoAdjustEnabled(context, true);
                  await _refreshVolumeState();
                },
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory_lab.enable_and_check_cde304',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final autoAdjustEnabled = _isAutoAdjustEnabled(context);
    if (!autoAdjustEnabled) {
      return _buildAutoAdjustDisabledCard(context, i18n);
    }
    final snapshot = _snapshot;
    final current = snapshot?.currentRatio ?? 0;
    final recommended = snapshot?.recommendedRatio ?? 0.65;
    final needsAdjustment = snapshot?.needsAdjustment ?? false;
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.platform_913e74',
                ),
                value: snapshot?.platformName ?? '--',
              ),
              ToolboxMetricCard(
                label: i18n.t('toolbox.breathing.current'),
                value: '${(current * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.recommended_994d2d',
                ),
                value: '${(recommended * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.auto_adjust_315e16',
                ),
                value: snapshot == null
                    ? '--'
                    : snapshot.canAutoApply
                    ? i18n.t(
                        'inline.ui.pages.toolbox_human_tests_auditory_lab.yes_3dc2f0',
                      )
                    : i18n.t(
                        'inline.ui.pages.toolbox_human_tests_auditory_lab.manual_3ec2d8',
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: current.clamp(0.0, 1.0).toDouble(),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _loading
                ? i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory_lab.checking_system_volume_e8faae',
                  )
                : needsAdjustment
                ? i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory_lab.the_volume_is_outside_the_recommended_range_adjust_it_be_fb1108',
                  )
                : i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory_lab.the_system_volume_is_ready_for_the_current_hearing_test_fa545b',
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (snapshot?.message != null &&
              snapshot!.message!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _volumeStatusMessage(i18n, snapshot),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _loading ? null : _refreshVolumeState,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory_lab.recheck_d984c3',
                  ),
                ),
              ),
              if (snapshot != null && snapshot.canAutoApply)
                FilledButton.tonalIcon(
                  onPressed: _applying ? null : _applyRecommendedVolume,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(
                    _applying
                        ? i18n.t(
                            'inline.ui.pages.toolbox_human_tests_auditory_lab.adjusting_1f4d82',
                          )
                        : i18n.t(
                            'inline.ui.pages.toolbox_human_tests_auditory_lab.auto_adjust_315e16',
                          ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MicModeSpec {
  const _MicModeSpec({
    required this.labelKey,
    required this.descriptionKey,
    required this.icon,
    required this.targetMinHz,
    required this.targetMaxHz,
  });

  final String labelKey;
  final String descriptionKey;
  final IconData icon;
  final double targetMinHz;
  final double targetMaxHz;

  String label(AppI18n i18n) => i18n.t(labelKey);

  String description(AppI18n i18n) => i18n.t(descriptionKey);
}

class _MicRecorderProfile {
  const _MicRecorderProfile({
    required this.id,
    required this.config,
    required this.sampleRate,
  });

  final String id;
  final RecordConfig config;
  final int sampleRate;
}

class _MicFrameSample {
  const _MicFrameSample({
    required this.elapsedMs,
    required this.rms,
    required this.peak,
    required this.dbfs,
    required this.zeroCrossingRate,
    required this.clippingRatio,
    required this.pitchStability,
    required this.sustainScore,
    required this.ambientScore,
    required this.curveSmoothness,
    required this.levelConsistency,
    this.pitchHz,
  });

  final int elapsedMs;
  final double rms;
  final double peak;
  final double dbfs;
  final double zeroCrossingRate;
  final double clippingRatio;
  final double pitchStability;
  final double sustainScore;
  final double ambientScore;
  final double curveSmoothness;
  final double levelConsistency;
  final double? pitchHz;

  double get peakDbfs => peak <= 1e-6
      ? -120.0
      : (20 * math.log(peak) / math.ln10).clamp(-120.0, 0.0).toDouble();
}

class _MicLabCapture {
  _MicLabCapture({
    required this.mode,
    required this.sampleCount,
    required this.durationMs,
    required this.averageDbfs,
    required this.minDbfs,
    required this.maxDbfs,
    required this.peakDbfs,
    required this.averageLevel,
    required this.peakLevel,
    required this.averagePitchHz,
    required this.minPitchHz,
    required this.maxPitchHz,
    required this.pitchStdDevHz,
    required this.pitchStability,
    required this.sustainScore,
    required this.ambientScore,
    required this.curveSmoothness,
    required this.levelConsistency,
    required this.zeroCrossingRate,
    required this.clippingRatio,
    required this.voicedRatio,
    required this.dynamicRangeDb,
    required this.crestFactorDb,
    required this.snrDb,
    required this.targetHitRatio,
    required this.emptyChunkRatio,
    required this.qualityScore,
  });

  factory _MicLabCapture.fromSamples({
    required _MicLabMode mode,
    required _MicModeSpec spec,
    required List<_MicFrameSample> samples,
    required double? noiseFloorDbfs,
  }) {
    final voicedSamples = samples
        .where((sample) => sample.pitchHz != null && sample.dbfs > -62)
        .toList(growable: false);
    final pitchSamples = voicedSamples
        .map((sample) => sample.pitchHz)
        .whereType<double>()
        .toList(growable: false);
    final levels = samples.map((sample) => sample.rms).toList(growable: false);
    final dbValues = samples
        .map((sample) => sample.dbfs)
        .toList(growable: false);
    final voicedRatio = samples.isEmpty
        ? 0.0
        : pitchSamples.length / samples.length;
    final averagePitch = _averageOrNull(pitchSamples);
    final pitchStdDev = averagePitch == null
        ? 0.0
        : _stdDev(pitchSamples, averagePitch);
    final averageDbfs = _averageOrZero(dbValues);
    final averageLevel = _averageOrZero(levels);
    final peakLevel = samples
        .map((sample) => sample.peak)
        .fold<double>(0, math.max);
    final targetHitRatio = _targetHitRatio(mode, spec, samples);
    final clippingRatio = _averageOrZero(
      samples.map((sample) => sample.clippingRatio),
    );
    final dynamicRangeDb = dbValues.isEmpty
        ? 0.0
        : (dbValues.reduce(math.max) - dbValues.reduce(math.min));
    final peakDbfs = samples.isEmpty
        ? -120.0
        : samples.map((sample) => sample.peakDbfs).reduce(math.max);
    final crestFactorDb = averageLevel <= 1e-6 || peakLevel <= 1e-6
        ? 0.0
        : (20 * math.log(peakLevel / averageLevel) / math.ln10)
              .clamp(0.0, 60.0)
              .toDouble();
    final snrDb = noiseFloorDbfs == null || mode == _MicLabMode.noise
        ? null
        : (averageDbfs - noiseFloorDbfs).clamp(-40.0, 80.0).toDouble();
    final pitchStability = _averageOrZero(
      samples.map((sample) => sample.pitchStability),
    );
    final sustainScore = _averageOrZero(
      samples.map((sample) => sample.sustainScore),
    );
    final ambientScore = _averageOrZero(
      samples.map((sample) => sample.ambientScore),
    );
    final smoothness = _averageOrZero(
      samples.map((sample) => sample.curveSmoothness),
    );
    final levelConsistency = _averageOrZero(
      samples.map((sample) => sample.levelConsistency),
    );
    final qualityScore = _qualityScore(
      mode: mode,
      pitchStability: pitchStability,
      sustainScore: sustainScore,
      ambientScore: ambientScore,
      smoothness: smoothness,
      levelConsistency: levelConsistency,
      targetHitRatio: targetHitRatio,
      clippingRatio: clippingRatio,
      voicedRatio: voicedRatio,
    );

    return _MicLabCapture(
      mode: mode,
      sampleCount: samples.length,
      durationMs: samples.last.elapsedMs,
      averageDbfs: averageDbfs,
      minDbfs: dbValues.isEmpty ? -120.0 : dbValues.reduce(math.min),
      maxDbfs: dbValues.isEmpty ? -120.0 : dbValues.reduce(math.max),
      peakDbfs: peakDbfs,
      averageLevel: averageLevel,
      peakLevel: peakLevel,
      averagePitchHz: averagePitch,
      minPitchHz: pitchSamples.isEmpty ? null : pitchSamples.reduce(math.min),
      maxPitchHz: pitchSamples.isEmpty ? null : pitchSamples.reduce(math.max),
      pitchStdDevHz: pitchStdDev,
      pitchStability: pitchStability,
      sustainScore: sustainScore,
      ambientScore: ambientScore,
      curveSmoothness: smoothness,
      levelConsistency: levelConsistency,
      zeroCrossingRate: _averageOrZero(
        samples.map((sample) => sample.zeroCrossingRate),
      ),
      clippingRatio: clippingRatio,
      voicedRatio: voicedRatio,
      dynamicRangeDb: dynamicRangeDb,
      crestFactorDb: crestFactorDb,
      snrDb: snrDb,
      targetHitRatio: targetHitRatio,
      emptyChunkRatio: samples.isEmpty
          ? 0.0
          : samples.where((sample) => sample.rms <= 0.001).length /
                samples.length,
      qualityScore: qualityScore,
    );
  }

  final _MicLabMode mode;
  final int sampleCount;
  final int durationMs;
  final double averageDbfs;
  final double minDbfs;
  final double maxDbfs;
  final double peakDbfs;
  final double averageLevel;
  final double peakLevel;
  final double? averagePitchHz;
  final double? minPitchHz;
  final double? maxPitchHz;
  final double pitchStdDevHz;
  final double pitchStability;
  final double sustainScore;
  final double ambientScore;
  final double curveSmoothness;
  final double levelConsistency;
  final double zeroCrossingRate;
  final double clippingRatio;
  final double voicedRatio;
  final double dynamicRangeDb;
  final double crestFactorDb;
  final double? snrDb;
  final double targetHitRatio;
  final double emptyChunkRatio;
  final double qualityScore;

  double get seconds => durationMs / 1000;

  static double _targetHitRatio(
    _MicLabMode mode,
    _MicModeSpec spec,
    List<_MicFrameSample> samples,
  ) {
    if (samples.isEmpty) {
      return 0;
    }
    if (mode == _MicLabMode.noise) {
      final quietCount = samples.where((sample) => sample.dbfs <= -52).length;
      return quietCount / samples.length;
    }
    final voicedSamples = samples
        .where((sample) => sample.pitchHz != null && sample.dbfs > -62)
        .toList(growable: false);
    if (voicedSamples.isEmpty) {
      return 0;
    }
    final pitchSamples = samples
        .map((sample) => sample.pitchHz)
        .whereType<double>()
        .toList(growable: false);
    final inRange = pitchSamples
        .where(
          (pitch) => pitch >= spec.targetMinHz && pitch <= spec.targetMaxHz,
        )
        .length;
    return inRange / voicedSamples.length;
  }

  static double _qualityScore({
    required _MicLabMode mode,
    required double pitchStability,
    required double sustainScore,
    required double ambientScore,
    required double smoothness,
    required double levelConsistency,
    required double targetHitRatio,
    required double clippingRatio,
    required double voicedRatio,
  }) {
    final clippingSafety = (1 - clippingRatio * 8).clamp(0.0, 1.0).toDouble();
    final base = switch (mode) {
      _MicLabMode.noise =>
        ambientScore * 0.58 + smoothness * 0.24 + clippingSafety * 0.18,
      _MicLabMode.sustain =>
        sustainScore * 0.34 +
            pitchStability * 0.24 +
            levelConsistency * 0.18 +
            smoothness * 0.12 +
            targetHitRatio * 0.08 +
            clippingSafety * 0.04,
      _ =>
        pitchStability * 0.28 +
            targetHitRatio * 0.24 +
            levelConsistency * 0.18 +
            voicedRatio * 0.12 +
            smoothness * 0.10 +
            clippingSafety * 0.08,
    };
    return base.clamp(0.0, 1.0).toDouble();
  }

  static double _averageOrZero(Iterable<double> values) {
    var count = 0;
    var sum = 0.0;
    for (final value in values) {
      count += 1;
      sum += value;
    }
    return count == 0 ? 0 : sum / count;
  }

  static double? _averageOrNull(List<double> values) {
    if (values.isEmpty) {
      return null;
    }
    return _averageOrZero(values);
  }

  static double _stdDev(List<double> values, double mean) {
    if (values.length < 2) {
      return 0;
    }
    final variance =
        values.fold<double>(
          0,
          (sum, value) => sum + math.pow(value - mean, 2).toDouble(),
        ) /
        values.length;
    return math.sqrt(variance);
  }
}

class _AuditoryMicLabCard extends StatefulWidget {
  const _AuditoryMicLabCard();

  @override
  State<_AuditoryMicLabCard> createState() => _AuditoryMicLabCardState();
}

class _AuditoryMicLabCardState extends State<_AuditoryMicLabCard> {
  static const Map<_MicLabMode, _MicModeSpec>
  _modeSpecs = <_MicLabMode, _MicModeSpec>{
    _MicLabMode.low: _MicModeSpec(
      labelKey:
          'inline.plan297.human_tests.auditory_lab.mode.label.low_tone.e3c1256c24',
      descriptionKey:
          'inline.plan297.human_tests.auditory_lab.mode.description.produce_a_low_steady_hum_and_check_low_frequency_pit.44b54f70f8',
      icon: Icons.arrow_downward_rounded,
      targetMinHz: 110,
      targetMaxHz: 240,
    ),
    _MicLabMode.high: _MicModeSpec(
      labelKey:
          'inline.plan297.human_tests.auditory_lab.mode.label.high_tone.19cf39f726',
      descriptionKey:
          'inline.plan297.human_tests.auditory_lab.mode.description.produce_a_higher_tone_and_observe_the_high_frequency.319a3befd1',
      icon: Icons.arrow_upward_rounded,
      targetMinHz: 360,
      targetMaxHz: 860,
    ),
    _MicLabMode.sustain: _MicModeSpec(
      labelKey:
          'inline.plan297.human_tests.auditory_lab.mode.label.sustain.924fe96c4e',
      descriptionKey:
          'inline.plan297.human_tests.auditory_lab.mode.description.hold_a_steady_sound_for_5_seconds_and_measure_sustai.1ea2bdec97',
      icon: Icons.graphic_eq_rounded,
      targetMinHz: 160,
      targetMaxHz: 420,
    ),
    _MicLabMode.noise: _MicModeSpec(
      labelKey:
          'inline.plan297.human_tests.auditory_lab.mode.label.noise_meter.703c222640',
      descriptionKey:
          'inline.plan297.human_tests.auditory_lab.mode.description.stay_quiet_to_measure_ambient_noise_peak_and_relativ.7dc763fa72',
      icon: Icons.hearing_disabled_rounded,
      targetMinHz: 0,
      targetMaxHz: 0,
    ),
  };

  static const int _primarySampleRate = 44100;
  static const int _fallbackSampleRate = 16000;
  static const Duration _firstFrameTimeout = Duration(milliseconds: 1600);
  static const int _digitalSilenceFrameLimit = 10;
  static const double _digitalSilencePeakFloor = 0.00008;

  static const List<_MicRecorderProfile> _recorderProfiles =
      <_MicRecorderProfile>[
        _MicRecorderProfile(
          id: 'default_44100',
          sampleRate: _primarySampleRate,
          config: RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _primarySampleRate,
            numChannels: 1,
            autoGain: true,
            echoCancel: false,
            noiseSuppress: false,
            androidConfig: AndroidRecordConfig(
              audioSource: AndroidAudioSource.defaultSource,
              manageBluetooth: true,
            ),
            iosConfig: IosRecordConfig(
              categoryOptions: <IosAudioCategoryOption>[
                IosAudioCategoryOption.allowBluetooth,
                IosAudioCategoryOption.allowBluetoothA2DP,
              ],
            ),
            audioInterruption: AudioInterruptionMode.pause,
            streamBufferSize: 4096,
          ),
        ),
        _MicRecorderProfile(
          id: 'mic_44100',
          sampleRate: _primarySampleRate,
          config: RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _primarySampleRate,
            numChannels: 1,
            autoGain: false,
            echoCancel: false,
            noiseSuppress: false,
            androidConfig: AndroidRecordConfig(
              audioSource: AndroidAudioSource.mic,
              manageBluetooth: true,
            ),
            iosConfig: IosRecordConfig(
              categoryOptions: <IosAudioCategoryOption>[
                IosAudioCategoryOption.allowBluetooth,
                IosAudioCategoryOption.allowBluetoothA2DP,
              ],
            ),
            audioInterruption: AudioInterruptionMode.pause,
            streamBufferSize: 4096,
          ),
        ),
        _MicRecorderProfile(
          id: 'voice_recognition_16000',
          sampleRate: _fallbackSampleRate,
          config: RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _fallbackSampleRate,
            numChannels: 1,
            autoGain: true,
            echoCancel: false,
            noiseSuppress: false,
            androidConfig: AndroidRecordConfig(
              audioSource: AndroidAudioSource.voiceRecognition,
              manageBluetooth: true,
            ),
            iosConfig: IosRecordConfig(
              categoryOptions: <IosAudioCategoryOption>[
                IosAudioCategoryOption.allowBluetooth,
                IosAudioCategoryOption.allowBluetoothA2DP,
              ],
            ),
            audioInterruption: AudioInterruptionMode.pause,
            streamBufferSize: 2048,
          ),
        ),
        _MicRecorderProfile(
          id: 'unprocessed_44100',
          sampleRate: _primarySampleRate,
          config: RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _primarySampleRate,
            numChannels: 1,
            autoGain: false,
            echoCancel: false,
            noiseSuppress: false,
            androidConfig: AndroidRecordConfig(
              audioSource: AndroidAudioSource.unprocessed,
              manageBluetooth: false,
            ),
            iosConfig: IosRecordConfig(
              categoryOptions: <IosAudioCategoryOption>[
                IosAudioCategoryOption.allowBluetooth,
                IosAudioCategoryOption.allowBluetoothA2DP,
              ],
            ),
            audioInterruption: AudioInterruptionMode.pause,
            streamBufferSize: 4096,
          ),
        ),
      ];

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmSubscription;
  StreamSubscription<RecordState>? _stateSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _firstFrameWatchdog;
  final List<double> _levelHistory = List<double>.filled(72, 0);
  final List<double> _pitchWindow = <double>[];
  final List<_MicFrameSample> _samples = <_MicFrameSample>[];
  final Map<_MicLabMode, _MicLabCapture> _captures =
      <_MicLabMode, _MicLabCapture>{};
  final Stopwatch _stopwatch = Stopwatch();

  _MicLabMode _mode = _MicLabMode.low;
  bool _starting = false;
  bool _running = false;
  bool _preferCompatibilityInput = false;
  bool _switchingInput = false;
  String? _error;
  String? _statusCode;
  String? _profileNoticeCode;
  String? _activeRecorderProfileId;
  String? _inputDeviceLabel;
  int _activeSampleRate = _primarySampleRate;
  int _streamRestartCount = 0;
  int _emptyChunkCount = 0;
  int _digitalSilenceFrameCount = 0;
  int _activeProfileSequenceIndex = -1;
  int? _lastPcmFrameMs;
  int? _firstFrameMs;
  bool _hasSeenFrame = false;
  double _level = 0;
  double _peak = 0;
  double _dbfs = -120;
  double? _pitchHz;
  double _pitchStability = 0;
  double _sustainScore = 0;
  double _ambientScore = 0;
  double _lastCurveSmoothness = 0;
  double _levelConsistencyScore = 0;
  double _zeroCrossingRate = 0;
  double _clippingRatio = 0;
  int _frameCount = 0;
  double? _noiseFloorDbfs;

  @override
  void dispose() {
    _firstFrameWatchdog?.cancel();
    unawaited(_pcmSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    unawaited(_amplitudeSubscription?.cancel());
    unawaited(_recorder.dispose());
    _stopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  void _setMode(_MicLabMode mode) {
    if (_mode == mode || _running || _starting) {
      return;
    }
    setState(() {
      _mode = mode;
      _error = null;
      _statusCode = null;
      _profileNoticeCode = null;
      _samples.clear();
      _pitchWindow.clear();
      _levelHistory.fillRange(0, _levelHistory.length, 0);
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = 0;
      _ambientScore = 0;
      _lastCurveSmoothness = 0;
      _levelConsistencyScore = 0;
      _zeroCrossingRate = 0;
      _clippingRatio = 0;
      _frameCount = 0;
      _digitalSilenceFrameCount = 0;
      _lastPcmFrameMs = null;
      _level = 0;
      _peak = 0;
      _dbfs = -120;
    });
  }

  Future<void> _startMonitoring() async {
    if (_starting || _running) {
      return;
    }
    setState(() {
      _starting = true;
      _switchingInput = false;
      _error = null;
      _statusCode = 'checking_input';
      _profileNoticeCode = null;
      _samples.clear();
      _pitchWindow.clear();
      _levelHistory.fillRange(0, _levelHistory.length, 0);
      _frameCount = 0;
      _streamRestartCount = 0;
      _emptyChunkCount = 0;
      _digitalSilenceFrameCount = 0;
      _firstFrameMs = null;
      _lastPcmFrameMs = null;
      _hasSeenFrame = false;
      _activeRecorderProfileId = null;
      _activeProfileSequenceIndex = -1;
      _level = 0;
      _peak = 0;
      _dbfs = -120;
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = 0;
      _ambientScore = 0;
      _lastCurveSmoothness = 0;
      _levelConsistencyScore = 0;
      _zeroCrossingRate = 0;
      _clippingRatio = 0;
    });
    try {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        if (!mounted) {
          return;
        }
        setState(() {
          _starting = false;
          _switchingInput = false;
          _error = 'microphone_permission_denied';
          _statusCode = 'permission_denied';
        });
        return;
      }

      final supported = await _recorder.isEncoderSupported(
        AudioEncoder.pcm16bits,
      );
      if (!supported) {
        if (!mounted) {
          return;
        }
        setState(() {
          _starting = false;
          _running = false;
          _switchingInput = false;
          _error = 'pcm_stream_not_supported';
          _statusCode = 'unsupported';
        });
        return;
      }

      await _refreshInputDeviceLabel();
      await _startWithBestRecorderProfile();

      _stateSubscription ??= _recorder.onStateChanged().listen((state) {
        if (!mounted) {
          return;
        }
        setState(() {
          _running = state == RecordState.record || state == RecordState.pause;
        });
      });

      if (!mounted) {
        return;
      }
      _stopwatch
        ..reset()
        ..start();
      setState(() {
        _starting = false;
        _running = true;
        _statusCode = 'waiting_for_signal';
      });
      _armFirstFrameWatchdog();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppLogService.instance.e(
        'toolbox_acoustic_lab',
        'start monitoring failed',
        error: error,
      );
      setState(() {
        _starting = false;
        _running = false;
        _switchingInput = false;
        _error = '$error';
        _statusCode = 'start_failed';
      });
    }
  }

  Future<void> _refreshInputDeviceLabel() async {
    try {
      final devices = await _recorder.listInputDevices();
      if (!mounted) {
        return;
      }
      final label = devices.isEmpty
          ? null
          : devices.first.label.trim().isEmpty
          ? devices.first.id
          : devices.first.label.trim();
      setState(() => _inputDeviceLabel = label);
    } catch (_) {
      if (mounted) {
        setState(() => _inputDeviceLabel = null);
      }
    }
  }

  List<int> _recorderProfileSequence() {
    if (_preferCompatibilityInput) {
      return const <int>[2, 0, 1, 3];
    }
    return const <int>[0, 1, 2, 3];
  }

  bool _hasNextRecorderProfile() {
    final sequence = _recorderProfileSequence();
    return _activeProfileSequenceIndex >= 0 &&
        _activeProfileSequenceIndex + 1 < sequence.length;
  }

  Future<void> _startWithBestRecorderProfile({
    int startSequenceIndex = 0,
  }) async {
    Object? lastError;
    StackTrace? lastStack;
    final sequence = _recorderProfileSequence();
    for (
      var orderIndex = startSequenceIndex;
      orderIndex < sequence.length;
      orderIndex += 1
    ) {
      final profile = _recorderProfiles[sequence[orderIndex]];
      try {
        await _startStreamWithProfile(profile, sequenceIndex: orderIndex);
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStack = stackTrace;
        AppLogService.instance.w(
          'toolbox_acoustic_lab',
          'recorder profile failed',
          data: <String, Object?>{
            'profile': profile.id,
            'sampleRate': profile.sampleRate,
            'error': '$error',
          },
        );
        await _pcmSubscription?.cancel();
        _pcmSubscription = null;
        try {
          await _recorder.stop();
        } catch (_) {}
      }
    }
    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStack ?? StackTrace.current);
    }
    throw StateError('No recorder profile is available.');
  }

  Future<void> _startStreamWithProfile(
    _MicRecorderProfile profile, {
    required int sequenceIndex,
  }) async {
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    final stream = await _recorder.startStream(profile.config);
    _pcmSubscription = stream.listen(
      (chunk) => _handlePcmChunk(chunk, sampleRate: profile.sampleRate),
      onError: (Object error, StackTrace stackTrace) {
        AppLogService.instance.e(
          'toolbox_acoustic_lab',
          'pcm stream error',
          error: error,
          stackTrace: stackTrace,
          data: <String, Object?>{'profile': profile.id},
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _error = '$error';
          _running = false;
          _starting = false;
          _switchingInput = false;
          _statusCode = 'stream_error';
        });
      },
      onDone: () {
        if (!mounted) {
          return;
        }
        if (!_hasSeenFrame && _hasNextRecorderProfile()) {
          unawaited(_retryNextRecorderProfile('no_pcm_frames'));
          return;
        }
        setState(() {
          _running = false;
          _starting = false;
          _switchingInput = false;
          _statusCode = _hasSeenFrame ? 'stream_done' : 'no_pcm_frames';
        });
      },
      cancelOnError: false,
    );
    await _subscribeAmplitudeUpdates();
    _activeSampleRate = profile.sampleRate;
    _activeRecorderProfileId = profile.id;
    _activeProfileSequenceIndex = sequenceIndex;
    _digitalSilenceFrameCount = 0;
    _lastPcmFrameMs = null;
    _streamRestartCount += 1;
  }

  Future<void> _subscribeAmplitudeUpdates() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 220))
        .listen(
          _handleAmplitudeSample,
          onError: (Object error, StackTrace stackTrace) {
            AppLogService.instance.w(
              'toolbox_acoustic_lab',
              'amplitude stream failed',
              data: <String, Object?>{'error': '$error'},
            );
          },
        );
  }

  Future<void> _retryNextRecorderProfile(String reason) async {
    if (_switchingInput || !_hasNextRecorderProfile()) {
      if (!_hasNextRecorderProfile()) {
        await _failRecorderProfiles(reason, exhausted: true);
      }
      return;
    }
    final nextSequenceIndex = _activeProfileSequenceIndex + 1;
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = null;
    if (mounted) {
      setState(() {
        _switchingInput = true;
        _starting = true;
        _running = false;
        _error = null;
        _statusCode = 'switching_input';
        _profileNoticeCode = reason;
      });
    }
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() {
      _samples.clear();
      _pitchWindow.clear();
      _levelHistory.fillRange(0, _levelHistory.length, 0);
      _frameCount = 0;
      _emptyChunkCount = 0;
      _digitalSilenceFrameCount = 0;
      _firstFrameMs = null;
      _lastPcmFrameMs = null;
      _hasSeenFrame = false;
      _level = 0;
      _peak = 0;
      _dbfs = -120;
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = 0;
      _ambientScore = 0;
      _lastCurveSmoothness = 0;
      _levelConsistencyScore = 0;
      _zeroCrossingRate = 0;
      _clippingRatio = 0;
    });
    try {
      await _startWithBestRecorderProfile(
        startSequenceIndex: nextSequenceIndex,
      );
      if (!mounted) {
        return;
      }
      _stopwatch
        ..reset()
        ..start();
      setState(() {
        _switchingInput = false;
        _starting = false;
        _running = true;
        _statusCode = 'waiting_for_signal';
      });
      _armFirstFrameWatchdog();
    } catch (error, stackTrace) {
      AppLogService.instance.e(
        'toolbox_acoustic_lab',
        'recorder retry failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'reason': reason},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _switchingInput = false;
        _starting = false;
        _running = false;
        _error = '$error';
        _statusCode = 'start_failed';
      });
    }
  }

  Future<void> _failRecorderProfiles(
    String reason, {
    bool exhausted = false,
  }) async {
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = null;
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _switchingInput = false;
      _starting = false;
      _running = false;
      _profileNoticeCode = exhausted ? 'exhausted_$reason' : reason;
      _statusCode = 'no_usable_input';
      _error = reason == 'digital_silence' ? 'silent_input' : 'no_pcm_frames';
    });
  }

  void _armFirstFrameWatchdog() {
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = Timer(_firstFrameTimeout, () {
      if (!mounted || !_running || _hasSeenFrame) {
        return;
      }
      if (_hasNextRecorderProfile()) {
        unawaited(_retryNextRecorderProfile('no_pcm_frames'));
        return;
      }
      setState(() {
        _statusCode = 'no_pcm_frames';
        _error = 'no_pcm_frames';
      });
      AppLogService.instance.w(
        'toolbox_acoustic_lab',
        'no pcm frame after start',
        data: <String, Object?>{
          'profile': _activeRecorderProfileId,
          'sampleRate': _activeSampleRate,
        },
      );
    });
  }

  Future<void> _stopMonitoring() async {
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = null;
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _running = false;
      _starting = false;
      _switchingInput = false;
      _statusCode = _samples.isEmpty ? 'stopped_without_samples' : 'stopped';
    });
  }

  Future<void> _finishCapture() async {
    if (_running || _starting) {
      await _stopMonitoring();
    }
    if (_samples.length < 3) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'capture_too_short');
      return;
    }
    final spec = _modeSpecs[_mode]!;
    final capture = _MicLabCapture.fromSamples(
      mode: _mode,
      spec: spec,
      samples: List<_MicFrameSample>.of(_samples),
      noiseFloorDbfs: _noiseFloorDbfs,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _captures[_mode] = capture;
      if (_mode == _MicLabMode.noise) {
        _noiseFloorDbfs = capture.averageDbfs;
      }
      _error = null;
      _statusCode = 'sample_added';
    });
  }

  void _reset() {
    _firstFrameWatchdog?.cancel();
    _firstFrameWatchdog = null;
    setState(() {
      _switchingInput = false;
      _error = null;
      _statusCode = null;
      _profileNoticeCode = null;
      _samples.clear();
      _pitchWindow.clear();
      _levelHistory.fillRange(0, _levelHistory.length, 0);
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = 0;
      _ambientScore = 0;
      _lastCurveSmoothness = 0;
      _levelConsistencyScore = 0;
      _zeroCrossingRate = 0;
      _clippingRatio = 0;
      _frameCount = 0;
      _emptyChunkCount = 0;
      _digitalSilenceFrameCount = 0;
      _firstFrameMs = null;
      _lastPcmFrameMs = null;
      _hasSeenFrame = false;
      _level = 0;
      _peak = 0;
      _dbfs = -120;
    });
  }

  Future<void> _resetCurrentRun() async {
    if (_running || _starting || _switchingInput) {
      await _stopMonitoring();
    }
    if (!mounted) {
      return;
    }
    _reset();
  }

  void _handlePcmChunk(Uint8List chunk, {required int sampleRate}) {
    final byteData = ByteData.sublistView(chunk);
    final sampleCount = byteData.lengthInBytes ~/ 2;
    if (sampleCount < 256) {
      _emptyChunkCount += 1;
      return;
    }
    if (!_hasSeenFrame) {
      _firstFrameWatchdog?.cancel();
      _firstFrameWatchdog = null;
      _hasSeenFrame = true;
      _firstFrameMs = _stopwatch.elapsedMilliseconds;
      if (_error == 'no_pcm_frames') {
        _error = null;
      }
    }

    var peak = 0.0;
    var sumSquares = 0.0;
    var zeroCrossings = 0;
    var clippedSamples = 0;
    var previousValue = 0.0;
    final samples = List<double>.filled(sampleCount, 0);
    for (var i = 0; i < sampleCount; i += 1) {
      final value = byteData.getInt16(i * 2, Endian.little) / 32768.0;
      samples[i] = value;
      final absValue = value.abs();
      if (absValue > peak) {
        peak = absValue;
      }
      if (i > 0 &&
          ((previousValue < 0 && value >= 0) ||
              (previousValue > 0 && value <= 0))) {
        zeroCrossings += 1;
      }
      if (absValue >= 0.985) {
        clippedSamples += 1;
      }
      previousValue = value;
      sumSquares += value * value;
    }

    final rms = math.sqrt(sumSquares / sampleCount);
    final dbfs = rms <= 1e-6
        ? -120.0
        : (20 * math.log(rms) / math.ln10).clamp(-120.0, 0.0).toDouble();
    if (peak <= _digitalSilencePeakFloor && rms <= _digitalSilencePeakFloor) {
      _digitalSilenceFrameCount += 1;
      if (_digitalSilenceFrameCount >= _digitalSilenceFrameLimit &&
          _hasNextRecorderProfile()) {
        unawaited(_retryNextRecorderProfile('digital_silence'));
        return;
      }
    } else {
      _digitalSilenceFrameCount = 0;
    }
    final detectedPitch = _detectPitch(samples, sampleRate);
    _pushLevelHistory(rms);
    if (detectedPitch != null) {
      _pitchWindow.add(detectedPitch);
      if (_pitchWindow.length > 10) {
        _pitchWindow.removeAt(0);
      }
    } else if (_pitchWindow.length > 6) {
      _pitchWindow.removeAt(0);
    }

    final smoothPitch = _smoothedPitch();
    final stability = _pitchStabilityScore(smoothPitch);
    final sustain = _sustainScoreForMode(rms, smoothPitch);
    final ambientScore = _ambientNoiseScore(dbfs);
    final curveSmoothness = _curveSmoothness();
    final levelConsistency = _levelConsistency();
    final zeroCrossingRate = zeroCrossings / math.max(1, sampleCount - 1);
    final clippingRatio = clippedSamples / sampleCount;
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    _lastPcmFrameMs = elapsedMs;
    final frameSample = _MicFrameSample(
      elapsedMs: elapsedMs,
      rms: rms.clamp(0.0, 1.0).toDouble(),
      peak: peak.clamp(0.0, 1.0).toDouble(),
      dbfs: dbfs,
      zeroCrossingRate: zeroCrossingRate,
      clippingRatio: clippingRatio,
      pitchStability: stability,
      sustainScore: sustain,
      ambientScore: ambientScore,
      curveSmoothness: curveSmoothness,
      levelConsistency: levelConsistency,
      pitchHz: smoothPitch,
    );
    _samples.add(frameSample);
    if (_samples.length > 360) {
      _samples.removeRange(0, _samples.length - 360);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _frameCount += 1;
      _level = rms.clamp(0.0, 1.0).toDouble();
      _peak = peak.clamp(0.0, 1.0).toDouble();
      _dbfs = dbfs;
      _pitchHz = smoothPitch;
      _pitchStability = stability;
      _sustainScore = sustain;
      _ambientScore = ambientScore;
      _lastCurveSmoothness = curveSmoothness;
      _levelConsistencyScore = levelConsistency;
      _zeroCrossingRate = zeroCrossingRate;
      _clippingRatio = clippingRatio;
      _statusCode = 'sampling';
      if (_error == 'no_pcm_frames') {
        _error = null;
      }
    });
  }

  void _handleAmplitudeSample(Amplitude amplitude) {
    if (!mounted || (!_running && !_starting)) {
      return;
    }
    final currentDbfs = amplitude.current;
    if (!currentDbfs.isFinite || currentDbfs <= -155) {
      return;
    }
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    final lastPcmFrameMs = _lastPcmFrameMs;
    if (lastPcmFrameMs != null && elapsedMs - lastPcmFrameMs < 650) {
      return;
    }
    final dbfs = currentDbfs.clamp(-120.0, 0.0).toDouble();
    final level = math.pow(10, dbfs / 20).clamp(0.0, 1.0).toDouble();
    if (level <= _digitalSilencePeakFloor) {
      return;
    }
    if (!_hasSeenFrame) {
      _firstFrameWatchdog?.cancel();
      _firstFrameWatchdog = null;
      _hasSeenFrame = true;
      _firstFrameMs = elapsedMs;
    }
    _pushLevelHistory(level);
    final ambientScore = _ambientNoiseScore(dbfs);
    final curveSmoothness = _curveSmoothness();
    final levelConsistency = _levelConsistency();
    final sustain = _sustainScoreForMode(level, null);
    final frameSample = _MicFrameSample(
      elapsedMs: elapsedMs,
      rms: level,
      peak: level,
      dbfs: dbfs,
      zeroCrossingRate: 0,
      clippingRatio: dbfs >= -1.0 ? 0.01 : 0,
      pitchStability: 0,
      sustainScore: sustain,
      ambientScore: ambientScore,
      curveSmoothness: curveSmoothness,
      levelConsistency: levelConsistency,
    );
    _samples.add(frameSample);
    if (_samples.length > 360) {
      _samples.removeRange(0, _samples.length - 360);
    }
    setState(() {
      _frameCount += 1;
      _level = level;
      _peak = math.max(_peak * 0.96, level).clamp(0.0, 1.0).toDouble();
      _dbfs = dbfs;
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = sustain;
      _ambientScore = ambientScore;
      _lastCurveSmoothness = curveSmoothness;
      _levelConsistencyScore = levelConsistency;
      _zeroCrossingRate = 0;
      _clippingRatio = dbfs >= -1.0 ? 0.01 : 0;
      _statusCode = 'sampling';
      if (_error == 'no_pcm_frames' || _error == 'silent_input') {
        _error = null;
      }
    });
  }

  void _pushLevelHistory(double level) {
    _levelHistory.removeAt(0);
    _levelHistory.add(level.clamp(0.0, 1.0).toDouble());
  }

  double? _smoothedPitch() {
    if (_pitchWindow.isEmpty) {
      return null;
    }
    final sorted = List<double>.of(_pitchWindow)..sort();
    return sorted[sorted.length ~/ 2];
  }

  double _pitchStabilityScore(double? pitch) {
    if (pitch == null || _pitchWindow.length < 3) {
      return 0;
    }
    final mean =
        _pitchWindow.fold<double>(0, (sum, value) => sum + value) /
        _pitchWindow.length;
    final variance =
        _pitchWindow.fold<double>(
          0,
          (sum, value) => sum + math.pow(value - mean, 2).toDouble(),
        ) /
        _pitchWindow.length;
    final deviation = math.sqrt(variance);
    final normalized = 1 - (deviation / math.max(1.0, mean * 0.08));
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  double _sustainScoreForMode(double level, double? pitch) {
    if (_mode == _MicLabMode.noise) {
      return 0;
    }
    final spec = _modeSpecs[_mode]!;
    final targetCenter = (spec.targetMinHz + spec.targetMaxHz) / 2;
    final targetSpan = math.max(1.0, spec.targetMaxHz - spec.targetMinHz);
    final pitchScore = pitch == null
        ? 0.0
        : (1 - ((pitch - targetCenter).abs() / (targetSpan * 0.75)))
              .clamp(0.0, 1.0)
              .toDouble();
    final levelConsistency = _levelConsistency();
    return (pitchScore * 0.6 + levelConsistency * 0.4)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _ambientNoiseScore(double dbfs) {
    final quiet = dbfs <= -52;
    if (quiet) {
      return 1.0;
    }
    final normalized = 1 - (((dbfs + 52) / 38).clamp(0.0, 1.0));
    return normalized.toDouble();
  }

  double _levelConsistency() {
    final values = _levelHistory.where((value) => value > 0.001).toList();
    if (values.length < 3) {
      return 0;
    }
    final mean =
        values.fold<double>(0, (sum, value) => sum + value) / values.length;
    final meanDelta =
        values
            .map((value) => (value - mean).abs())
            .fold<double>(0, (sum, value) => sum + value) /
        values.length;
    final normalized = 1 - (meanDelta / math.max(0.08, mean * 0.9));
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  double _curveSmoothness() {
    final values = _levelHistory.where((value) => value > 0.001).toList();
    if (values.length < 4) {
      return 0;
    }
    var delta = 0.0;
    for (var i = 1; i < values.length; i += 1) {
      delta += (values[i] - values[i - 1]).abs();
    }
    final normalized = 1 - (delta / math.max(0.2, values.length * 0.18));
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  String _noiseLabel(AppI18n i18n) {
    if (_dbfs <= -52) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.quiet_5ada47',
      );
    }
    if (_dbfs <= -38) {
      return i18n.t('toolbox.sleep.support.intensity.moderate');
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory_lab.noisy_fc4f5a',
    );
  }

  String _captureQualityLabel(AppI18n i18n, double score) {
    if (score >= 0.82) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.excellent_9e08fb',
      );
    }
    if (score >= 0.64) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.good_4b6421',
      );
    }
    if (score >= 0.42) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.usable_ca43f3',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory_lab.retest_98b4de',
    );
  }

  String _captureReadiness(AppI18n i18n) {
    if (_switchingInput || _statusCode == 'switching_input') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.switching_to_a_more_compatible_microphone_input_keep_mak_d2374a',
      );
    }
    if (_starting) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.checking_the_microphone_and_live_pcm_stream_5d8e73',
      );
    }
    if (_running) {
      if (!_hasSeenFrame) {
        return i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.recording_has_started_waiting_for_the_first_audio_frame_b69ca5',
        );
      }
      if (_stopwatch.elapsedMilliseconds < 2800) {
        return i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.keep_sampling_at_least_3_seconds_is_recommended_14a30b',
        );
      }
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.the_sample_is_ready_stop_and_add_it_to_the_report_735883',
      );
    }
    if (_statusCode == 'sample_added') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.sample_saved_to_the_report_you_can_move_to_the_next_mode_74ec0c',
      );
    }
    final capture = _captures[_mode];
    if (capture != null) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.this_mode_already_has_a_sample_a_new_run_will_replace_it_c028e0',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory_lab.choose_a_mode_start_sampling_then_add_it_to_the_acoustic_1de8c4',
    );
  }

  String _protocolText(AppI18n i18n) {
    return switch (_mode) {
      _MicLabMode.low => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.low_tone_stay_20_30_cm_from_the_mic_hum_steadily_for_3_6_8a8778',
      ),
      _MicLabMode.high => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.high_tone_hold_a_comfortable_high_tone_for_3_6_seconds_w_529b3a',
      ),
      _MicLabMode.sustain => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.sustain_hold_a_comfortable_pitch_for_5_seconds_the_repor_b8a178',
      ),
      _MicLabMode.noise => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.noise_keep_the_room_quiet_for_5_seconds_to_capture_the_r_d1ddf5',
      ),
    };
  }

  String _statusLabel(AppI18n i18n) {
    if (_switchingInput || _statusCode == 'switching_input') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.switching_input_4a93e8',
      );
    }
    if (_starting) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.starting_2d4107',
      );
    }
    if (_running && !_hasSeenFrame) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.waiting_for_audio_693144',
      );
    }
    if (_running) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.sampling_aca32f',
      );
    }
    if (_error != null) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.needs_attention_cb8534',
      );
    }
    if (_statusCode == 'sample_added') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.saved_147d6b',
      );
    }
    return i18n.t('timerIdle');
  }

  String _profileLabel(AppI18n i18n) {
    final profile = _activeRecorderProfileId;
    if (profile == null) {
      return i18n.t('toolbox.sleep.winddown.notStarted');
    }
    if (profile.contains('unprocessed')) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.raw_mic_3b77de',
      );
    }
    if (profile.contains('default')) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.auto_input_eb1c12',
      );
    }
    if (profile.contains('voice_recognition')) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.compat_mode_da4b80',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory_lab.standard_mic_eb364e',
    );
  }

  String _inputLabel(AppI18n i18n) {
    final label = _inputDeviceLabel;
    if (label != null && label.trim().isNotEmpty) {
      return label;
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory_lab.default_input_087701',
    );
  }

  String _formatFirstFrame(AppI18n i18n) {
    final firstFrameMs = _firstFrameMs;
    if (firstFrameMs == null) {
      return _hasSeenFrame
          ? '< 1 ms'
          : i18n.t('inline.plan295.life.waiting.22b93486ae77');
    }
    return '$firstFrameMs ms';
  }

  String _errorMessage(AppI18n i18n) {
    final error = _error;
    if (error == 'microphone_permission_denied') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.microphone_permission_was_denied_allow_microphone_access_84fc50',
      );
    }
    if (error == 'pcm_stream_not_supported') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.this_platform_does_not_support_live_pcm_streaming_so_aco_329a1c',
      );
    }
    if (error == 'no_pcm_frames') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.recording_started_but_no_audio_frames_arrived_check_micr_d37229',
      );
    }
    if (error == 'silent_input') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.the_microphone_stream_only_returned_digital_silence_avai_46a026',
      );
    }
    if (error == 'capture_too_short') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.the_sample_is_too_short_capture_at_least_3_seconds_befor_590c81',
      );
    }
    return error ?? '';
  }

  String? _profileNoticeMessage(AppI18n i18n) {
    final code = _profileNoticeCode;
    if (code == null) {
      return null;
    }
    if (code == 'exhausted_digital_silence') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.all_available_inputs_were_tried_but_only_silence_came_th_71dc3c',
      );
    }
    if (code == 'exhausted_no_pcm_frames') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.all_available_inputs_were_tried_but_no_audio_frames_arri_b5ecb3',
      );
    }
    if (code == 'digital_silence') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.the_previous_input_started_but_returned_silence_so_the_l_3c77b1',
      );
    }
    if (code == 'no_pcm_frames') {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.the_previous_input_delivered_no_audio_frames_so_the_next_35e89c',
      );
    }
    return null;
  }

  String _reportSummary(AppI18n i18n) {
    if (_captures.isEmpty) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.no_samples_yet_start_with_ambient_noise_then_low_tone_hi_894cb4',
      );
    }
    final averageScore =
        _captures.values.fold<double>(
          0,
          (sum, capture) => sum + capture.qualityScore,
        ) /
        _captures.length;
    final best = _captures.values.reduce(
      (a, b) => a.qualityScore >= b.qualityScore ? a : b,
    );
    final weakest = _captures.values.reduce(
      (a, b) => a.qualityScore <= b.qualityScore ? a : b,
    );
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory_lab.captures_length_4_modes_complete_overall_quality_capture_2d49a7',
      params: <String, Object?>{
        'captures': _captures.length,
        'captureQualityLabelAverageScore': _captureQualityLabel(
          i18n,
          averageScore,
        ),
        'bestModeLabel': _modeSpecs[best.mode]!.label(i18n),
        'weakestModeLabel': _modeSpecs[weakest.mode]!.label(i18n),
      },
    );
  }

  String _recommendedNextStep(AppI18n i18n) {
    if (!_captures.containsKey(_MicLabMode.noise)) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.next_measure_the_noise_meter_first_to_establish_the_room_b38a82',
      );
    }
    for (final mode in <_MicLabMode>[
      _MicLabMode.low,
      _MicLabMode.high,
      _MicLabMode.sustain,
    ]) {
      if (!_captures.containsKey(mode)) {
        return i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.next_capture_modespecs_mode_label_i18n_with_the_same_dis_0c5c6d',
          params: <String, Object?>{
            'modeSpecsModeLabel': _modeSpecs[mode]!.label(i18n),
          },
        );
      }
    }
    final weakest = _captures.values.reduce(
      (a, b) => a.qualityScore <= b.qualityScore ? a : b,
    );
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory_lab.all_four_modes_are_complete_to_improve_comparability_ret_589f75',
      params: <String, Object?>{
        'weakestModeLabel': _modeSpecs[weakest.mode]!.label(i18n),
      },
    );
  }

  String _baselineHint(AppI18n i18n) {
    if (_noiseFloorDbfs != null) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.room_floor_noisefloordbfs_tostringasfixed_1_dbfs_later_s_b81d7e',
        params: <String, Object?>{
          'noiseFloorDbfs': _noiseFloorDbfs!.toStringAsFixed(1),
        },
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory_lab.no_room_floor_yet_measure_noise_first_so_low_high_and_su_f4bd38',
    );
  }

  String _pitchNoteLabel(double frequency) {
    final midi = (69 + 12 * math.log(frequency / 440.0) / math.ln2).round();
    const noteNames = <String>[
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
    final noteName = noteNames[((midi % 12) + 12) % 12];
    final octave = (midi ~/ 12) - 1;
    return '$noteName$octave';
  }

  double? _detectPitch(List<double> samples, int sampleRate) {
    if (samples.length < 2048) {
      return null;
    }
    final window = samples.length > 4096
        ? samples.sublist(samples.length - 4096)
        : List<double>.of(samples);
    final mean =
        window.fold<double>(0, (sum, value) => sum + value) / window.length;
    for (var i = 0; i < window.length; i += 1) {
      window[i] -= mean;
    }

    final minLag = math.max(24, sampleRate ~/ 1000);
    final maxLag = math.min(window.length ~/ 2, sampleRate ~/ 65);
    var bestLag = 0;
    var bestScore = 0.0;
    var secondBestScore = 0.0;

    for (var lag = minLag; lag <= maxLag; lag += 1) {
      var correlation = 0.0;
      var energyA = 0.0;
      var energyB = 0.0;
      for (var i = 0; i < window.length - lag; i += 1) {
        final a = window[i];
        final b = window[i + lag];
        correlation += a * b;
        energyA += a * a;
        energyB += b * b;
      }
      final denominator = math.sqrt(energyA * energyB);
      if (denominator <= 1e-9) {
        continue;
      }
      final score = correlation / denominator;
      if (score > bestScore) {
        secondBestScore = bestScore;
        bestScore = score;
        bestLag = lag;
      } else if (score > secondBestScore) {
        secondBestScore = score;
      }
    }

    if (bestLag == 0 || bestScore < 0.72) {
      return null;
    }
    final refinedLag = _refineLag(window, bestLag);
    final frequency = sampleRate / refinedLag;
    if (frequency < 65 || frequency > 1400) {
      return null;
    }
    if ((bestScore - secondBestScore) < 0.08) {
      return null;
    }
    return frequency;
  }

  double _refineLag(List<double> window, int lag) {
    if (lag <= 1 || lag >= window.length - 1) {
      return lag.toDouble();
    }
    var y0 = 0.0;
    var y1 = 0.0;
    var y2 = 0.0;
    for (var i = 0; i < window.length - lag - 1; i += 1) {
      y0 += window[i] * window[i + lag - 1];
      y1 += window[i] * window[i + lag];
      y2 += window[i] * window[i + lag + 1];
    }
    final denominator = 2 * (y0 - 2 * y1 + y2);
    if (denominator.abs() < 1e-9) {
      return lag.toDouble();
    }
    final offset = (y0 - y2) / denominator;
    return lag + offset;
  }

  String _modeSummary(AppI18n i18n) {
    final spec = _modeSpecs[_mode]!;
    return switch (_mode) {
      _MicLabMode.low => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.target_spec_targetminhz_round_spec_targetmaxhz_round_hz_5c0997',
        params: <String, Object?>{
          'specTargetMinHz': spec.targetMinHz.round(),
          'specTargetMaxHz': spec.targetMaxHz.round(),
        },
      ),
      _MicLabMode.high => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.target_spec_targetminhz_round_spec_targetmaxhz_round_hz_5c0997',
        params: <String, Object?>{
          'specTargetMinHz': spec.targetMinHz.round(),
          'specTargetMaxHz': spec.targetMaxHz.round(),
        },
      ),
      _MicLabMode.sustain => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.hold_steady_for_5_seconds_the_system_reads_sustain_and_v_c6ea24',
      ),
      _MicLabMode.noise => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.stay_quiet_and_read_the_ambient_floor_and_peaks_751f50',
      ),
    };
  }

  Color _meterColor() {
    if (_mode == _MicLabMode.noise) {
      if (_dbfs <= -52) {
        return const Color(0xFF22C55E);
      }
      if (_dbfs <= -38) {
        return const Color(0xFFF59E0B);
      }
      return const Color(0xFFEF4444);
    }
    if (_pitchStability >= 0.82) {
      return const Color(0xFF22C55E);
    }
    if (_pitchStability >= 0.55) {
      return const Color(0xFF3B82F6);
    }
    return const Color(0xFFF97316);
  }

  Future<void> _showProfessionalReport() async {
    if (!mounted) {
      return;
    }
    final context = this.context;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final captures = Map<_MicLabMode, _MicLabCapture>.from(_captures);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final orderedCaptures = <_MicLabCapture>[
          for (final mode in _MicLabMode.values)
            if (captures[mode] != null) captures[mode]!,
        ];
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_auditory_lab.acoustic_report_20f936',
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey<String>(
                        'acoustic_report_close_button',
                      ),
                      tooltip: i18n.t('inline.plan295.life.close.370fb8697deb'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _reportSummary(i18n),
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_human_tests_auditory_lab.note_phone_and_computer_microphones_vary_by_device_dista_cb6da3',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (orderedCaptures.isEmpty)
                  _HumanPanel(
                    child: Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_auditory_lab.no_samples_yet_complete_at_least_one_mode_and_tap_add_to_6794a6',
                      ),
                    ),
                  )
                else
                  for (final capture in orderedCaptures) ...<Widget>[
                    _AcousticReportCaptureCard(
                      capture: capture,
                      spec: _modeSpecs[capture.mode]!,
                      i18n: i18n,
                      qualityLabel: _captureQualityLabel(
                        i18n,
                        capture.qualityScore,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 6),
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory_lab.retest_tip_if_clipping_is_above_1_pitch_hit_is_below_60_aaacda',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeSelector(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _MicLabMode.values
          .map((mode) {
            final modeSpec = _modeSpecs[mode]!;
            return ChoiceChip(
              avatar: Icon(modeSpec.icon, size: 18),
              label: Text(modeSpec.label(i18n)),
              selected: _mode == mode,
              onSelected: _running || _starting || _switchingInput
                  ? null
                  : (_) => _setMode(mode),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildActionRow(AppI18n i18n) {
    final canReset =
        _running ||
        _starting ||
        _switchingInput ||
        _samples.isNotEmpty ||
        _error != null ||
        _statusCode != null;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.tonalIcon(
          key: const ValueKey<String>('acoustic_start_button'),
          onPressed: _starting || _switchingInput
              ? null
              : _running
              ? _stopMonitoring
              : _startMonitoring,
          icon: Icon(_running ? Icons.stop_rounded : Icons.mic_rounded),
          label: Text(
            _starting || _switchingInput
                ? i18n.t('toolbox.breathing.preparing')
                : _running
                ? i18n.t('stop')
                : i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory_lab.open_mic_0c95cb',
                  ),
          ),
        ),
        FilledButton.icon(
          onPressed: (_running || (!_starting && _samples.length >= 3))
              ? _finishCapture
              : null,
          icon: const Icon(Icons.assignment_turned_in_rounded),
          label: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory_lab.add_to_report_1d2fed',
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _showProfessionalReport,
          icon: const Icon(Icons.summarize_rounded),
          label: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory_lab.acoustic_report_20f936',
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: canReset ? () => unawaited(_resetCurrentRun()) : null,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(i18n.t('appearanceReset')),
        ),
      ],
    );
  }

  List<Widget> _buildCoreMetrics(
    AppI18n i18n,
    String pitchLabel,
    _MicLabCapture? activeCapture,
  ) {
    return <Widget>[
      ToolboxMetricCard(
        label: i18n.t(
          'inline.ui.pages.focus_page_workspace_editor.status_cc59cb',
        ),
        value: _statusLabel(i18n),
      ),
      ToolboxMetricCard(
        label: i18n.t('toolbox.sound.pickup.level'),
        value: '${(_level * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.peak_62e9ba',
        ),
        value: '${(_peak * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.dbfs_768d78',
        ),
        value: _dbfs.toStringAsFixed(1),
      ),
      ToolboxMetricCard(
        label: i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.pitch_bb1d92',
        ),
        value: pitchLabel,
      ),
      ToolboxMetricCard(
        label: i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.stability_c45fda',
        ),
        value: '${(_pitchStability * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.sustain_03fa8b',
        ),
        value: '${(_sustainScore * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.smoothness_22ffe0',
        ),
        value: '${(_lastCurveSmoothness * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.level_hold_a5f198',
        ),
        value: '${(_levelConsistencyScore * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: i18n.t('inline.ui.pages.play_page.ambient_6e3e01'),
        value: '${(_ambientScore * 100).round()}%',
      ),
      ToolboxMetricCard(
        label: i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.zcr_a7b1f2',
        ),
        value: _zeroCrossingRate.toStringAsFixed(3),
      ),
      ToolboxMetricCard(
        label: i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.clipping_3a711c',
        ),
        value: '${(_clippingRatio * 100).toStringAsFixed(1)}%',
      ),
      ToolboxMetricCard(
        label: i18n.t('toolbox.sleep.report.range'),
        value: activeCapture == null
            ? '--'
            : '${activeCapture.dynamicRangeDb.toStringAsFixed(1)} dB',
      ),
    ];
  }

  Widget _buildDiagnostics(AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _preferCompatibilityInput,
          onChanged: _running || _starting || _switchingInput
              ? null
              : (value) => setState(() => _preferCompatibilityInput = value),
          secondary: const Icon(Icons.settings_input_component_rounded),
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory_lab.compatibility_input_first_790687',
            ),
          ),
          subtitle: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory_lab.some_phones_start_a_raw_or_standard_input_with_no_signal_ccc04a',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory_lab.sample_rate_40f6c3',
              ),
              value: _running || _activeRecorderProfileId != null
                  ? '${(_activeSampleRate / 1000).toStringAsFixed(_activeSampleRate % 1000 == 0 ? 0 : 1)} kHz'
                  : '--',
            ),
            ToolboxMetricCard(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory_lab.input_6e272b',
              ),
              value: _inputLabel(i18n),
            ),
            ToolboxMetricCard(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory_lab.stream_7c7440',
              ),
              value: _profileLabel(i18n),
            ),
            ToolboxMetricCard(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory_lab.first_frame_93065c',
              ),
              value: _formatFirstFrame(i18n),
            ),
            ToolboxMetricCard(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory_lab.frames_a0bc28',
              ),
              value: '$_frameCount',
            ),
            ToolboxMetricCard(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory_lab.blank_frames_ce9269',
              ),
              value: '$_emptyChunkCount',
            ),
            ToolboxMetricCard(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory_lab.starts_e37521',
              ),
              value: '$_streamRestartCount',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSamplingGuideSection(
    AppI18n i18n,
    ThemeData theme,
    _MicModeSpec spec,
    Color meterColor,
  ) {
    return _HumanSettingsSection(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.sampling_guide_c8ece1',
      ),
      subtitle: _baselineHint(i18n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _AcousticProtocolPanel(
            icon: spec.icon,
            title: spec.label(i18n),
            protocol: _protocolText(i18n),
            readiness: _captureReadiness(i18n),
            accent: meterColor,
          ),
          const SizedBox(height: 10),
          _AcousticStatusBanner(
            icon: Icons.tips_and_updates_rounded,
            message: i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory_lab.for_low_and_high_modes_keep_one_steady_sound_for_sustain_68803c',
            ),
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsSection(AppI18n i18n) {
    return _HumanSettingsSection(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.capture_diagnostics_9f6b8d',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.check_input_source_first_frame_blank_frames_and_compatib_db035d',
      ),
      initiallyExpanded: _error != null || _profileNoticeCode != null,
      child: _buildDiagnostics(i18n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final spec = _modeSpecs[_mode]!;
    final meterColor = _meterColor();
    final levelPercent =
        (_mode == _MicLabMode.noise
                ? ((_dbfs + 120) / 120).clamp(0.0, 1.0)
                : _level.clamp(0.0, 1.0))
            .toDouble();
    final pitchLabel = _pitchHz == null
        ? '--'
        : '${_pitchHz!.toStringAsFixed(1)} Hz · ${_pitchNoteLabel(_pitchHz!)}';
    final activeCapture = _captures[_mode];
    final error = _error == null ? null : _errorMessage(i18n);
    final profileNotice = _profileNoticeMessage(i18n);
    return _HumanPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildModeSelector(i18n),
          const SizedBox(height: 12),
          _buildSamplingGuideSection(i18n, theme, spec, meterColor),
          const SizedBox(height: 10),
          _buildDiagnosticsSection(i18n),
          const SizedBox(height: 12),
          _AcousticLiveStage(
            icon: spec.icon,
            title: spec.label(i18n),
            subtitle: spec.description(i18n),
            summary: _modeSummary(i18n),
            status: _statusLabel(i18n),
            readiness: _captureReadiness(i18n),
            primaryValue: _hasSeenFrame
                ? '${_dbfs.toStringAsFixed(1)} dBFS'
                : '-- dBFS',
            secondaryValue: _mode == _MicLabMode.noise
                ? _noiseLabel(i18n)
                : pitchLabel,
            levelPercent: levelPercent,
            levelCaption: _mode == _MicLabMode.noise
                ? '${_noiseLabel(i18n)} · ${_dbfs.toStringAsFixed(1)} dBFS'
                : _mode == _MicLabMode.sustain
                ? '${(_sustainScore * 100).round()}% · ${(_lastCurveSmoothness * 100).round()}%'
                : '${(_pitchStability * 100).round()}% · ${(_lastCurveSmoothness * 100).round()}%',
            levelHistory: _levelHistory,
            accent: meterColor,
          ),
          if (error != null) ...<Widget>[
            const SizedBox(height: 10),
            _AcousticStatusBanner(
              icon: Icons.error_outline_rounded,
              message: error,
              color: theme.colorScheme.error,
            ),
          ],
          if (profileNotice != null) ...<Widget>[
            const SizedBox(height: 10),
            _AcousticStatusBanner(
              icon: Icons.alt_route_rounded,
              message: profileNotice,
              color: theme.colorScheme.primary,
            ),
          ],
          const SizedBox(height: 12),
          _buildActionRow(i18n),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _buildCoreMetrics(i18n, pitchLabel, activeCapture),
          ),
          if (activeCapture != null) ...<Widget>[
            const SizedBox(height: 10),
            _AcousticCaptureSummary(
              capture: activeCapture,
              label: _captureQualityLabel(i18n, activeCapture.qualityScore),
              accent: meterColor,
            ),
          ],
          const SizedBox(height: 12),
          _AcousticReportSummaryCard(
            summary: _reportSummary(i18n),
            nextStep: _recommendedNextStep(i18n),
            completedText: '${_captures.length}/4',
            onOpen: _showProfessionalReport,
            i18n: i18n,
          ),
        ],
      ),
    );
  }
}

class _AcousticLiveStage extends StatelessWidget {
  const _AcousticLiveStage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.status,
    required this.readiness,
    required this.primaryValue,
    required this.secondaryValue,
    required this.levelPercent,
    required this.levelCaption,
    required this.levelHistory,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String summary;
  final String status;
  final String readiness;
  final String primaryValue;
  final String secondaryValue;
  final double levelPercent;
  final String levelCaption;
  final List<double> levelHistory;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _HumanPill(text: status, accent: accent),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _HumanPill(text: readiness, accent: accent),
              _HumanPill(
                text: secondaryValue,
                accent: accent.withValues(alpha: 0.78),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final chartHeight = compact ? 92.0 : 110.0;
              return Column(
                children: <Widget>[
                  SizedBox(
                    height: chartHeight,
                    child: CustomPaint(
                      painter: _MicLevelHistoryPainter(
                        levelHistory: levelHistory,
                        accent: accent,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: levelPercent,
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        levelCaption,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            primaryValue,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            secondaryValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcousticReportSummaryCard extends StatelessWidget {
  const _AcousticReportSummaryCard({
    required this.summary,
    required this.nextStep,
    required this.completedText,
    required this.onOpen,
    required this.i18n,
  });

  final String summary;
  final String nextStep;
  final String completedText;
  final VoidCallback onOpen;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory_lab.acoustic_report_20f936',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _HumanPill(text: completedText, accent: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 10),
          _HumanPill(text: nextStep, accent: colorScheme.secondary),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onOpen,
              icon: const Icon(Icons.summarize_rounded),
              label: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.acoustic_report_20f936',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcousticStatusBanner extends StatelessWidget {
  const _AcousticStatusBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicLevelHistoryPainter extends CustomPainter {
  const _MicLevelHistoryPainter({
    required this.levelHistory,
    required this.accent,
  });

  final List<double> levelHistory;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      background,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i += 1) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fill = Path();
    final count = levelHistory.length;
    for (var i = 0; i < count; i += 1) {
      final level = levelHistory[i].clamp(0.0, 1.0);
      final x = count <= 1 ? 0.0 : size.width * i / (count - 1);
      final y = size.height - (level * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          accent.withValues(alpha: 0.34),
          accent.withValues(alpha: 0.02),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fill, fillPaint);

    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MicLevelHistoryPainter oldDelegate) {
    return oldDelegate.levelHistory != levelHistory ||
        oldDelegate.accent != accent;
  }
}

class _AcousticProtocolPanel extends StatelessWidget {
  const _AcousticProtocolPanel({
    required this.icon,
    required this.title,
    required this.protocol,
    required this.readiness,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String protocol;
  final String readiness;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  protocol,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  readiness,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
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

class _AcousticCaptureSummary extends StatelessWidget {
  const _AcousticCaptureSummary({
    required this.capture,
    required this.label,
    required this.accent,
  });

  final _MicLabCapture capture;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Text(
        '${capture.seconds.toStringAsFixed(1)} s · '
        '${capture.averageDbfs.toStringAsFixed(1)} dBFS · '
        '${(capture.qualityScore * 100).round()}% · $label',
        style: theme.textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AcousticReportCaptureCard extends StatelessWidget {
  const _AcousticReportCaptureCard({
    required this.capture,
    required this.spec,
    required this.i18n,
    required this.qualityLabel,
  });

  final _MicLabCapture capture;
  final _MicModeSpec spec;
  final AppI18n i18n;
  final String qualityLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _qualityColor(capture.qualityScore);
    final pitch = capture.averagePitchHz == null
        ? '--'
        : '${capture.averagePitchHz!.toStringAsFixed(1)} Hz';
    final snr = capture.snrDb == null
        ? '--'
        : '${capture.snrDb!.toStringAsFixed(1)} dB';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(spec.icon, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  spec.label(i18n),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _HumanPill(text: qualityLabel, accent: accent),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxMetricCard(
                label: i18n.t('inline.plan294.breathing.duration_7b90564f'),
                value: '${capture.seconds.toStringAsFixed(1)} s',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.mean_cff00a',
                ),
                value: '${capture.averageDbfs.toStringAsFixed(1)} dBFS',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.peak_62e9ba',
                ),
                value: '${capture.peakDbfs.toStringAsFixed(1)} dBFS',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.pitch_bb1d92',
                ),
                value: pitch,
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.pitch_sd_76ff97',
                ),
                value: '${capture.pitchStdDevHz.toStringAsFixed(1)} Hz',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.target_hit_82f8a9',
                ),
                value: '${(capture.targetHitRatio * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.snr_fc3bf4',
                ),
                value: snr,
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.voiced_932dff',
                ),
                value: '${(capture.voicedRatio * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: i18n.t('toolbox.sleep.report.range'),
                value: '${capture.dynamicRangeDb.toStringAsFixed(1)} dB',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.crest_6868de',
                ),
                value: '${capture.crestFactorDb.toStringAsFixed(1)} dB',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.clipping_3a711c',
                ),
                value: '${(capture.clippingRatio * 100).toStringAsFixed(1)}%',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.blank_06d198',
                ),
                value: '${(capture.emptyChunkRatio * 100).toStringAsFixed(1)}%',
              ),
              ToolboxMetricCard(
                label: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.frames_a0bc28',
                ),
                value: '${capture.sampleCount}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _interpretation(i18n, capture),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Color _qualityColor(double score) {
    if (score >= 0.82) {
      return const Color(0xFF16A34A);
    }
    if (score >= 0.64) {
      return const Color(0xFF2563EB);
    }
    if (score >= 0.42) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFDC2626);
  }

  String _interpretation(AppI18n i18n, _MicLabCapture capture) {
    if (capture.mode == _MicLabMode.noise) {
      if (capture.averageDbfs <= -52) {
        return i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory_lab.the_ambient_noise_floor_is_low_suitable_as_a_reference_e_6f4708',
        );
      }
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.ambient_noise_is_elevated_and_may_reduce_later_snr_and_p_88cc39',
      );
    }
    if (capture.clippingRatio > 0.01) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.clipping_risk_is_present_suggesting_the_input_is_too_lou_faa6c1',
      );
    }
    if (capture.targetHitRatio < 0.55) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.pitch_target_hit_ratio_is_low_retest_with_a_steadier_sin_74457e',
      );
    }
    if (capture.pitchStability >= 0.78 && capture.levelConsistency >= 0.66) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory_lab.pitch_and_level_are_stable_this_sample_is_strong_enough_3a9f53',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory_lab.the_sample_is_usable_but_pitch_or_level_still_fluctuates_56c88f',
    );
  }
}
