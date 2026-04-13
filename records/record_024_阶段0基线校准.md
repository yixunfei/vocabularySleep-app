# 记录 024：阶段 0 基线校准

## 时间
- 2026-04-13

## 背景
执行 `PLAN_024` 前，项目存在以下基线问题：
- `ambient_service_test` 2 项失败。
- `dart analyze / flutter analyze` 存在 warning，阻断重构迭代。

## 动作
1. 修复环境音内置预设缺失，恢复 `noise_white` 等 built-in 源。
2. 修复与清理 analyze 阻断项（unused、lint warning、测试桩接口同步）。
3. 增补模块开关相关接口后，同步更新 `ui_smoke_test` 中 `_FakeAppState`。
4. 重跑全量验证。

## 结果
- `./scripts/verify-local-analysis.ps1 -Task analyze -Target lib test` 通过。
- `flutter test` 全量通过。
- 阶段 0 退出条件满足，可进入后续模块化深化阶段。
