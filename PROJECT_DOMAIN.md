# 项目整体说明文档

## 文档版本
- **版本**: v0.0.6
- **更新日期**: 2026-04-11
- **状态**: 待完善

---

## 项目基本信息

| 项目属性 | 说明 |
|----------|------|
| 项目名称 | (待填写) |
| 项目类型 | Flutter 移动应用 |
| 目标平台 | iOS / Android |
| 最低版本 | (待填写) |
| 当前版本 | (待填写) |

---

## 项目背景与目标

### 项目背景
(待分析填写 - 请描述项目起源、核心需求来源)

### 核心目标
1. (待填写)
2. (待填写)
3. (待填写)

### 目标用户
- 主要用户群体: (待填写)
- 用户场景: (待填写)

---

## 技术栈

### 框架与语言
| 组件 | 版本 | 说明 |
|------|------|------|
| Flutter SDK | (待填写) | |
| Dart | (待填写) | |
| 状态管理 | (待选择) | flutter_bloc / riverpod / provider |
| 路由管理 | (待选择) | go_router / auto_route |
| 网络请求 | (待选择) | dio / http |

### 主要依赖
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # 状态管理 (选择其一)
  flutter_bloc: ^8.1.3
  riverpod: ^2.4.9
  provider: ^6.1.1
  
  # 网络
  dio: ^5.4.0
  
  # 本地存储
  hive: ^2.2.3
  sqflite: ^2.3.0
  
  # 图片
  cached_network_image: ^3.3.0
  
  # UI组件
  flutter_slidable: ^3.0.1
```

---

## 项目结构

### 目录结构
```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 应用配置
├── core/                     # 核心模块
│   ├── constants/            # 常量定义
│   ├── theme/                # 主题配置
│   ├── utils/                # 工具类
│   └── extensions/           # 扩展方法
├── l10n/                     # 国际化资源
│   ├── app_en.arb
│   └── app_zh.arb
├── data/                     # 数据层
│   ├── models/               # 数据模型
│   ├── repositories/          # 数据仓库
│   ├── providers/            # 数据提供者
│   └── datasources/          # 数据源
│       ├── local/            # 本地数据源
│       └── remote/           # 远程数据源
├── domain/                   # 业务域
│   └── (按业务域组织)
├── presentation/             # 表现层
│   ├── pages/                # 页面
│   ├── widgets/              # 组件
│   └── blocs/                # 状态管理
└── services/                 # 服务层
    ├── navigation/           # 导航服务
    ├── storage/              # 存储服务
    └── network/              # 网络服务

scripts/
├── verify-local-analysis.ps1         # 本地格式与 analyze 验证工具箱
├── opencode-minimax-m27.ps1          # 固定调用 MiniMax-M2.7 的命令模板
├── orchestrate-opencode-models.ps1   # 多模型 fan-out 调度脚本
└── opencode-model-profiles.json      # 外部模型 profile 映射配置
```

### 架构模式
- **状态管理**: (待选择: BLoC / Riverpod / Provider)
- **数据流**: (单向数据流)
- **依赖注入**: (待选择: get_it / riverpod / 手动)

### 开发辅助工具
- 当前仓库已内置本地验证脚本与 `opencode` 外部模型协作脚本，供开发期分析、方案草拟、并行对比和调度使用。
- 外部模型输出仅作为辅助参考，不应直接替代对业务代码、架构边界和实际仓库上下文的本地判断。
- 多模型调度默认将结果写入工作区 `.tmp_model_runs/`，便于后续复查与归档。

### toolbox 设计文档
- `docs/toolbox_design/TOOLBOX_DESIGN_REVIEW.md`: 工具箱模块设计评审与问题清单。
- `docs/toolbox_design/TOOLBOX_ANIMATION_SPEC.md`: 工具箱动效规范与节奏建议。
- `docs/toolbox_design/TOOLBOX_UI_STYLE_GUIDE.md`: 当前生效的 toolbox UI 设计基线，用于约束后续“只动 UI、不动逻辑”的精修方向。

---

## 功能模块

### 核心功能清单
| 模块 | 优先级 | 状态 | 备注 |
|------|--------|------|------|
| (待填写) | (待定) | 待开发 | |

### 功能特性矩阵
(待完善 - 根据实际业务需求补充)

---

## 导航与交互

### 页面导航结构
```
首页 (HomePage)
├── 页面A (PageA)
│   └── 详情页A1 (DetailA1Page)
├── 页面B (PageB)
│   └── 详情页B1 (DetailB1Page)
└── 设置 (SettingsPage)
    ├── 主题设置 (ThemePage)
    └── 关于 (AboutPage)
```

### 移动端交互规范
- **抽屉(Drawer)**: 用于次要导航和设置
- **子页面**: 用于详情和表单填写
- **BottomSheet**: 用于快速选择和操作
- **SnackBar**: 用于操作反馈

---

## 本地化

### 支持语言
| 语言 | 代码 | 状态 |
|------|------|------|
| 中文 | zh | 计划中 |
| English | en | 计划中 |

### 本地化范围
- 用户界面文本
- 日期时间格式
- 数字格式
- 货币格式 (如适用)

---

## API 规范

### API 基础配置
```dart
// 待填写
const apiBaseUrl = 'https://api.example.com';
const apiTimeout = Duration(seconds: 30);
```

### 接口版本策略
(待制定)

---

## 数据存储

### 本地存储策略
| 数据类型 | 存储方案 | 说明 |
|----------|----------|------|
| 用户配置 | SharedPreferences / Hive | 轻量键值 |
| 业务数据 | SQLite | 结构化数据 |
| 缓存数据 | Hive | 离线可用 |
| 媒体文件 | 本地文件系统 | 按需存储 |

### 单词本数据规范
- 新的标准化单词本统一采用 `wordbook.v1` 结构。
- 标准文档位于 `docs/wordbooks/WORDBOOK_STANDARD.md`。
- 2026-04-11 起，单词本主链路已按“核心字段 + 动态扩展字段”重建：`word + meaning` 为核心字段，其他字段按每条词的实际内容动态入库、展示和播放。
- 当前词本数据库承载已经支持 `wordbooks.schema_version / metadata_json` 以及 `words.entry_uid / primary_gloss / schema_version / source_payload_json / sort_index`，并配套 `word_fields / word_field_tags / word_field_media` 子表承载灵活扩展字段。
- 内置词本目录现已恢复，可从本地 asset 目录发现并建立懒加载占位；真实导入时支持从本地文件或字节流解析，后续可平滑切换到 S3/远端词本源。
- 大词本运行态继续采用“轻量列表 + 按需详情 + 懒加载 built-in”的策略，避免在移动端启动时无条件把整本词典一次性加载进 UI 内存。

---

## 性能目标

| 指标 | 目标值 |
|------|--------|
| 冷启动时间 | < 2秒 |
| 页面切换时间 | < 300ms |
| APK大小 (Release) | < 20MB |
| 内存占用 | < 150MB |

---

## 潜在风险

### 已识别风险
| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| (待填写) | (待评估) | (待制定) |

---

## 待决策项

| 决策点 | 选项 | 状态 |
|--------|------|------|
| 状态管理方案 | flutter_bloc / riverpod / provider | 待选择 |
| 路由方案 | go_router / auto_route / Navigator | 待选择 |
| 离线策略 | 全量缓存 / 按需缓存 / 仅在线 | 待选择 |
| 推送通知 | (待选择第三方服务) | 待选择 |

---

## 更新记录

| 日期 | 版本 | 更新内容 |
|------|------|----------|
| 2026-04-08 | v0.0.1 | 初始创建文档 |
| 2026-04-09 | v0.0.2 | 补充单词本标准化规范入口 |
| 2026-04-10 | v0.0.3 | 补充 `opencode` 多模型协作脚本与开发辅助工具说明 |
| 2026-04-10 | v0.0.4 | 新增 toolbox UI 设计规范基线文档入口 |
| 2026-04-10 | v0.0.5 | 标记旧单词本导入解析与导出恢复链路已临时下线，等待整体重写 |
| 2026-04-11 | v0.0.6 | 同步单词本与播放模块重建结果，恢复导入、导出恢复、built-in 目录和动态字段播放说明 |

---

## 备注
- 本文档需要根据项目实际情况持续更新
- 每次重大修改后应同步更新版本号
- 建议在每次迭代结束时回顾和更新本文档
