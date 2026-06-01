# 记录 313: 工具箱声音模块当前进度归档

## 日期
- 2026-06-01

## 范围
- 整理当前 `codex/multisampled-instrument-engine` 分支的工具箱声音与模拟乐器阶段进度。
- 归档当前未提交的 `PLAN_311` 自由风铃模块。
- 核对已提交的 `PLAN_305`、`PLAN_308`、`PLAN_309`、`PLAN_310`、`PLAN_312` 作为当前声音工具基线。

## 已完成内容
1. 多采样乐器基线
   - `PLAN_305` 已完成从小提琴方向转向拇指琴与排钟，并接入 SoundFont 优先、程序化合成 fallback 的采样路线。
   - 长笛、吉他、竖琴等既有乐器已具备采样优先和 fallback 边界，部分真实手感仍保留为后续真机确认项。
2. 敲击键盘与乐器 deck 收口
   - `PLAN_308` 和 `PLAN_309` 已完成拇指琴、木琴/排钟族、共鸣管材质、触控命中一致性和移动端舞台优化。
   - `PLAN_310` 已完成模拟乐器入口网格、全屏按钮位置和 SoundFont 卸载日志降噪。
3. 尺八气流面板
   - `PLAN_312` 已完成尺八触控气流面板可行性切片、五孔布局、全屏入口收束和说明弹窗。
   - 该切片已提交到当前分支，作为后续“触控代替麦克风吹气”方案的实验基线。
4. 自由风铃
   - `PLAN_311` 已新增 `ToolboxFreeChimeController`，支持自由模式、快板模式、强度分层、方向翻转、BPM 估算和触发节流。
   - 新增 `ToolboxFreeChimesToolPage`，接入移动端加速度传感器，支持开始/停止监听、预览、模式切换、预设、十类声部比例、灵敏度和总音量调节。
   - `ToolboxAudioBank` 已新增自由风铃 one-shot 合成音效，包括沙铃、水流、风铃、落叶、气泡、雨声、撞击、快板、锣鼓和转轮弹球。
   - 工具箱入口、模块 registry、模块管理标签、首次启动推荐和七语言 i18n catalog/registry 已同步接入。

## 验证
- `dart format` 覆盖自由风铃相关 Dart 文件与本轮触达文件。
- `flutter analyze` 覆盖自由风铃页面、控制器、音频服务、工具箱入口、模块 registry/access 与对应测试。
- `flutter test test/toolbox_free_chimes_controller_test.dart test/toolbox_audio_bank_regression_test.dart --reporter compact` 通过。
- `flutter test test/app_i18n_catalog_test.dart --reporter compact` 通过。
- `node scripts/audit_i18n_placeholders.js` 通过。
- `node scripts/maintain_i18n_catalog.js --limit 20` 通过；历史 `staleRegistrySources` 与 `unreferencedCatalogKeys` 保留，不在本轮处理。
- 旧 helper 扫描和 catalog Dart 插值扫描无命中。

## 当前基线
- 当前未提交代码主体为自由风铃模块，属于已完成可提交状态。
- 已提交的模拟乐器链路保持为当前声音工具基线，不再在本轮重复修改。
- `changelogs/CHANGELOG.md` 保留各计划线性历史，`records/` 记录阶段归档，后续新需求再开新计划。

## 不处理项
- 不进行历史 i18n catalog 瘦身；未引用 key 和旧 registry source 仍作为后续独立整理切片处理。
- 不新增自由风铃偏好持久化；页面离开后恢复默认组合。
- 不引入真实采样或远程音频素材；本轮自由风铃使用轻量程序化合成。
- 自由风铃快板模式和传感器阈值仍需实体 Android/iOS 手机后续校准。
