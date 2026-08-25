part of 'wordbook_import_service.dart';

class PreparedWordbookJsonImport {
  const PreparedWordbookJsonImport({
    required this.descriptor,
    required this.payloads,
  });

  final WordbookImportDescriptor descriptor;
  final List<WordEntryPayload> payloads;
}

PreparedWordbookJsonImport _prepareWordbookJsonImportInWorker(
  ({String content, String fallbackName}) request,
) {
  return _prepareWordbookJsonImport(
    WordbookImportService(),
    request.content,
    fallbackName: request.fallbackName,
  );
}

PreparedWordbookJsonImport _prepareWordbookJsonImport(
  WordbookImportService service,
  String content, {
  required String fallbackName,
}) {
  Object? decoded;
  try {
    decoded = jsonDecode(content);
  } catch (_) {
    final records = _parseJsonRecordChunks(content);
    return PreparedWordbookJsonImport(
      descriptor: WordbookImportDescriptor(
        format: 'json_records',
        totalRecords: records.length,
      ),
      payloads: _payloadsFromJsonRecords(service, records),
    );
  }

  if (decoded is List) {
    return PreparedWordbookJsonImport(
      descriptor: WordbookImportDescriptor(
        format: 'json_array',
        totalRecords: decoded.length,
      ),
      payloads: _payloadsFromJsonRecords(service, decoded),
    );
  }

  if (decoded is Map) {
    final map = decoded.cast<String, Object?>();
    if (WordbookSchemaV1.looksLikeStandardWordbook(map)) {
      final schema = WordbookSchemaV1.fromJsonMap(map);
      service._ensureStandardWordbookValid(schema);
      return PreparedWordbookJsonImport(
        descriptor: WordbookImportDescriptor(
          format: wordbookSchemaV1,
          schemaVersion: schema.schemaVersion,
          bookName: schema.book.name,
          metadataJson: jsonEncode(schema.book.toJsonMap()),
          totalRecords: schema.entries.length,
        ),
        payloads: schema.toPayloads(),
      );
    }

    final container = _resolveRecordContainer(map);
    return PreparedWordbookJsonImport(
      descriptor: service._describeJsonMap(map, fallbackName: fallbackName),
      payloads: _payloadsFromJsonRecords(service, container ?? <Object?>[map]),
    );
  }

  return const PreparedWordbookJsonImport(
    descriptor: WordbookImportDescriptor(
      format: 'json_records',
      totalRecords: 0,
    ),
    payloads: <WordEntryPayload>[],
  );
}

List<WordEntryPayload> _payloadsFromJsonRecords(
  WordbookImportService service,
  Iterable<Object?> records,
) {
  final payloads = <WordEntryPayload>[];
  var index = 0;
  for (final value in records) {
    Map<String, Object?>? record;
    if (value is Map<String, Object?>) {
      record = value;
    } else if (value is Map) {
      record = value.cast<String, Object?>();
    }
    if (record != null) {
      final payload = service._recordToPayload(record, sortIndex: index);
      if (payload != null) {
        payloads.add(payload);
      }
    }
    index += 1;
  }
  return List<WordEntryPayload>.unmodifiable(payloads);
}

List<Map<String, Object?>> _parseJsonRecordChunks(String content) {
  final records = <Map<String, Object?>>[];
  final lines = content.split(RegExp(r'\r?\n'));
  var depth = 0;
  final buffer = StringBuffer();

  void push(Object? value) {
    if (value is Map<String, Object?>) {
      records.add(value);
    } else if (value is Map) {
      records.add(value.cast<String, Object?>());
    }
  }

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
      push(jsonDecode(chunk));
    } catch (_) {
      // Keep compatibility with the permissive JSONL importer.
    }
  }
  return records;
}
