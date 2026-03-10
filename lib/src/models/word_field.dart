import 'dart:convert';

typedef WordFieldValue = Object;

class WordFieldStyle {
  const WordFieldStyle({
    this.backgroundHex = '',
    this.borderHex = '',
    this.textHex = '',
    this.accentHex = '',
  });

  static const WordFieldStyle empty = WordFieldStyle();

  final String backgroundHex;
  final String borderHex;
  final String textHex;
  final String accentHex;

  bool get isEmpty =>
      backgroundHex.trim().isEmpty &&
      borderHex.trim().isEmpty &&
      textHex.trim().isEmpty &&
      accentHex.trim().isEmpty;

  WordFieldStyle copyWith({
    String? backgroundHex,
    String? borderHex,
    String? textHex,
    String? accentHex,
  }) {
    return WordFieldStyle(
      backgroundHex: backgroundHex ?? this.backgroundHex,
      borderHex: borderHex ?? this.borderHex,
      textHex: textHex ?? this.textHex,
      accentHex: accentHex ?? this.accentHex,
    );
  }

  WordFieldStyle mergeWith(WordFieldStyle next) {
    String choose(String current, String incoming) {
      final normalized = incoming.trim();
      return normalized.isEmpty ? current.trim() : normalized;
    }

    return WordFieldStyle(
      backgroundHex: choose(backgroundHex, next.backgroundHex),
      borderHex: choose(borderHex, next.borderHex),
      textHex: choose(textHex, next.textHex),
      accentHex: choose(accentHex, next.accentHex),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'backgroundHex': backgroundHex.trim(),
      'borderHex': borderHex.trim(),
      'textHex': textHex.trim(),
      'accentHex': accentHex.trim(),
    };
  }

  factory WordFieldStyle.fromJsonMap(Object? raw) {
    if (raw is! Map) return WordFieldStyle.empty;
    return WordFieldStyle(
      backgroundHex: '${raw['backgroundHex'] ?? ''}'.trim(),
      borderHex: '${raw['borderHex'] ?? ''}'.trim(),
      textHex: '${raw['textHex'] ?? ''}'.trim(),
      accentHex: '${raw['accentHex'] ?? ''}'.trim(),
    );
  }
}

class WordFieldItem {
  const WordFieldItem({
    required this.key,
    required this.label,
    required this.value,
    this.style = WordFieldStyle.empty,
  });

  final String key;
  final String label;
  final WordFieldValue value;
  final WordFieldStyle style;

  List<String> asList() {
    final fieldValue = value;
    if (fieldValue is List) {
      return fieldValue
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final text = '$fieldValue'.trim();
    return text.isEmpty ? const [] : [text];
  }

  String asText() => asList().join('\n');

  Map<String, Object?> toJsonMap() {
    final output = <String, Object?>{
      'key': key,
      'label': label,
      'value': value,
    };
    if (!style.isEmpty) {
      output['style'] = style.toJsonMap();
    }
    return output;
  }
}

class LegacyWordFields {
  const LegacyWordFields({
    this.meaning,
    this.examples,
    this.etymology,
    this.roots,
    this.affixes,
    this.variations,
    this.memory,
    this.story,
  });

  final String? meaning;
  final List<String>? examples;
  final String? etymology;
  final String? roots;
  final String? affixes;
  final String? variations;
  final String? memory;
  final String? story;
}

const Map<String, String> legacyFieldLabels = <String, String>{
  'meaning': 'Meaning',
  'examples': 'Examples',
  'etymology': 'Etymology',
  'roots': 'Roots',
  'affixes': 'Affixes',
  'variations': 'Variations',
  'memory': 'Memory',
  'story': 'Story',
};

const List<String> _legacyOrder = <String>[
  'meaning',
  'examples',
  'etymology',
  'roots',
  'affixes',
  'variations',
  'memory',
  'story',
];

const Map<String, String> _legacyKeyAliases = <String, String>{
  'meaning': 'meaning',
  'definition': 'meaning',
  'translation': 'meaning',
  '释义': 'meaning',
  '含义': 'meaning',
  'examples': 'examples',
  'example': 'examples',
  'sentences': 'examples',
  'sentence': 'examples',
  '例句': 'examples',
  'etymology': 'etymology',
  'origin': 'etymology',
  '词源': 'etymology',
  'roots': 'roots',
  'root': 'roots',
  '词根': 'roots',
  'affixes': 'affixes',
  'affix': 'affixes',
  'suffix': 'affixes',
  'prefix': 'affixes',
  '词缀': 'affixes',
  'variations': 'variations',
  'variation': 'variations',
  'forms': 'variations',
  'form': 'variations',
  '变形': 'variations',
  'memory': 'memory',
  'mnemonic': 'memory',
  '记忆': 'memory',
  'story': 'story',
  '故事': 'story',
};

const Set<String> _wordKeyAliases = <String>{
  'word',
  'term',
  'vocabulary',
  'headword',
  'title',
  '单词',
  '词汇',
};

const Set<String> _contentKeyAliases = <String>{
  'content',
  'raw_content',
  'definition_content',
  'body',
};

String normalizeFieldKey(String rawKey) {
  final trimmed = rawKey.trim();
  if (trimmed.isEmpty) return '';
  final normalized = trimmed.toLowerCase();
  final legacy = _legacyKeyAliases[normalized];
  if (legacy != null) return legacy;

  final simplePattern = RegExp(r'^[\u4e00-\u9fff_a-zA-Z0-9-]+$');
  if (simplePattern.hasMatch(trimmed)) return trimmed;

  final sanitized = normalized
      .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return sanitized.isNotEmpty ? sanitized : trimmed;
}

bool isWordKey(String key) =>
    _wordKeyAliases.contains(key.trim().toLowerCase());

bool isContentKey(String key) =>
    _contentKeyAliases.contains(key.trim().toLowerCase());

WordFieldValue? normalizeFieldValue(Object? value) {
  if (value == null) return null;

  if (value is List) {
    final list = value
        .map((item) {
          if (item == null) return '';
          if (item is String) return item.trim();
          if (item is num || item is bool) return '$item';
          return jsonEncode(item);
        })
        .where((item) => item.isNotEmpty)
        .toList();
    return list.isEmpty ? null : list;
  }

  if (value is String) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  if (value is num || value is bool) return '$value';

  final text = jsonEncode(value);
  if (text == '{}' || text == '[]') return null;
  return text;
}

WordFieldValue _mergeFieldValues(WordFieldValue base, WordFieldValue next) {
  final merged = <String>[
    ..._toList(base),
    ..._toList(next),
  ].map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

  final deduplicated = <String>[];
  for (final item in merged) {
    if (!deduplicated.contains(item)) deduplicated.add(item);
  }

  if (deduplicated.length <= 1) {
    return deduplicated.isEmpty ? '' : deduplicated.first;
  }
  return deduplicated;
}

List<String> _toList(Object value) {
  if (value is List) return value.map((item) => '$item').toList();
  return ['$value'];
}

WordFieldValue _coerceExamples(WordFieldValue value) {
  if (value is List) {
    return value
        .map((item) => '$item'.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final text = '$value';
  if (!text.contains('\n')) return text.trim();

  final rows = text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.replaceFirst(RegExp(r'^[-*\d.\s]+'), '').trim())
      .where((line) => line.isNotEmpty)
      .toList();

  if (rows.length <= 1) return text.trim();
  return rows;
}

List<WordFieldItem> orderFieldItems(List<WordFieldItem> items) {
  final orderMap = <String, int>{
    for (var i = 0; i < _legacyOrder.length; i++) _legacyOrder[i]: i,
  };

  items.sort((a, b) {
    final ai = orderMap[a.key] ?? 99999;
    final bi = orderMap[b.key] ?? 99999;
    if (ai != bi) return ai.compareTo(bi);
    return a.label.compareTo(b.label);
  });
  return items;
}

List<WordFieldItem> mergeFieldItems(List<WordFieldItem> items) {
  final merged = <String, WordFieldItem>{};

  for (final item in items) {
    final key = normalizeFieldKey(item.key);
    if (key.isEmpty) continue;
    final value = normalizeFieldValue(item.value);
    if (value == null) continue;

    final label = item.label.trim().isEmpty ? key : item.label.trim();
    final existing = merged[key];
    if (existing == null) {
      merged[key] = WordFieldItem(
        key: key,
        label: legacyFieldLabels[key] ?? label,
        value: value,
        style: item.style,
      );
      continue;
    }

    merged[key] = WordFieldItem(
      key: key,
      label: existing.label,
      value: _mergeFieldValues(existing.value, value),
      style: existing.style.mergeWith(item.style),
    );
  }

  return orderFieldItems(merged.values.toList());
}

List<WordFieldItem> buildFieldItemsFromRecord(Map<String, Object?> record) {
  final output = <WordFieldItem>[];

  for (final entry in record.entries) {
    if (entry.key.isEmpty) continue;
    if (isWordKey(entry.key) || isContentKey(entry.key)) continue;

    final key = normalizeFieldKey(entry.key);
    if (key.isEmpty) continue;

    var value = normalizeFieldValue(entry.value);
    if (value == null) continue;
    if (key == 'examples') value = _coerceExamples(value);

    output.add(
      WordFieldItem(
        key: key,
        label: legacyFieldLabels[key] ?? entry.key.trim(),
        value: value,
      ),
    );
  }

  return mergeFieldItems(output);
}

List<WordFieldItem> parseFieldItemsJson(String raw) {
  if (raw.trim().isEmpty) return const [];

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    final items = <WordFieldItem>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final key = normalizeFieldKey('${entry['key'] ?? ''}');
      if (key.isEmpty) continue;
      final label = '${entry['label'] ?? key}'.trim();
      final value = normalizeFieldValue(entry['value']);
      if (value == null) continue;

      items.add(
        WordFieldItem(
          key: key,
          label: label.isEmpty ? key : label,
          value: value,
          style: WordFieldStyle.fromJsonMap(entry['style']),
        ),
      );
    }
    return mergeFieldItems(items);
  } catch (_) {
    return const [];
  }
}

String stringifyFieldItems(List<WordFieldItem> items) {
  final normalized = mergeFieldItems(items);
  return jsonEncode(normalized.map((item) => item.toJsonMap()).toList());
}

LegacyWordFields toLegacyFields(List<WordFieldItem> items) {
  String? getText(String key) {
    final item = items
        .where((entry) => entry.key == key)
        .cast<WordFieldItem?>()
        .firstOrNull;
    return item?.asText();
  }

  List<String>? getList(String key) {
    final item = items
        .where((entry) => entry.key == key)
        .cast<WordFieldItem?>()
        .firstOrNull;
    final list = item?.asList() ?? const <String>[];
    return list.isEmpty ? null : list;
  }

  return LegacyWordFields(
    meaning: getText('meaning'),
    examples: getList('examples'),
    etymology: getText('etymology'),
    roots: getText('roots'),
    affixes: getText('affixes'),
    variations: getText('variations'),
    memory: getText('memory'),
    story: getText('story'),
  );
}

List<WordFieldItem> parseSectionedContent(String content) {
  final text = content.trim();
  if (text.isEmpty) return const [];

  final items = <WordFieldItem>[];

  final markdownPattern = RegExp(
    r'(?:^|\n)#{1,6}\s+([^\n]+)\n([\s\S]*?)(?=\n#{1,6}\s+|$)',
  );
  final markdownMatches = markdownPattern.allMatches(text);
  for (final match in markdownMatches) {
    final rawLabel = (match.group(1) ?? '').trim();
    final body = (match.group(2) ?? '').trim();
    if (rawLabel.isEmpty || body.isEmpty) continue;

    final key = normalizeFieldKey(rawLabel);
    var value = normalizeFieldValue(body);
    if (value == null) continue;
    if (key == 'examples') value = _coerceExamples(value);

    items.add(
      WordFieldItem(
        key: key,
        label: legacyFieldLabels[key] ?? rawLabel,
        value: value,
      ),
    );
  }

  if (items.isNotEmpty) return mergeFieldItems(items);

  return <WordFieldItem>[
    WordFieldItem(
      key: 'meaning',
      label: legacyFieldLabels['meaning'] ?? 'Meaning',
      value: text,
    ),
  ];
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
