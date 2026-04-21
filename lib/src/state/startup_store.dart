import 'package:flutter/foundation.dart';

import '../models/app_home_tab.dart';
import '../models/focus_startup_tab.dart';
import '../models/study_startup_tab.dart';
import '../services/settings_service.dart';

class StartupStore extends ChangeNotifier {
  StartupStore({required SettingsService settings}) : _settings = settings;

  final SettingsService _settings;

  AppHomeTab _startupPage = AppHomeTab.focus;
  FocusStartupTab _focusStartupTab = FocusStartupTab.todo;
  StudyStartupTab _studyStartupTab = StudyStartupTab.play;
  bool _startupTodoPromptEnabled = false;
  String? _startupTodoPromptSuppressedDate;
  String? _startupDailyQuote;
  String _startupDailyQuoteDateKey = '';
  bool _startupDailyQuoteLoading = false;
  int? _pendingTodoReminderLaunchId;

  AppHomeTab get startupPage => _startupPage;
  FocusStartupTab get focusStartupTab => _focusStartupTab;
  StudyStartupTab get studyStartupTab => _studyStartupTab;
  bool get startupTodoPromptEnabled => _startupTodoPromptEnabled;
  String? get startupTodoPromptSuppressedDate =>
      _startupTodoPromptSuppressedDate;
  String? get startupDailyQuote => _startupDailyQuote;
  String get startupDailyQuoteDateKey => _startupDailyQuoteDateKey;
  bool get startupDailyQuoteLoading => _startupDailyQuoteLoading;
  int? get pendingTodoReminderLaunchId => _pendingTodoReminderLaunchId;

  void syncPersistentStateFromSettings() {
    final nextStartupPage = _settings.loadStartupPage();
    final nextFocusStartupTab = _settings.loadFocusStartupTab();
    final nextStudyStartupTab = _settings.loadStudyStartupTab();
    final nextStartupTodoPromptEnabled =
        _settings.loadStartupTodoPromptEnabled();
    final nextStartupTodoPromptSuppressedDate =
        _settings.loadStartupTodoPromptSuppressedDate();
    var changed = false;
    if (_startupPage != nextStartupPage) {
      _startupPage = nextStartupPage;
      changed = true;
    }
    if (_focusStartupTab != nextFocusStartupTab) {
      _focusStartupTab = nextFocusStartupTab;
      changed = true;
    }
    if (_studyStartupTab != nextStudyStartupTab) {
      _studyStartupTab = nextStudyStartupTab;
      changed = true;
    }
    if (_startupTodoPromptEnabled != nextStartupTodoPromptEnabled) {
      _startupTodoPromptEnabled = nextStartupTodoPromptEnabled;
      changed = true;
    }
    if (_startupTodoPromptSuppressedDate !=
        nextStartupTodoPromptSuppressedDate) {
      _startupTodoPromptSuppressedDate = nextStartupTodoPromptSuppressedDate;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  bool setStartupPage(AppHomeTab page, {bool persist = true}) {
    if (_startupPage == page) {
      return false;
    }
    _startupPage = page;
    if (persist) {
      _settings.saveStartupPage(page);
    }
    notifyListeners();
    return true;
  }

  bool setFocusStartupTab(FocusStartupTab tab, {bool persist = true}) {
    if (_focusStartupTab == tab) {
      return false;
    }
    _focusStartupTab = tab;
    if (persist) {
      _settings.saveFocusStartupTab(tab);
    }
    notifyListeners();
    return true;
  }

  bool setStudyStartupTab(StudyStartupTab tab, {bool persist = true}) {
    if (_studyStartupTab == tab) {
      return false;
    }
    _studyStartupTab = tab;
    if (persist) {
      _settings.saveStudyStartupTab(tab);
    }
    notifyListeners();
    return true;
  }

  bool setStartupTodoPromptEnabled(bool enabled, {bool persist = true}) {
    if (_startupTodoPromptEnabled == enabled) {
      return false;
    }
    _startupTodoPromptEnabled = enabled;
    if (persist) {
      _settings.saveStartupTodoPromptEnabled(enabled);
    }
    notifyListeners();
    return true;
  }

  bool suppressStartupTodoPromptForDate(String date, {bool persist = true}) {
    if (_startupTodoPromptSuppressedDate == date) {
      return false;
    }
    _startupTodoPromptSuppressedDate = date;
    if (persist) {
      _settings.saveStartupTodoPromptSuppressedDate(date);
    }
    notifyListeners();
    return true;
  }

  bool setStartupDailyQuoteLoading(bool loading) {
    if (_startupDailyQuoteLoading == loading) {
      return false;
    }
    _startupDailyQuoteLoading = loading;
    notifyListeners();
    return true;
  }

  bool setStartupDailyQuote({
    required String? quote,
    required String dateKey,
  }) {
    if (_startupDailyQuote == quote && _startupDailyQuoteDateKey == dateKey) {
      return false;
    }
    _startupDailyQuote = quote;
    _startupDailyQuoteDateKey = dateKey;
    notifyListeners();
    return true;
  }

  bool setPendingTodoReminderLaunchId(int? todoId) {
    if (_pendingTodoReminderLaunchId == todoId) {
      return false;
    }
    _pendingTodoReminderLaunchId = todoId;
    notifyListeners();
    return true;
  }

  int? consumePendingTodoReminderLaunchId() {
    final pending = _pendingTodoReminderLaunchId;
    if (pending == null) {
      return null;
    }
    _pendingTodoReminderLaunchId = null;
    notifyListeners();
    return pending;
  }
}
