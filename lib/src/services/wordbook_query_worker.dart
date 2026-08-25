import 'dart:async';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

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

List<Map<String, Object?>> _readWordbookLiteRows({
  required String databasePath,
  required int wordbookId,
  required int limit,
  required int offset,
}) {
  final database = sqlite3.open(databasePath, mode: OpenMode.readOnly);
  try {
    database.execute('PRAGMA query_only = ON;');
    database.execute('PRAGMA busy_timeout = 5000;');
    final rows = database.select(
      '''
      SELECT
        id,
        wordbook_id,
        word,
        meaning,
        entry_uid,
        primary_gloss,
        schema_version,
        sort_index
      FROM words
      WHERE wordbook_id = ?
      ORDER BY sort_index ASC, id ASC
      LIMIT ? OFFSET ?
      ''',
      <Object?>[wordbookId, limit, offset],
    );
    return rows
        .map((row) => Map<String, Object?>.from(row))
        .toList(growable: false);
  } finally {
    database.dispose();
  }
}
