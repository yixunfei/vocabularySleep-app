# 单词本标准规范

## 文档信息
- **文档版本**: v1.0.0
- **发布日期**: 2026-04-09
- **适用范围**: 项目内所有新建、转换、导入、导出的标准化单词本
- **标准代号**: `wordbook.v1`

---

## 1. 目标

本规范用于统一项目中的单词本文件结构，解决以下问题：

- 单词本顶层结构不一致
- 字段命名混乱，语义重叠
- 嵌套字段被压平成文本，后续无法准确重建
- 导入后字段丢失、覆盖、错位
- SQL 存储与展示层难以稳定映射

本规范优先保证：

1. **语义稳定**
2. **可校验**
3. **可批量处理**
4. **可无损迁移**
5. **便于后续代码接入**

---

## 2. 标准总览

所有标准化单词本必须采用以下顶层结构：

```json
{
  "schema_version": "wordbook.v1",
  "book": {},
  "entries": []
}
```

### 顶层字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `schema_version` | string | 是 | 固定值为 `wordbook.v1` |
| `book` | object | 是 | 词本元数据 |
| `entries` | array | 是 | 词条数组 |

---

## 3. 词本元数据 `book`

### 标准结构

```json
{
  "id": "zh-en-12000-basic",
  "name": "中文-英语 12000",
  "source_language": "zh-Hans",
  "target_language": "en",
  "direction": "source_to_target",
  "entry_count": 12000,
  "created_at": "2026-03-13",
  "updated_at": "2026-04-09",
  "sources": [
    "Kaikki / English Wiktionary",
    "Open English WordNet 2025"
  ],
  "tags": [
    "builtin",
    "frequency",
    "general"
  ],
  "description": "基础高频词本",
  "license": "",
  "extra": {}
}
```

### 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 词本唯一标识，推荐使用 kebab-case |
| `name` | string | 是 | 词本展示名称 |
| `source_language` | string | 是 | 源语言，推荐 BCP-47，如 `zh-Hans` |
| `target_language` | string | 是 | 目标语言，推荐 BCP-47，如 `en`、`ja` |
| `direction` | string | 是 | 枚举值：`source_to_target` / `target_to_source` / `bidirectional` |
| `entry_count` | integer | 是 | 词条数量，需与 `entries.length` 一致 |
| `created_at` | string | 否 | 词本生成日期，格式 `YYYY-MM-DD` |
| `updated_at` | string | 否 | 最近更新时间，格式 `YYYY-MM-DD` |
| `sources` | array[string] | 否 | 数据来源列表 |
| `tags` | array[string] | 否 | 词本标签 |
| `description` | string | 否 | 词本说明 |
| `license` | string | 否 | 许可说明 |
| `extra` | object | 否 | 规范未覆盖的词本级扩展字段 |

### 约束

- `book.id` 在同一项目内必须唯一。
- `entry_count` 必须等于 `entries` 实际词条数量。
- `extra` 中不得覆盖标准字段名。

---

## 4. 词条 `entries`

每个词条必须是一个对象，推荐结构如下：

```json
{
  "entry_id": "zh-en-the",
  "lemma": {},
  "glosses": [],
  "pronunciations": [],
  "parts_of_speech": [],
  "examples": [],
  "collocations": [],
  "morphology": [],
  "notes": {},
  "tags": [],
  "media": [],
  "source": {},
  "extra": {}
}
```

---

## 5. 词条核心字段

### 5.1 `entry_id`

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `entry_id` | string | 是 | 词条唯一标识，建议 `词本id-主词` 或稳定 hash |

约束：

- 在同一本词本内必须唯一。
- 不建议依赖数组位置生成，避免后续重排时失效。

### 5.2 `lemma`

```json
{
  "text": "the",
  "normalized": "the",
  "language": "en",
  "script": "Latn"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `text` | string | 是 | 词条主词面 |
| `normalized` | string | 否 | 归一化文本，用于检索或去重 |
| `language` | string | 是 | 主词语言 |
| `script` | string | 否 | 书写系统，如 `Latn`、`Hans`、`Jpan` |

约束：

- `lemma.text` 不能为空。
- `lemma.normalized` 推荐与检索逻辑一致，但不能替代 `text`。

### 5.3 `glosses`

```json
[
  {
    "lang": "zh-Hans",
    "text": "定冠词",
    "type": "primary"
  }
]
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `glosses` | array | 是 | 释义数组，至少 1 条 |
| `lang` | string | 是 | 释义语言 |
| `text` | string | 是 | 释义正文 |
| `type` | string | 否 | 枚举建议：`primary` / `secondary` / `literal` / `note` |

约束：

- 不再使用顶层 `meaning` 作为标准字段。
- 多个释义必须保留为数组，不得强行合并成单行字符串。

---

## 6. 结构化扩展字段

### 6.1 `pronunciations`

```json
[
  {
    "locale": "en-GB",
    "ipa": "/ðə/",
    "note": "weak form before consonants",
    "audio": ""
  }
]
```

### 6.2 `parts_of_speech`

```json
["article", "adverb"]
```

### 6.3 `examples`

```json
[
  {
    "category": "daily",
    "source_text": "I’m reading the book Mary reviewed.",
    "translation": "我正在读 Mary 评论过的那本书。"
  }
]
```

### 6.4 `collocations`

```json
[
  "reading the book",
  "go to the office"
]
```

### 6.5 `morphology`

```json
[
  {
    "type": "spelling_variant",
    "value": "ye"
  }
]
```

---

## 7. 说明性字段 `notes`

`notes` 用于承载结构相对稳定、但不适合继续拆成复杂表结构的说明内容。

```json
{
  "etymology": "From Middle English...",
  "roots": "",
  "affixes": "",
  "usage": "",
  "confusions": "",
  "memory": "",
  "culture": "",
  "story": ""
}
```

### `notes` 子字段定义

| 字段 | 说明 |
|------|------|
| `etymology` | 词源、演变路径 |
| `roots` | 词根或词根分析 |
| `affixes` | 词缀、前后缀分析 |
| `usage` | 用法说明、语体限制、语境提示 |
| `confusions` | 易混词、辨析项 |
| `memory` | 记忆辅助、记忆法 |
| `culture` | 文化背景、历史背景 |
| `story` | 小故事、趣味补充 |

### 关键约束

- `etymology` 与 `culture` 不得合并。
- `roots` 与 `etymology` 不得互相覆盖。
- `story` 仅承载附加故事，不得承载主释义。

---

## 8. 附加字段

### 8.1 `tags`

```json
["common", "formal"]
```

### 8.2 `media`

```json
[
  {
    "type": "audio",
    "source": "https://example.com/audio/the.mp3",
    "label": "US pronunciation",
    "mime_type": "audio/mpeg"
  }
]
```

### 8.3 `source`

```json
{
  "provider": "kaikki",
  "license": "",
  "record_hash": "",
  "raw_ref": ""
}
```

### 8.4 `extra`

```json
{
  "original_fields": {
    "旧字段名": "旧值"
  }
}
```

规则：

- 无法稳定归类的历史字段先进入 `extra`。
- `extra` 只作为兜底，不作为主业务字段。
- 同一来源中反复出现的字段，若已具备稳定语义，应升级为正式标准字段，而不是长期停留在 `extra`。

---

## 9. 命名规则

### 顶层与词条字段

- 使用 `snake_case`
- 使用英文 key
- 枚举值使用小写英文

### 示例

| 正确 | 错误 |
|------|------|
| `source_language` | `sourceLanguage` |
| `parts_of_speech` | `词性分类` |
| `entry_id` | `id` |
| `source_text` | `例句原文` |

---

## 10. 禁止事项

- 不允许把词本元数据直接放进词条数组第一项。
- 不允许混用中文 key 和英文 key。
- 不允许继续以 `content` 作为主结构字段承载全部内容。
- 不允许把结构化数组压成多行字符串作为长期标准。
- 不允许将多个不同语义字段合并到同一个标准 key。
- 不允许省略 `schema_version`。

---

## 11. 旧词本到标准格式的映射建议

### 11.1 A 类数组旧格式

旧格式：

```json
{
  "word": "あなた",
  "content": "...",
  "meaning": "...",
  "examples": [],
  "etymology": "...",
  "roots": "...",
  "affixes": "..."
}
```

映射建议：

- `word` -> `lemma.text`
- `meaning` -> `glosses[].text`
- `examples` -> `examples`
- `etymology` -> `notes.etymology`
- `roots` -> `notes.roots`
- `affixes` -> `notes.affixes`
- `content` -> `extra.original_content`

### 11.2 B 类对象旧格式

旧格式：

```json
{
  "目标单词": "the",
  "中文释义": "定冠词",
  "音标/发音标注": {},
  "词性分类": [],
  "常见搭配组词": [],
  "场景化例句": [],
  "词根溯源": "...",
  "词缀分析": "...",
  "形态变形": [],
  "记忆辅助策略": "...",
  "易混淆点辨析": "...",
  "发展历史与文化背景": "...",
  "趣味文化小故事": "..."
}
```

映射建议：

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

---

## 12. 校验清单

在生成新的标准化单词本前，应至少检查以下内容：

### 文件级校验

- `schema_version == "wordbook.v1"`
- `book.id` 非空且唯一
- `entries` 为数组
- `book.entry_count == entries.length`

### 词条级校验

- `entry_id` 非空且唯一
- `lemma.text` 非空
- `glosses` 至少 1 条
- `glosses[].text` 非空
- 所有 key 使用英文 `snake_case`

### 语义校验

- `culture` 未错误落入 `etymology`
- `roots` 未错误落入 `etymology`
- `examples` 保持为结构化数组
- `pronunciations` 未被压成纯文本

---

## 13. 推荐落地流程

1. 先把旧词本转换成标准 `wordbook.v1`。
2. 对转换结果跑校验清单。
3. 抽样人工复核：
   - 高频词
   - 多义词
   - 长例句词
   - 字段丰富词
4. 确认无明显字段吞并后，再导入项目。
5. 待一批标准词本稳定后，再进行代码层改造。

---

## 14. 相关文件

- 标准模板: [wordbook.v1.template.json](D:\workspace\vocabularySleep-app\docs\wordbooks\templates\wordbook.v1.template.json)
- 最小示例: [wordbook.v1.example.json](D:\workspace\vocabularySleep-app\docs\wordbooks\examples\wordbook.v1.example.json)
- 评估计划: [PLAN_001_单词本结构标准化评估.md](D:\workspace\vocabularySleep-app\plans\PLAN_001_单词本结构标准化评估.md)
