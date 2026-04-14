part of 'practice_session_page.dart';

class _PracticeAnswerDecision {
  const _PracticeAnswerDecision({
    this.addToWrongNotebook = true,
    this.weakReasonIds = const <String>[],
  });

  final bool addToWrongNotebook;
  final List<String> weakReasonIds;
}

class _PendingPracticeAnswerFeedback {
  const _PendingPracticeAnswerFeedback({
    required this.current,
    required this.remembered,
    required this.addToWrongNotebook,
    required this.weakReasonIds,
  });

  final WordEntry current;
  final bool remembered;
  final bool addToWrongNotebook;
  final List<String> weakReasonIds;

  _PendingPracticeAnswerFeedback copyWith({
    bool? addToWrongNotebook,
    List<String>? weakReasonIds,
  }) {
    return _PendingPracticeAnswerFeedback(
      current: current,
      remembered: remembered,
      addToWrongNotebook: addToWrongNotebook ?? this.addToWrongNotebook,
      weakReasonIds: weakReasonIds ?? this.weakReasonIds,
    );
  }
}

class _PracticeMeaningCandidate {
  const _PracticeMeaningCandidate({
    required this.meaning,
    required this.normalizedMeaning,
  });

  final String meaning;
  final String normalizedMeaning;
}
