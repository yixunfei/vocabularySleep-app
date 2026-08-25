part of 'database_service.dart';

typedef _WordbookJsonImportWorkerRequest = ({
  String dbPath,
  String sourcePath,
  String name,
  String content,
  SendPort progressPort,
});

typedef _WordbookJsonImportWorkerResult = ({int imported, int total});

_WordbookJsonImportWorkerResult _runWordbookJsonImportWorker(
  _WordbookJsonImportWorkerRequest request,
) {
  final importService = WordbookImportService();
  final prepared = importService.prepareJsonImport(
    request.content,
    fallbackName: request.name,
  );
  final descriptor = prepared.descriptor;
  final total = descriptor.totalRecords ?? prepared.payloads.length;
  request.progressPort.send(<Object?>[0, total]);

  final database = AppDatabaseService(importService);
  database.dbPath = request.dbPath;
  final workerDb = sqlite3.open(request.dbPath);
  database._db = workerDb;

  try {
    workerDb.execute('PRAGMA busy_timeout = 10000;');
    workerDb.execute('PRAGMA foreign_keys = ON;');
    workerDb.execute('PRAGMA journal_mode = WAL;');
    workerDb.execute('PRAGMA synchronous = NORMAL;');
    final resolvedName = database._resolveImportedWordbookName(
      sourcePath: request.sourcePath,
      requestedName: request.name,
      descriptorName: descriptor.bookName,
    );
    final imported = database._runInTransaction<int>(() {
      final wordbookId = database._upsertImportedWordbookRow(
        sourcePath: request.sourcePath,
        name: resolvedName,
        schemaVersion: descriptor.schemaVersion,
        metadataJson: descriptor.metadataJson,
        replaceExisting: true,
      );
      final statements = database._openWordImportInsertStatements();
      var imported = 0;
      var lastPercent = -1;
      try {
        for (var index = 0; index < prepared.payloads.length; index += 1) {
          if (database._insertWordWithStatements(
            wordbookId,
            prepared.payloads[index],
            statements: statements,
          )) {
            imported += 1;
          }
          final processed = index + 1;
          final percent = total <= 0
              ? 100
              : ((processed * 100) ~/ total).clamp(0, 100);
          if (processed == prepared.payloads.length || percent != lastPercent) {
            lastPercent = percent;
            request.progressPort.send(<Object?>[processed, total]);
          }
        }
      } finally {
        statements.dispose();
      }
      database._refreshWordbookCount(wordbookId);
      return imported;
    });
    return (imported: imported, total: total);
  } finally {
    workerDb.dispose();
  }
}
