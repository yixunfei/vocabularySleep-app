import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/repositories/settings_store_repository.dart';
import 'package:vocabulary_sleep_app/src/services/app_log_service.dart';
import 'package:vocabulary_sleep_app/src/services/database_service.dart';
import 'package:vocabulary_sleep_app/src/services/secure_key_value_store.dart';
import 'package:vocabulary_sleep_app/src/services/settings_service.dart';
import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';
import 'package:vocabulary_sleep_app/src/utils/play_config_api_key_persistence.dart';

class _MemorySettingsStoreRepository implements SettingsStoreRepository {
  final Map<String, String> _settings = <String, String>{};

  @override
  String? getSetting(String key) => _settings[key];

  @override
  void setSetting(String key, String value) {
    _settings[key] = value;
  }
}

class _MemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String?> values = <String, String?>{};
  bool throwOnWrite = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (throwOnWrite) {
      throw StateError('secure storage unavailable');
    }
    values[key] = value;
  }
}

PlayConfig _configWithKeys({
  String? ttsKey = 'tts-secret',
  String? asrKey = 'asr-secret',
  String? voiceInputKey = 'voice-secret',
}) {
  final config = PlayConfig.defaults;
  return config.copyWith(
    tts: config.tts.copyWith(apiKey: ttsKey),
    asr: config.asr.copyWith(apiKey: asrKey),
    voiceInput: config.voiceInput.copyWith(apiKey: voiceInputKey),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AppLogService.instance.resetForTest();

  group('play config api key persistence helpers', () {
    test('extract finds keys in all three slots', () {
      final raw = jsonEncode(_configWithKeys().toJson());
      final keys = extractPlayConfigApiKeys(raw);
      expect(keys['tts'], 'tts-secret');
      expect(keys['asr'], 'asr-secret');
      expect(keys['voiceInput'], 'voice-secret');
    });

    test('strip removes keys and keeps the rest of the config', () {
      final config = _configWithKeys();
      final strippedRaw = stripPlayConfigApiKeysFromRaw(
        jsonEncode(config.toJson()),
      );
      expect(strippedRaw, isNotNull);
      final strippedConfig = PlayConfig.fromJson(
        (jsonDecode(strippedRaw!) as Map).cast<String, Object?>(),
      );
      expect(strippedConfig.tts.apiKey, isNull);
      expect(strippedConfig.asr.apiKey, isNull);
      expect(strippedConfig.voiceInput.apiKey, isNull);
      // 非敏感字段不受剥离影响。
      expect(strippedConfig.tts.model, config.tts.model);
      expect(strippedConfig.showText, config.showText);
      expect(stripPlayConfigApiKeysFromRaw(strippedRaw), strippedRaw);
    });

    test('inject fills only blank slots', () {
      final json =
          (jsonDecode(jsonEncode(PlayConfig.defaults.copyWith().toJson()))
                  as Map)
              .cast<String, Object?>();
      final changed = injectPlayConfigApiKeys(json, <String, String?>{
        'tts': 'restored',
        'asr': null,
      });
      expect(changed, isTrue);
      expect((json['tts'] as Map)['apiKey'], 'restored');
      expect((json['asr'] as Map)['apiKey'], isNull);
    });

    test('strip keeps invalid JSON untouched as null', () {
      expect(stripPlayConfigApiKeysFromRaw('not-json'), isNull);
      expect(stripPlayConfigApiKeysFromRaw(null), isNull);
    });
  });

  group('SettingsService secure api key round trip', () {
    test('save strips plaintext row and load restores from cache', () async {
      final store = _MemorySettingsStoreRepository();
      final secure = _MemorySecureKeyValueStore();
      final settings = SettingsService.fromRepository(
        store,
        secureKeyValueStore: secure,
      );

      settings.savePlayConfig(_configWithKeys());
      // 持久化行内不应再有明文密钥。
      final rawRow = store.getSetting('playConfig');
      expect(rawRow, isNotNull);
      expect(rawRow, isNot(contains('tts-secret')));
      expect(extractPlayConfigApiKeys(rawRow)['tts'], isNull);

      // 同一实例内（缓存）加载后密钥完整。
      final loaded = settings.loadPlayConfig();
      expect(loaded.tts.apiKey, 'tts-secret');
      expect(loaded.asr.apiKey, 'asr-secret');
      expect(loaded.voiceInput.apiKey, 'voice-secret');

      // 安全存储 blob 已写入。
      await Future<void>.delayed(Duration.zero);
      expect(secure.values[SettingsService.secureApiKeysBlobKey], isNotNull);
    });

    test(
      'prewarm migrates legacy plaintext rows into secure storage',
      () async {
        final store = _MemorySettingsStoreRepository();
        final legacyConfig = _configWithKeys();
        store.setSetting('playConfig', jsonEncode(legacyConfig.toJson()));

        final secure = _MemorySecureKeyValueStore();
        final settings = SettingsService.fromRepository(
          store,
          secureKeyValueStore: secure,
        );
        await settings.prewarmSecureApiKeys();

        // 明文行被剥离，密钥迁入安全存储，加载结果一致。
        expect(store.getSetting('playConfig'), isNot(contains('tts-secret')));
        expect(
          secure.values[SettingsService.secureApiKeysBlobKey],
          contains('tts-secret'),
        );
        final loaded = settings.loadPlayConfig();
        expect(loaded.tts.apiKey, 'tts-secret');
        expect(loaded.asr.apiKey, 'asr-secret');
      },
    );

    test('clearing a key in config clears it everywhere', () async {
      final store = _MemorySettingsStoreRepository();
      final secure = _MemorySecureKeyValueStore();
      final settings = SettingsService.fromRepository(
        store,
        secureKeyValueStore: secure,
      );

      settings.savePlayConfig(_configWithKeys());
      final cleared = _configWithKeys(asrKey: null);
      settings.savePlayConfig(cleared);
      await Future<void>.delayed(Duration.zero);

      final loaded = settings.loadPlayConfig();
      expect(loaded.tts.apiKey, 'tts-secret');
      expect(loaded.asr.apiKey, isNull);
      final blob = secure.values[SettingsService.secureApiKeysBlobKey];
      expect(blob, isNot(contains('asr-secret')));
    });

    test('save degrades to plaintext row when secure storage fails', () async {
      final store = _MemorySettingsStoreRepository();
      final secure = _MemorySecureKeyValueStore()..throwOnWrite = true;
      final settings = SettingsService.fromRepository(
        store,
        secureKeyValueStore: secure,
      );

      settings.savePlayConfig(_configWithKeys());
      // 等待异步降级回写完成。
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final loaded = settings.loadPlayConfig();
      expect(loaded.tts.apiKey, 'tts-secret');
      final rawRow = store.getSetting('playConfig');
      expect(rawRow, contains('tts-secret'));
    });
  });

  group('safety backup strips api keys', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'play_config_backup_test_',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => tempDir.path,
          );
      AppLogService.instance.resetForTest();
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('backup database does not contain plaintext api keys', () async {
      final database = AppDatabaseService(WordbookImportService());
      addTearDown(database.dispose);
      await database.init();

      final store = _MemorySettingsStoreRepository();
      final secure = _MemorySecureKeyValueStore();
      final settings = SettingsService.fromRepository(
        store,
        secureKeyValueStore: secure,
      );
      settings.savePlayConfig(_configWithKeys());

      // 模拟迁移前遗留：直接把明文 JSON 写进真实 settings 表。
      final db = sqlite3.open(database.dbPath);
      db.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [
        'playConfig',
        jsonEncode(_configWithKeys().toJson()),
      ]);
      db.dispose();

      final backupPath = await database.createSafetyBackup(
        reason: 'api_key_strip_test',
      );
      expect(await File(backupPath).exists(), isTrue);

      final backupDb = sqlite3.open(backupPath);
      final rows = backupDb.select(
        "SELECT value FROM settings WHERE key = 'playConfig'",
      );
      backupDb.dispose();
      expect(rows, isNotEmpty);
      final value = rows.first['value']?.toString() ?? '';
      expect(value, isNot(contains('tts-secret')));
      expect(value, isNot(contains('asr-secret')));
      expect(value, isNot(contains('voice-secret')));
    });
  });
}
