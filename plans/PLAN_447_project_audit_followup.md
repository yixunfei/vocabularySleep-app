# 计划 447：项目全面审计跟进

## 基本信息
- **创建日期**：2026-09-15
- **状态**：已完成本阶段（剩余边界见 PLAN_450 评估）
- **目标**：基于当前工作树真实分析与测试结果，修复高置信度缺陷并完成验证。

## 已确认问题与处理
1. `FocusService.saveTodo` 新建 Todo 的 `createdAt` 使用系统墙钟，绕过可注入 `_now`，导致会话时间与 Todo 时间在 fake clock、跨时区或时间跳变时不一致。已改为 `_now()`，待定向回归测试验证。
2. `flutter analyze --no-pub` 当前无 error/warning，但有 118 条既有 info lint；本轮不做无关大规模 lint 重构。
3. 全量 `flutter test --no-pub` 基线通过 912 tests；新增 FocusService 注入时钟回归测试后，定向 Focus 测试 17 个通过。
4. `dart format --output=none --set-exit-if-changed lib test` 会报告 13 个既有文件未格式化；执行格式化会产生与本轮无关的内容变更，已恢复这些 formatter-only 变更，待对本轮触达文件执行定向格式检查。

## 验证与剩余工作
- 对 Focus 时间一致性增加回归测试，并运行定向 Focus/Sleep/Web/S3 测试。
- 重新执行 `flutter analyze --no-pub`、全量测试、默认 Web 构建。
- 若验证发现新的高置信度 bug，按最小修改原则处理；其余既有 info、Web session-memory、Web ASR unavailable 和运维凭据轮换记录为边界风险。
- 完成后更新 changelog，逐项列出命令和真实结果。

## 本轮追加审计结果
- AmbientService 播放同步增加代际校验；禁用环境音后，异步资源解析完成不会重新创建播放器。
- AmbientService 的停止/释放改为逐播放器 best-effort 清理，单个播放器异常不会阻断其他资源；启动超时后的释放等待限定为 2 秒。
- AmbientService 下载扫描覆盖 `ambient/moodist` 全部分类，不再仅恢复 noise 目录。
- OnlineAmbientCatalogService 的 force refresh 纳入 single-flight，避免并发请求完成顺序覆盖缓存。
- AppState 恢复下载音频时拒绝零字节文件。
- SettingsService 安全存储写入失败时不再把 API key 回写到明文数据库行。
- 删除被 Git 跟踪的 `android/key.properties` 明文发布密码内容，改为仅保留 CI/Gradle 注入说明；发布签名密码仍需运维轮换并清理历史。
- S3 range 请求增加 `0 <= start <= end` 边界校验。
- Android release lint 改为 `checkReleaseBuilds = true`。

## 本轮验证
- 重点生命周期/安全测试通过：18 tests；Ambient 定向测试通过：7 tests。
- 全量 `flutter test --no-pub`：914 tests 全部通过。
- `flutter build web --no-pub --no-wasm-dry-run`：成功生成 `build/web`。
- `flutter analyze --no-pub`：无 error；仅既有 info lint，另有 2 条触达构造器 info。
- `node scripts/audit_i18n_placeholders.js`：missing=0、placeholderMismatch=0、dart missingParams=0、dynamicParams=0。
- `node scripts/maintain_i18n_catalog.js --limit 20`：fatal duplicate/missing locale 均为 0；3505 个历史未引用 key、417 个 stale registry source 仍保留为整理债务。

## 未完成边界
- 统一 Web/Wasm facade 仍需验证 Flutter 当前 toolchain 对 `dart.library.js_interop` 的条件行为；本轮未宣称 WASM 等价支持。
- S3 canonical URI 完整 AWS RFC3986 双编码、响应体上限/压缩炸弹防护、cache 跨 API single-flight、SleepSound 同实例 release 去重仍需独立测试切片，未以未验证的修改冒充完成。
- Android release signing secret 的历史清理、keystore 轮换和 CI secret 注入需要运维/仓库管理员权限，未执行破坏性历史重写。

## 2026-09-23 收口核对

S3 编码/分页与 SleepSound 同实例释放已由 PLAN_450 补齐。默认鉴权最终以 PLAN_448 为准；本文旧的匿名请求与签名配置描述仅为历史记录。其余解压上限、缓存并发策略等仍独立规划。

验证与限制见 [PLAN_450](PLAN_450_project_audit_completion.md) 和 [质量评估](../docs/PROJECT_QUALITY_REVIEW_2026-09-23.md)。
