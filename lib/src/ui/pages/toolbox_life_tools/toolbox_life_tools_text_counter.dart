part of '../toolbox_life_tools.dart';

@visibleForTesting
List<Map<String, Object>> buildLifeTextCounterTestChunks({
  required String text,
  required int chunkLimit,
  required String metric,
  required String splitMode,
  String sentenceEndings = '。！？.!?',
}) {
  final metricValue = switch (metric) {
    'total' => _TextCountMetric.total,
    'no_symbols' => _TextCountMetric.noSymbols,
    'no_whitespace' => _TextCountMetric.noWhitespace,
    'content_only' => _TextCountMetric.contentOnly,
    _ => _TextCountMetric.noSymbols,
  };
  final modeValue = switch (splitMode) {
    'fixed' => _TextSplitMode.fixedLength,
    'sentence' => _TextSplitMode.sentencePreferred,
    _ => _TextSplitMode.fixedLength,
  };
  final endings = <String>[];
  for (final char in sentenceEndings.characters) {
    if (char.trim().isNotEmpty && !endings.contains(char)) {
      endings.add(char);
    }
  }
  return _buildTextSplitResults(
    text: text,
    chunkLimit: chunkLimit,
    metric: metricValue,
    splitMode: modeValue,
    sentenceEndings: endings,
  ).map((chunk) {
    return <String, Object>{
      'content': chunk.content,
      'rawLength': chunk.rawLength,
      'effectiveLength': chunk.effectiveLength,
    };
  }).toList();
}

enum _TextCountMetric {
  total,
  noSymbols,
  noWhitespace,
  contentOnly,
}

enum _TextSplitMode {
  fixedLength,
  sentencePreferred,
}

class _TextSplitResult {
  const _TextSplitResult({
    required this.content,
    required this.rawLength,
    required this.effectiveLength,
  });

  final String content;
  final int rawLength;
  final int effectiveLength;
}

class _TextCounterPage extends StatefulWidget {
  const _TextCounterPage();

  @override
  State<_TextCounterPage> createState() => _TextCounterPageState();
}

class _TextCounterPageState extends State<_TextCounterPage> {
  static const int _defaultChunkLimit = 300;

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _chunkController = TextEditingController(
    text: '300',
  );
  final TextEditingController _sentenceController = TextEditingController(
    text: '。！？.!?',
  );

  _TextCountMetric _metric = _TextCountMetric.noSymbols;
  _TextSplitMode _splitMode = _TextSplitMode.fixedLength;
  bool _splitEnabled = false;
  bool _splitPanelExpanded = false;
  final Set<int> _expandedChunkIndexes = <int>{};
  final Set<int> _completedChunkIndexes = <int>{};

  @override
  void dispose() {
    _controller.dispose();
    _chunkController.dispose();
    _sentenceController.dispose();
    super.dispose();
  }

  int _symbolCount(String text) {
    var count = 0;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final isWord = RegExp(r'[A-Za-z0-9\u4E00-\u9FFF]').hasMatch(char);
      final isWhitespace = RegExp(r'\s').hasMatch(char);
      if (!isWord && !isWhitespace) {
        count += 1;
      }
    }
    return count;
  }

  bool _isWhitespaceCharacter(String char) {
    return RegExp(r'\s').hasMatch(char);
  }

  bool _isContentCharacter(String char) {
    return RegExp(r'[A-Za-z0-9\u4E00-\u9FFF]').hasMatch(char);
  }

  bool _isSymbolCharacter(String char) {
    return !_isContentCharacter(char) && !_isWhitespaceCharacter(char);
  }

  int _effectiveLengthFor(String text, _TextCountMetric metric) {
    if (text.isEmpty) {
      return 0;
    }
    switch (metric) {
      case _TextCountMetric.total:
        return text.characters.length;
      case _TextCountMetric.noSymbols:
        return text.characters.where((char) => !_isSymbolCharacter(char)).length;
      case _TextCountMetric.noWhitespace:
        return text.characters.where((char) => !_isWhitespaceCharacter(char)).length;
      case _TextCountMetric.contentOnly:
        return text.characters.where(_isContentCharacter).length;
    }
  }

  int _chunkLimitValue() {
    final value = int.tryParse(_chunkController.text.trim());
    if (value == null || value <= 0) {
      return _defaultChunkLimit;
    }
    return value.clamp(1, 50000);
  }

  List<String> _sentenceEndings() {
    final raw = _sentenceController.text;
    final results = <String>[];
    for (final char in raw.characters) {
      if (char.trim().isNotEmpty && !results.contains(char)) {
        results.add(char);
      }
    }
    return results;
  }

  Future<void> _copyText(String text, String successMessage) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
  }

  void _handleInputChanged(String _) {
    setState(() {
      _expandedChunkIndexes.clear();
      _completedChunkIndexes.clear();
    });
  }

  void _toggleChunkExpanded(int index) {
    setState(() {
      if (_expandedChunkIndexes.contains(index)) {
        _expandedChunkIndexes.remove(index);
      } else {
        _expandedChunkIndexes.add(index);
      }
    });
  }

  void _toggleChunkCompleted(int index, bool value) {
    setState(() {
      if (value) {
        _completedChunkIndexes.add(index);
      } else {
        _completedChunkIndexes.remove(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _controller.text;
    final total = text.characters.length;
    final symbols = _symbolCount(text);
    final noSymbols = total - symbols;
    final noWhitespace = text.replaceAll(RegExp(r'\s+'), '').characters.length;
    final contentOnly = _effectiveLengthFor(text, _TextCountMetric.contentOnly);
    final chunkLimit = _chunkLimitValue();
    final chunks = _splitEnabled
        ? _buildTextSplitResults(
            text: text,
            chunkLimit: chunkLimit,
            metric: _metric,
            splitMode: _splitMode,
            sentenceEndings: _sentenceEndings(),
          )
        : const <_TextSplitResult>[];
    final totalEffective = _effectiveLengthFor(text, _metric);
    final sentenceHint = _sentenceEndings().join(' ');

    return ToolboxToolPage(
      title: _lifeText(context, zh: '字数拆分与统计', en: 'Text split and count'),
      subtitle: _lifeText(
        context,
        zh: '统计字符信息，并在需要时展开自动拆分与逐块复制。',
        en: 'Count text and expand auto-splitting only when needed.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            maxLines: 10,
            minLines: 8,
            onChanged: _handleInputChanged,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _lifeText(context, zh: '输入文本', en: 'Input text'),
              hintText: _lifeText(
                context,
                zh: '先统计全文；需要时再打开拆分开关生成分块。',
                en: 'Count first, then enable splitting when needed.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeText(context, zh: '总字符数', en: 'Total'),
                value: '$total',
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '符号数', en: 'Symbols'),
                value: '$symbols',
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '去符号', en: 'No symbols'),
                value: '$noSymbols',
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '去空白', en: 'No whitespace'),
                value: '$noWhitespace',
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '仅正文', en: 'Content only'),
                value: '$contentOnly',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: <Widget>[
                SwitchListTile.adaptive(
                  value: _splitEnabled,
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  title: Text(
                    _lifeText(context, zh: '启用自动拆分', en: 'Enable auto split'),
                  ),
                  subtitle: Text(
                    _lifeText(
                      context,
                      zh: '关闭时仅统计。打开后可按规则生成可复制分块。',
                      en: 'Off for counting only. On to generate copyable chunks.',
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _splitEnabled = value;
                      _splitPanelExpanded = value;
                      if (!value) {
                        _expandedChunkIndexes.clear();
                        _completedChunkIndexes.clear();
                      }
                    });
                  },
                ),
                if (_splitEnabled)
                  Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: const PageStorageKey<String>('life_text_split_panel'),
                      initiallyExpanded: _splitPanelExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() => _splitPanelExpanded = expanded);
                      },
                      title: Text(
                        _lifeText(context, zh: '拆分设置与结果', en: 'Split settings and results'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _lifeText(
                          context,
                          zh: '当前按 ${_metricLabel(context, _metric)} 统计，预计 ${chunks.length} 块。',
                          en: 'Using ${_metricLabel(context, _metric)} with ${chunks.length} chunk(s).',
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: <Widget>[
                        DropdownButtonFormField<_TextCountMetric>(
                          initialValue: _metric,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: _lifeText(context, zh: '计数标准', en: 'Count by'),
                          ),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _metric = value);
                          },
                          items: _TextCountMetric.values.map((metric) {
                            return DropdownMenuItem<_TextCountMetric>(
                              value: metric,
                              child: Text(_metricLabel(context, metric)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<_TextSplitMode>(
                          initialValue: _splitMode,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: _lifeText(context, zh: '拆分方式', en: 'Split mode'),
                          ),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => _splitMode = value);
                          },
                          items: _TextSplitMode.values.map((mode) {
                            return DropdownMenuItem<_TextSplitMode>(
                              value: mode,
                              child: Text(_splitModeLabel(context, mode)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _chunkController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: _lifeText(
                              context,
                              zh: '单块字数上限',
                              en: 'Chunk size limit',
                            ),
                            helperText: _lifeText(
                              context,
                              zh: '按当前计数标准计算，默认 300。',
                              en: 'Uses the selected metric. Default is 300.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _sentenceController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: _lifeText(
                              context,
                              zh: '句末符号',
                              en: 'Sentence endings',
                            ),
                            helperText: _lifeText(
                              context,
                              zh: '句末优先模式会尽量在这些符号处截断。',
                              en: 'Sentence-first mode prefers these endings.',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _lifeText(context, zh: '拆分概览', en: 'Split overview'),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _lifeText(
                                  context,
                                  zh: '当前按 ${_metricLabel(context, _metric)} 统计，共 $totalEffective 个有效字符，预计分成 ${chunks.length} 块。',
                                  en: 'Using ${_metricLabel(context, _metric)}, there are $totalEffective effective characters in ${chunks.length} chunk(s).',
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (_splitMode == _TextSplitMode.sentencePreferred &&
                                  sentenceHint.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  _lifeText(
                                    context,
                                    zh: '句末优先符号: $sentenceHint',
                                    en: 'Preferred endings: $sentenceHint',
                                  ),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  FilledButton.tonalIcon(
                                    onPressed: text.trim().isEmpty
                                        ? null
                                        : () => _copyText(
                                            text,
                                            _lifeText(
                                              context,
                                              zh: '原文已复制',
                                              en: 'Original text copied',
                                            ),
                                          ),
                                    icon: const Icon(Icons.copy_all_rounded),
                                    label: Text(
                                      _lifeText(context, zh: '复制原文', en: 'Copy original'),
                                    ),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: chunks.isEmpty
                                        ? null
                                        : () => _copyText(
                                            chunks.map((chunk) => chunk.content).join('\n\n'),
                                            _lifeText(
                                              context,
                                              zh: '全部分块已复制',
                                              en: 'All chunks copied',
                                            ),
                                          ),
                                    icon: const Icon(Icons.splitscreen_rounded),
                                    label: Text(
                                      _lifeText(context, zh: '复制全部分块', en: 'Copy all chunks'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (chunks.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            child: Text(
                              _lifeText(
                                context,
                                zh: '输入文本后，这里会生成默认折叠的可复制分块。',
                                en: 'Collapsed copyable chunks will appear here after input.',
                              ),
                            ),
                          ),
                        for (var i = 0; i < chunks.length; i++) ...<Widget>[
                          _TextSplitCard(
                            index: i + 1,
                            chunk: chunks[i],
                            metricLabel: _metricLabel(context, _metric),
                            isExpanded: _expandedChunkIndexes.contains(i),
                            isCompleted: _completedChunkIndexes.contains(i),
                            onToggleExpanded: () => _toggleChunkExpanded(i),
                            onToggleCompleted: (value) =>
                                _toggleChunkCompleted(i, value),
                            onCopy: () => _copyText(
                              chunks[i].content,
                              _lifeText(
                                context,
                                zh: '第 ${i + 1} 块已复制',
                                en: 'Chunk ${i + 1} copied',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _lifeText(
                                context,
                                zh: '提示: 分块默认折叠，适合长文本快速处理。勾选后会保留划线完成态，方便逐块清理。',
                                en: 'Tip: chunks stay collapsed by default, and checked chunks keep a done style.',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextSplitCard extends StatelessWidget {
  const _TextSplitCard({
    required this.index,
    required this.chunk,
    required this.metricLabel,
    required this.isExpanded,
    required this.isCompleted,
    required this.onToggleExpanded,
    required this.onToggleCompleted,
    required this.onCopy,
  });

  final int index;
  final _TextSplitResult chunk;
  final String metricLabel;
  final bool isExpanded;
  final bool isCompleted;
  final VoidCallback onToggleExpanded;
  final ValueChanged<bool> onToggleCompleted;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      decoration: isCompleted ? TextDecoration.lineThrough : null,
      color: isCompleted
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onSurface,
    );
    final contentStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.55,
      decoration: isCompleted ? TextDecoration.lineThrough : null,
      color: isCompleted
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onSurface,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isCompleted ? 0.72 : 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? theme.colorScheme.outline
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: <Widget>[
                  Checkbox(
                    value: isCompleted,
                    onChanged: (value) => onToggleCompleted(value ?? false),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: onToggleExpanded,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _lifeText(
                                context,
                                zh: '第 $index 块',
                                en: 'Chunk $index',
                              ),
                              style: titleStyle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lifeText(
                                context,
                                zh: '原始 ${chunk.rawLength} 字 | $metricLabel ${chunk.effectiveLength} 字',
                                en: 'Raw ${chunk.rawLength} | $metricLabel ${chunk.effectiveLength}',
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: _lifeText(context, zh: '复制', en: 'Copy'),
                    onPressed: onCopy,
                    icon: const Icon(Icons.content_copy_rounded),
                  ),
                  IconButton(
                    tooltip: isExpanded
                        ? _lifeText(context, zh: '收起', en: 'Collapse')
                        : _lifeText(context, zh: '展开', en: 'Expand'),
                    onPressed: onToggleExpanded,
                    icon: Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                  ),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    SelectableText(chunk.content, style: contentStyle),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _metricLabel(BuildContext context, _TextCountMetric metric) {
  return switch (metric) {
    _TextCountMetric.total => _lifeText(context, zh: '总字符', en: 'Total'),
    _TextCountMetric.noSymbols => _lifeText(context, zh: '去符号', en: 'No symbols'),
    _TextCountMetric.noWhitespace => _lifeText(context, zh: '去空白', en: 'No whitespace'),
    _TextCountMetric.contentOnly => _lifeText(context, zh: '仅正文', en: 'Content only'),
  };
}

String _splitModeLabel(BuildContext context, _TextSplitMode mode) {
  return switch (mode) {
    _TextSplitMode.fixedLength => _lifeText(
        context,
        zh: '固定字数拆分',
        en: 'Fixed-length split',
      ),
    _TextSplitMode.sentencePreferred => _lifeText(
        context,
        zh: '句末优先拆分',
        en: 'Sentence-first split',
      ),
  };
}

List<_TextSplitResult> _buildTextSplitResults({
  required String text,
  required int chunkLimit,
  required _TextCountMetric metric,
  required _TextSplitMode splitMode,
  required List<String> sentenceEndings,
}) {
  if (text.trim().isEmpty) {
    return const <_TextSplitResult>[];
  }

  final clusters = text.characters.toList();
  if (clusters.isEmpty) {
    return const <_TextSplitResult>[];
  }

  final results = <_TextSplitResult>[];
  var start = 0;
  while (start < clusters.length) {
    final forcedEnd = _advanceToLimit(
      clusters: clusters,
      start: start,
      chunkLimit: chunkLimit,
      metric: metric,
    );
    if (forcedEnd >= clusters.length) {
      results.add(_buildChunkResult(clusters, start, clusters.length, metric));
      break;
    }

    var end = forcedEnd;
    if (splitMode == _TextSplitMode.sentencePreferred &&
        sentenceEndings.isNotEmpty) {
      final preferredEnd = _findSentenceBreak(
        clusters: clusters,
        start: start,
        forcedEnd: forcedEnd,
        sentenceEndings: sentenceEndings,
      );
      if (preferredEnd != null && preferredEnd > start) {
        end = preferredEnd;
      }
    }

    results.add(_buildChunkResult(clusters, start, end, metric));
    start = end;
  }

  return results.where((item) => item.content.isNotEmpty).toList();
}

_TextSplitResult _buildChunkResult(
  List<String> clusters,
  int start,
  int end,
  _TextCountMetric metric,
) {
  final content = clusters.sublist(start, end).join();
  return _TextSplitResult(
    content: content,
    rawLength: content.characters.length,
    effectiveLength: _measureClusters(clusters.sublist(start, end), metric),
  );
}

int _advanceToLimit({
  required List<String> clusters,
  required int start,
  required int chunkLimit,
  required _TextCountMetric metric,
}) {
  var effective = 0;
  var index = start;
  while (index < clusters.length) {
    final nextValue = _clusterMetricValue(clusters[index], metric);
    if (effective + nextValue > chunkLimit) {
      if (index == start) {
        return index + 1;
      }
      return index;
    }
    effective += nextValue;
    index += 1;
  }
  return clusters.length;
}

int? _findSentenceBreak({
  required List<String> clusters,
  required int start,
  required int forcedEnd,
  required List<String> sentenceEndings,
}) {
  final endingSet = sentenceEndings.toSet();
  for (var index = forcedEnd - 1; index >= start; index--) {
    if (endingSet.contains(clusters[index])) {
      return index + 1;
    }
  }
  return null;
}

int _measureClusters(List<String> clusters, _TextCountMetric metric) {
  var total = 0;
  for (final cluster in clusters) {
    total += _clusterMetricValue(cluster, metric);
  }
  return total;
}

int _clusterMetricValue(String char, _TextCountMetric metric) {
  final isWhitespace = RegExp(r'\s').hasMatch(char);
  final isContent = RegExp(r'[A-Za-z0-9\u4E00-\u9FFF]').hasMatch(char);
  final isSymbol = !isContent && !isWhitespace;
  return switch (metric) {
    _TextCountMetric.total => 1,
    _TextCountMetric.noSymbols => isSymbol ? 0 : 1,
    _TextCountMetric.noWhitespace => isWhitespace ? 0 : 1,
    _TextCountMetric.contentOnly => isContent ? 1 : 0,
  };
}
