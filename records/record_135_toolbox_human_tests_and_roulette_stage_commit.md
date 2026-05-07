# Toolbox 人类测试与小游戏阶段提交记录

## 本轮范围
- 汇总提交 2026-05-07 当前工作区中的 toolbox 阶段改动。
- 重点包含人类测试中心多模块增强、摇杆手眼协调全屏体验、运气测试抽卡体验、色觉报告可读性、俄罗斯轮盘音效/视觉/线程修复，以及相关 smoke test。
- 本次按用户要求做一次整体阶段提交；提交范围包含当前工作区已修改文件与未跟踪拆分文件。

## 人类测试中心
- 人类测试中心继续拆分为多个 `toolbox_human_tests_*` part 文件，降低主文件职责。
- 计算能力测试补齐难度、题型、固定题量/限时模式、反应速度、准确率和错题报告。
- 动态视力字符识别补齐字符集、轨迹、速度、弱干扰、组合长度、即时反馈和报告；小球数量模式保持独立。
- 持续注意力测试支持目标点击、低频目标和 n-back，并新增默认关闭的目标背景高亮与点击反馈。
- 运气测试支持单抽、十连、二十连、目标抽取、概率期望幸运指数、真实批量翻卡、史诗/传说全屏特效、趣味称号和下一轮刷新。
- 手速测试升级为经典连点、目标追击和节奏命中，统计 CPS、准确率、连击和趣味报告。
- 序列记忆补齐点击高亮、正确/错误反馈和输入进度徽标。
- 斯特鲁普新增一致判断、说出墨色、读出字义和反向规则，统计反应时并生成报告。
- 时间感知开始前增加 3-2-1 倒计时，秒表在倒计时结束后启动。
- 色觉报告移除低可读性的曲线/倾向图，改为近轮色差、色相分组和差异类型统计列表。

## 摇杆手眼协调
- 全屏训练采用白底全舞台，控制、状态和会话按钮改为浮层。
- 摇杆按下才显示，抬起隐藏；未开始时允许预练习准星移动。
- 全屏顶部新增设置入口，用弹窗复用摇杆、目标移动和干扰设置。
- 手机横屏下左侧作为摇杆唤起区，右侧作为射击唤起区，中间保留缓冲区；浮层仍随触点重定位。

## 小游戏中心
- 俄罗斯轮盘补充爆炸音效资源。
- 扳机、弹仓和命中音效改为更低沉的金属质感。
- 左轮舞台拆分为 view 与 painter，补充枪管、弹巢、握把、火光和血色 overlay。
- Android `audioplayers` 本地 override 修正平台事件派发线程，避免非主线程发送平台消息。

## 文档更新
- `README.md` 新增近期进展，标记本阶段 toolbox 收口范围。
- `modules/toolbox/README.md` 同步人类测试、小游戏和摇杆全屏能力说明。
- `changelogs/CHANGELOG.md` 增补 PLAN_132 到 PLAN_135 相关变更。
- `plans/PLAN_132_人类测试中心六模块完善.md` 到 `PLAN_135_运气特效与摇杆横屏热区修正.md` 均已标记完成。

## 验证记录
- `dart analyze lib/src/ui/pages/toolbox_human_tests.dart test/toolbox_human_tests_extended_smoke_test.dart test/toolbox_color_vision_smoke_test.dart test/ui_smoke_test.dart`：通过，仅保留 `test/ui_smoke_test.dart` 既有 info 级 const/final 提示。
- `flutter test test/toolbox_human_tests_extended_smoke_test.dart --reporter compact`：通过。
- `flutter test test/toolbox_color_vision_smoke_test.dart --reporter compact`：通过。
- `flutter test test/ui_smoke_test.dart --plain-name "joystick fullscreen keeps controls off the center stage" --reporter compact`：通过。
- `flutter test test/ui_smoke_test.dart --plain-name "joystick fullscreen portrait keeps a full white stage with floating controls" --reporter compact`：通过。

## 已知风险
- 本次提交包含多个 toolbox 子域，属于阶段性整合提交；后续若继续扩大人类测试中心，建议按测试类型进一步拆分 smoke test。
- 人类测试结果仍只适合作为趣味反馈，不作为医学、心理、职业能力或教育评价依据。
- 运气测试稀有特效默认可开关，长时全屏特效不拦截点击，但仍需后续真机观察低端设备动画负载。
