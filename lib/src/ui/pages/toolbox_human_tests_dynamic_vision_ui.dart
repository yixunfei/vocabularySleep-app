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
          label: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.moving_symbol_9705c3',
            ),
          ),
        ),
        ButtonSegment<_DynamicVisionMode>(
          value: _DynamicVisionMode.ballCount,
          icon: const Icon(Icons.bubble_chart_rounded),
          label: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_bimanual.ball_count_6464c6',
            ),
          ),
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
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_cognition.round_7f8e0d',
              ),
              '$symbolRound/$symbolRoundCount',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_cognition.correct_465f00',
              ),
              '$symbolCorrect',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.next_speed_147fb8',
              ),
              formatSpeed(symbolEffectiveSpeed),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.dwell_ab2a6f',
              ),
              _formatMilliseconds(nextDuration.inMilliseconds),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.set_7414d4',
              ),
              symbolSetLabel(i18n, symbolSet),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSymbolSettings(context, i18n),
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
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.done_symbolcorrect_symbolroundcount_f9f171',
              params: <String, Object?>{
                'symbolCorrect': symbolCorrect,
                'symbolRoundCount': symbolRoundCount,
              },
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
        ],
        if (symbolFeedbackKey != null) ...<Widget>[
          Text(
            i18n.t(symbolFeedbackKey!, params: symbolFeedbackParams),
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
              label: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.reset_start_099add',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: symbolRecords.isEmpty
                  ? null
                  : () => unawaited(showSymbolReport()),
              icon: const Icon(Icons.analytics_rounded),
              label: Text(i18n.t('toolbox.sleep.assist.reportCard')),
            ),
          ],
        ),
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
                              i18n.t('toolbox.breathing.done'),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            )
                          : _HumanActionButton(
                              label: i18n.t('toolbox.breathing.start'),
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
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.symbol_settings_21f1db',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.tune_character_set_rounds_path_speed_distractors_and_opt_c01567',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DynamicSettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.test_rounds_74da1b',
            ),
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
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.option_count_37d6de',
            ),
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
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.symbol_group_length_809ff6',
            ),
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
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.base_movement_speed_117a42',
            ),
            valueText: formatSpeed(symbolBaseSpeed),
            value: symbolBaseSpeed,
            min: 0.7,
            max: 1.8,
            divisions: 11,
            onChanged: (value) =>
                unawaited(updateSymbolSetting(() => setSymbolBaseSpeed(value))),
          ),
          _DynamicSettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.vertical_path_amplitude_551861',
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
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.character_set_e10997',
            ),
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
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.movement_path_4690bd',
            ),
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
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.show_faint_distractors_7ee025',
              ),
            ),
            subtitle: Text(
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.distractors_add_visual_load_but_are_never_correct_answer_d4b87c',
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
              labelText: i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.custom_groups_comma_separated_39e8a2',
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
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.apply_custom_groups_6698da',
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DynamicCurveSelector(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.growth_curve_2663ad',
            ),
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
            label: Text(
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.reset_defaults_4512fc',
              ),
            ),
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
            (i18n.t('toolbox.sound.pickup.level'), '$ballLevel'),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.count_range_4f27cd',
              ),
              ballCountRangeLabel,
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.speed_range_4d26d2',
              ),
              ballSpeedRangeLabel,
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory.misses_bcc2a1',
              ),
              '$ballMisses/3',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBallSettings(context, i18n),
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
        if (ballFeedbackKey != null) ...<Widget>[
          _DynamicFeedbackStrip(
            accent: ballLastCorrect == true
                ? const Color(0xFF3F9A6B)
                : Theme.of(context).colorScheme.error,
            icon: ballLastCorrect == true
                ? Icons.check_circle_rounded
                : Icons.info_rounded,
            text: i18n.t(ballFeedbackKey!, params: ballFeedbackParams),
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
                    ? i18n.t(
                        'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.start_over_e567d3',
                      )
                    : ballFeedbackKey == null
                    ? i18n.t('toolbox.breathing.start')
                    : i18n.t(
                        'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.next_round_ad9935',
                      ),
                icon: ballDone
                    ? Icons.restart_alt_rounded
                    : Icons.play_arrow_rounded,
                onPressed: ballDone ? resetBalls : startBallRound,
              ),
            OutlinedButton.icon(
              onPressed: ballShowing || ballAnswering ? null : resetBalls,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(i18n.t('appearanceReset')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.correct_rounds_ca1257',
              ),
              '$ballCorrect',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.best_level_6b13a1',
              ),
              '$ballBestLevel',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.observe_time_41406a',
              ),
              _formatSeconds(ballObservationMs / 1000),
            ),
          ],
        ),
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
                          ? i18n.t(
                              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.how_many_balls_did_you_see_6c4567',
                            )
                          : ballDone
                          ? i18n.t(
                              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.test_over_9eb707',
                            )
                          : i18n.t(
                              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.start_and_count_the_moving_balls_quickly_1cef01',
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
                    text: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.watching_48a062',
                    ),
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
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.ball_count_settings_ce7333',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.tune_starting_count_cap_speed_observe_time_and_growth_cu_f918ef',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DynamicSettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.starting_balls_1dd555',
            ),
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
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.maximum_balls_dc09b1',
            ),
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
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.base_movement_speed_117a42',
            ),
            valueText: formatSpeed(ballBaseSpeed),
            value: ballBaseSpeed,
            min: 0.6,
            max: 1.8,
            divisions: 12,
            onChanged: (value) =>
                unawaited(updateBallSetting(() => setBallBaseSpeed(value))),
          ),
          _DynamicSettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.observe_time_41406a',
            ),
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
              labelText: i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.observe_time_input_seconds_1a66b4',
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
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.ball_color_55f5d1',
            ),
            value: ballColorMode,
            values: _DynamicBallColorMode.values,
            labelFor: (mode) => switch (mode) {
              _DynamicBallColorMode.uniform => i18n.t(
                'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.uniform_4f21a2',
              ),
              _DynamicBallColorMode.varied => i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.varied_660d14',
              ),
            },
            onChanged: (mode) =>
                unawaited(updateBallSetting(() => setBallColorMode(mode))),
          ),
          const SizedBox(height: 8),
          _DynamicCurveSelector(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.growth_curve_2663ad',
            ),
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
            label: Text(
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.reset_defaults_4512fc',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
