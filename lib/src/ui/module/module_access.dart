import 'package:flutter/material.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';

String localizedModuleLabel(AppI18n i18n, String moduleId) {
  return switch (moduleId) {
    ModuleIds.study => i18n.t('toolbox.sound.soothing.v2.mode.study.title'),
    ModuleIds.practice => i18n.t(
      'inline.ui.module.module_access.practice_edc3b5',
    ),
    ModuleIds.focus => i18n.t('ambientCategoryFocus'),
    ModuleIds.toolbox => i18n.t('toolbox.hub.page.title'),
    ModuleIds.more => i18n.t('inline.ui.module.module_access.more_25e68b'),
    ModuleIds.toolboxSleepAssistant => i18n.t(
      'inline.ui.module.module_access.sleep_assistant_7d7180',
    ),
    ModuleIds.toolboxMiniGames => i18n.t(
      'inline.ui.module.module_access.mini_games_e63f5e',
    ),
    ModuleIds.toolboxHumanTests => i18n.t(
      'inline.ui.module.module_access.human_tests_b16d34',
    ),
    ModuleIds.toolboxSoothingMusic => i18n.t('toolbox.sleep.assist.music'),
    ModuleIds.toolboxSoundDeck => i18n.t(
      'inline.ui.module.module_access.sound_deck_129c55',
    ),
    ModuleIds.toolboxFreeChimes => i18n.t('toolbox.free_chimes.title'),
    ModuleIds.toolboxSingingBowls => i18n.t(
      'inline.ui.module.module_access.healing_bowls_918cb2',
    ),
    ModuleIds.toolboxFocusBeats => i18n.t(
      'inline.ui.module.module_access.focus_beats_68284f',
    ),
    ModuleIds.toolboxWoodfish => i18n.t(
      'inline.ui.module.module_access.digital_woodfish_35ef49',
    ),
    ModuleIds.toolboxSchulteGrid => i18n.t(
      'inline.ui.module.module_access.schulte_grid_0e6b45',
    ),
    ModuleIds.toolboxBreathing => i18n.t(
      'inline.ui.module.module_access.breathing_practice_211f64',
    ),
    ModuleIds.toolboxPrayerBeads => i18n.t(
      'inline.ui.module.module_access.prayer_beads_2fe197',
    ),
    ModuleIds.toolboxZenSand => i18n.t(
      'inline.plan294.zen_sand.zen_sand_tray_6452b86e',
    ),
    ModuleIds.toolboxDailyDecision => i18n.t('toolbox.daily_choice.hub_title'),
    ModuleIds.toolboxLifeTools => i18n.t(
      'inline.plan294.life_hub.life_tools_292cc56d',
    ),
    ModuleIds.toolboxCryptoSecurity => i18n.t(
      'inline.ui.module.module_access.crypto_security_edbc46',
    ),
    _ => moduleId,
  };
}

String moduleDisabledMessage(AppI18n i18n, String moduleId) {
  final label = localizedModuleLabel(i18n, moduleId);
  return i18n.t(
    'inline.ui.module.module_access.label_is_currently_disabled_re_enable_it_in_module_manag_0dfbf2',
    params: <String, Object?>{'label': label},
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
