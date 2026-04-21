import '../models/practice_question_type.dart';
import '../models/practice_session_record.dart';
import '../models/settings_dto.dart';
import '../models/word_entry.dart';
import '../models/word_memory_progress.dart';

/// Owns practice-domain runtime and persisted dashboard state.
///
/// AppState orchestrates IO and cross-domain coordination, while this store
/// keeps mutable practice data in one boundary.
class PracticeStore {
  String dateKey = '';
  int todaySessions = 0;
  int todayReviewed = 0;
  int todayRemembered = 0;
  int totalSessions = 0;
  int totalReviewed = 0;
  int totalRemembered = 0;
  String lastSessionTitle = '';

  List<String> rememberedWords = <String>[];
  List<String> weakWords = <String>[];
  Map<String, List<String>> weakWordReasons = <String, List<String>>{};
  List<PracticeSessionRecord> sessionHistory = <PracticeSessionRecord>[];
  Map<String, int> launchCursors = <String, int>{};

  final Map<String, WordEntry> trackedEntriesByWord = <String, WordEntry>{};
  Map<int, WordMemoryProgress> wordMemoryProgressByWordId =
      <int, WordMemoryProgress>{};

  bool autoAddWeakWordsToTask = false;
  bool autoPlayPronunciation = false;
  bool showHintsByDefault = false;
  bool showAnswerFeedbackDialog = true;
  PracticeQuestionType defaultQuestionType = PracticeQuestionType.flashcard;
  PracticeRoundSettings roundSettings = PracticeRoundSettings.defaults;
}
