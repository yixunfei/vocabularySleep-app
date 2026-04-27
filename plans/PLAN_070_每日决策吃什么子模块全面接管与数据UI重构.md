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
| 5. 管理 UI 拆分 | 待开始 | 管理 sheet 拆出子页面/子窗口，完善食谱集管理和自动分页 |
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
- 本轮从已上传到 S3 `/cook_data` 的验证包开始，优先确认运行时默认 key `cook_data/daily_choice_recipe_library.db` 与 `CstCloudS3CompatClient` 配置一致，并做真实远端 HEAD / range / 下载后 SQLite smoke。
- 不覆盖 `D:\vocabularySleep-resources\cook_data` 原始数据；如需重新生成验证包，仅写入 `D:\vocabularySleep-resources\cook_data_plan070_validation`，也不把外部数据包提交进仓库。
- 继续推进阶段 3 的运行时性能铺垫：生成器先对 SQLite 导出双写 v1 兼容表与 v2 分层表，app 现有读取链路仍以 v1 表为主，避免一次性破坏已上传远端库和当前运行时。
- 继续推进阶段 4 的筛选与随机基础收口：餐段默认增加并使用“全部”，忌口预设先收敛到香菜、海鲜、花生坚果、酒精、辣椒；食材匹配默认保留 raw / canonical 精确优先，不再把 `排骨` 自动退化成全猪肉。

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
