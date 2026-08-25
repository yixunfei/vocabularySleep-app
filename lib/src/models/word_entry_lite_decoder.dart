import 'word_entry.dart';
import 'word_field.dart';

/// Builds the summary-only representation used while browsing large books.
/// Keeping this decoder outside the database connection lets both the normal
/// and background query paths produce identical `WordEntry` instances.
WordEntry wordEntryFromLiteRow(Map<String, Object?> row) {
  String? nullableText(Object? raw) {
    final text = sanitizeDisplayText('${raw ?? ''}');
    return text.isEmpty ? null : text;
  }

  final resolvedMeaning =
      nullableText(row['primary_gloss']) ?? nullableText(row['meaning']);
  // Lite rows have no field JSON or child-table data. The summary is already
  // fully represented by the selected gloss/meaning columns, so avoid routing
  // each row through the full fields getter and a second copyWith allocation.
  return WordEntry(
    id: (row['id'] as num?)?.toInt(),
    wordbookId: ((row['wordbook_id'] as num?) ?? 0).toInt(),
    word: sanitizeDisplayText('${row['word'] ?? ''}'),
    meaning: resolvedMeaning,
    entryUid: nullableText(row['entry_uid']),
    primaryGloss: nullableText(row['primary_gloss']),
    schemaVersion: nullableText(row['schema_version']),
    sortIndex: (row['sort_index'] as num?)?.toInt(),
    rawContent: resolvedMeaning ?? '',
  );
}
