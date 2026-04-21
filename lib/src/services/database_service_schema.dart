part of 'database_service.dart';

const List<int> _databaseSchemaMigrationTargets = <int>[
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
];

extension AppDatabaseServiceSchema on AppDatabaseService {
  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS wordbooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT UNIQUE,
        word_count INTEGER DEFAULT 0,
        schema_version TEXT,
        metadata_json TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS words (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        wordbook_id INTEGER NOT NULL,
        entry_uid TEXT,
        word TEXT NOT NULL,
        meaning TEXT,
        primary_gloss TEXT,
        search_word TEXT NOT NULL,
        search_meaning TEXT,
        search_details TEXT,
        search_word_compact TEXT NOT NULL,
        search_details_compact TEXT,
        schema_version TEXT,
        source_payload_json TEXT,
        sort_index INTEGER DEFAULT 0,
        extension_json TEXT,
        entry_json TEXT,
        FOREIGN KEY (wordbook_id) REFERENCES wordbooks(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS word_fields (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        field_key TEXT NOT NULL,
        field_label TEXT NOT NULL,
        field_value_json TEXT NOT NULL,
        style_json TEXT,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS word_field_styles (
        word_field_id INTEGER PRIMARY KEY,
        background_hex TEXT,
        border_hex TEXT,
        text_hex TEXT,
        accent_hex TEXT,
        FOREIGN KEY (word_field_id) REFERENCES word_fields(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS word_field_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_field_id INTEGER NOT NULL,
        tag TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (word_field_id) REFERENCES word_fields(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS word_field_media (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_field_id INTEGER NOT NULL,
        media_type TEXT NOT NULL,
        media_source TEXT NOT NULL,
        media_label TEXT,
        mime_type TEXT,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (word_field_id) REFERENCES word_fields(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS user_marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('new', 'important', 'mastered')),
        note TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
        UNIQUE(word_id, type)
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        times_played INTEGER DEFAULT 0,
        times_correct INTEGER DEFAULT 0,
        last_played DATETIME,
        familiarity REAL DEFAULT 0,
        ease_factor REAL DEFAULT 2.5,
        interval_days INTEGER DEFAULT 0,
        next_review DATETIME,
        consecutive_correct INTEGER DEFAULT 0,
        memory_state TEXT DEFAULT 'new',
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
        UNIQUE(word_id)
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS word_memory_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        event_kind TEXT NOT NULL,
        quality INTEGER DEFAULT 0,
        weak_reasons_json TEXT,
        session_title TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        completed INTEGER DEFAULT 0,
        deferred INTEGER DEFAULT 0,
        priority INTEGER DEFAULT 0,
        category TEXT,
        note TEXT,
        color TEXT,
        sort_order INTEGER DEFAULT 0,
        due_at DATETIME,
        alarm_enabled INTEGER DEFAULT 0,
        sync_to_system_calendar INTEGER DEFAULT 1,
        system_calendar_notification_enabled INTEGER DEFAULT 1,
        system_calendar_notification_minutes_before INTEGER DEFAULT 0,
        system_calendar_alarm_enabled INTEGER DEFAULT 0,
        system_calendar_alarm_minutes_before INTEGER DEFAULT 10,
        created_at DATETIME,
        completed_at DATETIME
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        color TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at DATETIME,
        updated_at DATETIME
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS timer_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time DATETIME NOT NULL,
        duration_minutes INTEGER DEFAULT 0,
        focus_duration_minutes INTEGER DEFAULT 0,
        break_duration_minutes INTEGER DEFAULT 0,
        rounds_completed INTEGER DEFAULT 0,
        focus_minutes INTEGER DEFAULT 25,
        break_minutes INTEGER DEFAULT 5,
        is_partial INTEGER DEFAULT 0
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS downloaded_ambient_sounds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sound_id TEXT NOT NULL UNIQUE,
        remote_key TEXT NOT NULL,
        relative_path TEXT NOT NULL UNIQUE,
        category_key TEXT NOT NULL,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        downloaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_accessed_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_wordbook ON words(wordbook_id);',
    );
    _db.execute('CREATE INDEX IF NOT EXISTS idx_words_word ON words(word);');
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_search_word ON words(wordbook_id, search_word);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_search_meaning ON words(wordbook_id, search_meaning);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_search_details ON words(wordbook_id, search_details);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_search_word_compact ON words(wordbook_id, search_word_compact);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_search_details_compact ON words(wordbook_id, search_details_compact);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_entry_uid ON words(wordbook_id, entry_uid);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_words_sort_index ON words(wordbook_id, sort_index, id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_fields_word ON word_fields(word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_fields_word_sort ON word_fields(word_id, sort_order, id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_fields_key_label_word ON word_fields(field_key, field_label, word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_fields_key_sort ON word_fields(field_key, sort_order, word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_field_tags_field_sort ON word_field_tags(word_field_id, sort_order, id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_field_tags_tag ON word_field_tags(tag, word_field_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_field_media_field_sort ON word_field_media(word_field_id, sort_order, id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_field_media_type_source ON word_field_media(media_type, media_source, word_field_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_marks_word ON user_marks(word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_progress_word ON progress(word_id);',
    );
    _db.execute(
      'CREATE INDEX IF NOT EXISTS idx_word_memory_events_word_time ON word_memory_events(word_id, created_at DESC, id DESC);',
    );
  }

  void _applySchemaMigrations() {
    _assertSchemaMigrationPlanIsCurrent();
    final sourceVersion = _readSchemaVersion();
    final targetVersion = AppDatabaseService._currentSchemaVersion;
    if (sourceVersion > targetVersion) {
      throw StateError(
        'Database schema version $sourceVersion is newer than supported $targetVersion.',
      );
    }
    if (sourceVersion == targetVersion) {
      return;
    }
    _runInTransaction(() {
      for (final version in _databaseSchemaMigrationTargets) {
        if (version <= sourceVersion) {
          continue;
        }
        _applySchemaMigrationStep(version);
        _setSchemaVersion(version);
      }
    });
  }

  void _assertSchemaMigrationPlanIsCurrent() {
    final targetVersion = AppDatabaseService._currentSchemaVersion;
    if (_databaseSchemaMigrationTargets.length != targetVersion) {
      throw StateError(
        'Schema migration plan length (${_databaseSchemaMigrationTargets.length}) '
        'does not match current schema version ($targetVersion).',
      );
    }
    for (var index = 0; index < _databaseSchemaMigrationTargets.length; index += 1) {
      final expected = index + 1;
      if (_databaseSchemaMigrationTargets[index] != expected) {
        throw StateError(
          'Schema migration plan must include contiguous versions. '
          'Expected $expected but found ${_databaseSchemaMigrationTargets[index]}.',
        );
      }
    }
  }

  void _applySchemaMigrationStep(int version) {
    switch (version) {
      case 1:
        _migrateSchemaToV1();
        return;
      case 2:
        _migrateSchemaToV2();
        return;
      case 3:
        _migrateSchemaToV3();
        return;
      case 4:
        _migrateSchemaToV4();
        return;
      case 5:
        _migrateSchemaToV5();
        return;
      case 6:
        _migrateSchemaToV6();
        return;
      case 7:
        _migrateSchemaToV7();
        return;
      case 8:
        _migrateSchemaToV8();
        return;
      case 9:
        _migrateSchemaToV9();
        return;
    }
    throw StateError('Missing schema migration implementation for version $version.');
  }

  void _migrateSchemaToV1() {}

  void _migrateSchemaToV2() {}

  void _migrateSchemaToV3() {}

  void _migrateSchemaToV4() {}

  void _migrateSchemaToV5() {}

  void _migrateSchemaToV6() {}

  void _migrateSchemaToV7() {}

  void _migrateSchemaToV8() {}

  void _migrateSchemaToV9() {}

  void _setSchemaVersion(int version) {
    _db.execute('PRAGMA user_version = $version;');
  }

  int _readSchemaVersion() {
    final row = _db.select('PRAGMA user_version;');
    if (row.isEmpty) {
      return 0;
    }
    return (row.first['user_version'] as num?)?.toInt() ?? 0;
  }
}
