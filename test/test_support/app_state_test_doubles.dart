import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/models/todo_item.dart';
import 'package:vocabulary_sleep_app/src/models/word_entry.dart';
import 'package:vocabulary_sleep_app/src/services/ambient_service.dart';
import 'package:vocabulary_sleep_app/src/services/asr_service.dart';
import 'package:vocabulary_sleep_app/src/services/focus_service.dart';
import 'package:vocabulary_sleep_app/src/services/playback_service.dart';
import 'package:vocabulary_sleep_app/src/services/system_calendar_service.dart';
import 'package:vocabulary_sleep_app/src/services/todo_reminder_service.dart';

class TrackingPlaybackService implements PlaybackService {
  @override
  bool get isPaused => false;

  @override
  bool get isPlaying => false;

  int updateCalls = 0;
  PlayConfig? lastConfig;

  @override
  void updateRuntimeConfig(PlayConfig config) {
    updateCalls += 1;
    lastConfig = config;
  }

  @override
  Future<List<String>> getLocalVoices() async => const <String>[];

  @override
  Future<int> getApiTtsCacheSizeBytes() async => 0;

  @override
  Future<void> clearApiTtsCache() async {}

  @override
  Future<void> playWords({
    required List<WordEntry> words,
    required int startIndex,
    required PlayConfig config,
    WordChangeCallback? onWordChanged,
    UnitChangeCallback? onUnitChanged,
    void Function()? onFinished,
  }) async {
    onFinished?.call();
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> skipCurrentWord() async {}

  @override
  Future<void> speakText(String text, PlayConfig config) async {}
}

class StubAmbientService implements AmbientService {
  @override
  List<AmbientSource> get sources => const <AmbientSource>[];

  @override
  double get masterVolume => 0;

  @override
  void setMasterVolume(double value) {}

  @override
  void setSourceEnabled(String sourceId, bool enabled) {}

  @override
  void setSourceVolume(String sourceId, double value) {}

  @override
  void addFileSource(String path, {String? name}) {}

  @override
  void removeSource(String sourceId) {}

  @override
  Future<void> stopAll() async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> syncPlayback() async {}
}

class StubAsrService implements AsrService {
  @override
  Future<String?> startRecording({required AsrProviderType provider}) async {
    return null;
  }

  @override
  Future<String?> stopRecording() async => null;

  @override
  Future<void> cancelRecording() async {}

  @override
  void stopOfflineRecognition() {}

  @override
  Future<AsrResult> transcribeFile({
    required String audioPath,
    required AsrConfig config,
    String? expectedText,
    TtsConfig? ttsConfig,
    AsrProgressCallback? onProgress,
  }) async {
    return const AsrResult(success: false, error: 'asrDisabled');
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<AsrOfflineModelStatus> getOfflineModelStatus(
    AsrProviderType provider,
  ) async {
    return AsrOfflineModelStatus(
      provider: provider,
      installed: false,
      bytes: 0,
    );
  }

  @override
  Future<PronScoringPackStatus> getPronScoringPackStatus(
    PronScoringMethod method,
  ) async {
    return PronScoringPackStatus(method: method, installed: false, bytes: 0);
  }

  @override
  Future<void> preparePronScoringPack({
    required PronScoringMethod method,
    AsrProgressCallback? onProgress,
  }) async {}

  @override
  Future<void> removePronScoringPack(PronScoringMethod method) async {}

  @override
  Future<void> prepareOfflineModel({
    required AsrProviderType provider,
    required String language,
    AsrProgressCallback? onProgress,
  }) async {}

  @override
  Future<void> removeOfflineModel(AsrProviderType provider) async {}
}

class _StubSystemCalendarService implements SystemCalendarService {
  @override
  Future<void> syncTodo(TodoItem item) async {}

  @override
  Future<void> removeTodoReminder(int todoId) async {}

  @override
  Future<void> dispose() async {}
}

class _StubTodoReminderService implements TodoReminderService {
  @override
  Future<TodoReminderCapability> getCapability() async {
    return const TodoReminderCapability(
      notificationsGranted: true,
      notificationPermissionRequestable: false,
      exactAlarmGranted: true,
      exactAlarmSettingsAvailable: false,
    );
  }

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> syncTodo(TodoItem item) async {}

  @override
  Future<void> removeTodoReminder(int todoId) async {}

  @override
  Future<int?> consumePendingTodoLaunchId() async => null;

  @override
  Future<TodoReminderLaunchAction?> consumePendingTodoAction() async => null;

  @override
  Future<void> dispose() async {}
}

class StubFocusService extends FocusService {
  StubFocusService(
    super.database, {
    super.settings,
    this.todos = const <TodoItem>[],
  }) : super(
         ambient: null,
         systemCalendar: _StubSystemCalendarService(),
         todoReminder: _StubTodoReminderService(),
         tts: null,
       );

  final List<TodoItem> todos;
  int initCalls = 0;

  @override
  Future<void> init() async {
    initCalls += 1;
  }

  @override
  List<TodoItem> getTodos() => todos;

  @override
  Future<int?> consumePendingTodoReminderLaunchId() async => null;
}
