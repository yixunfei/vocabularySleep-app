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

  static const List<({String zh, String en, String value})> _examples =
      <({String zh, String en, String value})>[
        (zh: '化学式', en: 'Chemistry', value: 'H2O + CO2'),
        (zh: '楼层', en: 'Floor', value: 'B2 12F'),
        (zh: '章节', en: 'Section', value: 'Chapter 12'),
        (zh: '数学', en: 'Math', value: 'x2 + y3 = z4'),
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
        content: Text(_lifeText(context, zh: '结果已复制', en: 'Result copied')),
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
      ToolboxNumberMarkMode.superscript => _lifeText(
        context,
        zh: '上标',
        en: 'Superscript',
      ),
      ToolboxNumberMarkMode.subscript => _lifeText(
        context,
        zh: '下标',
        en: 'Subscript',
      ),
      ToolboxNumberMarkMode.circled => _lifeText(
        context,
        zh: '带圈',
        en: 'Circled',
      ),
      ToolboxNumberMarkMode.parenthesized => _lifeText(
        context,
        zh: '括号编号',
        en: 'Bracketed',
      ),
      ToolboxNumberMarkMode.fullwidth => _lifeText(
        context,
        zh: '全角',
        en: 'Fullwidth',
      ),
    };
  }

  String _modeSummary(ToolboxNumberMarkMode mode) {
    return switch (mode) {
      ToolboxNumberMarkMode.superscript => _lifeText(
        context,
        zh: '适合化学式、脚注、指数和小号标注。',
        en: 'Great for formulas, footnotes, exponents, and small labels.',
      ),
      ToolboxNumberMarkMode.subscript => _lifeText(
        context,
        zh: '适合化学式下标、序号尾标和低位标注。',
        en: 'Good for chemistry subscripts and lower-position markers.',
      ),
      ToolboxNumberMarkMode.circled => _lifeText(
        context,
        zh: '适合清单编号、重点序号和按钮样式文本。',
        en: 'Useful for list markers, callouts, and numbered buttons.',
      ),
      ToolboxNumberMarkMode.parenthesized => _lifeText(
        context,
        zh: '适合试题序号、步骤编号和文档条目。',
        en: 'Useful for quiz numbers, step markers, and document items.',
      ),
      ToolboxNumberMarkMode.fullwidth => _lifeText(
        context,
        zh: '适合海报标题、视觉强调和统一排版宽度。',
        en: 'Useful for poster-like emphasis and uniform text width.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '数字转标', en: 'Number marks'),
      subtitle: _lifeText(
        context,
        zh: '把数字和常用字符转换为上标、下标、带圈、括号编号或全角，并支持反向还原。',
        en: 'Convert digits and common symbols into superscript, subscript, circled, bracketed, or fullwidth forms with reverse normalization.',
      ),
      child: Column(
        key: const ValueKey<String>('life-number-marks-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '转换方式', en: 'Conversion mode'),
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
                  _lifeText(context, zh: '反向还原', en: 'Normalize back'),
                ),
                subtitle: Text(
                  _lifeText(
                    context,
                    zh: '开启后会把当前模式下的标记字符尽量还原回普通文本。',
                    en: 'When enabled, marked characters are normalized back into plain text where possible.',
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
            title: _lifeText(context, zh: '输入', en: 'Input'),
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
                        label: Text(
                          _lifeText(context, zh: example.zh, en: example.en),
                        ),
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
                label: _lifeText(context, zh: '已转换片段', en: 'Changed'),
                value: '${_result.changedCount}',
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '未覆盖字符', en: 'Unsupported'),
                value: '${_result.unsupportedCount}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '输出结果', en: 'Output'),
            children: <Widget>[
              _LifePreviewFrame(
                child: SelectableText(
                  _result.output.isEmpty
                      ? _lifeText(
                          context,
                          zh: '输入内容后会在这里实时显示转换结果。',
                          en: 'Converted output appears here as you type.',
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
                      _lifeText(context, zh: '复制结果', en: 'Copy result'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _result.output.isEmpty
                        ? null
                        : _useResultAsInput,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(
                      _lifeText(context, zh: '结果回填', en: 'Use result as input'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _lifeText(
                  context,
                  zh: '提示: Unicode 上下标本身覆盖不完整，无法转换的字符会保留原样并计入“未覆盖字符”。',
                  en: 'Tip: Unicode super/sub scripts are incomplete by nature, so unsupported characters stay unchanged and are counted above.',
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
