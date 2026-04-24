# CHANGELOG

## [Unreleased-PLAN_049] - 2026-04-24

### 原因
- 当前沙盘音效已接近真实沙沙声，但仍需要进一步轻柔化，并且需要随滑动节奏变化：加速滑动略增强、匀速滑动稳定、不动时应无声。

### 修改
- 在 `toolbox_zen_sand_sound_service.dart` 中重写循环声量映射：
  - `intensity <= 0.01` 时返回 0 音量，确保按住不动或停住时真正静音。
  - 整体基础音量和上限下调，使沙声更轻、更贴近背景触感。
  - 新增运动强度计算：根据位移、时间间隔、平滑速度和正向加速度计算 loop intensity。
- 在 `toolbox_zen_sand_tool.dart` 中接入运动联动：
  - 起笔只预热并以 0 音量启动 loop，不再触摸即响。
  - 滑动更新时按速度/加速度驱动沙声强度。
  - 停止移动约 `130ms` 后淡到 0，继续滑动时快速恢复。
  - 水迹长按扩散不再模拟滑动音，避免“没动也有声”。
- 在沙盘音效测试中新增运动联动断言，覆盖静止为 0、加速强于匀速、峰值保持轻柔。

### 风险变更
- 本轮只改变音效强度映射与手势运动到音量的联动，不改变绘制、落石、持久化或路由语义。

### 验证
- `dart format lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart test/toolbox_zen_sand_sound_service_test.dart`（通过）
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`（通过）
- `dart analyze lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart test/toolbox_zen_sand_sound_service_test.dart`（仍有 `toolbox_zen_sand_tool.dart` 既有 6 条 unused_element warning）

## [Unreleased-PLAN_048] - 2026-04-24

### 原因
- 用户进一步明确：创意沙盘音效核心应模拟手指在沙面滑动时沙砾发出的细密“悉沙声”，用于解压放松，而不是泛白噪声或电子噪音。
- 参考网页 `https://www.ppbzy.com/tools/zen/` 的沙盘实现采用平滑随机噪声、约 800Hz 中频带通和拖动速度控制音量的思路，方向更接近真实砂面摩擦。

### 修改
- 重写 `toolbox_zen_sand_sound_service.dart` 的现代循环底噪生成器：
  - 去除正弦 partial 堆叠，避免听感出现固定音高或电子调制感。
  - 改为确定性有色颗粒噪声：中频摩擦带负责“悉沙”，细粒脉冲负责砂粒感，慢压力漂移负责随手指移动的自然起伏。
  - 为木耙、指尖、水迹、沙铲、沙砾、抚平保留不同材质参数，但统一收口到“贴着沙面轻轻滑动”的声音方向。
  - 对循环首尾做短融合，并按目标峰值归一化，降低拼接点击声和刺耳峰值。

### 修复
- 修复上一版循环底噪仍偏“合成噪声/电子噪声”的听感问题，使滑动声更接近真实沙砾摩擦。

### 风险变更
- 音色主观听感变化较明显，但仅改动运行时合成音色，不改变手势语义、播放 API、持久化结构或 UI 行为。

### 验证
- `dart format lib/src/services/toolbox_zen_sand_sound_service.dart test/toolbox_zen_sand_sound_service_test.dart`（通过）
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`（通过）

## [Unreleased-PLAN_047] - 2026-04-24

### 原因
- 用户反馈创意沙盘滑动时音效卡顿严重，听感只有一声、不持续播放，期望连续滑动时有不停顿、无空白的沙沙声。
- 同时要求面向手机小屏重新优化一版 UX/UI，优先保留画布空间、当前状态和主操作热区。

### 新增
- 新增 `plans/PLAN_047_创意沙盘连续音效与移动端UX优化.md`，承接本轮音效连续性与移动端 UX/UI 优化。
- 在 `toolbox_zen_sand_sound_service.dart` 中补齐现代循环沙沙声 PCM 生成器，为木耙、指尖、水迹、沙铲、沙砾、抚平等连续工具提供 4.8s 周期底噪。
- 在音效回归测试中新增循环声时长、最小窗口 RMS 和动态稳定性断言，防止后续再次出现首尾空白或中段掉音。

### 修改
- 调整循环播放器起播判定：播放器进入 `PlayerState.playing` 即可视为已启动，不再强依赖 position 立刻前进，避免部分平台 position 回报慢时被误判失败并反复重启。
- 将循环 source ready 等待从长超时收敛为 `420ms` 短等待；源设置完成后优先快速尝试 `resume()`，减少首次滑动空白。
- 连续型工具继续采用 loop 主导策略，减少滑动过程中短促 impact 反复切源造成的卡顿感。
- 窄屏下压缩顶部标题区：保留返回、标题、场景和工具入口，说明文案收敛为一行，减少首屏高度占用。
- 窄屏状态区由横向滚动 badge 改为可换行短 pill，优先展示场景、工具、音效和笔触，避免 375dp 手机上横向滑动。
- 底部 Dock 按钮增加最小 `48dp` 触控约束，并限制按钮文本单行省略，提升手机端稳定性。

### 修复
- 修复当前代码中 `_tryBuildModernZenSandLoopPcm(...)` 被调用但未定义导致分析失败的缺口。
- 修复滑动音效可能因播放进度回报慢而进入“启动-误判失败-再次启动”的循环，降低只有首声、后续发空的概率。

### 风险变更
- 本轮音效改动集中在合成循环声与播放器启动判定，不改变工具语义、手势语义、持久化结构和路由行为。
- 小屏 UI 调整仅改变展示密度与控件布局，辅助设置仍通过场景/工具与控制面板进入。

### 验证
- `dart format lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart lib/src/ui/pages/toolbox_zen_sand_tool_widgets.dart test/toolbox_zen_sand_sound_service_test.dart`
- `dart analyze lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart lib/src/ui/pages/toolbox_zen_sand_tool_widgets.dart test/toolbox_zen_sand_sound_service_test.dart`（仍有 `toolbox_zen_sand_tool.dart` 既有 6 条 unused_element warning）
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`（通过）

## [Unreleased-PLAN_046] - 2026-04-23

- Follow-up: hardened the Zen Sand loop startup path so it now waits for the loop source to become ready before `resume()`, tracks in-flight startup state, and retries once if playback position does not advance after resume.
- Follow-up: switched the Zen Sand sustained loop from in-memory `BytesSource` playback to cached temp-file `DeviceFileSource` playback, matching the project's already-stable loop controller path on device.
- Follow-up verification: `dart analyze lib/src/services/toolbox_zen_sand_sound_service.dart` returned `No issues found`.

### 原因
- 用户反馈禅意沙盘当前音效在起播和停后再播时存在明显空白与延迟，听感像“先出一声，随后发空”，需要确认问题来自音频本体还是播放链路。
- 经代码排查，禅意沙盘音效并非静态 `assets` 文件，而是 `toolbox_zen_sand_sound_service.dart` 运行时合成的 WAV；因此需要同时检查合成波形与播放器切源/预热策略。

### 修改
- 在 `toolbox_zen_sand_sound_service.dart` 中新增 `prewarm(...)` 预热入口：
  - 当前工具切换、笔触大小变化、偏好恢复、音效重新开启后，会提前准备循环底噪 source，减少首次 `setSource` 的等待空白。
  - 同时预热当前工具首个常用击发音 source，并把 impact player 游标重置到已预热播放器，降低首响延迟。
- 优化 impact 播放链路：
  - 为 3 个 impact player 增加已加载 `cacheKey` 跟踪。
  - 当同参数击发音再次触发时，优先 `seek(Duration.zero) + resume()` 复用已加载 source，而不是每次重新切源。
- 根据用户实机日志进一步收口为“loop 主导”的连续沙声策略：
  - 连续型沙盘工具在绘制过程中不再高频插入 `zen_sand_sfx_impact`，避免 100ms 级短击发音把听感切成“卡壳”片段。
  - 提升 `zen_sand_sfx_loop` 基础音量与动态范围，并将非立即停播缓冲从 `240ms` 延长到 `420ms`，减少短抬手和触点抖动造成的断续感。
  - 下调非石子类 impact 音量，使保留的操作反馈不再压过持续底噪。
- 在 `toolbox_zen_sand_tool.dart` 中接入当前工具音频预热：
  - `restore prefs`
  - `select tool`
  - `set brush size`
  - `toggle sound(true)`
  - `apply ritual preset`

### 修复
- 修复禅意沙盘循环底噪首次起播容易落在 impact 声之后、导致“只有一声随后发空”的问题。
- 修复相同工具/参数连续绘制时反复切源带来的重复延迟，提升停后再播和短间隔连画的连续性。
- 新增波形回归检查，确认当前合成音频不存在“大段前导空白”：
  - 循环声 `leadingQuietMs = 0ms`，`longestQuietMs = 0-20ms`
  - 击发声 `leadingQuietMs = 0ms`

### 风险变更
- 本轮调整集中在播放器预热与 source 复用策略，不改变手势语义、工具语义、持久化结构和页面业务逻辑。
- 预热会让空闲状态下多保留少量已生成 WAV/已加载 source；范围仅限当前工具常用 bucket，风险可控。

### 验证
- `dart format lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart test/toolbox_zen_sand_sound_service_test.dart`（通过）
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`（通过）

## [Unreleased-PLAN_045] - 2026-04-23

### 原因
- 空灵音钵（疗愈音钵）模块单文件 2255 行严重违反 500 行硬顶；视觉上七脉轮霓虹彩虹色与 toolbox「柔和、克制、舒缓」基线不一致；移动端底部 188dp 常驻抽屉挤压主舞台，音钵失去首屏视觉焦点。

### 新增
- `lib/src/ui/pages/toolbox_singing_bowls_tool_specs.dart`：频率/音色 spec + 11 组自然色 palette。
- `lib/src/ui/pages/toolbox_singing_bowls_tool_painters.dart`：三组 CustomPainter（背景 / 音钵 / 余振扩散）。
- `lib/src/ui/pages/toolbox_singing_bowls_tool_stage.dart`：音钵主舞台（`bowlSize` 上限 296→360，新自然色轻触提示 pill）。
- `lib/src/ui/pages/toolbox_singing_bowls_tool_layout.dart`：移动端 Header(48dp) + Stage + SummaryBar(60dp) 三段结构；摘要条即把手，点击打开上拉 Sheet。
- `lib/src/ui/pages/toolbox_singing_bowls_tool_wide.dart` + `_wide_tiles.dart`：宽屏 ≥ 760dp 布局保留原骨架，换为新自然色。
- `lib/src/ui/pages/toolbox_singing_bowls_tool_sheet.dart` + `_sheet_controls.dart`：`DraggableScrollableSheet` 上拉抽屉，承载频率菜单（chakra/resonance 分组）+ 音色 2×2 网格 + 自动播放 slider + 触感 switch + 停止余振按钮。
- `plans/PLAN_045_空灵音钵自然舒适移动端精修.md`：本轮计划文档。

### 修改
- `lib/src/ui/pages/toolbox_singing_bowls_tool.dart`：从 2255 行收缩到 373 行，仅保留 `SingingBowlsToolPage` / `SingingBowlsPracticeCard` / `_SingingBowlsPracticeCardState` 的 lifecycle 与事件方法，其余通过 `part` 分片。
- 11 组脉轮/共振频率的 `accent / glow / gradient` 重写为自然低饱和色系（陶土 / 苔藓 / 晨雾 / 檀褐 / 薰衣灰紫 等），保留 `id / note / frequency / 文案` 语义不变。
- 背景线性纹理 alpha 从 0.026 降到 0.018，背景辉光轻度柔化，符合"自然舒适"气质。
- 移动端头部删除冗长副标题"频率、音色与空间尾韵的移动端重构"（文案已迁入 Sheet 内）。

### 风险变更
- 严格遵守「只动 UI、不动逻辑」边界：所有 `ToolboxSingingBowlsPrefsService` 调用、`ToolboxAudioBank.singingBowlTone` 调用方式、`_frequencyId/_voiceId/_autoPlayIntervalMs` 默认值与持久化结构、事件触发语义均未改动。
- `part of` 拆分后所有原私有类（`_SingingBowlFrequencySpec` / `_SingingBowlPainter` 等）继续文件私有；新增 `setPressing(bool)` 公开方法以支持 stage extension 触发 setState，未暴露内部字段。

### 验证
- `dart format lib/src/ui/pages/toolbox_singing_bowls_tool*.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_singing_bowls_tool*.dart`（No issues found）
- 所有 9 个子文件 ≤ 500 行硬顶：主 373 / specs 309 / painters 364 / stage 164 / layout 263 / wide 385 / wide_tiles 189 / sheet 267 / sheet_controls 324。

## [Unreleased-PLAN_044] - 2026-04-23

### 原因
- 当前程序可运行，但禅意沙盘存在两类体验问题：单指绘制偶发误触缩放、背景效果音在一笔绘制过程中间歇性"掉一下"（听感断断续续）。
- 用户反馈此前的 PLAN_044 改动只修到一半未提交；本次在同一 PLAN 下续补。

### 修改
- 在 `toolbox_zen_sand_tool.dart` 中收紧缩放判定：
  - 单指绘制状态下忽略 `|details.scale - 1| <= 0.02` 的微抖动，不再误切换到 transform 模式。
- 在 `toolbox_zen_sand_tool.dart` 中做移动端窄屏抛光（纯 UI）：
  - 在 <390dp 窄屏下收缩 padding、提升 headerGap/sectionGap 压缩、在 <380dp 将 Header 折叠为上下两行（返回+标题 / 描述 / 快捷入口 chip 行）。
  - 两个抽屉卡片（场景 / 工具与控制）在可用宽度 <360dp 时改为单列；160-420 卡宽改为 170-360 更紧致。
  - 底部 dock 折叠态删除"底部菜单已折叠"冗余副标题，腾出宽度给主操作按钮；compact 态外层冗余 `SingleChildScrollView` 改为 `Padding`，移除嵌套纵向滚动。
- 在 `toolbox_zen_sand_sound_service.dart` 中彻底修复循环底噪"一笔中空音"：
  - **根因**：此前合成混用了 `phase`（0→1 循环）与 `t`（绝对秒）两套自变量，在 phase=1 处以 `t` 驱动的波形不会闭合，叠加的 `loopWindow = 0.92 + 0.08 sin(2π phase) sin(4π phase)` 在 phase=0/0.25/0.5/0.75 又周期性压 8% 振幅，被人耳感知为"一笔画画隔一会儿就掉一下"。
  - **修复**：`_buildLoopWav` 所有分量重写为纯 `phase` 基、整数频率倍数（`rustle/low/shimmer/motion/wash`），使波形在 phase 0↔1 处严格闭合；去除 `loopWindow`（= 1.0），消除内部周期性凹陷；`_seamBlendLoopPcm` 保留为保险带（从 96ms 降到 48ms）。
  - 循环底噪长度从 `880ms` 延长到 `3200ms`；非立即停止延时从 `140ms` 调整到 `240ms`，减少短抬手造成的断续感。

### 修复
- 修复禅意沙盘单指绘制时偶发"界面误判为缩放/平移"的问题。
- 修复禅意沙盘背景效果音"一笔绘制过程中间隔一会儿就掉一下"的根因（相位不闭合 + loopWindow 周期性压幅）。
- 提升 375dp/iPhone SE 等窄屏下 Header、dock、抽屉卡片的触达与阅读舒适度。

### 风险变更
- 音频合成分量数学表达变化，会改变底噪的纹理细节（仍在同一听感家族内）；未改变服务 API/事件语义/持久化。
- 所有 UI 改动严格遵守"只动 UI、不动逻辑"边界。

### 验证
- `dart format`（通过）
- `dart analyze lib/src/services/toolbox_zen_sand_sound_service.dart lib/src/ui/pages/toolbox_zen_sand_tool.dart`（仅既有 6 条 unused_element warning，无新增）
- `flutter build windows --debug`（通过）
- `flutter test --reporter compact`（All 231 tests passed）

## [Unreleased-PLAN_043-MERGE-READY] - 2026-04-21

### Reason
- Finalize branch `codex/plan024-backup` for merge readiness after AppState ownership split and large toolbox page decoupling.

### Changed
- AppState practice/playback domain state now reads/writes directly through `PracticeStore` and `PlaybackStore` ownership boundaries, removing bridge-style private alias indirection.
- Harp settings sheet large UI block was extracted from `toolbox_sound_tools/harp.dart` into `toolbox_sound_tools/harp_settings_sheet.dart`, keeping page-layer file focused on lifecycle and UI entry orchestration.
- `toolbox_sound_tools.dart` part registry updated for the new harp settings sheet part file.

### Verification
- Full regression passed with `flutter.bat test --reporter compact` (all tests passed).
- Regression rerun after fixing a temporary refactor replacement issue to ensure stable merge gate.

### Residual Risks
- `app_state.dart` and some toolbox page files are still above preferred file-size targets; next iteration should continue domain-by-domain extraction for sleep/wordbook/export ownership boundaries.

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
