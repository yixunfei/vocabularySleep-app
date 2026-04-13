import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dict_reader/dict_reader.dart';
import 'package:flutter/foundation.dart';

import '../models/word_entry.dart';
import '../models/word_field.dart';
import '../models/wordbook_import_audit.dart';
import '../models/wordbook_schema_v1.dart';

const Set<String> _jsonRecordContainerKeys = <String>{
  'words',
  'entries',
  'items',
  'records',
  '词条列表',
  '单词列表',
  '词汇列表',
};

const Set<String> _metadataContainerKeys = <String>{
  'metadata',
  'meta',
  'book',
  '元数据',
};

class WordbookImportDescriptor {
  const WordbookImportDescriptor({
    required this.format,
    this.schemaVersion,
    this.bookName,
    this.metadataJson,
    this.totalRecords,
  });

  final String format;
  final String? schemaVersion;
  final String? bookName;
  final String? metadataJson;
  final int? totalRecords;

  bool get hasStructuredMetadata =>
      (metadataJson ?? '').trim().isNotEmpty ||
      (schemaVersion ?? '').trim().isNotEmpty;
}

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
      final container = _resolveRecordContainer(
        decoded.cast<String, Object?>(),
      );
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
    // Fall back to JSONL / concatenated object parsing below.
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

List<Object?>? _resolveRecordContainer(Map<String, Object?> decoded) {
  for (final key in _jsonRecordContainerKeys) {
    final value = decoded[key];
    if (value is List) {
      return value.cast<Object?>();
    }
  }
  return null;
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

  WordbookImportDescriptor inspectJsonText(
    String content, {
    String fallbackName = '',
  }) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return WordbookImportDescriptor(
          format: 'json_array',
          totalRecords: decoded.length,
        );
      }
      if (decoded is Map) {
        return _describeJsonMap(
          decoded.cast<String, Object?>(),
          fallbackName: fallbackName,
        );
      }
    } catch (_) {
      // Fall back to record counting below.
    }

    final records = _parseJsonRecords(content);
    return WordbookImportDescriptor(
      format: 'json_records',
      totalRecords: records.length,
    );
  }

  List<WordEntryPayload> parseJsonText(String content) {
    final payloads = <WordEntryPayload>[];
    processJsonText(content, onPayload: payloads.add);
    return payloads;
  }

  Future<List<WordEntryPayload>> parseJsonTextAsync(String content) async {
    final standard = tryParseStandardWordbook(content);
    if (standard != null) {
      _ensureStandardWordbookValid(standard);
      return standard.toPayloads();
    }

    final payloads = <WordEntryPayload>[];
    final records = await compute(_parseJsonRecords, content);
    for (var index = 0; index < records.length; index += 1) {
      final payload = _recordToPayload(records[index], sortIndex: index);
      if (payload != null) {
        payloads.add(payload);
      }
    }
    return payloads;
  }

  int processJsonText(
    String content, {
    required void Function(WordEntryPayload payload) onPayload,
    void Function(int processed, int? total)? onProgress,
  }) {
    final standard = tryParseStandardWordbook(content);
    if (standard != null) {
      _ensureStandardWordbookValid(standard);
      final payloads = standard.toPayloads();
      onProgress?.call(0, payloads.length);
      for (var index = 0; index < payloads.length; index += 1) {
        onPayload(payloads[index]);
        onProgress?.call(index + 1, payloads.length);
      }
      return payloads.length;
    }

    Map<String, Object?>? asRecordMap(Object? value) {
      if (value is Map<String, Object?>) {
        return value;
      }
      if (value is Map) {
        return value.cast<String, Object?>();
      }
      return null;
    }

    int emitPayload(Object? value, int sortIndex) {
      final record = asRecordMap(value);
      if (record == null) return 0;
      final payload = _recordToPayload(record, sortIndex: sortIndex);
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
          count += emitPayload(decoded[index], index);
          reportProgress(index + 1, total);
        }
        reportProgress(total, total, force: true);
        return count;
      }

      if (decoded is Map) {
        final container = _resolveRecordContainer(
          decoded.cast<String, Object?>(),
        );
        if (container != null) {
          var count = 0;
          final total = container.length;
          reportProgress(0, total, force: true);
          for (var index = 0; index < total; index += 1) {
            count += emitPayload(container[index], index);
            reportProgress(index + 1, total);
          }
          reportProgress(total, total, force: true);
          return count;
        }
        reportProgress(0, 1, force: true);
        final count = emitPayload(decoded, 0);
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
        count += emitPayload(decoded, processed);
        processed += 1;
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
    final standard = tryParseStandardWordbook(content);
    if (standard != null) {
      _ensureStandardWordbookValid(standard);
      final payloads = standard.toPayloads();
      onProgress?.call(0, payloads.length);
      final resolvedYieldEvery = yieldEvery < 1 ? 1 : yieldEvery;
      for (var index = 0; index < payloads.length; index += 1) {
        onPayload(payloads[index]);
        onProgress?.call(index + 1, payloads.length);
        if ((index + 1) % resolvedYieldEvery == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
      return payloads.length;
    }

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

    int emitPayload(Object? value, int sortIndex) {
      final record = asRecordMap(value);
      if (record == null) return 0;
      final payload = _recordToPayload(record, sortIndex: sortIndex);
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
          count += emitPayload(decoded[index], index);
          reportProgress(index + 1, total);
          await maybeYield();
        }
        reportProgress(total, total, force: true);
        return count;
      }

      if (decoded is Map) {
        final container = _resolveRecordContainer(
          decoded.cast<String, Object?>(),
        );
        if (container != null) {
          var count = 0;
          final total = container.length;
          reportProgress(0, total, force: true);
          for (var index = 0; index < total; index += 1) {
            count += emitPayload(container[index], index);
            reportProgress(index + 1, total);
            await maybeYield();
          }
          reportProgress(total, total, force: true);
          return count;
        }
        reportProgress(0, 1, force: true);
        final count = emitPayload(decoded, 0);
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
        count += emitPayload(decoded, processed);
        processed += 1;
        reportProgress(processed, null);
        await maybeYield();
      } catch (_) {
        // Ignore malformed rows.
      }
    }

    reportProgress(processed, null, force: true);
    return count;
  }

  Future<int> processJsonByteStreamAsync(
    Stream<List<int>> byteStream, {
    required void Function(WordEntryPayload payload) onPayload,
    void Function(int processed, int? total)? onProgress,
    int yieldEvery = 180,
    bool gzipped = false,
  }) async {
    final content = await readJsonByteStreamAsString(
      byteStream,
      gzipped: gzipped,
    );
    return processJsonTextAsync(
      content,
      onPayload: onPayload,
      onProgress: onProgress,
      yieldEvery: yieldEvery,
    );
  }

  WordbookImportAudit auditJsonText(String content) {
    try {
      final standard = tryParseStandardWordbook(content);
      if (standard != null) {
        return standard.validate();
      }

      final payloads = parseJsonText(content);
      return WordbookImportAudit(
        format: 'dynamic_json',
        schemaVersion: '',
        totalRecords: payloads.length,
        acceptedRecords: payloads.length,
        issues: const <WordbookImportIssue>[],
        note: payloads.isEmpty ? '未识别到可导入词条' : '已按兼容动态词本结构解析',
      );
    } catch (error) {
      return WordbookImportAudit(
        format: 'invalid',
        schemaVersion: '',
        totalRecords: 0,
        acceptedRecords: 0,
        issues: <WordbookImportIssue>[
          WordbookImportIssue(
            severity: 'error',
            code: 'parse_failed',
            path: r'$',
            message: '$error',
          ),
        ],
        note: '导入审计失败',
      );
    }
  }

  WordbookSchemaV1? tryParseStandardWordbook(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, Object?>();
      if (!WordbookSchemaV1.looksLikeStandardWordbook(map)) {
        return null;
      }
      return WordbookSchemaV1.fromJsonMap(map);
    } catch (_) {
      return null;
    }
  }

  List<WordEntryPayload> parseCsvText(String content) {
    final rows = _parseCsvRows(content);
    if (rows.length < 2) return const <WordEntryPayload>[];

    final headers = rows.first
        .map((item) => item.trim())
        .toList(growable: false);
    final wordIndex = headers.indexWhere(
      (header) => _wordAliases.contains(header.toLowerCase()),
    );
    if (wordIndex < 0) return const <WordEntryPayload>[];

    final payloads = <WordEntryPayload>[];
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex += 1) {
      final row = rows[rowIndex];
      if (wordIndex >= row.length) continue;
      final word = row[wordIndex].trim();
      if (word.isEmpty) continue;

      final map = <String, Object?>{headers[wordIndex]: word};
      for (var col = 0; col < headers.length; col += 1) {
        if (col == wordIndex || col >= row.length) continue;
        final key = headers[col].trim();
        if (key.isEmpty) continue;
        final value = row[col].trim();
        if (value.isEmpty) continue;
        map[key] = value;
      }

      final payload = _recordToPayload(map, sortIndex: rowIndex - 1);
      if (payload != null) {
        payloads.add(payload);
      }
    }

    return payloads;
  }

  Future<String> readJsonByteStreamAsString(
    Stream<List<int>> byteStream, {
    bool gzipped = false,
  }) async {
    final decodedStream =
        (gzipped ? byteStream.transform(gzip.decoder) : byteStream).transform(
          utf8.decoder,
        );
    final buffer = StringBuffer();
    await for (final chunk in decodedStream) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  WordbookImportDescriptor _describeJsonMap(
    Map<String, Object?> map, {
    String fallbackName = '',
  }) {
    if (WordbookSchemaV1.looksLikeStandardWordbook(map)) {
      final schema = WordbookSchemaV1.fromJsonMap(map);
      return WordbookImportDescriptor(
        format: wordbookSchemaV1,
        schemaVersion: schema.schemaVersion,
        bookName: schema.book.name,
        metadataJson: jsonEncode(schema.book.toJsonMap()),
        totalRecords: schema.entries.length,
      );
    }

    final metadata = _resolveMetadata(map);
    final container = _resolveRecordContainer(map);
    final metadataJson = metadata == null ? null : jsonEncode(metadata);
    final bookName =
        _readMetadataName(metadata) ??
        (fallbackName.trim().isEmpty ? null : fallbackName.trim());
    return WordbookImportDescriptor(
      format: container == null ? 'json_record' : 'dynamic_json',
      bookName: bookName,
      metadataJson: metadataJson,
      totalRecords: container?.length ?? 1,
    );
  }

  void _ensureStandardWordbookValid(WordbookSchemaV1 schema) {
    final audit = schema.validate();
    if (audit.isValid) {
      return;
    }
    final errors = audit.issues
        .where((item) => item.severity.toLowerCase() == 'error')
        .map((item) => '${item.path}: ${item.message}')
        .toList(growable: false);
    throw FormatException(
      errors.isEmpty ? 'wordbook.v1 校验失败' : errors.join('；'),
    );
  }

  Map<String, Object?>? _resolveMetadata(Map<String, Object?> map) {
    for (final key in _metadataContainerKeys) {
      final value = map[key];
      if (value is Map<String, Object?>) {
        return value;
      }
      if (value is Map) {
        return value.cast<String, Object?>();
      }
    }
    return null;
  }

  String? _readMetadataName(Map<String, Object?>? metadata) {
    if (metadata == null) return null;
    for (final key in <String>['name', 'title', 'book_name', '词本名称', '名称']) {
      final value = sanitizeDisplayText('${metadata[key] ?? ''}');
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  Future<List<WordEntryPayload>> _parseMdxFile(String filePath) async {
    final payloads = <WordEntryPayload>[];
    final dict = DictReader(filePath);

    try {
      await dict.initDict(readKeys: true, readRecordBlockInfo: false);
      var sortIndex = 0;
      await for (final record in dict.readWithMdxData()) {
        final key = record.keyText.trim();
        if (key.isEmpty) continue;

        final content = record.data.replaceAll('\u0000', '').trim();
        final payload = _recordToPayload(<String, Object?>{
          'word': key,
          'content': content,
        }, sortIndex: sortIndex);
        if (payload != null) {
          payloads.add(payload);
          sortIndex += 1;
        }
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
    for (var i = 0; i < normalized.length; i += 1) {
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

  WordEntryPayload? _recordToPayload(
    Map<String, Object?> record, {
    int? sortIndex,
  }) {
    final normalizedRecord = _normalizeRecord(record);
    final word = _extractWord(normalizedRecord);
    if (word.isEmpty) {
      return null;
    }

    final content = _extractContent(normalizedRecord);
    final fields = _buildFieldsFromDynamicRecord(normalizedRecord);
    final primaryGloss = _derivePrimaryGloss(fields, content);
    final entryUid = _deriveEntryUid(normalizedRecord, word);

    return WordEntryPayload(
      word: word,
      fields: fields,
      rawContent: content.isNotEmpty ? content : (primaryGloss ?? ''),
      entryUid: entryUid,
      primaryGloss: primaryGloss,
      sortIndex: sortIndex,
    );
  }

  String _extractWord(Map<String, Object?> record) {
    for (final entry in record.entries) {
      final key = entry.key.trim().toLowerCase();
      if (_wordAliases.contains(key)) {
        final text = sanitizeDisplayText('${entry.value ?? ''}');
        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    final lemma = record['lemma'];
    if (lemma is Map) {
      final lemmaText = sanitizeDisplayText('${lemma['text'] ?? ''}');
      if (lemmaText.isNotEmpty) {
        return lemmaText;
      }
    }

    return '';
  }

  String _extractContent(Map<String, Object?> record) {
    for (final key in _contentFields) {
      final value = record[key];
      if (value == null) continue;
      final text = sanitizeDisplayText('$value');
      if (text.isNotEmpty) {
        return text;
      }
    }

    final glossText = _flattenGlosses(record['glosses']);
    if (glossText.isNotEmpty) {
      return glossText;
    }
    return '';
  }

  List<WordFieldItem> _buildFieldsFromDynamicRecord(
    Map<String, Object?> record,
  ) {
    final dynamicRecord = <String, Object?>{};
    for (final entry in record.entries) {
      final key = entry.key.trim();
      if (key.isEmpty || isWordKey(key) || isContentKey(key)) {
        continue;
      }
      dynamicRecord[key] = entry.value;
    }

    final output = <WordFieldItem>[];
    for (final entry in dynamicRecord.entries) {
      final field = _buildStructuredField(entry.key, entry.value);
      if (field != null) {
        output.add(field);
      }
    }

    return mergeFieldItems(output);
  }

  WordFieldItem? _buildStructuredField(String rawKey, Object? rawValue) {
    final key = normalizeFieldKey(rawKey);
    if (key.isEmpty) {
      return null;
    }

    switch (key) {
      case 'meaning':
        final meaning = _flattenMeaningValue(rawValue);
        if (meaning.isEmpty) return null;
        return WordFieldItem(
          key: key,
          label: legacyFieldLabels[key] ?? 'Meaning',
          value: meaning,
        );
      case 'pronunciations':
        final pronunciation = _flattenPronunciations(rawValue);
        if (pronunciation.item1.isEmpty && pronunciation.item2.isEmpty) {
          return null;
        }
        return WordFieldItem(
          key: key,
          label: legacyFieldLabels[key] ?? 'Pronunciations',
          value: pronunciation.item1,
          media: pronunciation.item2,
        );
      case 'parts_of_speech':
        final rows = _flattenPartsOfSpeech(rawValue);
        if (rows.isEmpty) return null;
        return WordFieldItem(
          key: key,
          label: legacyFieldLabels[key] ?? 'Parts of Speech',
          value: rows,
        );
      case 'examples':
        final rows = _flattenExamples(rawValue);
        if (rows.isEmpty) return null;
        return WordFieldItem(
          key: key,
          label: legacyFieldLabels[key] ?? 'Examples',
          value: rows,
        );
      case 'variations':
        final rows = _flattenForms(rawValue);
        if (rows.isEmpty) return null;
        return WordFieldItem(
          key: key,
          label: legacyFieldLabels[key] ?? 'Variations',
          value: rows,
        );
      case 'glosses':
        final meaning = _flattenGlosses(rawValue);
        if (meaning.isEmpty) return null;
        return WordFieldItem(
          key: 'meaning',
          label: legacyFieldLabels['meaning'] ?? 'Meaning',
          value: meaning,
        );
      case 'collocations':
      case 'phrases':
      case 'synonyms':
      case 'antonyms':
      case 'related':
      case 'derived':
      case 'similar_words':
      case 'morphology':
      case 'tags':
        final rows = _flattenStringList(rawValue);
        if (rows.isEmpty) return null;
        return WordFieldItem(
          key: key,
          label: legacyFieldLabels[key] ?? rawKey.trim(),
          value: rows,
          tags: key == 'tags' ? rows : const <String>[],
        );
      case 'affixes':
        final affixes = _flattenAffixes(rawValue);
        if (affixes.isEmpty) return null;
        return WordFieldItem(
          key: key,
          label: legacyFieldLabels[key] ?? 'Affixes',
          value: affixes,
        );
      default:
        final value = normalizeFieldValue(rawValue);
        if (value == null) return null;
        return WordFieldItem(
          key: key,
          label: legacyFieldLabels[key] ?? rawKey.trim(),
          value: key == 'examples' ? _normalizeExamplesValue(value) : value,
        );
    }
  }

  String _flattenMeaningValue(Object? rawValue) {
    if (rawValue is List) {
      final rows = rawValue
          .map((item) => sanitizeDisplayText('$item'))
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      return rows.join('；');
    }
    return sanitizeDisplayText('$rawValue');
  }

  ({List<String> item1, List<WordFieldMediaItem> item2}) _flattenPronunciations(
    Object? rawValue,
  ) {
    final lines = <String>[];
    final media = <WordFieldMediaItem>[];

    void addLine(String line) {
      final normalized = sanitizeDisplayText(line);
      if (normalized.isEmpty || lines.contains(normalized)) {
        return;
      }
      lines.add(normalized);
    }

    void addMedia(String source, {String label = ''}) {
      final normalized = sanitizeDisplayText(source);
      if (normalized.isEmpty) return;
      media.add(
        WordFieldMediaItem(
          type: WordFieldMediaType.audio,
          source: normalized,
          label: sanitizeDisplayText(label),
        ),
      );
    }

    if (rawValue is List) {
      for (final item in rawValue) {
        if (item is Map) {
          final tags = _flattenStringList(item['tags']);
          final locale = sanitizeDisplayText('${item['locale'] ?? ''}');
          final ipa = sanitizeDisplayText('${item['ipa'] ?? ''}');
          final note = sanitizeDisplayText('${item['note'] ?? ''}');
          final audio = sanitizeDisplayText('${item['audio'] ?? ''}');
          final rhymes = sanitizeDisplayText('${item['rhymes'] ?? ''}');
          final parts = <String>[];
          if (locale.isNotEmpty) parts.add(locale);
          if (ipa.isNotEmpty) parts.add(ipa);
          if (note.isNotEmpty) parts.add(note);
          if (rhymes.isNotEmpty) parts.add('rhymes: $rhymes');
          if (tags.isNotEmpty) parts.add(tags.join(', '));
          if (parts.isNotEmpty) {
            addLine(parts.join(' | '));
          }
          if (audio.isNotEmpty) {
            final mediaLabel = tags.isNotEmpty ? tags.join(', ') : locale;
            addLine([if (mediaLabel.isNotEmpty) mediaLabel, audio].join(': '));
            addMedia(audio, label: mediaLabel);
          }
          continue;
        }
        final text = sanitizeDisplayText('$item');
        if (text.isNotEmpty) {
          addLine(text);
        }
      }
    } else {
      final text = sanitizeDisplayText('$rawValue');
      if (text.isNotEmpty) {
        addLine(text);
      }
    }

    return (item1: lines, item2: _dedupeMedia(media));
  }

  List<String> _flattenPartsOfSpeech(Object? rawValue) {
    if (rawValue is! List) {
      final text = sanitizeDisplayText('$rawValue');
      return text.isEmpty ? const <String>[] : <String>[text];
    }

    final rows = <String>[];
    for (final item in rawValue) {
      if (item is Map) {
        final pos = sanitizeDisplayText('${item['pos'] ?? item['type'] ?? ''}');
        final zh = _flattenStringList(item['zh']);
        final glosses = _flattenGlossGroups(item['sense_groups']);
        final examples = _flattenExamples(item['examples']);
        final segments = <String>[
          if (pos.isNotEmpty) pos,
          if (zh.isNotEmpty) zh.join('；'),
          if (glosses.isNotEmpty) glosses.join('；'),
        ];
        final head = segments.join(' | ').trim();
        if (head.isNotEmpty) {
          rows.add(head);
        }
        for (final example in examples.take(2)) {
          rows.add('例：$example');
        }
        continue;
      }

      final text = sanitizeDisplayText('$item');
      if (text.isNotEmpty) {
        rows.add(text);
      }
    }

    return rows;
  }

  List<String> _flattenExamples(Object? rawValue) {
    if (rawValue is! List) {
      final text = sanitizeDisplayText('$rawValue');
      return text.isEmpty ? const <String>[] : <String>[text];
    }

    final rows = <String>[];
    for (final item in rawValue) {
      if (item is Map) {
        final category = sanitizeDisplayText(
          '${item['category'] ?? item['含义类别'] ?? item['场景类别'] ?? item['类别'] ?? ''}',
        );
        final sourceText = sanitizeDisplayText(
          '${item['source_text'] ?? item['text'] ?? item['例句原文'] ?? item['英文例句'] ?? item['example'] ?? ''}',
        );
        final translation = sanitizeDisplayText(
          '${item['translation'] ?? item['中文翻译'] ?? item['译文'] ?? ''}',
        );
        final parts = <String>[];
        if (sourceText.isNotEmpty) {
          parts.add(category.isEmpty ? sourceText : '[$category] $sourceText');
        }
        if (translation.isNotEmpty) {
          parts.add('中文：$translation');
        }
        final row = parts.join('\n').trim();
        if (row.isNotEmpty) {
          rows.add(row);
        }
        continue;
      }

      final text = sanitizeDisplayText('$item');
      if (text.isNotEmpty) {
        rows.add(text);
      }
    }
    return rows;
  }

  List<String> _flattenStringList(Object? rawValue) {
    if (rawValue is List) {
      return rawValue
          .map((item) => sanitizeDisplayText('$item'))
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final text = sanitizeDisplayText('$rawValue');
    return text.isEmpty ? const <String>[] : <String>[text];
  }

  List<String> _flattenForms(Object? rawValue) {
    if (rawValue is! List) {
      final text = sanitizeDisplayText('$rawValue');
      return text.isEmpty ? const <String>[] : <String>[text];
    }

    final rows = <String>[];
    for (final item in rawValue) {
      if (item is Map) {
        final form = sanitizeDisplayText(
          '${item['form'] ?? item['text'] ?? item['value'] ?? ''}',
        );
        final tags = _flattenStringList(item['tags']);
        final note = sanitizeDisplayText('${item['note'] ?? ''}');
        final parts = <String>[
          if (form.isNotEmpty) form,
          if (tags.isNotEmpty) 'tags: ${tags.join(', ')}',
          if (note.isNotEmpty) note,
        ];
        final row = parts.join(' | ').trim();
        if (row.isNotEmpty) {
          rows.add(row);
        }
        continue;
      }

      final text = sanitizeDisplayText('$item');
      if (text.isNotEmpty) {
        rows.add(text);
      }
    }
    return rows;
  }

  String _flattenAffixes(Object? rawValue) {
    if (rawValue is Map) {
      final prefixes = _flattenStringList(rawValue['prefixes']);
      final suffixes = _flattenStringList(rawValue['suffixes']);
      final rows = <String>[];
      if (prefixes.isNotEmpty) {
        rows.add('prefixes: ${prefixes.join(', ')}');
      }
      if (suffixes.isNotEmpty) {
        rows.add('suffixes: ${suffixes.join(', ')}');
      }
      return rows.join('\n').trim();
    }
    return sanitizeDisplayText('$rawValue');
  }

  List<String> _flattenGlossGroups(Object? rawValue) {
    if (rawValue is! List) {
      return const <String>[];
    }
    final rows = <String>[];
    for (final item in rawValue) {
      if (item is! Map) continue;
      final glosses = item['glosses'];
      if (glosses is! List) continue;
      for (final gloss in glosses) {
        final text = sanitizeDisplayText('$gloss');
        if (text.isNotEmpty) {
          rows.add(text);
        }
      }
    }
    return rows;
  }

  String _flattenGlosses(Object? rawValue) {
    if (rawValue is! List) {
      return '';
    }
    final texts = <String>[];
    for (final item in rawValue) {
      if (item is! Map) continue;
      final text = sanitizeDisplayText('${item['text'] ?? ''}');
      if (text.isNotEmpty) {
        texts.add(text);
      }
    }
    return texts.join('；');
  }

  String? _derivePrimaryGloss(List<WordFieldItem> fields, String rawContent) {
    for (final field in fields) {
      if (field.key != 'meaning') continue;
      final text = field.asText().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    final normalizedRaw = rawContent.trim();
    return normalizedRaw.isEmpty ? null : normalizedRaw;
  }

  String? _deriveEntryUid(Map<String, Object?> record, String word) {
    final rawEntryId = sanitizeDisplayText(
      '${record['entry_id'] ?? record['entryUid'] ?? record['id'] ?? ''}',
    );
    if (rawEntryId.isNotEmpty) {
      return rawEntryId;
    }
    final normalizedWord = sanitizeDisplayText(
      '${record['normalized_word'] ?? ''}',
    );
    if (normalizedWord.isNotEmpty && normalizedWord != word) {
      return '$word::$normalizedWord';
    }
    return null;
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
      '场景化例句' => _flattenExamples(value),
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

  List<WordFieldMediaItem> _dedupeMedia(List<WordFieldMediaItem> items) {
    final seen = <String>{};
    final output = <WordFieldMediaItem>[];
    for (final item in items) {
      final key = '${item.type.name}:${item.source}:${item.label}';
      if (!seen.add(key)) continue;
      output.add(item);
    }
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
