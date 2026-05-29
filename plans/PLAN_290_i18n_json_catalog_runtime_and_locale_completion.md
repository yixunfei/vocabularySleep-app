# 计划 290: i18n JSON 文案表运行时接入与语言补全

## 基本信息
- **创建日期**: 2026-05-29
- **状态**: 已完成
- **负责人**: Codex

## 目标
将 `lib/l10n/catalog/app_texts_*.json` 接入项目运行时，使现有 `AppI18n.t(...)` 能优先读取集中 JSON 文案表，并在完成接入提交后，对 i18n 语言文本做一轮本地化补全，降低非中文语言回退到中文或 source 文本的比例。

## 详细步骤
1. 注册 `lib/l10n/catalog/` 为 Flutter assets。
2. 新增轻量 catalog 加载器，在启动阶段预加载 7 个语言 JSON。
3. 让 `AppI18n.t(...)` 优先查 JSON catalog，失败后回退现有内置 Map 与 humanize 行为，保持现有调用点兼容。
4. 增加最小单元测试覆盖 JSON catalog 注入、语言回退和占位符替换。
5. 更新 changelog，完成“JSON 接入”提交。
6. 基于现有 registry/语言表进行一轮语言内容补全，优先处理已有 `en/zh/source` 且其他语言缺失的集中表条目。
7. 再次验证 JSON 可解析与测试通过，更新 changelog 并提交“语言补全”。

## 风险评估
- **风险 1**: 运行时资产加载失败会影响所有 `AppI18n.t` 调用。
- **缓解措施**: JSON catalog 只作为优先层；加载失败或测试未加载时仍回退内置 Map。
- **风险 2**: 自动补全翻译可能包含不自然或上下文不精确的表达。
- **缓解措施**: 标记补全来源，并优先保留已有人工翻译；后续可逐模块人工校对。
- **风险 3**: 全量 JSON 体积较大，启动加载有成本。
- **缓解措施**: 本轮维持一次性加载以快速完成统一接入；后续可按语言懒加载或生成压缩资源。

## 依赖项
- 已存在 `lib/l10n/catalog/app_text_registry.json` 与 `app_texts_zh/en/ja/de/fr/es/ru.json`。
- 现有运行时本地化入口为 `lib/src/i18n/app_i18n.dart`。
