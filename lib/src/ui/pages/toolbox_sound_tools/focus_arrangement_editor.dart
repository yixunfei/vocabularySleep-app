part of '../toolbox_sound_tools.dart';

// ignore_for_file: dead_code, unused_element, unused_local_variable

class _FocusArrangementEditorResult {
  const _FocusArrangementEditorResult({
    required this.patternEnabled,
    required this.arrangementBeats,
    required this.templates,
    required this.activeTemplateId,
  });

  final bool patternEnabled;
  final List<int> arrangementBeats;
  final List<FocusBeatsArrangementTemplate> templates;
  final String? activeTemplateId;
}

class _FocusArrangementEditorPage extends StatefulWidget {
  const _FocusArrangementEditorPage({
    required this.beatsPerBar,
    required this.patternEnabled,
    required this.arrangementBeats,
    required this.templates,
    required this.activeTemplateId,
    required this.presets,
  });

  final int beatsPerBar;
  final bool patternEnabled;
  final List<int> arrangementBeats;
  final List<FocusBeatsArrangementTemplate> templates;
  final String? activeTemplateId;
  final List<_FocusArrangementPreset> presets;

  @override
  State<_FocusArrangementEditorPage> createState() =>
      _FocusArrangementEditorPageState();
}

class _FocusArrangementEditorPageState
    extends State<_FocusArrangementEditorPage> {
  late bool _patternEnabled;
  late List<int> _arrangementBeats;
  late List<FocusBeatsArrangementTemplate> _templates;
  String? _activeTemplateId;

  @override
  void initState() {
    super.initState();
    _patternEnabled = widget.patternEnabled;
    _arrangementBeats = _normalizeArrangementBeats(widget.arrangementBeats);
    _templates = widget.templates.toList(growable: false);
    _activeTemplateId = widget.activeTemplateId;
    if (_activeTemplateId != null &&
        !_templates.any((item) => item.id == _activeTemplateId)) {
      _activeTemplateId = null;
    }
  }

  List<int> _normalizeArrangementBeats(Iterable<int> values) {
    final normalized = values
        .map((value) => value.clamp(1, 64))
        .map((value) => value.toInt())
        .toList(growable: false);
    if (normalized.isNotEmpty) {
      return normalized;
    }
    return <int>[widget.beatsPerBar];
  }

  String _barsTokenFromBeats(int beats) {
    final gcd = _focusGreatestCommonDivisor(beats, widget.beatsPerBar);
    final numerator = beats ~/ gcd;
    final denominator = widget.beatsPerBar ~/ gcd;
    if (denominator == 1) {
      return '${numerator}bar';
    }
    return '$numerator/${denominator}bar';
  }

  String get _patternRaw =>
      _arrangementBeats.map(_barsTokenFromBeats).join('+');

  int get _totalBeats =>
      _arrangementBeats.fold<int>(0, (sum, item) => sum + item);

  String _newTemplateId() {
    return 'focus_tpl_${DateTime.now().microsecondsSinceEpoch}';
  }

  List<FocusBeatsArrangementTemplate> get _sortedTemplates {
    final list = _templates.toList(growable: false);
    list.sort((a, b) {
      if (a.isFavorite != b.isFavorite) {
        return a.isFavorite ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  void _changeSegmentBeats(int index, int delta) {
    if (index < 0 || index >= _arrangementBeats.length || delta == 0) {
      return;
    }
    setState(() {
      final next = _arrangementBeats.toList(growable: false);
      next[index] = (next[index] + delta).clamp(1, 64);
      _arrangementBeats = _normalizeArrangementBeats(next);
    });
  }

  void _insertSegmentAfter(int index) {
    final insertAt = (index + 1).clamp(0, _arrangementBeats.length);
    setState(() {
      final next = _arrangementBeats.toList(growable: true);
      next.insert(insertAt, widget.beatsPerBar);
      _arrangementBeats = _normalizeArrangementBeats(next);
    });
  }

  void _removeSegment(int index) {
    if (_arrangementBeats.length <= 1 ||
        index < 0 ||
        index >= _arrangementBeats.length) {
      return;
    }
    setState(() {
      final next = _arrangementBeats.toList(growable: true)..removeAt(index);
      _arrangementBeats = _normalizeArrangementBeats(next);
    });
  }

  void _addSegment() {
    setState(() {
      _arrangementBeats = _arrangementBeats.toList(growable: true)
        ..add(widget.beatsPerBar);
    });
  }

  void _applyPreset(_FocusArrangementPreset preset) {
    setState(() {
      _arrangementBeats = _normalizeArrangementBeats(
        preset.segmentsInBars
            .map((bars) => (bars * widget.beatsPerBar).round())
            .toList(growable: false),
      );
      if (_patternEnabled) {
        _activeTemplateId = null;
      }
    });
  }

  void _applyTemplate(FocusBeatsArrangementTemplate template) {
    final result = _parseFocusCyclePattern(
      template.patternText,
      beatsPerBar: widget.beatsPerBar,
      subdivision: 1,
    );
    if (!result.isValid || result.pattern == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('模板格式无效，无法应用。')));
      return;
    }
    final beats = <int>[];
    for (final bars in result.pattern!.segments) {
      final beatsValue = bars * widget.beatsPerBar;
      final rounded = beatsValue.round();
      if ((beatsValue - rounded).abs() > 0.001 || rounded < 1) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('模板包含非整数拍段，当前版本暂不支持。')));
        return;
      }
      beats.add(rounded);
    }
    setState(() {
      _arrangementBeats = _normalizeArrangementBeats(beats);
      _patternEnabled = true;
      _activeTemplateId = template.id;
    });
  }

  Future<void> _promptSaveTemplate({
    FocusBeatsArrangementTemplate? editing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text:
          editing?.name ??
          '模板 ${(DateTime.now().month).toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}',
    );
    var favorite = editing?.isFavorite ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(editing == null ? '保存编排模板' : '编辑编排模板'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 18,
                  decoration: const InputDecoration(
                    labelText: '模板名称',
                    hintText: '如：专注冲刺 20min',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return '请输入模板名称';
                    }
                    return null;
                  },
                ),
                StatefulBuilder(
                  builder: (context, setLocalState) {
                    return SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: favorite,
                      onChanged: (value) {
                        setLocalState(() {
                          favorite = value;
                        });
                      },
                      title: const Text('收藏模板'),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (saved != true || !mounted) {
      return;
    }

    final trimmedName = nameController.text.trim();
    setState(() {
      if (editing == null) {
        final template = FocusBeatsArrangementTemplate(
          id: _newTemplateId(),
          name: trimmedName,
          patternText: _patternRaw,
          isFavorite: favorite,
        );
        _templates = <FocusBeatsArrangementTemplate>[..._templates, template];
        _activeTemplateId = template.id;
      } else {
        _templates = _templates
            .map(
              (item) => item.id == editing.id
                  ? item.copyWith(
                      name: trimmedName,
                      patternText: _patternRaw,
                      isFavorite: favorite,
                    )
                  : item,
            )
            .toList(growable: false);
        _activeTemplateId = editing.id;
      }
    });
  }

  Future<void> _promptDeleteTemplate(
    FocusBeatsArrangementTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除模板'),
          content: Text('确定删除「${template.name}」吗？'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _templates = _templates
          .where((item) => item.id != template.id)
          .toList(growable: false);
      if (_activeTemplateId == template.id) {
        _activeTemplateId = null;
      }
    });
  }

  void _toggleTemplateFavorite(FocusBeatsArrangementTemplate template) {
    setState(() {
      _templates = _templates
          .map(
            (item) => item.id == template.id
                ? item.copyWith(isFavorite: !item.isFavorite)
                : item,
          )
          .toList(growable: false);
    });
  }

  Widget _buildPatternPreview(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (var index = 0; index < _arrangementBeats.length; index += 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              'S${index + 1} · ${_arrangementBeats[index]}拍 · ${_focusBarsLabel(_arrangementBeats[index] / widget.beatsPerBar)}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildTemplateItem(FocusBeatsArrangementTemplate template) {
    final selected = template.id == _activeTemplateId;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: 0.88)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                template.isFavorite
                    ? Icons.star_rounded
                    : Icons.bookmark_rounded,
                size: 16,
                color: template.isFavorite
                    ? const Color(0xFFF3B84B)
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  template.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '当前',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            template.patternText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () => _applyTemplate(template),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('应用'),
              ),
              OutlinedButton.icon(
                onPressed: () => _promptSaveTemplate(editing: template),
                icon: const Icon(Icons.drive_file_rename_outline_rounded),
                label: const Text('重命名'),
              ),
              OutlinedButton.icon(
                onPressed: () => _toggleTemplateFavorite(template),
                icon: Icon(
                  template.isFavorite
                      ? Icons.star_border_rounded
                      : Icons.star_rounded,
                ),
                label: Text(template.isFavorite ? '取消收藏' : '收藏'),
              ),
              OutlinedButton.icon(
                onPressed: () => _promptDeleteTemplate(template),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _finishEditing() {
    String? activeTemplateId = _activeTemplateId;
    if (activeTemplateId != null &&
        !_templates.any((item) => item.id == activeTemplateId)) {
      activeTemplateId = null;
    }
    Navigator.of(context).pop(
      _FocusArrangementEditorResult(
        patternEnabled: _patternEnabled,
        arrangementBeats: _arrangementBeats,
        templates: _templates,
        activeTemplateId: activeTemplateId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编排与模板编辑'),
        actions: <Widget>[
          TextButton(onPressed: _finishEditing, child: const Text('完成')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _patternEnabled,
            onChanged: (value) {
              setState(() {
                _patternEnabled = value;
                if (!value) {
                  _activeTemplateId = null;
                }
              });
            },
            title: const Text('启用循环编排'),
            subtitle: Text(
              _patternEnabled
                  ? '当前编排：$_patternRaw（共 $_totalBeats 拍）'
                  : '当前为单小节循环',
            ),
          ),
          const SizedBox(height: 10),
          const SectionHeader(title: '拍段编辑', subtitle: '按拍段逐个加减，可插入与删除。'),
          const SizedBox(height: 8),
          Column(
            children: <Widget>[
              for (var i = 0; i < _arrangementBeats.length; i += 1) ...<Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            '拍段 ${i + 1}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            '${_arrangementBeats[i]}拍',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () => _changeSegmentBeats(i, -1),
                            icon: const Icon(Icons.remove_rounded),
                            label: const Text('-1 拍'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _changeSegmentBeats(i, 1),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('+1 拍'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _insertSegmentAfter(i),
                            icon: const Icon(Icons.add_box_outlined),
                            label: const Text('后插拍段'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _arrangementBeats.length <= 1
                                ? null
                                : () => _removeSegment(i),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('删除'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (i != _arrangementBeats.length - 1)
                  const SizedBox(height: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _addSegment,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('新增拍段'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _arrangementBeats = <int>[widget.beatsPerBar];
                    _activeTemplateId = null;
                  });
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('重置编排'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _promptSaveTemplate(),
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('保存为模板'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.presets
                .map(
                  (preset) => ActionChip(
                    label: Text(preset.name),
                    onPressed: () => _applyPreset(preset),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          _buildPatternPreview(context),
          const SizedBox(height: 14),
          const SectionHeader(title: '编排模板库', subtitle: '可收藏、命名、应用、删除。'),
          const SizedBox(height: 8),
          if (_sortedTemplates.isEmpty)
            Text(
              '还没有模板，可先编辑拍段后点击“保存为模板”。',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Column(
              children: <Widget>[
                for (
                  var i = 0;
                  i < _sortedTemplates.length;
                  i += 1
                ) ...<Widget>[
                  _buildTemplateItem(_sortedTemplates[i]),
                  if (i != _sortedTemplates.length - 1)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _finishEditing,
            icon: const Icon(Icons.check_rounded),
            label: const Text('完成并返回'),
          ),
        ],
      ),
    );
  }
}
