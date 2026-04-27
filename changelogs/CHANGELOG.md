# CHANGELOG

## [Unreleased-PLAN_070-EAT-OVERHAUL-TAKEOVER] - 2026-04-27

### 原因
- 用户反馈工具箱「每日决策 - 吃什么」子模块存在数据源错乱、筛选字段不准、严重性能瓶颈、随机体验异常、加载阻塞、管理 UI 强聚合、分页体验差和 `TextEditingController` 生命周期崩溃等系统性问题。
- 用户要求先对当前工作区做备份式提交，再创建可持续接手的完整任务工作流与计划，便于后续会话继续推进。

### 新增
- 新增 `plans/PLAN_070_每日决策吃什么子模块全面接管与数据UI重构.md`，记录接管分支、备份提交、阶段拆分、13 个问题验收标准、数据重建原则、schema 优化方向、UI 拆分边界和后续验证策略。
- 新增 `DailyChoiceHub keeps other modules usable while eat library loads` smoke 测试，锁定吃什么摘要加载未完成时仍可切换并使用其他每日决策模块。
- 新增 `scripts/audit_daily_choice_recipe_dataset.py`，审计当前 `D:\vocabularySleep-resources\cook_data` JSON/SQLite 与 YunYouJun/cook `recipe.csv` 的字段冲突、来源覆盖、菜系 notes 污染、食材别名过宽匹配和抽取乱码。
- 新增 `records/record_070_daily_choice_recipe_data_audit.md` 与 `records/record_070_daily_choice_recipe_data_audit.json`，记录首轮数据源审计结果。
- 新增 `records/record_070_daily_choice_recipe_data_audit_after_generation.md` 与 `records/record_070_daily_choice_recipe_data_audit_after_generation.json`，记录修正生成规则后的隔离验证包审计结果。
- 新增 `records/record_070_daily_choice_recipe_schema_design.md`，记录吃什么 v2 数据库表设计、索引策略、典型查询、迁移顺序和验收标准。
- 新增 `scripts/daily_choice_recipe_schema_v2.sql`，作为后续生成器与 Flutter store 迁移的可执行 SQLite schema 草案。
- 新增 `decisions/ADR_070_daily_choice_recipe_schema_v2.md`，记录 v2 分层 schema 的技术决策。
- 新增 `records/record_070_daily_choice_s3_upload_package.md`，记录 `cook_data_plan070_validation` 压缩后文件大小、建议 S3 key、远端安装边界和验证命令。
- 新增 `DailyChoiceEatLibraryStore` 远端失败边界测试，覆盖“已有 SQLite 库时刷新失败不覆盖旧库”和“首次远端失败不生成 bundled JSON fallback”。
- 新增 `scripts/verify_daily_choice_recipe_remote.dart`，用于通过 S3 远端完整下载吃什么 SQLite DB，并验证 v1/v2 表计数、meta 和 sample detail。
- 新增 `records/record_070_daily_choice_remote_db_smoke.md`，记录 S3 `/cook_data` 上传后远端 key、文件大小、完整下载 smoke、meta 与 v2 当前状态。
- 新增吃什么 catalog 回归测试，覆盖“全部餐段”默认候选池、花生坚果组合忌口，以及 `排骨` 不再退化成通用 `pork` 食材 token。
- 新增 `records/record_070_daily_choice_v2_only_db_package.md`，记录新版 v2-only 上传 DB 的输出路径、大小、SHA256、schema/meta、表计数和运行时边界。
- 新增 `records/record_070_daily_choice_recipe_v2_only_db_audit.md` 与 JSON 审计结果，记录 v2-only DB 与验证包 JSON 的一致性、cook CSV 覆盖和 10 个数据问题桶结果。
- 新增 `records/record_070_daily_choice_remote_v2_runtime_smoke.md`，记录用户更新 S3 后的远端 v2-only DB 完整下载 smoke 和运行时读取验证。
- 新增 `DailyChoiceEatLibraryStore installs v2-only SQLite and lazy loads details` 单测，覆盖 v2-only DB 的安装、book/cook 计数、摘要轻量读取和详情懒加载。
- 新增 `DailyChoiceEatLibraryQuery` 与 `DailyChoiceEatLibraryQueryResult`，为吃什么 v2 内置库提供分页摘要、总数、完整随机候选 id 池和后续 random pivot 接入口。
- 新增 `records/record_070_daily_choice_v2_sql_query_foundation.md`，记录 v2 SQL 查询基础、本轮边界、测试覆盖和后续 UI 接入风险。
- 新增 v2 SQL 查询单测，覆盖索引筛选、分页摘要、`排骨` 精确食材匹配和花生坚果组合忌口。
- 新增 `DailyChoiceEatLibraryStore.pickBuiltInRandomSummary(...)`，支持按 v2 `random_key` pivot 从完整候选池抽取轻量摘要。
- 新增 `records/record_070_daily_choice_v2_random_pivot.md`，记录 store 层 random pivot 能力、测试覆盖和后续 UI 接入边界。
- 新增 `DailyChoiceRandomPanel` 可选异步最终抽取入口，供吃什么主 UI 在停止随机时接入 store random pivot。
- 新增 `records/record_070_daily_choice_ui_random_and_manager_sql_paging.md`，记录主 UI 随机与管理页内置库 SQL 分页接入边界。
- 新增随机面板 widget 回归测试，覆盖候选池变化后旧异步抽取结果不回写当前 UI。
- 新增 `DailyChoiceEatLibraryQuery.searchText`，为管理页吃什么内置库搜索下沉到 v2 SQLite search table 提供查询字段。
- 新增 `records/record_070_daily_choice_manager_sql_search.md`，记录管理页内置库搜索下沉范围、验证和后续 FTS/拆页方向。
- 新增管理页 SQL 内置摘要详情懒加载回归测试，覆盖内存全量摘要为空时仍可从 store 打开详情。
- 新增 `records/record_070_daily_choice_manager_item_action_states.md`，记录管理页内置菜谱逐项 loading / disabled / error 状态的实现边界和验证。
- 新增管理页内置菜谱逐项动作回归测试，覆盖 detail 慢读取期间不重复触发请求，以及 detail 失败时保留当前 sheet 并显示局部错误。
- 新增 `records/record_070_daily_choice_manager_auto_paging_and_search_commit.md`，记录管理页自动分页、搜索提交边界和后续 FTS/倒排表风险。
- 新增管理页自动分页与搜索提交回归测试，覆盖滚动触底自动扩大 SQL 分页 limit，以及输入搜索词期间不查询、失焦后才提交 `searchText`。
- 新增 `records/record_070_daily_choice_random_stop_timeout_and_pivot_guard.md`，记录随机停止超时兜底、大候选池 SQL guard 和本轮验证。
- 新增随机停止回归测试，覆盖异步最终抽取超时后退出 `Picking`，以及隐藏项导致需要精确可见池且候选过大时不触发重 SQL pivot。

### 修改
- 将后续工作流明确为：每轮先更新计划边界，再实施改动，完成后更新 changelog 与计划进度，并按阶段提交。
- 明确下一轮优先处理 P0 稳定性：每日决策入口不被吃什么菜谱库加载阻塞、管理 sheet controller 生命周期崩溃、随机面板停止按钮位置跳动和明显卡顿入口。
- `DailyChoiceHub` 初始化不再等待吃什么菜谱库摘要加载完成；首屏只等待轻量自定义状态，吃什么菜谱库在进入吃什么模块后后台读取。
- 吃什么资源状态面板区分后台读取和安装加载，读取期间只影响吃什么模块自身，不阻塞穿什么、去哪儿、干什么和决策助手。
- 随机面板候选舞台固定高度，随机时限制标题、简介和标签行数，让停止按钮位置保持稳定。
- 将 `PLAN_070` 阶段 2 标记为进行中，并写入首轮数据审计发现：`vegetarian` 与肉类/海鲜冲突 530 条，`vegan_friendly` 与动物性食材冲突 496 条，菜系标签混入 notes 2221 条，`清真友好` 规则说明混入 notes 3416 条，cook CSV 599 行中 569 行未在当前库标题精确命中。
- `scripts/generate_daily_choice_recipe_dataset.py` 停用自动生成 `halal_friendly`、`vegan_friendly`、`vegetarian_friendly` diet 标签，避免无依据饮食友好标签继续进入筛选和展示。
- 菜谱生成器不再把菜系标签或清真说明写入 notes，并统一清理 `??`、替换符等抽取乱码。
- 食材抽取收紧高风险别名：`蛋` 不再作为鸡蛋裸词匹配，`洋葱` 不再误索引为 `葱`，`排骨`、`猪里脊`、`猪油`、`猪肝`、`猪蹄` 等具体猪肉项不再折叠成通用 `猪肉`。
- 动物性风险判断补充兔肉、龟肉、甲鱼、鸽、鹌鹑、鹅肉、田鸡、牛蛙、牡蛎、蛤、蚌等词，`profile:vegetarian` 只在原始文本未命中肉类/水产风险时写入。
- 将 YunYouJun/cook `recipe.csv` 导入生成器作为 `cook_csv` 数据来源，保留 difficulty、tags、methods、tools、bv、stuff 到结构化 attributes，并避免写入用户可见 sourceLabel、sourceUrl 和 references。
- SQLite 导出 meta 现在写入真实 `bookRecipeCount` 与 `cookRecipeCount`，便于后续菜谱集分表和管理页展示。
- 将 `PLAN_070` 阶段 3 标记为进行中，并明确本轮边界为数据库与索引设计，不直接迁移 Flutter 读取逻辑。
- v2 schema 设计为 14 张表、18 个索引：菜谱集、基础索引、摘要、详情、材料/步骤行表、通用筛选索引、食材专用索引、搜索文本、本地用户状态和集合成员表。
- 食材匹配索引拆为 `raw`、`canonical`、`family` 三层，并增加 `idx_dcr_ingredient_value_lookup` 保障默认 raw/canonical 查询。
- 将 `D:\vocabularySleep-resources\cook_data_plan070_validation` 中三份 JSON 压缩为上传前版本：`daily_choice_recipe_library.json` 19,614,095 bytes、`daily_choice_recipe_library_summary.json` 4,918,383 bytes、`recipe_library_asset.json` 19,614,095 bytes。
- `DailyChoiceEatLibraryStore.installLibrary()` 改为远端 SQLite 候选文件安装：先下载到 `.remote` 候选 DB，规范 meta 并校验菜谱数，通过后才替换当前安装库。
- `inspectStatus()` 在未安装 SQLite 文件时只返回空状态，不再为了检查状态创建空数据库文件。
- 已验证用户上传到 S3 `/cook_data` 的远端包：运行时默认 key `cook_data/daily_choice_recipe_library.db` 可 HEAD、range 和完整下载，下载后 v1 summary/detail 均为 7,772 行。
- `scripts/generate_daily_choice_recipe_dataset.py` 的 SQLite 导出改为 v1/v2 双写：保留现有 v1 runtime 表，同时写入菜谱集、v2 基础索引、摘要、详情、材料/步骤、筛选索引、食材 raw/canonical/family 索引、搜索文本和集合统计表。
- 吃什么餐段默认改为“全部”，catalog 在 `mealId == 'all'` 时基于完整候选池筛选，不再按当前时间或午餐默认收窄。
- 忌口预设精简为香菜、海鲜、花生坚果、酒精、辣椒；花生坚果在筛选层展开为 `peanut` + `nut`，保持 UI 简洁但不丢过滤语义。
- 食材匹配继续收紧：`排骨`、猪蹄、猪肝、猪肚、猪油、火腿、培根、腊肉、腊肠等具体猪肉项不再作为默认 `pork` 食材同义词，只在 v2 family index 和 contains 排除里显式归入猪肉大类。
- `scripts/generate_daily_choice_recipe_dataset.py` 的 SQLite 导出默认改为 v2-only；需要兼容旧 runtime 时可显式使用 `--sqlite-mode v1-v2`。
- v2 SQLite 导出写入 `PRAGMA user_version=2`，便于上传后快速识别 schema 版本。
- `scripts/audit_daily_choice_recipe_dataset.py` 支持自动识别 v2-only DB，不再强依赖 v1 summary/detail 表。
- `scripts/verify_daily_choice_recipe_remote.dart` 支持 v1、v2 或 v1/v2 双写 DB 的远端 smoke 验证。
- 已验证用户更新后的 S3 `cook_data/daily_choice_recipe_library.db` 为 v2-only DB：远端大小 142,467,072 bytes，`user_version=2`，v2 recipes/summaries/details 均为 7,772 行。
- `DailyChoiceEatLibraryStore` 增加 schema 自动识别，优先读取 v2 表，同时保留 v1 旧库读取能力。
- `DailyChoiceEatLibraryStore` 的远端 DB 安装归一化按 schema 写入 meta：v2 写入 `daily_choice_recipe_schema_meta`，v1 继续写入 `daily_choice_eat_recipe_meta`。
- 吃什么内置菜谱摘要读取新增 v2 查询路径：从 `daily_choice_recipes` + `daily_choice_recipe_summaries` 读取轻量摘要，详情、材料、步骤继续按需从 `daily_choice_recipe_details` 懒加载。
- `DailyChoiceEatLibraryStore.queryBuiltInSummaries()` 在 v2 DB 中使用 `daily_choice_recipe_filter_index` 处理餐段、厨具和 trait 筛选，并使用 `daily_choice_recipe_ingredient_index` 的 raw/canonical 层处理忌口排除和已有食材优先匹配。
- legacy v1 库和缺少 v2 筛选索引的库继续回退到内存 `DailyChoiceEatCatalog` 过滤，避免查询入口影响已有本地库可读性。
- v2 随机候选 id 查询按 `random_key` 排序并去重，避免 raw/canonical 同时命中时让同一菜谱在随机池中重复出现。
- v2 random pivot 复用 `DailyChoiceEatLibraryQuery` 条件，并在 pivot 后半段无命中时回绕到候选池开头；随机抽取不读取详情字段。
- 吃什么主 UI 在随机池全为可见内置菜谱时，停止随机会调用 `pickBuiltInRandomSummary(...)` 作为最终选中来源；随机池混入本地自定义时继续使用内存结果。
- 随机面板在候选池变化时会让仍在进行的异步最终抽取失效，避免旧筛选结果回写到新筛选候选池。
- 管理页吃什么内置库使用 `queryBuiltInSummaries(...)` 分页读取；搜索词非空时同步传给 store，并优先使用 v2 `daily_choice_recipe_search_text` 查询。
- 管理页异步 SQL 查询在 sheet 关闭后不再调用 `setSheetState`，且失败时记录当前查询 key，降低关闭/返回和失败重试的生命周期风险。
- 吃什么详情/个人调整/另存入口的内置菜谱判断改为基于模块、安装状态和轻量摘要内容，不再要求当前内存 `builtInOptions` 全量列表包含该 id。
- 管理页吃什么内置菜谱的详情、个人调整、另存入口统一接入条目级异步动作状态；动作进行中会禁用同一条目的 detail/edit/copy 入口，并在条目内展示 loading 或错误反馈。
- 吃什么管理页内触发详情读取时由 manager sheet 承接局部错误；主 UI 的详情按钮仍沿用 SnackBar 错误反馈。
- 管理页吃什么内置库移除“继续加载”按钮，改为滚动接近底部时自动递增 SQL 查询 limit，并在加载下一页时保留当前已显示摘要。
- 管理页搜索框改为组件级 `TextEditingController` / `FocusNode` 管理；输入只更新 draft，离开输入框或提交搜索后才刷新 SQL 搜索词。
- 吃什么主 UI 停止随机时，无隐藏/个人调整/食谱集约束的内置候选池不再把全量 id 列表传给 `pickBuiltInRandomSummary(...)`，改为直接复用当前 SQL 筛选条件。
- 需要精确可见池的随机停止场景若候选 id 超过 300 个，会跳过 store random pivot 并保留当前锁定候选，避免构造大 `IN (...)` 查询。

### 风险变更
- 本轮只建立接管计划，不直接修改业务逻辑和远端/本地菜谱数据；实际数据清洗、schema 迁移和 UI 拆分将在后续阶段分批落地。
- `plans/` 目录在当前仓库 `.gitignore` 中默认忽略，本计划需要作为本次接管凭据强制纳入提交。
- 吃什么摘要加载改为模块级后台任务后，摘要未完成前吃什么候选池会保持为空并显示资源准备状态；这是有意降级，用来换取每日决策其他模块不被阻塞。
- 本轮生成的验证包位于 `D:\vocabularySleep-resources\cook_data_plan070_validation`，尚未覆盖 `D:\vocabularySleep-resources\cook_data`；后续确认后再执行替换或上传。
- cook CSV 原始 599 行中按标题/厨具去重导入 593 条菜谱，但审计按标题确认 599 行全部可在新库中命中。
- v2 schema 已接入 app 运行时的安装、状态、摘要和详情读取路径；后续仍需要把分页、筛选索引查询和 random pivot 下沉到 v2 SQL。
- SQLite 仍需要下载到应用支持目录后才能查询；本轮“不保留本地”收口为不再保留或生成 JSON 兜底缓存，而不是流式查询远端 SQLite。
- 吃什么远端首装失败且无旧库时会返回错误状态和空候选池，不再静默生成 fallback 菜谱库；这是有意让数据可信度优先于离线兜底。
- 当前已上传远端 DB 已切换为 v2-only，不再包含 v1 兼容表；旧版本 app 若只支持 v1 表将无法读取新版远端包。
- `scripts/verify_daily_choice_recipe_remote.dart` 为纯 Dart S3 smoke 工具，需要通过环境变量或命令行参数提供 S3 配置；本轮验证时配置从现有 `CstCloudS3CompatClient` 默认值读取后注入环境变量。
- 本轮重新生成的 `D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db` 为 v2-only DB，大小 142,467,072 bytes，SHA256 为 `9B769482EEA198E233263EB41E8FA01ECAA3C058E25F68377ED8E468F62C6FFE`；当前 app 已接入基础 v2 读取，但筛选和随机仍基于安装后加载的摘要集合。
- 本轮未覆盖 `D:\vocabularySleep-resources\cook_data` 原始数据；S3 远端 DB 已由用户更新，本轮仅做远端 smoke 和运行时读取修复。
- 当前 UI 仍保留内存 catalog 作为本地自定义、个人调整和旧库回退路径；吃什么内置库随机、管理页浏览和内置库搜索已逐步接入 store 查询。
- 已有食材优先的 SQL 版本先采用 raw/canonical 任一命中收口，尚未完整复刻内存 catalog 的 exact/strong/broad 分层扩池策略。
- random pivot 在主 UI 中只覆盖随机池全为可见内置菜谱的场景；legacy v1 fallback 使用候选 id 列表取模抽取，不具备 v2 `random_key` 的稳定全局分布。
- 管理页吃什么内置库搜索已接入 SQLite `daily_choice_recipe_search_text`；本地自定义和个人调整搜索仍走内存过滤，后续若要统一语义需单独处理 overlay 搜索。
- 当前搜索仍是 `instr`/substring 查询，不是 FTS；拼音、分词、多关键词相关性排序需后续单独引入 FTS5 或倒排表。
- 大候选池且存在隐藏/个人调整/食谱集约束时，最终随机分布会回退到当前 UI 随机过程锁定的候选；这是为避免停止按钮等待重 SQL 的性能兜底。

### 修复
- 修复每日决策入口被吃什么菜谱库摘要加载拖住的问题。
- 修复管理 sheet 新建食谱集输入框因函数级 `TextEditingController` 在关闭/重建时被释放后继续参与 TextField 构建的崩溃风险。
- 修复随机过程中菜品内容换行导致停止按钮上下跳动、难以点击的问题。
- 修复当前生成数据中素食/纯素冲突、清真说明污染 notes、菜系标签污染 notes、洋葱误索引葱、具体猪肉项折叠为通用猪肉和抽取乱码等审计问题。
- 修复远端 DB 安装失败时可能回退到 bundled JSON / cached CSV / fallback seed 并写入本地 JSON cache 的问题。
- 修复远端刷新失败时可能直接覆盖现有 SQLite 库的风险；现在候选 DB 校验通过后才替换旧库。
- 修复吃什么默认餐段过早收窄候选池的问题；默认现在从全部餐段候选中随机。
- 修复 `排骨` 等具体食材在运行时食材匹配中被自动折叠为通用猪肉 token，导致输入排骨可能扩大到全猪肉菜谱的问题。
- 修复新版 v2-only 远端 DB 因 `PRAGMA user_version=2` 被当前 store 判定为不支持新 schema，导致安装或读取失败的问题。
- 修复 v2-only DB 缺少 v1 summary/detail 表时，吃什么摘要和详情读取 SQL 仍固定查询 v1 表的问题。
- 修复 v2 查询候选 id 在 raw/canonical 同时命中时可能重复返回同一菜谱，导致随机权重被意外放大的问题。
- 修复后续分页接入时随机可能只落在当前分页窗口的问题基础：store 层 random pivot 现在忽略 `limit` / `offset`，始终按完整候选池抽取。
- 修复管理页内置库浏览和搜索仍同步过滤完整吃什么内置列表的性能路径，改为按当前筛选与搜索词分页查询 SQLite。
- 修复管理页 SQL 分页返回的内置摘要在内存全量摘要缺失时无法按需读取完整详情的隐性依赖。
- 修复管理页内置菜谱详情/个人调整/另存可重复点击导致重复 detail 读取的问题。
- 修复管理页内置菜谱 detail 读取失败时只能走全局提示、缺少条目级错误反馈的问题；现在失败不会关闭管理 sheet 或清空当前搜索/分页状态。
- 修复管理页搜索框每次输入字符都触发 SQL 查询的问题；现在只在失焦或提交时触发搜索。
- 修复随机停止后因最终抽取耗时过长可能长时间卡在“选中中 / Picking”，且无法稳定显示最终菜谱的问题。
- 修复主 UI 停止随机时对大候选池传入全量 `allowedOptionIds`，导致 v2 SQL random pivot 构造大 `IN (...)` 查询并拖慢交互的问题。

### 验证
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `git switch -c codex/daily-choice-overhaul`（通过）
- `git commit -m "chore: backup current workspace before daily choice overhaul"`（通过，备份提交 `735b95a`）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice test/daily_choice_hub_smoke_test.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart test/daily_choice_eat_library_store_test.dart`（通过）
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart test/daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `python -X utf8 scripts\audit_daily_choice_recipe_dataset.py --cook-csv .tmp_recipe_csv_head.txt`（通过）
- `python -m py_compile scripts\audit_daily_choice_recipe_dataset.py`（通过）
- `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py scripts\audit_daily_choice_recipe_dataset.py`（通过）
- `python -X utf8 scripts\generate_daily_choice_recipe_dataset.py --cook-csv .tmp_plan070_recipe.csv --output D:\vocabularySleep-resources\cook_data_plan070_validation\recipe_library_asset.json --export-dir D:\vocabularySleep-resources\cook_data_plan070_validation`（通过）
- `python -X utf8 scripts\audit_daily_choice_recipe_dataset.py --library-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.json --summary-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library_summary.json --sqlite-db D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db --cook-csv .tmp_plan070_recipe.csv --output-md records\record_070_daily_choice_recipe_data_audit_after_generation.md --output-json records\record_070_daily_choice_recipe_data_audit_after_generation.json`（通过，10 个审计问题桶均为 0）
- `python -X utf8` 内存 SQLite 执行 `scripts\daily_choice_recipe_schema_v2.sql`（通过，创建 14 张表和 18 个索引）
- `EXPLAIN QUERY PLAN` 验证 v2 摘要分页、通用筛选、食材匹配和随机 pivot 查询（通过，命中目标索引）
- `python -X utf8` 解析 `D:\vocabularySleep-resources\cook_data_plan070_validation` 中三份压缩 JSON（通过，三份 JSON 均为 7,772 条菜谱）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_library_store.dart test/daily_choice_eat_library_store_test.dart`（通过）
- `flutter test test/daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `dart run scripts/s3_resource_probe.dart --op list --prefix cook_data/ --max-keys 20`（通过）
- `dart run scripts/s3_resource_probe.dart --op head --key cook_data/daily_choice_recipe_library.db`（通过，47,915,008 bytes）
- `dart run scripts/s3_resource_probe.dart --op get-range --key cook_data/daily_choice_recipe_library.db`（通过，SQLite 文件头）
- `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py`（通过）
- `dart run scripts/verify_daily_choice_recipe_remote.dart --key cook_data/daily_choice_recipe_library.db --expected-count 7772`（通过）
- `python -X utf8` 最小数据集调用 `write_sqlite_export(...)` 验证 v1/v2 双写（通过）
- `dart analyze scripts/verify_daily_choice_recipe_remote.dart lib/src/ui/pages/toolbox_daily_choice test/daily_choice_eat_catalog_test.dart test/daily_choice_eat_library_store_test.dart`（通过）
- `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py scripts\audit_daily_choice_recipe_dataset.py`（通过）
- `dart format scripts\verify_daily_choice_recipe_remote.dart`（通过）
- `dart analyze scripts\verify_daily_choice_recipe_remote.dart`（通过）
- `python -X utf8` 从验证包 JSON 调用 `write_sqlite_export(..., sqlite_mode='v2')` 重写 `D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db`（通过，7,772 条）
- `python -X utf8` 检查 v2-only DB：`PRAGMA integrity_check=ok`、`user_version=2`、v1 summary/detail 表不存在、v2 recipes/summaries/details 均为 7,772 行（通过）
- `python -X utf8 scripts\audit_daily_choice_recipe_dataset.py --library-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.json --summary-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library_summary.json --sqlite-db D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db --cook-csv build\_external\cook\app\data\recipe.csv --output-md records\record_070_daily_choice_recipe_v2_only_db_audit.md --output-json records\record_070_daily_choice_recipe_v2_only_db_audit.json`（通过，10 个审计问题桶均为 0，cook CSV 599 行全部标题命中）
- `dart run scripts/verify_daily_choice_recipe_remote.dart --key cook_data/daily_choice_recipe_library.db --expected-count 7772`（通过，完整下载用户更新后的远端 v2-only DB，v2 recipes/summaries/details 均为 7,772 行）
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart scripts\verify_daily_choice_recipe_remote.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过，管理页内置库搜索下沉后无静态问题）
- `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`（通过，覆盖 v2 search table 查询）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖管理页搜索词传入 store 查询并只展示命中内置菜）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过，管理页 SQL 摘要 detail 解耦后无静态问题）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖内存摘要为空时管理页 SQL 摘要仍可打开详情，以及个人调整前 detail 懒加载）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart`（通过）
- `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`（通过，覆盖 v2 SQL 筛选、分页、食材精确匹配和组合忌口）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart`（通过，新增 random pivot API 后无静态问题）
- `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`（通过，覆盖 pivot 命中、回绕和分页窗口外候选抽取）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖停止随机触发 store pivot、管理页展开内置库触发 SQL 查询、候选池变化后旧异步抽取不回写）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`（通过）
- `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖随机停止超时兜底和大可见池本地 fallback）
- `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过）
- `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）

## [Unreleased-PLAN_069-BUILD-DISABLE-WEB] - 2026-04-26

### 原因
- 用户反馈 `.\scripts\build.ps1` 打 Web 包时失败，错误来自 `sherpa_onnx`、`sqlite3`、`ffi` 等 `dart:ffi` 依赖在 Flutter Web / Dart2JS 下无法编译。
- 当前项目主要目标不是 Web，暂不投入 Web 专用实现或条件导入重构。

### 修改
- `scripts/build.ps1` 的默认 `all` 目标不再包含 `web`，Windows / macOS / Linux 宿主平台均只保留当前可用的 Android 与桌面构建目标。
- 移除脚本中的 Web 构建分支，避免默认打包跑到 `flutter build web` 后输出大量 FFI 编译错误。
- 显式传入 `-Target web` 时，脚本会在目标解析阶段直接提示：当前因 `sherpa_onnx`、`sqlite3`、`ffi` 等 FFI 依赖禁用 Web，需要 Web 专用实现后再重新启用。

### 修复
- 修复 `.\scripts\build.ps1` 默认全量打包时被 Web 目标拖失败的问题。

### 风险变更
- `web` 不再是脚本支持目标；后续若需要恢复 Web 包，需要先处理 FFI 依赖的 Web 替代实现或条件导入隔离。

### 验证
- `.\scripts\build.ps1 -DryRun -NoPubGet`（通过，输出 Android APK / Android AppBundle / Windows，不再包含 Web）
- `.\scripts\build.ps1 -Target web -DryRun -NoPubGet`（按预期失败，并输出 FFI 依赖导致 Web 禁用的明确提示）
- `.\scripts\build.ps1 -Target android-apk -NoPubGet`（通过，产物输出到 `dist/android-apk/xianyushengxi.apk`）

## [Unreleased-PLAN_068-EAT-COOKING-GUIDE-PERF] - 2026-04-26

### 原因
- 用户要求「每日抉择 - 吃什么」中的做菜指南改成标准、通用、可长期扩展的做菜基准手册，移除混杂的项目 / 程序帮助内容。
- 用户要求参考 YunYouJun/cook 与本地 `D:\vocabularySleep-resources\做菜` 资料中的通用烹饪技巧、规范与安全边界。
- 用户要求把「高级设置」上移，并继续优化电脑端和手机端都能感知到的卡顿。

### 新增
- 新增 `test/daily_choice_cooking_guide_test.dart`，覆盖做菜指南不再出现 `recipe.csv`、`SQLite`、安装、远端、数据源等项目帮助语，并确认指南包含入厨、采购、清洗、刀工、火候和翻车排查等基准章节。

### 修改
- 重写吃什么做菜指南为通用烹饪手册结构，覆盖入厨前判断、采购验收、清洗去污、刀工切配、备料顺序、调味基准、火候锅具、基础处理技法、常用烹调法、米面烘焙、保存复热和翻车排查。
- 做菜指南参考来源改为「参考与延伸阅读」附录口吻，只保留资料标题和摘要说明，不再解释项目字段、页面行为或接入边界。
- 吃什么页面将「高级设置」前置到随机主舞台之前，让用户先收口已有材料、忌口、荤素 / 清真等条件，再开始随机。
- 随机面板运行中不再每 120ms 触发整块 `AnimatedSwitcher` 切换动画，只更新同一个候选舞台；停止选中时保留正常过渡，降低随机过程中的重建与合成压力。
- 菜谱库摘要加载改为后台 isolate 打开 SQLite 并解析摘要，失败时回退主 isolate 读取，减少进入吃什么界面时主线程同步解码压力。
- 管理页内置菜谱筛选增加缓存键，展开内置库后折叠 / 展开其他区域不再重复过滤全量内置菜谱。

### 修复
- 修复做菜指南中混入 `recipe.csv`、筛选字段、页面匹配逻辑、未接入资料等项目帮助说明的问题。
- 修复随机滚动时因高频切换动画导致的明显卡顿风险。
- 修复管理页展开内置库后轻量 UI 状态变化仍反复扫描完整菜谱库的性能浪费。

### 风险变更
- 摘要后台 isolate 读取依赖 SQLite 文件可被第二连接并发只读打开；若目标平台 isolate 读取失败，会自动回退既有主线程读取路径。
- 做菜指南内容明显变丰富，但仍只在指南弹窗内按模块选择渲染，不常驻主页面。
- 管理页筛选缓存仍基于本地摘要全集；若菜谱量继续增长到数十万级，后续应把管理搜索继续下沉到 SQLite 倒排 / FTS 查询。

### 验证
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_library_store.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart test/daily_choice_cooking_guide_test.dart test/daily_choice_hub_smoke_test.dart`（通过）
- `flutter analyze lib/src/ui/pages/toolbox_daily_choice test/daily_choice_cooking_guide_test.dart test/daily_choice_hub_smoke_test.dart test/daily_choice_eat_library_store_test.dart`（通过）
- `flutter test test/daily_choice_cooking_guide_test.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_eat_library_store_test.dart`（通过）
- `flutter test test/daily_choice_hub_smoke_test.dart`（通过）
- `.\scripts\build.ps1 -Target android-apk -NoPubGet`（通过，产物输出到 `dist/android-apk/xianyushengxi.apk`）

## [Unreleased-PLAN_067-EAT-FREEZE-BUILD] - 2026-04-26

### 原因
- 用户反馈工具箱「每日抉择 - 吃什么」进入页面接近卡死，管理页轻量折叠交互也会明显卡顿。
- 用户反馈新增菜谱时 `DropdownButtonFormField` 因 `all` 上下文重复和值冲突直接断言报错。
- 用户反馈通过 `.\scripts\build.ps1` release 打包时 Gradle 在 Flutter plugin loader 阶段因仓库策略冲突失败。

### 修改
- `DailyChoiceEditorSheet` 内部统一对分类 / 上下文候选去重，并在编辑态剔除 `all` 这类筛选哨兵项，避免不同入口传入重复上下文时触发下拉断言。
- 吃什么主页面在只变更食谱集数据且当前未选中食谱集时，不再重算当前随机池，减少管理页集合操作对底层页面的同步压力。
- `scripts/build.ps1` 在 Android 构建阶段使用项目内隔离的 `GRADLE_USER_HOME`，避免读取用户全局 `~/.gradle/init.gradle` 后向 Flutter included build 注入项目级 Maven 仓库。
- Android Gradle 配置移除 settings / project 两层自定义 Maven 镜像与全局 library `BuildConfig` 默认开关，分别修复 settings 仓库策略冲突和 `sherpa_onnx` 多 ABI 子包 release R8 重复类问题。

### 修复
- 修复新增 / 调整 / 另存吃什么菜谱时上下文初始值为 `all` 或上下文列表包含重复 `all` 导致的 `DropdownButton` 崩溃。
- 修复管理页在非必要场景下因食谱集状态变化牵动吃什么随机池重算的性能浪费。
- 修复 `.\scripts\build.ps1 -Target android-apk` 的 Android release APK 构建链路。

### 风险变更
- Android 构建脚本会在 `android/.gradle-user-home/` 下建立项目本地 Gradle 用户目录，首次构建需要重新下载 Gradle / AGP 依赖；该目录已加入 `.gitignore`。
- 移除全局 library `BuildConfig` 默认开关后，依赖库回到 AGP 默认行为；如果未来某个旧 Android library 源码直接引用自身 `BuildConfig`，需要该库自行开启 `buildFeatures.buildConfig`。
- 本机 Android SDK 的 `ndk;28.2.13676358` 曾处于半安装状态，本轮已通过 sdkmanager 重新安装；这是构建环境修复，不属于仓库源码变更。

### 验证
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart test/daily_choice_hub_smoke_test.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice test/daily_choice_hub_smoke_test.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart`（通过）
- `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart --reporter compact`（通过）
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `.\scripts\build.ps1 -Target android-apk -NoPubGet`（通过，产物输出到 `dist/android-apk/xianyushengxi.apk`）

## [Unreleased-PLAN_066-EAT-PERFORMANCE-SETS] - 2026-04-26

### 原因
- 用户反馈工具箱「每日抉择 - 吃什么」首屏展示臃肿，「先让选择动起来」和常驻菜谱库说明缺乏实际价值。
- 用户反馈「已有材料优先匹配」存在失效场景，连续食材短语无法稳定拆出多个可匹配 token。
- 用户反馈点击管理页会卡死，需要针对 7000+ 菜谱规模设计更极致的性能路径。
- 用户需要可自定义的食谱方案：把菜谱加入个人集合，并能在集合内筛选、随机、管理。
- 用户需要内置菜谱支持覆盖式个人调整，也支持另存为独立个人菜谱。

### 新增
- `DailyChoiceEatCollection` 与 `DailyChoiceCustomState.eatCollections`，支持本地持久化吃什么专属食谱集。
- 食谱集操作能力：创建集合、删除集合、加入菜谱、移出菜谱、删除自定义菜时自动从集合中清理。
- 吃什么主页面新增食谱集筛选入口；选择集合后，随机池和高级筛选只在当前集合内工作。
- 管理页新增「我的食谱集」区域，可创建集合、按集合只看、删除集合，并从内置 / 调整 / 自定义菜谱卡片加入或移出集合。
- 内置菜和个人调整新增「另存」动作，可把菜谱复制成独立个人食谱继续编辑。
- 新增 `test/daily_choice_custom_state_test.dart`，覆盖食谱集序列化和删除自定义菜时的集合清理。

### 修改
- 每日抉择页移除首屏大卡片「先让选择动起来」，让模块切换与当前工具内容更快进入首屏。
- 吃什么页面不再常驻展示菜谱库说明卡；仅在未安装、加载中或异常时显示资源准备状态。
- 吃什么页面顺序调整为餐段 / 厨具 / 食谱集 -> 随机主舞台 -> 高级筛选，减少进入页面后的视觉负担。
- 管理页内置菜谱列表改为分页展示，默认只构建首批条目，继续加载时再追加下一页，避免打开管理页一次性构建全量卡片。
- 管理页搜索、餐段、厨具、标签和集合筛选变更时会重置分页窗口，搜索仍覆盖完整菜谱库。
- 食材归一化增强为可从「番茄鸡蛋豆腐汤」这类连续短语中提取多个规范 token，并对 `豆腐 / 牛奶 / 鸡蛋` 等重叠别名采用更具体项优先，避免匹配分数虚高。

### 修复
- 修复已有材料优先匹配在紧凑输入或紧凑菜名中只命中第一个食材的问题。
- 修复管理页打开时因一次性构建数千个内置菜谱卡片导致卡死的核心瓶颈。

### 风险变更
- 食材短语拆词会让部分菜谱获得更完整的食材 token，随机池相关性会提升，但个别泛化标签命中范围也可能变化。
- 食谱集当前仍保存在本机 `toolbox_daily_choice_v1.json`，尚未接入账号同步、备份导入导出或云端多端合并。
- 管理页分页仅限制 UI 构建数量，搜索和筛选仍基于本地摘要全集；若未来菜谱量继续扩大到数十万级，应进一步把管理搜索迁移到 SQLite 索引查询。

### 验证
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_catalog.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_catalog.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart`（通过）
- `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart --reporter compact`（通过）
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`（通过）

## [Unreleased-PLAN_065-EAT-S3] - 2026-04-25

### 原因
- 用户要求将“吃什么”菜谱库切换到远端 S3 `/cook_data` 资源，移除安装包内本地菜谱资源，避免继续增大包体并拖慢移动端首开。
- 用户希望页面顶部进一步收口，只保留总条数与当前筛选池条数，并支持折叠。
- 用户要求管理页在“不喜欢”之外新增“个人调整”能力，允许基于内置菜谱保存个人口味版本，并要求管理界面更适合手机端折叠浏览。

### 新增
- `DailyChoiceCustomState` 新增 `adjustedBuiltInOptions` 持久化字段，支持保存内置菜谱的个人调整版本，并提供 `upsertAdjustedBuiltIn / restoreAdjustedBuiltIn / adjustedBuiltInById` 操作。
- `daily_choice_manager_sheet.dart` 为吃什么新增“我的调整”分区，支持继续调整、恢复原味，并把内置菜与个人调整统一纳入可搜索、可点击查看详情的移动端折叠管理界面。

### 修改
- `daily_choice_eat_library_store.dart` 接入 S3 远端库主链路，首次点击时优先下载 `cook_data/daily_choice_recipe_library.db` 到应用支持目录，本地保留标准 SQLite `summary / detail / index / meta` 表结构并复用既有 S3 兼容客户端。
- `daily_choice_eat_library_store.dart` 安装成功后会清理旧的 `toolbox_daily_choice_recipe_library.json` 和 `toolbox_daily_choice_cook_recipe.csv` 遗留缓存；若远端安装失败且本地已有库，则继续回退使用已有库。
- `daily_choice_hub.dart` 与 `daily_choice_eat_module.dart` 改为同时保留“原始内置菜谱”和“应用个人调整后的内置菜谱”，确保管理页可以正确执行“恢复原味”，并避免把调整后的快照错误当作原始基线。
- `daily_choice_eat_module.dart` 清理遗留旧状态卡代码，页面顶部菜谱库信息卡收口为折叠式紧凑卡片，只保留：
  - 总库条数
  - 当前筛选池条数
  - 加载 / 错误状态
- `daily_choice_manager_sheet.dart` 重构为更适合手机端的折叠结构：
  - 搜索保持常驻
  - 筛选条件折叠
  - 我的自定义 / 我的调整 / 内置条目折叠
  - 内置菜支持“个人调整 / 恢复原味 / 不喜欢”
- `test/daily_choice_eat_library_store_test.dart` 改为覆盖远端 SQLite 安装链路，不再依赖网络下载或 bundled 资源。
- `test/daily_choice_hub_smoke_test.dart` 同步验证 S3 风格加载按钮文案、管理页个人调整入口，以及“恢复原味”动作在交互层的可达性。
- 吃什么菜谱 asset 已从应用打包配置中移除，不再继续随安装包携带 `assets/toolbox/daily_choice/recipe_library.json`。

### 风险变更
- 当前远端安装仍保留“已有本地库优先继续可用”的兜底策略，但首次安装若 S3 访问失败，用户仍需要稍后重试才能拿到完整菜谱库。
- `daily_choice_cook_service.dart` 中的 bundled 解析路径暂未完全删除，只作为兼容兜底逻辑保留；运行时主路径已经切到 S3 本地缓存库。
- 本轮未完成仓库全量 `dart analyze`：当前桌面环境启动分析服务时遭遇 `dartaotruntime.exe` 拒绝访问，需要后续在本机权限环境下补跑。

### 验证
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart test/daily_choice_eat_library_store_test.dart test/daily_choice_hub_smoke_test.dart`（通过）
- `flutter test test/daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`（通过）

## [Unreleased-PLAN_064-EAT] - 2026-04-25

### 原因
- 用户继续要求完善工具箱“每日抉择”中的“吃什么”子模块，并明确指出当前菜谱量级远远不够，需要接入更大的本地菜谱库。
- 需要把 `D:\vocabularySleep-resources\做菜` 中可稳定抽取的完整菜谱去重后接入页面，同时补齐已有材料优先、高级筛选、管理搜索、指南整合和个人食谱能力。
- 用户额外要求对古籍资料保持克制：只有在识别质量可靠时才单独接入“食疗与禁忌”子页，不能为了覆盖率强行识别。
- 用户在继续体验时反馈“吃什么”页面首开非常卡、已有材料优先几乎只剩一种，要求把性能、匹配算法、多食材编辑和自定义忌口一起收口到可用状态。

### 新增
- 新增离线抽取脚本 `scripts/generate_daily_choice_recipe_dataset.py`，用于从 `D:\vocabularySleep-resources\做菜` 提取完整菜谱并生成项目内结构化数据集。
- 新增打包资源 `assets/toolbox/daily_choice/recipe_library.json`，当前包含 `7179` 条去重后的本地菜谱，并附带统一参考书目元数据。
- 新增本地导出目录 `D:\vocabularySleep-resources\cook_data`，同步生成：
  - `daily_choice_recipe_library.json`
  - `daily_choice_recipe_library_summary.json`
  - `daily_choice_recipe_library.db`
- 新增 `daily_choice_eat_library_store.dart`，将 bundled / cached / remote 菜谱资源整理导入独立 SQLite，本地维护 `summary / detail / index / meta` 四类标准表与筛选索引。
- 数据整理脚本新增多解析器管线，补齐 `The Italian Pantry`、`Nourishing Recipes for Elderly`、`食趣：欧文的无国界创意厨房` 等新版式 EPUB 的完整菜谱提取，并对低质量古籍 / 扫描资料保持跳过策略。
- 新增标准化菜谱库顶层字段：`libraryId / libraryVersion / schemaId / schemaVersion`，为后续远端分发或 S3 托管保留统一对象格式。
- `daily_choice_eat_support.dart` 为吃什么新增结构化属性支持：
  - `meal / type / profile / diet / contains / ingredient / tool`
  - 食材归一化与多来源属性补齐
  - 已有材料匹配计数、匹配比例和最优候选收口
  - 多来源菜谱合并去重
- 新增 `daily_choice_eat_module.dart`，收拢吃什么专用页面结构、高级设置区和指南入口。
- 扩充 `buildCookingGuideModules(...)`，新增“基础技能”“食材匹配与筛选说明”“参考书目”三个指南模块。
- 扩充 `test/daily_choice_cook_service_test.dart`，覆盖：
  - `cook` CSV 解析后的餐段/厨具映射
  - 午餐/晚餐重叠行为
  - bundled 菜谱库重复读取时的实例内解析缓存
  - 多来源菜谱合并去重
- 新增 `test/daily_choice_eat_catalog_test.dart` 与 `test/daily_choice_hub_smoke_test.dart`，分别覆盖高级筛选/多食材随机池策略，以及页面进入、展开高级设置、添加食材 chip、添加自定义忌口并完成随机停止的烟雾链路。

### 修改
- `pubspec.yaml` 接入 `assets/toolbox/daily_choice/` 资源目录，保证离线菜谱库随应用打包。
- `daily_choice_cook_service.dart` 改为按“本地库 -> 本地缓存 -> 远端刷新 -> 兜底种子”顺序加载，并在本地库与 `cook` 数据之间做结构化合并去重。
- `daily_choice_cook_service.dart` 为 bundled 大菜谱库增加跨实例解析缓存、`12h` 远端刷新 TTL，并避免在没有缓存文件时无意义读取整份大 bundle。
- `daily_choice_hub.dart` 将吃什么初始化流程改为并发加载自定义状态和菜谱数据，并确保吃什么候选在进入页面前统一补齐结构化属性；首次进入若尚未安装菜谱库，则明确提示用户点击导入本地 SQLite。
- `daily_choice_hub.dart` 在页面层只持有一次当前可见菜谱索引，进入页面和切换筛选时不再反复对 6000+ 菜谱做全量属性推断与扫描。
- `daily_choice_eat_catalog.dart` 新增预建索引过滤路径，稳定支持多餐段重叠、厨具筛选、荤素/友好标签、常见忌口、自定义忌口和多食材优先匹配。
- `daily_choice_eat_support.dart` 将“已有材料优先”改为 `exact -> strong -> broad` 三阶段随机池策略，并在命中太少时自动补入高相关候选，避免随机结果长期只剩 1 道菜。
- `daily_choice_seed_data.dart` 把做菜指南升级为统一参考书目版本，整合 `cook` “做菜之前”与本地基础技能，并补充“洗菜去残留”和“烘焙先称量”两条底层操作指南；《食物辑要》继续明确标记为暂不接入。
- `daily_choice_manager_sheet.dart` 为吃什么新增菜名搜索、餐段重叠筛选、厨具筛选和标签筛选。
- `daily_choice_eat_module.dart` 的高级设置改为支持多食材添加/删除、多自定义忌口 chip 编辑，并补齐香菜、花生、牛奶、鱼腥草等常见调料/食材忌口入口。
- `daily_choice_editor_sheet.dart` 为个人食谱保存逻辑补齐自动 attributes 推断、标签补齐和默认详情兜底。
- `daily_choice_detail_sheets.dart` 对吃什么详情页隐藏逐条来源说明，改为展示结构化标签摘要、完整步骤与关键提示；管理页点击菜名时同样按菜谱 ID 读取完整详情。
- `daily_choice_modules.dart` 清理旧的吃什么实现，仅保留 `go / activity` 公共模块，避免旧逻辑继续与新吃什么页面并存。
- `modules/toolbox/README.md` 同步记录吃什么离线大库、筛选能力、指南整合和古籍跳过边界。

### 风险变更
- 清真友好、素食友好、常见忌口与过敏原筛选均属于启发式辅助标签，不等价于宗教、医学或专业营养认证。
- 本地菜谱库体量已提升到约 `26.7 MB` JSON / `47.4 MB` SQLite 导出；当前通过预建索引、延后远端刷新、缓存复用与筛选收口控制首屏压力，后续若继续扩库，优先建议走 `summary manifest + detail/SQLite` 远端按需加载。
- 《食物辑要》属于竖排古体资料，本轮明确不强行接入“食疗与禁忌”子页，后续只在识别质量稳定时再单独落地。
- 自定义个人食谱与隐藏内置项仍保存在本地 `toolbox_daily_choice_v1.json`，当前不接入账号同步或跨端备份。

### 验证
- `python scripts\\generate_daily_choice_recipe_dataset.py`（通过，重新生成 `7179` 条去重菜谱，原始抽取 `7364` 条，并同步导出 full JSON / summary JSON / SQLite）
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_catalog.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_support.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_recipe_library.dart test/daily_choice_cook_service_test.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_hub_smoke_test.dart test/daily_choice_recipe_library_test.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice test`（通过；仍有全仓无关 `info`，不是本轮引入）
- `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`（通过）
- `flutter test test/daily_choice_eat_library_store_test.dart --reporter compact`（通过）
- `flutter test test/daily_choice_recipe_library_test.dart --reporter compact`（通过）

## [Unreleased-PLAN_061-WEAR-2] - 2026-04-25

### 原因
- 用户继续要求专注工具箱“每日抉择”中的“穿什么”子模块，并指出当前数据量仍不足以支撑更细的筛选与管理需求。
- 需要基于新增的本地穿搭参考资料继续扩充搭配库、把穿搭指南讲得更完整，并将个人衣橱管理升级为带有风格与样式引导的一版。

### 新增
- 为 `DailyChoiceOption` 新增结构化 `attributes` 字段，用于承载穿搭特征并持久化到 `toolbox_daily_choice_v1.json`。
- 在 `daily_choice_seed_data.dart` 中新增穿什么的结构化特征定义：
  - `风格`
  - `版型`
  - `样式类型`
  - `面料与触感`
  - `亮点`
- 新增模块化穿搭指南 `wearGuideModules`，按以下 8 个章节组织：
  - `基础与风格`
  - `版型与比例`
  - `场合与职场`
  - `色彩与材质`
  - `季节与天气`
  - `鞋履与配饰`
  - `衣橱整理与练习`
  - `扩展边界`
- 新增 `test/daily_choice_wear_seed_test.dart`，验证：
  - 穿什么条目总量达到发布级覆盖
  - 每个 `气温 × 场景` 组合至少有两条候选
  - 每条内置搭配都具备核心结构化特征

### 修改
- `daily_choice_wear_seed.dart`
  - 将穿什么内置搭配扩充到 `87` 条
  - 为原有与新增搭配补齐自动推断的结构化特征
  - 将穿搭参考来源扩展到更多本地资料，包括 `上班穿什么`、`搭配其实很好玩2`、`风格的练习`、`穿衣的基本`、`绅士时尚` 等
- `daily_choice_editor_sheet.dart`
  - 自定义穿搭编辑页新增五组引导式 trait 选择
  - 穿搭字段文案升级为更贴合衣橱管理的表达
  - 保存时会自动把结构化特征并入标签与默认详情
- `daily_choice_manager_sheet.dart`
  - 穿什么管理页新增 `风格 / 版型 / 样式类型` 三组筛选
  - 自定义和内置条目卡片改为显示结构化特征 chip
  - 衣橱管理文案升级为更明确的个人衣橱语义
- `daily_choice_detail_sheets.dart` 为穿什么详情补充“风格画像”模块，展示结构化特征摘要。
- `daily_choice_wear_module.dart` 的指南入口改为拉起新的模块化穿搭指南。
- `daily_choice_modules.dart` 做最小必要编译修补：为吃什么数据来源状态补齐 `bundle` 分支，避免 UI smoke 失败。
- `PROJECT_DOMAIN.md` 与 `modules/toolbox/README.md` 同步补充穿什么的结构化衣橱能力、87 条候选覆盖和详细指南说明。

### 风险变更
- 穿什么仍提供的是可解释、可编辑的建议层，不替代个体体质差异、制服要求、极端天气安全判断或专业形象顾问。
- 结构化特征目前用于本地筛选、展示和后续扩展边界，不代表已经接入图片识别、AI 试穿或购物平台。
- 本轮未改动其他每日抉择子模块的业务逻辑，只做了一个与吃什么编译通过相关的最小分支补齐。

### 验证
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_seed.dart test/daily_choice_wear_seed_test.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_seed.dart test/daily_choice_wear_seed_test.dart`（通过，No issues found）
- `flutter test test/daily_choice_wear_seed_test.dart --reporter compact`（通过，All tests passed）
- `flutter test test/ui_smoke_test.dart --reporter compact`（通过，All tests passed）
- `git diff --check -- lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_seed.dart test/daily_choice_wear_seed_test.dart`（通过）

## [Unreleased-PLAN_062-GO] - 2026-04-25

### 原因
- 用户要求只推进工具箱“每日抉择”中的“到哪儿去”子模块，并将其从占位级随机地点升级到可发布落地的一版。
- 当前“去哪儿”只有极少量静态地点，缺少足够丰富的场景分类、地点覆盖、详情说明和可持续扩展边界。

### 新增
- 新增 `daily_choice_place_seed.dart`，将“去哪儿”地点种子从活动数据中独立拆出，避免 `go` 与 `activity` 继续耦合在同一份 seed 内。
- 新增 15 个“去哪儿”场景分类：
  - `饮食 / 娱乐 / 运动 / 文化 / 历史 / 自然 / 学习 / 购物 / 社交 / 亲子 / 夜生活 / 放松 / 出片 / 特色区域 / 纪念`
- 基于 `3 个距离层级 × 15 个场景 × 8 个 archetype` 生成 360 条“去哪儿”内置地点条目，覆盖：
  - 公园、绿道、湿地、山林步道、观景台
  - 体育中心、健身房、游泳馆、球馆、攀岩馆
  - 餐馆、咖啡甜品店、小吃街、夜宵区、景观餐厅
  - 酒吧、精酿吧、Livehouse、KTV、网吧 / 电竞馆
  - 博物馆、美术馆、科技馆、剧院、图书馆、书店
  - 老街区、古镇、工业遗址、纪念馆、校史馆、城市记忆馆等
- 新增结构化“出行指南”模块组，按“先定范围 / 按场景匹配 / 地图与检索 / 天气预算安全 / 最小准备包 / 后续扩展边界”展示。
- 新增 `test/daily_choice_place_seed_test.dart`，验证“去哪儿”条目数量、分类覆盖、地图搜索词与引用字段完整性。

### 修改
- `daily_choice_seed_data.dart` 为“去哪儿”补齐 `placeSceneCategories` 与 `allPlaceSceneCategory`，并将原本简陋的出行指南升级为模块化指南。
- `daily_choice_modules.dart` 中的“去哪儿”页面改为：
  - 距离 + 场景双维筛选
  - 当前距离层级地点数 / 当前候选数 / 覆盖场景数状态面板
  - 更清晰的空状态和移动端首屏信息
  - 管理页支持按距离和场景筛选自定义地点
- `daily_choice_detail_sheets.dart` 对“去哪儿”详情页补齐地图搜索词提取逻辑，复制按钮优先复制结构化地图检索词，而不再机械复制标题。
- `daily_choice_activity_place_seed.dart` 移除旧的“去哪儿”占位数据，仅保留“干什么”相关 seed。
- `modules/toolbox/README.md` 补充“去哪儿”子模块的双维筛选、360 条地点覆盖和地图扩展边界说明。

### 风险变更
- 当前“去哪儿”仍属于结构化地点建议与搜索词辅助，不接入真实定位、系统地图拉起和在线 POI 动态检索。
- 内置地点数据是按常见场所 archetype 生成的通用候选，不代表真实营业状态、实时评分或实时开放信息；出发前仍需看地图和营业时间。
- 粗略定位、开放地理数据、系统地图与路线规划仍保留为后续独立扩展，不在本轮混入权限与平台差异处理。

### 验证
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_activity_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart test/daily_choice_place_seed_test.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_activity_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart test/daily_choice_place_seed_test.dart`（通过，No issues found）
- `flutter test test/daily_choice_place_seed_test.dart --reporter compact`（通过，All tests passed）
- `git diff --check -- lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_activity_place_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart test/daily_choice_place_seed_test.dart plans/PLAN_062_每日抉择去哪儿子模块发布级完善.md`（通过）

## [Unreleased-PLAN_062] - 2026-04-25

### 原因
- 用户要求专注完善 `工具箱 -> 每日决策 -> 决策助手` 子模块，基于本地 `D:\vocabularySleep-resources\决策` 资料，把原先的轻量占位计算器升级为可发布的理性决策辅助工作台。
- 需要补齐一套实用且科学的决策策略体系，同时增加一个提取整理后的“理性决策精要指南”拉起页，并且不侵入其他并行开发中的每日抉择子模块。

### 新增
- 新增 `daily_choice_decision_engine.dart`：
  - 抽离决策助手的核心计算层
  - 提供 `均匀随机 / 加权因素 / 期望收益 / 联合概率 / 情景分析 / 后悔与机会成本 / 底线守门 / 校准预测` 八类策略
  - 增加跨策略共识、信息价值信号与守门线配置
- 新增 `daily_choice_decision_content.dart`：
  - 定义各决策策略的说明、公式与使用边界
  - 增加模块化的 `理性决策精要指南`
  - 根据当前决策情境生成“决策卫生检查”条目
- 新增测试 `test/daily_choice_decision_engine_test.dart`，覆盖：
  - 高风险高不确定情境下的方法推荐
  - 底线守门优先保护风险下限
  - 校准预测会把低把握极端值拉回均值
  - 信息价值高时建议延后决策并优先补信息
- 新增资料整理记录 `records/record_062_决策参考资料整理与产品映射.md`
- 新增计划文档 `plans/PLAN_062_每日决策决策助手完善.md`

### 修改
- 重写 `daily_choice_decision_assistant.dart`，将原来的单页轻量排序器升级为完整工作台：
  - 新增“风险级别 / 不确定性 / 全局可回头性 / 时间压力”决策情境分型
  - 新增推荐镜头提示、方法切换与透明结果面板
  - 新增跨策略共识、守门线通过数、信息价值提示
  - 扩充每个选项的输入维度为：成功概率、执行概率、收益、风险、投入、可回退、把握、后悔、信息差
  - 增加“决策卫生检查”区，帮助用户在最终拍板前做偏差与噪声校正
- `daily_choice_hub.dart` 接入新的决策内容层与引擎层。
- `daily_choice_modules.dart` 做最小必要编译修补：`去哪儿` 子模块的指南入口从旧的 `placeGuideEntries` 对齐到现有 `placeGuideModules`，不改变其业务语义。

### 风险变更
- 当前决策助手提供的是“结构化辅助决策”，不是医疗、法律、财务等高风险专业判断的替代品。
- 情景分析、后悔权衡与加权因素依旧属于解释型模型，核心价值是帮助用户显式化假设、排序因素和收口行动，而不是制造虚假的确定性。
- 本轮没有接入历史决策日志，因此“校准预测”是基于当前选项集合的均值回拉，不是基于长期样本训练出的真实回归模型。

### 验证
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_engine.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_content.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_assistant.dart test/daily_choice_decision_engine_test.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_engine.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_content.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_decision_assistant.dart test/daily_choice_decision_engine_test.dart`（通过，No issues found）
- `flutter test test/daily_choice_decision_engine_test.dart --reporter compact`（通过，All tests passed）
- `flutter test test/ui_smoke_test.dart --reporter compact`（通过，All tests passed）

## [Unreleased-PLAN_061] - 2026-04-25

### 原因
- 用户要求重点完善工具箱“每日抉择”中的“吃什么”子模块，不再停留在精简离线种子，而是接入 YunYouJun/cook 数据并把随机、详情、做菜指南和个人食谱管理做成可实际使用的一版。
- 页面需要在移动端保持首屏清晰，同时支持“点击厨具图标后随机显示菜品、停止后锁定当前结果、点击菜品查看完整介绍和制作方法”的完整链路。

### 新增
- 新增 `daily_choice_cook_service.dart`：
  - 远端读取 `https://raw.githubusercontent.com/YunYouJun/cook/main/app/data/recipe.csv`
  - 解析 CSV 为吃什么专用条目
  - 将 cook 数据写入应用支持目录缓存
  - 远端失败时自动回退到缓存，再失败时回退到内置吃什么种子
- 新增吃什么模块的厨具图标筛选：`全部厨具 / 一口大锅 / 电饭煲 / 微波炉 / 空气炸锅 / 烤箱`。
- 新增结构化“做菜之前”指南卡组，按“盘点食材、筛字段、备菜、火候调味、保存与安全、长期规划”六个模块展示详细说明。
- 新增吃什么解析层测试 `test/daily_choice_cook_service_test.dart`，覆盖 cook CSV 到菜品条目的餐段/厨具映射和引用生成。

### 修改
- `DailyDecisionToolPage` 修复中文标题和副标题乱码。
- 吃什么模块改为：
  - 默认使用现有内置菜谱兜底，后台同步 cook 数据后平滑替换
  - 按餐段和厨具筛选当前候选，再进入“开始随机 / 停止并选中”主舞台
  - 页面展示当前数据来源状态、候选数量、同步时间和同步失败回退提示
- 菜品详情弹层升级为显示：
  - 结构化详细介绍
  - 更完整的食材清单
  - 更完整的制作步骤
  - 关键提示
  - cook 数据源 / B 站教程等参考链接与复制操作
- 自定义管理升级为按当前分类与上下文筛选，避免全量 cook 数据接入后管理页过载。
- 自定义编辑表单针对吃什么补齐更适合个人食谱的字段：餐段、厨具、菜名、介绍、食材、步骤、技巧备注和标签。
- `modules/toolbox/README.md` 补充吃什么的数据读取、缓存策略和升级后的能力边界。

### 风险变更
- cook 官方 `recipe.csv` 只提供菜名、食材、难度、标签、做法和厨具，不提供逐字逐步原文菜谱；本页详情中的“完整详细做法”属于基于元数据的结构化扩写，并保留原始来源链接。
- 当前 `PROJECT_DOMAIN.md` 工作树里仍存在编码异常，本轮未扩大对该文档的修改范围，避免把乱码问题和功能改动混在一起。
- 自定义个人食谱仍保存在 `toolbox_daily_choice_v1.json`，暂不接入主数据库、账号同步或导入导出。

### 验证
- `dart format lib/src/ui/pages/toolbox_daily_choice_tool.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_detail_sheets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_manager_sheet.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_editor_sheet.dart test/daily_choice_cook_service_test.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice_tool.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_cook_service.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart test/daily_choice_cook_service_test.dart`（通过，No issues found）
- `flutter test test/daily_choice_cook_service_test.dart --reporter compact`（通过，All tests passed）

## [Unreleased-PLAN_061-WEAR] - 2026-04-25

### 原因
- 用户要求只推进工具箱“每日抉择”中的“穿什么”子模块，不影响其他并行开发中的子模块。
- 当前穿什么仍偏占位，缺少资料整理、天气驱动默认推荐和足够丰富的可发布级穿搭数据。

### 新增
- 新增 `daily_choice_wear_module.dart`，收拢穿什么的天气建议、默认档位和场景快捷逻辑。
- 基于 `D:\\vocabularySleep-resources\\穿什么` 中的本地 EPUB 资料整理出穿搭原则，并补充到穿搭指南卡组。
- 扩充穿什么种子数据，覆盖严寒到酷暑、通勤到雨天的 50+ 套基础穿搭条目。

### 修改
- `DailyChoiceHub` 接入当前天气状态，并只向穿什么子模块传递天气数据。
- 穿什么默认根据 `AppState.weatherSnapshot` 的体感温度自动选中建议档位，同时保留手动覆盖与“恢复天气推荐”入口。
- 当当前天气存在降水时，页面会给出“切到雨天场景”的快捷建议，但不会强制改写用户场景选择。
- 当某个温度 + 场景精确条目过少时，随机结果会自动混入同温度稳妥备选，避免随机体验僵死。
- `daily_choice_seed_data.dart` 的穿搭指南升级为“基础款优先、合身先于流行、场景先行、质胜于量、天气收尾检查”等更可执行的规则说明。
- `PROJECT_DOMAIN.md` 与 `modules/toolbox/README.md` 补充穿什么的资料来源、天气建议和发布边界说明。

### 风险变更
- 穿什么的内置搭配仍属于可解释建议，不替代个体体质差异、严格 dress code 或极端天气安全判断。
- 当前天气建议依赖已有天气接口与近似定位；天气不可用时会回退到默认档位并允许用户手动调整。
- AI 数字人试穿、衣橱识别与购物网站接入仍只保留扩展边界，不在本轮实现。

### 验证
- `dart format lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_seed.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice_tool.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_modules.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_module.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_wear_seed.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart`（通过，No issues found）
- `flutter test test/ui_smoke_test.dart --reporter compact`（通过，All tests passed）

## [Unreleased-PLAN_060] - 2026-04-24

### 原因
- 用户要求专注工具箱“每日抉择”模块，将当前占位子模块扩展为“吃什么、穿什么、去哪儿、干什么、决策助手”五个大子模块。
- 新模块需要移动端首屏清晰、支持随机选择、详情/指南、自定义增删改，并为 cook 数据、地图、AI 试穿、购物接入和数学建模预留扩展边界。

### 新增
- 每日抉择新增五模块基础版：
  - `吃什么`: 按早饭、午餐、晚餐、下午茶、宵夜随机菜品，详情显示材料、介绍、简化制作步骤和来源。
  - `穿什么`: 按严寒、寒冷、凉爽、温和、微热、炎热、酷暑与通勤、日常、正式、约会、运动、雨天场景随机搭配。
  - `去哪儿`: 按出门、周边、远行随机常见目的地，并可复制地图搜索词。
  - `干什么`: 按运动、学习、出行、整理、放松、创作、社交随机行动，也支持随机方向。
  - `决策助手`: 提供均匀随机、期望加权、因子评分和联合概率四类透明计算。
- 新增 `toolbox_daily_choice/` 子目录，拆分模型、种子数据、本地 JSON 存储、共享组件和页面编排。
- 新增本地自定义管理：可隐藏内置项，新增/编辑/删除自定义菜品、搭配、地点和行动。
- 新增吃什么、穿什么、去哪儿、干什么和决策助手的基础指南弹层。

### 修改
- `DailyDecisionToolPage` 从旧转盘占位改为五模块入口和统一轻量随机交互。
- `modules/toolbox/README.md` 补充每日抉择数据来源、存储边界、风险和后续扩展路线。
- `PROJECT_DOMAIN.md` 更新到 v0.0.7，补充每日抉择五模块基础版说明。

### 风险变更
- 吃什么第一版只使用参考 YunYouJun/cook `recipe.csv` 的离线种子子集，并使用本地简化步骤，不做远端实时同步。
- 本地 `D:\vocabularySleep-resources\穿什么` 中 EPUB 不摘录原文；穿搭数据使用通用原则和生成式种子数据。
- 自定义项存储在应用支持目录 JSON 文件中，暂不接入主数据库、账号同步或备份恢复。
- 决策助手仅用于辅助排序和透明计算，不作为医疗、法律、财务等高风险决策依据。

### 验证
- `dart format lib/src/ui/pages/toolbox_daily_choice_tool.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_storage.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_daily_choice_tool.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_models.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_seed_data.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_storage.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_widgets.dart lib/src/ui/pages/toolbox_daily_choice/daily_choice_hub.dart`（通过，No issues found）

## [Unreleased-PLAN_059] - 2026-04-24

### 原因
- 用户要求继续完成前面建议中的其他实用项，让睡眠助手在睡前、夜醒、醒来和跨工具放松之间形成更完整的低阻力路径。
- 这些功能应继续保持手机端压缩，不把首页重新拉长，也不绕过模块启停边界。

### 新增
- 睡眠首页新增“睡前一键场景”确认抽屉，一次确认后打开睡眠暗色模式并启动最低能量流程。
- 晨间三按钮快记新增推断提示，可展示最近夜醒记录、最低能量流程和晚间看屏线索，并保留“补详细日志”入口。
- 免输入场景启动面板新增夜醒分支 chip，可直接进入“完全清醒、思绪停不下来、身体太兴奋”等夜醒救援状态。
- 更多入口折叠区新增跨 toolbox 放松入口：呼吸训练、舒缓音乐、疗愈音钵和禅意沙盘。

### 修改
- `SleepNightRescuePage` 新增可选 `initialMode` 参数，用于从首页分支直接进入对应夜醒状态；既有启动、保存和结束逻辑不变。
- 睡前一键场景只自动处理睡眠暗色与最低能量流程，背景音和其他工具仍由用户主动选择，避免夜间误播放。
- 跨 toolbox 入口统一使用 `pushModuleRoute` 与目标 moduleId，保持模块关闭时的访问守卫。
- `modules/sleep/README.md` 补充本轮睡前一键场景、晨间推断、夜醒分支和跨工具联动说明。

### 风险变更
- 本轮不新增睡眠持久化字段，不改变夜醒事件、日志保存或流程执行状态机。
- 睡前一键场景会主动打开睡眠助手暗色模式；这是明确确认后的模块内偏好更新。
- 跨 toolbox 链接只提供入口，不接管其他工具的播放状态或偏好。

### 验证
- `dart format lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart lib/src/ui/pages/sleep_night_rescue_page.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart lib/src/ui/pages/sleep_night_rescue_page.dart`（通过，No issues found）
- `flutter test test/sleep_repository_test.dart --reporter compact`（通过，All tests passed）
- `git diff --check -- changelogs/CHANGELOG.md lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart lib/src/ui/pages/sleep_night_rescue_page.dart`（通过，仅提示 changelog 受本机 Git 换行设置影响）

## [Unreleased-PLAN_058] - 2026-04-24

### 原因
- 用户希望按照低意志力体验方案继续完善睡眠助手，重点解决睡眠不足、烦躁、容易中断习惯时的驱动力不足。
- 首页需要加入具有鼓励、抚慰和支持性的目标文案，但仍要保持手机端紧凑，不再堆长页面。

### 新增
- 新增 `sleep_low_effort_widgets.dart`，承载睡眠首页的低意志力组件：支持性目标提示、疲惫模式抽屉和晨间三按钮快记。
- 睡眠首页主舞台新增“今晚目标”提示条，文案强调不追求完美睡眠，只先完成一个小动作，降低自责和选择负担。
- 睡眠首页新增“更短版本 / 我现在很累”入口，拉起疲惫模式底部抽屉，直接提供调暗灯光、放远手机、停放担心三步，并保留 8 分钟流程、背景音和夜醒救援。
- 早晨时段新增“醒来只点一下”三按钮快记，可用“差不多 / 更差 / 更好”记录晨间精神、白天困倦和必要备注。

### 修改
- 将支持性文案收进主舞台内部提示条，而不是额外新增长卡片，减少手机端首屏长度增长。
- 免输入场景启动面板增加“我现在很累”高优先级按钮，让疲惫用户不必先理解四个场景按钮。
- 晨间快记复用 `SleepDailyLog` 和 `AppState.saveSleepDailyLog`，不新增仓库字段或持久化结构。
- `modules/sleep/README.md` 补充低意志力体验、疲惫模式抽屉和晨间三按钮快记说明。

### 风险变更
- 晨间快记会更新当天日志的晨间精神和白天困倦；已有睡眠时长、时间轴、环境因子等详细字段会保留。
- 疲惫模式抽屉只复用既有流程、白噪音和夜醒救援入口，不改变睡前流程状态机。
- 本轮继续将新交互限制在睡眠助手首页展示与轻量日志保存层，不新增医疗判断或诊断承诺。

### 验证
- `dart format lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart`（通过，No issues found）
- `flutter test test/sleep_repository_test.dart --reporter compact`（通过，All tests passed）
- `git diff --check -- changelogs/CHANGELOG.md lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_low_effort_widgets.dart`（通过，仅提示 changelog 受本机 Git 换行设置影响）

## [Unreleased-PLAN_057] - 2026-04-24

### 原因
- 用户反馈睡眠助手首页仍然偏长，需要在手机端用折叠抽屉、下拉和子页面压缩信息密度。
- 用户要求新增“科学睡眠”子模块，参考 `D:\vocabularySleep-resources\睡眠参考` 中的资料，提炼高度实用的精简手册。
- 睡眠暗色模式下首页上部提示文字仍可能呈黑色，影响可读性。

### 新增
- 新增 `SleepSciencePage` 科学睡眠页，作为睡眠助手子页面入口。
- 科学睡眠页新增一分钟原则、风险优先、白天锚点、睡前收口、夜醒处理、易误用规则和参考资料索引，全部使用折叠标题组织。
- 睡眠首页新增“快速定位”抽屉，可直接跳到当前主线、闭环路线、更多入口、直接建议、7 天趋势，或打开科学睡眠页。

### 修改
- 睡眠首页进一步压缩手机端长度：移除重复的“低能量快速开始”展开区，将更多入口与即时工具合并为折叠面板。
- 当前主线、睡眠闭环路线、更多入口、直接建议、近 7 天趋势均改为折叠式面板，首屏保留下一步、免输入场景启动、指标与定位入口。
- `sleepModuleTheme` 改为显式覆盖 headline/title/body/label 全部文字层级，修复暗色模式下顶部提示文字仍可能黑字不可见的问题。
- 睡眠首页打鼾风险提示卡改为独立组件，在暗色主题内部读取 `errorContainer/onErrorContainer` 并显式设置正文颜色，避免浅色背景配浅色文字。
- `modules/sleep/README.md` 补充移动端压缩首页和科学睡眠页能力说明。

### 风险变更
- 科学睡眠页是健康教育和行为辅助，不替代医疗诊断；风险信号仍单独提示专业评估。
- 本轮不改睡眠状态机、仓库持久化结构或流程执行语义。
- `plans/` 与 `modules/sleep/` 当前被 `.gitignore` 忽略，本轮文档仍按项目规范在本地更新。

### 验证
- `dart format lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_science_page.dart`（通过）
- `dart analyze lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_science_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/sleep_night_rescue_page.dart lib/src/ui/pages/sleep_day_rhythm_page.dart lib/src/ui/pages/sleep_report_page.dart lib/src/ui/pages/sleep_assessment_page.dart`（通过，No issues found）
- `dart analyze lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_science_page.dart`（补充验证通过，No issues found）
- `flutter test test/sleep_repository_test.dart --reporter compact`（通过）

## [Unreleased-PLAN_056] - 2026-04-24

### 原因
- 用户要求继续聚焦工具箱睡眠助手，修复睡眠暗色模式效果，并降低疲惫状态下的启动阻力。
- 当前睡眠助手已有评估、日志、今晚流程、夜醒救援、白天节律和周报，但首页仍需要更明确的场景化入口和闭环串联。

### 新增
- 睡眠首页新增“免输入场景启动”面板，提供“现在就睡、半夜醒了、放背景音、明早补记”四个低摩擦入口。
- 睡眠首页新增“睡眠闭环路线”，把评估、今晚流程、夜醒救援、白天节律、最小日志和周报复盘串成可点击路径。

### 修改
- 强化 `sleepModuleTheme` 暗色主题，覆盖 Scaffold、AppBar、Card、Chip、ListTile、输入框、按钮、BottomSheet、SnackBar 和 TimePicker 等常见组件。
- 将睡眠暗色主题扩展到睡眠评估、夜醒救援、白天节律、睡眠周报和流程编辑器，并补齐快速工具弹层与研究说明弹层的暗色主题。
- 睡眠图表在暗色模式下会提升 accent 对比，并根据亮暗环境调整折线点内部颜色。
- `modules/sleep/README.md` 记录本轮免输入入口、闭环路线，以及后续“零输入晨间补记、睡前一键场景、夜醒分支脚本、跨 toolbox 联动”等实用功能设计。

### 风险变更
- 本轮没有新增睡眠数据模型，也没有改变 `SleepRepository` 的持久化结构。
- 新场景入口仅复用既有路由、bottom sheet 与 `startSleepRoutine()`，不改变睡前流程状态机。
- `plans/` 与 `modules/sleep/` 当前被 `.gitignore` 忽略，本轮文档仍按项目规范在本地更新。

### 验证
- `dart format lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_chart_widgets.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_assessment_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_day_rhythm_page.dart lib/src/ui/pages/sleep_night_rescue_page.dart lib/src/ui/pages/sleep_report_page.dart lib/src/ui/pages/sleep_routine_editor_page.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart`（通过）
- `dart analyze lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_chart_widgets.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_assessment_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_day_rhythm_page.dart lib/src/ui/pages/sleep_night_rescue_page.dart lib/src/ui/pages/sleep_report_page.dart lib/src/ui/pages/sleep_routine_editor_page.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart`（通过，No issues found）
- `flutter test test/sleep_repository_test.dart --reporter compact`（通过）
- `git diff --check -- changelogs/CHANGELOG.md plans/PLAN_056_睡眠助手暗色模式与场景闭环精修.md modules/sleep/README.md lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_chart_widgets.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_assessment_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_day_rhythm_page.dart lib/src/ui/pages/sleep_night_rescue_page.dart lib/src/ui/pages/sleep_report_page.dart lib/src/ui/pages/sleep_routine_editor_page.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart`（通过，仅提示 changelog 受本机 Git 换行设置影响）

## [Unreleased-PLAN_055] - 2026-04-24

### 原因
- 用户反馈当前睡眠模块仍依赖大量人工输入，疲惫状态下启动阻力高。
- 模块内流程串联不足，今晚流程选中模板后缺少可勾选、可确认的进一步交互。
- 需要增加模块内睡眠暗色模式，并优先复用现有系统通知/闹钟联动能力。

### 新增
- 连续睡眠日志页新增“30 秒最小日志”预设，可一键填入常见睡眠时长、入睡潜伏期、夜醒、精神/困倦和压力负荷。
- 日志页数值字段新增常见选项 chips，备注新增常见标签，保留自定义输入。
- 今晚流程页新增步骤清单，当前步骤勾选后会直接推进到下一步。
- 睡眠首页新增“睡眠暗色模式”开关，并在睡眠首页、连续日志、今晚流程内局部应用暗色主题。
- 今晚流程页新增睡前提醒和起床闹钟入口，复用现有待办提醒与系统日历/闹钟字段。

### 修改
- `SleepDashboardState` 增加 `sleepDarkModeEnabled` 持久化字段，旧数据默认关闭。
- 睡眠仓库测试增加 dashboard 暗色模式持久化断言。

### 风险变更
- 快速填充只在用户点击预设或 chips 时生效，不自动覆盖输入。
- 步骤清单只复用既有 `advanceSleepRoutine()` 推进当前步骤，不新增独立流程状态机。
- 系统提醒联动依赖既有待办提醒和平台能力，不新增新的平台插件。

### 验证
- `dart format lib/src/models/sleep_plan.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_wind_down_page.dart test/sleep_repository_test.dart`（通过）
- `dart analyze lib/src/models/sleep_plan.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart lib/src/ui/pages/sleep_daily_log_page.dart lib/src/ui/pages/sleep_wind_down_page.dart test/sleep_repository_test.dart`（通过，No issues found）
- `flutter test test/sleep_repository_test.dart --reporter compact`（通过）

## [Unreleased-PLAN_054] - 2026-04-24

### 原因
- 进入睡眠连续日志页时，`SleepDailyLogPage.initState()` 同步调用 `_loadDate()`，而 `_loadDate()` 会更新 `AppState.sleepDashboardState` 并触发 provider 通知。
- Riverpod 不允许在 widget tree 构建/挂载期间修改 provider，因此报错 “Tried to modify a provider while the widget tree was building”。

### 修复
- 将睡眠日志页的日期字段加载与 dashboard 选中日期同步拆开。
- 初始化时先加载页面本地表单字段，首帧结束后再同步 `selectedLogDateKey`。
- 用户通过日期选择器切换日志日期时仍保持即时同步 dashboard 状态。

### 风险变更
- 首帧期间 dashboard 的选中日期可能短暂保持旧值，但页面本地日期和表单字段立即可用；首帧后会补齐同步。
- 本轮只调整睡眠日志页初始化通知时机，不改变日志保存、字段含义、仓库持久化或首页推荐逻辑。

### 验证
- `dart format lib/src/ui/pages/sleep_daily_log_page.dart`（通过）
- `dart analyze lib/src/ui/pages/sleep_daily_log_page.dart`（通过，No issues found）
- `flutter test test/sleep_repository_test.dart --reporter compact`（通过）
- `git diff --check -- changelogs/CHANGELOG.md lib/src/ui/pages/sleep_daily_log_page.dart`（通过，仅提示 changelog 受本机 Git 换行设置影响）

## [Unreleased-PLAN_053] - 2026-04-24

### 原因
- 用户要求继续推进 toolbox 睡眠助手模块，将当前半完成示例扩展为完整、实用、科学且低启动成本的睡眠辅助闭环。
- 本轮参考 `D:\vocabularySleep-resources\睡眠参考` 中的 CBT-I、睡眠日志、R90/90 分钟周期、晨光节律、咖啡因、夜醒和睡眠医学风险边界资料，将其产品化为可直接执行的工具。

### 新增
- 新增睡眠助手首页“当前一步”主舞台，根据当前时间、评估、日志、晨光、咖啡因和流程运行状态推荐最值得做的一步。
- 新增“低能量快速开始”工具区，集中睡前、夜醒、晨光、咖啡因和 90 分钟周期入口。
- 新增 8 分钟内置 `minimum_energy_shutdown` 最低能量睡前流程，并在首页一键选中和启动。
- 新增 90 分钟睡眠周期规划器，支持反推今晚关灯时间与“现在就睡”的参考醒来时间。
- 新增睡眠日志/睡眠效率、90 分钟周期/R90 两类研究说明，并接入最小日志优先建议。

### 修改
- 读取睡前流程模板时会合并缺失的内置默认模板，让已有用户也能获得新增最低能量流程。
- 睡前流程页对内置模板和新增步骤增加本地化显示名，降低中文界面中的英文流程名暴露。
- 模块文档补充当前睡眠闭环能力、实用边界和更新历史。

### 风险变更
- 睡眠建议继续保持行为辅助、记录和风险提示定位，不替代医疗诊断；打鼾、憋醒和严重白天嗜睡等仍只提示进一步评估。
- 90 分钟周期工具仅作为规划辅助，文案避免暗示必须精确卡点。
- 本轮复用既有 `AppState`、`SleepRepository`、页面路由和模块开关，不新增独立强侵入式状态机。

### 验证
- `dart format lib/src/models/sleep_routine_template.dart lib/src/state/app_state_sleep.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_quick_tools_sheets.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart test/sleep_repository_test.dart`（通过）
- `dart analyze lib/src/models/sleep_routine_template.dart lib/src/state/app_state_sleep.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_quick_tools_sheets.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart test/sleep_repository_test.dart`（通过，No issues found）
- `flutter test test/sleep_repository_test.dart --reporter compact`（通过）
- `git diff --check -- plans/PLAN_053_睡眠助手实用闭环完善.md modules/sleep/README.md changelogs/CHANGELOG.md lib/src/models/sleep_routine_template.dart lib/src/state/app_state_sleep.dart lib/src/ui/pages/sleep_assistant_ui_support.dart lib/src/ui/pages/sleep_quick_tools.dart lib/src/ui/pages/sleep_quick_tools_sheets.dart lib/src/ui/pages/sleep_research_library.dart lib/src/ui/pages/sleep_wind_down_page.dart lib/src/ui/pages/toolbox_sleep_assistant_page.dart test/sleep_repository_test.dart`（通过，仅提示 changelog 受本机 Git 换行设置影响）

## [Unreleased-PLAN_052] - 2026-04-24

### 原因
- 用户确认 `ASR/sherpa-onnx-whisper-small.en.tar.bz2` 等 ASR 资源不是项目必须内容，要求整理 `.gitignore`，清除与项目代码无关的已跟踪文件，并保留最小提交。
- GitHub 推送已被两个超过 100MB 的 ASR 压缩包拒绝，需要从本地未推送历史中彻底移除。

### 修改
- 从 `origin/main..main` 的本地未推送历史中移除 `ASR/` 大模型压缩包和 `third_party/flutter_tts/example/` 第三方示例工程。
- 更新 `.gitignore`，忽略 ASR 本地资源、第三方示例工程、常见模型文件和压缩包产物，避免再次误加入版本库。
- 保留 `assets/branding/`、`assets/en_zh_15000_wordbook.json`、`assets/toolbox/` 等项目运行资产不变。

### 风险变更
- 本轮重写了本地尚未推送的 45 个提交哈希；远端 `origin/main` 未改写，当前 `main` 仍以远端分支为祖先。
- 本轮仅清理非必需资源与忽略规则，不改动 Flutter 运行代码和沙盘功能逻辑。

### 验证
- `git merge-base --is-ancestor origin/main main`（通过）
- `git filter-branch --force --index-filter "git rm -r --cached --ignore-unmatch ASR third_party/flutter_tts/example" --prune-empty --tag-name-filter cat -- origin/main..main`（通过）
- `git ls-files ASR third_party/flutter_tts/example`（通过，无输出）
- `git rev-list --objects main | Select-String -Pattern "sherpa-onnx-whisper|third_party/flutter_tts/example"`（通过，无输出）

## [Unreleased-PLAN_051] - 2026-04-24

### 原因
- 用户要求完成沙盘模块最后一轮收尾：将“一键抹平”加入页面底部菜单栏，并提交推送。
- 收尾审核中发现沉浸模式折叠菜单也应补齐同一操作，且页面中存在一组未使用 setter warning。

### 修改
- 将“一键抹平”加入底部菜单栏的折叠、紧凑和常规三种形态，复用现有横向滚动结构，不增加底部栏高度。
- 将画布快捷条文案统一为“一键抹平”，并复用 `_canSmoothAll` 禁用判断。
- 在沉浸模式折叠菜单中补齐“一键抹平”，避免全屏状态下必须退出才能完成抹平。
- 抹平成功后增加轻量提示，明确反馈笔触已被抹平。
- 清理沙盘页面中未使用的私有 setter，消除沙盘相关 `unused_element` 分析警告。

### 风险变更
- 本轮不改变 `_smoothAll()` 的数据语义：仍然只清除笔触并保留景石。
- 底部菜单新增按钮会增加横向滚动内容，但继续复用 48dp 触控按钮和现有滚动容器。

### 验证
- `dart format lib/src/ui/pages/toolbox_zen_sand_tool.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_zen_sand_tool.dart lib/src/ui/pages/toolbox_zen_sand_tool_config.dart lib/src/ui/pages/toolbox_zen_sand_tool_render.dart lib/src/ui/pages/toolbox_zen_sand_tool_state.dart lib/src/ui/pages/toolbox_zen_sand_tool_widgets.dart`（通过，No issues found）
- `git diff --check -- lib/src/ui/pages/toolbox_zen_sand_tool.dart changelogs/CHANGELOG.md plans/PLAN_051_创意沙盘底部抹平入口与收尾审核.md`（通过）
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`（通过）

## [Unreleased-PLAN_050] - 2026-04-24

### 原因
- 用户反馈创意沙盘“贴合触点”模式下，手指触点与实际画出的沙痕位置仍有错位，需要真实贴合。
- 当前全屏沉浸模式仍保留顶部按钮和底部 dock，手机横屏时画布空间没有被充分释放。

### 修改
- 修正沙盘画布手势坐标基准：
  - 原先使用外层容器尺寸计算落笔位置，容易被 padding、画布标题条和快捷操作条影响。
  - 改为在真实绘制区域内部用 `LayoutBuilder` 获取画布尺寸，并将手势、归一化、缩放/平移反变换统一到同一尺寸基准。
- 重构沉浸模式：
  - 沉浸态隐藏画布标题、快捷 action strip、底部 dock 和常驻提示，让沙盘画布直接铺满屏幕。
  - 仅保留一个 52dp 浮动菜单按钮，菜单中折叠提供退出全屏、场景、工具、预设、撤销、重做、重置视角和清空沙盘。
  - 手机尺寸进入沉浸模式时尝试切换到横屏方向，并在退出或销毁页面时恢复系统 UI 与方向偏好。

### 修复
- 修复“贴合触点”开启后仍因外层尺寸与真实绘制面不一致导致的落笔偏移。
- 修复沉浸模式控件占位过多、手机横屏不够沉浸的问题。

### 风险变更
- 坐标链路只修正画布尺寸来源，不改变现有 viewport 缩放/平移公式。
- 沉浸模式会在手机尺寸下请求横屏方向，退出沉浸或离开页面时恢复。

### 验证
- `dart format lib/src/ui/pages/toolbox_zen_sand_tool.dart`（通过）
- `dart analyze lib/src/ui/pages/toolbox_zen_sand_tool.dart`（仍有既有 6 条 `unused_element` warning）
- `git diff --check -- lib/src/ui/pages/toolbox_zen_sand_tool.dart changelogs/CHANGELOG.md`（通过）
- `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`（通过）

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
