# 咸鱼声息 / Vocabulary Sleep App

一个以「词汇学习、练习巩固、专注管理、睡眠支持、工具箱」为核心的 Flutter 综合应用。项目不是单点工具，而是一个本地优先、移动端优先、可模块化启停、可逐步扩展的多域能力平台。

## 项目定位

- **学习闭环**: 以词本、词条、播放、记忆进度和练习会话串起「学、听、练、复盘」。
- **低摩擦日常辅助**: 提供专注计时、待办笔记、睡前流程、夜醒救援、舒缓声音和轻量决策工具。
- **模块化平台**: 顶层功能和 toolbox 子工具都通过模块 ID、注册表和运行时守卫管理，支持按需启停。
- **本地优先**: SQLite、JSON、本地资源和缓存优先；远端资源主要用于可延迟下载的大数据集或媒体资源。
- **移动端优先**: 以 375dp 宽度为基础设计目标，控制首屏信息密度、触控热区和窄屏溢出。

## 当前能力概览

| 顶层模块 | 模块 ID | 说明 |
| --- | --- | --- |
| 学习 | `study` | 词本浏览、词条详情、学习播放、字段播放配置、内置词本延迟加载 |
| 练习 | `practice` | 多题型练习、练习会话、错题与历史、记忆进度追踪 |
| 专注 | `focus` | 专注计时、待办、笔记、锁屏专注、提醒与环境音联动 |
| 工具箱 | `toolbox` | 睡眠、声音、减压、小游戏、人类测试、每日决策等独立工具 |
| 更多 | `more` | 设置、模块管理、数据管理、语言、语音、外观和辅助入口 |

模块定义集中在 `lib/src/core/module_system/`：

- `module_id.dart`: 模块 ID 常量。
- `module_registry.dart`: 模块分组、父子关系和可禁用性。
- `module_runtime_guard.dart`: 运行时可访问性判断。
- `lib/src/ui/module/module_access.dart`: UI 侧统一路由守卫与禁用态提示。

## Toolbox 子模块

Toolbox 采用「模块注册 + 独立入口 + 页面守卫」组织。当前注册的子模块包括：

| 子模块 ID | 名称 | 主要能力 |
| --- | --- | --- |
| `toolbox.sleep_assistant` | 睡眠助手 | 睡眠评估、睡眠日志、睡前流程、夜醒救援、节律建议、报告 |
| `toolbox.mini_games` | 小游戏中心 | 数独、扫雷、拼图、五子棋、2048、俄罗斯轮盘等轻量游戏 |
| `toolbox.human_tests` | 人类测试中心 | 反应、记忆、视觉、手眼协调、时间感知、计算、持续注意力等趣味测试 |
| `toolbox.soothing_music` | 舒缓音乐 | 本地舒缓曲目、沉浸式视觉舞台、播放意图管理 |
| `toolbox.sound_deck` | 乐器工具集 | 竖琴、钢琴、吉他、长笛、鼓垫、小提琴、三角铁等声音工具 |
| `toolbox.singing_bowls` | 疗愈音钵 | 音钵共振、移动端控制面板、宽窄屏布局 |
| `toolbox.focus_beats` | 专注节拍 | 节拍训练、循环编排、可视化舞台 |
| `toolbox.woodfish` | 电子木鱼 | 触发、计数、音效、反馈和轻仪式化重置 |
| `toolbox.schulte_grid` | 舒尔特方格 | 视觉搜索与注意力训练 |
| `toolbox.breathing` | 呼吸训练 | 专注、放松、睡前等呼吸节奏流程 |
| `toolbox.prayer_beads` | 静心念珠 | 节奏化计数和减压反馈 |
| `toolbox.zen_sand` | 禅意沙盘 | 触控绘制、沙纹反馈和环境音联动 |
| `toolbox.daily_decision` | 每日决策 | 吃什么、穿什么、去哪儿、干什么、随机助手、决策助手 |

Toolbox UI 调整需要同步遵守：

- `docs/toolbox_design/TOOLBOX_DESIGN_REVIEW.md`
- `docs/toolbox_design/TOOLBOX_ANIMATION_SPEC.md`
- `docs/toolbox_design/TOOLBOX_UI_STYLE_GUIDE.md`

Toolbox 首页支持用户自定义布局：点击“编辑布局”或长按工具卡片进入编辑模式，可拖拽调整模块顺序、从首页隐藏入口、恢复隐藏入口或重置默认布局。该能力只影响工具箱首页展示，和“模块管理”中的全局启停相互独立；全局禁用仍会通过模块守卫阻断入口和路由访问。

## 近期进展

2026-05-07 的 toolbox 阶段提交重点收口以下内容：

- **人类测试中心**: 进一步拆分 `toolbox_human_tests_*` 页面职责，补齐反应、瞄准、打字、词汇记忆、数字记忆、动态视力、色觉、手眼协调、计算、持续注意力、运气、手速、序列记忆、斯特鲁普和时间感知等测试的设置、反馈、报告与 smoke test。
- **运气测试**: 支持单抽、十连、二十连、抽卡目标、概率期望幸运指数、真实批量卡片翻开、史诗/传说全屏特效、趣味称号和下一轮批次刷新。
- **摇杆手眼协调**: 白底全屏训练支持隐式摇杆、预练习、设置弹窗、横屏左摇杆/右射击热区、触点唤起浮层和报告。
- **小游戏中心**: 俄罗斯轮盘完成低沉金属音效、爆炸音效、左轮视觉拆分、Painter/View 分层与 Android 音频事件主线程派发修复。
- **文档与验证**: `modules/toolbox/README.md`、`changelogs/CHANGELOG.md`、`records/` 和相关 `plans/` 已同步记录阶段范围与验证命令。

## 技术栈

- **框架**: Flutter
- **语言**: Dart，SDK 约束为 `^3.11.0`
- **状态管理**: `ChangeNotifier`、`Provider`、`flutter_riverpod` 过渡共存
- **本地数据库**: `sqlite3` + `sqlite3_flutter_libs`
- **音频**: `audioplayers`，并使用本地 `third_party/audioplayers_android` override
- **TTS**: `flutter_tts`，并使用本地 `third_party/flutter_tts` override
- **ASR**: `sherpa_onnx`
- **网络与资源**: `http`、S3 兼容资源探测、远端资源缓存
- **地图与定位**: `geolocator`、`flutter_map`、`latlong2`、`url_launcher`
- **测试**: `flutter_test`、`integration_test`、单元测试与 UI smoke test

## 目录结构

```text
.
├── lib/
│   ├── main.dart
│   └── src/
│       ├── app/                 # 启动装配、依赖注入、应用身份
│       ├── core/module_system/  # 模块 ID、注册表、启停守卫
│       ├── i18n/                # 国际化入口
│       ├── models/              # 数据模型
│       ├── repositories/        # 仓储边界
│       ├── services/            # 数据库、播放、TTS、ASR、提醒、天气、toolbox 服务
│       ├── state/               # AppState 与各域状态
│       ├── ui/                  # 页面、组件、主题、动效、文案
│       └── utils/               # 搜索、语音、语言等工具
├── assets/                      # 品牌、词本、toolbox 静态资源
├── dict/                        # 词典与词本数据
├── docs/                        # 工程文档与设计规范
├── modules/                     # 模块说明和模块化推进记录
├── plans/                       # 每轮改动计划
├── records/                     # 过程记录、审计和回归记录
├── changelogs/                  # 变更日志
├── scripts/                     # 运行、构建、验证、数据生成脚本
├── test/                        # 单元测试、Widget 测试、smoke test
├── third_party/                 # 本地维护的依赖 override
└── dist/                        # 构建产物输出目录
```

## 环境准备

### 基础要求

- Flutter SDK，需满足 `pubspec.yaml` 中的 Dart SDK 约束。
- Windows 桌面运行需要 Visual Studio C++ 桌面开发工具链、CMake、NuGet。
- Android 构建需要 Android SDK、platform-tools 和 Gradle 环境。
- iOS/macOS 构建需要 macOS、Xcode 和对应签名环境。

### 可选环境变量

项目支持可选 `.env` 文件。复制 `.env.template` 为 `.env` 后按需填写：

```powershell
Copy-Item .env.template .env
```

常见配置项：

- `S3_ENDPOINT`
- `S3_BUCKET`
- `S3_REGION`
- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`
- `APP_FLAVOR`
- `API_BASE_URL`

未提供 `.env` 时，应用会使用代码中的默认配置或公开只读资源配置。

## 快速开始

安装依赖：

```bash
flutter pub get
```

Windows 桌面运行：

```bash
flutter run -d windows
```

PowerShell 快捷运行脚本：

```powershell
.\scripts\dev-run.ps1
```

常用参数：

```powershell
.\scripts\dev-run.ps1 -Clean
.\scripts\dev-run.ps1 -ResetAppState
.\scripts\dev-run.ps1 -Device windows
.\scripts\dev-run.ps1 -NoRun
```

## 构建

PowerShell 构建脚本会输出到 `dist/`：

```powershell
.\scripts\build.ps1 -Target windows
.\scripts\build.ps1 -Target android-apk
.\scripts\build.ps1 -Target android-appbundle
.\scripts\build.ps1 -Target android-apk,android-appbundle,windows
```

常用参数：

```powershell
.\scripts\build.ps1 -Target windows -Clean
.\scripts\build.ps1 -Target android-apk -BuildName 1.0.0 -BuildNumber 1
.\scripts\build.ps1 -Target windows -DryRun
```

Bash 构建脚本：

```bash
./scripts/build.sh --target linux
./scripts/build.sh --target android-apk
./scripts/build.sh --target android-appbundle
```

注意事项：

- `scripts/build.ps1` 已明确禁用 `web` target。当前应用依赖 `sqlite3`、`sherpa_onnx` 等 FFI 能力，不能直接作为 Flutter Web 构建。
- `scripts/build.sh` 仍保留 `web` 分支，使用前请确认目标平台依赖已经具备 Web 替代实现。
- Android 构建会使用项目局部 Gradle user home，减少用户全局 Gradle 缓存污染。

## 验证与测试

完整测试：

```bash
flutter test --reporter compact
```

静态检查和格式检查：

```powershell
.\scripts\verify-local-analysis.ps1
```

只检查指定目标：

```powershell
.\scripts\verify-local-analysis.ps1 -Task format-check,dart-analyze -Target lib/src/services
.\scripts\verify-local-analysis.ps1 -Task flutter-analyze -Target lib test
```

单个测试示例：

```bash
flutter test test/ui_smoke_test.dart --reporter compact
flutter test test/toolbox_audio_bank_regression_test.dart --reporter compact
```

提交前建议至少完成：

1. 文档改动：检查 Markdown 可读性和链接路径。
2. Dart/Flutter 改动：运行定向 `dart format`、`dart analyze` 或 `flutter analyze`。
3. 行为改动：补充或运行对应单元测试、Widget test、UI smoke test。
4. Toolbox UI 改动：额外核对 toolbox 设计规范、移动端首屏、触控区域、状态可读性。

## 数据与资源

- 内置词本资源位于 `assets/en_zh_15000_wordbook.json` 和 `dict/`。
- 运行期结构化数据以 SQLite 为主，仓储层位于 `lib/src/repositories/`。
- 每日决策等 toolbox 数据存在本地 JSON、SQLite 缓存和可延迟下载远端资源混合路径。
- 大资源默认不应随意加入安装包，优先考虑远端资源、懒加载、本地缓存和清晰的导入/导出边界。
- 品牌与图标资源位于 `assets/branding/`，启动图标由 `flutter_launcher_icons` 配置管理。

## 国际化与文案

- ARB 文件位于 `lib/l10n/`，当前包含中文、英文、日文、德文、西班牙文、法文等入口。
- 用户可见文本应优先进入统一文案或国际化管理，避免在 UI 中散落硬编码。
- 页面级文案和辅助 copy 可参考 `lib/src/ui/ui_copy.dart` 及相关页面局部 copy 文件。

## 开发规范

本仓库遵循根目录 `AGENTS.md` 中的项目代理规范，重点包括：

- 修改前先创建或更新 `plans/` 中的计划文档。
- 完成后先更新 `changelogs/CHANGELOG.md`，再回看当前进度。
- 文件编码使用 UTF-8，缩进 2 空格，Dart 命名遵循项目既有风格。
- 页面文件负责结构编排，复杂 UI 优先拆成 header、section、panel、controls、tokens、copy 等子文件。
- 涉及 toolbox UI 精修时，只动 UI 的任务不得混入播放、计时、持久化、状态机或数据模型逻辑。
- 单文件超过 1000 行属于禁止项，接近风险线时优先拆分职责。

## 文档索引

- `AGENTS.md`: 项目协作、计划、文档、UI 和提交规范。
- `PROJECT_DOMAIN.md`: 项目整体说明与领域边界。
- `modules/README.md`: 模块文档总览。
- `modules/module_system/README.md`: 模块系统说明。
- `modules/practice/README.md`: 练习模块说明。
- `modules/toolbox/README.md`: 工具箱模块说明。
- `docs/toolbox_design/TOOLBOX_DESIGN_REVIEW.md`: Toolbox 设计评审。
- `docs/toolbox_design/TOOLBOX_ANIMATION_SPEC.md`: Toolbox 动效规范。
- `docs/toolbox_design/TOOLBOX_UI_STYLE_GUIDE.md`: Toolbox UI 风格基线。
- `changelogs/CHANGELOG.md`: 项目变更日志。
- `plans/PLAN_TEMPLATE.md`: 计划文档模板。
- `decisions/DECISION_TEMPLATE.md`: 技术决策模板。

## 常见问题

### PowerShell 中中文显示乱码怎么办？

仓库文档按 UTF-8 保存。如果 PowerShell 输出中文乱码，优先用支持 UTF-8 的终端，或显式指定：

```powershell
Get-Content -Raw -Encoding UTF8 README.md
```

### 为什么 Web 构建不可用？

当前应用包含 SQLite FFI、离线 ASR、桌面/移动音频能力等依赖。它们没有完整 Web 替代实现前，Web 不是可靠目标。PowerShell 构建脚本已阻止 `web` target。

### 为什么有 `third_party` 依赖？

项目对 `audioplayers_android` 和 `flutter_tts` 有本地修补，用于满足当前音频回调、平台线程、TTS 行为等稳定性要求。升级这些依赖前应先阅读相关测试和 changelog。

### 可以直接提交全部未提交文件吗？

不建议。仓库常有多轮并行改动，提交前应确认改动范围，只暂存当前计划相关文件，避免把无关业务改动混入文档或小修提交。

## 协作流程

推荐每轮改动按以下节奏推进：

1. 阅读 `AGENTS.md`、相关模块 README、对应设计文档和现有代码。
2. 在 `plans/` 中创建计划，写清目标、步骤、风险和依赖。
3. 小步修改，优先复用现有模式和共享组件。
4. 运行与改动范围匹配的格式化、分析和测试。
5. 更新 `changelogs/CHANGELOG.md`。
6. 只暂存本轮相关文件并提交。

提交信息建议遵循：

```text
feat: 新功能
fix: 修复问题
docs: 文档更新
style: 代码格式调整
refactor: 重构
test: 测试相关
chore: 构建或工具变更
```

## License

See `LICENSE`.
