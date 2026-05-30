part of '../toolbox_life_tools.dart';

class _NumberMarksPage extends StatefulWidget {
  const _NumberMarksPage();

  @override
  State<_NumberMarksPage> createState() => _NumberMarksPageState();
}

class _NumberMarksPageState extends State<_NumberMarksPage> {
  final TextEditingController _inputController = TextEditingController(
    text: 'H2O + CO2',
  );
  ToolboxNumberMarkMode _mode = ToolboxNumberMarkMode.superscript;
  bool _reverse = false;
  late ToolboxNumberMarkTransformResult _result;

  static const List<({String labelKey, String value})> _examples =
      <({String labelKey, String value})>[
        (labelKey: 'life.number_marks.example.chemistry', value: 'H2O + CO2'),
        (labelKey: 'life.number_marks.example.floor', value: 'B2 12F'),
        (labelKey: 'life.number_marks.example.section', value: 'Chapter 12'),
        (labelKey: 'life.number_marks.example.math', value: 'x2 + y3 = z4'),
      ];

  @override
  void initState() {
    super.initState();
    _result = _compute();
    _inputController.addListener(_refresh);
  }

  @override
  void dispose() {
    _inputController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  ToolboxNumberMarkTransformResult _compute() {
    return ToolboxNumberMarkService.transform(
      _inputController.text,
      mode: _mode,
      reverse: _reverse,
    );
  }

  void _refresh() {
    setState(() {
      _result = _compute();
    });
  }

  Future<void> _copyResult() async {
    await Clipboard.setData(ClipboardData(text: _result.output));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.result_copied.d244810fc073',
          ),
        ),
      ),
    );
  }

  void _useResultAsInput() {
    _inputController.text = _result.output;
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputController.text.length),
    );
  }

  String _modeLabel(ToolboxNumberMarkMode mode) {
    return switch (mode) {
      ToolboxNumberMarkMode.superscript => _lifeI18nText(
        context,
        'inline.plan295.life.superscript.e97ae592e1fd',
      ),
      ToolboxNumberMarkMode.subscript => _lifeI18nText(
        context,
        'inline.plan295.life.subscript.e337109701da',
      ),
      ToolboxNumberMarkMode.circled => _lifeI18nText(
        context,
        'inline.plan295.life.circled.083a5fdb18c8',
      ),
      ToolboxNumberMarkMode.parenthesized => _lifeI18nText(
        context,
        'inline.plan295.life.bracketed.82cb7d9dd01d',
      ),
      ToolboxNumberMarkMode.fullwidth => _lifeI18nText(
        context,
        'inline.plan295.life.fullwidth.689974e36768',
      ),
    };
  }

  String _modeSummary(ToolboxNumberMarkMode mode) {
    return switch (mode) {
      ToolboxNumberMarkMode.superscript => _lifeI18nText(
        context,
        'inline.plan295.life.great_for_formulas_footnotes_exponen.0b3ff80a123b',
      ),
      ToolboxNumberMarkMode.subscript => _lifeI18nText(
        context,
        'inline.plan295.life.good_for_chemistry_subscripts_and_lo.819a95b56e8a',
      ),
      ToolboxNumberMarkMode.circled => _lifeI18nText(
        context,
        'inline.plan295.life.useful_for_list_markers_callouts_and.24096ee6e20d',
      ),
      ToolboxNumberMarkMode.parenthesized => _lifeI18nText(
        context,
        'inline.plan295.life.useful_for_quiz_numbers_step_markers.58db07f7783e',
      ),
      ToolboxNumberMarkMode.fullwidth => _lifeI18nText(
        context,
        'inline.plan295.life.useful_for_poster_like_emphasis_and.8ab66803d402',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.number_marks.b511f8d8fc42',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.convert_digits_and_common_symbols_in.4f97f1fc08a3',
      ),
      child: Column(
        key: const ValueKey<String>('life-number-marks-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.conversion_mode.0c44b683c7d3',
            ),
            subtitle: _modeSummary(_mode),
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ToolboxNumberMarkMode.values
                    .map((mode) {
                      return ChoiceChip(
                        selected: _mode == mode,
                        label: Text(_modeLabel(mode)),
                        onSelected: (_) {
                          setState(() {
                            _mode = mode;
                            _result = _compute();
                          });
                        },
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: _reverse,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.normalize_back.d3b4d073d189',
                  ),
                ),
                subtitle: Text(
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.when_enabled_marked_characters_are_n.1e0241957869',
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _reverse = value;
                    _result = _compute();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.ui.pages.toolbox_human_tests_auditory_lab.input_6e272b',
            ),
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('life-number-marks-input'),
                controller: _inputController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _examples
                    .map((example) {
                      return ActionChip(
                        label: Text(_lifeI18nText(context, example.labelKey)),
                        onPressed: () {
                          _inputController.text = example.value;
                          _inputController
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: _inputController.text.length),
                          );
                        },
                      );
                    })
                    .toList(growable: false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.changed.8b0bf83a79f0',
                ),
                value: '${_result.changedCount}',
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.unsupported.d62d93292bcd',
                ),
                value: '${_result.unsupportedCount}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.output.e0ba7997f58f',
            ),
            children: <Widget>[
              _LifePreviewFrame(
                child: SelectableText(
                  _result.output.isEmpty
                      ? _lifeI18nText(
                          context,
                          'inline.plan295.life.converted_output_appears_here_as_you.538b4b1f3716',
                        )
                      : _result.output,
                  key: const ValueKey<String>('life-number-marks-output'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _result.output.isEmpty ? null : _copyResult,
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.copy_result.d4f7944c520b',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _result.output.isEmpty
                        ? null
                        : _useResultAsInput,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.use_result_as_input.a1822752ba96',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.tip_unicode_super_sub_scripts_are_in.4dbf188b1324',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
