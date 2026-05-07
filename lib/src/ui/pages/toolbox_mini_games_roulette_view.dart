part of 'toolbox_mini_games.dart';

extension _RouletteGameView on _RouletteGameState {
  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final colors = Theme.of(context).colorScheme;
    final accent = const Color(0xFFC74C3F);
    final cylinderAngle = _displayCylinderAngle();
    final stageListenable = Listenable.merge(<Listenable>[
      _ambientController,
      _spinController,
      _chamberStepController,
      _fireController,
      _safeKickController,
      _recoilController,
      _shakeController,
      _hitFlashController,
    ]);

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.alphaBlend(
                const Color(0xFFB7AA9A).withValues(alpha: 0.34),
                colors.surfaceContainerHighest,
              ),
              const Color(0xFF5B514A),
              const Color(0xFF2C2E34),
            ],
          ),
          border: Border.all(
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.28),
              colors.outlineVariant,
            ),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AnimatedBuilder(
            animation: stageListenable,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(_stageShakeX(), _stageShakeY()),
                child: CustomPaint(
                  painter: _RouletteBackdropPainter(
                    accent: accent,
                    ambient: _ambientController.value,
                    hitFlash: _hitFlashController.value,
                    phase: _phase,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      children: <Widget>[
                        AspectRatio(
                          aspectRatio: 1.56,
                          child: CustomPaint(
                            painter: _RouletteRevolverPainter(
                              phase: _phase,
                              sequence: _sequence,
                              bulletCount: _bulletCount,
                              activeChamber: _activeChamber,
                              pullCount: _pullCount,
                              cylinderAngle: cylinderAngle,
                              fireProgress: _fireController.value,
                              safeKickProgress: _safeKickController.value,
                              recoilProgress: _recoilController.value,
                              ambient: _ambientController.value,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: accent.withValues(alpha: 0.16),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.34),
                                ),
                              ),
                              child: Text(
                                _phaseLabel(i18n),
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: const Color(0xFFFFF8EE),
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.graphic_eq_rounded,
                              color: Colors.white.withValues(alpha: 0.76),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _audioReady
                                  ? _text(i18n, zh: '真实音效', en: 'Live SFX')
                                  : _text(i18n, zh: '系统回退', en: 'Fallback'),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: const Color(
                                      0xFFFFF8EE,
                                    ).withValues(alpha: 0.88),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(
                              0xFF1E2025,
                            ).withValues(alpha: 0.52),
                            border: Border.all(
                              color: const Color(
                                0xFFFFF1DD,
                              ).withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            _stageCopy(i18n),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  height: 1.38,
                                  fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildMetrics(BuildContext context, AppI18n i18n) {
    final remaining = (_RouletteGameState._chambers - _pullCount).clamp(
      0,
      _RouletteGameState._chambers,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.0;
        final compact = constraints.maxWidth < 440;
        final width = compact
            ? (constraints.maxWidth - spacing) / 2
            : (constraints.maxWidth - spacing * 3) / 4;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            SizedBox(
              width: width,
              child: _RouletteMetricTile(
                label: _text(i18n, zh: '装填', en: 'Load'),
                value: '$_bulletCount / ${_RouletteGameState._chambers}',
                accent: const Color(0xFFC74C3F),
              ),
            ),
            SizedBox(
              width: width,
              child: _RouletteMetricTile(
                label: _text(i18n, zh: '空膛', en: 'Empty'),
                value: '$_safePullCount',
                accent: const Color(0xFFC9A76C),
              ),
            ),
            SizedBox(
              width: width,
              child: _RouletteMetricTile(
                label: _text(i18n, zh: '剩余', en: 'Remaining'),
                value: '$remaining',
                accent: const Color(0xFF84A9D6),
              ),
            ),
            SizedBox(
              width: width,
              child: _RouletteMetricTile(
                label: _text(i18n, zh: '膛位', en: 'Current'),
                value: '${_activeChamber + 1}',
                accent: const Color(0xFF9BCF9A),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInlineSwitch(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.surfaceContainerLowest.withValues(alpha: 0.9),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, AppI18n i18n) {
    final colors = Theme.of(context).colorScheme;
    final canPrepare =
        _phase == _RoulettePhase.idle ||
        _phase == _RoulettePhase.hit ||
        _phase == _RoulettePhase.exhausted;
    final canPull = _phase == _RoulettePhase.armed;
    final canAdjustLoad = canPrepare;
    final compact = MediaQuery.sizeOf(context).width < 520;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.surfaceContainerHigh,
            Color.alphaBlend(
              const Color(0xFFC74C3F).withValues(alpha: 0.06),
              colors.surfaceContainer,
            ),
          ],
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.gamepad_rounded,
                color: const Color(0xFFC74C3F),
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _text(i18n, zh: '舞台控制', en: 'Stage controls'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _settingsExpanded = !_settingsExpanded;
                  });
                },
                icon: Icon(
                  _settingsExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(_text(i18n, zh: '设置', en: 'Settings')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (compact)
            Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canPrepare ? _prepareRound : null,
                        icon: const Icon(Icons.autorenew_rounded),
                        label: Text(
                          _text(i18n, zh: '旋转弹仓', en: 'Spin cylinder'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canPull ? _pullTrigger : null,
                        icon: const Icon(Icons.warning_amber_rounded),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB3211A),
                          foregroundColor: Colors.white,
                        ),
                        label: Text(
                          _text(i18n, zh: '扣动扳机', en: 'Pull trigger'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _resetRound(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(_text(i18n, zh: '重置本轮', en: 'Reset round')),
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canPrepare ? _prepareRound : null,
                    icon: const Icon(Icons.autorenew_rounded),
                    label: Text(_text(i18n, zh: '旋转弹仓', en: 'Spin cylinder')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canPull ? _pullTrigger : null,
                    icon: const Icon(Icons.warning_amber_rounded),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB3211A),
                      foregroundColor: Colors.white,
                    ),
                    label: Text(_text(i18n, zh: '扣动扳机', en: 'Pull trigger')),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _resetRound(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(_text(i18n, zh: '重置', en: 'Reset')),
                ),
              ],
            ),
          const SizedBox(height: 10),
          _buildMetrics(context, i18n),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _settingsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: colors.surfaceContainerLowest.withValues(
                        alpha: 0.82,
                      ),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              _text(i18n, zh: '装填数量', en: 'Rounds loaded'),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            Text(
                              '$_bulletCount / ${_RouletteGameState._chambers}',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: const Color(0xFFC74C3F),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10,
                            ),
                            activeTrackColor: const Color(0xFFC74C3F),
                            inactiveTrackColor: colors.outlineVariant
                                .withValues(alpha: 0.5),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 18,
                            ),
                          ),
                          child: Slider(
                            value: _bulletCount.toDouble(),
                            min: 1,
                            max: (_RouletteGameState._chambers - 1).toDouble(),
                            divisions: _RouletteGameState._chambers - 2,
                            onChanged: canAdjustLoad
                                ? (value) {
                                    _resetRound(bullets: value.round());
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildInlineSwitch(
                          context,
                          label: _text(i18n, zh: '音效', en: 'SFX'),
                          value: _soundEnabled,
                          onChanged: (value) {
                            setState(() {
                              _soundEnabled = value;
                            });
                            if (!value) {
                              _stopAllEffects();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInlineSwitch(
                          context,
                          label: _text(i18n, zh: '震动', en: 'Haptics'),
                          value: _hapticsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _hapticsEnabled = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_audioFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _text(
                          i18n,
                          zh: '部分音效加载失败，已使用回退反馈。',
                          en: 'Some SFX failed to load. Using fallback feedback now.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _RouletteMetricTile extends StatelessWidget {
  const _RouletteMetricTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.surfaceContainerLowest.withValues(alpha: 0.9),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
