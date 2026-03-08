class Wordbook {
  const Wordbook({
    required this.id,
    required this.name,
    required this.path,
    required this.wordCount,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String path;
  final int wordCount;
  final DateTime? createdAt;

  bool get isSystem => path.startsWith('builtin:');
  bool get isSpecial => path == 'builtin:favorites' || path == 'builtin:task';

  factory Wordbook.fromMap(Map<String, Object?> map) {
    DateTime? createdAt;
    final rawCreatedAt = map['created_at']?.toString();
    if (rawCreatedAt != null && rawCreatedAt.isNotEmpty) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }

    return Wordbook(
      id: (map['id'] as num).toInt(),
      name: map['name']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      wordCount: ((map['word_count'] as num?) ?? 0).toInt(),
      createdAt: createdAt,
    );
  }
}
