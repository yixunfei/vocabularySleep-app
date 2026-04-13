import 'dart:convert';

import 'word_entry.dart';
import 'word_field.dart';
import 'wordbook_import_audit.dart';

const String wordbookSchemaV1 = 'wordbook.v1';

class WordbookSchemaV1 {
  const WordbookSchemaV1({
    required this.schemaVersion,
    required this.book,
    required this.entries,
  });

  final String schemaVersion;
  final WordbookBookMetaV1 book;
  final List<WordbookEntryV1> entries;

  static bool looksLikeStandardWordbook(Object? raw) {
    if (raw is! Map) return false;
    final schemaVersion = '${raw['schema_version'] ?? ''}'.trim();
    return schemaVersion == wordbookSchemaV1 &&
        raw['book'] is Map &&
        raw['entries'] is List;
  }

  factory WordbookSchemaV1.fromJsonMap(Map<String, Object?> json) {
    final bookJson = json['book'];
    final entriesJson = json['entries'];
    if (bookJson is! Map) {
      throw const FormatException('wordbook.v1 book must be an object');
    }
    if (entriesJson is! List) {
      throw const FormatException('wordbook.v1 entries must be an array');
    }

    return WordbookSchemaV1(
      schemaVersion: '${json['schema_version'] ?? ''}'.trim(),
      book: WordbookBookMetaV1.fromJsonMap(bookJson.cast<String, Object?>()),
      entries: entriesJson
          .whereType<Map>()
          .map(
            (item) => WordbookEntryV1.fromJsonMap(item.cast<String, Object?>()),
          )
          .toList(growable: false),
    );
  }

  WordbookImportAudit validate() {
    final issues = <WordbookImportIssue>[];
    final unknownFieldCounts = <String, int>{};

    void addIssue({
      required String severity,
      required String code,
      required String path,
      required String message,
    }) {
      issues.add(
        WordbookImportIssue(
          severity: severity,
          code: code,
          path: path,
          message: message,
        ),
      );
    }

    if (schemaVersion != wordbookSchemaV1) {
      addIssue(
        severity: 'error',
        code: 'schema_version_invalid',
        path: 'schema_version',
        message: 'schema_version 必须为 wordbook.v1',
      );
    }

    if (book.id.trim().isEmpty) {
      addIssue(
        severity: 'error',
        code: 'book_id_required',
        path: 'book.id',
        message: 'book.id 不能为空',
      );
    }
    if (book.name.trim().isEmpty) {
      addIssue(
        severity: 'error',
        code: 'book_name_required',
        path: 'book.name',
        message: 'book.name 不能为空',
      );
    }
    if (book.sourceLanguage.trim().isEmpty) {
      addIssue(
        severity: 'error',
        code: 'book_source_language_required',
        path: 'book.source_language',
        message: 'book.source_language 不能为空',
      );
    }
    if (book.targetLanguage.trim().isEmpty) {
      addIssue(
        severity: 'error',
        code: 'book_target_language_required',
        path: 'book.target_language',
        message: 'book.target_language 不能为空',
      );
    }
    if (!const <String>{
      'source_to_target',
      'target_to_source',
      'bidirectional',
    }.contains(book.direction)) {
      addIssue(
        severity: 'error',
        code: 'book_direction_invalid',
        path: 'book.direction',
        message: 'book.direction 必须是标准枚举值',
      );
    }
    if (book.entryCount != entries.length) {
      addIssue(
        severity: 'error',
        code: 'book_entry_count_mismatch',
        path: 'book.entry_count',
        message: 'book.entry_count 与 entries.length 不一致',
      );
    }

    final seenEntryIds = <String>{};
    for (var index = 0; index < entries.length; index += 1) {
      final entry = entries[index];
      final basePath = 'entries[$index]';
      if (entry.entryId.trim().isEmpty) {
        addIssue(
          severity: 'error',
          code: 'entry_id_required',
          path: '$basePath.entry_id',
          message: 'entry_id 不能为空',
        );
      } else if (!seenEntryIds.add(entry.entryId)) {
        addIssue(
          severity: 'error',
          code: 'entry_id_duplicate',
          path: '$basePath.entry_id',
          message: 'entry_id 在同一词本中必须唯一',
        );
      }
      if (entry.lemma.text.trim().isEmpty) {
        addIssue(
          severity: 'error',
          code: 'lemma_text_required',
          path: '$basePath.lemma.text',
          message: 'lemma.text 不能为空',
        );
      }
      if (entry.lemma.language.trim().isEmpty) {
        addIssue(
          severity: 'error',
          code: 'lemma_language_required',
          path: '$basePath.lemma.language',
          message: 'lemma.language 不能为空',
        );
      }
      if (entry.glosses.isEmpty) {
        addIssue(
          severity: 'error',
          code: 'glosses_required',
          path: '$basePath.glosses',
          message: 'glosses 至少需要一条释义',
        );
      }
      for (
        var glossIndex = 0;
        glossIndex < entry.glosses.length;
        glossIndex += 1
      ) {
        final gloss = entry.glosses[glossIndex];
        if (gloss.text.trim().isEmpty) {
          addIssue(
            severity: 'error',
            code: 'gloss_text_required',
            path: '$basePath.glosses[$glossIndex].text',
            message: 'glosses[].text 不能为空',
          );
        }
      }
      for (final unknownKey in entry.unknownKeys) {
        unknownFieldCounts[unknownKey] =
            (unknownFieldCounts[unknownKey] ?? 0) + 1;
      }
      for (final unknownNoteKey in entry.notesUnknownKeys) {
        final fieldPath = 'notes.$unknownNoteKey';
        unknownFieldCounts[fieldPath] =
            (unknownFieldCounts[fieldPath] ?? 0) + 1;
      }
    }

    for (final entry in unknownFieldCounts.entries) {
      addIssue(
        severity: 'warning',
        code: 'unknown_field',
        path: entry.key,
        message: '发现 ${entry.value} 个未识别字段，当前将保留在 extra 中',
      );
    }

    return WordbookImportAudit(
      format: 'wordbook.v1',
      schemaVersion: schemaVersion,
      totalRecords: entries.length,
      acceptedRecords: entries.length,
      issues: issues,
      bookId: book.id,
      bookName: book.name,
      unknownFieldCounts: unknownFieldCounts,
      note: '标准词本已按 wordbook.v1 校验',
    );
  }

  List<WordEntryPayload> toPayloads() {
    return entries
        .asMap()
        .entries
        .map((entry) => entry.value.toPayload(sortIndex: entry.key))
        .where((payload) => payload.word.trim().isNotEmpty)
        .toList(growable: false);
  }
}

class WordbookBookMetaV1 {
  const WordbookBookMetaV1({
    required this.id,
    required this.name,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.direction,
    required this.entryCount,
    this.createdAt = '',
    this.updatedAt = '',
    this.sources = const <String>[],
    this.tags = const <String>[],
    this.description = '',
    this.license = '',
    this.extra = const <String, Object?>{},
  });

  final String id;
  final String name;
  final String sourceLanguage;
  final String targetLanguage;
  final String direction;
  final int entryCount;
  final String createdAt;
  final String updatedAt;
  final List<String> sources;
  final List<String> tags;
  final String description;
  final String license;
  final Map<String, Object?> extra;

  factory WordbookBookMetaV1.fromJsonMap(Map<String, Object?> json) {
    return WordbookBookMetaV1(
      id: '${json['id'] ?? ''}'.trim(),
      name: '${json['name'] ?? ''}'.trim(),
      sourceLanguage: '${json['source_language'] ?? ''}'.trim(),
      targetLanguage: '${json['target_language'] ?? ''}'.trim(),
      direction: '${json['direction'] ?? ''}'.trim(),
      entryCount: (json['entry_count'] as num?)?.toInt() ?? 0,
      createdAt: '${json['created_at'] ?? ''}'.trim(),
      updatedAt: '${json['updated_at'] ?? ''}'.trim(),
      sources: _stringList(json['sources']),
      tags: _stringList(json['tags']),
      description: '${json['description'] ?? ''}'.trim(),
      license: '${json['license'] ?? ''}'.trim(),
      extra: _objectMap(json['extra']),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'direction': direction,
      'entry_count': entryCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'sources': sources,
      'tags': tags,
      'description': description,
      'license': license,
      'extra': extra,
    };
  }
}

class WordbookEntryV1 {
  const WordbookEntryV1({
    required this.entryId,
    required this.lemma,
    required this.glosses,
    required this.pronunciations,
    required this.partsOfSpeech,
    required this.examples,
    required this.collocations,
    required this.morphology,
    required this.notes,
    required this.tags,
    required this.media,
    required this.source,
    required this.extra,
    required this.unknownKeys,
    required this.notesUnknownKeys,
    required this.extraFields,
    required this.extraNoteFields,
  });

  final String entryId;
  final WordbookLemmaV1 lemma;
  final List<WordbookGlossV1> glosses;
  final List<WordbookPronunciationV1> pronunciations;
  final List<String> partsOfSpeech;
  final List<WordbookExampleV1> examples;
  final List<String> collocations;
  final List<WordbookMorphologyV1> morphology;
  final WordbookNotesV1 notes;
  final List<String> tags;
  final List<WordFieldMediaItem> media;
  final WordbookSourceV1 source;
  final Map<String, Object?> extra;
  final List<String> unknownKeys;
  final List<String> notesUnknownKeys;
  final Map<String, Object?> extraFields;
  final Map<String, Object?> extraNoteFields;

  factory WordbookEntryV1.fromJsonMap(Map<String, Object?> json) {
    const knownKeys = <String>{
      'entry_id',
      'lemma',
      'glosses',
      'pronunciations',
      'parts_of_speech',
      'examples',
      'collocations',
      'morphology',
      'notes',
      'tags',
      'media',
      'source',
      'extra',
    };
    final unknownKeys = json.keys
        .where((key) => !knownKeys.contains(key))
        .toList(growable: false);
    final extraFields = <String, Object?>{
      for (final key in unknownKeys) key: json[key],
    };
    final notesJson = _objectMap(json['notes']);
    const knownNoteKeys = <String>{
      'etymology',
      'roots',
      'affixes',
      'usage',
      'confusions',
      'memory',
      'culture',
      'story',
    };
    final notesUnknownKeys = notesJson.keys
        .where((key) => !knownNoteKeys.contains(key))
        .toList(growable: false);
    final extraNoteFields = <String, Object?>{
      for (final key in notesUnknownKeys) key: notesJson[key],
    };

    return WordbookEntryV1(
      entryId: '${json['entry_id'] ?? ''}'.trim(),
      lemma: WordbookLemmaV1.fromJsonMap(_objectMap(json['lemma'])),
      glosses: _listOfMaps(
        json['glosses'],
      ).map(WordbookGlossV1.fromJsonMap).toList(growable: false),
      pronunciations: _listOfMaps(
        json['pronunciations'],
      ).map(WordbookPronunciationV1.fromJsonMap).toList(growable: false),
      partsOfSpeech: _stringList(json['parts_of_speech']),
      examples: _listOfMaps(
        json['examples'],
      ).map(WordbookExampleV1.fromJsonMap).toList(growable: false),
      collocations: _stringList(json['collocations']),
      morphology: _listOfMaps(
        json['morphology'],
      ).map(WordbookMorphologyV1.fromJsonMap).toList(growable: false),
      notes: WordbookNotesV1.fromJsonMap(notesJson),
      tags: _stringList(json['tags']),
      media: _listOfMaps(json['media'])
          .map((item) => WordFieldMediaItem.fromJsonMap(item))
          .where((item) => item.source.trim().isNotEmpty)
          .toList(growable: false),
      source: WordbookSourceV1.fromJsonMap(_objectMap(json['source'])),
      extra: _objectMap(json['extra']),
      unknownKeys: unknownKeys,
      notesUnknownKeys: notesUnknownKeys,
      extraFields: extraFields,
      extraNoteFields: extraNoteFields,
    );
  }

  WordEntryPayload toPayload({int? sortIndex}) {
    final fields = <WordFieldItem>[];
    final glossTexts = glosses
        .map((item) => item.text.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (glossTexts.isNotEmpty) {
      fields.add(
        WordFieldItem(
          key: 'meaning',
          label: legacyFieldLabels['meaning'] ?? 'Meaning',
          value: glossTexts.join('；'),
        ),
      );
    }
    if (pronunciations.isNotEmpty) {
      fields.add(
        WordFieldItem(
          key: 'pronunciations',
          label: 'Pronunciations',
          value: pronunciations
              .map((item) => item.toDisplayText())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
        ),
      );
    }
    if (partsOfSpeech.isNotEmpty) {
      fields.add(
        WordFieldItem(
          key: 'parts_of_speech',
          label: 'Parts of Speech',
          value: partsOfSpeech,
        ),
      );
    }
    if (examples.isNotEmpty) {
      fields.add(
        WordFieldItem(
          key: 'examples',
          label: legacyFieldLabels['examples'] ?? 'Examples',
          value: examples
              .map((item) => item.toDisplayText())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
        ),
      );
    }
    if (collocations.isNotEmpty) {
      fields.add(
        WordFieldItem(
          key: 'collocations',
          label: 'Collocations',
          value: collocations,
        ),
      );
    }
    if (morphology.isNotEmpty) {
      fields.add(
        WordFieldItem(
          key: 'morphology',
          label: 'Morphology',
          value: morphology
              .map((item) => item.toDisplayText())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
        ),
      );
    }
    if (tags.isNotEmpty) {
      fields.add(
        WordFieldItem(key: 'tags', label: 'Tags', value: tags, tags: tags),
      );
    }
    if (media.isNotEmpty) {
      fields.add(
        WordFieldItem(
          key: 'media',
          label: 'Media',
          value: media
              .map((item) {
                final label = sanitizeDisplayText(item.label);
                final source = sanitizeDisplayText(item.source);
                if (label.isNotEmpty && source.isNotEmpty) {
                  return '$label: $source';
                }
                return source;
              })
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
          media: media,
        ),
      );
    }

    void addNoteField(String key, String label, String value) {
      final normalized = sanitizeDisplayText(value);
      if (normalized.isEmpty) return;
      fields.add(WordFieldItem(key: key, label: label, value: normalized));
    }

    addNoteField(
      'etymology',
      legacyFieldLabels['etymology'] ?? 'Etymology',
      notes.etymology,
    );
    addNoteField('roots', legacyFieldLabels['roots'] ?? 'Roots', notes.roots);
    addNoteField(
      'affixes',
      legacyFieldLabels['affixes'] ?? 'Affixes',
      notes.affixes,
    );
    addNoteField('usage', 'Usage', notes.usage);
    addNoteField('confusions', 'Confusions', notes.confusions);
    addNoteField(
      'memory',
      legacyFieldLabels['memory'] ?? 'Memory',
      notes.memory,
    );
    addNoteField('culture', 'Culture', notes.culture);
    addNoteField('story', legacyFieldLabels['story'] ?? 'Story', notes.story);

    void addDynamicField(String rawKey, Object? rawValue) {
      final key = normalizeFieldKey(rawKey);
      if (key.isEmpty) {
        return;
      }
      final value = normalizeFieldValue(rawValue);
      if (value == null) {
        return;
      }
      fields.add(
        WordFieldItem(
          key: key,
          label: legacyFieldLabels[key] ?? rawKey.trim(),
          value: key == 'examples' ? _normalizeExamplesValue(value) : value,
        ),
      );
    }

    for (final entry in extraNoteFields.entries) {
      addDynamicField(entry.key, entry.value);
    }
    for (final entry in extra.entries) {
      addDynamicField(entry.key, entry.value);
    }
    for (final entry in extraFields.entries) {
      addDynamicField(entry.key, entry.value);
    }

    return WordEntryPayload(
      word: lemma.text,
      fields: mergeFieldItems(fields),
      rawContent: glossTexts.join('\n'),
      entryUid: entryId,
      primaryGloss: glossTexts.isEmpty ? null : glossTexts.first,
      schemaVersion: wordbookSchemaV1,
      sortIndex: sortIndex,
      sourcePayloadJson: jsonEncode(toJsonMap()),
    );
  }

  Map<String, Object?> toJsonMap() {
    final notesJson = notes.toJsonMap()..addAll(extraNoteFields);
    final output = <String, Object?>{
      'entry_id': entryId,
      'lemma': lemma.toJsonMap(),
      'glosses': glosses
          .map((item) => item.toJsonMap())
          .toList(growable: false),
      'pronunciations': pronunciations
          .map((item) => item.toJsonMap())
          .toList(growable: false),
      'parts_of_speech': partsOfSpeech,
      'examples': examples
          .map((item) => item.toJsonMap())
          .toList(growable: false),
      'collocations': collocations,
      'morphology': morphology
          .map((item) => item.toJsonMap())
          .toList(growable: false),
      'notes': notesJson,
      'tags': tags,
      'media': media.map((item) => item.toJsonMap()).toList(growable: false),
      'source': source.toJsonMap(),
      'extra': extra,
    };
    output.addAll(extraFields);
    return output;
  }
}

WordFieldValue _normalizeExamplesValue(WordFieldValue value) {
  if (value is List) {
    return value;
  }
  final text = '$value';
  if (!text.contains('\n')) {
    return sanitizeDisplayText(text);
  }
  final rows = text
      .split(RegExp(r'\r?\n'))
      .map((line) => sanitizeDisplayText(line))
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  return rows.length <= 1 ? sanitizeDisplayText(text) : rows;
}

class WordbookLemmaV1 {
  const WordbookLemmaV1({
    required this.text,
    required this.normalized,
    required this.language,
    required this.script,
  });

  final String text;
  final String normalized;
  final String language;
  final String script;

  factory WordbookLemmaV1.fromJsonMap(Map<String, Object?> json) {
    return WordbookLemmaV1(
      text: '${json['text'] ?? ''}'.trim(),
      normalized: '${json['normalized'] ?? ''}'.trim(),
      language: '${json['language'] ?? ''}'.trim(),
      script: '${json['script'] ?? ''}'.trim(),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'text': text,
      'normalized': normalized,
      'language': language,
      'script': script,
    };
  }
}

class WordbookGlossV1 {
  const WordbookGlossV1({
    required this.lang,
    required this.text,
    required this.type,
  });

  final String lang;
  final String text;
  final String type;

  factory WordbookGlossV1.fromJsonMap(Map<String, Object?> json) {
    return WordbookGlossV1(
      lang: '${json['lang'] ?? ''}'.trim(),
      text: '${json['text'] ?? ''}'.trim(),
      type: '${json['type'] ?? ''}'.trim(),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{'lang': lang, 'text': text, 'type': type};
  }
}

class WordbookPronunciationV1 {
  const WordbookPronunciationV1({
    required this.locale,
    required this.ipa,
    required this.note,
    required this.audio,
  });

  final String locale;
  final String ipa;
  final String note;
  final String audio;

  factory WordbookPronunciationV1.fromJsonMap(Map<String, Object?> json) {
    return WordbookPronunciationV1(
      locale: '${json['locale'] ?? ''}'.trim(),
      ipa: '${json['ipa'] ?? ''}'.trim(),
      note: '${json['note'] ?? ''}'.trim(),
      audio: '${json['audio'] ?? ''}'.trim(),
    );
  }

  String toDisplayText() {
    final parts = <String>[];
    if (locale.isNotEmpty) parts.add(locale);
    if (ipa.isNotEmpty) parts.add(ipa);
    if (note.isNotEmpty) parts.add(note);
    return parts.join(' | ');
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'locale': locale,
      'ipa': ipa,
      'note': note,
      'audio': audio,
    };
  }
}

class WordbookExampleV1 {
  const WordbookExampleV1({
    required this.category,
    required this.sourceText,
    required this.translation,
  });

  final String category;
  final String sourceText;
  final String translation;

  factory WordbookExampleV1.fromJsonMap(Map<String, Object?> json) {
    return WordbookExampleV1(
      category: '${json['category'] ?? ''}'.trim(),
      sourceText: '${json['source_text'] ?? ''}'.trim(),
      translation: '${json['translation'] ?? ''}'.trim(),
    );
  }

  String toDisplayText() {
    final lines = <String>[];
    if (sourceText.isNotEmpty) {
      lines.add(category.isEmpty ? sourceText : '[$category] $sourceText');
    }
    if (translation.isNotEmpty) {
      lines.add('中文：$translation');
    }
    return lines.join('\n').trim();
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'category': category,
      'source_text': sourceText,
      'translation': translation,
    };
  }
}

class WordbookMorphologyV1 {
  const WordbookMorphologyV1({required this.type, required this.value});

  final String type;
  final String value;

  factory WordbookMorphologyV1.fromJsonMap(Map<String, Object?> json) {
    return WordbookMorphologyV1(
      type: '${json['type'] ?? ''}'.trim(),
      value: '${json['value'] ?? ''}'.trim(),
    );
  }

  String toDisplayText() {
    if (type.isEmpty) return value;
    if (value.isEmpty) return type;
    return '$type: $value';
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{'type': type, 'value': value};
  }
}

class WordbookNotesV1 {
  const WordbookNotesV1({
    required this.etymology,
    required this.roots,
    required this.affixes,
    required this.usage,
    required this.confusions,
    required this.memory,
    required this.culture,
    required this.story,
  });

  final String etymology;
  final String roots;
  final String affixes;
  final String usage;
  final String confusions;
  final String memory;
  final String culture;
  final String story;

  factory WordbookNotesV1.fromJsonMap(Map<String, Object?> json) {
    return WordbookNotesV1(
      etymology: '${json['etymology'] ?? ''}'.trim(),
      roots: '${json['roots'] ?? ''}'.trim(),
      affixes: '${json['affixes'] ?? ''}'.trim(),
      usage: '${json['usage'] ?? ''}'.trim(),
      confusions: '${json['confusions'] ?? ''}'.trim(),
      memory: '${json['memory'] ?? ''}'.trim(),
      culture: '${json['culture'] ?? ''}'.trim(),
      story: '${json['story'] ?? ''}'.trim(),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'etymology': etymology,
      'roots': roots,
      'affixes': affixes,
      'usage': usage,
      'confusions': confusions,
      'memory': memory,
      'culture': culture,
      'story': story,
    };
  }
}

class WordbookSourceV1 {
  const WordbookSourceV1({
    required this.provider,
    required this.license,
    required this.recordHash,
    required this.rawRef,
  });

  final String provider;
  final String license;
  final String recordHash;
  final String rawRef;

  factory WordbookSourceV1.fromJsonMap(Map<String, Object?> json) {
    return WordbookSourceV1(
      provider: '${json['provider'] ?? ''}'.trim(),
      license: '${json['license'] ?? ''}'.trim(),
      recordHash: '${json['record_hash'] ?? ''}'.trim(),
      rawRef: '${json['raw_ref'] ?? ''}'.trim(),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'provider': provider,
      'license': license,
      'record_hash': recordHash,
      'raw_ref': rawRef,
    };
  }
}

List<Map<String, Object?>> _listOfMaps(Object? raw) {
  if (raw is! List) return const <Map<String, Object?>>[];
  return raw
      .whereType<Map>()
      .map((item) => item.cast<String, Object?>())
      .toList(growable: false);
}

List<String> _stringList(Object? raw) {
  if (raw is! List) return const <String>[];
  return raw
      .map((item) => sanitizeDisplayText('$item'))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, Object?> _objectMap(Object? raw) {
  if (raw is Map<String, Object?>) return raw;
  if (raw is Map) return raw.cast<String, Object?>();
  return const <String, Object?>{};
}
