final List<MapEntry<RegExp, String>> _latinFoldRules =
    <MapEntry<RegExp, String>>[
      MapEntry(RegExp(r'[àáâãäåāăąǎǻȁȃȧạảấầẩẫậắằẳẵặ]'), 'a'),
      MapEntry(RegExp(r'[æǽǣ]'), 'ae'),
      MapEntry(RegExp(r'[çćĉċč]'), 'c'),
      MapEntry(RegExp(r'[ďđð]'), 'd'),
      MapEntry(RegExp('[èéêëēĕėęěȅȇẹẻẽếềểễệ\u8121]'), 'e'),
      MapEntry(RegExp(r'[ƒ]'), 'f'),
      MapEntry(RegExp(r'[ĝğġģ]'), 'g'),
      MapEntry(RegExp(r'[ĥħ]'), 'h'),
      MapEntry(RegExp(r'[ìíîïĩīĭįıǐȉȋịỉ]'), 'i'),
      MapEntry(RegExp(r'[ĵ]'), 'j'),
      MapEntry(RegExp(r'[ķĸ]'), 'k'),
      MapEntry(RegExp(r'[ĺļľŀł]'), 'l'),
      MapEntry(RegExp(r'[ñńņňŉŋ]'), 'n'),
      MapEntry(RegExp(r'[òóôõöøōŏőǒȍȏọỏốồổỗộớờởỡợ]'), 'o'),
      MapEntry(RegExp(r'[œ]'), 'oe'),
      MapEntry(RegExp(r'[ŕŗř]'), 'r'),
      MapEntry(RegExp(r'[śŝşšș]'), 's'),
      MapEntry(RegExp(r'[ß]'), 'ss'),
      MapEntry(RegExp(r'[ţťŧț]'), 't'),
      MapEntry(RegExp(r'[ùúûüũūŭůűųǔȕȗụủứừửữự]'), 'u'),
      MapEntry(RegExp(r'[ŵ]'), 'w'),
      MapEntry(RegExp(r'[ýÿŷȳỳỵỷỹ]'), 'y'),
      MapEntry(RegExp(r'[źżž]'), 'z'),
    ];

String foldLatinDiacritics(String text) {
  var output = text;
  for (final rule in _latinFoldRules) {
    output = output.replaceAll(rule.key, rule.value);
  }
  return output;
}

String normalizeSearchText(String text) {
  var normalized = foldLatinDiacritics(text.toLowerCase());
  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized;
}

String normalizeJumpText(String text) {
  final normalized = normalizeSearchText(text);
  return normalized.replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fff]+'), '');
}

String normalizeFuzzyCompactText(String text) {
  return normalizeSearchText(text).replaceAll(' ', '');
}

RegExp? buildFuzzyPattern(String query) {
  final normalized = query.trim();
  if (normalized.isEmpty) {
    return null;
  }
  final compact = normalized.replaceAll(' ', '');
  if (compact.isEmpty) {
    return null;
  }
  final escaped = compact.split('').map(RegExp.escape).join('.*');
  return RegExp(escaped, caseSensitive: false);
}

String buildFuzzySqlLikePattern(String query) {
  final compact = normalizeFuzzyCompactText(query);
  if (compact.isEmpty) {
    return '';
  }
  final escaped = compact
      .split('')
      .map(
        (char) => char
            .replaceAll('\\', '\\\\')
            .replaceAll('%', '\\%')
            .replaceAll('_', '\\_'),
      )
      .join('%');
  return '%$escaped%';
}

String wordInitialBucket(String word) {
  final normalized = normalizeJumpText(word);
  if (normalized.isEmpty) {
    return '#';
  }
  final first = normalized[0];
  final code = first.codeUnitAt(0);
  final isLatinLetter = code >= 97 && code <= 122;
  return isLatinLetter ? first.toUpperCase() : '#';
}
