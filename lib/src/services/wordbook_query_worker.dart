import 'dart:async';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

import '../models/word_entry.dart';
import '../models/word_entry_lite_decoder.dart';
import 'wordbook_search_query.dart';

const String _wordEntryLiteSelectColumns = '''
  id,
  wordbook_id,
  word,
  meaning,
  entry_uid,
  primary_gloss,
  schema_version,
  sort_index
''';

class WordbookSearchResult {
  const WordbookSearchResult({required this.entries, required this.totalCount});

  final List<WordEntry> entries;
  final int totalCount;
}

/// Reads summary rows on a worker isolate so a large wordbook does not block
/// Flutter's raster/UI isolate while SQLite scans and materializes rows.
Future<List<Map<String, Object?>>> loadWordbookLiteRowsInBackground({
  required String databasePath,
  required int wordbookId,
  int limit = 100000,
  int offset = 0,
}) {
  return Isolate.run(
    () => _readWordbookLiteRows(
      databasePath: databasePath,
      wordbookId: wordbookId,
      limit: limit,
      offset: offset,
    ),
  );
}

/// Reads and decodes summary entries on the worker isolate.
///
/// Returning the final model graph through [Isolate.run] avoids a second
/// large Map traversal on Flutter's UI isolate after SQLite finishes.
Future<List<WordEntry>> loadWordbookLiteEntriesInBackground({
  required String databasePath,
  required int wordbookId,
  int limit = 100000,
  int offset = 0,
}) {
  return Isolate.run(
    () => _readWordbookLiteEntries(
      databasePath: databasePath,
      wordbookId: wordbookId,
      limit: limit,
      offset: offset,
    ),
  );
}

/// Searches and decodes the complete lite result on a short-lived read-only
/// worker. [Isolate.run] transfers the final object graph when the worker exits.
Future<WordbookSearchResult> searchWordbookLiteInBackground({
  required String databasePath,
  required int wordbookId,
  required String query,
  required String mode,
  int limit = 100000,
}) {
  return Isolate.run(
    () => _searchWordbookLite(
      databasePath: databasePath,
      wordbookId: wordbookId,
      query: query,
      mode: mode,
      limit: limit,
    ),
  );
}

WordbookSearchResult _searchWordbookLite({
  required String databasePath,
  required int wordbookId,
  required String query,
  required String mode,
  required int limit,
}) {
  final database = sqlite3.open(databasePath, mode: OpenMode.readOnly);
  try {
    database.execute('PRAGMA query_only = ON;');
    database.execute('PRAGMA busy_timeout = 5000;');
    final plan = buildWordbookSearchSqlPlan(
      wordbookId: wordbookId,
      query: query,
      mode: mode,
    );
    final rows = database.select(
      '''
      SELECT $_wordEntryLiteSelectColumns
      FROM words
      WHERE ${plan.whereClause}
      ORDER BY sort_index ASC, id ASC
      LIMIT ?
      ''',
      <Object?>[...plan.parameters, limit.clamp(0, 100000)],
    );
    final entries = rows
        .map((row) => wordEntryFromLiteRow(Map<String, Object?>.from(row)))
        .toList(growable: false);
    return WordbookSearchResult(entries: entries, totalCount: entries.length);
  } finally {
    database.dispose();
  }
}

List<WordEntry> _readWordbookLiteEntries({
  required String databasePath,
  required int wordbookId,
  required int limit,
  required int offset,
}) {
  return _queryWordbookLiteRows(
    databasePath: databasePath,
    wordbookId: wordbookId,
    limit: limit,
    offset: offset,
    decode: (rows) => rows
        .map((row) => wordEntryFromLiteRow(Map<String, Object?>.from(row)))
        .toList(growable: false),
  );
}

List<Map<String, Object?>> _readWordbookLiteRows({
  required String databasePath,
  required int wordbookId,
  required int limit,
  required int offset,
}) {
  return _queryWordbookLiteRows(
    databasePath: databasePath,
    wordbookId: wordbookId,
    limit: limit,
    offset: offset,
    decode: (rows) => rows
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false),
  );
}

T _queryWordbookLiteRows<T>({
  required String databasePath,
  required int wordbookId,
  required int limit,
  required int offset,
  required T Function(ResultSet rows) decode,
}) {
  final database = sqlite3.open(databasePath, mode: OpenMode.readOnly);
  try {
    database.execute('PRAGMA query_only = ON;');
    database.execute('PRAGMA busy_timeout = 5000;');
    final rows = database.select(
      '''
      SELECT
        $_wordEntryLiteSelectColumns
      FROM words
      WHERE wordbook_id = ?
      ORDER BY sort_index ASC, id ASC
      LIMIT ? OFFSET ?
      ''',
      <Object?>[wordbookId, limit, offset],
    );
    return decode(rows);
  } finally {
    database.dispose();
  }
}
