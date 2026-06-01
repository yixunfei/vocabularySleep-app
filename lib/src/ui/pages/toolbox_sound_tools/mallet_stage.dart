part of '../toolbox_sound_tools.dart';

extension _MalletStageUi on _ChimesToolState {
  Widget _buildMalletStage(
    BuildContext context, {
    required AppI18n i18n,
    required double height,
    required bool immersive,
  }) {
    final theme = Theme.of(context);
    final notes = _activeMidis;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 390;
        final rotated = immersive || compact;
        final stageSize = Size(width, height);
        final sideInset = compact ? 14.0 : 20.0;
        final usableWidth = math.max(1.0, width - sideInset * 2);
        final usableHeight = math.max(1.0, height - sideInset * 2 - 28);
        final laneWidth = usableWidth / notes.length;
        final laneHeight = usableHeight / notes.length;
        final resonatorColor = Color.lerp(
          _activeInstrument.resonatorColor,
          _activeMaterial.resonatorColor,
          0.55,
        )!;
        return _ToolboxScrollLockSurface(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) =>
                _handleStagePointerDown(event, stageSize, rotated: rotated),
            onPointerMove: (event) =>
                _handleStagePointerMove(event, stageSize, rotated: rotated),
            onPointerUp: _handleStagePointerUp,
            onPointerCancel: _handleStagePointerUp,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  widget.fullScreen ? 24 : 18,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    immersive
                        ? const Color(0xFF141B24)
                        : const Color(0xFFFFF5E1),
                    immersive
                        ? const Color(0xFF2B1C14)
                        : const Color(0xFFE9C88E),
                  ],
                ),
                border: Border.all(
                  color: immersive
                      ? Colors.white.withValues(alpha: 0.14)
                      : const Color(0xFFB48A56),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: immersive ? 0.32 : 0.12,
                    ),
                    blurRadius: immersive ? 24 : 14,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: sideInset,
                    right: sideInset,
                    top: sideInset,
                    bottom: sideInset,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          _activeInstrument.bodyColor,
                          _activeMaterial.tint,
                          0.38,
                        )!.withValues(alpha: immersive ? 0.34 : 0.52),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  for (var index = 0; index < notes.length; index += 1)
                    if (rotated)
                      _buildRotatedBar(
                        index,
                        laneHeight,
                        usableWidth,
                        sideInset,
                        resonatorColor,
                        theme,
                        immersive,
                      )
                    else
                      _buildWideBar(
                        index,
                        laneWidth,
                        usableHeight,
                        sideInset,
                        resonatorColor,
                        theme,
                        immersive,
                      ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          i18n.t('toolbox.sound.mallet.low_side'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: immersive
                                ? Colors.white70
                                : const Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          i18n.t('toolbox.sound.mallet.high_side'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: immersive
                                ? Colors.white70
                                : const Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRotatedBar(
    int index,
    double laneHeight,
    double usableWidth,
    double sideInset,
    Color resonatorColor,
    ThemeData theme,
    bool immersive,
  ) {
    final lowToHigh = _activeMidis.length <= 1
        ? 0.0
        : index / (_activeMidis.length - 1);
    final barWidth = usableWidth * (0.92 - lowToHigh * 0.24);
    final top = sideInset + laneHeight * index + laneHeight * 0.13;
    final barHeight = math.max(22.0, laneHeight * 0.72);
    return Stack(
      children: <Widget>[
        Positioned(
          left: sideInset + 16,
          top: top + barHeight * 0.62,
          width: barWidth * _activeCavity.resonatorScale,
          height: math.max(7, barHeight * 0.22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: resonatorColor.withValues(alpha: immersive ? 0.5 : 0.74),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        _MalletBar(
          left: sideInset + 8,
          top: top,
          width: barWidth,
          height: barHeight,
          color: _barColorFor(index),
          label: _noteLabelFromMidi(_activeMidis[index]),
          active: _activeBar == index,
          immersive: immersive,
          rotated: true,
          textStyle: theme.textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildWideBar(
    int index,
    double laneWidth,
    double usableHeight,
    double sideInset,
    Color resonatorColor,
    ThemeData theme,
    bool immersive,
  ) {
    final lowToHigh = _activeMidis.length <= 1
        ? 0.0
        : index / (_activeMidis.length - 1);
    final barHeight = usableHeight * (0.9 - lowToHigh * 0.26);
    final left = sideInset + laneWidth * index + laneWidth * 0.12;
    final top = sideInset + 18 + (usableHeight - barHeight) * 0.52;
    return Stack(
      children: <Widget>[
        Positioned(
          left: left + laneWidth * 0.12,
          top: top + barHeight * 0.22,
          width: laneWidth * 0.5,
          height: barHeight * _activeCavity.resonatorScale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: resonatorColor.withValues(alpha: immersive ? 0.42 : 0.62),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        _MalletBar(
          left: left,
          top: top,
          width: laneWidth * 0.76,
          height: barHeight,
          color: _barColorFor(index),
          label: _noteLabelFromMidi(_activeMidis[index]),
          active: _activeBar == index,
          immersive: immersive,
          rotated: false,
          textStyle: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}
