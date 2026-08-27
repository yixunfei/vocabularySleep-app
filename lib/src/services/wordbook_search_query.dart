import '../utils/search_text_normalizer.dart' as search_text;

class WordbookSearchSqlPlan {
  const WordbookSearchSqlPlan({
    required this.whereClause,
    required this.parameters,
  });

  final String whereClause;
  final List<Object?> parameters;
}

WordbookSearchSqlPlan buildWordbookSearchSqlPlan({
  required int wordbookId,
  required String query,
  required String mode,
}) {
  final normalizedQuery = search_text.normalizeSearchText(query);
  if (normalizedQuery.isEmpty) {
    return WordbookSearchSqlPlan(
      whereClause: 'wordbook_id = ?',
      parameters: <Object?>[wordbookId],
    );
  }

  final likeQuery = _buildContainsLikePattern(normalizedQuery);
  final fuzzyLikeQuery = search_text.buildFuzzySqlLikePattern(query);
  final resolvedFuzzyPattern = fuzzyLikeQuery.isEmpty
      ? likeQuery
      : fuzzyLikeQuery;
  return switch (mode.trim()) {
    'word' => WordbookSearchSqlPlan(
      whereClause: 'wordbook_id = ? AND search_word LIKE ?',
      parameters: <Object?>[wordbookId, likeQuery],
    ),
    'meaning' => WordbookSearchSqlPlan(
      whereClause:
          'wordbook_id = ? AND (COALESCE(search_meaning, \'\') LIKE ? OR COALESCE(search_details, \'\') LIKE ?)',
      parameters: <Object?>[wordbookId, likeQuery, likeQuery],
    ),
    'fuzzy' => WordbookSearchSqlPlan(
      whereClause:
          'wordbook_id = ? AND (search_word_compact LIKE ? OR COALESCE(search_details_compact, \'\') LIKE ?)',
      parameters: <Object?>[
        wordbookId,
        resolvedFuzzyPattern,
        resolvedFuzzyPattern,
      ],
    ),
    _ => WordbookSearchSqlPlan(
      whereClause:
          'wordbook_id = ? AND (search_word LIKE ? OR COALESCE(search_meaning, \'\') LIKE ? OR COALESCE(search_details, \'\') LIKE ?)',
      parameters: <Object?>[wordbookId, likeQuery, likeQuery, likeQuery],
    ),
  };
}

String _buildContainsLikePattern(String raw) {
  final escaped = raw
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
  return '%$escaped%';
}
