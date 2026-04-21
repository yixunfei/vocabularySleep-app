# 计划 024：模块化解耦与可插拔重构（阶段化）

## 基本信息
- **创建日期**: 2026-04-13
- **状态**: 进行中
- **负责人**: Codex

## 目标
1. 建立“模块注册 + 模块开关 + 运行时守卫”基础设施，支持入口级与访问级的功能启停。
2. 收敛重构前基线红灯（`ambient_service_test` 失败与 analyze warning），建立可持续迭代的验证基线。
3. 以低侵入方式先接入可插拔能力，再逐步推进 Riverpod 与仓库分层深改。

## 本轮范围（阶段 0 + 阶段 1 + 阶段 2 首刀）
1. **阶段 0 基线校准**
   - 修复 `test/ambient_service_test.dart` 的两个失败场景。
   - 修复 `analyze` 阻断项并将 `flutter analyze` 与 `dart analyze` 收敛到无问题。
   - 重新跑通全量 `flutter test`。
2. **阶段 1 首批基础设施**
   - 新增 `core/module_system`：
     - `ModuleId`
     - `ModuleDescriptor`
     - `ModuleRegistry`
     - `ModuleRuntimeGuard`
     - `ModuleToggleState`
   - 将模块开关持久化接入 `SettingsService`（`module_toggles_v1`）。
   - 将模块开关状态接入 `AppState` 初始化与运行时读写。
   - 将底部导航改为受模块开关驱动的可见列表。
   - 为 `Toolbox` 入口与子工具接入模块开关过滤。
   - 新增“设置中心 -> 模块管理”页面，支持用户可见启停。
   - 在启动入口接入 `ProviderScope`（Riverpod 容器），为后续状态迁移预埋。
3. **阶段 2 首刀（练习域 + 数据层拆分起步）**
   - 新增 `repositories/`：
     - `PracticeRepository`
     - `WordbookRepository`
   - 在 `AppDependencies` 中显式注入仓库实现（数据库适配层）。
   - 将练习域数据库读写从 `AppState._database` 迁移到 `PracticeRepository`：
     - 记忆进度查询/写入
     - 练习事件写入
     - 练习导出写入
   - 将词本域核心读写从 `AppState._database` 迁移到 `WordbookRepository`：
     - 词本/词条 CRUD
     - 搜索/跳转查询
     - 词本导入/导出/合并
     - 延迟内置词本加载
4. **阶段 3 语义预落地（运行时停用补强）**
   - 模块切换时新增运行时联动：
     - 关闭 `focus` 时停止专注会话并清空 pending reminder。
     - 关闭 `study+focus+toolbox` 全部入口时关闭并停止环境音服务。
     - 重新启用相关模块时按需恢复 `focus/ambient` 初始化链路。
   - 当启动页对应模块被关闭时，自动回退到可用启动页并持久化。
   - `PracticePage` / `FocusPage` 增加直接访问守卫文案，避免绕过导航时进入失效模块。

## 风险评估
- **风险 1**: 模块关闭后历史入口索引失效导致导航异常。
  - **缓解措施**: `AppShell` 采用动态 tab 列表和安全索引回退。
- **风险 2**: 测试桩未同步新接口导致 smoke test 编译失败。
  - **缓解措施**: 同步 `_FakeAppState` 的模块接口实现。
- **风险 3**: 仅做模块入口层启停，尚未完成全服务懒初始化。
  - **缓解措施**: 已补充 focus/ambient 运行时启停联动；后续继续覆盖更多服务域。
- **风险 4**: 仓库层当前是数据库适配器，尚未完成“数据库核心完全抽象”。
  - **缓解措施**: 保持接口稳定，后续把 repository 与 database core 进一步解耦。

## 验证结果（本轮）
- `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
- `flutter test` ✅

## 本轮增量（备份后执行：下一步 1/2/3）
1. **下一步 1：Riverpod 一次切换的第一批页面落地**
   - 新增 `lib/src/state/app_state_provider.dart`，统一提供 `appStateProvider` 与 `cstCloudResourceCacheProvider`。
   - `AppBootstrap` 在 `ProviderScope` 中接入 `dependencies.riverpodOverrides`。
   - `AppDependencies` 改为创建单例 `AppState`，并同时注入 Riverpod 与 legacy provider，保证迁移期行为一致。
   - 页面读取改造：
     - `AppShell` -> `ConsumerStatefulWidget`。
     - `SettingsHomePage` -> `ConsumerWidget`。
     - `PracticePage` -> `ConsumerWidget`。
2. **下一步 2：仓库分层继续拆分（settings/focus/ambient）**
   - 新增仓库：
     - `SettingsStoreRepository`
     - `FocusRepository`
     - `AmbientRepository`
   - `SettingsService` 调整为 `fromRepository` 主构造，数据库构造保留兼容工厂。
   - `FocusService` 引入 `FocusRepository` 抽象，内部数据库读写改走仓库。
   - `AppState` 下载环境音持久化改走 `AmbientRepository`。
3. **下一步 3：停用语义扩展**
   - `StudyPage` 增加模块直达守卫（模块关闭时展示恢复指引）。
   - 模块切换运行时联动补充：`study` 从开启 -> 关闭时主动触发 `stop()`，阻断继续播放。

## 验证结果（增量）
- `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
- `flutter test` ✅

## 下一步（阶段 2 深化 / 阶段 3 扩展）
1. 继续将高频页面从 `provider` 读取迁移到 Riverpod（优先 `app_root.dart` 与其直接子树）。
2. 继续审计 `sleep` 与其余服务的数据访问边界，减少 `AppDatabaseService` 直连面。
3. 扩展模块停用守卫到更多直接路由入口，并补齐禁用状态回归测试矩阵。

## 本轮增量（阶段 2 / 阶段 3 / 阶段 4 继续推进）
1. **阶段 2 深化：sleep 域仓库化**
   - 新增 `SleepRepository`（`SettingsStoreSleepRepository` 实现）：
     - `lib/src/repositories/sleep_repository.dart`
   - `AppDependencies` 接入 `sleepRepository` 依赖注入。
   - `AppState` 新增 `SleepRepository` 注入位。
   - `app_state_sleep.dart` 持久化读写从 `SettingsService` 直连改为 `SleepRepository` 边界。
   - `AppState` 词本同步路径补齐：`favorites` 读取改走 `WordbookRepository`，特殊词集合持久化改走 `SettingsService.saveStringSet()`。
2. **阶段 3 扩展：停用语义 + 路由守卫统一**
   - 启动时仅在 `toolbox.sleep_assistant` 启用时预加载 sleep 数据。
   - 模块切换联动新增：
     - 关闭 `toolbox.sleep_assistant` 时主动停止 sleep routine。
     - 重新启用时按需懒加载 sleep 数据。
   - 新增统一模块守卫层：`lib/src/ui/module/module_access.dart`
     - `ModuleDisabledView`
     - `ensureModuleRouteAccess`
     - `pushModuleRoute`
   - 守卫接入页面与路由：
     - 页面禁用态复用：`StudyPage`、`PracticePage`、`FocusPage`、`ToolboxPage`、`ToolboxSleepAssistantPage`
     - 路由守卫接入：`ToolboxEntryCard`、`ToolboxSleepAssistantPage._open()`、`AppShell` 的 soothing mini player 入口、Practice 会话/复盘入口。
3. **阶段 4 模板化推进：模块文档扩展**
   - 新增模块文档：
     - `modules/focus/README.md`
     - `modules/toolbox/README.md`
     - `modules/sleep/README.md`
   - 更新模板与索引：
     - `modules/README.md`
     - `modules/module_system/README.md`
   - 文档结构统一为“状态独立 + 仓库独立 + 注册驱动 + 启停守卫”四件套。

## 验证结果（阶段 2/3/4 增量）
- `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
- `flutter test` ✅（含新增 `sleep_repository_test` 与 `app_state_init_test` 模块启停回归）

## 本轮增量（Riverpod 主链路续迁）
1. **阶段 1 延伸：主链路页面继续从 provider 迁移到 Riverpod**
   - `lib/src/app/app_root.dart`
     - `VocabularySleepApp` 从 `StatelessWidget + context.select` 迁移到 `ConsumerWidget + ref.watch(appStateProvider)`。
   - `lib/src/ui/pages/more_page.dart`
     - 从 `StatelessWidget + context.watch` 迁移到 `ConsumerWidget + ref.watch`。
   - `lib/src/ui/pages/library_page.dart`
     - 从 `StatefulWidget` 迁移到 `ConsumerStatefulWidget`。
     - 页面状态读取统一改为 `ref.watch(appStateProvider)`。
   - `lib/src/ui/pages/play_page.dart`
     - 从 `StatefulWidget` 迁移到 `ConsumerStatefulWidget`。
     - 初始化与弹窗链路的状态读取统一改为 `ref.read/watch(appStateProvider)`。
     - 天气详情弹窗中的 `Consumer<AppState>` 改为 Riverpod `Consumer`。
2. **兼容策略保持**
   - 保持 `AppDependencies` 双栈注入（Riverpod + legacy provider）不变，确保迁移期行为稳定。
   - 原有 UI smoke `ProviderScope + ChangeNotifierProvider` 包装无需额外改动即可覆盖新链路。

## 验证结果（Riverpod 续迁增量）
- `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
- `flutter test` ✅（全量通过）

## 本轮增量（Riverpod 续迁：设置与复盘批次 3）
1. **阶段 1 延伸：设置与复盘页面从 provider 迁移到 Riverpod**
   - `lib/src/ui/pages/language_settings_page.dart`
     - `StatelessWidget` 迁移为 `ConsumerWidget`，状态读取改为 `ref.watch(appStateProvider)`。
   - `lib/src/ui/pages/data_management_page.dart`
     - `StatelessWidget` 迁移为 `ConsumerWidget`，状态读取改为 `ref.watch(appStateProvider)`。
   - `lib/src/ui/pages/appearance_studio_page.dart`
     - `StatelessWidget` 迁移为 `ConsumerWidget`，状态读取改为 `ref.watch(appStateProvider)`。
   - `lib/src/ui/pages/wordbook_management_page.dart`
     - `StatelessWidget` 迁移为 `ConsumerWidget`，状态读取改为 `ref.watch(appStateProvider)`。
   - `lib/src/ui/pages/practice_review_page.dart`
     - `StatefulWidget` 迁移为 `ConsumerStatefulWidget`。
     - 页面与导出链路状态读取改为 `ref.read/watch(appStateProvider)`。
   - `lib/src/ui/pages/recognition_settings_page.dart`
     - `StatefulWidget` 迁移为 `ConsumerStatefulWidget`。
     - 离线包管理、评分包管理、配置更新链路改为 `ref.read/watch(appStateProvider)`。
   - `lib/src/ui/pages/voice_settings_page.dart`
     - `StatefulWidget` 迁移为 `ConsumerStatefulWidget`。
     - 本地音色拉取、缓存统计与页面配置读取改为 `ref.read/watch(appStateProvider)`。
2. **兼容策略保持**
   - 保持 `AppDependencies` 双栈注入（Riverpod + legacy provider）不变，迁移批次继续保持行为等价与可回滚。

## 验证结果（Riverpod 批次 3）
- `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
- `flutter test` ✅（全量通过，含 UI smoke 的 language/data/appearance/wordbook/practice review/voice/recognition 路径）

## 阶段门评估（2026-04-15）
1. 质量门禁状态
   - `dart analyze` / `flutter analyze` 0 issue。
   - `flutter test` 全量通过（本次实测 215 项）。
2. Riverpod 迁移状态
   - 主链路、设置与复盘批次已迁移完成。
   - 残留 provider 直读主要集中于 sleep 子页面与少量 UI 辅助组件。
3. 仓库边界状态
   - `practice/wordbook/settings/focus/ambient/sleep` 六个仓库边界已落地。
   - `AppState` 与 `wordbook_state` 仍有部分 `_database` 直连路径，需在下一阶段继续收口。
4. 模块守卫状态
   - 页面禁用态与关键入口路由守卫已统一，sleep assistant 停用停机语义已落地。

## 下一阶段（阶段 5）启动范围
1. **阶段 1 收尾：Riverpod 迁移 Batch 4**
   - 迁移 sleep 子页面与剩余 UI 辅助组件至 `appStateProvider`。
2. **阶段 2 深化：数据边界二次收口**
   - 继续削减 `AppState` / `wordbook_state` 的 `_database` 直连面，并补齐仓库承接接口。
3. **阶段 3 扩面：守卫覆盖补齐**
   - 跨模块入口优先统一到 `pushModuleRoute(...)`，降低历史路由绕过风险。
4. **阶段 4 验证：回归矩阵补强**
   - 增补 sleep 运行流程、模块启停、跨入口跳转回归用例。

## 下一阶段退出标准
1. UI 层 `AppState` 读取以 Riverpod 为主，provider 直读点清零或收敛为兼容桥。
2. 数据层直连面继续压缩，重构边界可持续扩展。
3. `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` 与 `flutter test` 持续全绿。

## 本轮增量（阶段 5A：非 sleep 大文件拆分 + Riverpod 收尾）
1. **执行边界**
   - 明确跳过 sleep 子页面（`sleep_*.dart`），仅推进非 sleep 范围重构。
2. **大文件结构拆分**
   - `play_page.dart` 拆分为：
     - `play_page_navigation.dart`
     - `play_page_weather.dart`
   - `practice_page.dart` 拆分区块构建段到：
     - `practice_page_sections.dart`
3. **非 sleep Riverpod 收尾**
   - `online_ambient_sheet.dart`：provider 直读迁移到 `ref.read/watch(appStateProvider)`。
   - `focus_lock_overlay.dart`：provider 直读迁移到 `ref.read/watch(appStateProvider)`。

## 验证结果（阶段 5A）
- `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
- `flutter test` ✅（全量通过，215 项）

## 本轮增量（阶段 5C：非 sleep 小游戏模块结构拆分）
1. **执行边界**
   - 延续阶段顺序推进，明确跳过 sleep 子页面（`sleep_*.dart`）。
   - 本轮仅做文件结构与模块拆分，不改业务逻辑。
2. **大文件拆分落地**
   - 将 `lib/src/ui/pages/toolbox_mini_games.dart` 拆分为多 `part` 文件：
     - `toolbox_mini_games_sudoku.dart`
     - `toolbox_mini_games_minesweeper.dart`
     - `toolbox_mini_games_jigsaw.dart`
     - `toolbox_mini_games_gomoku.dart`
     - `toolbox_mini_games_slide.dart`
   - 主文件收敛为入口、Hub 卡片与共享全屏/滚动锁逻辑。
3. **结果**
   - `toolbox_mini_games.dart` 由 3463 行收敛为 413 行。
   - 各游戏实现按模块解耦，后续可独立维护。
4. **验证**
   - `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
   - `flutter test` ✅（全量通过，215 项）

## 本轮增量（阶段 5D：非 sleep Focus 页面结构拆分第一步）
1. **执行边界**
   - 严格跳过 `sleep_*.dart` 子页面。
   - 仅对 `focus_page` 进行结构拆分，不改业务逻辑语义。
2. **大文件拆分落地**
   - `focus_page.dart` 主文件收敛为入口编排与生命周期（4890 -> 393 行）。
   - 新增：
     - `lib/src/ui/pages/focus_page_timer.dart`
     - `lib/src/ui/pages/focus_page_workspace.dart`
3. **结构适配**
   - 新增 `_setViewState(...)` 桥接，替代扩展方法内直接 `setState(...)`，保证 analyze 规则通过。
   - 扩展内静态成员访问改为 `_FocusPageState._todoPalette` 合规引用。
4. **验证**
   - `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
   - `flutter test` ✅（全量通过，215 项）

## 本轮增量（阶段 5D：非 sleep Focus 页面结构拆分第二步）
1. **执行边界**
   - 严格跳过 `sleep_*.dart` 子页面。
   - 仅对 `focus_page_workspace` 做结构拆分，不改业务逻辑语义。
2. **大文件拆分落地**
   - `focus_page_workspace.dart` 收敛为工作区入口编排（112 行）。
   - 新增并拆分到子域：
     - `lib/src/ui/pages/focus_page_workspace_todo.dart`
     - `lib/src/ui/pages/focus_page_workspace_notes.dart`
     - `lib/src/ui/pages/focus_page_workspace_editor.dart`
3. **结果**
   - workspace 逻辑按 `todo / notes / editor` 解耦，后续可独立演进。
4. **验证**
   - `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
   - `flutter test` ✅（全量通过，215 项）

## 本轮增量（阶段 5E：非 sleep 声音工具 Focus 模块拆分第一步）
1. **执行边界**
   - 延续顺序推进，严格跳过 `sleep_*.dart` 子页面。
   - 本轮仅做结构拆分，不改业务逻辑语义。
2. **大文件拆分落地**
   - `lib/src/ui/pages/toolbox_sound_tools/focus.dart` 由 8290 行收敛至 3787 行。
   - 新增模块文件：
     - `focus_controls.dart`
     - `focus_arrangement_editor.dart`
     - `focus_visualizer_legacy.dart`
     - `focus_visualizer.dart`
   - `toolbox_sound_tools.dart` 已新增对应 `part` 声明。
3. **结果**
   - 声音工具 Focus 页按“状态编排 / 控制组件 / 编辑器 / 可视化绘制”拆分为可维护子模块。
4. **验证**
   - `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
   - `flutter test` ✅（全量通过，215 项）

## 本轮增量（阶段 5E：非 sleep 声音工具 Focus 模块拆分第二步）
1. **执行边界**
   - 延续顺序推进，严格跳过 `sleep_*.dart` 子页面。
   - 本轮仅做结构拆分，不改业务逻辑语义。
2. **大文件拆分落地**
   - 将 `_FocusBeatsToolState` 的逻辑层与舞台构建层拆分为：
     - `lib/src/ui/pages/toolbox_sound_tools/focus_state_logic.dart`
     - `lib/src/ui/pages/toolbox_sound_tools/focus_state_stage.dart`
   - `toolbox_sound_tools.dart` 新增对应 `part` 声明。
   - `focus.dart` 从 3787 行进一步收敛到 745 行。
3. **结构适配**
   - 新增 `_setViewState(...)` 桥接，替代扩展内直接 `setState(...)`，保证 analyze 规则通过。
4. **验证**
   - `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
   - `flutter test` ✅（全量通过，215 项）

## 本轮增量（阶段 5E：非 sleep 声音工具 Focus 模块拆分第三步）
1. **执行边界**
   - 延续顺序推进，严格跳过 `sleep_*.dart` 子页面。
   - 本轮仅做结构拆分，不改业务逻辑语义。
2. **大文件拆分落地**
   - 将 `focus_state_stage.dart` 按职责拆分为：
     - `lib/src/ui/pages/toolbox_sound_tools/focus_state_stage.dart`（舞台视觉构建）
     - `lib/src/ui/pages/toolbox_sound_tools/focus_state_stage_sections.dart`（控制区 section 构建）
   - `toolbox_sound_tools.dart` 新增对应 `part` 声明。
3. **结构适配**
   - 修复拆分过程中的尾段截断问题并恢复语法结构。
   - 清理 `_buildPrimaryControls` 中 `return` 后不可达重复代码，保持行为等价。
4. **验证**
   - `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` ✅
   - `flutter test` ✅（全量通过，215 项）
