# 计划 305: 多层采样乐器引擎替换预研与落地方案

## 基本信息
- **创建日期**: 2026-05-31
- **状态**: 进行中
- **负责人**: Codex
- **建议分支**: `codex/multisampled-instrument-engine`
- **当前结论**: 已切到 `codex/multisampled-instrument-engine` 单独分支，先以钢琴 SoundFont POC 建立采样优先、程序化合成回退的最小闭环。

## 背景
当前模拟乐器主要依赖程序化合成与临时 WAV 生成。它的优势是包体可控、参数连续、没有外部授权依赖；劣势是在手机端容易把波形生成、临时文件、播放器预热和多层 UI 动画挤到同一条路径上，首次进入或快速触发时出现卡顿。

用户已判断移动端“便捷快速”的需求与复杂实时程序化乐器存在冲突，因此后续方向改为：用真实采样作为声音基准，再做轻量包络、混响、力度、音高和 UI 表达微调。

## 不在本轮处理的边界
- 本计划只记录方案，不实现代码。
- 不新增依赖，不修改 `pubspec.yaml`。
- 不替换现有模拟乐器逻辑。
- 不移动现有乐器文件结构。
- 不把大音色库直接打进当前包体。

## 目标
1. 建立可插拔 `InstrumentEngine` 抽象，让采样引擎与现有程序化引擎可并存、可回退。
2. 先以 SF2/SF3 作为最小验证路径，避免一开始接入完整 SFZ 目录树。
3. 为钢琴、吉他、长笛、小提琴、竖琴、鼓/三角铁建立基础可用音色。
4. 对古琴、疗愈音钵、木鱼等非 GM/特殊音色保留独立方案，不强行纳入通用 GM 库。
5. 以移动端首音延迟、连续触发延迟、内存、包体/缓存大小、授权清晰度作为验收核心。

## 推荐架构
### 引擎接口
- `InstrumentEngine`
  - `Future<void> load(InstrumentBankSpec bank)`
  - `Future<void> select(InstrumentPatch patch)`
  - `Future<void> noteOn(int midiNote, {double velocity, int channel})`
  - `Future<void> noteOff(int midiNote, {int channel})`
  - `Future<void> allNotesOff()`
  - `Future<void> setExpression(InstrumentExpression expression)`
  - `Future<void> dispose()`

### 实现分层
- `ProceduralInstrumentEngine`: 现有实现的包装层，作为兜底。
- `SoundFontInstrumentEngine`: SF2/SF3 验证实现，优先试 `flutter_midi_pro`。
- `SamplePackInstrumentEngine`: 未来用于精选 WAV/SFZ 转内部轻量格式，适合古琴、音钵、木鱼等非 GM 音色。

### 资源策略
- 默认不随安装包携带大型库。
- 首次进入乐器模块时按需下载基础 GM/SF2 或单乐器包，使用现有远程资源缓存。
- 缓存目录记录版本、license、来源 URL、SHA256、可用 patch 列表。
- 下载失败时回退现有程序化引擎，不阻断工具使用。

## 方案评估
### A. `flutter_midi_pro` + SF2
- **可行性**: 高，适合作为第一验证方案。
- **优点**: API 聚焦加载 SoundFont、选择乐器、播放/停止 MIDI note；Android 使用 FluidSynth，iOS/macOS 使用 AVFoundation。
- **风险**: 目前不支持 Windows/Linux/Web；Android 需要 CMake/原生构建链路，CI 和 release 构建要单独验证。
- **适用阶段**: POC 和移动端 MVP。

### B. `flutter_midi_engine` + SF2/SF3
- **可行性**: 中高，已选为首批 POC 方案。
- **优点**: 宣称支持 SF2/SF3、多通道、reverb/chorus、Android/iOS/Web。
- **风险**: 包较新、生态和下载量较小，Web 为实验性质；需重点测稳定性和后台音频行为。
- **适用阶段**: 首批 POC。原因是 API 覆盖 SF2/SF3、program change、note on/off、reverb、all notes off，且可在 Windows/Linux/Web 回退现有程序化合成。

### C. 自建 SFZ/WAV 采样播放器
- **可行性**: 中低，工程量大。
- **优点**: 对古琴、音钵、木鱼等特殊乐器最灵活；可裁剪包体。
- **风险**: 需要实现音高重采样、包络、voice stealing、loop、velocity layer、round robin、预加载和混音，容易重新变成性能工程。
- **适用阶段**: 仅在 SF2/SF3 无法覆盖某个重要乐器时做单点实现。

## 候选免费音色源
| 来源 | 格式 | 授权/注意 | 覆盖价值 | 建议用途 |
| --- | --- | --- | --- | --- |
| GeneralUser GS | SF2 | 自定义宽松授权；作者允许软件项目使用和修改，但样本来源有历史不确定性 | GM/GS，覆盖钢琴、吉他、长笛、小提琴、竖琴、鼓、三角铁 | 第一 POC，可验证完整 GM 映射 |
| MuseScore_General / FluidR3Mono_GM | SF3/SF2 | MuseScore 页面列出 MuseScore_General 为 MIT；Debian 页面说明 FluidR3Mono_GM 为 MIT | GM 覆盖完整，SF3 体积更友好 | 首批 POC 基线；优先使用约 13.8MB 的 `FluidR3Mono_GM.sf3`，下载暂存到 `dev_resources/instrument_banks/` 后再统一上传 S3 |
| FreePats | SF2/SFZ/WAV | 单库/单乐器授权需逐项检查；GM set 目前不完整 | 钢琴、吉他、竖琴、鼓等可补充 | 单乐器精修补丁，不建议只靠 GM set |
| VCSL | SFZ/WAV | CC0，授权非常清晰；体积大 | 竖琴、钢琴、打击、钟类、世界/实验音色 | 作为精选 WAV/SFZ 源，适合补特殊音色 |
| VSCO 2 Community Edition | SFZ/WAV | GitHub 标记 CC0-1.0；体积约 3GB | 管弦、钢琴、打击、长笛/小提琴/竖琴 | 只挑必要乐器，不整包进入移动端 |
| University of Iowa MIS | AIFF/WAV | 页面说明可免费下载并无限制用于任何项目 | 高质量单音采样，钢琴、吉他、长笛、小提琴等 | 需要自行转码/裁剪/映射，适合专项补采样 |
| Virtual Playing Orchestra | SFZ/WAV | 多来源混合，授权复杂；音乐使用宽松，重分发需谨慎 | 管弦综合、长音/短音 articulation | 只作参考或离线评估，不作为首批内置源 |

## 当前乐器覆盖判断
- **钢琴**: GM 库即可先覆盖；若质量不足，优先 FreePats/Salamander/Iowa 精选钢琴。
- **吉他**: GM 可覆盖基础拨弦；若要表现滑音、扫弦、泛音，需要精选 WAV 或后续专门包。
- **长笛**: GM 可覆盖普通音色；Iowa/VSCO/VCSL 可补更自然长音。
- **小提琴**: GM 可覆盖简化版；真实弓法、连奏、颤音建议后续走 SFZ/WAV 精选。
- **竖琴**: GM/FreePats/VCSL 都可候选，移动端建议优先短音采样。
- **鼓与三角铁**: GM drum kit 可覆盖；VCSL/FreePats 可补更真实打击层。
- **古琴**: 通用 GM/SoundFont 很难可靠覆盖，应保留当前方案或寻找明确授权的单独古琴采样。
- **疗愈音钵/木鱼**: 更像特殊冥想音色，不建议依赖 GM；继续走现有专用采样/合成混合路线。

## 实施阶段
### 阶段 0: 单独分支与基线
- [x] 从当前稳定点创建 `codex/multisampled-instrument-engine`。
- 记录当前程序化乐器首音延迟、连续触发延迟、内存和卡顿复现条件。
- [x] 明确首批以钢琴 POC 验证引擎，后续按低风险切片扩展；长笛/小提琴 sustain 与鼓类暂不改动。

### 阶段 1: POC
- [x] 引入 `flutter_midi_engine`，只在 Android/iOS 采样路径启用；其他平台保持程序化合成 fallback。
- [x] 下载或放置一个小体积 SoundFont 测试包。已尝试从 Debian 下载 `musescore-general-soundfont_0.2.1-1_all.deb` 到 `dev_resources/instrument_banks/`，当前网络速度过慢，未保留半成品文件；随后切换为 MuseScore 官方 GitHub 直链 `FluidR3Mono_GM.sf3` 作为首批轻量 POC bank，已暂存到 `dev_resources/instrument_banks/FluidR3Mono_GM.sf3`。
- [x] 验证钢琴 patch 的 note on/off、program change、音量和回退路径。
- [x] 接入并单测登记吉他、竖琴 GM patch 的 program/channel；采样加载失败时继续回退现有程序化发声。
- [x] 接入并单测登记长笛、小提琴 GM patch 的 program/channel；持续音通过采样核心音与现有合成细节混合回退。
- [ ] 吉他、竖琴仍需移动真机听感确认，包括快速扫弦/滑弦、竖琴滑扫与和弦共鸣触发。
- [ ] 长笛、小提琴仍需移动真机听感确认，包括长按持续音、滑动换音、多点双音和尾音释放。
- 记录 Android/iOS 原生构建问题。

### 阶段 2: 抽象与回退
- [x] 添加首批 `ToolboxSoundFontInstrumentEngine`、`ToolboxMidiSynthAdapter`、`ToolboxInstrumentBankCatalog` 与 `ToolboxNotePlayer` 抽象。
- [x] 钢琴、吉他、竖琴、长笛、小提琴页面通过 capability 判断使用采样引擎或现有引擎。
- [x] 下载缺失、加载失败、平台不支持时自动回退。
- [x] `ToolboxSoundFontInstrumentEngine` 接入 `CstCloudResourceCacheService`，钢琴页会读取 `cstCloudResourceCacheProvider`，上传 S3 后可用 `remoteKey` 直接进入既有 `remote_resource_cache` 下载/缓存路径。
- [x] 加载前执行 bank size/SHA256 校验；远程缓存损坏时删除坏缓存并尝试本地 bank fallback，下一次可重新下载。
- [ ] 内存不足、缓存清理与版本迁移仍待资源治理阶段补齐。

### 阶段 3: 资源治理
- [x] 建立 `assets/toolbox/instruments/instrument_banks.json`，记录库名、license、sourceUrl 和 patch 映射。
- [x] 建立 `dev_resources/instrument_banks/` 暂存目录并排除大文件提交。
- [x] 补齐首批 bank 的 sha256、size 和 S3 key；`FluidR3Mono_GM.sf3` 为 `14563174` bytes，SHA256 `cfcd66d89e8386823400eca64934b14fbea7bf48ba1f00d21189af1262794ec2`，远程 key 为 `SoundFont/FluidR3Mono_GM.sf3`。
- [x] 首批 bank 元数据已被加载路径实际使用，加载前会校验 size/SHA256，避免坏缓存进入 MIDI 引擎。
- [x] 用户已上传 S3 到 `SoundFont/FluidR3Mono_GM.sf3`，代码与 manifest 已切到该 key。
- [ ] 补正式 URL/HEAD 验证和移动端下载校验。
- 远程资源按 bank 下载并持久缓存。
- 加入缓存清理与版本迁移。

### 阶段 4: 移动端体验验收
- 首音延迟目标: 已缓存后 < 80ms，首次加载后第一声 < 250ms。
- 连续触发目标: 8 声以内无明显丢音，快速连击不会阻塞 UI。
- 进入页面目标: 不因加载音库阻塞首帧；显示可取消加载状态。
- 内存目标: 首批 bank 常驻内存控制在 50MB 以内；超限时分乐器卸载。

## 风险与缓解
- **授权风险**: 免费不等于可重分发。每个 bank 必须把 license 原文或链接写入 manifest，首批优先 MIT/CC0/明确允许软件项目使用的资源。
- **包体风险**: 禁止整包塞入安装包；用远程按需下载和本地缓存。
- **平台风险**: 插件对 Windows/Linux/Web 支持有限；非移动端继续用程序化 fallback。
- **性能风险**: SoundFont 加载可能一次性占内存；需要 lazy load、预热、卸载和错误兜底。
- **音色一致性风险**: 多来源音色空间感不一致；只做轻量混响/音量归一，不在首批追求录音棚级统一。
- **小提琴真实感风险**: 手机屏幕上的弓弦连续控制和 GM violin 音色都难以接近真实小提琴；后续不建议继续在当前交互上微调追真，应考虑改为简化弦乐氛围/练耳音高工具，或单独设计更适合手机的弦乐交互。
- **特殊乐器缺口**: 古琴、音钵、木鱼不强行 GM 化，单独采样或保留现有实现。

## 验证清单
- `flutter pub get`
- `flutter test test/toolbox_audio_bank_regression_test.dart --reporter compact`
- 新增采样引擎单元测试与 smoke，覆盖钢琴/吉他/竖琴/长笛/小提琴 GM patch、频率到 MIDI note 映射、持续音控制器与 fallback。
- Android release 构建。
- iOS 真机 note on/off、静音开关、后台/锁屏行为验证。
- 375dp 手机页面首帧、加载态、触控热区验证。

## 实施记录
- 2026-05-31: 创建 `codex/multisampled-instrument-engine` 分支。
- 2026-05-31: 新增 `flutter_midi_engine` 依赖、`ToolboxSoundFontInstrumentEngine`、`ToolboxMidiSynthAdapter`、`ToolboxSampledMidiNotePlayer` 和钢琴采样优先回退接入，并预留 `CstCloudResourceCacheService` 远程下载钩子。
- 2026-05-31: 新增 `assets/toolbox/instruments/instrument_banks.json` 与 `dev_resources/instrument_banks/` 资源暂存目录；下载 `FluidR3Mono_GM.sf3` 到暂存目录并记录 sha256/size。
- 2026-05-31: 钢琴采样引擎读取 `cstCloudResourceCacheProvider`；加载前校验 bank size/SHA256，远程缓存损坏时删除坏缓存并回退本地 bank。
- 2026-05-31: 用户确认 SF3 已上传到 S3 `SoundFont/FluidR3Mono_GM.sf3`；同步 remoteKey，并缓存采样引擎 program/volume/reverb 配置，单音动态走 MIDI velocity，同一按键重触发先释放活跃 note，降低移动端连续 note on 的平台通道串行开销。
- 2026-05-31: 验证 `dart analyze lib\src\services\toolbox_audio_service.dart lib\src\ui\pages\toolbox_sound_tools.dart test\toolbox_instrument_engine_test.dart`、`flutter test test\toolbox_instrument_engine_test.dart --reporter compact`、`flutter test test\toolbox_audio_bank_regression_test.dart --reporter compact`、`node scripts\audit_i18n_placeholders.js`、旧 i18n helper/catalog 插值扫描、`flutter build windows --debug`、`flutter build apk --debug`、`git diff --check` 均通过；Android debug APK 产物为 `build\app\outputs\flutter-apk\app-debug.apk`，`git diff --check` 仅提示 changelog、plan 与开发资源 README 后续 Git 触碰时会按当前 Windows 配置转换 CRLF。
- 2026-05-31: 第二扩展切片接入吉他 nylon guitar 与竖琴 orchestral harp 采样优先路径；复用同一个 `FluidR3Mono_GM.sf3`，保留程序化合成 fallback，并将长笛/小提琴 sustain 迁移顺延到独立切片。
- 2026-05-31: 第二扩展切片已验证 `dart analyze`、采样引擎测试、音频 bank 回归、i18n catalog 检查、旧 helper/catalog 插值扫描、Windows debug build、Android debug APK build 与 `git diff --check`；仍待移动真机听感确认吉他扫弦和竖琴滑扫。
- 2026-05-31: 第三扩展切片接入长笛 flute 与小提琴 violin 采样持续音；长笛采用 SoundFont core sustain + 现有 air/edge 呼吸层，小提琴采用 SoundFont bow sustain + 现有 attack/tail 表情层，并新增 `ToolboxSampledMidiSustainController` 管理 noteOn/noteOff、动态音量和换音释放。
- 2026-05-31: 第三扩展切片已验证 `dart format`、`dart analyze`、采样引擎测试、音频 bank 回归、i18n catalog 检查、旧 helper/catalog 插值扫描、Windows debug build、Android debug APK build 与 `git diff --check`；仍待手机真机确认长笛长按/换孔、小提琴滑动换音/双音与尾音释放。
- 2026-05-31: 根据真机反馈修复长笛吹气传感器在无麦克风/无权限时可能闪退的问题；启动前检查权限、WAV 编码器和输入设备，改为自管 amplitude 轮询并在异常时提示触摸播放仍可使用。同时记录小提琴真实感不足为产品方向风险，后续建议重新设计而非继续微调 GM violin。

## 参考源
- FluidSynth: https://www.fluidsynth.org/
- flutter_midi_pro: https://pub.dev/packages/flutter_midi_pro
- flutter_midi_engine: https://pub.dev/packages/flutter_midi_engine
- GeneralUser GS: https://github.com/mrbumpy409/GeneralUser-GS
- GeneralUser GS license: https://raw.githubusercontent.com/mrbumpy409/GeneralUser-GS/main/documentation/LICENSE.txt
- MuseScore SoundFonts and SFZ files: https://musescore.org/en/handbook/2/soundfonts-and-sfz-files
- Debian FluidR3Mono_GM package notes: https://packages.debian.org/sid/fluidr3mono-gm-soundfont
- FreePats: https://freepats.zenvoid.org/
- FreePats General MIDI set: https://freepats.zenvoid.org/SoundSets/general-midi.html
- VCSL: https://versilian-studios.com/vcsl/
- VSCO 2 CE: https://github.com/sgossner/VSCO-2-CE
- University of Iowa MIS: https://theremin.music.uiowa.edu/MIS.html
- Virtual Playing Orchestra: https://virtualplaying.com/virtual-playing-orchestra/
