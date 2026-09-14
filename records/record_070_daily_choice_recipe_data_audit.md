# 记录 070: 每日决策吃什么菜谱数据源审计

## 基本信息
- **生成时间**: 2026-09-14T15:06:41.366593+00:00
- **菜谱总数**: 7051
- **摘要总数**: 7051
- **cook recipe.csv 行数**: 599
- **SQLite 摘要行数**: 7051

## 关键结论
1. `YunYouJun/cook` 尚未完整作为默认 cook 数据来源导入：recipe.csv 共 599 行，当前库标题精确命中 30 行，未命中 569 行。
2. 素食/纯素字段存在高风险冲突：`vegetarian` 与肉类/海鲜冲突 0 条，`vegan_friendly` 与动物性食材冲突 0 条。
3. 菜系信息当前混在 notes 中且缺少可信度边界：含菜系标签 notes 共 0 条，其中西式/非中式标记却带中式菜系 notes 的高疑似错配 0 条。
4. `清真友好` 说明被写入菜谱 notes 0 条，属于 UI/规则说明污染菜谱正文。
5. 食材别名存在过宽匹配：`洋葱` 额外索引为 `葱` 0 条；排骨/猪油等具体猪肉项仍折叠到粗粒度猪肉 0 条。

## 数据源覆盖
- cook CSV 缺失样例: 电饭煲版广式腊肠煲饭, 电饭煲版烧鸡, 电饭煲焖面, 电饭煲版番茄牛腩焖饭, 电饭煲版蜜汁鸡翅, 电饭煲版南瓜鸡腿焖饭, 电饭煲版土豆排骨焖饭, 电饭煲版香菇腊肠焖饭
- 0 提取书籍数: 8
- 摘要行 sourceLabel/sourceUrl: 0
- 摘要行 references: 0

## 问题桶

## 初步修正建议
1. 数据生成阶段不要再写入 `halal_friendly`、`vegan_friendly`、`vegetarian_friendly` 这类高语义饮食友好字段，UI 也不再提供对应辅助筛选。
2. 肉类判断不要只依赖 canonical ingredient；`contains` 与 `profile` 应来自同一套原始材料风险词表，并覆盖兔、龟、鸽、牡蛎等当前漏建模动物食材。
3. 菜系不再写入 notes。若源资料明确给出菜系，后续迁移到 `recipe_filter_index(group=cuisine, confidence=source)`；无明确来源则留空。
4. 食材索引拆成 `raw_ingredient`、`canonical_ingredient`、`family_ingredient` 三层，默认匹配 raw/canonical，只有用户显式扩展时才用 family。
5. 对缺少自包含步骤的数据源只做元数据参考或候选清单，不再生成通用模板步骤；后续若能补齐真实步骤，再分批进入随机库。
