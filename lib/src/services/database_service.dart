import 'dart:convert';
import 'dart:math' as math;
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../models/todo_item.dart';
import '../models/tomato_timer.dart';
import '../models/user_data_export.dart';
import '../models/word_entry.dart';
import '../models/word_field.dart';
import '../models/word_memory_progress.dart';
import '../models/wordbook.dart';
import '../models/export_dto.dart';
import '../models/wordbook_schema_v1.dart';
import '../utils/search_text_normalizer.dart' as search_text;
import 'built_in_wordbook_source.dart';
import 'wordbook_import_service.dart';

part 'database_service_maintenance.dart';
part 'database_service_wordbook_query.dart';
part 'database_service_wordbook_import.dart';
part 'database_service_tasks.dart';
part 'database_service_core.dart';
part 'database_service_schema.dart';

class WordbookMergeResult {
  const WordbookMergeResult({
    required this.total,
    required this.inserted,
    required this.updated,
    required this.sourceWordbookId,
    required this.targetWordbookId,
    required this.deleteSourceAfterMerge,
  });

  final int total;
  final int inserted;
  final int updated;
  final int sourceWordbookId;
  final int targetWordbookId;
  final bool deleteSourceAfterMerge;
}

class DatabaseBackupInfo {
  const DatabaseBackupInfo({
    required this.name,
    required this.path,
    required this.reason,
    required this.modifiedAt,
    required this.sizeBytes,
  });

  final String name;
  final String path;
  final String reason;
  final DateTime modifiedAt;
  final int sizeBytes;

  String get reasonLabel {
    final normalized = reason.trim().replaceAll('_', ' ');
    return normalized.isEmpty ? 'manual' : normalized;
  }
}

class DownloadedAmbientSoundInfo {
  const DownloadedAmbientSoundInfo({
    required this.soundId,
    required this.remoteKey,
    required this.relativePath,
    required this.categoryKey,
    required this.name,
    required this.filePath,
    required this.downloadedAt,
    required this.lastAccessedAt,
  });

  final String soundId;
  final String remoteKey;
  final String relativePath;
  final String categoryKey;
  final String name;
  final String filePath;
  final DateTime downloadedAt;
  final DateTime lastAccessedAt;

  factory DownloadedAmbientSoundInfo.fromMap(Map<String, Object?> map) {
    return DownloadedAmbientSoundInfo(
      soundId: map['sound_id'] as String,
      remoteKey: map['remote_key'] as String,
      relativePath: map['relative_path'] as String,
      categoryKey: map['category_key'] as String,
      name: map['name'] as String,
      filePath: map['file_path'] as String,
      downloadedAt: DateTime.parse(map['downloaded_at'] as String),
      lastAccessedAt: DateTime.parse(map['last_accessed_at'] as String),
    );
  }
}

enum BuiltInWordbookLoadStage { downloading, processing, completed }

class BuiltInWordbookLoadProgress {
  const BuiltInWordbookLoadProgress({
    required this.stage,
    this.progress,
    this.receivedBytes,
    this.totalBytes,
    this.processedEntries,
    this.totalEntries,
  });

  final BuiltInWordbookLoadStage stage;
  final double? progress;
  final int? receivedBytes;
  final int? totalBytes;
  final int? processedEntries;
  final int? totalEntries;
}

typedef BuiltInWordbookLoadProgressCallback =
    void Function(BuiltInWordbookLoadProgress progress);

class _PreparedWordRecord {
  const _PreparedWordRecord({
    required this.row,
    required this.fields,
    required this.entryUid,
    required this.primaryGloss,
    required this.schemaVersion,
    required this.sourcePayloadJson,
    required this.sortIndex,
  });

  final Map<String, Object?> row;
  final List<WordFieldItem> fields;
  final String? entryUid;
  final String? primaryGloss;
  final String? schemaVersion;
  final String? sourcePayloadJson;
  final int sortIndex;
}

class _WordImportInsertStatements {
  _WordImportInsertStatements({
    required this.wordInsert,
    required this.fieldInsert,
    required this.styleInsert,
    required this.tagInsert,
    required this.mediaInsert,
  });

  final PreparedStatement wordInsert;
  final PreparedStatement fieldInsert;
  final PreparedStatement styleInsert;
  final PreparedStatement tagInsert;
  final PreparedStatement mediaInsert;

  void dispose() {
    wordInsert.dispose();
    fieldInsert.dispose();
    styleInsert.dispose();
    tagInsert.dispose();
    mediaInsert.dispose();
  }
}

class AppDatabaseService {
  AppDatabaseService(
    WordbookImportService importService, {
    BuiltInWordbookSource? builtInWordbookSource,
  }) : _importService = importService,
       _builtInWordbookSource =
           builtInWordbookSource ?? const AssetBuiltInWordbookSource();

  final WordbookImportService _importService;
  final BuiltInWordbookSource _builtInWordbookSource;
  final Map<String, Future<int>> _builtInWordbookLoadFutures =
      <String, Future<int>>{};

  late Database _db;
  late final String dbPath;
  bool _initialized = false;
  Future<void>? _initFuture;
  int _transactionDepth = 0;

  static const _specialWordbooks = <String, String>{
    'builtin:favorites': 'Favorites',
    'builtin:task': 'Task',
  };
  static final RegExp _backupFilePattern = RegExp(
    r'^vocabulary_(.+)_(\d{4}-\d{2}-\d{2}T.+)\.db$',
  );
  static final RegExp _windowsReservedFileNamePattern = RegExp(
    r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
    caseSensitive: false,
  );
  static const int _maxSqlVariablesPerStatement = 900;
  static const int _currentSchemaVersion = 9;
  static const String _wordOrderClause = 'sort_index ASC, id ASC';
  static const String _dictBuiltinPathPrefix = 'builtin:dict:';
  static const String _hiddenBuiltInWordbooksSettingKey =
      'hidden_built_in_wordbooks';

  Future<void> init() {
    if (_initialized) {
      return Future<void>.value();
    }
    _initFuture ??= _initImpl();
    return _initFuture!;
  }

  Future<void> _initImpl() async {
    try {
      final supportDir = await getApplicationSupportDirectory();
      if (!await supportDir.exists()) {
        await supportDir.create(recursive: true);
      }
      dbPath = p.join(supportDir.path, 'vocabulary.db');
      _openDatabase();
      await _prepareDatabase();
      _initialized = true;
    } catch (_) {
      try {
        _db.dispose();
      } catch (_) {}
      rethrow;
    } finally {
      if (!_initialized) {
        _initFuture = null;
      }
    }
  }
}
