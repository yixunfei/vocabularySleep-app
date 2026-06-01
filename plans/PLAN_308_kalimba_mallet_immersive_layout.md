# 计划 308: 拇指琴与敲击键盘乐器沉浸布局

## 基本信息
- **创建日期**: 2026-06-01
- **状态**: 已完成
- **负责人**: Codex

## 目标
修复模拟乐器中拇指琴窄屏按键拥挤和琴齿越界问题，并将排钟扩展为以木琴为默认主体的敲击键盘乐器族。两个模块都需要在手机窄屏和沉浸式全屏下使用 90 度横向舞台，提升触控面积并保留 FluidR3Mono_GM 采样音源优先路径。

## 详细步骤
1. 检查当前 git 状态；若存在未提交修改，先提交保护现场。
2. 调整拇指琴舞台：
   - 窄屏与全屏使用旋转 90 度的横向琴齿布局。
   - 修正琴齿固定点、琴面承托层与边界，避免琴齿露出琴面。
   - 全屏仅常驻一个设置入口，设置通过底部面板唤起。
3. 调整排钟为敲击键盘乐器族：
   - 默认类型改为木琴，并提供排钟、木琴、颤音琴、马林巴、刚片琴等类型。
   - 不同类型使用不同 GM patch、音域和键数。
   - 增加共鸣管材质与腔体设置，影响视觉材质、尾音和混响参数。
   - 舞台默认呈现儿童 12 音彩虹木琴样式，窄屏和全屏使用 90 度横向布局。
4. 更新 SoundFont patch catalog 与 `assets/toolbox/instruments/instrument_banks.json`。
5. 更新 `lib/l10n/catalog/app_texts.csv` 与 `app_text_registry.json`，确保新增 UI 文案通过 `AppI18n.t(...)` 管理。
6. 运行分析、相关测试和 i18n 必跑检查。
7. 更新本计划状态与 `changelogs/CHANGELOG.md`，记录验证结果和剩余风险。

## 风险评估
- **风险 1**: 全屏方向锁定影响其他乐器返回后的方向状态。
  - **缓解措施**: 复用现有 toolbox 沉浸式进入/退出函数，并只调整目标乐器方向偏好。
- **风险 2**: 新增 GM patch 与 channel 配置可能影响已有排钟采样。
  - **缓解措施**: 保持原排钟 patch 常量，新增木琴族 patch 并补测试。
- **风险 3**: i18n catalog 新增 key 较多，容易出现 registry 或占位符不一致。
  - **缓解措施**: 使用脚本做 registry 同步，并运行 placeholder audit、维护报告和旧 helper 扫描。
- **风险 4**: 真机手势可能被父级滚动抢走。
  - **缓解措施**: 保留 `_ToolboxScrollLockSurface`，舞台命中区域显式处理 pointer down/move/up。

## 依赖项
- `lib/src/ui/pages/toolbox_sound_tools/kalimba.dart`
- `lib/src/ui/pages/toolbox_sound_tools/chimes.dart`
- `lib/src/services/toolbox_instrument_engine.dart`
- `assets/toolbox/instruments/instrument_banks.json`
- `lib/l10n/catalog/app_texts.csv`
- `lib/l10n/catalog/app_text_registry.json`

## 完成记录
- 拇指琴窄屏和全屏已改为 90 度横向琴齿舞台，全屏只常驻设置按钮；普通宽屏琴齿改用内缩可用宽度，避免边缘琴齿露出琴面。
- 排钟已扩展为敲击键盘乐器族，默认木琴，支持排钟、颤音琴、马林巴、钢片琴，并支持共鸣管材质和腔体设置。
- SoundFont catalog 新增 `gm_xylophone`、`gm_vibraphone`、`gm_marimba`、`gm_glockenspiel`，继续优先使用 `FluidR3Mono_GM.sf3` 采样。
- i18n catalog 新增 key 40 个，退休 key 0 个；`app_text_registry.json` 已同步。
- `node scripts/maintain_i18n_catalog.js --limit 20` 结果：catalogKeys 49670，registryEntries 48158，duplicateCsvKeys 0，duplicateRegistryIds 0，missingLocaleColumns 0；历史 staleRegistrySources 123 和 unreferencedCatalogKeys 39591 不在本轮处理。
- 明确不处理项：全量 `flutter analyze` 中既有 DailyChoice guide 测试 getter 缺失错误；历史 i18n stale source 与未引用 key 清理。

## 验证记录
- `flutter analyze lib/src/ui/pages/toolbox_sound_tools.dart lib/src/services/toolbox_instrument_engine.dart test/toolbox_instrument_engine_test.dart` 通过。
- `flutter test test/toolbox_instrument_engine_test.dart` 通过。
- `flutter test test/app_i18n_catalog_test.dart` 通过。
- `node scripts/audit_i18n_placeholders.js` 通过。
- `node scripts/maintain_i18n_catalog.js --limit 20` 通过。
- `rg -n "pickUiText|lookupBySourcePair|source-pair|_lifeText|_lifeCatalogPairText|_uiText|pickSleepText" lib test --glob "*.dart"` 无命中。
- `rg -n "\$\{|\\$[A-Za-z_][A-Za-z0-9_]*" lib/l10n/catalog/app_texts.csv` 无命中。
- `git diff --check` 通过，仅提示 `app_texts.csv` 受当前 Windows Git 配置影响后续可能 LF/CRLF 转换。
