import 'package:flutter/material.dart';

import '../../../i18n/app_i18n.dart';
import '../../ui_copy.dart';

enum DailyChoiceModuleId {
  eat('eat'),
  wear('wear'),
  go('go'),
  activity('activity');

  const DailyChoiceModuleId(this.storageValue);

  final String storageValue;

  static DailyChoiceModuleId? fromStorage(String value) {
    final normalized = value.trim();
    for (final item in DailyChoiceModuleId.values) {
      if (item.storageValue == normalized) {
        return item;
      }
    }
    return null;
  }
}

class DailyChoiceModuleConfig {
  const DailyChoiceModuleConfig({
    required this.id,
    required this.icon,
    required this.accent,
    required this.titleZh,
    required this.titleEn,
    required this.subtitleZh,
    required this.subtitleEn,
  });

  final String id;
  final IconData icon;
  final Color accent;
  final String titleZh;
  final String titleEn;
  final String subtitleZh;
  final String subtitleEn;

  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);

  String subtitle(AppI18n i18n) =>
      pickUiText(i18n, zh: subtitleZh, en: subtitleEn);
}

class DailyChoiceCategory {
  const DailyChoiceCategory({
    required this.id,
    required this.icon,
    required this.titleZh,
    required this.titleEn,
    required this.subtitleZh,
    required this.subtitleEn,
  });

  final String id;
  final IconData icon;
  final String titleZh;
  final String titleEn;
  final String subtitleZh;
  final String subtitleEn;

  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);

  String subtitle(AppI18n i18n) =>
      pickUiText(i18n, zh: subtitleZh, en: subtitleEn);
}

class DailyChoiceTraitOption {
  const DailyChoiceTraitOption({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    this.icon = Icons.label_rounded,
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final IconData icon;

  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);
}

class DailyChoiceTraitGroup {
  const DailyChoiceTraitGroup({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.subtitleZh,
    required this.subtitleEn,
    required this.options,
    this.icon = Icons.tune_rounded,
    this.multiSelect = true,
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final String subtitleZh;
  final String subtitleEn;
  final List<DailyChoiceTraitOption> options;
  final IconData icon;
  final bool multiSelect;

  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);

  String subtitle(AppI18n i18n) =>
      pickUiText(i18n, zh: subtitleZh, en: subtitleEn);
}

class DailyChoiceGuideEntry {
  const DailyChoiceGuideEntry({
    required this.titleZh,
    required this.titleEn,
    required this.bodyZh,
    required this.bodyEn,
    this.icon = Icons.tips_and_updates_rounded,
  });

  final String titleZh;
  final String titleEn;
  final String bodyZh;
  final String bodyEn;
  final IconData icon;

  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);

  String body(AppI18n i18n) => pickUiText(i18n, zh: bodyZh, en: bodyEn);
}

class DailyChoiceGuideModule {
  const DailyChoiceGuideModule({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.subtitleZh,
    required this.subtitleEn,
    required this.entries,
    this.icon = Icons.menu_book_rounded,
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final String subtitleZh;
  final String subtitleEn;
  final List<DailyChoiceGuideEntry> entries;
  final IconData icon;

  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);

  String subtitle(AppI18n i18n) =>
      pickUiText(i18n, zh: subtitleZh, en: subtitleEn);
}

class DailyChoiceReferenceLink {
  const DailyChoiceReferenceLink({
    required this.labelZh,
    required this.labelEn,
    required this.url,
  });

  final String labelZh;
  final String labelEn;
  final String url;

  String label(AppI18n i18n) => pickUiText(i18n, zh: labelZh, en: labelEn);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'labelZh': labelZh,
      'labelEn': labelEn,
      'url': url,
    };
  }

  factory DailyChoiceReferenceLink.fromJson(Map<String, Object?> json) {
    return DailyChoiceReferenceLink(
      labelZh: _stringValue(json['labelZh']),
      labelEn: _stringValue(json['labelEn']),
      url: _stringValue(json['url']),
    );
  }
}

class DailyChoiceOption {
  const DailyChoiceOption({
    required this.id,
    required this.moduleId,
    required this.categoryId,
    required this.titleZh,
    required this.titleEn,
    required this.subtitleZh,
    required this.subtitleEn,
    required this.detailsZh,
    required this.detailsEn,
    this.contextId,
    this.contextIds = const <String>[],
    this.materialsZh = const <String>[],
    this.materialsEn = const <String>[],
    this.stepsZh = const <String>[],
    this.stepsEn = const <String>[],
    this.notesZh = const <String>[],
    this.notesEn = const <String>[],
    this.tagsZh = const <String>[],
    this.tagsEn = const <String>[],
    this.sourceLabel,
    this.sourceUrl,
    this.references = const <DailyChoiceReferenceLink>[],
    this.attributes = const <String, List<String>>{},
    this.custom = false,
  });

  final String id;
  final String moduleId;
  final String categoryId;
  final String? contextId;
  final List<String> contextIds;
  final String titleZh;
  final String titleEn;
  final String subtitleZh;
  final String subtitleEn;
  final String detailsZh;
  final String detailsEn;
  final List<String> materialsZh;
  final List<String> materialsEn;
  final List<String> stepsZh;
  final List<String> stepsEn;
  final List<String> notesZh;
  final List<String> notesEn;
  final List<String> tagsZh;
  final List<String> tagsEn;
  final String? sourceLabel;
  final String? sourceUrl;
  final List<DailyChoiceReferenceLink> references;
  final Map<String, List<String>> attributes;
  final bool custom;

  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);

  String subtitle(AppI18n i18n) =>
      pickUiText(i18n, zh: subtitleZh, en: subtitleEn);

  String details(AppI18n i18n) =>
      pickUiText(i18n, zh: detailsZh, en: detailsEn);

  List<String> materials(AppI18n i18n) {
    return AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh'
        ? materialsZh
        : (materialsEn.isEmpty ? materialsZh : materialsEn);
  }

  List<String> steps(AppI18n i18n) {
    return AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh'
        ? stepsZh
        : (stepsEn.isEmpty ? stepsZh : stepsEn);
  }

  List<String> notes(AppI18n i18n) {
    return AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh'
        ? notesZh
        : (notesEn.isEmpty ? notesZh : notesEn);
  }

  List<String> tags(AppI18n i18n) {
    return AppI18n.normalizeLanguageCode(i18n.languageCode) == 'zh'
        ? tagsZh
        : (tagsEn.isEmpty ? tagsZh : tagsEn);
  }

  List<String> attributeValues(String key) =>
      attributes[key] ?? const <String>[];

  DailyChoiceOption copyWith({
    String? id,
    String? moduleId,
    String? categoryId,
    String? contextId,
    List<String>? contextIds,
    String? titleZh,
    String? titleEn,
    String? subtitleZh,
    String? subtitleEn,
    String? detailsZh,
    String? detailsEn,
    List<String>? materialsZh,
    List<String>? materialsEn,
    List<String>? stepsZh,
    List<String>? stepsEn,
    List<String>? notesZh,
    List<String>? notesEn,
    List<String>? tagsZh,
    List<String>? tagsEn,
    String? sourceLabel,
    String? sourceUrl,
    List<DailyChoiceReferenceLink>? references,
    Map<String, List<String>>? attributes,
    bool? custom,
  }) {
    return DailyChoiceOption(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      categoryId: categoryId ?? this.categoryId,
      contextId: contextId ?? this.contextId,
      contextIds: contextIds ?? this.contextIds,
      titleZh: titleZh ?? this.titleZh,
      titleEn: titleEn ?? this.titleEn,
      subtitleZh: subtitleZh ?? this.subtitleZh,
      subtitleEn: subtitleEn ?? this.subtitleEn,
      detailsZh: detailsZh ?? this.detailsZh,
      detailsEn: detailsEn ?? this.detailsEn,
      materialsZh: materialsZh ?? this.materialsZh,
      materialsEn: materialsEn ?? this.materialsEn,
      stepsZh: stepsZh ?? this.stepsZh,
      stepsEn: stepsEn ?? this.stepsEn,
      notesZh: notesZh ?? this.notesZh,
      notesEn: notesEn ?? this.notesEn,
      tagsZh: tagsZh ?? this.tagsZh,
      tagsEn: tagsEn ?? this.tagsEn,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      references: references ?? this.references,
      attributes: attributes ?? this.attributes,
      custom: custom ?? this.custom,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'moduleId': moduleId,
      'categoryId': categoryId,
      'contextId': contextId,
      'contextIds': contextIds,
      'titleZh': titleZh,
      'titleEn': titleEn,
      'subtitleZh': subtitleZh,
      'subtitleEn': subtitleEn,
      'detailsZh': detailsZh,
      'detailsEn': detailsEn,
      'materialsZh': materialsZh,
      'materialsEn': materialsEn,
      'stepsZh': stepsZh,
      'stepsEn': stepsEn,
      'notesZh': notesZh,
      'notesEn': notesEn,
      'tagsZh': tagsZh,
      'tagsEn': tagsEn,
      'sourceLabel': sourceLabel,
      'sourceUrl': sourceUrl,
      'references': references
          .map((item) => item.toJson())
          .toList(growable: false),
      'attributes': attributes.map(
        (key, value) => MapEntry(key, value.toList(growable: false)),
      ),
      'custom': custom,
    };
  }

  factory DailyChoiceOption.fromJson(Map<String, Object?> json) {
    return DailyChoiceOption(
      id: _stringValue(json['id']),
      moduleId: _stringValue(json['moduleId']),
      categoryId: _stringValue(json['categoryId']),
      contextId: _nullableString(json['contextId']),
      contextIds: _stringList(json['contextIds']),
      titleZh: _stringValue(json['titleZh']),
      titleEn: _stringValue(json['titleEn']),
      subtitleZh: _stringValue(json['subtitleZh']),
      subtitleEn: _stringValue(json['subtitleEn']),
      detailsZh: _stringValue(json['detailsZh']),
      detailsEn: _stringValue(json['detailsEn']),
      materialsZh: _stringList(json['materialsZh']),
      materialsEn: _stringList(json['materialsEn']),
      stepsZh: _stringList(json['stepsZh']),
      stepsEn: _stringList(json['stepsEn']),
      notesZh: _stringList(json['notesZh']),
      notesEn: _stringList(json['notesEn']),
      tagsZh: _stringList(json['tagsZh']),
      tagsEn: _stringList(json['tagsEn']),
      sourceLabel: _nullableString(json['sourceLabel']),
      sourceUrl: _nullableString(json['sourceUrl']),
      references: _referenceList(json['references']),
      attributes: _stringListMap(json['attributes']),
      custom: json['custom'] == true,
    );
  }
}

class DailyChoiceEatCollection {
  const DailyChoiceEatCollection({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    this.optionIds = const <String>[],
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final List<String> optionIds;

  String title(AppI18n i18n) => pickUiText(i18n, zh: titleZh, en: titleEn);

  bool containsOption(String optionId) => optionIds.contains(optionId);

  DailyChoiceEatCollection copyWith({
    String? id,
    String? titleZh,
    String? titleEn,
    List<String>? optionIds,
  }) {
    return DailyChoiceEatCollection(
      id: id ?? this.id,
      titleZh: titleZh ?? this.titleZh,
      titleEn: titleEn ?? this.titleEn,
      optionIds: optionIds ?? this.optionIds,
    );
  }

  DailyChoiceEatCollection addOption(String optionId) {
    final normalized = optionId.trim();
    if (normalized.isEmpty || optionIds.contains(normalized)) {
      return this;
    }
    return copyWith(optionIds: <String>[...optionIds, normalized]);
  }

  DailyChoiceEatCollection removeOption(String optionId) {
    return copyWith(
      optionIds: optionIds
          .where((item) => item != optionId)
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'titleZh': titleZh,
      'titleEn': titleEn,
      'optionIds': optionIds,
    };
  }

  factory DailyChoiceEatCollection.fromJson(Map<String, Object?> json) {
    return DailyChoiceEatCollection(
      id: _stringValue(json['id']),
      titleZh: _stringValue(json['titleZh']),
      titleEn: _stringValue(json['titleEn']),
      optionIds: _dedupeStringList(_stringList(json['optionIds'])),
    );
  }
}

class DailyChoiceCustomState {
  const DailyChoiceCustomState({
    this.hiddenBuiltInIds = const <String>{},
    this.customOptions = const <DailyChoiceOption>[],
    this.adjustedBuiltInOptions = const <DailyChoiceOption>[],
    this.eatCollections = const <DailyChoiceEatCollection>[],
  });

  final Set<String> hiddenBuiltInIds;
  final List<DailyChoiceOption> customOptions;
  final List<DailyChoiceOption> adjustedBuiltInOptions;
  final List<DailyChoiceEatCollection> eatCollections;

  static const DailyChoiceCustomState empty = DailyChoiceCustomState();

  DailyChoiceCustomState copyWith({
    Set<String>? hiddenBuiltInIds,
    List<DailyChoiceOption>? customOptions,
    List<DailyChoiceOption>? adjustedBuiltInOptions,
    List<DailyChoiceEatCollection>? eatCollections,
  }) {
    return DailyChoiceCustomState(
      hiddenBuiltInIds: hiddenBuiltInIds ?? this.hiddenBuiltInIds,
      customOptions: customOptions ?? this.customOptions,
      adjustedBuiltInOptions:
          adjustedBuiltInOptions ?? this.adjustedBuiltInOptions,
      eatCollections: eatCollections ?? this.eatCollections,
    );
  }

  DailyChoiceCustomState hideBuiltIn(String optionId) {
    return copyWith(hiddenBuiltInIds: <String>{...hiddenBuiltInIds, optionId});
  }

  DailyChoiceCustomState restoreBuiltIn(String optionId) {
    return copyWith(
      hiddenBuiltInIds: hiddenBuiltInIds
          .where((item) => item != optionId)
          .toSet(),
    );
  }

  DailyChoiceCustomState upsertCustom(DailyChoiceOption option) {
    final next = <DailyChoiceOption>[];
    var replaced = false;
    for (final item in customOptions) {
      if (item.id == option.id) {
        next.add(option.copyWith(custom: true));
        replaced = true;
      } else {
        next.add(item);
      }
    }
    if (!replaced) {
      next.add(option.copyWith(custom: true));
    }
    return copyWith(customOptions: next);
  }

  DailyChoiceCustomState deleteCustom(String optionId) {
    return copyWith(
      customOptions: customOptions
          .where((item) => item.id != optionId)
          .toList(growable: false),
      eatCollections: eatCollections
          .map((collection) => collection.removeOption(optionId))
          .toList(growable: false),
    );
  }

  DailyChoiceOption? adjustedBuiltInById(String optionId) {
    for (final item in adjustedBuiltInOptions) {
      if (item.id == optionId) {
        return item;
      }
    }
    return null;
  }

  DailyChoiceCustomState upsertAdjustedBuiltIn(DailyChoiceOption option) {
    final normalized = option.copyWith(custom: false);
    final next = <DailyChoiceOption>[];
    var replaced = false;
    for (final item in adjustedBuiltInOptions) {
      if (item.id == normalized.id) {
        next.add(normalized);
        replaced = true;
      } else {
        next.add(item);
      }
    }
    if (!replaced) {
      next.add(normalized);
    }
    return copyWith(adjustedBuiltInOptions: next);
  }

  DailyChoiceCustomState restoreAdjustedBuiltIn(String optionId) {
    return copyWith(
      adjustedBuiltInOptions: adjustedBuiltInOptions
          .where((item) => item.id != optionId)
          .toList(growable: false),
    );
  }

  DailyChoiceEatCollection? eatCollectionById(String collectionId) {
    for (final item in eatCollections) {
      if (item.id == collectionId) {
        return item;
      }
    }
    return null;
  }

  DailyChoiceCustomState upsertEatCollection(
    DailyChoiceEatCollection collection,
  ) {
    final normalized = collection.copyWith(
      optionIds: _dedupeStringList(collection.optionIds),
    );
    final next = <DailyChoiceEatCollection>[];
    var replaced = false;
    for (final item in eatCollections) {
      if (item.id == normalized.id) {
        next.add(normalized);
        replaced = true;
      } else {
        next.add(item);
      }
    }
    if (!replaced) {
      next.add(normalized);
    }
    return copyWith(eatCollections: next);
  }

  DailyChoiceCustomState deleteEatCollection(String collectionId) {
    return copyWith(
      eatCollections: eatCollections
          .where((item) => item.id != collectionId)
          .toList(growable: false),
    );
  }

  DailyChoiceCustomState addOptionToEatCollection({
    required String collectionId,
    required String optionId,
  }) {
    return copyWith(
      eatCollections: eatCollections
          .map(
            (collection) => collection.id == collectionId
                ? collection.addOption(optionId)
                : collection,
          )
          .toList(growable: false),
    );
  }

  DailyChoiceCustomState removeOptionFromEatCollection({
    required String collectionId,
    required String optionId,
  }) {
    return copyWith(
      eatCollections: eatCollections
          .map(
            (collection) => collection.id == collectionId
                ? collection.removeOption(optionId)
                : collection,
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'hiddenBuiltInIds': hiddenBuiltInIds.toList(growable: false)..sort(),
      'customOptions': customOptions
          .map((item) => item.toJson())
          .toList(growable: false),
      'adjustedBuiltInOptions': adjustedBuiltInOptions
          .map((item) => item.toJson())
          .toList(growable: false),
      'eatCollections': eatCollections
          .map((item) => item.toJson())
          .toList(growable: false),
    };
  }

  factory DailyChoiceCustomState.fromJson(Map<String, Object?> json) {
    final hiddenBuiltInIds = _stringList(json['hiddenBuiltInIds']).toSet();
    final customRaw = json['customOptions'];
    final adjustedRaw = json['adjustedBuiltInOptions'];
    final eatCollectionsRaw = json['eatCollections'];
    final customOptions = <DailyChoiceOption>[];
    final adjustedBuiltInOptions = <DailyChoiceOption>[];
    final eatCollections = <DailyChoiceEatCollection>[];
    if (customRaw is List) {
      for (final item in customRaw) {
        if (item is Map) {
          customOptions.add(
            DailyChoiceOption.fromJson(
              item.cast<String, Object?>(),
            ).copyWith(custom: true),
          );
        }
      }
    }
    if (adjustedRaw is List) {
      for (final item in adjustedRaw) {
        if (item is Map) {
          adjustedBuiltInOptions.add(
            DailyChoiceOption.fromJson(
              item.cast<String, Object?>(),
            ).copyWith(custom: false),
          );
        }
      }
    }
    if (eatCollectionsRaw is List) {
      for (final item in eatCollectionsRaw) {
        if (item is Map) {
          final collection = DailyChoiceEatCollection.fromJson(
            item.cast<String, Object?>(),
          );
          if (collection.id.isNotEmpty && collection.titleZh.isNotEmpty) {
            eatCollections.add(collection);
          }
        }
      }
    }
    return DailyChoiceCustomState(
      hiddenBuiltInIds: hiddenBuiltInIds,
      customOptions: customOptions,
      adjustedBuiltInOptions: adjustedBuiltInOptions,
      eatCollections: eatCollections,
    );
  }
}

String _stringValue(Object? value) => value == null ? '' : '$value'.trim();

String? _nullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final normalized = '$value'.trim();
  return normalized.isEmpty ? null : normalized;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((item) => '$item'.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _dedupeStringList(Iterable<String> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isEmpty || !seen.add(normalized)) {
      continue;
    }
    result.add(normalized);
  }
  return result;
}

List<DailyChoiceReferenceLink> _referenceList(Object? value) {
  if (value is! List) {
    return const <DailyChoiceReferenceLink>[];
  }
  final references = <DailyChoiceReferenceLink>[];
  for (final item in value) {
    if (item is Map) {
      references.add(
        DailyChoiceReferenceLink.fromJson(item.cast<String, Object?>()),
      );
    }
  }
  return references;
}

Map<String, List<String>> _stringListMap(Object? value) {
  if (value is! Map) {
    return const <String, List<String>>{};
  }
  final result = <String, List<String>>{};
  value.forEach((key, item) {
    final normalizedKey = '$key'.trim();
    if (normalizedKey.isEmpty) {
      return;
    }
    final values = _stringList(item);
    if (values.isNotEmpty) {
      result[normalizedKey] = values;
    }
  });
  return result;
}
