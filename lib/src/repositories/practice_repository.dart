import '../models/word_memory_progress.dart';
import '../services/database_service.dart';

abstract class PracticeRepository {
  Map<int, WordMemoryProgress> getWordMemoryProgressByWordIds(
    Iterable<int> wordIds,
  );

  void upsertWordMemoryProgress(WordMemoryProgress progress);

  void insertWordMemoryEvent({
    required int wordId,
    required String eventKind,
    required int quality,
    List<String> weakReasonIds,
    String? sessionTitle,
    DateTime? createdAt,
  });

  Future<String> writeTextExport({
    required String contents,
    required String defaultFileStem,
    required String extension,
    String? directoryPath,
    String? fileName,
  });
}

class DatabasePracticeRepository implements PracticeRepository {
  DatabasePracticeRepository(this._database);

  final AppDatabaseService _database;

  @override
  Map<int, WordMemoryProgress> getWordMemoryProgressByWordIds(
    Iterable<int> wordIds,
  ) {
    return _database.getWordMemoryProgressByWordIds(wordIds);
  }

  @override
  void upsertWordMemoryProgress(WordMemoryProgress progress) {
    _database.upsertWordMemoryProgress(progress);
  }

  @override
  void insertWordMemoryEvent({
    required int wordId,
    required String eventKind,
    required int quality,
    List<String> weakReasonIds = const <String>[],
    String? sessionTitle,
    DateTime? createdAt,
  }) {
    _database.insertWordMemoryEvent(
      wordId: wordId,
      eventKind: eventKind,
      quality: quality,
      weakReasonIds: weakReasonIds,
      sessionTitle: sessionTitle,
      createdAt: createdAt,
    );
  }

  @override
  Future<String> writeTextExport({
    required String contents,
    required String defaultFileStem,
    required String extension,
    String? directoryPath,
    String? fileName,
  }) {
    return _database.writeTextExport(
      contents: contents,
      defaultFileStem: defaultFileStem,
      extension: extension,
      directoryPath: directoryPath,
      fileName: fileName,
    );
  }
}
