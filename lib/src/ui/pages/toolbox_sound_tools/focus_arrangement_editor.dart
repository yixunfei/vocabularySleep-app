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

  AppI18n get _i18n => _toolboxI18n(context, listen: false);

  String _t(String key, {Map<String, Object?> params = const {}}) {
    return _i18n.t(key, params: params);
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('toolbox.sound.focus.editor.invalid_template')),
        ),
      );
      return;
    }
    final beats = <int>[];
    for (final bars in result.pattern!.segments) {
      final beatsValue = bars * widget.beatsPerBar;
      final rounded = beatsValue.round();
      if ((beatsValue - rounded).abs() > 0.001 || rounded < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('toolbox.sound.focus.editor.non_integer_template'),
            ),
          ),
        );
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
    final i18n = _i18n;
    final nameController = TextEditingController(
      text:
          editing?.name ??
          i18n.t(
            'toolbox.sound.focus.editor.default_template_name',
            params: <String, Object?>{
              'date':
                  '${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}',
            },
          ),
    );
    var favorite = editing?.isFavorite ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            editing == null
                ? i18n.t('toolbox.sound.focus.editor.save_template_title')
                : i18n.t('toolbox.sound.focus.editor.edit_template_title'),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 18,
                  decoration: InputDecoration(
                    labelText: i18n.t(
                      'toolbox.sound.focus.editor.template_name_label',
                    ),
                    hintText: i18n.t(
                      'toolbox.sound.focus.editor.template_name_hint',
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return i18n.t(
                        'toolbox.sound.focus.editor.template_name_required',
                      );
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
                      title: Text(
                        i18n.t('toolbox.sound.focus.editor.favorite_template'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: Text(i18n.t('save')),
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
        final i18n = _toolboxI18n(context);
        return AlertDialog(
          title: Text(i18n.t('toolbox.sound.focus.editor.delete_template')),
          content: Text(
            i18n.t(
              'toolbox.sound.focus.editor.delete_template_confirm',
              params: <String, Object?>{'name': template.name},
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(i18n.t('delete')),
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
    final i18n = _toolboxI18n(context);
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
              i18n.t(
                'toolbox.sound.focus.editor.segment_preview',
                params: <String, Object?>{
                  'index': index + 1,
                  'beats': _arrangementBeats[index],
                  'bars': _focusBarsLabel(
                    _arrangementBeats[index] / widget.beatsPerBar,
                  ),
                },
              ),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildTemplateItem(FocusBeatsArrangementTemplate template) {
    final selected = template.id == _activeTemplateId;
    final colorScheme = Theme.of(context).colorScheme;
    final i18n = _toolboxI18n(context);
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
                    i18n.t('toolbox.sound.focus.editor.current'),
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
                label: Text(i18n.t('toolbox.sound.soothing.apply')),
              ),
              OutlinedButton.icon(
                onPressed: () => _promptSaveTemplate(editing: template),
                icon: const Icon(Icons.drive_file_rename_outline_rounded),
                label: Text(i18n.t('rename')),
              ),
              OutlinedButton.icon(
                onPressed: () => _toggleTemplateFavorite(template),
                icon: Icon(
                  template.isFavorite
                      ? Icons.star_border_rounded
                      : Icons.star_rounded,
                ),
                label: Text(
                  template.isFavorite
                      ? i18n.t('toolbox.sound.focus.editor.unfavorite')
                      : i18n.t('toolbox.sound.focus.editor.favorite'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _promptDeleteTemplate(template),
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(i18n.t('delete')),
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
    final i18n = _toolboxI18n(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.t('toolbox.sound.focus.editor.page_title')),
        actions: <Widget>[
          TextButton(
            onPressed: _finishEditing,
            child: Text(i18n.t('toolbox.breathing.done')),
          ),
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
            title: Text(i18n.t('toolbox.sound.focus.editor.enable_pattern')),
            subtitle: Text(
              _patternEnabled
                  ? i18n.t(
                      'toolbox.sound.focus.editor.current_pattern',
                      params: <String, Object?>{
                        'pattern': _patternRaw,
                        'beats': _totalBeats,
                      },
                    )
                  : i18n.t('toolbox.sound.focus.editor.single_bar_loop'),
            ),
          ),
          const SizedBox(height: 10),
          SectionHeader(
            title: i18n.t('toolbox.sound.focus.editor.segment_editing'),
            subtitle: i18n.t(
              'toolbox.sound.focus.editor.segment_editing_subtitle',
            ),
          ),
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
                            i18n.t(
                              'toolbox.sound.focus.editor.segment_title',
                              params: <String, Object?>{'index': i + 1},
                            ),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            i18n.t(
                              'toolbox.sound.focus.editor.beats_count',
                              params: <String, Object?>{
                                'beats': _arrangementBeats[i],
                              },
                            ),
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
                            label: Text(
                              i18n.t('toolbox.sound.focus.editor.minus_beat'),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _changeSegmentBeats(i, 1),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(
                              i18n.t('toolbox.sound.focus.editor.plus_beat'),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _insertSegmentAfter(i),
                            icon: const Icon(Icons.add_box_outlined),
                            label: Text(
                              i18n.t('toolbox.sound.focus.editor.insert_after'),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _arrangementBeats.length <= 1
                                ? null
                                : () => _removeSegment(i),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text(i18n.t('delete')),
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
                label: Text(i18n.t('toolbox.sound.focus.editor.add_segment')),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _arrangementBeats = <int>[widget.beatsPerBar];
                    _activeTemplateId = null;
                  });
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(i18n.t('toolbox.sound.focus.editor.reset_pattern')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _promptSaveTemplate(),
                icon: const Icon(Icons.bookmark_add_rounded),
                label: Text(
                  i18n.t('toolbox.sound.focus.editor.save_as_template'),
                ),
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
                    label: Text(preset.label(i18n)),
                    onPressed: () => _applyPreset(preset),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          _buildPatternPreview(context),
          const SizedBox(height: 14),
          SectionHeader(
            title: i18n.t('toolbox.sound.focus.editor.template_library'),
            subtitle: i18n.t(
              'toolbox.sound.focus.editor.template_library_subtitle',
            ),
          ),
          const SizedBox(height: 8),
          if (_sortedTemplates.isEmpty)
            Text(
              i18n.t('toolbox.sound.focus.editor.empty_templates'),
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
            label: Text(i18n.t('toolbox.sound.focus.editor.done_return')),
          ),
        ],
      ),
    );
  }
}
