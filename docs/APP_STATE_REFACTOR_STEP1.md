# AppState 渐进式重构计划

**目标**: 将 3011 行的 AppState 拆分为独立模块，**零风险、向后兼容**

---

## 重构策略

### 零风险原则

1. ✅ **保持现有 API 不变** - 所有 getter/setter 保持兼容
2. ✅ **渐进式提取** - 每次只重构一个模块
3. ✅ **充分测试** - 每个模块都有完整测试
4. ✅ **回滚能力** - 每一步都可安全回滚

### 重构阶段

| 阶段 | 模块 | 行数 | 风险 | 工时 |
|------|------|------|------|------|
| 1 | WordbookState | ~400 | 低 | 4h |
| 2 | SettingsState | ~200 | 低 | 2h |
| 3 | PlaybackState | ~300 | 中 | 3h |
| 4 | PracticeState | ~500 | 中 | 4h |
| 5 | AmbientState | ~200 | 低 | 2h |
| 6 | FocusState | ~250 | 低 | 2h |
| 7 | UI 适配 | - | 高 | 4h |
| 8 | 测试修复 | - | 中 | 4h |

---

## 阶段 1: WordbookState

### 提取的属性 (22 个)

```dart
// 词本数据
List<Wordbook> _wordbooks;
Wordbook? _selectedWordbook;
List<WordEntry> _words;
int _currentWordIndex;
int _wordsVersion;

// 搜索相关
String _searchQuery;
SearchMode _searchMode;
List<WordEntry>? _visibleWordsCache;
int _visibleWordsCacheVersion;
String _visibleWordsCacheQuery;
SearchMode _visibleWordsCacheMode;

// 收藏和任务
Set<String> _favorites;
Set<String> _taskWords;
Set<String> _rememberedWords;

// 导入进度
bool _wordbookImportActive;
String _wordbookImportName;
int _wordbookImportProcessedEntries;
int? _wordbookImportTotalEntries;
```

### 提取的方法

**核心方法**:
- `loadWordbooks()`
- `selectWordbook()`
- `setSearchQuery()`
- `setSearchMode()`
- `toggleFavorite()`
- `toggleTaskWord()`
- `addWordToFavorites()`
- `removeWordFromFavorites()`
- `addWordToTask()`
- `removeWordFromTask()`

**导入相关**:
- `startWordbookImport()`
- `updateImportProgress()`
- `finishWordbookImport()`
- `cancelWordbookImport()`

### API 兼容性设计

```dart
// AppState 中使用委托模式
class AppState {
  late final WordbookState _wordbookState;
  
  // 保持原有 getter 不变
  List<Wordbook> get wordbooks => _wordbookState.wordbooks;
  Wordbook? get selectedWordbook => _wordbookState.selectedWordbook;
  List<WordEntry> get words => _wordbookState.words;
  String get searchQuery => _wordbookState.searchQuery;
  // ... 所有其他 getter
}
```

---

## 阶段 2: SettingsState

### 提取的属性 (10 个)

```dart
PlayConfig _config;
String _uiLanguage;
bool _uiLanguageFollowsSystem;
AppHomeTab _startupPage;
FocusStartupTab _focusStartupTab;
StudyStartupTab _studyStartupTab;
bool _testModeEnabled;
bool _testModeRevealed;
bool _testModeHintRevealed;
String? _lastBackupPath;
```

---

## 阶段 3: PlaybackState

### 提取的属性 (15 个)

```dart
bool _isPlaying;
bool _isPaused;
int _currentUnit;
int _totalUnits;
PlayUnit? _activeUnit;
int? _playingWordbookId;
String? _playingWordbookName;
String? _playingWord;
List<WordEntry> _playingScopeWords;
int _playingScopeIndex;
int _playSessionId;
bool _playbackScopeRestarting;
int? _queuedPlaybackScopeTarget;
int _wordbookPlaybackSyncToken;
Map<String, PlaybackProgressSnapshot> _playbackProgressByWordbookPath;
```

---

## 实施步骤 (阶段 1)

### 步骤 1: 创建 WordbookState 类

```dart
// lib/src/state/wordbook_state.dart
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../models/wordbook.dart';
import '../models/word_entry.dart';

class WordbookState extends ChangeNotifier {
  WordbookState({required AppDatabaseService database})
      : _database = database;

  final AppDatabaseService _database;

  // 状态属性
  List<Wordbook> _wordbooks = <Wordbook>[];
  Wordbook? _selectedWordbook;
  List<WordEntry> _words = <WordEntry>[];
  int _currentWordIndex = 0;
  int _wordsVersion = 0;

  // Getters (保持与 AppState 相同的 API)
  List<Wordbook> get wordbooks => List.unmodifiable(_wordbooks);
  Wordbook? get selectedWordbook => _selectedWordbook;
  List<WordEntry> get words => List.unmodifiable(_words);
  int get currentWordIndex => _currentWordIndex;

  // 方法实现...
}
```

### 步骤 2: 更新 AppState 使用委托

```dart
// lib/src/state/app_state.dart
class AppState extends ChangeNotifier with WidgetsBindingObserver {
  late final WordbookState _wordbookState;

  AppState({...}) {
    _wordbookState = WordbookState(database: _database);
    // ...
  }

  // 委托给 WordbookState
  List<Wordbook> get wordbooks => _wordbookState.wordbooks;
  Wordbook? get selectedWordbook => _wordbookState.selectedWordbook;
  List<WordEntry> get words => _wordbookState.words;
  int get currentWordIndex => _wordbookState.currentWordIndex;
  // ... 其他所有 getter
}
```

### 步骤 3: 测试验证

```bash
# 运行测试
flutter test test/state/wordbook_state_test.dart

# 验证编译
flutter analyze

# 运行应用
flutter run
```

---

## 风险控制

### 回滚计划

如果重构后发现问题：

```bash
# Git 回滚
git checkout HEAD~1 -- lib/src/state/

# 或者手动恢复
git checkout app_state.dart.bak -- lib/src/state/app_state.dart
```

### 测试覆盖

每个模块至少包含：
- ✅ 属性 getter 测试
- ✅ 核心方法测试
- ✅ 状态变更通知测试
- ✅ 边界条件测试

---

## 成功标准

### 阶段完成标准

- [ ] 代码分析通过 (0 errors)
- [ ] 所有现有测试通过
- [ ] 新模块测试覆盖 >80%
- [ ] 应用运行正常
- [ ] 性能无下降

### 最终目标

- ✅ AppState 行数：3011 → <1000
- ✅ 可维护性提升 60%
- ✅ 测试覆盖率提升到 70%+
- ✅ 编译时间减少 25%

---

**开始时间**: 2026-03-30  
**预计完成**: 2026-04-06 (7 天)  
**风险等级**: 低 (渐进式、可回滚)
