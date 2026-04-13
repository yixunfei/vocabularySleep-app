class ModuleIds {
  ModuleIds._();

  // Top-level navigation modules.
  static const String study = 'study';
  static const String practice = 'practice';
  static const String focus = 'focus';
  static const String toolbox = 'toolbox';
  static const String more = 'more';

  // Toolbox modules.
  static const String toolboxSleepAssistant = 'toolbox.sleep_assistant';
  static const String toolboxMiniGames = 'toolbox.mini_games';
  static const String toolboxSoothingMusic = 'toolbox.soothing_music';
  static const String toolboxSoundDeck = 'toolbox.sound_deck';
  static const String toolboxSingingBowls = 'toolbox.singing_bowls';
  static const String toolboxFocusBeats = 'toolbox.focus_beats';
  static const String toolboxWoodfish = 'toolbox.woodfish';
  static const String toolboxSchulteGrid = 'toolbox.schulte_grid';
  static const String toolboxBreathing = 'toolbox.breathing';
  static const String toolboxPrayerBeads = 'toolbox.prayer_beads';
  static const String toolboxZenSand = 'toolbox.zen_sand';
  static const String toolboxDailyDecision = 'toolbox.daily_decision';

  static const List<String> topLevelModules = <String>[
    study,
    practice,
    focus,
    toolbox,
    more,
  ];

  static const List<String> toolboxModules = <String>[
    toolboxSleepAssistant,
    toolboxMiniGames,
    toolboxSoothingMusic,
    toolboxSoundDeck,
    toolboxSingingBowls,
    toolboxFocusBeats,
    toolboxWoodfish,
    toolboxSchulteGrid,
    toolboxBreathing,
    toolboxPrayerBeads,
    toolboxZenSand,
    toolboxDailyDecision,
  ];

  static const List<String> allModules = <String>[
    ...topLevelModules,
    ...toolboxModules,
  ];
}
