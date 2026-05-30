part of 'toolbox_human_tests.dart';

extension _NumberMemoryView on _NumberMemoryCardState {
  List<Widget> _buildModeDetailSettings(BuildContext context, AppI18n i18n) {
    return switch (_mode) {
      _NumberMemoryMode.coloredDigits => <Widget>[
        const SizedBox(height: 12),
        _NumberMemorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_memory.color_count_47de48',
          ),
          valueText: '$_colorCount',
          value: _colorCount.toDouble(),
          min: 3,
          max: _NumberMemoryCardState._colorPalette.length.toDouble(),
          divisions: _NumberMemoryCardState._colorPalette.length - 3,
          onChanged: _roundBusy
              ? null
              : (value) => _applySetting(() => _colorCount = value.round()),
        ),
        _buildColorPreview(context, i18n),
      ],
      _NumberMemoryMode.multiTarget => <Widget>[
        const SizedBox(height: 12),
        _NumberMemorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_number_memory_view.visible_groups_f44f71',
          ),
          valueText: '$_targetGroupCount',
          value: _targetGroupCount.toDouble(),
          min: 2,
          max: 6,
          divisions: 4,
          onChanged: _roundBusy
              ? null
              : (value) =>
                    _applySetting(() => _targetGroupCount = value.round()),
        ),
      ],
      _NumberMemoryMode.equation => <Widget>[
        const SizedBox(height: 12),
        _NumberMemorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_number_memory_view.equation_terms_d465df',
          ),
          valueText: '$_equationTerms',
          value: _equationTerms.toDouble(),
          min: 2,
          max: 5,
          divisions: 3,
          onChanged: _roundBusy
              ? null
              : (value) => _applySetting(() => _equationTerms = value.round()),
        ),
        _NumberMemorySwitchTile(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_number_memory_view.include_multiplication_3ff976',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_number_memory_view.occasionally_adds_x_using_normal_operator_precedence_e087f7',
          ),
          value: _includeMultiplication,
          onChanged: _roundBusy
              ? null
              : (value) => _applySetting(() => _includeMultiplication = value),
        ),
      ],
      _NumberMemoryMode.digits => const <Widget>[],
    };
  }

  Widget _buildColorPreview(BuildContext context, AppI18n i18n) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _activeColors
            .map(
              (color) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _colorName(i18n, color),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildRecentResults(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _history
          .map(
            (result) => _NumberMemoryResultChip(
              label:
                  '${_modeLabel(i18n, result.mode)} L${result.level} ${result.sizeLabel}',
              correct: result.correct,
            ),
          )
          .toList(growable: false),
    );
  }
}
