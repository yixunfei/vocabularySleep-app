part of '../toolbox_sound_tools.dart';

// ignore_for_file: dead_code, unused_element, unused_local_variable

extension _FocusBeatsToolStateStageVisualX on _FocusBeatsToolState {
  Color _animationAccent(_FocusBeatAnimationKind kind) {
    return switch (kind) {
      _FocusBeatAnimationKind.pendulum => const Color(0xFFD7A86B),
      _FocusBeatAnimationKind.hypno => const Color(0xFF7E90F2),
      _FocusBeatAnimationKind.dew => const Color(0xFF59C6C0),
      _FocusBeatAnimationKind.gear => const Color(0xFF95A6C2),
      _FocusBeatAnimationKind.steps => const Color(0xFF78BC8E),
    };
  }

  Color _soundAccent(_FocusBeatSoundKind kind) {
    return switch (kind) {
      _FocusBeatSoundKind.pendulum => const Color(0xFFC68F58),
      _FocusBeatSoundKind.hypno => const Color(0xFF6E84E8),
      _FocusBeatSoundKind.dew => const Color(0xFF4AB4D6),
      _FocusBeatSoundKind.gear => const Color(0xFF8FA0B8),
      _FocusBeatSoundKind.steps => const Color(0xFF84B56A),
    };
  }

  _FocusVisualPalette _visualPalette(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = Color.lerp(
      _animationAccent(_animationKind),
      colorScheme.primary,
      0.22,
    )!;
    return _FocusVisualPalette(
      accent: accent,
      accentSoft: Color.lerp(accent, Colors.white, 0.72)!,
      accentGlow: accent.withValues(alpha: 0.42),
      stageTop: Color.lerp(const Color(0xFF08131F), accent, 0.30)!,
      stageMid: Color.lerp(const Color(0xFF102034), accent, 0.16)!,
      stageBottom: Color.lerp(const Color(0xFF040B14), accent, 0.12)!,
      panel: colorScheme.surface.withValues(alpha: 0.92),
      panelStrong: colorScheme.surfaceContainerHighest.withValues(alpha: 0.94),
      stroke: Color.lerp(colorScheme.outlineVariant, accent, 0.34)!,
    );
  }

  Widget _buildStage(BuildContext context) {
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
        border: Border.all(color: palette.stroke.withValues(alpha: 0.72)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.accentGlow.withValues(alpha: 0.24),
            blurRadius: 42,
            offset: const Offset(0, 22),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 18),
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
              Positioned(
                left: -48,
                top: -36,
                child: _FocusGlowOrb(
                  size: 180,
                  color: palette.accentGlow.withValues(alpha: 0.24),
                ),
              ),
              Positioned(
                right: -72,
                bottom: -86,
                child: _FocusGlowOrb(
                  size: 220,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.06),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.18),
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
                    const _FocusStageBadge(
                      icon: Icons.blur_on_rounded,
                      label: 'Focus Studio',
                    ),
                    _FocusStageBadge(
                      icon: _animationKind.icon,
                      label: _animationLabel(_animationKind),
                    ),
                    _FocusStageBadge(
                      icon: _soundKind.icon,
                      label: _soundLabel(_soundKind),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.26),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          beatLabel,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (_subdivision > 1) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            'Sub $subLabel',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _running ? '节拍运行中' : '等待开始',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _animationLabel(_animationKind),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _running
                                      ? _animationSyncHint(_animationKind)
                                      : _animationDescription(_animationKind),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.82,
                                        ),
                                        height: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: palette.accentSoft.withValues(
                                  alpha: 0.34,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Cycle',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: palette.accentSoft,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cycleLabel,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildStagePulseRail(context, palette),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          _FocusStageBadge(
                            icon: Icons.timeline_rounded,
                            label: '编排 $arrangementLabel',
                          ),
                          _FocusStageBadge(
                            icon: Icons.layers_rounded,
                            label: '段落 $segmentLabel',
                          ),
                          _FocusStageBadge(
                            icon: Icons.touch_app_rounded,
                            label: _hapticsEnabled ? '触感已启用' : '触感已关闭',
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
    final activeBeat = _activeBeat;
    final activeSub = _activeSubPulse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (var index = 0; index < _beatsPerBar; index += 1)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == _beatsPerBar - 1 ? 0 : 8,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: index == activeBeat
                            ? <Color>[
                                palette.accentSoft.withValues(alpha: 0.96),
                                palette.accent.withValues(alpha: 0.92),
                              ]
                            : <Color>[
                                Colors.white.withValues(
                                  alpha: index == 0 ? 0.20 : 0.12,
                                ),
                                Colors.white.withValues(alpha: 0.04),
                              ],
                      ),
                      border: Border.all(
                        color: index == activeBeat
                            ? palette.accentSoft.withValues(alpha: 0.78)
                            : Colors.white.withValues(
                                alpha: index == 0 ? 0.22 : 0.10,
                              ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: index == activeBeat
                              ? const Color(0xFF09111B)
                              : Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_subdivision > 1) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (var index = 0; index < _subdivision; index += 1)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: activeSub == index + 1 ? 26 : 14,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: activeSub == index + 1
                        ? palette.accentSoft
                        : Colors.white.withValues(alpha: 0.18),
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
              '${pickUiText(previewI18n, zh: '段', en: 'S')}${index + 1} · ${previewSegmentBeats[index]} ${pickUiText(previewI18n, zh: '拍', en: 'beats')} · '
              '${_focusBarsLabel(previewSegmentBeats[index] / _beatsPerBar)}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
    );

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
    final segmentBeats = _patternError.isEmpty
        ? _arrangementBeats
        : <int>[_beatsPerBar];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (var index = 0; index < segmentBeats.length; index += 1)
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
              'S${index + 1} · ${segmentBeats[index]}拍 · '
              '${_focusBarsLabel(segmentBeats[index] / _beatsPerBar)}',
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
                  ? pickUiText(i18n, zh: '正在跟拍', en: 'In motion')
                  : pickUiText(i18n, zh: '待启动', en: 'Ready'),
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
              ? pickUiText(
                  i18n,
                  zh: '舞台、发音与触感已经对齐，保持呼吸或动作跟着当前拍点推进。',
                  en: 'Stage, clicks, and haptics are aligned. Let your motion follow the current beat.',
                )
              : pickUiText(
                  i18n,
                  zh: '首屏只保留开始、节奏和舞台，其他设置折叠到下方，适合手机单手快速进入状态。',
                  en: 'The first screen keeps only start, rhythm, and stage so it is faster to enter flow on a phone.',
                ),
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
        border: Border.all(color: palette.stroke.withValues(alpha: 0.60)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.accentGlow.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
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
                        Colors.white.withValues(alpha: 0.04),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.14),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: _FocusStageBadge(
                  icon: Icons.speed_rounded,
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
                      ? pickUiText(i18n, zh: '运行中', en: 'Running')
                      : pickUiText(i18n, zh: '待启动', en: 'Ready'),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
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
    final activeBeat = _activeBeat >= 0 ? _activeBeat : 0;
    final activeSub = _activeSubPulse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            for (var index = 0; index < _beatsPerBar; index += 1)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == _beatsPerBar - 1 ? 0 : 8,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    height: index == activeBeat ? 12 : 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: index == activeBeat
                          ? palette.accentSoft
                          : Colors.white.withValues(
                              alpha: index == 0 ? 0.28 : 0.14,
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_subdivision > 1) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              for (var index = 0; index < _subdivision; index += 1)
                Padding(
                  padding: EdgeInsets.only(
                    right: index == _subdivision - 1 ? 0 : 6,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    width: activeSub == index + 1 ? 16 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: activeSub == index + 1
                          ? palette.accent
                          : Colors.white.withValues(alpha: 0.18),
                    ),
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
        Text(
          pickUiText(i18n, zh: '循环', en: 'Loop'),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
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
                            : Colors.white.withValues(alpha: 0.14),
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
        color: Colors.black,
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
                        Colors.black.withValues(alpha: 0.10),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.16),
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
                                icon: Icons.speed_rounded,
                                label:
                                    '$_bpm BPM · $_beatsPerBar/4 × $_subdivision',
                              ),
                              const Spacer(),
                              IconButton.filledTonal(
                                tooltip: pickUiText(
                                  immersiveI18n,
                                  zh: '唤起控制',
                                  en: 'Open controls',
                                ),
                                onPressed: _openImmersiveControlsSheet,
                                icon: const Icon(Icons.tune_rounded),
                              ),
                              if (widget.onExitFullScreen != null) ...<Widget>[
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  tooltip: pickUiText(
                                    immersiveI18n,
                                    zh: '退出全屏',
                                    en: 'Exit full screen',
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
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                      foregroundColor: Colors.white,
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
                                            ? pickUiText(
                                                immersiveI18n,
                                                zh: '当前拍点 $immersiveBeatLabel',
                                                en: 'Beat $immersiveBeatLabel',
                                              )
                                            : pickUiText(
                                                immersiveI18n,
                                                zh: '准备开始',
                                                en: 'Ready',
                                              ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        pickUiText(
                                          immersiveI18n,
                                          zh: '轻触显示控件，上滑打开完整菜单',
                                          en: 'Tap for HUD, swipe up for full controls',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white.withValues(
                                                alpha: 0.76,
                                              ),
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

    return ColoredBox(
      color: Colors.black,
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
          Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Wrap(
                  spacing: 8,
                  children: <Widget>[
                    IconButton.filledTonal(
                      tooltip: '退出沉浸',
                      onPressed: _toggleImmersiveMode,
                      icon: const Icon(Icons.fullscreen_exit_rounded),
                    ),
                    if (widget.onExitFullScreen != null)
                      IconButton.filledTonal(
                        tooltip: '退出全屏',
                        onPressed: widget.onExitFullScreen,
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
