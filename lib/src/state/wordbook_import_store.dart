import 'package:flutter/foundation.dart';

@immutable
class WordbookImportProgressSnapshot {
  const WordbookImportProgressSnapshot({
    required this.active,
    required this.name,
    required this.processedEntries,
    required this.totalEntries,
  });

  static const idle = WordbookImportProgressSnapshot(
    active: false,
    name: '',
    processedEntries: 0,
    totalEntries: null,
  );

  final bool active;
  final String name;
  final int processedEntries;
  final int? totalEntries;

  double? get progress {
    final total = totalEntries;
    if (!active || total == null || total <= 0) {
      return null;
    }
    return (processedEntries / total).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) {
    return other is WordbookImportProgressSnapshot &&
        other.active == active &&
        other.name == name &&
        other.processedEntries == processedEntries &&
        other.totalEntries == totalEntries;
  }

  @override
  int get hashCode => Object.hash(active, name, processedEntries, totalEntries);
}

class WordbookImportStore
    extends ValueNotifier<WordbookImportProgressSnapshot> {
  WordbookImportStore() : super(WordbookImportProgressSnapshot.idle);

  void start(String name) {
    value = WordbookImportProgressSnapshot(
      active: true,
      name: name,
      processedEntries: 0,
      totalEntries: null,
    );
  }

  void update({required int processedEntries, required int? totalEntries}) {
    final current = value;
    value = WordbookImportProgressSnapshot(
      active: true,
      name: current.name,
      processedEntries: processedEntries < 0 ? 0 : processedEntries,
      totalEntries: totalEntries == null || totalEntries < 0
          ? null
          : totalEntries,
    );
  }

  void finish() {
    value = WordbookImportProgressSnapshot.idle;
  }
}
