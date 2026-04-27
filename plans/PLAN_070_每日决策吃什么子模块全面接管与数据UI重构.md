# 计划 070: 每日决策吃什么子模块全面接管与数据 UI 重构

## 基本信息
- **创建日期**: 2026-04-27
- **状态**: 进行中
- **负责人**: Codex
- **工作分支**: `codex/daily-choice-overhaul`
- **备份提交**: `735b95a chore: backup current workspace before daily choice overhaul`

## 目标
接管工具箱「每日决策 - 吃什么」子模块，从数据可信度、字段索引、筛选匹配、随机算法、加载链路、管理界面、分页体验和崩溃修复等方面做系统性重构。目标不是继续在现有大页面上补丁式堆功能，而是把菜谱数据、筛选索引、随机池、详情读取和管理 UI 分层，确保移动端能稳定、快速、可维护地承载更丰富的菜谱系统。

## 当前基线
1. 当前已创建 `codex/daily-choice-overhaul` 分支，并完成备份式提交 `735b95a`。
2. 每日决策模块已拆入 `lib/src/ui/pages/toolbox_daily_choice/`，但吃什么模块仍存在大文件、大集合同步构建、管理 sheet 过重和字段语义混乱问题。
3. 当前 `DailyChoiceHub` 在初始化时并发加载自定义状态和吃什么菜谱库，导致吃什么成为每日决策入口的阻塞源，即使用户要用其他子模块也会被拖慢。
4. 崩溃堆栈指向 `daily_choice_manager_sheet.dart` 中函数级 `TextEditingController` 生命周期与 bottom sheet 重建/关闭过程耦合过强，需要改为独立 Stateful 组件持有。
5. 既有 `PLAN_068` 已做过指南与部分摘要加载优化，但用户反馈说明数据源质量、字段匹配、随机体验和管理 UI 仍需进入下一轮架构级处理。

## 工作流约定
1. 每轮修改前先更新本计划的「阶段进度」和「本轮边界」。
2. 先修可导致阻塞或崩溃的 P0 问题，再推进 schema 和数据重建，避免用户无法进入其他模块。
3. 涉及 `toolbox` UI 精修时同步遵守：
   - `docs/toolbox_design/TOOLBOX_DESIGN_REVIEW.md`
   - `docs/toolbox_design/TOOLBOX_ANIMATION_SPEC.md`
   - `docs/toolbox_design/TOOLBOX_UI_STYLE_GUIDE.md`
4. 数据重建遵守“证据优先”：菜系、素食友好、清真、忌口、餐段等字段若源资料没有明确依据，不做过度推测。
5. 用户可见文本继续使用现有 `pickUiText` / i18n 入口，不新增硬编码单语文案。
6. 每轮完成后更新 `changelogs/CHANGELOG.md`，再回写本计划的完成记录与验证记录。
7. 每个阶段完成后提交一次专业 commit；若阶段未完成但上下文需要交接，也提交计划/记录更新。

## 阶段进度
| 阶段 | 状态 | 目标 |
|------|------|------|
| 0. 备份与接管计划 | 已完成 | 建立分支、备份提交、创建可延续计划 |
| 1. P0 稳定性止血 | 已完成 | 修复加载阻塞、controller 崩溃、随机按钮跳动和明显卡顿入口 |
| 2. 数据源审计与规范 | 进行中 | 从 cook 项目、本地做菜资料和现有 `cook_data` 生成可信字段规范 |
| 3. 数据库与索引重构 | 进行中 | 建立菜谱集、摘要表、详情表、字段索引、不可用标记和迁移兼容 |
| 4. 筛选与随机引擎重构 | 进行中 | 精确食材匹配、餐段默认全部、忌口精简、随机池去顺序偏差 |
| 5. 管理 UI 拆分 | 进行中 | 管理 sheet 拆出子页面/子窗口，完善食谱集管理和自动分页 |
| 6. 数据包生成与交付 | 进行中 | 产出可重新上传的本地数据包、校验报告和上传前清单 |
| 7. 回归验证与收尾 | 待开始 | 单测、widget smoke、性能采样、构建验证、changelog 和计划归档 |

## 详细步骤
1. P0 稳定性止血
   - 将每日决策入口初始化改为“模块级懒加载”：先加载轻量自定义状态与非吃什么模块，只有进入吃什么或触发安装/管理时加载菜谱库摘要。
   - 修复 `daily_choice_manager_sheet.dart` 的 `TextEditingController` 生命周期，优先把管理 sheet 拆成 StatefulWidget，由组件生命周期负责 dispose。
   - 随机面板固定候选展示高度，标题/说明超出省略或折入详情；停止按钮放入稳定操作区，随机过程中不随内容高度上下跳。
   - 暂时保留现有数据结构，但避免进入页面、编辑保存、管理切换时同步重建全量 `DailyChoiceOption` UI。

2. 数据源审计与规范
   - 对比 `https://github.com/YunYouJun/cook`、`D:\vocabularySleep-resources\做菜` 和 `D:\vocabularySleep-resources\cook_data`。
   - 先生成字段审计报告：菜名、食材、步骤、标签、菜系、荤素、忌口、餐段、厨具、难度、来源字段的可信度。
   - 规则：明确包含猪肉/排骨/肉类时不得标注素食友好；菜系只采用源文件明确标注或稳定目录语义，无法确认则留空；不展示外部参考和来源。
   - 删除或停用不可用字段，避免继续通过全表更新修正错误标签。

3. 数据库与索引重构
   - 新增或迁移为分层表：
     - `recipe_sets`: 菜谱集元数据，默认内置 cook 独立成集。
     - `recipe_summary`: 仅包含 id、set_id、名称、简短摘要、可用状态和轻量排序字段。
     - `recipe_detail`: 通过 id 按需读取完整材料、步骤、备注。
     - `recipe_filter_index`: 餐段、厨具、菜系、荤素、忌口、标签等结构化筛选索引。
     - `recipe_ingredient_index`: 标准食材、别名、匹配等级和原始食材片段。
     - `recipe_delete_flags` 或 `is_available`: 用不可用标记代替全量删除/重写。
   - 搜索方案优先复用 SQLite 索引；若名称/材料文本搜索仍不足，再评估 SQLite FTS5 或轻量倒排索引，不先引入重依赖。
   - 默认列表只读摘要并分页，详情、编辑、校验才读取 `recipe_detail`。

4. 筛选与随机引擎重构
   - 食材匹配从“泛化扩展”改为“精确优先”：用户输入 `排骨` 时先匹配排骨，不自动退化为所有猪肉；只有用户选择“扩展到同类食材”时才放宽。
   - 餐段增加“全部”并设为默认，不再按当前时间强制早餐/午餐/晚餐。
   - 忌口预设保留：香菜、海鲜、花生坚果、酒精、辣椒；额外展示最近 3 个用户自定义忌口且不重复。
   - 随机池通过候选 id 计算，停止时再读取摘要或详情；避免列表顺序、分页窗口或 UI 当前段落影响随机结果。
   - 为随机结果增加测试：同一候选池多次抽取不应只落在顺序区间或当前分页区间。

5. 管理 UI 拆分
   - 将“我的调整”“我的自定义”“食谱集管理”“内置菜谱浏览”从单一超长 bottom sheet 拆成独立页面或分层子窗口。
   - 菜谱管理支持按菜谱集进入，集合内默认显示摘要，滑到底部自动加载下一页。
   - “继续加载”按钮改为无感自动加载；必要时保留小型加载尾标。
   - 内存策略先不做激进清理：若仅保留摘要列表，移动端压力通常可控；当摘要超过约 5 万条或详情缓存明显增长时，再加入窗口化缓存和 LRU 详情缓存。

6. 数据包生成与交付
   - 更新或重写 `scripts/generate_daily_choice_recipe_dataset.py`，输出数据库、字段审计报告和上传清单。
   - 对 `D:\vocabularySleep-resources\cook_data` 的修改保持可追溯，必要时另存生成产物目录，避免覆盖原始下载数据。
   - 输出重新上传 S3 前的校验项：总数、空字段、互斥字段冲突、素食/肉类冲突、菜系来源、随机池可用数。

7. 回归验证
   - 单测覆盖数据字段规范、食材精确匹配、忌口筛选、餐段默认全部、随机池抽样、详情懒加载。
   - widget smoke 覆盖每日决策入口不被吃什么加载阻塞、管理页打开/关闭无 controller disposed 崩溃。
   - 运行 `dart format`、`flutter analyze`、相关 `flutter test`，可行时运行 Android 构建脚本。

## 13 个问题对应验收
| 编号 | 验收标准 |
|------|----------|
| 1 | 数据字段审计通过，猪肉/排骨等肉类不再被标注素食友好，菜系无依据则留空 |
| 2 | 食材匹配精确优先，`排骨` 不默认匹配全量猪肉菜谱 |
| 3 | 进入、编辑保存、管理浏览不再全量构建详情；摘要/详情/索引分层 |
| 4 | 随机基于完整候选 id 池，不受分页窗口和列表顺序影响 |
| 5 | 随机过程中停止按钮位置稳定，候选内容高度固定或溢出省略 |
| 6 | 每日决策入口不等待吃什么菜谱库加载即可使用其他模块 |
| 7 | 管理入口拆分，避免所有菜谱、调整、自定义、集合挤在两个简单页面 |
| 8 | 菜谱分集合具备创建、选择、浏览、加入/移出、集合内随机和管理 |
| 9 | 高级筛选精简忌口预设，并展示最近 3 个自定义忌口 |
| 10 | 餐段增加并默认“全部” |
| 11 | 用户界面和指南中不展示外部参考和来源 |
| 12 | 菜谱分页滑到底部自动加载，必要时评估窗口化内存策略 |
| 13 | `TextEditingController was used after being disposed` 崩溃不再复现 |

## 风险评估
- **风险 1**: 数据源存在大量错误或缺失，短期内无法自动修复全部语义字段。
- **缓解措施**: 先把无依据字段留空或停用，用审计报告列出待人工确认项，避免继续输出错误自信标签。
- **风险 2**: SQLite schema 迁移影响已安装用户的本地库。
- **缓解措施**: 新 schema 采用版本化安装与惰性迁移；旧库可读时提供兼容读取路径；安装失败时不阻塞其他每日决策模块。
- **风险 3**: 管理 UI 拆页会触碰导航和状态同步边界。
- **缓解措施**: 先拆展示层和页面承载，不改变自定义状态的保存语义；每一步都用 smoke test 锁定入口、保存和关闭行为。
- **风险 4**: 文本搜索和食材别名容易在“召回率”和“精准度”之间摇摆。
- **缓解措施**: 默认精确优先，扩展匹配作为显式选项；测试用例固定 `排骨`、`猪肉`、`牛肉`、`鸡蛋` 等高风险词。

## 依赖项
- `lib/src/ui/pages/toolbox_daily_choice/`
- `scripts/generate_daily_choice_recipe_dataset.py`
- `test/daily_choice_*`
- `D:\vocabularySleep-resources\做菜`
- `D:\vocabularySleep-resources\cook_data`
- `https://github.com/YunYouJun/cook`
- `docs/toolbox_design/TOOLBOX_DESIGN_REVIEW.md`
- `docs/toolbox_design/TOOLBOX_ANIMATION_SPEC.md`
- `docs/toolbox_design/TOOLBOX_UI_STYLE_GUIDE.md`

## 本轮边界
- 本轮收敛管理页“我的食谱集”重复入口：移除上方 chip 与下方卡片的双重选择，改为一个单一下拉框选择当前随机/浏览范围。
- 本轮把食谱集删除和重命名功能放到下拉框旁边的动作按钮中，默认“我喜欢的菜”继续保留保护，不允许删除或重命名。
- 本轮新增食谱集导出/导入能力：导出当前个人食谱集为 JSON 分享包，由用户选择保存位置；导入时从用户选择的 JSON 文件合并集合、自定义菜谱和个人调整。
- 本轮导入/导出只处理本地自定义状态，不修改内置 SQLite 菜谱库，也不覆盖 `D:\vocabularySleep-resources\cook_data` 或验证包数据。

## 完成记录
1. 2026-04-27: 已创建 `codex/daily-choice-overhaul` 分支。
2. 2026-04-27: 已完成备份式提交 `735b95a chore: backup current workspace before daily choice overhaul`。
3. 2026-04-27: 已梳理当前关键风险文件：`daily_choice_hub.dart`、`daily_choice_manager_sheet.dart`、`daily_choice_widgets.dart`、`daily_choice_eat_library_store.dart`。
4. 2026-04-27: 已补充 `changelogs/CHANGELOG.md` 的 PLAN_070 接管记录。
5. 2026-04-27: 已启动阶段 1 P0 稳定性止血，范围限定为入口懒加载、管理 sheet controller 生命周期和随机面板稳定高度。
6. 2026-04-27: 已将 `DailyChoiceHub` 改为只用自定义状态阻塞首帧；吃什么菜谱库摘要进入吃什么模块后后台加载，其他模块不再等待吃什么加载完成。
7. 2026-04-27: 已移除管理 sheet 新建食谱集输入框的函数级 `TextEditingController`，改为 `TextFormField` 内部状态，避免关闭/重建时使用已释放 controller。
8. 2026-04-27: 已固定随机面板候选舞台高度，并限制随机中的标题、简介和标签行数，停止按钮不再随菜品文本换行上下跳动。
9. 2026-04-27: 已新增 smoke 测试覆盖“吃什么摘要加载未完成时仍可切换并使用穿什么模块”。
10. 2026-04-27: 已新增 `scripts/audit_daily_choice_recipe_dataset.py`，用于审计当前 `cook_data` JSON/SQLite 与 YunYouJun/cook `recipe.csv` 的字段冲突和数据源覆盖。
11. 2026-04-27: 已生成首轮审计报告 `records/record_070_daily_choice_recipe_data_audit.md` 与机器可读报告 `records/record_070_daily_choice_recipe_data_audit.json`。
12. 2026-04-27: 首轮审计确认：当前 7179 条菜谱中，`vegetarian` 与肉类/海鲜冲突 530 条，`vegan_friendly` 与动物性食材冲突 496 条，菜系标签混入 notes 2221 条，`清真友好` 规则说明混入 notes 3416 条，cook CSV 599 行中 569 行未在当前库标题精确命中。
13. 2026-04-27: 已修正 `scripts/generate_daily_choice_recipe_dataset.py` 的字段生成规则：停用自动清真/纯素/素食友好 diet 标签，菜系不再写入 notes，清真说明不再写入菜谱正文，动物性风险词覆盖兔、龟、鸽、鹌鹑、田鸡、牡蛎等漏标食材。
14. 2026-04-27: 已将 YunYouJun/cook `recipe.csv` 作为 `cook_csv` 结构化数据来源导入验证包，保留 difficulty/tags/methods/tools/bv/stuff 到 attributes，不写入 sourceLabel、sourceUrl 或 references。
15. 2026-04-27: 已输出隔离验证包 `D:\vocabularySleep-resources\cook_data_plan070_validation`，包含 7772 条菜谱、7179 条本地书籍菜谱和 593 条去重 cook CSV 菜谱；cook CSV 599 行标题精确命中 599 行。
16. 2026-04-27: 已生成修正规则后的审计报告 `records/record_070_daily_choice_recipe_data_audit_after_generation.md` 与 `records/record_070_daily_choice_recipe_data_audit_after_generation.json`；10 个审计问题桶均为 0。
17. 2026-04-27: 已新增 `records/record_070_daily_choice_recipe_schema_design.md`，明确 v2 数据库分层：菜谱集、基础索引、摘要、详情、筛选中间表、食材专用索引、材料/步骤行表、搜索表和用户 overlay 表。
18. 2026-04-27: 已新增 `scripts/daily_choice_recipe_schema_v2.sql`，包含 14 张表和 18 个索引，覆盖 keyset 分页、随机 pivot、筛选 lookup、食材 value lookup、用户隐藏/收藏和集合成员查询。
19. 2026-04-27: 已压缩 `D:\vocabularySleep-resources\cook_data_plan070_validation` 中三份 JSON：`daily_choice_recipe_library.json` 为 19,614,095 bytes，`daily_choice_recipe_library_summary.json` 为 4,918,383 bytes，`recipe_library_asset.json` 为 19,614,095 bytes；三份 JSON 均可解析且包含 7,772 条菜谱。
20. 2026-04-27: 已新增 `records/record_070_daily_choice_s3_upload_package.md`，记录上传包文件大小、建议 S3 key、远端安装边界和验证命令。
21. 2026-04-27: 已将 `DailyChoiceEatLibraryStore.installLibrary()` 改为远端 SQLite 候选文件安装：下载/校验通过后才替换当前 DB，远端失败时保留已有库。
22. 2026-04-27: 已移除吃什么菜谱安装阶段的 bundled JSON / cached CSV / fallback seed 兜底导入路径；首次远端失败且无旧库时返回错误状态，并清理候选 DB、空 DB、旧 JSON cache 和旧 cook CSV cache。
23. 2026-04-27: 已验证用户上传到 S3 `/cook_data` 的远端包：`cook_data/daily_choice_recipe_library.db` 可 HEAD、range 和完整下载，下载后 v1 summary/detail 均为 7,772 行，meta 显示 book 7,179 条、cook 593 条。
24. 2026-04-27: 已新增 `scripts/verify_daily_choice_recipe_remote.dart`，用于通过纯 Dart S3 probe 下载远端 DB 并验证 v1/v2 表计数、meta 和 sample detail。
25. 2026-04-27: 已将 `scripts/generate_daily_choice_recipe_dataset.py` 的 SQLite 导出改为 v1/v2 双写：保留现有 v1 runtime 表，同时写入 `daily_choice_recipe_sets`、`daily_choice_recipes`、summary/detail、filter index、ingredient index、search text 和 set stats 等 v2 表。
26. 2026-04-27: 已开始阶段 4 筛选基础收口：吃什么餐段默认改为“全部”，catalog 支持 `mealId == 'all'`；忌口预设精简为香菜、海鲜、花生坚果、酒精、辣椒；`排骨` 等具体猪肉项不再在运行时自动折叠成通用 `pork` 食材 token。
27. 2026-04-27: 已按用户要求重新生成 `D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db` 为 v2-only DB，不再包含 v1 兼容表；新 DB 大小 142,467,072 bytes，SHA256 为 `9B769482EEA198E233263EB41E8FA01ECAA3C058E25F68377ED8E468F62C6FFE`。
28. 2026-04-27: 已新增 `records/record_070_daily_choice_v2_only_db_package.md`、`records/record_070_daily_choice_recipe_v2_only_db_audit.md` 与 JSON 审计记录，记录 v2-only 上传包、schema 计数、哈希和审计结果。
29. 2026-04-27: 已验证用户更新后的 S3 `cook_data/daily_choice_recipe_library.db`：远端大小 142,467,072 bytes，`user_version=2`，v2 recipes/summaries/details 均为 7,772 行。
30. 2026-04-27: 已让 `DailyChoiceEatLibraryStore` 支持 v2-only DB：安装校验、meta 归一化、状态读取、摘要读取和详情懒加载均可按 v2 表执行，同时保留 v1 旧库读取能力。
31. 2026-04-27: 已新增 v2-only SQLite store 单测，覆盖远端安装后 schemaVersion=2、book/cook 计数、摘要无详情负载和详情懒加载。
32. 2026-04-27: 已新增 `records/record_070_daily_choice_remote_v2_runtime_smoke.md`，记录远端 v2 smoke、运行时改动和验证命令。
33. 2026-04-27: 已新增 `DailyChoiceEatLibraryQuery` / `DailyChoiceEatLibraryQueryResult`，为 v2 摘要分页、总数、完整候选 id 池和后续 random pivot 建立 store 查询入口。
34. 2026-04-27: 已将 v2 查询下沉到 `daily_choice_recipe_filter_index` 与 `daily_choice_recipe_ingredient_index`，覆盖餐段、厨具、trait、contains 忌口、自定义忌口和 raw/canonical 食材优先匹配。
35. 2026-04-27: 已新增 `records/record_070_daily_choice_v2_sql_query_foundation.md`，记录 v2 SQL 查询基础、本轮边界、测试覆盖和后续 UI 接入风险。
36. 2026-04-27: 已新增 `DailyChoiceEatLibraryStore.pickBuiltInRandomSummary(...)`，支持按 v2 `random_key` pivot 从完整候选池抽取轻量摘要。
37. 2026-04-27: random pivot 已复用 `DailyChoiceEatLibraryQuery` 的筛选条件，并在 pivot 超过候选尾部时回绕到候选池开头。
38. 2026-04-27: 已新增 `records/record_070_daily_choice_v2_random_pivot.md`，记录 store 层随机 pivot 能力、测试覆盖和后续 UI 接入边界。
39. 2026-04-27: 已让主 UI 的吃什么内置库停止随机逐步接入 `pickBuiltInRandomSummary(...)`；当随机池全为可见内置菜谱时，最终选中由 store random pivot 返回。
40. 2026-04-27: 已让管理页吃什么内置库在无搜索词时使用 `queryBuiltInSummaries(...)` 分页读取；搜索词非空时继续走旧内存过滤，避免搜索语义回退。
41. 2026-04-27: 已新增 `records/record_070_daily_choice_ui_random_and_manager_sql_paging.md`，记录主 UI 随机与管理页 SQL 分页接入边界。
42. 2026-04-27: 已收口管理页 SQL 查询失败态，同一查询 key 失败后不在 build 循环中反复重试，后续筛选或分页变化会自然触发新查询。
43. 2026-04-27: 已收口随机面板异步最终抽取的候选池变化边界，筛选变化会让旧抽取结果失效。
44. 2026-04-27: 已补充随机面板 widget 回归测试，覆盖候选池变化后旧异步抽取不回写当前 UI。
45. 2026-04-27: 已新增 `DailyChoiceEatLibraryQuery.searchText`，并让 v2 store 通过 `daily_choice_recipe_search_text` 下沉管理页吃什么内置库搜索。
46. 2026-04-27: 已让管理页吃什么内置库搜索词非空时继续使用 `queryBuiltInSummaries(...)`，本地自定义和个人调整搜索仍沿用内存路径。
47. 2026-04-27: 已新增 `records/record_070_daily_choice_manager_sql_search.md`，记录管理页内置库搜索下沉范围、风险和后续 FTS/拆页方向。
48. 2026-04-27: 已将吃什么详情解析从内存 `builtInOptions` 全量摘要依赖中解耦，SQL 分页/搜索返回的轻量内置摘要可直接按 id 懒加载 detail。
49. 2026-04-27: 已新增 `records/record_070_daily_choice_manager_detail_lazy_load.md`，记录管理页内置摘要详情按需加载解耦范围和风险。
50. 2026-04-27: 已为管理页吃什么内置菜谱条目增加详情、个人调整、另存的逐项 loading / disabled / error 状态，避免同一条目重复触发 detail 读取。
51. 2026-04-27: detail 读取失败时，管理页会保留当前 sheet、分页和搜索状态，并在对应菜谱条目内显示局部错误；主 UI 详情按钮仍保留 SnackBar 错误反馈。
52. 2026-04-27: 已新增 `records/record_070_daily_choice_manager_item_action_states.md`，记录本轮管理页逐项动作状态的实现边界、风险和验证。
53. 2026-04-27: 已将管理页吃什么内置库“继续加载”按钮改为滚动接近底部自动加载下一页，查询仍通过 `queryBuiltInSummaries(...)` SQL limit 递进完成。
54. 2026-04-27: 已将管理页搜索输入改为 draft/commit 两段，输入中不触发 SQL 搜索，失焦或提交搜索后才刷新分页与 `searchText`。
55. 2026-04-27: 已新增 `records/record_070_daily_choice_manager_auto_paging_and_search_commit.md`，记录自动分页、搜索提交边界和后续 FTS/倒排表风险。
56. 2026-04-27: 已为随机面板最终异步抽取增加 1200ms 超时兜底；超时、失败或返回空结果时保留停止瞬间锁定的当前候选，避免按钮卡在“选中中”。
57. 2026-04-27: 已优化吃什么主 UI 停止随机的 v2 random pivot 边界：无隐藏/调整/食谱集时不再传入全量候选 id 列表；需要精确可见池且候选过大时回退本地锁定候选，避免生成大 `IN (...)` 查询。
58. 2026-04-27: 已新增 `records/record_070_daily_choice_random_stop_timeout_and_pivot_guard.md`，记录随机停止超时兜底、大候选池 SQL guard 和验证结果。
59. 2026-04-27: 已将吃什么主 UI 停止随机改为纯本地锁定，不再在停止按钮链路触发 `pickBuiltInRandomSummary(...)` 或任何 SQLite 查询，避免 UI isolate 被同步查询占住。
60. 2026-04-27: 已将 `DailyChoiceEatLibraryStore.queryBuiltInSummaries(...)` 改为优先通过 `Isolate.run` 后台打开 SQLite 文件查询，失败时回退原同步路径；管理页分页/搜索查询不再优先占用 UI isolate。
61. 2026-04-27: 已增强管理页内置库自动分页触发：除滚动通知外，在 SQL 返回并完成布局后检查当前滚动位置，修复停在底部但没有新滚动事件时不继续加载的问题。
62. 2026-04-27: 已新增 `records/record_070_daily_choice_stop_local_and_manager_isolate_paging.md`，记录停止随机本地落点、管理页 isolate 查询和触底分页修复。
63. 2026-04-27: 已将吃什么随机页的菜谱集选择保留在外层入口，并将默认大库口径统一命名为“内置菜谱”，用户开始随机前即可选择内置库或个人菜谱集。
64. 2026-04-27: 已新增默认空集合“我喜欢的菜”，自定义状态加载/保存时自动补齐该集合，且删除集合时保护该默认集合不被移除。
65. 2026-04-27: 已将管理页内置菜谱集合动作改为“喜欢/加入”，默认加入“我喜欢的菜”，并通过弹窗支持多选加入其他菜谱集。
66. 2026-04-27: 已为“不喜欢”隐藏动作增加确认弹窗，并为保存调整、另存、加入集合等写入动作增加处理中反馈，降低误触和卡顿感知。
67. 2026-04-27: 已新增管理页右侧固定“一键回到页首”浮动按钮，并收紧搜索输入框高度，使其与旁边按钮高度更协调。
68. 2026-04-27: 已移除吃什么 UI 的饮食友好辅助筛选入口，生成器和 v2 schema 移除起源地字段，验证包 JSON/DB 不再写入 `origin` 或 `diet` 字段。
69. 2026-04-27: 已重新生成 `D:\vocabularySleep-resources\cook_data_plan070_validation` 验证包；当前 v2-only DB 大小 142,233,600 bytes，SHA256 为 `418B40F934925FEB4AA1054A0A74442C2BEA063730EB727F20BE586ABD71C7B3`。
70. 2026-04-27: 已新增 `records/record_070_daily_choice_collection_favorites_and_risk_cleanup.md`，记录本轮集合入口、喜欢集合、确认隐藏、风险字段清理和验证包输出。
71. 2026-04-27: 已将管理页“我的食谱集”选择入口收敛为单一下拉框，移除重复的集合 chip 与集合卡片选择区。
72. 2026-04-27: 已把食谱集重命名和删除动作放到下拉框旁边；默认“我喜欢的菜”继续保持保护，不允许重命名或删除。
73. 2026-04-27: 已新增当前个人食谱集 JSON 导出能力，导出包包含集合元数据、集合内自定义菜谱、个人调整和内置菜谱 id 引用，并由用户选择保存位置。
74. 2026-04-27: 已新增食谱集 JSON 分享包导入能力，导入时合并自定义菜谱和个人调整，并生成新的集合 id，避免覆盖已有集合。
75. 2026-04-27: 已新增 `records/record_070_daily_choice_collection_dropdown_import_export.md`，记录集合下拉入口、重命名/删除、导入/导出格式和风险边界。
76. 2026-04-27: 已为食谱集导入补充分享包版本校验和文件内容读取失败提示，避免无效文件被静默忽略。

## 验证记录
- 2026-04-27: `git status --short --branch` 已确认备份前存在大量每日决策相关改动。
- 2026-04-27: `git commit -m "chore: backup current workspace before daily choice overhaul"`（通过，提交 `735b95a`）。
- 2026-04-27: `dart analyze lib/src/ui/pages/toolbox_daily_choice test/daily_choice_hub_smoke_test.dart test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart test/daily_choice_eat_library_store_test.dart`（通过）。
- 2026-04-27: `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`（通过）。
- 2026-04-27: `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_custom_state_test.dart test/daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `python -X utf8 scripts\audit_daily_choice_recipe_dataset.py --cook-csv .tmp_recipe_csv_head.txt`（通过，生成审计报告）。
- 2026-04-27: `python -m py_compile scripts\audit_daily_choice_recipe_dataset.py`（通过）。
- 2026-04-27: `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py scripts\audit_daily_choice_recipe_dataset.py`（通过）。
- 2026-04-27: `python -X utf8 scripts\generate_daily_choice_recipe_dataset.py --cook-csv .tmp_plan070_recipe.csv --output D:\vocabularySleep-resources\cook_data_plan070_validation\recipe_library_asset.json --export-dir D:\vocabularySleep-resources\cook_data_plan070_validation`（通过，生成隔离验证包）。
- 2026-04-27: `python -X utf8 scripts\audit_daily_choice_recipe_dataset.py --library-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.json --summary-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library_summary.json --sqlite-db D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db --cook-csv .tmp_plan070_recipe.csv --output-md records\record_070_daily_choice_recipe_data_audit_after_generation.md --output-json records\record_070_daily_choice_recipe_data_audit_after_generation.json`（通过，10 个审计问题桶均为 0）。
- 2026-04-27: `python -X utf8` 内存 SQLite 执行 `scripts\daily_choice_recipe_schema_v2.sql`（通过，创建 14 张表和 18 个索引）。
- 2026-04-27: `EXPLAIN QUERY PLAN` 验证 v2 摘要分页、通用筛选、食材匹配和随机 pivot 查询（通过，分别命中 `idx_dcr_recipes_active_set_sort`、`idx_dcr_filter_lookup`、`idx_dcr_ingredient_value_lookup`、`idx_dcr_recipes_active_set_random`）。
- 2026-04-27: `python -X utf8` 解析 `D:\vocabularySleep-resources\cook_data_plan070_validation` 中三份压缩 JSON（通过，三份 JSON 均为 7,772 条菜谱）。
- 2026-04-27: `dart analyze lib/src/ui/pages/toolbox_daily_choice/daily_choice_eat_library_store.dart test/daily_choice_eat_library_store_test.dart`（通过）。
- 2026-04-27: `flutter test test/daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `dart run scripts/s3_resource_probe.dart --op list --prefix cook_data/ --max-keys 20`（通过，确认远端 4 个上传文件存在）。
- 2026-04-27: `dart run scripts/s3_resource_probe.dart --op head --key cook_data/daily_choice_recipe_library.db`（通过，大小 47,915,008 bytes）。
- 2026-04-27: `dart run scripts/s3_resource_probe.dart --op get-range --key cook_data/daily_choice_recipe_library.db`（通过，文件头为 SQLite format 3）。
- 2026-04-27: `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py`（通过）。
- 2026-04-27: `dart run scripts/verify_daily_choice_recipe_remote.dart --key cook_data/daily_choice_recipe_library.db --expected-count 7772`（通过，远端完整下载后 v1 summary/detail 均为 7,772 行）。
- 2026-04-27: `python -X utf8` 最小数据集调用 `write_sqlite_export(...)`（通过，验证 v1/v2 表、`排骨` canonical 与 `猪肉` family index）。
- 2026-04-27: `dart analyze scripts/verify_daily_choice_recipe_remote.dart lib/src/ui/pages/toolbox_daily_choice test/daily_choice_eat_catalog_test.dart test/daily_choice_eat_library_store_test.dart`（通过）。
- 2026-04-27: `flutter test test/daily_choice_eat_catalog_test.dart test/daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `flutter test test/daily_choice_hub_smoke_test.dart --reporter compact`（通过）。
- 2026-04-27: `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py scripts\audit_daily_choice_recipe_dataset.py`（通过，确认 v2-only 导出与审计脚本语法有效）。
- 2026-04-27: `dart format scripts\verify_daily_choice_recipe_remote.dart`（通过）。
- 2026-04-27: `dart analyze scripts\verify_daily_choice_recipe_remote.dart`（通过）。
- 2026-04-27: `python -X utf8` 从验证包 `daily_choice_recipe_library.json` 调用 `write_sqlite_export(..., sqlite_mode='v2')`（通过，重写 `D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db`，7,772 条）。
- 2026-04-27: `python -X utf8` 检查 v2-only DB（通过，`PRAGMA integrity_check=ok`、`user_version=2`、v1 summary/detail 表不存在、v2 recipes/summaries/details 均为 7,772 行）。
- 2026-04-27: `python -X utf8 scripts\audit_daily_choice_recipe_dataset.py --library-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.json --summary-json D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library_summary.json --sqlite-db D:\vocabularySleep-resources\cook_data_plan070_validation\daily_choice_recipe_library.db --cook-csv build\_external\cook\app\data\recipe.csv --output-md records\record_070_daily_choice_recipe_v2_only_db_audit.md --output-json records\record_070_daily_choice_recipe_v2_only_db_audit.json`（通过，10 个审计问题桶均为 0，cook CSV 599 行全部标题命中）。
- 2026-04-27: `dart run scripts/verify_daily_choice_recipe_remote.dart --key cook_data/daily_choice_recipe_library.db --expected-count 7772`（通过，完整下载用户更新后的远端 v2-only DB，v2 recipes/summaries/details 均为 7,772 行）。
- 2026-04-27: `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart scripts\verify_daily_choice_recipe_remote.dart`（通过）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`（通过）。
- 2026-04-27: `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）。
- 2026-04-27: `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_hub_smoke_test.dart`（通过）。
- 2026-04-27: `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart`（通过）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过，管理页内置库搜索下沉后无静态问题）。
- 2026-04-27: `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`（通过，覆盖 v2 search table 查询）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖管理页搜索词传入 store 查询并只展示命中内置菜）。
- 2026-04-27: `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`（通过）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过，管理页 SQL 摘要 detail 解耦后无静态问题）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖内存摘要为空时管理页 SQL 摘要仍可打开详情，以及个人调整前 detail 懒加载）。
- 2026-04-27: `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`（通过）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过，管理页逐项动作状态接入后无静态问题）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖管理页 detail 慢读取期间禁用重复点击，以及 detail 失败时保留 sheet 并显示局部错误）。
- 2026-04-27: `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_hub_smoke_test.dart`（通过）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过，管理页自动分页和搜索提交边界接入后无静态问题）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖滚动触底自动扩大 SQL 分页 limit、搜索输入中不查询且失焦后提交）。
- 2026-04-27: `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过，主 UI random pivot 与管理页 SQL 分页接入后无静态问题）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖停止随机触发 store pivot、管理页展开内置库触发 SQL 查询、候选池变化后旧异步抽取不回写）。
- 2026-04-27: `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart`（通过，新增 v2 SQL 查询 API 后无静态问题）。
- 2026-04-27: `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`（通过，覆盖 v2 SQL 筛选、分页、`排骨` 精确食材匹配和花生坚果忌口）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`（通过）。
- 2026-04-27: `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart test\daily_choice_eat_library_store_test.dart`（通过，新增 random pivot API 后无静态问题）。
- 2026-04-27: `flutter test test\daily_choice_eat_library_store_test.dart --reporter compact`（通过，覆盖 pivot 命中、回绕和分页窗口外候选抽取）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_eat_library_store_test.dart test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_catalog_test.dart`（通过）。
- 2026-04-27: `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过）。
- 2026-04-27: `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart test\daily_choice_hub_smoke_test.dart`（通过）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖随机停止超时后退出 Picking、大可见池本地兜底且不触发 random pivot 重查询）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过，随机停止兜底与 pivot guard 接入后无静态问题）。
- 2026-04-27: `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
- 2026-04-27: `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_library_store.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart test\daily_choice_hub_smoke_test.dart`（通过）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖主 UI 停止随机不触发 store random pivot、管理页触底自动扩大 SQL 分页 limit）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart`（通过，queryBuiltInSummaries isolate 查询与分页触发修复后无静态问题）。
- 2026-04-27: `flutter test test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过，覆盖 store v2 SQL 查询 isolate 路径与 catalog 筛选）。
- 2026-04-27: `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_models.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_catalog.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_support.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_hub.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_eat_module.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_editor_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_seed_data.dart test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_hub_smoke_test.dart`（通过）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`（通过）。
- 2026-04-27: `python -m py_compile scripts\generate_daily_choice_recipe_dataset.py scripts\audit_daily_choice_recipe_dataset.py`（通过）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖管理页搜索提交、自动分页、个人调整懒加载、保存回写后恢复原味入口和停止随机本地落点）。
- 2026-04-27: `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过，覆盖默认喜欢集合、catalog 筛选和 v2 store 查询）。
- 2026-04-27: `python -X utf8` 检查 `D:\vocabularySleep-resources\cook_data_plan070_validation`（通过，recipes=7772，`user_version=2`，`integrity=ok`，v2 recipes/summaries/details 均为 7,772，`hasOriginColumn=False`，JSON `diet/origin` 为 0，DB 风险 diet terms 为 0，SHA256=`418B40F934925FEB4AA1054A0A74442C2BEA063730EB727F20BE586ABD71C7B3`）。
- 2026-04-27: `dart format lib\src\ui\pages\toolbox_daily_choice\daily_choice_manager_sheet.dart lib\src\ui\pages\toolbox_daily_choice\daily_choice_widgets.dart`（通过）。
- 2026-04-27: `dart analyze lib\src\ui\pages\toolbox_daily_choice test\daily_choice_hub_smoke_test.dart test\daily_choice_eat_library_store_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_custom_state_test.dart`（通过）。
- 2026-04-27: `flutter test test\daily_choice_hub_smoke_test.dart --reporter compact`（通过，覆盖管理页 smoke、SQL 分页、详情懒加载和随机停止回归）。
- 2026-04-27: `flutter test test\daily_choice_custom_state_test.dart test\daily_choice_eat_catalog_test.dart test\daily_choice_eat_library_store_test.dart --reporter compact`（通过）。
