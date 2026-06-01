# 计划 309: 敲击键盘命中区与共鸣体验修复

## 基本信息
- **创建日期**: 2026-06-01
- **状态**: 已完成
- **负责人**: Codex

## 目标
修复木琴与排钟等敲击键盘乐器中视觉琴键和真实触摸命中区不一致的问题，放宽手机与普通舞台的高度约束，并让共鸣管材质、腔体设置更明显；对不适合共鸣管控制的乐器隐藏相关设置，避免用户误以为所有类型都有同等结构。

## 详细步骤
1. 对齐舞台绘制和触摸命中的几何参数，确保窄屏 90 度布局和宽屏横向布局都以同一可用区域切分音键。
2. 根据当前乐器键数动态计算普通舞台高度，避免 12 到 16 键乐器在手机端和宽屏端过于紧密。
3. 为乐器类型增加共鸣控制支持标记，只在木琴、排钟、颤音琴、马林巴等具备明确共鸣结构的类型中显示材质和腔体设置。
4. 强化材质和腔体对尾音、混响、音量与舞台视觉的影响，同时继续使用当前 FluidR3Mono_GM 采样链路。
5. 更新变更日志和计划完成记录，执行格式化、静态分析、相关测试与 diff 检查。

## 风险评估
- **风险 1**: 命中区调整可能影响滑扫演奏时的边界手感。
  - **缓解措施**: 与绘制层共用同一内边距和可用尺寸计算，并保留边界 clamp，避免触点刚好落在边缘时失效。
- **风险 2**: 动态舞台高度可能让页面纵向长度增加。
  - **缓解措施**: 按键数设置合理触控间距目标，并通过上限控制宽屏高度；全屏继续使用可用空间填充。
- **风险 3**: 强化材质与腔体参数可能造成部分乐器音色过湿或过长。
  - **缓解措施**: 保持参数 clamp，并对不支持共鸣管的类型隐藏控制，避免无效设置叠加。

## 依赖项
- `lib/src/ui/pages/toolbox_sound_tools/chimes.dart`
- `lib/src/ui/pages/toolbox_sound_tools/mallet_stage.dart`
- `lib/src/ui/pages/toolbox_sound_tools/mallet_models.dart`
- `changelogs/CHANGELOG.md`

## 完成记录
- 舞台绘制和触摸命中已统一使用同一套内边距、可用宽高与窄屏判断，修复窄屏 90 度布局下视觉琴键和实际触摸音高错位的问题。
- 普通舞台高度改为按当前乐器键数动态计算：手机窄屏 12 音约 574dp、16 音约 742dp，宽屏按键数小幅增高，避免固定高度导致琴键过密。
- 刚片琴标记为不支持共鸣控制，材质/腔体指标卡、设置项和声音参数叠加都会隐藏或停用；木琴、排钟、颤音琴、马林巴继续显示共鸣管材质和腔体设置。
- 材质与腔体对尾音、混响、音量、共鸣管长度/透明度和琴键染色的影响已加大，但播放链路仍优先使用当前 FluidR3Mono_GM 采样。
- i18n catalog 本轮新增 key 0 个、退休 key 0 个；仅调整既有 `AppI18n.t(...)` UI 分支显隐。

## 验证记录
- `dart format lib/src/ui/pages/toolbox_sound_tools/chimes.dart lib/src/ui/pages/toolbox_sound_tools/mallet_stage.dart lib/src/ui/pages/toolbox_sound_tools/mallet_models.dart` 通过。
- `flutter analyze lib/src/ui/pages/toolbox_sound_tools.dart lib/src/services/toolbox_instrument_engine.dart test/toolbox_instrument_engine_test.dart` 通过，No issues found。
- `flutter test test/toolbox_instrument_engine_test.dart` 通过。
- `flutter test test/app_i18n_catalog_test.dart` 通过。
- `node scripts/audit_i18n_placeholders.js` 通过：catalog missing 0，placeholderMismatch 0，Dart missingParams 0。
- `node scripts/maintain_i18n_catalog.js --limit 20` 通过：duplicateCsvKeys 0，duplicateRegistryIds 0，missingLocaleColumns 0；历史 staleRegistrySources 123 和 unreferencedCatalogKeys 39591 保留，不在本轮处理。
- 旧 helper 扫描无命中，catalog Dart 插值扫描无命中。
- `git diff --check` 通过。
