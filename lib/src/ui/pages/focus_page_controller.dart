import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/focus_startup_tab.dart';
import '../../models/tomato_timer.dart';
import '../../services/focus_service.dart';

class FocusPageController {
  FocusService? _boundFocusService;
  final Map<int, GlobalKey> _todoCardKeys = <int, GlobalKey>{};
  Timer? _visualReminderTimer;
  Timer? _todoHighlightTimer;
  TomatoTimerPhase? _lastCompletedPhase;
  int? _lastOpenedReminderTodoId;
  int? _highlightedTodoId;
  bool _reminderDialogVisible = false;
  FocusStartupTab? _lastAppliedStartupTab;

  TomatoTimerPhase? get lastCompletedPhase => _lastCompletedPhase;
  int? get highlightedTodoId => _highlightedTodoId;
  bool get reminderDialogVisible => _reminderDialogVisible;

  bool bindFocusService(
    FocusService focus, {
    required void Function(TomatoTimerPhase, int) onPhaseComplete,
  }) {
    if (identical(_boundFocusService, focus)) {
      return false;
    }
    _boundFocusService?.setCallbacks();
    focus.setCallbacks(onPhaseComplete: onPhaseComplete);
    _boundFocusService = focus;
    return true;
  }

  void dispose() {
    _boundFocusService?.setCallbacks();
    _visualReminderTimer?.cancel();
    _todoHighlightTimer?.cancel();
  }

  void startVisualReminder(
    TomatoTimerPhase phase, {
    required VoidCallback refresh,
  }) {
    _visualReminderTimer?.cancel();
    _lastCompletedPhase = phase;
    refresh();
    _visualReminderTimer = Timer(const Duration(seconds: 2), () {
      _lastCompletedPhase = null;
      refresh();
    });
  }

  bool tryMarkReminderOpened(int todoId) {
    if (_lastOpenedReminderTodoId == todoId) {
      return false;
    }
    _lastOpenedReminderTodoId = todoId;
    return true;
  }

  GlobalKey todoCardKey(int todoId) {
    return _todoCardKeys.putIfAbsent(todoId, () => GlobalKey());
  }

  void highlightTodo(
    int todoId, {
    required VoidCallback refresh,
    required VoidCallback ensureVisible,
  }) {
    _todoHighlightTimer?.cancel();
    _highlightedTodoId = todoId;
    refresh();
    ensureVisible();
    _todoHighlightTimer = Timer(const Duration(seconds: 4), () {
      if (_highlightedTodoId == todoId) {
        _highlightedTodoId = null;
        refresh();
      }
    });
  }

  void setReminderDialogVisible(bool value) {
    _reminderDialogVisible = value;
  }

  bool syncConfiguredStartupTab(FocusStartupTab tab, TabController controller) {
    if (_lastAppliedStartupTab == tab) {
      return false;
    }
    _lastAppliedStartupTab = tab;
    final targetIndex = tab.index;
    if (controller.index == targetIndex) {
      return false;
    }
    controller.index = targetIndex;
    return true;
  }
}
