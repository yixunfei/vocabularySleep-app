import 'package:flutter/foundation.dart';

@immutable
class WordbookLoadProgressSnapshot {
  const WordbookLoadProgressSnapshot({
    required this.active,
    required this.name,
    required this.detail,
    required this.progress,
  });

  static const idle = WordbookLoadProgressSnapshot(
    active: false,
    name: '',
    detail: '',
    progress: null,
  );

  final bool active;
  final String name;
  final String detail;
  final double? progress;

  @override
  bool operator ==(Object other) {
    return other is WordbookLoadProgressSnapshot &&
        other.active == active &&
        other.name == name &&
        other.detail == detail &&
        other.progress == progress;
  }

  @override
  int get hashCode => Object.hash(active, name, detail, progress);
}

class WordbookLoadStore extends ValueNotifier<WordbookLoadProgressSnapshot> {
  WordbookLoadStore() : super(WordbookLoadProgressSnapshot.idle);

  void start({required String name, required String detail}) {
    value = WordbookLoadProgressSnapshot(
      active: true,
      name: name,
      detail: detail,
      progress: 0,
    );
  }

  void update({required String detail, required double? progress}) {
    final current = value;
    value = WordbookLoadProgressSnapshot(
      active: true,
      name: current.name,
      detail: detail,
      progress: progress?.clamp(0.0, 1.0).toDouble(),
    );
  }

  void finish() {
    value = WordbookLoadProgressSnapshot.idle;
  }
}
