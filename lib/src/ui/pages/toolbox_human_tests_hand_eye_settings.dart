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
    required this.onApply,
    required this.enabled,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onApply;
  final bool enabled;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: label,
                suffixText: suffix,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: enabled ? (_) => onApply() : null,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: enabled ? onApply : null,
            icon: const Icon(Icons.check_rounded),
            label: Text(pickUiText(i18n, zh: '应用', en: 'Apply')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(88, 48),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
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
          label: pickUiText(i18n, zh: '轮数', en: 'Rounds'),
          valueText: '$_roundCount',
          value: _roundCount.toDouble(),
          min: 1,
          max: 120,
          divisions: 119,
          onChanged: _active ? null : _setRoundCount,
        ),
        _HandEyeNumberInput(
          label: pickUiText(i18n, zh: '自定义轮数', en: 'Custom rounds'),
          controller: _roundCountController,
          suffix: pickUiText(i18n, zh: '轮', en: 'rounds'),
          enabled: !_active,
          onApply: () => _applyIntInput(
            controller: _roundCountController,
            min: 1,
            max: 200,
            apply: _setRoundCount,
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '显示移动时长', en: 'Visible time'),
          valueText: '${(_displayMs / 1000).toStringAsFixed(2)} s',
          value: _displayMs.toDouble(),
          min: 100,
          max: 5000,
          divisions: 49,
          onChanged: _active ? null : _setDisplayMs,
        ),
        _HandEyeNumberInput(
          label: pickUiText(i18n, zh: '自定义显示时长', en: 'Custom visible time'),
          controller: _displayMsController,
          suffix: 'ms',
          enabled: !_active,
          onApply: () => _applyIntInput(
            controller: _displayMsController,
            min: 80,
            max: 10000,
            apply: _setDisplayMs,
          ),
        ),
        Text(
          pickUiText(i18n, zh: '消失方式', en: 'Vanish mode'),
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
                  onSelected: _active ? null : (_) => _setVisibleMode(mode),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '随机运动幅度', en: 'Movement range'),
          valueText: '${(_movementAmplitude * 100).round()}%',
          value: _movementAmplitude,
          min: 0,
          max: 2,
          divisions: 40,
          onChanged: _active ? null : _setMovementAmplitude,
        ),
        _HandEyeNumberInput(
          label: pickUiText(i18n, zh: '自定义运动幅度', en: 'Custom movement range'),
          controller: _movementAmplitudeController,
          suffix: '%',
          enabled: !_active,
          onApply: () => _applyDoubleInput(
            controller: _movementAmplitudeController,
            min: 0,
            max: 2.5,
            scale: 100,
            apply: _setMovementAmplitude,
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '速度', en: 'Speed'),
          valueText: _movementSpeed == 0
              ? pickUiText(i18n, zh: '不移动', en: 'Still')
              : '${_movementSpeed.toStringAsFixed(1)}x',
          value: _movementSpeed,
          min: 0,
          max: 6,
          divisions: 60,
          onChanged: _active ? null : _setMovementSpeed,
        ),
        _HandEyeNumberInput(
          label: pickUiText(i18n, zh: '自定义速度', en: 'Custom speed'),
          controller: _movementSpeedController,
          suffix: 'x',
          enabled: !_active,
          onApply: () => _applyDoubleInput(
            controller: _movementSpeedController,
            min: 0,
            max: 8,
            apply: _setMovementSpeed,
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '需要点击次数', en: 'Required taps'),
          valueText: '$_requiredTaps',
          value: _requiredTaps.toDouble(),
          min: 1,
          max: 12,
          divisions: 11,
          onChanged: _active ? null : _setRequiredTaps,
        ),
        _HandEyeNumberInput(
          label: pickUiText(i18n, zh: '自定义点击次数', en: 'Custom required taps'),
          controller: _requiredTapsController,
          suffix: pickUiText(i18n, zh: '次', en: 'taps'),
          enabled: !_active,
          onApply: () => _applyIntInput(
            controller: _requiredTapsController,
            min: 1,
            max: 20,
            apply: _setRequiredTaps,
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '目标点大小', en: 'Target size'),
          valueText: '${_targetDiameter.round()} dp',
          value: _targetDiameter,
          min: 16,
          max: 96,
          divisions: 40,
          onChanged: _active ? null : _setTargetDiameter,
        ),
        _HandEyeNumberInput(
          label: pickUiText(i18n, zh: '自定义目标大小', en: 'Custom target size'),
          controller: _targetDiameterController,
          suffix: 'dp',
          enabled: !_active,
          onApply: () => _applyDoubleInput(
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
          onChanged: _active ? null : _setDistractorEnabled,
          title: Text(
            pickUiText(
              i18n,
              zh: '多目标真假干扰',
              en: 'Multi-target false distractors',
            ),
          ),
          subtitle: Text(
            pickUiText(
              i18n,
              zh: '假目标不会计入命中，会在报告中单独统计。',
              en: 'False targets do not count as hits and are reported separately.',
            ),
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '出现概率', en: 'Spawn chance'),
          valueText: '${(_distractorChance * 100).round()}%',
          value: _distractorChance,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: !_active && _distractorEnabled
              ? _setDistractorChance
              : null,
        ),
        _HandEyeNumberInput(
          label: pickUiText(i18n, zh: '自定义概率', en: 'Custom chance'),
          controller: _distractorChanceController,
          suffix: '%',
          enabled: !_active && _distractorEnabled,
          onApply: () => _applyDoubleInput(
            controller: _distractorChanceController,
            min: 0,
            max: 1,
            scale: 100,
            apply: _setDistractorChance,
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '最大假目标数', en: 'Max false targets'),
          valueText: '$_distractorCount',
          value: _distractorCount.toDouble(),
          min: 1,
          max: 6,
          divisions: 5,
          onChanged: !_active && _distractorEnabled
              ? _setDistractorCount
              : null,
        ),
        _HandEyeNumberInput(
          label: pickUiText(
            i18n,
            zh: '自定义假目标数',
            en: 'Custom false target count',
          ),
          controller: _distractorCountController,
          suffix: pickUiText(i18n, zh: '个', en: 'targets'),
          enabled: !_active && _distractorEnabled,
          onApply: () => _applyIntInput(
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
          pickUiText(i18n, zh: '测试方案', en: 'Test mode'),
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
            label: pickUiText(i18n, zh: '测试时长', en: 'Duration'),
            valueText: '${_durationSeconds}s',
            value: _durationSeconds.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            onChanged: _settingsLocked ? null : _setDuration,
          )
        else
          _HandEyeSettingSlider(
            label: pickUiText(i18n, zh: '目标总数', en: 'Target total'),
            valueText: '$_targetGoal',
            value: _targetGoal.toDouble(),
            min: 1,
            max: 120,
            divisions: 119,
            onChanged: _settingsLocked ? null : _setTargetGoal,
          ),
        if (_mode == _JoystickTestMode.timed)
          _HandEyeNumberInput(
            label: pickUiText(i18n, zh: '自定义时长', en: 'Custom duration'),
            controller: _durationController,
            suffix: 's',
            enabled: !_settingsLocked,
            onApply: () => _applyIntInput(
              controller: _durationController,
              min: 3,
              max: 600,
              apply: _setDuration,
            ),
          )
        else
          _HandEyeNumberInput(
            label: pickUiText(i18n, zh: '自定义目标数', en: 'Custom target total'),
            controller: _targetGoalController,
            suffix: pickUiText(i18n, zh: '个', en: 'targets'),
            enabled: !_settingsLocked,
            onApply: () => _applyIntInput(
              controller: _targetGoalController,
              min: 1,
              max: 300,
              apply: _setTargetGoal,
            ),
          ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '摇杆响应位移速率', en: 'Response speed'),
          valueText: '${_crosshairSpeed.toStringAsFixed(1)}x',
          value: _crosshairSpeed,
          min: 0.2,
          max: 6,
          divisions: 58,
          onChanged: _settingsLocked ? null : _setCrosshairSpeed,
        ),
        _HandEyeNumberInput(
          label: pickUiText(i18n, zh: '自定义响应速率', en: 'Custom response'),
          controller: _crosshairSpeedController,
          suffix: 'x',
          enabled: !_settingsLocked,
          onApply: () => _applyDoubleInput(
            controller: _crosshairSpeedController,
            min: 0.1,
            max: 10,
            apply: _setCrosshairSpeed,
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '摇杆位置加速', en: 'Joystick acceleration'),
          valueText: '${_joystickAcceleration.toStringAsFixed(1)}x',
          value: _joystickAcceleration,
          min: 0,
          max: 7,
          divisions: 70,
          onChanged: _settingsLocked ? null : _setJoystickAcceleration,
        ),
        _HandEyeNumberInput(
          label: pickUiText(i18n, zh: '自定义摇杆加速', en: 'Custom acceleration'),
          controller: _joystickAccelerationController,
          suffix: 'x',
          enabled: !_settingsLocked,
          onApply: () => _applyDoubleInput(
            controller: _joystickAccelerationController,
            min: 0,
            max: 8,
            apply: _setJoystickAcceleration,
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '目标大小', en: 'Target size'),
          valueText: '${_targetDiameter.round()} dp',
          value: _targetDiameter,
          min: 18,
          max: 96,
          divisions: 39,
          onChanged: _settingsLocked ? null : _setTargetDiameter,
        ),
        _HandEyeNumberInput(
          label: pickUiText(i18n, zh: '自定义目标大小', en: 'Custom target size'),
          controller: _targetDiameterController,
          suffix: 'dp',
          enabled: !_settingsLocked,
          onApply: () => _applyDoubleInput(
            controller: _targetDiameterController,
            min: 14,
            max: 120,
            apply: _setTargetDiameter,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          pickUiText(i18n, zh: '命中后刷新', en: 'After hit'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: Text(pickUiText(i18n, zh: '立即刷新', en: 'Immediate')),
              selected: !_randomRespawnDelay,
              onSelected: _settingsLocked
                  ? null
                  : (_) => _updateView(() => _randomRespawnDelay = false),
            ),
            ChoiceChip(
              label: Text(pickUiText(i18n, zh: '随机延迟', en: 'Random delay')),
              selected: _randomRespawnDelay,
              onSelected: _settingsLocked
                  ? null
                  : (_) => _updateView(() => _randomRespawnDelay = true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          pickUiText(
            i18n,
            zh: '当前刷新方式：${_spawnLabel(i18n)}。',
            en: 'Current respawn: ${_spawnLabel(i18n)}.',
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
            pickUiText(i18n, zh: '启用目标移动', en: 'Enable target movement'),
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '移动幅度', en: 'Movement range'),
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
          label: pickUiText(i18n, zh: '自定义移动幅度', en: 'Custom movement range'),
          controller: _targetMovementRangeController,
          suffix: '%',
          enabled: !_settingsLocked && _targetMovementEnabled,
          onApply: () => _applyDoubleInput(
            controller: _targetMovementRangeController,
            min: 0,
            max: 2,
            scale: 100,
            apply: _setTargetMovementRange,
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '目标移动速度', en: 'Target move speed'),
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
          label: pickUiText(i18n, zh: '自定义移动速度', en: 'Custom move speed'),
          controller: _targetMovementSpeedController,
          suffix: 'x',
          enabled: !_settingsLocked && _targetMovementEnabled,
          onApply: () => _applyDoubleInput(
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
            pickUiText(
              i18n,
              zh: '多目标假目标干扰',
              en: 'Multi-target false distractors',
            ),
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '出现概率', en: 'Spawn chance'),
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
          label: pickUiText(i18n, zh: '自定义概率', en: 'Custom chance'),
          controller: _distractorChanceController,
          suffix: '%',
          enabled: !_settingsLocked && _distractorEnabled,
          onApply: () => _applyDoubleInput(
            controller: _distractorChanceController,
            min: 0,
            max: 1,
            scale: 100,
            apply: _setDistractorChance,
          ),
        ),
        _HandEyeSettingSlider(
          label: pickUiText(i18n, zh: '最大假目标数', en: 'Max false targets'),
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
          label: pickUiText(
            i18n,
            zh: '自定义假目标数',
            en: 'Custom false target count',
          ),
          controller: _distractorCountController,
          suffix: pickUiText(i18n, zh: '个', en: 'targets'),
          enabled: !_settingsLocked && _distractorEnabled,
          onApply: () => _applyIntInput(
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
