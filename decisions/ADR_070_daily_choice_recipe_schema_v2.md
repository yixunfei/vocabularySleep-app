# ADR-070: 每日决策吃什么 v2 菜谱数据库分层

## 状态
已接受

## 背景
当前「吃什么」菜谱库已经达到 7000 条以上，后续还会继续扩展。v1 SQLite 只有摘要、详情和通用 term index 三层，Flutter 侧仍会加载全量摘要再在内存中构建筛选索引。管理页、编辑保存、随机候选和高级筛选因此容易出现卡顿，也难以支持更细的菜谱集管理和精确食材匹配。

## 决策
采用 v2 分层 schema：
1. `daily_choice_recipe_sets` 管理内置 cook、本地书籍、用户集合和扩展包。
2. `daily_choice_recipes` 保存最小基础索引字段，包含 `sort_key`、`random_key`、状态和可用标记。
3. `daily_choice_recipe_summaries` 与 `daily_choice_recipe_details` 分离，首屏与列表只读摘要。
4. `daily_choice_recipe_filter_index` 保存餐段、厨具、类型、contains、难度等低基数字段。
5. `daily_choice_recipe_ingredient_index` 独立保存 `raw`、`canonical`、`family` 三层食材 token，默认只用 raw/canonical，显式扩展才用 family。
6. 本地隐藏、收藏、集合和个人备注进入 overlay 表，不重写远端库。

## 备选方案
1. 继续沿用 v1 三表结构，只在 Dart 内存索引上优化。
   - 优点：改动小。
   - 缺点：无法根治全量摘要加载和筛选遍历，菜谱继续增长后仍会卡顿。
2. 全字段完全关系化，包括步骤、备注、详情全部拆表。
   - 优点：查询能力最强。
   - 缺点：写入和编辑复杂度过高，短期不利于稳定交付。
3. 直接引入 FTS5/倒排索引作为核心。
   - 优点：搜索强。
   - 缺点：设备 SQLite 编译选项存在不确定性，且随机和结构化筛选并不需要 FTS。

## 后果
- 正面：列表分页、筛选候选、食材精确匹配、随机 pivot 和用户集合都可走 SQLite 索引。
- 正面：详情按需读取，进入吃什么和管理页不再天然依赖全量详情。
- 正面：远端数据包和本地用户状态分离，隐藏/收藏/集合不会触发大表重写。
- 负面：生成器、安装器和 Flutter store 都需要迁移，短期实现量增加。
- 负面：筛选逻辑从 Dart 内存迁移到 SQL 后，需要补充查询层单测和 explain 级验证。
