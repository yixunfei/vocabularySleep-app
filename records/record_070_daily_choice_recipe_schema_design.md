# 记录 070: 每日决策吃什么 v2 数据库表设计

## 基本信息
- **创建日期**: 2026-04-27
- **状态**: 设计完成，待实现迁移
- **适用阶段**: PLAN_070 阶段 3 数据库与索引重构
- **SQL 草案**: `scripts/daily_choice_recipe_schema_v2.sql`

## 设计目标
1. 默认进入「吃什么」时不再加载全量详情，也不需要一次性加载全量摘要到 Dart 内存。
2. 列表页、管理页和菜谱集页使用游标分页，滑到底部自动加载下一页。
3. 随机只在候选 id 池上运行，详情按需读取，随机不受当前分页窗口或展示顺序影响。
4. 筛选、忌口、现有食材匹配和菜谱集范围都尽量由 SQLite 索引完成，减少 Flutter 侧全量遍历。
5. 食材匹配默认精确优先，`排骨` 不自动扩展为全部 `猪肉`；只有用户显式选择扩展匹配时才使用 family 层。
6. 数据包仍可离线安装和 S3 下发，用户隐藏、收藏、自定义集合等状态留在本地 overlay 表，避免重写远端库。

## 当前 v1 瓶颈
1. `daily_choice_eat_recipe_summaries` 同时保存摘要、attributes JSON、搜索文本和排序字段，读取摘要时按 `sort_key` 全量返回。
2. `daily_choice_eat_recipe_index_terms` 是通用 term 表，但当前 Flutter 仍把摘要全量转成 `DailyChoiceOption` 后在内存里建索引。
3. 食材只有单层 `ingredient`，具体食材、标准食材、家族食材混在一起，导致 `排骨`、`猪肉`、`洋葱`、`葱` 这类匹配边界容易被放大。
4. 详情表使用 JSON 足够简单，但列表与筛选没有严格阻止详情参与首屏路径。
5. 用户隐藏、集合管理和内置数据可用状态没有形成清晰 overlay，后续如果直接更新大表容易导致保存卡顿。

## v2 表分层

### 1. 元数据与菜谱集
- `daily_choice_recipe_schema_meta`
  - 保存 schema 版本、库版本、生成时间、记录数、兼容标记。
- `daily_choice_recipe_sets`
  - 管理默认 cook 集、本地书籍集、用户自定义集和后续扩展包。
  - `set_kind` 区分 `builtin`、`remote`、`user`、`collection`。
  - `is_enabled` 支持用户关闭某个菜谱集而不删除数据。

### 2. 基础索引层
- `daily_choice_recipes`
  - 每条菜谱的最小可筛选元信息：`recipe_id`、`primary_set_id`、标题、主餐段、主厨具、排序键、随机键、可用状态。
  - `random_key` 是生成期写入的 0 到 999999999 整数，用于随机 pivot 查询，避免 `ORDER BY RANDOM()` 扫全表。
  - `status` 与 `is_available` 用于软删除、停用和数据质量下线。
- `daily_choice_recipe_summaries`
  - UI 列表所需摘要：标题、副标题、少量 tag JSON、轻量 attributes JSON。
  - 与 `daily_choice_recipes` 一对一，列表分页只 join 这张表。
- `daily_choice_recipe_details`
  - 完整说明、材料 JSON、步骤 JSON、备注 JSON。只在详情、编辑、导出时读取。

### 3. 可查询中间表
- `daily_choice_recipe_filter_index`
  - 低基数字段索引：餐段、厨具、做法类型、荤素画像、contains、难度、cook tag、菜谱集标签等。
  - 结构为 `(term_group, term_value, set_id, recipe_id)`，故按筛选项查候选 id 不需要先 join 菜谱集。
- `daily_choice_recipe_ingredient_index`
  - 食材专用索引，保存三层 token：
    - `raw`: 原始食材或标题补充的具体食材，如 `排骨`、`猪里脊`。
    - `canonical`: 稳定标准词，如 `番茄`、`鸡蛋`。
    - `family`: 显式扩展层，如 `pork_family`、`seafood_family`。
  - `match_level` 用数字表达匹配优先级：100 raw、80 canonical、40 family。
  - 默认已有食材匹配只使用 `raw/canonical`；用户启用“扩展到同类食材”时才加入 `family`。
- `daily_choice_recipe_materials` 与 `daily_choice_recipe_steps`
  - 保留材料/步骤的行级结构，支持后续管理页材料编辑、局部搜索、质量审计，不强迫详情 JSON 反复解析。

### 4. 搜索与本地 overlay
- `daily_choice_recipe_search_text`
  - 轻量搜索表，保存 title/material/tag 拼接文本。基础方案用 `LIKE` 或前缀归一化查询。
  - 如果目标 SQLite 确认启用 FTS5，再增加 `daily_choice_recipe_search_fts` 虚表；v2 基表不强依赖 FTS5。
- `daily_choice_recipe_user_state`
  - 本地用户态：隐藏、收藏、最近查看、个人备注、用户可用性覆盖。
  - 不写回远端库，避免“删除/隐藏一条菜谱”触发全量库更新。
- `daily_choice_recipe_user_collections`
  - 用户集合元信息。
- `daily_choice_recipe_user_collection_members`
  - 用户集合成员关系，支持“我的集合”“我的调整”独立管理。

## 核心索引策略
1. 列表分页：
   - `idx_dcr_recipes_active_set_sort(primary_set_id, sort_key, recipe_id) WHERE is_available = 1 AND status = 'active'`
   - 用 keyset pagination：`sort_key > :cursorSort OR (sort_key = :cursorSort AND recipe_id > :cursorId)`。
2. 随机：
   - `idx_dcr_recipes_active_set_random(primary_set_id, random_key, recipe_id) WHERE is_available = 1 AND status = 'active'`
   - 候选 CTE 得到 recipe_id 后按 `random_key >= :seed` 取第一条，空则回绕取最小 random_key。
3. 通用筛选：
   - `idx_dcr_filter_lookup(term_group, term_value, set_id, recipe_id)`。
   - 多选同组取 union，多组之间取 intersection。
4. 食材精确匹配：
   - `idx_dcr_ingredient_lookup(token_kind, token_value, set_id, match_level DESC, recipe_id)`。
   - `idx_dcr_ingredient_value_lookup(token_value, set_id, match_level DESC, recipe_id, token_kind)` 用于默认 `raw/canonical` 双层精确查询，避免多 token_kind 合并时回到全表扫描。
   - 多食材输入用 `GROUP BY recipe_id HAVING COUNT(DISTINCT token_value) = :inputCount` 做全命中，命中不足再降级到高重叠。
5. 忌口排除：
   - contains 用 `filter_index` 排除。
   - 自定义忌口用 `ingredient_index` 排除，默认 `raw/canonical`，用户显式扩展时才排除 family。
6. 用户隐藏：
   - `daily_choice_recipe_user_state(recipe_id)` 主键查 overlay。
   - 随机和列表查询用 `NOT EXISTS` 排除 `is_hidden = 1` 或 `local_is_available = 0`。

## 典型查询

### 摘要分页
```sql
SELECT r.recipe_id, s.title_zh, s.subtitle_zh, s.tags_zh_json
FROM daily_choice_recipes r
JOIN daily_choice_recipe_summaries s ON s.recipe_id = r.recipe_id
WHERE r.primary_set_id = :setId
  AND r.is_available = 1
  AND r.status = 'active'
  AND (:cursorSort IS NULL OR r.sort_key > :cursorSort
       OR (r.sort_key = :cursorSort AND r.recipe_id > :cursorId))
ORDER BY r.sort_key, r.recipe_id
LIMIT :pageSize;
```

### 多条件候选池
```sql
WITH meal AS (
  SELECT recipe_id FROM daily_choice_recipe_filter_index
  WHERE term_group = 'meal' AND term_value IN (:mealIds)
),
tool AS (
  SELECT recipe_id FROM daily_choice_recipe_filter_index
  WHERE term_group = 'tool' AND term_value IN (:toolIds)
),
ingredient_exact AS (
  SELECT recipe_id
  FROM daily_choice_recipe_ingredient_index
  WHERE token_kind IN ('raw', 'canonical')
    AND token_value IN (:ingredientTokens)
  GROUP BY recipe_id
  HAVING COUNT(DISTINCT token_value) = :ingredientCount
)
SELECT r.recipe_id
FROM daily_choice_recipes r
JOIN meal ON meal.recipe_id = r.recipe_id
JOIN tool ON tool.recipe_id = r.recipe_id
JOIN ingredient_exact ON ingredient_exact.recipe_id = r.recipe_id
WHERE r.is_available = 1
  AND r.status = 'active'
  AND NOT EXISTS (
    SELECT 1
    FROM daily_choice_recipe_filter_index x
    WHERE x.recipe_id = r.recipe_id
      AND x.term_group = 'contains'
      AND x.term_value IN (:avoidContains)
  );
```

### 随机 pivot
```sql
WITH candidate AS (
  SELECT r.recipe_id, r.random_key
  FROM daily_choice_recipes r
  WHERE r.is_available = 1
    AND r.status = 'active'
    AND r.primary_set_id IN (:enabledSetIds)
)
SELECT recipe_id
FROM candidate
WHERE random_key >= :seed
ORDER BY random_key, recipe_id
LIMIT 1;
```
如果第一段无结果，再用同一个 candidate 查询最小 `random_key`。这样随机与列表顺序、分页窗口无关，也避免全表 `ORDER BY RANDOM()`。

## 迁移实施顺序
1. 生成器先输出 v1 与 v2 双库，Flutter 仍读取 v1。
2. 新增 `DailyChoiceEatLibraryStoreV2` 只实现 inspect、分页摘要、详情读取和按 id 随机。
3. 吃什么模块入口改为分页摘要加载，管理页切换到游标分页。
4. 筛选器从 Dart 内存索引切换到 SQLite 候选 id 查询。
5. 稳定后移除 v1 远端依赖，保留 v1 兼容读取一个版本周期。

## 取舍
- 不把所有字段完全关系化：详情正文、完整步骤和备注仍保留 JSON，避免编辑与导出过度复杂。
- 对高频筛选字段做中间表：餐段、厨具、类型、contains 和食材必须可索引查询，性能优先于表数量。
- 先不强依赖 FTS5：搜索体验可以升级，但基础随机与筛选不能依赖设备 SQLite 编译选项。
- 不做激进内存清理：v2 默认只分页摘要和按需详情，内存压力已显著下降；只有当摘要超过 5 万条或详情缓存增长明显时再加 LRU。

## 验收标准
1. 首屏进入吃什么不读取 `daily_choice_recipe_details`。
2. 管理列表分页查询可通过 `EXPLAIN QUERY PLAN` 命中 `idx_dcr_recipes_active_set_sort`。
3. `排骨` 输入默认命中 `raw/canonical` 排骨菜谱，不召回仅有 `猪肉` family 的菜谱。
4. 多筛选条件候选查询不需要把全部菜谱加载到 Dart。
5. 随机查询不使用 `ORDER BY RANDOM()`，并且不依赖当前分页窗口。
6. 隐藏、收藏、加入集合只写本地 overlay 表，不重写远端库。
