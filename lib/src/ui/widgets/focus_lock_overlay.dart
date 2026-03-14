import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/tomato_timer.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';

/// Full-screen immersive overlay shown during focus sessions.
///
/// Covers the entire app, shows timer countdown and minimal controls.
/// Prevents accidental exit via back button (requires long-press to unlock).
class FocusLockOverlay extends StatefulWidget {
  const FocusLockOverlay({super.key});

  @override
  State<FocusLockOverlay> createState() => _FocusLockOverlayState();
}

class _FocusLockOverlayState extends State<FocusLockOverlay> {
  bool _unlockConfirming = false;
  double _unlockProgress = 0;
  Timer? _unlockTimer;

  @override
  void dispose() {
    _unlockTimer?.cancel();
    super.dispose();
  }

  void _startUnlock() {
    setState(() {
      _unlockConfirming = true;
      _unlockProgress = 0;
    });
    const steps = 30;
    var step = 0;
    _unlockTimer?.cancel();
    _unlockTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      step += 1;
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _unlockProgress = (step / steps).clamp(0.0, 1.0);
      });
      if (step >= steps) {
        timer.cancel();
        _exitLockScreen();
      }
    });
  }

  void _cancelUnlock() {
    _unlockTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _unlockConfirming = false;
      _unlockProgress = 0;
    });
  }

  void _exitLockScreen() {
    final state = context.read<AppState>();
    state.focusService.setLockScreenActive(false);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _phaseLabel(AppI18n i18n, TomatoTimerPhase phase) {
    return switch (phase) {
      TomatoTimerPhase.focus => pickUiText(i18n, zh: '专注中', en: 'Focusing'),
      TomatoTimerPhase.breakTime => pickUiText(i18n, zh: '休息中', en: 'Break'),
      TomatoTimerPhase.breakReady => pickUiText(
        i18n,
        zh: '准备休息',
        en: 'Break ready',
      ),
      TomatoTimerPhase.focusReady => pickUiText(
        i18n,
        zh: '准备专注',
        en: 'Focus ready',
      ),
      TomatoTimerPhase.idle => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final focus = state.focusService;
    final timerState = focus.state;
    final config = focus.config;
    final phase = timerState.phase;
    final isActive = phase != TomatoTimerPhase.idle;

    if (!isActive) {
      return const SizedBox.shrink();
    }

    final remaining = timerState.remainingSeconds;
    final total = timerState.totalSeconds;
    final progress = total > 0
        ? (1.0 - remaining / total).clamp(0.0, 1.0)
        : 0.0;
    final isFocusPhase = phase == TomatoTimerPhase.focus;

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Material(
          color: isFocusPhase
              ? const Color(0xF0101828)
              : const Color(0xF0142030),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                const Spacer(flex: 2),
                // Phase label
                Text(
                  _phaseLabel(i18n, phase),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                // Round indicator
                Text(
                  pickUiText(
                    i18n,
                    zh: '第 ${timerState.currentRound} / ${config.rounds} 轮',
                    en: 'Round ${timerState.currentRound} / ${config.rounds}',
                  ),
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
                const SizedBox(height: 32),
                // Timer display
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFocusPhase
                                ? const Color(0xFF60A5FA)
                                : const Color(0xFF34D399),
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(remaining),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Current word (if playing)
                if (state.isPlaying && state.currentWord != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.currentWord!.word,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(flex: 2),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Pause / Resume
                    IconButton(
                      iconSize: 40,
                      color: Colors.white70,
                      icon: Icon(
                        timerState.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                      ),
                      onPressed: () => focus.pauseOrResume(),
                    ),
                    const SizedBox(width: 24),
                    // Skip phase
                    if (timerState.isAwaitingManualTransition)
                      IconButton(
                        iconSize: 40,
                        color: Colors.white70,
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: () => focus.advanceToNextPhase(),
                      )
                    else
                      IconButton(
                        iconSize: 40,
                        color: Colors.white70,
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: () => focus.skip(),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                // Unlock hint + long-press to exit
                GestureDetector(
                  onLongPressStart: (_) => _startUnlock(),
                  onLongPressEnd: (_) => _cancelUnlock(),
                  onLongPressCancel: _cancelUnlock,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _unlockProgress,
                            minHeight: 4,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFF87171),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _unlockConfirming
                            ? pickUiText(
                                i18n,
                                zh: '松开取消',
                                en: 'Release to cancel',
                              )
                            : pickUiText(
                                i18n,
                                zh: '长按退出专注',
                                en: 'Long press to exit focus',
                              ),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
