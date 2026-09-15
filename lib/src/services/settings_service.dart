import 'dart:async';
import 'dart:convert';

import '../core/module_system/module_toggle_state.dart';
import '../models/ambient_preset.dart';
import '../models/app_home_tab.dart';
import '../models/focus_startup_tab.dart';
import '../models/play_config.dart';
import '../models/settings_dto.dart';
import '../models/study_startup_tab.dart';
import '../repositories/settings_store_repository.dart';
import '../utils/play_config_api_key_persistence.dart';
import 'app_log_service.dart';
import 'database_service.dart';
import 'secure_key_value_store.dart';

class SettingsService {
  // [风险] SEC-02: 不能再用 const 构造——实例需持有安全存储缓存，
  // 保证同步的 loadPlayConfig 能取回已迁移到安全存储的 API key。
  SettingsService.fromRepository(
    this._store, {
    SecureKeyValueStore? secureKeyValueStore,
  }) : _secureStore = secureKeyValueStore ?? FlutterSecureKeyValueStore();

  factory SettingsService(AppDatabaseService database) {
    return SettingsService.fromRepository(
      DatabaseSettingsStoreRepository(database),
    );
  }

  static const String uiLanguageSystem = 'system';
  static const String remotePrewarmCompletedKey =
      'remoteResourcePrewarmCompletedV1';
  static const String moduleTogglesKey = 'module_toggles_v1';
  static const String toolboxLayoutKey = 'toolbox_layout_v1';
  static const String todoSystemRemindersEnabledKey =
      'todo_system_reminders_enabled_v1';
  static const String toolboxAutoAdjustSystemVolumeEnabledKey =
      'toolbox_auto_adjust_system_volume_enabled_v1';
  static const String bottomNavigationAutoHideEnabledKey =
      'bottom_navigation_auto_hide_enabled_v1';
  static const String firstRunSetupCompletedKey =
      'first_run_setup_completed_v1';

  /// [风险] SEC-02: TTS/ASR/语音输入的 apiKey 不再明文驻留 playConfig 行，
  /// 统一迁入安全存储 blob；持久化行中只保留占位 null。
  static const String secureApiKeysBlobKey = 'play_config.api_keys.v1';

  final SettingsStoreRepository _store;
  final SecureKeyValueStore _secureStore;

  // 内存缓存：prewarm 后可让同步的 loadPlayConfig 取回密钥；
  // savePlayConfig 同步更新，保证"保存后立即读取"始终拿得到。
  Map<String, String?>? _secureApiKeysCache;
  bool _secureApiKeysPrewarmed = false;
  int _secureApiKeysPersistGeneration = 0;

  /// 启动时预热：读取安全存储 blob 并把遗留明文 key 迁移出 settings 行。
  /// 幂等；迁移遵循"密钥先落安全存储成功，才剥离明文行"的顺序，
  /// 安全存储不可用时保持旧行为并记录日志。
  Future<void> prewarmSecureApiKeys() async {
    if (_secureApiKeysPrewarmed) return;
    _secureApiKeysPrewarmed = true;
    try {
      final blob = await _secureStore.read(secureApiKeysBlobKey);
      if (blob != null && blob.trim().isNotEmpty) {
        final decoded = jsonDecode(blob);
        if (decoded is Map) {
          _secureApiKeysCache = decoded.map<String, String?>(
            (key, value) => MapEntry('$key', value?.toString()),
          );
        }
      }
    } catch (error, stackTrace) {
      _logSecureStoreFailure('read', error, stackTrace);
    }
    await _migrateLegacyPlaintextApiKeys();
  }

  Future<void> _migrateLegacyPlaintextApiKeys() async {
    try {
      final raw = _store.getSetting(playConfigSettingKey);
      final legacy = extractPlayConfigApiKeys(raw);
      final hasLegacy = legacy.values.any(
        (value) => value != null && value.trim().isNotEmpty,
      );
      if (!hasLegacy) return;
      final merged = <String, String?>{...?_secureApiKeysCache, ...legacy};
      await _secureStore.write(secureApiKeysBlobKey, jsonEncode(merged));
      _secureApiKeysCache = merged;
      final stripped = stripPlayConfigApiKeysFromRaw(raw);
      if (stripped != null) {
        _store.setSetting(playConfigSettingKey, stripped);
      }
      AppLogService.instance.d(
        'SettingsService',
        'API keys migrated to secure storage',
      );
    } catch (error, stackTrace) {
      // 安全存储不可用：保留明文行（旧行为），避免用户凭据无法读取。
      _logSecureStoreFailure('migrate', error, stackTrace);
    }
  }

  PlayConfig loadPlayConfig() {
    final raw = _store.getSetting(playConfigSettingKey);
    if (raw == null || raw.trim().isEmpty) return PlayConfig.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final json = decoded.cast<String, Object?>();
        final cache = _secureApiKeysCache;
        if (cache != null) {
          injectPlayConfigApiKeys(json, cache);
        }
        return PlayConfig.fromJson(json);
      }
    } catch (_) {
      // ignore invalid JSON and fallback to defaults.
    }
    return PlayConfig.defaults;
  }

  void savePlayConfig(PlayConfig config) {
    final json = config.toJson();
    final keys = extractPlayConfigApiKeysFromJson(json);
    // 缓存镜像"最近一次保存"的密钥：UI 清空 key 时必须真正清除，
    // 不能因缓存保旧导致清空操作被静默撤销。
    _secureApiKeysCache = <String, String?>{...?_secureApiKeysCache, ...keys};
    stripPlayConfigApiKeysInJson(json);
    _store.setSetting(playConfigSettingKey, jsonEncode(json));
    unawaited(_persistSecureApiKeys());
  }

  Future<void> _persistSecureApiKeys() async {
    final generation = ++_secureApiKeysPersistGeneration;
    try {
      await _secureStore.write(
        secureApiKeysBlobKey,
        jsonEncode(_secureApiKeysCache ?? <String, String?>{}),
      );
    } catch (error, stackTrace) {
      _logSecureStoreFailure('write', error, stackTrace);
      // 永不把密钥写回 settings 行：安全存储不可用时宁可不持久化，
      // 也不能让数据库备份和导出重新携带明文凭据。
      if (generation == _secureApiKeysPersistGeneration) {
        _secureApiKeysCache = null;
      }
    }
  }

  void _logSecureStoreFailure(
    String operation,
    Object error,
    StackTrace stackTrace,
  ) {
    AppLogService.instance.e(
      'SettingsService',
      'secure api key store $operation failed',
      error: error,
      stackTrace: stackTrace,
    );
  }

  String loadUiLanguage() {
    final raw = _store.getSetting('uiLanguage');
    if (raw == null) return uiLanguageSystem;
    final normalized = raw.trim();
    return normalized.isEmpty ? uiLanguageSystem : normalized;
  }

  void saveUiLanguage(String language) {
    final normalized = language.trim();
    _store.setSetting(
      'uiLanguage',
      normalized.isEmpty ? uiLanguageSystem : normalized,
    );
  }

  AppHomeTab loadStartupPage() {
    return AppHomeTabX.fromStorage(_store.getSetting('startupPage'));
  }

  void saveStartupPage(AppHomeTab page) {
    _store.setSetting('startupPage', page.storageValue);
  }

  FocusStartupTab loadFocusStartupTab() {
    return FocusStartupTabX.fromStorage(_store.getSetting('focusStartupTab'));
  }

  void saveFocusStartupTab(FocusStartupTab tab) {
    _store.setSetting('focusStartupTab', tab.storageValue);
  }

  StudyStartupTab loadStudyStartupTab() {
    final stored = _store.getSetting('studyStartupTab');
    if (stored != null && stored.trim().isNotEmpty) {
      return StudyStartupTabX.fromStorage(stored);
    }
    final legacyStartup = _store.getSetting('startupPage');
    if ((legacyStartup ?? '').trim() == 'library') {
      return StudyStartupTab.library;
    }
    return StudyStartupTab.play;
  }

  void saveStudyStartupTab(StudyStartupTab tab) {
    _store.setSetting('studyStartupTab', tab.storageValue);
  }

  bool loadWeatherEnabled() {
    return _store.getSetting('weatherEnabled') == '1';
  }

  void saveWeatherEnabled(bool enabled) {
    _store.setSetting('weatherEnabled', enabled ? '1' : '0');
  }

  bool loadStartupTodoPromptEnabled() {
    final raw = _store.getSetting('startupTodoPromptEnabled');
    if (raw == null || raw.trim().isEmpty) {
      return true;
    }
    return raw.trim() == '1';
  }

  void saveStartupTodoPromptEnabled(bool enabled) {
    _store.setSetting('startupTodoPromptEnabled', enabled ? '1' : '0');
  }

  bool loadTodoSystemRemindersEnabled() {
    return _store.getSetting(todoSystemRemindersEnabledKey) == '1';
  }

  void saveTodoSystemRemindersEnabled(bool enabled) {
    _store.setSetting(todoSystemRemindersEnabledKey, enabled ? '1' : '0');
  }

  bool loadToolboxAutoAdjustSystemVolumeEnabled() {
    return _store.getSetting(toolboxAutoAdjustSystemVolumeEnabledKey) == '1';
  }

  void saveToolboxAutoAdjustSystemVolumeEnabled(bool enabled) {
    _store.setSetting(
      toolboxAutoAdjustSystemVolumeEnabledKey,
      enabled ? '1' : '0',
    );
  }

  bool loadBottomNavigationAutoHideEnabled() {
    return _store.getSetting(bottomNavigationAutoHideEnabledKey) == '1';
  }

  void saveBottomNavigationAutoHideEnabled(bool enabled) {
    _store.setSetting(bottomNavigationAutoHideEnabledKey, enabled ? '1' : '0');
  }

  bool loadFirstRunSetupCompleted() {
    final raw = _store.getSetting(firstRunSetupCompletedKey);
    if (raw != null && raw.trim().isNotEmpty) {
      return raw.trim() == '1';
    }
    return _hasExistingSetupState();
  }

  void saveFirstRunSetupCompleted(bool completed) {
    _store.setSetting(firstRunSetupCompletedKey, completed ? '1' : '0');
  }

  bool _hasExistingSetupState() {
    const keys = <String>[
      'playConfig',
      'uiLanguage',
      'startupPage',
      'focusStartupTab',
      'studyStartupTab',
      'weatherEnabled',
      'startupTodoPromptEnabled',
      'startupTodoPromptSuppressedDate',
      'testModeState',
      'practiceDashboard',
      'rememberedWords',
      'playbackProgressByWordbook',
      'ambientPresets',
      'sleepProfile',
      'sleepDailyLogs',
      'sleepCurrentPlan',
      'sleepRoutineTemplates',
      'sleepDashboardState',
      'sleepProgramProgress',
      'tomato_focus_seconds',
      'tomato_break_seconds',
      'tomato_rounds',
      'tomato_reminder_config',
      moduleTogglesKey,
      toolboxLayoutKey,
      todoSystemRemindersEnabledKey,
      toolboxAutoAdjustSystemVolumeEnabledKey,
      bottomNavigationAutoHideEnabledKey,
      remotePrewarmCompletedKey,
    ];
    for (final key in keys) {
      final raw = _store.getSetting(key);
      if (raw != null && raw.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  String? loadStartupTodoPromptSuppressedDate() {
    final raw = _store.getSetting('startupTodoPromptSuppressedDate');
    if (raw == null) {
      return null;
    }
    final normalized = raw.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void saveStartupTodoPromptSuppressedDate(String? dateKey) {
    _store.setSetting('startupTodoPromptSuppressedDate', dateKey?.trim() ?? '');
  }

  TestModeState loadTestModeState() {
    final raw = _store.getSetting('testModeState');
    if (raw == null || raw.trim().isEmpty) {
      return TestModeState.defaults;
    }

    try {
      final decoded = jsonDecode(raw);
      return TestModeState.fromJsonValue(decoded);
    } catch (_) {
      // ignore and fallback.
    }

    return TestModeState.defaults;
  }

  void saveTestModeState(TestModeState state) {
    _store.setSetting('testModeState', jsonEncode(state.toJsonMap()));
  }

  PracticeDashboardState loadPracticeDashboard() {
    final raw = _store.getSetting('practiceDashboard');
    if (raw == null || raw.trim().isEmpty) {
      return PracticeDashboardState.defaults;
    }
    try {
      final decoded = jsonDecode(raw);
      return PracticeDashboardState.fromJsonValue(decoded);
    } catch (_) {
      // ignore and fallback.
    }
    return PracticeDashboardState.defaults;
  }

  void savePracticeDashboard(PracticeDashboardState data) {
    _store.setSetting('practiceDashboard', jsonEncode(data.toJsonMap()));
  }

  Set<String> loadRememberedWords() {
    final raw = _store.getSetting('rememberedWords');
    if (raw == null || raw.trim().isEmpty) {
      return <String>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String>{};
      }
      return decoded
          .map((item) => '$item'.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  void saveRememberedWords(Set<String> words) {
    final sorted = words.toList(growable: false)..sort();
    _store.setSetting('rememberedWords', jsonEncode(sorted));
  }

  Set<String> loadStringSet(String key) {
    final raw = _store.getSetting(key);
    if (raw == null || raw.trim().isEmpty) {
      return <String>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <String>{};
      }
      return decoded
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  void saveStringSet(String key, Set<String> values) {
    final sorted =
        values
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();
    _store.setSetting(key, jsonEncode(sorted));
  }

  Map<String, PlaybackProgressSnapshot> loadPlaybackProgressByWordbook() {
    final raw = _store.getSetting('playbackProgressByWordbook');
    if (raw == null || raw.trim().isEmpty) {
      return const <String, PlaybackProgressSnapshot>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const <String, PlaybackProgressSnapshot>{};
      }
      final output = <String, PlaybackProgressSnapshot>{};
      for (final entry in decoded.entries) {
        final path = '${entry.key}'.trim();
        if (path.isEmpty || entry.value is! Map) {
          continue;
        }
        output[path] = PlaybackProgressSnapshot.fromJsonMap(
          (entry.value as Map).cast<String, Object?>(),
        );
      }
      return output;
    } catch (_) {
      return const <String, PlaybackProgressSnapshot>{};
    }
  }

  void savePlaybackProgressByWordbook(
    Map<String, PlaybackProgressSnapshot> snapshots,
  ) {
    final keys = snapshots.keys.toList(growable: false)..sort();
    _store.setSetting(
      'playbackProgressByWordbook',
      jsonEncode(<String, Object?>{
        for (final key in keys) key: snapshots[key]!.toJsonMap(),
      }),
    );
  }

  List<AmbientPreset> loadAmbientPresets() {
    final raw = _store.getSetting('ambientPresets');
    if (raw == null || raw.trim().isEmpty) {
      return const <AmbientPreset>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <AmbientPreset>[];
      }
      return decoded
          .map(AmbientPreset.fromJsonValue)
          .whereType<AmbientPreset>()
          .toList(growable: false);
    } catch (_) {
      return const <AmbientPreset>[];
    }
  }

  void saveAmbientPresets(List<AmbientPreset> presets) {
    _store.setSetting(
      'ambientPresets',
      jsonEncode(
        presets.map((preset) => preset.toJson()).toList(growable: false),
      ),
    );
  }

  bool loadRemoteResourcePrewarmCompleted() {
    return _store.getSetting(remotePrewarmCompletedKey) == '1';
  }

  void saveRemoteResourcePrewarmCompleted(bool value) {
    _store.setSetting(remotePrewarmCompletedKey, value ? '1' : '0');
  }

  ModuleToggleState loadModuleToggleState() {
    final raw = _store.getSetting(moduleTogglesKey);
    if (raw == null || raw.trim().isEmpty) {
      return ModuleToggleState.defaults;
    }
    try {
      return ModuleToggleState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return ModuleToggleState.defaults;
    }
  }

  void saveModuleToggleState(ModuleToggleState value) {
    _store.setSetting(moduleTogglesKey, jsonEncode(value.toJsonMap()));
  }

  ToolboxLayoutState loadToolboxLayoutState() {
    final raw = _store.getSetting(toolboxLayoutKey);
    if (raw == null || raw.trim().isEmpty) {
      return ToolboxLayoutState.defaults;
    }
    try {
      return ToolboxLayoutState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return ToolboxLayoutState.defaults;
    }
  }

  void saveToolboxLayoutState(ToolboxLayoutState value) {
    _store.setSetting(toolboxLayoutKey, jsonEncode(value.toJsonMap()));
  }
}
