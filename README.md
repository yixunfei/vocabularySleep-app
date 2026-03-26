# 咸鱼声息 Flutter App

咸鱼声息是一个围绕「词汇学习、播放输入、练习巩固、专注计时、待办笔记、环境音助眠」构建的 Flutter 多平台应用。  
项目当前以桌面端和安卓打包为主，核心目标是把“听、练、记、专注”串成一条连续学习路径。

## 应用简介

当前版本包含这些核心能力：

- 学习页：将“播放”和“词库”合并为二级页，便于在同一入口内切换听词与查词
- 播放页：支持连续播放、上次播放进度恢复、大词库精确跳转、环境音混音
- 词库页：支持 SQL 搜索、分页、前缀跳转，并默认定位到当前单词
- 练习页：支持多种题型、错题本、练习历史、轮次设置与答题反馈
- 专注页：支持番茄钟、待办、笔记、环境音、提醒与锁屏专注模式
- 数据管理：支持导入/导出、备份/恢复、词本迁移与用户数据重置
- 环境音：内置离线环境音 + Moodist 在线资源目录解析下载
- 语音能力：TTS、跟读识别、离线 ASR / 本地评分包准备与管理

## 截图

> 当前仓库已包含几张界面截图，下面直接引用现有文件。

### 学习 / 播放
![学习页预览](image.png)

### 练习 / 专注
![练习页预览](image-1.png)

### 数据与设置
![设置页预览](image-2.png)

### 其他界面
![其他界面预览](image-3.png)

## 编译与打包

### 环境要求

- Flutter SDK
- Dart SDK
- 对应平台的原生构建环境
  - Windows: Visual Studio C++ Build Tools, CMake
  - Android: Android SDK / Android Studio
  - macOS / iOS: Xcode
  - Linux: clang / ninja / GTK 相关依赖

### 本地运行

```bash
flutter pub get
flutter run -d windows
```

Windows 下也可以使用辅助脚本：

```powershell
.\scripts\dev-run.ps1
```

### 标准打包脚本

PowerShell:

```powershell
.\scripts\build.ps1 -Target windows
.\scripts\build.ps1 -Target android-apk
.\scripts\build.ps1 -Target android-apk,android-appbundle,windows
```

Bash:

```bash
./scripts/build.sh --target linux
./scripts/build.sh --target web
./scripts/build.sh --target android-apk --target android-appbundle
```

### `scripts/build.*` 当前支持的目标

按宿主平台区分：

- Windows 主机：`android-apk` / `android-appbundle` / `windows` / `web`
- macOS 主机：`android-apk` / `android-appbundle` / `ios` / `macos` / `web`
- Linux 主机：`android-apk` / `android-appbundle` / `linux` / `web`

打包产物会复制到 [dist](D:/workspace/opensource/vocabularySleep-app/flutter_app/dist) 目录。

## 用户指南

### 1. 学习页

- 顶部二级切换为“播放 / 词库”
- 词库页默认会定位到当前单词
- 播放页会默认恢复到上次播放进度附近的单词
- 播放页下方提供更适合大词库的进度控制：
  - 归一化滑动条
  - 粗步长快跳
  - 精确跳转输入框

### 2. 练习页

- 可以从当前范围、整本词库、错题本、任务词、收藏词等来源发起练习
- 支持题型切换、自动发音、错题加入、练习轮次与起始位置设置
- 完成答题后可根据反馈继续下一题或回收错题

### 3. 专注页

- 支持番茄钟、待办与笔记
- 支持提醒、语音播报、环境音、锁屏专注
- 环境音入口中可以：
  - 导入本地音频
  - 打开白噪音资源目录
  - 下载资源到本地
  - 若本地已存在则直接删除

### 4. 工具箱页

- 当前为预留空白页
- 现阶段显示 `TODO`
- 预期后续承载各类独立工具能力

### 5. 数据管理与安全

- 支持导入词本、在线词本下载导入、旧数据库迁移
- 支持导出用户数据与任务词本
- 支持安全备份、恢复备份、删除备份
- 重置用户数据前会优先尝试创建安全备份

## 项目结构

主要目录：

- [lib/main.dart](D:/workspace/opensource/vocabularySleep-app/flutter_app/lib/main.dart)：应用入口
- [lib/src/app](D:/workspace/opensource/vocabularySleep-app/flutter_app/lib/src/app)：依赖装配与根应用
- [lib/src/state](D:/workspace/opensource/vocabularySleep-app/flutter_app/lib/src/state)：全局状态与业务编排
- [lib/src/services](D:/workspace/opensource/vocabularySleep-app/flutter_app/lib/src/services)：数据库、播放、环境音、识别、提醒等服务
- [lib/src/ui](D:/workspace/opensource/vocabularySleep-app/flutter_app/lib/src/ui)：页面、组件、主题与界面文案
- [assets](D:/workspace/opensource/vocabularySleep-app/flutter_app/assets)：品牌资源、环境音与静态词本资源
- [dict](D:/workspace/opensource/vocabularySleep-app/flutter_app/dict)：内置词库 JSON
- [scripts](D:/workspace/opensource/vocabularySleep-app/flutter_app/scripts)：运行、构建、日志辅助脚本
- [test](D:/workspace/opensource/vocabularySleep-app/flutter_app/test)：状态逻辑、数据库与 UI 烟测

## 外部开源资源与使用位置

### 运行时依赖

| 资源 | 用途 | 使用位置 |
| --- | --- | --- |
| Flutter | UI 框架与跨平台运行时 | 整个项目 |
| provider | 状态注入与界面监听 | `lib/src/app`、`lib/src/ui` |
| sqlite3 / sqlite3_flutter_libs | 本地 SQLite 存储 | `lib/src/services/database_service.dart` |
| path_provider / path | 应用目录、缓存与导出路径管理 | `database_service.dart`、`tts_service.dart`、`online_ambient_catalog_service.dart` |
| http | 在线词本、天气、白噪音目录与下载请求 | `wordbook_management_page.dart`、`weather_service.dart`、`online_ambient_catalog_service.dart` |
| file_picker | 导入词本、导入音频、导入背景图等 | `app_state.dart`、各设置/管理页面 |
| flutter_tts | 本地 TTS | `lib/src/services/tts_service.dart` |
| audioplayers | 音频播放与环境音循环 | `lib/src/services/ambient_service.dart`、`tts_service.dart` |
| record | 录音 | `lib/src/services/asr_service.dart` |
| sherpa_onnx | 离线 ASR / 语音评分底层 | `lib/src/services/asr_service.dart` |
| dict_reader | MDX 词典导入 | `lib/src/services/wordbook_import_service.dart` |
| csv | CSV 词本解析 | `wordbook_import_service.dart` |
| intl | 本地化与格式辅助 | 多页面日期/文本处理 |
| collection | 集合辅助扩展 | 多个 state/service 模块 |
| uuid | 环境音与临时资源唯一 ID | `ambient_service.dart` |
| archive | 模型包解压 | `asr_service.dart` |
| crypto | 缓存与资源校验 | `asr_service.dart`、`tts_service.dart` |
| flutter_localizations | Flutter 官方多语言支持 | `app_root.dart` |
| cupertino_icons | iOS 风格图标 | 全局 UI |

### 开发与构建依赖

| 资源 | 用途 | 使用位置 |
| --- | --- | --- |
| flutter_test | 单元测试 / Widget 测试 | `test/` |
| flutter_lints | 代码规范 | 项目静态检查 |
| flutter_launcher_icons | 多平台图标生成 | `pubspec.yaml` |
| fake_async | 测试中的时间控制 | 测试代码 |
| path_provider_platform_interface / plugin_platform_interface | 插件测试与平台接口支撑 | 测试 / 构建依赖 |

### 外部开源内容资源

| 资源 | 地址 | 使用位置 |
| --- | --- | --- |
| Moodist | [moodist.mvze.net](https://moodist.mvze.net/) / [GitHub](https://github.com/remvze/moodist) | 内置环境音素材来源、在线白噪音目录解析、下载回退源 |
| GPT-WordBooks | [GitHub / yixunfei / GPT-WordBooks](https://github.com/yixunfei/GPT-WordBooks) | 在线词本选择与下载导入，部分词库整理参考 |
| sherpa-onnx 模型与发布 | [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) | 离线识别模型与评分包下载 |

### 公开在线服务接口

> 下列接口被项目调用，但不视为“项目内置开源资源”。

| 服务 | 用途 | 使用位置 |
| --- | --- | --- |
| ipwho.is | 近似城市定位 | `lib/src/services/weather_service.dart` |
| Open-Meteo | 天气查询 | `weather_service.dart` |
| SiliconFlow API | 远程 TTS / ASR（按用户配置启用） | `tts_service.dart`、`asr_service.dart` |

## 特别鸣谢

- [Flutter](https://flutter.dev/) 与 Dart 生态
- [remvze/moodist](https://github.com/remvze/moodist) 提供高质量环境音素材与在线资源目录参考
- [yixunfei/GPT-WordBooks](https://github.com/yixunfei/GPT-WordBooks) 提供词本来源参考
- [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) 提供离线语音识别能力
- 所有依赖库的维护者与贡献者

## AI 协作说明

本项目在持续开发过程中使用了 AI 辅助工具参与以下工作：

- 代码重构与页面拆分
- SQLite 结构迁移与表驱动改造
- 播放/练习/环境音交互流程设计
- 文案整理与 README 编写
- 测试补全与回归检查

当前主要协作方式为本地仓库内的人机协同开发，AI 负责提出补丁、编写测试与整理文档，人类开发者负责需求判断、结果验收与最终合并。

## 当前说明

- 当前仓库的 Git 历史仍处于一次未完成的 interactive rebase 中，但工作树可以保持干净并继续开发
- 若继续整理提交历史，请在确认当前代码稳定后自行处理 `git rebase --continue`
