import '../models/word_entry.dart';
import '../models/wordbook.dart';
import '../services/database_service.dart';

abstract class WordbookRepository {
  String get databasePath;

  bool isLazyBuiltInPath(String path);

  Future<int> ensureBuiltInWordbookLoaded(
    String path, {
    BuiltInWordbookLoadProgressCallback? onProgress,
  });

  Future<void> syncBuiltInWordbooksCatalog();

  List<Wordbook> getWordbooks();

  List<WordEntry> getWords(int wordbookId, {int limit, int offset});

  List<WordEntry> getWordsLite(int wordbookId, {int limit, int offset});

  List<WordEntry> searchWords(
    int wordbookId, {
    required String query,
    required String mode,
    int limit,
    int offset,
  });

  List<WordEntry> searchWordsLite(
    int wordbookId, {
    required String query,
    required String mode,
    int limit,
    int offset,
  });

  WordEntry? hydrateWordEntry(WordEntry entry);

  int countSearchWords(
    int wordbookId, {
    required String query,
    required String mode,
  });

  int? findSearchOffsetByPrefix(
    int wordbookId, {
    required String prefix,
    required String query,
    required String mode,
  });

  int? findSearchOffsetByInitial(
    int wordbookId, {
    required String initial,
    required String query,
    required String mode,
  });

  int? findSearchOffsetByWordId(
    int wordbookId, {
    required int wordId,
    required String query,
    required String mode,
  });

  WordEntry? findJumpWordByPrefix(
    int wordbookId, {
    required String prefix,
    required String query,
    required String mode,
  });

  WordEntry? findJumpWordByInitial(
    int wordbookId, {
    required String initial,
    required String query,
    required String mode,
  });

  int createWordbook(String name);

  void renameWordbook(int wordbookId, String newName);

  void deleteManagedWordbook(int wordbookId);

  Future<int> importWordbookFileAsync({
    required String filePath,
    required String name,
    void Function(int processedEntries, int? totalEntries)? onProgress,
  });

  Future<int> importLegacyDatabase(String legacyDbPath);

  void ensureSpecialWordbooks();

  Future<int> importWordbook({
    required String sourcePath,
    required String name,
    required List<WordEntryPayload> entries,
    bool replaceExisting,
    void Function(int processedEntries, int? totalEntries)? onProgress,
  });

  Future<int> importWordbookAsync({
    required String sourcePath,
    required String name,
    required List<WordEntryPayload> entries,
    bool replaceExisting,
    void Function(int processedEntries, int? totalEntries)? onProgress,
    int yieldEvery,
  });

  void addWord(int wordbookId, WordEntryPayload payload);

  void updateWord({
    required int wordbookId,
    required String sourceWord,
    int? sourceWordId,
    String? sourceEntryUid,
    String? sourcePrimaryGloss,
    required WordEntryPayload payload,
  });

  bool upsertWord(
    int wordbookId,
    WordEntryPayload payload, {
    bool refreshWordbookCount,
  });

  void deleteWord(int wordbookId, String word);

  void deleteWordByEntryIdentity(int wordbookId, WordEntry entry);

  void clearWordbook(int wordbookId);

  int exportWordbook(int sourceWordbookId, String name);

  WordbookMergeResult mergeWordbooks({
    required int sourceWordbookId,
    required int targetWordbookId,
    required bool deleteSourceAfterMerge,
  });
}

class DatabaseWordbookRepository implements WordbookRepository {
  DatabaseWordbookRepository(this._database);

  final AppDatabaseService _database;

  @override
  String get databasePath => _database.dbPath;

  @override
  bool isLazyBuiltInPath(String path) => _database.isLazyBuiltInPath(path);

  @override
  Future<int> ensureBuiltInWordbookLoaded(
    String path, {
    BuiltInWordbookLoadProgressCallback? onProgress,
  }) {
    return _database.ensureBuiltInWordbookLoaded(path, onProgress: onProgress);
  }

  @override
  Future<void> syncBuiltInWordbooksCatalog() {
    return _database.syncBuiltInWordbooksCatalog();
  }

  @override
  List<Wordbook> getWordbooks() => _database.getWordbooks();

  @override
  List<WordEntry> getWords(
    int wordbookId, {
    int limit = 100000,
    int offset = 0,
  }) {
    return _database.getWords(wordbookId, limit: limit, offset: offset);
  }

  @override
  List<WordEntry> getWordsLite(
    int wordbookId, {
    int limit = 100000,
    int offset = 0,
  }) {
    return _database.getWordsLite(wordbookId, limit: limit, offset: offset);
  }

  @override
  List<WordEntry> searchWords(
    int wordbookId, {
    required String query,
    required String mode,
    int limit = 100000,
    int offset = 0,
  }) {
    return _database.searchWords(
      wordbookId,
      query: query,
      mode: mode,
      limit: limit,
      offset: offset,
    );
  }

  @override
  List<WordEntry> searchWordsLite(
    int wordbookId, {
    required String query,
    required String mode,
    int limit = 100000,
    int offset = 0,
  }) {
    return _database.searchWordsLite(
      wordbookId,
      query: query,
      mode: mode,
      limit: limit,
      offset: offset,
    );
  }

  @override
  WordEntry? hydrateWordEntry(WordEntry entry) {
    return _database.hydrateWordEntry(entry);
  }

  @override
  int countSearchWords(
    int wordbookId, {
    required String query,
    required String mode,
  }) {
    return _database.countSearchWords(wordbookId, query: query, mode: mode);
  }

  @override
  int? findSearchOffsetByPrefix(
    int wordbookId, {
    required String prefix,
    required String query,
    required String mode,
  }) {
    return _database.findSearchOffsetByPrefix(
      wordbookId,
      prefix: prefix,
      query: query,
      mode: mode,
    );
  }

  @override
  int? findSearchOffsetByInitial(
    int wordbookId, {
    required String initial,
    required String query,
    required String mode,
  }) {
    return _database.findSearchOffsetByInitial(
      wordbookId,
      initial: initial,
      query: query,
      mode: mode,
    );
  }

  @override
  int? findSearchOffsetByWordId(
    int wordbookId, {
    required int wordId,
    required String query,
    required String mode,
  }) {
    return _database.findSearchOffsetByWordId(
      wordbookId,
      wordId: wordId,
      query: query,
      mode: mode,
    );
  }

  @override
  WordEntry? findJumpWordByPrefix(
    int wordbookId, {
    required String prefix,
    required String query,
    required String mode,
  }) {
    return _database.findJumpWordByPrefix(
      wordbookId,
      prefix: prefix,
      query: query,
      mode: mode,
    );
  }

  @override
  WordEntry? findJumpWordByInitial(
    int wordbookId, {
    required String initial,
    required String query,
    required String mode,
  }) {
    return _database.findJumpWordByInitial(
      wordbookId,
      initial: initial,
      query: query,
      mode: mode,
    );
  }

  @override
  int createWordbook(String name) => _database.createWordbook(name);

  @override
  void renameWordbook(int wordbookId, String newName) {
    _database.renameWordbook(wordbookId, newName);
  }

  @override
  void deleteManagedWordbook(int wordbookId) {
    _database.deleteManagedWordbook(wordbookId);
  }

  @override
  Future<int> importWordbookFileAsync({
    required String filePath,
    required String name,
    void Function(int processedEntries, int? totalEntries)? onProgress,
  }) {
    return _database.importWordbookFileAsync(
      filePath: filePath,
      name: name,
      onProgress: onProgress,
    );
  }

  @override
  Future<int> importLegacyDatabase(String legacyDbPath) {
    return _database.importLegacyDatabase(legacyDbPath);
  }

  @override
  void ensureSpecialWordbooks() {
    _database.ensureSpecialWordbooks();
  }

  @override
  Future<int> importWordbook({
    required String sourcePath,
    required String name,
    required List<WordEntryPayload> entries,
    bool replaceExisting = true,
    void Function(int processedEntries, int? totalEntries)? onProgress,
  }) {
    return _database.importWordbook(
      sourcePath: sourcePath,
      name: name,
      entries: entries,
      replaceExisting: replaceExisting,
      onProgress: onProgress,
    );
  }

  @override
  Future<int> importWordbookAsync({
    required String sourcePath,
    required String name,
    required List<WordEntryPayload> entries,
    bool replaceExisting = true,
    void Function(int processedEntries, int? totalEntries)? onProgress,
    int yieldEvery = 180,
  }) {
    return _database.importWordbookAsync(
      sourcePath: sourcePath,
      name: name,
      entries: entries,
      replaceExisting: replaceExisting,
      onProgress: onProgress,
      yieldEvery: yieldEvery,
    );
  }

  @override
  void addWord(int wordbookId, WordEntryPayload payload) {
    _database.addWord(wordbookId, payload);
  }

  @override
  void updateWord({
    required int wordbookId,
    required String sourceWord,
    int? sourceWordId,
    String? sourceEntryUid,
    String? sourcePrimaryGloss,
    required WordEntryPayload payload,
  }) {
    _database.updateWord(
      wordbookId: wordbookId,
      sourceWord: sourceWord,
      sourceWordId: sourceWordId,
      sourceEntryUid: sourceEntryUid,
      sourcePrimaryGloss: sourcePrimaryGloss,
      payload: payload,
    );
  }

  @override
  bool upsertWord(
    int wordbookId,
    WordEntryPayload payload, {
    bool refreshWordbookCount = true,
  }) {
    return _database.upsertWord(
      wordbookId,
      payload,
      refreshWordbookCount: refreshWordbookCount,
    );
  }

  @override
  void deleteWord(int wordbookId, String word) {
    _database.deleteWord(wordbookId, word);
  }

  @override
  void deleteWordByEntryIdentity(int wordbookId, WordEntry entry) {
    _database.deleteWordByEntryIdentity(wordbookId, entry);
  }

  @override
  void clearWordbook(int wordbookId) {
    _database.clearWordbook(wordbookId);
  }

  @override
  int exportWordbook(int sourceWordbookId, String name) {
    return _database.exportWordbook(sourceWordbookId, name);
  }

  @override
  WordbookMergeResult mergeWordbooks({
    required int sourceWordbookId,
    required int targetWordbookId,
    required bool deleteSourceAfterMerge,
  }) {
    return _database.mergeWordbooks(
      sourceWordbookId: sourceWordbookId,
      targetWordbookId: targetWordbookId,
      deleteSourceAfterMerge: deleteSourceAfterMerge,
    );
  }
}
