# 计划 310: 模拟乐器切换与 SoundFont 卸载修复

## 基本信息
- **创建日期**: 2026-06-01
- **状态**: 已完成
- **负责人**: Codex

## 目标
优化模拟乐器页面的乐器切换区、全屏入口和无效快速提示入口，并修复 `flutter_midi_engine` 在当前平台缺少 `unloadSoundfont` 实现时产生的错误日志。乐器顺序调整为竖琴、敲击乐器、拇指琴、钢琴、长笛、吉他、铁三角、鼓垫、拾音器。

## 详细步骤
1. 将乐器切换从变长 `ChoiceChip` 改为移动端更整齐的固定列网格，并为每个乐器图标提供不同强调色。
2. 将“木琴与排钟”入口文案更名为“敲击乐器”，同步 catalog 和 registry 的七语言文本。
3. 将全屏按钮移出乐器切换区，放在当前乐器舞台底部附近，并增强尺寸、颜色和可触达性。
4. 移除快速提示按钮，保留已有信息折叠区的手动展开能力。
5. 捕获 `unloadSoundfont` 缺失实现并降级为静默成功，避免 dispose 期间产生错误日志。
6. 更新 changelog 与本计划完成记录，运行格式化、目标分析、相关测试和 i18n 必跑检查。

## 风险评估
- **风险 1**: 固定网格可能在极窄屏或多语言文本下仍出现截断。
  - **缓解措施**: 使用 `FittedBox`、固定高度和动态列宽，优先保持触控区稳定。
- **风险 2**: 移动全屏入口可能影响用户发现切换区功能。
  - **缓解措施**: 将按钮做成全宽主操作并放在舞台后，仍使用既有全屏文案。
- **风险 3**: SoundFont 卸载插件缺失如果被当作失败处理，会误伤可播放状态。
  - **缓解措施**: 只在适配器层针对 `MissingPluginException` 返回成功，其他调用错误继续抛给引擎统一兜底。

## 依赖项
- `lib/src/ui/pages/toolbox_sound_tools/deck.dart`
- `lib/src/services/toolbox_instrument_engine.dart`
- `test/toolbox_instrument_engine_test.dart`
- `lib/l10n/catalog/app_texts.csv`
- `lib/l10n/catalog/app_text_registry.json`
- `changelogs/CHANGELOG.md`

## 完成记录
- 乐器切换区已由变长 `ChoiceChip` 改为固定列网格，移动端默认三列排列，图标使用独立强调色，顺序调整为竖琴、敲击乐器、拇指琴、钢琴、长笛、吉他、三角铁、鼓垫、拾音器。
- “木琴与排钟”入口已更名为“敲击乐器”，并同步 `toolbox.sound.deck.chimes` 的七语言 catalog 和 registry 文案；切换区副标题同步说明全屏入口在舞台下方。
- 全屏按钮已移出乐器切换折叠区，改为当前乐器舞台后方的全宽高强调按钮；快速提示按钮已移除，信息折叠区保留手动展开。
- `ToolboxFlutterMidiEngineAdapter.unloadSoundfont()` 已改为本地静默成功，避免 `flutter_midi_engine` 0.1.3 在缺少原生 `unloadSoundfont` 方法时打印 `MissingPluginException`。
- i18n catalog 本轮新增 key 0 个、退休 key 0 个；更新既有 key 2 个。

## 验证记录
- `dart format lib/src/ui/pages/toolbox_sound_tools/deck.dart lib/src/services/toolbox_instrument_engine.dart test/toolbox_instrument_engine_test.dart` 通过。
- `flutter analyze lib/src/ui/pages/toolbox_sound_tools.dart lib/src/services/toolbox_audio_service.dart test/toolbox_instrument_engine_test.dart` 通过，No issues found。
- `flutter test test/toolbox_instrument_engine_test.dart` 通过，新增默认 MIDI adapter 卸载测试。
- `flutter test test/app_i18n_catalog_test.dart` 通过。
- `node scripts/audit_i18n_placeholders.js` 通过：catalog missing 0，placeholderMismatch 0，Dart missingParams 0。
- `node scripts/maintain_i18n_catalog.js --limit 20` 通过：duplicateCsvKeys 0，duplicateRegistryIds 0，missingLocaleColumns 0；历史 staleRegistrySources 123 和 unreferencedCatalogKeys 39592 保留，不在本轮处理。
- 旧 helper 扫描无命中，catalog Dart 插值扫描无命中。
- `git diff --check` 通过。
