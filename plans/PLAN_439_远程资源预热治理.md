# 计划 439: 远程资源预热治理（取消 / 总量上限 / 网络门控）

## 基本信息
- **创建日期**: 2026-09-13
- **状态**: 已完成本阶段（由 PLAN_450 补齐取消、门控与预算重试）
- **负责人**: ZCode

## 目标
落实审计 PERF-03 中代码侧可闭环部分：`CstCloudResourcePrewarmService` 不再无条件串行全量下载。

## 现状
- `prewarm()` 串行下载 `music/`、`ambient/` 前缀下全部对象，无总量上限、无取消、无网络条件判断。
- `AppState` 在启动/按需路径触发后无法中途停止；dispose 不取消。
- AndroidManifest 已含 `ACCESS_NETWORK_STATE`。

## 方案
1. **取消**：新增 `CstCloudResourcePrewarmCancellation` 句柄；`prewarm` 在每个对象下载前检查；AppState 持有句柄并在 `dispose()` 取消，另暴露 `cancelRemoteResourcePrewarm()`。
2. **总量上限**：`maxTotalBytes`（默认 96 MiB，可配）：列目录时按 `S3ObjectSummary.size` 累计计划量，超限的对象跳过并标记 capped；避免一次性拉爆流量/磁盘。
3. **网络门控**：新增 `connectivity_plus`；`isPrewarmNetworkAllowed()`（wifi/ethernet/vpn 允许，mobile/none 拒绝）；`prewarm({networkGate})` 可注入覆写（测试/未来策略）；AppState 按需路径在列目录前先检查，避免无谓请求。
4. **结果语义**：`CstCloudResourcePrewarmResult`（planned/completed/cancelled/capped/skippedByNetworkGate）；仅"全部完成或无事可做"才置 `_remotePrewarmCompleted`，capped/cancelled 保留下次重试机会。

## 不处理边界
- LRU/TTL 缓存淘汰、分片并发下载：留待后续切片（本轮只做治理闸门）。
- iOS/Windows 权限与网络子类型判定差异：connectivity_plus 官方插件能力范围内。

## 验证方式
- 新增 `test/cstcloud_resource_prewarm_service_test.dart`：cap 生效、取消中途停止、网络门控拒绝/允许、正常全量完成、默认门控纯函数。
- 全量 analyze/test 回归；无新增用户可见文案。

## 风险评估
- **风险 1**: capped/cancelled 不再标记 completed，弱网下每次启动都重试。缓解：网络门控本身会拦住移动网络；wifi 下重试是收敛行为。
- **风险 2**: connectivity_plus 新插件引入。缓解：官方维护插件，Android 权限已具备，门控可注入便于测试与降级。

## 2026-09-23 收口核对

取消、门控、预算收敛与缓存完整性在 PLAN_450 补齐；LRU/TTL 与主动中止在途网络请求仍不纳入。

验证与限制见 [PLAN_450](PLAN_450_project_audit_completion.md) 和 [质量评估](../docs/PROJECT_QUALITY_REVIEW_2026-09-23.md)。
