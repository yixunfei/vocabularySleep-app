# 计划 304: toolbox 第一批移动端、音频与小游戏修复

## 基本信息
- **创建日期**: 2026-05-31
- **状态**: 进行中
- **负责人**: Codex
- **工作分支**: `codex/batch1-toolbox-mobile-fixes`
- **原始基线提交**: `fb63abf0e08ca29233964db93967ddc800489373`

## 背景
本批次覆盖睡眠助手、声音工具、游戏中心、日常决策、生活实用与部分代码结构治理问题。问题共同特征是移动端首屏可用性、触控误操作、音频初始化卡顿、入口不一致、文案本地化和历史结构分散。

由于范围较大，本计划优先确保每个修复可独立验证、可回滚、可交接。结构治理放到功能修复之后，且不与功能修复并行修改。

## 目标
1. 统一睡眠助手与外部入口的白噪/环境音页面，并修复在线目录音频名称本地化。
2. 改善游戏中心移动端体验：俄罗斯轮盘降噪或替换、俄罗斯方块一屏化、推箱子随机性、扫雷/五子棋触控误操作与无效全屏入口治理。
3. 优化舒缓轻音首次加载首屏反馈，并支持用户导入本地音乐。
4. 排查并降低模拟乐器、疗愈音钵等声音工具在手机端进入和交互时的明显卡顿。
5. 完善专注节拍、赛博木鱼、呼吸引导、念珠、禅意沙盘等沉浸类工具的移动端体验。
6. 修复日常决策去哪儿离线地图源提示歧义与生活实用子模块返回误触发退出应用弹窗。
7. 在业务修复稳定后，梳理代码和文件结构，降低后续定位成本。

## 范围清单
### A. 入口、导航与文案
- 睡眠助手进入的白噪环境音与外部入口应跳转同一页面或同一页面壳。
- 在线目录音频名称应按用户当前语言展示。
- 日常决策去哪儿离线地图只保留下载失败/网络环境提示，不再暗示固定首选源或可控网络环境。
- 生活实用所有子模块返回上一层时不得误触发退出应用弹窗。

### B. 游戏中心
- 俄罗斯轮盘现有表现过重且负面，优先改为隐藏入口或替换为更直白、低刺激的随机器表现。
- 俄罗斯方块在 375dp 手机宽度下必须舞台与操作区同屏可见，不遮挡上侧方块。
- 推箱子关卡生成需要降低重复三箱梯形等固定形态概率。
- 扫雷、五子棋需要减少手机端误缩放/误移动；若全屏棋盘未真正实现，则移除或隐藏该入口。

### C. 声音工具与性能
- 舒缓轻音首次加载时，进度反馈必须出现在首屏主舞台，不依赖用户下滑发现。
- 舒缓轻音支持用户自定义导入本地音乐，并纳入播放列表/最近使用逻辑。
- 模拟乐器与疗愈音钵进入卡顿、触发卡顿需优先做懒初始化、资源预热节流、绘制降负载与音频通道复用排查。

### D. 沉浸与触感工具
- 专注节拍修复动画与音效脱节，并在快速开始附近提供几个预设节拍效果。
- 赛博木鱼全屏模式只保留木鱼主体、设置唤起与退出控制。
- 呼吸引导补齐或重配场景语音/舞台效果，确保主题、呼吸节奏和提示一致。
- 念珠加入可开关、可调强度的轻微触觉反馈。
- 禅意沙盘非全屏移动端避免内容被遮挡；必要时加强全屏优先入口。

### E. 结构治理
- 汇总分散在上层和包目录中的模块文件，按页面、组件、服务、模型边界逐步整理。
- 结构治理不得与业务逻辑修复并行落代码；必须在功能批次完成、验证通过、变更日志更新后单独开始。

## 执行策略
### 阶段 0: 基线与并行只读探索
- [x] 确认工作区干净。
- [x] 从 `main` 创建分支 `codex/batch1-toolbox-mobile-fixes`。
- [x] 记录基线提交 `fb63abf0e08ca29233964db93967ddc800489373`。
- [x] 启动只读 explorer 并行定位代码边界：
  - `Zeno` / `019e7bab-b6a0-7ac2-94b9-5e0bc9b7723e`: 睡眠、舒缓轻音、音频性能。
  - `Confucius` / `019e7bab-ebbe-7b10-82f4-1033e565d310`: 游戏中心与棋盘触控。
  - `Nash` / `019e7bac-1e4d-7d83-ac46-18cf6e3a9a4a`: 专注节拍、木鱼、呼吸、念珠、沙盘、日常决策与生活实用。
- [x] 回收并整合三条只读探索结论。

## 探索回收结论
### 入口、睡眠与音频
- 白噪/环境音相关边界集中在 `toolbox_sleep_assistant_page.dart`、`sleep_quick_tools.dart`、`ambient_sheet.dart`、`app_state_ambient.dart`、`ambient_service.dart` 与 `online_ambient_sheet.dart`。
- 当前在线目录存在直接显示 `source.name` / `option.name`、slug 人工英文名、Dart 内硬编码中文映射和暴露 `relativePath` 的风险，需要回到 catalog key 与本地化 helper。
- 舒缓轻音首屏加载风险来自初始 `_loading` 状态、当前 mode preload 与主加载争抢资源，以及 loader 缺少 in-flight Future 去重。
- 乐器与音钵卡顿候选包括 UI isolate 上音频生成/临时文件写入、设置变化触发重复 warm up、音钵启动双 rebuild、全屏背景大面积 blur/repaint。

### 游戏中心
- 俄罗斯轮盘问题是枪械 painter、枪声/爆炸音效、红闪和强震动共同造成的体验风险，优先隐藏入口或替换为非武器主题，而不是只改样式。
- 俄罗斯方块移动端高度问题来自外层工具页 header/ListView、棋盘最小高度、难度设置、预览和手柄堆叠，需要一屏优先布局。
- 推箱子重复来自固定尺寸、起点范围窄、路线短、缺少最近关卡签名去重，以及失败回退固定 fallback。
- 扫雷/五子棋误操作来自 `InteractiveViewer` 的 pan/scale 与格子 tap/longPress 竞争；当前全屏只是原页面沉浸系统栏加高卡片，不是真全屏。

### 沉浸工具、地图与返回
- 专注节拍音频使用 `Timer + DateTime`，视觉使用 `AnimationController`，并叠加手工 30ms 延迟，存在声画相位漂移。
- 木鱼全屏仍保留过多顶部/底部控制和固定高度扣减，应改为最小 HUD。
- 呼吸引导的 `presetId` 与 `themeId` 可分离持久化，语音 cue 又按 scenario 解析，容易造成主题、语音和舞台不一致。
- 念珠只有布尔触觉开关，缺少轻/中/强等强度模型和旧配置迁移。
- 禅意沙盘非全屏由画布、chrome、横向工具条、多个滚动区和 overlay 共同抢高度。
- 地图能力更接近网络瓦片、Overpass、IP 粗定位和已浏览瓦片缓存，不应被 UI 暗示为真正离线地图源。
- 生活实用子模块以 `_activeTool` 本地状态切换，内层 `PopScope` 与 AppShell 外层 `PopScope(canPop:false)` 可能同时收到系统返回并弹退出确认。

### 调整后的首批实施顺序
1. 先修生活实用返回消费边界，降低对业务逻辑和 i18n 的影响。
2. 再收口每日决策去哪儿地图源提示，只改文案和 catalog，不改地图服务。
3. 接着统一白噪入口和在线目录本地化，处理同一领域入口/文案问题。
4. 游戏中心先做低风险治理：轮盘入口策略、扫雷/五子棋伪全屏入口移除或隐藏。
5. 再做俄罗斯方块一屏布局和推箱子随机去重。
6. 声音工具先做舒缓轻音首屏 loading 与加载去重，再做自定义导入。
7. 乐器/音钵性能单独做 profile 导向优化，不与导入功能混写。
8. 沉浸工具按专注节拍、木鱼、呼吸、念珠、沙盘顺序逐项收口。

### 阶段 1: 低耦合修复先行
- [x] 修复生活实用子模块返回误触发退出应用弹窗。
- [x] 收口日常决策去哪儿离线地图源提示文案。
- [x] 统一睡眠助手白噪入口与外部入口。
- [x] 修复在线目录音频名称本地化。

### 阶段 2: 游戏中心移动端体验
- [x] 确认俄罗斯轮盘处理策略：隐藏入口或替换为低刺激随机器。
- [x] 俄罗斯方块移动端一屏化布局与操作区压缩。
- [x] 推箱子关卡随机生成去重复。
- [x] 扫雷/五子棋禁用误触发缩放移动或改为稳定单点棋盘；移除未完成全屏入口。

### 阶段 3: 声音工具加载与导入
- [x] 舒缓轻音加载状态首屏可见。
- [x] 设计并实现本地音乐导入、播放列表合并和错误反馈。
- [x] 排查声音工具共用音频初始化、资源加载和绘制热点，并完成疗愈音钵低风险延迟初始化、防抖和绘制隔离切片。
- [x] 模拟乐器完成代码级优化分析；更大范围的多层采样/SoundFont 替换已拆到 `plans/PLAN_305_multisampled_instrument_engine_replacement.md`，本批不实现。

### 阶段 4: 沉浸工具体验补齐
- [x] 专注节拍声画同步与快捷预设。
- [x] 赛博木鱼全屏模式最小控制层。
- [x] 呼吸引导场景语音资产覆盖补齐；通用远端语音文件作为各场景 stage fallback，并按真实/近似时长限制播放速率。
- [x] 念珠触觉反馈开关与强度。
- [x] 禅意沙盘移动端非全屏遮挡修复。

### 阶段 5: 结构治理
- [x] 建立结构治理子计划，列出文件移动映射和不处理边界：`plans/PLAN_306_toolbox_structure_governance.md`。
- [ ] 单线完成文件结构调整，不并行改业务逻辑。
- [ ] 修复 import、导出 barrel 和测试路径。
- [ ] 单独验证并记录 changelog。

## 风险评估
- **音频性能风险**: 声音工具共用服务较多，直接改播放逻辑可能引入断音、重叠或平台差异。缓解措施：先定位瓶颈，再优先做懒加载、节流、缓存和 UI 绘制优化；避免改动播放语义。
- **i18n 风险**: 在线目录和地图提示涉及用户可见文本。缓解措施：所有新增/改名文案必须同步 `app_texts.csv`、七语言 JSON 与 registry，并运行 i18n 检查。
- **触控风险**: 扫雷、五子棋、沙盘、方块类游戏在移动端容易与父级滚动冲突。缓解措施：窄屏回归必须覆盖 375dp 宽度与连续手势。
- **结构治理风险**: 文件移动可能制造大 diff 和冲突。缓解措施：结构治理最后单独做，先记录映射，不混入功能行为变更。

## 并行协作规则
- 当前阶段只允许子 agent 做只读探索或互不重叠的小范围补丁。
- 若进入代码修改阶段，必须为每个 worker 指定互斥写入范围。
- 结构治理阶段禁止并行写入，由主线程单线完成。
- 任一子任务完成后，主线程必须复查 diff、运行对应验证，再进入下一子批次。

## 验证基线
每个实现子批次至少执行：
```powershell
dart analyze <changed dart files>
git diff --check
```

涉及 i18n 时额外执行：
```powershell
node scripts/audit_i18n_placeholders.js
rg -n "pickUiText|lookupBySourcePair|source-pair|_lifeText|_lifeCatalogPairText|_uiText|pickSleepText" lib test --glob "*.dart"
rg -n "\$\{|\\$[A-Za-z_][A-Za-z0-9_]*" lib/l10n/catalog/app_texts.csv
flutter test test/app_i18n_catalog_test.dart --reporter compact
```

涉及移动端布局/手势时额外确认：
- 375dp 宽度下首屏信息、主操作、加载/错误/选中态均可见。
- 方块、棋盘、沙盘等连续手势不被父级滚动抢焦点。
- 全屏入口若保留，必须真的进入沉浸布局；否则隐藏或移除。

## 交接说明
新会话接手时，从以下顺序恢复：
1. `git status --short` 确认工作区状态。
2. `git branch --show-current` 确认在 `codex/batch1-toolbox-mobile-fixes`。
3. 阅读本计划的阶段状态和最新 changelog 条目。
4. 先处理阶段 1 的低耦合修复，再进入游戏和音频性能批次。
5. 每完成一个阶段，先更新 `changelogs/CHANGELOG.md`，再更新本计划勾选状态和风险记录。

## 当前进度记录
### 2026-05-31
- 实施切片 2 已完成：赛博木鱼全屏最小 HUD、念珠触觉强度持久化、禅意沙盘窄屏/矮屏折叠、专注节拍快捷预设与固定视觉延迟移除、呼吸引导加载时场景主题对齐、疗愈音钵首帧后初始化/参数防抖/RepaintBoundary/移动端 burst 限制。
- 切片 2 已验证：目标 `dart analyze`、`node scripts\audit_i18n_placeholders.js`、旧 helper 扫描、catalog Dart 插值扫描、`flutter test test\app_i18n_catalog_test.dart --reporter compact`、`flutter test test\toolbox_mini_games_roulette_smoke_test.dart --reporter compact`、`flutter test test\ui_smoke_test.dart --plain-name "app shell keeps bottom navigation inside life tools" --reporter compact`、`flutter test test\toolbox_audio_bank_regression_test.dart --reporter compact`、`flutter test test\toolbox_zen_sand_sound_service_test.dart --reporter compact`、`git diff --check`。
- 当前剩余：结构治理实际文件移动仍需在功能修复提交稳定后单独分支/单线执行；舒缓轻音远程曲目已按“首次远程加载、后续本地缓存”处理，只有用户自定义本地导入的路径持久化与失效文件恢复可作为后续增强。
- 实施切片 3 已完成：呼吸引导接入用户已上传的通用远端语音清单作为 stage fallback，播放时基于 WAV 实际时长/近似时长计算速率并设置自然上限；腹式基础首轮首个吸气阶段接入 `开始用鼻子缓缓吸气.wav`；呼吸舞台按浅色/深色主题切换暖色/暗色背景与对应前景色；多层采样乐器替换拆为 `PLAN_305`，当前批次不实现；结构治理拆为 `PLAN_306`，当前批次只完成映射和风险边界。
- 切片 3 已验证：`dart analyze lib\src\services\audio_player_source_helper.dart lib\src\ui\pages\toolbox_breathing_tool.dart lib\src\ui\pages\toolbox_breathing_ui_parts.dart test\toolbox_breathing_audio_repository_test.dart`、`flutter test test\toolbox_breathing_audio_repository_test.dart --reporter compact`、`flutter build windows --debug`、`flutter test test\app_i18n_catalog_test.dart --reporter compact`、`node scripts\audit_i18n_placeholders.js`、旧 helper 扫描、catalog Dart 插值扫描和 `git diff --check` 均通过。
- 实施切片 1 已完成：生活实用子模块系统返回消费、每日决策地图源提示、睡眠助手白噪入口统一、在线环境音展示本地化、游戏中心随机选择器替换、俄罗斯方块窄屏紧凑布局、扫雷/五子棋去除误缩放与伪全屏、推箱子最近关卡去重、舒缓轻音首屏加载提示与本地音频导入。
- 已验证：目标 `dart analyze`、随机选择器 smoke、i18n catalog test、生活实用返回 smoke、i18n placeholder audit、旧 helper 扫描、catalog Dart 插值扫描、`git diff --check`。
- 创建本批次分支并记录基线提交。
- 创建本计划，完成任务拆分、风险边界和验证基线。
- 启动并回收三个只读 explorer，补充根因候选、关键文件边界和调整后的首批实施顺序。
