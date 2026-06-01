# 计划 312: 尺八气流面板可行性测试

## 基本信息
- **创建日期**: 2026-06-01
- **状态**: 已完成
- **负责人**: Codex

## 目标
在模拟乐器中新增一个尺八类测试乐器，验证“不依赖麦克风吹气检测、改用触控气流面板控制吹奏”的可行性。尺八入口默认不展示非全屏舞台，只提供进入全屏的按钮；全屏内按住气流面板表示吹气，向上/向下滑动表示气流强弱变化，松开停止吹气。

## 详细步骤
1. 新增独立 `shakuhachi.dart` 模块，并以最小改动接入 `toolbox_sound_tools.dart` 和模拟乐器 deck。
2. 在 deck 中加入尺八入口，默认 inline 仅显示说明和进入全屏按钮，不运行非全屏演奏舞台。
3. 全屏尺八舞台提供音孔/音阶选择和气流控制面板：按下开始，滑动调节气流强度，松开停止。
4. 声音继续优先使用 FluidR3Mono_GM 采样，新增 GM shakuhachi patch；采样不可用时使用既有长笛 fallback 的 bamboo 风格，不新增共享音频 bank 改动。
5. 同步新增 i18n catalog/registry 文案和 SoundFont patch 测试。
6. 更新 changelog 与本计划，运行格式化、目标分析、相关测试和 i18n 检查。

## 风险评估
- **风险 1**: 当前工作树已有其他模块未提交改动。
  - **缓解措施**: 不触碰已被占用的并行模块文件；共享文件仅做必要的 part、deck、patch 和测试小改。
- **风险 2**: GM shakuhachi 采样在部分平台资源未就绪时不可用。
  - **缓解措施**: 保留既有 `ToolboxAudioBank.fluteNote` bamboo fallback，仍可验证交互。
- **风险 3**: 触控面板强度映射可能需要真机手感微调。
  - **缓解措施**: 使用稳定的纵向 clamp 和可视化气流条，先作为测试切片记录剩余风险。

## 依赖项
- `lib/src/ui/pages/toolbox_sound_tools.dart`
- `lib/src/ui/pages/toolbox_sound_tools/deck.dart`
- `lib/src/ui/pages/toolbox_sound_tools/shakuhachi.dart`
- `lib/src/services/toolbox_instrument_engine.dart`
- `assets/toolbox/instruments/instrument_banks.json`
- `test/toolbox_instrument_engine_test.dart`
- `lib/l10n/catalog/app_texts.csv`
- `lib/l10n/catalog/app_text_registry.json`

## 完成记录
- 新增独立 `shakuhachi.dart` 模块，普通模式只显示尺八气流面板测试说明和进入全屏按钮，不展示非全屏演奏舞台。
- 全屏尺八舞台使用触控气流面板：按下开始吹奏，纵向滑动调节气流强弱，松开停止；顶部保留音级选择和退出全屏入口。
- 模拟乐器 deck 已加入尺八入口，排列在长笛之后、吉他之前，并使用独立图标色。
- SoundFont catalog 新增 `gm_shakuhachi`，映射 FluidR3Mono_GM 的 Shakuhachi GM program 77 / channel 11；采样不可用时复用现有 bamboo flute fallback。
- i18n catalog 新增尺八相关 key 11 个、退休 key 0 个；registry 已同步。
- 本轮仅暂存尺八相关文件；当前工作树中的并行模块改动保留为未提交状态，不纳入本次提交。

## 追加记录
- 2026-06-01: 根据现代尺八重新调整全屏演奏面板，采用五孔布局（前四后一）与右侧气流滑控两列排列；一尺八寸 D 管按全闭 D、开放 F/G/A/C/D 映射当前音。
- 移除尺八模块自身的全屏入口，只保留模拟乐器 deck 底部全屏按钮，避免页面出现两个全屏按钮。
- 移除“测试用乐器”描述，i18n catalog 新增 `toolbox.sound.shakuhachi.current_note` 1 个 key，退休 key 0 个；registry 已同步。

## 验证记录
- `dart format lib/src/ui/pages/toolbox_sound_tools.dart lib/src/ui/pages/toolbox_sound_tools/deck.dart lib/src/ui/pages/toolbox_sound_tools/shakuhachi.dart lib/src/services/toolbox_instrument_engine.dart test/toolbox_instrument_engine_test.dart` 通过。
- `flutter analyze lib/src/ui/pages/toolbox_sound_tools.dart lib/src/services/toolbox_audio_service.dart test/toolbox_instrument_engine_test.dart` 通过，No issues found。
- `flutter test test/toolbox_instrument_engine_test.dart` 通过。
- `flutter test test/app_i18n_catalog_test.dart` 通过。
- `node scripts/audit_i18n_placeholders.js` 通过：catalog missing 0，placeholderMismatch 0，Dart missingParams 0。
- `node scripts/maintain_i18n_catalog.js --limit 20` 通过：duplicateCsvKeys 0，duplicateRegistryIds 0，missingLocaleColumns 0；历史 staleRegistrySources 123 和 unreferencedCatalogKeys 39610 保留，不在本轮处理。
- 旧 helper 扫描无命中，catalog Dart 插值扫描无命中。
- `git diff --check` 通过。
- 2026-06-01 追加验证：`dart format lib/src/ui/pages/toolbox_sound_tools/shakuhachi.dart lib/src/ui/pages/toolbox_sound_tools/deck.dart` 通过。
- 2026-06-01 追加验证：`flutter analyze lib/src/ui/pages/toolbox_sound_tools.dart lib/src/services/toolbox_audio_service.dart test/toolbox_instrument_engine_test.dart` 通过，No issues found。
- 2026-06-01 追加验证：`flutter test test/toolbox_instrument_engine_test.dart` 与 `flutter test test/app_i18n_catalog_test.dart` 通过。
- 2026-06-01 追加验证：`node scripts/audit_i18n_placeholders.js` 通过；`node scripts/maintain_i18n_catalog.js --limit 20` 仅报告历史 staleRegistrySources 123 和 unreferencedCatalogKeys 39612。
