part of 'daily_choice_widgets.dart';

class DailyChoiceEditorResult {
  const DailyChoiceEditorResult({
    required this.option,
    this.eatCollectionIds = const <String>{},
    this.wearCollectionIds = const <String>{},
  });

  final DailyChoiceOption option;
  final Set<String> eatCollectionIds;
  final Set<String> wearCollectionIds;
}

Future<DailyChoiceEditorResult?> showDailyChoiceEditorSheet({
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
  List<DailyChoiceEatCollection> eatCollections =
      const <DailyChoiceEatCollection>[],
  Set<String> initialEatCollectionIds = const <String>{},
  List<DailyChoiceWearCollection> wearCollections =
      const <DailyChoiceWearCollection>[],
  Set<String> initialWearCollectionIds = const <String>{},
}) {
  return showModalBottomSheet<DailyChoiceEditorResult>(
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
        eatCollections: eatCollections,
        initialEatCollectionIds: initialEatCollectionIds,
        wearCollections: wearCollections,
        initialWearCollectionIds: initialWearCollectionIds,
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
    this.eatCollections = const <DailyChoiceEatCollection>[],
    this.initialEatCollectionIds = const <String>{},
    this.wearCollections = const <DailyChoiceWearCollection>[],
    this.initialWearCollectionIds = const <String>{},
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
  final List<DailyChoiceEatCollection> eatCollections;
  final Set<String> initialEatCollectionIds;
  final List<DailyChoiceWearCollection> wearCollections;
  final Set<String> initialWearCollectionIds;

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
  late Set<String> _selectedEatCollectionIds;
  late Set<String> _selectedWearCollectionIds;
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
    _selectedEatCollectionIds = _resolveInitialEatCollectionIds();
    _selectedWearCollectionIds = _resolveInitialWearCollectionIds();
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

  Set<String> _resolveInitialEatCollectionIds() {
    if (!_isEatModule || widget.eatCollections.isEmpty) {
      return <String>{};
    }
    final validIds = widget.eatCollections.map((item) => item.id).toSet();
    return widget.initialEatCollectionIds.where(validIds.contains).toSet();
  }

  Set<String> _resolveInitialWearCollectionIds() {
    if (!_isWearModule || widget.wearCollections.isEmpty) {
      return <String>{};
    }
    final validIds = widget.wearCollections.map((item) => item.id).toSet();
    return widget.initialWearCollectionIds.where(validIds.contains).toSet();
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
    final normalizedOption = _isEatModule
        ? ensureEatOptionAttributes(option)
        : option;
    Navigator.of(context).pop(
      DailyChoiceEditorResult(
        option: normalizedOption,
        eatCollectionIds: _isEatModule
            ? Set<String>.unmodifiable(_selectedEatCollectionIds)
            : const <String>{},
        wearCollectionIds: _isWearModule
            ? Set<String>.unmodifiable(_selectedWearCollectionIds)
            : const <String>{},
      ),
    );
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

  void _toggleEatCollection(String collectionId) {
    setState(() {
      if (_selectedEatCollectionIds.contains(collectionId)) {
        _selectedEatCollectionIds.remove(collectionId);
      } else {
        _selectedEatCollectionIds.add(collectionId);
      }
    });
  }

  void _toggleWearCollection(String collectionId) {
    setState(() {
      if (_selectedWearCollectionIds.contains(collectionId)) {
        _selectedWearCollectionIds.remove(collectionId);
      } else {
        _selectedWearCollectionIds.add(collectionId);
      }
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
                        zh: _isEatModule
                            ? '另存为个人食谱'
                            : (_isWearModule ? '另存到我的衣柜' : '另存为自定义条目'),
                        en: _isEatModule
                            ? 'Save as personal recipe'
                            : (_isWearModule
                                  ? 'Save to my wardrobe'
                                  : 'Save as custom item'),
                      )
                    : widget.option == null
                    ? pickUiText(
                        widget.i18n,
                        zh: _isWearModule ? '新增我的衣柜搭配' : '新增自定义条目',
                        en: _isWearModule
                            ? 'Add my wardrobe outfit'
                            : 'Add custom item',
                      )
                    : pickUiText(
                        widget.i18n,
                        zh: _isWearModule ? '编辑我的衣柜搭配' : '编辑自定义条目',
                        en: _isWearModule
                            ? 'Edit my wardrobe outfit'
                            : 'Edit custom item',
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
                      zh: _isEatModule
                          ? '主要餐段'
                          : (_isWearModule ? '适用气温' : '分类'),
                      en: _isEatModule
                          ? 'Primary meal'
                          : (_isWearModule ? 'Temperature' : 'Category'),
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
                    zh: '先从你真实拥有的单品出发：能明天就穿、能替换、能重复出现的搭配，才值得放进我的衣柜。',
                    en: 'Start from pieces you actually own. A useful outfit is wearable tomorrow, easy to substitute, and worth repeating.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                _WearEditorPrincipleCard(
                  i18n: widget.i18n,
                  accent: widget.accent,
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
              if (_isWearModule &&
                  widget.wearCollections.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                _EditorWearCollectionSection(
                  i18n: widget.i18n,
                  accent: widget.accent,
                  collections: widget.wearCollections,
                  selectedIds: _selectedWearCollectionIds,
                  onToggle: _toggleWearCollection,
                ),
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
                if (widget.eatCollections.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  _EditorEatCollectionSection(
                    i18n: widget.i18n,
                    accent: widget.accent,
                    collections: widget.eatCollections,
                    selectedIds: _selectedEatCollectionIds,
                    onToggle: _toggleEatCollection,
                  ),
                ],
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    widget.i18n,
                    zh: _isEatModule
                        ? '菜名'
                        : (_isWearModule ? '搭配名称 / 公式' : '名称'),
                    en: _isEatModule
                        ? 'Dish name'
                        : (_isWearModule ? 'Outfit formula' : 'Name'),
                  ),
                  helperText: _isWearModule
                      ? pickUiText(
                          widget.i18n,
                          zh: '写成“核心单品 + 下装 + 鞋/外套”，以后更容易复用。',
                          en: 'Use “key piece + bottom + shoes/outer layer” so it is easy to reuse.',
                        )
                      : null,
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
                        : (_isWearModule ? '一句话使用场景' : '一句话说明'),
                    en: _isEatModule
                        ? 'Short recipe note'
                        : (_isWearModule ? 'When to wear it' : 'Short note'),
                  ),
                  helperText: _isWearModule
                      ? pickUiText(
                          widget.i18n,
                          zh: '说明这套适合哪种日程、天气或心情，不必写成评价。',
                          en: 'Name the day, weather, or mood this outfit solves.',
                        )
                      : null,
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
                        : (_isWearModule ? '为什么这样搭 / 适合哪天穿' : '详细介绍'),
                    en: _isEatModule
                        ? 'Details / when to make it'
                        : (_isWearModule ? 'Why it works' : 'Details'),
                  ),
                  helperText: _isWearModule
                      ? pickUiText(
                          widget.i18n,
                          zh: '可写比例、颜色、材质、行动便利和当天场景。',
                          en: 'Mention proportion, color, fabric, mobility, and scene.',
                        )
                      : null,
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
                  helperText: _isWearModule
                      ? pickUiText(
                          widget.i18n,
                          zh: '优先写真实拥有的单品；没有同款时写可替代颜色、版型或面料。',
                          en: 'Use real closet pieces first; add substitutes by color, shape, or fabric.',
                        )
                      : null,
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
                  helperText: _isWearModule
                      ? pickUiText(
                          widget.i18n,
                          zh: '建议写：先确定内外层，再看比例，最后检查鞋包和天气。',
                          en: 'Try: layer first, then proportion, then shoes, bag, and weather.',
                        )
                      : null,
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
                        : (_isWearModule ? '替换方案 / 保养提醒' : '补充备注（每行一条）'),
                    en: _isEatModule
                        ? 'Tips / notes'
                        : (_isWearModule ? 'Wear notes / care' : 'Extra notes'),
                  ),
                  helperText: _isWearModule
                      ? pickUiText(
                          widget.i18n,
                          zh: '记录容易忘的点：裤长、鞋底、防晒、保暖、易皱或洗护。',
                          en: 'Record easy-to-forget details: hem, traction, sun, warmth, wrinkles, care.',
                        )
                      : null,
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
                  helperText: _isWearModule
                      ? pickUiText(
                          widget.i18n,
                          zh: '性别和年龄只是参考标签，按你自己的穿着习惯选就好。',
                          en: 'Gender and age are reference tags only; choose by your real habits.',
                        )
                      : null,
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

class _WearEditorPrincipleCard extends StatelessWidget {
  const _WearEditorPrincipleCard({required this.i18n, required this.accent});

  final AppI18n i18n;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <String>[
      pickUiText(
        i18n,
        zh: '先写真实单品，再写替代方案。',
        en: 'Start with real pieces, then note substitutes.',
      ),
      pickUiText(
        i18n,
        zh: '先解决温度和行动，再处理风格亮点。',
        en: 'Solve weather and movement before styling accents.',
      ),
      pickUiText(
        i18n,
        zh: '用性别和年龄做参考，不把它们当规则。',
        en: 'Use gender and age as references, not rules.',
      ),
    ];
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(12),
      borderColor: accent.withValues(alpha: 0.16),
      shadowOpacity: 0.02,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                pickUiText(i18n, zh: '录入原则', en: 'Saving principles'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in items) ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 5, color: accent),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _EditorEatCollectionSection extends StatelessWidget {
  const _EditorEatCollectionSection({
    required this.i18n,
    required this.accent,
    required this.collections,
    required this.selectedIds,
    required this.onToggle,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceEatCollection> collections;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: accent.withValues(alpha: 0.16),
      shadowOpacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.playlist_add_check_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                pickUiText(i18n, zh: '保存到食谱集', en: 'Save to recipe sets'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            pickUiText(
              i18n,
              zh: '可以多选；不选则只保存为个人菜谱，不加入任何集合。',
              en: 'Select one or more sets. Leave all unchecked to save only as a personal recipe.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          for (final collection in collections)
            CheckboxListTile(
              value: selectedIds.contains(collection.id),
              onChanged: (_) => onToggle(collection.id),
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(collection.title(i18n)),
              subtitle: Text(
                pickUiText(
                  i18n,
                  zh: '${collection.optionIds.length} 道菜',
                  en: '${collection.optionIds.length} recipes',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditorWearCollectionSection extends StatelessWidget {
  const _EditorWearCollectionSection({
    required this.i18n,
    required this.accent,
    required this.collections,
    required this.selectedIds,
    required this.onToggle,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceWearCollection> collections;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: accent.withValues(alpha: 0.16),
      shadowOpacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.checkroom_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                pickUiText(i18n, zh: '保存到我的衣柜', en: 'Save to my wardrobe'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            pickUiText(
              i18n,
              zh: '建议至少选一个自己的衣柜。这样随机时可以直接从真实衣橱里抽取，而不是只看内置参考。',
              en: 'Choose at least one wardrobe when possible, so random picks can come from your real closet instead of only the built-in reference.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          for (final collection in collections)
            CheckboxListTile(
              value: selectedIds.contains(collection.id),
              onChanged: (_) => onToggle(collection.id),
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(collection.title(i18n)),
              subtitle: Text(
                pickUiText(
                  i18n,
                  zh: '${collection.optionIds.length} 套搭配',
                  en: '${collection.optionIds.length} outfits',
                ),
              ),
            ),
        ],
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
