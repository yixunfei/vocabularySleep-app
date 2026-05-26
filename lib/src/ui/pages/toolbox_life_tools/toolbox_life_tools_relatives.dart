part of '../toolbox_life_tools.dart';

class _RelativesToolPage extends StatefulWidget {
  const _RelativesToolPage();

  @override
  State<_RelativesToolPage> createState() => _RelativesToolPageState();
}

class _RelativesToolPageState extends State<_RelativesToolPage> {
  static const Set<String> _frontTokens = <String>{'爸爸', '妈妈', '弟弟', '老婆'};

  static const List<_RelativesKeyGroup> _keyGroups = <_RelativesKeyGroup>[
    _RelativesKeyGroup(
      titleZh: '直系亲属',
      titleEn: 'Direct family',
      tokens: <String>['爸爸', '妈妈', '儿子', '女儿'],
    ),
    _RelativesKeyGroup(
      titleZh: '伴侣与手足',
      titleEn: 'Partner and siblings',
      tokens: <String>['老公', '老婆', '哥哥', '弟弟', '姐姐', '妹妹'],
    ),
    _RelativesKeyGroup(
      titleZh: '祖辈与孙辈',
      titleEn: 'Grand family',
      tokens: <String>['爷爷', '奶奶', '外公', '外婆', '孙子', '孙女'],
    ),
    _RelativesKeyGroup(
      titleZh: '叔伯姑舅姨',
      titleEn: 'Uncles and aunts',
      tokens: <String>['伯伯', '叔叔', '姑妈', '舅舅', '姨妈'],
    ),
    _RelativesKeyGroup(
      titleZh: '姻亲常用',
      titleEn: 'In-laws',
      tokens: <String>['公公', '婆婆', '岳父', '岳母', '姐夫', '嫂子'],
    ),
  ];

  static const List<List<String>> _quickExamples = <List<String>>[
    <String>['弟弟', '老婆'],
    <String>['妈妈', '哥哥'],
    <String>['老婆', '爸爸'],
    <String>['爸爸', '姐姐', '儿子'],
  ];

  static const Map<String, String> _tokenEnLabels = <String, String>{
    '爸爸': 'Father',
    '妈妈': 'Mother',
    '老公': 'Husband',
    '老婆': 'Wife',
    '儿子': 'Son',
    '女儿': 'Daughter',
    '哥哥': 'Older brother',
    '弟弟': 'Younger brother',
    '姐姐': 'Older sister',
    '妹妹': 'Younger sister',
    '爷爷': 'Paternal grandpa',
    '奶奶': 'Paternal grandma',
    '外公': 'Maternal grandpa',
    '外婆': 'Maternal grandma',
    '孙子': 'Grandson',
    '孙女': 'Granddaughter',
    '伯伯': 'Elder uncle',
    '叔叔': 'Younger uncle',
    '姑妈': 'Paternal aunt',
    '舅舅': 'Maternal uncle',
    '姨妈': 'Maternal aunt',
    '公公': 'Husband\'s father',
    '婆婆': 'Husband\'s mother',
    '岳父': 'Wife\'s father',
    '岳母': 'Wife\'s mother',
    '姐夫': 'Sister\'s husband',
    '嫂子': 'Brother\'s wife',
  };

  final TextEditingController _targetController = TextEditingController();
  final List<String> _chainTokens = <String>[];

  int _sex = 1;
  bool _reverse = false;
  bool _optimal = false;
  bool _busy = false;
  String? _errorMessage;
  List<String> _results = const <String>[];

  String get _chainText => _chainTokens.join('的');

  @override
  void initState() {
    super.initState();
    _targetController.addListener(_recalculateFromTarget);
  }

  @override
  void dispose() {
    _targetController.removeListener(_recalculateFromTarget);
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '亲戚关系计算器', en: 'Relative calculator'),
      subtitle: _lifeText(
        context,
        zh: '点选关联关系，称呼会自动算出来。',
        en: 'Tap relations and see the title instantly.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildStagePanel(context),
          const SizedBox(height: 12),
          _buildTokenPad(context),
          const SizedBox(height: 12),
          _buildOptionsPanel(context),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: 10),
            _buildErrorPanel(context),
          ],
          const SizedBox(height: 12),
          _buildTopologyPanel(context),
        ],
      ),
    );
  }

  Widget _buildStagePanel(BuildContext context) {
    final theme = Theme.of(context);
    final chainText = _chainText;
    final hasInput = _chainTokens.isNotEmpty;
    final statusText = _busy
        ? _lifeText(context, zh: '计算中', en: 'Calculating')
        : hasInput
        ? _lifeText(context, zh: '实时结果', en: 'Live result')
        : _lifeText(context, zh: '等待输入', en: 'Waiting');
    final primaryResult = _results.isEmpty ? null : _results.first;
    final expressionText = chainText.isEmpty
        ? _lifeText(context, zh: '点击下方关联关系开始', en: 'Tap relations below')
        : primaryResult == null
        ? chainText
        : '$chainText = $primaryResult';
    final resultHint = chainText.isEmpty
        ? _lifeText(
            context,
            zh: '结果会在这里实时显示',
            en: 'Result appears here instantly',
          )
        : primaryResult == null
        ? _lifeText(
            context,
            zh: '暂时没有匹配称呼，可以换一条关系试试',
            en: 'No title matched yet. Try another relation.',
          )
        : _results.length == 1
        ? _lifeText(context, zh: '已自动算出称呼', en: 'Calculated instantly')
        : _lifeText(
            context,
            zh: '另有 ${_results.length - 1} 个候选称呼',
            en: '${_results.length - 1} more candidate(s)',
          );

    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '计算器', en: 'Calculator'),
      subtitle: _lifeText(
        context,
        zh: '上方看链路和结果，下方可退格、清空或套用示例。',
        en: 'View the chain and result, then backspace, clear, or try an example.',
      ),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                theme.colorScheme.primaryContainer.withValues(alpha: 0.64),
                theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.72,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.18),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _RelativesStatusPill(
                    icon: Icons.calculate_rounded,
                    label: _lifeText(context, zh: '本地计算', en: 'Local'),
                  ),
                  _RelativesStatusPill(
                    icon: Icons.account_circle_outlined,
                    label: _sexLabel(context),
                  ),
                  _RelativesStatusPill(
                    icon: _reverse
                        ? Icons.compare_arrows_rounded
                        : Icons.east_rounded,
                    label: _reverse
                        ? _lifeText(context, zh: '反向称呼', en: 'Reverse')
                        : _lifeText(context, zh: '我称呼对方', en: 'Forward'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.route_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _lifeText(context, zh: '当前计算', en: 'Current input'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          statusText,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      expressionText,
                      key: const ValueKey<String>('life_relatives_chain_text'),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        color: chainText.isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            resultHint,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: primaryResult == null
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _RelativesMetric(
                      label: _lifeText(context, zh: '层级', en: 'Steps'),
                      value: '${_chainTokens.length}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RelativesMetric(
                      label: _lifeText(context, zh: '结果', en: 'Results'),
                      value: '${_results.length}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RelativesMetric(
                      label: _lifeText(context, zh: '模式', en: 'Mode'),
                      value: _optimal
                          ? _lifeText(context, zh: '最短', en: 'Short')
                          : _lifeText(context, zh: '完整', en: 'Full'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionRow(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTokenPad(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '关联关系', en: 'Relations'),
      subtitle: _lifeText(
        context,
        zh: '常用关系放前面，点一下就加入计算器。',
        en: 'Common relations are first; one tap adds them.',
      ),
      children: <Widget>[
        _buildFrontKeyRow(context),
        const SizedBox(height: 14),
        for (final group in _keyGroups) ...<Widget>[
          Text(
            group.label(context),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _buildKeyGrid(context, group.tokens),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildFrontKeyRow(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _lifeText(context, zh: '常用快捷键', en: 'Quick keys'),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 320.0;
            const spacing = 6.0;
            final columns = width < 360 ? 3 : 4;
            final buttonWidth = (width - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: _frontTokens
                  .map((token) {
                    return SizedBox(
                      width: buttonWidth,
                      child: _RelativesCalculatorKey(
                        buttonKey: ValueKey<String>(
                          'life_relatives_token_$token',
                        ),
                        label: _tokenPrimaryLabel(context, token),
                        helper: _tokenHelperLabel(context, token),
                        onPressed: () => _appendToken(token),
                      ),
                    );
                  })
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }

  Widget _buildKeyGrid(BuildContext context, List<String> tokens) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        const spacing = 6.0;
        final columns = width < 340
            ? 3
            : width < 520
            ? 4
            : 5;
        final buttonWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tokens
              .map((token) {
                final keyPrefix = _frontTokens.contains(token)
                    ? 'life_relatives_token_more'
                    : 'life_relatives_token';
                return SizedBox(
                  width: buttonWidth,
                  child: _RelativesCalculatorKey(
                    buttonKey: ValueKey<String>('${keyPrefix}_$token'),
                    label: _tokenPrimaryLabel(context, token),
                    helper: _tokenHelperLabel(context, token),
                    onPressed: () => _appendToken(token),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildTopologyPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '家族图谱', en: 'Family map'),
      subtitle: _lifeText(
        context,
        zh: '用树状节点看清“我”到当前称呼的路径。',
        en: 'See the path from me as a compact family tree.',
      ),
      children: <Widget>[_RelativesTopologyView(tokens: _chainTokens)],
    );
  }

  Widget _buildOptionsPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '计算设置', en: 'Calculation options'),
      subtitle: _lifeText(
        context,
        zh: '性别、反向称呼和常用称呼偏好会影响部分结果。',
        en: 'Gender, reverse mode, and common-title preference affect some results.',
      ),
      children: <Widget>[
        _LifeSegmentedField<int>(
          label: _lifeText(context, zh: '我的性别', en: 'My gender'),
          value: _sex,
          options: const <_LifeOption<int>>[
            _LifeOption<int>(value: 1, labelZh: '男', labelEn: 'Male'),
            _LifeOption<int>(value: 0, labelZh: '女', labelEn: 'Female'),
          ],
          onChanged: (value) => _updateAndRecalculate(() => _sex = value),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey<String>('life_relatives_target_field'),
          controller: _targetController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeText(
              context,
              zh: '从谁的角度算（可选）',
              en: 'Target person (optional)',
            ),
            hintText: _lifeText(
              context,
              zh: '例如：老婆，用来算“老婆的亲戚”',
              en: 'Example: wife, for relation-to-target scenarios',
            ),
          ),
        ),
        const SizedBox(height: 8),
        _RelativesSwitchTile(
          key: const ValueKey<String>('life_relatives_reverse_switch'),
          icon: Icons.compare_arrows_rounded,
          title: _lifeText(context, zh: '对方如何称呼我', en: 'How they call me'),
          subtitle: _lifeText(
            context,
            zh: '开启后按反向关系推算称谓。',
            en: 'Resolve the chain in reverse direction.',
          ),
          value: _reverse,
          onChanged: (value) => _updateAndRecalculate(() => _reverse = value),
        ),
        const SizedBox(height: 8),
        _RelativesSwitchTile(
          key: const ValueKey<String>('life_relatives_optimal_switch'),
          icon: Icons.alt_route_rounded,
          title: _lifeText(context, zh: '最短路径优先', en: 'Prefer shortest path'),
          subtitle: _lifeText(
            context,
            zh: '优先展示更日常、更短的称呼。',
            en: 'Prefer shorter, everyday titles.',
          ),
          value: _optimal,
          onChanged: (value) => _updateAndRecalculate(() => _optimal = value),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        OutlinedButton.icon(
          key: const ValueKey<String>('life_relatives_undo_button'),
          onPressed: _chainTokens.isEmpty ? null : _undoLast,
          icon: const Icon(Icons.backspace_outlined),
          label: Text(_lifeText(context, zh: '退格', en: 'Backspace')),
        ),
        OutlinedButton.icon(
          key: const ValueKey<String>('life_relatives_clear_button'),
          onPressed: _chainTokens.isEmpty ? null : _clearChain,
          icon: const Icon(Icons.clear_all_rounded),
          label: Text(_lifeText(context, zh: '清空', en: 'Clear')),
        ),
        FilledButton.tonalIcon(
          key: const ValueKey<String>('life_relatives_example_button'),
          onPressed: _applyNextExample,
          icon: const Icon(Icons.auto_fix_high_rounded),
          label: Text(_lifeText(context, zh: '示例', en: 'Example')),
        ),
        FilledButton.icon(
          key: const ValueKey<String>('life_relatives_calculate_button'),
          onPressed: _busy ? null : _calculate,
          icon: _busy
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.done_rounded),
          label: Text(
            _busy
                ? _lifeText(context, zh: '计算中', en: 'Calculating')
                : _lifeText(context, zh: '刷新结果', en: 'Refresh'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _errorMessage!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  void _appendToken(String token) {
    _updateAndRecalculate(() {
      _chainTokens.add(token);
      _errorMessage = null;
    });
  }

  void _undoLast() {
    if (_chainTokens.isEmpty) {
      return;
    }
    _updateAndRecalculate(() {
      _chainTokens.removeLast();
      _errorMessage = null;
    });
  }

  void _clearChain() {
    _updateAndRecalculate(() {
      _chainTokens.clear();
      _errorMessage = null;
    });
  }

  void _applyNextExample() {
    final current = _chainTokens.join(',');
    var next = _quickExamples.first;
    for (var i = 0; i < _quickExamples.length; i += 1) {
      if (_quickExamples[i].join(',') == current) {
        next = _quickExamples[(i + 1) % _quickExamples.length];
        break;
      }
    }
    _updateAndRecalculate(() {
      _chainTokens
        ..clear()
        ..addAll(next);
      _errorMessage = null;
    });
  }

  void _calculate() {
    _recalculate(showErrors: true);
  }

  void _recalculateFromTarget() {
    if (!mounted) {
      return;
    }
    _recalculate();
  }

  void _updateAndRecalculate(VoidCallback update) {
    update();
    _recalculate();
  }

  void _recalculate({bool showErrors = false}) {
    if (_chainTokens.isEmpty) {
      setState(() {
        _results = const <String>[];
        _busy = false;
        _errorMessage = showErrors
            ? _lifeText(
                context,
                zh: '先选择一个关联关系再计算。',
                en: 'Select at least one relation first.',
              )
            : null;
      });
      return;
    }

    final text = _chainText;
    final target = _targetController.text.trim();
    final normalizedText = _normalizeRelationInput(text);
    final normalizedTarget = _normalizeRelationInput(target);
    try {
      final results = kinship.relationship(
        text: normalizedText,
        target: normalizedTarget,
        sex: _sex,
        reverse: _reverse,
        optimal: _optimal,
      );
      setState(() {
        _busy = false;
        _results = results;
        if (_results.isEmpty) {
          _errorMessage = showErrors
              ? _lifeText(
                  context,
                  zh: '未找到可用称呼，请换一条关系试试。',
                  en: 'No matched title. Try another relation.',
                )
              : null;
        } else {
          _errorMessage = null;
        }
      });
    } catch (_) {
      setState(() {
        _busy = false;
        _results = const <String>[];
        _errorMessage = showErrors
            ? _lifeText(
                context,
                zh: '计算失败，请检查关系链是否合法。',
                en: 'Calculation failed, please check relationship chain.',
              )
            : null;
      });
    }
  }

  String _sexLabel(BuildContext context) {
    return switch (_sex) {
      1 => _lifeText(context, zh: '我是男', en: 'Male'),
      0 => _lifeText(context, zh: '我是女', en: 'Female'),
      _ => _lifeText(context, zh: '我是男', en: 'Male'),
    };
  }

  String _tokenPrimaryLabel(BuildContext context, String token) {
    final lang = AppI18n.normalizeLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    if (lang == 'zh') {
      return token;
    }
    return _tokenEnLabels[token] ?? token;
  }

  String _tokenHelperLabel(BuildContext context, String token) {
    final lang = AppI18n.normalizeLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    if (lang == 'zh') {
      return _tokenEnLabels[token] ?? '';
    }
    return token;
  }

  String _normalizeRelationInput(String text) {
    if (text.isEmpty) {
      return text;
    }
    var result = text;
    const replacements = <String, String>{
      'mom': '妈妈',
      'mother': '妈妈',
      'mum': '妈妈',
      'dad': '爸爸',
      'father': '爸爸',
      'wife': '老婆',
      'husband': '老公',
      'younger brother': '弟弟',
      'older brother': '哥哥',
      'brother': '哥哥',
      'younger sister': '妹妹',
      'older sister': '姐姐',
      'sister': '姐姐',
      "'s": '的',
      ' of ': '的',
      ' de ': '的',
    };
    replacements.forEach((from, to) {
      result = result.replaceAll(from, to);
      result = result.replaceAll(from.toUpperCase(), to);
      result = result.replaceAll(from[0].toUpperCase() + from.substring(1), to);
    });
    return result;
  }
}

class _RelativesKeyGroup {
  const _RelativesKeyGroup({
    required this.titleZh,
    required this.titleEn,
    required this.tokens,
  });

  final String titleZh;
  final String titleEn;
  final List<String> tokens;

  String label(BuildContext context) {
    return _lifeText(context, zh: titleZh, en: titleEn);
  }
}

class _RelativesStatusPill extends StatelessWidget {
  const _RelativesStatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelativesMetric extends StatelessWidget {
  const _RelativesMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RelativesCalculatorKey extends StatelessWidget {
  const _RelativesCalculatorKey({
    required this.buttonKey,
    required this.label,
    required this.helper,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final String helper;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: buttonKey,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Ink(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.62,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Tooltip(
                message: helper.trim().isEmpty ? label : '$label · $helper',
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RelativesSwitchTile extends StatelessWidget {
  const _RelativesSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 10),
        secondary: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _RelativesTopologyView extends StatelessWidget {
  const _RelativesTopologyView({required this.tokens});

  final List<String> tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tokens.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.42,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          _lifeText(
            context,
            zh: '暂无链路。先点击关联关系，家族图谱会在这里同步更新。',
            en: 'No chain yet. Tap relations and the family map updates here.',
          ),
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: _RelativesFamilyTree(tokens: tokens),
    );
  }
}

class _RelativesFamilyTree extends StatelessWidget {
  const _RelativesFamilyTree({required this.tokens});

  final List<String> tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleTokens = tokens.length > 5
        ? <String>[...tokens.take(4), '...${tokens.length - 4}']
        : tokens;
    final nodes = <String>[
      _lifeText(context, zh: '我', en: 'Me'),
      ...visibleTokens,
    ];
    final height = (86.0 + (nodes.length - 1) * 54).clamp(150.0, 360.0);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _RelativesFamilyTreePainter(
          nodes: nodes,
          primary: theme.colorScheme.primary,
          outline: theme.colorScheme.outlineVariant,
          surface: theme.colorScheme.surface,
          surfaceHigh: theme.colorScheme.surfaceContainerHighest,
          onSurface: theme.colorScheme.onSurface,
          onSurfaceVariant: theme.colorScheme.onSurfaceVariant,
          textStyle:
              theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ) ??
              const TextStyle(fontWeight: FontWeight.w900),
          smallStyle:
              theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ) ??
              const TextStyle(fontWeight: FontWeight.w700),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RelativesFamilyTreePainter extends CustomPainter {
  _RelativesFamilyTreePainter({
    required this.nodes,
    required this.primary,
    required this.outline,
    required this.surface,
    required this.surfaceHigh,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.textStyle,
    required this.smallStyle,
  });

  final List<String> nodes;
  final Color primary;
  final Color outline;
  final Color surface;
  final Color surfaceHigh;
  final Color onSurface;
  final Color onSurfaceVariant;
  final TextStyle textStyle;
  final TextStyle smallStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) {
      return;
    }

    final linePaint = Paint()
      ..color = primary.withValues(alpha: 0.32)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final branchPaint = Paint()
      ..color = outline.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final top = 18.0;
    final rowGap = nodes.length <= 3 ? 58.0 : 50.0;
    final nodeWidth = math.min(118.0, math.max(82.0, size.width * 0.34));
    final nodeHeight = 34.0;

    final centers = <Offset>[];
    for (var i = 0; i < nodes.length; i += 1) {
      final level = i.toDouble();
      final branchDirection = i.isEven ? -1.0 : 1.0;
      final branchOffset = i == 0
          ? 0.0
          : branchDirection * math.min(72.0, size.width * 0.18);
      centers.add(Offset(centerX + branchOffset, top + level * rowGap));
    }

    for (var i = 0; i < centers.length - 1; i += 1) {
      final current = centers[i];
      final next = centers[i + 1];
      final midY = (current.dy + next.dy) / 2;
      final path = Path()
        ..moveTo(current.dx, current.dy + nodeHeight / 2)
        ..lineTo(current.dx, midY)
        ..lineTo(next.dx, midY)
        ..lineTo(next.dx, next.dy - nodeHeight / 2);
      canvas.drawPath(path, linePaint);

      final branchEnd = Offset(
        current.dx + (next.dx >= current.dx ? -18 : 18),
        midY,
      );
      canvas.drawLine(Offset(current.dx, midY), branchEnd, branchPaint);
      canvas.drawCircle(
        branchEnd,
        3.0,
        branchPaint..style = PaintingStyle.fill,
      );
      branchPaint.style = PaintingStyle.stroke;
    }

    for (var i = 0; i < centers.length; i += 1) {
      _drawNode(
        canvas,
        center: centers[i],
        width: nodeWidth,
        height: nodeHeight,
        label: nodes[i],
        active: i == 0,
        terminal: i == centers.length - 1,
        index: i,
      );
    }
  }

  void _drawNode(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required String label,
    required bool active,
    required bool terminal,
    required int index,
  }) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final radius = Radius.circular(height / 2);
    final fillPaint = Paint()
      ..color = active
          ? primary.withValues(alpha: 0.16)
          : terminal
          ? primary.withValues(alpha: 0.1)
          : surface.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = active || terminal ? primary.withValues(alpha: 0.55) : outline
      ..strokeWidth = active || terminal ? 1.6 : 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), fillPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), borderPaint);

    final badgeRadius = 10.0;
    final badgeCenter = Offset(rect.left + 14, center.dy);
    final badgePaint = Paint()
      ..color = active ? primary : surfaceHigh
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius, badgePaint);

    final badgeText = index == 0 ? nodes.first : '$index';
    _paintText(
      canvas,
      text: badgeText,
      center: badgeCenter,
      maxWidth: badgeRadius * 2,
      style: smallStyle.copyWith(
        color: active ? surface : onSurfaceVariant,
        fontSize: 10,
      ),
    );

    _paintText(
      canvas,
      text: label,
      center: Offset(center.dx + 8, center.dy),
      maxWidth: width - 42,
      style: textStyle.copyWith(color: onSurface),
    );
  }

  void _paintText(
    Canvas canvas, {
    required String text,
    required Offset center,
    required double maxWidth,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      ellipsis: '...',
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RelativesFamilyTreePainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.primary != primary ||
        oldDelegate.outline != outline ||
        oldDelegate.surface != surface ||
        oldDelegate.surfaceHigh != surfaceHigh ||
        oldDelegate.onSurface != onSurface ||
        oldDelegate.onSurfaceVariant != onSurfaceVariant ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.smallStyle != smallStyle;
  }
}
