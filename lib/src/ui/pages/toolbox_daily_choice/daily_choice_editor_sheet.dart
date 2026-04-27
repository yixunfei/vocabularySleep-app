part of 'daily_choice_widgets.dart';

Future<DailyChoiceOption?> showDailyChoiceEditorSheet({
  required BuildContext context,
  required AppI18n i18n,
  required Color accent,
  required String moduleId,
  required List<DailyChoiceCategory> categories,
  required String initialCategoryId,
  List<DailyChoiceCategory> contexts = const <DailyChoiceCategory>[],
  String? initialContextId,
  String contextLabelZh = '场景',
  String contextLabelEn = 'Scene',
  DailyChoiceOption? option,
  bool forceNewId = false,
}) {
  return showModalBottomSheet<DailyChoiceOption>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return DailyChoiceEditorSheet(
        i18n: i18n,
        accent: accent,
        moduleId: moduleId,
        categories: categories,
        initialCategoryId: initialCategoryId,
        contexts: contexts,
        initialContextId: initialContextId,
        contextLabelZh: contextLabelZh,
        contextLabelEn: contextLabelEn,
        option: option,
        forceNewId: forceNewId,
      );
    },
  );
}

class DailyChoiceEditorSheet extends StatefulWidget {
  const DailyChoiceEditorSheet({
    super.key,
    required this.i18n,
    required this.accent,
    required this.moduleId,
    required this.categories,
    required this.initialCategoryId,
    this.contexts = const <DailyChoiceCategory>[],
    this.initialContextId,
    this.contextLabelZh = '场景',
    this.contextLabelEn = 'Scene',
    this.option,
    this.forceNewId = false,
  });

  final AppI18n i18n;
  final Color accent;
  final String moduleId;
  final List<DailyChoiceCategory> categories;
  final String initialCategoryId;
  final List<DailyChoiceCategory> contexts;
  final String? initialContextId;
  final String contextLabelZh;
  final String contextLabelEn;
  final DailyChoiceOption? option;
  final bool forceNewId;

  @override
  State<DailyChoiceEditorSheet> createState() => _DailyChoiceEditorSheetState();
}

class _DailyChoiceEditorSheetState extends State<DailyChoiceEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _detailsController;
  late final TextEditingController _materialsController;
  late final TextEditingController _stepsController;
  late final TextEditingController _notesController;
  late final TextEditingController _tagsController;
  late final List<DailyChoiceCategory> _categoryChoices;
  late final List<DailyChoiceCategory> _contextChoices;
  late String _categoryId;
  String? _contextId;
  late final Map<String, Set<String>> _selectedAttributes;
  bool _saving = false;

  bool get _isEatModule =>
      widget.moduleId == DailyChoiceModuleId.eat.storageValue;
  bool get _isWearModule =>
      widget.moduleId == DailyChoiceModuleId.wear.storageValue;

  @override
  void initState() {
    super.initState();
    final option = widget.option;
    _categoryChoices = _dedupeEditorChoices(widget.categories);
    _contextChoices = _dedupeEditorChoices(widget.contexts);
    _titleController = TextEditingController(text: option?.titleZh ?? '');
    _subtitleController = TextEditingController(text: option?.subtitleZh ?? '');
    _detailsController = TextEditingController(text: option?.detailsZh ?? '');
    _materialsController = TextEditingController(
      text: option?.materialsZh.join('\n') ?? '',
    );
    _stepsController = TextEditingController(
      text: option?.stepsZh.join('\n') ?? '',
    );
    _notesController = TextEditingController(
      text: option?.notesZh.join('\n') ?? '',
    );
    _tagsController = TextEditingController(
      text: option?.tagsZh.join('、') ?? '',
    );
    _categoryId = _resolveInitialCategoryId(option);
    _contextId = _resolveInitialContextId(option);
    _selectedAttributes = <String, Set<String>>{
      for (final group in wearTraitGroups)
        group.id: option?.attributeValues(group.id).toSet() ?? <String>{},
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _detailsController.dispose();
    _materialsController.dispose();
    _stepsController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _resolveInitialCategoryId(DailyChoiceOption? option) {
    final preferredId = option?.categoryId ?? widget.initialCategoryId;
    if (_categoryChoices.any((item) => item.id == preferredId)) {
      return preferredId;
    }
    return _categoryChoices.isEmpty ? preferredId : _categoryChoices.first.id;
  }

  String? _resolveInitialContextId(DailyChoiceOption? option) {
    if (_contextChoices.isEmpty) {
      return null;
    }
    final validContextIds = _contextChoices.map((item) => item.id).toSet();
    final candidates = <String?>[
      option?.contextId,
      ...?option?.contextIds,
      widget.initialContextId,
      _contextChoices.first.id,
    ];
    for (final candidate in candidates) {
      if (candidate != null && validContextIds.contains(candidate)) {
        return candidate;
      }
    }
    return _contextChoices.first.id;
  }

  void _save() {
    if (_saving) {
      return;
    }
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      return;
    }
    setState(() {
      _saving = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _finishSave(title);
      }
    });
  }

  void _finishSave(String title) {
    final subtitle = _subtitleController.text.trim();
    final materials = _splitLines(_materialsController.text);
    final steps = _splitLines(_stepsController.text);
    final notes = _splitLines(_notesController.text);
    final rawTags = _splitTags(_tagsController.text);
    final contextIds = _contextChoices.isEmpty
        ? const <String>[]
        : (_contextId == null || _contextId == 'all')
        ? const <String>[]
        : <String>[_contextId!];

    final attributes = _buildAttributes(
      title: title,
      materials: materials,
      notes: notes,
      rawTags: rawTags,
      contextIds: contextIds,
    );

    final tagsZh = _isWearModule
        ? _mergeWearTags(_tagsController.text, wearTraitLabelsZh(attributes))
        : (_isEatModule
              ? <String>{
                  ...rawTags,
                  ...eatTraitLabelsZh(
                    attributes,
                    groupIds: <String>[eatAttributeType, eatAttributeProfile],
                    limit: 5,
                  ),
                }.toList(growable: false)
              : rawTags);
    final tagsEn = _isWearModule
        ? _mergeWearTags(_tagsController.text, wearTraitLabelsEn(attributes))
        : (_isEatModule
              ? <String>{
                  ...rawTags,
                  ...eatTraitLabelsEn(
                    attributes,
                    groupIds: <String>[eatAttributeType, eatAttributeProfile],
                    limit: 5,
                  ),
                }.toList(growable: false)
              : rawTags);

    final details = _detailsController.text.trim().isEmpty
        ? _fallbackDetails(
            title: title,
            subtitle: subtitle,
            materials: materials,
            attributes: attributes,
          )
        : _detailsController.text.trim();

    final id = widget.forceNewId
        ? 'custom_${widget.moduleId}_${DateTime.now().microsecondsSinceEpoch}'
        : widget.option?.id ??
              'custom_${widget.moduleId}_${DateTime.now().microsecondsSinceEpoch}';
    final option = DailyChoiceOption(
      id: id,
      moduleId: widget.moduleId,
      categoryId: _categoryId,
      contextId: _contextChoices.isEmpty ? null : _contextId,
      contextIds: contextIds,
      titleZh: title,
      titleEn: title,
      subtitleZh: subtitle,
      subtitleEn: subtitle,
      detailsZh: details,
      detailsEn: details,
      materialsZh: materials,
      materialsEn: materials,
      stepsZh: steps,
      stepsEn: steps,
      notesZh: notes,
      notesEn: notes,
      tagsZh: tagsZh,
      tagsEn: tagsEn,
      attributes: attributes,
      custom: true,
    );
    Navigator.of(
      context,
    ).pop(_isEatModule ? ensureEatOptionAttributes(option) : option);
  }

  Map<String, List<String>> _buildAttributes({
    required String title,
    required List<String> materials,
    required List<String> notes,
    required List<String> rawTags,
    required List<String> contextIds,
  }) {
    if (_isWearModule) {
      return <String, List<String>>{
        for (final entry in _selectedAttributes.entries)
          if (entry.value.isNotEmpty)
            entry.key: entry.value.toList(growable: false)..sort(),
      };
    }
    if (_isEatModule) {
      return buildEatAttributes(
        title: title,
        materials: materials,
        notes: notes,
        tags: rawTags,
        tools: contextIds,
        primaryMealId: _categoryId,
      );
    }
    return const <String, List<String>>{};
  }

  void _toggleWearTrait(String groupId, String optionId) {
    setState(() {
      final values = _selectedAttributes[groupId] ?? <String>{};
      if (values.contains(optionId)) {
        values.remove(optionId);
      } else {
        values.add(optionId);
      }
      _selectedAttributes[groupId] = values;
    });
  }

  String _fallbackDetails({
    required String title,
    required String subtitle,
    required List<String> materials,
    required Map<String, List<String>> attributes,
    bool useZh = true,
  }) {
    if (_isEatModule) {
      final categoryTitle = _categoryTitle(
        _categoryChoices,
        _categoryId,
        useZh,
      );
      final contextTitle = _categoryTitle(_contextChoices, _contextId, useZh);
      final materialsPreview = materials.take(4).join(useZh ? '、' : ', ');
      final traitPreview =
          (useZh
                  ? eatTraitLabelsZh(
                      attributes,
                      groupIds: <String>[eatAttributeType, eatAttributeProfile],
                      limit: 3,
                    )
                  : eatTraitLabelsEn(
                      attributes,
                      groupIds: <String>[eatAttributeType, eatAttributeProfile],
                      limit: 3,
                    ))
              .join(useZh ? '、' : ', ');
      final scope = <String>[
        if (categoryTitle.isNotEmpty) categoryTitle,
        if (contextTitle.isNotEmpty) contextTitle,
      ].join(useZh ? ' / ' : ' / ');
      final leading = subtitle.isEmpty
          ? (useZh ? '这是我保存的一道个人菜谱。' : 'This is a saved personal recipe.')
          : subtitle;
      return <String>[
        leading,
        if (scope.isNotEmpty) useZh ? '主要用于：$scope。' : 'Best used for: $scope.',
        if (materialsPreview.isNotEmpty)
          useZh
              ? '主要材料：$materialsPreview。'
              : 'Main ingredients: $materialsPreview.',
        if (traitPreview.isNotEmpty)
          useZh ? '大致属于：$traitPreview。' : 'This usually fits: $traitPreview.',
      ].join(' ');
    }
    if (!_isWearModule) {
      return subtitle;
    }
    final categoryTitle = _categoryTitle(_categoryChoices, _categoryId, useZh);
    final contextTitle = _categoryTitle(_contextChoices, _contextId, useZh);
    final traitSummary =
        (useZh
                ? wearTraitLabelsZh(attributes, limit: 4)
                : wearTraitLabelsEn(attributes, limit: 4))
            .join(useZh ? '、' : ', ');
    final scope = <String>[
      if (categoryTitle.isNotEmpty) categoryTitle,
      if (contextTitle.isNotEmpty) contextTitle,
    ].join(' / ');
    final leading = subtitle.isEmpty
        ? (useZh
              ? '这是我整理的一套个人衣橱搭配。'
              : 'This is a saved personal wardrobe outfit.')
        : subtitle;
    final traitLine = traitSummary.isEmpty
        ? (useZh
              ? '重点放在体感舒适、场景得体和重复利用。'
              : 'The priority is comfort, scene fit, and repeatable use.')
        : (useZh ? '风格特征：$traitSummary。' : 'Key traits: $traitSummary.');
    return <String>[
      leading,
      if (scope.isNotEmpty) useZh ? '适用范围：$scope。' : 'Best used for: $scope.',
      traitLine,
    ].join(' ');
  }

  String _categoryTitle(
    List<DailyChoiceCategory> categories,
    String? id,
    bool useZh,
  ) {
    if (id == null) {
      return '';
    }
    for (final item in categories) {
      if (item.id == id) {
        return useZh ? item.titleZh : item.titleEn;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.forceNewId
                    ? pickUiText(
                        widget.i18n,
                        zh: _isEatModule ? '另存为个人食谱' : '另存为自定义条目',
                        en: _isEatModule
                            ? 'Save as personal recipe'
                            : 'Save as custom item',
                      )
                    : widget.option == null
                    ? pickUiText(
                        widget.i18n,
                        zh: '新增自定义条目',
                        en: 'Add custom item',
                      )
                    : pickUiText(
                        widget.i18n,
                        zh: '编辑自定义条目',
                        en: 'Edit custom item',
                      ),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              if (_categoryChoices.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: InputDecoration(
                    labelText: pickUiText(
                      widget.i18n,
                      zh: _isEatModule ? '主要餐段' : '分类',
                      en: _isEatModule ? 'Primary meal' : 'Category',
                    ),
                  ),
                  items: _categoryChoices
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.title(widget.i18n)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _categoryId = value;
                    });
                  },
                ),
              if (_contextChoices.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _contextId ?? _contextChoices.first.id,
                  decoration: InputDecoration(
                    labelText: pickUiText(
                      widget.i18n,
                      zh: widget.contextLabelZh,
                      en: widget.contextLabelEn,
                    ),
                  ),
                  items: _contextChoices
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.title(widget.i18n)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() {
                      _contextId = value;
                    });
                  },
                ),
              ],
              if (_isWearModule) ...<Widget>[
                const SizedBox(height: 14),
                Text(
                  pickUiText(
                    widget.i18n,
                    zh: '先给这套搭配打上风格和样式特征，后面管理个人衣橱时会更容易筛选和复用。',
                    en: 'Tag style and outfit traits first so wardrobe management stays easy to filter and reuse.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                for (final group in wearTraitGroups) ...<Widget>[
                  _EditorTraitSection(
                    i18n: widget.i18n,
                    accent: widget.accent,
                    group: group,
                    selectedIds: _selectedAttributes[group.id] ?? <String>{},
                    onToggle: (optionId) =>
                        _toggleWearTrait(group.id, optionId),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
              if (_isEatModule) ...<Widget>[
                const SizedBox(height: 14),
                Text(
                  pickUiText(
                    widget.i18n,
                    zh: '保存时会自动从菜名、食材、备注和主餐段推断餐段重叠、食材关键词、做法类型和常见排除项。',
                    en: 'Saving automatically infers overlapping meals, ingredient keywords, dish types, and common avoid terms from the title, materials, notes, and primary meal.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    widget.i18n,
                    zh: _isEatModule ? '菜名' : '名称',
                    en: _isEatModule ? 'Dish name' : 'Name',
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subtitleController,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    widget.i18n,
                    zh: _isEatModule
                        ? '一句话推荐 / 口味特点'
                        : (_isWearModule ? '一句话风格说明' : '一句话说明'),
                    en: _isEatModule
                        ? 'Short recipe note'
                        : (_isWearModule ? 'Style note' : 'Short note'),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _detailsController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    widget.i18n,
                    zh: _isEatModule
                        ? '详细介绍 / 适合什么时候做'
                        : (_isWearModule ? '详细介绍 / 穿着场景' : '详细介绍'),
                    en: _isEatModule ? 'Details / when to make it' : 'Details',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _materialsController,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    widget.i18n,
                    zh: _isEatModule
                        ? '食材清单（每行一个）'
                        : (_isWearModule
                              ? '核心单品 / 搭配组成（每行一个）'
                              : '材料 / 条件（每行一个）'),
                    en: _isEatModule
                        ? 'Ingredients (one per line)'
                        : (_isWearModule
                              ? 'Pieces / components'
                              : 'Materials / conditions'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _stepsController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    widget.i18n,
                    zh: _isEatModule
                        ? '详细做法（每行一步）'
                        : (_isWearModule ? '穿法步骤 / 出门检查' : '方法步骤（每行一步）'),
                    en: _isEatModule
                        ? 'Recipe steps'
                        : (_isWearModule
                              ? 'Outfit steps / checklist'
                              : 'Steps'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    widget.i18n,
                    zh: _isEatModule
                        ? '技巧 / 备注（每行一条）'
                        : (_isWearModule ? '适用提醒 / 保养备注' : '补充备注（每行一条）'),
                    en: _isEatModule
                        ? 'Tips / notes'
                        : (_isWearModule ? 'Wear notes / care' : 'Extra notes'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    widget.i18n,
                    zh: _isEatModule
                        ? '附加标签（例如家常、下饭、减脂）'
                        : (_isWearModule
                              ? '附加标签（会自动并入风格特征）'
                              : '标签（用顿号、逗号或空格分隔）'),
                    en: 'Tags',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        pickUiText(widget.i18n, zh: '取消', en: 'Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        pickUiText(
                          widget.i18n,
                          zh: _saving ? '保存中' : '保存',
                          en: _saving ? 'Saving' : 'Save',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorTraitSection extends StatelessWidget {
  const _EditorTraitSection({
    required this.i18n,
    required this.accent,
    required this.group,
    required this.selectedIds,
    required this.onToggle,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceTraitGroup group;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(group.icon, size: 18, color: accent),
            const SizedBox(width: 6),
            Text(
              group.title(i18n),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          group.subtitle(i18n),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: group.options
              .map(
                (option) => FilterChip(
                  selected: selectedIds.contains(option.id),
                  label: Text(option.title(i18n)),
                  avatar: Icon(option.icon, size: 16),
                  showCheckmark: false,
                  selectedColor: accent.withValues(alpha: 0.16),
                  onSelected: (_) => onToggle(option.id),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

List<String> _mergeWearTags(String raw, List<String> traits) {
  return <String>{..._splitTags(raw), ...traits}.toList(growable: false);
}

List<DailyChoiceCategory> _dedupeEditorChoices(
  List<DailyChoiceCategory> categories,
) {
  final seen = <String>{};
  final unique = <DailyChoiceCategory>[];
  for (final category in categories) {
    if (category.id.trim().isEmpty || !seen.add(category.id)) {
      continue;
    }
    unique.add(category);
  }
  final withoutAll = unique
      .where((category) => category.id != 'all')
      .toList(growable: false);
  return withoutAll.isEmpty ? unique : withoutAll;
}
