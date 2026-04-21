part of 'toolbox_soothing_music_v2_page.dart';

extension _SoothingMusicV2Stage on _SoothingMusicV2PageState {
  Widget _buildStageArea(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required bool compact,
    required double effectBoost,
    required double waveBoost,
  }) {
    final narrow = compact && MediaQuery.of(context).size.width < 430;
    final screenSize = MediaQuery.of(context).size;
    final effectiveCompact = compact && !_fullscreen;
    final playbackActive = _playbackVisualActive;
    final compactVisualBoost = effectiveCompact ? 1.22 : 1.0;
    final bands = _stageBands;
    final playbackGain = playbackActive
        ? (_fullscreen ? 1.58 : 1.28) * compactVisualBoost
        : (effectiveCompact ? 0.92 : 0.82);
    final fullscreenStageTopPadding =
        MediaQuery.of(context).padding.top + (_fullscreen ? 8 : 0);
    final phaseOffset = _currentTrack.seed.toDouble() * 0.013;

    return Column(
      children: <Widget>[
        if (!_fullscreen)
          _buildTrackShelf(i18n, palette: palette, compact: effectiveCompact),
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.08),
                      radius: _fullscreen ? 1.2 : 0.96,
                      colors: <Color>[
                        palette.glowA.withValues(
                          alpha: _fullscreen
                              ? (palette.isDark ? 0.62 : 0.42)
                              : (palette.isDark ? 0.44 : 0.3),
                        ),
                        Colors.transparent,
                      ],
                    ),
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
                        palette.accent.withValues(
                          alpha: _fullscreen
                              ? (palette.isDark ? 0.14 : 0.16)
                              : (palette.isDark ? 0.08 : 0.1),
                        ),
                        Colors.transparent,
                        palette.orbitAccent.withValues(
                          alpha: _fullscreen
                              ? (palette.isDark ? 0.12 : 0.14)
                              : (palette.isDark ? 0.06 : 0.08),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_fullscreen)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, 0),
                          radius: 1.08,
                          colors: <Color>[
                            Colors.white.withValues(
                              alpha: palette.isDark ? 0.08 : 0.05,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: _fullscreen
                    ? 24
                    : compact
                    ? 70
                    : 90,
                child: _GlowBlob(
                  animation: _orbitController,
                  color: palette.glowA,
                  size: _fullscreen
                      ? screenSize.width * 0.72
                      : compact
                      ? 220
                      : 290,
                  seed: 0.18,
                  drift: compact ? 18 : 26,
                ),
              ),
              Positioned(
                right: _fullscreen
                    ? -88
                    : compact
                    ? -38
                    : 112,
                top: _fullscreen
                    ? 36
                    : compact
                    ? 86
                    : 66,
                child: _GlowBlob(
                  animation: _orbitController,
                  color: palette.glowB,
                  size: _fullscreen
                      ? screenSize.width * 0.66
                      : compact
                      ? 210
                      : 270,
                  seed: 1.64,
                  drift: compact ? 16 : 24,
                ),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _SoothingSpectrumPainter(
                      accent: palette.accent,
                      orbitAccent: palette.orbitAccent,
                      orbit: _orbitController,
                      phaseOffset: phaseOffset,
                      bands: bands,
                      barGain:
                          (_mode.id == 'motion'
                              ? 1
                              : _mode.id == 'study' || _mode.id == 'jazz'
                              ? 0.82
                              : 0.56) *
                          effectBoost *
                          playbackGain *
                          compactVisualBoost,
                      particleGain:
                          (_mode.id == 'dreaming'
                              ? 1
                              : _mode.id == 'motion'
                              ? 0.9
                              : _mode.id == 'sleep'
                              ? 0.35
                              : 0.6) *
                          effectBoost *
                          playbackGain *
                          compactVisualBoost,
                      breathingGain:
                          (_mode.id == 'sleep'
                              ? 1
                              : _mode.id == 'music_box' || _mode.id == 'harp'
                              ? 0.86
                              : 0.62) *
                          waveBoost *
                          playbackGain *
                          compactVisualBoost,
                      rippleGain: waveBoost * playbackGain * compactVisualBoost,
                      waveGain:
                          (1.04 + effectBoost * 0.34) *
                          playbackGain *
                          compactVisualBoost *
                          (_mode.id == 'dreaming' ? 1.1 : 1),
                      compact: effectiveCompact,
                      isDark: palette.isDark,
                      fullscreen: _fullscreen,
                      animate: playbackActive,
                    ),
                    child: LayoutBuilder(
                      builder: (context, stageConstraints) {
                        final cramped = stageConstraints.maxHeight < 250;
                        final veryCramped = stageConstraints.maxHeight < 180;
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: _fullscreen ? fullscreenStageTopPadding : 0,
                            ),
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: _fullscreen
                                    ? 16
                                    : compact
                                    ? 24
                                    : 56,
                                vertical: _fullscreen
                                    ? 0
                                    : veryCramped
                                    ? 8
                                    : 18,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: _fullscreen
                                      ? screenSize.width
                                      : compact
                                      ? 460
                                      : 520,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    _buildStageHeaderCluster(
                                      context,
                                      i18n,
                                      palette: palette,
                                      narrow: narrow,
                                      compact: compact,
                                      cramped: cramped,
                                      veryCramped: veryCramped,
                                      screenSize: screenSize,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildBottomControls(
          context,
          i18n,
          palette: palette,
          compact: effectiveCompact,
        ),
      ],
    );
  }

  Widget _buildStageHeaderCluster(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required bool narrow,
    required bool compact,
    required bool cramped,
    required bool veryCramped,
    required Size screenSize,
  }) {
    final double titleSize = _fullscreen
        ? math.min(screenSize.width * 0.16, 76)
        : veryCramped
        ? 26.0
        : cramped
        ? 30.0
        : narrow
        ? 34.0
        : compact
        ? 40.0
        : 54.0;
    final titleColor = palette.isDark ? Colors.white : const Color(0xFF10263A);
    final subtitleText = _mode.subtitle(i18n);
    final trackLabel = _currentTrack.label(i18n);
    final loadingText = _trackLoadText(i18n);
    final errorText = _audioErrorText(i18n);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        _fullscreen ? 18 : 16,
        _fullscreen ? 18 : 16,
        _fullscreen ? 18 : 16,
        _fullscreen ? 16 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            palette.panelSurface.withValues(alpha: _fullscreen ? 0.54 : 0.7),
            palette.panelSurfaceMuted.withValues(
              alpha: _fullscreen ? 0.52 : 0.72,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(_fullscreen ? 28 : 24),
        border: Border.all(
          color: palette.border.withValues(alpha: _fullscreen ? 0.78 : 0.9),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.accent.withValues(
              alpha: palette.isDark ? 0.16 : 0.08,
            ),
            blurRadius: _fullscreen ? 28 : 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoPill(
                icon: _mode.icon,
                label: subtitleText,
                palette: palette,
                accent: palette.accent,
              ),
              _InfoPill(
                icon: Icons.album_rounded,
                label: trackLabel,
                palette: palette,
                accent: palette.orbitAccent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _mode.title(i18n),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              shadows: <Shadow>[
                Shadow(
                  color: palette.accent.withValues(
                    alpha: palette.isDark ? 0.24 : 0.12,
                  ),
                  blurRadius: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _fullscreen ? 18 : 14,
              vertical: _fullscreen ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: palette.panelSurface.withValues(
                alpha: _fullscreen ? 0.66 : 0.82,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: palette.accent.withValues(
                  alpha: _fullscreen ? 0.72 : 0.54,
                ),
              ),
            ),
            child: Text(
              trackLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.accent,
                fontSize: _fullscreen
                    ? math.min(screenSize.width * 0.038, 18)
                    : narrow
                    ? 12
                    : 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!cramped && !_fullscreen) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              _mode.description(i18n),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: narrow ? 12 : 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _mode.footer(i18n),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textSecondary.withValues(alpha: 0.88),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
          if (loadingText != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: palette.panelSurface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    loadingText,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_trackLoadProgress != null) ...<Widget>[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _trackLoadProgress,
                      minHeight: 4,
                      backgroundColor: palette.border.withValues(alpha: 0.3),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (errorText != null) ...<Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: palette.dangerBg.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                errorText,
                style: TextStyle(color: palette.dangerFg, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackShelf(
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, compact ? 10 : 12, 16, 12),
      decoration: BoxDecoration(
        color: palette.panelSurface.withValues(
          alpha: palette.isDark ? 0.82 : 0.94,
        ),
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoPill(
                icon: _mode.icon,
                label: _mode.title(i18n),
                palette: palette,
                accent: palette.accent,
              ),
              _InfoPill(
                icon: Icons.library_music_rounded,
                label: _copyTrackCountLabel(i18n, _tracks.length),
                palette: palette,
              ),
              if (_sleepRemaining != null)
                _InfoPill(
                  icon: Icons.timer_outlined,
                  label: _copyActiveSleepTimerLabel(i18n, _sleepRemaining!),
                  palette: palette,
                  accent: palette.orbitAccent,
                ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              _setViewState(() {
                _tracksExpanded = !_tracksExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: palette.panelSurfaceMuted,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          SoothingMusicCopy.text(i18n, 'track.selector'),
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentTrack.label(i18n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        if (SoothingMusicCopy.trackLabel(
                              AppI18n('zh'),
                              _currentTrack.labelKey,
                            ) !=
                            _currentTrack.label(i18n)) ...<Widget>[
                          const SizedBox(height: 1),
                          Text(
                            SoothingMusicCopy.trackLabel(
                              AppI18n('zh'),
                              _currentTrack.labelKey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    SoothingMusicCopy.text(
                      i18n,
                      _tracksExpanded ? 'track.hide' : 'track.show',
                    ),
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _tracksExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _tracksExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tracks.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _TrackPill(
                    label: _tracks[index].label(i18n),
                    selected: _trackIndex == index,
                    palette: palette,
                    compact: compact,
                    onTap: () => _setTrackIndex(index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required bool compact,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fullscreen
            ? palette.controlSurface.withValues(alpha: 0.76)
            : palette.controlSurface,
        border: Border(
          top: BorderSide(
            color: _fullscreen
                ? palette.border.withValues(alpha: 0.38)
                : palette.border,
          ),
        ),
        boxShadow: _fullscreen
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _fullscreen ? 14 : 18,
            compact
                ? 10
                : _fullscreen
                ? 8
                : 14,
            _fullscreen ? 14 : 18,
            _fullscreen ? 6 : 10,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progress = _progressRatio;
              final currentLabel = _format(
                Duration(
                  milliseconds: (_duration.inMilliseconds * progress)
                      .round()
                      .clamp(0, _duration.inMilliseconds),
                ),
              );
              final totalLabel = _format(_duration);
              final narrow = compact && MediaQuery.of(context).size.width < 430;
              final screenSize = MediaQuery.of(context).size;
              final stacked =
                  _fullscreen || compact || constraints.maxWidth < 1000;
              final ultraNarrow = constraints.maxWidth < 360;
              final sideBySideControls =
                  !_fullscreen && stacked && !ultraNarrow;
              final playbackActive = _playbackVisualActive;

              final sliderTheme = SliderTheme.of(context).copyWith(
                trackHeight: 3.2,
                activeTrackColor: palette.accent,
                inactiveTrackColor: palette.border.withValues(alpha: 0.6),
                thumbColor: palette.accent,
                overlayColor: palette.accent.withValues(alpha: 0.16),
              );

              final volumeControl = Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    tooltip: _copyVolumeToggleLabel(i18n),
                    onPressed: () => _setMuted(!_muted),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    icon: Icon(
                      _muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: palette.textSecondary,
                      size: 18,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: sideBySideControls
                          ? (narrow ? 64 : 84)
                          : narrow
                          ? 96
                          : _fullscreen
                          ? 110
                          : stacked
                          ? 128
                          : 176,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        value: _muted ? 0 : _volume,
                        min: 0,
                        max: 1,
                        onChanged: _setVolume,
                      ),
                    ),
                  ),
                ],
              );

              final transportControls = Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _TransportIconButton(
                    tooltip: _copyPreviousTrackLabel(i18n),
                    icon: Icons.skip_previous_rounded,
                    palette: palette,
                    compact: stacked,
                    onPressed: _loading || _tracks.length <= 1
                        ? null
                        : () => _stepTrack(-1),
                  ),
                  SizedBox(width: stacked ? 4 : 8),
                  FilledButton(
                    onPressed: _loading ? null : _togglePlayback,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.isDark
                          ? const Color(0xFF051C2B)
                          : const Color(0xFF082337),
                      minimumSize: Size(
                        _fullscreen
                            ? 68
                            : stacked
                            ? 54
                            : 70,
                        _fullscreen
                            ? 68
                            : stacked
                            ? 54
                            : 70,
                      ),
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: _loading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: palette.isDark
                                  ? const Color(0xFF042033)
                                  : const Color(0xFF0A2940),
                            ),
                          )
                        : Icon(
                            playbackActive
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: _fullscreen
                                ? 32
                                : stacked
                                ? 26
                                : 34,
                          ),
                  ),
                  SizedBox(width: stacked ? 4 : 8),
                  _TransportIconButton(
                    tooltip: _copyNextTrackLabel(i18n),
                    icon: Icons.skip_next_rounded,
                    palette: palette,
                    compact: stacked,
                    onPressed: _loading || _tracks.length <= 1
                        ? null
                        : () => _stepTrack(1),
                  ),
                ],
              );

              final progressBlock = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: stacked
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '$currentLabel / $totalLabel',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: narrow
                        ? double.infinity
                        : _fullscreen
                        ? screenSize.width * 0.74
                        : stacked
                        ? 260
                        : 240,
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        value: progress,
                        min: 0,
                        max: 1,
                        onChangeStart: (value) {
                          _setViewState(() {
                            _draggingRatio = value;
                            _updateStageSpectrum(force: true);
                          });
                        },
                        onChanged: (value) {
                          _setViewState(() {
                            _draggingRatio = value;
                            _updateStageSpectrum(force: true);
                          });
                        },
                        onChangeEnd: (value) async {
                          _setViewState(() {
                            _draggingRatio = null;
                          });
                          await _seekToRatio(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _mode.footer(i18n),
                    maxLines: _fullscreen
                        ? 1
                        : narrow
                        ? 2
                        : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              );

              return stacked
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_fullscreen)
                          Row(
                            children: <Widget>[
                              Expanded(child: Center(child: transportControls)),
                              const SizedBox(width: 12),
                              volumeControl,
                            ],
                          )
                        else if (sideBySideControls)
                          Row(
                            children: <Widget>[
                              Expanded(child: volumeControl),
                              const SizedBox(width: 8),
                              transportControls,
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              volumeControl,
                              const SizedBox(height: 8),
                              transportControls,
                            ],
                          ),
                        const SizedBox(height: 8),
                        progressBlock,
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        volumeControl,
                        Expanded(child: Center(child: transportControls)),
                        progressBlock,
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}
