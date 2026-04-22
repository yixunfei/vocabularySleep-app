# Vocabulary Sleep App

一个以「学习 + 训练 + 专注 + 睡眠支持 + 工具箱」为核心的 Flutter 综合性项目。  
项目目标不是单一功能 App，而是一个可持续扩展、可模块化插拔的多域能力平台。

## 项目定位

- 面向移动端优先的综合应用，覆盖学习、练习、专注、放松、睡眠等连续场景。
- 采用模块化能力开关机制，支持按域启停、按需演进和逐步解耦。
- 以本地优先为主线，兼顾在线资源下载与缓存预热。

## 顶层模块（导航层）

| 模块 | 作用 | 当前能力概览 |
| --- | --- | --- |
| `study` | 学习中枢 | 播放与词库双入口、词条浏览、学习路径衔接 |
| `practice` | 训练中枢 | 多题型练习、错题与历史、练习会话管理 |
| `focus` | 专注中枢 | 专注计时、待办与笔记、提醒与锁屏专注流程 |
| `toolbox` | 工具中枢 | 睡眠支持、声音工具、减压训练、小游戏与决策工具 |
| `more` | 配置中枢 | 设置、数据管理、模块管理、语言与语音能力入口 |

> 模块 ID、注册关系、父子边界定义见：`lib/src/core/module_system/`

## Toolbox 子模块能力

Toolbox 当前按「场景分组 + 子模块独立入口」组织，主要能力如下：

| 模块 ID | 名称 | 功能说明 |
| --- | --- | --- |
| `toolbox.sleep_assistant` | 睡眠助手 | 评估、记录、睡前流程、夜醒救援、报告 |
| `toolbox.mini_games` | 小游戏中心 | 数独、扫雷、拼图等轻量训练 |
| `toolbox.soothing_music` | 舒缓音乐 | 本地曲目与沉浸式视觉组合 |
| `toolbox.sound_deck` | 乐器工具集 | 竖琴/钢琴/长笛/鼓垫/吉他/三角铁/小提琴等 |
| `toolbox.singing_bowls` | 疗愈音钵 | 共振音色与移动端操作面板 |
| `toolbox.focus_beats` | 专注节拍 | 节拍训练与循环编排 |
| `toolbox.woodfish` | 电子木鱼 | 触发、计数、反馈与轻仪式化 reset |
| `toolbox.schulte_grid` | 舒尔特方格 | 视觉搜索与注意力训练 |
| `toolbox.breathing` | 呼吸训练 | 专注/放松/睡前等场景呼吸流程 |
| `toolbox.prayer_beads` | 静心念珠 | 节奏化计数与减压 |
| `toolbox.zen_sand` | 禅意沙盘 | 触控绘制、沙纹反馈与静心交互 |
| `toolbox.daily_decision` | 每日决策 | 转盘式快速决策工具 |

## 架构与模块化设计

### 1. 模块系统（Module System）

- `ModuleIds`：统一管理模块标识。
- `ModuleRegistry`：注册模块元数据（分组、父子关系、可禁用性）。
- `ModuleRuntimeGuard` + UI 路由守卫：确保禁用模块不可进入。
- `module_access.dart`：统一禁用态文案与导航拦截入口。

### 2. 应用装配（App Bootstrap）

- `main.dart` 负责启动与环境变量初始化（`.env` 可选）。
- `AppDependencies` 统一装配数据库、服务、仓储、状态实例。
- `AppState` 作为当前主状态入口，正在持续推进域级拥有权拆分。

### 3. 数据与能力层

- 数据层：SQLite（`sqlite3` + `sqlite3_flutter_libs`）为主。
- 服务层：播放、TTS、ASR、环境音、提醒、日历、专注服务等。
- 仓储层：按实践域拆分（wordbook/practice/ambient/focus/sleep 等）。
- 状态管理：`ChangeNotifier` + `Provider` + `Riverpod` 组合接入。

## 目录概览

```text
lib/
  main.dart
  src/
    app/                # 启动装配与依赖注入
    core/module_system/ # 模块系统
    repositories/       # 数据仓储边界
    services/           # 业务服务能力
    state/              # 应用状态层
    ui/                 # 页面、组件、主题、文案
assets/                 # 静态资源（品牌、词本、toolbox 资源）
dict/                   # 词典与词本数据
docs/                   # 设计规范与工程文档
modules/                # 分域模块说明文档（模块化推进记录）
plans/                  # 计划文档
records/                # 过程记录与回归记录
changelogs/             # 变更日志
scripts/                # 构建、运行与验证脚本
test/                   # 单元/Widget/集成相关测试
```

## 快速开始

### 环境要求

- Flutter SDK（Dart 3.11+）
- Android Studio / Xcode / Visual Studio（按目标平台准备）

### 本地运行

```bash
flutter pub get
flutter run -d windows
```

PowerShell 快捷方式：

```powershell
.\scripts\dev-run.ps1
```

## 构建命令

PowerShell：

```powershell
.\scripts\build.ps1 -Target windows
.\scripts\build.ps1 -Target android-apk
.\scripts\build.ps1 -Target android-apk,android-appbundle,windows
```

Bash：

```bash
./scripts/build.sh --target linux
./scripts/build.sh --target web
./scripts/build.sh --target android-apk --target android-appbundle
```

## 回归与质量验证

```bash
flutter test --reporter compact
```

本地静态检查辅助脚本：

```powershell
.\scripts\verify-local-analysis.ps1
```

## 相关文档

- 项目域说明：`PROJECT_DOMAIN.md`
- 代理协作规范：`AGENTS.md`
- 模块化记录：`modules/README.md`
- toolbox 设计规范：
  - `docs/toolbox_design/TOOLBOX_DESIGN_REVIEW.md`
  - `docs/toolbox_design/TOOLBOX_ANIMATION_SPEC.md`
  - `docs/toolbox_design/TOOLBOX_UI_STYLE_GUIDE.md`
- 变更日志：`changelogs/CHANGELOG.md`

## 协作与提交建议

- 提交信息建议遵循：`feat` / `fix` / `refactor` / `docs` / `test` / `chore`
- 涉及结构性改动时，优先补充 `plans/` 与 `records/` 文档
- 涉及 toolbox UI 收敛时，请同步遵守 `docs/toolbox_design/` 规范

## License

See `LICENSE`.
