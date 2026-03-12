import 'dart:convert';
import 'dart:io';

import 'package:dict_reader/dict_reader.dart';

import '../models/word_entry.dart';
import '../models/word_field.dart';

class WordbookImportService {
  static const Set<String> _wordAliases = <String>{
    'word',
    'term',
    'vocabulary',
    'headword',
    'title',
    '单词',
    '词汇',
  };

  static const List<String> _contentFields = <String>[
    'content',
    'raw_content',
    'definition',
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
        return parseJsonText(content);
      case '.csv':
        return parseCsvText(content);
      default:
        return parseJsonText(content);
    }
  }

  List<WordEntryPayload> parseJsonText(String content) {
    final payloads = <WordEntryPayload>[];

    void push(Map<String, Object?>? record) {
      if (record == null) return;
      final payload = _recordToPayload(record);
      if (payload != null) payloads.add(payload);
    }

    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) push(item.cast<String, Object?>());
        }
        return payloads;
      }

      if (decoded is Map) {
        if (decoded['words'] is List) {
          for (final item in decoded['words'] as List) {
            if (item is Map) push(item.cast<String, Object?>());
          }
        } else {
          push(decoded.cast<String, Object?>());
        }
        return payloads;
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
          if (decoded is Map) push(decoded.cast<String, Object?>());
        } catch (_) {
          // Ignore malformed rows.
        }
      }
    }

    return payloads;
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
    String word = '';
    for (final entry in record.entries) {
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
      final value = record[key];
      if (value == null) continue;
      final text = sanitizeDisplayText('$value');
      if (text.isEmpty) continue;
      content = text;
      break;
    }

    final recordFields = buildFieldItemsFromRecord(record);
    final contentFields = content.isNotEmpty
        ? parseSectionedContent(content)
        : const <WordFieldItem>[];
    final fields = mergeFieldItems(<WordFieldItem>[
      ...recordFields,
      ...contentFields,
    ]);

    return WordEntryPayload(word: word, fields: fields, rawContent: content);
  }
}
