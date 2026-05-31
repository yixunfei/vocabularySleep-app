# 计划 306: toolbox 文件结构治理子计划

## 基本信息
- **创建日期**: 2026-05-31
- **状态**: 计划中，等待 `PLAN_304` 功能修复提交稳定后实施
- **负责人**: Codex
- **建议分支**: `codex/toolbox-structure-governance`

## 背景
`PLAN_304` 中的行为修复已经触达 sleep、game、sound、life、daily choice 等多个模块。当前工作区存在大量功能性 diff，此时继续移动文件会扩大冲突和回归范围。因此结构治理先形成单独子计划，实际文件移动放到功能修复验证、changelog 更新并提交后再做。

## 目标
1. 把分散在 `lib/src/ui/pages/` 根目录下的 toolbox 页面逐步迁入模块目录。
2. 优先处理本轮触达且后续维护成本最高的模块。
3. 只做文件归位、import 修正、必要 barrel 导出，不改变业务逻辑。
4. 每一组移动后立即跑 `dart analyze` 和目标 smoke，避免大批量搬迁后难定位。

## 不处理边界
- 不拆业务状态机。
- 不改 i18n key。
- 不重命名公开 Widget 类。
- 不混入 UI 样式重构。
- 不移动 `lib/src/services/` 中的共享服务，除非已有明确模块边界。

## 候选迁移映射
| 当前文件 | 建议位置 | 优先级 | 备注 |
| --- | --- | --- | --- |
| `toolbox_breathing_tool.dart` | `toolbox_breathing/toolbox_breathing_tool.dart` | P0 | 单文件仍较大，先只迁目录，再考虑展示组件拆分 |
| `toolbox_breathing_tool_voice.dart` | `toolbox_breathing/toolbox_breathing_tool_voice.dart` | P0 | 保持 `part` 关系或改私有 helper 文件需单独评估 |
| `toolbox_breathing_ui_parts.dart` | `toolbox_breathing/toolbox_breathing_ui_parts.dart` | P0 | 与主页面同迁 |
| `toolbox_mini_games*.dart` | `toolbox_mini_games/` | P1 | Tetris、Sokoban、Minesweeper、Gomoku 等从根目录收口 |
| `toolbox_mini_games_roulette*.dart` | `toolbox_mini_games/roulette/` 或 `toolbox_mini_games/` | P1 | 已有 painter/view 拆分，可二级目录 |
| `toolbox_singing_bowls_tool*.dart` | `toolbox_singing_bowls/` | P1 | 现已多文件拆分，但仍在根目录 |
| `toolbox_soothing_music_v2*.dart` | `toolbox_soothing_music/` | P2 | 已有 `toolbox_soothing_music/` 子目录，v2 文件应归并 |
| `toolbox_zen_sand_tool*.dart` | `toolbox_zen_sand/` | P2 | 文件较大，先目录治理，后续再拆交互/绘制 |
| `toolbox_prayer_beads_tool.dart` | `toolbox_prayer_beads/` | P2 | 单文件可先迁目录 |
| `toolbox_life_tools.dart` | `toolbox_life_tools/toolbox_life_tools_page.dart` | P3 | life 子模块已在目录内，入口页最后迁 |

## 执行顺序
1. 从 `main` 或当前稳定提交创建单独结构治理分支。
2. 先迁呼吸引导三文件，因为本轮已刚完成语音收口，验证目标清晰。
3. 再迁小游戏根目录文件，优先保留类名和路由引用。
4. 再迁疗愈音钵、舒缓轻音 v2、沙盘和念珠。
5. 最后处理入口页和 barrel/export，避免中途影响其他模块。

## 验证
每组迁移后至少执行：
```powershell
dart analyze <moved files and direct import users>
flutter test test/app_i18n_catalog_test.dart --reporter compact
git diff --check
```

按模块追加：
- 小游戏: `flutter test test/toolbox_mini_games_roulette_smoke_test.dart --reporter compact`
- 生活实用入口: `flutter test test/ui_smoke_test.dart --plain-name "app shell keeps bottom navigation inside life tools" --reporter compact`
- 声音工具: `flutter test test/toolbox_audio_bank_regression_test.dart --reporter compact`
- 沙盘: `flutter test test/toolbox_zen_sand_sound_service_test.dart --reporter compact`

## 风险
- 大量 import 变更容易与仍未提交的功能修复冲突。
- `part/part of` 文件迁移需要保持相对路径正确，建议一组一组迁。
- 根目录页面可能被路由、测试和 hub 多处引用，必须用 `rg` 反查引用。
- 结构治理若失败，应能整组回滚，不影响已完成的功能修复。
