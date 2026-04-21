# CHANGELOG

## [Unreleased-PLAN_043] - 2026-04-21

### 原因
- 需要先降低 ASR 测试脆弱性、音频缓存内存风险与 AppState 状态枢纽耦合，再推进大页面第三轮分层。

### 修改
- 新增 `AsrServiceContract` 抽象接口，`AsrService` 改为显式实现公共 API，并将 extension 暴露能力收口为内部实现方法。
- `AppDependencies` 与 `AppState` 的 ASR 依赖改为面向 `AsrServiceContract`，测试 double 改为接口实现。
- `ToolboxAudioBank` 引入可配置上限 LRU 缓存容器，新增 `configureCache`、`clearCache`、`clearDomainCache`、缓存容量/条目/估算字节观测接口。
- 新增 `WeatherStore` 独立 notifier/store 并接入 `AppState`，天气域状态拥有权从 `AppState` 内部字段迁移到 store。
- 锁定 `zen_sand / woodfish / harp` 第三轮结构拆分：新增配置层文件与渲染层入口文件，主文件保留状态编排与交互语义。

### 修复
- 修复 `WeatherStore` 在 `AppState` 构造阶段过早读取设置导致数据库未初始化场景下触发 `LateInitializationError` 的问题。
- 新增 `ToolboxAudioBank` 回归测试，覆盖 LRU 淘汰与 `clearDomainCache` 域级清理语义。

### 风险变更
- 本轮 `woodfish/harp` 渲染层先完成入口文件落位与配置层抽离，完整 painter 迁移将在后续迭代继续推进。

### Continuation (2026-04-21)
- AppState ownership split continues with a dedicated `TestModeStore`, including constructor injection, listener lifecycle wiring, and startup/reload sync integration.
- `app_state_startup.dart` test-mode mutation paths now delegate to `TestModeStore` (`setEnabled/toggleReveal/toggleHint/resetProgress`) to avoid cross-domain private-state writes.
- Added `test/test_mode_store_test.dart` to lock persistence and guard behavior of the new store.
- Zen Sand round-3 layering advanced: `_ZenSurfacePainter` and `_ZenSandPainter` moved from `toolbox_zen_sand_tool.dart` into `toolbox_zen_sand_tool_render.dart`, keeping main file focused on orchestration/state.

## [Unreleased] - 2026-04-13

### 原因
- 需要降低 `database_service.dart` 中 `_applySchemaMigrations()` 的重复分支复杂度，减少后续新增 schema 版本时的维护成本与漏改风险。
- 按当前版本基线清理数据库历史迁移冗余代码，减少维护负担并收敛初始化路径复杂度。
- `database_service.dart` 长期累计到数千行，单文件维护成本过高，需按功能模块拆分以降低耦合和改动风险。
- 第一轮模块拆分后，主文件仍承载核心实现细节，需继续拆出 core/schema 以进一步降低入口文件复杂度。
- 修复大词本播放时只播单词本身、释义与扩展字段未继续播放的问题。
- 修复历史播放配置中的字段禁用标记与当前重复次数设置冲突，导致学习播放只播单词本身的问题。
- 修复 Windows 本地 TTS 在自动语言模式下无法随字段内容切换音色，导致学习播放中后续中文释义等字段听感上像“没有继续播放”的问题。
- 修复 Windows 本地 TTS 在单词播完后因完成回调未正确回到平台线程、`isSpeaking` 状态滞留而长时间停顿并最终超时的问题。
- 修正播放页大词本入口“加载并播放”会在加载完成后直接开播，不符合先加载再由用户决定是否开始播放的交互预期。
- 收敛轻量词条语义漂移与测试基线老化问题，避免学习播放修复反向放大大词本加载内存、卡顿和跨模块 UI 回归失效。
- 修复练习模块连续答题时 Windows 桌面端 `accessibility_bridge.cc` / `ui::AXTree` 报错连刷，并伴随明显卡顿的问题。
- 修复练习会话在切换下一题时仍存在明显卡顿，且词义选择题错误作答时可能被误判为正确的问题。
- 为合并前收尾再压缩练习会话切题时的同步计算与附加写入竞争，降低移动端和桌面端连续练习时的剩余抖动。
- 推进 `PLAN_024` 阶段化重构，从“模块入口可插拔”进一步落到“运行时可停用 + 数据层仓库分域”。
- 在 `PLAN_024` 备份提交后继续完成“下一步 1/2/3”，推进 Riverpod 首批迁移、仓库分层续拆与学习模块停用语义扩展。
- 继续推进 `PLAN_024` 阶段 2/3/4：补齐 sleep 域仓库边界、统一模块路由守卫并将模板扩展到 focus/toolbox/sleep 文档域。
- 继续推进 `PLAN_024` 阶段 1：将 `app_root` 与主链路页面批次 2（More/Library/Play）迁移到 Riverpod 读取链路。
- 继续推进 `PLAN_024` 阶段 1：将设置与复盘页面批次 3（language/data/appearance/wordbook/practice review/recognition/voice）迁移到 Riverpod 读取链路。
- 对 `PLAN_024` 执行阶段门评估，确认质量基线与迁移增量可稳定进入下一阶段。
- 启动 `PLAN_025`（阶段 5A）：在跳过 sleep 子页面的前提下，优先推进大文件结构拆分与非 sleep 的 Riverpod 收尾。
- 继续推进 `PLAN_026`（阶段 5B）：将 `AppState/wordbook_state` 的剩余数据库直连能力下沉到仓库层抽象。

### 修改
- 将 `_applySchemaMigrations()` 重构为“迁移步骤表 + 统一顺序执行”编排，保留逐步迁移后立即写入 `PRAGMA user_version` 的既有语义。
- 将数据库 schema 迁移策略收敛为“仅对齐当前版本号（v9）”，并删除仅服务旧版升级链路的 `_migrate*` 历史冗余实现。
- 将 `database_service.dart` 拆分为 `part` 结构：`database_service_maintenance.dart`、`database_service_wordbook_query.dart`、`database_service_wordbook_import.dart`、`database_service_tasks.dart`，主文件保留核心骨架与基础能力。
- 继续拆分 `database_service` 核心层：新增 `database_service_core.dart` 与 `database_service_schema.dart`，将建表/schema 对齐与底层数据库 helper 从主文件迁出，主文件收敛到类型定义与初始化入口。
- 在播放链路中加入逐词 hydrate 解析，保持大词本列表轻量加载的同时，确保实际播放前拿到完整字段。
- 调整字段播放配置解析逻辑：当重复次数大于 `0` 时，优先视为当前字段应参与播放，并统一按规范化字段键读取配置标签与重复次数。
- 为 Windows 本地 TTS 增加可缓存的本地音色解析与按文本语言自动匹配逻辑，未显式选择本地音色时可在英文与中文字段之间自动切换合适 voice。
- 为 Windows 本地 TTS 补充 `setVoice` 失败后的 `setLanguage` 回退路径，并记录实际语音选择日志，方便后续追踪。
- 将 Windows 本地 TTS 的等待策略改为“完成回调优先、状态轮询兜底”，不再把 `isSpeaking` 轮询作为唯一完成依据。
- 修正 `flutter_tts` Windows 桌面插件的回调投递线程与窗口句柄使用方式，确保 `MediaEnded` / `speak.onComplete` 能真正回到顶层窗口线程执行。
- 将 `flutter_tts` Windows 桌面插件的 `isSpeaking` 查询改为优先读取实际播放状态，避免内部布尔值卡死导致轮询兜底失效。
- 将学习播放的大词本延迟加载入口改为“先加载词本，再手动开始播放”，避免首次点击即自动开播。
- 补强 `PlaybackService` 预加载会话状态管理，停止或切换到直接播放时会清理旧 prepared session，并保存解析后的词条快照避免后续回调拿到轻量对象。
- 将 `getWordsLite()` / `searchWordsLite()` 恢复为真正 lite 查询，只读取最小必要列，并以 `primary_gloss/meaning` 作为轻量摘要兜底。
- 明确本轮不接受 richer-lite 语义扩张，继续通过 `hydrateWordEntry()` / 播放前按需补全满足学习播放字段需求。
- 为 UI smoke 假状态补充稳定的在线环境音目录样例，避免依赖当前线上 fallback 为空导致目录操作回归失真。
- 同步更新启动态与初始化测试的 tracking key / lite 字段断言，使练习、任务本与学习模块共用的状态期望保持一致。
- 将 Windows 练习会话中的逐题答题反馈从高频 `showDialog` 路由切换为页内反馈卡，保留错题本开关、弱因标签和继续下一题操作，但减少连续答题时的语义树重建。
- 为练习进度条增加稳定语义描述，并将单词卡标题改为稳定语义标签 + 排除装饰动画语义的组合，降低 AXTree 抖动。
- 将练习追踪快照收敛为轻量持久化结构，逐题保存时不再携带完整 `fields`，并仅在身份兜底确有需要时保留 `rawContent`。
- 调整练习缓存词条的优先级与构造方式：内存中优先缓存轻量词条，实际解析词条时由当前作用域/已加载词条覆盖轻量快照，兼顾性能与展示完整度。
- 将练习页对 `AppState` 的整页监听收窄到 `uiLanguage`，并把自动发音触发从 `build()` 挪到切题准备阶段，减少下一题阶段的无关 rebuild 和副作用。
- 为练习答题状态写入与切题过程增加慢路径日志，便于继续追踪设备侧性能异常。
- 将练习会话的词义候选池改为按轮次预计算缓存，避免每次切题都重新遍历整轮单词并重复归一化词义。
- 将错题自动加入任务本的附加写入改为首帧渲染后再触发，降低和“下一题”界面切换争抢主线程的概率。
- 新增 `repositories` 分层并接入依赖注入：`PracticeRepository` 与 `WordbookRepository` 作为数据库访问边界。
- 将练习域关键数据路径（记忆进度、练习事件、导出写入）改由 `PracticeRepository` 承接，减少 `AppState` 对数据库实现细节的直连。
- 将词本域关键数据路径（词本/词条 CRUD、搜索跳转、导入导出、延迟内置词本加载）改由 `WordbookRepository` 承接。
- 模块开关新增运行时联动：停用 `focus` 时主动停止会话；停用所有依赖环境音模块时停播并停用 ambient；恢复启用时按需重建初始化链路。
- 补充模块直达守卫：`PracticePage` 与 `FocusPage` 在模块停用时展示恢复指引，避免隐藏入口后仍可通过历史路径进入失效功能。
- 新增 `app_state_provider` 并在应用启动链路接入 Riverpod overrides，形成 `AppState` 双栈注入过渡层（Riverpod + provider）。
- 首批页面读取迁移到 Riverpod：`AppShell`、`SettingsHomePage`、`PracticePage`。
- 新增并接入 `SettingsStoreRepository`、`FocusRepository`、`AmbientRepository`，将设置、专注与环境音相关路径继续从单体数据库服务中剥离。
- 同步更新 `ui_smoke_test` 的 `ProviderScope` 与 provider override 包装，确保迁移阶段测试稳定。
- 新增并接入 `SleepRepository`（`SettingsStoreSleepRepository`），将 sleep 域持久化从 `SettingsService` 直连迁移到仓库边界。
- `AppState` 启动流程新增 sleep assistant 预加载白名单，仅在模块启用时加载 sleep 数据。
- 新增统一模块守卫层 `ui/module/module_access.dart`，复用模块禁用文案与路由阻断逻辑。
- 将模块守卫接入 `StudyPage`、`PracticePage`、`FocusPage`、`ToolboxPage`、`ToolboxSleepAssistantPage`，并覆盖 toolbox 卡片入口、soothing mini player 入口、practice 会话入口。
- 更新 `modules/` 模块文档模板，并新增 `focus`/`toolbox`/`sleep` 模块文档，沉淀“状态独立 + 仓库独立 + 注册驱动 + 启停守卫”四件套。
- 将 `VocabularySleepApp` 迁移为 `ConsumerWidget`，应用根状态读取改为 `ref.watch(appStateProvider)`。
- 将 `MorePage`、`LibraryPage`、`PlayPage` 迁移到 Riverpod（`ConsumerWidget/ConsumerStatefulWidget`），减少主链路 UI 对 `provider` 的直接依赖。
- 保持迁移期双栈注入兼容（Riverpod + provider），确保 UI smoke 与全量测试无行为回归。
- 将 `LanguageSettingsPage`、`DataManagementPage`、`AppearanceStudioPage`、`WordbookManagementPage` 迁移到 `ConsumerWidget`，状态读取统一改为 `ref.watch(appStateProvider)`。
- 将 `PracticeReviewPage`、`RecognitionSettingsPage`、`VoiceSettingsPage` 迁移到 `ConsumerStatefulWidget`，交互链路中的状态读写统一改为 `ref.read/watch(appStateProvider)`。
- 新增阶段评估记录 `record_024_阶段门评估与阶段5启动.md`，并在 `PLAN_024` 明确阶段 5 启动范围与退出标准。
- 新增 `PLAN_025`，明确阶段 5A 的执行边界（跳过 sleep 子页面）与验收标准。
- 将 `play_page.dart` 拆分为 `play_page_navigation.dart` 与 `play_page_weather.dart` 两个 part 文件，主页面保留编排逻辑。
- 将 `practice_page.dart` 的大段区块构建函数拆分到 `practice_page_sections.dart`，降低主文件体量和耦合度。
- 将 `online_ambient_sheet.dart` 迁移到 Riverpod（`ConsumerStatefulWidget + ref.read/watch(appStateProvider)`）。
- 将 `focus_lock_overlay.dart` 迁移到 Riverpod（`ConsumerStatefulWidget + ref.read/watch(appStateProvider)`）。
- 新增 `MaintenanceRepository`（`DatabaseMaintenanceRepository`）承接数据库运维能力：`init/reset/backup/restore/export-dir/dispose`。
- 将 `AppState` 与 `app_state_startup.dart` 的数据库运维调用迁移到 `MaintenanceRepository`。
- 扩展 `WordbookRepository` 接口并完成数据库适配：新增 `databasePath`、`ensureSpecialWordbooks()`、`importWordbook(...)`、`importWordbookAsync(...)`。
- 将 `wordbook_state.dart` 改为仅依赖 `WordbookRepository`，移除对 `AppDatabaseService` 的直接依赖。

### 修复
- 修复大词本轻量词条参与播放时队列只包含 `word` 的问题。
- 修复旧版 `fieldSettings.enabled = false` 遗留配置会拦截释义等字段播放的问题。
- 修复 Windows 本地 TTS 只沿用系统默认声线播报混合字段内容，导致释义等中文字段看似未继续播放的问题。
- 修复 Windows 本地 TTS 在单词播完后卡死在等待完成状态、导致释义等后续播放单元迟迟不开始的问题。
- 新增回归测试，覆盖轻量词条补全后应继续播放释义的场景。
- 新增回归测试，覆盖重复次数已开启但旧字段禁用标记仍存在时的学习播放场景。
- 新增回归测试，覆盖 Windows 本地 TTS 在连续英文/中文播报时的自动声线切换与回退行为。
- 新增回归测试，覆盖 Windows 本地 TTS “完成回调已到但 `isSpeaking` 仍卡住” 与 “完成回调缺失时由轮询兜底完成” 两类阻塞场景。
- 新增回归测试，覆盖大词本延迟加载场景下首次点击只加载、第二次点击才正式播放的状态路径。
- 修复 `ui_smoke_test` 中在线环境音目录回归依赖空 catalog 假数据、按钮查找脆弱导致的误失败。
- 修复 `app_state_startup_test` 对 remembered/weak tracking key 的旧期望。
- 修复 `app_state_init_test` 对 lite 词条字段集合过宽的旧断言。
- 修复练习会话在 Windows 连续答题时反复打开/关闭反馈弹窗引发的 AXTree 更新异常与卡顿。
- 新增回归测试，覆盖 Windows 练习会话答题后应走页内反馈卡而不是 `AlertDialog` 的状态路径。
- 修复练习会话逐题落盘时把完整字段型词条快照一并序列化，导致切换下一题明显卡顿的问题。
- 修复词义选择题在错误选项与正确释义归一化碰撞时，仍可能显示“回答正确”的判题/文案异常。
- 新增回归测试，覆盖练习追踪快照应保持轻量化，以及词义选择题错误作答时必须显示纠正反馈的状态路径。
- 修复练习词义题在连续会话中反复重建干扰项池的重复计算开销，进一步缩短下一题准备阶段。
- 修复错题自动加入任务本会与切题同时竞争执行的问题，优先保证会话切题流畅性。
- 修复模块关闭后启动页可能仍指向已停用模块的问题，模块切换后会自动回退并持久化到可用入口。
- 修复学习模块关闭后仍可经直达页面访问学习视图的问题，并在运行时关闭学习模块时主动停止学习播放。
- 修复禁用 `toolbox.sleep_assistant` 后仍可能继续执行已启动 sleep routine 的问题，模块关闭时会立即停机。
- 修复 sleep assistant 子页面可通过历史路由绕过模块开关的问题，模块禁用后统一阻断跳转。
- 新增回归测试：`sleep_repository_test` 与 `app_state_init_test` 中的 sleep assistant 启停行为验证。
- 修复非 sleep 范围内残留的 `provider` 直读 `AppState` 路径，统一回收至 Riverpod 读取链路。
- 修复 `AppState` 与历史 `wordbook_state` 对数据库实现细节耦合过深的问题，改为经仓库边界访问数据库运维与词本导入能力。

### 修改（阶段 5C 补充）
- 按非 sleep 优先顺序完成小游戏模块大文件拆分：`toolbox_mini_games.dart` 拆分为 5 个 `part` 子文件（数独/扫雷/拼图/五子棋/2048）。
- 主文件保留入口与共享结构，页面级模块职责进一步清晰化，降低单文件耦合与维护成本。

### 风险变更
- 本轮仅做结构拆分，不涉及 sleep 子页面与业务逻辑语义。

### 修改（阶段 5D 补充）
- 对非 sleep 的 `focus_page.dart` 进行结构拆分：主文件收敛为入口编排与生命周期，计时域与工作域拆分到 `focus_page_timer.dart`、`focus_page_workspace.dart`。
- 新增 `_setViewState(...)` 状态更新桥接，替代扩展方法内直接 `setState(...)`，确保拆分后 analyze 规则保持全绿。

### 风险变更
- 本轮仍严格跳过 `sleep_*.dart`，未修改 sleep 子页面逻辑。

### 修改（阶段 5D 补充-第二步）
- 对 `focus_page_workspace.dart` 继续进行非 sleep 结构拆分，主文件收敛为工作区入口编排。
- 新增 `focus_page_workspace_todo.dart`、`focus_page_workspace_notes.dart`、`focus_page_workspace_editor.dart`，按 `todo / notes / editor` 拆分工作区实现。
- 保持 Focus 工作区业务语义与交互流程不变，便于后续按子域独立维护。

### 修改（阶段 5E 补充）
- 对 `toolbox_sound_tools/focus.dart` 进行第一步模块拆分：控制组件、编排编辑器、legacy painter、新版 painter 分离为独立 part 文件。
- `toolbox_sound_tools.dart` 新增 `focus_controls.dart`、`focus_arrangement_editor.dart`、`focus_visualizer_legacy.dart`、`focus_visualizer.dart` 的 `part` 声明。
- `focus.dart` 文件体量从 8290 行收敛至 3787 行，后续可继续拆分状态编排域。

### 风险变更
- 本轮仍严格跳过 `sleep_*.dart` 子页面，仅进行非 sleep 的结构性重构。

### 修改（阶段 5E 补充-第二步）
- 将 `toolbox_sound_tools/focus.dart` 中 `_FocusBeatsToolState` 的运行逻辑与舞台构建方法拆分到 `focus_state_logic.dart`、`focus_state_stage.dart` 两个新 part 文件。
- `toolbox_sound_tools.dart` 新增 `focus_state_logic.dart` 与 `focus_state_stage.dart` 的 `part` 声明，保持模块引用完整。
- `focus.dart` 从 3787 行进一步收敛到 745 行，主文件聚焦状态字段、生命周期与 build 入口。
- 新增 `_setViewState(...)` 作为类内状态更新桥接，消除扩展内直接 `setState(...)` 的 analyze 告警。

### 风险变更
- 本轮仍严格跳过 `sleep_*.dart` 子页面，仅进行非 sleep 的结构化拆分。

### 修改（阶段 5F 补充-第二步：Toolbox Audio Bank 二层域拆分）
- 将 `toolbox_audio_bank.dart` 从单文件私有实现继续拆分为音色/乐器域二层结构：`loops / harp_piano / guitar_guqin / flute / strings / drums / clicks / prayer_bead / singing_bowl / woodfish / shared`。
- `ToolboxAudioBank` 主文件收敛为缓存与对外静态 API，私有合成实现迁移到独立 `part` 文件，降低后续维护的阅读与改动成本。
- `toolbox_audio_service.dart` 同步新增二层 `part` 声明，确保库级私有函数可见性与调用链保持一致。
- 在 `flute/strings` 域拆分补齐阶段采用同接口实现重建，保持参数边界、缓存键语义与 WAV 输出格式不变。

### 风险变更
- 本轮核心目标为结构拆分与职责收敛；`flute/strings` 域因补齐实现存在听感侧细微差异风险，已通过定向 analyze 与相关测试，建议后续补一轮听感回归验收。

### 修改（阶段 5F 补充-第三步：听感回归与安全调优）
- 对 `toolbox_audio_bank_flute.dart` 进行保守调音：修复主音包络异常、增强气噪塑形与攻击瞬态控制，并加入轻量平滑与尾段衰减收口。
- 对 `toolbox_audio_bank_strings.dart`（violin）进行保守调音：补充弓噪动态过滤、颤音渐入、慢速漂移与尾段控制，提高连贯性与自然度。
- 在 `toolbox_audio_bank_shared.dart` 新增局部可复用 DSP 工具（`_applyOnePoleLowPass`、`_applyDcBlock`），仅用于本轮调优路径稳定化。
- 新增 `test/toolbox_audio_bank_regression_test.dart`，覆盖 WAV 结构合法性、非静音阈值、尾段衰减、变体差异与同参数确定性。

### 风险变更
- 本轮调优保持 public API 与缓存键不变，风险集中在听感细微变化；已通过定向 analyze + 回归测试收敛功能性回归风险，建议补一轮人工听感验收。

### 修改（阶段 5F 补充：ASR 与 Toolbox Audio）
- 对 `asr_service.dart` 完成按功能域拆分：主文件仅保留类型定义与共享状态，识别流程拆分到 `core / api / audio / offline / models` 五个 `part` 文件。
- 对 `toolbox_audio_service.dart` 完成按职责拆分：主文件仅保留库声明，播放器池与音色合成能力分别迁移到 `toolbox_audio_players.dart` 与 `toolbox_audio_bank.dart`。
- 清理单文件堆叠式历史结构，统一 `part of` 组织并收敛静态成员访问路径，保持既有 API 语义与调用方式不变。

### 风险变更
- 本轮为结构性重构，不调整 ASR 与音频合成算法语义；回归风险主要集中在文件边界迁移，已通过定向 analyze + 测试验证收敛。

### 修改（阶段 5E 补充-第三步）
- 对 `focus_state_stage.dart` 进行职责拆分：视觉舞台构建保留在原文件，控制区 section 构建迁移至 `focus_state_stage_sections.dart`。
- `toolbox_sound_tools.dart` 新增 `focus_state_stage_sections.dart` 的 `part` 声明，保持模块引用完整。
- 修复拆分过程中的尾段截断，并清理 `_buildPrimaryControls` 内 `return` 后不可达的重复代码块（仅结构清理，行为不变）。

### 风险变更
- 本轮仍严格跳过 `sleep_*.dart` 子页面，仅进行非 sleep 的结构化拆分。

### 修改（2026-04-20 / PLAN_041）
- 对大文件拆分结果做安全体检：修复 `tts_service_api.dart` 的 extension 静态成员限定引用问题，并完成 `tts_service` 分层文件的格式化与定向 analyze 验证。
- 回滚损坏的 `piano` 拆分结果，恢复 `toolbox_sound_tools/piano.dart` 到可编译状态，避免编码/字符串损坏继续扩散。
- 对 `toolbox_sound_tools/drum_pad.dart` 做第一层解耦：新增 `drum_pad_state_logic.dart`（状态与音频逻辑）与 `drum_pad_painter.dart`（光束绘制器），主文件收敛为 UI 编排入口。
- 删除历史冗余文件 `lib/src/ui/pages/toolbox_sound_tools/drum_pad.dart.bak`（无引用备份文件）。

### 风险变更（2026-04-20 / PLAN_041）
- 本轮聚焦结构解耦与稳定性修复，不改动业务语义；对编码风险文件采取回滚而非继续叠加改动。

### 修改（2026-04-21 / PLAN_042）
- 对 `toolbox_soothing_music_v2_page.dart` 进行模块化拆分：
  - 新增 `toolbox_soothing_music_v2_playback.dart`，承接播放、切曲、模式加载、资源加载与播放状态流。
  - 新增 `toolbox_soothing_music_v2_stage.dart`，承接舞台区、曲目栏与底部控制区 UI 组合。
- 新增 `_playbackIntent` 与 `_playbackVisualActive` 状态语义，修复播放按钮在切曲加载过渡期的显示不一致。
- 修复切换下一曲时偶发不立即自动播放：切源链路统一串行化，切源前 `stop()`，恢复播放前 `seek(Duration.zero)` + `resume()`。
- 优化手机端舞台效果可见性：紧凑布局提升特效增益，并增强频谱 painter 的振幅、波带与描边强度。

### 修复（2026-04-21 / PLAN_042）
- 修复播放按钮显示状态与实际播放链路偶发不同步的问题。
- 修复模式/曲目切换场景下自动播放意图在瞬时 stop 事件中被误清空导致的断播问题。
- 修复手机端舞台可视反馈过弱、动态存在感不足的问题。

### 风险变更（2026-04-21 / PLAN_042）
- 本轮改动聚焦页面拆分与播放链路稳定性修补，不改变对外业务语义与播放配置持久化协议。
