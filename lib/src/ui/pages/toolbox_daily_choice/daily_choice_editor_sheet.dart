part of 'daily_choice_widgets.dart';

class DailyChoiceEditorResult {
  const DailyChoiceEditorResult({
    required this.option,
    this.eatCollectionIds = const <String>{},
    this.wearCollectionIds = const <String>{},
    this.activityCollectionIds = const <String>{},
  });

  final DailyChoiceOption option;
  final Set<String> eatCollectionIds;
  final Set<String> wearCollectionIds;
  final Set<String> activityCollectionIds;
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
  String contextLabelKey = 'toolbox.daily_choice.editor.field.scene',
  DailyChoiceOption? option,
  bool forceNewId = false,
  List<DailyChoiceEatCollection> eatCollections =
      const <DailyChoiceEatCollection>[],
  Set<String> initialEatCollectionIds = const <String>{},
  List<DailyChoiceWearCollection> wearCollections =
      const <DailyChoiceWearCollection>[],
  Set<String> initialWearCollectionIds = const <String>{},
  List<DailyChoiceActivityCollection> activityCollections =
      const <DailyChoiceActivityCollection>[],
  Set<String> initialActivityCollectionIds = const <String>{},
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
        contextLabelKey: contextLabelKey,
        option: option,
        forceNewId: forceNewId,
        eatCollections: eatCollections,
        initialEatCollectionIds: initialEatCollectionIds,
        wearCollections: wearCollections,
        initialWearCollectionIds: initialWearCollectionIds,
        activityCollections: activityCollections,
        initialActivityCollectionIds: initialActivityCollectionIds,
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
    this.contextLabelKey = 'toolbox.daily_choice.editor.field.scene',
    this.option,
    this.forceNewId = false,
    this.eatCollections = const <DailyChoiceEatCollection>[],
    this.initialEatCollectionIds = const <String>{},
    this.wearCollections = const <DailyChoiceWearCollection>[],
    this.initialWearCollectionIds = const <String>{},
    this.activityCollections = const <DailyChoiceActivityCollection>[],
    this.initialActivityCollectionIds = const <String>{},
  });

  final AppI18n i18n;
  final Color accent;
  final String moduleId;
  final List<DailyChoiceCategory> categories;
  final String initialCategoryId;
  final List<DailyChoiceCategory> contexts;
  final String? initialContextId;
  final String contextLabelKey;
  final DailyChoiceOption? option;
  final bool forceNewId;
  final List<DailyChoiceEatCollection> eatCollections;
  final Set<String> initialEatCollectionIds;
  final List<DailyChoiceWearCollection> wearCollections;
  final Set<String> initialWearCollectionIds;
  final List<DailyChoiceActivityCollection> activityCollections;
  final Set<String> initialActivityCollectionIds;

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
  late Set<String> _selectedActivityCollectionIds;
  bool _saving = false;

  bool get _isEatModule =>
      widget.moduleId == DailyChoiceModuleId.eat.storageValue;
  bool get _isWearModule =>
      widget.moduleId == DailyChoiceModuleId.wear.storageValue;
  bool get _isActivityModule =>
      widget.moduleId == DailyChoiceModuleId.activity.storageValue;

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
    _selectedActivityCollectionIds = _resolveInitialActivityCollectionIds();
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

  String _editorModuleKey({
    required String eatKey,
    required String wearKey,
    required String activityKey,
    required String defaultKey,
  }) {
    if (_isEatModule) {
      return eatKey;
    }
    if (_isWearModule) {
      return wearKey;
    }
    if (_isActivityModule) {
      return activityKey;
    }
    return defaultKey;
  }

  String _editorTitleKey() {
    if (widget.forceNewId) {
      return _editorModuleKey(
        eatKey: 'inline.plan295.daily_choice.save_as_personal_recipe.ff812c8062d5',
        wearKey: 'inline.plan295.daily_choice.save_to_my_wardrobe.8d5c904e4187',
        activityKey:
            'inline.plan295.daily_choice.save_to_action_set.40bdbc29f8f2',
        defaultKey: 'inline.plan295.daily_choice.save_as_custom_item.277464962f22',
      );
    }
    if (widget.option == null) {
      return _editorModuleKey(
        eatKey: 'inline.plan295.daily_choice.add_recipe.342dfa0d76b3',
        wearKey: 'inline.plan295.daily_choice.add_my_wardrobe_outfit.ab5bbfdc5025',
        activityKey: 'inline.plan295.daily_choice.add_action.0a2571423038',
        defaultKey: 'inline.plan295.daily_choice.add_custom_item.4c4b95788fcf',
      );
    }
    return _editorModuleKey(
      eatKey: 'toolbox.daily_choice.editor.title.edit_recipe',
      wearKey: 'inline.plan295.daily_choice.edit_my_wardrobe_outfit.28310bb9b709',
      activityKey: 'inline.plan295.daily_choice.edit_action.c16d134338f5',
      defaultKey: 'inline.plan295.daily_choice.edit_custom_item.ac74bed50d6e',
    );
  }

  String _categoryFieldKey() {
    return _editorModuleKey(
      eatKey: 'inline.plan295.daily_choice.primary_meal.7265865874d4',
      wearKey: 'inline.plan295.daily_choice.temperature.3834f05f20bc',
      activityKey: 'inline.plan295.daily_choice.action_direction.b9d20eafb516',
      defaultKey: 'inline.plan295.daily_choice.category.c3134f512d8c',
    );
  }

  String _titleFieldKey() {
    return _editorModuleKey(
      eatKey: 'inline.plan295.daily_choice.dish_name.227248e036f6',
      wearKey: 'inline.plan295.daily_choice.outfit_formula.42f80447b0f9',
      activityKey: 'inline.plan295.daily_choice.action_name.3391a9a2d227',
      defaultKey: 'inline.plan295.daily_choice.name.a1e8bb92d9f5',
    );
  }

  String _subtitleFieldKey() {
    return _editorModuleKey(
      eatKey: 'inline.plan295.daily_choice.short_recipe_note.fee8f1fec3b5',
      wearKey: 'inline.plan295.daily_choice.when_to_wear_it.c320b8c228cd',
      activityKey: 'inline.plan295.daily_choice.trigger_situation.40dfd18bd598',
      defaultKey: 'inline.plan295.daily_choice.short_note.730780daf0ea',
    );
  }

  String _detailsFieldKey() {
    return _editorModuleKey(
      eatKey: 'inline.plan295.daily_choice.details_when_to_make_it.0a812be3929d',
      wearKey: 'inline.plan295.daily_choice.why_it_works.b3f19d146bcd',
      activityKey: 'inline.plan295.daily_choice.why_and_boundary.9761657c643f',
      defaultKey: 'inline.plan295.daily_choice.details.7bbe5d15d198',
    );
  }

  String _materialsFieldKey() {
    return _editorModuleKey(
      eatKey: 'inline.plan295.daily_choice.ingredients_one_per_line.bc6c5d98c803',
      wearKey: 'inline.plan295.daily_choice.pieces_components.b75e0638b6d0',
      activityKey: 'inline.plan295.daily_choice.start_conditions.16f92dd1e176',
      defaultKey: 'inline.plan295.daily_choice.materials_conditions.feb2d8e31e93',
    );
  }

  String _stepsFieldKey() {
    return _editorModuleKey(
      eatKey: 'inline.plan295.daily_choice.recipe_steps.052c8348637f',
      wearKey: 'inline.plan295.daily_choice.outfit_steps_checklist.d63bb3dc95ee',
      activityKey: 'inline.plan295.daily_choice.action_steps.202c74b134b7',
      defaultKey: 'inline.plan295.daily_choice.steps.a55041a8ded6',
    );
  }

  String _notesFieldKey() {
    return _editorModuleKey(
      eatKey: 'inline.plan295.daily_choice.tips_notes.f75aa7de5045',
      wearKey: 'inline.plan295.daily_choice.wear_notes_care.3dff07117a4e',
      activityKey: 'inline.plan295.daily_choice.exit_rules_notes.08dd313ce34b',
      defaultKey: 'inline.plan295.daily_choice.extra_notes.7308da25fc72',
    );
  }

  String _tagsFieldKey() {
    return _editorModuleKey(
      eatKey: 'toolbox.daily_choice.editor.field.tags.eat',
      wearKey: 'toolbox.daily_choice.editor.field.tags.wear',
      activityKey: 'toolbox.daily_choice.editor.field.tags.activity',
      defaultKey: 'toolbox.daily_choice.editor.field.tags.default',
    );
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

  Set<String> _resolveInitialActivityCollectionIds() {
    if (!_isActivityModule || widget.activityCollections.isEmpty) {
      return <String>{};
    }
    final validIds = widget.activityCollections.map((item) => item.id).toSet();
    return widget.initialActivityCollectionIds.where(validIds.contains).toSet();
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
        activityCollectionIds: _isActivityModule
            ? Set<String>.unmodifiable(_selectedActivityCollectionIds)
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

  void _toggleActivityCollection(String collectionId) {
    setState(() {
      if (_selectedActivityCollectionIds.contains(collectionId)) {
        _selectedActivityCollectionIds.remove(collectionId);
      } else {
        _selectedActivityCollectionIds.add(collectionId);
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
    if (_isActivityModule) {
      final categoryTitle = _categoryTitle(
        _categoryChoices,
        _categoryId,
        useZh,
      );
      final conditionPreview = materials.take(3).join(useZh ? '、' : ', ');
      final leading = subtitle.isEmpty
          ? (useZh
                ? '这是一个保存到行动集里的可执行动作。'
                : 'This is a saved action for an action set.')
          : subtitle;
      return <String>[
        leading,
        if (categoryTitle.isNotEmpty)
          useZh ? '方向：$categoryTitle。' : 'Direction: $categoryTitle.',
        if (conditionPreview.isNotEmpty)
          useZh
              ? '开始条件：$conditionPreview。'
              : 'Start conditions: $conditionPreview.',
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
        return item.title(AppI18n(useZh ? 'zh' : 'en'));
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
                widget.i18n.t(_editorTitleKey()),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              if (_categoryChoices.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: InputDecoration(
                    labelText: widget.i18n.t(_categoryFieldKey()),
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
                    labelText: widget.i18n.t(widget.contextLabelKey),
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
                  widget.i18n.t(
                    'inline.plan295.daily_choice.start_from_pieces_you_actually_own_a.25ff1b114b35',
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
                  widget.i18n.t(
                    'inline.plan295.daily_choice.saving_automatically_infers_overlapp.01f73387bbb9',
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
              if (_isActivityModule &&
                  widget.activityCollections.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                Text(
                  widget.i18n.t(
                    'inline.plan295.daily_choice.save_actions_as_low_friction_finisha.cad2756251d1',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                _EditorActivityCollectionSection(
                  i18n: widget.i18n,
                  accent: widget.accent,
                  collections: widget.activityCollections,
                  selectedIds: _selectedActivityCollectionIds,
                  onToggle: _toggleActivityCollection,
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: widget.i18n.t(_titleFieldKey()),
                  helperText: _isWearModule
                      ? widget.i18n.t(
                          'inline.plan295.daily_choice.use_key_piece_bottom_shoes_outer_lay.47a68960b435',
                        )
                      : (_isActivityModule
                            ? widget.i18n.t(
                                'inline.plan295.daily_choice.start_with_a_verb_such_as_walk_for_1.347fa2be3385',
                              )
                            : null),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subtitleController,
                decoration: InputDecoration(
                  labelText: widget.i18n.t(_subtitleFieldKey()),
                  helperText: _isWearModule
                      ? widget.i18n.t(
                          'inline.plan295.daily_choice.name_the_day_weather_or_mood_this_ou.27de9fb4a3ce',
                        )
                      : (_isActivityModule
                            ? widget.i18n.t(
                                'inline.plan295.daily_choice.name_the_entry_point_such_as_distrac.8290954534c7',
                              )
                            : null),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _detailsController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: widget.i18n.t(_detailsFieldKey()),
                  helperText: _isWearModule
                      ? widget.i18n.t(
                          'inline.plan295.daily_choice.mention_proportion_color_fabric_mobi.10548ba8fdbd',
                        )
                      : (_isActivityModule
                            ? widget.i18n.t(
                                'inline.plan295.daily_choice.state_the_goal_done_condition_and_ex.db1612e68221',
                              )
                            : null),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _materialsController,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: widget.i18n.t(_materialsFieldKey()),
                  helperText: _isWearModule
                      ? widget.i18n.t(
                          'inline.plan295.daily_choice.use_real_closet_pieces_first_add_sub.68d0df66af6a',
                        )
                      : (_isActivityModule
                            ? widget.i18n.t(
                                'inline.plan295.daily_choice.for_example_8_minute_timer_no_outfit.31e62d78ffa9',
                              )
                            : null),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _stepsController,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: widget.i18n.t(_stepsFieldKey()),
                  helperText: _isWearModule
                      ? widget.i18n.t(
                          'inline.plan295.daily_choice.try_layer_first_then_proportion_then.bba5f12db501',
                        )
                      : (_isActivityModule
                            ? widget.i18n.t(
                                'inline.plan295.daily_choice.make_step_one_tiny_end_with_stop_on.7d6f79140c5b',
                              )
                            : null),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: widget.i18n.t(_notesFieldKey()),
                  helperText: _isWearModule
                      ? widget.i18n.t(
                          'inline.plan295.daily_choice.record_easy_to_forget_details_hem_tr.6c828f8a8ebf',
                        )
                      : (_isActivityModule
                            ? widget.i18n.t(
                                'inline.plan295.daily_choice.note_substitutions_when_body_weather.aac27dbd83df',
                              )
                            : null),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: widget.i18n.t(_tagsFieldKey()),
                  helperText: _isWearModule
                      ? widget.i18n.t(
                          'inline.plan295.daily_choice.gender_and_age_are_reference_tags_on.cd9d3f790fc0',
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
                      child: Text(widget.i18n.t('cancel')),
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
                        _saving
                            ? widget.i18n.t(
                                'inline.plan295.daily_choice.saving.3236260eaf53',
                              )
                            : widget.i18n.t('toolbox.sound.soothing.save'),
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
      i18n.t(
        'inline.plan295.daily_choice.start_with_real_pieces_then_note_sub.268ec9a35281',
      ),
      i18n.t(
        'inline.plan295.daily_choice.solve_weather_and_movement_before_st.e18d89b99311',
      ),
      i18n.t(
        'inline.plan295.daily_choice.use_gender_and_age_as_references_not.3c4611001c89',
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
                i18n.t(
                  'inline.plan295.daily_choice.saving_principles.69f9347e2686',
                ),
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
                i18n.t(
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_editor_sheet.save_to_recipe_sets_6135ac',
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            i18n.t(
              'inline.plan295.daily_choice.select_one_or_more_sets_leave_all_un.e0dba9d9ddb6',
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
                i18n.t(
                  'inline.plan295.daily_choice.collection_optionids_length_recipes.44a4a08c31f4',
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
                i18n.t(
                  'inline.plan295.daily_choice.save_to_my_wardrobe.0696b8e8ae1d',
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            i18n.t(
              'inline.plan295.daily_choice.choose_at_least_one_wardrobe_when_po.2baee4769b32',
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
                i18n.t(
                  'inline.plan295.daily_choice.collection_optionids_length_outfits.fcbd023a8667',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditorActivityCollectionSection extends StatelessWidget {
  const _EditorActivityCollectionSection({
    required this.i18n,
    required this.accent,
    required this.collections,
    required this.selectedIds,
    required this.onToggle,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceActivityCollection> collections;
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
                i18n.t(
                  'inline.plan295.daily_choice.save_to_action_sets.363f5d7746d6',
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            i18n.t(
              'inline.plan295.daily_choice.choose_at_least_one_action_set_when.dd41cc48032e',
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
                i18n.t(
                  'inline.plan295.daily_choice.collection_optionids_length_actions.2327f5e73732',
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
