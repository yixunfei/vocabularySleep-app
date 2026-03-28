import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dict_reader/dict_reader.dart';
import 'package:flutter/foundation.dart';

import '../models/word_entry.dart';
import '../models/word_field.dart';

const Set<String> _jsonRecordContainerKeys = <String>{
  'words',
  'entries',
  'items',
  'records',
  '词条列表',
  '单词列表',
  '词汇列表',
};

List<Map<String, Object?>> _parseJsonRecords(String content) {
  final records = <Map<String, Object?>>[];

  void push(Object? record) {
    if (record is Map<String, Object?>) {
      records.add(record);
      return;
    }
    if (record is Map) {
      records.add(record.cast<String, Object?>());
    }
  }

  try {
    final decoded = jsonDecode(content);
    if (decoded is List) {
      for (final item in decoded) {
        push(item);
      }
      return records;
    }

    if (decoded is Map) {
      List? container;
      for (final key in _jsonRecordContainerKeys) {
        final value = decoded[key];
        if (value is List) {
          container = value;
          break;
        }
      }
      if (container != null) {
        for (final item in container) {
          push(item);
        }
      } else {
        push(decoded);
      }
      return records;
    }
  } catch (_) {
    // Fall back to JSONL / concatenated object parser.
  }

  final lines = content.split(RegExp(r'\r?\n'));
  var depth = 0;
  final buffer = StringBuffer();

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    buffer.writeln(line);
    for (final char in trimmed.runes) {
      if (char == 123) depth += 1;
      if (char == 125) depth -= 1;
    }

    if (depth == 0) {
      final chunk = buffer.toString().trim();
      buffer.clear();
      if (chunk.isEmpty) continue;
      try {
        final decoded = jsonDecode(chunk);
        push(decoded);
      } catch (_) {
        // Ignore malformed rows.
      }
    }
  }

  return records;
}

class WordbookImportService {
  static const Set<String> _wordAliases = <String>{
    'word',
    'term',
    'vocabulary',
    'headword',
    'title',
    '目标单词',
    '单词',
    '英文单词',
    '目标词',
    '词汇',
  };

  static const List<String> _contentFields = <String>[
    'content',
    'raw_content',
    'definition',
    'meaning',
    'translation',
    '中文释义',
    '释义',
    'definition_content',
    'body',
  ];

  Future<List<WordEntryPayload>> parseFile(String filePath) async {
    final ext = _extension(filePath).toLowerCase();
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', filePath);
    }

    if (ext == '.mdx') {
      return _parseMdxFile(filePath);
    }

    if (ext == '.mdd') {
      throw UnsupportedError(
        'MDD cannot be imported alone. Please import the corresponding MDX file.',
      );
    }

    final content = await file.readAsString();
    switch (ext) {
      case '.json':
        return parseJsonTextAsync(content);
      case '.csv':
        return parseCsvText(content);
      default:
        return parseJsonTextAsync(content);
    }
  }

  List<WordEntryPayload> parseJsonText(String content) {
    final payloads = <WordEntryPayload>[];
    processJsonText(content, onPayload: payloads.add);
    return payloads;
  }

  Future<List<WordEntryPayload>> parseJsonTextAsync(String content) async {
    final payloads = <WordEntryPayload>[];
    final records = await compute(_parseJsonRecords, content);
    for (final record in records) {
      final payload = _recordToPayload(record);
      if (payload != null) payloads.add(payload);
    }
    return payloads;
  }

  int processJsonText(
    String content, {
    required void Function(WordEntryPayload payload) onPayload,
    void Function(int processed, int? total)? onProgress,
  }) {
    Map<String, Object?>? asRecordMap(Object? value) {
      if (value is Map<String, Object?>) {
        return value;
      }
      if (value is Map) {
        return value.cast<String, Object?>();
      }
      return null;
    }

    int emitPayload(Object? value) {
      final record = asRecordMap(value);
      if (record == null) return 0;
      final payload = _recordToPayload(record);
      if (payload == null) return 0;
      onPayload(payload);
      return 1;
    }

    var lastReportedProcessed = -1;
    var lastReportedPercent = -1;

    void reportProgress(int processed, int? total, {bool force = false}) {
      if (onProgress == null) return;
      if (!force) {
        if (total != null && total > 0) {
          final percent = ((processed * 100) ~/ total).clamp(0, 100);
          if (processed < total && percent == lastReportedPercent) {
            return;
          }
          lastReportedPercent = percent;
        } else if (processed - lastReportedProcessed < 64) {
          return;
        }
      }
      lastReportedProcessed = processed;
      onProgress(processed, total);
    }

    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        var count = 0;
        final total = decoded.length;
        reportProgress(0, total, force: true);
        for (var index = 0; index < total; index += 1) {
          count += emitPayload(decoded[index]);
          reportProgress(index + 1, total);
        }
        reportProgress(total, total, force: true);
        return count;
      }

      if (decoded is Map) {
        for (final key in _jsonRecordContainerKeys) {
          final container = decoded[key];
          if (container is! List) continue;
          var count = 0;
          final total = container.length;
          reportProgress(0, total, force: true);
          for (var index = 0; index < total; index += 1) {
            count += emitPayload(container[index]);
            reportProgress(index + 1, total);
          }
          reportProgress(total, total, force: true);
          return count;
        }
        reportProgress(0, 1, force: true);
        final count = emitPayload(decoded);
        reportProgress(1, 1, force: true);
        return count;
      }
    } catch (_) {
      // Fall back to JSONL / concatenated object parser below.
    }

    final lines = content.split(RegExp(r'\r?\n'));
    var depth = 0;
    var count = 0;
    var processed = 0;
    final buffer = StringBuffer();
    reportProgress(0, null, force: true);

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      buffer.writeln(line);
      for (final char in trimmed.runes) {
        if (char == 123) depth += 1;
        if (char == 125) depth -= 1;
      }

      if (depth != 0) continue;
      final chunk = buffer.toString().trim();
      buffer.clear();
      if (chunk.isEmpty) continue;

      try {
        final decoded = jsonDecode(chunk);
        processed += 1;
        count += emitPayload(decoded);
        reportProgress(processed, null);
      } catch (_) {
        // Ignore malformed rows.
      }
    }

    reportProgress(processed, null, force: true);
    return count;
  }

  Future<int> processJsonTextAsync(
    String content, {
    required void Function(WordEntryPayload payload) onPayload,
    void Function(int processed, int? total)? onProgress,
    int yieldEvery = 180,
  }) async {
    final resolvedYieldEvery = yieldEvery < 1 ? 1 : yieldEvery;

    Map<String, Object?>? asRecordMap(Object? value) {
      if (value is Map<String, Object?>) {
        return value;
      }
      if (value is Map) {
        return value.cast<String, Object?>();
      }
      return null;
    }

    int emitPayload(Object? value) {
      final record = asRecordMap(value);
      if (record == null) return 0;
      final payload = _recordToPayload(record);
      if (payload == null) return 0;
      onPayload(payload);
      return 1;
    }

    var lastReportedProcessed = -1;
    var lastReportedPercent = -1;
    var sinceLastYield = 0;

    void reportProgress(int processed, int? total, {bool force = false}) {
      if (onProgress == null) return;
      if (!force) {
        if (total != null && total > 0) {
          final percent = ((processed * 100) ~/ total).clamp(0, 100);
          if (processed < total && percent == lastReportedPercent) {
            return;
          }
          lastReportedPercent = percent;
        } else if (processed - lastReportedProcessed < 64) {
          return;
        }
      }
      lastReportedProcessed = processed;
      onProgress(processed, total);
    }

    Future<void> maybeYield() async {
      sinceLastYield += 1;
      if (sinceLastYield < resolvedYieldEvery) return;
      sinceLastYield = 0;
      await Future<void>.delayed(Duration.zero);
    }

    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        var count = 0;
        final total = decoded.length;
        reportProgress(0, total, force: true);
        for (var index = 0; index < total; index += 1) {
          count += emitPayload(decoded[index]);
          reportProgress(index + 1, total);
          await maybeYield();
        }
        reportProgress(total, total, force: true);
        return count;
      }

      if (decoded is Map) {
        for (final key in _jsonRecordContainerKeys) {
          final container = decoded[key];
          if (container is! List) continue;
          var count = 0;
          final total = container.length;
          reportProgress(0, total, force: true);
          for (var index = 0; index < total; index += 1) {
            count += emitPayload(container[index]);
            reportProgress(index + 1, total);
            await maybeYield();
          }
          reportProgress(total, total, force: true);
          return count;
        }
        reportProgress(0, 1, force: true);
        final count = emitPayload(decoded);
        reportProgress(1, 1, force: true);
        return count;
      }
    } catch (_) {
      // Fall back to JSONL / concatenated object parser below.
    }

    final lines = content.split(RegExp(r'\r?\n'));
    var depth = 0;
    var count = 0;
    var processed = 0;
    final buffer = StringBuffer();
    reportProgress(0, null, force: true);

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      buffer.writeln(line);
      for (final char in trimmed.runes) {
        if (char == 123) depth += 1;
        if (char == 125) depth -= 1;
      }

      if (depth != 0) continue;
      final chunk = buffer.toString().trim();
      buffer.clear();
      if (chunk.isEmpty) continue;

      try {
        final decoded = jsonDecode(chunk);
        processed += 1;
        count += emitPayload(decoded);
        reportProgress(processed, null);
        await maybeYield();
      } catch (_) {
        // Ignore malformed rows.
      }
    }

    reportProgress(processed, null, force: true);
    return count;
  }

  List<WordEntryPayload> parseCsvText(String content) {
    final rows = _parseCsvRows(content);
    if (rows.length < 2) return const <WordEntryPayload>[];

    final headers = rows.first.map((item) => item.trim()).toList();
    final wordIndex = headers.indexWhere(
      (header) => _wordAliases.contains(header.toLowerCase()),
    );
    if (wordIndex < 0) return const <WordEntryPayload>[];

    final payloads = <WordEntryPayload>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (wordIndex >= row.length) continue;
      final word = row[wordIndex].trim();
      if (word.isEmpty) continue;

      final map = <String, Object?>{headers[wordIndex]: word};
      for (var col = 0; col < headers.length; col++) {
        if (col == wordIndex || col >= row.length) continue;
        final key = headers[col].trim();
        if (key.isEmpty) continue;
        final value = row[col].trim();
        if (value.isEmpty) continue;
        map[key] = value;
      }

      final payload = _recordToPayload(map);
      if (payload != null) payloads.add(payload);
    }

    return payloads;
  }

  Future<List<WordEntryPayload>> _parseMdxFile(String filePath) async {
    final payloads = <WordEntryPayload>[];
    final dict = DictReader(filePath);

    try {
      await dict.initDict(readKeys: true, readRecordBlockInfo: false);
      await for (final record in dict.readWithMdxData()) {
        final key = record.keyText.trim();
        if (key.isEmpty) continue;

        final content = record.data.replaceAll('\u0000', '').trim();
        final payload = _recordToPayload(<String, Object?>{
          'word': key,
          'content': content,
        });
        if (payload != null) payloads.add(payload);
      }
    } finally {
      await dict.close();
    }

    return payloads;
  }

  List<List<String>> _parseCsvRows(String content) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentCell = StringBuffer();
    var inQuotes = false;

    void pushCell() {
      currentRow.add(currentCell.toString());
      currentCell.clear();
    }

    void pushRow() {
      rows.add(List<String>.from(currentRow));
      currentRow.clear();
    }

    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    for (var i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      if (char == '"') {
        final nextIsQuote =
            i + 1 < normalized.length && normalized[i + 1] == '"';
        if (inQuotes && nextIsQuote) {
          currentCell.write('"');
          i += 1;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (char == ',' && !inQuotes) {
        pushCell();
        continue;
      }

      if (char == '\n' && !inQuotes) {
        pushCell();
        if (currentRow.any((cell) => cell.trim().isNotEmpty)) {
          pushRow();
        } else {
          currentRow.clear();
        }
        continue;
      }

      currentCell.write(char);
    }

    pushCell();
    if (currentRow.any((cell) => cell.trim().isNotEmpty)) {
      pushRow();
    }

    return rows;
  }

  String _extension(String filePath) {
    final index = filePath.lastIndexOf('.');
    if (index < 0) return '';
    return filePath.substring(index);
  }

  WordEntryPayload? _recordToPayload(Map<String, Object?> record) {
    final normalizedRecord = _normalizeRecord(record);
    String word = '';
    for (final entry in normalizedRecord.entries) {
      if (_wordAliases.contains(entry.key.trim().toLowerCase())) {
        final text = sanitizeDisplayText('${entry.value ?? ''}');
        if (text.isNotEmpty) {
          word = text;
          break;
        }
      }
    }
    if (word.isEmpty) return null;

    String content = '';
    for (final key in _contentFields) {
      final value = normalizedRecord[key];
      if (value == null) continue;
      final text = sanitizeDisplayText('$value');
      if (text.isEmpty) continue;
      content = text;
      break;
    }

    final recordFields = buildFieldItemsFromRecord(normalizedRecord);
    final contentFields = content.isNotEmpty
        ? parseSectionedContent(content)
        : const <WordFieldItem>[];
    final fields = mergeFieldItems(<WordFieldItem>[
      ...recordFields,
      ...contentFields,
    ]);

    return WordEntryPayload(word: word, fields: fields, rawContent: content);
  }

  Map<String, Object?> _normalizeRecord(Map<String, Object?> record) {
    final normalized = <String, Object?>{};
    for (final entry in record.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      final value = _normalizeRecordValue(key, entry.value);
      if (value == null) continue;
      normalized[key] = value;
    }
    return normalized;
  }

  Object? _normalizeRecordValue(String key, Object? value) {
    return switch (key) {
      '音标/发音标注' => _flattenLabeledMap(value),
      '场景化例句' => _flattenScenarioExamples(value),
      _ => value,
    };
  }

  String? _flattenLabeledMap(Object? value) {
    if (value is! Map) return value == null ? null : '$value';
    final lines = <String>[];
    for (final entry in value.entries) {
      final label = sanitizeDisplayText('${entry.key}');
      final text = sanitizeDisplayText('${entry.value ?? ''}');
      if (label.isEmpty || text.isEmpty) continue;
      lines.add('$label: $text');
    }
    if (lines.isEmpty) return null;
    return lines.join('\n');
  }

  List<String>? _flattenScenarioExamples(Object? value) {
    if (value is! List) return null;
    final rows = <String>[];
    for (final item in value) {
      if (item is Map) {
        final category = sanitizeDisplayText(
          '${item['含义类别'] ?? item['场景类别'] ?? item['类别'] ?? ''}',
        );
        final sentence = sanitizeDisplayText(
          '${item['例句原文'] ?? item['英文例句'] ?? item['example'] ?? ''}',
        );
        final translation = sanitizeDisplayText(
          '${item['中文翻译'] ?? item['译文'] ?? item['translation'] ?? ''}',
        );
        final parts = <String>[];
        if (sentence.isNotEmpty) {
          parts.add(category.isEmpty ? sentence : '[$category] $sentence');
        }
        if (translation.isNotEmpty) {
          parts.add('中文：$translation');
        }
        final row = parts.join('\n').trim();
        if (row.isNotEmpty) rows.add(row);
        continue;
      }

      final text = sanitizeDisplayText('$item');
      if (text.isNotEmpty) rows.add(text);
    }
    return rows.isEmpty ? null : rows;
  }
}
