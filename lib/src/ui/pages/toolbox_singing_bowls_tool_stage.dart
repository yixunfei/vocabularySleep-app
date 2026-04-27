part of 'toolbox_singing_bowls_tool.dart';

// ============ Stage：音钵主舞台（首屏视觉主角） ============
// [风险] 手机端首屏要求音钵占高 >= 50%。本次将 bowlSize 上限由 296 提升到 360，
// 保证移动端单手视线聚焦点落在音钵中心，而不是摘要条或抽屉。
// ========================================================

extension _SingingBowlsStage on _SingingBowlsPracticeCardState {
  Widget buildStage(BuildContext context, {required bool compact}) {
    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final baseSize = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final bowlSize = compact
                    ? baseSize.clamp(240.0, 360.0).toDouble()
                    : baseSize.clamp(300.0, 440.0).toDouble();
                return GestureDetector(
                  onTapDown: (_) => setPressing(true),
                  onTapCancel: () => setPressing(false),
                  onTapUp: (_) => setPressing(false),
                  onTap: () => unawaited(strikeBowl()),
                  child: Semantics(
                    button: true,
                    label: t('敲击音钵', 'Strike bowl'),
                    child: SizedBox(
                      width: bowlSize * 2.2,
                      height: bowlSize * 2.2,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          for (final burst in _bursts)
                            _buildBurstWave(
                              burst: burst,
                              bowlSize: bowlSize * 2.02,
                            ),
                          AnimatedBuilder(
                            animation: Listenable.merge(<Listenable>[
                              _ambientController,
                              _strikeController,
                            ]),
                            builder: (BuildContext context, Widget? child) {
                              final strike = AppEasing.bounce.transform(
                                _strikeController.value,
                              );
                              final pulse =
                                  0.5 +
                                  0.5 *
                                      math.sin(
                                        _ambientController.value * math.pi * 2,
                                      );
                              final scale =
                                  1 -
                                  strike * 0.056 -
                                  (_pressing ? 0.025 : 0) +
                                  pulse * 0.004;
                              final yOffset = strike * 8.5;
                              return Transform.translate(
                                offset: Offset(0, yOffset),
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: SizedBox.square(
                              dimension: bowlSize,
                              child: CustomPaint(
                                painter: _SingingBowlPainter(
                                  accent: frequencySpec.accent,
                                  glow: frequencySpec.glow,
                                  voice: voiceSpec,
                                  ambientValue: _ambientController.value,
                                  strikeValue: _strikeController.value,
                                  pressing: _pressing,
                                ),
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
        ),
        const SizedBox(height: 6),
        _buildTapHint(context, compact: compact),
      ],
    );
  }

  Widget _buildTapHint(BuildContext context, {required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.touch_app_rounded,
            size: compact ? 14 : 16,
            color: frequencySpec.accent,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              t(
                '轻触音钵，听它从敲击、扩散到归静。',
                'Tap the bowl and let it bloom, spread, and settle.',
              ),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBurstWave({
    required _SpectrumBurst burst,
    required double bowlSize,
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(burst.id),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 4600),
      curve: Curves.easeOutCubic,
      onEnd: () => removeBurst(burst.id),
      builder: (BuildContext context, double value, Widget? child) {
        return IgnorePointer(
          child: SizedBox.square(
            dimension: bowlSize * 2.1,
            child: CustomPaint(
              painter: _SpectrumBurstPainter(
                accent: frequencySpec.accent,
                glow: frequencySpec.glow,
                progress: value,
                seed: burst.seed,
              ),
            ),
          ),
        );
      },
    );
  }
}
