# 计划 448：恢复 S3 默认鉴权读取

## 基本信息
- **创建日期**：2026-09-15
- **状态**：已完成
- **负责人**：Codex
- **代码版本**：1.0.0+1（不调整发行版本）

## 目标与确认
- 用户确认远端拒绝匿名访问，原凭据仅具有读取权限，可以随客户端分发；不得要求用户设置环境变量。
- 恢复原默认只读凭据、AWS SigV4 签名和 `S3 browser 13.1.1` 请求头；保留显式参数与环境配置覆盖。
- 计划审查：签名算法仍在，根因是默认凭据删除和缺失凭据返回空 headers；局部恢复即可覆盖共享客户端的所有资源读取入口。

## 详细步骤
1. 恢复客户端默认凭据与必要说明，底层配置恢复必填凭据，空值在发请求前拒绝。
2. 回归覆盖默认免配置读取、显式/环境覆盖、LIST/HEAD/GET/Range/文件下载请求头与签名。
3. 执行目标测试与静态分析；使用默认客户端对真实远端做只读小流量验证。
4. 更新 changelog，再回看计划完成情况，提交本轮变更。

## 风险与边界
- 不改动已有下载完整性清理、Range 边界检查与当前未提交的平台改造。
- 客户端内置凭据可以被提取；按用户确认保留只读分发模式，不以混淆冒充加密。不输出 secret/Authorization 日志，不执行远端写入或权限变更。
- HTTPS 和服务端只读权限是当前保护边界；不引入需要新后端的代理或临时签名服务。
- 本轮无 UI、catalog、registry 或 AppI18n 调用修改；新增/退休 key 均为 0，无需 i18n 迁移检查。
- 已检查 PROJECT_DOMAIN.md：属于既有资源访问修复，项目范围不变。

## 验证结果
- `flutter test --no-pub test/cstcloud_s3_auth_test.dart`：9 个通过；测试捕获本地 HTTP 请求，真实校验请求头、显式/环境凭据签名及空凭据拒绝。
- `flutter test --no-pub test/s3_bucket_probe_test.dart test/cstcloud_resource_cache_service_test.dart test/cstcloud_resource_prewarm_service_test.dart test/online_ambient_catalog_service_test.dart test/toolbox_breathing_audio_repository_test.dart test/toolbox_instrument_engine_test.dart test/daily_choice_activity_library_store_test.dart test/daily_choice_place_seed_test.dart`：52 个通过。首次合并运行中新增鉴权测试存在编译错误，修复测试类型与 Flutter HTTP override 后新增 9 项单独通过。
- `flutter test --no-pub test/cstcloud_s3_auth_test.dart .dart_tool/s3_authenticated_smoke_test.dart`：10 个通过，其中 1 项为本地临时真实远端验证，不加入常规测试以免依赖网络。
- 真实远端默认客户端：LIST/HEAD/Range 成功；抽样 `ambient/moodist/animals/chickens.mp3`，HEAD 长度 5,017,248 bytes，Range 长度 32 bytes。未打印凭据或签名头。
- `dart analyze lib/src/services/cstcloud_s3_compat_client.dart lib/src/services/s3_bucket_probe.dart test/cstcloud_s3_auth_test.dart test/s3_bucket_probe_test.dart`：No issues found。
- 对上述四个文件运行 `dart format --output=none --set-exit-if-changed`：0 changed，通过。
- i18n 新增/退休 key 均为 0；无触达项，维护脚本不适用。未处理历史 i18n 债务、Web facade、后端鉴权架构或其他工作区改动。
- 已先更新 [changelog](../changelogs/CHANGELOG.md)，再回看本计划；README/环境模板同步说明默认签名方式。
