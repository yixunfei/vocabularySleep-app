# 计划 019: Windows 本地 TTS 完成判定阻塞修复

## 基本信息
- **创建日期**: 2026-04-13
- **状态**: 已完成
- **负责人**: Codex

## 目标
1. 深入排查学习播放中 Windows 本地 TTS 播放完单词后长时间停顿、最终出现 `pollWindowsSpeakDone: TIMEOUT` 的根因。
2. 修复本地 TTS 完成判定与插件线程/窗口消息协作问题，避免单词播完后播放链路被长时间阻塞。
3. 补充回归测试，覆盖“完成回调已到但 `isSpeaking` 仍异常”以及“完成回调缺失时仍可通过轮询兜底”的场景。

## 详细步骤
1. 复核 `TtsService._speakByLocal`、`_pollWindowsSpeakDone` 与 Windows `flutter_tts` 插件的 `speak/isSpeaking/stop` 实现，确认当前阻塞发生在 Dart 侧等待还是插件侧完成通知缺失。
2. 调整 Windows 本地 TTS 的等待策略，采用完成回调优先、状态轮询兜底的双保险完成机制，避免只依赖 `isSpeaking` 导致长时间等待。
3. 修复插件中 SAPI 完成消息绑定时机，确保首句播报前就已绑定到正确的顶层窗口消息，不再依赖偶发窗口消息触发初始化。
4. 补充针对 Windows 本地 TTS 的回归测试，覆盖回调正常、回调缺失但轮询成功，以及回调先到而 `isSpeaking` 异常滞留的场景。
5. 更新 `changelogs/CHANGELOG.md` 与本计划执行结果。

## 风险评估
- **风险 1**: 若直接回退到纯回调方案，一旦插件回调偶发丢失，仍可能卡住播放链路。
- **缓解措施**: 保留轮询兜底，只是不再把轮询作为唯一完成依据。
- **风险 2**: Windows 插件窗口句柄绑定时机处理不当，可能影响现有暂停/停止事件分发。
- **缓解措施**: 仅补强 `speak()` 前的消息绑定，不改动现有事件类型和方法通道名称。
- **风险 3**: 现有工作区已有 TTS 与播放相关未提交改动，修复时容易误伤其他链路。
- **缓解措施**: 本轮仅聚焦 `lib/src/services/tts_service.dart`、`third_party/flutter_tts/windows/flutter_tts_plugin.cpp` 与对应测试文件，避免扩散。

## 依赖项
- `lib/src/services/tts_service.dart`
- `third_party/flutter_tts/windows/flutter_tts_plugin.cpp`
- `third_party/flutter_tts/lib/flutter_tts.dart`
- `test/tts_service_test.dart`
- `changelogs/CHANGELOG.md`

## 执行结果
1. 已确认学习播放链路本身仍是“逐播放单元串行等待 `TtsService.speak()` 返回再进入下一个单元”，因此单词播完后长时间停顿的直接阻塞点不在 `PlaybackService` 队列构建，而在 Windows 本地 TTS 的完成判定未能及时返回。
2. 已确认 Dart 侧原有 Windows 本地 TTS 完成判定过度依赖 `isSpeaking` 轮询，一旦插件完成回调未抵达或 `isSpeaking` 状态滞留，就会把整个播放链路卡住，最终出现 `pollWindowsSpeakDone: TIMEOUT`。
3. 已确认 Windows 桌面插件存在平台线程派发问题：
   - `MediaEnded` 回调通过自定义窗口消息回到平台线程。
   - 但消息投递使用的是 Flutter 子窗口句柄，而处理逻辑注册在顶层窗口过程上。
   - 这会导致 `speak.onComplete` 无法被消费，`isSpeaking` 长时间保持 `true`。
4. 已在 Dart 侧完成修复：
   - 关闭 `awaitSpeakCompletion(true)` 的阻塞式等待，改为 `awaitSpeakCompletion(false)`。
   - Windows 本地 TTS 改为“完成回调优先、`isSpeaking` 轮询兜底”的双保险完成机制。
   - 回调先到时立即结束等待；回调缺失时继续通过轮询判定完成；多次轮询异常或超时会主动停止并抛错，避免无界卡死。
5. 已在 Windows 插件侧完成修复：
   - Windows 桌面 `MediaPlayer` 分支改为向顶层窗口投递回调消息，并在窗口消息处理时同步更新顶层句柄，确保 `speak.onComplete` 能真正回到平台线程执行。
   - Windows 桌面 `isSpeaking` 改为优先读取 `MediaPlayer.PlaybackSession().PlaybackState()`，避免只依赖内部布尔值导致轮询兜底失效。
   - SAPI 分支同步补强完成通知绑定与状态读取逻辑，确保不同 Windows 路径下都不会再次回到单点阻塞。
6. 已完成验证：
   - `flutter test test/tts_service_test.dart`
   - `flutter test test/playback_service_test.dart`
   - `flutter build windows --debug`
