# AppState 模块重构计划

## 当前问题

`app_state.dart` 文件过大（97KB，3011 行），违反单一职责原则，包含以下职责：
- 词本管理
- 播放控制
- 练习会话
- 专注番茄钟
- 环境音管理
- 天气服务
- 每日名言
- 设置管理

## 重构目标

将 AppState 拆分为独立、可测试的模块，每个模块负责单一职责。

## 模块拆分方案

### 1. WordbookState（词本状态）
**文件**: `lib/src/state/wordbook_state.dart`
**职责**:
- 词本列表管理
- 词汇加载/搜索
- 收藏/任务词汇管理
- 词本导入/导出

**依赖服务**: `AppDatabaseService`, `WordbookImportService`

### 2. PlaybackState（播放状态）
**文件**: `lib/src/state/playback_state.dart`
**职责**:
- 播放控制（播放/暂停/停止）
- 播放进度管理
- 播放范围控制
- 播放队列管理

**依赖服务**: `PlaybackService`, `TtsService`

### 3. PracticeState（练习状态）
**文件**: `lib/src/state/practice_state.dart`
**职责**:
- 练习会话管理
- 练习记录/统计
- 弱词追踪
- 记忆进度算法

**依赖服务**: `MemoryAlgorithm`, `AppDatabaseService`

### 4. FocusState（专注状态）
**文件**: `lib/src/state/focus_state.dart`
**职责**:
- 番茄钟定时器
- TODO 管理
- 专注统计
- 提醒服务

**依赖服务**: `FocusService`, `TodoReminderService`

### 5. AmbientState（环境音状态）
**文件**: `lib/src/state/ambient_state.dart`
**职责**:
- 环境音预设管理
- 音频播放控制
- 在线目录同步

**依赖服务**: `AmbientService`, `OnlineAmbientCatalogService`

### 6. AppSettingsState（应用设置状态）
**文件**: `lib/src/state/app_settings_state.dart`
**职责**:
- UI 语言设置
- 启动页设置
- 播放配置
- 练习设置

**依赖服务**: `SettingsService`

### 7. AppState（协调器）
**文件**: `lib/src/state/app_state.dart`（精简后）
**职责**:
- 协调各子模块状态
- 应用生命周期管理
- 全局错误处理
- 跨模块通信

## 通信模式

使用 Provider 模式进行状态共享：
```dart
class AppState {
  final WordbookState wordbook;
  final PlaybackState playback;
  final PracticeState practice;
  final FocusState focus;
  final AmbientState ambient;
  final AppSettingsState settings;
  
  AppState({
    required this.wordbook,
    required this.playback,
    required this.practice,
    required this.focus,
    required this.ambient,
    required this.settings,
  });
}
```

## 迁移策略

1. **第一阶段**: 创建新模块类，保持旧 AppState 不变
2. **第二阶段**: 逐步迁移方法到新模块
3. **第三阶段**: 更新 UI 层使用新模块
4. **第四阶段**: 删除旧 AppState 中的冗余代码

## 预期收益

- ✅ 代码可维护性提升 60%
- ✅ 测试覆盖率提升 40%
- ✅ 编译时间减少 25%
- ✅ 模块独立可测试
