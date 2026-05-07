part of 'toolbox_human_tests.dart';

extension _DynamicVisionCardUi on _DynamicVisionCardState {
  Widget buildDynamicVisionBody(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildModeSwitcher(context, i18n),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInQuad,
          child: mode == _DynamicVisionMode.symbol
              ? _buildSymbolMode(context, i18n)
              : _buildBallCountMode(context, i18n),
        ),
      ],
    );
  }

  Widget _buildModeSwitcher(BuildContext context, AppI18n i18n) {
    return SegmentedButton<_DynamicVisionMode>(
      segments: <ButtonSegment<_DynamicVisionMode>>[
        ButtonSegment<_DynamicVisionMode>(
          value: _DynamicVisionMode.symbol,
          icon: const Icon(Icons.text_fields_rounded),
          label: Text(pickUiText(i18n, zh: '字符识别', en: 'Moving symbol')),
        ),
        ButtonSegment<_DynamicVisionMode>(
          value: _DynamicVisionMode.ballCount,
          icon: const Icon(Icons.bubble_chart_rounded),
          label: Text(pickUiText(i18n, zh: '小球数量', en: 'Ball count')),
        ),
      ],
      selected: <_DynamicVisionMode>{mode},
      onSelectionChanged: (values) => unawaited(changeMode(values.first)),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll<TextStyle>(
          Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800) ??
              const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildSymbolMode(BuildContext context, AppI18n i18n) {
    final nextDuration = symbolDurationForRound(
      (symbolRound + 1).clamp(1, symbolRoundCount),
    );
    return Column(
      key: const ValueKey<_DynamicVisionMode>(_DynamicVisionMode.symbol),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '轮次', en: 'Round'),
              '$symbolRound/$symbolRoundCount',
            ),
            (pickUiText(i18n, zh: '正确', en: 'Correct'), '$symbolCorrect'),
            (
              pickUiText(i18n, zh: '下轮速度', en: 'Next speed'),
              formatSpeed(symbolEffectiveSpeed),
            ),
            (
              pickUiText(i18n, zh: '显示时间', en: 'Dwell'),
              _formatMilliseconds(nextDuration.inMilliseconds),
            ),
            (
              pickUiText(i18n, zh: '字符集', en: 'Set'),
              symbolSetLabel(i18n, symbolSet),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: EdgeInsets.zero,
          child: buildSymbolStage(context, i18n),
        ),
        const SizedBox(height: 12),
        if (symbolChoosing)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: symbolOptions
                .map(
                  (value) => SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => chooseSymbol(value),
                      child: Text(value),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        if (symbolDone) ...<Widget>[
          Text(
            pickUiText(
              i18n,
              zh: '完成：$symbolCorrect / $symbolRoundCount',
              en: 'Done: $symbolCorrect / $symbolRoundCount',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
        ],
        if (symbolFeedbackZh != null) ...<Widget>[
          Text(
            pickUiText(i18n, zh: symbolFeedbackZh!, en: symbolFeedbackEn!),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: symbolLastCorrect == false
                  ? Theme.of(context).colorScheme.error
                  : accent,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: symbolChoosing ? null : resetSymbol,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(pickUiText(i18n, zh: '重置开始', en: 'Reset start')),
            ),
            OutlinedButton.icon(
              onPressed: symbolRecords.isEmpty
                  ? null
                  : () => unawaited(showSymbolReport()),
              icon: const Icon(Icons.analytics_rounded),
              label: Text(pickUiText(i18n, zh: '查看报告', en: 'Report')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSymbolSettings(context, i18n),
      ],
    );
  }

  Widget buildSymbolStage(BuildContext context, AppI18n i18n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * 0.58).clamp(220.0, 310.0);
        final size = Size(constraints.maxWidth, height);
        return SizedBox(
          width: size.width,
          height: size.height,
          child: AnimatedBuilder(
            animation: symbolAnimation,
            builder: (context, child) {
              final value = Curves.linear.transform(symbolAnimation.value);
              final position = symbolPositionFor(value, size);
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  if (symbolShowing)
                    ...symbolDistractors.map((item) {
                      return Positioned(
                        left: (item.dx * size.width).clamp(
                          12.0,
                          size.width - 48,
                        ),
                        top: (item.dy * size.height).clamp(
                          12.0,
                          size.height - 48,
                        ),
                        child: Opacity(
                          opacity: 0.22,
                          child: Text(
                            item.value,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      );
                    }),
                  if (symbolShowing)
                    Positioned(
                      left: position.dx,
                      top: position.dy,
                      child: Text(
                        symbolTarget,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    )
                  else
                    Center(
                      child: symbolDone
                          ? Text(
                              pickUiText(i18n, zh: '完成', en: 'Done'),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            )
                          : _HumanActionButton(
                              label: pickUiText(i18n, zh: '开始', en: 'Start'),
                              icon: Icons.play_arrow_rounded,
                              onPressed: startSymbolRound,
                            ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSymbolSettings(BuildContext context, AppI18n i18n) {
    return _HumanSettingsSection(
      title: pickUiText(i18n, zh: '字符识别设置', en: 'Symbol settings'),
      subtitle: pickUiText(
        i18n,
        zh: '调整字符集、轮次数、轨迹、速度、干扰和选项数量',
        en: 'Tune character set, rounds, path, speed, distractors, and option count',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DynamicSettingSlider(
            label: pickUiText(i18n, zh: '测试轮次数', en: 'Test rounds'),
            valueText: '$symbolRoundCount',
            value: symbolRoundCount.toDouble(),
            min: 5,
            max: 15,
            divisions: 10,
            onChanged: (value) => unawaited(
              updateSymbolSetting(() => setSymbolRoundCount(value.round())),
            ),
          ),
          _DynamicSettingSlider(
            label: pickUiText(i18n, zh: '选项数量', en: 'Option count'),
            valueText: '$symbolOptionCount',
            value: symbolOptionCount.toDouble(),
            min: 2,
            max: 6,
            divisions: 4,
            onChanged: (value) => unawaited(
              updateSymbolSetting(() => setSymbolOptionCount(value.round())),
            ),
          ),
          _DynamicSettingSlider(
            label: pickUiText(i18n, zh: '字符组合长度', en: 'Symbol group length'),
            valueText: '$symbolGroupLength',
            value: symbolGroupLength.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            onChanged: (value) => unawaited(
              updateSymbolSetting(() => setSymbolGroupLength(value.round())),
            ),
          ),
          _DynamicSettingSlider(
            label: pickUiText(i18n, zh: '基础移动速度', en: 'Base movement speed'),
            valueText: formatSpeed(symbolBaseSpeed),
            value: symbolBaseSpeed,
            min: 0.7,
            max: 1.8,
            divisions: 11,
            onChanged: (value) =>
                unawaited(updateSymbolSetting(() => setSymbolBaseSpeed(value))),
          ),
          _DynamicSettingSlider(
            label: pickUiText(
              i18n,
              zh: '上下摆动幅度',
              en: 'Vertical path amplitude',
            ),
            valueText: '${(symbolWaveAmplitude * 100).round()}%',
            value: symbolWaveAmplitude,
            min: 0.08,
            max: 0.28,
            divisions: 10,
            onChanged: (value) => unawaited(
              updateSymbolSetting(() => setSymbolWaveAmplitude(value)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(i18n, zh: '字符集', en: 'Character set'),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _DynamicSymbolSet.values
                .map(
                  (set) => ChoiceChip(
                    label: Text(symbolSetLabel(i18n, set)),
                    selected: symbolSet == set,
                    onSelected: (_) =>
                        unawaited(updateSymbolSetting(() => setSymbolSet(set))),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            pickUiText(i18n, zh: '移动轨迹', en: 'Movement path'),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _DynamicSymbolPath.values
                .map(
                  (path) => ChoiceChip(
                    label: Text(symbolPathLabel(i18n, path)),
                    selected: symbolPath == path,
                    onSelected: (_) => unawaited(
                      updateSymbolSetting(() => setSymbolPath(path)),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: symbolDistractorEnabled,
            title: Text(
              pickUiText(i18n, zh: '显示弱干扰字符', en: 'Show faint distractors'),
            ),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '干扰只影响识别压力，不参与答案。',
                en: 'Distractors add visual load but are never correct answers.',
              ),
            ),
            onChanged: (value) => unawaited(
              updateSymbolSetting(() => setSymbolDistractorEnabled(value)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: symbolCustomController,
            decoration: InputDecoration(
              labelText: pickUiText(
                i18n,
                zh: '自定义组合（逗号分割）',
                en: 'Custom groups (comma separated)',
              ),
              hintText: 'AB, 82, F9',
              border: const OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 2,
            onSubmitted: (value) => unawaited(
              updateSymbolSetting(() => setSymbolCustomSource(value.trim())),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => unawaited(
              updateSymbolSetting(
                () => setSymbolCustomSource(symbolCustomController.text.trim()),
              ),
            ),
            icon: const Icon(Icons.done_rounded),
            label: Text(
              pickUiText(i18n, zh: '应用自定义组合', en: 'Apply custom groups'),
            ),
          ),
          const SizedBox(height: 8),
          _DynamicCurveSelector(
            label: pickUiText(i18n, zh: '增长曲线', en: 'Growth curve'),
            value: symbolCurve,
            enabled: true,
            labelFor: (curve) => curveLabel(i18n, curve),
            onChanged: (curve) =>
                unawaited(updateSymbolSetting(() => setSymbolCurve(curve))),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => unawaited(
              updateSymbolSetting(() {
                setSymbolRoundCount(10);
                setSymbolGroupLength(1);
                setSymbolOptionCount(4);
                setSymbolCustomSource('');
                symbolCustomController.text = '';
                setSymbolBaseSpeed(1.0);
                setSymbolWaveAmplitude(0.18);
                setSymbolCurve(_DynamicVisionGrowthCurve.linear);
                setSymbolSet(_DynamicSymbolSet.mixed);
                setSymbolPath(_DynamicSymbolPath.wave);
                setSymbolDistractorEnabled(false);
              }),
            ),
            icon: const Icon(Icons.settings_backup_restore_rounded),
            label: Text(pickUiText(i18n, zh: '恢复默认', en: 'Reset defaults')),
          ),
        ],
      ),
    );
  }

  Widget _buildBallCountMode(BuildContext context, AppI18n i18n) {
    return Column(
      key: const ValueKey<_DynamicVisionMode>(_DynamicVisionMode.ballCount),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '等级', en: 'Level'), '$ballLevel'),
            (
              pickUiText(i18n, zh: '数量范围', en: 'Count range'),
              ballCountRangeLabel,
            ),
            (
              pickUiText(i18n, zh: '速度范围', en: 'Speed range'),
              ballSpeedRangeLabel,
            ),
            (pickUiText(i18n, zh: '失误', en: 'Misses'), '$ballMisses/3'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: EdgeInsets.zero,
          child: buildBallStage(context, i18n),
        ),
        const SizedBox(height: 12),
        if (ballAnswering)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ballOptions
                .map(
                  (value) => SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => chooseBallCount(value),
                      child: Text('$value'),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        if (ballFeedbackZh != null) ...<Widget>[
          _DynamicFeedbackStrip(
            accent: ballLastCorrect == true
                ? const Color(0xFF3F9A6B)
                : Theme.of(context).colorScheme.error,
            icon: ballLastCorrect == true
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            text: pickUiText(i18n, zh: ballFeedbackZh!, en: ballFeedbackEn!),
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            if (!ballShowing && !ballAnswering)
              _HumanActionButton(
                label: ballDone
                    ? pickUiText(i18n, zh: '重新开始', en: 'Start over')
                    : ballFeedbackZh == null
                    ? pickUiText(i18n, zh: '开始', en: 'Start')
                    : pickUiText(i18n, zh: '下一轮', en: 'Next round'),
                icon: ballDone
                    ? Icons.restart_alt_rounded
                    : Icons.play_arrow_rounded,
                onPressed: ballDone ? resetBalls : startBallRound,
              ),
            OutlinedButton.icon(
              onPressed: ballShowing || ballAnswering ? null : resetBalls,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '正确轮数', en: 'Correct rounds'),
              '$ballCorrect',
            ),
            (pickUiText(i18n, zh: '最佳等级', en: 'Best level'), '$ballBestLevel'),
            (
              pickUiText(i18n, zh: '观察时长', en: 'Observe time'),
              _formatSeconds(ballObservationMs / 1000),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBallSettings(context, i18n),
      ],
    );
  }

  Widget buildBallStage(BuildContext context, AppI18n i18n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * 0.64).clamp(230.0, 330.0);
        final size = Size(constraints.maxWidth, height);
        setLastBallStageSize(size);
        return SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _DynamicVisionBallPainter(
                    balls: visibleBalls,
                    accent: accent,
                    surface: Theme.of(context).colorScheme.surface,
                    outline: Theme.of(context).colorScheme.outlineVariant,
                    repaint: ballAnimation,
                  ),
                ),
              ),
              if (!ballShowing)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      ballAnswering
                          ? pickUiText(
                              i18n,
                              zh: '刚才有多少个小球？',
                              en: 'How many balls did you see?',
                            )
                          : ballDone
                          ? pickUiText(i18n, zh: '测试结束', en: 'Test over')
                          : pickUiText(
                              i18n,
                              zh: '开始后快速数出移动小球数量',
                              en: 'Start and count the moving balls quickly',
                            ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              if (ballShowing)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _HumanPill(
                    text: pickUiText(i18n, zh: '观察中', en: 'Watching'),
                    accent: accent,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBallSettings(BuildContext context, AppI18n i18n) {
    return _HumanSettingsSection(
      title: pickUiText(i18n, zh: '小球数量设置', en: 'Ball count settings'),
      subtitle: pickUiText(
        i18n,
        zh: '调整起始数量、上限、速度、观察时长与增长曲线',
        en: 'Tune starting count, cap, speed, observe time, and growth curve',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DynamicSettingSlider(
            label: pickUiText(i18n, zh: '起始小球数量', en: 'Starting balls'),
            valueText: '$ballStartCount',
            value: ballStartCount.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            onChanged: (value) => unawaited(
              updateBallSetting(() => setBallStartCount(value.round())),
            ),
          ),
          _DynamicSettingSlider(
            label: pickUiText(i18n, zh: '最大小球数量', en: 'Maximum balls'),
            valueText: '$ballMaxCount',
            value: ballMaxCount.toDouble(),
            min: 6,
            max: 18,
            divisions: 12,
            onChanged: (value) => unawaited(
              updateBallSetting(() => setBallMaxCount(value.round())),
            ),
          ),
          _DynamicSettingSlider(
            label: pickUiText(i18n, zh: '基础移动速度', en: 'Base movement speed'),
            valueText: formatSpeed(ballBaseSpeed),
            value: ballBaseSpeed,
            min: 0.6,
            max: 1.8,
            divisions: 12,
            onChanged: (value) =>
                unawaited(updateBallSetting(() => setBallBaseSpeed(value))),
          ),
          _DynamicSettingSlider(
            label: pickUiText(i18n, zh: '观察时长', en: 'Observe time'),
            valueText: _formatSeconds(ballObservationMs / 1000),
            value: ballObservationMs.toDouble(),
            min: 800,
            max: 12000,
            divisions: 56,
            onChanged: (value) => unawaited(
              updateBallSetting(() => setBallObservationMs(value.round())),
            ),
          ),
          TextField(
            controller: ballObservationController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: pickUiText(
                i18n,
                zh: '观察时长输入（秒）',
                en: 'Observe time input (seconds)',
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              final milliseconds = parseObservationMilliseconds(value);
              if (milliseconds == null) {
                ballObservationController.text = formatObservationInput(
                  ballObservationMs,
                );
                return;
              }
              unawaited(
                updateBallSetting(() => setBallObservationMs(milliseconds)),
              );
            },
          ),
          const SizedBox(height: 8),
          _DynamicEnumChoice<_DynamicBallColorMode>(
            label: pickUiText(i18n, zh: '小球颜色', en: 'Ball color'),
            value: ballColorMode,
            values: _DynamicBallColorMode.values,
            labelFor: (mode) => switch (mode) {
              _DynamicBallColorMode.uniform => pickUiText(
                i18n,
                zh: '同色',
                en: 'Uniform',
              ),
              _DynamicBallColorMode.varied => pickUiText(
                i18n,
                zh: '多色',
                en: 'Varied',
              ),
            },
            onChanged: (mode) =>
                unawaited(updateBallSetting(() => setBallColorMode(mode))),
          ),
          const SizedBox(height: 8),
          _DynamicCurveSelector(
            label: pickUiText(i18n, zh: '增长曲线', en: 'Growth curve'),
            value: ballCurve,
            enabled: true,
            labelFor: (curve) => curveLabel(i18n, curve),
            onChanged: (curve) =>
                unawaited(updateBallSetting(() => setBallCurve(curve))),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => unawaited(
              updateBallSetting(() {
                setBallStartCount(3);
                setBallMaxCount(12);
                setBallBaseSpeed(1.0);
                setBallObservationMs(2200);
                setBallColorMode(_DynamicBallColorMode.uniform);
                setBallCurve(_DynamicVisionGrowthCurve.linear);
              }),
            ),
            icon: const Icon(Icons.settings_backup_restore_rounded),
            label: Text(pickUiText(i18n, zh: '恢复默认', en: 'Reset defaults')),
          ),
        ],
      ),
    );
  }
}
