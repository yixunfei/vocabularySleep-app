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

enum _TextCountMetric { total, noSymbols, noWhitespace, contentOnly }

enum _TextSplitMode { fixedLength, sentencePreferred }

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
        return text.characters
            .where((char) => !_isSymbolCharacter(char))
            .length;
      case _TextCountMetric.noWhitespace:
        return text.characters
            .where((char) => !_isWhitespaceCharacter(char))
            .length;
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.text_split_and_count.1f879ec08a67',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.count_text_and_expand_auto_splitting.15295828df9a',
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
              labelText: _lifeI18nText(
                context,
                'inline.plan295.life.input_text.7f94eb5eae24',
              ),
              hintText: _lifeI18nText(
                context,
                'inline.plan295.life.count_first_then_enable_splitting_wh.3035ad4d19f4',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.total.80c11663ed42',
                ),
                value: '$total',
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.symbols.11e6462b50cc',
                ),
                value: '$symbols',
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.no_symbols.8b31011b4ebc',
                ),
                value: '$noSymbols',
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.no_whitespace.124363a7bc4f',
                ),
                value: '$noWhitespace',
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.content_only.edb91509ece5',
                ),
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
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.enable_auto_split.9d881440b2c1',
                    ),
                  ),
                  subtitle: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.off_for_counting_only_on_to_generate.5fcf05bb3535',
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
                      key: const PageStorageKey<String>(
                        'life_text_split_panel',
                      ),
                      initiallyExpanded: _splitPanelExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() => _splitPanelExpanded = expanded);
                      },
                      title: Text(
                        _lifeI18nText(
                          context,
                          'inline.plan295.life.split_settings_and_results.6ae20ba89081',
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _lifeI18nText(
                          context,
                          'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.text.counter.using_with_chunk_s.9a90aaa3a7',
                          params: <String, Object?>{
                            'p0': _metricLabel(context, _metric),
                            'length': chunks.length,
                          },
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: <Widget>[
                        DropdownButtonFormField<_TextCountMetric>(
                          initialValue: _metric,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: _lifeI18nText(
                              context,
                              'inline.plan295.life.count_by.64ca83d7fe99',
                            ),
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
                            labelText: _lifeI18nText(
                              context,
                              'inline.plan295.life.split_mode.b2b8c203c746',
                            ),
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
                            labelText: _lifeI18nText(
                              context,
                              'inline.plan295.life.chunk_size_limit.a469ed8648e8',
                            ),
                            helperText: _lifeI18nText(
                              context,
                              'inline.plan295.life.uses_the_selected_metric_default_is.946bbae1bedf',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _sentenceController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: _lifeI18nText(
                              context,
                              'inline.plan295.life.sentence_endings.441354c823d2',
                            ),
                            helperText: _lifeI18nText(
                              context,
                              'inline.plan295.life.sentence_first_mode_prefers_these_en.594287ee8bf5',
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
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _lifeI18nText(
                                  context,
                                  'inline.plan295.life.split_overview.854b98ff4508',
                                ),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _lifeI18nText(
                                  context,
                                  'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.text.counter.using_there_are_effective_characters_in.650f97f4b7',
                                  params: <String, Object?>{
                                    'p0': _metricLabel(context, _metric),
                                    'totalEffective': totalEffective,
                                    'length': chunks.length,
                                  },
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (_splitMode ==
                                      _TextSplitMode.sentencePreferred &&
                                  sentenceHint.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  _lifeI18nText(
                                    context,
                                    'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.text.counter.preferred_endings.f989e11f88',
                                    params: <String, Object?>{
                                      'sentenceHint': sentenceHint,
                                    },
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
                                            _lifeI18nText(
                                              context,
                                              'inline.plan295.life.original_text_copied.90765dddd9c7',
                                            ),
                                          ),
                                    icon: const Icon(Icons.copy_all_rounded),
                                    label: Text(
                                      _lifeI18nText(
                                        context,
                                        'inline.plan295.life.copy_original.ed31164abdbd',
                                      ),
                                    ),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: chunks.isEmpty
                                        ? null
                                        : () => _copyText(
                                            chunks
                                                .map((chunk) => chunk.content)
                                                .join('\n\n'),
                                            _lifeI18nText(
                                              context,
                                              'inline.plan295.life.all_chunks_copied.ee0b667733a8',
                                            ),
                                          ),
                                    icon: const Icon(Icons.splitscreen_rounded),
                                    label: Text(
                                      _lifeI18nText(
                                        context,
                                        'inline.plan295.life.copy_all_chunks.426cc95e293d',
                                      ),
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
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              _lifeI18nText(
                                context,
                                'inline.plan295.life.collapsed_copyable_chunks_will_appea.ee9f3cb3f95a',
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
                              _lifeI18nText(
                                context,
                                'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.text.counter.chunk_copied.f830e8d908',
                                params: <String, Object?>{'p0': i + 1},
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _lifeI18nText(
                                context,
                                'inline.plan295.life.tip_chunks_stay_collapsed_by_default.152516c937ab',
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
                              _lifeI18nText(
                                context,
                                'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.text.counter.chunk.2c7eda6e36',
                                params: <String, Object?>{'index': index},
                              ),
                              style: titleStyle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lifeI18nText(
                                context,
                                'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.text.counter.raw.7f7b0f8770',
                                params: <String, Object?>{
                                  'rawLength': chunk.rawLength,
                                  'metricLabel': metricLabel,
                                  'effectiveLength': chunk.effectiveLength,
                                },
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
                    tooltip: _lifeI18nText(context, 'copyField'),
                    onPressed: onCopy,
                    icon: const Icon(Icons.content_copy_rounded),
                  ),
                  IconButton(
                    tooltip: isExpanded
                        ? _lifeI18nText(
                            context,
                            'inline.plan295.daily_choice.collapse.ad0db950964e',
                          )
                        : _lifeI18nText(
                            context,
                            'inline.ui.pages.play_page.expand_33fdcb',
                          ),
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
    _TextCountMetric.total => _lifeI18nText(
      context,
      'inline.plan295.life.total.213226d3339d',
    ),
    _TextCountMetric.noSymbols => _lifeI18nText(
      context,
      'inline.plan295.life.no_symbols.8b31011b4ebc',
    ),
    _TextCountMetric.noWhitespace => _lifeI18nText(
      context,
      'inline.plan295.life.no_whitespace.124363a7bc4f',
    ),
    _TextCountMetric.contentOnly => _lifeI18nText(
      context,
      'inline.plan295.life.content_only.edb91509ece5',
    ),
  };
}

String _splitModeLabel(BuildContext context, _TextSplitMode mode) {
  return switch (mode) {
    _TextSplitMode.fixedLength => _lifeI18nText(
      context,
      'inline.plan295.life.fixed_length_split.ac3a3a138c37',
    ),
    _TextSplitMode.sentencePreferred => _lifeI18nText(
      context,
      'inline.plan295.life.sentence_first_split.b5d66ebecb8a',
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
