import '../models/todo_item.dart';
import '../models/tomato_timer.dart';
import '../models/wordbook.dart';
import '../models/word_entry.dart';
import '../models/word_memory_progress.dart';

/// Browser storage adapter. It intentionally does not expose a native file
/// path or SQLite handle; the current Web shell uses this for session state.
class AppDatabaseService {
  AppDatabaseService(Object? importService, {Object? builtInWordbookSource});

  final Map<String, String> _settings = <String, String>{};
  final List<TodoItem> _todos = <TodoItem>[];
  final List<PlanNote> _notes = <PlanNote>[];
  final List<TomatoTimerRecord> _timerRecords = <TomatoTimerRecord>[];
  final Map<int, WordMemoryProgress> _memoryProgress =
      <int, WordMemoryProgress>{};
  bool _initialized = false;

  String get dbPath => 'web://vocabulary-sleep';
  bool get initialized => _initialized;

  Future<void> init() async {
    _initialized = true;
  }

  String? getSetting(String key) => _settings[key];
  void setSetting(String key, String value) => _settings[key] = value;

  List<TodoItem> getTodos() => List<TodoItem>.unmodifiable(_todos);
  List<PlanNote> getNotes() => List<PlanNote>.unmodifiable(_notes);
  List<TomatoTimerRecord> getTimerRecords({int limit = 30}) =>
      List<TomatoTimerRecord>.unmodifiable(_timerRecords.take(limit));
  List<Wordbook> getWordbooks() => const <Wordbook>[];
  List<WordEntry> getWords(int wordbookId, {int limit = 100, int offset = 0}) =>
      const <WordEntry>[];
  Map<int, WordMemoryProgress> getWordMemoryProgressByWordIds(
    Iterable<int> wordIds,
  ) => <int, WordMemoryProgress>{
    for (final id in wordIds)
      if (_memoryProgress.containsKey(id)) id: _memoryProgress[id]!,
  };

  Future<void> dispose() async {
    _initialized = false;
  }
}
