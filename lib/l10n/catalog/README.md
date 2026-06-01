# i18n 文案集中目录

本目录是全量文案管理基线。运行时文案以单表 CSV 为主数据源，方便人工横向查看、筛选和批量修改。

- `app_texts.csv`: 主文案表。每行一个稳定 key，每种语言一列，列顺序为 `key,zh,en,ja,de,fr,es,ru`。
- `app_text_registry.json`: 机器可读总账，包含来源文件、行号、文本类型、建议 key、缺失语言和占位符；仅作为审计元数据，不作为人工维护入口。
- `app_text_retirements.json`: 待移除 key 的软删除清单。功能开发中先登记退休意图，定期整理时再由脚本确认无引用后删除。

修改文案时优先编辑 `app_texts.csv`。新增 key 时必须同步补齐七语言列，并在需要追踪来源时更新 `app_text_registry.json`。代码中仍只使用稳定 key 与 params，不使用源文本反查。

日常开发采用 append-only 优先，不在功能切片中顺手大规模删除旧 key。每次触达 i18n 后运行：

```powershell
node scripts/audit_i18n_placeholders.js
node scripts/maintain_i18n_catalog.js --limit 20
```

`maintain_i18n_catalog.js` 默认只读报告；真正删除退休 key 时需显式执行 `node scripts/maintain_i18n_catalog.js --apply-retirements`，且只会处理已无 `lib/test` 引用的清单项。
