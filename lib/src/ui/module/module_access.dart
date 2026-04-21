import 'package:flutter/material.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';

String localizedModuleLabel(AppI18n i18n, String moduleId) {
  return switch (moduleId) {
    ModuleIds.study => pickUiText(i18n, zh: '学习', en: 'Study'),
    ModuleIds.practice => pickUiText(i18n, zh: '练习', en: 'Practice'),
    ModuleIds.focus => pickUiText(i18n, zh: '专注', en: 'Focus'),
    ModuleIds.toolbox => pickUiText(i18n, zh: '工具箱', en: 'Toolbox'),
    ModuleIds.more => pickUiText(i18n, zh: '更多', en: 'More'),
    ModuleIds.toolboxSleepAssistant => pickUiText(
      i18n,
      zh: '睡眠助手',
      en: 'Sleep assistant',
    ),
    ModuleIds.toolboxMiniGames => pickUiText(i18n, zh: '小游戏', en: 'Mini games'),
    ModuleIds.toolboxSoothingMusic => pickUiText(
      i18n,
      zh: '舒缓音乐',
      en: 'Soothing music',
    ),
    ModuleIds.toolboxSoundDeck => pickUiText(
      i18n,
      zh: '乐器合奏台',
      en: 'Sound deck',
    ),
    ModuleIds.toolboxSingingBowls => pickUiText(
      i18n,
      zh: '疗愈音钵',
      en: 'Healing bowls',
    ),
    ModuleIds.toolboxFocusBeats => pickUiText(
      i18n,
      zh: '专注节拍',
      en: 'Focus beats',
    ),
    ModuleIds.toolboxWoodfish => pickUiText(
      i18n,
      zh: '电子木鱼',
      en: 'Digital woodfish',
    ),
    ModuleIds.toolboxSchulteGrid => pickUiText(
      i18n,
      zh: '舒尔特方格',
      en: 'Schulte grid',
    ),
    ModuleIds.toolboxBreathing => pickUiText(
      i18n,
      zh: '呼吸训练',
      en: 'Breathing practice',
    ),
    ModuleIds.toolboxPrayerBeads => pickUiText(
      i18n,
      zh: '静心念珠',
      en: 'Prayer beads',
    ),
    ModuleIds.toolboxZenSand => pickUiText(
      i18n,
      zh: '禅意沙盘',
      en: 'Zen sand tray',
    ),
    ModuleIds.toolboxDailyDecision => pickUiText(
      i18n,
      zh: '每日决策',
      en: 'Daily decision',
    ),
    _ => moduleId,
  };
}

String moduleDisabledMessage(AppI18n i18n, String moduleId) {
  final label = localizedModuleLabel(i18n, moduleId);
  return pickUiText(
    i18n,
    zh: '$label 模块当前已停用，请在设置中心的模块管理中重新开启。',
    en: '$label is currently disabled. Re-enable it in module management.',
  );
}

class ModuleDisabledView extends StatelessWidget {
  const ModuleDisabledView({
    super.key,
    required this.i18n,
    required this.moduleId,
  });

  final AppI18n i18n;
  final String moduleId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          moduleDisabledMessage(i18n, moduleId),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

bool ensureModuleRouteAccess(
  BuildContext context, {
  required AppState state,
  required String moduleId,
}) {
  if (state.isModuleEnabled(moduleId)) {
    return true;
  }
  final i18n = AppI18n(state.uiLanguage);
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    SnackBar(content: Text(moduleDisabledMessage(i18n, moduleId))),
  );
  return false;
}

Future<T?> pushModuleRoute<T>(
  BuildContext context, {
  required AppState state,
  required String moduleId,
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  if (!ensureModuleRouteAccess(context, state: state, moduleId: moduleId)) {
    return Future<T?>.value(null);
  }
  return Navigator.of(
    context,
  ).push<T>(MaterialPageRoute<T>(builder: builder, settings: settings));
}
