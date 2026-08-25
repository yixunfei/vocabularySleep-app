# 计划 418: 单词学习练习性能分阶段优化

## 基本信息
- **创建日期**: 2026-08-25
- **状态**: 进行中（阶段 1-5 已完成，阶段 6 进行中）
- **负责人**: Codex

## 目标
解决大词本（已用中英 12000 词本验证）进入单词表、学习、练习后主线程持续卡顿的问题，优先切断播放切词对其他模块的全局重建放大，再逐步降低播放 hydrate、练习会话和数据库加载的同步成本。

## 详细步骤
1. **阶段 0：备份基线**。提交当前工作区全部改动，保留可回滚基线。已完成，备份提交 `1c2d62a8`。
2. **阶段 1：隔离播放广播**。收窄 AppShell、Root、Study、Practice 等页面的状态选择器；隐藏页面不因播放位置变化执行昂贵 token/build。保持当前页、迷你播放器和播放控制的即时更新。已完成，提交前验证通过。
3. **阶段 2：播放 hydrate 收敛**。避免切词时复制整份词表和重新查询整本记忆进度，改为当前词详情/有界缓存的增量更新。
4. **阶段 3：练习批次收敛**。练习会话只持有当前轮次词条，避免把完整 12000 词本复制并为整表建立派生候选。
5. **阶段 4：记忆进度增量化**。按进度 revision 更新受影响词，避免答题后反复扫描整表。
6. **阶段 5：数据库/导入后台化**。评估并实现数据库 actor isolate 或等价后台执行，迁移 JSON 解析和 SQLite 写入；增加集成回归。已完成大词本 lite 只读查询后台化；导入写入暂不迁移。
7. **阶段 6：轻量模型与列表**。分离摘要/详情模型，收敛 Library 测量与分页常驻对象。已完成延迟分页/计数缓存和列表 key/测量有界化；轻量模型进一步拆分待后续切片。

## 风险评估
- **风险 1**: 过度收窄监听会导致当前播放词、语言或设置 UI 不更新。缓解：为每个页面保留明确 selector，并以状态 token 测试覆盖真正需要更新的字段。
- **风险 2**: hydrate 不再替换主词表可能使详情展示与列表摘要时序不一致。缓解：增加当前词详情 revision/缓存，切换词本时清空并验证 lite/full 两条路径。
- **风险 3**: 练习批次裁剪可能影响恢复、错题和候选题生成。缓解：保留最小身份/释义快照，补充会话恢复与大词本测试。
- **风险 4**: 数据库 isolate 改动涉及连接所有权和迁移顺序。缓解：单独提交，先做基准与集成测试，不在前序阶段混入。
- **风险 5**: worker 与主连接并行访问 SQLite，且 Web/迁移环境可能不支持独立 FFI 连接。缓解：worker 使用独立只读连接和 `PRAGMA query_only`；异常自动回退现有同步查询，写入连接和事务边界保持不变。

## 验证方式
- 每个阶段独立提交，运行对应 Dart/Flutter 测试、`dart format`、目标范围 `flutter analyze`。
- Profile Android 模拟器使用真实 12000 词本复测：导入/加载首帧、播放切词帧、切换 Toolbox 后连续操作、练习首帧与 RSS/heap。
- 阶段 1 的验收重点：隐藏 PracticePage 不因播放切词重建，切到 Toolbox 后连续切词不再随词本规模出现 500ms 级 UI 阻塞。

## 明确不处理
- 本计划不修改播放状态机语义、判题规则、用户可见文案和无关 Toolbox UI。
- 不以 `Future.delayed(Duration.zero)` 冒充后台执行；数据库后台化作为独立高风险阶段推进。

## 阶段 1 执行结果
- 播放切词、播放控制和播放结束改用 `PlaybackStore.revision`；普通 `AppState` listener 在连续播放期间不再收到事件。
- `StudyPage`、`PlayPage`、`LibraryPage` 通过顶层/子 Tab `isActive` gate，隐藏页面不执行播放 revision rebuild；重新进入时刷新一次。
- 兼容性边界：播放相关的当前词 UI 仅由 Play/Library/MiniPlayer 订阅专用 revision；词本切换、搜索、配置和错误消息仍走全局通知。

## 阶段 2 执行结果
- `AppState` 增加 64 条上限的 hydrated word LRU；换词本或清空词表时清理，避免详情缓存无界增长。
- `_syncPlaybackToSelectedWordbook`、`_preparePlayImpl`、`_startPlaySession` 与重启路径复用 `scopeWords`，取消播放期间的整表复制。
- `_hydrateWordEntryIfNeeded` 只返回当前词的完整详情并写入 LRU，不再替换 `_words`、增加 `wordsVersion` 或调用整本 `_refreshWordMemoryProgressCache`。
- 播放服务回调直接使用返回的 `word` 与服务提供的 `index`，避免为定位当前词再次扫描整表。
- 集成测试验证：播放服务收到的列表与 `AppState.words` 为同一实例，播放后列表版本和 memory progress 查询次数不变，当前词仍能读取完整字段。
- 阶段 2 验证命令：`flutter test test/app_state_init_test.dart test/app_state_logic_test.dart test/app_state_practice_test.dart test/playback_service_test.dart test/memory_lane_selector_test.dart --reporter compact`、目标文件 `flutter analyze`、`dart format`、`git diff --check`。

## 阶段 3 执行结果
- `PracticeStore` 增加独立 revision；练习设置、完成、错题清理等仪表盘变更只通知练习订阅者。
- 答题过程不再逐题广播全局 `AppState`，会话页本地维护当前题、反馈和统计，完成或路由销毁时再刷新练习面板。
- `PracticePage` 在非活动 Tab 直接卸载展示树且不订阅全局/练习 revision；练习派生候选按词表版本、集合身份和记忆进度身份缓存。
- 轮次会话改为持有 `PracticeRoundSource` 描述和有界 batch；下一批从 `AppState` 动态解析，避免 session widget 长期持有完整 12000 词源列表。
- 阶段 3 验证：练习状态测试、初始化测试、练习 UI smoke 全部通过；新增回归确认答题期间全局通知为 0，完成时练习 revision 递增。

## 阶段 4 执行结果
- `PracticeStore` 增加 `wordMemoryProgressRevision`；答题只原地更新受影响词的进度并递增 revision，避免每题复制整张进度 map。
- `AppState` 增加有界 `LinkedHashMap` 进度索引（最多 30,000 条，包含空结果）；换词本时只向仓库查询未命中的词 ID，并保留当前词本快照语义。
- 进度派生记忆 lane 缓存改用显式 revision 失效；数据库恢复/重置时清空索引，避免跨数据源复用旧进度。
- 阶段 4 回归验证：两个词本来回切换时第二次访问不再重复查询已加载 ID；既有状态、播放、记忆 lane 测试保持通过。

## 阶段 5 执行结果
- 大词本（超过启动全量加载阈值）的 lite 查询改由 `Isolate.run` 打开独立 SQLite 连接，仅读取摘要列，不触碰 `word_fields`、styles、tags、media 子表。
- `WordbookRepository.getWordsLiteAsync` 为数据库适配器提供后台路径，非数据库适配器和 worker 失败时回退原同步查询，保持 Web、迁移和测试适配器的功能语义。
- 选词本和播放按需加载均等待异步结果，并使用 `_wordbookLoadGeneration` 丢弃过期请求；数据库恢复、重置和 `dispose` 会使未完成查询失效，busy 状态只由当前请求关闭。
- 完整字段查询、搜索、分页同步接口、导入 JSON 解析/SQLite 写入和事务语义本阶段明确不变，留待独立阶段评估。
- 阶段 5 验证：`flutter test test/app_state_practice_test.dart test/app_state_init_test.dart test/app_state_logic_test.dart test/playback_service_test.dart test/memory_lane_selector_test.dart test/wordbook_query_worker_test.dart --reporter compact`（41 项通过）；目标文件 `flutter analyze` 无 error；`dart format`、`git diff --check` 通过。

## 阶段 6（进行中）执行结果
- `visibleWordCount` 和延迟大词本的分页查询增加签名缓存；相同词本、搜索条件和词表版本下，播放切词或其他全局通知不会重复执行同步 SQLite count/page 查询。
- 延迟分页使用最多 8 个 LRU 页面、首段最多 240 条，并记录已到达末尾的短页，避免空结果反复查询；搜索分页仍走原有 `searchWordsLite` 语义。
- `LibraryPage` 不再在 build 阶段为所有已加载条目预创建 GlobalKey；只为 Sliver 实际构建的窗口创建 key，并将未挂载 key 与高度测量限制在 240 条以内，降低滚动后的常驻对象数量。
- 阶段 6 当前验证：新增初始化回归覆盖普通分页和搜索分页重复读取；`flutter test test/app_state_init_test.dart test/app_state_logic_test.dart --reporter compact` 通过，`dart format`、`git diff --check` 通过。轻量摘要/详情模型拆分和真机 profile 复测尚未完成。
