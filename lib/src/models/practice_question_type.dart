enum PracticeQuestionType {
  flashcard,
  meaningChoice,
  spelling,
  mixed;

  String get storageValue => switch (this) {
    PracticeQuestionType.flashcard => 'flashcard',
    PracticeQuestionType.meaningChoice => 'meaning_choice',
    PracticeQuestionType.spelling => 'spelling',
    PracticeQuestionType.mixed => 'mixed',
  };

  static PracticeQuestionType fromStorage(String? raw) {
    return switch ((raw ?? '').trim()) {
      'meaning_choice' => PracticeQuestionType.meaningChoice,
      'spelling' => PracticeQuestionType.spelling,
      'mixed' => PracticeQuestionType.mixed,
      _ => PracticeQuestionType.flashcard,
    };
  }
}
