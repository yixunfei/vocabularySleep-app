part of '../toolbox_sound_tools.dart';

extension _PianoToolStateUi on _PianoToolState {
  String _displayLabelForKey(_PianoKey key, _PianoViewportSpec viewport) {
    if (viewport.compactLabels && key.pitchClass != 'C') {
      return key.pitchClass;
    }
    return key.label;
  }

  Widget _buildKeyLayoutPickerButton(
    BuildContext context,
    AppI18n i18n, {
    bool immersive = false,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final foregroundColor = immersive
        ? Colors.white
        : theme.colorScheme.onSurface;
    final borderColor = immersive
        ? Colors.white.withValues(alpha: 0.24)
        : theme.colorScheme.outlineVariant;
    final backgroundColor = immersive
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest;
    return PopupMenuButton<String>(
      tooltip: i18n.t('toolbox.sound.piano.changeKeyLayout'),
      onSelected: (layoutId) {
        _setViewState(() {
          _applyKeyLayoutById(layoutId);
        });
      },
      itemBuilder: (menuContext) {
        return _PianoToolState._keyLayouts
            .map(
              (layout) => PopupMenuItem<String>(
                value: layout.id,
                child: Text(_displayKeyLayoutLabel(i18n, layout)),
              ),
            )
            .toList(growable: false);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          color: backgroundColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 11,
            vertical: compact ? 7 : 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.piano_rounded,
                size: compact ? 16 : 18,
                color: foregroundColor,
              ),
              const SizedBox(width: 6),
              Text(
                i18n.t(
                  'toolbox.sound.piano.keyCount',
                  params: {'count': '${_activeKeyLayout.keyCount}'},
                ),
                style:
                    (compact
                            ? theme.textTheme.labelLarge
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: foregroundColor,
                size: compact ? 18 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeNavigator(
    BuildContext context,
    AppI18n i18n, {
    required int octaveSpan,
    required int rangeStart,
    required _PianoKeyboardSlice slice,
    required bool immersive,
    bool aggressiveOneHand = false,
  }) {
    final ultraCompact = _isUltraCompactPhoneWidth(
      MediaQuery.sizeOf(context).width,
    );
    final theme = Theme.of(context);
    final maxStart = _maxRangeStart(octaveSpan);
    final quickStarts = _quickRangeStarts(octaveSpan);
    final starts = List<int>.generate(maxStart + 1, (index) => index);
    final labelColor = immersive ? Colors.white70 : null;
    final pickerTextColor = immersive
        ? Colors.white
        : theme.colorScheme.onSurface;
    final pickerBorderColor = immersive
        ? Colors.white.withValues(alpha: 0.24)
        : theme.colorScheme.outlineVariant;
    final pickerBackgroundColor = immersive
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest;
    final chipChildren = starts
        .map(
          (start) => Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: ChoiceChip(
              label: Text(_windowLabelForIndex(start, octaveSpan)),
              selected: start == rangeStart,
              onSelected: (_) => _updateRangeStart(
                start,
                octaveSpan,
                immediateWarmUp: true,
                preloadAllKeys: true,
              ),
            ),
          ),
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton.filledTonal(
              onPressed: rangeStart > 0
                  ? () => _updateRangeStart(
                      rangeStart - 1,
                      octaveSpan,
                      immediateWarmUp: true,
                      preloadAllKeys: true,
                    )
                  : null,
              tooltip: i18n.t('toolbox.sound.piano.previousWindow'),
              style: immersive
                  ? IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      foregroundColor: Colors.white,
                    )
                  : null,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    i18n.t('toolbox.sound.piano.currentWindow'),
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: labelColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ultraCompact
                        ? slice.label
                        : '${slice.label} · ${rangeStart + 1}/${maxStart + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: immersive ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _isRangeWindowPreparing
                        ? Row(
                            key: const ValueKey<String>('range-preparing'),
                            children: <Widget>[
                              SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: immersive
                                      ? Colors.white70
                                      : theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                i18n.t('toolbox.sound.piano.preparingVoices'),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: labelColor),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey<String>('range-ready'),
                            children: <Widget>[
                              Icon(
                                Icons.done_rounded,
                                size: 14,
                                color: immersive
                                    ? Colors.white70
                                    : theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                i18n.t('toolbox.sound.piano.windowReady'),
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: labelColor),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: rangeStart < maxStart
                  ? () => _updateRangeStart(
                      rangeStart + 1,
                      octaveSpan,
                      immediateWarmUp: true,
                      preloadAllKeys: true,
                    )
                  : null,
              tooltip: i18n.t('toolbox.sound.piano.nextWindow'),
              style: immersive
                  ? IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      foregroundColor: Colors.white,
                    )
                  : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _toggleRangeNavigatorLayout,
              tooltip: i18n.t('toolbox.sound.piano.toggleWindowList'),
              style: immersive
                  ? IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      foregroundColor: Colors.white,
                    )
                  : null,
              icon: Icon(
                _rangeNavigatorExpanded
                    ? Icons.view_stream_rounded
                    : Icons.view_day_rounded,
              ),
            ),
          ],
        ),
        if (maxStart > 0) ...<Widget>[
          const SizedBox(height: 6),
          if (aggressiveOneHand)
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    i18n.t('toolbox.sound.piano.quickJump'),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: labelColor),
                  ),
                ),
                PopupMenuButton<int>(
                  onSelected: (value) => _updateRangeStart(
                    value,
                    octaveSpan,
                    immediateWarmUp: true,
                    preloadAllKeys: true,
                  ),
                  itemBuilder: (menuContext) {
                    return starts
                        .map(
                          (start) => CheckedPopupMenuItem<int>(
                            value: start,
                            checked: start == rangeStart,
                            child: Text(
                              _windowLabelForIndex(start, octaveSpan),
                            ),
                          ),
                        )
                        .toList(growable: false);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: pickerBorderColor),
                      color: pickerBackgroundColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.swap_vert_rounded,
                            size: 18,
                            color: pickerTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            i18n.t('toolbox.sound.piano.chooseWindow'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: pickerTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            slice.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: pickerTextColor.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Text(
                  i18n.t('toolbox.sound.piano.quickJump'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: labelColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: rangeStart.toDouble(),
                    min: 0,
                    max: maxStart.toDouble(),
                    divisions: maxStart,
                    label: slice.label,
                    onChanged: (value) => _updateRangeStart(
                      value.round(),
                      octaveSpan,
                      immediateWarmUp: false,
                      preloadAllKeys: false,
                    ),
                    onChangeEnd: (value) => _updateRangeStart(
                      value.round(),
                      octaveSpan,
                      immediateWarmUp: true,
                      preloadAllKeys: true,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: quickStarts
                .map(
                  (start) => ChoiceChip(
                    label: Text(_windowLabelForIndex(start, octaveSpan)),
                    selected: start == rangeStart,
                    onSelected: (_) => _updateRangeStart(
                      start,
                      octaveSpan,
                      immediateWarmUp: true,
                      preloadAllKeys: true,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (!aggressiveOneHand) ...<Widget>[
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _rangeNavigatorExpanded
                ? Wrap(
                    key: const ValueKey<String>('range-wrap'),
                    children: chipChildren,
                  )
                : SingleChildScrollView(
                    key: const ValueKey<String>('range-scroll'),
                    scrollDirection: Axis.horizontal,
                    child: Row(children: chipChildren),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildKeyboardStage(
    BuildContext context,
    _PianoKeyboardSlice slice, {
    required _PianoViewportSpec viewport,
    required bool immersive,
    bool hideWhiteLabels = false,
    bool hideBlackLabels = false,
    double shellOpacity = 1.0,
    bool highlightFrame = false,
    bool isDualMode = false,
    bool aggressiveOneHand = false,
  }) {
    final style = _activeKeyboardStyle;
    final highlightedPitchClasses = _highlightedPitchClasses();
    final theme = Theme.of(context);
    final compactPhone = _isCompactPhoneWidth(MediaQuery.sizeOf(context).width);

    final shellGradientColors = isDualMode
        ? <Color>[Colors.transparent, Colors.transparent]
        : <Color>[
            style.shellTop.withValues(alpha: shellOpacity),
            style.shellBottom.withValues(alpha: shellOpacity),
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          widget.fullScreen ? 28 : (isDualMode ? 20 : 24),
        ),
        border: highlightFrame
            ? Border.all(color: const Color(0xFFBFD6FF), width: 1.6)
            : Border.all(
                color: Colors.white.withValues(alpha: isDualMode ? 0.20 : 0.10),
                width: isDualMode ? 1.0 : 1.0,
              ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: shellGradientColors,
        ),
        boxShadow: isDualMode
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: style.sideGlow.withValues(alpha: shellOpacity * 0.9),
                  blurRadius: immersive ? 28 : 18,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.fullScreen ? 8 : (isDualMode ? 8 : 10),
          widget.fullScreen ? 10 : (isDualMode ? 8 : 12),
          widget.fullScreen ? 8 : (isDualMode ? 8 : 10),
          widget.fullScreen ? 10 : (isDualMode ? 8 : 12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrowStage = _isCompactPhoneWidth(constraints.maxWidth);
            final adaptiveBlackWidthRatio = isDualMode
                ? (narrowStage ? 0.30 : _blackKeyWidthRatio.clamp(0.30, 0.40))
                : aggressiveOneHand
                ? _blackKeyWidthRatio.clamp(0.38, 0.46)
                : _blackKeyWidthRatio;
            final adaptiveBlackHeightRatio = (isDualMode && narrowStage)
                ? (_blackKeyHeightRatio * 0.90).clamp(0.44, 0.70)
                : aggressiveOneHand
                ? _blackKeyHeightRatio.clamp(0.72, 0.86)
                : _blackKeyHeightRatio;
            final metrics = _PianoStageMetrics(
              size: Size(constraints.maxWidth, viewport.stageHeight),
              whiteKeyExtent: viewport.whiteKeyExtent,
              blackKeyWidth: (constraints.maxWidth * adaptiveBlackWidthRatio)
                  .clamp(
                    aggressiveOneHand ? 58.0 : (narrowStage ? 44.0 : 54.0),
                    aggressiveOneHand ? 132.0 : (narrowStage ? 86.0 : 108.0),
                  ),
              blackKeyHeight:
                  (viewport.whiteKeyExtent * adaptiveBlackHeightRatio).clamp(
                    16.0,
                    viewport.whiteKeyExtent,
                  ),
              blackKeyInset: aggressiveOneHand
                  ? 2.0
                  : narrowStage
                  ? 3.0
                  : math.max(4.0, constraints.maxWidth * 0.018),
              blackKeyHitPadding: aggressiveOneHand
                  ? 16
                  : narrowStage
                  ? 12
                  : 6,
            );
            return SizedBox(
              height: viewport.stageHeight,
              child: _ToolboxScrollLockSurface(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _handleStagePointerDown(
                    event,
                    metrics: metrics,
                    slice: slice,
                    octaveSpan: viewport.octaveSpan,
                  ),
                  onPointerMove: (event) => _handleStagePointerMove(
                    event,
                    metrics: metrics,
                    slice: slice,
                    octaveSpan: viewport.octaveSpan,
                  ),
                  onPointerUp: _handleStagePointerUp,
                  onPointerCancel: _handleStagePointerUp,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              widget.fullScreen ? 20 : 18,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                        ),
                      ),
                      ...slice.whiteKeys.asMap().entries.map((entry) {
                        final index = entry.key;
                        final key = entry.value;
                        final isActive = _activeKeyIds.contains(key.id);
                        final isHighlighted = highlightedPitchClasses.contains(
                          key.pitchClass,
                        );
                        final keyBorderRadius = isDualMode ? 14.0 : 18.0;
                        final keyMargin = isDualMode
                            ? (compactPhone ? 0.35 : 0.5)
                            : 1.0;
                        final labelPadding = EdgeInsets.fromLTRB(
                          isDualMode ? (compactPhone ? 8 : 10) : 14,
                          widget.fullScreen ? 10 : (isDualMode ? 6 : 8),
                          math.max(
                            isDualMode ? 52 : 84,
                            metrics.blackKeyWidth +
                                (isDualMode
                                    ? (compactPhone ? 8 : 10)
                                    : (aggressiveOneHand ? 20 : 14)),
                          ),
                          widget.fullScreen ? 10 : (isDualMode ? 6 : 8),
                        );

                        return Positioned(
                          left: 0,
                          right: 0,
                          top: metrics.whiteTopFor(index),
                          height: metrics.whiteKeyExtent,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOutCubic,
                            margin: EdgeInsets.only(bottom: keyMargin),
                            padding: labelPadding,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                keyBorderRadius,
                              ),
                              border: Border.all(
                                color: Colors.black.withValues(
                                  alpha: isDualMode ? 0.08 : 0.10,
                                ),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  isActive
                                      ? theme.colorScheme.primaryContainer
                                      : isHighlighted
                                      ? style.whiteAccentTop
                                      : style.whiteTop,
                                  isActive
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.32,
                                        )
                                      : isHighlighted
                                      ? style.whiteAccentBottom
                                      : style.whiteBottom,
                                ],
                              ),
                              boxShadow: isActive
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: isDualMode
                                      ? (compactPhone ? 2.5 : 3)
                                      : 5,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : isHighlighted
                                        ? style.blackAccentTop
                                        : Colors.black.withValues(
                                            alpha: isDualMode ? 0.08 : 0.12,
                                          ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                SizedBox(width: isDualMode ? 6 : 10),
                                Expanded(
                                  child: hideWhiteLabels
                                      ? const SizedBox.shrink()
                                      : Text(
                                          _displayLabelForKey(key, viewport),
                                          style:
                                              (isDualMode
                                                      ? theme
                                                            .textTheme
                                                            .bodySmall
                                                      : theme
                                                            .textTheme
                                                            .titleSmall)
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(
                                                      0xFF0F172A,
                                                    ),
                                                    fontSize: isDualMode
                                                        ? 11
                                                        : null,
                                                  ),
                                        ),
                                ),
                                if (!viewport.compactLabels && !hideWhiteLabels)
                                  Text(
                                    key.pitchClass,
                                    style:
                                        (isDualMode
                                                ? theme.textTheme.labelSmall
                                                : theme.textTheme.labelMedium)
                                            ?.copyWith(
                                              color: const Color(0xFF475569),
                                              fontWeight: FontWeight.w700,
                                              fontSize: isDualMode ? 10 : null,
                                            ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      ...slice.blackKeys.map((placement) {
                        final key = placement.key;
                        final isActive = _activeKeyIds.contains(key.id);
                        final isHighlighted = highlightedPitchClasses.contains(
                          key.pitchClass,
                        );
                        final blackKeyRadius = isDualMode ? 12.0 : 16.0;
                        final blackKeyPadding = EdgeInsets.symmetric(
                          horizontal: isDualMode ? 8 : 12,
                        );

                        return Positioned(
                          right: metrics.blackKeyInset,
                          top: metrics.blackTopFor(placement.slot),
                          width: metrics.blackKeyWidth,
                          height: metrics.blackKeyHeight,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOutCubic,
                            padding: blackKeyPadding,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                blackKeyRadius,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: isDualMode ? 0.15 : 0.10,
                                ),
                                width: isDualMode ? 0.8 : 1.0,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  isActive
                                      ? const Color(0xFF2F56A6)
                                      : isHighlighted
                                      ? style.blackAccentTop
                                      : style.blackTop,
                                  isActive
                                      ? const Color(0xFF1A2E63)
                                      : isHighlighted
                                      ? style.blackAccentBottom
                                      : style.blackBottom,
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDualMode ? 0.35 : 0.28,
                                  ),
                                  blurRadius: isDualMode ? 8 : 10,
                                  offset: Offset(0, isDualMode ? 3 : 5),
                                ),
                                if (isActive)
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2F56A6,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            alignment: Alignment.centerLeft,
                            child: hideBlackLabels
                                ? const SizedBox.shrink()
                                : Text(
                                    viewport.compactLabels
                                        ? key.pitchClass
                                        : key.label,
                                    style:
                                        (isDualMode
                                                ? theme.textTheme.labelSmall
                                                : theme.textTheme.labelLarge)
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: isDualMode ? 10 : null,
                                            ),
                                  ),
                          ),
                        );
                      }),
                      Positioned(
                        left: 6,
                        top: 6,
                        bottom: 6,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: style.railColor,
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
    );
  }

  Widget _buildDualKeyboardStage(
    BuildContext context, {
    required _PianoViewportSpec viewport,
    required bool immersive,
  }) {
    final i18n = _toolboxI18n(context);
    final lowerOctaveSpan = viewport.octaveSpan;
    final lowerStart = _rangeStartOctave;
    final upperStart = math.min(
      lowerStart + lowerOctaveSpan,
      _maxRangeStart(lowerOctaveSpan),
    );

    final lowerSlice = _sliceFor(lowerStart, lowerOctaveSpan);
    final upperSlice = _sliceFor(upperStart, lowerOctaveSpan);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactSwitcher = _isCompactPhoneWidth(constraints.maxWidth);
        final keyboardWidth = compactSwitcher
            ? constraints.maxWidth
            : (constraints.maxWidth - 8) / 2;
        final dualViewport = _PianoViewportSpec(
          octaveSpan: viewport.octaveSpan,
          whiteKeyExtent: viewport.whiteKeyExtent,
          stageHeight: viewport.stageHeight,
          compactLabels: viewport.compactLabels || keyboardWidth < 140,
        );
        if (compactSwitcher) {
          final compactWhiteExtent = (viewport.whiteKeyExtent * 0.90).clamp(
            26.0,
            viewport.whiteKeyExtent,
          );
          final compactViewport = _PianoViewportSpec(
            octaveSpan: viewport.octaveSpan,
            whiteKeyExtent: compactWhiteExtent.toDouble(),
            stageHeight: compactWhiteExtent * (viewport.octaveSpan * 7 + 1),
            compactLabels: true,
          );
          Widget buildLane(
            _PianoKeyboardSlice laneSlice, {
            required _PianoCompactDeckFocus focus,
            required bool active,
          }) {
            return Column(
              key: ValueKey<String>('compact-lane-${focus.name}'),
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _compactFocusLabel(i18n, focus),
                    style: TextStyle(
                      color: immersive ? Colors.white70 : null,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildKeyboardStage(
                  context,
                  laneSlice,
                  viewport: compactViewport,
                  immersive: immersive,
                  hideWhiteLabels: !active,
                  hideBlackLabels: !active,
                  shellOpacity: active ? 1.0 : 0.70,
                  highlightFrame: active,
                  isDualMode: true,
                ),
              ],
            );
          }

          final activeFocus = _compactDualFocus;
          final activeSlice = activeFocus == _PianoCompactDeckFocus.high
              ? upperSlice
              : lowerSlice;
          final inactiveFocus = activeFocus == _PianoCompactDeckFocus.high
              ? _PianoCompactDeckFocus.low
              : _PianoCompactDeckFocus.high;
          final inactiveSlice = activeFocus == _PianoCompactDeckFocus.high
              ? lowerSlice
              : upperSlice;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildCompactDualToggle(
                      context,
                      i18n,
                      focus: _PianoCompactDeckFocus.low,
                      slice: lowerSlice,
                      selected: _compactDualFocus == _PianoCompactDeckFocus.low,
                      immersive: immersive,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactDualToggle(
                      context,
                      i18n,
                      focus: _PianoCompactDeckFocus.high,
                      slice: upperSlice,
                      selected:
                          _compactDualFocus == _PianoCompactDeckFocus.high,
                      immersive: immersive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: buildLane(activeSlice, focus: activeFocus, active: true),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _setViewState(() {
                    _compactDualFocus = inactiveFocus;
                  });
                },
                icon: const Icon(Icons.swap_vert_rounded),
                label: Text(
                  i18n.t(
                    'toolbox.sound.piano.switchKeyboard',
                    params: {
                      'side': inactiveFocus == _PianoCompactDeckFocus.high
                          ? 'high'
                          : 'low',
                      'label': inactiveSlice.label,
                    },
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      i18n.t('toolbox.sound.piano.high'),
                      style: TextStyle(
                        color: immersive ? Colors.white70 : null,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: _buildKeyboardStage(
                      context,
                      upperSlice,
                      viewport: dualViewport,
                      immersive: immersive,
                      isDualMode: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      i18n.t('toolbox.sound.piano.low'),
                      style: TextStyle(
                        color: immersive ? Colors.white70 : null,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: _buildKeyboardStage(
                      context,
                      lowerSlice,
                      viewport: dualViewport,
                      immersive: immersive,
                      isDualMode: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactDualToggle(
    BuildContext context,
    AppI18n i18n, {
    required _PianoCompactDeckFocus focus,
    required _PianoKeyboardSlice slice,
    required bool selected,
    required bool immersive,
  }) {
    final theme = Theme.of(context);
    final foregroundColor = selected
        ? immersive
              ? Colors.white
              : theme.colorScheme.onPrimaryContainer
        : immersive
        ? Colors.white
        : theme.colorScheme.onSurface;
    final borderColor = immersive
        ? Colors.white.withValues(alpha: selected ? 0.28 : 0.14)
        : selected
        ? theme.colorScheme.primary.withValues(alpha: 0.28)
        : theme.colorScheme.outlineVariant;
    final backgroundColor = immersive
        ? Colors.white.withValues(alpha: selected ? 0.16 : 0.08)
        : selected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _setViewState(() {
            _compactDualFocus = focus;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _compactFocusLabel(i18n, focus),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                slice.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildPianoSettingsContent(
    BuildContext context,
    AppI18n i18n, {
    required _PianoViewportSpec viewport,
    required _PianoKeyboardSlice slice,
    required void Function(VoidCallback mutation) applySettings,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          i18n.t('toolbox.sound.piano.pianoSettings'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: i18n.t('toolbox.sound.piano.layout'),
              value: _displayKeyLayoutLabel(i18n, _activeKeyLayout),
            ),
            ToolboxMetricCard(
              label: i18n.t('toolbox.sound.piano.range'),
              value: slice.label,
            ),
            ToolboxMetricCard(
              label: i18n.t('toolbox.sound.piano.scale'),
              value: _displayScaleLabelFixed(i18n, _scaleId),
            ),
            ToolboxMetricCard(
              label: i18n.t('toolbox.sound.piano.harmony'),
              value: _displayChordLabelFixed(i18n, _chordId),
            ),
            ToolboxMetricCard(
              label: i18n.t('toolbox.sound.piano.style'),
              value: _displayKeyboardStyleLabelFixed(
                i18n,
                _activeKeyboardStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          i18n.t('toolbox.sound.piano.keyLayoutLabel'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _PianoToolState._keyLayouts
              .map(
                (layout) => ChoiceChip(
                  label: Text('${layout.keyCount}'),
                  selected: layout.id == _keyLayoutId,
                  onSelected: (_) => applySettings(() {
                    _applyKeyLayoutById(layout.id);
                  }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Text(
          _displayKeyLayoutLabel(i18n, _activeKeyLayout),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          i18n.t('toolbox.sound.piano.presetPack'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _PianoToolState._presets
              .map(
                (item) => ChoiceChip(
                  label: Text(_displayPresetLabel(i18n, item)),
                  selected: item.id == _presetId,
                  onSelected: (_) => applySettings(() => _applyPreset(item.id)),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Text(
          _displayPresetSubtitleFixed(i18n, _activePreset),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          i18n.t('toolbox.sound.piano.keyboardStyle'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _PianoToolState._keyboardStyles
              .map(
                (item) => ChoiceChip(
                  label: Text(_displayKeyboardStyleLabelFixed(i18n, item)),
                  selected: item.id == _keyboardStyleId,
                  onSelected: (_) => applySettings(() {
                    _keyboardStyleId = item.id;
                  }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          i18n.t('toolbox.sound.piano.touchAndSpace'),
        ),
        Text(_displayTouchLabelFixed(i18n), style: theme.textTheme.labelLarge),
        Slider(
          value: _touch,
          min: 0.55,
          max: 1.0,
          divisions: 18,
          onChanged: (value) => applySettings(() {
            _touch = value;
          }),
        ),
        Text(_displaySpaceLabelFixed(i18n), style: theme.textTheme.labelLarge),
        Slider(
          value: _reverb,
          min: 0.0,
          max: 0.55,
          divisions: 11,
          onChanged: (value) => applySettings(() {
            _reverb = value;
          }),
          onChangeEnd: (_) => _invalidatePlayers(),
        ),
        Text(_displayDecayLabelFixed(i18n), style: theme.textTheme.labelLarge),
        Slider(
          value: _decay,
          min: 0.7,
          max: 1.8,
          divisions: 22,
          onChanged: (value) => applySettings(() {
            _decay = value;
          }),
          onChangeEnd: (_) => _invalidatePlayers(),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          i18n.t('toolbox.sound.piano.phoneTuning'),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _compactKeyboardMode,
          onChanged: (value) => applySettings(() {
            _compactKeyboardMode = value;
          }),
          title: Text(i18n.t('toolbox.sound.piano.compactKeyboardMode')),
          subtitle: Text(i18n.t('toolbox.sound.piano.compactKeyboardModeDesc')),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _aggressiveOneHandMode,
          onChanged: (value) => applySettings(() {
            _aggressiveOneHandMode = value;
            if (value) {
              _dualKeyboardMode = false;
            }
          }),
          title: Text(i18n.t('toolbox.sound.piano.aggressiveOneHand')),
          subtitle: Text(i18n.t('toolbox.sound.piano.aggressiveOneHandDesc')),
        ),
        Text(
          _displayGestureThresholdLabelFixed(i18n),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _gestureThresholdScale,
          min: 0.8,
          max: 1.25,
          divisions: 9,
          onChanged: (value) => applySettings(() {
            _gestureThresholdScale = value;
          }),
        ),
        Text(
          i18n.t('toolbox.sound.piano.sensitivityTip'),
          style: theme.textTheme.bodySmall,
        ),
        Text(
          i18n.t(
            'toolbox.sound.piano.keyHeight',
            params: {'percent': '${(_keyHeightScale * 100).round()}'},
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _keyHeightScale,
          min: 0.9,
          max: 1.12,
          divisions: 11,
          onChanged: (value) => applySettings(() {
            _keyHeightScale = value;
          }),
        ),
        Text(
          i18n.t(
            'toolbox.sound.piano.blackKeyWidth',
            params: {'percent': '${(_blackKeyWidthRatio * 100).round()}'},
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _blackKeyWidthRatio,
          min: 0.28,
          max: 0.40,
          divisions: 12,
          onChanged: (value) => applySettings(() {
            _blackKeyWidthRatio = value;
          }),
        ),
        Text(
          i18n.t(
            'toolbox.sound.piano.blackKeyHeight',
            params: {'percent': '${(_blackKeyHeightRatio * 100).round()}'},
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _blackKeyHeightRatio,
          min: 0.58,
          max: 0.76,
          divisions: 9,
          onChanged: (value) => applySettings(() {
            _blackKeyHeightRatio = value;
          }),
        ),
        Text(
          i18n.t(
            'toolbox.sound.piano.chordDelay',
            params: {'percent': '${(_chordSpreadScale * 100).round()}'},
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _chordSpreadScale,
          min: 0.8,
          max: 1.6,
          divisions: 16,
          onChanged: (value) => applySettings(() {
            _chordSpreadScale = value;
          }),
        ),
        Text(
          i18n.t(
            'toolbox.sound.piano.chordFalloff',
            params: {'percent': '${(_chordFalloff * 100).round()}'},
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _chordFalloff,
          min: 0.08,
          max: 0.18,
          divisions: 10,
          onChanged: (value) => applySettings(() {
            _chordFalloff = value;
          }),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          i18n.t('toolbox.sound.piano.scaleAndHarmony'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _PianoToolState._scaleSets
              .map(
                (item) => ChoiceChip(
                  label: Text(_displayScaleLabelFixed(i18n, item.id)),
                  selected: item.id == _scaleId,
                  onSelected: (_) => applySettings(() {
                    _scaleId = item.id;
                  }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _PianoToolState._chordSets
              .map(
                (item) => ChoiceChip(
                  label: Text(_displayChordLabelFixed(i18n, item.id)),
                  selected: item.id == _chordId,
                  onSelected: (_) => applySettings(() {
                    _chordId = item.id;
                  }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _PianoToolState._rootPitchClasses
              .map(
                (pitchClass) => ChoiceChip(
                  label: Text(pitchClass),
                  selected: pitchClass == _rootPitchClass,
                  onSelected: (_) => applySettings(() {
                    _rootPitchClass = pitchClass;
                  }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          i18n.t('toolbox.sound.piano.rangeWindow'),
        ),
        Text(
          i18n.t(
            'toolbox.sound.piano.octaveSpanDesc',
            params: {'octaveSpan': '${viewport.octaveSpan}'},
          ),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        _buildRangeNavigator(
          context,
          i18n,
          octaveSpan: viewport.octaveSpan,
          rangeStart: _rangeStartOctave.clamp(
            0,
            _maxRangeStart(viewport.octaveSpan),
          ),
          slice: slice,
          immersive: false,
          aggressiveOneHand:
              _aggressiveOneHandMode &&
              _isAggressiveOneHandWidth(MediaQuery.sizeOf(context).width),
        ),
      ],
    );
  }

  Future<void> _openPianoSettingsSheet(
    BuildContext context,
    AppI18n i18n, {
    required _PianoViewportSpec viewport,
    required _PianoKeyboardSlice slice,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void applySettings(VoidCallback mutation) {
              if (!mounted) {
                return;
              }
              _setViewState(mutation);
              setSheetState(() {});
            }

            final refreshedViewport = _viewportFor(
              context,
              BoxConstraints(
                maxWidth: MediaQuery.sizeOf(sheetContext).width - 32,
              ),
            );
            final refreshedRangeStart = _rangeStartOctave.clamp(
              0,
              _maxRangeStart(refreshedViewport.octaveSpan),
            );
            final refreshedSlice = _sliceFor(
              refreshedRangeStart,
              refreshedViewport.octaveSpan,
            );
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: _buildPianoSettingsContent(
                  sheetContext,
                  i18n,
                  viewport: refreshedViewport,
                  slice: refreshedSlice,
                  applySettings: applySettings,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPianoFullScreen(
    BuildContext context,
    AppI18n i18n, {
    required _PianoViewportSpec viewport,
    required _PianoKeyboardSlice slice,
    required int rangeStart,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final aggressiveOneHand =
        _aggressiveOneHandMode && _isAggressiveOneHandWidth(width);
    final effectiveDualMode = _dualKeyboardMode && !aggressiveOneHand;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final compactTopBar = width < 430;
    final overlayButtonStyle = FilledButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: 0.58),
      foregroundColor: Colors.white,
      elevation: 0,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      visualDensity: VisualDensity.compact,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _activeKeyboardStyle.shellTop,
            _activeKeyboardStyle.shellBottom,
            const Color(0xFF020617),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                topInset + 56,
                12,
                bottomInset + 110,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: effectiveDualMode
                    ? _buildDualKeyboardStage(
                        context,
                        viewport: viewport,
                        immersive: true,
                      )
                    : _buildKeyboardStage(
                        context,
                        slice,
                        viewport: viewport,
                        immersive: true,
                        aggressiveOneHand: aggressiveOneHand,
                      ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: topInset + 10,
            right: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.34),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: <Widget>[
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      style: overlayButtonStyle,
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: aggressiveOneHand
                          ? null
                          : _toggleDualKeyboardMode,
                      style: overlayButtonStyle,
                      child: Icon(
                        effectiveDualMode
                            ? Icons.view_day_rounded
                            : Icons.view_stream_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!compactTopBar)
                      FilledButton.tonal(
                        onPressed: _toggleCompactKeyboardMode,
                        style: overlayButtonStyle,
                        child: Icon(
                          _compactKeyboardMode
                              ? Icons.compress_rounded
                              : Icons.expand_rounded,
                        ),
                      ),
                    if (compactTopBar)
                      PopupMenuButton<_PianoTopBarAction>(
                        tooltip: i18n.t('toolbox.sound.piano.moreActions'),
                        color: Colors.black.withValues(alpha: 0.92),
                        onSelected: (action) {
                          switch (action) {
                            case _PianoTopBarAction.toggleCompact:
                              _toggleCompactKeyboardMode();
                            case _PianoTopBarAction.openSettings:
                              _openPianoSettingsSheet(
                                context,
                                i18n,
                                viewport: viewport,
                                slice: slice,
                              );
                          }
                        },
                        itemBuilder: (menuContext) {
                          return <PopupMenuEntry<_PianoTopBarAction>>[
                            PopupMenuItem<_PianoTopBarAction>(
                              value: _PianoTopBarAction.toggleCompact,
                              child: Text(
                                _compactKeyboardMode
                                    ? i18n.t(
                                        'toolbox.sound.piano.disableCompact',
                                      )
                                    : i18n.t(
                                        'toolbox.sound.piano.enableCompact',
                                      ),
                              ),
                            ),
                            PopupMenuItem<_PianoTopBarAction>(
                              value: _PianoTopBarAction.openSettings,
                              child: Text(
                                i18n.t('toolbox.sound.piano.keyboardSettings'),
                              ),
                            ),
                          ];
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (!compactTopBar)
                      FilledButton.tonalIcon(
                        onPressed: () => _openPianoSettingsSheet(
                          context,
                          i18n,
                          viewport: viewport,
                          slice: slice,
                        ),
                        style: overlayButtonStyle,
                        icon: const Icon(Icons.tune_rounded),
                        label: Text(i18n.t('toolbox.sound.piano.settings')),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: bottomInset + 10,
            child: _buildFullScreenBottomBar(
              context,
              i18n,
              viewport: viewport,
              rangeStart: rangeStart,
              slice: slice,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenBottomBar(
    BuildContext context,
    AppI18n i18n, {
    required _PianoViewportSpec viewport,
    required int rangeStart,
    required _PianoKeyboardSlice slice,
  }) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compactPhone = _isCompactPhoneWidth(width);
    final aggressiveOneHand =
        _aggressiveOneHandMode && _isAggressiveOneHandWidth(width);
    final effectiveDualMode = _dualKeyboardMode && !aggressiveOneHand;
    final overlayButtonStyle = FilledButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: 0.56),
      foregroundColor: Colors.white,
      elevation: 0,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
    final activeCompactSlice = _compactDualFocus == _PianoCompactDeckFocus.high
        ? i18n.t('toolbox.sound.piano.high')
        : i18n.t('toolbox.sound.piano.low');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _PianoOverlayChip(
                    label: i18n.t('toolbox.sound.piano.window'),
                    value: slice.label,
                  ),
                  const SizedBox(width: 8),
                  _PianoOverlayChip(
                    label: i18n.t('toolbox.sound.piano.harmony'),
                    value: _displayChordLabelFixed(i18n, _chordId),
                  ),
                  const SizedBox(width: 8),
                  _PianoOverlayChip(
                    label: i18n.t('toolbox.sound.piano.mode'),
                    value: effectiveDualMode
                        ? compactPhone
                              ? '${i18n.t('toolbox.sound.piano.dual')} · $activeCompactSlice'
                              : i18n.t('toolbox.sound.piano.dual')
                        : i18n.t('toolbox.sound.piano.single'),
                  ),
                  const SizedBox(width: 8),
                  _buildKeyLayoutPickerButton(
                    context,
                    i18n,
                    immersive: true,
                    compact: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: rangeStart > 0
                      ? () => _updateRangeStart(
                          rangeStart - 1,
                          viewport.octaveSpan,
                        )
                      : null,
                  style: overlayButtonStyle,
                  child: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    compactPhone
                        ? i18n.t('toolbox.sound.piano.glissTip')
                        : i18n.t('toolbox.sound.piano.glissTipWide'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: rangeStart < _maxRangeStart(viewport.octaveSpan)
                      ? () => _updateRangeStart(
                          rangeStart + 1,
                          viewport.octaveSpan,
                        )
                      : null,
                  style: overlayButtonStyle,
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _disposePianoToolState() {
    _rangeWarmUpTimer?.cancel();
    _rangeWarmUpTimer = null;
    _activeKeyReleaseTimer?.cancel();
    _activeKeyReleaseTimer = null;
    _rangeWarmUpVersion += 1;
    _invalidatePlayers(warmUp: false);
    unawaited(_sampledPianoEngine.dispose());
  }

  Widget _buildPianoToolState(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _maybeApplyResponsiveDefaults(constraints.maxWidth);
        final compactPhone = _isCompactPhoneWidth(constraints.maxWidth);
        final ultraCompactPhone = _isUltraCompactPhoneWidth(
          constraints.maxWidth,
        );
        final aggressiveOneHand =
            _aggressiveOneHandMode &&
            _isAggressiveOneHandWidth(constraints.maxWidth);
        final effectiveDualMode = _dualKeyboardMode && !aggressiveOneHand;
        final viewport = _viewportFor(context, constraints);
        _visibleOctaveSpan = viewport.octaveSpan;
        final rangeStart = _rangeStartOctave.clamp(
          0,
          _maxRangeStart(viewport.octaveSpan),
        );
        final slice = _sliceFor(rangeStart, viewport.octaveSpan);
        if (widget.fullScreen) {
          return _buildPianoFullScreen(
            context,
            i18n,
            viewport: viewport,
            slice: slice,
            rangeStart: rangeStart,
          );
        }
        return _buildInstrumentPanelShell(
          context,
          fullScreen: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.piano.keys'),
                    value: '${_activeKeyLayout.keyCount}',
                  ),
                  if (!compactPhone)
                    ToolboxMetricCard(
                      label: i18n.t('toolbox.sound.piano.totalRange'),
                      value:
                          '${_noteLabelForMidi(_activeKeyLayout.startMidi)}-${_noteLabelForMidi(_activeKeyLayout.startMidi + _activeKeyLayout.keyCount - 1)}',
                    ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.piano.window'),
                    value: slice.label,
                  ),
                  if (!compactPhone)
                    ToolboxMetricCard(
                      label: i18n.t('toolbox.sound.piano.preset'),
                      value: _displayPresetLabel(i18n, _activePreset),
                    ),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.piano.harmony'),
                    value: _displayChordLabelFixed(i18n, _chordId),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (compactPhone) ...<Widget>[
                SectionHeader(
                  title: i18n.t('toolbox.sound.piano.verticalKeyboard'),
                  subtitle: i18n.t(
                    'toolbox.sound.piano.verticalKeyboardPhoneDesc',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openPianoSettingsSheet(
                      context,
                      i18n,
                      viewport: viewport,
                      slice: slice,
                    ),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(i18n.t('toolbox.sound.piano.keyboardSettings')),
                  ),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: SectionHeader(
                        title: i18n.t('toolbox.sound.piano.verticalKeyboard'),
                        subtitle: i18n.t(
                          'toolbox.sound.piano.verticalKeyboardDesc',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: () => _openPianoSettingsSheet(
                        context,
                        i18n,
                        viewport: viewport,
                        slice: slice,
                      ),
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(i18n.t('toolbox.sound.piano.settings')),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _buildKeyLayoutPickerButton(
                    context,
                    i18n,
                    compact: ultraCompactPhone,
                  ),
                  OutlinedButton.icon(
                    onPressed: _toggleRangeNavigatorLayout,
                    icon: Icon(
                      _rangeNavigatorExpanded
                          ? Icons.view_stream_rounded
                          : Icons.view_day_rounded,
                    ),
                    label: Text(
                      ultraCompactPhone
                          ? i18n.t('toolbox.sound.piano.window')
                          : i18n.t('toolbox.sound.piano.windowList'),
                    ),
                  ),
                  if (!aggressiveOneHand)
                    OutlinedButton.icon(
                      onPressed: _toggleDualKeyboardMode,
                      icon: Icon(
                        effectiveDualMode
                            ? Icons.view_stream_rounded
                            : Icons.view_day_rounded,
                      ),
                      label: Text(
                        ultraCompactPhone
                            ? i18n.t('toolbox.sound.piano.dual')
                            : i18n.t('toolbox.sound.piano.dualKeyboard'),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _openFullScreen(context),
                    icon: const Icon(Icons.open_in_full_rounded),
                    label: Text(
                      ultraCompactPhone
                          ? i18n.t('toolbox.sound.piano.full')
                          : i18n.t('toolbox.sound.piano.fullScreen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (compactPhone) ...<Widget>[
                effectiveDualMode
                    ? _buildDualKeyboardStage(
                        context,
                        viewport: viewport,
                        immersive: false,
                      )
                    : _buildKeyboardStage(
                        context,
                        slice,
                        viewport: viewport,
                        immersive: false,
                        aggressiveOneHand: aggressiveOneHand,
                      ),
                const SizedBox(height: 10),
                _buildRangeNavigator(
                  context,
                  i18n,
                  octaveSpan: viewport.octaveSpan,
                  rangeStart: rangeStart,
                  slice: slice,
                  immersive: false,
                  aggressiveOneHand: aggressiveOneHand,
                ),
              ] else ...<Widget>[
                _buildRangeNavigator(
                  context,
                  i18n,
                  octaveSpan: viewport.octaveSpan,
                  rangeStart: rangeStart,
                  slice: slice,
                  immersive: false,
                  aggressiveOneHand: aggressiveOneHand,
                ),
                const SizedBox(height: 12),
                effectiveDualMode
                    ? _buildDualKeyboardStage(
                        context,
                        viewport: viewport,
                        immersive: false,
                      )
                    : _buildKeyboardStage(
                        context,
                        slice,
                        viewport: viewport,
                        immersive: false,
                        aggressiveOneHand: aggressiveOneHand,
                      ),
              ],
              const SizedBox(height: 10),
              Text(
                compactPhone
                    ? i18n.t('toolbox.sound.piano.glissandoGuideCompact')
                    : i18n.t('toolbox.sound.piano.glissandoGuide'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
