class PracticeSessionRecord {
  const PracticeSessionRecord({
    required this.title,
    required this.practicedAt,
    required this.total,
    required this.remembered,
    this.weakReasonCounts = const <String, int>{},
  });

  final String title;
  final DateTime practicedAt;
  final int total;
  final int remembered;
  final Map<String, int> weakReasonCounts;

  int get weakCount => (total - remembered).clamp(0, total);
  double get accuracy => total <= 0 ? 0 : (remembered / total).clamp(0.0, 1.0);

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'practicedAt': practicedAt.toIso8601String(),
      'total': total,
      'remembered': remembered,
      'weakReasonCounts': weakReasonCounts,
    };
  }

  factory PracticeSessionRecord.fromMap(Map<String, Object?> map) {
    final rawReasonCounts = map['weakReasonCounts'];
    final parsedReasonCounts = <String, int>{};
    if (rawReasonCounts is Map) {
      for (final entry in rawReasonCounts.entries) {
        final key = '${entry.key}'.trim();
        if (key.isEmpty) {
          continue;
        }
        final value = switch (entry.value) {
          int() => entry.value as int,
          num() => (entry.value as num).toInt(),
          _ => int.tryParse('${entry.value}') ?? 0,
        };
        if (value > 0) {
          parsedReasonCounts[key] = value;
        }
      }
    }
    final practicedAt =
        DateTime.tryParse('${map['practicedAt'] ?? ''}') ?? DateTime.now();
    final total = switch (map['total']) {
      int() => map['total'] as int,
      num() => (map['total'] as num).toInt(),
      _ => int.tryParse('${map['total']}') ?? 0,
    };
    final remembered = switch (map['remembered']) {
      int() => map['remembered'] as int,
      num() => (map['remembered'] as num).toInt(),
      _ => int.tryParse('${map['remembered']}') ?? 0,
    };
    return PracticeSessionRecord(
      title: '${map['title'] ?? ''}'.trim(),
      practicedAt: practicedAt,
      total: total < 0 ? 0 : total,
      remembered: remembered < 0 ? 0 : remembered,
      weakReasonCounts: parsedReasonCounts,
    );
  }
}

const List<String> practiceWeakReasonIds = <String>[
  'recall',
  'meaning',
  'pronunciation',
  'spelling',
];
