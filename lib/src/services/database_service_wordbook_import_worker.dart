part of 'database_service.dart';

typedef _WordbookJsonImportWorkerRequest = ({
  String dbPath,
  String sourcePath,
  String name,
  String? content,
  String? filePath,
  TransferableTypedData? encodedBytes,
  bool gzipped,
  SendPort progressPort,
});

typedef _WordbookJsonImportWorkerResult = ({int imported, int total});

_WordbookJsonImportWorkerResult _runWordbookJsonImportWorker(
  _WordbookJsonImportWorkerRequest request,
) {
  final content = _resolveWordbookJsonImportContent(request);
  final importService = WordbookImportService();
  final prepared = importService.prepareJsonImport(
    content,
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

String _resolveWordbookJsonImportContent(
  _WordbookJsonImportWorkerRequest request,
) {
  final directContent = request.content;
  if (directContent != null) {
    return directContent;
  }

  final filePath = request.filePath;
  final encodedBytes = filePath != null
      ? File(filePath).readAsBytesSync()
      : request.encodedBytes?.materialize().asUint8List();
  if (encodedBytes == null) {
    throw ArgumentError('Wordbook import worker requires JSON input.');
  }
  final jsonBytes = request.gzipped ? gzip.decode(encodedBytes) : encodedBytes;
  return utf8.decode(jsonBytes);
}

Future<_WordbookJsonImportWorkerResult?> _tryRunWordbookJsonImportWorker({
  required String dbPath,
  required String sourcePath,
  required String name,
  String? content,
  String? filePath,
  TransferableTypedData? encodedBytes,
  bool gzipped = false,
  void Function(int processedEntries, int? totalEntries)? onProgress,
}) async {
  final progressPort = ReceivePort();
  var lastProgress = 0;
  int? lastTotal;
  final progressSubscription = progressPort.listen((message) {
    if (message is! List || message.length < 2) return;
    final processed = message[0];
    final total = message[1];
    if (processed is int && (total is int || total == null)) {
      lastProgress = processed;
      lastTotal = total;
      onProgress?.call(processed, total);
    }
  });
  try {
    final result =
        await compute<
          _WordbookJsonImportWorkerRequest,
          _WordbookJsonImportWorkerResult
        >(_runWordbookJsonImportWorker, (
          dbPath: dbPath,
          sourcePath: sourcePath,
          name: name,
          content: content,
          filePath: filePath,
          encodedBytes: encodedBytes,
          gzipped: gzipped,
          progressPort: progressPort.sendPort,
        ), debugLabel: 'wordbook-json-import-write');
    if (onProgress != null &&
        (lastProgress != result.total || lastTotal != result.total)) {
      onProgress(result.total, result.total);
    }
    return result;
  } catch (_) {
    // The worker transaction rolls back on failure. The caller can continue
    // through the compatibility path for unsupported isolate/FFI platforms.
    return null;
  } finally {
    await progressSubscription.cancel();
    progressPort.close();
  }
}
