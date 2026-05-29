# i18n 文案集中目录

本目录是 2026-05-29 建立的全量文案管理基线，当前只新增资源与清单，不修改运行时代码。

- `app_text_registry.json`: 机器可读总账，包含来源文件、行号、文本类型、建议 key、缺失语言和占位符。
- `app_texts_*.json`: 按语言拆分的平铺文案表，方便批量替换、翻译和差异审查。缺失语言当前按 en/zh/source 回退，真实缺口以 registry 的 `missingLocales` 为准。

后续接入代码时，优先按 `existing_app_i18n_key` 复用已有 key；`inline_pick_ui_text` 可逐页迁移到 `AppI18n.t`；`dart_string_literal_candidate` 需要先确认是否真为用户可见文本。
