class WordMemoryProgress {
  const WordMemoryProgress({
    required this.wordId,
    this.timesPlayed = 0,
    this.timesCorrect = 0,
    this.lastPlayed,
    this.familiarity = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.nextReview,
    this.consecutiveCorrect = 0,
    this.memoryState = 'new',
  });

  final int wordId;
  final int timesPlayed;
  final int timesCorrect;
  final DateTime? lastPlayed;
  final double familiarity;
  final double easeFactor;
  final int intervalDays;
  final DateTime? nextReview;
  final int consecutiveCorrect;
  final String memoryState;

  bool get isTracked => timesPlayed > 0;

  factory WordMemoryProgress.fromMap(Map<String, Object?> map) {
    return WordMemoryProgress(
      wordId: ((map['word_id'] as num?) ?? 0).toInt(),
      timesPlayed: ((map['times_played'] as num?) ?? 0).toInt(),
      timesCorrect: ((map['times_correct'] as num?) ?? 0).toInt(),
      lastPlayed: map['last_played'] == null
          ? null
          : DateTime.tryParse('${map['last_played']}'),
      familiarity: ((map['familiarity'] as num?) ?? 0).toDouble(),
      easeFactor: ((map['ease_factor'] as num?) ?? 2.5).toDouble(),
      intervalDays: ((map['interval_days'] as num?) ?? 0).toInt(),
      nextReview: map['next_review'] == null
          ? null
          : DateTime.tryParse('${map['next_review']}'),
      consecutiveCorrect: ((map['consecutive_correct'] as num?) ?? 0).toInt(),
      memoryState: ('${map['memory_state'] ?? 'new'}').trim().isEmpty
          ? 'new'
          : '${map['memory_state']}',
    );
  }

  WordMemoryProgress copyWith({
    int? wordId,
    int? timesPlayed,
    int? timesCorrect,
    Object? lastPlayed = _unset,
    double? familiarity,
    double? easeFactor,
    int? intervalDays,
    Object? nextReview = _unset,
    int? consecutiveCorrect,
    String? memoryState,
  }) {
    return WordMemoryProgress(
      wordId: wordId ?? this.wordId,
      timesPlayed: timesPlayed ?? this.timesPlayed,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      lastPlayed: identical(lastPlayed, _unset)
          ? this.lastPlayed
          : lastPlayed as DateTime?,
      familiarity: familiarity ?? this.familiarity,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReview: identical(nextReview, _unset)
          ? this.nextReview
          : nextReview as DateTime?,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      memoryState: memoryState ?? this.memoryState,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'word_id': wordId,
      'times_played': timesPlayed,
      'times_correct': timesCorrect,
      'last_played': lastPlayed?.toIso8601String(),
      'familiarity': familiarity,
      'ease_factor': easeFactor,
      'interval_days': intervalDays,
      'next_review': nextReview?.toIso8601String(),
      'consecutive_correct': consecutiveCorrect,
      'memory_state': memoryState,
    };
  }

  static const Object _unset = Object();
}
