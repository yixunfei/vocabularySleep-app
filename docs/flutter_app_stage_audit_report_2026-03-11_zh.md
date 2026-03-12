# flutter_app 阶段复评报告

审计日期：2026-03-12

审计对象：`D:\workspace\opensource\vocabularySleep-app\flutter_app` 当前工作树

审计口径：本报告基于当前未提交代码、未跟踪文件和最新资源目录状态重新评估，不以历史提交版本为准。

## 1. 本轮复评范围

重点复核模块：

- `lib/main.dart`
- `lib/src/i18n/app_i18n.dart`
- `lib/src/services/database_service.dart`
- `lib/src/services/focus_service.dart`
- `lib/src/state/app_state.dart`
- `lib/src/ui/app_shell.dart`
- `lib/src/ui/pages/focus_page.dart`
- `lib/src/ui/pages/library_page.dart`
- `lib/src/ui/wordbook_localization.dart`
- `lib/src/services/wordbook_import_service.dart`
- `lib/l10n/*.arb`
- `pubspec.yaml`
- `dict/`
- `test/`
- `coverage/lcov.info`

执行检查：

- `flutter analyze`
- `flutter test -r expanded`
- `flutter test --coverage`
- 资源体积统计

## 2. 执行结果

### 2.1 静态检查

- `flutter analyze`：未通过 clean 标准
- 当前结果：
  - `lib/src/ui/pages/appearance_studio_page.dart:778:29` `unnecessary_null_comparison`
  - `lib/src/ui/pages/appearance_studio_page.dart:779:15` `dead_code`

### 2.2 自动化测试

- `flutter test -r expanded`：通过
- 当前全量测试数：`24`

### 2.3 覆盖率

- `flutter test --coverage`：通过
- `LF=9241`
- `LH=2512`
- 总覆盖率：`27.18%`

覆盖薄弱区仍然非常明显：

- `lib/src/services/focus_service.dart`：`0.00%`
- `lib/src/services/database_service.dart`：`0.21%`
- `lib/src/models/todo_item.dart`：`0.00%`
- `lib/src/models/tomato_timer.dart`：`4.08%`
- `lib/src/state/app_state.dart`：`19.41%`

### 2.4 资源体积

- `assets/` 当前总量约 `74.17 MB`
- `dict/` 当前总量约 `100.39 MB`
- 两者合计约 `174.55 MB`

其中 `dict/` 最大文件包括：

- `dict/中英_12000.json`：`33,967,721` 字节
- `dict/中德_12000.json`：`12,910,457` 字节
- `dict/英法_12000.json`：`11,610,017` 字节
- `dict/中法_12000.json`：`11,382,687` 字节
- `dict/中俄_12000.json`：`10,723,220` 字节
- `dict/中日_12000.json`：`10,250,620` 字节
- `dict/中世_12000.json`：`9,541,820` 字节

## 3. 总体结论

这轮相比上一版有几项明确进展：

- 内建词库已经不是“只有资源没有路径”，而是形成了“目录建档 -> 词库页可见 -> 点击时懒加载导入”的前后台闭环
- `Focus` 页、Todo、Quick Notes 和多语言切换已经接入当前前台
- 冒烟测试数量和整体覆盖率都有提升

但当前版本仍不建议作为“阶段验收版”提交，主要原因不是零散 UI 细节，而是存在会直接影响功能正确性和移动端体验的阻塞项：

1. `Focus` 默认流程存在结构性缺陷，当前状态下多轮专注流程无法稳定走通
2. `Focus` 今日统计口径错误，展示值与文案语义不一致
3. 内建词库虽然已接入，但并没有降低首包体积，首次导入还会同步解析大 JSON
4. 国际化进入双轨维护，`.arb` 未接入运行时，且部分资源文件本身已经损坏

综合评级：

| 维度 | 评级 | 结论 |
| --- | --- | --- |
| 功能性 | C+ | 新功能已接入，但 `Focus` 主链路默认不可用，不能按“已完成”看待 |
| 性能 | C | 词库懒加载只延后数据库导入，没有降低首包资源体积，首次导入仍有明显卡顿风险 |
| 用户体验 | C | 交互面在扩展，但默认流程、统计文案、词库命名和多语言质量尚未达标 |
| 代码质量 | C | 多语言双轨、配置键不一致、死代码和状态机分叉都说明实现仍在过渡态 |
| 测试成熟度 | C- | 总覆盖率提升到 `27.18%`，但新增重点模块几乎无保护 |

提交建议：

- 不建议按当前状态作为稳定阶段提交
- 如果只是开发分支中间提交，可以提交为 WIP/阶段快照，但应明确标注“Focus 与 i18n 尚未收口”

## 4. 已确认改善项

### 4.1 对上一版结论的修正：内建词库已经接通前台入口

这点需要明确修正。

现状不是“`dict/` 资源进包但完全未使用”，而是：

- `lib/src/services/database_service.dart:288-326` 会同步内建词库 catalog
- `lib/src/services/database_service.dart:331-380` 实现按路径懒加载导入
- `lib/src/state/app_state.dart:526-560` 在选中空词数的 `builtin:dict:*` 词本时触发 `ensureBuiltInWordbookLoaded()`
- `lib/src/ui/pages/library_page.dart:419-446` 已在前台给出“首次打开加载”的提示
- `lib/src/ui/pages/library_page.dart:1117-1125` 已可从词本切换面板触发加载

也就是说，功能链路已经存在，问题已经从“未接通”转成“策略与体验不够好”。

### 4.2 多语言基础接入已完成

- `lib/main.dart:137-148` 已增加 `locale`、`supportedLocales` 和 Flutter 自带 delegates
- `lib/src/i18n/app_i18n.dart` 已扩展 `zh / en / ja / de / fr / es`
- `lib/src/ui/ui_copy.dart` 已把部分导航和文案选择接入多语言分支

### 4.3 自动化测试和覆盖率较上一版提升

- 当前 `flutter test` 全量 `24` 条通过
- 覆盖率从上一版 `17.55%` 提升到当前 `27.18%`
- `ui_smoke_test.dart` 已覆盖更多设置页和词库页可见性路径

## 5. 主要问题

### 5.1 [高] `Focus` 计时器默认流程与配置持久化存在结构性缺陷

位置：

- `lib/src/models/tomato_timer.dart:1-49`
- `lib/src/services/focus_service.dart:33-66`
- `lib/src/services/focus_service.dart:140-174`
- `lib/src/services/focus_service.dart:216-243`
- `lib/src/ui/pages/focus_page.dart:249-295`

证据：

- `TomatoTimerConfig` 构造函数默认值是 `autoStartBreak = true`、`autoStartNextRound = false`
- 但 `TomatoTimerConfig.fromMap()` 在 key 缺失时会把两个布尔值都算成 `false`
- `FocusService._loadConfig()` 读取的是 `tomato_auto_start_next`
- `FocusService.saveConfig()` 保存的却是 `tomato_auto_start_next_round`
- `FocusPage` 当前只提供了专注时长、休息时长、轮数 3 个数字项，没有提供 `autoStartBreak` / `autoStartNextRound` 的用户控制入口

这会造成 3 个直接问题：

1. 首次进入时，`autoStartBreak` 实际默认为 `false`，和模型默认值不一致
2. `autoStartNextRound` 的读取 key 与保存 key 不一致，重启后无法正确恢复
3. 用户无法通过 UI 修正这两个状态

更严重的是状态机本身也与当前 UI 不匹配：

- 当专注阶段结束且 `autoStartBreak == false` 时，`_handlePhaseComplete()` 只是把当前 phase 保持为 `focus`、`remainingSeconds` 置 0、`isPaused` 置 `true`
- 这时页面展示的是“Resume/Skip/Stop”，但 `resume()` 只是取消暂停，下一秒会再次进入 `_handlePhaseComplete()`，导致已完成轮次被重复计数
- 当休息结束且 `autoStartNextRound == false` 时，状态会被置成 `idle` 且 `currentRound = round + 1`
- 但用户点击“Start Focus”会重新执行 `start()`，它会把 `_sessionRoundsCompleted` 清零并重新从 round 1 开始，而不是继续下一轮

影响：

- 默认配置下，多轮番茄流程不能按产品语义稳定跑通
- 轮次统计会被重复计数或被错误重置
- 当前 `Focus` 功能还不能视为“可提交的新主功能”

建议：

1. 先修正配置加载逻辑，让“无配置时”严格回退到模型默认值
2. 统一 `tomato_auto_start_next` / `tomato_auto_start_next_round` 键名
3. 如果保留“手动进入下一阶段”，就不要复用 `resume()`；应显式提供“开始休息”“开始下一轮”按钮
4. 为 `FocusService` 增加状态机单测，覆盖：
   - 首次启动默认值
   - 专注结束进入休息
   - 休息结束进入下一轮
   - 手动停止和跳过

### 5.2 [高] `Focus` 今日统计口径错误，当前展示的不是“专注分钟”

位置：

- `lib/src/services/focus_service.dart:182-206`
- `lib/src/services/focus_service.dart:332-359`
- `lib/src/ui/pages/focus_page.dart:325-359`

证据：

- `FocusService._saveTimerRecord()` 保存的是 `durationMinutes`
- 该值来自 `_sessionDurationSeconds / 60`
- `_sessionDurationSeconds` 在 focus 和 break 的每一秒都会累计
- `getTodayFocusMinutes()` 最后直接累加 `record.durationMinutes`
- 但 UI 文案显示的是 `focusMinutesLabel`

这意味着：

- 用户看到的“今日专注分钟”实际包含休息时长
- 完整跑完一轮 `25 + 5` 时，页面更接近展示 `30` 而不是 `25`

同时还有一个体验问题：

- `stop()` 和 `_completeSession()` 都要求 `_sessionRoundsCompleted > 0` 才写入记录
- 用户如果在第一轮未完成前停止，当前投入不会出现在今日统计中

影响：

- 统计数据不可置信
- 用户难以判断自己真实投入的专注时间
- 后续若要基于这些数据做日报/可视化，会直接失真

建议：

1. 将“专注分钟”“总会话时长”“已完成轮次”拆成不同指标
2. 若保留当前表结构，可优先按 `roundsCompleted * focusMinutes` 计算专注分钟
3. 若需要支持中途停止，也应把 partial session 独立记录下来
4. 为统计逻辑增加单测，至少验证：
   - 一轮完整 session
   - 带 break 的 session
   - 中途 stop 的 session

### 5.3 [高] 内建词库虽然已接入，但首包体积和首次导入性能风险仍然偏高

位置：

- `pubspec.yaml:79-85`
- `lib/src/services/database_service.dart:331-380`
- `lib/src/services/database_service.dart:857-884`
- `lib/src/services/wordbook_import_service.dart:56-114`
- `lib/src/ui/pages/library_page.dart:419-446`

证据：

- `pubspec.yaml` 仍把 `dict/` 整目录加入 assets
- 当前 `dict/` 目录约 `100.39 MB`
- 当前 `assets/` 自身约 `74.17 MB`
- 也就是说，只算静态资源就已接近 `174.55 MB`
- 首次打开内建词库时会执行：
  - `rootBundle.loadString(target.assetPath)`
  - `parseJsonText(content)`
  - `jsonDecode(content)`

其中最大词库 `dict/中英_12000.json` 单文件就约 `33.97 MB`。

当前“懒加载”的真实含义是：

- 懒的是“导入到数据库”
- 不是“懒下载”或“懒进入安装包”

因此它没有解决两个移动端核心问题：

1. 首包安装体积仍然被大资源直接拉高
2. 首次点击导入时仍会在单次用户操作里同步解析超大 JSON，卡顿风险非常高

另外还有一个体验问题：

- `lib/src/services/database_service.dart:877-884` 直接把文件名作为词本名
- `lib/src/ui/wordbook_localization.dart:47-52` 对 `builtin:dict:*` 也是直接回落到原始文件名
- 结果是用户会看到类似 `中英_12000` 这样的内部资源名，而不是可理解的产品化命名

影响：

- 安装包和分发成本偏高
- 首次导入体验不稳定，容易出现长时间“处理中”
- 内建词本虽然可用，但仍偏“工程接通态”，还不是“移动端成品态”

建议：

1. 如果目标是移动端体验，优先评估“首次下载/解压”而不是“首包全带”
2. 若暂时保留首包内置，至少把 JSON 解析迁到 isolate，避免大文件同步解码阻塞主线程
3. 为内建词本补产品化命名和多语言展示名
4. 增加内建词库加载链路测试，验证：
   - catalog 同步
   - 首次点击加载
   - 加载失败反馈
   - 再次进入不重复导入

### 5.4 [中高] 国际化进入双轨维护，`.arb` 未接入运行时且部分文件已损坏

位置：

- `lib/main.dart:143-147`
- `lib/src/i18n/app_i18n.dart:2385-2397`
- `lib/l10n/app_de.arb:66`

证据：

- `MaterialApp` 里只接入了 Flutter 自带 `GlobalMaterialLocalizations` / `GlobalWidgetsLocalizations` / `GlobalCupertinoLocalizations`
- 当前运行时业务文案仍然完全依赖 `AppI18n.t()` 中的手写大 Map
- 未发现 `AppLocalizations.delegate`、`flutter_gen`、`gen_l10n` 等运行时接入
- `lib/l10n/app_de.arb` 当前还存在 JSON 语法错误：
  - `pronunciationDiffReplace` 这一行引号不闭合，文件本身不能被标准 JSON 解析

当前状态说明：

- `.arb` 与 `AppI18n` 形成了双轨数据源
- 但真正运行时只用 `AppI18n`
- `.arb` 不仅没有形成收益，反而已经开始和运行时实现脱节

影响：

- 文案维护成本翻倍
- 后续如果切到 `gen-l10n`，会先撞上资源损坏和内容不一致问题
- 当前多语言体系还不具备“可持续扩展”的结构

建议：

1. 明确唯一文案真源
2. 如果决定使用 `gen-l10n`，就尽快把业务文案迁回 `.arb`，并修复所有语法错误
3. 如果短期继续使用 `AppI18n`，建议移除未接入的 `.arb` 新增稿，避免团队误判
4. 为语言切换补一条集成级测试，验证 `state.uiLanguage -> 页面文案` 的完整链路

### 5.5 [中] 多语言文案质量还未达到可发布水平

位置：

- `lib/src/i18n/app_i18n.dart:940`
- `lib/src/i18n/app_i18n.dart:996`
- `lib/src/i18n/app_i18n.dart:1117`
- `lib/src/i18n/app_i18n.dart:1570`
- `lib/src/i18n/app_i18n.dart:1887`

示例问题：

- 日语 `local` 被翻成了 `地元`
- 日语 `close` 被翻成了 `近い`
- 日语 `themeMono` 被翻成了 `単核症`
- 法语 `resume` 被翻成了 `CV`
- 西语 `play` 被翻成了 `Jugar`

这些已经不是“措辞是否优雅”的问题，而是用户可直接感知的语义错误。

影响：

- 多语言看起来像“已支持”，但实际完成度不足
- 会削弱用户对产品专业度的信任
- 一旦进入截图、分享或商店材料，会直接暴露质量问题

建议：

1. 在对外发布前，至少完成各语言的高频主路径人工校对
2. 先确保导航、设置、错误反馈、Focus 主功能相关文案准确，再扩展长尾字段
3. 不建议把当前多语言状态直接当作“已完成国际化”

### 5.6 [中] `flutter analyze` 仍未恢复 clean 状态

位置：

- `lib/src/ui/pages/appearance_studio_page.dart:778-779`

现状：

- `preview` 在上文已经通过 `??` 回退成非空值
- 但后续仍保留 `preview == null ? null : ...`
- 这既是多余判断，也形成了 dead code

影响：

- 虽然不是功能阻塞，但说明这轮提交仍有可见残留
- 这类 warning 如果继续累积，会让后续真正有价值的问题被淹没

建议：

1. 在提交前把 analyze 恢复到 clean
2. 把 warning 级别也纳入“可提交”的最低门槛

### 5.7 [中] 测试数量提升明显，但新增重点模块几乎没有保护

现状：

- 当前全量测试是 `24`
- 但本轮检索未发现 `FocusPage`、`focusService`、`ensureBuiltInWordbookLoaded`、`builtin:dict` 等关键字对应的测试覆盖
- 覆盖率最低的文件正好集中在本轮新增或重改模块

这说明当前测试增长主要来自：

- 旧页面冒烟验证
- 局部逻辑验证

而这轮最值得担心的路径仍然是空白：

- `Focus` 状态机
- `Focus` 统计
- 内建词库懒加载
- 多语言切换后的真实页面内容

建议：

1. 把这轮新增功能至少补到 widget test 级别
2. 优先覆盖“会出错但目前人工不易稳定回归”的链路
3. 报告中建议的 P0 问题修完后，必须同步补测试，不建议只修代码不加保护

## 6. 新功能专项评估

### 6.1 Focus 功能

结论：

- 页面已经成型，功能点包括计时、今日统计、Todo、Quick Notes
- 但默认状态机和统计逻辑还不可靠

当前判断：

- 属于“功能已接通但不可验收”

### 6.2 内建词库

结论：

- 已具备前台入口和按需导入逻辑
- 不再属于“完全未接通”

当前判断：

- 属于“功能已存在，但移动端资源策略与首次导入体验仍不合格”

### 6.3 多语言

结论：

- 基础切换能力已经接上
- 但结构和内容都还处于过渡态

当前判断：

- 属于“开发态国际化”，不宜直接宣称为完整多语言版本

## 7. 分阶段整改方案

### 7.1 P0：提交前必须处理

1. 修复 `Focus` 默认配置、状态机分支和设置键名不一致问题
2. 修复 `Focus` 今日统计口径
3. 清掉当前 `flutter analyze` 的 warning
4. 为 `FocusService` 补最小状态机测试

### 7.2 P1：下一阶段优先处理

1. 明确国际化唯一真源，结束 `AppI18n` 与 `.arb` 双轨
2. 修复 `.arb` 资源文件语法问题
3. 人工校对各语言高频文案
4. 为内建词库补产品化命名和错误反馈
5. 为内建词库懒加载补测试

### 7.3 P2：性能与体验优化

1. 重新设计内建词库资源策略，避免首包携带全部大 JSON
2. 将大词典首次导入改为 isolate 或后台任务，降低主线程阻塞
3. 将今日统计下沉到数据库聚合查询，而不是每次取最近 100 条记录后在内存中过滤
4. 为 `Focus` 页补空状态、失败反馈和更明确的阶段切换按钮文案

## 8. 是否建议当前提交

结论：

- 不建议将当前版本作为“阶段验收版”提交
- 如果只是代码快照或团队内部开发分支提交，可以提交，但应明确标注以下事实：
  - `Focus` 仍未达到可用闭环
  - 内建词库策略仍未收口
  - 多语言仍处于过渡态

建议的提交门槛：

1. `flutter analyze` clean
2. `Focus` 默认流程可完整跑通至少两轮
3. 今日统计与文案语义一致
4. 至少补一组 `FocusService` 和内建词库入口测试
