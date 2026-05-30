part of '../toolbox_sound_tools.dart';

// ignore_for_file: dead_code, unused_element, unused_local_variable

extension _FocusBeatsToolStateStageVisualX on _FocusBeatsToolState {
  Color _animationAccent(_FocusBeatAnimationKind kind) {
    return const Color(0xFFE5D8C8);
  }

  _FocusVisualPalette _visualPalette(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _animationAccent(_animationKind);
    return _FocusVisualPalette(
      accent: accent,
      accentSoft: const Color(0xFFFFFBF5),
      accentGlow: const Color(0xFFD6C5B5).withValues(alpha: 0.24),
      stageTop: const Color(0xFFF9F5EE),
      stageMid: const Color(0xFFE9DED1),
      stageBottom: const Color(0xFFD5C5B4),
      panel: colorScheme.surface.withValues(alpha: 0.96),
      panelStrong: Color.lerp(
        colorScheme.surface,
        const Color(0xFFFFFBF5),
        0.58,
      )!,
      stroke: const Color(0xFFC7B8A8),
    );
  }

  Widget _buildStage(BuildContext context) {
    final i18n = _i18nOf(context);
    final palette = _visualPalette(context);
    final beatLabel = _activeBeat < 0 ? '--' : '${_activeBeat + 1}';
    final subLabel = _activeSubPulse == 0
        ? '--'
        : '$_activeSubPulse/$_subdivision';
    final segmentLabel = _patternEnabled && _patternError.isEmpty
        ? '${_currentSegmentIndex + 1}/${_segmentPulseCounts.length}'
        : '1/1';
    final cycleLabel = '${_cycleCount + 1}';
    final arrangementLabel = _patternError.isEmpty ? _pattern.raw : '1bar';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final stageHeight = widget.fullScreen
        ? (screenWidth * 0.64).clamp(340.0, 470.0)
        : (screenWidth * 0.74).clamp(320.0, 430.0);
    return Container(
      width: double.infinity,
      height: stageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.stageTop,
            palette.stageMid,
            palette.stageBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(widget.fullScreen ? 30 : 28),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.46)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.accentGlow.withValues(alpha: 0.16),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _pulseController,
          _ambientController,
        ]),
        builder: (context, _) {
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                        const Color(0xFF9E8D7C).withValues(alpha: 0.08),
                      ],
                      stops: const <double>[0.0, 0.38, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _FocusBeatVisualizerPainter(
                    kind: _animationKind,
                    bpm: _bpm,
                    pulseProgress: _pulseController.value,
                    ambientProgress: _ambientController.value,
                    accentLayer: _lastLayer,
                    running: _running,
                    activeBeat: _activeBeat,
                    activeSubPulse: _activeSubPulse,
                    beatsPerBar: _beatsPerBar,
                    subdivision: _subdivision,
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 18,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _FocusStageBadge(
                      icon: Icons.route_rounded,
                      label: i18n.t('toolbox.sound.focus.stageBeatPath'),
                    ),
                    _FocusStageBadge(
                      icon: _soundKind.icon,
                      label: _soundName(context, _soundKind),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _focusStagePalePanel.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.58),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _activeBeat < 0 ? '--' : '$beatLabel/$_beatsPerBar',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: _focusStagePaleInk,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (_subdivision > 1) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            i18n.t(
                              'toolbox.sound.focus.stageSubbeat',
                              params: {'label': subLabel},
                            ),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: _focusStagePaleMutedInk,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _running
                              ? i18n.t('toolbox.sound.focus.stageMoving')
                              : i18n.t('toolbox.sound.focus.stageReady'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: _focusStagePaleMutedInk),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: _focusStagePalePanel.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.54),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _FocusStageBadge(
                            icon: _running
                                ? Icons.graphic_eq_rounded
                                : Icons.motion_photos_paused_rounded,
                            label: _running
                                ? i18n.t(
                                    'toolbox.sound.focus.stagePulseInMotion',
                                  )
                                : i18n.t(
                                    'toolbox.sound.focus.stageWaitingBeatOne',
                                  ),
                          ),
                          const Spacer(),
                          _FocusStageBadge(
                            icon: Icons.repeat_rounded,
                            label: i18n.t(
                              'toolbox.sound.focus.stageCycleLabel',
                              params: {'label': cycleLabel},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStagePulseRail(context, palette),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _FocusStageBadge(
                            icon: Icons.timeline_rounded,
                            label: i18n.t(
                              'toolbox.sound.focus.stagePatternLabel',
                              params: {'label': arrangementLabel},
                            ),
                          ),
                          _FocusStageBadge(
                            icon: Icons.layers_rounded,
                            label: i18n.t(
                              'toolbox.sound.focus.stagePhraseLabel',
                              params: {'label': segmentLabel},
                            ),
                          ),
                          _FocusStageBadge(
                            icon: Icons.touch_app_rounded,
                            label: _hapticsEnabled
                                ? i18n.t('toolbox.sound.focus.stageHapticsOn')
                                : i18n.t('toolbox.sound.focus.stageHapticsOff'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStagePulseRail(
    BuildContext context,
    _FocusVisualPalette palette,
  ) {
    final i18n = _i18nOf(context);
    final activeBeat = _activeBeat >= 0 ? _activeBeat : -1;
    final activeSub = _activeSubPulse;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: _focusStagePaleMutedInk,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 42,
              child: Text(
                i18n.t('toolbox.sound.focus.stageBeatLabel'),
                style: labelStyle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: <Widget>[
                  for (var index = 0; index < _beatsPerBar; index += 1)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == _beatsPerBar - 1 ? 0 : 6,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          height: index == activeBeat ? 30 : 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: index == activeBeat
                                  ? <Color>[
                                      palette.accentSoft.withValues(
                                        alpha: 0.98,
                                      ),
                                      palette.accent.withValues(alpha: 0.88),
                                    ]
                                  : <Color>[
                                      _focusStagePaleMutedInk.withValues(
                                        alpha: index == 0 ? 0.18 : 0.10,
                                      ),
                                      _focusStagePaleMutedInk.withValues(
                                        alpha: 0.045,
                                      ),
                                    ],
                            ),
                            border: Border.all(
                              color: index == activeBeat
                                  ? palette.stroke.withValues(alpha: 0.38)
                                  : _focusStagePaleMutedInk.withValues(
                                      alpha: index == 0 ? 0.18 : 0.08,
                                    ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: index == activeBeat
                                        ? _focusStagePaleInk
                                        : _focusStagePaleMutedInk.withValues(
                                            alpha: 0.72,
                                          ),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
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
        if (_subdivision > 1) ...<Widget>[
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 42,
                child: Text(
                  i18n.t('toolbox.sound.focus.stageSubLabel'),
                  style: labelStyle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: <Widget>[
                    for (var index = 0; index < _subdivision; index += 1)
                      Padding(
                        padding: EdgeInsets.only(
                          right: index == _subdivision - 1 ? 0 : 7,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          width: activeSub == index + 1 ? 28 : 12,
                          height: 9,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: activeSub == index + 1
                                ? palette.accentSoft
                                : _focusStagePaleMutedInk.withValues(
                                    alpha: 0.18,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPatternPreview(BuildContext context) {
    final previewI18n = _i18nOf(context);
    if (_patternEnabled && _patternError.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _patternError,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      );
    }
    final previewSegmentBeats = _patternError.isEmpty
        ? _arrangementBeats
        : <int>[_beatsPerBar];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (var index = 0; index < previewSegmentBeats.length; index += 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _running && index == _currentSegmentIndex
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _running && index == _currentSegmentIndex
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              '${previewI18n.t('toolbox.sound.focus.stageSegmentS')}${index + 1} · ${previewSegmentBeats[index]} ${previewI18n.t('toolbox.sound.focus.stageBeatsUnit')} · '
              '${_focusBarsLabel(previewSegmentBeats[index] / _beatsPerBar)}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildStudioSummaryStrip(BuildContext context) {
    final i18n = _i18nOf(context);
    final arrangementLabel = _patternError.isEmpty ? _pattern.raw : '1bar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _FocusInfoPill(
              icon: _running
                  ? Icons.graphic_eq_rounded
                  : Icons.motion_photos_paused_rounded,
              label: _running
                  ? i18n.t('toolbox.sound.focus.stagePulseMoving')
                  : i18n.t('toolbox.sound.focus.stageTrackReady'),
              emphasized: _running,
              tone: _visualPalette(context).accent,
            ),
            _FocusInfoPill(icon: Icons.speed_rounded, label: '$_bpm BPM'),
            _FocusInfoPill(
              icon: Icons.music_note_rounded,
              label: '$_beatsPerBar/4 × $_subdivision',
            ),
            _FocusInfoPill(
              icon: Icons.view_timeline_rounded,
              label: arrangementLabel,
              emphasized: _patternEnabled,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _running
              ? i18n.t('toolbox.sound.focus.stageSummaryRunning')
              : i18n.t('toolbox.sound.focus.stageSummaryIdle'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildStageCompact(BuildContext context) {
    final i18n = _i18nOf(context);
    final palette = _visualPalette(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final stageHeight = (screenWidth * 0.92).clamp(320.0, 420.0);
    return Container(
      width: double.infinity,
      height: stageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.stageTop,
            palette.stageMid,
            palette.stageBottom,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.42)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.accentGlow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _pulseController,
          _ambientController,
        ]),
        builder: (context, _) {
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _FocusBeatVisualizerPainter(
                    kind: _animationKind,
                    bpm: _bpm,
                    pulseProgress: _pulseController.value,
                    ambientProgress: _ambientController.value,
                    accentLayer: _lastLayer,
                    running: _running,
                    activeBeat: _activeBeat,
                    activeSubPulse: _activeSubPulse,
                    beatsPerBar: _beatsPerBar,
                    subdivision: _subdivision,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.10),
                        Colors.transparent,
                        const Color(0xFF9E8D7C).withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: _FocusStageBadge(
                  icon: Icons.route_rounded,
                  label: '$_bpm BPM · $_beatsPerBar/4 × $_subdivision',
                ),
              ),
              Positioned(
                right: 16,
                top: 16,
                child: _FocusStageBadge(
                  icon: _running
                      ? Icons.graphic_eq_rounded
                      : Icons.motion_photos_paused_rounded,
                  label: _running
                      ? i18n.t('toolbox.sound.focus.stageMoving')
                      : i18n.t('toolbox.sound.focus.stageReady'),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  decoration: BoxDecoration(
                    color: _focusStagePalePanel.withValues(alpha: 0.64),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.54),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildStagePulseRailCompact(context, palette),
                      const SizedBox(height: 10),
                      _buildStageArrangementDots(context, palette),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStagePulseRailCompact(
    BuildContext context,
    _FocusVisualPalette palette,
  ) {
    final i18n = _i18nOf(context);
    final activeBeat = _activeBeat >= 0 ? _activeBeat : -1;
    final activeSub = _activeSubPulse;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: _focusStagePaleMutedInk,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            SizedBox(
              width: 34,
              child: Text(
                i18n.t('toolbox.sound.focus.stageBeatShort'),
                style: labelStyle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: <Widget>[
                  for (var index = 0; index < _beatsPerBar; index += 1)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == _beatsPerBar - 1 ? 0 : 6,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          height: index == activeBeat ? 13 : 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: index == activeBeat
                                ? palette.accentSoft
                                : _focusStagePaleMutedInk.withValues(
                                    alpha: index == 0 ? 0.20 : 0.12,
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
        if (_subdivision > 1) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              SizedBox(
                width: 34,
                child: Text(
                  i18n.t('toolbox.sound.focus.stageSubShort'),
                  style: labelStyle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: <Widget>[
                    for (var index = 0; index < _subdivision; index += 1)
                      Padding(
                        padding: EdgeInsets.only(
                          right: index == _subdivision - 1 ? 0 : 6,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          curve: Curves.easeOutCubic,
                          width: activeSub == index + 1 ? 18 : 8,
                          height: 7,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: activeSub == index + 1
                                ? palette.accent
                                : _focusStagePaleMutedInk.withValues(
                                    alpha: 0.16,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStageArrangementDots(
    BuildContext context,
    _FocusVisualPalette palette,
  ) {
    final i18n = _i18nOf(context);
    final segments = _patternEnabled && _patternError.isEmpty
        ? _arrangementBeats
        : <int>[_beatsPerBar];
    return Row(
      children: <Widget>[
        SizedBox(
          width: 34,
          child: Text(
            i18n.t('toolbox.sound.focus.stageLoopLabel'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _focusStagePaleMutedInk,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: <Widget>[
              for (var index = 0; index < segments.length; index += 1)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == segments.length - 1 ? 0 : 6,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      height: index == _currentSegmentIndex ? 10 : 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: index == _currentSegmentIndex
                            ? palette.accent
                            : _focusStagePaleMutedInk.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImmersiveAnimationOnly(BuildContext context) {
    final immersiveI18n = _i18nOf(context);
    final immersiveBeatLabel = _activeBeat < 0
        ? '--'
        : '${_activeBeat + 1}/$_beatsPerBar';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleImmersiveHud,
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -180) {
          unawaited(_openImmersiveControlsSheet());
        }
      },
      child: ColoredBox(
        color: const Color(0xFFF8F2EA),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[
                  _pulseController,
                  _ambientController,
                ]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _FocusBeatVisualizerPainter(
                      kind: _animationKind,
                      bpm: _bpm,
                      pulseProgress: _pulseController.value,
                      ambientProgress: _ambientController.value,
                      accentLayer: _lastLayer,
                      running: _running,
                      activeBeat: _activeBeat,
                      activeSubPulse: _activeSubPulse,
                      beatsPerBar: _beatsPerBar,
                      subdivision: _subdivision,
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        const Color(0xFF9E8D7C).withValues(alpha: 0.05),
                        Colors.transparent,
                        const Color(0xFF9E8D7C).withValues(alpha: 0.10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: AnimatedOpacity(
                  opacity: _immersiveHudVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_immersiveHudVisible,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              _FocusStageBadge(
                                icon: Icons.route_rounded,
                                label:
                                    '$_bpm BPM · $_beatsPerBar/4 × $_subdivision',
                              ),
                              const Spacer(),
                              IconButton.filledTonal(
                                tooltip: immersiveI18n.t(
                                  'toolbox.sound.focus.immersiveOpenControls',
                                ),
                                onPressed: _openImmersiveControlsSheet,
                                icon: const Icon(Icons.tune_rounded),
                              ),
                              if (widget.onExitFullScreen != null) ...<Widget>[
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  tooltip: immersiveI18n.t(
                                    'toolbox.sound.focus.immersiveExitFull',
                                  ),
                                  onPressed: widget.onExitFullScreen,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ],
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: _focusStagePalePanel.withValues(
                                  alpha: 0.74,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.58),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: _focusStagePaleMutedInk
                                          .withValues(alpha: 0.12),
                                      foregroundColor: _focusStagePaleInk,
                                    ),
                                    onPressed: _running ? _stop : _start,
                                    icon: Icon(
                                      _running
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _running
                                            ? immersiveI18n.t(
                                                'toolbox.sound.focus.immersiveCurrentBeat',
                                                params: {
                                                  'label': immersiveBeatLabel,
                                                },
                                              )
                                            : immersiveI18n.t(
                                                'toolbox.sound.focus.immersiveReady',
                                              ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: _focusStagePaleInk,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        immersiveI18n.t(
                                          'toolbox.sound.focus.immersiveHint',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: _focusStagePaleMutedInk,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
