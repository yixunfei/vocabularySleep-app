# flutter_app 阶段复评报告

审计日期：2026-03-11

审计对象：`D:\workspace\opensource\vocabularySleep-app\flutter_app` 当前工作树

审计口径：本报告基于当前未提交代码、未跟踪文件和最新工作目录状态重新评估，不以历史提交版本为准。

## 1. 本轮复评范围

重点复核模块：

- 数据层与导入链路：
  - `lib/src/services/database_service.dart`
  - `lib/src/services/wordbook_import_service.dart`
  - `lib/src/models/word_entry.dart`
  - `lib/src/models/word_field.dart`
- 状态层：
  - `lib/src/state/app_state.dart`
- 核心页面：
  - `lib/src/ui/pages/library_page.dart`
  - `lib/src/ui/pages/voice_settings_page.dart`
  - `lib/src/ui/pages/recognition_settings_page.dart`
  - `lib/src/ui/pages/word_editor_page.dart`
- 资源与配置：
  - `pubspec.yaml`
  - `dict/`
- 测试：
  - `test/`
  - `coverage/lcov.info`

执行结果：

- `flutter analyze`：通过，`No issues found`
- `flutter test -r expanded`：通过，当前全量用例 `15` 条
- `flutter test --coverage`：通过
- 覆盖率：`LF=7409`、`LH=1300`、总覆盖率 `17.55%`

## 2. 总体结论

当前版本相较前一轮已经有明显进步：

- 旧库迁移后会恢复特殊词本和内建词本
- 编辑保存失败不再误退出
- 远程 TTS 配置已接入当前前台
- 离线 ASR 模型与评分包管理已接入当前识别设置页
- 词库页进一步演进到 `CustomScrollView + SliverList`
- 搜索加入防抖，`visibleWords` 加入缓存
- UI 冒烟测试和字段清洗测试已补入

因此，这个版本已经从“结构性重构阶段”进入“补功能闭环 + 补体验稳定性”的阶段。

但当前仍有两个最值得优先处理的风险：

1. `dict/` 下约 `95.74 MB` 大词典资源已被加入 `pubspec` 资产清单，但当前代码中未发现运行链路引用
2. 新增的 `sanitizeDisplayText()` 会无差别清除剩余反斜杠，存在静默改写内容的风险

综合评级：

| 维度 | 评级 | 结论 |
| --- | --- | --- |
| 功能性 | B | 关键主流程比上一轮完整，设置闭环明显改善 |
| 性能 | B- | 词库页与搜索链路已有实质优化，但包体与数据层仍有风险 |
| 用户体验 | B- | 页面结构更成熟，但资源策略和文本清洗副作用需要收口 |
| 代码质量 | C+ | 方向正确，但部分实现仍有隐性代价 |
| 测试成熟度 | C- | 已从纯逻辑测试升级到 5 个测试文件，但仍缺少集成级保护 |

是否建议按当前版本直接作为稳定阶段提交：

- 不建议直接作为“稳定验收版”提交
- 若是内部迭代提交，建议至少先明确 `dict/` 资源策略，并收敛文本清洗规则

## 3. 主要发现

### 3.1 [高] `dict/` 大资源已进入打包清单，但当前代码中未发现实际使用链路

位置：

- [pubspec.yaml:90](D:\workspace\opensource\vocabularySleep-app\flutter_app\pubspec.yaml:90)

证据：

- `pubspec.yaml` 已新增 `- dict/`
- `dict/` 目录当前共约 `95.74 MB`
- 文件包括：
  - `中英_12000.json`：约 `32.39 MB`
  - `中德_12000.json`：约 `12.31 MB`
  - `中法_12000.json`：约 `10.86 MB`
  - `中俄_12000.json`：约 `10.23 MB`
  - `中日_12000.json`：约 `9.78 MB`
  - `中世_12000.json`：约 `9.10 MB`
  - `英法_12000.json`：约 `11.07 MB`
- 本轮搜索 `lib/**/*.dart` 未发现 `dict/`、`中英_12000`、`rootBundle.loadString('dict/...')` 等引用

风险：

- 即使当前前台未使用，这批资源也会进入应用资产包
- 会直接推高安装包体积、构建产物体积、冷启动资源清单体积和分发成本
- 在移动端场景下，这是实打实的性能与发行风险
- 当前代码里没有对应功能入口，意味着成本已落地，收益尚未落地

建议：

1. 若这批词典只是后续计划资源，先从 `pubspec.yaml` 资产列表移除
2. 若确实需要离线内置，改成按需下载或首次解包，而不是首包全量携带
3. 若准备接入内置词库浏览/导入，先补最小可见功能路径，再决定是否保留全量打包

### 3.2 [中高] `sanitizeDisplayText()` 当前会无差别删除剩余反斜杠，存在数据静默变形风险

位置：

- [word_field.dart:231](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\models\word_field.dart:231)
- [word_field.dart:247](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\models\word_field.dart:247)
- [word_entry.dart:116](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\models\word_entry.dart:116)
- [word_entry.dart:162](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\models\word_entry.dart:162)
- [word_entry.dart:172](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\models\word_entry.dart:172)
- [wordbook_import_service.dart:242](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\services\wordbook_import_service.dart:242)
- [wordbook_import_service.dart:255](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\services\wordbook_import_service.dart:255)
- [word_field_sanitization_test.dart:6](D:\workspace\opensource\vocabularySleep-app\flutter_app\test\word_field_sanitization_test.dart:6)
- [word_field_sanitization_test.dart:16](D:\workspace\opensource\vocabularySleep-app\flutter_app\test\word_field_sanitization_test.dart:16)

证据：

- `sanitizeDisplayText()` 先处理 `\n`、`\t`、`\"`、`\/`
- 随后又执行：
  - `text = text.replaceAll(RegExp(r'\\\\+'), '');`
- 这意味着所有剩余反斜杠都会被删除
- 当前新增测试明确把 `B\\C` 期望为 `BC`

风险：

- 这不是“显示转义”这么简单，而是内容级改写
- 一些原本合法的文本会被静默损坏：
  - 路径
  - 正则/转义示例
  - 某些导入来源中的原始文本
  - 用户手工维护的带反斜杠字段
- 因为清洗被接到了导入、字段归一化和数据库读取模型层，一旦用户再次保存，变形内容可能被持久化

建议：

1. 只处理确定的脏转义序列，不要全量删除剩余反斜杠
2. 将“显示清洗”和“持久化清洗”拆开
3. 增加反例测试：
   - `C:\\Users\\foo`
   - `\\w+`
   - `A\\B`
   - Markdown/LaTeX 风格文本
4. 如果业务明确允许清除，应在需求层写清楚“仅针对某类脏数据导入”

### 3.3 [中] 测试覆盖已进步，但离集成级质量保护仍有距离

位置：

- [ui_smoke_test.dart:19](D:\workspace\opensource\vocabularySleep-app\flutter_app\test\ui_smoke_test.dart:19)
- [word_field_sanitization_test.dart:6](D:\workspace\opensource\vocabularySleep-app\flutter_app\test\word_field_sanitization_test.dart:6)

现状：

- 当前 `test/` 下已有 5 个测试文件：
  - `app_state_logic_test.dart`
  - `sanity_test.dart`
  - `settings_service_test.dart`
  - `ui_smoke_test.dart`
  - `word_field_sanitization_test.dart`
- 全量测试通过，覆盖率提升到 `17.55%`

问题：

- 当前新增测试仍主要覆盖：
  - 页面存在性
  - 标签可见性
  - 文本清洗函数
- 还没有覆盖关键跨链路场景：
  - 大词典资源是否真正接通功能入口
  - 导入后文本是否被过度清洗
  - 词库分页/回顶/索引弹层的长链路交互
  - TTS / ASR 设置保存后的真实服务调用链

建议：

1. 增加导入链路测试，直接验证原始记录到 `WordEntryPayload` 的保真性
2. 为词库页补交互型 widget test：
   - 搜索防抖
   - 加载更多
   - 索引弹层
   - 回顶锚点
3. 逐步增加 integration test，至少覆盖：
   - 打开设置页
   - 切换 TTS provider
   - 下载/删除离线包

### 3.4 [中低] 编辑器字段标签仍未统一到多语言文案体系

位置：

- [word_editor_page.dart:309](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\word_editor_page.dart:309)
- [word_editor_page.dart:315](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\word_editor_page.dart:315)
- [word_editor_page.dart:323](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\word_editor_page.dart:323)

现象：

- `Label / Key / Content` 仍为硬编码英文

影响：

- 会与当前逐步完善的中英文切换体验形成割裂
- 不是阻塞项，但会拉低完成度

## 4. 已确认修复和改善的项

### 4.1 迁移后特殊词本/内建词本恢复问题已修复

位置：

- [database_service.dart:703](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\services\database_service.dart:703)
- [database_service.dart:712](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\services\database_service.dart:712)

结论：

- 旧库导入后现在会重算 `word_count`
- 会补执行 `ensureSpecialWordbooks()`
- 会补执行 `seedBuiltInWordbooks()`

### 4.2 编辑保存失败后误退出的问题已修复

位置：

- [app_state.dart:571](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\state\app_state.dart:571)
- [word_editor_page.dart:96](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\word_editor_page.dart:96)

结论：

- `saveWord()` 已返回 `bool`
- 编辑页只在成功时关闭

### 4.3 远程 TTS 配置已前移到当前前台

位置：

- [voice_settings_page.dart:156](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\voice_settings_page.dart:156)
- [voice_settings_page.dart:257](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\voice_settings_page.dart:257)
- [voice_settings_page.dart:366](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\voice_settings_page.dart:366)

结论：

- provider、本地 voice、远程 model/voice、custom baseUrl/apiKey 等路径已补齐

### 4.4 离线 ASR 模型与评分包管理已进入当前识别设置页

位置：

- [recognition_settings_page.dart:116](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\recognition_settings_page.dart:116)
- [recognition_settings_page.dart:165](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\recognition_settings_page.dart:165)
- [recognition_settings_page.dart:562](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\recognition_settings_page.dart:562)

结论：

- 这项之前“服务层有能力、前台不可达”的问题已修复

### 4.5 词库页性能结构继续向正确方向演进

位置：

- [app_state.dart:155](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\state\app_state.dart:155)
- [library_page.dart:60](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\library_page.dart:60)
- [library_page.dart:498](D:\workspace\opensource\vocabularySleep-app\flutter_app\lib\src\ui\pages\library_page.dart:498)

结论：

- `visibleWords` 已有缓存
- 搜索已加入 160ms 防抖
- 页面已用 `SliverList` 承载列表区

## 5. 详细反馈方案

### Phase A：先收口当前最值得优先处理的两件事

1. 明确 `dict/` 的产品定位
2. 明确 `sanitizeDisplayText()` 的边界

建议动作：

1. 若 `dict/` 暂不上线：
   - 先从 `pubspec.yaml` 移除
   - 保留文件在仓库或独立资源目录，但不要首包携带
2. 若 `dict/` 要上线：
   - 先补最小可见功能链路
   - 再决定是内置、首启解压还是远程下载
3. 对文本清洗：
   - 改成白名单式清洗
   - 保留合法反斜杠
   - 分离“导入修正”和“显示格式化”

### Phase B：巩固已补上的体验链路

建议动作：

1. 为 TTS / ASR 当前前台配置补持久化与回读测试
2. 为词库页补以下交互测试：
   - 搜索防抖
   - 索引弹层
   - 回顶按钮
   - 加载更多
3. 把编辑器的硬编码字段标签并入统一文案体系

### Phase C：继续推进性能与发布质量

建议动作：

1. 把词库筛选和分页进一步前推到数据层
2. 控制一级页对 `AppState` 的整页监听范围
3. 提前做一次 release 包体评估，确认 `dict/` 对 APK / AAB 的实际影响

## 6. 建议的验证清单

建议在下一轮修改后至少做以下验证：

1. 检查 release 构建前后包体变化
2. 导入包含合法反斜杠文本的数据，确认不会被误删
3. 进入语音设置页，验证：
   - provider 切换
   - model / voice 选择
   - custom API 字段保存
4. 进入识别设置页，验证：
   - 离线模型下载/删除
   - 评分包下载/删除
5. 在大词库场景下验证：
   - 搜索输入流畅度
   - 索引入口可达性
   - 回顶行为

## 7. 最终判断

当前版本的方向是对的，而且比上一轮更接近“可交付的移动端产品版本”。

真正需要优先处理的，不再是之前那些已经修掉的功能闭环问题，而是这两个更隐蔽但更容易在发布后放大的风险：

1. `dict/` 资源策略不清晰，当前是先付成本、后谈收益
2. 文本清洗策略过于激进，存在静默改写内容的可能

如果这两项先收好，再配合本轮已经增加的测试基础继续往前推，我会更愿意把这个版本判断为“可以进入稳定提交候选”的状态。
