part of 'toolbox_human_tests.dart';

class _HandEyeSettingSlider extends StatelessWidget {
  const _HandEyeSettingSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label · $valueText',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueText,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _HandEyeNumberInput extends StatelessWidget {
  const _HandEyeNumberInput({
    required this.label,
    required this.controller,
    required this.onCommit,
    required this.enabled,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onCommit;
  final bool enabled;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus && enabled) {
          onCommit();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: label,
            suffixText: suffix,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: enabled ? (_) => onCommit() : null,
          onEditingComplete: enabled ? onCommit : null,
        ),
      ),
    );
  }
}

extension _HandEyeTapSettingsWidgets on _HandEyeCoordinationCardState {
  Widget _buildTargetSettings(AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HandEyeSettingSlider(
          label: i18n.t('inline.plan294.breathing.rounds_06b0afec'),
          valueText: '$_roundCount',
          value: _roundCount.toDouble(),
          min: 1,
          max: 120,
          divisions: 119,
          onChanged: _settingsLocked ? null : _setRoundCount,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_rounds_3cef7e',
          ),
          controller: _roundCountController,
          suffix: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.rounds_c13d5c',
          ),
          enabled: !_settingsLocked,
          onCommit: () => _applyIntInput(
            controller: _roundCountController,
            min: 1,
            max: 200,
            apply: _setRoundCount,
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.visible_time_cb3bd8',
          ),
          valueText: '${(_displayMs / 1000).toStringAsFixed(2)} s',
          value: _displayMs.toDouble(),
          min: 100,
          max: 5000,
          divisions: 49,
          onChanged: _settingsLocked ? null : _setDisplayMs,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_visible_time_bc5b57',
          ),
          controller: _displayMsController,
          suffix: 'ms',
          enabled: !_settingsLocked,
          onCommit: () => _applyIntInput(
            controller: _displayMsController,
            min: 80,
            max: 10000,
            apply: _setDisplayMs,
          ),
        ),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.vanish_mode_f884ef',
          ),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _HandEyeVisibleMode.values
              .map(
                (mode) => ChoiceChip(
                  label: Text(_visibleModeLabel(i18n, mode)),
                  selected: _visibleMode == mode,
                  onSelected: _settingsLocked
                      ? null
                      : (_) => _setVisibleMode(mode),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.movement_range_1b8c13',
          ),
          valueText: '${(_movementAmplitude * 100).round()}%',
          value: _movementAmplitude,
          min: 0,
          max: 2,
          divisions: 40,
          onChanged: _settingsLocked ? null : _setMovementAmplitude,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_movement_range_6bc3de',
          ),
          controller: _movementAmplitudeController,
          suffix: '%',
          enabled: !_settingsLocked,
          onCommit: () => _applyDoubleInput(
            controller: _movementAmplitudeController,
            min: 0,
            max: 2.5,
            scale: 100,
            apply: _setMovementAmplitude,
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.speed_29ca97',
          ),
          valueText: _movementSpeed == 0
              ? i18n.t('inline.plan295.life.still.05c1a3e01a9c')
              : '${_movementSpeed.toStringAsFixed(1)}x',
          value: _movementSpeed,
          min: 0,
          max: 6,
          divisions: 60,
          onChanged: _settingsLocked ? null : _setMovementSpeed,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_speed_970da9',
          ),
          controller: _movementSpeedController,
          suffix: 'x',
          enabled: !_settingsLocked,
          onCommit: () => _applyDoubleInput(
            controller: _movementSpeedController,
            min: 0,
            max: 8,
            apply: _setMovementSpeed,
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.required_taps_2f692a',
          ),
          valueText: '$_requiredTaps',
          value: _requiredTaps.toDouble(),
          min: 1,
          max: 12,
          divisions: 11,
          onChanged: _settingsLocked ? null : _setRequiredTaps,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_required_taps_446416',
          ),
          controller: _requiredTapsController,
          suffix: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.taps_141d80',
          ),
          enabled: !_settingsLocked,
          onCommit: () => _applyIntInput(
            controller: _requiredTapsController,
            min: 1,
            max: 20,
            apply: _setRequiredTaps,
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t('inline.plan295.life.target_size.f5281cce0aac'),
          valueText: '${_targetDiameter.round()} dp',
          value: _targetDiameter,
          min: 16,
          max: 96,
          divisions: 40,
          onChanged: _settingsLocked ? null : _setTargetDiameter,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_target_size_06db9f',
          ),
          controller: _targetDiameterController,
          suffix: 'dp',
          enabled: !_settingsLocked,
          onCommit: () => _applyDoubleInput(
            controller: _targetDiameterController,
            min: 12,
            max: 120,
            apply: _setTargetDiameter,
          ),
        ),
      ],
    );
  }

  Widget _buildDistractorSettings(AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _distractorEnabled,
          onChanged: _settingsLocked ? null : _setDistractorEnabled,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_hand_eye_settings.multi_target_false_distractors_3b74b0',
            ),
          ),
          subtitle: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_hand_eye_settings.false_targets_do_not_count_as_hits_and_are_reported_sepa_36c979',
            ),
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.spawn_chance_bc1468',
          ),
          valueText: '${(_distractorChance * 100).round()}%',
          value: _distractorChance,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: !_settingsLocked && _distractorEnabled
              ? _setDistractorChance
              : null,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_chance_6c850d',
          ),
          controller: _distractorChanceController,
          suffix: '%',
          enabled: !_settingsLocked && _distractorEnabled,
          onCommit: () => _applyDoubleInput(
            controller: _distractorChanceController,
            min: 0,
            max: 1,
            scale: 100,
            apply: _setDistractorChance,
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.max_false_targets_0345d1',
          ),
          valueText: '$_distractorCount',
          value: _distractorCount.toDouble(),
          min: 1,
          max: 6,
          divisions: 5,
          onChanged: !_settingsLocked && _distractorEnabled
              ? _setDistractorCount
              : null,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_false_target_count_c394b6',
          ),
          controller: _distractorCountController,
          suffix: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.targets_3e7a7e',
          ),
          enabled: !_settingsLocked && _distractorEnabled,
          onCommit: () => _applyIntInput(
            controller: _distractorCountController,
            min: 1,
            max: 8,
            apply: _setDistractorCount,
          ),
        ),
      ],
    );
  }
}

extension _JoystickHandEyeSettingsWidgets on _JoystickHandEyeCardState {
  Widget _buildJoystickSettings(AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.test_mode_64311a',
          ),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _JoystickTestMode.values
              .map(
                (mode) => ChoiceChip(
                  label: Text(_modeLabel(i18n, mode)),
                  selected: _mode == mode,
                  onSelected: _settingsLocked ? null : (_) => _setMode(mode),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        if (_mode == _JoystickTestMode.timed)
          _HandEyeSettingSlider(
            label: i18n.t('toolbox.breathing.duration'),
            valueText: '${_durationSeconds}s',
            value: _durationSeconds.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            onChanged: _settingsLocked ? null : _setDuration,
          )
        else
          _HandEyeSettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_aim.target_total_97e9f3',
            ),
            valueText: '$_targetGoal',
            value: _targetGoal.toDouble(),
            min: 1,
            max: 120,
            divisions: 119,
            onChanged: _settingsLocked ? null : _setTargetGoal,
          ),
        if (_mode == _JoystickTestMode.timed)
          _HandEyeNumberInput(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_duration_55d8d9',
            ),
            controller: _durationController,
            suffix: 's',
            enabled: !_settingsLocked,
            onCommit: () => _applyIntInput(
              controller: _durationController,
              min: 3,
              max: 600,
              apply: _setDuration,
            ),
          )
        else
          _HandEyeNumberInput(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_target_total_93b081',
            ),
            controller: _targetGoalController,
            suffix: i18n.t(
              'inline.ui.pages.toolbox_human_tests_hand_eye_settings.targets_3e7a7e',
            ),
            enabled: !_settingsLocked,
            onCommit: () => _applyIntInput(
              controller: _targetGoalController,
              min: 1,
              max: 300,
              apply: _setTargetGoal,
            ),
          ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.response_speed_45096d',
          ),
          valueText: '${_crosshairSpeed.toStringAsFixed(1)}x',
          value: _crosshairSpeed,
          min: 0.2,
          max: 6,
          divisions: 58,
          onChanged: _settingsLocked ? null : _setCrosshairSpeed,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_response_fc1ddf',
          ),
          controller: _crosshairSpeedController,
          suffix: 'x',
          enabled: !_settingsLocked,
          onCommit: () => _applyDoubleInput(
            controller: _crosshairSpeedController,
            min: 0.1,
            max: 10,
            apply: _setCrosshairSpeed,
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.joystick_acceleration_cd9120',
          ),
          valueText: '${_joystickAcceleration.toStringAsFixed(1)}x',
          value: _joystickAcceleration,
          min: 0,
          max: 7,
          divisions: 70,
          onChanged: _settingsLocked ? null : _setJoystickAcceleration,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_acceleration_17d78d',
          ),
          controller: _joystickAccelerationController,
          suffix: 'x',
          enabled: !_settingsLocked,
          onCommit: () => _applyDoubleInput(
            controller: _joystickAccelerationController,
            min: 0,
            max: 8,
            apply: _setJoystickAcceleration,
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_aim_widgets.target_size_2f3de4',
          ),
          valueText: '${_targetDiameter.round()} dp',
          value: _targetDiameter,
          min: 18,
          max: 96,
          divisions: 39,
          onChanged: _settingsLocked ? null : _setTargetDiameter,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_target_size_06db9f',
          ),
          controller: _targetDiameterController,
          suffix: 'dp',
          enabled: !_settingsLocked,
          onCommit: () => _applyDoubleInput(
            controller: _targetDiameterController,
            min: 14,
            max: 120,
            apply: _setTargetDiameter,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.after_hit_40885b',
          ),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.immediate_1d793e',
                ),
              ),
              selected: !_randomRespawnDelay,
              onSelected: _settingsLocked
                  ? null
                  : (_) => _updateView(() => _randomRespawnDelay = false),
            ),
            ChoiceChip(
              label: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_hand_eye_joystick.random_delay_c5fe81',
                ),
              ),
              selected: _randomRespawnDelay,
              onSelected: _settingsLocked
                  ? null
                  : (_) => _updateView(() => _randomRespawnDelay = true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.current_respawn_spawnlabel_i18n_55aef0',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildJoystickMovementSettings(AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _targetMovementEnabled,
          onChanged: _settingsLocked ? null : _setTargetMovementEnabled,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_hand_eye_settings.enable_target_movement_577b99',
            ),
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.movement_range_1b8c13',
          ),
          valueText: '${(_targetMovementRange * 100).round()}%',
          value: _targetMovementRange,
          min: 0,
          max: 1.4,
          divisions: 28,
          onChanged: !_settingsLocked && _targetMovementEnabled
              ? _setTargetMovementRange
              : null,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_movement_range_6bc3de',
          ),
          controller: _targetMovementRangeController,
          suffix: '%',
          enabled: !_settingsLocked && _targetMovementEnabled,
          onCommit: () => _applyDoubleInput(
            controller: _targetMovementRangeController,
            min: 0,
            max: 2,
            scale: 100,
            apply: _setTargetMovementRange,
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.target_move_speed_2378af',
          ),
          valueText: '${_targetMovementSpeed.toStringAsFixed(1)}x',
          value: _targetMovementSpeed,
          min: 0,
          max: 4,
          divisions: 40,
          onChanged: !_settingsLocked && _targetMovementEnabled
              ? _setTargetMovementSpeed
              : null,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_move_speed_728109',
          ),
          controller: _targetMovementSpeedController,
          suffix: 'x',
          enabled: !_settingsLocked && _targetMovementEnabled,
          onCommit: () => _applyDoubleInput(
            controller: _targetMovementSpeedController,
            min: 0,
            max: 6,
            apply: _setTargetMovementSpeed,
          ),
        ),
      ],
    );
  }

  Widget _buildJoystickDistractorSettings(AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _distractorEnabled,
          onChanged: _settingsLocked ? null : _setDistractorEnabled,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_hand_eye_settings.multi_target_false_distractors_3b74b0',
            ),
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.spawn_chance_bc1468',
          ),
          valueText: '${(_distractorChance * 100).round()}%',
          value: _distractorChance,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: !_settingsLocked && _distractorEnabled
              ? _setDistractorChance
              : null,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_chance_6c850d',
          ),
          controller: _distractorChanceController,
          suffix: '%',
          enabled: !_settingsLocked && _distractorEnabled,
          onCommit: () => _applyDoubleInput(
            controller: _distractorChanceController,
            min: 0,
            max: 1,
            scale: 100,
            apply: _setDistractorChance,
          ),
        ),
        _HandEyeSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.max_false_targets_0345d1',
          ),
          valueText: '$_distractorCount',
          value: _distractorCount.toDouble(),
          min: 1,
          max: 6,
          divisions: 5,
          onChanged: !_settingsLocked && _distractorEnabled
              ? _setDistractorCount
              : null,
        ),
        _HandEyeNumberInput(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.custom_false_target_count_c394b6',
          ),
          controller: _distractorCountController,
          suffix: i18n.t(
            'inline.ui.pages.toolbox_human_tests_hand_eye_settings.targets_3e7a7e',
          ),
          enabled: !_settingsLocked && _distractorEnabled,
          onCommit: () => _applyIntInput(
            controller: _distractorCountController,
            min: 1,
            max: 8,
            apply: _setDistractorCount,
          ),
        ),
      ],
    );
  }
}
