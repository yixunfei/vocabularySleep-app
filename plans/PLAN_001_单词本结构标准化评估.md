# 计划 001: 单词本结构标准化评估

## 基本信息
- **创建日期**: 2026-04-09
- **状态**: 计划中
- **负责人**: Codex

## 目标
基于当前 `wordbooks/` 示例词本、导入逻辑、SQL 存储和展示链路，梳理一套统一的单词本标准格式，并评估彻底调整结构时对分析、存储、检索、展示和迁移的风险，给出建议的分阶段落地方案。

## 现状结论

### 1. 当前存在两类主格式，且结构不兼容
- A 类词本：顶层是数组，词条字段以 `word/content/meaning/examples/etymology/roots/affixes` 为主。
- B 类词本：顶层是对象，含 `元数据` 与 `词条列表`，词条字段以 `目标单词/中文释义/音标/发音标注/词性分类/场景化例句/...` 为主。
- 当前导入器通过“别名 + 自动猜测”兼容两类格式，但没有真正的统一 schema。

### 2. 导入层是“宽松兼容”，不是“标准化落库”
- [`lib/src/services/wordbook_import_service.dart`](D:\workspace\vocabularySleep-app\lib\src\services\wordbook_import_service.dart) 会尝试识别多种字段名，并把 `音标/发音标注`、`场景化例句` 等嵌套结构直接压平成文本。
- `content` 中的 Markdown 段落也会再次被解析成字段，和原始字段合并。
- 字段合并规则当前是“同 key 后值覆盖前值”，不是保留多来源结构，也不是按置信度选择。

### 3. 当前最关键的问题不是“字段少”，而是“语义冲突和信息丢失”
- [`lib/src/models/word_field.dart`](D:\workspace\vocabularySleep-app\lib\src\models\word_field.dart) 中别名映射把多个不同语义字段压成同一个 legacy key。
- 例如：
  - `词根溯源` 被映射到 `etymology`
  - `发展历史与文化背景` 也被映射到 `etymology`
  - `场景化例句` 被映射到 `examples`
- 在 `mergeFieldItems()` 中，同 key 字段最终以后者覆盖前者，导致真实数据被吞掉。

### 4. SQL 当前是“新旧混存”
- [`lib/src/services/database_service.dart`](D:\workspace\vocabularySleep-app\lib\src\services\database_service.dart) 已有较新的 `word_fields / word_field_tags / word_field_media` 结构。
- 但 `words` 表仍保留 `meaning`、`extension_json`、`entry_json` 等兼容缓存职责。
- `entry_json` 目前主要只保存 `rawContent` 恢复信息，不再是真正完整的结构化原始词条。
- 这意味着数据库现在同时承担：
  - 搜索摘要缓存
  - 兼容旧字段
  - 新字段展示
  - 原始内容兜底恢复
- 职责边界已经模糊。

### 5. 展示层存在“非核心字段显示不完整”的表象
- [`lib/src/ui/widgets/word_card.dart`](D:\workspace\vocabularySleep-app\lib\src\ui\widgets\word_card.dart) 卡片模式只展示 `meaning`、`examples` 和最多 2~4 个附加字段。
- 详情页 [`lib/src/ui/pages/word_detail_page.dart`](D:\workspace\vocabularySleep-app\lib\src\ui\pages\word_detail_page.dart) 会展示全部字段，但前提是这些字段已正确导入和落库。
- 所以“非核心字段未完全展示”有两层原因：
  - UI 卡片刻意截断展示
  - 更严重的是导入与合并阶段已发生字段覆盖/压扁/丢失

## 根因分析

### 根因 1：没有单词本文件级标准
- 当前项目接受“任何长得像 JSON 的词条集合”。
- 这适合快速导入，不适合长期维护、校验和多语言扩展。

### 根因 2：领域模型仍带有强 legacy 痕迹
- `meaning/examples/etymology/roots/affixes/...` 仍然被当作主干字段。
- 其他字段被视为“扩展字段”，导致英文词本中 `音标`、`词性`、`搭配`、`易混淆点` 等数据天然处于次级地位。

### 根因 3：字段标准化规则过于激进
- 同义字段没有分层归一，而是直接压到同一 key。
- 多来源内容没有 source/priority/version。
- 嵌套结构被序列化成纯文本后，后续无法准确重建。

### 根因 4：SQL 层缺少“标准导入 DTO”和“原始源数据留存”
- 数据库里存的是展示态字段，不是稳定领域态。
- 一旦字段映射规则改错，后续很难无损回放重建。

## 建议的标准词本格式

## 顶层结构
```json
{
  "schema_version": "wordbook.v1",
  "book": {
    "id": "zh-en-12000-basic",
    "name": "中文-英语 12000",
    "source_language": "zh-Hans",
    "target_language": "en",
    "direction": "source_to_target",
    "entry_count": 12000,
    "created_at": "2026-03-13",
    "sources": [
      "Kaikki / English Wiktionary",
      "Open English WordNet 2025"
    ],
    "tags": ["builtin", "frequency", "general"],
    "description": "基础高频词本",
    "extra": {}
  },
  "entries": []
}
```

## 词条结构
```json
{
  "entry_id": "zh-en-the",
  "lemma": {
    "text": "the",
    "normalized": "the",
    "language": "en",
    "script": "Latn"
  },
  "glosses": [
    {
      "lang": "zh-Hans",
      "text": "定冠词",
      "type": "primary"
    }
  ],
  "pronunciations": [
    {
      "locale": "en-GB",
      "ipa": "/ðə/",
      "note": "weak form before consonants",
      "audio": ""
    },
    {
      "locale": "en-US",
      "ipa": "/ðə/",
      "note": "weak form before vowels",
      "audio": ""
    }
  ],
  "parts_of_speech": ["article", "adverb", "preposition", "pronoun"],
  "examples": [
    {
      "category": "daily",
      "source_text": "I’m reading the book Mary reviewed.",
      "translation": "我正在读 Mary 评论过的那本书。"
    }
  ],
  "collocations": [
    "reading the book",
    "go to the office"
  ],
  "morphology": [
    {
      "type": "spelling_variant",
      "value": "ye"
    }
  ],
  "notes": {
    "etymology": "From Middle English...",
    "roots": "",
    "affixes": "",
    "usage": "",
    "confusions": "",
    "memory": "",
    "culture": "",
    "story": ""
  },
  "tags": [],
  "media": [],
  "source": {
    "provider": "kaikki",
    "license": "",
    "record_hash": ""
  },
  "extra": {}
}
```

## 标准格式设计原则
- **词本元数据和词条数据分离**：词本级信息不得混入词条数组。
- **字段语义稳定**：`etymology`、`roots`、`culture`、`story` 等不得再互相吞并。
- **结构优先，不先压平文本**：音标、例句、词形变化、媒体等保持对象数组。
- **保留 `extra` 扩展槽**：未知字段先挂入 `extra`，而不是直接丢弃。
- **保留原始来源信息**：为将来重新清洗、回放迁移留通道。

## 当前示例词本到标准格式的映射建议

### A 类数组词本
- `word` -> `lemma.text`
- `meaning` -> `glosses[].text`
- `examples[]` -> `examples[]`
- `etymology` -> `notes.etymology`
- `roots` -> `notes.roots`
- `affixes` -> `notes.affixes`
- `content` -> `source.raw_content` 或导入期辅助恢复字段，不再作为主展示字段

### B 类对象词本
- `元数据` -> `book`
- `词条列表` -> `entries`
- `目标单词` -> `lemma.text`
- `中文释义` -> `glosses`
- `音标/发音标注` -> `pronunciations`
- `词性分类` -> `parts_of_speech`
- `常见搭配组词` -> `collocations`
- `场景化例句` -> `examples`
- `词根溯源` -> `notes.etymology`
- `词缀分析` -> `notes.affixes`
- `形态变形` -> `morphology`
- `记忆辅助策略` -> `notes.memory`
- `易混淆点辨析` -> `notes.confusions`
- `发展历史与文化背景` -> `notes.culture`
- `趣味文化小故事` -> `notes.story`

## SQL 存储建议

### 推荐方向：保留当前“词条主表 + 字段明细表”的大框架，但重建职责边界

#### 推荐表职责
- `wordbooks`
  - 词本基础信息
  - 新增 `schema_version`
  - 新增 `metadata_json`
- `words`
  - 词条主索引
  - 保留 `wordbook_id / lemma / normalized_search / primary_meaning / source_payload_json`
  - 只保存用于检索与主列表展示的摘要字段
- `word_fields`
  - 保存展示字段，但 field key 必须来自标准集合或扩展命名空间
- `word_field_media / word_field_tags`
  - 保留

#### 建议新增或调整字段
- `wordbooks.metadata_json`
- `words.entry_uid`
- `words.source_payload_json`
- `words.primary_gloss`
- `words.sort_index`
- `words.schema_version`

### 不建议的方案
- 一次性把所有内容拆成十几个强关系表，例如 `entry_examples`、`entry_pronunciations`、`entry_morphology`、`entry_etymology` 等全部独立。
- 原因：
  - 当前项目已有 `word_fields` 体系，可复用。
  - 一步拆太细会显著放大迁移、搜索、编辑器、导入器、导出器和测试成本。
  - 在业务尚未稳定前，过度关系化会降低迭代速度。

## 建议的分阶段方案

### 阶段 1：先定义“标准导入 DTO”
1. 新增 `WordbookSchemaV1`、`WordbookEntryV1` 领域模型。
2. 所有 JSON 文件先转换到 DTO，再决定如何入库。
3. 导入时必须输出校验结果：
   - 缺少主词
   - 重复字段
   - 语义冲突字段
   - 未识别字段

### 阶段 2：保留旧库结构，先让导入无损
1. `word_fields` 继续作为展示字段承载层。
2. 新增 `source_payload_json` 保存标准化后整条词条。
3. `content/rawContent` 不再作为主数据源，只作兼容恢复。

### 阶段 3：调整 UI 渲染规则
1. 卡片页继续保持摘要展示，但应明确“仅预览”。
2. 详情页必须完整按字段组展示。
3. 字段分组建议：
   - 核心：释义、音标、词性
   - 用法：例句、搭配、易混淆点
   - 语言学：词源、词根、词缀、形态
   - 记忆：记忆法、文化背景、故事

### 阶段 4：最后再清理 legacy
1. 等新导入、新编辑、新展示全部稳定后，再考虑废弃 `meaning/rawContent/entry_json` 的兼容职责。
2. 清理前必须先做数据库备份和全量迁移验证。

## 风险评估

### 风险 1：分析层风险
- **表现**: 旧字段映射规则改变后，历史导入逻辑与当前 UI 假设不一致。
- **影响**: 搜索结果、词条摘要、详情页顺序、编辑器字段回填都可能变化。
- **等级**: 高
- **缓解措施**:
  - 先引入标准 DTO，不直接改 UI
  - 对旧样例词本跑字段映射审计
  - 输出迁移前后字段对比报告

### 风险 2：SQL 迁移风险
- **表现**: 当前库是兼容态，若直接删旧列或改主表职责，容易出现数据无法恢复。
- **影响**: 已导入词本、收藏词、任务词、学习记录关联异常。
- **等级**: 高
- **缓解措施**:
  - 迁移前自动备份数据库
  - 新增列优先，旧列延迟删除
  - 提供幂等迁移脚本和回滚路径

### 风险 3：逻辑关联风险
- **表现**: `AppState`、搜索、收藏、任务词、详情页、编辑页都依赖 `WordEntry` 现有结构。
- **影响**: 词条能显示但不能编辑，能搜索但字段为空，或者收藏项指向错误摘要。
- **等级**: 高
- **缓解措施**:
  - `WordEntry` 增加新字段时先兼容旧 getter
  - 优先保持 `id / wordbookId / word / primaryMeaning` 稳定
  - 先迁移读取链路，再迁移写入链路

### 风险 4：展示层风险
- **表现**: 新字段变多后，移动端详情页可能过长，卡片可能信息噪音过大。
- **影响**: 移动端阅读体验变差。
- **等级**: 中
- **缓解措施**:
  - 摘要页只展示核心字段
  - 详情页分组折叠
  - 保持一屏内核心信息优先

### 风险 5：历史词本兼容风险
- **表现**: 当前 `wordbooks/` 中不同来源词本字段差异极大，无法一次性全自动无损映射。
- **影响**: 个别词本迁移后字段缺失或错位。
- **等级**: 高
- **缓解措施**:
  - 按词本类型分批迁移
  - 先支持 A 类和 B 类两套正式映射器
  - 未识别字段统一进入 `extra`

## 综合判断
- **如果“彻底重写文件格式 + 彻底重写 SQL + 彻底重写展示模型”一次性同时做，风险很高。**
- **如果“先统一文件标准和导入 DTO，再渐进收敛 SQL 与 UI”，风险可控且收益最大。**

## 建议结论
1. 先把“单词本标准格式”定为 `wordbook.v1`，统一词本顶层和词条字段语义。
2. 先重做导入标准化，不立即推翻现有 `word_fields` 数据表。
3. 短期内保留兼容字段，但停止继续扩大 legacy 映射范围。
4. 中期引入 `metadata_json` 与 `source_payload_json`，保证迁移可回放、可审计。
5. 只有在新格式稳定跑完一轮真实词本后，才开始删除旧缓存字段和旧映射逻辑。

## 依赖项
- 需要补充词本 schema 校验器
- 需要补充迁移前后词条 diff 工具
- 需要补充标准格式样例文件
- 需要补充数据库迁移测试与 UI 回归测试
