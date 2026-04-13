import 'dart:convert';

import 'word_field.dart';

class WordEntryPayload {
  const WordEntryPayload({
    required this.word,
    required this.fields,
    this.rawContent = '',
    this.entryUid,
    this.primaryGloss,
    this.schemaVersion,
    this.sortIndex,
    this.sourcePayloadJson,
  });

  final String word;
  final List<WordFieldItem> fields;
  final String rawContent;
  final String? entryUid;
  final String? primaryGloss;
  final String? schemaVersion;
  final int? sortIndex;
  final String? sourcePayloadJson;

  WordEntryPayload copyWith({
    String? word,
    List<WordFieldItem>? fields,
    String? rawContent,
    String? entryUid,
    String? primaryGloss,
    String? schemaVersion,
    int? sortIndex,
    String? sourcePayloadJson,
  }) {
    return WordEntryPayload(
      word: word ?? this.word,
      fields: fields ?? this.fields,
      rawContent: rawContent ?? this.rawContent,
      entryUid: entryUid ?? this.entryUid,
      primaryGloss: primaryGloss ?? this.primaryGloss,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      sortIndex: sortIndex ?? this.sortIndex,
      sourcePayloadJson: sourcePayloadJson ?? this.sourcePayloadJson,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'word': word,
      'fields': fields.map((item) => item.toJsonMap()).toList(growable: false),
      'rawContent': rawContent,
      'entryUid': entryUid,
      'primaryGloss': primaryGloss,
      'schemaVersion': schemaVersion,
      'sortIndex': sortIndex,
      'sourcePayloadJson': sourcePayloadJson,
    };
  }
}

class WordEntryFieldGroup {
  const WordEntryFieldGroup({required this.groupKey, required this.fields});

  static const List<String> orderedKeys = <String>[
    'core',
    'usage',
    'linguistics',
    'memory',
    'other',
  ];

  final String groupKey;
  final List<WordFieldItem> fields;
}

String classifyWordFieldGroup(String rawKey) {
  final key = normalizeFieldKey(rawKey);
  if (const <String>{
    'meaning',
    'meanings_zh',
    'pronunciations',
    'parts_of_speech',
  }.contains(key)) {
    return 'core';
  }
  if (const <String>{
    'examples',
    'collocations',
    'phrases',
    'usage',
    'confusions',
    'synonyms',
    'antonyms',
  }.contains(key)) {
    return 'usage';
  }
  if (const <String>{
    'etymology',
    'roots',
    'affixes',
    'morphology',
    'variations',
    'related',
    'derived',
    'similar_words',
  }.contains(key)) {
    return 'linguistics';
  }
  if (const <String>{'memory', 'culture', 'story'}.contains(key)) {
    return 'memory';
  }
  return 'other';
}

class WordEntry {
  const WordEntry({
    this.id,
    required this.wordbookId,
    required this.word,
    this.meaning,
    this.examples,
    this.etymology,
    this.roots,
    this.affixes,
    this.variations,
    this.memory,
    this.story,
    this.entryUid,
    this.primaryGloss,
    this.schemaVersion,
    this.sortIndex,
    this.sourcePayloadJson,
    List<WordFieldItem> fields = const <WordFieldItem>[],
    this.rawContent = '',
    String rawFieldsJson = '',
  }) : _fields = fields,
       _rawFieldsJson = rawFieldsJson;

  final int? id;
  final int wordbookId;
  final String word;
  final String? meaning;
  final List<String>? examples;
  final String? etymology;
  final String? roots;
  final String? affixes;
  final String? variations;
  final String? memory;
  final String? story;
  final String? entryUid;
  final String? primaryGloss;
  final String? schemaVersion;
  final int? sortIndex;
  final String? sourcePayloadJson;
  final String rawContent;
  final List<WordFieldItem> _fields;
  final String _rawFieldsJson;

  String get stableIdentityKey {
    final entryUidPart = sanitizeDisplayText(entryUid ?? '');
    if (entryUidPart.isNotEmpty) {
      return 'wb:$wordbookId|entry:$entryUidPart';
    }
    final idPart = id;
    if (idPart != null && idPart > 0) {
      return 'wb:$wordbookId|id:$idPart';
    }
    return 'wb:$wordbookId|word:${sanitizeDisplayText(word)}|gloss:${sanitizeDisplayText(primaryGloss ?? summaryMeaningText)}|raw:${sanitizeDisplayText(rawContent)}';
  }

  String get collectionReferenceKey {
    final entryUidPart = sanitizeDisplayText(entryUid ?? '');
    if (entryUidPart.isNotEmpty) {
      return 'entry:$entryUidPart';
    }
    final glossPart = sanitizeDisplayText(primaryGloss ?? summaryMeaningText);
    if (glossPart.isNotEmpty) {
      return 'word:${sanitizeDisplayText(word)}|gloss:$glossPart';
    }
    final rawPart = sanitizeDisplayText(rawContent);
    if (rawPart.isNotEmpty) {
      return 'word:${sanitizeDisplayText(word)}|raw:$rawPart';
    }
    return 'word:${sanitizeDisplayText(word)}';
  }

  bool sameEntryAs(WordEntry other, {bool ignoreWordbook = false}) {
    if (identical(this, other)) {
      return true;
    }
    final selfId = id;
    final otherId = other.id;
    if (!ignoreWordbook &&
        selfId != null &&
        selfId > 0 &&
        otherId != null &&
        otherId > 0) {
      return selfId == otherId;
    }
    if (!ignoreWordbook && wordbookId != other.wordbookId) {
      return false;
    }
    final selfEntryUid = sanitizeDisplayText(entryUid ?? '');
    final otherEntryUid = sanitizeDisplayText(other.entryUid ?? '');
    if (selfEntryUid.isNotEmpty && otherEntryUid.isNotEmpty) {
      return selfEntryUid == otherEntryUid;
    }
    if (sanitizeDisplayText(word) != sanitizeDisplayText(other.word)) {
      return false;
    }
    final selfGloss = sanitizeDisplayText(primaryGloss ?? summaryMeaningText);
    final otherGloss = sanitizeDisplayText(
      other.primaryGloss ?? other.summaryMeaningText,
    );
    if (selfGloss.isNotEmpty || otherGloss.isNotEmpty) {
      return selfGloss == otherGloss;
    }
    final selfRaw = sanitizeDisplayText(rawContent);
    final otherRaw = sanitizeDisplayText(other.rawContent);
    if (selfRaw.isNotEmpty || otherRaw.isNotEmpty) {
      return selfRaw == otherRaw;
    }
    return true;
  }

  Map<String, Object?> get _legacyFieldRecord => <String, Object?>{
    'meaning': meaning,
    'examples': examples,
    'etymology': etymology,
    'roots': roots,
    'affixes': affixes,
    'variations': variations,
    'memory': memory,
    'story': story,
  };

  List<WordFieldItem> get fields {
    final parsedRawFields = _rawFieldsJson.trim().isEmpty
        ? const <WordFieldItem>[]
        : parseFieldItemsJson(_rawFieldsJson);
    final fallbackFields = buildFieldItemsFromRecord(_legacyFieldRecord);
    return mergeFieldItems(<WordFieldItem>[
      ..._fields,
      ...parsedRawFields,
      ...fallbackFields,
    ]);
  }

  WordFieldItem? get primaryMeaningField {
    for (final field in fields) {
      if (field.key == 'meaning' && field.asList().isNotEmpty) {
        return field;
      }
    }
    final fallback = sanitizeDisplayText(primaryGloss ?? meaning ?? '');
    if (fallback.isEmpty) return null;
    return WordFieldItem(
      key: 'meaning',
      label: legacyFieldLabels['meaning'] ?? 'Meaning',
      value: fallback,
    );
  }

  WordFieldItem? get primaryExampleField {
    for (final field in fields) {
      if (field.key == 'examples' && field.asList().isNotEmpty) {
        return field;
      }
    }
    return null;
  }

  String get displayMeaning => primaryMeaningField?.asText() ?? '';

  List<String> get displayExamples =>
      primaryExampleField?.asList() ?? const <String>[];

  String get summaryMeaningText {
    final display = displayMeaning.trim();
    if (display.isNotEmpty) {
      return display;
    }
    final gloss = sanitizeDisplayText(primaryGloss ?? '');
    if (gloss.isNotEmpty) {
      return gloss;
    }
    final legacyMeaning = sanitizeDisplayText(meaning ?? '');
    if (legacyMeaning.isNotEmpty) {
      return legacyMeaning;
    }
    final raw = rawContent.trim();
    if (raw.isEmpty) {
      return '';
    }
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final text = line.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  String get searchMeaningText => summaryMeaningText;

  String get searchDetailsText {
    final segments = <String>[];
    for (final field in fields) {
      final text = field.asText().trim();
      if (text.isEmpty) continue;
      segments.add(text);
    }
    final raw = rawContent.trim();
    if (raw.isNotEmpty) {
      segments.add(raw);
    }
    return segments.join('\n').trim();
  }

  String get listSubtitleText {
    final meaningText = summaryMeaningText.trim();
    if (meaningText.isNotEmpty) {
      return meaningText;
    }
    for (final field in previewSupplementaryFields) {
      final text = field.asText().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    final raw = rawContent.trim();
    if (raw.isEmpty) {
      return '';
    }
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final text = line.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  List<WordFieldItem> get previewSupplementaryFields {
    return fields
        .where((item) {
          if (item.asList().isEmpty) return false;
          return item.key != 'meaning' && item.key != 'examples';
        })
        .toList(growable: false);
  }

  List<WordEntryFieldGroup> get groupedFields {
    final grouped = <String, List<WordFieldItem>>{};
    for (final field in fields) {
      if (field.asList().isEmpty) continue;
      final groupKey = classifyWordFieldGroup(field.key);
      grouped.putIfAbsent(groupKey, () => <WordFieldItem>[]).add(field);
    }

    final output = <WordEntryFieldGroup>[];
    for (final groupKey in WordEntryFieldGroup.orderedKeys) {
      final items = grouped[groupKey];
      if (items == null || items.isEmpty) continue;
      output.add(WordEntryFieldGroup(groupKey: groupKey, fields: items));
    }
    return output;
  }

  LegacyWordFields get legacyFields => toLegacyFields(fields);

  List<WordFieldItem> get playbackFields {
    final output = <WordFieldItem>[];
    for (final field in fields) {
      final values = field.asList();
      if (values.isEmpty) continue;
      if (field.key == 'pronunciations') {
        final spoken = values
            .map(_extractIpaForPlayback)
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        if (spoken.isEmpty) continue;
        output.add(field.copyWith(value: spoken));
        continue;
      }
      output.add(field);
    }
    return output;
  }

  static String _extractIpaForPlayback(String value) {
    final text = sanitizeDisplayText(value);
    if (text.isEmpty) return '';
    final ipaMatch = RegExp(r'/(.+?)/').firstMatch(text);
    if (ipaMatch != null) {
      return '/${ipaMatch.group(1)}/';
    }
    return text;
  }

  WordEntry copyWith({
    int? id,
    int? wordbookId,
    String? word,
    String? meaning,
    List<String>? examples,
    String? etymology,
    String? roots,
    String? affixes,
    String? variations,
    String? memory,
    String? story,
    String? entryUid,
    String? primaryGloss,
    String? schemaVersion,
    int? sortIndex,
    String? sourcePayloadJson,
    List<WordFieldItem>? fields,
    String? rawContent,
    String? rawFieldsJson,
  }) {
    return WordEntry(
      id: id ?? this.id,
      wordbookId: wordbookId ?? this.wordbookId,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      examples: examples ?? this.examples,
      etymology: etymology ?? this.etymology,
      roots: roots ?? this.roots,
      affixes: affixes ?? this.affixes,
      variations: variations ?? this.variations,
      memory: memory ?? this.memory,
      story: story ?? this.story,
      entryUid: entryUid ?? this.entryUid,
      primaryGloss: primaryGloss ?? this.primaryGloss,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      sortIndex: sortIndex ?? this.sortIndex,
      sourcePayloadJson: sourcePayloadJson ?? this.sourcePayloadJson,
      fields: fields == null || fields.isEmpty ? _fields : fields,
      rawContent: rawContent ?? this.rawContent,
      rawFieldsJson: fields == null ? (rawFieldsJson ?? _rawFieldsJson) : '',
    );
  }

  WordEntryPayload toPayload() {
    final mergedFields = mergeFieldItems(<WordFieldItem>[
      ...fields,
      ...buildFieldItemsFromRecord(_legacyFieldRecord),
    ]);

    return WordEntryPayload(
      word: word,
      fields: mergedFields,
      rawContent: rawContent.isNotEmpty ? rawContent : summaryMeaningText,
      entryUid: entryUid,
      primaryGloss: primaryGloss ?? sanitizeDisplayText(summaryMeaningText),
      schemaVersion: schemaVersion,
      sortIndex: sortIndex,
      sourcePayloadJson: sourcePayloadJson,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'wordbookId': wordbookId,
      'word': word,
      'meaning': meaning,
      'examples': examples,
      'etymology': etymology,
      'roots': roots,
      'affixes': affixes,
      'variations': variations,
      'memory': memory,
      'story': story,
      'entryUid': entryUid,
      'primaryGloss': primaryGloss,
      'schemaVersion': schemaVersion,
      'sortIndex': sortIndex,
      'sourcePayloadJson': sourcePayloadJson,
      'fields': fields.map((item) => item.toJsonMap()).toList(growable: false),
      'rawContent': rawContent,
    };
  }

  static WordEntry fromJsonMap(Map<String, Object?> map) {
    List<String>? parseExamples(Object? raw) {
      if (raw is List) {
        final output = raw
            .map((item) => sanitizeDisplayText('$item'))
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        return output.isEmpty ? null : output;
      }
      if (raw is String && raw.trim().isNotEmpty) {
        final output = raw
            .split(RegExp(r'\r?\n'))
            .map(sanitizeDisplayText)
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        return output.isEmpty ? null : output;
      }
      return null;
    }

    List<WordFieldItem> parseFields(Object? raw) {
      if (raw is! List) {
        return const <WordFieldItem>[];
      }
      return parseFieldItemsJson(jsonEncode(raw));
    }

    String? sanitizeNullable(Object? raw) {
      final cleaned = sanitizeDisplayText('${raw ?? ''}');
      return cleaned.isEmpty ? null : cleaned;
    }

    return WordEntry(
      id: (map['id'] as num?)?.toInt(),
      wordbookId: ((map['wordbookId'] as num?) ?? 0).toInt(),
      word: sanitizeDisplayText('${map['word'] ?? ''}'),
      meaning: sanitizeNullable(map['meaning']),
      examples: parseExamples(map['examples']),
      etymology: sanitizeNullable(map['etymology']),
      roots: sanitizeNullable(map['roots']),
      affixes: sanitizeNullable(map['affixes']),
      variations: sanitizeNullable(map['variations']),
      memory: sanitizeNullable(map['memory']),
      story: sanitizeNullable(map['story']),
      entryUid: sanitizeNullable(map['entryUid']),
      primaryGloss: sanitizeNullable(map['primaryGloss']),
      schemaVersion: sanitizeNullable(map['schemaVersion']),
      sortIndex: (map['sortIndex'] as num?)?.toInt(),
      sourcePayloadJson: sanitizeNullable(map['sourcePayloadJson']),
      fields: parseFields(map['fields']),
      rawContent: sanitizeDisplayText('${map['rawContent'] ?? ''}'),
    );
  }

  static WordEntry fromMap(Map<String, Object?> map) {
    String? sanitizeNullable(Object? raw) {
      final cleaned = sanitizeDisplayText('${raw ?? ''}');
      return cleaned.isEmpty ? null : cleaned;
    }

    List<WordFieldItem> parseInlineFields(Object? raw) {
      if (raw == null) {
        return const <WordFieldItem>[];
      }
      if (raw is String) {
        final jsonText = raw.trim();
        if (jsonText.isEmpty) {
          return const <WordFieldItem>[];
        }
        return parseFieldItemsJson(jsonText);
      }
      try {
        return parseFieldItemsJson(jsonEncode(raw));
      } catch (_) {
        return const <WordFieldItem>[];
      }
    }

    List<WordFieldItem> parseExtensionFields(Object? raw) {
      final jsonText = '${raw ?? ''}'.trim();
      if (jsonText.isEmpty) {
        return const <WordFieldItem>[];
      }
      try {
        final decoded = jsonDecode(jsonText);
        if (decoded is Map) {
          final fields = decoded['fields'];
          if (fields is List) {
            return parseInlineFields(fields);
          }
        }
      } catch (_) {
        // Fall back to legacy fields/entry_json when extension_json is invalid.
      }
      return const <WordFieldItem>[];
    }

    List<String>? examples;
    final rawExamples = map['examples'];
    if (rawExamples is String && rawExamples.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(rawExamples);
        if (parsed is List) {
          examples = parsed
              .map((item) => sanitizeDisplayText('$item'))
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
        }
      } catch (_) {
        examples = rawExamples
            .split(RegExp(r'\r?\n'))
            .map((line) => sanitizeDisplayText(line))
            .where((line) => line.isNotEmpty)
            .toList(growable: false);
      }
    }

    final rowId = (map['id'] as num?)?.toInt();
    final rowWordbookId = ((map['wordbook_id'] as num?) ?? 0).toInt();
    final rowMeaning = sanitizeNullable(map['meaning']);
    final rowEtymology = sanitizeNullable(map['etymology']);
    final rowRoots = sanitizeNullable(map['roots']);
    final rowAffixes = sanitizeNullable(map['affixes']);
    final rowVariations = sanitizeNullable(map['variations']);
    final rowMemory = sanitizeNullable(map['memory']);
    final rowStory = sanitizeNullable(map['story']);
    final rowEntryUid = sanitizeNullable(map['entry_uid']);
    final rowPrimaryGloss = sanitizeNullable(map['primary_gloss']);
    final rowSchemaVersion = sanitizeNullable(map['schema_version']);
    final rowSortIndex = (map['sort_index'] as num?)?.toInt();
    final rowSourcePayloadJson = sanitizeNullable(map['source_payload_json']);
    final inlineFields = mergeFieldItems(<WordFieldItem>[
      ...parseInlineFields(map['fields_json']),
      ...parseExtensionFields(map['extension_json']),
    ]);
    final entryJson = '${map['entry_json'] ?? ''}'.trim();
    String readRecoveryRawContent() {
      if (entryJson.isEmpty) {
        return '';
      }
      try {
        final decoded = jsonDecode(entryJson);
        if (decoded is Map) {
          return sanitizeDisplayText(
            '${decoded['rawContent'] ?? decoded['raw_content'] ?? ''}',
          );
        }
      } catch (_) {
        return '';
      }
      return '';
    }

    final recoveryRawContent = readRecoveryRawContent();
    if (entryJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(entryJson);
        if (decoded is Map) {
          final decodedMap = decoded.cast<String, Object?>();
          final hasStructuredLegacyPayload =
              decodedMap.containsKey('word') ||
              decodedMap.containsKey('fields') ||
              decodedMap.containsKey('meaning') ||
              decodedMap.containsKey('examples') ||
              decodedMap.containsKey('etymology') ||
              decodedMap.containsKey('roots') ||
              decodedMap.containsKey('affixes') ||
              decodedMap.containsKey('variations') ||
              decodedMap.containsKey('memory') ||
              decodedMap.containsKey('story');
          if (hasStructuredLegacyPayload) {
            final entry = WordEntry.fromJsonMap(decodedMap);
            final resolvedMeaning = rowMeaning ?? entry.meaning;
            final resolvedExamples = examples ?? entry.examples;
            final resolvedEtymology = rowEtymology ?? entry.etymology;
            final resolvedRoots = rowRoots ?? entry.roots;
            final resolvedAffixes = rowAffixes ?? entry.affixes;
            final resolvedVariations = rowVariations ?? entry.variations;
            final resolvedMemory = rowMemory ?? entry.memory;
            final resolvedStory = rowStory ?? entry.story;
            final resolvedFields = mergeFieldItems(<WordFieldItem>[
              ...entry.fields,
              ...inlineFields,
              ...buildFieldItemsFromRecord(<String, Object?>{
                'meaning': resolvedMeaning,
                'examples': resolvedExamples,
                'etymology': resolvedEtymology,
                'roots': resolvedRoots,
                'affixes': resolvedAffixes,
                'variations': resolvedVariations,
                'memory': resolvedMemory,
                'story': resolvedStory,
              }),
            ]);
            return WordEntry(
              id: rowId ?? entry.id,
              wordbookId: rowWordbookId > 0 ? rowWordbookId : entry.wordbookId,
              word: sanitizeDisplayText(map['word']?.toString() ?? entry.word),
              meaning: resolvedMeaning,
              examples: resolvedExamples,
              etymology: resolvedEtymology,
              roots: resolvedRoots,
              affixes: resolvedAffixes,
              variations: resolvedVariations,
              memory: resolvedMemory,
              story: resolvedStory,
              entryUid: rowEntryUid ?? entry.entryUid,
              primaryGloss: rowPrimaryGloss ?? entry.primaryGloss,
              schemaVersion: rowSchemaVersion ?? entry.schemaVersion,
              sortIndex: rowSortIndex ?? entry.sortIndex,
              sourcePayloadJson:
                  rowSourcePayloadJson ?? entry.sourcePayloadJson,
              fields: resolvedFields,
              rawContent: sanitizeDisplayText(
                map['raw_content']?.toString() ?? entry.rawContent,
              ),
            );
          }
        }
      } catch (_) {
        // Fall back to legacy columns if the structured payload is invalid.
      }
    }

    final fallbackFields = mergeFieldItems(<WordFieldItem>[
      ...inlineFields,
      ...buildFieldItemsFromRecord(<String, Object?>{
        'meaning': rowMeaning,
        'examples': examples,
        'etymology': rowEtymology,
        'roots': rowRoots,
        'affixes': rowAffixes,
        'variations': rowVariations,
        'memory': rowMemory,
        'story': rowStory,
      }),
    ]);

    return WordEntry(
      id: rowId,
      wordbookId: rowWordbookId,
      word: sanitizeDisplayText(map['word']?.toString() ?? ''),
      meaning: rowMeaning,
      examples: examples,
      etymology: rowEtymology,
      roots: rowRoots,
      affixes: rowAffixes,
      variations: rowVariations,
      memory: rowMemory,
      story: rowStory,
      entryUid: rowEntryUid,
      primaryGloss: rowPrimaryGloss,
      schemaVersion: rowSchemaVersion,
      sortIndex: rowSortIndex,
      sourcePayloadJson: rowSourcePayloadJson,
      fields: fallbackFields,
      rawContent: sanitizeDisplayText(
        map['raw_content']?.toString() ?? recoveryRawContent,
      ),
    );
  }
}
