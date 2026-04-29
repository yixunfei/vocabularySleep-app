part of 'daily_choice_widgets.dart';

Future<String?> _promptEatCollectionName({
  required BuildContext context,
  required AppI18n i18n,
  required Color accent,
  required String initialTitle,
}) async {
  final controller = TextEditingController(text: initialTitle);
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(pickUiText(i18n, zh: '重命名食谱集', en: 'Rename set')),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.bookmarks_rounded),
              labelText: pickUiText(i18n, zh: '食谱集名称', en: 'Set name'),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: accent),
              ),
            ),
            onSubmitted: (value) {
              final title = value.trim();
              if (title.isNotEmpty) {
                Navigator.of(context).pop(title);
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
            ),
            FilledButton.icon(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  Navigator.of(context).pop(title);
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(pickUiText(i18n, zh: '保存', en: 'Save')),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

Future<bool?> _confirmDeleteEatCollection({
  required BuildContext context,
  required AppI18n i18n,
  required DailyChoiceEatCollection collection,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(pickUiText(i18n, zh: '删除食谱集？', en: 'Delete recipe set?')),
        content: Text(
          pickUiText(
            i18n,
            zh: '「${collection.title(i18n)}」只会删除这个集合，不会删除集合里的个人菜谱或内置菜谱。',
            en: '"${collection.title(i18n)}" will be removed as a set. Recipes inside it will not be deleted.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(pickUiText(i18n, zh: '删除', en: 'Delete')),
          ),
        ],
      );
    },
  );
}

const _eatCollectionExportFormat =
    'vocabulary_sleep_daily_choice_eat_collection';
const _eatCollectionExportFormatVersion = 1;

Map<String, Object?> _buildEatCollectionExportPackage({
  required DailyChoiceCustomState state,
  required DailyChoiceEatCollection collection,
}) {
  final optionIds = collection.optionIds.toSet();
  final customOptions = state.customOptions
      .where(
        (option) =>
            option.moduleId == DailyChoiceModuleId.eat.storageValue &&
            optionIds.contains(option.id),
      )
      .map((option) => option.toJson())
      .toList(growable: false);
  final adjustedBuiltIns = state.adjustedBuiltInOptions
      .where(
        (option) =>
            option.moduleId == DailyChoiceModuleId.eat.storageValue &&
            optionIds.contains(option.id),
      )
      .map((option) => option.toJson())
      .toList(growable: false);
  return <String, Object?>{
    'format': _eatCollectionExportFormat,
    'formatVersion': _eatCollectionExportFormatVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'collections': <Object?>[collection.toJson()],
    'customOptions': customOptions,
    'adjustedBuiltInOptions': adjustedBuiltIns,
  };
}

_EatCollectionImportResult _importEatCollectionExportPackage({
  required DailyChoiceCustomState state,
  required Map<String, Object?> payload,
}) {
  if (payload['format'] != _eatCollectionExportFormat) {
    throw const FormatException('Unsupported recipe set package.');
  }
  if (payload['formatVersion'] != _eatCollectionExportFormatVersion) {
    throw const FormatException('Unsupported recipe set package version.');
  }
  final collections = _eatCollectionJsonList(payload['collections'])
      .map(DailyChoiceEatCollection.fromJson)
      .where((collection) {
        return collection.id.trim().isNotEmpty ||
            collection.titleZh.trim().isNotEmpty ||
            collection.titleEn.trim().isNotEmpty;
      })
      .toList(growable: false);
  if (collections.isEmpty) {
    throw const FormatException('Recipe set package has no collections.');
  }

  var next = state.withDefaultEatCollections();
  final existingCustomIds = next.customOptions.map((item) => item.id).toSet();
  final importedOptionIdByOriginalId = <String, String>{};
  var uniqueSeed = DateTime.now().microsecondsSinceEpoch;
  var customCount = 0;
  var adjustedCount = 0;

  for (final raw in _eatCollectionJsonList(payload['customOptions'])) {
    final option = DailyChoiceOption.fromJson(
      raw,
    ).copyWith(moduleId: DailyChoiceModuleId.eat.storageValue, custom: true);
    final originalId = option.id.trim();
    if (originalId.isEmpty) {
      continue;
    }
    var nextId = originalId;
    if (existingCustomIds.contains(nextId)) {
      nextId = 'custom_eat_import_${uniqueSeed++}';
    }
    importedOptionIdByOriginalId[originalId] = nextId;
    existingCustomIds.add(nextId);
    next = next.upsertCustom(
      ensureEatOptionAttributes(option.copyWith(id: nextId, custom: true)),
    );
    customCount += 1;
  }

  for (final raw in _eatCollectionJsonList(payload['adjustedBuiltInOptions'])) {
    final option = DailyChoiceOption.fromJson(
      raw,
    ).copyWith(moduleId: DailyChoiceModuleId.eat.storageValue, custom: false);
    if (option.id.trim().isEmpty) {
      continue;
    }
    next = next.upsertAdjustedBuiltIn(ensureEatOptionAttributes(option));
    adjustedCount += 1;
  }

  var importedCollectionCount = 0;
  var selectedCollectionId = 'all';
  for (final collection in collections) {
    final fallbackTitle = collection.titleZh.trim().isNotEmpty
        ? collection.titleZh.trim()
        : collection.titleEn.trim();
    if (fallbackTitle.isEmpty) {
      continue;
    }
    final collectionId = 'eat_collection_import_${uniqueSeed++}';
    final optionIds = collection.optionIds
        .map((id) => importedOptionIdByOriginalId[id] ?? id)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    next = next.upsertEatCollection(
      collection.copyWith(
        id: collectionId,
        titleZh: collection.titleZh.trim().isEmpty
            ? fallbackTitle
            : collection.titleZh.trim(),
        titleEn: collection.titleEn.trim().isEmpty
            ? fallbackTitle
            : collection.titleEn.trim(),
        optionIds: optionIds,
      ),
    );
    selectedCollectionId = collectionId;
    importedCollectionCount += 1;
  }

  if (importedCollectionCount == 0) {
    throw const FormatException('Recipe set package has no valid collections.');
  }
  return _EatCollectionImportResult(
    state: next,
    selectedCollectionId: selectedCollectionId,
    collectionCount: importedCollectionCount,
    customCount: customCount,
    adjustedCount: adjustedCount,
  );
}

List<Map<String, Object?>> _eatCollectionJsonList(Object? raw) {
  if (raw is! List) {
    return const <Map<String, Object?>>[];
  }
  return raw
      .whereType<Map>()
      .map((item) => item.cast<String, Object?>())
      .toList(growable: false);
}

String _safeEatCollectionExportFileName(String title) {
  final normalized = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  if (normalized.isEmpty) {
    return 'daily_choice_recipe_set';
  }
  return normalized.length > 40 ? normalized.substring(0, 40) : normalized;
}

class _EatCollectionImportResult {
  const _EatCollectionImportResult({
    required this.state,
    required this.selectedCollectionId,
    required this.collectionCount,
    required this.customCount,
    required this.adjustedCount,
  });

  final DailyChoiceCustomState state;
  final String selectedCollectionId;
  final int collectionCount;
  final int customCount;
  final int adjustedCount;
}

Future<String?> _promptWearCollectionName({
  required BuildContext context,
  required AppI18n i18n,
  required Color accent,
  required String initialTitle,
}) async {
  final controller = TextEditingController(text: initialTitle);
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(pickUiText(i18n, zh: '重命名衣橱', en: 'Rename wardrobe')),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.checkroom_rounded),
              labelText: pickUiText(i18n, zh: '衣橱名称', en: 'Wardrobe name'),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: accent),
              ),
            ),
            onSubmitted: (value) {
              final title = value.trim();
              if (title.isNotEmpty) {
                Navigator.of(context).pop(title);
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
            ),
            FilledButton.icon(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  Navigator.of(context).pop(title);
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(pickUiText(i18n, zh: '保存', en: 'Save')),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

Future<bool?> _confirmDeleteWearCollection({
  required BuildContext context,
  required AppI18n i18n,
  required DailyChoiceWearCollection collection,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(pickUiText(i18n, zh: '删除衣橱？', en: 'Delete wardrobe?')),
        content: Text(
          pickUiText(
            i18n,
            zh: '「${collection.title(i18n)}」只会删除这个衣橱，不会删除衣橱里的个人搭配或内置穿搭。',
            en: '"${collection.title(i18n)}" will be removed as a wardrobe. Outfits inside it will not be deleted.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(pickUiText(i18n, zh: '删除', en: 'Delete')),
          ),
        ],
      );
    },
  );
}

const _wearCollectionExportFormat =
    'vocabulary_sleep_daily_choice_wear_collection';
const _wearCollectionExportFormatVersion = 1;

Map<String, Object?> _buildWearCollectionExportPackage({
  required DailyChoiceCustomState state,
  required DailyChoiceWearCollection collection,
}) {
  final optionIds = collection.optionIds.toSet();
  final customOptions = state.customOptions
      .where(
        (option) =>
            option.moduleId == DailyChoiceModuleId.wear.storageValue &&
            optionIds.contains(option.id),
      )
      .map((option) => option.toJson())
      .toList(growable: false);
  final adjustedBuiltIns = state.adjustedBuiltInOptions
      .where(
        (option) =>
            option.moduleId == DailyChoiceModuleId.wear.storageValue &&
            optionIds.contains(option.id),
      )
      .map((option) => option.toJson())
      .toList(growable: false);
  return <String, Object?>{
    'format': _wearCollectionExportFormat,
    'formatVersion': _wearCollectionExportFormatVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'collections': <Object?>[collection.toJson()],
    'customOptions': customOptions,
    'adjustedBuiltInOptions': adjustedBuiltIns,
  };
}

_WearCollectionImportResult _importWearCollectionExportPackage({
  required DailyChoiceCustomState state,
  required Map<String, Object?> payload,
}) {
  if (payload['format'] != _wearCollectionExportFormat) {
    throw const FormatException('Unsupported wardrobe package.');
  }
  if (payload['formatVersion'] != _wearCollectionExportFormatVersion) {
    throw const FormatException('Unsupported wardrobe package version.');
  }
  final collections = _eatCollectionJsonList(payload['collections'])
      .map(DailyChoiceWearCollection.fromJson)
      .where((collection) {
        return collection.id.trim().isNotEmpty ||
            collection.titleZh.trim().isNotEmpty ||
            collection.titleEn.trim().isNotEmpty;
      })
      .toList(growable: false);
  if (collections.isEmpty) {
    throw const FormatException('Wardrobe package has no collections.');
  }

  var next = state.withDefaultWearCollections();
  final existingCustomIds = next.customOptions.map((item) => item.id).toSet();
  final importedOptionIdByOriginalId = <String, String>{};
  var uniqueSeed = DateTime.now().microsecondsSinceEpoch;
  var customCount = 0;
  var adjustedCount = 0;

  for (final raw in _eatCollectionJsonList(payload['customOptions'])) {
    final option = DailyChoiceOption.fromJson(
      raw,
    ).copyWith(moduleId: DailyChoiceModuleId.wear.storageValue, custom: true);
    final originalId = option.id.trim();
    if (originalId.isEmpty) {
      continue;
    }
    var nextId = originalId;
    if (existingCustomIds.contains(nextId)) {
      nextId = 'custom_wear_import_${uniqueSeed++}';
    }
    importedOptionIdByOriginalId[originalId] = nextId;
    existingCustomIds.add(nextId);
    next = next.upsertCustom(option.copyWith(id: nextId, custom: true));
    customCount += 1;
  }

  for (final raw in _eatCollectionJsonList(payload['adjustedBuiltInOptions'])) {
    final option = DailyChoiceOption.fromJson(
      raw,
    ).copyWith(moduleId: DailyChoiceModuleId.wear.storageValue, custom: false);
    if (option.id.trim().isEmpty) {
      continue;
    }
    next = next.upsertAdjustedBuiltIn(option);
    adjustedCount += 1;
  }

  var importedCollectionCount = 0;
  var selectedCollectionId = 'all';
  for (final collection in collections) {
    final fallbackTitle = collection.titleZh.trim().isNotEmpty
        ? collection.titleZh.trim()
        : collection.titleEn.trim();
    if (fallbackTitle.isEmpty) {
      continue;
    }
    final collectionId = 'wear_collection_import_${uniqueSeed++}';
    final optionIds = collection.optionIds
        .map((id) => importedOptionIdByOriginalId[id] ?? id)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    next = next.upsertWearCollection(
      collection.copyWith(
        id: collectionId,
        titleZh: collection.titleZh.trim().isEmpty
            ? fallbackTitle
            : collection.titleZh.trim(),
        titleEn: collection.titleEn.trim().isEmpty
            ? fallbackTitle
            : collection.titleEn.trim(),
        optionIds: optionIds,
      ),
    );
    selectedCollectionId = collectionId;
    importedCollectionCount += 1;
  }

  if (importedCollectionCount == 0) {
    throw const FormatException('Wardrobe package has no valid collections.');
  }
  return _WearCollectionImportResult(
    state: next,
    selectedCollectionId: selectedCollectionId,
    collectionCount: importedCollectionCount,
    customCount: customCount,
    adjustedCount: adjustedCount,
  );
}

String _safeWearCollectionExportFileName(String title) {
  final normalized = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  if (normalized.isEmpty) {
    return 'daily_choice_wardrobe';
  }
  return normalized;
}

class _WearCollectionImportResult {
  const _WearCollectionImportResult({
    required this.state,
    required this.selectedCollectionId,
    required this.collectionCount,
    required this.customCount,
    required this.adjustedCount,
  });

  final DailyChoiceCustomState state;
  final String selectedCollectionId;
  final int collectionCount;
  final int customCount;
  final int adjustedCount;
}

Set<String> _managerInitialWearCollectionIds({
  required List<DailyChoiceWearCollection> collections,
  required DailyChoiceOption? option,
  required DailyChoiceWearCollection? selectedCollection,
  required bool defaultFavoriteWhenEmpty,
}) {
  final ids = <String>{};
  final validIds = collections.map((item) => item.id).toSet();
  final optionId = option?.id.trim();
  if (optionId != null && optionId.isNotEmpty) {
    for (final collection in collections) {
      if (collection.containsOption(optionId)) {
        ids.add(collection.id);
      }
    }
  }
  if (selectedCollection != null && validIds.contains(selectedCollection.id)) {
    ids.add(selectedCollection.id);
  }
  if (ids.isEmpty &&
      defaultFavoriteWhenEmpty &&
      collections.any(
        (item) => item.id == dailyChoiceFavoriteWearCollectionId,
      )) {
    ids.add(dailyChoiceFavoriteWearCollectionId);
  }
  return ids;
}

Future<String?> _promptActivityCollectionName({
  required BuildContext context,
  required AppI18n i18n,
  required Color accent,
  required String initialTitle,
}) async {
  final controller = TextEditingController(text: initialTitle);
  try {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(pickUiText(i18n, zh: '重命名行动集', en: 'Rename action set')),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.playlist_add_check_rounded),
              labelText: pickUiText(i18n, zh: '行动集名称', en: 'Action set name'),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: accent),
              ),
            ),
            onSubmitted: (value) {
              final title = value.trim();
              if (title.isNotEmpty) {
                Navigator.of(context).pop(title);
              }
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
            ),
            FilledButton.icon(
              onPressed: () {
                final title = controller.text.trim();
                if (title.isNotEmpty) {
                  Navigator.of(context).pop(title);
                }
              },
              icon: const Icon(Icons.check_rounded),
              label: Text(pickUiText(i18n, zh: '保存', en: 'Save')),
            ),
          ],
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

Future<bool?> _confirmDeleteActivityCollection({
  required BuildContext context,
  required AppI18n i18n,
  required DailyChoiceActivityCollection collection,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(pickUiText(i18n, zh: '删除行动集？', en: 'Delete action set?')),
        content: Text(
          pickUiText(
            i18n,
            zh: '「${collection.title(i18n)}」只会删除这个集合，不会删除集合里的个人行动或内置行动。',
            en: '"${collection.title(i18n)}" will be removed as a set. Actions inside it will not be deleted.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(pickUiText(i18n, zh: '删除', en: 'Delete')),
          ),
        ],
      );
    },
  );
}

const _activityCollectionExportFormat =
    'vocabulary_sleep_daily_choice_activity_collection';
const _activityCollectionExportFormatVersion = 1;

Map<String, Object?> _buildActivityCollectionExportPackage({
  required DailyChoiceCustomState state,
  required DailyChoiceActivityCollection collection,
}) {
  final optionIds = collection.optionIds.toSet();
  final customOptions = state.customOptions
      .where(
        (option) =>
            option.moduleId == DailyChoiceModuleId.activity.storageValue &&
            optionIds.contains(option.id),
      )
      .map((option) => option.toJson())
      .toList(growable: false);
  final adjustedBuiltIns = state.adjustedBuiltInOptions
      .where(
        (option) =>
            option.moduleId == DailyChoiceModuleId.activity.storageValue &&
            optionIds.contains(option.id),
      )
      .map((option) => option.toJson())
      .toList(growable: false);
  return <String, Object?>{
    'format': _activityCollectionExportFormat,
    'formatVersion': _activityCollectionExportFormatVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'collections': <Object?>[collection.toJson()],
    'customOptions': customOptions,
    'adjustedBuiltInOptions': adjustedBuiltIns,
  };
}

_ActivityCollectionImportResult _importActivityCollectionExportPackage({
  required DailyChoiceCustomState state,
  required Map<String, Object?> payload,
}) {
  if (payload['format'] != _activityCollectionExportFormat) {
    throw const FormatException('Unsupported action set package.');
  }
  if (payload['formatVersion'] != _activityCollectionExportFormatVersion) {
    throw const FormatException('Unsupported action set package version.');
  }
  final collections = _eatCollectionJsonList(payload['collections'])
      .map(DailyChoiceActivityCollection.fromJson)
      .where((collection) {
        return collection.id.trim().isNotEmpty ||
            collection.titleZh.trim().isNotEmpty ||
            collection.titleEn.trim().isNotEmpty;
      })
      .toList(growable: false);
  if (collections.isEmpty) {
    throw const FormatException('Action set package has no collections.');
  }

  var next = state.withDefaultActivityCollections();
  final existingCustomIds = next.customOptions.map((item) => item.id).toSet();
  final importedOptionIdByOriginalId = <String, String>{};
  var uniqueSeed = DateTime.now().microsecondsSinceEpoch;
  var customCount = 0;
  var adjustedCount = 0;

  for (final raw in _eatCollectionJsonList(payload['customOptions'])) {
    final option = DailyChoiceOption.fromJson(raw).copyWith(
      moduleId: DailyChoiceModuleId.activity.storageValue,
      custom: true,
    );
    final originalId = option.id.trim();
    if (originalId.isEmpty) {
      continue;
    }
    var nextId = originalId;
    if (existingCustomIds.contains(nextId)) {
      nextId = 'custom_activity_import_${uniqueSeed++}';
    }
    importedOptionIdByOriginalId[originalId] = nextId;
    existingCustomIds.add(nextId);
    next = next.upsertCustom(option.copyWith(id: nextId, custom: true));
    customCount += 1;
  }

  for (final raw in _eatCollectionJsonList(payload['adjustedBuiltInOptions'])) {
    final option = DailyChoiceOption.fromJson(raw).copyWith(
      moduleId: DailyChoiceModuleId.activity.storageValue,
      custom: false,
    );
    if (option.id.trim().isEmpty) {
      continue;
    }
    next = next.upsertAdjustedBuiltIn(option);
    adjustedCount += 1;
  }

  var importedCollectionCount = 0;
  var selectedCollectionId = 'all';
  for (final collection in collections) {
    final fallbackTitle = collection.titleZh.trim().isNotEmpty
        ? collection.titleZh.trim()
        : collection.titleEn.trim();
    if (fallbackTitle.isEmpty) {
      continue;
    }
    final collectionId = 'activity_collection_import_${uniqueSeed++}';
    final optionIds = collection.optionIds
        .map((id) => importedOptionIdByOriginalId[id] ?? id)
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    next = next.upsertActivityCollection(
      collection.copyWith(
        id: collectionId,
        titleZh: collection.titleZh.trim().isEmpty
            ? fallbackTitle
            : collection.titleZh.trim(),
        titleEn: collection.titleEn.trim().isEmpty
            ? fallbackTitle
            : collection.titleEn.trim(),
        optionIds: optionIds,
      ),
    );
    selectedCollectionId = collectionId;
    importedCollectionCount += 1;
  }

  if (importedCollectionCount == 0) {
    throw const FormatException('Action set package has no valid collections.');
  }
  return _ActivityCollectionImportResult(
    state: next,
    selectedCollectionId: selectedCollectionId,
    collectionCount: importedCollectionCount,
    customCount: customCount,
    adjustedCount: adjustedCount,
  );
}

String _safeActivityCollectionExportFileName(String title) {
  final normalized = title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
  if (normalized.isEmpty) {
    return 'daily_choice_action_set';
  }
  return normalized.length > 40 ? normalized.substring(0, 40) : normalized;
}

class _ActivityCollectionImportResult {
  const _ActivityCollectionImportResult({
    required this.state,
    required this.selectedCollectionId,
    required this.collectionCount,
    required this.customCount,
    required this.adjustedCount,
  });

  final DailyChoiceCustomState state;
  final String selectedCollectionId;
  final int collectionCount;
  final int customCount;
  final int adjustedCount;
}

Set<String> _managerInitialActivityCollectionIds({
  required List<DailyChoiceActivityCollection> collections,
  required DailyChoiceOption? option,
  required DailyChoiceActivityCollection? selectedCollection,
  required bool defaultFavoriteWhenEmpty,
}) {
  final ids = <String>{};
  final validIds = collections.map((item) => item.id).toSet();
  final optionId = option?.id.trim();
  if (optionId != null && optionId.isNotEmpty) {
    for (final collection in collections) {
      if (collection.containsOption(optionId)) {
        ids.add(collection.id);
      }
    }
  }
  if (selectedCollection != null && validIds.contains(selectedCollection.id)) {
    ids.add(selectedCollection.id);
  }
  if (ids.isEmpty &&
      defaultFavoriteWhenEmpty &&
      collections.any(
        (item) => item.id == dailyChoiceFavoriteActivityCollectionId,
      )) {
    ids.add(dailyChoiceFavoriteActivityCollectionId);
  }
  return ids;
}
