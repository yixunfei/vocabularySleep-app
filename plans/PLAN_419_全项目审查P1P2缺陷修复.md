# 计划 419: 全项目审查 P1/P2 缺陷修复

## 基本信息
- **创建日期**: 2026-08-28
- **状态**: 进行中
- **负责人**: Codex
- **分支**: `codex/fix-audit-findings`

## 背景
全项目只读审查确认测试门禁、Material 组件层级、图片与归档资源边界、i18n 启动和发布资源、异步生命周期及高频音频调用存在 P1/P2 风险。用户已确认先处理这些生产风险，并将超大文件拆分、静态债务和依赖升级保留为独立 P3 计划。

## 目标
1. 恢复全量测试门禁，消除已确认的 Material 断言、失效文案断言和测试乱码。
2. 将图片和归档的 CPU 密集型编解码移出 UI isolate，并建立可测试的输入、像素、文件数和解压总量硬限制。
3. 移除发布包中的 i18n 审计元数据，避免首帧前在 UI isolate 解析完整 CSV，并保留加载失败诊断能力。
4. 修复异步 `BuildContext` 生命周期缺口，串行化环境音音量和麦克风振幅轮询，避免重叠平台调用。

## 详细步骤
1. **正确性与门禁**
   - 为带背景的 `SwitchListTile`/`ListTile` 提供就近 `Material` 承载层。
   - 在密码库、日期时间选择器和 GIF 保存异步间隙后补充 mounted/context 存活检查。
   - 修正专注回合中文语序；更新已失效的测试契约和 mojibake 期望，不改变业务状态机。
   - 分组复现剩余失败并只修复有明确现行产品契约的断言。
2. **图片处理**
   - 提取可发送到 isolate 的顶层 worker 输入/输出模型和纯函数。
   - 压缩、放大、证件照的解码、方向修正、逐像素处理及编码均在后台 isolate 执行。
   - 统一限制源文件为 32 MiB、源图为 40 MP、输出为 64 MP 且单边不超过 16384 px；超过限制返回可本地化错误。
   - 保持现有算法选项和输出格式语义；QR 既有 `compute` 路径不改。
3. **归档处理**
   - 压缩和解码迁移到后台 isolate；目录收集继续使用异步文件 I/O。
   - 输入压缩包不超过 256 MiB，文件数不超过 10000，单文件不超过 256 MiB，累计原始/解压内容不超过 1 GiB，压缩比不超过 200:1。
   - 解码后在写盘前再次校验条目数、条目大小、安全相对路径和累计大小；拒绝资源超限归档。
4. **i18n 启动与包体**
   - `pubspec.yaml` 仅打包运行时 CSV，不再打包 `app_text_registry.json`、retirement 和说明文档。
   - CSV 在后台 isolate 解析；`runApp` 立即安装轻量加载壳，catalog 就绪后再构造完整依赖和应用树。
   - 加载失败记录日志并显示可重试的最小错误界面，不再把空表伪装为加载成功。
   - 不执行 catalog 历史 key 批量删除；仅新增启动失败与重试所需的 2 个稳定 key，退休 key 目标为 0。
5. **音频异步竞争**
   - 环境音音量同步改为单飞合并：同一时刻只允许一个平台调用链，期间变化合并为最新状态。
   - 长笛振幅轮询增加 in-flight guard，并在停止/销毁后丢弃迟到结果。
   - 使用可控慢 fake 补充不重叠和最新值生效测试。
6. **验证与提交**
   - 每阶段运行目标测试、目标 analyze、格式化和 `git diff --check` 后独立提交。
   - 最终运行 `flutter analyze --no-pub`、全量 `flutter test --no-pub`、i18n 四项必跑检查和发布资源检查。
   - 更新本计划执行记录和 `changelogs/CHANGELOG.md`。

## 风险评估
- **后台 isolate 数据传输增加峰值内存**：字节数据使用 `TransferableTypedData` 或单次可发送对象；worker 只返回最终结果和必要元数据。
- **归档限制拒绝合法超大文件**：限制集中为具名策略常量并返回明确错误，后续可按设备等级配置；本轮优先保证移动端稳定性。
- **启动壳改变初始化时序**：完整依赖只在 catalog 成功后创建一次；增加加载成功、失败和重试测试，避免服务重复构造。
- **音量合并改变中间采样点**：只丢弃过期中间值，最终目标音量和淡入淡出完成语义不变。
- **旧测试断言可能掩盖产品回归**：以当前 catalog、现行 Widget 语义和单独复现结果为依据逐项修正，不使用批量跳过或降低断言强度。

## 依赖项
- 复用现有 `image`、`archive`、Flutter isolate 与测试基础设施，不新增第三方依赖。
- Android/iOS 真机当前不可用；最终帧时间、RSS 和耗电仍需设备回归。

## 不处理边界
- 不在本轮机械拆分 111 个超限源码文件；单独建立 P3 架构计划。
- 不在本轮升级 EOL SQLite 包、Riverpod 或本地 override 插件；依赖升级单独验证迁移风险。
- 不批量删除 40109 个未引用 catalog key，也不执行 `--apply-retirements`。
- 不改变图片算法、归档格式、专注状态机、播放策略或工具入口行为。

## 执行记录
### 2026-08-28
- 已完成全项目只读审查、定向复现和用户方案确认。
- 已创建 `codex/fix-audit-findings` 分支并建立本计划。
- 已完成 correctness 阶段：修复 Material 层级、异步 context 生命周期、快速入口长按/拖放冲突与移动端跨屏接收区，并恢复现行 UI/文案测试契约。
- `test/ui_smoke_test.dart` 共 147 项通过；`focus_service_test.dart`、`focus_timer_widgets_test.dart` 与 `toolbox_human_tests_extended_smoke_test.dart` 共 21 项通过，测试输出无离屏点击告警。
- i18n 本阶段新增 key 0、退休 key 0；占位符审计为 `51755` keys、缺失/不一致均为 0，旧 helper 与 catalog Dart 插值扫描无命中。维护报告保留历史基线：`40108` 个未引用 key、`661` 个 stale registry source、`30` 个待清理 retirement，本轮不处理。
- `flutter analyze --no-pub` 完成扫描，仍有 175 条既有 lint/warning；本轮修改未新增诊断，静态债务按计划保留到 P3。
- 已完成图片阶段：压缩、放大和证件照统一使用后台 `compute` worker 与 `TransferableTypedData`；源图先读元数据、仅解码第一帧并修正方向，UI 仅接收最长边不超过 1600 px 的预览。
- 图片资源策略统一限制源文件 32 MiB、源图 4000 万像素、输出 6400 万像素且单边不超过 16384 px；原生文件选择改为限额流式读取，避免完整载入超限文件后才拒绝。
- 图片 service/证件照测试共 9 项通过，覆盖方向修正、预览缩小、元数据预检、输出预检、压缩格式和证件照既有算法；完整 `ui_smoke_test.dart` 147 项通过。
- 图片目标文件定向 `flutter analyze --no-pub` 无诊断，`git diff --check` 通过。压缩页由 1221 行降至 998 行，证件照页由 1016 行降至 976 行；放大页由 1354 行降至 1135 行，剩余既有展示层拆分仍按计划留到 P3。
- 图片阶段 i18n 新增 key 3、退休 key 0；占位符审计为 `51758` keys、缺失/不一致均为 0。维护报告保留历史基线：`40108` 个未引用 key、`661` 个 stale registry source、`30` 个待清理 retirement，本轮不处理；旧 helper 与 catalog Dart 插值扫描无命中。
- Web 全应用构建仍被既有 `sherpa_onnx`/`sqlite3` 的 `dart:ffi` 直接依赖阻断。Chrome 图片测试已完成编译并启动浏览器，但本机 runner 未建立连接，等待约 2 分钟后终止；VM 与完整 Widget 回归已通过，Web 运行时仍作为设备/环境验证缺口保留。
- 已完成归档阶段：ZIP/TAR/GZip/BZip2/XZ 编解码和 Web 解压重打包统一迁移到 `compute` worker，并使用 `TransferableTypedData` 传递输入、输出和已验证条目；目录收集保留异步 I/O，原生文件读取改为限额流式读取。
- 归档策略统一限制归档输入/输出 256 MiB、条目数 10 000、单文件 256 MiB、累计内容 1 GiB、压缩比 200:1。ZIP 在内容物化前预检中央目录；所有解码使用有界输出流，并以实际解码长度和 CRC 复核头部声明。
- 解压路径现在拒绝绝对路径、`..`、符号链接、大小写冲突和规范化后重复项；写盘前再次复核全部限制，并验证目标路径仍位于本次新建解压目录内，失败时清理该次部分输出。
- 归档 service 测试 10 项通过，覆盖 ZIP/TAR.GZ/GZip worker 往返、路径穿越、符号链接、路径冲突、压缩比炸弹和写盘前二次验证；完整 `ui_smoke_test.dart` 147 项通过，目标文件定向 `flutter analyze --no-pub` 无诊断。
- 归档页按职责拆为状态/I/O 910 行、视图 406 行、进度与选项 294 行；公开 service 531 行、纯 worker 692 行、资源策略 181 行，均低于项目单文件上限。
- 归档阶段 i18n 新增 key 6、退休 key 0；占位符审计为 `51764` keys、缺失/不一致均为 0。维护报告保留历史基线：`40108` 个未引用 key、`661` 个 stale registry source、`30` 个待清理 retirement，本轮不处理；旧 helper 与 catalog Dart 插值扫描无命中。
- 已完成 i18n 启动与包体阶段：`runApp` 在绑定和全局错误处理安装后立即挂载轻量加载壳；`.env` 等前置初始化与 catalog 加载异步执行，catalog 成功前不构造 `AppDependencies`，失败时记录诊断并提供单飞重试，成功后的完整应用树仅构造一次。
- catalog 改为 `rootBundle.load` 读取原始字节，通过 `TransferableTypedData` 交给 `compute` worker 完成 UTF-8 与 CSV 解析；空内容、缺列、无有效 key 和损坏编码均抛出带阶段信息的 `AppI18nCatalogLoadException`，失败不会安装空表或覆盖此前成功表。
- `pubspec.yaml` 仅发布 `app_texts.csv`，AssetManifest 测试确认 registry、retirement 与说明文件不再进入应用资源。catalog/启动测试 12 项与完整 `ui_smoke_test.dart` 147 项通过，4 个目标文件定向 `flutter analyze --no-pub` 无诊断，`git diff --check` 通过。
- i18n 启动阶段新增 key 2、退休 key 0；占位符审计为 `51766` keys、缺失/不一致均为 0。维护报告保留历史基线：`40108` 个未引用 key、`661` 个 stale registry source、`30` 个待清理 retirement，本轮不处理；旧 helper 与 catalog Dart 插值扫描无命中。
- 已完成音频异步竞争阶段：`SeamlessAmbientLoop` 将启动、切轨、淡入收尾和外部调节的全部音量写入统一到单飞 drain；在途批次期间的变化只标记 pending，下一批重新采样最新目标，销毁会先等待在途音量写入再停止播放器。
- 长笛振幅轮询提取为 71 行独立控制器，以 in-flight guard 阻止 50ms 定时器堆叠平台调用，并用 generation 在停止、重启和销毁时丢弃迟到数据与错误；现有长笛页面只替换定时接线，未扩展超大页面职责。
- 环境音与振幅轮询测试共 9 项通过，覆盖最大并发为 1、中间音量合并、最终值落地、销毁等待、停止后迟到异常和销毁后迟到结果；完整 `ui_smoke_test.dart` 147 项通过，新增轮询器、接入文件和测试定向 `flutter analyze --no-pub` 无诊断，`git diff --check` 通过。`ambient_service.dart` 仍有 2 条既有 `prefer_initializing_formals` info，本轮不做无关构造器改名。

## 完成检查清单
- [x] 正确性与测试门禁修复完成
- [x] 图片与归档资源安全修复完成
- [x] i18n 启动与包体修复完成
- [x] 音频异步竞争修复完成
- [ ] 全量验证通过或剩余历史项已明确记录
- [ ] Changelog 已更新
- [ ] 各阶段已提交
