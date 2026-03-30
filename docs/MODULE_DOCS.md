# 咸鱼声息 - 模块说明文档

## 项目架构概述

本项目采用**服务层 + 状态层 + UI 层**的三层架构：

```
lib/
├── src/
│   ├── app/           # 应用入口和依赖注入
│   ├── i18n/          # 国际化
│   ├── models/        # 数据模型
│   ├── services/      # 业务服务层
│   ├── state/         # 状态管理层
│   ├── ui/            # UI 组件层
│   └── utils/         # 工具函数
├── main.dart          # 应用入口
└── test/              # 测试文件
```

---

## 核心模块说明

### 1. 应用启动模块 (`lib/src/app/`)

#### 文件结构
- `app_bootstrap.dart` - 应用启动和全局错误处理
- `app_dependencies.dart` - 依赖注入容器
- `app_root.dart` - 根组件和 Provider 配置

#### 职责
- 初始化 Flutter 绑定
- 设置全局错误捕获
- 创建和注册服务实例
- 初始化环境变量

#### 关键代码
```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化环境变量
  await dotenv.load(fileName: '.env');
  
  runVocabularySleepApp();
}
```

---

### 2. 状态管理模块 (`lib/src/state/`)

#### 文件结构
- `app_state.dart` - 全局状态协调器 (97KB，待重构)
- `app_state_playback.dart` - 播放状态扩展
- `app_state_practice.dart` - 练习状态扩展
- `app_state_startup.dart` - 启动配置扩展
- `app_state_wordbook.dart` - 词本状态扩展

#### 职责
- 管理应用全局状态
- 协调各服务层组件
- 实现 ChangeNotifier 模式
- 处理应用生命周期事件

#### 状态细分
| 状态类别 | 属性示例 |
|----------|----------|
| 词本状态 | `_wordbooks`, `_selectedWordbook`, `_words` |
| 播放状态 | `_isPlaying`, `_isPaused`, `_currentUnit` |
| 练习状态 | `_practiceTodaySessions`, `_practiceWeakWords` |
| 设置状态 | `_uiLanguage`, `_startupPage`, `_config` |
| 环境音状态 | `_ambientPresets` |
| 专注状态 | (通过 `focusService` 管理) |

#### ⚠️ 重构计划
详见 `docs/APP_STATE_REFACTOR_PLAN.md`

---

### 3. 服务层模块 (`lib/src/services/`)

#### 3.1 数据服务
| 服务 | 文件 | 职责 |
|------|------|------|
| 数据库服务 | `database_service.dart` | SQLite CRUD 操作，词本/TODO/专注记录管理 |
| 设置服务 | `settings_service.dart` | 持久化用户设置 |
| S3 客户端 | `cstcloud_s3_compat_client.dart` | 云存储资源访问 |

#### 3.2 音频服务
| 服务 | 文件 | 职责 |
|------|------|------|
| 播放服务 | `playback_service.dart` | TTS 音频播放控制 |
| TTS 服务 | `tts_service.dart` | 文本转语音（本地/在线） |
| 环境音服务 | `ambient_service.dart` | 白噪音/助眠音频播放 |
| 音频工具 | `audio_player_source_helper.dart` | AudioPlayer 工具类 |

#### 3.3 语音服务
| 服务 | 文件 | 职责 |
|------|------|------|
| ASR 服务 | `asr_service.dart` | 自动语音识别，发音评分 |

#### 3.4 专注服务
| 服务 | 文件 | 职责 |
|------|------|------|
| 专注服务 | `focus_service.dart` | 番茄钟定时器，TODO 管理 |

#### 3.5 其他服务
| 服务 | 文件 | 职责 |
|------|------|------|
| 日志服务 | `app_log_service.dart` | 结构化日志记录 |
| 天气服务 | `weather_service.dart` | 天气数据获取 |
| 每日名言 | `daily_quote_service.dart` | 每日名言获取 |
| 记忆算法 | `memory_algorithm.dart` | 艾宾浩斯记忆曲线算法 |

---

### 4. 数据模型模块 (`lib/src/models/`)

#### 核心模型

| 模型 | 文件 | 说明 |
|------|------|------|
| 词汇 | `word_entry.dart` | 单词、释义、音标等 |
| 词本 | `wordbook.dart` | 词本元数据 |
| 用户数据 | `user_data_export.dart` | 导出/导入数据结构 |
| 播放配置 | `play_config.dart` | TTS 播放参数 |
| 专注定时器 | `tomato_timer.dart` | 番茄钟状态 |
| TODO 项 | `todo_item.dart` | TODO 任务数据 |
| 记忆进度 | `word_memory_progress.dart` | 词汇记忆状态 |
| 环境音预设 | `ambient_preset.dart` | 环境音配置 |

---

### 5. UI 组件模块 (`lib/src/ui/`)

#### 页面结构
```
ui/
├── pages/          # 完整页面
│   ├── focus_page.dart           # 专注页面
│   ├── practice_page.dart        # 练习页面
│   ├── wordbook_page.dart        # 词本页面
│   ├── ambient_page.dart         # 环境音页面
│   └── settings_page.dart        # 设置页面
├── widgets/        # 可复用组件
│   ├── word_card.dart            # 词汇卡片
│   ├── tomato_timer_widget.dart  # 番茄钟组件
│   └── audio_player_widget.dart  # 播放器组件
└── theme/          # 主题配置
```

---

### 6. 工具模块 (`lib/src/utils/`)

| 工具 | 文件 | 说明 |
|------|------|------|
| 搜索文本标准化 | `search_text_normalizer.dart` | 搜索词规范化 |
| 词本导入服务 | `wordbook_import_service.dart` | 词本解析/导入 |

---

## 依赖关系图

```
┌─────────────────┐
│     UI Layer    │
│  (pages/widgets)│
└────────┬────────┘
         │ uses
         ▼
┌─────────────────┐
│   State Layer   │
│   (app_state)   │
└────────┬────────┘
         │ coordinates
         ▼
┌─────────────────┐
│  Service Layer  │
│  (services/*)   │
└────────┬────────┘
         │ accesses
         ▼
┌─────────────────┐
│   Data Layer    │
│ (db/file/S3)    │
└─────────────────┘
```

---

## 关键设计模式

### 1. Provider 模式
使用 `ChangeNotifier` + `provider` 包实现状态管理：
```dart
ChangeNotifierProvider(
  create: (_) => AppState(...),
  child: MyApp(),
)
```

### 2. 服务定位器模式
通过 `AppDependencies` 集中管理服务实例：
```dart
class AppDependencies {
  static AppDependencies create() => ...;
  T get<T extends Object>();
}
```

### 3. 仓库模式
数据访问通过服务层封装：
```dart
class AppDatabaseService {
  List<WordEntry> getWords(int wordbookId);
  void insertWord(WordEntry word);
}
```

### 4. 观察者模式
状态变更通知监听者：
```dart
class AppState extends ChangeNotifier {
  void updateState() {
    // ...
    notifyListeners();
  }
}
```

---

## 环境变量配置

### .env 文件结构
```env
# S3 配置
S3_ENDPOINT=s3.cstcloud.cn
S3_BUCKET=32be744530ff4a4b9be7bf802bd959b8
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=YOUR_KEY
S3_SECRET_ACCESS_KEY=YOUR_SECRET

# 应用配置
APP_FLAVOR=production
```

### 使用方法
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final endpoint = dotenv.env['S3_ENDPOINT'];
```

---

## 测试策略

### 测试类型
| 类型 | 位置 | 说明 |
|------|------|------|
| 单元测试 | `test/*_test.dart` | 服务/模型测试 |
| 组件测试 | `test/widgets/*_test.dart` | Widget 测试 |
| 集成测试 | `integration_test/` | 端到端测试 |

### 测试工具
- `flutter_test` - Flutter 测试框架
- `fake_async` - 异步测试辅助
- `app_state_test_doubles.dart` - 测试桩实现

---

## 构建配置

### 依赖版本
| 依赖 | 版本 | 说明 |
|------|------|------|
| Flutter | 3.11+ | 框架版本 |
| sqlite3 | ^2.9.4 | 数据库 |
| provider | ^6.1.5+1 | 状态管理 |
| audioplayers | ^6.6.0 | 音频播放 |

### 构建命令
```bash
# Debug APK
flutter build apk --debug

# Release APK (单架构)
flutter build apk --target-platform android-arm64

# Release App Bundle
flutter build appbundle --release
```

---

## 代码规范

### Lint 规则
详见 `analysis_options.yaml`：
- `prefer_const_constructors` - 优先使用 const 构造
- `prefer_single_quotes` - 使用单引号
- `avoid_print` - 禁止 print
- `use_build_context_synchronously` - 异步 context 使用检查

### 命名约定
- 文件/目录：`snake_case`
- 类/枚举：`PascalCase`
- 变量/函数：`camelCase`
- 常量：`camelCase` 或 `SCREAMING_SNAKE_CASE`

---

## 性能优化

### 已实现
- ✅ 词汇列表缓存机制
- ✅ 懒加载词本
- ✅ S3 资源按需加载

### 待优化
- 🔄 AppState 模块拆分
- 🔲 图片资源 WebP 化
- 🔲 启用 R8 代码压缩

详见 `docs/APK_SIZE_OPTIMIZATION.md`

---

## 安全建议

### 敏感信息管理
- ✅ API 密钥移至环境变量
- ✅ .env 文件加入 .gitignore
- ✅ 使用 .env.template 提供配置示例

### 数据安全
- 本地数据库文件存储于应用沙箱
- 导出文件需用户授权

---

## 国际化

### 支持语言
- 简体中文 (zh)
- 英文 (en)
- 系统语言自动检测

### 实现方式
```dart
final i18n = AppI18n(_uiLanguage);
final text = i18n.t('common.hello');
```

---

## 模块联系方式

各模块通过 `AppState` 协调通信：
```dart
// UI 层访问状态
final state = context.watch<AppState>();
final word = state.currentWord;

// 状态层调用服务
state.focusService.startTimer(minutes: 25);
```

---

## 开发快速开始

1. **环境准备**
```bash
flutter doctor
cp .env.template .env
# 编辑 .env 填入配置
```

2. **运行应用**
```bash
flutter run
```

3. **运行测试**
```bash
flutter test
```

4. **代码检查**
```bash
flutter analyze
```

---

## 文档索引

| 文档 | 位置 | 说明 |
|------|------|------|
| 项目结构 | `docs/PROJECT_STRUCTURE.md` | 目录结构说明 |
| 构建指南 | `docs/BUILDING.md` | 构建配置说明 |
| State 重构计划 | `docs/APP_STATE_REFACTOR_PLAN.md` | 模块拆分方案 |
| 包体积优化 | `docs/APK_SIZE_OPTIMIZATION.md` | 优化建议 |

---

*文档最后更新：2026-03-30*
