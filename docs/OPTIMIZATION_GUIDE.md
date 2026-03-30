# 咸鱼声息 - 优化实施手册

**版本**: 1.0  
**日期**: 2026-03-30  
**目标**: 提升可维护性，减少包体积，优化依赖

---

## 一、AppState 模块拆分实施指南

### 当前状态

```
lib/src/state/app_state.dart: 97KB, 3011 行
```

**问题**:
- 违反单一职责原则
- 包含 6+ 个不同领域的状态管理
- 难以测试和维护

### 目标架构

```
lib/src/state/
├── app_state.dart              # 协调器 (精简到 ~500 行)
├── wordbook_state.dart         # 词本状态 (~300 行)
├── playback_state.dart         # 播放状态 (~250 行)
├── practice_state.dart         # 练习状态 (~400 行)
├── focus_state.dart            # 专注状态 (~200 行)
├── ambient_state.dart          # 环境音状态 (~150 行)
└── settings_state.dart         # 设置状态 (~150 行)
```

### 实施步骤

#### 步骤 1: 提取 WordbookState

```dart
// lib/src/state/wordbook_state.dart
class WordbookState extends ChangeNotifier {
  final AppDatabaseService _database;
  
  // 词本数据
  List<Wordbook> _wordbooks = [];
  Wordbook? _selectedWordbook;
  List<WordEntry> _words = [];
  
  // 搜索
  String _searchQuery = '';
  SearchMode _searchMode = SearchMode.all;
  
  // 收藏/任务
  Set<String> _favorites = {};
  Set<String> _taskWords = {};
  
  // Getters...
  List<Wordbook> get wordbooks => List.unmodifiable(_wordbooks);
  Wordbook? get selectedWordbook => _selectedWordbook;
  
  // 方法...
  Future<void> loadWordbooks() async { ... }
  Future<void> selectWordbook(Wordbook? w) async { ... }
  void toggleFavorite(String word) { ... }
}
```

**从 AppState 迁移的属性**:
- `_wordbooks`, `_selectedWordbook`, `_words`
- `_searchQuery`, `_searchMode`
- `_favorites`, `_taskWords`, `_rememberedWords`
- `_wordbookImportActive` 等相关属性

**从 AppState 迁移的方法**:
- `loadWordbooks()`, `selectWordbook()`
- `setSearchQuery()`, `setSearchMode()`
- `toggleFavorite()`, `toggleTaskWord()`
- 所有词本导入相关方法

#### 步骤 2: 提取 PlaybackState

```dart
// lib/src/state/playback_state.dart
class PlaybackState extends ChangeNotifier {
  final PlaybackService _playback;
  final TtsService _tts;
  
  bool _isPlaying = false;
  bool _isPaused = false;
  int _currentUnit = 0;
  int? _playingWordbookId;
  
  // Getters...
  bool get isPlaying => _isPlaying;
  int? get playingWordbookId => _playingWordbookId;
  
  // 方法...
  Future<void> play(Wordbook w, List<WordEntry> words) async { ... }
  Future<void> pause() async { ... }
  Future<void> stop() async { ... }
}
```

#### 步骤 3: 更新 AppState

```dart
// lib/src/state/app_state.dart (精简后)
class AppState extends ChangeNotifier {
  final WordbookState wordbook;
  final PlaybackState playback;
  final PracticeState practice;
  final FocusState focus;
  final AmbientState ambient;
  final SettingsState settings;
  
  AppState({
    required this.wordbook,
    required this.playback,
    required this.practice,
    required this.focus,
    required this.ambient,
    required this.settings,
  });
  
  // 协调方法
  Future<void> initialize() async {
    await wordbook.init();
    await practice.init();
    // ...
  }
}
```

#### 步骤 4: 更新 UI 层

```dart
// 之前
final state = context.watch<AppState>();
final word = state.words[state.currentWordIndex];

// 之后
final wordbook = context.watch<WordbookState>();
final playback = context.watch<PlaybackState>();
final word = wordbook.words[wordbook.currentWordIndex];
```

### 依赖注入配置

```dart
// lib/src/app/app_dependencies.dart
class AppDependencies {
  late final WordbookState wordbook;
  late final PlaybackState playback;
  
  static AppDependencies create() {
    final deps = AppDependencies();
    deps.wordbook = WordbookState(database: deps.database);
    deps.playback = PlaybackState(
      playback: deps.playbackService,
      tts: deps.ttsService,
    );
    return deps;
  }
  
  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => wordbook),
        ChangeNotifierProvider(create: (_) => playback),
        ChangeNotifierProvider(create: (_) => practice),
        ChangeNotifierProvider(create: (_) => AppState(
          wordbook: wordbook,
          playback: playback,
          // ...
        )),
      ],
      child: child,
    );
  }
}
```

### 测试策略

```dart
// test/state/wordbook_state_test.dart
void main() {
  test('toggleFavorite updates favorites set', () async {
    final state = WordbookState(database: mockDatabase);
    
    state.toggleFavorite('hello');
    expect(state.favorites, contains('hello'));
    
    state.toggleFavorite('hello');
    expect(state.favorites, isNot(contains('hello')));
  });
}
```

### 时间表

| 阶段 | 模块 | 预计工时 | 风险 |
|------|------|----------|------|
| 1 | WordbookState | 4h | 低 |
| 2 | PlaybackState | 3h | 中 |
| 3 | PracticeState | 4h | 中 |
| 4 | FocusState | 2h | 低 |
| 5 | AmbientState | 2h | 低 |
| 6 | SettingsState | 2h | 低 |
| 7 | UI 层适配 | 4h | 高 |
| 8 | 测试和修复 | 4h | 中 |
| **总计** | | **25h** | |

---

## 二、图片 WebP 化实施

### 当前资源

```
assets/branding/logo.jpg: 30.6 KB
```

### 转换步骤

#### 方法 1: 使用在线工具 (推荐)

1. 访问 [Squoosh.app](https://squoosh.app/)
2. 上传 `logo.jpg`
3. 选择 WebP 格式，质量 85%
4. 下载 `logo.webp`
5. 替换原文件

#### 方法 2: 使用命令行工具

```bash
# Windows - 下载 WebP 工具包
# https://storage.googleapis.com/downloads.webmproject.org/releases/webp/index.html

# 转换
cwebp -q 85 assets/branding/logo.jpg -o assets/branding/logo.webp

# 验证
ls -lh assets/branding/logo.webp  # 应 ~12KB
```

#### 方法 3: 使用 Flutter 包

```bash
flutter pub add webp_converter
```

```dart
// scripts/convert_images.dart
import 'package:webp_converter/webp_converter.dart';

void main() async {
  await WebpConverter.convert(
    input: 'assets/branding/logo.jpg',
    output: 'assets/branding/logo.webp',
    quality: 85,
  );
}
```

### 更新配置

**pubspec.yaml**:
```yaml
flutter:
  assets:
    - assets/branding/logo.webp  # 更新此行
    - assets/wordbooks/
```

**清理**:
```bash
# 删除原文件
rm assets/branding/logo.jpg

# 清理构建缓存
flutter clean
```

### 预期收益

| 指标 | 转换前 | 转换后 | 改善 |
|------|--------|--------|------|
| 文件大小 | 30.6 KB | ~12 KB | -60% |
| 加载速度 | 基准 | +30% | 更快 |
| 带宽 | 基准 | -60% | 节省 |

---

## 三、依赖包优化

### 立即可移除的依赖

```bash
# 1. 检查是否直接使用
grep -r "audioplayers_platform_interface" lib/
grep -r "path_provider_platform_interface" lib/
grep -r "plugin_platform_interface" lib/

# 2. 如果无直接使用，从 pubspec.yaml 移除
```

**pubspec.yaml 修改**:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_launcher_icons: ^0.14.3
  fake_async: ^1.3.3
  # 移除以下行:
  # path_provider_platform_interface: ^2.1.2
  # plugin_platform_interface: ^2.1.8
```

### 升级 EOL 依赖

**pubspec.yaml**:
```yaml
dependencies:
  # 升级前
  sqlite3_flutter_libs: ^0.6.0+eol
  
  # 升级后 (等待新版本发布)
  # sqlite3_flutter_libs: ^0.6.1
```

### 优化大体积依赖

#### sherpa_onnx (~10MB)

**选项 1: 按需下载模型**
```dart
// 仅在需要时下载
if (!await modelExists()) {
  await downloadModel();
}
```

**选项 2: 提供精简模式**
```dart
// 设置中提供选项
bool get useAdvancedAsr => settings.advancedAsrEnabled;
```

### 依赖审计命令

```bash
# 检查过时依赖
flutter pub outdated

# 检查安全漏洞
flutter pub global activate dart_audit
flutter pub global run dart_audit

# 查看依赖树
flutter pub deps --style=tree
```

---

## 四、优化效果追踪

### 关键指标

| 指标 | 当前 | 目标 | 测量方法 |
|------|------|------|----------|
| AppState 行数 | 3011 | <1000 | wc -l |
| APK 体积 | 54.6MB | <40MB | ls -lh |
| 构建时间 | 92s | <70s | time flutter build |
| 测试覆盖率 | ~40% | >70% | flutter test --coverage |

### 监控脚本

```bash
# scripts/track_metrics.sh
#!/bin/bash

echo "=== 代码指标 ==="
wc -l lib/src/state/app_state.dart
wc -l lib/src/state/*.dart

echo "=== 构建体积 ==="
ls -lh build/app/outputs/flutter-apk/*.apk

echo "=== 依赖数量 ==="
flutter pub deps | grep "├──" | wc -l
```

---

## 五、后续优化建议

### 短期 (1-2 周)

1. ✅ 完成 WordbookState 提取
2. ✅ 图片 WebP 化
3. ✅ 移除未使用依赖

### 中期 (1 个月)

1. 完成所有状态模块拆分
2. 实现按需资源下载
3. 配置 ProGuard/R8 代码压缩

### 长期 (2-3 个月)

1. 迁移到 Riverpod (可选)
2. 实现模块化构建
3. 添加性能监控

---

## 六、故障排除

### 问题 1: 迁移后状态不同步

**解决**:
```dart
// 使用 Listener 监听多个状态
return ListenableBuilder(
  listenable: Listenable.merge([wordbook, playback]),
  builder: (context, child) {
    // 重建 UI
  },
);
```

### 问题 2: 依赖注入循环

**解决**:
```dart
// 使用 Lazy 初始化
late final appState = AppState(
  wordbook: wordbook,
  playback: playback,
  // 避免循环引用
);
```

### 问题 3: WebP 不显示

**检查**:
```bash
# 验证文件存在
ls assets/branding/logo.webp

# 清理并重建
flutter clean
flutter pub get
flutter run
```

---

## 附录：完整代码示例

详见：
- `docs/APP_STATE_REFACTOR_PLAN.md` - 重构计划
- `docs/WEBP_OPTIMIZATION.md` - WebP 转换指南  
- `docs/DEPENDENCY_REVIEW.md` - 依赖审查报告

---

*手册最后更新：2026-03-30*
