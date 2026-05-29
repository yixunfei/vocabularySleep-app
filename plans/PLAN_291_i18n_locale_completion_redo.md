# 计划 291: i18n 本地化补全返工

## 基本信息
- **创建日期**: 2026-05-29
- **状态**: 已完成
- **负责人**: Codex

## 目标
在已接入 JSON catalog 运行时的基础上，重新完成一轮语言文本补全。该轮补全不引用历史提交中的翻译结果，不复用旧脚本，并对远程翻译后端先做独立样本验证；补全结果需要覆盖真实运行时和显式 UI 文本，同时避免把技术字符串、路径、枚举、SQL、日志或源代码候选误当成用户文案。

## 详细步骤
1. 确认当前卡住的翻译流程是否仍在运行，停止异常残留进程。
2. 重新统计 catalog 中真实 UI/runtime 文案缺口，区分 `existing_app_i18n_key`、`existing_arb_key`、`inline_pick_ui_text`、`i18n_runtime_reference` 与非运行时候选字符串。
3. 独立验证可用翻译后端的短 UI、长句与占位符表现；不合格后端不得进入主流程。
4. 新增可恢复补全脚本：保护占位符、批量翻译、缓存结果、失败记录、校验目标语言仍为英文回退的条目。
5. 回填 `app_texts_*.json` 与 registry 的本轮补全元信息，保留技术候选池的审计状态。
6. 输出补全报告，验证 JSON 可解析、占位符一致、真实 UI/runtime 缺口减少。
7. 更新 changelog，运行 i18n 相关测试并提交。

## 风险评估
- **风险 1**: 远程翻译服务可能临时不可用或返回不稳定结果。
- **缓解措施**: 先做代表性样本验证；主脚本使用批次缓存、超时、失败报告和占位符校验，失败条目不伪装为完成。
- **风险 2**: 早期 registry 抽取存在多分支文案拼接或缺失标记不完整。
- **缓解措施**: 同时检查 `missingLocales` 与 locale JSON 中的英文回退；对无干净英文源的条目标记审计，必要时回看源文件。
- **风险 3**: 非 UI 候选字符串数量巨大，盲目翻译会污染资源表。
- **缓解措施**: 本轮只补运行时或显式 UI 文案；`dart_string_literal_candidate` 和 `platform_metadata_string` 保持集中登记，不纳入自动补全。

## 依赖项
- 当前 JSON catalog: `lib/l10n/catalog/app_text_registry.json`
- 当前语言表: `lib/l10n/catalog/app_texts_*.json`
- 已验证可用但需防护的远程后端: `translators` 包的 Bing 翻译入口

## 完成记录
- 停止使用旧脚本和历史翻译库；重新设计 `scripts/redo_i18n_locale_completion.py`，按当前 catalog 重新补齐 zh/ja/de/fr/es/ru。
- 对真实运行时与显式 UI 文案完成补全，同步 `app_texts_*.json` 与 registry 文本摘要。
- 空英文源 ARB 资源不再计入待翻译缺口，避免把非当前英文源资源误报为 runtime/UI 缺失。
- 对同形品牌、单位、音乐术语、格式串和中文双语分支占位符做显式校验与保留。

## 验证结果
- `collect_jobs(..., include_zh=True, force_runtime=False)`: 0。
- `audit(...).unresolvedCount`: 0。
- JSON 解析覆盖 `app_text_registry.json` 与 7 个 `app_texts_*.json`: 通过。
- 非空英文源占位符兼容校验: 0 个不一致。
