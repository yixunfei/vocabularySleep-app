import 'app_i18n_catalog.dart';

class AppI18n {
  AppI18n(this.languageCode);

  final String languageCode;

  static const List<String> supportedLanguages = <String>[
    'zh',
    'en',
    'ja',
    'de',
    'fr',
    'es',
    'ru',
  ];

  static const Map<String, String> _languageNames = <String, String>{
    'zh': '\u4e2d\u6587',
    'en': 'English',
    'ja': '\u65e5\u672c\u8a9e',
    'de': 'Deutsch',
    'fr': 'Fran\u00e7ais',
    'es': 'Espa\u00f1ol',
    'ru': '\u0420\u0443\u0441\u0441\u043a\u0438\u0439',
  };

  static String normalizeLanguageCode(String code) {
    final lower = code.trim().toLowerCase();
    if (lower.startsWith('zh')) return 'zh';
    if (lower.startsWith('en')) return 'en';
    if (lower.startsWith('ja')) return 'ja';
    if (lower.startsWith('de')) return 'de';
    if (lower.startsWith('fr')) return 'fr';
    if (lower.startsWith('es')) return 'es';
    if (lower.startsWith('ru')) return 'ru';
    return 'en';
  }

  String languageName(String code) =>
      _languageNames[normalizeLanguageCode(code)] ?? code.toUpperCase();

  static const Map<String, String> _en = <String, String>{
    'appTitle': '咸鱼声息',
    'importWordbook': 'Import Wordbook',
    'migrateLegacy': 'Migrate Legacy DB',
    'newWordbook': 'New Wordbook',
    'addWord': 'Add Word',
    'jsonBatchImport': 'JSON Batch Import',
    'settings': 'Settings',
    'ambientAudio': 'Ambient Audio',
    'noWordbookYet': 'No wordbook yet. Import or create one first.',
    'play': 'Play',
    'pause': 'Pause',
    'resume': 'Resume',
    'skip': 'Skip',
    'stop': 'Stop',
    'ttsProvider': 'TTS Provider',
    'local': 'Local',
    'siliconFlowApi': 'SiliconFlow API',
    'customApi': 'Custom API',
    'voice': 'Voice',
    'defaultVoice': 'Default voice',
    'ttsModel': 'TTS Model',
    'ttsApiKey': 'TTS API Key',
    'ttsApiBaseUrl': 'TTS Base URL',
    'ttsModelIdHint': 'Enter model ID',
    'localVoicesNotFound':
        'No local voices found. System default voice will be used.',
    'enableAsr': 'Enable ASR follow-along',
    'asrProvider': 'ASR Provider',
    'asrLanguage': 'ASR Language (e.g. en / zh)',
    'asrLanguageAuto': 'Auto',
    'asrLanguageEnglish': 'English (en)',
    'asrLanguageChinese': 'Chinese (zh)',
    'asrLanguageJapanese': 'Japanese (ja)',
    'asrLanguageFrench': 'French (fr)',
    'asrLanguageGerman': 'German (de)',
    'asrLanguageSpanish': 'Spanish (es)',
    'asrLanguageCustom': 'Custom code',
    'asrLanguageCustomInput': 'Custom language code',
    'asrLanguageCustomInputHint': 'e.g. pt-BR / it',
    'asrModel': 'ASR Model (API mode)',
    'asrApiKey': 'ASR API Key (API mode)',
    'asrApiBaseUrl': 'ASR Base URL (Custom API)',
    'offlineWhisperBase': 'Offline (Whisper Base)',
    'offlineWhisperSmall': 'Offline (Whisper Small)',
    'asrLocalSimilarity': 'Local Similarity (No ASR)',
    'asrMultiEngine': 'Multi-Engine (Selectable)',
    'asrLocalSimilarityHint':
        'Uses current playback TTS (local or remote) to generate reference audio, then compares pronunciation locally by acoustic similarity.',
    'asrMultiEngineHint':
        'Select one or more engines. They run in order. Text ASR and acoustic similarity results will be combined when available.',
    'asrScoringMethods': 'Pronunciation Scoring Methods',
    'asrScoringMethodsHint':
        'Choose which scoring algorithms to enable. Installed packages only.',
    'asrScoringPackManager': 'Scoring Package Manager',
    'asrScoringPackInstallFirst':
        'Download package first to enable this method.',
    'asrDumpRecognitionAudio': 'Dump raw/processed recognition audio',
    'asrDumpRecognitionAudioHint':
        'Save temporary raw and processed audio files for comparison/debug.',
    'scorerSslEmbedding': 'SSL Embedding Similarity (HuBERT/wav2vec2)',
    'scorerGop': 'GOP Scoring',
    'scorerForcedAlignmentPer': 'Forced Alignment + PER',
    'scorerPpgPosterior': 'PPG Posterior Scoring',
    'asrScoringMethodApplied': 'Applied scoring: {method}',
    'asrScoringEngineApplied': 'Scored by engine: {engine}',
    'asrScoringBreakdown': 'Method breakdown',
    'asrOfflineModelManager': 'Offline Model Packages',
    'asrModelInstalled': 'Installed ({size})',
    'asrModelNotInstalled': 'Not installed (download size: {size})',
    'asrOfflineNoticeTitle': 'Offline ASR Notice',
    'asrOfflineNoticeBody':
        'Offline ASR needs an extra first-time download ({size}) and has lower accuracy. Recommended: remote API (currently free on this platform after registration).',
    'language': 'Language',
    'cancel': 'Cancel',
    'save': 'Save',
    'close': 'Close',
    'searchPlaceholder': 'Search word or content',
    'all': 'All',
    'word': 'Word',
    'meaning': 'Meaning',
    'fuzzy': 'Fuzzy',
    'go': 'Go',
    'wordsCount': '{count} words',
    'selectWord': 'Select a word',
    'toggleFavorite': 'Toggle favorite',
    'toggleTask': 'Toggle task word',
    'edit': 'Edit',
    'delete': 'Delete',
    'followAlong': 'Follow Along',
    'followAlongTitle': 'Follow Along',
    'playPronunciation': 'Play pronunciation',
    'tapToStopRecord': 'Tap to stop recording',
    'tapToStartRecord': 'Tap to start recording',
    'recognizing': 'Recognizing...',
    'recognitionFailed': 'Recognition failed',
    'great': 'Great',
    'needsPractice': 'Needs practice',
    'recognizedText': 'Recognized: {text}',
    'similarity': 'Similarity: {score}%',
    'differences': 'Differences',
    'wordbooks': 'Wordbooks',
    'rename': 'Rename',
    'mergeWordbooks': 'Merge wordbooks',
    'exportTaskWordbook': 'Export task wordbook',
    'clearTaskWordbook': 'Clear task wordbook',
    'createWordbook': 'Create wordbook',
    'wordbookName': 'Wordbook name',
    'create': 'Create',
    'renameWordbook': 'Rename wordbook',
    'deleteWordbook': 'Delete wordbook',
    'confirmDeleteWordbook': 'Delete "{name}"?',
    'confirmDeleteWord': 'Delete "{word}"?',
    'mergeDialogTitle': 'Merge wordbooks',
    'sourceWordbook': 'Source wordbook',
    'targetWordbook': 'Target wordbook',
    'deleteSourceAfterMerge': 'Delete source after merge',
    'needTwoWordbooks': 'Need at least two custom wordbooks.',
    'addWordTitle': 'Add word',
    'editWordTitle': 'Edit word',
    'fieldWord': 'Word',
    'fieldMeaning': 'Meaning',
    'fieldExamples': 'Examples',
    'fieldEtymology': 'Etymology',
    'fieldRoots': 'Roots',
    'fieldAffixes': 'Affixes',
    'fieldVariations': 'Variations',
    'fieldMemory': 'Memory',
    'fieldStory': 'Story',
    'fieldContent': 'Field Content',
    'fieldKey': 'Field Key',
    'fieldLabel': 'Field Label',
    'fieldKeyPlaceholder': 'Enter field key (e.g. roots)',
    'fieldLabelPlaceholder': 'Enter field label (e.g. Roots)',
    'fieldStyleTitle': 'Field Style',
    'fieldStyleBackground': 'Card background color',
    'fieldStyleBorder': 'Card border color',
    'fieldStyleText': 'Text color',
    'fieldStyleAccent': 'Title accent color',
    'fieldStyleHint': '#RRGGBB or #AARRGGBB',
    'fieldCopied': 'Field copied',
    'copyField': 'Copy',
    'editField': 'Edit Field',
    'deleteField': 'Delete Field',
    'deleteFieldTitle': 'Delete Field',
    'deleteFieldMessage': 'Delete field "{field}"?',
    'editFieldTitle': 'Edit Field: {field}',
    'addField': 'Add Field',
    'expandEmptyFields': 'Expand Empty Fields',
    'collapseEmptyFields': 'Collapse Empty Fields',
    'emptyFieldsDetected': 'Empty fields detected',
    'deleteWordInEditor': 'Delete Word',
    'specialWordbooks': 'Task & Favorites',
    'manageWordbook': 'Wordbook Management',
    'playbackVolume': 'Playback Volume',
    'masterVolume': 'Master Volume',
    'playbackSpeed': 'Playback Speed',
    'wordRepeat': 'Word repeat',
    'meaningRepeat': 'Meaning repeat',
    'exampleRepeat': 'Example repeat',
    'spellingLabel': 'Spelling',
    'nonCoreRepeat': 'Non-core Repeat',
    'applyToAllNonCore': 'Apply to All',
    'currentPlayingList': 'Current Playing',
    'currentWord': 'Current Word',
    'progress': 'Progress',
    'startFrom': 'Start from',
    'prev': 'Prev',
    'next': 'Next',
    'testMode': 'Test Mode',
    'backToTop': 'Back to Top',
    'showHint': 'Show Hint',
    'hideHint': 'Hide Hint',
    'revealAnswer': 'Reveal Answer',
    'hideAnswer': 'Hide Answer',
    'testModeEnabledHint': 'Test mode is enabled',
    'coreRepeat': 'Core Repeat',
    'overallLoop': 'Overall Loop',
    'delayBetweenUnits': 'Delay Between Units (ms)',
    'showText': 'Show text',
    'saveAndApply': 'Save & Apply',
    'download': 'Download',
    'processing': 'Processing...',
    'busyInitializingApp': 'Preparing your library...',
    'busyInitializingHint':
        'Loading local settings and data. This may take a moment.',
    'busyLoadingWordbook': 'Loading wordbook...',
    'busyImportingWordbook': 'Importing wordbook...',
    'busyMigratingLegacyData': 'Migrating legacy data...',
    'busyMergingWordbooks': 'Merging wordbooks...',
    'busyResettingUserData': 'Resetting local data...',
    'busyRestoringBackup': 'Restoring backup...',
    'busyPatienceHint': 'This wordbook may be large. Please wait patiently.',
    'settingsTabPlayback': 'Playback',
    'settingsTabVoice': 'Voice',
    'settingsTabAsr': 'Recognition',
    'settingsTabAppearance': 'Appearance',
    'appearanceThemeTitle': 'Theme',
    'appearanceReset': 'Reset',
    'appearanceSaveCustomTheme': 'Save as Custom Theme',
    'appearanceCustomThemes': 'Custom Themes',
    'appearanceCustomThemePrefix': 'Custom Theme',
    'appearanceTypographyTitle': 'Typography',
    'appearanceFontFamily': 'Font family',
    'appearanceFontFamilySystem': 'System',
    'appearanceFontFamilySerif': 'Serif',
    'appearanceFontFamilyMono': 'Monospace',
    'appearanceFontFamilyRounded': 'Rounded',
    'appearanceFontScale': 'Font scale',
    'appearanceFontScaleHint': 'Scale all text globally for readability.',
    'appearanceTitleWeight': 'Title weight',
    'appearanceBodyWeight': 'Body weight',
    'appearanceWeightRegular': 'Regular',
    'appearanceWeightMedium': 'Medium',
    'appearanceWeightSemibold': 'Semibold',
    'appearanceWeightBold': 'Bold',
    'appearanceLayoutTitle': 'Layout',
    'appearanceLayoutHint':
        'Layout details will be refined in the next iteration.',
    'appearanceCompactLayout': 'Compact layout',
    'appearanceCompactLayoutHint':
        'Reduce paddings and control heights for denser display.',
    'appearanceColorsTitle': 'Colors',
    'appearanceColorsHint':
        'Color details will be refined in the next iteration.',
    'appearanceHighContrastText': 'High contrast text',
    'appearanceHighContrastTextHint':
        'Use stronger text contrast for better readability.',
    'appearanceGradientIntensity': 'Gradient intensity',
    'appearanceGradientIntensityHint':
        'Control how vivid the gradient and color transitions appear.',
    'appearanceBackgroundTitle': 'Background',
    'appearanceBackgroundHint':
        'Background details will be refined in the next iteration.',
    'appearanceEnhancedBackground': 'Enhanced background',
    'appearanceEnhancedBackgroundHint':
        'Use richer page gradients and atmosphere.',
    'appearanceFrostedPanels': 'Frosted panels',
    'appearanceFrostedPanelsHint':
        'Use translucent glass-like surfaces for panels and cards.',
    'appearancePreviewTitle': 'Preview',
    'appearancePreviewHint':
        'Theme and appearance changes take effect after Save & Apply.',
    'appearanceFieldSectionsTitle': 'Field Sections',
    'appearanceFieldSectionsHint':
        'Field section styles will be refined in the next iteration.',
    'appearanceSidebarOpacity': 'Sidebar opacity',
    'appearanceSidebarOpacityHint':
        'Set transparency for the left wordbook/navigation module.',
    'appearanceDetailOpacity': 'Detail panel opacity',
    'appearanceDetailOpacityHint':
        'Set transparency for the main word detail module.',
    'appearancePlaybackOpacity': 'Playback bar opacity',
    'appearancePlaybackOpacityHint':
        'Set transparency for the bottom playback control module.',
    'appearanceFieldOpacity': 'Field card opacity',
    'appearanceFieldOpacityHint':
        'Set transparency for meaning/example/etymology field cards.',
    'appearanceFieldGradientAccent': 'Field gradient accent',
    'appearanceFieldGradientAccentHint':
        'Apply subtle accent gradients per field item.',
    'appearanceFieldGlow': 'Field glow effect',
    'appearanceFieldGlowHint':
        'Enable soft glow around field cards to emphasize content blocks.',
    'appearanceEffectIntensity': 'Effect intensity',
    'appearanceEffectIntensityHint':
        'Control shadow, glow, and visual depth strength.',
    'appearancePlaybackGlow': 'Playback glow effect',
    'appearancePlaybackGlowHint':
        'Highlight the active playback bar when audio is playing.',
    'appearanceColorBackground': 'Global background color',
    'appearanceBackgroundGradientStart': 'Background gradient start',
    'appearanceBackgroundGradientEnd': 'Background gradient end',
    'appearanceColorAccent': 'Global accent color',
    'appearanceColorBorder': 'Global border color',
    'appearanceColorSidebar': 'Sidebar module color',
    'appearanceColorDetail': 'Detail module color',
    'appearanceColorPlayback': 'Playback module color',
    'appearanceColorField': 'Field item color',
    'appearanceEffectsTitle': 'Visual effects',
    'appearanceRandomEntryColors': 'Random entry colors',
    'appearanceRandomEntryColorsHint':
        'Cycle field-card accent colors while browsing words.',
    'appearanceRainbowText': 'Rainbow text',
    'appearanceRainbowTextHint':
        'Render the current-word title with multi-color gradient text.',
    'appearanceMarqueeText': 'Marquee title',
    'appearanceMarqueeTextHint':
        'Scroll long current-word titles horizontally like a marquee.',
    'appearanceBreathingEffect': 'Breathing effect',
    'appearanceBreathingEffectHint':
        'Apply subtle rhythmic scale animation to active title and controls.',
    'appearanceFlowingEffect': 'Flowing effect',
    'appearanceFlowingEffectHint':
        'Animate gradient direction for background and rainbow text.',
    'appearanceBackgroundImage': 'Background image',
    'appearanceBackgroundImageHint': 'Set local file path or use picker below.',
    'appearanceBackgroundImagePick': 'Pick image',
    'appearanceBackgroundImageClear': 'Clear image',
    'appearanceBackgroundImageMode': 'Image mode',
    'appearanceBackgroundImageOpacity': 'Image opacity',
    'appearanceBackgroundImageOpacityHint':
        'Control transparency for the background image.',
    'appearanceBgModeCover': 'Fill cover',
    'appearanceBgModeContain': 'Contain fit',
    'appearanceBgModeStretch': 'Stretch fill',
    'appearanceBgModeTop': 'Top aligned',
    'appearanceBgModeTile': 'Tile repeat',
    'themeFlat': 'Flat Blue',
    'themeTech': 'Tech Blue',
    'themeDark': 'Dark',
    'themeFantasy': 'Fantasy',
    'themeNature': 'Nature',
    'themeSunset': 'Sunset',
    'themeOcean': 'Ocean',
    'themeMono': 'Mono',
    'noAudioSources': 'No audio sources',
    'importAudio': 'Import audio file',
    'importedAudio': 'Imported Audio',
    'ambientCategoryNoise': 'Noise',
    'ambientCategoryNature': 'Nature',
    'ambientCategoryRain': 'Rain',
    'ambientCategoryFocus': 'Focus',
    'ambientCategoryAnimals': 'Animals',
    'ambientCategoryUrban': 'Urban',
    'ambientCategoryPlaces': 'Places',
    'ambientCategoryTransport': 'Transport',
    'ambientCategoryThings': 'Things',
    'ambientCategoryBinaural': 'Binaural',
    'ambientNameNoiseWhite': 'White Noise',
    'ambientNameNoisePink': 'Pink Noise',
    'ambientNameNoiseBrown': 'Brown Noise',
    'ambientNameNatureWind': 'Wind',
    'ambientNameNatureForest': 'Wind in Trees',
    'ambientNameNatureFire': 'Campfire',
    'ambientNameNatureOcean': 'Waves',
    'ambientNameRainLight': 'Light Rain',
    'ambientNameRainHeavy': 'Heavy Rain',
    'ambientNameFocusLibrary': 'Library',
    'ambientNameFocusCafe': 'Cafe',
    'ambientNameFocusNightVillage': 'Night Village',
    'jumpByLetter': 'Jump by letter',
    'jumpByPrefix': 'Jump by prefix',
    'jumpNoMatch': 'No words matching "{value}"',
    'importedWordbookName': 'Imported Wordbook',
    'errorInitFailed': 'Initialization failed: {error}',
    'errorCreateWordbookFailed': 'Create wordbook failed: {error}',
    'errorRenameWordbookFailed': 'Rename failed: {error}',
    'errorDeleteWordbookFailed': 'Delete wordbook failed: {error}',
    'importWordbookSuccess': 'Imported {count} words',
    'importWordbookSuccessWithBackup': 'Imported {count} words (backup saved)',
    'errorImportFailed': 'Import failed: {error}',
    'migrationSuccess': 'Migration completed, {count} rows imported',
    'migrationSuccessWithBackup':
        'Migration completed, {count} rows imported (backup saved)',
    'errorMigrationFailed': 'Migration failed: {error}',
    'errorWordEmpty': 'Word cannot be empty',
    'errorSaveWordFailed': 'Save word failed: {error}',
    'errorDeleteWordFailed': 'Delete word failed: {error}',
    'errorFavoriteOperationFailed': 'Favorite operation failed: {error}',
    'errorTaskOperationFailed': 'Task operation failed: {error}',
    'errorClearTaskWordbookFailed': 'Clear task wordbook failed: {error}',
    'errorExportFailed': 'Export failed: {error}',
    'errorResetUserDataFailed': 'Reset local data failed: {error}',
    'errorMergeFailed': 'Merge failed: {error}',
    'recordingFailed': 'Recording failed',
    'startRecordingFailed':
        'Failed to start recording. Please check microphone permission.',
    'enableAsrFirst': 'Please enable ASR in Settings first.',
    'playCurrent': 'Play Current',
    'asrDisabled': 'ASR is disabled.',
    'asrAudioFileNotFound': 'Audio file not found.',
    'asrApiKeyMissing': 'ASR API key is missing.',
    'asrApiBaseUrlMissing': 'ASR API base URL is missing.',
    'asrApiTimeout': 'ASR request timed out.',
    'asrApiRequestFailed': 'ASR API request failed ({code}). {body}',
    'asrRequestFailed': 'ASR request failed: {error}',
    'asrEmptyResult': 'No speech recognized.',
    'asrInvalidWav': 'Invalid recording format.',
    'asrRecordingTooShort': 'Recording is too short.',
    'asrNoSpeechDetected': 'No speech detected in recording.',
    'asrRecognitionCancelled': 'Recognition was cancelled.',
    'asrLocalSimilarityNoTranscript':
        'No transcript in local similarity mode (audio score only).',
    'asrSimilarityExpectedTextMissing':
        'Target word is missing for local similarity mode.',
    'asrSimilarityTtsMissing':
        'TTS config is missing for local similarity mode.',
    'asrSimilarityRequiresRemoteTts':
        'Local similarity mode requires available TTS reference audio.',
    'asrSimilarityTtsApiKeyMissing':
        'TTS API key is missing for local similarity mode.',
    'asrSimilarityTtsBaseUrlMissing':
        'TTS Base URL is missing for local similarity mode.',
    'asrSimilarityLocalSynthesisUnsupported':
        'Current platform cannot export local TTS reference audio. Switch to remote TTS.',
    'asrSimilarityReferenceInvalid':
        'Failed to generate valid reference audio for similarity compare.',
    'asrSimilarityReferenceFailedHttp':
        'Reference audio request failed ({code}). {body}',
    'asrSimilarityFeatureInsufficient':
        'Audio is too short or unclear for similarity compare.',
    'asrSimilarityFailed': 'Local similarity compare failed: {error}',
    'asrScoringPackNotInstalled':
        'No selected scoring package is installed. Please download at least one.',
    'asrScoringPackUnsupported': 'Unsupported scoring package.',
    'asrMultiEngineNoResult':
        'No engine produced a valid result. Please adjust engine selection.',
    'asrOfflineFailed': 'Offline ASR failed: {error}',
    'asrOfflineInitFailed': 'Offline ASR initialization failed.',
    'asrUnsupportedOfflineProvider': 'Unsupported offline ASR provider.',
    'asrModelMissingAfterExtract': 'ASR model files are missing after extract.',
    'asrModelExtractionIncomplete': 'ASR model extraction is incomplete.',
    'asrDownloadFailedHttp': 'ASR model download failed ({code}).',
    'asrProgressStoppingRecording': 'Stopping recording...',
    'asrProgressPreparing': 'Preparing ASR...',
    'asrProgressDownloading': 'Downloading ASR model...',
    'asrProgressDownloadDone': 'ASR model download completed.',
    'asrProgressExtracting': 'Extracting ASR model...',
    'asrProgressExtractDone': 'ASR model extraction completed.',
    'asrProgressLoadingModel': 'Loading ASR model...',
    'asrProgressDecoding': 'Recognizing speech...',
    'asrProgressDone': 'Recognition completed.',
    'pronunciationDiffMissing': 'Missing: {value}',
    'pronunciationDiffExtra': 'Extra: {value}',
    'pronunciationDiffReplace': 'Expected "{from}", heard "{to}"',
    'focusTitle': 'Focus',
    'timerTab': 'Timer',
    'todoTab': 'Tasks',
    'timerIdle': 'Ready',
    'focusPhase': 'Focus',
    'breakPhase': 'Break',
    'breakReady': 'Break ready',
    'focusReady': 'Next round ready',
    'focusPhaseComplete': 'Focus session complete!',
    'breakPhaseComplete': 'Break time over!',
    'roundProgress': 'Round {current} of {total}',
    'startFocus': 'Start Focus',
    'startBreak': 'Start Break',
    'startNextRound': 'Start Next Round',
    'timerConfig': 'Timer Settings',
    'focusMinutes': 'Focus (min)',
    'breakMinutes': 'Break (min)',
    'rounds': 'Rounds',
    'autoStartBreak': 'Auto-start break',
    'autoStartNextRound': 'Auto-start next round',
    'timerWaitingAction': 'Waiting for your action',
    'stopTimer': 'Stop Timer',
    'stopTimerConfirm': 'Stop the timer and save progress?',
    'todayStats': 'Today\'s Stats',
    'focusMinutesLabel': 'Focus Minutes',
    'sessionMinutesLabel': 'Session Minutes',
    'roundsLabel': 'Rounds',
    'addTodo': 'Add task',
    'addTodoHint': 'Add a new task...',
    'clearCompleted': 'Clear Completed',
    'quickNotes': 'Quick Notes',
    'addNote': 'Add Note',
    'editNote': 'Edit Note',
    'deleteNote': 'Delete Note',
    'deleteNoteConfirm': 'Delete this note?',
    'noteTitle': 'Title',
    'noteContent': 'Content',
  };

  static const Map<String, String> _zhBase = <String, String>{
    'appTitle': '咸鱼声息',
    'importWordbook': '导入单词本',
    'newWordbook': '新建单词本',
    'addWord': '添加单词',
    'jsonBatchImport': 'JSON 批量导入',
    'settings': '设置',
    'play': '播放',
    'pause': '暂停',
    'resume': '继续',
    'stop': '停止',
    'ttsProvider': 'TTS 提供方',
    'local': '本地',
    'siliconFlowApi': 'SiliconFlow API',
    'customApi': '自定义 API',
    'voice': '音色',
    'ttsModel': 'TTS 模型',
    'ttsApiKey': 'TTS API Key',
    'ttsApiBaseUrl': 'TTS Base URL',
    'enableAsr': '启用跟读识别',
    'asrProvider': 'ASR 提供方',
    'asrLanguage': 'ASR 语言',
    'asrLanguageAuto': '自动',
    'asrLanguageEnglish': '英语 (en)',
    'asrLanguageChinese': '中文 (zh)',
    'asrLanguageJapanese': '日语 (ja)',
    'asrLanguageFrench': '法语 (fr)',
    'asrLanguageGerman': '德语 (de)',
    'asrLanguageSpanish': '西班牙语 (es)',
    'asrLanguageCustom': '自定义代码',
    'asrLanguageCustomInput': '自定义语言代码',
    'asrModel': 'ASR 模型（API 模式）',
    'asrApiKey': 'ASR API Key（API 模式）',
    'asrApiBaseUrl': 'ASR Base URL（自定义 API）',
    'offlineWhisperBase': '离线（Whisper Base）',
    'offlineWhisperSmall': '离线（Whisper Small）',
    'asrOfflineNoticeTitle': '离线识别提示',
    'asrOfflineNoticeBody':
        '离线识别首次使用需额外下载（{size}），且识别率较低。建议使用远程 API（当前平台免费，仅需注册）。',
    'saveAndApply': '保存并应用',
    'settingsTabPlayback': '播放',
    'settingsTabVoice': '语音',
    'settingsTabAsr': '识别',
    'settingsTabAppearance': '外观',
    'cancel': '取消',
    'close': '关闭',
    'playbackVolume': '播放音量',
    'playbackSpeed': '播放速度',
    'asrDisabled': 'ASR 未启用。',
    'asrAudioFileNotFound': '未找到录音文件。',
    'asrApiKeyMissing': '缺少 ASR API Key。',
    'asrApiBaseUrlMissing': '缺少 ASR Base URL。',
    'asrApiTimeout': 'ASR 请求超时。',
    'asrApiRequestFailed': 'ASR 接口请求失败（{code}）。{body}',
    'asrRequestFailed': 'ASR 请求失败：{error}',
    'asrEmptyResult': '未识别到有效语音。',
    'asrInvalidWav': '录音格式无效。',
    'asrRecordingTooShort': '录音时长过短。',
    'asrNoSpeechDetected': '录音中未检测到语音。',
    'asrRecognitionCancelled': '识别已取消。',
    'asrOfflineFailed': '离线识别失败：{error}',
    'asrOfflineInitFailed': '离线识别初始化失败。',
    'asrUnsupportedOfflineProvider': '不支持的离线识别提供方。',
    'asrModelMissingAfterExtract': '模型解压后缺少必要文件。',
    'asrModelExtractionIncomplete': '模型解压不完整。',
    'asrDownloadFailedHttp': '模型下载失败（{code}）。',
    'asrProgressStoppingRecording': '正在停止录音...',
    'asrProgressPreparing': '正在准备识别...',
    'asrProgressDownloading': '正在下载识别模型...',
    'asrProgressDownloadDone': '识别模型下载完成。',
    'asrProgressExtracting': '正在解压识别模型...',
    'asrProgressExtractDone': '识别模型解压完成。',
    'asrProgressLoadingModel': '正在加载识别模型...',
    'asrProgressDecoding': '正在识别语音...',
    'asrProgressDone': '识别完成。',
    'pronunciationDiffMissing': '缺少：{value}',
    'pronunciationDiffExtra': '多出：{value}',
    'pronunciationDiffReplace': '应为“{from}”，识别为“{to}”',
  };

  static const Map<String, String> _zhExtra = <String, String>{
    'addField': '添加字段',
    'addWord': '添加单词',
    'addWordTitle': '添加单词',
    'jsonBatchImport': 'JSON 批量导入',
    'all': '全部',
    'ambientAudio': '环境音',
    'ambientCategoryFocus': '专注',
    'ambientCategoryNature': '自然',
    'ambientCategoryNoise': '白噪音',
    'ambientCategoryRain': '雨声',
    'ambientCategoryAnimals': '动物',
    'ambientCategoryUrban': '城市',
    'ambientCategoryPlaces': '场所',
    'ambientCategoryTransport': '交通',
    'ambientCategoryThings': '器物',
    'ambientCategoryBinaural': '双耳节拍',
    'appearanceBackgroundGradientEnd': '背景渐变终点',
    'appearanceBackgroundGradientStart': '背景渐变起点',
    'appearanceBackgroundHint': '调整页面背景与纹理层次。',
    'appearanceBackgroundImage': '背景图片',
    'appearanceBackgroundImageClear': '清除图片',
    'appearanceBackgroundImageHint': '可填写本地文件路径，或使用下方图片选择器。',
    'appearanceBackgroundImageMode': '图片模式',
    'appearanceBackgroundImageOpacity': '图片透明度',
    'appearanceBackgroundImageOpacityHint': '控制背景图片的透明程度。',
    'appearanceBackgroundImagePick': '选择图片',
    'appearanceBackgroundTitle': '背景',
    'appearanceBgModeContain': '完整显示',
    'appearanceBgModeCover': '覆盖填充',
    'appearanceBgModeStretch': '拉伸铺满',
    'appearanceBgModeTile': '平铺重复',
    'appearanceBgModeTop': '顶部对齐',
    'appearanceBodyWeight': '正文字重',
    'appearanceBreathingEffect': '呼吸效果',
    'appearanceBreathingEffectHint': '为当前标题和控件加入轻微的律动缩放动画。',
    'appearanceColorAccent': '全局强调色',
    'appearanceColorBackground': '全局背景色',
    'appearanceColorBorder': '全局边框色',
    'appearanceColorDetail': '详情模块颜色',
    'appearanceColorField': '字段卡片颜色',
    'appearanceColorPlayback': '播放模块颜色',
    'appearanceColorSidebar': '侧边栏模块颜色',
    'appearanceColorsHint': '调整主色、强调色与透明度。',
    'appearanceColorsTitle': '配色',
    'appearanceCompactLayout': '紧凑布局',
    'appearanceCompactLayoutHint': '减少内边距和控件高度，让信息排列更紧凑。',
    'appearanceCustomThemePrefix': '自定义主题',
    'appearanceCustomThemes': '自定义主题',
    'appearanceDetailOpacity': '详情面板透明度',
    'appearanceDetailOpacityHint': '设置主词条详情模块的透明度。',
    'appearanceEffectIntensity': '特效强度',
    'appearanceEffectIntensityHint': '控制阴影、发光和视觉层次的强度。',
    'appearanceEffectsTitle': '视觉特效',
    'appearanceEnhancedBackground': '增强背景氛围',
    'appearanceEnhancedBackgroundHint': '使用更丰富的页面渐变和氛围层次。',
    'appearanceFieldGlow': '字段发光效果',
    'appearanceFieldGlowHint': '为字段卡片添加柔和光晕，突出内容区块。',
    'appearanceFieldGradientAccent': '字段渐变强调',
    'appearanceFieldGradientAccentHint': '为各字段卡片添加轻微强调渐变。',
    'appearanceFieldOpacity': '字段卡片透明度',
    'appearanceFieldOpacityHint': '设置释义、例句、词源等字段卡片的透明度。',
    'appearanceFieldSectionsHint': '控制单词字段模块的显示与顺序。',
    'appearanceFieldSectionsTitle': '字段模块',
    'appearanceFlowingEffect': '流动效果',
    'appearanceFlowingEffectHint': '为背景和渐变文字添加流动方向动画。',
    'appearanceFontFamily': '字体家族',
    'appearanceFontFamilyMono': '等宽',
    'appearanceFontFamilyRounded': '圆角',
    'appearanceFontFamilySerif': '衬线',
    'appearanceFontFamilySystem': '系统字体',
    'appearanceFontScale': '字号缩放',
    'appearanceFontScaleHint': '统一调整全局文字大小，提高可读性。',
    'appearanceFrostedPanels': '毛玻璃面板',
    'appearanceFrostedPanelsHint': '为卡片和面板启用半透明玻璃质感。',
    'appearanceGradientIntensity': '渐变强度',
    'appearanceGradientIntensityHint': '控制渐变和颜色过渡的鲜明程度。',
    'appearanceHighContrastText': '高对比文本',
    'appearanceHighContrastTextHint': '使用更强的文字对比度，提升阅读清晰度。',
    'appearanceLayoutHint': '调整布局密度与卡片样式。',
    'appearanceLayoutTitle': '布局',
    'appearanceMarqueeText': '跑马灯标题',
    'appearanceMarqueeTextHint': '让过长的当前单词标题像跑马灯一样横向滚动。',
    'appearancePlaybackGlow': '播放发光效果',
    'appearancePlaybackGlowHint': '播放音频时高亮当前播放栏。',
    'appearancePlaybackOpacity': '播放栏透明度',
    'appearancePlaybackOpacityHint': '设置底部播放控制模块的透明度。',
    'appearancePreviewHint': '主题和外观调整会在保存并应用后生效。',
    'appearancePreviewTitle': '预览',
    'appearanceRainbowText': '彩虹文字',
    'appearanceRainbowTextHint': '让当前单词标题显示为多色渐变文字。',
    'appearanceRandomEntryColors': '随机词条配色',
    'appearanceRandomEntryColorsHint': '浏览单词时轮换字段卡片的强调色。',
    'appearanceReset': '重置',
    'appearanceSaveCustomTheme': '保存为自定义主题',
    'appearanceSidebarOpacity': '侧边栏透明度',
    'appearanceSidebarOpacityHint': '设置左侧词本/导航模块的透明度。',
    'appearanceThemeTitle': '主题',
    'appearanceTitleWeight': '标题字重',
    'appearanceTypographyTitle': '字体排版',
    'appearanceWeightBold': '粗体',
    'appearanceWeightMedium': '中等',
    'appearanceWeightRegular': '常规',
    'appearanceWeightSemibold': '中粗',
    'applyToAllNonCore': '应用到全部非核心',
    'appTitle': '咸鱼声息',
    'asrApiBaseUrl': 'ASR Base URL',
    'asrApiBaseUrlMissing': '请先填写 ASR Base URL',
    'asrApiKey': 'ASR API Key',
    'asrApiKeyMissing': '请先填写 ASR API Key',
    'asrApiRequestFailed': 'ASR 请求失败（HTTP {code}）：{body}',
    'asrApiTimeout': 'ASR 请求超时',
    'asrAudioFileNotFound': '未找到可用录音文件',
    'asrDisabled': 'ASR 已禁用',
    'asrDownloadFailedHttp': '模型下载失败（HTTP {code}）',
    'asrDumpRecognitionAudio': '保存识别原始/处理音频',
    'asrDumpRecognitionAudioHint': '保存临时原始和处理后的音频用于对比调试',
    'asrLanguage': 'ASR 语言',
    'asrLanguageAuto': '自动',
    'asrLanguageChinese': '中文 (zh)',
    'asrLanguageCustom': '自定义代码',
    'asrLanguageCustomInput': '输入自定义语言代码',
    'asrLanguageCustomInputHint': '例如：pt-BR / it',
    'asrLanguageEnglish': '英语 (en)',
    'asrLanguageFrench': '法语 (fr)',
    'asrLanguageGerman': '德语 (de)',
    'asrLanguageJapanese': '日语 (ja)',
    'asrLanguageSpanish': '西班牙语 (es)',
    'asrEmptyResult': '未识别到有效文本',
    'asrInvalidWav': '音频格式无效，请使用 WAV',
    'asrLocalSimilarity': '本地相似度（无 ASR）',
    'asrLocalSimilarityHint': '使用当前朗读 TTS（本地或远程）生成参考音频，再在本地按声学相似度比较发音。',
    'asrLocalSimilarityNoTranscript': '本地相似度模式未返回转写文本',
    'asrModel': 'ASR 模型（API 模式）',
    'asrModelExtractionIncomplete': '模型解压不完整，请重试下载',
    'asrModelInstalled': '已安装（{size}）',
    'asrModelMissingAfterExtract': '解压后未找到模型文件',
    'asrModelNotInstalled': '未安装（下载大小：{size}）',
    'asrMultiEngine': '多引擎（可选）',
    'asrMultiEngineHint': '可选择一个或多个引擎并按顺序执行，文本识别与声学相似度结果会在可用时合并。',
    'asrMultiEngineNoResult': '多引擎未返回可用识别结果',
    'asrOfflineModelManager': '离线模型包管理',
    'asrOfflineFailed': '离线识别失败：{error}',
    'asrOfflineInitFailed': '离线识别初始化失败',
    'asrOfflineNoticeBody':
        '离线识别首次使用需额外下载（{size}），且识别率较低。推荐使用远程 API（当前平台注册后可免费使用）。',
    'asrOfflineNoticeTitle': '离线识别提示',
    'asrNoSpeechDetected': '未检测到语音，请重试',
    'asrProgressDecoding': '正在识别语音...',
    'asrProgressDone': '识别完成',
    'asrProgressDownloadDone': '识别模型下载完成',
    'asrProgressDownloading': '正在下载识别模型...',
    'asrProgressExtractDone': '识别模型解压完成',
    'asrProgressExtracting': '正在解压识别模型...',
    'asrProgressLoadingModel': '正在加载识别模型...',
    'asrProgressPreparing': '正在准备识别...',
    'asrProgressStoppingRecording': '正在停止录音...',
    'asrProvider': 'ASR 提供方',
    'asrRecognitionCancelled': '识别已取消',
    'asrRecordingTooShort': '录音时间过短，请重试',
    'asrRequestFailed': 'ASR 请求失败：{error}',
    'asrScoringBreakdown': '评分明细',
    'asrScoringEngineApplied': '评分引擎：{engine}',
    'asrScoringMethodApplied': '已应用评分：{method}',
    'asrScoringMethods': '发音评分算法',
    'asrScoringMethodsHint': '选择要启用的评分算法（仅已安装算法可用）',
    'asrScoringPackInstallFirst': '需先下载对应评分包后才能启用',
    'asrScoringPackManager': '评分包管理',
    'asrScoringPackNotInstalled': '未检测到已安装的评分包，请先下载至少一个。',
    'asrScoringPackUnsupported': '当前平台不支持该评分包。',
    'asrSimilarityExpectedTextMissing': '缺少目标文本，无法进行相似度评分',
    'asrSimilarityFailed': '相似度评分失败：{error}',
    'asrSimilarityFeatureInsufficient': '有效语音特征不足，请靠近麦克风重试',
    'asrSimilarityLocalSynthesisUnsupported': '当前本地 TTS 不支持导出参考语音',
    'asrSimilarityReferenceFailedHttp': '参考语音请求失败（{code}）：{body}',
    'asrSimilarityReferenceInvalid': '参考语音无效或为空',
    'asrSimilarityRequiresRemoteTts': '该模式需要远程 TTS 才能生成参考语音',
    'asrSimilarityTtsApiKeyMissing': '请先填写 TTS API Key',
    'asrSimilarityTtsBaseUrlMissing': '请先填写 TTS Base URL',
    'asrSimilarityTtsMissing': '未检测到可用 TTS 配置',
    'asrUnsupportedOfflineProvider': '当前离线识别引擎不受支持',
    'backToTop': '回到顶部',
    'cancel': '取消',
    'clearTaskWordbook': '清空任务词本',
    'close': '关闭',
    'collapseEmptyFields': '收起空字段',
    'confirmDeleteWord': '确认删除“{word}”？',
    'confirmDeleteWordbook': '确认删除“{name}”？',
    'copyField': '复制',
    'coreRepeat': '核心播放次数',
    'create': '创建',
    'createWordbook': '创建词本',
    'currentPlayingList': '当前播放词本',
    'currentWord': '当前单词',
    'customApi': '自定义 API',
    'defaultVoice': '默认音色',
    'delayBetweenUnits': '单元间隔',
    'delete': '删除',
    'deleteField': '删除字段',
    'deleteFieldMessage': '确认删除字段“{field}”？',
    'deleteFieldTitle': '删除字段',
    'deleteSourceAfterMerge': '合并后删除来源词本',
    'deleteWordInEditor': '删除该词',
    'deleteWordbook': '删除词本',
    'differences': '差异',
    'download': '下载',
    'edit': '编辑',
    'editField': '编辑字段',
    'editFieldTitle': '编辑字段：{field}',
    'editWordTitle': '编辑单词',
    'emptyFieldsDetected': '检测到空字段',
    'enableAsr': '启用语音识别跟读',
    'enableAsrFirst': '请先在设置中启用 ASR',
    'errorClearTaskWordbookFailed': '清空任务词本失败：{error}',
    'errorCreateWordbookFailed': '创建词本失败：{error}',
    'errorDeleteWordbookFailed': '删除词本失败：{error}',
    'errorDeleteWordFailed': '删除单词失败：{error}',
    'errorExportFailed': '导出失败：{error}',
    'errorFavoriteOperationFailed': '收藏操作失败：{error}',
    'errorImportFailed': '导入失败：{error}',
    'errorInitFailed': '初始化失败：{error}',
    'errorResetUserDataFailed': '重置本地数据失败：{error}',
    'errorMergeFailed': '合并词本失败：{error}',
    'errorMigrationFailed': '迁移失败：{error}',
    'errorRenameWordbookFailed': '重命名词本失败：{error}',
    'errorSaveWordFailed': '保存单词失败：{error}',
    'errorTaskOperationFailed': '任务操作失败：{error}',
    'errorWordEmpty': '单词不能为空',
    'exampleRepeat': '例句播放次数',
    'expandEmptyFields': '展开空字段',
    'exportTaskWordbook': '导出任务词本',
    'fieldContent': '字段内容',
    'fieldCopied': '字段已复制',
    'fieldExamples': '例句',
    'fieldKey': '字段键',
    'fieldKeyPlaceholder': '请输入字段键（例如 roots）',
    'fieldLabel': '字段显示名',
    'fieldLabelPlaceholder': '请输入字段显示名称',
    'fieldStyleTitle': '字段样式',
    'fieldStyleBackground': '卡片背景色',
    'fieldStyleBorder': '卡片边框色',
    'fieldStyleText': '文本颜色',
    'fieldStyleAccent': '标题强调色',
    'fieldStyleHint': '#RRGGBB 或 #AARRGGBB',
    'fieldMeaning': '释义',
    'fieldWord': '单词',
    'followAlong': '跟读识别',
    'followAlongTitle': '跟读识别',
    'fuzzy': '模糊',
    'go': '跳转',
    'great': '很棒',
    'hideAnswer': '隐藏答案',
    'hideHint': '隐藏提示',
    'importAudio': '导入音频',
    'importedAudio': '已导入音频',
    'importedWordbookName': '导入词本名称',
    'importWordbook': '导入词本',
    'importWordbookSuccess': '已导入 {count} 个单词',
    'importWordbookSuccessWithBackup': '已导入 {count} 个单词（已保存备份）',
    'jumpByLetter': '按字母跳转',
    'jumpByPrefix': '按前缀跳转',
    'jumpNoMatch': '未找到以 {value} 开头的单词',
    'language': '语言',
    'local': '本地',
    'localVoicesNotFound': '未找到可用本地音色，将使用系统默认音色',
    'manageWordbook': '管理词本',
    'masterVolume': '主音量',
    'meaning': '释义',
    'meaningRepeat': '释义播放次数',
    'mergeDialogTitle': '合并词本',
    'mergeWordbooks': '合并词本',
    'migrateLegacy': '迁移旧版数据库',
    'migrationSuccess': '迁移完成，已导入 {count} 条记录',
    'migrationSuccessWithBackup': '迁移完成，已导入 {count} 条记录（已保存备份）',
    'needTwoWordbooks': '至少需要两个词本才能合并',
    'needsPractice': '需要练习',
    'newWordbook': '新建词本',
    'next': '下一个',
    'noAudioSources': '暂无可用音频源',
    'nonCoreRepeat': '非核心播放次数',
    'noWordbookYet': '还没有词本，请先导入或创建',
    'offlineWhisperBase': '离线（Whisper Base）',
    'offlineWhisperSmall': '离线（Whisper Small）',
    'overallLoop': '整体循环',
    'pause': '暂停',
    'play': '播放',
    'playbackSpeed': '播放速度',
    'playbackVolume': '播放音量',
    'playCurrent': '播放当前',
    'playPronunciation': '播放发音',
    'prev': '上一个',
    'processing': '处理中...',
    'busyInitializingApp': '正在准备你的词库...',
    'busyInitializingHint': '正在加载本地设置与数据，这可能需要一点时间。',
    'busyLoadingWordbook': '正在加载单词本...',
    'busyImportingWordbook': '正在导入单词本...',
    'busyMigratingLegacyData': '正在迁移旧版数据...',
    'busyMergingWordbooks': '正在合并单词本...',
    'busyResettingUserData': '正在重置本地数据...',
    'busyRestoringBackup': '正在恢复备份...',
    'busyPatienceHint': '当前单词本可能较大，请耐心等待。',
    'progress': '进度',
    'pronunciationDiffExtra': '多读：{value}',
    'pronunciationDiffMissing': '漏读：{value}',
    'pronunciationDiffReplace': '应读“{from}”，识别为“{to}”',
    'recognitionFailed': '识别失败',
    'recognizedText': '识别结果：{text}',
    'recognizing': '识别中...',
    'recordingFailed': '录音失败',
    'rename': '重命名',
    'renameWordbook': '重命名词本',
    'resume': '继续',
    'revealAnswer': '显示答案',
    'save': '保存',
    'saveAndApply': '保存并应用',
    'scorerForcedAlignmentPer': '强制对齐 + PER',
    'scorerGop': 'GOP 打分',
    'scorerPpgPosterior': 'PPG 后验打分',
    'scorerSslEmbedding': 'SSL 嵌入相似度（HuBERT/wav2vec2）',
    'searchPlaceholder': '搜索单词或内容',
    'selectWord': '请选择单词',
    'settings': '设置',
    'settingsTabAppearance': '外观',
    'settingsTabAsr': '识别',
    'settingsTabPlayback': '播放',
    'settingsTabVoice': '语音',
    'showHint': '显示提示',
    'showText': '显示文本',
    'siliconFlowApi': 'SiliconFlow API',
    'similarity': '相似度：{score}%',
    'skip': '跳过',
    'sourceWordbook': '来源词本',
    'specialWordbooks': '特殊词本',
    'spellingLabel': '拼写',
    'startFrom': '起始位置',
    'startRecordingFailed': '启动录音失败，请检查麦克风权限',
    'tapToStartRecord': '点击开始录音',
    'tapToStopRecord': '点击停止录音',
    'targetWordbook': '目标词本',
    'testMode': '测试模式',
    'testModeEnabledHint': '测试模式已启用',
    'themeDark': '暗色',
    'themeFantasy': '幻想',
    'themeFlat': '扁平',
    'themeMono': '极简',
    'themeNature': '自然',
    'themeOcean': '海洋',
    'themeSunset': '日落',
    'themeTech': '科技',
    'toggleFavorite': '收藏/取消收藏',
    'toggleTask': '加入/移出任务',
    'ttsApiBaseUrl': 'TTS Base URL',
    'ttsApiKey': 'TTS API Key',
    'ttsModel': 'TTS 模型',
    'ttsModelIdHint': '输入模型 ID',
    'ttsProvider': 'TTS 提供方',
    'voice': '音色',
    'word': '单词',
    'wordbookName': '词本名称',
    'wordbooks': '词本',
    'wordRepeat': '单词播放次数',
    'wordsCount': '{count} 个单词',
    'stop': '停止',
    'fieldEtymology': '词源',
    'fieldRoots': '词根',
    'fieldAffixes': '词缀',
    'fieldVariations': '词形变化',
    'fieldMemory': '记忆',
    'fieldStory': '故事',
    'ambientNameNoiseWhite': '白噪音',
    'ambientNameNoisePink': '粉红噪音',
    'ambientNameNoiseBrown': '棕噪音',
    'ambientNameNatureWind': '风声',
    'ambientNameNatureForest': '林间风声',
    'ambientNameNatureFire': '篝火',
    'ambientNameNatureOcean': '海浪',
    'ambientNameRainLight': '小雨',
    'ambientNameRainHeavy': '大雨',
    'ambientNameFocusLibrary': '图书馆',
    'ambientNameFocusCafe': '咖啡馆',
    'ambientNameFocusNightVillage': '夜间村庄',
  };

  static const Map<String, String> _ja = <String, String>{
    'appTitle': '咸鱼声息',
    'importWordbook': '単語帳をインポートする',
    'migrateLegacy': 'レガシー DB の移行',
    'newWordbook': '新しい単語帳',
    'addWord': '単語を追加',
    'jsonBatchImport': 'JSONバッチインポート',
    'settings': '設定',
    'ambientAudio': 'アンビエントオーディオ',
    'noWordbookYet': '単語帳はまだありません。まずインポートまたは作成します。',
    'play': '再生',
    'pause': '一時停止',
    'resume': '再開する',
    'skip': 'スキップ',
    'stop': '停止',
    'ttsProvider': 'TTSプロバイダー',
    'local': 'ローカル',
    'siliconFlowApi': 'SiliconFlow API',
    'customApi': 'カスタムAPI',
    'voice': '声',
    'defaultVoice': 'デフォルトボイス',
    'ttsModel': 'TTSモデル',
    'ttsApiKey': 'TTS APIキー',
    'ttsApiBaseUrl': 'TTS ベース URL',
    'ttsModelIdHint': 'モデルIDを入力してください',
    'localVoicesNotFound': '現地の声は見つかりませんでした。システムのデフォルトの音声が使用されます。',
    'enableAsr': 'ASRフォローアロングを有効にする',
    'asrProvider': 'ASRプロバイダー',
    'asrLanguage': 'ASR 言語 (例: en / zh)',
    'asrLanguageAuto': '自動',
    'asrLanguageEnglish': '英語 (en)',
    'asrLanguageChinese': '中国語 (zh)',
    'asrLanguageJapanese': '日本語 (ja)',
    'asrLanguageFrench': 'フランス語 (フランス)',
    'asrLanguageGerman': 'ドイツ語 (デ)',
    'asrLanguageSpanish': 'スペイン語 (エス)',
    'asrLanguageCustom': 'カスタムコード',
    'asrLanguageCustomInput': 'カスタム言語コード',
    'asrLanguageCustomInputHint': '例えばpt-BR/それ',
    'asrModel': 'ASRモデル（APIモード）',
    'asrApiKey': 'ASR APIキー（APIモード）',
    'asrApiBaseUrl': 'ASR ベース URL (カスタム API)',
    'offlineWhisperBase': 'オフライン（ウィスパーベース）',
    'offlineWhisperSmall': 'オフライン (ささやき小声)',
    'asrLocalSimilarity': '局所的な類似性 (ASR なし)',
    'asrMultiEngine': 'マルチエンジン（選択可能）',
    'asrLocalSimilarityHint':
        '現在の再生 TTS (ローカルまたはリモート) を使用して参照オーディオを生成し、音響の類似性によって発音をローカルで比較します。',
    'asrMultiEngineHint':
        '1 つ以上のエンジンを選択します。彼らは順番に走ります。テキスト ASR と音響類似性の結果は、利用可能な場合には結合されます。',
    'asrScoringMethods': '発音の採点方法',
    'asrScoringMethodsHint': '有効にするスコアリング アルゴリズムを選択します。インストールされたパッケージのみ。',
    'asrScoringPackManager': 'スコアリングパッケージマネージャー',
    'asrScoringPackInstallFirst': 'この方法を有効にするには、最初にパッケージをダウンロードしてください。',
    'asrDumpRecognitionAudio': '未処理/処理済みの認識音声をダンプする',
    'asrDumpRecognitionAudioHint': '比較/デバッグのために生の音声ファイルと処理された音声ファイルを一時的に保存します。',
    'scorerSslEmbedding': 'SSL 埋め込みの類似性 (HuBERT/wav2vec2)',
    'scorerGop': 'GOP スコアリング',
    'scorerForcedAlignmentPer': '強制調整 + PER',
    'scorerPpgPosterior': 'PPG 事後スコアリング',
    'asrScoringMethodApplied': '適用されたスコア: {method}',
    'asrScoringEngineApplied': 'エンジン別スコア: {engine}',
    'asrScoringBreakdown': 'メソッドの内訳',
    'asrOfflineModelManager': 'オフラインモデルパッケージ',
    'asrModelInstalled': 'インストール済み ({size})',
    'asrModelNotInstalled': 'インストールされていません (ダウンロード サイズ: {size})',
    'asrOfflineNoticeTitle': 'オフライン ASR に関する通知',
    'asrOfflineNoticeBody':
        'オフライン ASR には追加の初回ダウンロード ({size}) が必要であり、精度が低くなります。推奨: リモート API (登録後、このプラットフォームでは現在無料)。',
    'language': '言語',
    'cancel': 'キャンセル',
    'save': '保存',
    'close': '閉じる',
    'searchPlaceholder': '単語や内容を検索する',
    'all': '全て',
    'word': '言葉',
    'meaning': '意味',
    'fuzzy': 'ファジー',
    'go': '行く',
    'wordsCount': '{count} 単語',
    'selectWord': '単語を選択してください',
    'toggleFavorite': 'お気に入りを切り替え',
    'toggleTask': 'タスクワードを切り替えます',
    'edit': '編集',
    'delete': '消去',
    'followAlong': 'フォローアロング',
    'followAlongTitle': 'フォローアロング',
    'playPronunciation': '発音を再生する',
    'tapToStopRecord': 'タップして録音を停止します',
    'tapToStartRecord': 'タップして録音を開始します',
    'recognizing': '認識しています...',
    'recognitionFailed': '認識に失敗しました',
    'great': '素晴らしい',
    'needsPractice': '練習が必要です',
    'recognizedText': '認識済み: {text}',
    'similarity': '類似性: {score}%',
    'differences': '違い',
    'wordbooks': '単語帳',
    'rename': '名前の変更',
    'mergeWordbooks': '単語帳を結合する',
    'exportTaskWordbook': 'タスクの単語帳をエクスポートする',
    'clearTaskWordbook': 'クリアタスクの単語帳',
    'createWordbook': '単語帳を作成する',
    'wordbookName': '単語帳名',
    'create': '作成する',
    'renameWordbook': '単語帳の名前を変更する',
    'deleteWordbook': '単語帳を削除する',
    'confirmDeleteWordbook': '「{name}」を削除しますか？',
    'confirmDeleteWord': '「{word}」を削除しますか？',
    'mergeDialogTitle': '単語帳を結合する',
    'sourceWordbook': '出典単語帳',
    'targetWordbook': '対象単語帳',
    'deleteSourceAfterMerge': 'マージ後にソースを削除する',
    'needTwoWordbooks': 'カスタム単語帳が少なくとも 2 冊必要です。',
    'addWordTitle': '単語を追加',
    'editWordTitle': '単語を編集する',
    'fieldWord': '言葉',
    'fieldMeaning': '意味',
    'fieldExamples': '例',
    'fieldEtymology': '語源',
    'fieldRoots': 'ルーツ',
    'fieldAffixes': '接辞',
    'fieldVariations': 'バリエーション',
    'fieldMemory': 'メモリ',
    'fieldStory': '話',
    'fieldContent': 'フィールドの内容',
    'fieldKey': 'フィールドキー',
    'fieldLabel': 'フィールドラベル',
    'fieldKeyPlaceholder': 'フィールドキーを入力してください (例: ルート)',
    'fieldLabelPlaceholder': 'フィールドラベルを入力してください (例: ルート)',
    'fieldCopied': 'コピーされたフィールド',
    'copyField': 'コピー',
    'editField': 'フィールドの編集',
    'deleteField': 'フィールドの削除',
    'deleteFieldTitle': 'フィールドの削除',
    'deleteFieldMessage': 'フィールド「{field}」を削除しますか?',
    'editFieldTitle': '編集フィールド: {field}',
    'addField': 'フィールドの追加',
    'expandEmptyFields': '空のフィールドを展開する',
    'collapseEmptyFields': '空のフィールドを折りたたむ',
    'emptyFieldsDetected': '空のフィールドが検出されました',
    'deleteWordInEditor': '単語の削除',
    'specialWordbooks': 'タスクとお気に入り',
    'manageWordbook': '単語帳の管理',
    'playbackVolume': '再生音量',
    'masterVolume': 'マスターボリューム',
    'playbackSpeed': '再生速度',
    'wordRepeat': '単語の繰り返し',
    'meaningRepeat': '繰り返しの意味',
    'exampleRepeat': '繰り返しの例',
    'spellingLabel': 'スペル',
    'nonCoreRepeat': 'ノンコアリピート',
    'applyToAllNonCore': 'すべてに適用',
    'currentPlayingList': '現在のプレイ中',
    'currentWord': '現在の単語',
    'progress': '進捗',
    'startFrom': 'から開始',
    'prev': '前へ',
    'next': '次',
    'testMode': 'テストモード',
    'backToTop': 'トップに戻る',
    'showHint': 'ヒントを表示',
    'hideHint': 'ヒントを隠す',
    'revealAnswer': '答えを明らかにする',
    'hideAnswer': '回答を隠す',
    'testModeEnabledHint': 'テストモードが有効になっています',
    'coreRepeat': 'コアリピート',
    'overallLoop': '全体ループ',
    'delayBetweenUnits': 'ユニット間の遅延 (ミリ秒)',
    'showText': 'テキストを表示',
    'saveAndApply': '保存して適用',
    'download': 'ダウンロード',
    'processing': '処理...',
    'settingsTabPlayback': '再生',
    'settingsTabVoice': '声',
    'settingsTabAsr': '認識',
    'settingsTabAppearance': '外観',
    'appearanceThemeTitle': 'テーマ',
    'appearanceLayoutTitle': 'レイアウト',
    'appearanceLayoutHint': 'レイアウトの詳細は次のイテレーションで調整されます。',
    'appearanceColorsTitle': '色',
    'appearanceColorsHint': '色の詳細は次のイテレーションで調整されます。',
    'appearanceBackgroundTitle': '背景',
    'appearanceBackgroundHint': '背景の詳細​​は次のイテレーションで改良されます。',
    'appearanceFieldSectionsTitle': 'フィールドセクション',
    'appearanceFieldSectionsHint': 'フィールド セクションのスタイルは、次のイテレーションで改良されます。',
    'themeFlat': 'フラットブルー',
    'themeTech': 'テックブルー',
    'themeDark': '暗い',
    'themeFantasy': 'ファンタジー',
    'themeNature': '自然',
    'themeSunset': '日没',
    'themeOcean': '海',
    'themeMono': 'モノ',
    'noAudioSources': '音源がありません',
    'importAudio': 'オーディオファイルをインポートする',
    'importedAudio': 'インポートされたオーディオ',
    'ambientCategoryNoise': 'ノイズ',
    'ambientCategoryNature': '自然',
    'ambientCategoryRain': '雨',
    'ambientCategoryFocus': '集中',
    'ambientNameNoiseWhite': 'ホワイトノイズ',
    'ambientNameNoisePink': 'ピンクノイズ',
    'ambientNameNoiseBrown': 'ブラウンノイズ',
    'ambientNameNatureWind': '風',
    'ambientNameNatureForest': '木々の風',
    'ambientNameNatureFire': 'キャンプファイヤー',
    'ambientNameNatureOcean': '波',
    'ambientNameRainLight': '小雨',
    'ambientNameRainHeavy': '大雨',
    'ambientNameFocusLibrary': '図書館',
    'ambientNameFocusCafe': 'カフェ',
    'ambientNameFocusNightVillage': 'ナイトビレッジ',
    'jumpByLetter': '文字でジャンプ',
    'jumpByPrefix': '接頭辞でジャンプ',
    'jumpNoMatch': '「{value}」に一致する単語はありません',
    'importedWordbookName': 'インポートされた単語帳',
    'errorInitFailed': '初期化に失敗しました: {error}',
    'errorCreateWordbookFailed': '単語帳の作成に失敗しました: {error}',
    'errorRenameWordbookFailed': '名前の変更に失敗しました: {error}',
    'errorDeleteWordbookFailed': '単語帳の削除に​​失敗しました: {error}',
    'importWordbookSuccess': 'インポートされた {count} 単語',
    'importWordbookSuccessWithBackup': 'インポートされた {count} 単語 (バックアップが保存されました)',
    'errorImportFailed': 'インポートに失敗しました: {error}',
    'migrationSuccess': '移行が完了し、{count} 行がインポートされました',
    'migrationSuccessWithBackup': '移行が完了し、{count} 行がインポートされました（バックアップは保存されました）',
    'errorMigrationFailed': '移行失敗: {error}',
    'errorWordEmpty': 'Word を空にすることはできません',
    'errorSaveWordFailed': '単語の保存に失敗しました: {error}',
    'errorDeleteWordFailed': '単語の削除に失敗しました: {error}',
    'errorFavoriteOperationFailed': 'お気に入りの操作が失敗しました: {error}',
    'errorTaskOperationFailed': 'タスク操作が失敗しました: {error}',
    'errorClearTaskWordbookFailed': 'タスク単語帳のクリアに失敗しました: {error}',
    'errorExportFailed': 'エクスポートに失敗しました: {error}',
    'errorMergeFailed': 'マージ失敗: {error}',
    'recordingFailed': '録音に失敗しました',
    'startRecordingFailed': '記録の開始に失敗しました。マイクの許可を確認してください。',
    'enableAsrFirst': 'まず設定で ASR を有効にしてください。',
    'playCurrent': '現在の再生',
    'asrDisabled': 'ASR は無効になっています。',
    'asrAudioFileNotFound': '音声ファイルが見つかりません。',
    'asrApiKeyMissing': 'ASR API キーがありません。',
    'asrApiBaseUrlMissing': 'ASR API ベース URL がありません。',
    'asrApiTimeout': 'ASR リクエストがタイムアウトしました。',
    'asrApiRequestFailed': 'ASR API リクエストが失敗しました ({code})。 {body}',
    'asrRequestFailed': 'ASR リクエストが失敗しました: {error}',
    'asrEmptyResult': '音声は認識されませんでした。',
    'asrInvalidWav': '無効な記録形式です。',
    'asrRecordingTooShort': '録音時間が短すぎます。',
    'asrNoSpeechDetected': '録音中に音声が検出されませんでした。',
    'asrRecognitionCancelled': '認識がキャンセルされました。',
    'asrLocalSimilarityNoTranscript':
        'ローカル類似性モードではトランスクリプトはありません (オーディオ スコアのみ)。',
    'asrSimilarityExpectedTextMissing': '局所類似性モードではターゲット単語が欠落しています。',
    'asrSimilarityTtsMissing': 'ローカル類似性モードの TTS 構成がありません。',
    'asrSimilarityRequiresRemoteTts': 'ローカル類似性モードでは、利用可能な TTS 参照オーディオが必要です。',
    'asrSimilarityTtsApiKeyMissing': 'ローカル類似性モードの TTS API キーがありません。',
    'asrSimilarityTtsBaseUrlMissing': 'ローカル類似性モードの TTS ベース URL がありません。',
    'asrSimilarityLocalSynthesisUnsupported':
        '現在のプラットフォームでは、ローカル TTS リファレンス オーディオをエクスポートできません。リモート TTS に切り替えます。',
    'asrSimilarityReferenceInvalid': '類似性比較のための有効なリファレンスオーディオを生成できませんでした。',
    'asrSimilarityReferenceFailedHttp': '参照オーディオ要求が失敗しました ({code})。 {body}',
    'asrSimilarityFeatureInsufficient': '類似性を比較するには音声が短すぎるか不明瞭です。',
    'asrSimilarityFailed': 'ローカル類似性比較が失敗しました: {error}',
    'asrScoringPackNotInstalled':
        '選択されたスコアリング パッケージがインストールされていません。少なくとも 1 つダウンロードしてください。',
    'asrScoringPackUnsupported': 'サポートされていないスコアリング パッケージです。',
    'asrMultiEngineNoResult': '有効な結果を生成したエンジンはありませんでした。エンジンの選択を調整してください。',
    'asrOfflineFailed': 'オフライン ASR が失敗しました: {error}',
    'asrOfflineInitFailed': 'オフライン ASR の初期化に失敗しました。',
    'asrUnsupportedOfflineProvider': 'サポートされていないオフライン ASR プロバイダーです。',
    'asrModelMissingAfterExtract': 'ASR モデル ファイルが抽出後に失われます。',
    'asrModelExtractionIncomplete': 'ASR モデルの抽出が不完全です。',
    'asrDownloadFailedHttp': 'ASR モデルのダウンロードに失敗しました ({code})。',
    'asrProgressStoppingRecording': '録音を停止しています...',
    'asrProgressPreparing': 'ASR を準備しています...',
    'asrProgressDownloading': 'ASR モデルをダウンロードしています...',
    'asrProgressDownloadDone': 'ASRモデルのダウンロードが完了しました。',
    'asrProgressExtracting': 'ASR モデルを抽出しています...',
    'asrProgressExtractDone': 'ASR モデルの抽出が完了しました。',
    'asrProgressLoadingModel': 'ASR モデルをロードしています...',
    'asrProgressDecoding': '音声を認識中...',
    'asrProgressDone': '認識が完了しました。',
    'pronunciationDiffMissing': '欠落: {value}',
    'pronunciationDiffExtra': '追加: {value}',
    'pronunciationDiffReplace': '「{from}」と予想され、「{to}」と聞こえました',
    'focusTitle': '集中',
    'timerTab': 'タイマー',
    'todoTab': 'タスク',
    'timerIdle': '準備完了',
    'focusPhase': '集中中',
    'breakPhase': '休憩中',
    'focusPhaseComplete': '集中時間終了！',
    'breakPhaseComplete': '休憩時間終了！',
    'roundProgress': '第{current}ラウンド、全{total}ラウンド',
    'startFocus': '集中開始',
    'timerConfig': 'タイマー設定',
    'focusMinutes': '集中時間',
    'breakMinutes': '休憩時間',
    'rounds': 'ラウンド数',
    'stopTimer': 'タイマー停止',
    'stopTimerConfirm': 'タイマーを停止して進捗を保存しますか？',
    'todayStats': '今日の統計',
    'focusMinutesLabel': '集中分数',
    'roundsLabel': '完了ラウンド',
    'addTodoHint': '新しいタスクを追加...',
    'clearCompleted': '完了をクリア',
    'quickNotes': 'クイックメモ',
    'addNote': 'メモ追加',
    'editNote': 'メモ編集',
    'deleteNote': 'メモ削除',
    'deleteNoteConfirm': 'このメモを削除しますか？',
    'noteTitle': 'タイトル',
    'noteContent': '内容',
  };

  static const Map<String, String> _de = <String, String>{
    'appTitle': '咸鱼声息',
    'importWordbook': 'Wordbook importieren',
    'migrateLegacy': 'Legacy-Datenbank migrieren',
    'newWordbook': 'Neues Wortbuch',
    'addWord': 'Wort hinzufügen',
    'jsonBatchImport': 'JSON-Batch-Import',
    'settings': 'Einstellungen',
    'ambientAudio': 'Umgebungsgeräusche',
    'noWordbookYet':
        'Noch kein Wortbuch. Importieren oder erstellen Sie zuerst eines.',
    'play': 'Spielen',
    'pause': 'Pause',
    'resume': 'Wieder aufnehmen',
    'skip': 'Überspringen',
    'stop': 'Stoppen',
    'ttsProvider': 'TTS-Anbieter',
    'local': 'Lokal',
    'siliconFlowApi': 'SiliconFlow-API',
    'customApi': 'Benutzerdefinierte API',
    'voice': 'Stimme',
    'defaultVoice': 'Standardstimme',
    'ttsModel': 'TTS-Modell',
    'ttsApiKey': 'TTS-API-Schlüssel',
    'ttsApiBaseUrl': 'TTS-Basis-URL',
    'ttsModelIdHint': 'Geben Sie die Modell-ID ein',
    'localVoicesNotFound':
        'Keine lokalen Stimmen gefunden. Es wird die Standardstimme des Systems verwendet.',
    'enableAsr': 'ASR-Follow-Along aktivieren',
    'asrProvider': 'ASR-Anbieter',
    'asrLanguage': 'ASR-Sprache (z. B. en / zh)',
    'asrLanguageAuto': 'Auto',
    'asrLanguageEnglish': 'Englisch (en)',
    'asrLanguageChinese': 'Chinesisch (zh)',
    'asrLanguageJapanese': 'Japanisch (ja)',
    'asrLanguageFrench': 'Französisch (fr)',
    'asrLanguageGerman': 'Deutsch (de)',
    'asrLanguageSpanish': 'Spanisch (es)',
    'asrLanguageCustom': 'Benutzerdefinierter Code',
    'asrLanguageCustomInput': 'Benutzerdefinierter Sprachcode',
    'asrLanguageCustomInputHint': 'z.B. pt-BR / es',
    'asrModel': 'ASR-Modell (API-Modus)',
    'asrApiKey': 'ASR-API-Schlüssel (API-Modus)',
    'asrApiBaseUrl': 'ASR-Basis-URL (benutzerdefinierte API)',
    'offlineWhisperBase': 'Offline (Flüsterbasis)',
    'offlineWhisperSmall': 'Offline (Flüsterklein)',
    'asrLocalSimilarity': 'Lokale Ähnlichkeit (kein ASR)',
    'asrMultiEngine': 'Mehrmotorig (wählbar)',
    'asrLocalSimilarityHint':
        'Verwendet das aktuelle Wiedergabe-TTS (lokal oder remote), um Referenzaudio zu generieren, und vergleicht dann die Aussprache lokal anhand der akustischen Ähnlichkeit.',
    'asrMultiEngineHint':
        'Wählen Sie einen oder mehrere Motoren aus. Sie laufen der Reihe nach. Ergebnisse von Text-ASR und akustischer Ähnlichkeit werden kombiniert, sofern verfügbar.',
    'asrScoringMethods': 'Methoden zur Bewertung der Aussprache',
    'asrScoringMethodsHint':
        'Wählen Sie aus, welche Bewertungsalgorithmen aktiviert werden sollen. Nur installierte Pakete.',
    'asrScoringPackManager': 'Bewertungspaket-Manager',
    'asrScoringPackInstallFirst':
        'Laden Sie zuerst das Paket herunter, um diese Methode zu aktivieren.',
    'asrDumpRecognitionAudio': 'Rohes/verarbeitetes Erkennungsaudio ausgeben',
    'asrDumpRecognitionAudioHint':
        'Speichern Sie temporäre rohe und verarbeitete Audiodateien zum Vergleich/Fehlerbehebung.',
    'scorerSslEmbedding': 'SSL-Einbettungsähnlichkeit (HuBERT/wav2vec2)',
    'scorerGop': 'GOP-Wertung',
    'scorerForcedAlignmentPer': 'Zwangsausrichtung + PER',
    'scorerPpgPosterior': 'PPG-Posterior-Scoring',
    'asrScoringMethodApplied': 'Angewandte Wertung: {method}',
    'asrScoringEngineApplied': 'Bewertet nach Motor: {engine}',
    'asrScoringBreakdown': 'Methodenaufschlüsselung',
    'asrOfflineModelManager': 'Offline-Modellpakete',
    'asrModelInstalled': 'Installiert ({size})',
    'asrModelNotInstalled': 'Nicht installiert (Downloadgröße: {size})',
    'asrOfflineNoticeTitle': 'Offline-ASR-Hinweis',
    'asrOfflineNoticeBody':
        'Offline-ASR erfordert beim ersten Mal einen zusätzlichen Download ({size}) und weist eine geringere Genauigkeit auf. Empfohlen: Remote-API (derzeit kostenlos auf dieser Plattform nach Registrierung).',
    'language': 'Sprache',
    'cancel': 'Stornieren',
    'save': 'Speichern',
    'close': 'Schließen',
    'searchPlaceholder': 'Suchbegriff oder Inhalt suchen',
    'all': 'Alle',
    'word': 'Wort',
    'meaning': 'Bedeutung',
    'fuzzy': 'Unscharf',
    'go': 'Gehen',
    'wordsCount': '{count} Wörter',
    'selectWord': 'Wählen Sie ein Wort aus',
    'toggleFavorite': 'Favorit umschalten',
    'toggleTask': 'Aufgabenwort umschalten',
    'edit': 'Bearbeiten',
    'delete': 'Löschen',
    'followAlong': 'Folgen Sie uns',
    'followAlongTitle': 'Folgen Sie uns',
    'playPronunciation': 'Spielen Sie die Aussprache',
    'tapToStopRecord': 'Tippen Sie, um die Aufnahme zu beenden',
    'tapToStartRecord': 'Tippen Sie, um die Aufnahme zu starten',
    'recognizing': 'Erkennen...',
    'recognitionFailed': 'Die Erkennung ist fehlgeschlagen',
    'great': 'Großartig',
    'needsPractice': 'Braucht Übung',
    'recognizedText': 'Erkannt: {text}',
    'similarity': 'Ähnlichkeit: {score}%',
    'differences': 'Unterschiede',
    'wordbooks': 'Wortbücher',
    'rename': 'Umbenennen',
    'mergeWordbooks': 'Wortbücher zusammenführen',
    'exportTaskWordbook': 'Aufgaben-Wortbuch exportieren',
    'clearTaskWordbook': 'Klares Aufgabenwortbuch',
    'createWordbook': 'Wortbuch erstellen',
    'wordbookName': 'Wordbook-Name',
    'create': 'Erstellen',
    'renameWordbook': 'Wortbuch umbenennen',
    'deleteWordbook': 'Wortbuch löschen',
    'confirmDeleteWordbook': '„{name}“ löschen?',
    'confirmDeleteWord': '„{word}“ löschen?',
    'mergeDialogTitle': 'Wortbücher zusammenführen',
    'sourceWordbook': 'Quellenwortbuch',
    'targetWordbook': 'Ziel-Wortbuch',
    'deleteSourceAfterMerge': 'Quelle nach dem Zusammenführen löschen',
    'needTwoWordbooks':
        'Benötigen Sie mindestens zwei benutzerdefinierte Wortbücher.',
    'addWordTitle': 'Wort hinzufügen',
    'editWordTitle': 'Wort bearbeiten',
    'fieldWord': 'Wort',
    'fieldMeaning': 'Bedeutung',
    'fieldExamples': 'Beispiele',
    'fieldEtymology': 'Etymologie',
    'fieldRoots': 'Wurzeln',
    'fieldAffixes': 'Affixe',
    'fieldVariations': 'Variationen',
    'fieldMemory': 'Erinnerung',
    'fieldStory': 'Geschichte',
    'fieldContent': 'Feldinhalt',
    'fieldKey': 'Feldschlüssel',
    'fieldLabel': 'Feldbezeichnung',
    'fieldKeyPlaceholder': 'Feldschlüssel eingeben (z. B. Wurzeln)',
    'fieldLabelPlaceholder': 'Feldbezeichnung eingeben (z. B. Roots)',
    'fieldCopied': 'Feld kopiert',
    'copyField': 'Kopie',
    'editField': 'Feld bearbeiten',
    'deleteField': 'Feld löschen',
    'deleteFieldTitle': 'Feld löschen',
    'deleteFieldMessage': 'Feld „{field}“ löschen?',
    'editFieldTitle': 'Feld bearbeiten: {field}',
    'addField': 'Feld hinzufügen',
    'expandEmptyFields': 'Erweitern Sie leere Felder',
    'collapseEmptyFields': 'Leere Felder ausblenden',
    'emptyFieldsDetected': 'Leere Felder erkannt',
    'deleteWordInEditor': 'Word löschen',
    'specialWordbooks': 'Aufgabe und Favoriten',
    'manageWordbook': 'Wordbook-Management',
    'playbackVolume': 'Wiedergabelautstärke',
    'masterVolume': 'Master-Volume',
    'playbackSpeed': 'Wiedergabegeschwindigkeit',
    'wordRepeat': 'Wortwiederholung',
    'meaningRepeat': 'Bedeutung wiederholen',
    'exampleRepeat': 'Beispiel wiederholen',
    'spellingLabel': 'Rechtschreibung',
    'nonCoreRepeat': 'Nicht zum Kern gehörende Wiederholung',
    'applyToAllNonCore': 'Bewerben Sie sich für alle',
    'currentPlayingList': 'Aktuelle Wiedergabe',
    'currentWord': 'Aktuelles Wort',
    'progress': 'Fortschritt',
    'startFrom': 'Beginnen Sie mit',
    'prev': 'Vorher',
    'next': 'Nächste',
    'testMode': 'Testmodus',
    'backToTop': 'Zurück nach oben',
    'showHint': 'Hinweis anzeigen',
    'hideHint': 'Hinweis ausblenden',
    'revealAnswer': 'Antwort offenbaren',
    'hideAnswer': 'Antwort ausblenden',
    'testModeEnabledHint': 'Der Testmodus ist aktiviert',
    'coreRepeat': 'Kernwiederholung',
    'overallLoop': 'Gesamtschleife',
    'delayBetweenUnits': 'Verzögerung zwischen Einheiten (ms)',
    'showText': 'Text anzeigen',
    'saveAndApply': 'Speichern und anwenden',
    'download': 'Herunterladen',
    'processing': 'Verarbeitung...',
    'settingsTabPlayback': 'Wiedergabe',
    'settingsTabVoice': 'Stimme',
    'settingsTabAsr': 'Erkennung',
    'settingsTabAppearance': 'Aussehen',
    'appearanceThemeTitle': 'Thema',
    'appearanceLayoutTitle': 'Layout',
    'appearanceLayoutHint':
        'Layoutdetails werden in der nächsten Iteration verfeinert.',
    'appearanceColorsTitle': 'Farben',
    'appearanceColorsHint':
        'Farbdetails werden in der nächsten Iteration verfeinert.',
    'appearanceBackgroundTitle': 'Hintergrund',
    'appearanceBackgroundHint':
        'Hintergrunddetails werden in der nächsten Iteration verfeinert.',
    'appearanceFieldSectionsTitle': 'Feldabschnitte',
    'appearanceFieldSectionsHint':
        'Die Feldabschnittsstile werden in der nächsten Iteration verfeinert.',
    'themeFlat': 'Flaches Blau',
    'themeTech': 'Tech-Blau',
    'themeDark': 'Dunkel',
    'themeFantasy': 'Fantasie',
    'themeNature': 'Natur',
    'themeSunset': 'Sonnenuntergang',
    'themeOcean': 'Ozean',
    'themeMono': 'Mono',
    'noAudioSources': 'Keine Audioquellen',
    'importAudio': 'Audiodatei importieren',
    'importedAudio': 'Importiertes Audio',
    'ambientCategoryNoise': 'Lärm',
    'ambientCategoryNature': 'Natur',
    'ambientCategoryRain': 'Regen',
    'ambientCategoryFocus': 'Fokus',
    'ambientNameNoiseWhite': 'Weißes Rauschen',
    'ambientNameNoisePink': 'Rosa Rauschen',
    'ambientNameNoiseBrown': 'Braunes Rauschen',
    'ambientNameNatureWind': 'Wind',
    'ambientNameNatureForest': 'Wind in Bäumen',
    'ambientNameNatureFire': 'Lagerfeuer',
    'ambientNameNatureOcean': 'Wellen',
    'ambientNameRainLight': 'Leichter Regen',
    'ambientNameRainHeavy': 'Starker Regen',
    'ambientNameFocusLibrary': 'Bibliothek',
    'ambientNameFocusCafe': 'Cafe',
    'ambientNameFocusNightVillage': 'Nachtdorf',
    'jumpByLetter': 'Springe nach Buchstaben',
    'jumpByPrefix': 'Springe nach Präfix',
    'jumpNoMatch': 'Keine Wörter passend zu „{value}“',
    'importedWordbookName': 'Importiertes Wordbook',
    'errorInitFailed': 'Initialisierung fehlgeschlagen: {error}',
    'errorCreateWordbookFailed': 'Wortbuch erstellen fehlgeschlagen: {error}',
    'errorRenameWordbookFailed': 'Umbenennen fehlgeschlagen: {error}',
    'errorDeleteWordbookFailed': 'Wortbuch löschen fehlgeschlagen: {error}',
    'importWordbookSuccess': '{count} Wörter importiert',
    'importWordbookSuccessWithBackup':
        'Importierte {count} Wörter (Backup gespeichert)',
    'errorImportFailed': 'Import fehlgeschlagen: {error}',
    'migrationSuccess': 'Migration abgeschlossen, {count} Zeilen importiert',
    'migrationSuccessWithBackup':
        'Migration abgeschlossen, {count} Zeilen importiert (Sicherung gespeichert)',
    'errorMigrationFailed': 'Migration fehlgeschlagen: {error}',
    'errorWordEmpty': 'Wort darf nicht leer sein',
    'errorSaveWordFailed': 'Wort speichern fehlgeschlagen: {error}',
    'errorDeleteWordFailed': 'Wort löschen fehlgeschlagen: {error}',
    'errorFavoriteOperationFailed': 'Lieblingsvorgang fehlgeschlagen: {error}',
    'errorTaskOperationFailed': 'Aufgabenvorgang fehlgeschlagen: {error}',
    'errorClearTaskWordbookFailed':
        'Das Löschen des Aufgabenwortbuchs ist fehlgeschlagen: {error}',
    'errorExportFailed': 'Export fehlgeschlagen: {error}',
    'errorMergeFailed': 'Zusammenführung fehlgeschlagen: {error}',
    'recordingFailed': 'Die Aufnahme ist fehlgeschlagen',
    'startRecordingFailed':
        'Die Aufnahme konnte nicht gestartet werden. Bitte überprüfen Sie die Mikrofonberechtigung.',
    'enableAsrFirst': 'Bitte aktivieren Sie zuerst ASR in den Einstellungen.',
    'playCurrent': 'Aktuell abspielen',
    'asrDisabled': 'ASR ist deaktiviert.',
    'asrAudioFileNotFound': 'Audiodatei nicht gefunden.',
    'asrApiKeyMissing': 'Der ASR-API-Schlüssel fehlt.',
    'asrApiBaseUrlMissing': 'Die Basis-URL der ASR-API fehlt.',
    'asrApiTimeout': 'Zeitüberschreitung bei der ASR-Anfrage.',
    'asrApiRequestFailed': 'ASR-API-Anfrage fehlgeschlagen ({code}). {body}',
    'asrRequestFailed': 'ASR-Anfrage fehlgeschlagen: {error}',
    'asrEmptyResult': 'Keine Sprache erkannt.',
    'asrInvalidWav': 'Ungültiges Aufnahmeformat.',
    'asrRecordingTooShort': 'Die Aufnahme ist zu kurz.',
    'asrNoSpeechDetected': 'Bei der Aufnahme wurde keine Sprache erkannt.',
    'asrRecognitionCancelled': 'Die Anerkennung wurde abgebrochen.',
    'asrLocalSimilarityNoTranscript':
        'Kein Transkript im lokalen Ähnlichkeitsmodus (nur Audiopartitur).',
    'asrSimilarityExpectedTextMissing':
        'Für den lokalen Ähnlichkeitsmodus fehlt das Zielwort.',
    'asrSimilarityTtsMissing':
        'Für den lokalen Ähnlichkeitsmodus fehlt die TTS-Konfiguration.',
    'asrSimilarityRequiresRemoteTts':
        'Der lokale Ähnlichkeitsmodus erfordert verfügbares TTS-Referenzaudio.',
    'asrSimilarityTtsApiKeyMissing':
        'Für den lokalen Ähnlichkeitsmodus fehlt der TTS-API-Schlüssel.',
    'asrSimilarityTtsBaseUrlMissing':
        'Für den lokalen Ähnlichkeitsmodus fehlt die TTS-Basis-URL.',
    'asrSimilarityLocalSynthesisUnsupported':
        'Die aktuelle Plattform kann kein lokales TTS-Referenzaudio exportieren. Wechseln Sie zu Remote-TTS.',
    'asrSimilarityReferenceInvalid':
        'Es konnte kein gültiges Referenzaudio für den Ähnlichkeitsvergleich generiert werden.',
    'asrSimilarityReferenceFailedHttp':
        'Referenz-Audio-Anfrage fehlgeschlagen ({code}). {body}',
    'asrSimilarityFeatureInsufficient':
        'Der Ton ist für einen Ähnlichkeitsvergleich zu kurz oder unklar.',
    'asrSimilarityFailed':
        'Lokaler Ähnlichkeitsvergleich fehlgeschlagen: {error}',
    'asrScoringPackNotInstalled':
        'Es ist kein ausgewähltes Scoring-Paket installiert. Bitte laden Sie mindestens eine herunter.',
    'asrScoringPackUnsupported': 'Nicht unterstütztes Scoring-Paket.',
    'asrMultiEngineNoResult':
        'Keine Engine lieferte ein gültiges Ergebnis. Bitte passen Sie die Motorauswahl an.',
    'asrOfflineFailed': 'Offline-ASR fehlgeschlagen: {error}',
    'asrOfflineInitFailed':
        'Die Offline-ASR-Initialisierung ist fehlgeschlagen.',
    'asrUnsupportedOfflineProvider':
        'Nicht unterstützter Offline-ASR-Anbieter.',
    'asrModelMissingAfterExtract':
        'ASR-Modelldateien fehlen nach dem Extrahieren.',
    'asrModelExtractionIncomplete':
        'Die Extraktion des ASR-Modells ist unvollständig.',
    'asrDownloadFailedHttp':
        'Der Download des ASR-Modells ist fehlgeschlagen ({code}).',
    'asrProgressStoppingRecording': 'Aufnahme stoppen...',
    'asrProgressPreparing': 'ASR vorbereiten...',
    'asrProgressDownloading': 'ASR-Modell wird heruntergeladen...',
    'asrProgressDownloadDone': 'Download des ASR-Modells abgeschlossen.',
    'asrProgressExtracting': 'ASR-Modell extrahieren...',
    'asrProgressExtractDone': 'Extraktion des ASR-Modells abgeschlossen.',
    'asrProgressLoadingModel': 'ASR-Modell wird geladen...',
    'asrProgressDecoding': 'Sprache erkennen...',
    'asrProgressDone': 'Anerkennung abgeschlossen.',
    'pronunciationDiffMissing': 'Fehlt: {value}',
    'pronunciationDiffExtra': 'Extra: {value}',
    'pronunciationDiffReplace': '„{from}“ erwartet, „{to}“ gehört',
  };

  static const Map<String, String> _fr = <String, String>{
    'appTitle': '咸鱼声息',
    'importWordbook': 'Importer un livre de mots',
    'migrateLegacy': 'Migrer la base de données héritée',
    'newWordbook': 'Nouveau livre de mots',
    'addWord': 'Ajouter un mot',
    'jsonBatchImport': 'Importation par lots JSON',
    'settings': 'Paramètres',
    'ambientAudio': 'Audio ambiant',
    'noWordbookYet':
        'Pas encore de manuel de mots. Importez ou créez-en un d’abord.',
    'play': 'Jouer',
    'pause': 'Pause',
    'resume': 'Reprendre',
    'skip': 'Sauter',
    'stop': 'Arrêt',
    'ttsProvider': 'Fournisseur TTS',
    'local': 'Local',
    'siliconFlowApi': 'API SiliconFlow',
    'customApi': 'API personnalisée',
    'voice': 'Voix',
    'defaultVoice': 'Voix par défaut',
    'ttsModel': 'Modèle TTS',
    'ttsApiKey': 'Clé API TTS',
    'ttsApiBaseUrl': 'URL de base TTS',
    'ttsModelIdHint': 'Entrez l\'ID du modèle',
    'localVoicesNotFound':
        'Aucune voix locale trouvée. La voix par défaut du système sera utilisée.',
    'enableAsr': 'Activer le suivi ASR',
    'asrProvider': 'Fournisseur ASR',
    'asrLanguage': 'Langue ASR (par exemple en / zh)',
    'asrLanguageAuto': 'Auto',
    'asrLanguageEnglish': 'anglais (fr)',
    'asrLanguageChinese': 'Chinois (zh)',
    'asrLanguageJapanese': 'Japonais (ja)',
    'asrLanguageFrench': 'français (fr)',
    'asrLanguageGerman': 'allemand (de)',
    'asrLanguageSpanish': 'Espagnol (es)',
    'asrLanguageCustom': 'Code personnalisé',
    'asrLanguageCustomInput': 'Code de langue personnalisé',
    'asrLanguageCustomInputHint': 'par ex. pt-BR / il',
    'asrModel': 'Modèle ASR (mode API)',
    'asrApiKey': 'Clé API ASR (mode API)',
    'asrApiBaseUrl': 'URL de base ASR (API personnalisée)',
    'offlineWhisperBase': 'Hors ligne (Whisper Base)',
    'offlineWhisperSmall': 'Hors ligne (Whisper Small)',
    'asrLocalSimilarity': 'Similarité locale (pas d\'ASR)',
    'asrMultiEngine': 'Multimoteur (sélectionnable)',
    'asrLocalSimilarityHint':
        'Utilise le TTS de lecture actuel (local ou distant) pour générer un audio de référence, puis compare la prononciation localement par similarité acoustique.',
    'asrMultiEngineHint':
        'Sélectionnez un ou plusieurs moteurs. Ils courent dans l\'ordre. Les résultats de l’ASR du texte et de la similarité acoustique seront combinés lorsqu’ils seront disponibles.',
    'asrScoringMethods': 'Méthodes de notation de la prononciation',
    'asrScoringMethodsHint':
        'Choisissez les algorithmes de notation à activer. Packages installés uniquement.',
    'asrScoringPackManager': 'Gestionnaire de packages de notation',
    'asrScoringPackInstallFirst':
        'Téléchargez d\'abord le package pour activer cette méthode.',
    'asrDumpRecognitionAudio': 'Dumper l\'audio de reconnaissance brut/traité',
    'asrDumpRecognitionAudioHint':
        'Enregistrez les fichiers audio temporaires bruts et traités pour comparaison/débogage.',
    'scorerSslEmbedding': 'Similitude d\'intégration SSL (HuBERT/wav2vec2)',
    'scorerGop': 'Notation GOP',
    'scorerForcedAlignmentPer': 'Alignement forcé + PER',
    'scorerPpgPosterior': 'Notation postérieure PPG',
    'asrScoringMethodApplied': 'Notation appliquée : {method}',
    'asrScoringEngineApplied': 'Noté par moteur : {engine}',
    'asrScoringBreakdown': 'Répartition de la méthode',
    'asrOfflineModelManager': 'Packages de modèles hors ligne',
    'asrModelInstalled': 'Installé ({size})',
    'asrModelNotInstalled': 'Non installé (taille du téléchargement : {size})',
    'asrOfflineNoticeTitle': 'Avis ASR hors ligne',
    'asrOfflineNoticeBody':
        'L\'ASR hors ligne nécessite un premier téléchargement supplémentaire ({size}) et a une précision moindre. Recommandé : API distante (actuellement gratuite sur cette plateforme après inscription).',
    'language': 'Langue',
    'cancel': 'Annuler',
    'save': 'Sauvegarder',
    'close': 'Fermer',
    'searchPlaceholder': 'Rechercher un mot ou un contenu',
    'all': 'Tous',
    'word': 'Mot',
    'meaning': 'Signification',
    'fuzzy': 'Flou',
    'go': 'Aller',
    'wordsCount': '{count} mots',
    'selectWord': 'Sélectionnez un mot',
    'toggleFavorite': 'Changer de favori',
    'toggleTask': 'Basculer le mot de tâche',
    'edit': 'Modifier',
    'delete': 'Supprimer',
    'followAlong': 'Suivez-nous',
    'followAlongTitle': 'Suivez-nous',
    'playPronunciation': 'Jouer la prononciation',
    'tapToStopRecord': 'Appuyez pour arrêter l\'enregistrement',
    'tapToStartRecord': 'Appuyez pour démarrer l\'enregistrement',
    'recognizing': 'Reconnaître...',
    'recognitionFailed': 'La reconnaissance a échoué',
    'great': 'Super',
    'needsPractice': 'Nécessite de la pratique',
    'recognizedText': 'Reconnu : {text}',
    'similarity': 'Similarité : {score}%',
    'differences': 'Différences',
    'wordbooks': 'Livres de mots',
    'rename': 'Rebaptiser',
    'mergeWordbooks': 'Fusionner des manuels de mots',
    'exportTaskWordbook': 'Exporter le manuel de tâches',
    'clearTaskWordbook': 'Manuel de tâches clair',
    'createWordbook': 'Créer un livre de mots',
    'wordbookName': 'Nom du carnet de mots',
    'create': 'Créer',
    'renameWordbook': 'Renommer le carnet de mots',
    'deleteWordbook': 'Supprimer le carnet de mots',
    'confirmDeleteWordbook': 'Supprimer "{name}" ?',
    'confirmDeleteWord': 'Supprimer "{word}" ?',
    'mergeDialogTitle': 'Fusionner des manuels de mots',
    'sourceWordbook': 'Recueil de mots source',
    'targetWordbook': 'Livre de mots cible',
    'deleteSourceAfterMerge': 'Supprimer la source après la fusion',
    'needTwoWordbooks':
        'Besoin d\'au moins deux manuels de mots personnalisés.',
    'addWordTitle': 'Ajouter un mot',
    'editWordTitle': 'Modifier le mot',
    'fieldWord': 'Mot',
    'fieldMeaning': 'Signification',
    'fieldExamples': 'Exemples',
    'fieldEtymology': 'Étymologie',
    'fieldRoots': 'Racines',
    'fieldAffixes': 'Affixes',
    'fieldVariations': 'Variantes',
    'fieldMemory': 'Mémoire',
    'fieldStory': 'Histoire',
    'fieldContent': 'Contenu du champ',
    'fieldKey': 'Clé de champ',
    'fieldLabel': 'Libellé du champ',
    'fieldKeyPlaceholder': 'Entrez la clé du champ (par exemple, racines)',
    'fieldLabelPlaceholder':
        'Saisissez le libellé du champ (par exemple, Racines)',
    'fieldCopied': 'Champ copié',
    'copyField': 'Copie',
    'editField': 'Modifier le champ',
    'deleteField': 'Supprimer le champ',
    'deleteFieldTitle': 'Supprimer le champ',
    'deleteFieldMessage': 'Supprimer le champ "{field}" ?',
    'editFieldTitle': 'Modifier le champ : {field}',
    'addField': 'Ajouter un champ',
    'expandEmptyFields': 'Développer les champs vides',
    'collapseEmptyFields': 'Réduire les champs vides',
    'emptyFieldsDetected': 'Champs vides détectés',
    'deleteWordInEditor': 'Supprimer le mot',
    'specialWordbooks': 'Tâche et favoris',
    'manageWordbook': 'Gestion des manuels de mots',
    'playbackVolume': 'Volume de lecture',
    'masterVolume': 'Volume principal',
    'playbackSpeed': 'Vitesse de lecture',
    'wordRepeat': 'Répétition de mots',
    'meaningRepeat': 'Signification répéter',
    'exampleRepeat': 'Exemple de répétition',
    'spellingLabel': 'Orthographe',
    'nonCoreRepeat': 'Répétition non essentielle',
    'applyToAllNonCore': 'Appliquer à tous',
    'currentPlayingList': 'Lecture actuelle',
    'currentWord': 'Mot actuel',
    'progress': 'Progrès',
    'startFrom': 'Commencer à partir de',
    'prev': 'Précédent',
    'next': 'Suivant',
    'testMode': 'Mode Test',
    'backToTop': 'Retour en haut',
    'showHint': 'Afficher l\'indice',
    'hideHint': 'Masquer l\'indice',
    'revealAnswer': 'Révéler la réponse',
    'hideAnswer': 'Masquer la réponse',
    'testModeEnabledHint': 'Le mode test est activé',
    'coreRepeat': 'Répétition de base',
    'overallLoop': 'Boucle globale',
    'delayBetweenUnits': 'Délai entre les unités (ms)',
    'showText': 'Afficher le texte',
    'saveAndApply': 'Enregistrer et appliquer',
    'download': 'Télécharger',
    'processing': 'Traitement...',
    'settingsTabPlayback': 'Lecture',
    'settingsTabVoice': 'Voix',
    'settingsTabAsr': 'Reconnaissance',
    'settingsTabAppearance': 'Apparence',
    'appearanceThemeTitle': 'Thème',
    'appearanceLayoutTitle': 'Mise en page',
    'appearanceLayoutHint':
        'Les détails de la mise en page seront affinés lors de la prochaine itération.',
    'appearanceColorsTitle': 'Couleurs',
    'appearanceColorsHint':
        'Les détails des couleurs seront affinés lors de la prochaine itération.',
    'appearanceBackgroundTitle': 'Arrière-plan',
    'appearanceBackgroundHint':
        'Les détails du contexte seront affinés lors de la prochaine itération.',
    'appearanceFieldSectionsTitle': 'Sections de terrain',
    'appearanceFieldSectionsHint':
        'Les styles de section de champ seront affinés dans la prochaine itération.',
    'themeFlat': 'Bleu plat',
    'themeTech': 'Bleu technique',
    'themeDark': 'Sombre',
    'themeFantasy': 'Fantaisie',
    'themeNature': 'Nature',
    'themeSunset': 'Coucher de soleil',
    'themeOcean': 'Océan',
    'themeMono': 'Mono',
    'noAudioSources': 'Aucune source audio',
    'importAudio': 'Importer un fichier audio',
    'importedAudio': 'Audio importé',
    'ambientCategoryNoise': 'Bruit',
    'ambientCategoryNature': 'Nature',
    'ambientCategoryRain': 'Pluie',
    'ambientCategoryFocus': 'Se concentrer',
    'ambientNameNoiseWhite': 'Bruit blanc',
    'ambientNameNoisePink': 'Bruit rose',
    'ambientNameNoiseBrown': 'Bruit brun',
    'ambientNameNatureWind': 'Vent',
    'ambientNameNatureForest': 'Vent dans les arbres',
    'ambientNameNatureFire': 'Feu de camp',
    'ambientNameNatureOcean': 'Flots',
    'ambientNameRainLight': 'Pluie légère',
    'ambientNameRainHeavy': 'Forte pluie',
    'ambientNameFocusLibrary': 'Bibliothèque',
    'ambientNameFocusCafe': 'Café',
    'ambientNameFocusNightVillage': 'Village de nuit',
    'jumpByLetter': 'Sauter par lettre',
    'jumpByPrefix': 'Sauter par préfixe',
    'jumpNoMatch': 'Aucun mot ne correspondant à "{value}"',
    'importedWordbookName': 'Livre de mots importé',
    'errorInitFailed': 'Échec de l\'initialisation : {error}',
    'errorCreateWordbookFailed':
        'Échec de la création du livre de mots : {error}',
    'errorRenameWordbookFailed': 'Échec du changement de nom : {error}',
    'errorDeleteWordbookFailed':
        'Échec de la suppression du répertoire : {error}',
    'importWordbookSuccess': '{count} mots importés',
    'importWordbookSuccessWithBackup':
        '{count} mots importés (sauvegarde enregistrée)',
    'errorImportFailed': 'Échec de l\'importation : {error}',
    'migrationSuccess': 'Migration terminée, {count} lignes importées',
    'migrationSuccessWithBackup':
        'Migration terminée, {count} lignes importées (sauvegarde enregistrée)',
    'errorMigrationFailed': 'Échec de la migration : {error}',
    'errorWordEmpty': 'Le mot ne peut pas être vide',
    'errorSaveWordFailed': 'Échec de l\'enregistrement du mot : {error}',
    'errorDeleteWordFailed': 'Échec de la suppression du mot : {error}',
    'errorFavoriteOperationFailed': 'Échec de l\'opération Favoris : {error}',
    'errorTaskOperationFailed': 'Échec de l\'opération de tâche : {error}',
    'errorClearTaskWordbookFailed':
        'Échec de l\'effacement du manuel de tâches : {error}',
    'errorExportFailed': 'Échec de l\'exportation : {error}',
    'errorMergeFailed': 'Échec de la fusion : {error}',
    'recordingFailed': 'L\'enregistrement a échoué',
    'startRecordingFailed':
        'Échec du démarrage de l\'enregistrement. Veuillez vérifier l\'autorisation du microphone.',
    'enableAsrFirst': 'Veuillez d\'abord activer l\'ASR dans les paramètres.',
    'playCurrent': 'Jouer en cours',
    'asrDisabled': 'L\'ASR est désactivé.',
    'asrAudioFileNotFound': 'Fichier audio introuvable.',
    'asrApiKeyMissing': 'La clé API ASR est manquante.',
    'asrApiBaseUrlMissing': 'L\'URL de base de l\'API ASR est manquante.',
    'asrApiTimeout': 'La demande ASR a expiré.',
    'asrApiRequestFailed': 'La requête API ASR a échoué ({code}). {body}',
    'asrRequestFailed': 'La requête ASR a échoué : {error}',
    'asrEmptyResult': 'Aucun discours reconnu.',
    'asrInvalidWav': 'Format d\'enregistrement invalide.',
    'asrRecordingTooShort': 'L\'enregistrement est trop court.',
    'asrNoSpeechDetected': 'Aucune parole détectée lors de l\'enregistrement.',
    'asrRecognitionCancelled': 'La reconnaissance a été annulée.',
    'asrLocalSimilarityNoTranscript':
        'Pas de transcription en mode similarité locale (partition audio uniquement).',
    'asrSimilarityExpectedTextMissing':
        'Le mot cible est manquant pour le mode de similarité locale.',
    'asrSimilarityTtsMissing':
        'La configuration TTS est manquante pour le mode de similarité locale.',
    'asrSimilarityRequiresRemoteTts':
        'Le mode de similarité locale nécessite un audio de référence TTS disponible.',
    'asrSimilarityTtsApiKeyMissing':
        'La clé API TTS est manquante pour le mode de similarité locale.',
    'asrSimilarityTtsBaseUrlMissing':
        'L\'URL de base TTS est manquante pour le mode de similarité locale.',
    'asrSimilarityLocalSynthesisUnsupported':
        'La plate-forme actuelle ne peut pas exporter l\'audio de référence TTS local. Basculez vers TTS distant.',
    'asrSimilarityReferenceInvalid':
        'Échec de la génération d\'un audio de référence valide pour la comparaison de similarité.',
    'asrSimilarityReferenceFailedHttp':
        'La demande audio de référence a échoué ({code}). {body}',
    'asrSimilarityFeatureInsufficient':
        'L\'audio est trop court ou peu clair pour permettre une comparaison de similarité.',
    'asrSimilarityFailed':
        'Échec de la comparaison de similarité locale : {error}',
    'asrScoringPackNotInstalled':
        'Aucun package de notation sélectionné n\'est installé. Veuillez en télécharger au moins un.',
    'asrScoringPackUnsupported': 'Package de notation non pris en charge.',
    'asrMultiEngineNoResult':
        'Aucun moteur n\'a produit de résultat valide. Veuillez ajuster la sélection du moteur.',
    'asrOfflineFailed': 'Échec de l\'ASR hors ligne : {error}',
    'asrOfflineInitFailed': 'L\'initialisation ASR hors ligne a échoué.',
    'asrUnsupportedOfflineProvider':
        'Fournisseur ASR hors ligne non pris en charge.',
    'asrModelMissingAfterExtract':
        'Les fichiers du modèle ASR sont manquants après l\'extraction.',
    'asrModelExtractionIncomplete':
        'L\'extraction du modèle ASR est incomplète.',
    'asrDownloadFailedHttp':
        'Le téléchargement du modèle ASR a échoué ({code}).',
    'asrProgressStoppingRecording': 'Arrêt de l\'enregistrement...',
    'asrProgressPreparing': 'Préparation de l\'ASR...',
    'asrProgressDownloading': 'Téléchargement du modèle ASR...',
    'asrProgressDownloadDone': 'Téléchargement du modèle ASR terminé.',
    'asrProgressExtracting': 'Extraction du modèle ASR...',
    'asrProgressExtractDone': 'Extraction du modèle ASR terminée.',
    'asrProgressLoadingModel': 'Chargement du modèle ASR...',
    'asrProgressDecoding': 'Reconnaître la parole...',
    'asrProgressDone': 'Reconnaissance terminée.',
    'pronunciationDiffMissing': 'Manquant : {value}',
    'pronunciationDiffExtra': 'Supplément : {value}',
    'pronunciationDiffReplace': '"{from}" attendu, "{to}" entendu',
  };

  static const Map<String, String> _es = <String, String>{
    'appTitle': '咸鱼声息',
    'importWordbook': 'Importar libro de palabras',
    'migrateLegacy': 'Migrar base de datos heredada',
    'newWordbook': 'Nuevo libro de palabras',
    'addWord': 'Agregar palabra',
    'jsonBatchImport': 'Importación por lotes JSON',
    'settings': 'Ajustes',
    'ambientAudio': 'Audio ambiental',
    'noWordbookYet':
        'Aún no hay ningún libro de palabras. Importe o cree uno primero.',
    'play': 'Reproducir',
    'pause': 'Pausa',
    'resume': 'Reanudar',
    'skip': 'Saltar',
    'stop': 'Detener',
    'ttsProvider': 'Proveedor de TTS',
    'local': 'Local',
    'siliconFlowApi': 'API de flujo de silicio',
    'customApi': 'API personalizada',
    'voice': 'Voz',
    'defaultVoice': 'Voz predeterminada',
    'ttsModel': 'Modelo TTS',
    'ttsApiKey': 'Clave API TTS',
    'ttsApiBaseUrl': 'URL básica de TTS',
    'ttsModelIdHint': 'Ingrese el ID del modelo',
    'localVoicesNotFound':
        'No se encontraron voces locales. Se utilizará la voz predeterminada del sistema.',
    'enableAsr': 'Habilitar el seguimiento de ASR',
    'asrProvider': 'Proveedor de ASR',
    'asrLanguage': 'Idioma ASR (por ejemplo, en / zh)',
    'asrLanguageAuto': 'Auto',
    'asrLanguageEnglish': 'Inglés (es)',
    'asrLanguageChinese': 'chino (zh)',
    'asrLanguageJapanese': 'japonés (ja)',
    'asrLanguageFrench': 'francés (fr)',
    'asrLanguageGerman': 'alemán (de)',
    'asrLanguageSpanish': 'español (es)',
    'asrLanguageCustom': 'código personalizado',
    'asrLanguageCustomInput': 'Código de idioma personalizado',
    'asrLanguageCustomInputHint': 'p.ej. pt-BR/es',
    'asrModel': 'Modelo ASR (modo API)',
    'asrApiKey': 'Clave API ASR (modo API)',
    'asrApiBaseUrl': 'URL base de ASR (API personalizada)',
    'offlineWhisperBase': 'Sin conexión (Base de susurros)',
    'offlineWhisperSmall': 'Sin conexión (Whisper Small)',
    'asrLocalSimilarity': 'Similitud local (sin ASR)',
    'asrMultiEngine': 'Multimotor (seleccionable)',
    'asrLocalSimilarityHint':
        'Utiliza TTS de reproducción actual (local o remoto) para generar audio de referencia y luego compara la pronunciación localmente mediante similitud acústica.',
    'asrMultiEngineHint':
        'Seleccione uno o más motores. Corren en orden. Los resultados de ASR de texto y similitud acústica se combinarán cuando estén disponibles.',
    'asrScoringMethods': 'Métodos de puntuación de pronunciación',
    'asrScoringMethodsHint':
        'Elija qué algoritmos de puntuación habilitar. Solo paquetes instalados.',
    'asrScoringPackManager': 'Administrador de paquetes de puntuación',
    'asrScoringPackInstallFirst':
        'Descargue el paquete primero para habilitar este método.',
    'asrDumpRecognitionAudio':
        'Volcar audio de reconocimiento sin procesar/procesado',
    'asrDumpRecognitionAudioHint':
        'Guarde archivos de audio temporales sin procesar y procesados ​​para compararlos/depurarlos.',
    'scorerSslEmbedding': 'Similitud de incrustación de SSL (HuBERT/wav2vec2)',
    'scorerGop': 'Puntuación del Partido Republicano',
    'scorerForcedAlignmentPer': 'Alineación forzada + PER',
    'scorerPpgPosterior': 'Puntuación posterior de PPG',
    'asrScoringMethodApplied': 'Puntuación aplicada: {method}',
    'asrScoringEngineApplied': 'Puntuación por motor: {engine}',
    'asrScoringBreakdown': 'Desglose del método',
    'asrOfflineModelManager': 'Paquetes de modelos sin conexión',
    'asrModelInstalled': 'Instalado ({size})',
    'asrModelNotInstalled': 'No instalado (tamaño de descarga: {size})',
    'asrOfflineNoticeTitle': 'Aviso de ASR sin conexión',
    'asrOfflineNoticeBody':
        'ASR sin conexión necesita una descarga adicional por primera vez ({size}) y tiene menor precisión. Recomendado: API remota (actualmente gratuita en esta plataforma después del registro).',
    'language': 'Idioma',
    'cancel': 'Cancelar',
    'save': 'Ahorrar',
    'close': 'Cerrar',
    'searchPlaceholder': 'Buscar palabra o contenido',
    'all': 'Todo',
    'word': 'Palabra',
    'meaning': 'Significado',
    'fuzzy': 'Difuso',
    'go': 'Ir',
    'wordsCount': '{count} palabras',
    'selectWord': 'Selecciona una palabra',
    'toggleFavorite': 'Alternar favorito',
    'toggleTask': 'Alternar palabra de tarea',
    'edit': 'Editar',
    'delete': 'Borrar',
    'followAlong': 'Seguir adelante',
    'followAlongTitle': 'Seguir adelante',
    'playPronunciation': 'Reproducir pronunciación',
    'tapToStopRecord': 'Toca para detener la grabación',
    'tapToStartRecord': 'Toca para comenzar a grabar',
    'recognizing': 'Reconociendo...',
    'recognitionFailed': 'El reconocimiento falló',
    'great': 'Excelente',
    'needsPractice': 'Necesita practica',
    'recognizedText': 'Reconocido: {text}',
    'similarity': 'Similitud: {score}%',
    'differences': 'Diferencias',
    'wordbooks': 'Libros de palabras',
    'rename': 'Rebautizar',
    'mergeWordbooks': 'Fusionar libros de palabras',
    'exportTaskWordbook': 'Exportar libro de tareas de tareas',
    'clearTaskWordbook': 'Borrar libro de tareas',
    'createWordbook': 'Crear libro de palabras',
    'wordbookName': 'Nombre del libro de palabras',
    'create': 'Crear',
    'renameWordbook': 'Cambiar nombre del libro de palabras',
    'deleteWordbook': 'Eliminar libro de palabras',
    'confirmDeleteWordbook': '¿Eliminar "{name}"?',
    'confirmDeleteWord': '¿Eliminar "{word}"?',
    'mergeDialogTitle': 'Fusionar libros de palabras',
    'sourceWordbook': 'Libro de palabras fuente',
    'targetWordbook': 'Libro de palabras objetivo',
    'deleteSourceAfterMerge': 'Eliminar fuente después de fusionar',
    'needTwoWordbooks':
        'Necesita al menos dos libros de palabras personalizados.',
    'addWordTitle': 'Agregar palabra',
    'editWordTitle': 'Editar palabra',
    'fieldWord': 'Palabra',
    'fieldMeaning': 'Significado',
    'fieldExamples': 'Ejemplos',
    'fieldEtymology': 'Etimología',
    'fieldRoots': 'Raíces',
    'fieldAffixes': 'Afijos',
    'fieldVariations': 'Variaciones',
    'fieldMemory': 'Memoria',
    'fieldStory': 'Historia',
    'fieldContent': 'Contenido del campo',
    'fieldKey': 'Clave de campo',
    'fieldLabel': 'Etiqueta de campo',
    'fieldKeyPlaceholder': 'Ingrese la clave del campo (por ejemplo, raíces)',
    'fieldLabelPlaceholder':
        'Ingrese la etiqueta del campo (por ejemplo, Raíces)',
    'fieldCopied': 'Campo copiado',
    'copyField': 'Copiar',
    'editField': 'Editar campo',
    'deleteField': 'Eliminar campo',
    'deleteFieldTitle': 'Eliminar campo',
    'deleteFieldMessage': '¿Eliminar el campo "{field}"?',
    'editFieldTitle': 'Editar campo: {field}',
    'addField': 'Agregar campo',
    'expandEmptyFields': 'Expandir campos vacíos',
    'collapseEmptyFields': 'Contraer campos vacíos',
    'emptyFieldsDetected': 'Campos vacíos detectados',
    'deleteWordInEditor': 'Eliminar palabra',
    'specialWordbooks': 'Tarea y favoritos',
    'manageWordbook': 'Gestión de libros de palabras',
    'playbackVolume': 'Volumen de reproducción',
    'masterVolume': 'Volumen maestro',
    'playbackSpeed': 'Velocidad de reproducción',
    'wordRepeat': 'repetición de palabras',
    'meaningRepeat': 'Significado repetir',
    'exampleRepeat': 'Ejemplo de repetición',
    'spellingLabel': 'Ortografía',
    'nonCoreRepeat': 'Repetición no básica',
    'applyToAllNonCore': 'Aplicar a todos',
    'currentPlayingList': 'Jugando actualmente',
    'currentWord': 'Palabra actual',
    'progress': 'Progreso',
    'startFrom': 'Empezar desde',
    'prev': 'Anterior',
    'next': 'Próximo',
    'testMode': 'Modo de prueba',
    'backToTop': 'Volver al principio',
    'showHint': 'Mostrar sugerencia',
    'hideHint': 'Ocultar pista',
    'revealAnswer': 'Revelar respuesta',
    'hideAnswer': 'Ocultar respuesta',
    'testModeEnabledHint': 'El modo de prueba está habilitado',
    'coreRepeat': 'Repetición central',
    'overallLoop': 'Bucle general',
    'delayBetweenUnits': 'Retraso entre unidades (ms)',
    'showText': 'Mostrar texto',
    'saveAndApply': 'Guardar y aplicar',
    'download': 'Descargar',
    'processing': 'Tratamiento...',
    'settingsTabPlayback': 'Reproducción',
    'settingsTabVoice': 'Voz',
    'settingsTabAsr': 'Reconocimiento',
    'settingsTabAppearance': 'Apariencia',
    'appearanceThemeTitle': 'Tema',
    'appearanceLayoutTitle': 'Disposición',
    'appearanceLayoutHint':
        'Los detalles del diseño se perfeccionarán en la próxima iteración.',
    'appearanceColorsTitle': 'Bandera',
    'appearanceColorsHint':
        'Los detalles de color se perfeccionarán en la próxima versión.',
    'appearanceBackgroundTitle': 'Fondo',
    'appearanceBackgroundHint':
        'Los detalles del fondo se perfeccionarán en la próxima versión.',
    'appearanceFieldSectionsTitle': 'Secciones de campo',
    'appearanceFieldSectionsHint':
        'Los estilos de las secciones de campo se perfeccionarán en la próxima iteración.',
    'themeFlat': 'Azul plano',
    'themeTech': 'Azul tecnológico',
    'themeDark': 'Oscuro',
    'themeFantasy': 'Fantasía',
    'themeNature': 'Naturaleza',
    'themeSunset': 'Atardecer',
    'themeOcean': 'Océano',
    'themeMono': 'Mono',
    'noAudioSources': 'Sin fuentes de audio',
    'importAudio': 'Importar archivo de audio',
    'importedAudio': 'Audio importado',
    'ambientCategoryNoise': 'Ruido',
    'ambientCategoryNature': 'Naturaleza',
    'ambientCategoryRain': 'Lluvia',
    'ambientCategoryFocus': 'Enfocar',
    'ambientNameNoiseWhite': 'Ruido Blanco',
    'ambientNameNoisePink': 'Ruido Rosa',
    'ambientNameNoiseBrown': 'Ruido Marrón',
    'ambientNameNatureWind': 'Viento',
    'ambientNameNatureForest': 'Viento en los árboles',
    'ambientNameNatureFire': 'Hoguera',
    'ambientNameNatureOcean': 'Ondas',
    'ambientNameRainLight': 'lluvia ligera',
    'ambientNameRainHeavy': 'Lluvia Pesada',
    'ambientNameFocusLibrary': 'Biblioteca',
    'ambientNameFocusCafe': 'Cafetería',
    'ambientNameFocusNightVillage': 'pueblo nocturno',
    'jumpByLetter': 'Saltar por letra',
    'jumpByPrefix': 'Saltar por prefijo',
    'jumpNoMatch': 'No hay palabras que coincidan con "{value}"',
    'importedWordbookName': 'Libro de palabras importado',
    'errorInitFailed': 'Error de inicialización: {error}',
    'errorCreateWordbookFailed': 'Error al crear el libro de palabras: {error}',
    'errorRenameWordbookFailed': 'Error al cambiar el nombre: {error}',
    'errorDeleteWordbookFailed':
        'Error al eliminar el libro de palabras: {error}',
    'importWordbookSuccess': '{count} palabras importadas',
    'importWordbookSuccessWithBackup':
        '{count} palabras importadas (copia de seguridad guardada)',
    'errorImportFailed': 'Error de importación: {error}',
    'migrationSuccess': 'Migración completada, {count} filas importadas',
    'migrationSuccessWithBackup':
        'Migración completada, {count} filas importadas (copia de seguridad guardada)',
    'errorMigrationFailed': 'Error de migración: {error}',
    'errorWordEmpty': 'La palabra no puede estar vacía.',
    'errorSaveWordFailed': 'Error al guardar palabra: {error}',
    'errorDeleteWordFailed': 'Error al eliminar palabra: {error}',
    'errorFavoriteOperationFailed': 'Error en la operación favorita: {error}',
    'errorTaskOperationFailed': 'La operación de tarea falló: {error}',
    'errorClearTaskWordbookFailed':
        'Error al borrar el libro de tareas: {error}',
    'errorExportFailed': 'Exportación fallida: {error}',
    'errorMergeFailed': 'Fusión fallida: {error}',
    'recordingFailed': 'Error de grabación',
    'startRecordingFailed':
        'No se pudo iniciar la grabación. Por favor verifique el permiso del micrófono.',
    'enableAsrFirst': 'Primero habilite ASR en Configuración.',
    'playCurrent': 'Reproducir actual',
    'asrDisabled': 'ASR está deshabilitado.',
    'asrAudioFileNotFound': 'Archivo de audio no encontrado.',
    'asrApiKeyMissing': 'Falta la clave API de ASR.',
    'asrApiBaseUrlMissing': 'Falta la URL base de la API de ASR.',
    'asrApiTimeout': 'Se agotó el tiempo de espera de la solicitud de ASR.',
    'asrApiRequestFailed': 'La solicitud de API de ASR falló ({code}). {body}',
    'asrRequestFailed': 'La solicitud de ASR falló: {error}',
    'asrEmptyResult': 'No se reconoce ningún discurso.',
    'asrInvalidWav': 'Formato de grabación no válido.',
    'asrRecordingTooShort': 'La grabación es demasiado corta.',
    'asrNoSpeechDetected': 'No se detectó voz en la grabación.',
    'asrRecognitionCancelled': 'Se canceló el reconocimiento.',
    'asrLocalSimilarityNoTranscript':
        'Sin transcripción en modo de similitud local (solo partitura de audio).',
    'asrSimilarityExpectedTextMissing':
        'Falta la palabra objetivo para el modo de similitud local.',
    'asrSimilarityTtsMissing':
        'Falta la configuración TTS para el modo de similitud local.',
    'asrSimilarityRequiresRemoteTts':
        'El modo de similitud local requiere audio de referencia TTS disponible.',
    'asrSimilarityTtsApiKeyMissing':
        'Falta la clave API TTS para el modo de similitud local.',
    'asrSimilarityTtsBaseUrlMissing':
        'Falta la URL base de TTS para el modo de similitud local.',
    'asrSimilarityLocalSynthesisUnsupported':
        'La plataforma actual no puede exportar audio de referencia TTS local. Cambie a TTS remoto.',
    'asrSimilarityReferenceInvalid':
        'No se pudo generar un audio de referencia válido para la comparación de similitudes.',
    'asrSimilarityReferenceFailedHttp':
        'La solicitud de audio de referencia falló ({code}). {body}',
    'asrSimilarityFeatureInsufficient':
        'El audio es demasiado corto o poco claro para comparar similitudes.',
    'asrSimilarityFailed': 'La comparación de similitud local falló: {error}',
    'asrScoringPackNotInstalled':
        'No hay ningún paquete de puntuación seleccionado instalado. Descargue al menos uno.',
    'asrScoringPackUnsupported': 'Paquete de puntuación no compatible.',
    'asrMultiEngineNoResult':
        'Ningún motor produjo un resultado válido. Ajuste la selección del motor.',
    'asrOfflineFailed': 'ASR sin conexión falló: {error}',
    'asrOfflineInitFailed': 'La inicialización de ASR sin conexión falló.',
    'asrUnsupportedOfflineProvider':
        'Proveedor de ASR fuera de línea no compatible.',
    'asrModelMissingAfterExtract':
        'Faltan archivos del modelo ASR después de la extracción.',
    'asrModelExtractionIncomplete':
        'La extracción del modelo ASR está incompleta.',
    'asrDownloadFailedHttp': 'Error en la descarga del modelo ASR ({code}).',
    'asrProgressStoppingRecording': 'Deteniendo la grabación...',
    'asrProgressPreparing': 'Preparando ASR...',
    'asrProgressDownloading': 'Descargando modelo ASR...',
    'asrProgressDownloadDone': 'Descarga del modelo ASR completada.',
    'asrProgressExtracting': 'Extrayendo el modelo ASR...',
    'asrProgressExtractDone': 'Se completó la extracción del modelo ASR.',
    'asrProgressLoadingModel': 'Cargando modelo ASR...',
    'asrProgressDecoding': 'Reconocer el habla...',
    'asrProgressDone': 'Reconocimiento completado.',
    'pronunciationDiffMissing': 'Desaparecido: {value}',
    'pronunciationDiffExtra': 'Extra: {value}',
    'pronunciationDiffReplace': 'Se esperaba "{from}", se escuchó "{to}"',
  };

  static final Map<String, String> _zh = <String, String>{
    ..._en,
    ..._zhBase,
    ..._zhExtra,
    ..._toolboxEn,
    ..._toolboxZh,
  };

  static const Map<String, String> _focusEn = <String, String>{
    'focusTitle': 'Focus',
    'timerTab': 'Timer',
    'todoTab': 'Tasks',
    'timerIdle': 'Ready',
    'focusPhase': 'Focus',
    'breakPhase': 'Break',
    'focusPhaseComplete': 'Focus session complete!',
    'breakPhaseComplete': 'Break time over!',
    'roundProgress': 'Round {current} of {total}',
    'startFocus': 'Start Focus',
    'timerConfig': 'Timer Settings',
    'focusMinutes': 'Focus (min)',
    'breakMinutes': 'Break (min)',
    'rounds': 'Rounds',
    'stopTimer': 'Stop Timer',
    'stopTimerConfirm': 'Stop the timer and save progress?',
    'todayStats': 'Today\'s Stats',
    'focusMinutesLabel': 'Focus Minutes',
    'roundsLabel': 'Rounds',
    'addTodoHint': 'Add a new task...',
    'clearCompleted': 'Clear Completed',
    'quickNotes': 'Quick Notes',
    'addNote': 'Add Note',
    'editNote': 'Edit Note',
    'deleteNote': 'Delete Note',
    'deleteNoteConfirm': 'Delete this note?',
    'noteTitle': 'Title',
    'noteContent': 'Content',
  };

  static const Map<String, String> _focusZh = <String, String>{
    'focusTitle': '专注',
    'timerTab': '计时器',
    'todoTab': '待办',
    'timerIdle': '准备就绪',
    'focusPhase': '专注中',
    'breakPhase': '休息中',
    'breakReady': '开始休息',
    'focusReady': '开始下一轮',
    'focusPhaseComplete': '专注时间结束！',
    'breakPhaseComplete': '休息时间结束！',
    'roundProgress': '第 {current} 轮，共 {total} 轮',
    'startFocus': '开始专注',
    'startBreak': '开始休息',
    'startNextRound': '开始下一轮',
    'timerConfig': '计时器设置',
    'focusMinutes': '专注时长',
    'breakMinutes': '休息时长',
    'rounds': '循环轮数',
    'autoStartBreak': '专注结束后自动开始休息',
    'autoStartNextRound': '休息结束后自动开始下一轮',
    'timerWaitingAction': '等待你手动进入下一阶段',
    'stopTimer': '停止计时',
    'stopTimerConfirm': '停止计时并保存进度？',
    'todayStats': '今日统计',
    'focusMinutesLabel': '专注分钟',
    'sessionMinutesLabel': '总会话分钟',
    'roundsLabel': '完成轮数',
    'addTodo': '添加任务',
    'addTodoHint': '添加新任务...',
    'clearCompleted': '清除已完成',
    'quickNotes': '快速笔记',
    'addNote': '添加笔记',
    'editNote': '编辑笔记',
    'deleteNote': '删除笔记',
    'deleteNoteConfirm': '确定删除此笔记？',
    'noteTitle': '标题',
    'noteContent': '内容',
  };

  static const Map<String, String> _focusJa = <String, String>{
    'focusTitle': '集中',
    'timerTab': 'タイマー',
    'todoTab': 'タスク',
    'timerIdle': '準備完了',
    'focusPhase': '集中中',
    'breakPhase': '休憩中',
    'breakReady': '休憩を開始',
    'focusReady': '次のラウンドを開始',
    'focusPhaseComplete': '集中時間終了！',
    'breakPhaseComplete': '休憩時間終了！',
    'roundProgress': '第{current}ラウンド、全{total}ラウンド',
    'startFocus': '集中開始',
    'startBreak': '休憩を開始',
    'startNextRound': '次のラウンドを開始',
    'timerConfig': 'タイマー設定',
    'focusMinutes': '集中時間',
    'breakMinutes': '休憩時間',
    'rounds': 'ラウンド数',
    'autoStartBreak': '集中終了後に休憩を自動開始',
    'autoStartNextRound': '休憩終了後に次のラウンドを自動開始',
    'timerWaitingAction': '次の段階を手動で開始してください',
    'stopTimer': 'タイマー停止',
    'stopTimerConfirm': 'タイマーを停止して進捗を保存しますか？',
    'todayStats': '今日の統計',
    'focusMinutesLabel': '集中分数',
    'sessionMinutesLabel': 'セッション時間',
    'roundsLabel': '完了ラウンド',
    'addTodo': 'タスクを追加',
    'addTodoHint': '新しいタスクを追加...',
    'clearCompleted': '完了をクリア',
    'quickNotes': 'クイックメモ',
    'addNote': 'メモ追加',
    'editNote': 'メモ編集',
    'deleteNote': 'メモ削除',
    'deleteNoteConfirm': 'このメモを削除しますか？',
    'noteTitle': 'タイトル',
    'noteContent': '内容',
  };

  static const Map<String, String> _focusDe = <String, String>{
    'focusTitle': 'Fokus',
    'timerTab': 'Timer',
    'todoTab': 'Aufgaben',
    'timerIdle': 'Bereit',
    'focusPhase': 'Fokus',
    'breakPhase': 'Pause',
    'breakReady': 'Pause starten',
    'focusReady': 'Nächste Runde starten',
    'focusPhaseComplete': 'Fokuszeit abgeschlossen!',
    'breakPhaseComplete': 'Pause beendet!',
    'roundProgress': 'Runde {current} von {total}',
    'startFocus': 'Fokus starten',
    'startBreak': 'Pause starten',
    'startNextRound': 'Nächste Runde starten',
    'timerConfig': 'Timer-Einstellungen',
    'focusMinutes': 'Fokus (min)',
    'breakMinutes': 'Pause (min)',
    'rounds': 'Runden',
    'autoStartBreak': 'Pause automatisch starten',
    'autoStartNextRound': 'Nächste Runde automatisch starten',
    'timerWaitingAction': 'Warte auf deine nächste Aktion',
    'stopTimer': 'Timer stoppen',
    'stopTimerConfirm': 'Timer stoppen und Fortschritt speichern?',
    'todayStats': 'Heutige Statistik',
    'focusMinutesLabel': 'Fokus-Minuten',
    'sessionMinutesLabel': 'Sitzungsminuten',
    'roundsLabel': 'Runden',
    'addTodo': 'Aufgabe hinzufügen',
    'addTodoHint': 'Neue Aufgabe hinzufügen...',
    'clearCompleted': 'Fertige löschen',
    'quickNotes': 'Schnellnotizen',
    'addNote': 'Notiz hinzufügen',
    'editNote': 'Notiz bearbeiten',
    'deleteNote': 'Notiz löschen',
    'deleteNoteConfirm': 'Diese Notiz löschen?',
    'noteTitle': 'Titel',
    'noteContent': 'Inhalt',
  };

  static const Map<String, String> _focusFr = <String, String>{
    'focusTitle': 'Concentration',
    'timerTab': 'Minuteur',
    'todoTab': 'Tâches',
    'timerIdle': 'Prêt',
    'focusPhase': 'Concentration',
    'breakPhase': 'Pause',
    'breakReady': 'Démarrer la pause',
    'focusReady': 'Démarrer le tour suivant',
    'focusPhaseComplete': 'Session de concentration terminée !',
    'breakPhaseComplete': 'Pause terminée !',
    'roundProgress': 'Tour {current} sur {total}',
    'startFocus': 'Démarrer',
    'startBreak': 'Démarrer la pause',
    'startNextRound': 'Démarrer le tour suivant',
    'timerConfig': 'Paramètres du minuteur',
    'focusMinutes': 'Concentration (min)',
    'breakMinutes': 'Pause (min)',
    'rounds': 'Tours',
    'autoStartBreak': 'Démarrer la pause automatiquement',
    'autoStartNextRound': 'Démarrer le tour suivant automatiquement',
    'timerWaitingAction': 'En attente de votre action',
    'stopTimer': 'Arrêter',
    'stopTimerConfirm': 'Arrêter le minuteur et sauvegarder ?',
    'todayStats': 'Statistiques du jour',
    'focusMinutesLabel': 'Minutes de concentration',
    'sessionMinutesLabel': 'Minutes de session',
    'roundsLabel': 'Tours',
    'addTodo': 'Ajouter une tâche',
    'addTodoHint': 'Ajouter une nouvelle tâche...',
    'clearCompleted': 'Effacer terminées',
    'quickNotes': 'Notes rapides',
    'addNote': 'Ajouter une note',
    'editNote': 'Modifier la note',
    'deleteNote': 'Supprimer la note',
    'deleteNoteConfirm': 'Supprimer cette note ?',
    'noteTitle': 'Titre',
    'noteContent': 'Contenu',
  };

  static const Map<String, String> _focusEs = <String, String>{
    'focusTitle': 'Enfoque',
    'timerTab': 'Temporizador',
    'todoTab': 'Tareas',
    'timerIdle': 'Listo',
    'focusPhase': 'Enfoque',
    'breakPhase': 'Descanso',
    'breakReady': 'Iniciar descanso',
    'focusReady': 'Iniciar la siguiente ronda',
    'focusPhaseComplete': '¡Sesión de enfoque completada!',
    'breakPhaseComplete': '¡Descanso terminado!',
    'roundProgress': 'Ronda {current} de {total}',
    'startFocus': 'Iniciar enfoque',
    'startBreak': 'Iniciar descanso',
    'startNextRound': 'Iniciar la siguiente ronda',
    'timerConfig': 'Configuración del temporizador',
    'focusMinutes': 'Enfoque (min)',
    'breakMinutes': 'Descanso (min)',
    'rounds': 'Rondas',
    'autoStartBreak': 'Iniciar el descanso automáticamente',
    'autoStartNextRound': 'Iniciar la siguiente ronda automáticamente',
    'timerWaitingAction': 'Esperando tu siguiente acción',
    'stopTimer': 'Detener temporizador',
    'stopTimerConfirm': '¿Detener el temporizador y guardar el progreso?',
    'todayStats': 'Estadísticas de hoy',
    'focusMinutesLabel': 'Minutos de enfoque',
    'sessionMinutesLabel': 'Minutos de sesión',
    'roundsLabel': 'Rondas',
    'addTodo': 'Agregar tarea',
    'addTodoHint': 'Agregar nueva tarea...',
    'clearCompleted': 'Limpiar completadas',
    'quickNotes': 'Notas rápidas',
    'addNote': 'Agregar nota',
    'editNote': 'Editar nota',
    'deleteNote': 'Eliminar nota',
    'deleteNoteConfirm': '¿Eliminar esta nota?',
    'noteTitle': 'Título',
    'noteContent': 'Contenido',
  };

  static const Map<String, String> _ru = <String, String>{
    'settings': 'Настройки',
    'ambientAudio': 'Фоновый звук',
    'play': 'Воспроизвести',
    'pause': 'Пауза',
    'resume': 'Продолжить',
    'skip': 'Пропустить',
    'stop': 'Остановить',
    'ttsProvider': 'Провайдер TTS',
    'local': 'Локально',
    'siliconFlowApi': 'SiliconFlow API',
    'customApi': 'Пользовательский API',
    'voice': 'Голос',
    'defaultVoice': 'Голос по умолчанию',
    'ttsModel': 'Модель TTS',
    'ttsApiKey': 'Ключ API TTS',
    'ttsApiBaseUrl': 'Базовый URL TTS',
    'ttsModelIdHint': 'Введите ID модели',
    'localVoicesNotFound':
        'Локальные голоса не найдены. Будет использован системный голос.',
    'asrProvider': 'Провайдер ASR',
    'asrModel': 'Модель ASR',
    'asrApiKey': 'Ключ API ASR',
    'asrApiBaseUrl': 'Базовый URL ASR',
    'offlineWhisperBase': 'Оффлайн (Whisper Base)',
    'offlineWhisperSmall': 'Оффлайн (Whisper Small)',
    'asrLocalSimilarity': 'Локальное сходство (без ASR)',
    'asrMultiEngine': 'Несколько движков',
    'asrLocalSimilarityHint':
        'Использует текущий TTS для эталонного аудио и локально сравнивает произношение по акустическому сходству.',
    'asrMultiEngineHint':
        'Выберите один или несколько движков. Они будут запускаться по очереди, а результаты объединятся.',
    'asrScoringMethods': 'Методы оценки произношения',
    'asrScoringMethodsHint':
        'Выберите алгоритмы оценки, которые нужно включить.',
    'asrScoringPackManager': 'Пакеты оценки',
    'asrScoringPackInstallFirst':
        'Сначала загрузите пакет, чтобы включить этот метод.',
    'scorerSslEmbedding': 'SSL-сходство эмбеддингов (HuBERT/wav2vec2)',
    'scorerGop': 'Оценка GOP',
    'scorerForcedAlignmentPer': 'Выравнивание + PER',
    'scorerPpgPosterior': 'Оценка по PPG',
    'asrOfflineModelManager': 'Оффлайн-пакеты ASR',
    'asrModelInstalled': 'Установлено ({size})',
    'asrModelNotInstalled': 'Не установлено (размер: {size})',
    'language': 'Язык',
    'cancel': 'Отмена',
    'save': 'Сохранить',
    'close': 'Закрыть',
    'delete': 'Удалить',
    'download': 'Скачать',
    'processing': 'Обработка...',
    'fieldWord': 'Слово',
    'fieldMeaning': 'Значение',
    'fieldExamples': 'Примеры',
    'fieldEtymology': 'Этимология',
    'fieldRoots': 'Корни',
    'fieldAffixes': 'Аффиксы',
    'fieldVariations': 'Варианты',
    'fieldMemory': 'Память',
    'fieldStory': 'История',
    'showText': 'Показывать текст',
    'masterVolume': 'Общая громкость',
    'noAudioSources': 'Нет источников звука',
    'importAudio': 'Импорт аудио',
    'importedAudio': 'Импортированное аудио',
    'ambientCategoryNoise': 'Шум',
    'ambientCategoryNature': 'Природа',
    'ambientCategoryRain': 'Дождь',
    'ambientCategoryFocus': 'Фокус',
    'ambientNameNoiseWhite': 'Белый шум',
    'ambientNameNoisePink': 'Розовый шум',
    'ambientNameNoiseBrown': 'Коричневый шум',
    'ambientNameNatureWind': 'Ветер',
    'ambientNameNatureForest': 'Лес',
    'ambientNameNatureFire': 'Костёр',
    'ambientNameNatureOcean': 'Волны',
    'ambientNameRainLight': 'Лёгкий дождь',
    'ambientNameRainHeavy': 'Сильный дождь',
    'ambientNameFocusLibrary': 'Библиотека',
    'ambientNameFocusCafe': 'Кафе',
    'ambientNameFocusNightVillage': 'Ночная деревня',
    'appearanceThemeTitle': 'Тема',
    'appearanceReset': 'Сбросить',
    'appearanceTypographyTitle': 'Типографика',
    'appearanceFontFamily': 'Шрифт',
    'appearanceFontFamilySystem': 'Системный',
    'appearanceFontFamilySerif': 'С засечками',
    'appearanceFontFamilyMono': 'Моноширинный',
    'appearanceFontFamilyRounded': 'Скруглённый',
    'appearanceFontScale': 'Масштаб шрифта',
    'appearanceFontScaleHint':
        'Глобально увеличивает или уменьшает размер текста.',
    'appearanceTitleWeight': 'Насыщенность заголовков',
    'appearanceBodyWeight': 'Насыщенность основного текста',
    'appearanceWeightRegular': 'Обычный',
    'appearanceWeightMedium': 'Средний',
    'appearanceWeightSemibold': 'Полужирный',
    'appearanceWeightBold': 'Жирный',
    'appearanceColorsTitle': 'Цвета',
    'appearanceCompactLayout': 'Компактный макет',
    'appearanceCompactLayoutHint':
        'Уменьшает отступы и высоту элементов для более плотного интерфейса.',
    'appearanceHighContrastText': 'Высокий контраст текста',
    'appearanceHighContrastTextHint':
        'Усиливает контраст текста для лучшей читаемости.',
    'appearanceGradientIntensity': 'Интенсивность градиента',
    'appearanceGradientIntensityHint':
        'Определяет насыщенность градиентов и цветовых переходов.',
    'appearanceSidebarOpacity': 'Прозрачность боковой панели',
    'appearanceSidebarOpacityHint':
        'Настройка прозрачности левого модуля навигации.',
    'appearanceDetailOpacity': 'Прозрачность панели деталей',
    'appearanceDetailOpacityHint':
        'Настройка прозрачности основной панели слова.',
    'appearancePlaybackOpacity': 'Прозрачность панели воспроизведения',
    'appearancePlaybackOpacityHint':
        'Настройка прозрачности нижней панели управления воспроизведением.',
    'appearanceFieldOpacity': 'Прозрачность карточек полей',
    'appearanceFieldOpacityHint':
        'Настройка прозрачности карточек значения, примеров и других полей.',
    'appearanceColorAccent': 'Акцентный цвет',
    'appearanceColorBorder': 'Цвет границы',
    'appearanceColorBackground': 'Фоновый цвет страницы',
    'appearanceEffectsTitle': 'Визуальные эффекты',
    'appearanceRandomEntryColors': 'Случайные цвета карточек',
    'appearanceRandomEntryColorsHint':
        'Меняет акцентные цвета карточек при просмотре слов.',
    'appearanceRainbowText': 'Радужный текст',
    'appearanceRainbowTextHint':
        'Показывает текущее слово с многоцветным градиентом.',
    'appearanceMarqueeText': 'Бегущая строка',
    'appearanceMarqueeTextHint':
        'Прокручивает длинные заголовки слов по горизонтали.',
    'appearanceBreathingEffect': 'Эффект дыхания',
    'appearanceBreathingEffectHint':
        'Добавляет мягкую ритмичную анимацию масштаба.',
    'appearanceFlowingEffect': 'Текущий градиент',
    'appearanceFlowingEffectHint':
        'Анимирует направление градиента фона и текста.',
    'appearanceFieldGradientAccent': 'Градиентный акцент полей',
    'appearanceFieldGradientAccentHint':
        'Добавляет мягкий акцентный градиент в карточки полей.',
    'appearanceFieldGlow': 'Свечение полей',
    'appearanceFieldGlowHint':
        'Добавляет лёгкое свечение вокруг карточек контента.',
    'appearancePlaybackGlow': 'Свечение панели воспроизведения',
    'appearancePlaybackGlowHint':
        'Подсвечивает активную панель воспроизведения.',
    'appearanceEffectIntensity': 'Интенсивность эффектов',
    'appearanceEffectIntensityHint':
        'Управляет силой теней, свечения и глубины интерфейса.',
    'appearanceBackgroundTitle': 'Фон',
    'appearanceBackgroundHint':
        'Настройка фоновых изображений и их прозрачности.',
    'appearanceBackgroundImagePick': 'Выбрать изображение',
    'appearanceBackgroundImageClear': 'Очистить изображение',
    'appearanceBackgroundImageMode': 'Режим изображения',
    'appearanceBackgroundImageOpacity': 'Прозрачность изображения',
    'appearanceBackgroundImageOpacityHint':
        'Управляет прозрачностью фонового изображения.',
    'appearanceBgModeCover': 'Заполнить',
    'appearanceBgModeContain': 'Вписать',
    'appearanceBgModeStretch': 'Растянуть',
    'appearanceBgModeTop': 'По верхнему краю',
    'appearanceBgModeTile': 'Плитка',
    'appearancePreviewTitle': 'Предпросмотр',
    'themeFlat': 'Плоский синий',
    'themeTech': 'Техно-синий',
    'themeDark': 'Тёмный',
    'themeFantasy': 'Фэнтези',
    'themeNature': 'Природа',
    'themeSunset': 'Закат',
    'themeOcean': 'Океан',
    'themeMono': 'Моно',
  };

  static const Map<String, String> _extraEn = <String, String>{
    'appearanceTimerStyle': 'Timer style',
    'appearanceTimerStyleHint':
        'Choose how the focus timer looks on the focus page.',
    'appearanceWordTransitionStyle': 'Word switch effect',
    'appearanceWordTransitionStyleHint':
        'Choose how the current word changes when you switch left or right.',
    'timerStyleHourglass': 'Hourglass',
    'timerStyleCountdown': 'Countdown',
    'wordTransitionStyleNone': 'None',
    'wordTransitionStyleSmooth': 'Smooth slide',
    'wordTransitionStyleFade': 'Fade',
    'wordTransitionStylePageFlip': 'Page flip',
    // B3: sound piano
    'toolbox.sound.piano.changeKeyLayout': 'Change key layout',
    'toolbox.sound.piano.pianoSettings': 'Piano settings',
    'toolbox.sound.piano.layout': 'Layout',
    'toolbox.sound.piano.range': 'Range',
    'toolbox.sound.piano.scale': 'Scale',
    'toolbox.sound.piano.harmony': 'Harmony',
    'toolbox.sound.piano.style': 'Style',
    'toolbox.sound.piano.keyLayoutLabel': 'Key layout',
    'toolbox.sound.piano.presetPack': 'Preset pack',
    'toolbox.sound.piano.keyboardStyle': 'Keyboard style',
    'toolbox.sound.piano.touchAndSpace': 'Touch and space',
    'toolbox.sound.piano.phoneTuning': 'Phone tuning',
    'toolbox.sound.piano.compactKeyboardMode': 'Compact keyboard mode',
    'toolbox.sound.piano.scaleAndHarmony': 'Scale and harmony',
    'toolbox.sound.piano.rangeWindow': 'Range window',
    'toolbox.sound.piano.keyboardSettings': 'Keyboard settings',
    'toolbox.sound.piano.settings': 'Settings',
    'toolbox.sound.piano.window': 'Window',
    'toolbox.sound.piano.mode': 'Mode',
    'toolbox.sound.piano.single': 'Single',
    'toolbox.sound.piano.keys': 'Keys',
    'toolbox.sound.piano.totalRange': 'Total range',
    'toolbox.sound.piano.preset': 'Preset',
    'toolbox.sound.piano.verticalKeyboard': 'Vertical keyboard',
    'toolbox.sound.piano.windowList': 'Window list',
    'toolbox.sound.piano.full': 'Full',
    'toolbox.sound.piano.fullScreen': 'Full screen',
    'toolbox.sound.piano.dual': 'Dual',
    'toolbox.sound.piano.dualKeyboard': 'Dual keyboard',
    'toolbox.sound.piano.high': 'High',
    'toolbox.sound.piano.low': 'Low',
    'toolbox.sound.piano.duetMode': 'Duet mode',
    'toolbox.sound.piano.majorChord': 'Major',
    'toolbox.sound.piano.minorChord': 'Minor',
    'toolbox.sound.piano.sus2': 'Sus2',
    'toolbox.sound.piano.maj7': 'Maj7',
    'toolbox.sound.piano.m7': 'm7',
    'toolbox.sound.piano.add9': 'Add9',
    'toolbox.sound.piano.singleNote': 'Single note',
    'toolbox.sound.piano.previousWindow': 'Previous window',
    'toolbox.sound.piano.currentWindow': 'Current window',
    'toolbox.sound.piano.nextWindow': 'Next window',
    'toolbox.sound.piano.quickJump': 'Quick jump',
    'toolbox.sound.piano.chooseWindow': 'Choose window',
    'toolbox.sound.piano.toggleWindowList': 'Toggle window list layout',
    'toolbox.sound.piano.preparingVoices': 'Preparing note voices',
    'toolbox.sound.piano.windowReady': 'Window ready',
    'toolbox.sound.piano.moreActions': 'More actions',
    'toolbox.sound.piano.disableCompact': 'Disable compact keys',
    'toolbox.sound.piano.enableCompact': 'Enable compact keys',
    'toolbox.sound.piano.aggressiveOneHand':
        'Aggressive one-hand mode (320-390dp)',
    'toolbox.sound.piano.dualMode': 'Dual keyboard mode',
    'toolbox.sound.piano.gestureSwitching': 'Gesture window switching',
    'toolbox.sound.piano.compactKeyboardModeDesc':
        'Shrink key height and show more octaves to reduce frequent range switching.',
    'toolbox.sound.piano.aggressiveOneHandDesc':
        'On narrow phones, enlarge black-key hit zones, reduce control density, and prefer a single keyboard.',
    'toolbox.sound.piano.sensitivityTip':
        'Lower values are more sensitive, higher values are steadier. Fine-tune on a real device.',
    'toolbox.sound.piano.dualModeDesc':
        'Show two adjacent ranges and play on both keyboards with two fingers.',
    'toolbox.sound.piano.gestureSwitchingDesc':
        'Swipe up or down with two fingers to switch ranges quickly. Disable if conflict occurs.',
    'toolbox.sound.piano.duetModeDesc':
        'In dual mode, two people can play on high and low keyboards simultaneously.',
    'toolbox.sound.piano.verticalKeyboardPhoneDesc':
        'Phone layout prioritizes one-hand taps and glissando before exposing the dual keyboard.',
    'toolbox.sound.piano.verticalKeyboardDesc':
        'The keyboard now expands down the phone height instead of being crushed horizontally.',
    'toolbox.sound.piano.glissTip':
        'Gliss with one finger; shift range with two.',
    'toolbox.sound.piano.glissTipWide':
        'Gliss with one finger; use two fingers to shift range.',
    'toolbox.sound.piano.glissandoGuide':
        'Single-finger glissando is supported, while two-finger vertical drags jump registers and horizontal drags switch windows.',
    'toolbox.sound.piano.glissandoGuideCompact':
        'Use one finger for glissando, two fingers to change range, and tap once to switch high or low rows in phone dual mode.',
    'toolbox.sound.piano.switchKeyboard': 'Switch to {side} ({label})',
    'toolbox.sound.piano.studioUpright': 'Studio upright',
    'toolbox.sound.piano.brightStage': 'Bright stage',
    'toolbox.sound.piano.feltRoom': 'Felt room',
    'toolbox.sound.piano.concertHall': 'Concert hall',
    'toolbox.sound.piano.studioUprightDesc':
        'Dryer wood resonance and cleaner attacks, closer to a real upright piano.',
    'toolbox.sound.piano.brightStageDesc':
        'Sharper hammer edge for lead lines and brighter attacks.',
    'toolbox.sound.piano.feltRoomDesc':
        'Softer felt body for intimate and quiet playing.',
    'toolbox.sound.piano.concertHallDesc':
        'Balanced sustain and room feel for all-purpose playing.',
    'toolbox.sound.piano.minor': 'Minor',
    'toolbox.sound.piano.dorian': 'Dorian',
    'toolbox.sound.piano.lydian': 'Lydian',
    'toolbox.sound.piano.harmonicMinor': 'Harmonic minor',
    'toolbox.sound.piano.pentatonic': 'Pentatonic',
    'toolbox.sound.piano.chromatic': 'Chromatic',
    'toolbox.sound.piano.major': 'Major',
    'toolbox.sound.piano.classicBW': 'Classic black & white',
    'toolbox.sound.piano.midnight': 'Midnight',
    'toolbox.sound.piano.mist': 'Mist',
    'toolbox.sound.piano.ivory': 'Ivory',
    'toolbox.sound.piano.keyCount': '{count} keys',
    'toolbox.sound.piano.keyLayoutRange': '{count} keys {range}',
    'toolbox.sound.piano.keyHeight': 'Key height {percent}%',
    'toolbox.sound.piano.blackKeyWidth': 'Black key width {percent}%',
    'toolbox.sound.piano.blackKeyHeight': 'Black key height {percent}%',
    'toolbox.sound.piano.chordDelay': 'Chord delay {percent}%',
    'toolbox.sound.piano.chordFalloff': 'Chord falloff {percent}%',
    'toolbox.sound.piano.octaveSpanDesc':
        'The vertical stage currently shows {octaveSpan} octaves and supports quick range switching and wrapped rows.',
    'toolbox.sound.piano.touch': 'Touch {percent}%',
    'toolbox.sound.piano.space': 'Space {percent}%',
    'toolbox.sound.piano.decay': 'Decay {value}x',
    'toolbox.sound.piano.gestureSensitivity':
        'Two-finger range sensitivity {percent}%',
  };

  static const Map<String, String> _extraZh = <String, String>{
    'appearanceTimerStyle': '计时样式',
    'appearanceTimerStyleHint': '选择专注页中计时器的显示样式。',
    'timerStyleHourglass': '沙漏',
    'timerStyleCountdown': '倒计时',
    // B3: sound piano
    'toolbox.sound.piano.changeKeyLayout': '切换键盘键数',
    'toolbox.sound.piano.pianoSettings': '钢琴设置',
    'toolbox.sound.piano.layout': '键盘规格',
    'toolbox.sound.piano.range': '音域',
    'toolbox.sound.piano.scale': '调式',
    'toolbox.sound.piano.harmony': '和声',
    'toolbox.sound.piano.style': '风格',
    'toolbox.sound.piano.keyLayoutLabel': '键盘键数',
    'toolbox.sound.piano.presetPack': '预设音色包',
    'toolbox.sound.piano.keyboardStyle': '键盘风格',
    'toolbox.sound.piano.touchAndSpace': '触键与空间',
    'toolbox.sound.piano.phoneTuning': '手机适配',
    'toolbox.sound.piano.compactKeyboardMode': '紧凑键盘模式',
    'toolbox.sound.piano.scaleAndHarmony': '调式与和声',
    'toolbox.sound.piano.rangeWindow': '音域窗口',
    'toolbox.sound.piano.keyboardSettings': '键盘设置',
    'toolbox.sound.piano.settings': '设置',
    'toolbox.sound.piano.window': '窗口',
    'toolbox.sound.piano.mode': '模式',
    'toolbox.sound.piano.single': '单键盘',
    'toolbox.sound.piano.keys': '键数',
    'toolbox.sound.piano.totalRange': '总音域',
    'toolbox.sound.piano.preset': '预设',
    'toolbox.sound.piano.verticalKeyboard': '纵向键盘',
    'toolbox.sound.piano.windowList': '窗口列表',
    'toolbox.sound.piano.full': '全屏',
    'toolbox.sound.piano.fullScreen': '全屏',
    'toolbox.sound.piano.dual': '双键盘',
    'toolbox.sound.piano.dualKeyboard': '双键盘',
    'toolbox.sound.piano.high': '高音',
    'toolbox.sound.piano.low': '低音',
    'toolbox.sound.piano.duetMode': '双人合奏',
    'toolbox.sound.piano.majorChord': '大三和弦',
    'toolbox.sound.piano.minorChord': '小三和弦',
    'toolbox.sound.piano.sus2': '挂二',
    'toolbox.sound.piano.maj7': '大七',
    'toolbox.sound.piano.m7': '小七',
    'toolbox.sound.piano.add9': '加九',
    'toolbox.sound.piano.singleNote': '单音',
    'toolbox.sound.piano.previousWindow': '上一窗口',
    'toolbox.sound.piano.currentWindow': '当前窗口',
    'toolbox.sound.piano.nextWindow': '下一窗口',
    'toolbox.sound.piano.quickJump': '快速跳转',
    'toolbox.sound.piano.chooseWindow': '选择窗口',
    'toolbox.sound.piano.toggleWindowList': '切换窗口列表布局',
    'toolbox.sound.piano.preparingVoices': '音域音色准备中',
    'toolbox.sound.piano.windowReady': '音域就绪',
    'toolbox.sound.piano.moreActions': '更多操作',
    'toolbox.sound.piano.disableCompact': '关闭紧凑键盘',
    'toolbox.sound.piano.enableCompact': '开启紧凑键盘',
    'toolbox.sound.piano.aggressiveOneHand': '激进单手模式（320-390dp）',
    'toolbox.sound.piano.dualMode': '双键盘模式',
    'toolbox.sound.piano.gestureSwitching': '手势滑动切窗',
    'toolbox.sound.piano.compactKeyboardModeDesc': '缩小键位并尽量显示更多八度，减少频繁切换音域。',
    'toolbox.sound.piano.aggressiveOneHandDesc': '窄屏自动放大黑键触控区、减少控件干扰，并优先单键盘演奏。',
    'toolbox.sound.piano.sensitivityTip': '值越小越灵敏，越大越稳。建议真机按手势习惯微调。',
    'toolbox.sound.piano.dualModeDesc': '同时显示两个相邻音域，用两根手指在其中一个键盘上演奏。',
    'toolbox.sound.piano.gestureSwitchingDesc': '双指在键盘上下滑动可快速切换音域。',
    'toolbox.sound.piano.duetModeDesc': '双键盘模式下，两人可在高低键盘上同时演奏。',
    'toolbox.sound.piano.verticalKeyboardPhoneDesc':
        '手机布局优先保证单手点击和滑奏，再按需切换双键盘。',
    'toolbox.sound.piano.verticalKeyboardDesc': '键盘沿屏幕高度展开，避免横向压缩。',
    'toolbox.sound.piano.glissTip': '单指滑奏，双指切换音域。',
    'toolbox.sound.piano.glissTipWide': '单指滑奏，双指上下或左右切换音域。',
    'toolbox.sound.piano.glissandoGuide': '单指可连续滑奏；双指上下滑动可跳转音域，双指左右滑动可快速切窗。',
    'toolbox.sound.piano.glissandoGuideCompact':
        '单指可连续滑奏；双指上下或左右滑动可切换音域窗口；窄屏优先单键盘。',
    'toolbox.sound.piano.switchKeyboard': '切换到另一组键盘',
    'toolbox.sound.piano.studioUpright': '录音室立式',
    'toolbox.sound.piano.brightStage': '明亮舞台',
    'toolbox.sound.piano.feltRoom': '毛毡房间',
    'toolbox.sound.piano.concertHall': '音乐厅',
    'toolbox.sound.piano.studioUprightDesc': '更接近真实立式钢琴的木质共鸣与干净起音，适合日常练习。',
    'toolbox.sound.piano.brightStageDesc': '更锋利的击弦边缘，适合突出旋律和明亮起音。',
    'toolbox.sound.piano.feltRoomDesc': '毛毡包裹感更强，适合安静和亲密的演奏氛围。',
    'toolbox.sound.piano.concertHallDesc': '延音与空间感更均衡，适合通用演奏和编配。',
    'toolbox.sound.piano.minor': '小调',
    'toolbox.sound.piano.dorian': '多利亚',
    'toolbox.sound.piano.lydian': '利底亚',
    'toolbox.sound.piano.harmonicMinor': '和声小调',
    'toolbox.sound.piano.pentatonic': '五声音阶',
    'toolbox.sound.piano.chromatic': '半音阶',
    'toolbox.sound.piano.major': '大调',
    'toolbox.sound.piano.classicBW': '经典黑白',
    'toolbox.sound.piano.midnight': '午夜',
    'toolbox.sound.piano.mist': '薄雾',
    'toolbox.sound.piano.ivory': '象牙',
    'toolbox.sound.piano.keyCount': '{count}键',
    'toolbox.sound.piano.keyLayoutRange': '{count}键 {range}',
    'toolbox.sound.piano.keyHeight': '白键高度 {percent}%',
    'toolbox.sound.piano.blackKeyWidth': '黑键宽度 {percent}%',
    'toolbox.sound.piano.blackKeyHeight': '黑键高度 {percent}%',
    'toolbox.sound.piano.chordDelay': '和弦延迟 {percent}%',
    'toolbox.sound.piano.chordFalloff': '和弦衰减 {percent}%',
    'toolbox.sound.piano.octaveSpanDesc':
        '当前纵向舞台一次显示 {octaveSpan} 个八度，支持快速切换音域与分行展示窗口。',
    'toolbox.sound.piano.touch': '触键 {percent}%',
    'toolbox.sound.piano.space': '空间 {percent}%',
    'toolbox.sound.piano.decay': '延音 {value}x',
    'toolbox.sound.piano.gestureSensitivity': '双指切窗灵敏度 {percent}%',
  };

  static const Map<String, String> _extraJa = <String, String>{
    'appearanceTimerStyle': 'タイマースタイル',
    'appearanceTimerStyleHint': '集中ページでのタイマー表示スタイルを選びます。',
    'timerStyleHourglass': '砂時計',
    'timerStyleCountdown': 'カウントダウン',
  };

  static const Map<String, String> _extraDe = <String, String>{
    'appearanceTimerStyle': 'Timerstil',
    'appearanceTimerStyleHint':
        'Wählen Sie aus, wie der Timer auf der Fokus-Seite aussieht.',
    'timerStyleHourglass': 'Sanduhr',
    'timerStyleCountdown': 'Countdown',
  };

  static const Map<String, String> _extraFr = <String, String>{
    'appearanceTimerStyle': 'Style du minuteur',
    'appearanceTimerStyleHint':
        'Choisissez l’apparence du minuteur sur la page de concentration.',
    'timerStyleHourglass': 'Sablier',
    'timerStyleCountdown': 'Compte à rebours',
  };

  static const Map<String, String> _extraEs = <String, String>{
    'appearanceTimerStyle': 'Estilo del temporizador',
    'appearanceTimerStyleHint':
        'Elige cómo se ve el temporizador en la página de enfoque.',
    'timerStyleHourglass': 'Reloj de arena',
    'timerStyleCountdown': 'Cuenta regresiva',
  };

  static const Map<String, String> _extraRu = <String, String>{
    'appearanceTimerStyle': 'Стиль таймера',
    'appearanceTimerStyleHint':
        'Выберите внешний вид таймера на странице фокуса.',
    'timerStyleHourglass': 'Песочные часы',
    'timerStyleCountdown': 'Обратный отсчёт',
  };

  static const Map<String, String> _focusEnhancedEn = <String, String>{
    'focusTitle': 'Focus / Relax',
    'timerTab': 'Timer',
    'todoTab': 'Tasks & Notes',
    'timerIdle': 'Ready',
    'focusPhase': 'Focus',
    'breakPhase': 'Relax',
    'breakReady': 'Relax ready',
    'focusReady': 'Next round ready',
    'focusPhaseComplete': 'Focus complete!',
    'breakPhaseComplete': 'Relax time over!',
    'roundProgress': 'Round {current} of {total}',
    'startFocus': 'Start Focus',
    'startBreak': 'Start Relax',
    'startNextRound': 'Start Next Round',
    'timerConfig': 'Timer Settings',
    'focusMinutes': 'Focus duration',
    'breakMinutes': 'Relax duration',
    'rounds': 'Rounds',
    'autoStartBreak': 'Auto-start relax',
    'autoStartNextRound': 'Auto-start next round',
    'timerWaitingAction': 'Waiting for your action',
    'stopTimer': 'Stop Timer',
    'stopTimerConfirm': 'Stop the timer and save progress?',
    'todayStats': 'Today\'s Stats',
    'focusMinutesLabel': 'Focus Minutes',
    'sessionMinutesLabel': 'Session Minutes',
    'roundsLabel': 'Rounds',
    'addTodo': 'Add task',
    'addTodoHint': 'Add a new task...',
    'clearCompleted': 'Clear Completed',
    'quickNotes': 'Quick Notes',
    'addNote': 'Add Note',
    'editNote': 'Edit Note',
    'deleteNote': 'Delete Note',
    'deleteNoteConfirm': 'Delete this note?',
    'noteTitle': 'Title',
    'noteContent': 'Content',
    'hoursLabel': 'Hours',
    'minutesLabel': 'Minutes',
    'secondsLabel': 'Seconds',
    'hoursUnit': 'hr',
    'minutesUnit': 'min',
    'secondsUnit': 'sec',
    'reminderSettings': 'Completion reminders',
    'reminderHaptic': 'Vibration / haptics',
    'reminderSound': 'System chime',
    'reminderVoice': 'Voice prompt',
    'reminderPauseAmbient': 'Pause ambient audio',
    'reminderVisual': 'Visual highlight',
    'resizeSplitHint': 'Drag the divider to resize tasks and notes',
    'selectNotes': 'Select notes',
    'deleteSelectedNotes': 'Delete selected',
    'selectedNotesCount': '{count} selected',
    'notesEmpty': 'No notes yet',
    'todosEmpty': 'No tasks yet',
    'dragToReorder': 'Drag to reorder',
    'todoInputTapHint': 'Tap to open the detailed task editor',
    'addTodoDetails': 'Add task details',
    'editTodoDetails': 'Edit task details',
    'todoTitle': 'Task title',
    'todoTitleHint': 'What do you want to get done?',
    'todoTitleRequired': 'Please enter a task title',
    'todoCategory': 'Category',
    'todoCategoryHint': 'For example: review / listening / reading',
    'todoPriority': 'Priority',
    'todoPriorityLow': 'Low',
    'todoPriorityMedium': 'Medium',
    'todoPriorityHigh': 'High',
    'todoColor': 'Color',
    'todoNoColor': 'Default',
    'todoColorOption': 'Color',
    'todoNotes': 'Notes',
    'todoNotesHint': 'Add notes, context, or acceptance criteria',
    'todoReminder': 'Reminder time',
    'todoReminderHint':
        'Save a reminder time and sync it to the system calendar when supported.',
    'todoPickReminder': 'Pick date and time',
    'todoReminderStorageHint':
        'Supported devices can sync this reminder into the system calendar and keep it updated.',
    'clearValue': 'Clear',
  };

  static const Map<String, String> _focusEnhancedZh = <String, String>{
    'appearanceWordTransitionStyle': '单词切换特效',
    'appearanceWordTransitionStyleHint': '选择左右切换单词时的显示效果。',
    'wordTransitionStyleNone': '无特效',
    'wordTransitionStyleSmooth': '平滑切换',
    'wordTransitionStyleFade': '淡入淡出',
    'wordTransitionStylePageFlip': '仿真翻页',
    'focusTitle': '专注/放松',
    'timerTab': '计时',
    'todoTab': '待办/笔记',
    'timerIdle': '准备就绪',
    'focusPhase': '专注中',
    'breakPhase': '放松中',
    'breakReady': '开始放松',
    'focusReady': '开始下一轮',
    'focusPhaseComplete': '专注时间结束！',
    'breakPhaseComplete': '放松时间结束！',
    'roundProgress': '第 {current} 轮，共 {total} 轮',
    'startFocus': '开始专注',
    'startBreak': '开始放松',
    'startNextRound': '开始下一轮',
    'timerConfig': '计时设置',
    'focusMinutes': '专注时长',
    'breakMinutes': '放松时长',
    'rounds': '循环轮数',
    'autoStartBreak': '专注结束后自动开始放松',
    'autoStartNextRound': '放松结束后自动开始下一轮',
    'timerWaitingAction': '等待你手动进入下一阶段',
    'stopTimer': '停止计时',
    'stopTimerConfirm': '停止计时并保存进度？',
    'todayStats': '今日统计',
    'focusMinutesLabel': '专注分钟',
    'sessionMinutesLabel': '总会话分钟',
    'roundsLabel': '完成轮数',
    'addTodo': '添加待办',
    'addTodoHint': '添加新的待办...',
    'clearCompleted': '清除已完成',
    'quickNotes': '快速笔记',
    'addNote': '添加笔记',
    'editNote': '编辑笔记',
    'deleteNote': '删除笔记',
    'deleteNoteConfirm': '删除这条笔记？',
    'noteTitle': '标题',
    'noteContent': '内容',
    'hoursLabel': '小时',
    'minutesLabel': '分钟',
    'secondsLabel': '秒',
    'hoursUnit': '时',
    'minutesUnit': '分',
    'secondsUnit': '秒',
    'reminderSettings': '结束提醒',
    'reminderHaptic': '震动/触感',
    'reminderSound': '系统铃声',
    'reminderVoice': '语音播报',
    'reminderPauseAmbient': '暂停背景音',
    'reminderVisual': '视觉高亮',
    'resizeSplitHint': '拖动分隔条可调整待办和笔记的高度占比',
    'selectNotes': '选择笔记',
    'deleteSelectedNotes': '删除所选',
    'selectedNotesCount': '已选 {count} 条',
    'notesEmpty': '还没有笔记',
    'todosEmpty': '还没有待办',
    'dragToReorder': '拖动排序',
    'todoInputTapHint': '点击打开待办详情编辑器',
    'addTodoDetails': '添加待办详情',
    'editTodoDetails': '编辑待办详情',
    'todoTitle': '待办标题',
    'todoTitleHint': '这次要完成什么？',
    'todoTitleRequired': '请输入待办标题',
    'todoCategory': '类别',
    'todoCategoryHint': '例如：复习 / 听力 / 阅读',
    'todoPriority': '优先级',
    'todoPriorityLow': '低',
    'todoPriorityMedium': '中',
    'todoPriorityHigh': '高',
    'todoColor': '颜色',
    'todoNoColor': '默认',
    'todoColorOption': '颜色',
    'todoNotes': '备注',
    'todoNotesHint': '补充说明、上下文或完成标准',
    'todoReminder': '提醒时间',
    'todoReminderHint': '保存提醒时间，并在支持时同步到系统日历',
    'todoPickReminder': '选择日期和时间',
    'todoReminderStorageHint': '在支持的设备上，这个提醒会自动同步到系统日历并随编辑更新。',
    'clearValue': '清除',
  };

  static const Map<String, String> _focusEnhancedJa = <String, String>{
    'focusTitle': '集中 / リラックス',
    'timerTab': 'タイマー',
    'todoTab': 'タスクとメモ',
    'timerIdle': '準備完了',
    'focusPhase': '集中',
    'breakPhase': 'リラックス',
    'breakReady': 'リラックス開始',
    'focusReady': '次のラウンドを開始',
    'focusPhaseComplete': '集中時間が終了しました！',
    'breakPhaseComplete': 'リラックス時間が終了しました！',
    'roundProgress': '{total} 回中 {current} 回目',
    'startFocus': '集中開始',
    'startBreak': 'リラックス開始',
    'startNextRound': '次のラウンドを開始',
    'timerConfig': 'タイマー設定',
    'focusMinutes': '集中時間',
    'breakMinutes': 'リラックス時間',
    'rounds': 'ラウンド数',
    'autoStartBreak': '集中後に自動でリラックス開始',
    'autoStartNextRound': 'リラックス後に自動で次のラウンド開始',
    'timerWaitingAction': '次の操作を待っています',
    'stopTimer': 'タイマー停止',
    'stopTimerConfirm': 'タイマーを停止して進捗を保存しますか？',
    'todayStats': '今日の統計',
    'focusMinutesLabel': '集中時間',
    'sessionMinutesLabel': 'セッション時間',
    'roundsLabel': '完了ラウンド',
    'addTodo': 'タスク追加',
    'addTodoHint': '新しいタスクを追加...',
    'clearCompleted': '完了を削除',
    'quickNotes': 'クイックメモ',
    'addNote': 'メモ追加',
    'editNote': 'メモ編集',
    'deleteNote': 'メモ削除',
    'deleteNoteConfirm': 'このメモを削除しますか？',
    'noteTitle': 'タイトル',
    'noteContent': '内容',
    'hoursLabel': '時間',
    'minutesLabel': '分',
    'secondsLabel': '秒',
    'hoursUnit': '時間',
    'minutesUnit': '分',
    'secondsUnit': '秒',
    'reminderSettings': '終了リマインダー',
    'reminderHaptic': '振動 / 触覚',
    'reminderSound': 'システム音',
    'reminderVoice': '音声案内',
    'reminderPauseAmbient': '環境音を一時停止',
    'reminderVisual': '視覚ハイライト',
    'resizeSplitHint': '仕切りをドラッグしてタスクとメモの高さを調整',
    'selectNotes': 'メモを選択',
    'deleteSelectedNotes': '選択を削除',
    'selectedNotesCount': '{count} 件を選択',
    'notesEmpty': 'メモはまだありません',
    'todosEmpty': 'タスクはまだありません',
    'dragToReorder': 'ドラッグして並べ替え',
    'todoInputTapHint': 'タップして詳細なタスク編集を開く',
    'addTodoDetails': 'タスク詳細を追加',
    'editTodoDetails': 'タスク詳細を編集',
    'todoTitle': 'タスク名',
    'todoTitleHint': '今回やりたいことは何ですか？',
    'todoTitleRequired': 'タスク名を入力してください',
    'todoCategory': 'カテゴリ',
    'todoCategoryHint': '例: 復習 / リスニング / 読書',
    'todoPriority': '優先度',
    'todoPriorityLow': '低',
    'todoPriorityMedium': '中',
    'todoPriorityHigh': '高',
    'todoColor': '色',
    'todoNoColor': '標準',
    'todoColorOption': '色',
    'todoNotes': 'メモ',
    'todoNotesHint': '補足説明や完了条件を記録',
    'todoReminder': 'リマインダー時刻',
    'todoReminderHint': '後で通知に使えるよう日時を保存します',
    'todoPickReminder': '日時を選択',
    'todoReminderStorageHint': 'この日時は保存され、今後リマインダー機能にそのまま使えます。',
    'clearValue': 'クリア',
  };

  static const Map<String, String> _focusEnhancedDe = <String, String>{
    'focusTitle': 'Fokus / Entspannen',
    'timerTab': 'Timer',
    'todoTab': 'Aufgaben & Notizen',
    'timerIdle': 'Bereit',
    'focusPhase': 'Fokus',
    'breakPhase': 'Entspannen',
    'breakReady': 'Entspannen bereit',
    'focusReady': 'Nächste Runde bereit',
    'focusPhaseComplete': 'Fokus beendet!',
    'breakPhaseComplete': 'Entspannungszeit vorbei!',
    'roundProgress': 'Runde {current} von {total}',
    'startFocus': 'Fokus starten',
    'startBreak': 'Entspannen starten',
    'startNextRound': 'Nächste Runde starten',
    'timerConfig': 'Timer-Einstellungen',
    'focusMinutes': 'Fokusdauer',
    'breakMinutes': 'Entspannungsdauer',
    'rounds': 'Runden',
    'autoStartBreak': 'Entspannung automatisch starten',
    'autoStartNextRound': 'Nächste Runde automatisch starten',
    'timerWaitingAction': 'Warte auf deine Aktion',
    'stopTimer': 'Timer stoppen',
    'stopTimerConfirm': 'Timer stoppen und Fortschritt speichern?',
    'todayStats': 'Heutige Statistik',
    'focusMinutesLabel': 'Fokus-Minuten',
    'sessionMinutesLabel': 'Sitzungsminuten',
    'roundsLabel': 'Runden',
    'addTodo': 'Aufgabe hinzufügen',
    'addTodoHint': 'Neue Aufgabe hinzufügen...',
    'clearCompleted': 'Erledigte löschen',
    'quickNotes': 'Schnellnotizen',
    'addNote': 'Notiz hinzufügen',
    'editNote': 'Notiz bearbeiten',
    'deleteNote': 'Notiz löschen',
    'deleteNoteConfirm': 'Diese Notiz löschen?',
    'noteTitle': 'Titel',
    'noteContent': 'Inhalt',
    'hoursLabel': 'Stunden',
    'minutesLabel': 'Minuten',
    'secondsLabel': 'Sekunden',
    'hoursUnit': 'Std',
    'minutesUnit': 'Min',
    'secondsUnit': 'Sek',
    'reminderSettings': 'Ende-Erinnerungen',
    'reminderHaptic': 'Vibration / Haptik',
    'reminderSound': 'Systemton',
    'reminderVoice': 'Sprachhinweis',
    'reminderPauseAmbient': 'Umgebungsgeräusche pausieren',
    'reminderVisual': 'Visuelle Hervorhebung',
    'resizeSplitHint': 'Trenner ziehen, um Aufgaben und Notizen anzupassen',
    'selectNotes': 'Notizen auswählen',
    'deleteSelectedNotes': 'Ausgewählte löschen',
    'selectedNotesCount': '{count} ausgewählt',
    'notesEmpty': 'Noch keine Notizen',
    'todosEmpty': 'Noch keine Aufgaben',
    'dragToReorder': 'Zum Umordnen ziehen',
    'todoInputTapHint': 'Tippen, um den detaillierten Aufgabeneditor zu öffnen',
    'addTodoDetails': 'Aufgabendetails hinzufügen',
    'editTodoDetails': 'Aufgabendetails bearbeiten',
    'todoTitle': 'Aufgabentitel',
    'todoTitleHint': 'Was möchtest du jetzt erledigen?',
    'todoTitleRequired': 'Bitte gib einen Aufgabentitel ein',
    'todoCategory': 'Kategorie',
    'todoCategoryHint': 'Zum Beispiel: Wiederholung / Hören / Lesen',
    'todoPriority': 'Priorität',
    'todoPriorityLow': 'Niedrig',
    'todoPriorityMedium': 'Mittel',
    'todoPriorityHigh': 'Hoch',
    'todoColor': 'Farbe',
    'todoNoColor': 'Standard',
    'todoColorOption': 'Farbe',
    'todoNotes': 'Notizen',
    'todoNotesHint': 'Kontext oder Erledigungskriterien hinzufügen',
    'todoReminder': 'Erinnerungszeit',
    'todoReminderHint': 'Speichert Datum und Uhrzeit für spätere Erinnerungen.',
    'todoPickReminder': 'Datum und Uhrzeit wählen',
    'todoReminderStorageHint':
        'Dieser Zeitpunkt wird bereits gespeichert und kann später direkt für Erinnerungen genutzt werden.',
    'clearValue': 'Leeren',
  };

  static const Map<String, String> _focusEnhancedFr = <String, String>{
    'focusTitle': 'Concentration / Détente',
    'timerTab': 'Minuteur',
    'todoTab': 'Tâches et notes',
    'timerIdle': 'Prêt',
    'focusPhase': 'Concentration',
    'breakPhase': 'Détente',
    'breakReady': 'Détente prête',
    'focusReady': 'Tour suivant prêt',
    'focusPhaseComplete': 'Concentration terminée !',
    'breakPhaseComplete': 'Temps de détente terminé !',
    'roundProgress': 'Tour {current} sur {total}',
    'startFocus': 'Démarrer la concentration',
    'startBreak': 'Démarrer la détente',
    'startNextRound': 'Démarrer le tour suivant',
    'timerConfig': 'Paramètres du minuteur',
    'focusMinutes': 'Durée de concentration',
    'breakMinutes': 'Durée de détente',
    'rounds': 'Tours',
    'autoStartBreak': 'Démarrer la détente automatiquement',
    'autoStartNextRound': 'Démarrer le tour suivant automatiquement',
    'timerWaitingAction': 'En attente de votre action',
    'stopTimer': 'Arrêter le minuteur',
    'stopTimerConfirm': 'Arrêter le minuteur et sauvegarder la progression ?',
    'todayStats': 'Statistiques du jour',
    'focusMinutesLabel': 'Minutes de concentration',
    'sessionMinutesLabel': 'Minutes de session',
    'roundsLabel': 'Tours',
    'addTodo': 'Ajouter une tâche',
    'addTodoHint': 'Ajouter une nouvelle tâche...',
    'clearCompleted': 'Effacer les terminées',
    'quickNotes': 'Notes rapides',
    'addNote': 'Ajouter une note',
    'editNote': 'Modifier la note',
    'deleteNote': 'Supprimer la note',
    'deleteNoteConfirm': 'Supprimer cette note ?',
    'noteTitle': 'Titre',
    'noteContent': 'Contenu',
    'hoursLabel': 'Heures',
    'minutesLabel': 'Minutes',
    'secondsLabel': 'Secondes',
    'hoursUnit': 'h',
    'minutesUnit': 'min',
    'secondsUnit': 's',
    'reminderSettings': 'Rappels de fin',
    'reminderHaptic': 'Vibration / retour haptique',
    'reminderSound': 'Son système',
    'reminderVoice': 'Annonce vocale',
    'reminderPauseAmbient': 'Mettre l’audio ambiant en pause',
    'reminderVisual': 'Mise en évidence visuelle',
    'resizeSplitHint':
        'Faites glisser le séparateur pour redimensionner tâches et notes',
    'selectNotes': 'Sélectionner les notes',
    'deleteSelectedNotes': 'Supprimer la sélection',
    'selectedNotesCount': '{count} sélectionnées',
    'notesEmpty': 'Aucune note pour le moment',
    'todosEmpty': 'Aucune tâche pour le moment',
    'dragToReorder': 'Glisser pour réorganiser',
    'todoInputTapHint': 'Touchez pour ouvrir l’éditeur détaillé de tâche',
    'addTodoDetails': 'Ajouter les détails de la tâche',
    'editTodoDetails': 'Modifier les détails de la tâche',
    'todoTitle': 'Titre de la tâche',
    'todoTitleHint': 'Que voulez-vous terminer maintenant ?',
    'todoTitleRequired': 'Veuillez saisir un titre de tâche',
    'todoCategory': 'Catégorie',
    'todoCategoryHint': 'Par exemple : révision / écoute / lecture',
    'todoPriority': 'Priorité',
    'todoPriorityLow': 'Basse',
    'todoPriorityMedium': 'Moyenne',
    'todoPriorityHigh': 'Haute',
    'todoColor': 'Couleur',
    'todoNoColor': 'Par défaut',
    'todoColorOption': 'Couleur',
    'todoNotes': 'Notes',
    'todoNotesHint': 'Ajoutez du contexte ou des critères de validation',
    'todoReminder': 'Heure de rappel',
    'todoReminderHint': 'Enregistre la date et l’heure pour de futurs rappels.',
    'todoPickReminder': 'Choisir la date et l’heure',
    'todoReminderStorageHint':
        'Cette heure est déjà enregistrée et pourra être utilisée directement quand les rappels seront activés.',
    'clearValue': 'Effacer',
  };

  static const Map<String, String> _focusEnhancedEs = <String, String>{
    'focusTitle': 'Enfoque / Relajación',
    'timerTab': 'Temporizador',
    'todoTab': 'Tareas y notas',
    'timerIdle': 'Listo',
    'focusPhase': 'Enfoque',
    'breakPhase': 'Relajación',
    'breakReady': 'Relajación lista',
    'focusReady': 'Siguiente ronda lista',
    'focusPhaseComplete': '¡Enfoque completado!',
    'breakPhaseComplete': '¡Tiempo de relajación terminado!',
    'roundProgress': 'Ronda {current} de {total}',
    'startFocus': 'Iniciar enfoque',
    'startBreak': 'Iniciar relajación',
    'startNextRound': 'Iniciar la siguiente ronda',
    'timerConfig': 'Configuración del temporizador',
    'focusMinutes': 'Duración del enfoque',
    'breakMinutes': 'Duración de la relajación',
    'rounds': 'Rondas',
    'autoStartBreak': 'Iniciar la relajación automáticamente',
    'autoStartNextRound': 'Iniciar la siguiente ronda automáticamente',
    'timerWaitingAction': 'Esperando tu siguiente acción',
    'stopTimer': 'Detener temporizador',
    'stopTimerConfirm': '¿Detener el temporizador y guardar el progreso?',
    'todayStats': 'Estadísticas de hoy',
    'focusMinutesLabel': 'Minutos de enfoque',
    'sessionMinutesLabel': 'Minutos de sesión',
    'roundsLabel': 'Rondas',
    'addTodo': 'Agregar tarea',
    'addTodoHint': 'Agregar nueva tarea...',
    'clearCompleted': 'Limpiar completadas',
    'quickNotes': 'Notas rápidas',
    'addNote': 'Agregar nota',
    'editNote': 'Editar nota',
    'deleteNote': 'Eliminar nota',
    'deleteNoteConfirm': '¿Eliminar esta nota?',
    'noteTitle': 'Título',
    'noteContent': 'Contenido',
    'hoursLabel': 'Horas',
    'minutesLabel': 'Minutos',
    'secondsLabel': 'Segundos',
    'hoursUnit': 'h',
    'minutesUnit': 'min',
    'secondsUnit': 's',
    'reminderSettings': 'Recordatorios de finalización',
    'reminderHaptic': 'Vibración / respuesta háptica',
    'reminderSound': 'Sonido del sistema',
    'reminderVoice': 'Aviso por voz',
    'reminderPauseAmbient': 'Pausar el audio ambiental',
    'reminderVisual': 'Resaltado visual',
    'resizeSplitHint':
        'Arrastra el separador para cambiar la altura de tareas y notas',
    'selectNotes': 'Seleccionar notas',
    'deleteSelectedNotes': 'Eliminar selección',
    'selectedNotesCount': '{count} seleccionadas',
    'notesEmpty': 'Todavía no hay notas',
    'todosEmpty': 'Todavía no hay tareas',
    'dragToReorder': 'Arrastra para reordenar',
    'todoInputTapHint': 'Toca para abrir el editor detallado de tareas',
    'addTodoDetails': 'Agregar detalles de la tarea',
    'editTodoDetails': 'Editar detalles de la tarea',
    'todoTitle': 'Título de la tarea',
    'todoTitleHint': '¿Qué quieres completar ahora?',
    'todoTitleRequired': 'Introduce un título para la tarea',
    'todoCategory': 'Categoría',
    'todoCategoryHint': 'Por ejemplo: repaso / escucha / lectura',
    'todoPriority': 'Prioridad',
    'todoPriorityLow': 'Baja',
    'todoPriorityMedium': 'Media',
    'todoPriorityHigh': 'Alta',
    'todoColor': 'Color',
    'todoNoColor': 'Predeterminado',
    'todoColorOption': 'Color',
    'todoNotes': 'Notas',
    'todoNotesHint': 'Añade contexto o criterios de finalización',
    'todoReminder': 'Hora del recordatorio',
    'todoReminderHint': 'Guarda fecha y hora para futuras alertas.',
    'todoPickReminder': 'Elegir fecha y hora',
    'todoReminderStorageHint':
        'La hora ya se guarda y podrá usarse directamente cuando se active la integración de recordatorios.',
    'clearValue': 'Limpiar',
  };

  static const Map<String, String> _focusEnhancedRu = <String, String>{
    'focusTitle': 'Фокус / Отдых',
    'timerTab': 'Таймер',
    'todoTab': 'Задачи и заметки',
    'timerIdle': 'Готово',
    'focusPhase': 'Фокус',
    'breakPhase': 'Отдых',
    'breakReady': 'Отдых готов',
    'focusReady': 'Следующий раунд готов',
    'focusPhaseComplete': 'Фокус завершён!',
    'breakPhaseComplete': 'Время отдыха закончилось!',
    'roundProgress': 'Раунд {current} из {total}',
    'startFocus': 'Начать фокус',
    'startBreak': 'Начать отдых',
    'startNextRound': 'Начать следующий раунд',
    'timerConfig': 'Настройки таймера',
    'focusMinutes': 'Длительность фокуса',
    'breakMinutes': 'Длительность отдыха',
    'rounds': 'Раунды',
    'autoStartBreak': 'Автоматически запускать отдых',
    'autoStartNextRound': 'Автоматически запускать следующий раунд',
    'timerWaitingAction': 'Ожидание вашего действия',
    'stopTimer': 'Остановить таймер',
    'stopTimerConfirm': 'Остановить таймер и сохранить прогресс?',
    'todayStats': 'Статистика за сегодня',
    'focusMinutesLabel': 'Минуты фокуса',
    'sessionMinutesLabel': 'Минуты сессии',
    'roundsLabel': 'Раунды',
    'addTodo': 'Добавить задачу',
    'addTodoHint': 'Добавить новую задачу...',
    'clearCompleted': 'Очистить выполненные',
    'quickNotes': 'Быстрые заметки',
    'addNote': 'Добавить заметку',
    'editNote': 'Редактировать заметку',
    'deleteNote': 'Удалить заметку',
    'deleteNoteConfirm': 'Удалить эту заметку?',
    'noteTitle': 'Заголовок',
    'noteContent': 'Содержание',
    'hoursLabel': 'Часы',
    'minutesLabel': 'Минуты',
    'secondsLabel': 'Секунды',
    'hoursUnit': 'ч',
    'minutesUnit': 'мин',
    'secondsUnit': 'с',
    'reminderSettings': 'Напоминания о завершении',
    'reminderHaptic': 'Вибрация / отклик',
    'reminderSound': 'Системный сигнал',
    'reminderVoice': 'Голосовая подсказка',
    'reminderPauseAmbient': 'Пауза фонового звука',
    'reminderVisual': 'Визуальная подсветка',
    'resizeSplitHint':
        'Перетаскивайте разделитель, чтобы менять размер задач и заметок',
    'selectNotes': 'Выбрать заметки',
    'deleteSelectedNotes': 'Удалить выбранные',
    'selectedNotesCount': 'Выбрано: {count}',
    'notesEmpty': 'Пока нет заметок',
    'todosEmpty': 'Пока нет задач',
    'dragToReorder': 'Перетащите для сортировки',
    'todoInputTapHint': 'Нажмите, чтобы открыть подробный редактор задачи',
    'addTodoDetails': 'Добавить детали задачи',
    'editTodoDetails': 'Редактировать детали задачи',
    'todoTitle': 'Название задачи',
    'todoTitleHint': 'Что вы хотите завершить сейчас?',
    'todoTitleRequired': 'Введите название задачи',
    'todoCategory': 'Категория',
    'todoCategoryHint': 'Например: повторение / аудирование / чтение',
    'todoPriority': 'Приоритет',
    'todoPriorityLow': 'Низкий',
    'todoPriorityMedium': 'Средний',
    'todoPriorityHigh': 'Высокий',
    'todoColor': 'Цвет',
    'todoNoColor': 'По умолчанию',
    'todoColorOption': 'Цвет',
    'todoNotes': 'Заметки',
    'todoNotesHint': 'Добавьте контекст или критерии выполнения',
    'todoReminder': 'Время напоминания',
    'todoReminderHint': 'Сохраняет дату и время для будущих уведомлений.',
    'todoPickReminder': 'Выбрать дату и время',
    'todoReminderStorageHint':
        'Это время уже сохраняется и может быть использовано позже при подключении напоминаний.',
    'clearValue': 'Очистить',
  };

  // --- toolbox translations (B3: sound locator / soothing / bowls) ---

  static const Map<String, String> _toolboxEn = <String, String>{
    'toolbox.sound.locator.page_title': 'Sound locator',
    'toolbox.sound.locator.page_eyebrow': 'Toolbox / Acoustic',
    'toolbox.sound.locator.page_subtitle':
        'Use the phone microphone, move through several positions, and confirm the source area step by step.',
    'toolbox.sound.locator.awaiting_source': 'Awaiting source',
    'toolbox.sound.locator.source_in_front': 'Source in front',
    'toolbox.sound.locator.direction_right': 'right',
    'toolbox.sound.locator.direction_left': 'left',
    'toolbox.sound.locator.direction_front': 'front',
    'toolbox.sound.locator.source_offset': 'Source {deg} deg {side}',
    'toolbox.sound.locator.status_starting_capture': 'Starting capture',
    'toolbox.sound.locator.status_idle': 'Idle',
    'toolbox.sound.locator.status_professional': 'Professional lock',
    'toolbox.sound.locator.status_stable': 'Stable',
    'toolbox.sound.locator.status_usable': 'Usable',
    'toolbox.sound.locator.status_low_confidence': 'Low confidence',
    'toolbox.sound.locator.status_listening': 'Listening',
    'toolbox.sound.locator.engine_mobile_move': 'Phone movement',
    'toolbox.sound.locator.engine_mobile_stereo': 'Phone stereo',
    'toolbox.sound.locator.engine_array_optional': 'Array optional',
    'toolbox.sound.locator.guidance_idle':
        'Start listening, keep the target sound active, then record this position.',
    'toolbox.sound.locator.guidance_mono':
        'Mono is still usable: record this spot, then move left, right, or forward and sample again.',
    'toolbox.sound.locator.guidance_reverb':
        'Reverb risk is high. Move closer to the source, avoid corners, or lower background noise.',
    'toolbox.sound.locator.guidance_low_snr':
        'SNR is low. In multi-source scenes, keep the target source continuous before locking.',
    'toolbox.sound.locator.guidance_normal':
        'Direction is updating. Record multiple positions so strength, SNR, and bearing stability can confirm the area.',
    'toolbox.sound.locator.btn_stop_monitor': 'Stop monitor',
    'toolbox.sound.locator.btn_starting': 'Starting',
    'toolbox.sound.locator.btn_start_locating': 'Start locating',
    'toolbox.sound.locator.btn_record_position': 'Record position',
    'toolbox.sound.locator.metric_snr': 'SNR',
    'toolbox.sound.locator.movement_confirmation': 'Movement confirmation',
    'toolbox.sound.locator.confirm_locked':
        'Source area confirmed from multiple positions. For complex environments, taking one more opposite-side sample is still recommended.',
    'toolbox.sound.locator.confirm_tracking':
        'Source area is converging. Keep the target sound active and add one more position.',
    'toolbox.sound.locator.confirm_tentative':
        'Early clues found, but at least 3 positions are needed before a stable confirmation.',
    'toolbox.sound.locator.confirm_unconfirmed':
        'Record your current position first, then move in different directions to continue sampling.',
    'toolbox.sound.locator.cue_step_0':
        'Step 1: stay here, point the phone toward the suspected area, and record once.',
    'toolbox.sound.locator.cue_stay':
        'Next: keep the target active and record this spot once more.',
    'toolbox.sound.locator.cue_left':
        'Next: step left, keep the phone facing the same way, then record.',
    'toolbox.sound.locator.cue_right':
        'Next: step right, keep the phone facing the same way, then record.',
    'toolbox.sound.locator.cue_forward':
        'Next: move one step toward the target area, then record.',
    'toolbox.sound.locator.cue_back':
        'Next: step back for a comparison sample, then record.',
    'toolbox.sound.locator.btn_reset_samples': 'Reset samples',
    'toolbox.sound.locator.cue_label_stay': 'Start',
    'toolbox.sound.locator.cue_label_left': 'Left',
    'toolbox.sound.locator.cue_label_right': 'Right',
    'toolbox.sound.locator.cue_label_forward': 'Forward',
    'toolbox.sound.locator.cue_label_back': 'Back',
    'toolbox.sound.locator.phone_mic': 'Phone microphone',
    'toolbox.sound.locator.metric_channels': 'Channels',
    'toolbox.sound.locator.metric_sample_rate': 'Sample rate',
    'toolbox.sound.locator.metric_peak': 'Peak',
    'toolbox.sound.locator.metric_reverb': 'Reverb',
    'toolbox.sound.locator.try_stereo': 'Try stereo capture',
    'toolbox.sound.locator.try_stereo_subtitle':
        'If the platform returns mono or fails to start, turn this off for stable activity checks.',
    'toolbox.sound.locator.mic_sufficient':
        'The built-in phone mic is enough for movement confirmation: one static point is weak, but several positions can converge on the source area.',
    'toolbox.sound.locator.source_candidates': 'Source candidates',
    'toolbox.sound.locator.no_stable_source':
        'No stable source yet. Keep the target source active for 1-2 seconds.',
    'toolbox.sound.locator.source_locked': 'Primary source locked',
    'toolbox.sound.locator.source_tracking': 'Tracking source',
    'toolbox.sound.locator.source_candidate': 'Candidate source',
    'toolbox.sound.locator.source_activity': 'Sound activity',
    'toolbox.sound.locator.advanced_odas': 'Advanced reference: optional ODAS',
    'toolbox.sound.locator.btn_less': 'Less',
    'toolbox.sound.locator.btn_details': 'Details',
    'toolbox.sound.locator.odas_description':
        'External synchronized mics are not required. ODAS stays optional: if a dedicated array exists, its output can be merged into this confirmation model.',
    'toolbox.sound.locator.odas_default_path':
        'The default path is phone movement sampling; advanced mode can read ODAS tracked-source JSON as extra evidence.',
    'toolbox.sound.locator.requirement_1':
        'Phone mic permission and stable PCM capture',
    'toolbox.sound.locator.requirement_2':
        'At least 3 movement samples from different positions',
    'toolbox.sound.locator.requirement_3':
        'Target sound remains active while sampling',
    'toolbox.sound.locator.requirement_4':
        'Optional ODAS or array output as advanced evidence',
    'toolbox.sound.locator.error_mic_denied':
        'Microphone permission was denied.',
    'toolbox.sound.locator.error_no_frame':
        'No usable audio frame yet. Start listening and keep the target sound active.',

    'toolbox.sound.soothing.page_title': 'Soothing music',
    'toolbox.sound.soothing.page_subtitle':
        'Curated calming loops with breathing light effects, local tracks, and a mobile-first immersive layout.',
    'toolbox.sound.soothing.browse_modes_title': 'Browse modes',
    'toolbox.sound.soothing.browse_modes_subtitle':
        'Selecting a mode closes the menu and keeps the current mode clearly highlighted.',
    'toolbox.sound.soothing.modes_button_label': 'Modes',
    'toolbox.sound.soothing.mode_filter_all': 'All',
    'toolbox.sound.soothing.mode_filter_favorites': 'Favorites',
    'toolbox.sound.soothing.mode_filter_recent': 'Recent',
    'toolbox.sound.soothing.empty_mode_title_favorites':
        'No favorite modes yet',
    'toolbox.sound.soothing.empty_mode_title_recent': 'No recent modes yet',
    'toolbox.sound.soothing.empty_mode_subtitle_favorites':
        'Mark modes you use often and they will appear here for quick switching.',
    'toolbox.sound.soothing.empty_mode_subtitle_recent':
        'Once you switch or play a few modes, your recent history will appear here.',
    'toolbox.sound.soothing.show_all_modes_label': 'Show all',
    'toolbox.sound.soothing.sleep_timer_button_label': 'Sleep timer',
    'toolbox.sound.soothing.timer_off': 'Off',
    'toolbox.sound.soothing.timer_minutes': '{count} min',
    'toolbox.sound.soothing.active_sleep_timer': 'Sleep timer {duration}',
    'toolbox.sound.soothing.track_count_label': '{count} tracks',
    'toolbox.sound.soothing.active_mode_label': 'Active',
    'toolbox.sound.soothing.favorite_toggle_label': 'Toggle favorite',
    'toolbox.sound.soothing.previous_track_label': 'Previous track',
    'toolbox.sound.soothing.next_track_label': 'Next track',
    'toolbox.sound.soothing.volume_toggle_label': 'Toggle mute',
    'toolbox.sound.soothing.playback_single_loop': 'Single loop',
    'toolbox.sound.soothing.playback_mode_cycle': 'Mode cycle',
    'toolbox.sound.soothing.playback_arrangement': 'Arrangement',
    'toolbox.sound.soothing.arrangement_not_configured':
        'Arrangement (not configured)',
    'toolbox.sound.soothing.arrangement_template': 'Arrangement \u00b7 {name}',
    'toolbox.sound.soothing.arrangement_steps':
        'Arrangement \u00b7 {steps} steps',
    'toolbox.sound.soothing.arrangement_progress':
        'Step {current}/{total} \u00b7 {mode} \u00b7 {track} \u00b7 {repeat}/{max}',
    'toolbox.sound.soothing.btn_playback_settings': 'Playback settings',
    'toolbox.sound.soothing.btn_edit_arrangement': 'Edit arrangement',
    'toolbox.sound.soothing.btn_fullscreen_exit': 'Exit fullscreen',
    'toolbox.sound.soothing.btn_fullscreen_enter': 'Enter fullscreen',
    'toolbox.sound.soothing.my_arrangement': 'My arrangement',
    'toolbox.sound.soothing.save_arrangement': 'Save arrangement',
    'toolbox.sound.soothing.save_arrangement_subtitle':
        'Save the current arrangement for quick reuse.',
    'toolbox.sound.soothing.save_arrangement_hint':
        'For example: Wind-down 20m',
    'toolbox.sound.soothing.save': 'Save',
    'toolbox.sound.soothing.arrangement_saved': 'Saved arrangement: {name}',
    'toolbox.sound.soothing.rename_arrangement': 'Rename arrangement',
    'toolbox.sound.soothing.rename_hint': 'Enter a new name',
    'toolbox.sound.soothing.delete_arrangement': 'Delete arrangement',
    'toolbox.sound.soothing.delete_arrangement_confirm': 'Delete "{name}"?',
    'toolbox.sound.soothing.delete': 'Delete',
    'toolbox.sound.soothing.playback_order': 'Playback order',
    'toolbox.sound.soothing.playback_order_desc':
        'Single loop is the default. Switch to arrangement mode to auto-advance across themes and tracks.',
    'toolbox.sound.soothing.arrangement_not_saved':
        'Current arrangement not saved',
    'toolbox.sound.soothing.arrangement_steps_info':
        '{steps} steps \u00b7 {templates} saved',
    'toolbox.sound.soothing.save_current': 'Save current',
    'toolbox.sound.soothing.load_saved': 'Load saved',
    'toolbox.sound.soothing.template_steps': '{count} steps',
    'toolbox.sound.soothing.rename': 'Rename',
    'toolbox.sound.soothing.arrangement_steps_title': 'Arrangement steps',
    'toolbox.sound.soothing.add_current': 'Add current',
    'toolbox.sound.soothing.theme': 'Theme',
    'toolbox.sound.soothing.track': 'Track',
    'toolbox.sound.soothing.repeats': 'Repeats',
    'toolbox.sound.soothing.apply': 'Apply',

    'toolbox.sound.bowls.appbar_title': 'Healing bowls',
    'toolbox.sound.bowls.page_subtitle':
        'Eleven nature-tuned frequencies and four bowl voices, shaped for a softer, longer listening session.',
    'toolbox.sound.bowls.voices_section_title': 'Voices',
    'toolbox.sound.bowls.voices_section_subtitle':
        'Four harmonic profiles to rotate through',
    'toolbox.sound.bowls.frequency_menu_title': 'Frequency menu',
    'toolbox.sound.bowls.frequency_menu_subtitle': 'Chakra and resonance tones',
    'toolbox.sound.bowls.today_suggestion_title': 'Current listening note',
    'toolbox.sound.bowls.today_suggestion_body':
        'At night, try Deep with Om / Earth or 174 Hz. For lighter daytime reset sessions, Crystal with Harmony, 528 Hz, or 639 Hz feels gentler.',
    'toolbox.sound.bowls.nature_tuned_tones': 'Nature-tuned tones',
    'toolbox.sound.bowls.soft_spectral_decay': 'Soft spectral decay',
    'toolbox.sound.bowls.pull_up_sheet_controls': 'Pull-up sheet controls',
    'toolbox.sound.bowls.autoplay_title': 'Autoplay',
    'toolbox.sound.bowls.autoplay_subtitle': 'Slow, spacious repetition',
    'toolbox.sound.bowls.interval_label': 'Interval',
    'toolbox.sound.bowls.haptics_title': 'Haptics',
    'toolbox.sound.bowls.haptics_subtitle':
        'Add a light pulse on manual strike',
    'toolbox.sound.bowls.btn_pause_autoplay': 'Pause autoplay',
    'toolbox.sound.bowls.btn_start_autoplay': 'Start autoplay',
    'toolbox.sound.bowls.btn_stop_resonance': 'Stop resonance',
    'toolbox.sound.bowls.btn_mute': 'Mute',
    'toolbox.sound.bowls.btn_enable_sound': 'Enable sound',
    'toolbox.sound.bowls.back_to_toolbox': 'Back to toolbox',
    'toolbox.sound.bowls.sheet_title': 'Tone & cadence',
    'toolbox.sound.bowls.sheet_subtitle':
        'Pick a frequency, choose a voice, and tap at your own slow rhythm.',
    'toolbox.sound.bowls.sheet_frequency_menu': 'Frequency menu',
    'toolbox.sound.bowls.sheet_frequency_subtitle': 'Chakra & resonance tones',
    'toolbox.sound.bowls.sheet_chakra_group': 'Chakra series',
    'toolbox.sound.bowls.sheet_resonance_group': 'Resonance tones',
    'toolbox.sound.bowls.sheet_voices_title': 'Voices',
    'toolbox.sound.bowls.sheet_voices_subtitle': 'Four bowl harmonics',
    'toolbox.sound.bowls.sheet_autoplay_title': 'Autoplay',
    'toolbox.sound.bowls.sheet_autoplay_subtitle': 'Slow, spacious repetition',
    'toolbox.sound.bowls.sheet_interval': 'Interval',
    'toolbox.sound.bowls.sheet_haptics_title': 'Haptics',
    'toolbox.sound.bowls.sheet_haptics_subtitle':
        'Add a light pulse on manual strike',
    'toolbox.sound.bowls.sheet_pause_autoplay': 'Pause autoplay',
    'toolbox.sound.bowls.sheet_start_autoplay': 'Start autoplay',
    'toolbox.sound.bowls.sheet_stop_resonance': 'Stop resonance',
    'toolbox.sound.bowls.btn_close': 'Close',
    'toolbox.sound.bowls.auto_interval_label': 'Autoplay every {interval}s',
    'toolbox.sound.bowls.tap_hint':
        'Tap the bowl and let it bloom, spread, and settle.',
    'toolbox.sound.bowls.bowl_semantics': 'Strike bowl',
    'toolbox.sound.bowls.auto_summary_suffix': ' \u00b7 Auto {interval}s',

    // B3: sound harp/guitar/violin/flute/triangle
    'toolbox.sound.flute.airy': 'Airy',
    'toolbox.sound.flute.airy_flow': 'Airy flow',
    'toolbox.sound.flute.alto': 'Alto',
    'toolbox.sound.flute.bamboo': 'Bamboo',
    'toolbox.sound.flute.bamboo_breath': 'Bamboo breath',
    'toolbox.sound.flute.blow_off': 'Blow off',
    'toolbox.sound.flute.blow_on': 'Blow on',
    'toolbox.sound.flute.blow_sensor': 'Blow sensor',
    'toolbox.sound.flute.breath': 'Breath',
    'toolbox.sound.flute.breath_2': 'Breath',
    'toolbox.sound.flute.breath_3': 'Breath {value}%',
    'toolbox.sound.flute.breath_and_space': 'Breath and space',
    'toolbox.sound.flute.brighter_lead_tone_with_stronger':
        'Brighter lead tone with stronger presence for melodic phrases.',
    'toolbox.sound.flute.clay_ocarina': 'Clay ocarina',
    'toolbox.sound.flute.disable_blow_sensor': 'Disable blow sensor',
    'toolbox.sound.flute.dorian': 'Dorian',
    'toolbox.sound.flute.enable_blow_sensor': 'Enable blow sensor',
    'toolbox.sound.flute.flute_settings': 'Flute settings',
    'toolbox.sound.flute.full_screen': 'Full screen',
    'toolbox.sound.flute.gentler_attacks_and_a_more':
        'Gentler attacks and a more bamboo-like body for calm pentatonic phrases.',
    'toolbox.sound.flute.hollow': 'Hollow',
    'toolbox.sound.flute.jade_flute': 'Jade flute',
    'toolbox.sound.flute.lead': 'Lead',
    'toolbox.sound.flute.lead_solo': 'Lead solo',
    'toolbox.sound.flute.long_metal': 'Long metal',
    'toolbox.sound.flute.lydian': 'Lydian',
    'toolbox.sound.flute.major': 'Major',
    'toolbox.sound.flute.material': 'Material',
    'toolbox.sound.flute.microphone_permission_unavailable':
        'Microphone permission unavailable',
    'toolbox.sound.flute.microphone_permission_unavailable_touch_play':
        'Microphone permission unavailable. Touch play is still available.',
    'toolbox.sound.flute.mixolydian': 'Mixolydian',
    'toolbox.sound.flute.natural_breathy_tone_for_gentle':
        'Natural breathy tone for gentle and flowing play.',
    'toolbox.sound.flute.natural_minor': 'Natural minor',
    'toolbox.sound.flute.off': 'Off',
    'toolbox.sound.flute.pentatonic': 'Pentatonic',
    'toolbox.sound.flute.preset_pack': 'Preset pack',
    'toolbox.sound.flute.rebuild_the_flute_body_finger':
        'Rebuild the flute body, finger holes, and note rail for portrait phones.',
    'toolbox.sound.flute.scale': 'Scale',
    'toolbox.sound.flute.settings': 'Settings',
    'toolbox.sound.flute.short_metal': 'Short metal',
    'toolbox.sound.flute.space': 'Space {value}%',
    'toolbox.sound.flute.tail': 'Tail {value}%',
    'toolbox.sound.flute.threshold_current':
        'Threshold {pct}% \u00b7 Current {current}%',
    'toolbox.sound.flute.threshold_current_holes':
        'Threshold {pct}% \u00b7 Current {current}% \u00b7 Holes {holes}',
    'toolbox.sound.flute.timbre': 'Timbre',
    'toolbox.sound.flute.velvet': 'Velvet',
    'toolbox.sound.flute.vertical_flute': 'Vertical flute',
    'toolbox.sound.flute.warm_alto': 'Warm alto',
    'toolbox.sound.flute.warmer_midrange_and_softer_tail':
        'Warmer midrange and softer tail for calm backing layers.',
    'toolbox.sound.flute.wood_flute': 'Wood flute',
    'toolbox.sound.guitar.ambient_chime': 'Ambient chime',
    'toolbox.sound.guitar.chord_and_capo': 'Chord and capo',
    'toolbox.sound.guitar.clear_steelcore_tone_tuned_for':
        'Clear steel-core tone tuned for rhythmic strumming.',
    'toolbox.sound.guitar.guitar_settings': 'Guitar settings',
    'toolbox.sound.guitar.guitar_stage': 'Guitar stage',
    'toolbox.sound.guitar.longer_shimmer_and_overtones_for':
        'Longer shimmer and overtones for ambient layers.',
    'toolbox.sound.guitar.nylon_finger': 'Nylon finger',
    'toolbox.sound.guitar.open_ring': 'Open ring',
    'toolbox.sound.guitar.palm_mute': 'Palm mute',
    'toolbox.sound.guitar.palm_mute_2': 'Palm mute',
    'toolbox.sound.guitar.pick_a_chord_pluck_or':
        'Pick a chord, pluck or sweep the strings, and move the capo to lift the voicing.',
    'toolbox.sound.guitar.pick_position': 'Pick position {value}%',
    'toolbox.sound.guitar.resonance': 'Resonance {value}%',
    'toolbox.sound.guitar.resonance_shapes_body_response_and':
        'Resonance shapes body response and pick position shifts brightness.',
    'toolbox.sound.guitar.rounder_and_softer_for_slow':
        'Rounder and softer for slow arpeggios and finger picking.',
    'toolbox.sound.guitar.shortens_sustain_and_tightens_upper':
        'Shortens sustain and tightens upper harmonics for rhythmic strokes.',
    'toolbox.sound.guitar.steel_strum': 'Steel strum',
    'toolbox.sound.guitar.strum_down': 'Strum down',
    'toolbox.sound.guitar.strum_up': 'Strum up',
    'toolbox.sound.guitar.swipe_vertically_to_strum_tap':
        'Swipe vertically to strum; tap a string to pluck single notes.',
    'toolbox.sound.guitar.tone_shaping': 'Tone shaping',
    'toolbox.sound.guitar.swipe_label': 'Swipe',
    'toolbox.sound.guitar.strum_label': 'Swipe to strum',
    'toolbox.sound.guitar.phone_layout_sub':
        'The phone layout keeps the strum surface primary and moves harmony controls into compact rows.',
    'toolbox.sound.guitar.desktop_layout_sub':
        'The strum surface stays primary while chords, capo, and tone controls sit around it.',
    'toolbox.sound.harp.a_minor': 'A Minor',
    'toolbox.sound.harp.add9': 'Add9',
    'toolbox.sound.harp.advanced': 'Advanced',
    'toolbox.sound.harp.arpeggio': 'Arpeggio',
    'toolbox.sound.harp.ascending_sweep': 'Ascending sweep.',
    'toolbox.sound.harp.aurora': 'Aurora',
    'toolbox.sound.harp.auto_arpeggio': 'Auto arpeggio',
    'toolbox.sound.harp.balanced_and_soft': 'Balanced and soft.',
    'toolbox.sound.harp.balanced_sustain_for_melodic_passages':
        'Balanced sustain for melodic passages.',
    'toolbox.sound.harp.bright': 'Bright',
    'toolbox.sound.harp.c_lydian': 'C Lydian',
    'toolbox.sound.harp.c_major': 'C Major',
    'toolbox.sound.harp.cascade': 'Cascade',
    'toolbox.sound.harp.chamber_soft': 'Chamber Soft',
    'toolbox.sound.harp.chord': 'Chord',
    'toolbox.sound.harp.chord_2': 'Chord',
    'toolbox.sound.harp.chord_resonance': 'Chord resonance',
    'toolbox.sound.harp.chord_root': 'Chord root {current} / {total}',
    'toolbox.sound.harp.clear_attack_for_active_strum':
        'Clear attack for active strum.',
    'toolbox.sound.harp.concert': 'Concert',
    'toolbox.sound.harp.concert_nylon': 'Concert Nylon',
    'toolbox.sound.harp.crystal': 'Crystal',
    'toolbox.sound.harp.custom': 'Custom',
    'toolbox.sound.harp.d_dorian': 'D Dorian',
    'toolbox.sound.harp.damping': 'Damping {value}',
    'toolbox.sound.harp.damping_sweep_deadzone_and_chord':
        'Damping, sweep deadzone, and chord root.',
    'toolbox.sound.harp.ember': 'Ember',
    'toolbox.sound.harp.ethereal_harp': 'Ethereal Harp',
    'toolbox.sound.harp.glass': 'Glass',
    'toolbox.sound.harp.glide': 'Glide',
    'toolbox.sound.harp.hide_tip': 'Hide tip',
    'toolbox.sound.harp.high_realism_presets': 'High Realism Presets',
    'toolbox.sound.harp.hirajoshi': 'Hirajoshi',
    'toolbox.sound.harp.horizontal': 'Horizontal',
    'toolbox.sound.harp.ivory_wood': 'Ivory Wood',
    'toolbox.sound.harp.jade': 'Jade',
    'toolbox.sound.harp.layout': 'Layout',
    'toolbox.sound.harp.maj7': 'Maj7',
    'toolbox.sound.harp.major': 'Major',
    'toolbox.sound.harp.min7': 'Min7',
    'toolbox.sound.harp.minor': 'Minor',
    'toolbox.sound.harp.moon': 'Moon',
    'toolbox.sound.harp.more_body_and_slower_tail':
        'More body and slower tail.',
    'toolbox.sound.harp.muted': 'Muted',
    'toolbox.sound.harp.nylon': 'Nylon',
    'toolbox.sound.harp.palette': 'Palette',
    'toolbox.sound.harp.pedal_harp': 'Pedal Harp',
    'toolbox.sound.harp.pedalharp_like_balance_and_sustain':
        'Pedal-harp like balance and sustain.',
    'toolbox.sound.harp.preset': 'Preset',
    'toolbox.sound.harp.pulse_active_chord_tones': 'Pulse active chord tones.',
    'toolbox.sound.harp.reverb': 'Reverb',
    'toolbox.sound.harp.reverb_2': 'Reverb {value}%',
    'toolbox.sound.harp.round_body_with_controlled_hall':
        'Round body with controlled hall tail.',
    'toolbox.sound.harp.round_body_with_light_transient':
        'Round body with light transient.',
    'toolbox.sound.harp.scale_harmony': 'Scale & Harmony',
    'toolbox.sound.harp.sharper_upper_harmonics': 'Sharper upper harmonics.',
    'toolbox.sound.harp.silk': 'Silk',
    'toolbox.sound.harp.soft_fingerpluck_with_gentle_bloom':
        'Soft finger-pluck with gentle bloom.',
    'toolbox.sound.harp.sound_on': 'Sound on',
    'toolbox.sound.harp.steel': 'Steel',
    'toolbox.sound.harp.steel_studio': 'Steel Studio',
    'toolbox.sound.harp.stronger_core_and_brighter_attack':
        'Stronger core and brighter attack.',
    'toolbox.sound.harp.sus2': 'Sus2',
    'toolbox.sound.harp.sus4': 'Sus4',
    'toolbox.sound.harp.sweep_deadzone_px': 'Sweep deadzone {value} px',
    'toolbox.sound.harp.tap_a_note_then_glide':
        'Tap a note, then glide across strings to sweep.',
    'toolbox.sound.harp.tap_for_single_note_swipe':
        'Tap for single note, swipe for sweep.',
    'toolbox.sound.harp.theme_timbre': 'Theme & Timbre',
    'toolbox.sound.harp.thin_body_and_sparkling_top':
        'Thin body and sparkling top.',
    'toolbox.sound.harp.tight_transient_and_clear_note':
        'Tight transient and clear note separation.',
    'toolbox.sound.harp.timbre': 'Timbre',
    'toolbox.sound.harp.timbre_scale_chord_and_feel':
        'Timbre, scale, chord, and feel live in the sheet.',
    'toolbox.sound.harp.up_then_down': 'Up then down.',
    'toolbox.sound.harp.vertical': 'Vertical',
    'toolbox.sound.harp.warm': 'Warm',
    'toolbox.sound.harp.zen_pentatonic': 'Zen Pentatonic',
    'toolbox.sound.triangle.accent': 'Accent',
    'toolbox.sound.triangle.aluminum': 'Aluminum',
    'toolbox.sound.triangle.balanced_brightness_and_decay_close':
        'Balanced brightness and decay close to orchestral behavior.',
    'toolbox.sound.triangle.brass': 'Brass',
    'toolbox.sound.triangle.bright_ring': 'Bright ring',
    'toolbox.sound.triangle.brighter_attack_and_stronger_ring':
        'Brighter attack and stronger ring to mark accents.',
    'toolbox.sound.triangle.damping': 'Damping {value}%',
    'toolbox.sound.triangle.left_is_softer_right_is':
        'Left is softer, right is brighter; roll mode creates tight repeated accents.',
    'toolbox.sound.triangle.left_softer': 'Left softer',
    'toolbox.sound.triangle.material_shapes_overtones_while_strike':
        'Material shapes overtones while strike point and damping control attack and tail.',
    'toolbox.sound.triangle.orchestral_ring': 'Orchestral ring',
    'toolbox.sound.triangle.presets_move_tone_material_and':
        'Presets move tone, material, and default ring length together.',
    'toolbox.sound.triangle.right_brighter': 'Right brighter',
    'toolbox.sound.triangle.ring': 'Ring {value}%',
    'toolbox.sound.triangle.roll': 'Roll',
    'toolbox.sound.triangle.single': 'Single',
    'toolbox.sound.triangle.soft_ring': 'Soft ring',
    'toolbox.sound.triangle.softer_highs_and_a_shorter':
        'Softer highs and a shorter tail for gentle rhythm support.',
    'toolbox.sound.triangle.steel': 'Steel',
    'toolbox.sound.triangle.strike': 'Strike {value}%',
    'toolbox.sound.triangle.strike_now': 'Strike now',
    'toolbox.sound.triangle.strike_stage': 'Strike stage',
    'toolbox.sound.triangle.tap_directly_on_the_triangle':
        'Tap directly on the triangle: left is softer, right is brighter, and the mode changes the gesture output.',
    'toolbox.sound.triangle.tone_and_decay': 'Tone and decay',
    'toolbox.sound.triangle.triangle_settings': 'Triangle settings',
    'toolbox.sound.violin.a_woody': 'A Woody',
    'toolbox.sound.violin.ab_voicing': 'A/B voicing',
    'toolbox.sound.violin.b_bright': 'B Bright',
    'toolbox.sound.violin.balanced_solo_tone_for_melodic':
        'Balanced solo tone for melodic glides.',
    'toolbox.sound.violin.bow_and_space': 'Bow and space',
    'toolbox.sound.violin.bow_tone':
        'Bow {pct}% \u00b7 Tone {tone} \u00b7 {variant}',
    'toolbox.sound.violin.brighter_harmonics_with_a_cleaner':
        'Brighter harmonics with a cleaner edge for airy textures.',
    'toolbox.sound.violin.chromatic': 'Chromatic',
    'toolbox.sound.violin.expose_bow_pressure_and_reverb':
        'Expose bow pressure and reverb separately for better solo and room control.',
    'toolbox.sound.violin.fingerboard_stage': 'Fingerboard stage',
    'toolbox.sound.violin.glass': 'Glass',
    'toolbox.sound.violin.glass_harmonic': 'Glass harmonic',
    'toolbox.sound.violin.last_note': 'Last note',
    'toolbox.sound.violin.minor': 'Minor',
    'toolbox.sound.violin.position': 'Position',
    'toolbox.sound.violin.position_2': 'Position {value}',
    'toolbox.sound.violin.reverb': 'Reverb {value}%',
    'toolbox.sound.violin.scale_and_position': 'Scale and position',
    'toolbox.sound.violin.softer_bow_pressure_with_a':
        'Softer bow pressure with a longer tail for lyrical lines.',
    'toolbox.sound.violin.solo': 'Solo',
    'toolbox.sound.violin.solo_bow': 'Solo bow',
    'toolbox.sound.violin.strings': 'Strings',
    'toolbox.sound.violin.two_fingers_enable_doublestop':
        'Two fingers enable double-stop',
    'toolbox.sound.violin.use_scale_categories_and_position':
        'Use scale categories and position windows to keep the fingerboard playable on phones.',
    'toolbox.sound.violin.variant_a_is_woodier_and':
        'Variant A is woodier and fuller for natural solo phrases.',
    'toolbox.sound.violin.variant_b_is_brighter_and':
        'Variant B is brighter and more forward for cutting solo lines.',
    'toolbox.sound.violin.violin_settings': 'Violin settings',
    'toolbox.sound.violin.warm': 'Warm',
    'toolbox.sound.violin.warm_legato': 'Warm legato',
    'toolbox.sound.violin.phone_subtitle':
        'Tap to start the bow, slide for pitch, and release to stop on phones.',
    'toolbox.sound.violin.desktop_subtitle':
        'Slide horizontally for pitch, vertically for strings, and now start instantly on tap.',

    // B4: focus beats (sound)
    'toolbox.sound.focus.controlTempo': 'Tempo',
    'toolbox.sound.focus.controlTempoDesc':
        'Adjust BPM with quick step buttons.',
    'toolbox.sound.focus.controlMeter': 'Time signature',
    'toolbox.sound.focus.controlMeterDesc':
        'Sets strong/weak beat structure and subdivision density.',
    'toolbox.sound.focus.controlTimbre': 'Beat timbre',
    'toolbox.sound.focus.controlTimbreDesc':
        'Choose the sound character for each beat click.',
    'toolbox.sound.focus.controlArrangement': 'Beat pattern',
    'toolbox.sound.focus.controlArrangementDesc':
        'Group bars into phrases for rhythmic variety.',
    'toolbox.sound.focus.singleBarLoop': 'Single bar',
    'toolbox.sound.focus.controlMix': 'Mix & haptics',
    'toolbox.sound.focus.controlMixDesc':
        'Adjust accent, regular, subdivision, and vibration levels.',
    'toolbox.sound.focus.controlMixDesc2':
        'Fine-tune accent, regular, subdivision beats and vibration.',
    'toolbox.sound.focus.hapticsOn': 'Haptics on',
    'toolbox.sound.focus.hapticsOff': 'Haptics off',
    'toolbox.sound.focus.controlStart': 'Start',
    'toolbox.sound.focus.controlStop': 'Stop',
    'toolbox.sound.focus.controlPreviewSound': 'Preview',
    'toolbox.sound.focus.controlFullStage': 'Full stage',
    'toolbox.sound.focus.controlOpenControls': 'Open controls',
    'toolbox.sound.focus.controlExitFull': 'Exit fullscreen',
    'toolbox.sound.focus.controlImmersive': 'Immersive',
    'toolbox.sound.focus.controlHapticsOn': 'Haptics on',
    'toolbox.sound.focus.controlHapticsOff': 'Haptics off',
    'toolbox.sound.focus.controlTapHint':
        'Tap to start or stop — stay in flow.',
    'toolbox.sound.focus.animNameWarm': 'Warm path',
    'toolbox.sound.focus.animNameStill': 'Still orbit',
    'toolbox.sound.focus.animNameClear': 'Clear wave',
    'toolbox.sound.focus.animNamePrecision': 'Precision mark',
    'toolbox.sound.focus.animNameStep': 'Step array',
    'toolbox.sound.focus.soundNamePendulum': 'Click',
    'toolbox.sound.focus.soundNamePulse': 'Pulse',
    'toolbox.sound.focus.soundNameDrop': 'Drop',
    'toolbox.sound.focus.soundNameTick': 'Tick',
    'toolbox.sound.focus.soundNameStep': 'Step',
    'toolbox.sound.focus.immersiveControlsTitle': 'Controls',
    'toolbox.sound.focus.immersiveControlsDesc':
        'Tap the bottom edge to bring up controls while staying fullscreen.',
    'toolbox.sound.focus.immersiveExitSheet': 'Close',
    'toolbox.sound.focus.immersiveOpenControls': 'Open controls',
    'toolbox.sound.focus.immersiveExitFull': 'Exit fullscreen',
    'toolbox.sound.focus.immersiveCurrentBeat': '{label}',
    'toolbox.sound.focus.immersiveReady': 'Ready',
    'toolbox.sound.focus.immersiveHint': 'Tap to start the beat. Stay in flow.',
    'toolbox.sound.focus.stageBeatPath': 'Beat path',
    'toolbox.sound.focus.stageSubbeat': '{label} subdivision',
    'toolbox.sound.focus.stageMoving': 'Moving',
    'toolbox.sound.focus.stageReady': 'Ready',
    'toolbox.sound.focus.stagePulseInMotion': 'Pulse in motion',
    'toolbox.sound.focus.stageWaitingBeatOne': 'Waiting for beat one',
    'toolbox.sound.focus.stageCycleLabel': 'Cycle {label}',
    'toolbox.sound.focus.stagePatternLabel': 'Pattern {label}',
    'toolbox.sound.focus.stagePhraseLabel': 'Phrase {label}',
    'toolbox.sound.focus.stageHapticsOn': 'Haptics on',
    'toolbox.sound.focus.stageHapticsOff': 'Haptics off',
    'toolbox.sound.focus.stageBeatLabel': 'Beat',
    'toolbox.sound.focus.stageSubLabel': 'Sub',
    'toolbox.sound.focus.stageSegmentS': 'Segment ',
    'toolbox.sound.focus.stageBeatsUnit': ' beats',
    'toolbox.sound.focus.stagePulseMoving': 'Playing',
    'toolbox.sound.focus.stageTrackReady': 'Ready',
    'toolbox.sound.focus.stageSummaryRunning': 'Playing',
    'toolbox.sound.focus.stageSummaryIdle': 'Ready to start',
    'toolbox.sound.focus.stageBeatShort': 'Bt',
    'toolbox.sound.focus.stageSubShort': 'Sub',
    'toolbox.sound.focus.stageLoopLabel': 'Loop',
    'toolbox.sound.focus.tempoLabel': '{bpm} BPM · {sec} s/beat',
    'toolbox.sound.focus.meterDesc':
        'Time signature sets strong/weak beats; subdivision splits each beat internally.',
    'toolbox.sound.focus.meterSubDiv': 'Sub ×{div}',
    'toolbox.sound.focus.styleDesc':
        'Animation and timbre are paired by default. Switch freely to mix and match.',
    'toolbox.sound.focus.previewButton': 'Preview',
    'toolbox.sound.focus.styleTimbreTitle': 'Beat timbre',
    'toolbox.sound.focus.arrangementEnabled': 'Pattern on',
    'toolbox.sound.focus.arrangementSingleBar': 'Single bar',
    'toolbox.sound.focus.arrangementLabel': 'Pattern: {label} ({total} beats)',
    'toolbox.sound.focus.editButton': 'Edit',
    'toolbox.sound.focus.arrangementDesc':
        'Group bars into phrases to create stronger section feel across a cycle.',
    'toolbox.sound.focus.mixMaster': 'Master',
    'toolbox.sound.focus.mixAccent': 'Accent',
    'toolbox.sound.focus.mixRegular': 'Regular',
    'toolbox.sound.focus.mixSubdivision': 'Subdivision',
    'toolbox.sound.focus.mixHapticLabel': 'Haptic feedback',
    'toolbox.sound.focus.mixHapticDesc':
        'Subtle vibration on accents and section changes.',

    // --- toolbox hub (B2: main hub page, sections, entries, quick panel) ---
    'toolbox.hub.page.title': 'Toolbox',
    'toolbox.hub.page.subtitle':
        'Browse, configure, and personalize your wellness toolkit.',
    'toolbox.hub.page.section_title': 'Available tools',
    'toolbox.hub.intro.title_idle': 'Your wellness toolkit',
    'toolbox.hub.intro.summary_idle':
        'Quick access to sleep, focus, sound, and calm tools.',
    'toolbox.hub.intro.details_idle':
        'Tap any tool to open it. Drag entries onto the Quick panel for one-tap access.',
    'toolbox.hub.intro.title_editing': 'Customize your toolbox',
    'toolbox.hub.intro.summary_editing':
        'Hide tools you rarely use, reorder your favorites, and pin shortcuts.',
    'toolbox.hub.intro.details_editing':
        'Tap the eye icon to hide or restore. Drag the handle to reorder. Pinned entries appear at the top.',
    'toolbox.hub.intro.highlight_edit':
        'Hide or show tools to match your daily routine.',
    'toolbox.hub.intro.highlight_reorder':
        'Drag-and-drop reordering for quick access.',
    'toolbox.hub.intro.highlight_shortcuts':
        'Pin your most-used tools to the Quick entry panel.',
    'toolbox.hub.intro.highlight_restorable':
        'Hidden tools are hidden, not deleted — one tap restores them.',
    'toolbox.hub.intro.help_tooltip': 'How to use the toolbox',
    'toolbox.hub.edit.toggle_enter': 'Customize',
    'toolbox.hub.edit.toggle_exit': 'Done',
    'toolbox.hub.edit.drag_tooltip': 'Drag to reorder',
    'toolbox.hub.edit.remove_tooltip': 'Hide this tool',
    'toolbox.hub.edit.confirm_remove_title': 'Hide {title}?',
    'toolbox.hub.edit.confirm_remove_desc':
        'This tool will be hidden from the toolbox. You can restore it anytime from the edit panel.',
    'toolbox.hub.edit.remove_action': 'Hide',
    'toolbox.hub.edit.snackbar_hidden': '{title} hidden',
    'toolbox.hub.edit.snackbar_restore': 'Undo',
    'toolbox.hub.edit.section_title': 'Toolbox layout',
    'toolbox.hub.edit.layout_instructions':
        'Tap the eye icon to hide or show a tool. Drag the handle to reorder.',
    'toolbox.hub.edit.status_visible': 'Visible',
    'toolbox.hub.edit.status_hidden': 'Hidden',
    'toolbox.hub.edit.exit_button': 'Exit edit',
    'toolbox.hub.edit.restore_button': 'Restore all',
    'toolbox.hub.edit.reset_button': 'Reset layout',
    'toolbox.hub.edit.empty_title': 'No visible tools',
    'toolbox.hub.edit.empty_desc_no_hidden':
        'All available tools are currently visible. To hide a tool, tap the eye icon next to its name.',
    'toolbox.hub.edit.empty_desc_has_hidden':
        'Some tools are currently hidden. Use the hidden section below to restore them.',
    'toolbox.hub.edit.empty_hidden_count': '{count} hidden tools available',
    'toolbox.hub.edit.empty_edit_button': 'Open edit panel',
    'toolbox.hub.edit.restore_section_title': 'Hidden tools',
    'toolbox.hub.edit.restore_notice':
        'Tap the eye icon to restore a hidden tool.',
    'toolbox.hub.edit.restore_action': 'Restore',

    'toolbox.hub.section.sleep.title': 'Sleep',
    'toolbox.hub.section.sleep.subtitle':
        'Assessment, logging, wind-down, and night rescue guides.',
    'toolbox.hub.section.games.title': 'Mini Games',
    'toolbox.hub.section.games.subtitle':
        'Light cognitive activities to shift focus and unwind.',
    'toolbox.hub.section.tests.title': 'Human Tests',
    'toolbox.hub.section.tests.subtitle':
        'Self-assessment tools for cognitive and behavioral patterns.',
    'toolbox.hub.section.sound.title': 'Sound & Music',
    'toolbox.hub.section.sound.subtitle':
        'Soothing audio, singing bowls, harp, guitar, flute, and more.',
    'toolbox.hub.section.focus.title': 'Focus & Attention',
    'toolbox.hub.section.focus.subtitle':
        'Schulte grid, breathing exercises, and attention training.',
    'toolbox.hub.section.calm.title': 'Calm & Meditation',
    'toolbox.hub.section.calm.subtitle':
        'Mindful beads, finger sand art, and meditation tools.',
    'toolbox.hub.section.life.title': 'Life Tools',
    'toolbox.hub.section.life.subtitle':
        'Practical daily utilities and lifestyle helpers.',
    'toolbox.hub.section.crypto.title': 'Crypto & Security',
    'toolbox.hub.section.crypto.subtitle':
        'Encryption, hashing, and security utilities.',
    'toolbox.hub.section.decision.title': 'Decision Helper',
    'toolbox.hub.section.decision.subtitle':
        'Turn daily dilemmas into light, replayable choices.',

    'toolbox.hub.entry.sleep_assistant.title': 'Sleep Assistant',
    'toolbox.hub.entry.sleep_assistant.subtitle':
        'Personalized assessment, plans, and nightly guidance.',
    'toolbox.hub.entry.games.title': 'Mini Games',
    'toolbox.hub.entry.games.subtitle':
        'Quick cognitive mini-games for focus shifting.',
    'toolbox.hub.entry.tests.title': 'Human Tests',
    'toolbox.hub.entry.tests.subtitle':
        'Cognitive and behavioral self-assessments.',
    'toolbox.hub.entry.soothing.title': 'Soothing Music',
    'toolbox.hub.entry.soothing.subtitle':
        'Curated calming loops with breathing light effects.',
    'toolbox.hub.entry.harp.title': 'Harp & Strings',
    'toolbox.hub.entry.harp.subtitle':
        'Play harp, guitar, violin, flute, and triangle sounds.',
    'toolbox.hub.entry.bowls.title': 'Singing Bowls',
    'toolbox.hub.entry.bowls.subtitle':
        'Eleven nature-tuned frequencies and four bowl voices.',
    'toolbox.hub.entry.locator.title': 'Sound Locator',
    'toolbox.hub.entry.locator.subtitle':
        'Use the phone mic to find and confirm sound sources.',
    'toolbox.hub.entry.beats.title': 'Focus Beats',
    'toolbox.hub.entry.beats.subtitle':
        'Rhythmic audio cues for timed focus sessions.',
    'toolbox.hub.entry.woodfish.title': 'Cyber Woodfish',
    'toolbox.hub.entry.woodfish.subtitle':
        'A digital wooden fish for mindful tapping and stress relief.',
    'toolbox.hub.entry.schulte.title': 'Schulte Grid',
    'toolbox.hub.entry.schulte.subtitle':
        'Classic attention training with speed and accuracy tracking.',
    'toolbox.hub.entry.breathing.title': 'Breathing Guide',
    'toolbox.hub.entry.breathing.subtitle':
        'Guided breathing exercises with visual pacing.',
    'toolbox.hub.entry.beads.title': 'Mindful Beads',
    'toolbox.hub.entry.beads.subtitle':
        'Gently slide each bead and settle your mind in a calming rhythm.',
    'toolbox.hub.entry.zen.title': 'Finger Sand Art',
    'toolbox.hub.entry.zen.subtitle':
        'Draw with your fingertip on sand — a pocket-sized moment of calm.',
    'toolbox.hub.entry.life.title': 'Life Tools',
    'toolbox.hub.entry.life.subtitle':
        'Practical utilities for daily routines.',
    'toolbox.hub.entry.crypto.title': 'Crypto Security',
    'toolbox.hub.entry.crypto.subtitle':
        'Encryption, hashing, and data security tools.',
    'toolbox.hub.entry.decision.title': 'Daily Decision',
    'toolbox.hub.entry.decision.subtitle':
        'Turn everyday indecision into randomized, editable, reviewable choices.',

    'toolbox.hub.quick.title': 'Quick Access',
    'toolbox.hub.quick.release_hint': 'Drop here to pin',
    'toolbox.hub.quick.manage': 'Manage',
    'toolbox.hub.quick.empty_hint':
        'Drag tools here for one-tap access. Tap "Manage" to pick your shortcuts.',
    'toolbox.hub.quick.choose_title': 'Choose quick entries',
    'toolbox.hub.quick.choose_desc':
        'Select the tools you want to appear in the Quick panel.',
    'toolbox.hub.quick.clear': 'Clear all',
    'toolbox.hub.quick.save': 'Save',

    // --- toolbox sleep (B4: sleep assistant, assessment, log, rhythm, rescue, wind-down, routine, low-effort) ---
    'toolbox.sleep.core.title': 'Sleep Support',
    'toolbox.sleep.core.start': 'Start',
    'toolbox.sleep.core.disabled': 'Sleep module is currently disabled.',
    'toolbox.sleep.core.disabledHint':
        'Enable the sleep module in settings to access this feature.',
    'toolbox.sleep.core.loading': 'Loading...',
    'toolbox.sleep.core.noData': 'No data yet',
    'toolbox.sleep.core.pause': 'Pause',
    'toolbox.sleep.core.resume': 'Resume',
    'toolbox.sleep.core.next': 'Next',
    'toolbox.sleep.core.stop': 'Stop',
    'toolbox.sleep.core.delete': 'Delete',

    'toolbox.sleep.assist.locatorPlan': 'Your sleep plan',
    'toolbox.sleep.assist.locatorPlanHint':
        'Track your current action plan and progress.',
    'toolbox.sleep.assist.locatorLoop': 'Sleep loop',
    'toolbox.sleep.assist.locatorLoopHint':
        'Quick actions for tonight and tomorrow morning.',
    'toolbox.sleep.assist.locatorMore': 'More actions',
    'toolbox.sleep.assist.locatorMoreHint':
        'Tools, advice, and deeper adjustments.',
    'toolbox.sleep.assist.locatorAdvice': 'Direct advice',
    'toolbox.sleep.assist.locatorAdviceHint':
        'Personalized suggestions based on your data.',
    'toolbox.sleep.assist.locatorTrend': '7-day trend',
    'toolbox.sleep.assist.locatorTrendHint':
        'See your sleep patterns over the past week.',
    'toolbox.sleep.assist.locatorScience': 'Science cards',
    'toolbox.sleep.assist.locatorScienceHint':
        'Evidence-based sleep knowledge and tips.',
    'toolbox.sleep.assist.subtitle':
        'Your personal sleep guide — assessment, tracking, and nightly support.',
    'toolbox.sleep.assist.morningSame': 'Same as usual',
    'toolbox.sleep.assist.morningWorse': 'Worse than usual',
    'toolbox.sleep.assist.morningBetter': 'Better than usual',
    'toolbox.sleep.assist.morningSavedSame': 'Morning check-in saved.',
    'toolbox.sleep.assist.morningSavedWorse':
        'Morning check-in saved — take it easy today.',
    'toolbox.sleep.assist.morningSavedBetter':
        'Morning check-in saved — great start!',
    'toolbox.sleep.assist.recentRescue': 'Recent night rescue',
    'toolbox.sleep.assist.leftBedRecorded': 'Left-bed event recorded.',
    'toolbox.sleep.assist.tinyRoutineUsed':
        'Tiny wind-down routine used recently.',
    'toolbox.sleep.assist.lateScreenClue':
        'Late screen exposure detected in recent logs.',
    'toolbox.sleep.assist.shorterVersion': 'SHORT',
    'toolbox.sleep.assist.avgSleep': 'Average sleep',
    'toolbox.sleep.assist.avgEfficiency': 'Efficiency',
    'toolbox.sleep.assist.morningEnergy': 'Morning energy',
    'toolbox.sleep.assist.track': 'Track',
    'toolbox.sleep.assist.darkMode': 'Night mode',
    'toolbox.sleep.assist.darkModeHint':
        'Dim the screen and reduce blue light for evening use.',
    'toolbox.sleep.assist.currentPlan': 'Current plan',
    'toolbox.sleep.assist.currentPlanHint':
        'Your active sleep improvement track.',
    'toolbox.sleep.assist.sleepLoop': 'Sleep loop',
    'toolbox.sleep.assist.sleepLoopSub':
        'Tonight and tomorrow morning in one flow.',
    'toolbox.sleep.assist.moreActions': 'More actions',
    'toolbox.sleep.assist.moreActionsHint':
        'Tools, reports, and deeper settings.',
    'toolbox.sleep.assist.whiteNoise': 'White noise',
    'toolbox.sleep.assist.morningLightTimer': 'Morning light timer',
    'toolbox.sleep.assist.caffeineCutoff': 'Caffeine cutoff',
    'toolbox.sleep.assist.min90': '90-min cycles',
    'toolbox.sleep.assist.breathing': 'Breathing',
    'toolbox.sleep.assist.music': 'Soothing music',
    'toolbox.sleep.assist.bowls': 'Singing bowls',
    'toolbox.sleep.assist.zenSand': 'Finger sand art',
    'toolbox.sleep.assist.directAdvice': 'Direct advice',
    'toolbox.sleep.assist.directAdviceSub':
        'Personalized suggestions from your sleep data.',
    'toolbox.sleep.assist.trend7': '7-day trend',
    'toolbox.sleep.assist.trend7Sub':
        'How your sleep has changed over the past week.',
    'toolbox.sleep.assist.setDirection': 'Set direction',
    'toolbox.sleep.assist.setDirectionHint':
        'Choose a sleep goal and get a personalized plan.',
    'toolbox.sleep.assist.windDown': 'Wind-down routine',
    'toolbox.sleep.assist.windDownHint':
        'A step-by-step evening routine to prepare for sleep.',
    'toolbox.sleep.assist.nightRescue': 'Night rescue',
    'toolbox.sleep.assist.nightRescueHint':
        'What to do when you wake up in the middle of the night.',
    'toolbox.sleep.assist.dayAnchor': 'Day anchor',
    'toolbox.sleep.assist.dayAnchorHint':
        'Morning light and activity to stabilize your rhythm.',
    'toolbox.sleep.assist.tinyLog': 'Tiny log',
    'toolbox.sleep.assist.tinyLogHint':
        'A 30-second nightly sleep log with minimal effort.',
    'toolbox.sleep.assist.weeklyReview': 'Weekly review',
    'toolbox.sleep.assist.weeklyReviewHint':
        'Look back at your sleep patterns and adjust.',
    'toolbox.sleep.assist.scienceCard': 'Science',
    'toolbox.sleep.assist.scienceCardSub':
        'Evidence-based knowledge about sleep.',
    'toolbox.sleep.assist.assessmentCard': 'Assessment',
    'toolbox.sleep.assist.assessmentCardSub':
        'Evaluate your sleep concerns and risk factors.',
    'toolbox.sleep.assist.logCard': 'Daily log',
    'toolbox.sleep.assist.logCardSub':
        'Track each night with a structured sleep diary.',
    'toolbox.sleep.assist.routineCard': 'Wind-down',
    'toolbox.sleep.assist.routineCardSub':
        'Build and run your evening wind-down routine.',
    'toolbox.sleep.assist.rescueCard': 'Night rescue',
    'toolbox.sleep.assist.rescueCardSub':
        'Guided support when you wake up at night.',
    'toolbox.sleep.assist.rhythmCard': 'Day rhythm',
    'toolbox.sleep.assist.rhythmCardSub':
        'A 7-day program to stabilize your circadian rhythm.',
    'toolbox.sleep.assist.reportCard': 'Report',
    'toolbox.sleep.assist.reportCardSub':
        'Visualize trends and patterns over time.',
    'toolbox.sleep.assist.collect3':
        'Collect 3 nights of data to unlock personalized patterns.',
    'toolbox.sleep.assist.busyMind': 'Racing thoughts',
    'toolbox.sleep.assist.lateScreensTag': 'Late screens',
    'toolbox.sleep.assist.setDirectionBtn': 'Set direction',
    'toolbox.sleep.assist.assessment2min': 'Sleep assessment',
    'toolbox.sleep.assist.assessmentIntro':
        'A short 2-minute questionnaire to understand your sleep situation and get personalized guidance.',
    'toolbox.sleep.assist.startAssessment': 'Start assessment',
    'toolbox.sleep.assist.rescueFirst': 'Night rescue first',
    'toolbox.sleep.assist.smallFirst': 'Start small',
    'toolbox.sleep.assist.autoPlan': 'Auto-plan after assessment',
    'toolbox.sleep.assist.inProgress': 'In progress',
    'toolbox.sleep.assist.continueRoutine': 'Continue your wind-down routine',
    'toolbox.sleep.assist.continueRoutineHint':
        'Your evening routine is already set up. Pick up where you left off.',
    'toolbox.sleep.assist.backToRoutine': 'Back to routine',
    'toolbox.sleep.assist.noNewTask': 'No new tasks tonight',
    'toolbox.sleep.assist.nightMode': 'Night mode',
    'toolbox.sleep.assist.nightModeHint': 'Middle of the night',
    'toolbox.sleep.assist.nightModeDesc':
        'Keep stimulation low. Avoid screens, clocks, and bright lights.',
    'toolbox.sleep.assist.openRescue': 'Open night rescue',
    'toolbox.sleep.assist.leaveBedAid': 'Leave bed if awake 20+ min',
    'toolbox.sleep.assist.lowStim': 'Low stimulation',
    'toolbox.sleep.assist.noClock': 'No clock checking',
    'toolbox.sleep.assist.tonightStep': 'Tonight\'s step',
    'toolbox.sleep.assist.startTinyRoutine': 'Start tiny wind-down',
    'toolbox.sleep.assist.startTinyRoutineHint':
        'A minimal 3-step routine you can do even when exhausted.',
    'toolbox.sleep.assist.oneTapStart': 'One-tap start',
    'toolbox.sleep.assist.min90Guide': '90-min cycle guide',
    'toolbox.sleep.assist.min8': '8-minute tiny routine',
    'toolbox.sleep.assist.dayAnchorTitle': 'Morning anchor',
    'toolbox.sleep.assist.dayAnchorDesc': 'Get bright light',
    'toolbox.sleep.assist.dayAnchorScenarioHint':
        'Expose yourself to natural or bright light within 30 minutes of waking to anchor your circadian rhythm.',
    'toolbox.sleep.assist.startLightTimer': 'Start light timer',
    'toolbox.sleep.assist.logLastNight': 'Log last night',
    'toolbox.sleep.assist.min10to20': '10-20 min',
    'toolbox.sleep.assist.logPending': 'Log pending',
    'toolbox.sleep.assist.minimalLog': 'Minimal log',
    'toolbox.sleep.assist.minimalLogHint': 'Log last night',
    'toolbox.sleep.assist.minimalLogDesc':
        'A quick 30-second log entry to capture the essentials of last night.',
    'toolbox.sleep.assist.logNow': 'Log now',
    'toolbox.sleep.assist.caffeineLine': 'Caffeine timeline',
    'toolbox.sleep.assist.lowEffort': 'Low effort',
    'toolbox.sleep.assist.trendFirst': 'Trends first',
    'toolbox.sleep.assist.controlOneVar': 'Control one variable',
    'toolbox.sleep.assist.controlOneVarHint': 'Caffeine cutoff',
    'toolbox.sleep.assist.controlOneVarDesc':
        'Calculate your personal caffeine cutoff time based on your typical bedtime.',
    'toolbox.sleep.assist.calcCutoff': 'Calculate cutoff',
    'toolbox.sleep.assist.dayRhythm': 'Day rhythm program',
    'toolbox.sleep.assist.lateYesterday': 'Late caffeine yesterday',
    'toolbox.sleep.assist.caffeineSensitive': 'Caffeine sensitive',
    'toolbox.sleep.assist.nextCycle': 'Next cycle',
    'toolbox.sleep.assist.nextCycleHint': 'Check upcoming sleep windows',
    'toolbox.sleep.assist.nextCycleDesc':
        'Based on 90-minute sleep cycles, see the best times to go to bed or wake up.',
    'toolbox.sleep.assist.openReport': 'Open report',
    'toolbox.sleep.assist.tonightRoutine': 'Tonight\'s routine',
    'toolbox.sleep.assist.snoringRisk': 'Snoring risk',
    'toolbox.sleep.assist.quickLocate': 'Quick locate',
    'toolbox.sleep.assist.openDrawer': 'Open drawer',
    'toolbox.sleep.assist.instantTools': 'Instant tools',
    'toolbox.sleep.assist.noLogsYet': 'No logs yet',
    'toolbox.sleep.assist.noLogsHint':
        'Start logging your sleep to see trends and get personalized advice.',
    'toolbox.sleep.assist.startLogging': 'Start logging',
    'toolbox.sleep.assist.lateCaffeine': 'Late caffeine',
    'toolbox.sleep.assist.lateScreens': 'Late screens',
    'toolbox.sleep.assist.morningLightDone': 'Morning light',
    'toolbox.sleep.assist.jumpTitle': 'Quick actions',
    'toolbox.sleep.assist.jumpDesc':
        'Jump directly to what you need right now.',
    'toolbox.sleep.assist.noInputStarts': 'No-input start',
    'toolbox.sleep.assist.noInputStartsHint':
        'Just tap and go — no setup needed.',
    'toolbox.sleep.assist.imTired': 'I\'m tired',
    'toolbox.sleep.assist.bedtimeScene': 'Bedtime scene',
    'toolbox.sleep.assist.sleepNow': 'Sleep now',
    'toolbox.sleep.assist.tiny8min': '8-minute tiny routine',
    'toolbox.sleep.assist.awakeNow': 'Awake now',
    'toolbox.sleep.assist.lowStimRescue': 'Low-stimulation rescue',
    'toolbox.sleep.assist.audioBed': 'Audio bed',
    'toolbox.sleep.assist.noiseOrRain': 'White noise or rain sounds',
    'toolbox.sleep.assist.logLater': 'Log later',
    'toolbox.sleep.assist.log30sec': '30-sec log',
    'toolbox.sleep.assist.nightWakeBranches': 'Night wake branches',
    'toolbox.sleep.assist.noPlanYet': 'No plan yet',
    'toolbox.sleep.assist.noPlanHint':
        'Complete the sleep assessment to get a personalized plan.',
    'toolbox.sleep.assist.latestNight': 'Latest night',
    'toolbox.sleep.assist.sleep': 'Sleep',
    'toolbox.sleep.assist.efficiency': 'Efficiency',
    'toolbox.sleep.assist.wakeUps': 'Wake-ups',
    'toolbox.sleep.assist.energy': 'Energy',

    'toolbox.sleep.assessment.saved': 'Assessment saved.',
    'toolbox.sleep.assessment.moduleDisabled':
        'Sleep module is disabled. Enable it in settings to access this feature.',
    'toolbox.sleep.assessment.title': 'Sleep assessment',
    'toolbox.sleep.assessment.intro':
        'A short questionnaire to understand your sleep patterns and get personalized guidance.',
    'toolbox.sleep.assessment.mainConcerns': 'Main concerns',
    'toolbox.sleep.assessment.baselineSchedule': 'Baseline schedule',
    'toolbox.sleep.assessment.typicalBedtime': 'Typical bedtime',
    'toolbox.sleep.assessment.typicalWakeTime': 'Typical wake time',
    'toolbox.sleep.assessment.currentGoal': 'Current sleep goal',
    'toolbox.sleep.assessment.goalHint':
        'e.g., Fall asleep faster, wake up less, feel more rested',
    'toolbox.sleep.assessment.riskAndContext': 'Risk and context',
    'toolbox.sleep.assessment.racingThoughts': 'Racing thoughts at bedtime',
    'toolbox.sleep.assessment.caffeineSensitive': 'Caffeine sensitivity',
    'toolbox.sleep.assessment.snoringRisk': 'Snoring or breathing pauses',
    'toolbox.sleep.assessment.bedroomBright': 'Bedroom too bright',
    'toolbox.sleep.assessment.bedroomNoisy': 'Bedroom too noisy',
    'toolbox.sleep.assessment.bedroomTemp': 'Bedroom too hot or cold',
    'toolbox.sleep.assessment.shiftWork': 'Shift work or irregular schedule',
    'toolbox.sleep.assessment.digestiveDiscomfort':
        'Digestive discomfort at night',
    'toolbox.sleep.assessment.nightmares': 'Frequent nightmares',
    'toolbox.sleep.assessment.directAdvice': 'Personalized suggestions',
    'toolbox.sleep.assessment.save': 'Save assessment',

    'toolbox.sleep.log.saved': 'Log saved.',
    'toolbox.sleep.log.title': 'Daily sleep log',
    'toolbox.sleep.log.intro':
        'A structured sleep diary to track each night in detail.',
    'toolbox.sleep.log.sleep': 'Sleep',
    'toolbox.sleep.log.efficiency': 'Efficiency',
    'toolbox.sleep.log.morningEnergy': 'Morning energy',
    'toolbox.sleep.log.editingDate': 'Editing date',
    'toolbox.sleep.log.log30sec': '30-second log',
    'toolbox.sleep.log.log30secHint':
        'Quick entry with presets for common patterns.',
    'toolbox.sleep.log.presetOkay': 'Okay night',
    'toolbox.sleep.log.presetShort': 'Short night',
    'toolbox.sleep.log.presetWokeOften': 'Woke often',
    'toolbox.sleep.log.saveCurrent': 'Save current log',
    'toolbox.sleep.log.timeline': 'Timeline',
    'toolbox.sleep.log.bedtime': 'Bedtime',
    'toolbox.sleep.log.lightsOff': 'Lights off',
    'toolbox.sleep.log.sleepOnset': 'Sleep onset',
    'toolbox.sleep.log.finalWake': 'Final wake',
    'toolbox.sleep.log.outOfBed': 'Out of bed',
    'toolbox.sleep.log.commonValues': 'Common values',
    'toolbox.sleep.log.estimatedSleepMinutes': 'Estimated sleep (minutes)',
    'toolbox.sleep.log.sleepLatency': 'Sleep latency (minutes)',
    'toolbox.sleep.log.wakeCount': 'Wake count',
    'toolbox.sleep.log.fourPlus': '4+',
    'toolbox.sleep.log.wakeTotal': 'Wake total (minutes)',
    'toolbox.sleep.log.napMinutes': 'Nap (minutes)',
    'toolbox.sleep.log.windDownMinutes': 'Wind-down (minutes)',
    'toolbox.sleep.log.contextNotes': 'Context notes',
    'toolbox.sleep.log.notesHint': 'Anything unusual about tonight...',
    'toolbox.sleep.log.overtime': 'Overtime',
    'toolbox.sleep.log.roomHot': 'Room hot',
    'toolbox.sleep.log.noise': 'Noise',
    'toolbox.sleep.log.travel': 'Travel',
    'toolbox.sleep.log.reflux': 'Reflux',
    'toolbox.sleep.log.tagDreams': 'Dreams',
    'toolbox.sleep.log.subjectiveScores': 'Subjective scores',
    'toolbox.sleep.log.daytimeSleepiness': 'Daytime sleepiness',
    'toolbox.sleep.log.stressPeak': 'Stress peak',
    'toolbox.sleep.log.worryLoad': 'Worry load',
    'toolbox.sleep.log.behaviorEnv': 'Behavior & environment',
    'toolbox.sleep.log.heavyDinnerHint': 'Heavy dinner within 2 hours of sleep',
    'toolbox.sleep.log.intenseExerciseHint':
        'Intense exercise within 3 hours of sleep',
    'toolbox.sleep.log.hotBathHint':
        'Hot bath or shower within 2 hours of sleep',
    'toolbox.sleep.log.stretchingHint': 'Stretching or yoga before bed',
    'toolbox.sleep.log.bedroomHotHint': 'Bedroom felt too hot',
    'toolbox.sleep.log.bedroomBrightHint': 'Bedroom felt too bright',
    'toolbox.sleep.log.bedroomNoisyHint': 'Bedroom felt too noisy',
    'toolbox.sleep.log.practicalTools': 'Practical tools',
    'toolbox.sleep.log.whiteNoise': 'White noise',
    'toolbox.sleep.log.caffeineCutoff': 'Caffeine cutoff',
    'toolbox.sleep.log.directAdvice': 'Personalized suggestions',
    'toolbox.sleep.log.saveLog': 'Save log',

    'toolbox.sleep.rhythm.title': 'Day rhythm',
    'toolbox.sleep.rhythm.intro':
        'A 7-day program to stabilize your circadian rhythm through morning light, caffeine timing, and evening habits.',
    'toolbox.sleep.rhythm.currentDay': 'Current day',
    'toolbox.sleep.rhythm.completed': 'Completed',
    'toolbox.sleep.rhythm.programDone': 'Program complete',
    'toolbox.sleep.rhythm.completeToday': 'Complete today',
    'toolbox.sleep.rhythm.tools': 'Tools',
    'toolbox.sleep.rhythm.lightTimer': 'Light timer',
    'toolbox.sleep.rhythm.caffeineCutoff': 'Caffeine cutoff',
    'toolbox.sleep.rhythm.leaveBedAid': 'Leave bed aid',
    'toolbox.sleep.rhythm.startProgram': 'Start program',
    'toolbox.sleep.rhythm.logOneNight': 'Log one night first',
    'toolbox.sleep.rhythm.needOneLog':
        'You need at least one sleep log entry to start the rhythm program.',
    'toolbox.sleep.rhythm.morningLight': 'Morning light',
    'toolbox.sleep.rhythm.morningLightDone': 'Morning light done',
    'toolbox.sleep.rhythm.morningLightMissed': 'Morning light missed',
    'toolbox.sleep.rhythm.done': 'Done',
    'toolbox.sleep.rhythm.missed': 'Missed',
    'toolbox.sleep.rhythm.lateCaffeine': 'Late caffeine',
    'toolbox.sleep.rhythm.noLateCaffeine': 'No late caffeine',
    'toolbox.sleep.rhythm.late': 'Late',
    'toolbox.sleep.rhythm.stable': 'Stable',
    'toolbox.sleep.rhythm.napMgmt': 'Nap management',
    'toolbox.sleep.rhythm.napLong': 'Nap too long',
    'toolbox.sleep.rhythm.napOk': 'Nap OK',
    'toolbox.sleep.rhythm.eveningStim': 'Evening stimulation',
    'toolbox.sleep.rhythm.eveningStimHigh': 'High evening stimulation',
    'toolbox.sleep.rhythm.eveningStimOk': 'Evening stimulation OK',
    'toolbox.sleep.rhythm.high': 'High',
    'toolbox.sleep.rhythm.ok': 'OK',
    'toolbox.sleep.rhythm.directAdvice': 'Personalized suggestions',
    'toolbox.sleep.rhythm.active': 'Active',

    'toolbox.sleep.rescue.saved': 'Night rescue event saved.',
    'toolbox.sleep.rescue.title': 'Night rescue',
    'toolbox.sleep.rescue.intro':
        'What to do when you wake up in the middle of the night. Choose your state and get step-by-step guidance.',
    'toolbox.sleep.rescue.chooseState': 'Choose your state',
    'toolbox.sleep.rescue.currentGuidance': 'Current guidance',
    'toolbox.sleep.rescue.chooseFirst':
        'Choose your current state first to get tailored guidance.',
    'toolbox.sleep.rescue.beginGuide': 'Begin guidance',
    'toolbox.sleep.rescue.leaveBedAid': 'Leave bed aid',
    'toolbox.sleep.rescue.saveEvent': 'Save event',
    'toolbox.sleep.rescue.guessedTrigger': 'Guessed trigger',
    'toolbox.sleep.rescue.actionTaken': 'Action taken',
    'toolbox.sleep.rescue.extraNotes': 'Extra notes',
    'toolbox.sleep.rescue.leftBed': 'Left bed',
    'toolbox.sleep.rescue.recentEvents': 'Recent events',
    'toolbox.sleep.rescue.action': 'Action',
    'toolbox.sleep.rescue.trigger': 'Trigger',

    'toolbox.sleep.low.tonightGoal': 'Tonight\'s goal',
    'toolbox.sleep.low.tonightGoalHint':
        'e.g., In bed by 11, no screens after 10',
    'toolbox.sleep.low.wakeTap': 'Tap when you wake up',
    'toolbox.sleep.low.wakeTapDone': 'Morning check-in recorded',
    'toolbox.sleep.low.wakeTapHint': 'How did you sleep?',
    'toolbox.sleep.low.same': 'Same',
    'toolbox.sleep.low.worse': 'Worse',
    'toolbox.sleep.low.better': 'Better',
    'toolbox.sleep.low.openFullLog': 'Open full log',
    'toolbox.sleep.low.bedtimeScene': 'Bedtime scene',
    'toolbox.sleep.low.bedtimeSceneHint':
        'Dim lights, quiet space, phone on dark mode.',
    'toolbox.sleep.low.switchDark': 'Switch to dark',
    'toolbox.sleep.low.selectTiny': 'Select tiny routine',
    'toolbox.sleep.low.enterRunner': 'Enter routine runner',
    'toolbox.sleep.low.confirmStart': 'Confirm & start',
    'toolbox.sleep.low.chooseAudio': 'Choose audio',
    'toolbox.sleep.low.notNow': 'Not now',
    'toolbox.sleep.low.imTired': 'I\'m tired',
    'toolbox.sleep.low.imTiredHint':
        'Let\'s get you to bed with minimal effort.',
    'toolbox.sleep.low.dimLights': 'Dim lights',
    'toolbox.sleep.low.movePhoneAway': 'Phone away',
    'toolbox.sleep.low.parkWorry': 'Park worry',
    'toolbox.sleep.low.start8min': 'Start 8 min',
    'toolbox.sleep.low.audioOnly': 'Audio only',
    'toolbox.sleep.low.wokeAtNight': 'Woke at night',
    'toolbox.sleep.low.do3Steps': 'Do 3 steps',

    'toolbox.sleep.routine.title': 'Wind-down editor',
    'toolbox.sleep.routine.intro':
        'Build your personalized evening wind-down routine.',
    'toolbox.sleep.routine.templateName': 'Template name',
    'toolbox.sleep.routine.newStep': 'New step',
    'toolbox.sleep.routine.addStep': 'Add step',
    'toolbox.sleep.routine.saveTemplate': 'Save template',
    'toolbox.sleep.routine.step': 'Step',
    'toolbox.sleep.routine.stepType': 'Step type',
    'toolbox.sleep.routine.stepLabel': 'Step label',
    'toolbox.sleep.routine.stepDuration': 'Duration',

    'toolbox.sleep.winddown.unloadSaved': 'Thought unload saved.',
    'toolbox.sleep.winddown.wakeGetLight': 'Wake & get light',
    'toolbox.sleep.winddown.startWindDown': 'Start wind-down',
    'toolbox.sleep.winddown.reminderMorning': 'Morning reminder',
    'toolbox.sleep.winddown.reminderEvening': 'Evening reminder',
    'toolbox.sleep.winddown.reminderWakeCreated': 'Wake reminder created.',
    'toolbox.sleep.winddown.reminderBedCreated': 'Bedtime reminder created.',
    'toolbox.sleep.winddown.title': 'Wind-down',
    'toolbox.sleep.winddown.intro':
        'A guided evening routine to prepare your body and mind for sleep.',
    'toolbox.sleep.winddown.templates': 'Templates',
    'toolbox.sleep.winddown.templatesHint':
        'Choose a pre-built routine or create your own.',
    'toolbox.sleep.winddown.new': 'New',
    'toolbox.sleep.winddown.runner': 'Runner',
    'toolbox.sleep.winddown.notStarted': 'Not started',
    'toolbox.sleep.winddown.start': 'Start',
    'toolbox.sleep.winddown.unloadThoughts': 'Unload thoughts',
    'toolbox.sleep.winddown.topThought': 'Top thought on your mind',
    'toolbox.sleep.winddown.gentlerReframe': 'Gentler reframe',
    'toolbox.sleep.winddown.intensity': 'Intensity',
    'toolbox.sleep.winddown.saveUnload': 'Save unload',
    'toolbox.sleep.winddown.quickTools': 'Quick tools',
    'toolbox.sleep.winddown.whiteNoise': 'White noise',
    'toolbox.sleep.winddown.cycle90min': '90-min cycles',
    'toolbox.sleep.winddown.bedReminder': 'Bed reminder',
    'toolbox.sleep.winddown.wakeAlarm': 'Wake alarm',
    'toolbox.sleep.winddown.soothingAudio': 'Soothing audio',
    'toolbox.sleep.winddown.recentUnload': 'Recent unloads',
    'toolbox.sleep.winddown.reframe': 'Reframe',
    'toolbox.sleep.winddown.stepChecklist': 'Step checklist',
    'toolbox.sleep.winddown.stepHint': 'Tap each step as you complete it.',
    'toolbox.sleep.winddown.builtIn': 'Built-in',
    'toolbox.sleep.winddown.currentlySelected': 'Currently selected',

    'toolbox.sleep.support.issue.hard_fall_asleep': 'Difficulty falling asleep',
    'toolbox.sleep.support.issue.frequent_awakenings': 'Frequent awakenings',
    'toolbox.sleep.support.issue.early_awakening': 'Early awakening',
    'toolbox.sleep.support.issue.non_restorative': 'Non-restorative sleep',
    'toolbox.sleep.support.issue.irregular_schedule': 'Irregular schedule',
    'toolbox.sleep.support.issue.racing_thoughts': 'Racing thoughts',
    'toolbox.sleep.support.issue.daytime_sleepiness': 'Daytime sleepiness',
    'toolbox.sleep.support.issue.snoring_risk': 'Snoring risk',
    'toolbox.sleep.support.issue.pain_tension': 'Pain or tension',
    'toolbox.sleep.support.risk.low': 'Low risk',
    'toolbox.sleep.support.risk.mild': 'Mild risk',
    'toolbox.sleep.support.risk.medium': 'Medium risk',
    'toolbox.sleep.support.risk.high': 'High risk',
    'toolbox.sleep.support.mode.brief': 'Brief awakening',
    'toolbox.sleep.support.mode.fully_awake': 'Fully awake',
    'toolbox.sleep.support.mode.racing_thoughts': 'Racing thoughts',
    'toolbox.sleep.support.mode.body_activated': 'Body activated',
    'toolbox.sleep.support.mode.temperature': 'Temperature discomfort',
    'toolbox.sleep.support.mode_body.brief':
        'You woke briefly and want to fall back asleep quickly.',
    'toolbox.sleep.support.mode_body.fully_awake':
        'You are wide awake and unable to fall back asleep.',
    'toolbox.sleep.support.mode_body.racing_thoughts':
        'Your mind is busy and keeps spinning.',
    'toolbox.sleep.support.mode_body.body_activated':
        'Your body feels tense, restless, or activated.',
    'toolbox.sleep.support.mode_body.temperature':
        'You feel too hot or too cold.',
    'toolbox.sleep.support.track.observation': 'Observation',
    'toolbox.sleep.support.track.wind_down': 'Wind-down',
    'toolbox.sleep.support.track.insomnia': 'Insomnia support',
    'toolbox.sleep.support.track.rhythm_reset': 'Rhythm reset',
    'toolbox.sleep.support.track.environment': 'Environment fix',
    'toolbox.sleep.support.track.recovery': 'Daytime recovery',
    'toolbox.sleep.support.program.rhythm_7': '7-day rhythm reset',
    'toolbox.sleep.support.program.reset_14': '14-day sleep reset',
    'toolbox.sleep.support.program.starter': 'Insomnia starter',
    'toolbox.sleep.support.program_body.rhythm_7':
        'A 7-day program to stabilize your sleep-wake rhythm through light exposure and schedule anchoring.',
    'toolbox.sleep.support.program_body.reset_14':
        'A two-week comprehensive sleep reset with daily guidance and habit tracking.',
    'toolbox.sleep.support.program_body.starter':
        'A gentle 5-step starter program for managing occasional insomnia.',
    'toolbox.sleep.support.step.dim_lights': 'Dim lights',
    'toolbox.sleep.support.step.stop_screens': 'Stop screens',
    'toolbox.sleep.support.step.prepare_room': 'Prepare room',
    'toolbox.sleep.support.step.unload_thoughts': 'Unload thoughts',
    'toolbox.sleep.support.step.breathing': 'Breathing',
    'toolbox.sleep.support.step.stretch': 'Stretch',
    'toolbox.sleep.support.step.warm_bath': 'Warm bath',
    'toolbox.sleep.support.step.white_noise': 'White noise',
    'toolbox.sleep.support.step.soothing_audio': 'Soothing audio',
    'toolbox.sleep.support.step.body_scan': 'Body scan',
    'toolbox.sleep.support.step.go_to_bed': 'Go to bed',
    'toolbox.sleep.support.template.tiny': 'Tiny shutdown',
    'toolbox.sleep.support.template.quick_reset': 'Quick reset',
    'toolbox.sleep.support.template.standard': 'Standard wind-down',
    'toolbox.sleep.support.template_step.tiny1':
        'Dim only the lights you can reach',
    'toolbox.sleep.support.template_step.tiny2': 'Put the screen face down',
    'toolbox.sleep.support.template_step.tiny3': 'Park one loud thought',
    'toolbox.sleep.support.template_step.tiny4': 'Longer exhale breathing',
    'toolbox.sleep.support.template_step.tiny5':
        'Get into bed without adding tasks',
    'toolbox.sleep.support.intensity.very_low': 'Very low',
    'toolbox.sleep.support.intensity.low': 'Low',
    'toolbox.sleep.support.intensity.moderate': 'Moderate',
    'toolbox.sleep.support.intensity.high': 'High',
    'toolbox.sleep.support.intensity.very_high': 'Very high',
    'toolbox.sleep.support.frequency.rare': 'Rare',
    'toolbox.sleep.support.frequency.sometimes': 'Sometimes',
    'toolbox.sleep.support.frequency.often': 'Often',
    'toolbox.sleep.support.frequency.frequent': 'Frequent',
    'toolbox.sleep.support.frequency.daily': 'Daily',
    'toolbox.sleep.support.bool.recorded': 'Recorded',
    'toolbox.sleep.support.bool.not_recorded': 'Not recorded',
    'toolbox.sleep.support.burden.low': 'Low burden',
    'toolbox.sleep.support.burden.medium': 'Medium burden',
    'toolbox.sleep.support.burden.high': 'High burden',
    'toolbox.sleep.support.factor.stress': 'Stress load',
    'toolbox.sleep.support.factor.screen': 'Screen dependence',
    'toolbox.sleep.support.factor.late_work': 'Late work frequency',
    'toolbox.sleep.support.factor.late_exercise': 'Late exercise frequency',
    'toolbox.sleep.support.factor.pain': 'Pain impact',
    'toolbox.sleep.support.factor.snoring': 'Snoring risk',
    'toolbox.sleep.support.factor_hint.stress':
        'How much stress impacts your sleep',
    'toolbox.sleep.support.factor_hint.screen':
        'How screen use affects your bedtime',
    'toolbox.sleep.support.factor_hint.late_work':
        'How often work keeps you up late',
    'toolbox.sleep.support.factor_hint.late_exercise':
        'How often you exercise close to bedtime',
    'toolbox.sleep.support.factor_hint.pain':
        'How much pain interferes with sleep',
    'toolbox.sleep.support.factor_hint.snoring':
        'Whether snoring or breathing pauses occur',
    'toolbox.sleep.support.daily.late_caffeine': 'Caffeine after cutoff',
    'toolbox.sleep.support.daily.late_screens': 'Late screen exposure',
    'toolbox.sleep.support.daily.alcohol': 'Alcohol at night',
    'toolbox.sleep.support.daily.morning_light': 'Morning light done',
    'toolbox.sleep.support.daily.heavy_dinner': 'Heavy dinner',
    'toolbox.sleep.support.daily.late_exercise': 'Intense exercise late',
    'toolbox.sleep.support.daily.warm_bath': 'Hot bath or shower',
    'toolbox.sleep.support.daily.stretching': 'Stretching done',
    'toolbox.sleep.support.daily.white_noise': 'White noise used',
    'toolbox.sleep.support.daily.room_hot': 'Bedroom too hot',
    'toolbox.sleep.support.daily.room_bright': 'Bedroom too bright',
    'toolbox.sleep.support.daily.room_noisy': 'Bedroom too noisy',
    'toolbox.sleep.support.daily.clock_checking': 'Clock checking',
    'toolbox.sleep.support.daily_hint.caffeine':
        'Coffee, tea, or energy drinks after your cutoff',
    'toolbox.sleep.support.daily_hint.screens':
        'Phone, tablet, or computer late in the evening',
    'toolbox.sleep.support.daily_hint.alcohol':
        'Any alcohol consumed close to bedtime',
    'toolbox.sleep.support.daily_hint.morning_light':
        'Got natural or bright light within 30 minutes of waking',
    'toolbox.sleep.support.daily_hint.clock':
        'Checked the clock repeatedly during the night',
    'toolbox.sleep.support.daily_hint.white_noise':
        'Used white noise, fan, or ambient sound',

    // --- toolbox sleep report (B4 continued) ---
    'toolbox.sleep.report.title': 'Sleep report',
    'toolbox.sleep.report.intro':
        'Visualize your sleep trends and patterns over time.',
    'toolbox.sleep.report.noData': 'No data yet',
    'toolbox.sleep.report.noDataHint':
        'Log at least one night to see your sleep report.',
    'toolbox.sleep.report.range': 'Range',
    'toolbox.sleep.report.range7d': '7 days',
    'toolbox.sleep.report.range14d': '14 days',
    'toolbox.sleep.report.avgSleep': 'Average sleep',
    'toolbox.sleep.report.avgEfficiency': 'Average efficiency',
    'toolbox.sleep.report.morningEnergy': 'Morning energy',
    'toolbox.sleep.report.daytimeSleepiness': 'Daytime sleepiness',
    'toolbox.sleep.report.sleepDurationTrend': 'Sleep duration trend',
    'toolbox.sleep.report.sleepDurationTrendHint':
        'How your total sleep time has changed.',
    'toolbox.sleep.report.efficiencyTrend': 'Efficiency trend',
    'toolbox.sleep.report.efficiencyTrendHint':
        'How your sleep efficiency has changed.',
    'toolbox.sleep.report.energyTrend': 'Morning energy trend',
    'toolbox.sleep.report.energyTrendHint': 'How refreshed you feel on waking.',
    'toolbox.sleep.report.wakeBurden': 'Wake burden',
    'toolbox.sleep.report.wakeBurdenHint':
        'Total time spent awake during the night.',
    'toolbox.sleep.report.lateCaffeineDays': 'Late caffeine days',
    'toolbox.sleep.report.lateCaffeineDaysHint':
        'Nights where caffeine was consumed after cutoff.',
    'toolbox.sleep.report.lateScreenDays': 'Late screen days',
    'toolbox.sleep.report.lateScreenDaysHint':
        'Nights with screen exposure close to bedtime.',
    'toolbox.sleep.report.morningLightDays': 'Morning light days',
    'toolbox.sleep.report.morningLightDaysHint':
        'Mornings where you got natural bright light.',
    'toolbox.sleep.report.envIssueDays': 'Environment issues',
    'toolbox.sleep.report.envIssueDaysHint':
        'Nights with bedroom environment problems.',
    'toolbox.sleep.report.nextCycleAdvice':
        'Check 90-min cycle windows for tonight.',

    // --- toolbox sleep science ---
    'toolbox.sleep.science.title': 'Sleep science',
    'toolbox.sleep.science.intro':
        'Evidence-based sleep knowledge, references, and practical principles.',
    'toolbox.sleep.science.disclaimer':
        'This information is for educational purposes and does not replace medical advice. Consult a healthcare professional for persistent sleep issues.',
    'toolbox.sleep.science.anchorRhythm': 'Anchor your rhythm',
    'toolbox.sleep.science.anchorRhythmBody':
        'Morning light within 30 minutes of waking is the strongest signal for setting your internal clock. Even 10 minutes outdoors makes a measurable difference.',
    'toolbox.sleep.science.keepBedForSleep': 'Keep bed for sleep',
    'toolbox.sleep.science.keepBedForSleepBody':
        'If you lie awake for 20+ minutes, get up and do something low-stimulation until sleepy. This re-strengthens the bed-sleep association.',
    'toolbox.sleep.science.logLightly': 'Log lightly',
    'toolbox.sleep.science.logLightlyBody':
        'A 30-second sleep diary entry is enough to reveal patterns over time. Perfection is not needed — consistency matters more.',
    'toolbox.sleep.science.referenceIndex': 'Reference index',
    'toolbox.sleep.science.referenceSource': 'Source',
    'toolbox.sleep.science.refGroupCbti': 'CBT-I guidelines',
    'toolbox.sleep.science.refGroupCbtiBody':
        'Stimulus control, sleep restriction, and cognitive techniques for chronic insomnia.',
    'toolbox.sleep.science.refGroupRhythm': 'Circadian science',
    'toolbox.sleep.science.refGroupRhythmBody':
        'Light exposure, melatonin timing, and body clock fundamentals.',
    'toolbox.sleep.science.refGroupMedical': 'Medical screening',
    'toolbox.sleep.science.refGroupMedicalBody':
        'When to consider sleep apnea screening, RLS, or specialist referral.',
    'toolbox.sleep.science.refGroupPopular': 'Popular evidence summaries',
    'toolbox.sleep.science.refGroupPopularBody':
        'Translations of research for everyday sleep habits.',
    'toolbox.sleep.science.riskFirst': 'Rule out medical issues first',
    'toolbox.sleep.science.riskFirstBody':
        'Some sleep problems may have underlying medical causes. Look out for key warning signs before self-treatment.',
    'toolbox.sleep.science.riskSnoring':
        'Loud snoring with witnessed breathing pauses',
    'toolbox.sleep.science.riskMental':
        'Sleep disturbance tied to mood episodes or trauma',
    'toolbox.sleep.science.riskMedical':
        'Restless legs, chronic pain, or medication side effects',
    'toolbox.sleep.science.dayAnchors': 'Day anchors stabilize nights',
    'toolbox.sleep.science.dayAnchorsBody':
        'Stable wake time, morning light, and consistent meal timing anchor your circadian rhythm.',
    'toolbox.sleep.science.fixWakeTime':
        'Fix wake-up time within a 30-minute window every day',
    'toolbox.sleep.science.caffeineRule':
        'No caffeine after 2pm (or 8-10 hours before bed)',
    'toolbox.sleep.science.napRule':
        'Naps under 20 minutes before 3pm, or skip entirely',
    'toolbox.sleep.science.windDownSm': 'The small wind-down matters',
    'toolbox.sleep.science.windDownSmBody':
        'Even a tiny 3-step routine signals your brain that the day is ending. Consistency matters more than ritual complexity.',
    'toolbox.sleep.science.windDownDetail1':
        'Dim lights 30-60 minutes before bed',
    'toolbox.sleep.science.windDownDetail2':
        'Put screens away or switch to dark/night mode',
    'toolbox.sleep.science.windDownDetail3':
        'One quiet activity: reading, stretching, or breathing',
    'toolbox.sleep.science.nightWaking': 'Night waking is normal',
    'toolbox.sleep.science.nightWakingBody':
        'Brief awakenings between sleep cycles are normal. The problem is how we react — clock-checking and frustration prolong wakefulness.',
    'toolbox.sleep.science.nightWakingDetail1':
        'Avoid looking at clocks or your phone',
    'toolbox.sleep.science.nightWakingDetail2':
        'If still awake after 20 minutes, leave the bed',
    'toolbox.sleep.science.nightWakingDetail3':
        'Do something boring in dim light until sleepy',
    'toolbox.sleep.science.easyMisuse': 'Common misunderstandings',
    'toolbox.sleep.science.easyMisuseIntro':
        'Popular sleep advice can be misapplied. Here are three common pitfalls.',
    'toolbox.sleep.science.eightHour':
        '"Everyone needs 8 hours" — normal sleep varies from 6-9 hours across individuals.',
    'toolbox.sleep.science.cycle90':
        '"Always wake at a cycle boundary" — sleep architecture is more complex than fixed 90-minute blocks.',
    'toolbox.sleep.science.hygiene':
        '"Sleep hygiene alone fixes insomnia" — chronic insomnia often needs structured CBT-I techniques.',

    // --- toolbox sleep tools ---
    'toolbox.sleep.tools.ambientNoise': 'Ambient sound',
    'toolbox.sleep.tools.ambientNoiseHint':
        'Use white noise, rain, or ambient sounds to mask disturbances.',
    'toolbox.sleep.tools.enableAmbient': 'Enable ambient',
    'toolbox.sleep.tools.masterSwitch': 'Master switch',
    'toolbox.sleep.tools.mySounds': 'My sounds',
    'toolbox.sleep.tools.onlineCatalog': 'Online catalog',
    'toolbox.sleep.tools.available': 'Available',
    'toolbox.sleep.tools.disabled': 'Disabled',
    'toolbox.sleep.tools.volume': 'Volume {pct}%',
    'toolbox.sleep.tools.notDownloaded': 'Not downloaded',
    'toolbox.sleep.tools.downloadedReady': 'Downloaded, ready',
    'toolbox.sleep.tools.downloading': 'Downloading...',
    'toolbox.sleep.tools.download': 'Download',
    'toolbox.sleep.tools.enabled': 'Enabled',
    'toolbox.sleep.tools.use': 'Use',

    // --- toolbox sleep sheets ---
    'toolbox.sleep.sheets.plannedBedtime': 'Planned bedtime',
    'toolbox.sleep.sheets.caffeineSensitive': 'Caffeine sensitivity',
    'toolbox.sleep.sheets.caffeineSuggestion':
        'Based on your sensitivity and planned bedtime, cut off caffeine by {time}.',
    'toolbox.sleep.sheets.lightTimer': 'Light timer',
    'toolbox.sleep.sheets.lightTimerHint':
        'Get {minutes} minutes of bright light exposure to anchor your rhythm.',
    'toolbox.sleep.core.cancel': 'Cancel',
    'toolbox.sleep.sheets.cyclePlan': '90-minute cycle plan',
    'toolbox.sleep.sheets.cyclePlanHint':
        'Sleep cycles are roughly 90 minutes. Plan your schedule around cycle boundaries.',
    'toolbox.sleep.sheets.targetWake': 'Target wake-up time',
    'toolbox.sleep.sheets.settleBuffer':
        'Settle buffer: {minutes} min to fall asleep',
    'toolbox.sleep.sheets.backPlanLightsOff': 'Plan: Lights off by {time}',
    'toolbox.sleep.sheets.backPlanHint':
        'Working backwards from your target wake time with 5-6 cycles.',
    'toolbox.sleep.sheets.sleepNow': 'If you sleep now',
    'toolbox.sleep.sheets.sleepNowHint':
        'Wake up around {time} with {cycles} complete cycles.',
    'toolbox.sleep.sheets.leaveBed': 'Leave bed',
    'toolbox.sleep.sheets.awakeAWhile': 'I\'ve been awake a while',
    'toolbox.sleep.sheets.stillSleepy': 'Still feel sleepy',
    'toolbox.sleep.sheets.busyMind': 'Mind is busy / racing',
    'toolbox.sleep.sheets.bodyUncomfortable': 'Body feels uncomfortable',
    'toolbox.sleep.sheets.adviceUncomfortable':
        'Check temperature, adjust bedding, try gentle stretch.',
    'toolbox.sleep.sheets.adviceAwake':
        'Get up for 15-20 minutes, do a quiet activity, return when drowsy.',
    'toolbox.sleep.sheets.adviceBusy':
        'Write down the thoughts, then do 4-7-8 breathing for 2 minutes.',
    'toolbox.sleep.sheets.adviceSleepy':
        'Close your eyes, breathe slowly, and let yourself drift.',

    // --- toolbox sleep library (research) ---
    'toolbox.sleep.library.topic.light.title':
        'Morning light and circadian anchoring',
    'toolbox.sleep.library.topic.light.summary':
        'Bright light within 30 minutes of waking is the single strongest signal for your internal clock.',
    'toolbox.sleep.library.topic.light.detail':
        'The suprachiasmatic nucleus (SCN) uses light detected by ipRGC cells in the retina to synchronize your circadian rhythm. Morning light advances your clock, making it easier to fall asleep at night. Even 10-15 minutes outdoors on a cloudy day provides enough lux to make a measurable difference.',
    'toolbox.sleep.library.topic.light.action_hint':
        'Get outside within 30 minutes of waking. No sunglasses for the first 10 minutes.',
    'toolbox.sleep.library.source.light_1':
        'Czeisler CA, et al. Stability, precision, and near-24-hour period of the human circadian pacemaker. Science (1999).',
    'toolbox.sleep.library.source.light_2':
        'Duffy JF, Czeisler CA. Effect of light on human circadian physiology. Sleep Med Clin (2009).',
    'toolbox.sleep.library.source.light_3':
        'Blume C, et al. Effects of light on human circadian rhythms, sleep and mood. Somnologie (2019).',
    'toolbox.sleep.library.topic.caffeine.title':
        'Caffeine timing and adenosine blockade',
    'toolbox.sleep.library.topic.caffeine.summary':
        'Caffeine works by blocking adenosine receptors. Its half-life is 3-7 hours, meaning a 2pm coffee can still affect sleep at midnight.',
    'toolbox.sleep.library.topic.caffeine.detail':
        'Adenosine builds up during the day, creating "sleep pressure." Caffeine temporarily blocks adenosine receptors, masking sleepiness without reducing the underlying pressure. Genetic differences in CYP1A2 mean some people metabolize caffeine much slower than others.',
    'toolbox.sleep.library.topic.caffeine.action_hint':
        'Set a personal caffeine cutoff 8-10 hours before your typical bedtime.',
    'toolbox.sleep.library.source.caffeine_1':
        'Drake C, et al. Caffeine effects on sleep taken 0, 3, or 6 hours before going to bed. J Clin Sleep Med (2013).',
    'toolbox.sleep.library.source.caffeine_2':
        'Landolt HP. Genotype-dependent differences in sleep, vigilance, and response to stimulants. Curr Pharm Des (2008).',
    'toolbox.sleep.library.source.caffeine_3':
        'Roehrs T, Roth T. Caffeine: sleep and daytime sleepiness. Sleep Med Rev (2008).',
    'toolbox.sleep.library.topic.digital_sunset.title':
        'Digital sunset and blue light',
    'toolbox.sleep.library.topic.digital_sunset.summary':
        'Evening screen light, especially blue wavelengths, can suppress melatonin by activating the same ipRGC cells that respond to morning light.',
    'toolbox.sleep.library.topic.digital_sunset.detail':
        'The melanopsin photopigment in ipRGC cells is most sensitive to ~480nm (blue) light. Evening exposure shifts the circadian clock later, making it harder to fall asleep. However, the effect size varies widely between individuals, and content arousal may matter as much as the light itself.',
    'toolbox.sleep.library.topic.digital_sunset.action_hint':
        'Switch devices to night mode after sunset. Stop active screen use 30-60 minutes before bed.',
    'toolbox.sleep.library.source.digital_sunset_1':
        'Chang AM, et al. Evening use of light-emitting eReaders negatively affects sleep. PNAS (2015).',
    'toolbox.sleep.library.source.digital_sunset_2':
        'Cajochen C, et al. Evening exposure to a light-emitting diode (LED)-backlit computer screen affects circadian physiology. J Appl Physiol (2011).',
    'toolbox.sleep.library.source.digital_sunset_3':
        'Exelmans L, Van den Bulck J. Bedtime mobile phone use and sleep in adults. Soc Sci Med (2016).',
    'toolbox.sleep.library.topic.stimulus_control.title':
        'Stimulus control: bed = sleep',
    'toolbox.sleep.library.topic.stimulus_control.summary':
        'One of the most effective CBT-I techniques: re-associate the bed with sleep only.',
    'toolbox.sleep.library.topic.stimulus_control.detail':
        'When people spend time awake in bed (worrying, working, watching shows), the brain learns that bed is a place for wakefulness. Stimulus control therapy breaks this cycle by prescribing: only go to bed when sleepy, get up if awake for 20+ minutes, and use the bed only for sleep.',
    'toolbox.sleep.library.topic.stimulus_control.action_hint':
        'If you lie awake for 20+ minutes, get up and do something boring in dim light.',
    'toolbox.sleep.library.source.stimulus_control_1':
        'Bootzin RR, Epstein D, Wood JM. Stimulus control instructions. In: Case Studies in Insomnia (1991).',
    'toolbox.sleep.library.source.stimulus_control_2':
        'Morin CM, et al. Psychological and behavioral treatment of insomnia: update of the recent evidence. Sleep (2006).',
    'toolbox.sleep.library.topic.diary_trends.title':
        'The power of a simple sleep diary',
    'toolbox.sleep.library.topic.diary_trends.summary':
        'A 30-second sleep log reveals patterns that even detailed sleep trackers miss.',
    'toolbox.sleep.library.topic.diary_trends.detail':
        'Consumer sleep trackers estimate sleep stages from movement and heart rate, but their accuracy varies widely and they often overestimate sleep. A simple diary capturing bedtime, wake time, and subjective restfulness provides complementary data that highlights behavioral patterns trackers cannot see.',
    'toolbox.sleep.library.topic.diary_trends.action_hint':
        'Log just 3 data points per night: bedtime, wake time, and how rested you feel.',
    'toolbox.sleep.library.source.diary_trends_1':
        'Carney CE, et al. The consensus sleep diary: standardizing prospective sleep self-monitoring. Sleep (2012).',
    'toolbox.sleep.library.source.diary_trends_2':
        'Baron KG, et al. Feeling validated yet? A scoping review of consumer wearable sleep technology. Sleep Med Rev (2018).',
    'toolbox.sleep.library.source.diary_trends_3':
        'de Zambotti M, et al. The sleep of the ring: comparison of the ŌURA sleep tracker against polysomnography. Behav Sleep Med (2019).',
    'toolbox.sleep.library.topic.sleep_cycles.title':
        'Sleep cycles and the 90-minute myth',
    'toolbox.sleep.library.topic.sleep_cycles.summary':
        'Sleep cycles average about 90 minutes, but the range is 70-120 minutes, and they change across the night.',
    'toolbox.sleep.library.topic.sleep_cycles.detail':
        'NREM-REM cycles do follow a roughly 90-minute rhythm, but the first cycle of the night is often shorter (~70 min) with more deep sleep, while later cycles are longer (~100-120 min) with more REM. Waking up naturally often occurs from REM and can feel restorative.',
    'toolbox.sleep.library.topic.sleep_cycles.action_hint':
        'Use 90-minute windows as a rough guide, not a rigid rule. Consistency of wake time matters more.',
    'toolbox.sleep.library.source.sleep_cycles_1':
        'Feinberg I, Floyd TC. Systematic trends across the night in human sleep cycles. Psychophysiology (1979).',
    'toolbox.sleep.library.source.sleep_cycles_2':
        'Carskadon MA, Dement WC. Normal human sleep: an overview. In: Principles and Practice of Sleep Medicine (2011).',
    'toolbox.sleep.library.source.sleep_cycles_3':
        'Achermann P, Borbély AA. Sleep homeostasis and models of sleep regulation. J Biol Rhythms (1999).',
    'toolbox.sleep.library.topic.worry_unload.title':
        'Unloading worry before bedtime',
    'toolbox.sleep.library.topic.worry_unload.summary':
        'A brief structured writing exercise before bed can reduce pre-sleep cognitive arousal.',
    'toolbox.sleep.library.topic.worry_unload.detail':
        'Pre-sleep cognitive arousal—worrying, planning, replaying events—is a primary driver of sleep-onset insomnia. Structured "worry time" earlier in the evening plus a brief bedside unloading exercise (writing down the top concern and a gentle reframe) reduces the mental activation that delays sleep.',
    'toolbox.sleep.library.topic.worry_unload.action_hint':
        'Write down your top worry and one gentler way to see it before turning off the light.',
    'toolbox.sleep.library.source.worry_unload_1':
        'Harvey AG. A cognitive model of insomnia. Behav Res Ther (2002).',
    'toolbox.sleep.library.source.worry_unload_2':
        'Espie CA, et al. The attention-intention-effort pathway in the development of psychophysiologic insomnia. Sleep Med Rev (2006).',
    'toolbox.sleep.library.topic.bedroom.title':
        'Bedroom environment optimization',
    'toolbox.sleep.library.topic.bedroom.summary':
        'Temperature, noise, and light are the three main environmental factors affecting sleep quality.',
    'toolbox.sleep.library.topic.bedroom.detail':
        'The ideal bedroom temperature for sleep is 18-20°C (65-68°F). Core body temperature must drop by about 1°C to initiate and maintain sleep. A room that is too warm prevents this drop. Noise above 40dB can cause arousals even without full awakening.',
    'toolbox.sleep.library.topic.bedroom.action_hint':
        'Keep the bedroom cool, dark, and quiet. Try a temperature of 18-20°C.',
    'toolbox.sleep.library.source.bedroom_1':
        'Okamoto-Mizuno K, Mizuno K. Effects of thermal environment on sleep and circadian rhythm. J Physiol Anthropol (2012).',
    'toolbox.sleep.library.source.bedroom_2':
        'Muzet A. Environmental noise, sleep and health. Sleep Med Rev (2007).',
    'toolbox.sleep.library.source.bedroom_3':
        'van Maanen A, et al. The effects of light therapy on sleep problems. Sleep Med Rev (2016).',
    'toolbox.sleep.library.topic.temperature.title':
        'Core body temperature and sleep onset',
    'toolbox.sleep.library.topic.temperature.summary':
        'A drop in core body temperature of about 1°C is required to initiate and maintain sleep.',
    'toolbox.sleep.library.topic.temperature.detail':
        'The body\'s thermoregulatory system is closely linked to sleep regulation. Vasodilation in hands and feet (which is why warm hands help sleep onset) facilitates heat loss. A warm bath 1-2 hours before bed paradoxically helps by drawing blood to the skin surface, triggering a rebound temperature drop.',
    'toolbox.sleep.library.topic.temperature.action_hint':
        'Try a warm bath or shower 1-2 hours before bed. Keep the bedroom slightly cool.',
    'toolbox.sleep.library.source.temperature_1':
        'Kräuchi K, et al. Warm feet promote the rapid onset of sleep. Nature (1999).',
    'toolbox.sleep.library.source.temperature_2':
        'Raymann RJ, et al. Skin temperature and sleep-onset latency. Physiol Behav (2007).',
    'toolbox.sleep.library.topic.nap.title': 'Naps: strategic use and timing',
    'toolbox.sleep.library.topic.nap.summary':
        'Short naps under 20 minutes can boost alertness without causing sleep inertia or disrupting nighttime sleep.',
    'toolbox.sleep.library.topic.nap.detail':
        'The ideal nap window is 10-20 minutes (the "power nap") which stays in lighter NREM sleep stages before entering deep slow-wave sleep. Longer naps (30+ min) risk sleep inertia—grogginess on waking—and can reduce homeostatic sleep pressure, making it harder to fall asleep at night.',
    'toolbox.sleep.library.topic.nap.action_hint':
        'Naps under 20 minutes, before 3pm. If you have insomnia, skip naps entirely.',
    'toolbox.sleep.library.source.nap_1':
        'Milner CE, Cote KA. Benefits of napping in healthy adults. J Sleep Res (2009).',
    'toolbox.sleep.library.source.nap_2':
        'Brooks A, Lack L. A brief afternoon nap following nocturnal sleep restriction. Sleep (2006).',
    'toolbox.sleep.library.topic.white_noise.title':
        'White noise and auditory masking',
    'toolbox.sleep.library.topic.white_noise.summary':
        'White noise can help by masking sudden environmental noises that cause micro-arousals.',
    'toolbox.sleep.library.topic.white_noise.detail':
        'White noise raises the auditory threshold, making it harder for sudden sounds (door closing, traffic, neighbor noise) to trigger a waking response. The effect is most pronounced in environments with intermittent noise rather than continuous noise.',
    'toolbox.sleep.library.topic.white_noise.action_hint':
        'Set white noise at a comfortable volume, just loud enough to mask background disturbances.',
    'toolbox.sleep.library.source.white_noise_1':
        'Stanchina ML, et al. The influence of white noise on sleep in subjects exposed to ICU noise. Sleep Med (2005).',
    'toolbox.sleep.library.source.white_noise_2':
        'Forquer LM, Johnson CM. Continuous white noise to reduce sleep latency and night wakings in college students. Sleep Hypn (2007).',
    'toolbox.sleep.library.topic.red_flags.title': 'When to see a doctor',
    'toolbox.sleep.library.topic.red_flags.summary':
        'Some sleep symptoms warrant medical evaluation before self-guided approaches.',
    'toolbox.sleep.library.topic.red_flags.detail':
        'Loud, habitual snoring with witnessed breathing pauses suggests possible sleep apnea, which affects 10-30% of adults and requires medical diagnosis. Restless legs, chronic pain disrupting sleep, and sleep disturbance tied to mood episodes also warrant professional evaluation.',
    'toolbox.sleep.library.topic.red_flags.action_hint':
        'If you snore loudly and feel unrefreshed despite adequate sleep duration, ask your doctor about a sleep study.',
    'toolbox.sleep.library.source.red_flags_1':
        'Young T, et al. The occurrence of sleep-disordered breathing among middle-aged adults. N Engl J Med (1993).',
    'toolbox.sleep.library.source.red_flags_2':
        'Winkelman JW, et al. Clinical practice guideline for restless legs syndrome. J Clin Sleep Med (2016).',
    'toolbox.sleep.library.source.red_flags_3':
        'Baglioni C, et al. Sleep and mental disorders: a meta-analysis of polysomnographic research. Psychol Bull (2016).',
    'toolbox.sleep.library.topic.references': 'References',
    'toolbox.sleep.library.advice_assessment_rhythm.title':
        'Start a 7-day rhythm reset',
    'toolbox.sleep.library.advice_assessment_rhythm.body':
        'Your assessment suggests an irregular sleep schedule. A structured rhythm program focusing on consistent wake time and morning light can stabilize your circadian rhythm.',
    'toolbox.sleep.library.advice_assessment_rhythm.reason':
        'Irregular schedules weaken the circadian signal, making it harder to fall asleep and wake up predictably.',
    'toolbox.sleep.library.tag.rhythm': 'Rhythm',
    'toolbox.sleep.library.advice_assessment_wind_down.title':
        'Build a tiny wind-down routine',
    'toolbox.sleep.library.advice_assessment_wind_down.body':
        'Even a simple 3-step pre-bed routine can significantly reduce the time it takes to fall asleep by signaling to your brain that the day is ending.',
    'toolbox.sleep.library.advice_assessment_wind_down.reason':
        'Racing thoughts and difficulty winding down respond well to a consistent behavioral routine.',
    'toolbox.sleep.library.tag.wind_down': 'Wind-down',
    'toolbox.sleep.library.advice_assessment_caffeine.title':
        'Optimize your caffeine cutoff',
    'toolbox.sleep.library.advice_assessment_caffeine.body':
        'Based on your sensitivity, set a firm caffeine cutoff 8-10 hours before your typical bedtime to protect your natural sleep pressure.',
    'toolbox.sleep.library.advice_assessment_caffeine.reason':
        'Caffeine blocks adenosine receptors, masking the sleep pressure your brain needs to initiate sleep.',
    'toolbox.sleep.library.tag.behavior': 'Behavior',
    'toolbox.sleep.library.advice_assessment_environment.title':
        'Optimize your bedroom environment',
    'toolbox.sleep.library.advice_assessment_environment.body':
        'A cool, dark, and quiet bedroom supports the natural drop in core body temperature needed for sleep.',
    'toolbox.sleep.library.advice_assessment_environment.reason':
        'Environmental factors can interfere with the physiological transition to sleep.',
    'toolbox.sleep.library.tag.environment': 'Environment',
    'toolbox.sleep.library.advice_assessment_temp.title':
        'Use temperature to aid sleep onset',
    'toolbox.sleep.library.advice_assessment_temp.body':
        'A warm bath 1-2 hours before bed, plus a cool bedroom, helps trigger the core temperature drop needed for sleep.',
    'toolbox.sleep.library.advice_assessment_temp.reason':
        'Core body temperature must drop about 1°C to initiate and maintain sleep.',
    'toolbox.sleep.library.tag.temperature': 'Temperature',
    'toolbox.sleep.library.advice_assessment_risk.title':
        'Consider a medical evaluation',
    'toolbox.sleep.library.advice_assessment_risk.body':
        'Your assessment flagged potential risk factors that may benefit from professional evaluation alongside self-guided approaches.',
    'toolbox.sleep.library.advice_assessment_risk.reason':
        'Some sleep symptoms have underlying medical causes that are best evaluated by a healthcare professional.',
    'toolbox.sleep.library.tag.risk': 'Health',
    'toolbox.sleep.library.advice_daily_minimal_log.title':
        'Keep logging — consistency beats detail',
    'toolbox.sleep.library.advice_daily_minimal_log.body':
        'Your daily log entries are building a dataset that reveals patterns. Keep going — even 30-second entries add up.',
    'toolbox.sleep.library.advice_daily_minimal_log.reason':
        'Sleep diary data over multiple nights reveals patterns that single-night snapshots miss.',
    'toolbox.sleep.library.tag.log': 'Logging',
    'toolbox.sleep.library.advice_daily_caffeine.title':
        'Watch the late caffeine pattern',
    'toolbox.sleep.library.advice_daily_caffeine.body':
        'Your logs show caffeine consumption close to bedtime on some nights. Even when you can fall asleep, caffeine reduces deep sleep.',
    'toolbox.sleep.library.advice_daily_caffeine.reason':
        'Caffeine after the cutoff can fragment sleep architecture even without delaying sleep onset.',
    'toolbox.sleep.library.advice_daily_light.title':
        'Prioritize morning light',
    'toolbox.sleep.library.advice_daily_light.body':
        'Your sleep quality correlates with morning light exposure. Try getting outside for 10-15 minutes within 30 minutes of waking.',
    'toolbox.sleep.library.advice_daily_light.reason':
        'Morning light is the strongest zeitgeber for anchoring circadian rhythm.',
    'toolbox.sleep.library.advice_daily_screen.title':
        'Try a digital sunset tonight',
    'toolbox.sleep.library.advice_daily_screen.body':
        'Late screen use appears in your recent logs. Switching to night mode or putting devices away 30-60 minutes before bed can improve sleep quality.',
    'toolbox.sleep.library.advice_daily_screen.reason':
        'Evening blue light can suppress melatonin and delay sleep onset.',
    'toolbox.sleep.library.advice_daily_worry.title':
        'Try the worry unload exercise',
    'toolbox.sleep.library.advice_daily_worry.body':
        'Pre-sleep worry or busy-mind patterns show in your data. A 2-minute writing exercise before bed can significantly reduce this cognitive arousal.',
    'toolbox.sleep.library.advice_daily_worry.reason':
        'Pre-sleep cognitive arousal is a primary driver of sleep-onset difficulty.',
    'toolbox.sleep.library.tag.cognitive': 'Cognitive',
    'toolbox.sleep.library.advice_daily_rescue.title':
        'Keep the night rescue tool handy',
    'toolbox.sleep.library.advice_daily_rescue.body':
        'Night awakenings appear in your recent logs. Having a pre-planned low-stimulation response makes it easier to handle them calmly.',
    'toolbox.sleep.library.advice_daily_rescue.reason':
        'A planned response to night waking reduces the anxiety and clock-checking that prolong wakefulness.',
    'toolbox.sleep.library.tag.rescue': 'Rescue',
    'toolbox.sleep.library.advice_daily_environment.title':
        'Tweak your bedroom environment',
    'toolbox.sleep.library.advice_daily_environment.body':
        'Your logs show environmental factors are affecting your sleep. Small adjustments to temperature, light, or noise can make a meaningful difference.',
    'toolbox.sleep.library.advice_daily_environment.reason':
        'The bedroom environment directly impacts the body\'s ability to initiate and maintain sleep.',
    'toolbox.sleep.library.advice_daily_nap.title':
        'Optimize your nap strategy',
    'toolbox.sleep.library.advice_daily_nap.body':
        'Your data suggests daytime sleepiness. If you nap, keep it under 20 minutes and before 3pm. If you have insomnia, consider skipping naps.',
    'toolbox.sleep.library.advice_daily_nap.reason':
        'Naps can help or hurt nighttime sleep depending on timing and duration.',
    'toolbox.sleep.library.tag.recovery': 'Recovery',
    'toolbox.sleep.library.advice_weekly_light.title':
        'Morning light is your strongest rhythm tool',
    'toolbox.sleep.library.advice_weekly_light.body':
        'Your weekly data shows inconsistent morning light. Prioritizing even 10 minutes outdoors within 30 minutes of waking can strengthen your sleep-wake cycle.',
    'toolbox.sleep.library.advice_weekly_light.reason':
        'Consistent morning light exposure is the most effective way to stabilize circadian timing.',
    'toolbox.sleep.library.advice_weekly_caffeine.title':
        'Your caffeine pattern may be reducing sleep quality',
    'toolbox.sleep.library.advice_weekly_caffeine.body':
        'Caffeine close to bedtime correlates with lower sleep efficiency and less deep sleep in your weekly data.',
    'toolbox.sleep.library.advice_weekly_caffeine.reason':
        'Late caffeine affects sleep architecture even when you don\'t notice difficulty falling asleep.',
    'toolbox.sleep.library.advice_weekly_screen.title':
        'Late screen use is affecting your sleep',
    'toolbox.sleep.library.advice_weekly_screen.body':
        'Your data shows a correlation between late screen use and longer time to fall asleep. Try a 30-60 minute screen-free buffer before bed.',
    'toolbox.sleep.library.advice_weekly_screen.reason':
        'Screen light and content arousal both contribute to delayed sleep onset.',
    'toolbox.sleep.library.advice_weekly_rescue.title':
        'Night awakenings: prepare a response plan',
    'toolbox.sleep.library.advice_weekly_rescue.body':
        'Multiple night awakenings in your recent logs suggest having a pre-planned rescue response could help. The key: avoid clock-checking, and get up briefly if awake 20+ minutes.',
    'toolbox.sleep.library.advice_weekly_rescue.reason':
        'A planned response to night waking reduces the frustration that can prolong wakefulness.',
    'toolbox.sleep.library.advice_weekly_worry.title':
        'Pre-sleep worry: a simple writing exercise can help',
    'toolbox.sleep.library.advice_weekly_worry.body':
        'Your data shows elevated worry or busy-mind ratings. A structured 2-minute "worry unload" before bed can clear mental space for sleep.',
    'toolbox.sleep.library.advice_weekly_worry.reason':
        'Cognitive arousal before bed is one of the strongest predictors of prolonged sleep onset.',
    'toolbox.sleep.library.advice_weekly_environment.title':
        'Your sleep environment needs attention',
    'toolbox.sleep.library.advice_weekly_environment.body':
        'Environmental complaints (temperature, noise, light) appear across multiple nights. Consistent bedroom optimization can yield cumulative benefits.',
    'toolbox.sleep.library.advice_weekly_environment.reason':
        'Persistent environmental issues have a compounding negative effect on sleep quality.',
    'toolbox.sleep.library.advice_weekly_sleep_amount.title':
        'Your total sleep time shows a pattern',
    'toolbox.sleep.library.advice_weekly_sleep_amount.body':
        'Your weekly sleep duration shows variability. Focus on consistent wake time rather than bedtime — this is the stronger anchor for circadian rhythm.',
    'toolbox.sleep.library.advice_weekly_sleep_amount.reason':
        'Wake-time consistency is more important than bedtime consistency for circadian health.',
    'toolbox.sleep.library.tag.sleep_amount': 'Sleep amount',
    'toolbox.sleep.library.empty.no_advice': 'No advice available yet',
    'toolbox.sleep.library.empty.no_advice_hint':
        'Continue logging your sleep to receive personalized suggestions.',
    'toolbox.sleep.library.research_detail': 'Research detail',

    // --- Breathing tool (toolbox_breathing_tool.dart) ---
    'toolbox.breathing.guide_title': 'Breathing guide',
    'toolbox.breathing.research_basis': 'Research basis',
    'toolbox.breathing.how_it_works': 'How it works',
    'toolbox.breathing.body_focus': 'Body focus',
    'toolbox.breathing.when_to_use': 'When to use',
    'toolbox.breathing.cycle_flow': 'Cycle flow',
    'toolbox.breathing.practice_steps': 'Practice steps',
    'toolbox.breathing.core_technique': 'Core technique',
    'toolbox.breathing.caution': 'Caution',
    'toolbox.breathing.advanced': 'Advanced',
    'toolbox.breathing.altitude_simulation_prompt': 'Use altitude simulation?',
    'toolbox.breathing.altitude_simulation_description':
        'Altitude simulation adjusts patterns and difficulty, designed for experienced users. If you have respiratory conditions, cardiovascular issues, or are pregnant, consult a doctor first.',
    'toolbox.breathing.altitude_extra_warning':
        'Altitude simulation is not medical advice. Stop immediately and return to natural breathing if you feel dizzy, tightness, or any discomfort.',
    'toolbox.breathing.cancel': 'Cancel',
    'toolbox.breathing.continue_select': 'Continue',
    'toolbox.breathing.bolt_test': 'BOLT test',
    'toolbox.breathing.bolt_description':
        'Measures your CO2 tolerance to help assess current breathing efficiency. A low score often points to shallow or rapid breathing.',
    'toolbox.breathing.current': 'Current',
    'toolbox.breathing.band': 'Band',
    'toolbox.breathing.best': 'Best',
    'toolbox.breathing.preparing': 'Preparing',
    'toolbox.breathing.save_result': 'Save result',
    'toolbox.breathing.start_test': 'Start test',
    'toolbox.breathing.test_steps': 'Test steps',
    'toolbox.breathing.recommended_drills': 'Recommended drills',
    'toolbox.breathing.reset': 'Reset',
    'toolbox.breathing.seconds_unit': 's',
    'toolbox.breathing.follow_orb': 'Follow the orb',
    'toolbox.breathing.keep_natural': 'Keep the breath natural',
    'toolbox.breathing.cycle_duration': 'Cycle',
    'toolbox.breathing.target': 'Target',
    'toolbox.breathing.done': 'Done',
    'toolbox.breathing.left': 'Left',
    'toolbox.breathing.pause': 'Pause',
    'toolbox.breathing.start': 'Start',
    'toolbox.breathing.next_stage': 'Next stage',
    'toolbox.breathing.session_setup': 'Session setup',
    'toolbox.breathing.theme': 'Theme',
    'toolbox.breathing.duration': 'Duration',
    'toolbox.breathing.minutes': '{minutes} min',
    'toolbox.breathing.breath_hold_stage': 'Breath-hold stage',
    'toolbox.breathing.breath_hold_on':
        'On: adding a hold makes the cycle more complete but takes more adaptation.',
    'toolbox.breathing.breath_hold_off':
        'Off: best for first-time practice or when you prefer no extra hold.',
    'toolbox.breathing.recovery_stage': 'Recovery stage',
    'toolbox.breathing.recovery_on':
        'On: a quiet recovery pause at the end of each cycle.',
    'toolbox.breathing.recovery_off':
        'Off: skip the recovery pause for a tighter rhythm.',
    'toolbox.breathing.voice_cues': 'Voice cues',
    'toolbox.breathing.voice_on':
        'On: spoken reminders guide each phase of the breath.',
    'toolbox.breathing.voice_off':
        'Off: keep text, animation, and haptics only.',
    'toolbox.breathing.text_cues': 'Text cues',
    'toolbox.breathing.text_on': 'On: show text prompts beside the orb.',
    'toolbox.breathing.text_off': 'Off: rely on animation and voice only.',
    'toolbox.breathing.haptics': 'Haptics',
    'toolbox.breathing.haptics_on':
        'On: a light vibration on each stage change.',
    'toolbox.breathing.haptics_off': 'Off: no extra vibration.',
    'toolbox.breathing.scenarios_title': 'Breathing scenarios',
    'toolbox.breathing.scenarios_subtitle':
        'From focus to relaxation, from daily practice to BOLT testing and altitude simulation. Each scenario includes detailed breathing guidance and phase breakdown.',
    'toolbox.breathing.rounds': 'Rounds',
    'toolbox.breathing.sessions_completed': 'Sessions',
    'toolbox.breathing.total_time': 'Total time',
    'toolbox.breathing.voice_source': 'Voice',
    'toolbox.breathing.bolt': 'BOLT',
    'toolbox.breathing.safety_note_title': 'Safety note',
    'toolbox.breathing.safety_note_body':
        'Breathing exercises are not a substitute for medical advice. Consult a doctor before starting new training if you have respiratory or cardiovascular concerns or are pregnant. Stop immediately and return to natural breathing if you feel dizzy, tightness, or any discomfort.',
    'toolbox.breathing.stop_preview': 'Stop preview',
    'toolbox.breathing.preview_guidance': 'Preview guidance',
    'toolbox.breathing.voice_only_chinese_title':
        'Voice is Chinese-only for now',
    'toolbox.breathing.voice_only_chinese_body':
        'Breathing voice guidance is currently recorded in Chinese only. The interface can stay in your current language, but spoken cues will play in Chinese.',
    'toolbox.breathing.turn_voice_off': 'Turn voice off',
    'toolbox.breathing.keep_chinese_voice': 'Keep Chinese voice',
    'toolbox.breathing.voice_off_status': 'Voice is off',
    'toolbox.breathing.voice_checking_status': 'Checking voice resources',
    'toolbox.breathing.voice_remote_status': 'Online voice is ready',
    'toolbox.breathing.voice_bundled_status': 'Bundled voice is ready',
    'toolbox.breathing.voice_unavailable_status': 'No stage voice available',
    'toolbox.breathing.voice_availability_short':
        'Voice guidance is available.',
    'toolbox.breathing.short_stage_mute_hint': 'Pause stays silent',
    'toolbox.breathing.pause_stays_silent': 'Pause stays silent',
    'toolbox.breathing.remote_source': 'Online',
    'toolbox.breathing.bundled_source': 'Bundled',
    'toolbox.breathing.ready': 'Ready',
    'toolbox.breathing.not_tested_yet': 'Not tested yet',
    'toolbox.breathing.not_tested_body':
        'You have not completed a BOLT test yet. BOLT (Body Oxygen Level Test) measures your CO2 tolerance: a higher score generally indicates better breathing efficiency.',
    'toolbox.breathing.not_tested_next':
        'Suggestion: complete one BOLT test for a baseline score.',
    'toolbox.breathing.low_bolt': 'Low BOLT',
    'toolbox.breathing.low_bolt_body':
        'Your BOLT is low (under 20 s), suggesting room to improve CO2 tolerance. Shallow or rapid breathing is a common cause.',
    'toolbox.breathing.low_bolt_next':
        'Start with the diaphragmatic breathing scenario and aim to raise BOLT above 20 before trying breath-hold patterns.',
    'toolbox.breathing.building_bolt': 'BOLT building',
    'toolbox.breathing.building_bolt_body':
        'Your BOLT is 20-29 s, in the building range. Breathing efficiency still has room to grow.',
    'toolbox.breathing.building_bolt_next':
        'Keep practicing diaphragmatic breathing and no-hold slow patterns to gradually improve CO2 tolerance.',
    'toolbox.breathing.stable_bolt': 'Stable BOLT',
    'toolbox.breathing.stable_bolt_body':
        'Your BOLT is 30-39 s, a stable range where breath-hold patterns become appropriate.',
    'toolbox.breathing.stable_bolt_next':
        'You can safely try box breathing, 4-7-8, and other patterns with holds.',
    'toolbox.breathing.advanced_bolt': 'Advanced BOLT',
    'toolbox.breathing.advanced_bolt_body':
        'Your BOLT is over 40 s, indicating strong breathing efficiency. You are ready for altitude simulation and advanced hold training.',
    'toolbox.breathing.advanced_bolt_next':
        'You can try altitude simulation and longer breath-hold sessions. Keep up regular practice.',
    'toolbox.breathing.next_step_prefix': 'Next: ',

    // --- Daily decision / Daily choice (daily_choice_*.dart) ---
    'toolbox.daily_choice.page_title': 'Daily decision',
    'toolbox.daily_choice.page_subtitle':
        'Turn everyday indecision into light, editable, reviewable choices, from what to eat and wear to lightweight decision calculations.',
    'toolbox.daily_choice.decision_workbench': 'Decision workbench',
    'toolbox.daily_choice.rational_guide': 'Guide',
    'toolbox.daily_choice.six_elements': 'Six elements',
    'toolbox.daily_choice.bias_vs_noise': 'Bias vs noise',
    'toolbox.daily_choice.set_context': 'Set the decision context',
    'toolbox.daily_choice.calculation_model': 'Decision lens',
    'toolbox.daily_choice.context_influences':
        'The context changes which lens should lead: random, weighted, scenario, or guardrails.',
    'toolbox.daily_choice.high_stakes_guardrail':
        'For high-stakes calls, check the safety threshold before upside. Open the full checklist when needed.',
    'toolbox.daily_choice.pre_commit_scan':
        'Before committing, scan bias, noise, and review conditions.',
    'toolbox.daily_choice.guided_decision_flow': 'Guided decision flow',
    'toolbox.daily_choice.frame_question': 'Frame the question',
    'toolbox.daily_choice.options': 'Options',
    'toolbox.daily_choice.classify_situation': 'Classify the situation',
    'toolbox.daily_choice.check_guardrails_first':
        'Check the safety threshold before chasing upside.',
    'toolbox.daily_choice.guardrail_best_for':
        'Best when stakes are high, reversal is hard, time is tight, or the floor must be protected.',
    'toolbox.daily_choice.six_modules': 'Six modules',
    'toolbox.daily_choice.local_custom': 'Local custom',
    'toolbox.daily_choice.let_choice_move': 'Let the choice start moving',
    'toolbox.daily_choice.uniform_random': 'Uniform random',
    'toolbox.daily_choice.uniform_random_subtitle':
        'Best for low-stakes, reversible choices with tiny differences.',
    'toolbox.daily_choice.uniform_random_formula':
        'Each option gets the same chance. The goal is to end hesitation fast.',
    'toolbox.daily_choice.uniform_random_caution':
        'Do not use random choice for high-stakes decisions.',
    'toolbox.daily_choice.weighted_factors': 'Weighted factors',
    'toolbox.daily_choice.weighted_factors_subtitle':
        'Compare value, success odds, reversibility, risk, and info gaps on one ruler.',
    'toolbox.daily_choice.weighted_factors_formula':
        'Weighted positives minus penalties for risk, effort, regret, and info gaps.',
    'toolbox.daily_choice.weighted_factors_caution':
        'Useful for ranking, not for claiming certainty.',
    'toolbox.daily_choice.expected_value': 'Expected value',
    'toolbox.daily_choice.expected_value_subtitle':
        'Best for uncertain outcomes when you can estimate rough odds.',
    'toolbox.daily_choice.expected_value_formula':
        'Success probability × upside − downside exposure − effort cost.',
    'toolbox.daily_choice.expected_value_caution':
        'Your inputs are still judgments, so estimate independently first.',
    'toolbox.daily_choice.joint_probability': 'Joint probability',
    'toolbox.daily_choice.joint_probability_subtitle':
        'Use a conservative product when success needs multiple things to line up.',
    'toolbox.daily_choice.joint_probability_formula':
        'Success probability × execution probability × confidence, then subtract downside exposure.',
    'toolbox.daily_choice.joint_probability_caution':
        'Great for multi-step dependence, weaker when the events are strongly correlated.',
    'toolbox.daily_choice.scenario_blend': 'Scenario blend',
    'toolbox.daily_choice.scenario_blend_subtitle':
        'Blend optimistic, base, and pessimistic scenarios so you do not stare only at the upside.',
    'toolbox.daily_choice.scenario_blend_formula':
        'A weighted blend of optimistic, base, and pessimistic cases.',
    'toolbox.daily_choice.scenario_blend_caution':
        'When uncertainty is high, let the pessimistic case carry real weight.',
    'toolbox.daily_choice.regret_balance': 'Regret and opportunity cost',
    'toolbox.daily_choice.regret_balance_subtitle':
        'Useful when you are likely to revisit the decision and ask what you should have chosen.',
    'toolbox.daily_choice.regret_balance_formula':
        'Realized upside plus reversibility buffer minus regret exposure and opportunity cost.',
    'toolbox.daily_choice.regret_balance_caution':
        'This lens corrects emotion; it does not predict destiny.',
    'toolbox.daily_choice.threshold_guardrail': 'Safety threshold first',
    'toolbox.daily_choice.threshold_guardrail_subtitle':
        'Check minimum standards first, then rank only the options that clear them.',
    'toolbox.daily_choice.threshold_guardrail_formula':
        'Check confidence, downside, reversibility, and info gaps first, then break ties with a composite score.',
    'toolbox.daily_choice.threshold_guardrail_caution':
        'In high-stakes situations, protect the floor before chasing upside.',
    'toolbox.daily_choice.calibrated_forecast': 'Calibrated forecast',
    'toolbox.daily_choice.calibrated_forecast_subtitle':
        'Shrink extreme forecasts back toward the mean to curb overconfidence.',
    'toolbox.daily_choice.calibrated_forecast_formula':
        'Average score + confidence × (raw forecast − average forecast).',
    'toolbox.daily_choice.calibrated_forecast_caution':
        'This is not machine learning; it is a disciplined pull back from extremes.',
    'toolbox.daily_choice.classify_first': 'Classify before choosing a method',
    'toolbox.daily_choice.classify_first_subtitle':
        'High-quality decisions start by identifying the type of decision before choosing the math lens.',
    'toolbox.daily_choice.low_stakes_fast':
        'Low stakes and reversible: decide fast',
    'toolbox.daily_choice.low_stakes_fast_body':
        'For restaurants, weekend plans, or lightweight purchases, the point is not perfection. Random choice or weighted factors are usually enough.',
    'toolbox.daily_choice.high_stakes_guardrail_title':
        'High stakes or hard to undo: set a safety threshold first',
    'toolbox.daily_choice.high_stakes_guardrail_body':
        'When mistakes are costly to unwind, check risk, confidence, info gaps, and reversibility before chasing upside.',
    'toolbox.daily_choice.high_uncertainty_pessimistic':
        'High uncertainty: bring in the pessimistic case',
    'toolbox.daily_choice.high_uncertainty_pessimistic_body':
        'When you know you do not know enough, a single score is not enough. Use joint probability, scenarios, and information value together.',
    'toolbox.daily_choice.six_elements_quality':
        'Six elements of decision quality',
    'toolbox.daily_choice.six_elements_quality_subtitle':
        'Taken from the Stanford decision-quality framework. This is the backbone of the module.',
    'toolbox.daily_choice.frame_question_right': 'Frame the question correctly',
    'toolbox.daily_choice.frame_question_right_body':
        'Clarify what is being decided, the time horizon, and which constraints are non-negotiable. A bad frame corrupts later analysis.',
    'toolbox.daily_choice.generate_options':
        'Generate at least 2 to 3 viable options',
    'toolbox.daily_choice.generate_options_body':
        'Many bad decisions happen because the option set was poor, not because comparison failed. Expand first, then narrow.',
    'toolbox.daily_choice.reliable_info':
        'Use relevant and reliable information',
    'toolbox.daily_choice.values_tradeoffs': 'Write down values and tradeoffs',
    'toolbox.daily_choice.transparent_reasoning':
        'Keep reasoning transparent and reviewable',
    'toolbox.daily_choice.decision_to_action': 'A decision must end in action',
    'toolbox.daily_choice.probability_uncertainty':
        'Probability and uncertainty',
    'toolbox.daily_choice.probability_uncertainty_subtitle':
        'Translate emotional certainty into probability language that can actually be compared.',
    'toolbox.daily_choice.assign_probabilities':
        'Assign probabilities before conclusions',
    'toolbox.daily_choice.use_multiplication':
        'Use multiplication when several conditions must hold',
    'toolbox.daily_choice.pull_extremes_back':
        'Pull extreme forecasts back toward the mean',
    'toolbox.daily_choice.update_evidence': 'Update when evidence changes',
    'toolbox.daily_choice.bias_noise_control': 'Bias and noise control',
    'toolbox.daily_choice.bias_noise_control_subtitle':
        'Avoid getting dragged around by anchors, sunk costs, compelling stories, or group noise.',
    'toolbox.daily_choice.independent_estimate':
        'Estimate independently before discussion',
    'toolbox.daily_choice.sunk_cost': 'Sunk cost is not a reason to continue',
    'toolbox.daily_choice.common_scale': 'Use a common scale to reduce noise',
    'toolbox.daily_choice.good_story': 'A good story is not strong evidence',
    'toolbox.daily_choice.when_to_research':
        'When to research more and when to move',
    'toolbox.daily_choice.when_to_research_subtitle':
        'Information has value, but analysis still needs a stop point.',
    'toolbox.daily_choice.most_likely_flip':
        'Collect the one fact most likely to change the answer',
    'toolbox.daily_choice.stop_rule': 'Set a stopping rule',
    'toolbox.daily_choice.premortem': 'Run a premortem for high-stakes choices',
    'toolbox.daily_choice.professional_judgment':
        'Medical, legal, and financial calls still need experts',
    'toolbox.daily_choice.score_independently': 'Score independently first',
    'toolbox.daily_choice.no_double_down': 'Do not double down on sunk cost',
    'toolbox.daily_choice.same_fields': 'Use the same fields for every option',
    'toolbox.daily_choice.base_rates_high_uncertainty':
        'Use base rates when uncertainty is high',
    'toolbox.daily_choice.research_flip_fact':
        'Research the fact most likely to change the answer',
    'toolbox.daily_choice.premortem_high_stakes':
        'Run a premortem for high stakes',
    'toolbox.daily_choice.value_ranking_disagree':
        'Return to value ranking when methods disagree',
    'toolbox.daily_choice.stop_rule_now':
        'If you must decide now, define a stopping rule',
    'toolbox.daily_choice.joint_rounds': 'Joint rounds',
    'toolbox.daily_choice.dice_count': 'Dice count',
    'toolbox.daily_choice.guide': 'Guide',
    'toolbox.daily_choice.ready_to_draw': 'Ready to draw',
    'toolbox.daily_choice.picked': 'Picked: {winner}',
    'toolbox.daily_choice.low_stakes_choice': 'Low-stakes choice',
    'toolbox.daily_choice.hub_title': 'Daily decision',
    'toolbox.daily_choice.hub_subtitle':
        'Turn everyday small dilemmas into randomized, editable, reviewable lightweight choices.',
    'toolbox.daily_choice.recipe_library': 'Recipe library',
    'toolbox.daily_choice.wear_library': 'Wardrobe',
    'toolbox.daily_choice.activity_library': 'Activity library',
    'toolbox.daily_choice.place_library': 'Place library',
    'toolbox.daily_choice.weather_not_ready':
        'Showing all temperatures for now. If the weather service has loaded, it will be used here automatically.',
  };

  static const Map<String, String> _toolboxZh = <String, String>{
    'toolbox.sound.locator.page_title': '声源定位',
    'toolbox.sound.locator.page_eyebrow': '工具箱 / 声学',
    'toolbox.sound.locator.page_subtitle':
        '使用手机自带麦克风监听目标声源，并引导你移动到多个位置逐步确认声源区域。',
    'toolbox.sound.locator.awaiting_source': '等待声源',
    'toolbox.sound.locator.source_in_front': '声源在正前方',
    'toolbox.sound.locator.direction_right': '右侧',
    'toolbox.sound.locator.direction_left': '左侧',
    'toolbox.sound.locator.direction_front': '正前方',
    'toolbox.sound.locator.source_offset': '声源偏{side} {deg} 度',
    'toolbox.sound.locator.status_starting_capture': '开始采集',
    'toolbox.sound.locator.status_idle': '待机',
    'toolbox.sound.locator.status_professional': '专业确认',
    'toolbox.sound.locator.status_stable': '稳定追踪',
    'toolbox.sound.locator.status_usable': '可用估计',
    'toolbox.sound.locator.status_low_confidence': '信号偏弱',
    'toolbox.sound.locator.status_listening': '等待声源',
    'toolbox.sound.locator.engine_mobile_move': '手机移动确认',
    'toolbox.sound.locator.engine_mobile_stereo': '手机双声道',
    'toolbox.sound.locator.engine_array_optional': '高级阵列可选',
    'toolbox.sound.locator.guidance_idle': '点击开始后让目标声源持续发声，然后在当前位置记录一次采样。',
    'toolbox.sound.locator.guidance_mono':
        '单声道也可以使用：请记录当前位置，然后向左、向右或向前移动一步继续采样。',
    'toolbox.sound.locator.guidance_reverb': '回响风险偏高，请靠近目标声源、避开墙角或降低背景噪声后重新确认。',
    'toolbox.sound.locator.guidance_low_snr': '信噪比偏低，多声源环境下请先让目标声源持续发声再锁定。',
    'toolbox.sound.locator.guidance_normal':
        '方向估计正在更新；请记录多个位置，系统会结合强度、信噪比和方位稳定性确认声源区域。',
    'toolbox.sound.locator.btn_stop_monitor': '停止监听',
    'toolbox.sound.locator.btn_starting': '开始中',
    'toolbox.sound.locator.btn_start_locating': '开始定位',
    'toolbox.sound.locator.btn_record_position': '记录当前位置',
    'toolbox.sound.locator.metric_snr': '信噪比',
    'toolbox.sound.locator.movement_confirmation': '移动确认',
    'toolbox.sound.locator.confirm_locked':
        '已根据多个手机位置确认声源区域。复杂环境下仍建议再采一次反方向样本。',
    'toolbox.sound.locator.confirm_tracking': '声源区域正在缩小范围，请保持目标声源持续发声并补充一个新位置。',
    'toolbox.sound.locator.confirm_tentative': '已有早期线索，但还需要至少 3 个位置才能稳定确认。',
    'toolbox.sound.locator.confirm_unconfirmed': '请先记录当前位置，再移动到不同方向继续采样。',
    'toolbox.sound.locator.cue_step_0': '第一步：站在当前位置，保持手机朝向目标区域，记录一次。',
    'toolbox.sound.locator.cue_stay': '下一步：保持目标声源持续发声，再在当前位置复测一次。',
    'toolbox.sound.locator.cue_left': '下一步：向左侧移动一小步，手机朝向不变，然后记录。',
    'toolbox.sound.locator.cue_right': '下一步：向右侧移动一小步，手机朝向不变，然后记录。',
    'toolbox.sound.locator.cue_forward': '下一步：向目标方向靠近一步，然后记录。',
    'toolbox.sound.locator.cue_back': '下一步：后退一步做对照采样，然后记录。',
    'toolbox.sound.locator.btn_reset_samples': '重置采样',
    'toolbox.sound.locator.cue_label_stay': '原地',
    'toolbox.sound.locator.cue_label_left': '左移',
    'toolbox.sound.locator.cue_label_right': '右移',
    'toolbox.sound.locator.cue_label_forward': '前移',
    'toolbox.sound.locator.cue_label_back': '后退',
    'toolbox.sound.locator.phone_mic': '手机麦克风能力',
    'toolbox.sound.locator.metric_channels': '输入通道',
    'toolbox.sound.locator.metric_sample_rate': '采样率',
    'toolbox.sound.locator.metric_peak': '峰值',
    'toolbox.sound.locator.metric_reverb': '回响风险',
    'toolbox.sound.locator.try_stereo': '尝试双声道采集',
    'toolbox.sound.locator.try_stereo_subtitle':
        '如果平台只返回单声道或开启失败，可关闭此项改为稳定的单声道活动检查。',
    'toolbox.sound.locator.mic_sufficient':
        '手机自带麦克风足够用于移动确认流程：静止单点不可靠，但记录多个位置后可以逐步确定声源区域。',
    'toolbox.sound.locator.source_candidates': '多声源候选',
    'toolbox.sound.locator.no_stable_source': '还没有稳定声源。请让目标声源持续发声 1-2 秒。',
    'toolbox.sound.locator.source_locked': '已锁定主声源',
    'toolbox.sound.locator.source_tracking': '正在追踪声源',
    'toolbox.sound.locator.source_candidate': '候选声源',
    'toolbox.sound.locator.source_activity': '声音活动',
    'toolbox.sound.locator.advanced_odas': '高级参考: ODAS 可选',
    'toolbox.sound.locator.btn_less': '收起',
    'toolbox.sound.locator.btn_details': '展开',
    'toolbox.sound.locator.odas_description':
        '手机端默认不要求外接同步麦克风。ODAS 只作为高级参考：当用户有专用阵列时，可把输出并入本页的确认模型。',
    'toolbox.sound.locator.odas_default_path':
        '默认路径是手机移动采样；高级模式可以通过原生插件或本地守护进程读取 ODAS tracked source JSON 作为附加证据。',
    'toolbox.sound.locator.requirement_1': '手机麦克风权限与稳定 PCM 采集',
    'toolbox.sound.locator.requirement_2': '至少 3 个不同位置的移动采样',
    'toolbox.sound.locator.requirement_3': '目标声源在采样期间保持持续发声',
    'toolbox.sound.locator.requirement_4': '可选 ODAS/阵列输出作为高级证据',
    'toolbox.sound.locator.error_mic_denied': '麦克风权限被拒绝，无法进行声源采集。',
    'toolbox.sound.locator.error_no_frame': '还没有可记录的声音帧，请先开始监听并让目标声源持续发声。',

    'toolbox.sound.soothing.page_title': '舒缓轻音',
    'toolbox.sound.soothing.page_subtitle':
        '精选疗愈系轻音乐与氛围旋律，配合动态呼吸光效与本地曲库，适合手机端沉浸使用。',
    'toolbox.sound.soothing.browse_modes_title': '浏览模式',
    'toolbox.sound.soothing.browse_modes_subtitle': '切换模式后会自动回到播放页，当前模式会高亮显示。',
    'toolbox.sound.soothing.modes_button_label': '模式',
    'toolbox.sound.soothing.mode_filter_all': '全部',
    'toolbox.sound.soothing.mode_filter_favorites': '收藏',
    'toolbox.sound.soothing.mode_filter_recent': '最近',
    'toolbox.sound.soothing.empty_mode_title_favorites': '还没有收藏模式',
    'toolbox.sound.soothing.empty_mode_title_recent': '最近还没有播放记录',
    'toolbox.sound.soothing.empty_mode_subtitle_favorites':
        '给常用模式点亮爱心，之后就能在这里快速切换。',
    'toolbox.sound.soothing.empty_mode_subtitle_recent':
        '切换或播放几个模式后，这里会自动记录最近使用内容。',
    'toolbox.sound.soothing.show_all_modes_label': '查看全部',
    'toolbox.sound.soothing.sleep_timer_button_label': '睡眠定时',
    'toolbox.sound.soothing.timer_off': '关闭',
    'toolbox.sound.soothing.timer_minutes': '{count} 分钟',
    'toolbox.sound.soothing.active_sleep_timer': '睡眠定时 {duration}',
    'toolbox.sound.soothing.track_count_label': '{count} 首曲目',
    'toolbox.sound.soothing.active_mode_label': '当前',
    'toolbox.sound.soothing.favorite_toggle_label': '收藏模式',
    'toolbox.sound.soothing.previous_track_label': '上一首',
    'toolbox.sound.soothing.next_track_label': '下一首',
    'toolbox.sound.soothing.volume_toggle_label': '静音切换',
    'toolbox.sound.soothing.playback_single_loop': '单曲循环',
    'toolbox.sound.soothing.playback_mode_cycle': '主题内顺播',
    'toolbox.sound.soothing.playback_arrangement': '顺次播放',
    'toolbox.sound.soothing.arrangement_not_configured': '顺次播放（未设置）',
    'toolbox.sound.soothing.arrangement_template': '顺次播放 · {name}',
    'toolbox.sound.soothing.arrangement_steps': '顺次播放 · {steps} 段',
    'toolbox.sound.soothing.arrangement_progress':
        '第 {current}/{total} 段 · {mode} · {track} · {repeat}/{max} 次',
    'toolbox.sound.soothing.btn_playback_settings': '播放设置',
    'toolbox.sound.soothing.btn_edit_arrangement': '编辑播放顺序',
    'toolbox.sound.soothing.btn_fullscreen_exit': '退出全屏',
    'toolbox.sound.soothing.btn_fullscreen_enter': '进入全屏',
    'toolbox.sound.soothing.my_arrangement': '我的播放列表',
    'toolbox.sound.soothing.save_arrangement': '保存播放模板',
    'toolbox.sound.soothing.save_arrangement_subtitle': '保存当前播放顺序，方便下次直接使用。',
    'toolbox.sound.soothing.save_arrangement_hint': '例如：睡前 20 分钟',
    'toolbox.sound.soothing.save': '保存',
    'toolbox.sound.soothing.arrangement_saved': '已保存播放模板：{name}',
    'toolbox.sound.soothing.rename_arrangement': '重命名播放模板',
    'toolbox.sound.soothing.rename_hint': '输入新名称',
    'toolbox.sound.soothing.delete_arrangement': '删除播放模板',
    'toolbox.sound.soothing.delete_arrangement_confirm': '确定删除"{name}"？',
    'toolbox.sound.soothing.delete': '删除',
    'toolbox.sound.soothing.playback_order': '播放顺序',
    'toolbox.sound.soothing.playback_order_desc':
        '默认单曲重复。切换为顺次播放后，可按设定顺序自动切换主题和曲目。',
    'toolbox.sound.soothing.arrangement_not_saved': '播放顺序未保存',
    'toolbox.sound.soothing.arrangement_steps_info':
        '{steps} 段 · 已保存模板 {templates} 个',
    'toolbox.sound.soothing.save_current': '保存当前顺序',
    'toolbox.sound.soothing.load_saved': '加载模板',
    'toolbox.sound.soothing.template_steps': '{count} 段',
    'toolbox.sound.soothing.rename': '重命名',
    'toolbox.sound.soothing.arrangement_steps_title': '播放步骤',
    'toolbox.sound.soothing.add_current': '添加当前曲目',
    'toolbox.sound.soothing.theme': '主题',
    'toolbox.sound.soothing.track': '曲目',
    'toolbox.sound.soothing.repeats': '重复次数',
    'toolbox.sound.soothing.apply': '应用',

    'toolbox.sound.bowls.appbar_title': '空灵音钵',
    'toolbox.sound.bowls.page_subtitle': '十一组自然音阶与四套钵体音色，长时间聆听也很温润舒适。',
    'toolbox.sound.bowls.voices_section_title': '音色',
    'toolbox.sound.bowls.voices_section_subtitle': '四套钵体谐波，慢慢换着听',
    'toolbox.sound.bowls.frequency_menu_title': '频率菜单',
    'toolbox.sound.bowls.frequency_menu_subtitle': '七脉轮与古典共振频率',
    'toolbox.sound.bowls.today_suggestion_title': '当前共振建议',
    'toolbox.sound.bowls.today_suggestion_body':
        '夜里想要沉一点，优先尝试"深邃 + 地球 / 174 Hz"；白天短时调息，"水晶 + 和谐 / 528 Hz / 639 Hz"会更轻一些。',
    'toolbox.sound.bowls.nature_tuned_tones': '自然色调谐频率',
    'toolbox.sound.bowls.soft_spectral_decay': '柔和扩散衰减',
    'toolbox.sound.bowls.pull_up_sheet_controls': '上拉调整面板',
    'toolbox.sound.bowls.autoplay_title': '自动播放',
    'toolbox.sound.bowls.autoplay_subtitle': '慢而宽地重复，不要急促敲击',
    'toolbox.sound.bowls.interval_label': '间隔时间',
    'toolbox.sound.bowls.haptics_title': '触感反馈',
    'toolbox.sound.bowls.haptics_subtitle': '手动敲击时提供轻微反馈',
    'toolbox.sound.bowls.btn_pause_autoplay': '暂停自动敲击',
    'toolbox.sound.bowls.btn_start_autoplay': '开始自动敲击',
    'toolbox.sound.bowls.btn_stop_resonance': '停止余振',
    'toolbox.sound.bowls.btn_mute': '点击静音',
    'toolbox.sound.bowls.btn_enable_sound': '点击恢复声音',
    'toolbox.sound.bowls.back_to_toolbox': '返回工具箱',
    'toolbox.sound.bowls.sheet_title': '调音与节律',
    'toolbox.sound.bowls.sheet_subtitle': '挑一条频率，选一只音色，按你想要的节奏慢慢敲。',
    'toolbox.sound.bowls.sheet_frequency_menu': '频率菜单',
    'toolbox.sound.bowls.sheet_frequency_subtitle': '七脉轮与古典共振频率',
    'toolbox.sound.bowls.sheet_chakra_group': '七脉轮',
    'toolbox.sound.bowls.sheet_resonance_group': '共振频率',
    'toolbox.sound.bowls.sheet_voices_title': '音色',
    'toolbox.sound.bowls.sheet_voices_subtitle': '四套钵体谐波',
    'toolbox.sound.bowls.sheet_autoplay_title': '自动播放',
    'toolbox.sound.bowls.sheet_autoplay_subtitle': '慢而宽地重复，不要急促敲击',
    'toolbox.sound.bowls.sheet_interval': '间隔时间',
    'toolbox.sound.bowls.sheet_haptics_title': '触感反馈',
    'toolbox.sound.bowls.sheet_haptics_subtitle': '手动敲击时给一点轻微反馈',
    'toolbox.sound.bowls.sheet_pause_autoplay': '暂停自动敲击',
    'toolbox.sound.bowls.sheet_start_autoplay': '开始自动敲击',
    'toolbox.sound.bowls.sheet_stop_resonance': '停止余振',
    'toolbox.sound.bowls.btn_close': '收起',
    'toolbox.sound.bowls.auto_interval_label': '每 {interval} 秒自动敲击',
    'toolbox.sound.bowls.tap_hint': '轻触音钵，听它从敲击、扩散到归静。',
    'toolbox.sound.bowls.bowl_semantics': '\u6572\u51fb\u97f3\u94b5',
    'toolbox.sound.bowls.auto_summary_suffix':
        ' \u00b7 \u81ea\u52a8 {interval}s',

    // B3: sound harp/guitar/violin/flute/triangle
    'toolbox.sound.flute.airy': '\u7a7a\u6c14',
    'toolbox.sound.flute.airy_flow': '\u7a7a\u6c14\u6d41',
    'toolbox.sound.flute.alto': '\u4e2d\u97f3',
    'toolbox.sound.flute.bamboo': '\u7af9\u611f',
    'toolbox.sound.flute.bamboo_breath': '\u7af9\u97f5\u547c\u5438',
    'toolbox.sound.flute.blow_off': '\u5439\u6c14\u5173\u95ed',
    'toolbox.sound.flute.blow_on': '\u5439\u6c14\u5f00\u542f',
    'toolbox.sound.flute.blow_sensor': '\u5439\u6c14\u68c0\u6d4b',
    'toolbox.sound.flute.breath': '\u5439\u594f',
    'toolbox.sound.flute.breath_2': '\u6c14\u606f',
    'toolbox.sound.flute.breath_3': '\u6c14\u606f {value}%',
    'toolbox.sound.flute.breath_and_space': '\u6c14\u606f\u4e0e\u7a7a\u95f4',
    'toolbox.sound.flute.brighter_lead_tone_with_stronger':
        '\u66f4\u4eae\u3001\u66f4\u9760\u524d\uff0c\u9002\u5408\u65cb\u5f8b\u53e5\u7684\u7a81\u51fa\u3002',
    'toolbox.sound.flute.clay_ocarina': '\u9676\u7b1b',
    'toolbox.sound.flute.disable_blow_sensor':
        '\u5173\u95ed\u5439\u6c14\u68c0\u6d4b',
    'toolbox.sound.flute.dorian': '\u591a\u5229\u4e9a',
    'toolbox.sound.flute.enable_blow_sensor':
        '\u5f00\u542f\u5439\u6c14\u68c0\u6d4b',
    'toolbox.sound.flute.flute_settings': '\u957f\u7b1b\u8bbe\u7f6e',
    'toolbox.sound.flute.full_screen': '\u5168\u5c4f',
    'toolbox.sound.flute.gentler_attacks_and_a_more':
        '\u7af9\u611f\u66f4\u5f3a\uff0c\u8d77\u97f3\u66f4\u67d4\uff0c\u9002\u5408\u5b89\u9759\u7684\u4e94\u58f0\u97f3\u9636\u5373\u5174\u3002',
    'toolbox.sound.flute.hollow': '\u7a7a\u8154',
    'toolbox.sound.flute.jade_flute': '\u7389\u7b1b',
    'toolbox.sound.flute.lead': '\u9886\u594f',
    'toolbox.sound.flute.lead_solo': '\u72ec\u594f\u9886\u594f',
    'toolbox.sound.flute.long_metal': '\u957f\u94c1\u7b1b',
    'toolbox.sound.flute.lydian': '\u5229\u5e95\u4e9a',
    'toolbox.sound.flute.major': '\u5927\u8c03',
    'toolbox.sound.flute.material': '\u6750\u8d28\u97f3\u8272',
    'toolbox.sound.flute.microphone_permission_unavailable':
        '\u9ea6\u514b\u98ce\u6743\u9650\u4e0d\u53ef\u7528',
    'toolbox.sound.flute.microphone_permission_unavailable_touch_play':
        '\u9ea6\u514b\u98ce\u6743\u9650\u4e0d\u53ef\u7528\uff0c\u5f53\u524d\u4ec5\u53ef\u4f7f\u7528\u89e6\u63a7\u6f14\u594f\u3002',
    'toolbox.sound.flute.mixolydian': '\u6df7\u5408\u5229\u5e95\u4e9a',
    'toolbox.sound.flute.natural_breathy_tone_for_gentle':
        '\u81ea\u7136\u6c14\u606f\u611f\uff0c\u9002\u5408\u8f7b\u67d4\u6f14\u594f\u3002',
    'toolbox.sound.flute.natural_minor': '\u81ea\u7136\u5c0f\u8c03',
    'toolbox.sound.flute.off': '\u5173\u95ed',
    'toolbox.sound.flute.pentatonic': '\u4e94\u58f0\u97f3\u9636',
    'toolbox.sound.flute.preset_pack': '\u9884\u8bbe\u5305',
    'toolbox.sound.flute.rebuild_the_flute_body_finger':
        '\u6309\u624b\u673a\u7ad6\u5c4f\u91cd\u6392\u957f\u7b1b\u673a\u8eab\u3001\u6309\u5b54\u548c\u97f3\u9636\u6309\u94ae\uff0c\u4fdd\u7559\u89e6\u63a7\u4e0e\u5439\u6c14\u4e24\u79cd\u6f14\u594f\u8def\u5f84\u3002',
    'toolbox.sound.flute.scale': '\u8c03\u5f0f',
    'toolbox.sound.flute.settings': '\u8bbe\u7f6e',
    'toolbox.sound.flute.short_metal': '\u77ed\u94c1\u7b1b',
    'toolbox.sound.flute.space': '\u7a7a\u95f4 {value}%',
    'toolbox.sound.flute.tail': '\u5c3e\u97f3 {value}%',
    'toolbox.sound.flute.threshold_current':
        '\u5439\u6c14\u9608\u503c {pct}% \u00b7 \u5f53\u524d {current}%',
    'toolbox.sound.flute.threshold_current_holes':
        '\u5439\u6c14\u9608\u503c {pct}% \u00b7 \u5f53\u524d {current}% \u00b7 \u6309\u5b54 {holes}',
    'toolbox.sound.flute.timbre': '\u97f3\u8272\u62df\u771f',
    'toolbox.sound.flute.velvet': '\u7ed2\u611f',
    'toolbox.sound.flute.vertical_flute': '\u7eb5\u5411\u957f\u7b1b',
    'toolbox.sound.flute.warm_alto': '\u6696\u97f3\u4e2d\u97f3',
    'toolbox.sound.flute.warmer_midrange_and_softer_tail':
        '\u66f4\u539a\u5b9e\u7684\u4e2d\u9891\u548c\u66f4\u67d4\u548c\u5c3e\u97f3\uff0c\u9002\u5408\u6c1b\u56f4\u94fa\u5e95\u3002',
    'toolbox.sound.flute.wood_flute': '\u6728\u7b1b',
    'toolbox.sound.guitar.ambient_chime': '\u6c1b\u56f4\u6cdb\u97f3',
    'toolbox.sound.guitar.chord_and_capo':
        '\u548c\u5f26\u4e0e\u53d8\u8c03\u5939',
    'toolbox.sound.guitar.clear_steelcore_tone_tuned_for':
        '\u6e05\u6670\u6709\u529b\u7684\u94a2\u5f26\u6838\u5fc3\uff0c\u9002\u5408\u8282\u594f\u626b\u5f26\u3002',
    'toolbox.sound.guitar.guitar_settings': '\u5409\u4ed6\u8bbe\u7f6e',
    'toolbox.sound.guitar.guitar_stage': '\u5409\u4ed6\u821e\u53f0',
    'toolbox.sound.guitar.longer_shimmer_and_overtones_for':
        '\u66f4\u957f\u6cdb\u97f3\u548c\u5c3e\u97f5\uff0c\u9002\u5408\u6c1b\u56f4\u94fa\u5e95\u3002',
    'toolbox.sound.guitar.nylon_finger': '\u5c3c\u9f99\u6307\u5f39',
    'toolbox.sound.guitar.open_ring': '\u5f00\u653e\u5ef6\u97f3',
    'toolbox.sound.guitar.palm_mute': '\u624b\u638c\u95f7\u97f3',
    'toolbox.sound.guitar.palm_mute_2': '\u95f7\u97f3',
    'toolbox.sound.guitar.pick_a_chord_pluck_or':
        '\u9009\u5b9a\u548c\u5f26\u540e\u53ef\u76f4\u63a5\u70b9\u5f26\u6216\u6ed1\u626b\uff0c\u53d8\u8c03\u5939\u4f1a\u6574\u4f53\u62ac\u9ad8\u97f3\u9ad8\u3002',
    'toolbox.sound.guitar.pick_position': '\u62e8\u5f26\u4f4d\u7f6e {value}%',
    'toolbox.sound.guitar.resonance': '\u5171\u9e23 {value}%',
    'toolbox.sound.guitar.resonance_shapes_body_response_and':
        '\u5171\u9e23\u63a7\u5236\u7434\u4f53\u54cd\u5e94\uff0c\u62e8\u5f26\u4f4d\u7f6e\u63a7\u5236\u4eae\u5ea6\u4e0e\u9897\u7c92\u611f\u3002',
    'toolbox.sound.guitar.rounder_and_softer_for_slow':
        '\u66f4\u5706\u6da6\u67d4\u548c\uff0c\u9002\u5408\u6162\u901f\u5206\u89e3\u548c\u5355\u97f3\u62e8\u594f\u3002',
    'toolbox.sound.guitar.shortens_sustain_and_tightens_upper':
        '\u5f00\u542f\u540e\u4f1a\u7f29\u77ed\u5ef6\u97f3\uff0c\u66f4\u9002\u5408\u8282\u594f\u578b\u626b\u5f26\u3002',
    'toolbox.sound.guitar.steel_strum': '\u94a2\u5f26\u626b\u5f26',
    'toolbox.sound.guitar.strum_down': '\u4e0b\u626b',
    'toolbox.sound.guitar.strum_up': '\u4e0a\u626b',
    'toolbox.sound.guitar.swipe_vertically_to_strum_tap':
        '\u7eb5\u5411\u6ed1\u52a8\u53ef\u626b\u5f26\uff1b\u70b9\u6309\u5355\u6839\u7434\u5f26\u53ef\u89e6\u53d1\u5355\u97f3\u62e8\u594f\u3002',
    'toolbox.sound.guitar.tone_shaping': '\u97f3\u8272\u5851\u5f62',
    'toolbox.sound.guitar.swipe_label': '\u6ed1\u626b',
    'toolbox.sound.guitar.strum_label': '\u6ed1\u52a8\u626b\u5f26',
    'toolbox.sound.guitar.phone_layout_sub':
        '\u624b\u673a\u4f18\u5148\u4fdd\u7559\u4e3b\u626b\u5f26\u533a\u57df\uff0c\u548c\u5f26\u4e0e\u53d8\u8c03\u5939\u6536\u8fdb\u7d27\u51d1\u63a7\u5236\u533a\u3002',
    'toolbox.sound.guitar.desktop_layout_sub':
        '\u626b\u5f26\u533a\u57df\u4fdd\u6301\u4e3b\u89c6\u89c9\uff0c\u548c\u5f26\u3001\u53d8\u8c03\u5939\u4e0e\u97f3\u8272\u63a7\u5236\u56f4\u7ed5\u5176\u5e03\u5c40\u3002',
    'toolbox.sound.harp.a_minor': 'A\u5c0f\u8c03',
    'toolbox.sound.harp.add9': '\u52a0\u4e5d',
    'toolbox.sound.harp.advanced': '\u9ad8\u7ea7\u5fae\u8c03',
    'toolbox.sound.harp.arpeggio': '\u7435\u97f3\u6a21\u5f0f',
    'toolbox.sound.harp.ascending_sweep':
        '\u8fde\u7eed\u4e0a\u884c\u626b\u5f26\u3002',
    'toolbox.sound.harp.aurora': '\u6781\u5149',
    'toolbox.sound.harp.auto_arpeggio': '\u81ea\u52a8\u7435\u97f3',
    'toolbox.sound.harp.balanced_and_soft': '\u5e73\u8861\u67d4\u548c\u3002',
    'toolbox.sound.harp.balanced_sustain_for_melodic_passages':
        '\u9002\u5408\u65cb\u5f8b\u7ebf\u6761\u7684\u5e73\u8861\u5ef6\u97f3\u3002',
    'toolbox.sound.harp.bright': '\u660e\u4eae',
    'toolbox.sound.harp.c_lydian': 'C\u5229\u5e95\u4e9a',
    'toolbox.sound.harp.c_major': 'C\u5927\u8c03',
    'toolbox.sound.harp.cascade': '\u7011\u5e03',
    'toolbox.sound.harp.chamber_soft': '\u5ba4\u5185\u67d4\u548c',
    'toolbox.sound.harp.chord': '\u548c\u5f26',
    'toolbox.sound.harp.chord_2': '\u548c\u5f26\u8109\u51b2',
    'toolbox.sound.harp.chord_resonance': '\u548c\u5f26\u5171\u632f',
    'toolbox.sound.harp.chord_root':
        '\u548c\u5f26\u6839\u97f3 {current} / {total}',
    'toolbox.sound.harp.clear_attack_for_active_strum':
        '\u8d77\u97f3\u66f4\u6e05\u695a\uff0c\u9002\u5408\u626b\u5f26\u3002',
    'toolbox.sound.harp.concert': '\u97f3\u4e50\u5385',
    'toolbox.sound.harp.concert_nylon': '\u97f3\u4e50\u4f1a\u5c3c\u9f99',
    'toolbox.sound.harp.crystal': '\u6c34\u666f',
    'toolbox.sound.harp.custom': '\u81ea\u5b9a\u4e49',
    'toolbox.sound.harp.d_dorian': 'D\u591a\u5229\u4e9a',
    'toolbox.sound.harp.damping': '\u963b\u5c3c {value}',
    'toolbox.sound.harp.damping_sweep_deadzone_and_chord':
        '\u963b\u5c3c\u3001\u626b\u5f26\u6b7b\u533a\u4e0e\u548c\u5f26\u6839\u97f3\u3002',
    'toolbox.sound.harp.ember': '\u4f59\u70ec',
    'toolbox.sound.harp.ethereal_harp': '\u7a7a\u7075\u7ad6\u7434',
    'toolbox.sound.harp.glass': '\u73bb\u7483',
    'toolbox.sound.harp.glide': '\u6ed1\u884c',
    'toolbox.sound.harp.hide_tip': '收起提示',
    'toolbox.sound.harp.high_realism_presets':
        '\u9ad8\u771f\u5b9e\u5ea6\u9884\u8bbe',
    'toolbox.sound.harp.hirajoshi': '\u5e73\u8c03\u5b50',
    'toolbox.sound.harp.horizontal': '\u6a2a\u5f26',
    'toolbox.sound.harp.ivory_wood': '\u8c61\u7259\u6728\u8d28',
    'toolbox.sound.harp.jade': '\u7fe1\u7fe0',
    'toolbox.sound.harp.layout': '\u5e03\u5c40',
    'toolbox.sound.harp.maj7': '\u5927\u4e03',
    'toolbox.sound.harp.major': '\u5927\u4e09\u548c\u5f26',
    'toolbox.sound.harp.min7': '\u5c0f\u4e03',
    'toolbox.sound.harp.minor': '\u5c0f\u4e09\u548c\u5f26',
    'toolbox.sound.harp.moon': '\u6708\u5149',
    'toolbox.sound.harp.more_body_and_slower_tail':
        '\u66f4\u539a\u5b9e\u3001\u5c3e\u97f3\u66f4\u6162\u3002',
    'toolbox.sound.harp.muted': '\u9759\u97f3',
    'toolbox.sound.harp.nylon': '\u5c3c\u9f99',
    'toolbox.sound.harp.palette': '\u4e3b\u9898',
    'toolbox.sound.harp.pedal_harp': '\u8e0f\u677f\u7ad6\u7434',
    'toolbox.sound.harp.pedalharp_like_balance_and_sustain':
        '\u63a5\u8fd1\u8e0f\u677f\u7ad6\u7434\u7684\u5747\u8861\u5ef6\u97f3\u3002',
    'toolbox.sound.harp.preset': '\u9884\u8bbe',
    'toolbox.sound.harp.pulse_active_chord_tones':
        '\u8109\u51b2\u5f39\u594f\u5f53\u524d\u548c\u5f26\u97f3\u3002',
    'toolbox.sound.harp.reverb': '\u6b8b\u54cd',
    'toolbox.sound.harp.reverb_2': '\u6b8b\u54cd {value}%',
    'toolbox.sound.harp.round_body_with_controlled_hall':
        '\u5706\u6da6\u7434\u4f53\u4e0e\u53d7\u63a7\u5385\u5802\u5c3e\u97f3\u3002',
    'toolbox.sound.harp.round_body_with_light_transient':
        '\u5706\u6da6\u67d4\u548c\uff0c\u77ac\u6001\u8f83\u8f7b\u3002',
    'toolbox.sound.harp.scale_harmony': '\u8c03\u5f0f\u4e0e\u548c\u58f0',
    'toolbox.sound.harp.sharper_upper_harmonics':
        '\u9ad8\u9891\u66f4\u4eae\uff0c\u9897\u7c92\u66f4\u6e05\u6670\u3002',
    'toolbox.sound.harp.silk': '\u4e1d\u7ef8',
    'toolbox.sound.harp.soft_fingerpluck_with_gentle_bloom':
        '\u67d4\u548c\u62e8\u5f26\uff0c\u4f59\u97f5\u8212\u5c55\u3002',
    'toolbox.sound.harp.sound_on': '\u58f0\u97f3\u5f00',
    'toolbox.sound.harp.steel': '\u94a2\u5f26',
    'toolbox.sound.harp.steel_studio': '\u94a2\u5f26\u5f55\u97f3\u68da',
    'toolbox.sound.harp.stronger_core_and_brighter_attack':
        '\u6838\u5fc3\u66f4\u5f3a\uff0c\u62e8\u5f26\u66f4\u4eae\u3002',
    'toolbox.sound.harp.sus2': '\u6302\u4e8c',
    'toolbox.sound.harp.sus4': '\u6302\u56db',
    'toolbox.sound.harp.sweep_deadzone_px':
        '\u626b\u5f26\u6b7b\u533a {value} px',
    'toolbox.sound.harp.tap_a_note_then_glide':
        '\u8f7b\u89e6\u5355\u97f3\uff0c\u987a\u7740\u7434\u5f26\u6ed1\u52a8\u53ef\u626b\u5f26\u3002',
    'toolbox.sound.harp.tap_for_single_note_swipe':
        'Tap for single note, swipe for sweep.',
    'toolbox.sound.harp.theme_timbre': '\u4e3b\u9898\u4e0e\u97f3\u8272',
    'toolbox.sound.harp.thin_body_and_sparkling_top':
        '\u66f4\u8584\u66f4\u4eae\uff0c\u6cdb\u97f3\u95ea\u70c1\u3002',
    'toolbox.sound.harp.tight_transient_and_clear_note':
        '\u77ac\u6001\u7d27\u81f4\uff0c\u97f3\u7b26\u5206\u79bb\u6e05\u6670\u3002',
    'toolbox.sound.harp.timbre': '\u97f3\u8272',
    'toolbox.sound.harp.timbre_scale_chord_and_feel':
        '\u97f3\u8272\u3001\u8c03\u5f0f\u3001\u548c\u5f26\u4e0e\u624b\u611f\u5df2\u6536\u5165\u53e3\u5e95\u677f\u3002',
    'toolbox.sound.harp.up_then_down':
        '\u5148\u4e0a\u884c\u518d\u4e0b\u884c\u3002',
    'toolbox.sound.harp.vertical': '\u7ad6\u5f26',
    'toolbox.sound.harp.warm': '\u6e29\u6696',
    'toolbox.sound.harp.zen_pentatonic': '\u7985\u610f\u4e94\u58f0\u97f3\u9636',
    'toolbox.sound.triangle.accent': '\u91cd\u51fb',
    'toolbox.sound.triangle.aluminum': '\u94dd\u5236',
    'toolbox.sound.triangle.balanced_brightness_and_decay_close':
        '\u660e\u4eae\u4e0e\u5ef6\u97f3\u66f4\u5e73\u8861\uff0c\u66f4\u63a5\u8fd1\u7ba1\u5f26\u8bed\u5883\u3002',
    'toolbox.sound.triangle.brass': '\u9ec4\u94dc',
    'toolbox.sound.triangle.bright_ring': '\u660e\u4eae\u632f\u94c3',
    'toolbox.sound.triangle.brighter_attack_and_stronger_ring':
        '\u66f4\u4eae\u66f4\u8106\uff0c\u5c3e\u97f3\u66f4\u660e\u663e\uff0c\u9002\u5408\u5f3a\u8c03\u62cd\u70b9\u3002',
    'toolbox.sound.triangle.damping': '\u963b\u5c3c {value}%',
    'toolbox.sound.triangle.left_is_softer_right_is':
        '\u5de6\u4fa7\u66f4\u67d4\uff0c\u53f3\u4fa7\u66f4\u4eae\uff1b\u6eda\u594f\u6a21\u5f0f\u9002\u5408\u8fde\u7eed\u7d27\u51d1\u7684\u5f3a\u8c03\u3002',
    'toolbox.sound.triangle.left_softer': '\u5de6\u4fa7\u66f4\u67d4',
    'toolbox.sound.triangle.material_shapes_overtones_while_strike':
        '\u6750\u8d28\u51b3\u5b9a\u6cdb\u97f3\u8d28\u611f\uff0c\u6572\u51fb\u70b9\u548c\u963b\u5c3c\u51b3\u5b9a\u8106\u5ea6\u4e0e\u5c3e\u97f3\u957f\u5ea6\u3002',
    'toolbox.sound.triangle.orchestral_ring': '\u7ba1\u5f26\u632f\u94c3',
    'toolbox.sound.triangle.presets_move_tone_material_and':
        '\u9884\u8bbe\u4f1a\u8054\u52a8\u97f3\u8272\u3001\u9ed8\u8ba4\u6750\u8d28\u548c\u5ef6\u97f3\u957f\u5ea6\u3002',
    'toolbox.sound.triangle.right_brighter': '\u53f3\u4fa7\u66f4\u4eae',
    'toolbox.sound.triangle.ring': '\u632f\u94c3 {value}%',
    'toolbox.sound.triangle.roll': '\u6eda\u594f',
    'toolbox.sound.triangle.single': '\u5355\u51fb',
    'toolbox.sound.triangle.soft_ring': '\u67d4\u548c\u632f\u94c3',
    'toolbox.sound.triangle.softer_highs_and_a_shorter':
        '\u66f4\u67d4\u548c\u7684\u9ad8\u9891\u548c\u66f4\u77ed\u7684\u5c3e\u97f3\uff0c\u9002\u5408\u8f7b\u8282\u594f\u70b9\u7f00\u3002',
    'toolbox.sound.triangle.steel': '\u94a2\u5236',
    'toolbox.sound.triangle.strike': '\u6572\u51fb\u70b9 {value}%',
    'toolbox.sound.triangle.strike_now': '\u7acb\u5373\u51fb\u6253',
    'toolbox.sound.triangle.strike_stage': '\u51fb\u6253\u821e\u53f0',
    'toolbox.sound.triangle.tap_directly_on_the_triangle':
        '\u76f4\u63a5\u5728\u4e09\u89d2\u94c1\u753b\u9762\u4e0a\u70b9\u6309\uff1a\u5de6\u67d4\u53f3\u4eae\uff0c\u6a21\u5f0f\u51b3\u5b9a\u662f\u5355\u51fb\u3001\u91cd\u51fb\u8fd8\u662f\u6eda\u594f\u3002',
    'toolbox.sound.triangle.tone_and_decay': '\u97f3\u8272\u4e0e\u8870\u51cf',
    'toolbox.sound.triangle.triangle_settings':
        '\u4e09\u89d2\u94c1\u8bbe\u7f6e',
    'toolbox.sound.violin.a_woody': 'A \u6728\u8d28',
    'toolbox.sound.violin.ab_voicing': 'A/B \u5fae\u8c03',
    'toolbox.sound.violin.b_bright': 'B \u4eae\u5f13',
    'toolbox.sound.violin.balanced_solo_tone_for_melodic':
        '\u5e73\u8861\u7684\u72ec\u594f\u97f3\u8272\uff0c\u9002\u5408\u65cb\u5f8b\u6ed1\u97f3\u3002',
    'toolbox.sound.violin.bow_and_space': '\u5f13\u538b\u4e0e\u7a7a\u95f4',
    'toolbox.sound.violin.bow_tone':
        '\u5f13\u538b {pct}% \u00b7 \u97f3\u8272 {tone} \u00b7 {variant}',
    'toolbox.sound.violin.brighter_harmonics_with_a_cleaner':
        '\u66f4\u4eae\u7684\u6cdb\u97f3\u548c\u66f4\u6e05\u6670\u7684\u524d\u7f18\uff0c\u9002\u5408\u7a7a\u7075\u94fa\u5e95\u3002',
    'toolbox.sound.violin.chromatic': '\u534a\u97f3\u9636',
    'toolbox.sound.violin.expose_bow_pressure_and_reverb':
        '\u5f00\u653e\u5f13\u538b\u548c\u6b8b\u54cd\u53c2\u6570\uff0c\u65b9\u4fbf\u628a\u72ec\u594f\u611f\u4e0e\u7a7a\u95f4\u611f\u62c6\u5f00\u63a7\u5236\u3002',
    'toolbox.sound.violin.fingerboard_stage': '\u6307\u677f\u821e\u53f0',
    'toolbox.sound.violin.glass': '\u6676\u4eae',
    'toolbox.sound.violin.glass_harmonic': '\u7a7a\u7075\u6cdb\u97f3',
    'toolbox.sound.violin.last_note': '\u6700\u8fd1\u97f3\u7b26',
    'toolbox.sound.violin.minor': '\u5c0f\u8c03',
    'toolbox.sound.violin.position': '\u628a\u4f4d',
    'toolbox.sound.violin.position_2': '\u628a\u4f4d {value}',
    'toolbox.sound.violin.reverb': '\u6b8b\u54cd {value}%',
    'toolbox.sound.violin.scale_and_position': '\u8c03\u5f0f\u4e0e\u628a\u4f4d',
    'toolbox.sound.violin.softer_bow_pressure_with_a':
        '\u66f4\u67d4\u548c\u7684\u5f13\u538b\u548c\u66f4\u957f\u7684\u5c3e\u97f3\uff0c\u9002\u5408\u6162\u901f\u6b4c\u5531\u6027\u65cb\u5f8b\u3002',
    'toolbox.sound.violin.solo': '\u72ec\u594f',
    'toolbox.sound.violin.solo_bow': '\u72ec\u594f\u8fd0\u5f13',
    'toolbox.sound.violin.strings': '\u5f26\u6570',
    'toolbox.sound.violin.two_fingers_enable_doublestop':
        '\u53cc\u6307\u53ef\u89e6\u53d1\u53cc\u97f3',
    'toolbox.sound.violin.use_scale_categories_and_position':
        '\u7528\u8c03\u5f0f\u5206\u7c7b\u548c\u628a\u4f4d\u7a97\u53e3\u63a7\u5236\u624b\u673a\u5c4f\u5e55\u4e2d\u7684\u6709\u6548\u6f14\u594f\u533a\u95f4\u3002',
    'toolbox.sound.violin.variant_a_is_woodier_and':
        'A \u7248\u7434\u4f53\u66f4\u539a\u3001\u66f4\u6728\u8d28\uff0c\u9002\u5408\u81ea\u7136\u72ec\u594f\u4e0e\u6162\u901f\u65cb\u5f8b\u3002',
    'toolbox.sound.violin.variant_b_is_brighter_and':
        'B \u7248\u524d\u7f18\u66f4\u4eae\u3001\u66f4\u9760\u524d\uff0c\u9002\u5408\u7a7f\u900f\u611f\u66f4\u5f3a\u7684\u72ec\u594f\u3002',
    'toolbox.sound.violin.violin_settings': '\u5c0f\u63d0\u7434\u8bbe\u7f6e',
    'toolbox.sound.violin.warm': '\u67d4\u6696',
    'toolbox.sound.violin.warm_legato': '\u6e29\u6696\u8fde\u5f13',
    'toolbox.sound.violin.phone_subtitle':
        '\u624b\u673a\u4e0a\u652f\u6301\u70b9\u6309\u8d77\u5f13\u3001\u6ed1\u52a8\u6362\u97f3\uff0c\u62ac\u624b\u5373\u505c\uff0c\u4f18\u5148\u4fdd\u8bc1\u6f14\u594f\u8fde\u8d2f\u3002',
    'toolbox.sound.violin.desktop_subtitle':
        '\u6a2a\u5411\u6ed1\u52a8\u6539\u53d8\u91cf\u9ad8\uff0c\u7eb5\u5411\u5207\u6362\u5f26\u4f4d\uff1b\u73b0\u5728\u652f\u6301\u70b9\u6309\u5373\u53d1\u58f0\u3001\u62ac\u624b\u5373\u505c\u3002',

    // B4: \u4e13\u6ce8\u8282\u62cd (sound)
    'toolbox.sound.focus.controlTempo': '\u901f\u5ea6',
    'toolbox.sound.focus.controlTempoDesc':
        '\u8c03\u6574 BPM\uff0c\u7528\u5feb\u6377\u6309\u94ae\u5fae\u8c03\u8282\u594f\u3002',
    'toolbox.sound.focus.controlMeter': '\u62cd\u53f7',
    'toolbox.sound.focus.controlMeterDesc':
        '\u51b3\u5b9a\u5f3a\u5f31\u62cd\u7ed3\u6784\u4e0e\u5207\u5206\u5bc6\u5ea6\u3002',
    'toolbox.sound.focus.controlTimbre': '\u62cd\u70b9\u97f3\u8272',
    'toolbox.sound.focus.controlTimbreDesc':
        '\u9009\u62e9\u62cd\u70b9\u6572\u51fb\u7684\u58f0\u97f3\u8d28\u611f\u3002',
    'toolbox.sound.focus.controlArrangement': '\u62cd\u6bb5\u7ec4\u5408',
    'toolbox.sound.focus.controlArrangementDesc':
        '\u6309\u5c0f\u8282\u7f16\u7ec4\u5f62\u6210\u6bb5\u843d\uff0c\u8ba9\u8282\u594f\u66f4\u6709\u5c42\u6b21\u3002',
    'toolbox.sound.focus.singleBarLoop': '\u5355\u5c0f\u8282',
    'toolbox.sound.focus.controlMix': '\u6df7\u97f3\u4e0e\u89e6\u611f',
    'toolbox.sound.focus.controlMixDesc':
        '\u5206\u522b\u8c03\u6574\u91cd\u62cd\u3001\u666e\u901a\u62cd\u3001\u5b50\u62cd\u4e0e\u632f\u52a8\u5f3a\u5ea6\u3002',
    'toolbox.sound.focus.controlMixDesc2':
        '\u7cbe\u7ec6\u8c03\u6574\u91cd\u62cd\u3001\u666e\u901a\u62cd\u3001\u5b50\u62cd\u4e0e\u89e6\u611f\u632f\u52a8\u3002',
    'toolbox.sound.focus.hapticsOn': '\u89e6\u611f\u5f00',
    'toolbox.sound.focus.hapticsOff': '\u89e6\u611f\u5173',
    'toolbox.sound.focus.controlStart': '\u5f00\u59cb',
    'toolbox.sound.focus.controlStop': '\u505c\u6b62',
    'toolbox.sound.focus.controlPreviewSound': '\u8bd5\u542c',
    'toolbox.sound.focus.controlFullStage': '\u5168\u5c4f\u821e\u53f0',
    'toolbox.sound.focus.controlOpenControls':
        '\u6253\u5f00\u63a7\u5236\u9762\u677f',
    'toolbox.sound.focus.controlExitFull': '\u9000\u51fa\u5168\u5c4f',
    'toolbox.sound.focus.controlImmersive': '\u6c89\u6d78\u6a21\u5f0f',
    'toolbox.sound.focus.controlHapticsOn': '\u89e6\u611f\u5f00',
    'toolbox.sound.focus.controlHapticsOff': '\u89e6\u611f\u5173',
    'toolbox.sound.focus.controlTapHint':
        '\u8f7b\u89e6\u753b\u9762\u5f00\u59cb\u6216\u505c\u6b62\uff0c\u4fdd\u6301\u4e13\u6ce8\u8282\u594f\u3002',
    'toolbox.sound.focus.animNameWarm': '\u6696\u8272\u8def\u5f84',
    'toolbox.sound.focus.animNameStill': '\u9759\u84dd\u73af\u7ebf',
    'toolbox.sound.focus.animNameClear': '\u6e05\u6c34\u8109\u7edc',
    'toolbox.sound.focus.animNamePrecision': '\u7cbe\u5bc6\u523b\u5ea6',
    'toolbox.sound.focus.animNameStep': '\u6b65\u9635\u8def\u5f84',
    'toolbox.sound.focus.soundNamePendulum': '\u949f\u6446',
    'toolbox.sound.focus.soundNamePulse': '\u547c\u5438',
    'toolbox.sound.focus.soundNameDrop': '\u9732\u6ef4',
    'toolbox.sound.focus.soundNameTick': '\u673a\u68b0',
    'toolbox.sound.focus.soundNameStep': '\u6b65\u4f10',
    'toolbox.sound.focus.immersiveControlsTitle': '\u63a7\u5236',
    'toolbox.sound.focus.immersiveControlsDesc':
        '\u8f7b\u89e6\u5e95\u90e8\u8fb9\u7f18\u5373\u53ef\u5524\u51fa\u63a7\u5236\u9762\u677f\uff0c\u65e0\u9700\u9000\u51fa\u5168\u5c4f\u3002',
    'toolbox.sound.focus.immersiveExitSheet': '\u6536\u8d77',
    'toolbox.sound.focus.immersiveOpenControls': '\u6253\u5f00\u63a7\u5236',
    'toolbox.sound.focus.immersiveExitFull': '\u9000\u51fa\u5168\u5c4f',
    'toolbox.sound.focus.immersiveCurrentBeat': '{label}',
    'toolbox.sound.focus.immersiveReady': '\u5c31\u7eea',
    'toolbox.sound.focus.immersiveHint':
        '\u8f7b\u89e6\u5f00\u59cb\u8282\u62cd\uff0c\u8ddf\u968f\u8282\u594f\u8fdb\u5165\u4e13\u6ce8\u3002',
    'toolbox.sound.focus.stageBeatPath': '\u8282\u62cd\u8def\u5f84',
    'toolbox.sound.focus.stageSubbeat': '{label} \u5b50\u62cd',
    'toolbox.sound.focus.stageMoving': '\u8fdb\u884c\u4e2d',
    'toolbox.sound.focus.stageReady': '\u5c31\u7eea',
    'toolbox.sound.focus.stagePulseInMotion': '\u8282\u62cd\u8fdb\u884c\u4e2d',
    'toolbox.sound.focus.stageWaitingBeatOne': '\u7b49\u5f85\u7b2c\u4e00\u62cd',
    'toolbox.sound.focus.stageCycleLabel': '\u7b2c {label} \u8f6e',
    'toolbox.sound.focus.stagePatternLabel': '\u62cd\u6bb5 {label}',
    'toolbox.sound.focus.stagePhraseLabel': '\u4e50\u53e5 {label}',
    'toolbox.sound.focus.stageHapticsOn': '\u89e6\u611f\u5f00',
    'toolbox.sound.focus.stageHapticsOff': '\u89e6\u611f\u5173',
    'toolbox.sound.focus.stageBeatLabel': '\u62cd',
    'toolbox.sound.focus.stageSubLabel': '\u5b50\u62cd',
    'toolbox.sound.focus.stageSegmentS': '\u6bb5',
    'toolbox.sound.focus.stageBeatsUnit': ' \u62cd',
    'toolbox.sound.focus.stagePulseMoving': '\u8282\u62cd\u8fd0\u884c\u4e2d',
    'toolbox.sound.focus.stageTrackReady': '\u5c31\u7eea',
    'toolbox.sound.focus.stageSummaryRunning': '\u8282\u594f\u8fdb\u884c\u4e2d',
    'toolbox.sound.focus.stageSummaryIdle': '\u51c6\u5907\u5f00\u59cb',
    'toolbox.sound.focus.stageBeatShort': '\u62cd',
    'toolbox.sound.focus.stageSubShort': '\u5b50',
    'toolbox.sound.focus.stageLoopLabel': '\u5f80\u590d',
    'toolbox.sound.focus.tempoLabel': '{bpm} BPM \u00b7 {sec} \u79d2/\u62cd',
    'toolbox.sound.focus.meterDesc':
        '\u62cd\u53f7\u51b3\u5b9a\u5f3a\u5f31\u62cd\u7ed3\u6784\uff0c\u5b50\u62cd\u51b3\u5b9a\u6bcf\u62cd\u5185\u90e8\u5207\u5206\uff1b\u4e24\u8005\u5171\u540c\u5f71\u54cd\u8282\u594f\u63a8\u8fdb\u548c\u62cd\u6bb5\u7ec4\u5408\u3002',
    'toolbox.sound.focus.meterSubDiv': '\u5b50\u62cd \u00d7{div}',
    'toolbox.sound.focus.styleDesc':
        '\u52a8\u753b\u4e0e\u97f3\u8272\u9ed8\u8ba4\u63a8\u8350\u642d\u914d\uff0c\u4e5f\u53ef\u4ee5\u81ea\u7531\u6df7\u642d\u3002',
    'toolbox.sound.focus.previewButton': '\u8bd5\u542c',
    'toolbox.sound.focus.styleTimbreTitle': '\u62cd\u70b9\u97f3\u8272',
    'toolbox.sound.focus.arrangementEnabled':
        '\u62cd\u6bb5\u7ec4\u5408\u5df2\u5f00\u542f',
    'toolbox.sound.focus.arrangementSingleBar': '\u5355\u5c0f\u8282',
    'toolbox.sound.focus.arrangementLabel':
        '\u5f53\u524d\u62cd\u6bb5\uff1a{label}\uff08\u5171 {total} \u62cd\uff09',
    'toolbox.sound.focus.editButton': '\u7f16\u8f91',
    'toolbox.sound.focus.arrangementDesc':
        '\u901a\u8fc7\u5c0f\u8282\u7f16\u7ec4\u8ba9\u89c6\u89c9\u548c\u97f3\u8272\u5728\u5b8c\u6574\u5468\u671f\u4e2d\u5f62\u6210\u66f4\u660e\u663e\u7684\u6bb5\u843d\u611f\u3002',
    'toolbox.sound.focus.mixMaster': '\u603b\u97f3\u91cf',
    'toolbox.sound.focus.mixAccent': '\u91cd\u62cd',
    'toolbox.sound.focus.mixRegular': '\u666e\u901a\u62cd',
    'toolbox.sound.focus.mixSubdivision': '\u5b50\u62cd',
    'toolbox.sound.focus.mixHapticLabel': '\u89e6\u611f\u53cd\u9988',
    'toolbox.sound.focus.mixHapticDesc':
        '\u5728\u91cd\u62cd\u548c\u6bb5\u843d\u5207\u6362\u65f6\u63d0\u4f9b\u8f7b\u5fae\u632f\u52a8\u63d0\u793a\u3002',

    // --- toolbox hub (B2: Chinese) ---
    'toolbox.hub.page.title': '\u5de5\u5177\u7bb1',
    'toolbox.hub.page.subtitle':
        '\u6d4f\u89c8\u3001\u6574\u7406\u548c\u4e2a\u6027\u5316\u4f60\u7684\u5065\u5eb7\u5de5\u5177\u7bb1\u3002',
    'toolbox.hub.page.section_title': '\u53ef\u7528\u5de5\u5177',
    'toolbox.hub.intro.title_idle':
        '\u4f60\u7684\u5065\u5eb7\u5de5\u5177\u7bb1',
    'toolbox.hub.intro.summary_idle':
        '\u5feb\u901f\u8bbf\u95ee\u7761\u7720\u3001\u4e13\u6ce8\u3001\u97f3\u7597\u548c\u51a5\u60f3\u5de5\u5177\u3002',
    'toolbox.hub.intro.details_idle':
        '\u70b9\u51fb\u4efb\u610f\u5de5\u5177\u5373\u53ef\u6253\u5f00\u3002\u5c06\u6761\u76ee\u62d6\u5165\u5feb\u6377\u9762\u677f\u53ef\u5b9e\u73b0\u4e00\u952e\u8bbf\u95ee\u3002',
    'toolbox.hub.intro.title_editing':
        '\u81ea\u5b9a\u4e49\u4f60\u7684\u5de5\u5177\u7bb1',
    'toolbox.hub.intro.summary_editing':
        '\u9690\u85cf\u4e0d\u5e38\u7528\u7684\u5de5\u5177\uff0c\u91cd\u65b0\u6392\u5e8f\u4f60\u7684\u6536\u85cf\uff0c\u56fa\u5b9a\u5feb\u6377\u65b9\u5f0f\u3002',
    'toolbox.hub.intro.details_editing':
        '\u70b9\u51fb\u773c\u775b\u56fe\u6807\u9690\u85cf\u6216\u6062\u590d\u3002\u62d6\u52a8\u624b\u67c4\u91cd\u65b0\u6392\u5e8f\u3002\u56fa\u5b9a\u7684\u6761\u76ee\u4f1a\u663e\u793a\u5728\u9876\u90e8\u3002',
    'toolbox.hub.intro.highlight_edit':
        '\u9690\u85cf\u6216\u663e\u793a\u5de5\u5177\u4ee5\u5339\u914d\u4f60\u7684\u65e5\u5e38\u8282\u594f\u3002',
    'toolbox.hub.intro.highlight_reorder':
        '\u62d6\u62fd\u6392\u5e8f\uff0c\u8ba9\u5e38\u7528\u5de5\u5177\u89e6\u624b\u53ef\u53ca\u3002',
    'toolbox.hub.intro.highlight_shortcuts':
        '\u5c06\u6700\u5e38\u7528\u7684\u5de5\u5177\u56fa\u5b9a\u5230\u5feb\u6377\u9762\u677f\u3002',
    'toolbox.hub.intro.highlight_restorable':
        '\u9690\u85cf\u7684\u5de5\u5177\u5e76\u672a\u5220\u9664\u2014\u2014\u4e00\u952e\u5373\u53ef\u6062\u590d\u3002',
    'toolbox.hub.intro.help_tooltip':
        '\u5982\u4f55\u4f7f\u7528\u5de5\u5177\u7bb1',
    'toolbox.hub.edit.toggle_enter': '\u81ea\u5b9a\u4e49',
    'toolbox.hub.edit.toggle_exit': '\u5b8c\u6210',
    'toolbox.hub.edit.drag_tooltip': '\u62d6\u52a8\u6392\u5e8f',
    'toolbox.hub.edit.remove_tooltip': '\u9690\u85cf\u6b64\u5de5\u5177',
    'toolbox.hub.edit.confirm_remove_title': '\u9690\u85cf {title}\uff1f',
    'toolbox.hub.edit.confirm_remove_desc':
        '\u6b64\u5de5\u5177\u5c06\u4ece\u5de5\u5177\u7bb1\u4e2d\u9690\u85cf\u3002\u4f60\u53ef\u4ee5\u968f\u65f6\u4ece\u7f16\u8f91\u9762\u677f\u6062\u590d\u5b83\u3002',
    'toolbox.hub.edit.remove_action': '\u9690\u85cf',
    'toolbox.hub.edit.snackbar_hidden': '{title} \u5df2\u9690\u85cf',
    'toolbox.hub.edit.snackbar_restore': '\u64a4\u9500',
    'toolbox.hub.edit.section_title': '\u5de5\u5177\u7bb1\u5e03\u5c40',
    'toolbox.hub.edit.layout_instructions':
        '\u70b9\u51fb\u773c\u775b\u56fe\u6807\u663e\u793a\u6216\u9690\u85cf\u5de5\u5177\u3002\u62d6\u52a8\u624b\u67c4\u91cd\u65b0\u6392\u5e8f\u3002',
    'toolbox.hub.edit.status_visible': '\u53ef\u89c1',
    'toolbox.hub.edit.status_hidden': '\u5df2\u9690\u85cf',
    'toolbox.hub.edit.exit_button': '\u9000\u51fa\u7f16\u8f91',
    'toolbox.hub.edit.restore_button': '\u6062\u590d\u5168\u90e8',
    'toolbox.hub.edit.reset_button': '\u91cd\u7f6e\u5e03\u5c40',
    'toolbox.hub.edit.empty_title': '\u6ca1\u6709\u53ef\u89c1\u5de5\u5177',
    'toolbox.hub.edit.empty_desc_no_hidden':
        '\u6240\u6709\u53ef\u7528\u5de5\u5177\u5f53\u524d\u5747\u53ef\u89c1\u3002\u8981\u9690\u85cf\u5de5\u5177\uff0c\u8bf7\u70b9\u51fb\u5176\u540d\u79f0\u65c1\u8fb9\u7684\u773c\u775b\u56fe\u6807\u3002',
    'toolbox.hub.edit.empty_desc_has_hidden':
        '\u90e8\u5206\u5de5\u5177\u5f53\u524d\u5df2\u9690\u85cf\u3002\u4f7f\u7528\u4e0b\u65b9\u9690\u85cf\u533a\u57df\u6765\u6062\u590d\u5b83\u4eec\u3002',
    'toolbox.hub.edit.empty_hidden_count':
        '\u6709 {count} \u4e2a\u9690\u85cf\u5de5\u5177\u53ef\u7528',
    'toolbox.hub.edit.empty_edit_button':
        '\u6253\u5f00\u7f16\u8f91\u9762\u677f',
    'toolbox.hub.edit.restore_section_title': '\u9690\u85cf\u7684\u5de5\u5177',
    'toolbox.hub.edit.restore_notice':
        '\u70b9\u51fb\u773c\u775b\u56fe\u6807\u6765\u6062\u590d\u9690\u85cf\u7684\u5de5\u5177\u3002',
    'toolbox.hub.edit.restore_action': '\u6062\u590d',

    'toolbox.hub.section.sleep.title': '\u7761\u7720',
    'toolbox.hub.section.sleep.subtitle':
        '\u7761\u7720\u8bc4\u4f30\u3001\u8bb0\u5f55\u3001\u7761\u524d\u653e\u677e\u4e0e\u591c\u9192\u5b89\u629a\u6307\u5357\u3002',
    'toolbox.hub.section.games.title': '\u8ff7\u4f60\u6e38\u620f',
    'toolbox.hub.section.games.subtitle':
        '\u8f7b\u5ea6\u8ba4\u77e5\u6d3b\u52a8\uff0c\u5e2e\u52a9\u8f6c\u79fb\u6ce8\u610f\u529b\u548c\u653e\u677e\u3002',
    'toolbox.hub.section.tests.title': '\u4eba\u7c7b\u6d4b\u8bd5',
    'toolbox.hub.section.tests.subtitle':
        '\u8ba4\u77e5\u4e0e\u884c\u4e3a\u6a21\u5f0f\u7684\u81ea\u6211\u8bc4\u4f30\u5de5\u5177\u3002',
    'toolbox.hub.section.sound.title': '\u58f0\u97f3\u4e0e\u97f3\u4e50',
    'toolbox.hub.section.sound.subtitle':
        '\u8212\u7f13\u8f7b\u97f3\u3001\u7a7a\u7075\u97f3\u94b5\u3001\u7ad6\u7434\u3001\u5409\u4ed6\u3001\u957f\u7b1b\u7b49\u3002',
    'toolbox.hub.section.focus.title': '\u4e13\u6ce8\u4e0e\u6ce8\u610f\u529b',
    'toolbox.hub.section.focus.subtitle':
        '\u8212\u5c14\u7279\u65b9\u683c\u3001\u547c\u5438\u5f15\u5bfc\u4e0e\u6ce8\u610f\u529b\u8bad\u7ec3\u3002',
    'toolbox.hub.section.calm.title': '\u51a5\u60f3\u4e0e\u653e\u677e',
    'toolbox.hub.section.calm.subtitle':
        '\u9759\u5fc3\u5ff5\u73e0\u3001\u6307\u5c16\u6c99\u753b\u4e0e\u6b63\u5ff5\u5de5\u5177\u3002',
    'toolbox.hub.section.life.title': '\u751f\u6d3b\u5b9e\u7528',
    'toolbox.hub.section.life.subtitle':
        '\u65e5\u5e38\u5b9e\u7528\u5de5\u5177\u4e0e\u751f\u6d3b\u65b9\u5f0f\u52a9\u624b\u3002',
    'toolbox.hub.section.crypto.title': '\u52a0\u5bc6\u4e0e\u5b89\u5168',
    'toolbox.hub.section.crypto.subtitle':
        '\u52a0\u5bc6\u3001\u54c8\u5e0c\u4e0e\u5b89\u5168\u5b9e\u7528\u5de5\u5177\u3002',
    'toolbox.hub.section.decision.title': '\u51b3\u7b56\u52a9\u624b',
    'toolbox.hub.section.decision.subtitle':
        '\u5316\u89e3\u9009\u62e9\u56f0\u96be\uff0c\u8ba9\u65e5\u5e38\u7ea0\u7ed3\u53d8\u5f97\u8f7b\u677e\u3002',

    'toolbox.hub.entry.sleep_assistant.title': '\u7761\u7720\u52a9\u624b',
    'toolbox.hub.entry.sleep_assistant.subtitle':
        '\u4e2a\u6027\u5316\u8bc4\u4f30\u3001\u6539\u5584\u8ba1\u5212\u4e0e\u591c\u95f4\u6307\u5bfc\u3002',
    'toolbox.hub.entry.games.title': '\u8ff7\u4f60\u6e38\u620f',
    'toolbox.hub.entry.games.subtitle':
        '\u5feb\u901f\u8ba4\u77e5\u5c0f\u6e38\u620f\uff0c\u5e2e\u52a9\u8f6c\u79fb\u6ce8\u610f\u529b\u3002',
    'toolbox.hub.entry.tests.title': '\u4eba\u7c7b\u6d4b\u8bd5',
    'toolbox.hub.entry.tests.subtitle':
        '\u8ba4\u77e5\u4e0e\u884c\u4e3a\u81ea\u6211\u8bc4\u4f30\u3002',
    'toolbox.hub.entry.soothing.title': '\u8212\u7f13\u8f7b\u97f3',
    'toolbox.hub.entry.soothing.subtitle':
        '\u7cbe\u9009\u7597\u6108\u7cfb\u8f7b\u97f3\u4e50\u4e0e\u52a8\u6001\u547c\u5438\u5149\u6548\u3002',
    'toolbox.hub.entry.harp.title': '\u7ad6\u7434\u4e0e\u5f26\u4e50',
    'toolbox.hub.entry.harp.subtitle':
        '\u6f14\u594f\u7ad6\u7434\u3001\u5409\u4ed6\u3001\u5c0f\u63d0\u7434\u3001\u957f\u7b1b\u548c\u4e09\u89d2\u94c1\u3002',
    'toolbox.hub.entry.bowls.title': '\u7a7a\u7075\u97f3\u94b5',
    'toolbox.hub.entry.bowls.subtitle':
        '\u5341\u4e00\u7ec4\u81ea\u7136\u9891\u7387\u4e0e\u56db\u79cd\u94b5\u4f53\u97f3\u8272\u3002',
    'toolbox.hub.entry.locator.title': '\u58f0\u6e90\u5b9a\u4f4d',
    'toolbox.hub.entry.locator.subtitle':
        '\u4f7f\u7528\u624b\u673a\u9ea6\u514b\u98ce\u5b9a\u4f4d\u5e76\u786e\u8ba4\u58f0\u6e90\u3002',
    'toolbox.hub.entry.beats.title': '\u4e13\u6ce8\u8282\u62cd',
    'toolbox.hub.entry.beats.subtitle':
        '\u7528\u6709\u8282\u594f\u7684\u97f3\u9891\u63d0\u793a\uff0c\u966a\u4f34\u4f60\u7684\u4e13\u6ce8\u65f6\u5149\u3002',
    'toolbox.hub.entry.woodfish.title': '\u8d5b\u535a\u6728\u9c7c',
    'toolbox.hub.entry.woodfish.subtitle':
        '\u7535\u5b50\u6728\u9c7c\uff0c\u5b89\u5fc3\u89e3\u538b\u7684\u8282\u5f8b\u6572\u51fb\u3002',
    'toolbox.hub.entry.schulte.title': '\u8212\u5c14\u7279\u65b9\u683c',
    'toolbox.hub.entry.schulte.subtitle':
        '\u7ecf\u5178\u6ce8\u610f\u529b\u8bad\u7ec3\uff0c\u8ffd\u8e2a\u901f\u5ea6\u4e0e\u51c6\u786e\u5ea6\u3002',
    'toolbox.hub.entry.breathing.title': '\u547c\u5438\u5f15\u5bfc',
    'toolbox.hub.entry.breathing.subtitle':
        '\u5e26\u53ef\u89c6\u5316\u8282\u594f\u7684\u5f15\u5bfc\u547c\u5438\u7ec3\u4e60\u3002',
    'toolbox.hub.entry.beads.title': '\u9759\u5fc3\u5ff5\u73e0',
    'toolbox.hub.entry.beads.subtitle':
        '\u6307\u5c16\u8f7b\u62e8\u5ff5\u73e0\uff0c\u5728\u5b89\u5b81\u8282\u594f\u4e2d\u6c89\u6dc0\u5fc3\u7eea\u3002',
    'toolbox.hub.entry.zen.title': '\u6307\u5c16\u6c99\u753b',
    'toolbox.hub.entry.zen.subtitle':
        '\u4ee5\u6307\u4e3a\u7b14\u3001\u4ee5\u6c99\u4e3a\u7eb8\uff0c\u5728\u65b9\u5bf8\u4e4b\u95f4\u653e\u677e\u5fc3\u5883\u3002',
    'toolbox.hub.entry.life.title': '\u751f\u6d3b\u5b9e\u7528',
    'toolbox.hub.entry.life.subtitle':
        '\u65e5\u5e38\u751f\u6d3b\u7684\u5b9e\u7528\u5de5\u5177\u3002',
    'toolbox.hub.entry.crypto.title': '\u52a0\u5bc6\u5b89\u5168',
    'toolbox.hub.entry.crypto.subtitle':
        '\u52a0\u5bc6\u3001\u54c8\u5e0c\u4e0e\u6570\u636e\u5b89\u5168\u5de5\u5177\u3002',
    'toolbox.hub.entry.decision.title': '\u6bcf\u65e5\u51b3\u7b56',
    'toolbox.hub.entry.decision.subtitle':
        '\u628a\u65e5\u5e38\u5c0f\u7ea0\u7ed3\u53d8\u6210\u53ef\u968f\u673a\u3001\u53ef\u7f16\u8f91\u3001\u53ef\u56de\u770b\u7684\u8f7b\u91cf\u9009\u62e9\u3002',

    'toolbox.hub.quick.title': '\u5feb\u6377\u8bbf\u95ee',
    'toolbox.hub.quick.release_hint':
        '\u62d6\u653e\u5230\u6b64\u5904\u4ee5\u56fa\u5b9a',
    'toolbox.hub.quick.manage': '\u7ba1\u7406',
    'toolbox.hub.quick.empty_hint':
        '\u5c06\u5de5\u5177\u62d6\u5230\u6b64\u5904\u5b9e\u73b0\u4e00\u952e\u8bbf\u95ee\u3002\u70b9\u51fb"\u7ba1\u7406"\u9009\u62e9\u4f60\u7684\u5feb\u6377\u65b9\u5f0f\u3002',
    'toolbox.hub.quick.choose_title': '\u9009\u62e9\u5feb\u6377\u5165\u53e3',
    'toolbox.hub.quick.choose_desc':
        '\u9009\u62e9\u4f60\u60f3\u8981\u5728\u5feb\u6377\u9762\u677f\u4e2d\u663e\u793a\u7684\u5de5\u5177\u3002',
    'toolbox.hub.quick.clear': '\u5168\u90e8\u6e05\u9664',
    'toolbox.hub.quick.save': '\u4fdd\u5b58',

    // --- toolbox sleep (B4: Chinese) ---
    'toolbox.sleep.core.title': '\u7761\u7720\u652f\u6301',
    'toolbox.sleep.core.start': '\u5f00\u59cb',
    'toolbox.sleep.core.disabled':
        '\u7761\u7720\u6a21\u5757\u5f53\u524d\u5df2\u7981\u7528\u3002',
    'toolbox.sleep.core.disabledHint':
        '\u8bf7\u5728\u8bbe\u7f6e\u4e2d\u542f\u7528\u7761\u7720\u6a21\u5757\u4ee5\u4f7f\u7528\u6b64\u529f\u80fd\u3002',
    'toolbox.sleep.core.loading': '\u52a0\u8f7d\u4e2d...',
    'toolbox.sleep.core.noData': '\u6682\u65e0\u6570\u636e',
    'toolbox.sleep.core.pause': '\u6682\u505c',
    'toolbox.sleep.core.resume': '\u7ee7\u7eed',
    'toolbox.sleep.core.next': '\u4e0b\u4e00\u6b65',
    'toolbox.sleep.core.stop': '\u505c\u6b62',
    'toolbox.sleep.core.delete': '\u5220\u9664',

    'toolbox.sleep.assist.locatorPlan': '\u4f60\u7684\u7761\u7720\u8ba1\u5212',
    'toolbox.sleep.assist.locatorPlanHint':
        '\u8ffd\u8e2a\u4f60\u5f53\u524d\u7684\u884c\u52a8\u8ba1\u5212\u548c\u8fdb\u5c55\u3002',
    'toolbox.sleep.assist.locatorLoop': '\u7761\u7720\u5faa\u73af',
    'toolbox.sleep.assist.locatorLoopHint':
        '\u4eca\u665a\u548c\u660e\u5929\u65e9\u4e0a\u7684\u5feb\u901f\u64cd\u4f5c\u3002',
    'toolbox.sleep.assist.locatorMore': '\u66f4\u591a\u64cd\u4f5c',
    'toolbox.sleep.assist.locatorMoreHint':
        '\u5de5\u5177\u3001\u5efa\u8bae\u548c\u66f4\u6df1\u5c42\u7684\u8c03\u6574\u3002',
    'toolbox.sleep.assist.locatorAdvice': '\u76f4\u63a5\u5efa\u8bae',
    'toolbox.sleep.assist.locatorAdviceHint':
        '\u57fa\u4e8e\u4f60\u7684\u6570\u636e\u63d0\u4f9b\u7684\u4e2a\u6027\u5316\u5efa\u8bae\u3002',
    'toolbox.sleep.assist.locatorTrend': '7\u65e5\u8d8b\u52bf',
    'toolbox.sleep.assist.locatorTrendHint':
        '\u67e5\u770b\u8fc7\u53bb\u4e00\u5468\u4f60\u7684\u7761\u7720\u6a21\u5f0f\u3002',
    'toolbox.sleep.assist.locatorScience': '\u79d1\u5b66\u5361\u7247',
    'toolbox.sleep.assist.locatorScienceHint':
        '\u57fa\u4e8e\u8bc1\u636e\u7684\u7761\u7720\u77e5\u8bc6\u548c\u6280\u5de7\u3002',
    'toolbox.sleep.assist.subtitle':
        '\u4f60\u7684\u4e2a\u4eba\u7761\u7720\u6307\u5357\u2014\u2014\u8bc4\u4f30\u3001\u8ffd\u8e2a\u4e0e\u591c\u95f4\u652f\u6301\u3002',
    'toolbox.sleep.assist.morningSame': '\u548c\u5e73\u65f6\u4e00\u6837',
    'toolbox.sleep.assist.morningWorse': '\u6bd4\u5e73\u65f6\u5dee',
    'toolbox.sleep.assist.morningBetter': '\u6bd4\u5e73\u65f6\u597d',
    'toolbox.sleep.assist.morningSavedSame':
        '\u6668\u95f4\u7b7e\u5230\u5df2\u4fdd\u5b58\u3002',
    'toolbox.sleep.assist.morningSavedWorse':
        '\u6668\u95f4\u7b7e\u5230\u5df2\u4fdd\u5b58\u2014\u2014\u4eca\u5929\u653e\u8f7b\u677e\u3002',
    'toolbox.sleep.assist.morningSavedBetter':
        '\u6668\u95f4\u7b7e\u5230\u5df2\u4fdd\u5b58\u2014\u2014\u597d\u7684\u5f00\u59cb\uff01',
    'toolbox.sleep.assist.recentRescue': '\u6700\u8fd1\u591c\u9192\u8bb0\u5f55',
    'toolbox.sleep.assist.leftBedRecorded':
        '\u5df2\u8bb0\u5f55\u79bb\u5e8a\u4e8b\u4ef6\u3002',
    'toolbox.sleep.assist.tinyRoutineUsed':
        '\u6700\u8fd1\u4f7f\u7528\u4e86\u7b80\u6613\u653e\u677e\u6d41\u7a0b\u3002',
    'toolbox.sleep.assist.lateScreenClue':
        '\u8fd1\u671f\u65e5\u5fd7\u4e2d\u68c0\u6d4b\u5230\u665a\u7761\u5c4f\u5e55\u4f7f\u7528\u3002',
    'toolbox.sleep.assist.shorterVersion': '\u7cbe\u7b80\u7248',
    'toolbox.sleep.assist.avgSleep': '\u5e73\u5747\u7761\u7720',
    'toolbox.sleep.assist.avgEfficiency': '\u6548\u7387',
    'toolbox.sleep.assist.morningEnergy': '\u6668\u95f4\u7cbe\u529b',
    'toolbox.sleep.assist.track': '\u8ffd\u8e2a',
    'toolbox.sleep.assist.darkMode': '\u591c\u95f4\u6a21\u5f0f',
    'toolbox.sleep.assist.darkModeHint':
        '\u8c03\u6697\u5c4f\u5e55\u5e76\u51cf\u5c11\u84dd\u5149\u4ee5\u9002\u5408\u591c\u95f4\u4f7f\u7528\u3002',
    'toolbox.sleep.assist.currentPlan': '\u5f53\u524d\u8ba1\u5212',
    'toolbox.sleep.assist.currentPlanHint':
        '\u4f60\u6b63\u5728\u8fdb\u884c\u7684\u7761\u7720\u6539\u5584\u65b9\u6848\u3002',
    'toolbox.sleep.assist.sleepLoop': '\u7761\u7720\u5faa\u73af',
    'toolbox.sleep.assist.sleepLoopSub':
        '\u4eca\u665a\u548c\u660e\u65e9\uff0c\u4e00\u7ad9\u5f0f\u6d41\u7a0b\u3002',
    'toolbox.sleep.assist.moreActions': '\u66f4\u591a\u64cd\u4f5c',
    'toolbox.sleep.assist.moreActionsHint':
        '\u5de5\u5177\u3001\u62a5\u8868\u548c\u66f4\u6df1\u5c42\u8bbe\u7f6e\u3002',
    'toolbox.sleep.assist.whiteNoise': '\u767d\u566a\u97f3',
    'toolbox.sleep.assist.morningLightTimer': '\u6668\u5149\u8ba1\u65f6\u5668',
    'toolbox.sleep.assist.caffeineCutoff':
        '\u5496\u5561\u56e0\u622a\u6b62\u65f6\u95f4',
    'toolbox.sleep.assist.min90': '90\u5206\u949f\u5468\u671f',
    'toolbox.sleep.assist.breathing': '\u547c\u5438\u7ec3\u4e60',
    'toolbox.sleep.assist.music': '\u8212\u7f13\u8f7b\u97f3',
    'toolbox.sleep.assist.bowls': '\u7a7a\u7075\u97f3\u94b5',
    'toolbox.sleep.assist.zenSand': '\u6307\u5c16\u6c99\u753b',
    'toolbox.sleep.assist.directAdvice': '\u76f4\u63a5\u5efa\u8bae',
    'toolbox.sleep.assist.directAdviceSub':
        '\u57fa\u4e8e\u4f60\u7684\u7761\u7720\u6570\u636e\u751f\u6210\u7684\u4e2a\u6027\u5316\u5efa\u8bae\u3002',
    'toolbox.sleep.assist.trend7': '7\u65e5\u8d8b\u52bf',
    'toolbox.sleep.assist.trend7Sub':
        '\u8fc7\u53bb\u4e00\u5468\u4f60\u7684\u7761\u7720\u53d8\u5316\u60c5\u51b5\u3002',
    'toolbox.sleep.assist.setDirection': '\u8bbe\u5b9a\u65b9\u5411',
    'toolbox.sleep.assist.setDirectionHint':
        '\u9009\u62e9\u4e00\u4e2a\u7761\u7720\u76ee\u6807\u5e76\u83b7\u53d6\u4e2a\u6027\u5316\u8ba1\u5212\u3002',
    'toolbox.sleep.assist.windDown': '\u7761\u524d\u653e\u677e\u6d41\u7a0b',
    'toolbox.sleep.assist.windDownHint':
        '\u4e3a\u5165\u7761\u505a\u51c6\u5907\u7684\u9010\u6b65\u665a\u95f4\u6d41\u7a0b\u3002',
    'toolbox.sleep.assist.nightRescue': '\u591c\u9192\u6307\u5357',
    'toolbox.sleep.assist.nightRescueHint':
        '\u534a\u591c\u9192\u6765\u65f6\u8be5\u600e\u4e48\u529e\u3002',
    'toolbox.sleep.assist.dayAnchor': '\u65e5\u95f4\u951a\u70b9',
    'toolbox.sleep.assist.dayAnchorHint':
        '\u65e9\u6668\u5149\u7167\u548c\u6d3b\u52a8\u6765\u7a33\u5b9a\u4f60\u7684\u751f\u7269\u949f\u3002',
    'toolbox.sleep.assist.tinyLog': '\u7b80\u6613\u65e5\u5fd7',
    'toolbox.sleep.assist.tinyLogHint':
        '\u6bcf\u665a\u53ea\u970030\u79d2\u7684\u4f4e\u8d1f\u62c5\u7761\u7720\u8bb0\u5f55\u3002',
    'toolbox.sleep.assist.weeklyReview': '\u6bcf\u5468\u56de\u987e',
    'toolbox.sleep.assist.weeklyReviewHint':
        '\u56de\u987e\u4f60\u7684\u7761\u7720\u6a21\u5f0f\u5e76\u8fdb\u884c\u8c03\u6574\u3002',
    'toolbox.sleep.assist.scienceCard': '\u79d1\u5b66\u77e5\u8bc6',
    'toolbox.sleep.assist.scienceCardSub':
        '\u5173\u4e8e\u7761\u7720\u7684\u5faa\u8bc1\u77e5\u8bc6\u3002',
    'toolbox.sleep.assist.assessmentCard': '\u7761\u7720\u8bc4\u4f30',
    'toolbox.sleep.assist.assessmentCardSub':
        '\u8bc4\u4f30\u4f60\u7684\u7761\u7720\u95ee\u9898\u548c\u98ce\u9669\u56e0\u7d20\u3002',
    'toolbox.sleep.assist.logCard': '\u6bcf\u65e5\u65e5\u5fd7',
    'toolbox.sleep.assist.logCardSub':
        '\u7528\u7ed3\u6784\u5316\u7761\u7720\u65e5\u8bb0\u8ffd\u8e2a\u6bcf\u4e00\u665a\u3002',
    'toolbox.sleep.assist.routineCard': '\u7761\u524d\u653e\u677e',
    'toolbox.sleep.assist.routineCardSub':
        '\u5efa\u7acb\u548c\u8fd0\u884c\u4f60\u7684\u665a\u95f4\u653e\u677e\u6d41\u7a0b\u3002',
    'toolbox.sleep.assist.rescueCard': '\u591c\u9192\u6307\u5357',
    'toolbox.sleep.assist.rescueCardSub':
        '\u591c\u95f4\u9192\u6765\u65f6\u7684\u5b89\u5fc3\u5f15\u5bfc\u3002',
    'toolbox.sleep.assist.rhythmCard': '\u65e5\u95f4\u8282\u5f8b',
    'toolbox.sleep.assist.rhythmCardSub':
        '\u4e00\u4e2a7\u5929\u8ba1\u5212\u6765\u7a33\u5b9a\u4f60\u7684\u4f5c\u606f\u8282\u5f8b\u3002',
    'toolbox.sleep.assist.reportCard': '\u7761\u7720\u62a5\u544a',
    'toolbox.sleep.assist.reportCardSub':
        '\u53ef\u89c6\u5316\u8d8b\u52bf\u548c\u957f\u671f\u6a21\u5f0f\u3002',
    'toolbox.sleep.assist.collect3':
        '\u6536\u96c63\u665a\u6570\u636e\u4ee5\u89e3\u9501\u4e2a\u6027\u5316\u6a21\u5f0f\u3002',
    'toolbox.sleep.assist.busyMind': '\u601d\u7eea\u7eb7\u98de',
    'toolbox.sleep.assist.lateScreensTag': '\u7761\u524d\u5c4f\u5e55',
    'toolbox.sleep.assist.setDirectionBtn': '\u8bbe\u5b9a\u65b9\u5411',
    'toolbox.sleep.assist.assessment2min': '\u7761\u7720\u8bc4\u4f30',
    'toolbox.sleep.assist.assessmentIntro':
        '\u4e00\u4efd\u7b80\u77ed\u76842\u5206\u949f\u95ee\u5377\uff0c\u4e86\u89e3\u4f60\u7684\u7761\u7720\u72b6\u51b5\u5e76\u83b7\u53d6\u4e2a\u6027\u5316\u6307\u5bfc\u3002',
    'toolbox.sleep.assist.startAssessment': '\u5f00\u59cb\u8bc4\u4f30',
    'toolbox.sleep.assist.rescueFirst': '\u5148\u770b\u591c\u9192\u6307\u5357',
    'toolbox.sleep.assist.smallFirst': '\u4ece\u5c0f\u5904\u5f00\u59cb',
    'toolbox.sleep.assist.autoPlan':
        '\u8bc4\u4f30\u540e\u81ea\u52a8\u751f\u6210\u8ba1\u5212',
    'toolbox.sleep.assist.inProgress': '\u8fdb\u884c\u4e2d',
    'toolbox.sleep.assist.continueRoutine':
        '\u7ee7\u7eed\u4f60\u7684\u7761\u524d\u653e\u677e\u6d41\u7a0b',
    'toolbox.sleep.assist.continueRoutineHint':
        '\u4f60\u7684\u665a\u95f4\u6d41\u7a0b\u5df2\u7ecf\u8bbe\u7f6e\u597d\u4e86\uff0c\u4ece\u4e0a\u6b21\u4e2d\u65ad\u7684\u5730\u65b9\u7ee7\u7eed\u3002',
    'toolbox.sleep.assist.backToRoutine': '\u56de\u5230\u6d41\u7a0b',
    'toolbox.sleep.assist.noNewTask':
        '\u4eca\u665a\u4e0d\u52a0\u65b0\u4efb\u52a1',
    'toolbox.sleep.assist.nightMode': '\u591c\u95f4\u6a21\u5f0f',
    'toolbox.sleep.assist.nightModeHint': '\u534a\u591c\u65f6\u5206',
    'toolbox.sleep.assist.nightModeDesc':
        '\u4fdd\u6301\u4f4e\u523a\u6fc0\u3002\u907f\u514d\u5c4f\u5e55\u3001\u65f6\u949f\u548c\u4eae\u5149\u3002',
    'toolbox.sleep.assist.openRescue': '\u6253\u5f00\u591c\u9192\u6307\u5357',
    'toolbox.sleep.assist.leaveBedAid':
        '\u9192\u676520\u5206\u949f\u4ee5\u4e0a\u5c31\u79bb\u5e8a',
    'toolbox.sleep.assist.lowStim': '\u4f4e\u523a\u6fc0',
    'toolbox.sleep.assist.noClock': '\u4e0d\u8981\u770b\u949f',
    'toolbox.sleep.assist.tonightStep': '\u4eca\u665a\u7684\u4efb\u52a1',
    'toolbox.sleep.assist.startTinyRoutine':
        '\u5f00\u59cb\u7b80\u6613\u653e\u677e',
    'toolbox.sleep.assist.startTinyRoutineHint':
        '\u4e00\u4e2a\u5373\u4f7f\u7b4b\u75b2\u529b\u5c3d\u4e5f\u80fd\u5b8c\u6210\u7684\u4e09\u6b65\u6781\u7b80\u6d41\u7a0b\u3002',
    'toolbox.sleep.assist.oneTapStart': '\u4e00\u952e\u5f00\u59cb',
    'toolbox.sleep.assist.min90Guide': '90\u5206\u949f\u5468\u671f\u6307\u5357',
    'toolbox.sleep.assist.min8': '8\u5206\u949f\u7b80\u6613\u6d41\u7a0b',
    'toolbox.sleep.assist.dayAnchorTitle': '\u6668\u95f4\u951a\u70b9',
    'toolbox.sleep.assist.dayAnchorDesc': '\u89c1\u4eae\u5149',
    'toolbox.sleep.assist.dayAnchorScenarioHint':
        '\u8d77\u5e8a\u540e30\u5206\u949f\u5185\u63a5\u89e6\u81ea\u7136\u5149\u6216\u4eae\u5149\uff0c\u4ee5\u7a33\u56fa\u4f60\u7684\u751f\u7269\u949f\u3002',
    'toolbox.sleep.assist.startLightTimer':
        '\u5f00\u59cb\u5149\u7167\u8ba1\u65f6',
    'toolbox.sleep.assist.logLastNight': '\u8bb0\u5f55\u6628\u665a',
    'toolbox.sleep.assist.min10to20': '10-20 \u5206\u949f',
    'toolbox.sleep.assist.logPending': '\u5f85\u8bb0\u5f55',
    'toolbox.sleep.assist.minimalLog': '\u7b80\u8981\u8bb0\u5f55',
    'toolbox.sleep.assist.minimalLogHint': '\u8bb0\u5f55\u6628\u665a',
    'toolbox.sleep.assist.minimalLogDesc':
        '\u4e00\u4e2a\u5feb\u901f\u768430\u79d2\u65e5\u5fd7\u6761\u76ee\uff0c\u8bb0\u5f55\u6628\u665a\u7684\u5173\u952e\u4fe1\u606f\u3002',
    'toolbox.sleep.assist.logNow': '\u73b0\u5728\u8bb0\u5f55',
    'toolbox.sleep.assist.caffeineLine': '\u5496\u5561\u56e0\u65f6\u95f4\u7ebf',
    'toolbox.sleep.assist.lowEffort': '\u4f4e\u8d1f\u62c5',
    'toolbox.sleep.assist.trendFirst': '\u8d8b\u52bf\u4f18\u5148',
    'toolbox.sleep.assist.controlOneVar':
        '\u63a7\u5236\u4e00\u4e2a\u53d8\u91cf',
    'toolbox.sleep.assist.controlOneVarHint': '\u5496\u5561\u56e0\u622a\u6b62',
    'toolbox.sleep.assist.controlOneVarDesc':
        '\u6839\u636e\u4f60\u7684\u5178\u578b\u5c31\u5bdd\u65f6\u95f4\u8ba1\u7b97\u4e2a\u4eba\u5496\u5561\u56e0\u622a\u6b62\u65f6\u95f4\u3002',
    'toolbox.sleep.assist.calcCutoff': '\u8ba1\u7b97\u622a\u6b62\u65f6\u95f4',
    'toolbox.sleep.assist.dayRhythm': '\u65e5\u95f4\u8282\u5f8b\u8ba1\u5212',
    'toolbox.sleep.assist.lateYesterday':
        '\u6628\u5929\u5496\u5561\u56e0\u8fc7\u665a',
    'toolbox.sleep.assist.caffeineSensitive':
        '\u5bf9\u5496\u5561\u56e0\u654f\u611f',
    'toolbox.sleep.assist.nextCycle': '\u4e0b\u4e00\u4e2a\u5468\u671f',
    'toolbox.sleep.assist.nextCycleHint':
        '\u67e5\u770b\u5373\u5c06\u5230\u6765\u7684\u7761\u7720\u7a97\u53e3',
    'toolbox.sleep.assist.nextCycleDesc':
        '\u57fa\u4e8e90\u5206\u949f\u7761\u7720\u5468\u671f\uff0c\u67e5\u770b\u6700\u4f73\u5165\u7761\u6216\u8d77\u5e8a\u65f6\u95f4\u3002',
    'toolbox.sleep.assist.openReport': '\u6253\u5f00\u62a5\u544a',
    'toolbox.sleep.assist.tonightRoutine': '\u4eca\u665a\u6d41\u7a0b',
    'toolbox.sleep.assist.snoringRisk': '\u6253\u9f3e\u98ce\u9669',
    'toolbox.sleep.assist.quickLocate': '\u5feb\u901f\u5b9a\u4f4d',
    'toolbox.sleep.assist.openDrawer': '\u5c55\u5f00\u9762\u677f',
    'toolbox.sleep.assist.instantTools': '\u5373\u65f6\u5de5\u5177',
    'toolbox.sleep.assist.noLogsYet': '\u6682\u65e0\u65e5\u5fd7',
    'toolbox.sleep.assist.noLogsHint':
        '\u5f00\u59cb\u8bb0\u5f55\u4f60\u7684\u7761\u7720\u4ee5\u67e5\u770b\u8d8b\u52bf\u5e76\u83b7\u53d6\u4e2a\u6027\u5316\u5efa\u8bae\u3002',
    'toolbox.sleep.assist.startLogging': '\u5f00\u59cb\u8bb0\u5f55',
    'toolbox.sleep.assist.lateCaffeine': '\u5496\u5561\u56e0\u8fc7\u665a',
    'toolbox.sleep.assist.lateScreens': '\u5c4f\u5e55\u4f7f\u7528\u8fc7\u665a',
    'toolbox.sleep.assist.morningLightDone': '\u5df2\u5b8c\u6210\u6668\u5149',
    'toolbox.sleep.assist.jumpTitle': '\u5feb\u6377\u64cd\u4f5c',
    'toolbox.sleep.assist.jumpDesc':
        '\u76f4\u63a5\u8df3\u8f6c\u5230\u4f60\u73b0\u5728\u9700\u8981\u7684\u529f\u80fd\u3002',
    'toolbox.sleep.assist.noInputStarts': '\u96f6\u8f93\u5165\u5f00\u59cb',
    'toolbox.sleep.assist.noInputStartsHint':
        '\u53ea\u9700\u70b9\u51fb\u5373\u53ef\u5f00\u59cb\u2014\u2014\u65e0\u9700\u4efb\u4f55\u8bbe\u7f6e\u3002',
    'toolbox.sleep.assist.imTired': '\u6211\u7d2f\u4e86',
    'toolbox.sleep.assist.bedtimeScene': '\u7761\u524d\u573a\u666f',
    'toolbox.sleep.assist.sleepNow': '\u7acb\u5373\u5165\u7761',
    'toolbox.sleep.assist.tiny8min': '8\u5206\u949f\u7b80\u6613\u6d41\u7a0b',
    'toolbox.sleep.assist.awakeNow': '\u73b0\u5728\u9192\u7740',
    'toolbox.sleep.assist.lowStimRescue': '\u4f4e\u523a\u6fc0\u5b89\u629a',
    'toolbox.sleep.assist.audioBed': '\u97f3\u9891\u966a\u7761',
    'toolbox.sleep.assist.noiseOrRain': '\u767d\u566a\u97f3\u6216\u96e8\u58f0',
    'toolbox.sleep.assist.logLater': '\u7a0d\u540e\u8bb0\u5f55',
    'toolbox.sleep.assist.log30sec': '30\u79d2\u8bb0\u5f55',
    'toolbox.sleep.assist.nightWakeBranches':
        '\u591c\u95f4\u9192\u6765\u5206\u652f',
    'toolbox.sleep.assist.noPlanYet': '\u6682\u65e0\u8ba1\u5212',
    'toolbox.sleep.assist.noPlanHint':
        '\u5b8c\u6210\u7761\u7720\u8bc4\u4f30\u4ee5\u83b7\u53d6\u4e2a\u6027\u5316\u8ba1\u5212\u3002',
    'toolbox.sleep.assist.latestNight': '\u6700\u8fd1\u4e00\u665a',
    'toolbox.sleep.assist.sleep': '\u7761\u7720',
    'toolbox.sleep.assist.efficiency': '\u6548\u7387',
    'toolbox.sleep.assist.wakeUps': '\u9192\u6765\u6b21\u6570',
    'toolbox.sleep.assist.energy': '\u7cbe\u529b',

    'toolbox.sleep.assessment.saved': '\u8bc4\u4f30\u5df2\u4fdd\u5b58\u3002',
    'toolbox.sleep.assessment.moduleDisabled':
        '\u7761\u7720\u6a21\u5757\u5df2\u7981\u7528\u3002\u8bf7\u5728\u8bbe\u7f6e\u4e2d\u542f\u7528\u4ee5\u4f7f\u7528\u6b64\u529f\u80fd\u3002',
    'toolbox.sleep.assessment.title': '\u7761\u7720\u8bc4\u4f30',
    'toolbox.sleep.assessment.intro':
        '\u4e00\u4efd\u7b80\u77ed\u95ee\u5377\uff0c\u4e86\u89e3\u4f60\u7684\u7761\u7720\u6a21\u5f0f\u5e76\u83b7\u53d6\u4e2a\u6027\u5316\u6307\u5bfc\u3002',
    'toolbox.sleep.assessment.mainConcerns': '\u4e3b\u8981\u95ee\u9898',
    'toolbox.sleep.assessment.baselineSchedule': '\u57fa\u51c6\u4f5c\u606f',
    'toolbox.sleep.assessment.typicalBedtime':
        '\u901a\u5e38\u5c31\u5bdd\u65f6\u95f4',
    'toolbox.sleep.assessment.typicalWakeTime':
        '\u901a\u5e38\u8d77\u5e8a\u65f6\u95f4',
    'toolbox.sleep.assessment.currentGoal':
        '\u5f53\u524d\u7761\u7720\u76ee\u6807',
    'toolbox.sleep.assessment.goalHint':
        '\u4f8b\u5982\uff1a\u66f4\u5feb\u5165\u7761\u3001\u51cf\u5c11\u591c\u95f4\u9192\u6765\u3001\u9192\u6765\u65f6\u66f4\u7cbe\u795e',
    'toolbox.sleep.assessment.riskAndContext': '\u98ce\u9669\u4e0e\u73af\u5883',
    'toolbox.sleep.assessment.racingThoughts':
        '\u7761\u524d\u601d\u7eea\u7eb7\u98de',
    'toolbox.sleep.assessment.caffeineSensitive':
        '\u5496\u5561\u56e0\u654f\u611f\u5ea6',
    'toolbox.sleep.assessment.snoringRisk':
        '\u6253\u9f3e\u6216\u547c\u5438\u6682\u505c',
    'toolbox.sleep.assessment.bedroomBright': '\u5367\u5ba4\u592a\u4eae',
    'toolbox.sleep.assessment.bedroomNoisy': '\u5367\u5ba4\u592a\u5435',
    'toolbox.sleep.assessment.bedroomTemp':
        '\u5367\u5ba4\u8fc7\u51b7\u6216\u8fc7\u70ed',
    'toolbox.sleep.assessment.shiftWork':
        '\u8f6e\u73ed\u6216\u4e0d\u89c4\u5f8b\u4f5c\u606f',
    'toolbox.sleep.assessment.digestiveDiscomfort':
        '\u591c\u95f4\u6d88\u5316\u4e0d\u9002',
    'toolbox.sleep.assessment.nightmares': '\u9891\u7e41\u5669\u68a6',
    'toolbox.sleep.assessment.directAdvice': '\u4e2a\u6027\u5316\u5efa\u8bae',
    'toolbox.sleep.assessment.save': '\u4fdd\u5b58\u8bc4\u4f30',

    'toolbox.sleep.log.saved': '\u65e5\u5fd7\u5df2\u4fdd\u5b58\u3002',
    'toolbox.sleep.log.title': '\u6bcf\u65e5\u7761\u7720\u65e5\u5fd7',
    'toolbox.sleep.log.intro':
        '\u7ed3\u6784\u5316\u7684\u7761\u7720\u65e5\u8bb0\uff0c\u8be6\u7ec6\u8ffd\u8e2a\u6bcf\u4e00\u665a\u3002',
    'toolbox.sleep.log.sleep': '\u7761\u7720',
    'toolbox.sleep.log.efficiency': '\u6548\u7387',
    'toolbox.sleep.log.morningEnergy': '\u6668\u95f4\u7cbe\u529b',
    'toolbox.sleep.log.editingDate': '\u7f16\u8f91\u65e5\u671f',
    'toolbox.sleep.log.log30sec': '30\u79d2\u8bb0\u5f55',
    'toolbox.sleep.log.log30secHint':
        '\u4f7f\u7528\u5e38\u89c1\u6a21\u5f0f\u9884\u8bbe\u5feb\u901f\u8bb0\u5f55\u3002',
    'toolbox.sleep.log.presetOkay': '\u8fd8\u53ef\u4ee5',
    'toolbox.sleep.log.presetShort': '\u7761\u7720\u4e0d\u8db3',
    'toolbox.sleep.log.presetWokeOften': '\u9891\u7e41\u9192\u6765',
    'toolbox.sleep.log.saveCurrent': '\u4fdd\u5b58\u5f53\u524d\u65e5\u5fd7',
    'toolbox.sleep.log.timeline': '\u65f6\u95f4\u7ebf',
    'toolbox.sleep.log.bedtime': '\u4e0a\u5e8a\u65f6\u95f4',
    'toolbox.sleep.log.lightsOff': '\u5173\u706f\u65f6\u95f4',
    'toolbox.sleep.log.sleepOnset': '\u5165\u7761\u65f6\u95f4',
    'toolbox.sleep.log.finalWake': '\u6700\u540e\u9192\u6765',
    'toolbox.sleep.log.outOfBed': '\u8d77\u5e8a\u65f6\u95f4',
    'toolbox.sleep.log.commonValues': '\u5e38\u7528\u53c2\u6570',
    'toolbox.sleep.log.estimatedSleepMinutes':
        '\u9884\u4f30\u7761\u7720\uff08\u5206\u949f\uff09',
    'toolbox.sleep.log.sleepLatency':
        '\u5165\u7761\u8017\u65f6\uff08\u5206\u949f\uff09',
    'toolbox.sleep.log.wakeCount': '\u9192\u6765\u6b21\u6570',
    'toolbox.sleep.log.fourPlus': '4\u6b21\u4ee5\u4e0a',
    'toolbox.sleep.log.wakeTotal':
        '\u591c\u95f4\u6e05\u9192\u603b\u8ba1\uff08\u5206\u949f\uff09',
    'toolbox.sleep.log.napMinutes': '\u5348\u7761\uff08\u5206\u949f\uff09',
    'toolbox.sleep.log.windDownMinutes':
        '\u7761\u524d\u653e\u677e\uff08\u5206\u949f\uff09',
    'toolbox.sleep.log.contextNotes': '\u60c5\u5883\u5907\u6ce8',
    'toolbox.sleep.log.notesHint':
        '\u4eca\u665a\u6709\u4ec0\u4e48\u4e0d\u5bfb\u5e38\u7684\u4e8b\u60c5...',
    'toolbox.sleep.log.overtime': '\u52a0\u73ed',
    'toolbox.sleep.log.roomHot': '\u623f\u95f4\u592a\u70ed',
    'toolbox.sleep.log.noise': '\u566a\u97f3',
    'toolbox.sleep.log.travel': '\u51fa\u884c',
    'toolbox.sleep.log.reflux': '\u80c3\u53cd\u6d41',
    'toolbox.sleep.log.tagDreams': '\u505a\u68a6',
    'toolbox.sleep.log.subjectiveScores': '\u4e3b\u89c2\u8bc4\u5206',
    'toolbox.sleep.log.daytimeSleepiness':
        '\u767d\u5929\u56f0\u5026\u7a0b\u5ea6',
    'toolbox.sleep.log.stressPeak': '\u538b\u529b\u5cf0\u503c',
    'toolbox.sleep.log.worryLoad': '\u7126\u8651\u8d1f\u8377',
    'toolbox.sleep.log.behaviorEnv': '\u884c\u4e3a\u4e0e\u73af\u5883',
    'toolbox.sleep.log.heavyDinnerHint':
        '\u7761\u524d\u4e09\u5c0f\u65f6\u5185\u5403\u8fc7\u5927\u9910',
    'toolbox.sleep.log.intenseExerciseHint':
        '\u7761\u524d\u4e24\u5c0f\u65f6\u5185\u5267\u70c8\u8fd0\u52a8',
    'toolbox.sleep.log.hotBathHint':
        '\u7761\u524d\u4e24\u5c0f\u65f6\u5185\u6d17\u8fc7\u70ed\u6c34\u6fa1',
    'toolbox.sleep.log.stretchingHint':
        '\u7761\u524d\u505a\u4f38\u5c55\u6216\u745c\u4f3d',
    'toolbox.sleep.log.bedroomHotHint': '\u5367\u5ba4\u611f\u89c9\u592a\u70ed',
    'toolbox.sleep.log.bedroomBrightHint':
        '\u5367\u5ba4\u611f\u89c9\u592a\u4eae',
    'toolbox.sleep.log.bedroomNoisyHint':
        '\u5367\u5ba4\u611f\u89c9\u592a\u5435',
    'toolbox.sleep.log.practicalTools': '\u5b9e\u7528\u5de5\u5177',
    'toolbox.sleep.log.whiteNoise': '\u767d\u566a\u97f3',
    'toolbox.sleep.log.caffeineCutoff': '\u5496\u5561\u56e0\u622a\u6b62',
    'toolbox.sleep.log.directAdvice': '\u4e2a\u6027\u5316\u5efa\u8bae',
    'toolbox.sleep.log.saveLog': '\u4fdd\u5b58\u65e5\u5fd7',

    'toolbox.sleep.rhythm.title': '\u65e5\u95f4\u8282\u5f8b',
    'toolbox.sleep.rhythm.intro':
        '\u4e00\u4e2a7\u5929\u8ba1\u5212\uff0c\u901a\u8fc7\u6668\u5149\u3001\u5496\u5561\u56e0\u65f6\u95f4\u548c\u665a\u95f4\u4e60\u60ef\u6765\u7a33\u5b9a\u4f60\u7684\u751f\u7406\u8282\u5f8b\u3002',
    'toolbox.sleep.rhythm.currentDay': '\u5f53\u524d\u5929\u6570',
    'toolbox.sleep.rhythm.completed': '\u5df2\u5b8c\u6210',
    'toolbox.sleep.rhythm.programDone': '\u8ba1\u5212\u5df2\u5b8c\u6210',
    'toolbox.sleep.rhythm.completeToday':
        '\u5b8c\u6210\u4eca\u5929\u4efb\u52a1',
    'toolbox.sleep.rhythm.tools': '\u5de5\u5177',
    'toolbox.sleep.rhythm.lightTimer': '\u5149\u7167\u8ba1\u65f6',
    'toolbox.sleep.rhythm.caffeineCutoff': '\u5496\u5561\u56e0\u622a\u6b62',
    'toolbox.sleep.rhythm.leaveBedAid': '\u79bb\u5e8a\u52a9\u624b',
    'toolbox.sleep.rhythm.startProgram': '\u5f00\u59cb\u8ba1\u5212',
    'toolbox.sleep.rhythm.logOneNight': '\u8bf7\u5148\u8bb0\u5f55\u4e00\u665a',
    'toolbox.sleep.rhythm.needOneLog':
        '\u4f60\u9700\u8981\u81f3\u5c11\u4e00\u6761\u7761\u7720\u65e5\u5fd7\u6765\u5f00\u542f\u8282\u5f8b\u8ba1\u5212\u3002',
    'toolbox.sleep.rhythm.morningLight': '\u6668\u95f4\u5149\u7167',
    'toolbox.sleep.rhythm.morningLightDone':
        '\u5df2\u5b8c\u6210\u6668\u95f4\u5149\u7167',
    'toolbox.sleep.rhythm.morningLightMissed':
        '\u672a\u5b8c\u6210\u6668\u95f4\u5149\u7167',
    'toolbox.sleep.rhythm.done': '\u5df2\u5b8c\u6210',
    'toolbox.sleep.rhythm.missed': '\u672a\u5b8c\u6210',
    'toolbox.sleep.rhythm.lateCaffeine': '\u5496\u5561\u56e0\u8fc7\u665a',
    'toolbox.sleep.rhythm.noLateCaffeine':
        '\u65e0\u8fc7\u665a\u5496\u5561\u56e0',
    'toolbox.sleep.rhythm.late': '\u8fc7\u665a',
    'toolbox.sleep.rhythm.stable': '\u7a33\u5b9a',
    'toolbox.sleep.rhythm.napMgmt': '\u5348\u7761\u7ba1\u7406',
    'toolbox.sleep.rhythm.napLong': '\u5348\u7761\u8fc7\u957f',
    'toolbox.sleep.rhythm.napOk': '\u5348\u7761\u5408\u7406',
    'toolbox.sleep.rhythm.eveningStim': '\u665a\u95f4\u523a\u6fc0',
    'toolbox.sleep.rhythm.eveningStimHigh':
        '\u665a\u95f4\u523a\u6fc0\u504f\u9ad8',
    'toolbox.sleep.rhythm.eveningStimOk':
        '\u665a\u95f4\u523a\u6fc0\u6b63\u5e38',
    'toolbox.sleep.rhythm.high': '\u504f\u9ad8',
    'toolbox.sleep.rhythm.ok': '\u6b63\u5e38',
    'toolbox.sleep.rhythm.directAdvice': '\u4e2a\u6027\u5316\u5efa\u8bae',
    'toolbox.sleep.rhythm.active': '\u8fdb\u884c\u4e2d',

    'toolbox.sleep.rescue.saved':
        '\u591c\u9192\u8bb0\u5f55\u5df2\u4fdd\u5b58\u3002',
    'toolbox.sleep.rescue.title': '\u591c\u9192\u6307\u5357',
    'toolbox.sleep.rescue.intro':
        '\u534a\u591c\u9192\u6765\u65f6\u8be5\u600e\u4e48\u529e\u3002\u9009\u62e9\u4f60\u5f53\u524d\u7684\u72b6\u6001\uff0c\u83b7\u53d6\u9010\u6b65\u6307\u5bfc\u3002',
    'toolbox.sleep.rescue.chooseState':
        '\u9009\u62e9\u4f60\u6b64\u523b\u7684\u72b6\u6001',
    'toolbox.sleep.rescue.currentGuidance': '\u5f53\u524d\u6307\u5bfc',
    'toolbox.sleep.rescue.chooseFirst':
        '\u8bf7\u5148\u9009\u62e9\u4f60\u5f53\u524d\u7684\u72b6\u6001\u4ee5\u83b7\u53d6\u9488\u5bf9\u6027\u6307\u5bfc\u3002',
    'toolbox.sleep.rescue.beginGuide': '\u5f00\u59cb\u6307\u5bfc',
    'toolbox.sleep.rescue.leaveBedAid': '\u79bb\u5e8a\u52a9\u624b',
    'toolbox.sleep.rescue.saveEvent': '\u4fdd\u5b58\u4e8b\u4ef6',
    'toolbox.sleep.rescue.guessedTrigger': '\u731c\u6d4b\u7684\u539f\u56e0',
    'toolbox.sleep.rescue.actionTaken': '\u91c7\u53d6\u7684\u884c\u52a8',
    'toolbox.sleep.rescue.extraNotes': '\u989d\u5916\u5907\u6ce8',
    'toolbox.sleep.rescue.leftBed': '\u5df2\u79bb\u5e8a',
    'toolbox.sleep.rescue.recentEvents': '\u6700\u8fd1\u4e8b\u4ef6',
    'toolbox.sleep.rescue.action': '\u884c\u52a8',
    'toolbox.sleep.rescue.trigger': '\u539f\u56e0',

    'toolbox.sleep.low.tonightGoal': '\u4eca\u665a\u76ee\u6807',
    'toolbox.sleep.low.tonightGoalHint':
        '\u4f8b\u5982\uff1a11\u70b9\u524d\u4e0a\u5e8a\uff0c10\u70b9\u540e\u4e0d\u770b\u5c4f\u5e55',
    'toolbox.sleep.low.wakeTap': '\u9192\u6765\u65f6\u70b9\u51fb',
    'toolbox.sleep.low.wakeTapDone':
        '\u6668\u95f4\u7b7e\u5230\u5df2\u8bb0\u5f55',
    'toolbox.sleep.low.wakeTapHint':
        '\u6628\u665a\u7761\u5f97\u600e\u4e48\u6837\uff1f',
    'toolbox.sleep.low.same': '\u5dee\u4e0d\u591a',
    'toolbox.sleep.low.worse': '\u66f4\u5dee',
    'toolbox.sleep.low.better': '\u66f4\u597d',
    'toolbox.sleep.low.openFullLog': '\u6253\u5f00\u5b8c\u6574\u65e5\u5fd7',
    'toolbox.sleep.low.bedtimeScene': '\u7761\u524d\u573a\u666f',
    'toolbox.sleep.low.bedtimeSceneHint':
        '\u8c03\u6697\u706f\u5149\uff0c\u5b89\u9759\u7a7a\u95f4\uff0c\u624b\u673a\u5207\u6362\u6697\u8272\u6a21\u5f0f\u3002',
    'toolbox.sleep.low.switchDark': '\u5207\u6362\u5230\u6697\u8272',
    'toolbox.sleep.low.selectTiny': '\u9009\u62e9\u7b80\u6613\u6d41\u7a0b',
    'toolbox.sleep.low.enterRunner':
        '\u8fdb\u5165\u6d41\u7a0b\u8fd0\u884c\u5668',
    'toolbox.sleep.low.confirmStart': '\u786e\u8ba4\u5e76\u5f00\u59cb',
    'toolbox.sleep.low.chooseAudio': '\u9009\u62e9\u97f3\u9891',
    'toolbox.sleep.low.notNow': '\u6682\u4e0d',
    'toolbox.sleep.low.imTired': '\u6211\u7d2f\u4e86',
    'toolbox.sleep.low.imTiredHint':
        '\u7528\u6700\u5c11\u7684\u529b\u6c14\u5e2e\u4f60\u5165\u7761\u3002',
    'toolbox.sleep.low.dimLights': '\u8c03\u6697\u706f\u5149',
    'toolbox.sleep.low.movePhoneAway': '\u624b\u673a\u653e\u8fdc',
    'toolbox.sleep.low.parkWorry': '\u653e\u4e0b\u5fe7\u8651',
    'toolbox.sleep.low.start8min': '\u5f00\u59cb8\u5206\u949f',
    'toolbox.sleep.low.audioOnly': '\u4ec5\u97f3\u9891',
    'toolbox.sleep.low.wokeAtNight': '\u591c\u91cc\u9192\u4e86',
    'toolbox.sleep.low.do3Steps': '\u505a\u4e09\u6b65',

    'toolbox.sleep.routine.title': '\u7761\u524d\u653e\u677e\u7f16\u8f91\u5668',
    'toolbox.sleep.routine.intro':
        '\u5efa\u7acb\u4f60\u4e2a\u6027\u5316\u7684\u665a\u95f4\u653e\u677e\u6d41\u7a0b\u3002',
    'toolbox.sleep.routine.templateName': '\u6a21\u677f\u540d\u79f0',
    'toolbox.sleep.routine.newStep': '\u65b0\u5efa\u6b65\u9aa4',
    'toolbox.sleep.routine.addStep': '\u6dfb\u52a0\u6b65\u9aa4',
    'toolbox.sleep.routine.saveTemplate': '\u4fdd\u5b58\u6a21\u677f',
    'toolbox.sleep.routine.step': '\u6b65\u9aa4',
    'toolbox.sleep.routine.stepType': '\u6b65\u9aa4\u7c7b\u578b',
    'toolbox.sleep.routine.stepLabel': '\u6b65\u9aa4\u540d\u79f0',
    'toolbox.sleep.routine.stepDuration': '\u65f6\u957f',

    'toolbox.sleep.winddown.unloadSaved':
        '\u601d\u7eea\u5378\u8f7d\u5df2\u4fdd\u5b58\u3002',
    'toolbox.sleep.winddown.wakeGetLight': '\u8d77\u5e8a\u89c1\u5149',
    'toolbox.sleep.winddown.startWindDown': '\u5f00\u59cb\u653e\u677e',
    'toolbox.sleep.winddown.reminderMorning': '\u65e9\u6668\u63d0\u9192',
    'toolbox.sleep.winddown.reminderEvening': '\u665a\u95f4\u63d0\u9192',
    'toolbox.sleep.winddown.reminderWakeCreated':
        '\u8d77\u5e8a\u63d0\u9192\u5df2\u521b\u5efa\u3002',
    'toolbox.sleep.winddown.reminderBedCreated':
        '\u5c31\u5bdd\u63d0\u9192\u5df2\u521b\u5efa\u3002',
    'toolbox.sleep.winddown.title': '\u7761\u524d\u653e\u677e',
    'toolbox.sleep.winddown.intro':
        '\u4e00\u4e2a\u5f15\u5bfc\u5f0f\u7684\u665a\u95f4\u6d41\u7a0b\uff0c\u5e2e\u52a9\u4f60\u7684\u8eab\u4f53\u548c\u5927\u8111\u4e3a\u7761\u7720\u505a\u597d\u51c6\u5907\u3002',
    'toolbox.sleep.winddown.templates': '\u6a21\u677f',
    'toolbox.sleep.winddown.templatesHint':
        '\u9009\u62e9\u4e00\u4e2a\u9884\u8bbe\u6d41\u7a0b\u6216\u521b\u5efa\u4f60\u81ea\u5df1\u7684\u3002',
    'toolbox.sleep.winddown.new': '\u65b0\u5efa',
    'toolbox.sleep.winddown.runner': '\u8fd0\u884c\u5668',
    'toolbox.sleep.winddown.notStarted': '\u672a\u5f00\u59cb',
    'toolbox.sleep.winddown.start': '\u5f00\u59cb',
    'toolbox.sleep.winddown.unloadThoughts': '\u5378\u8f7d\u601d\u7eea',
    'toolbox.sleep.winddown.topThought':
        '\u6700\u8ba9\u5728\u610f\u7684\u5ff5\u5934',
    'toolbox.sleep.winddown.gentlerReframe':
        '\u66f4\u6e29\u548c\u7684\u91cd\u65b0\u8868\u8ff0',
    'toolbox.sleep.winddown.intensity': '\u5f3a\u70c8\u7a0b\u5ea6',
    'toolbox.sleep.winddown.saveUnload': '\u4fdd\u5b58\u5378\u8f7d',
    'toolbox.sleep.winddown.quickTools': '\u5feb\u6377\u5de5\u5177',
    'toolbox.sleep.winddown.whiteNoise': '\u767d\u566a\u97f3',
    'toolbox.sleep.winddown.cycle90min': '90\u5206\u949f\u5468\u671f',
    'toolbox.sleep.winddown.bedReminder': '\u5c31\u5bdd\u63d0\u9192',
    'toolbox.sleep.winddown.wakeAlarm': '\u8d77\u5e8a\u95f9\u949f',
    'toolbox.sleep.winddown.soothingAudio': '\u8212\u7f13\u97f3\u9891',
    'toolbox.sleep.winddown.recentUnload': '\u6700\u8fd1\u5378\u8f7d',
    'toolbox.sleep.winddown.reframe': '\u91cd\u65b0\u8868\u8ff0',
    'toolbox.sleep.winddown.stepChecklist': '\u6b65\u9aa4\u6e05\u5355',
    'toolbox.sleep.winddown.stepHint':
        '\u5b8c\u6210\u6bcf\u4e00\u6b65\u540e\u70b9\u51fb\u6807\u8bb0\u3002',
    'toolbox.sleep.winddown.builtIn': '\u5185\u7f6e',
    'toolbox.sleep.winddown.currentlySelected': '\u5f53\u524d\u9009\u4e2d',

    'toolbox.sleep.support.issue.hard_fall_asleep': '\u96be\u4ee5\u5165\u7761',
    'toolbox.sleep.support.issue.frequent_awakenings':
        '\u9891\u7e41\u9192\u6765',
    'toolbox.sleep.support.issue.early_awakening': '\u8fc7\u65e9\u9192\u6765',
    'toolbox.sleep.support.issue.non_restorative':
        '\u7761\u7720\u4e0d\u89e3\u4e4f',
    'toolbox.sleep.support.issue.irregular_schedule':
        '\u4f5c\u606f\u4e0d\u89c4\u5f8b',
    'toolbox.sleep.support.issue.racing_thoughts': '\u601d\u7eea\u7eb7\u98de',
    'toolbox.sleep.support.issue.daytime_sleepiness':
        '\u767d\u5929\u56f0\u5026',
    'toolbox.sleep.support.issue.snoring_risk': '\u6253\u9f3e\u98ce\u9669',
    'toolbox.sleep.support.issue.pain_tension':
        '\u75bc\u75db\u6216\u7d27\u7ef7',
    'toolbox.sleep.support.risk.low': '\u4f4e\u98ce\u9669',
    'toolbox.sleep.support.risk.mild': '\u8f7b\u5ea6\u98ce\u9669',
    'toolbox.sleep.support.risk.medium': '\u4e2d\u5ea6\u98ce\u9669',
    'toolbox.sleep.support.risk.high': '\u9ad8\u98ce\u9669',
    'toolbox.sleep.support.mode.brief': '\u77ed\u6682\u9192\u6765',
    'toolbox.sleep.support.mode.fully_awake': '\u5b8c\u5168\u6e05\u9192',
    'toolbox.sleep.support.mode.racing_thoughts': '\u601d\u7eea\u7eb7\u98de',
    'toolbox.sleep.support.mode.body_activated': '\u8eab\u4f53\u7d27\u7ef7',
    'toolbox.sleep.support.mode.temperature': '\u6e29\u5ea6\u4e0d\u9002',
    'toolbox.sleep.support.mode_body.brief':
        '\u4f60\u77ed\u6682\u5730\u9192\u4e86\uff0c\u60f3\u5feb\u901f\u91cd\u65b0\u5165\u7761\u3002',
    'toolbox.sleep.support.mode_body.fully_awake':
        '\u4f60\u5b8c\u5168\u6e05\u9192\u4e86\uff0c\u65e0\u6cd5\u91cd\u65b0\u5165\u7761\u3002',
    'toolbox.sleep.support.mode_body.racing_thoughts':
        '\u4f60\u7684\u5927\u8111\u5f88\u5fd9\u788c\uff0c\u601d\u7eea\u4e0d\u65ad\u3002',
    'toolbox.sleep.support.mode_body.body_activated':
        '\u4f60\u611f\u5230\u8eab\u4f53\u7d27\u5f20\u3001\u4e0d\u5b89\u6216\u5fc3\u795e\u4e0d\u5b81\u3002',
    'toolbox.sleep.support.mode_body.temperature':
        '\u4f60\u611f\u89c9\u592a\u70ed\u6216\u592a\u51b7\u3002',
    'toolbox.sleep.support.track.observation': '\u89c2\u5bdf\u8bb0\u5f55',
    'toolbox.sleep.support.track.wind_down': '\u7761\u524d\u653e\u677e',
    'toolbox.sleep.support.track.insomnia': '\u5931\u7720\u652f\u6301',
    'toolbox.sleep.support.track.rhythm_reset': '\u8282\u5f8b\u91cd\u7f6e',
    'toolbox.sleep.support.track.environment': '\u73af\u5883\u6539\u5584',
    'toolbox.sleep.support.track.recovery': '\u65e5\u95f4\u6062\u590d',
    'toolbox.sleep.support.program.rhythm_7': '7\u5929\u8282\u5f8b\u91cd\u7f6e',
    'toolbox.sleep.support.program.reset_14':
        '14\u5929\u7761\u7720\u91cd\u7f6e',
    'toolbox.sleep.support.program.starter': '\u5931\u7720\u5165\u95e8',
    'toolbox.sleep.support.program_body.rhythm_7':
        '\u4e00\u4e2a\u901a\u8fc7\u5149\u7167\u548c\u4f5c\u606f\u951a\u5b9a\u6765\u7a33\u5b9a\u7761\u7720-\u6e05\u9192\u8282\u5f8b\u76847\u5929\u8ba1\u5212\u3002',
    'toolbox.sleep.support.program_body.reset_14':
        '\u4e3a\u671f\u4e24\u5468\u7684\u7efc\u5408\u7761\u7720\u91cd\u7f6e\uff0c\u542b\u6bcf\u65e5\u6307\u5bfc\u4e0e\u4e60\u60ef\u8ffd\u8e2a\u3002',
    'toolbox.sleep.support.program_body.starter':
        '\u4e00\u4e2a\u6e29\u548c\u76845\u6b65\u5165\u95e8\u8ba1\u5212\uff0c\u7528\u4e8e\u7ba1\u7406\u5076\u53d1\u6027\u5931\u7720\u3002',
    'toolbox.sleep.support.step.dim_lights': '\u8c03\u6697\u706f\u5149',
    'toolbox.sleep.support.step.stop_screens': '\u505c\u6b62\u5c4f\u5e55',
    'toolbox.sleep.support.step.prepare_room': '\u51c6\u5907\u623f\u95f4',
    'toolbox.sleep.support.step.unload_thoughts': '\u5378\u8f7d\u601d\u7eea',
    'toolbox.sleep.support.step.breathing': '\u547c\u5438\u7ec3\u4e60',
    'toolbox.sleep.support.step.stretch': '\u4f38\u5c55',
    'toolbox.sleep.support.step.warm_bath': '\u6e29\u6c34\u6fa1',
    'toolbox.sleep.support.step.white_noise': '\u767d\u566a\u97f3',
    'toolbox.sleep.support.step.soothing_audio': '\u8212\u7f13\u97f3\u9891',
    'toolbox.sleep.support.step.body_scan': '\u8eab\u4f53\u626b\u63cf',
    'toolbox.sleep.support.step.go_to_bed': '\u4e0a\u5e8a\u7761\u89c9',
    'toolbox.sleep.support.template.tiny': '\u6781\u7b80\u6a21\u5f0f',
    'toolbox.sleep.support.template.quick_reset': '\u5feb\u901f\u91cd\u542f',
    'toolbox.sleep.support.template.standard': '\u6807\u51c6\u653e\u677e',
    'toolbox.sleep.support.template_step.tiny1':
        '\u53ea\u8c03\u6697\u4f60\u80fd\u78b0\u5230\u7684\u706f',
    'toolbox.sleep.support.template_step.tiny2':
        '\u628a\u624b\u673a\u5c4f\u5e55\u671d\u4e0b\u653e',
    'toolbox.sleep.support.template_step.tiny3':
        '\u653e\u4e0b\u6700\u5435\u7684\u90a3\u4e2a\u5ff5\u5934',
    'toolbox.sleep.support.template_step.tiny4':
        '\u5ef6\u957f\u547c\u6c14\u7684\u547c\u5438',
    'toolbox.sleep.support.template_step.tiny5':
        '\u4e0d\u6dfb\u65b0\u4efb\u52a1\u5730\u8fdb\u5165\u88ab\u7a9d',
    'toolbox.sleep.support.intensity.very_low': '\u975e\u5e38\u4f4e',
    'toolbox.sleep.support.intensity.low': '\u4f4e',
    'toolbox.sleep.support.intensity.moderate': '\u4e2d\u7b49',
    'toolbox.sleep.support.intensity.high': '\u9ad8',
    'toolbox.sleep.support.intensity.very_high': '\u975e\u5e38\u9ad8',
    'toolbox.sleep.support.frequency.rare': '\u6781\u5c11',
    'toolbox.sleep.support.frequency.sometimes': '\u5076\u5c14',
    'toolbox.sleep.support.frequency.often': '\u7ecf\u5e38',
    'toolbox.sleep.support.frequency.frequent': '\u9891\u7e41',
    'toolbox.sleep.support.frequency.daily': '\u6bcf\u5929',
    'toolbox.sleep.support.bool.recorded': '\u5df2\u8bb0\u5f55',
    'toolbox.sleep.support.bool.not_recorded': '\u672a\u8bb0\u5f55',
    'toolbox.sleep.support.burden.low': '\u4f4e\u8d1f\u62c5',
    'toolbox.sleep.support.burden.medium': '\u4e2d\u7b49\u8d1f\u62c5',
    'toolbox.sleep.support.burden.high': '\u9ad8\u8d1f\u62c5',
    'toolbox.sleep.support.factor.stress': '\u538b\u529b\u8d1f\u8377',
    'toolbox.sleep.support.factor.screen': '\u5c4f\u5e55\u4f9d\u8d56',
    'toolbox.sleep.support.factor.late_work':
        '\u6df1\u591c\u5de5\u4f5c\u9891\u7387',
    'toolbox.sleep.support.factor.late_exercise':
        '\u6df1\u591c\u8fd0\u52a8\u9891\u7387',
    'toolbox.sleep.support.factor.pain': '\u75bc\u75db\u5f71\u54cd',
    'toolbox.sleep.support.factor.snoring': '\u6253\u9f3e\u98ce\u9669',
    'toolbox.sleep.support.factor_hint.stress':
        '\u538b\u529b\u5bf9\u4f60\u7761\u7720\u7684\u5f71\u54cd\u7a0b\u5ea6',
    'toolbox.sleep.support.factor_hint.screen':
        '\u5c4f\u5e55\u4f7f\u7528\u5982\u4f55\u5f71\u54cd\u4f60\u7684\u5165\u7761',
    'toolbox.sleep.support.factor_hint.late_work':
        '\u5de5\u4f5c\u8ba9\u4f60\u71ac\u591c\u7684\u9891\u7387',
    'toolbox.sleep.support.factor_hint.late_exercise':
        '\u4f60\u5728\u4e34\u8fd1\u5c31\u5bdd\u65f6\u8fd0\u52a8\u7684\u9891\u7387',
    'toolbox.sleep.support.factor_hint.pain':
        '\u75bc\u75db\u5bf9\u7761\u7720\u7684\u5e72\u6270\u7a0b\u5ea6',
    'toolbox.sleep.support.factor_hint.snoring':
        '\u662f\u5426\u51fa\u73b0\u6253\u9f3e\u6216\u547c\u5438\u6682\u505c',
    'toolbox.sleep.support.daily.late_caffeine':
        '\u5496\u5561\u56e0\u8d85\u8fc7\u622a\u6b62\u65f6\u95f4',
    'toolbox.sleep.support.daily.late_screens':
        '\u6df1\u591c\u5c4f\u5e55\u4f7f\u7528',
    'toolbox.sleep.support.daily.alcohol': '\u591c\u95f4\u996e\u9152',
    'toolbox.sleep.support.daily.morning_light':
        '\u5df2\u5b8c\u6210\u6668\u5149',
    'toolbox.sleep.support.daily.heavy_dinner': '\u665a\u9910\u8fc7\u9971',
    'toolbox.sleep.support.daily.late_exercise':
        '\u6df1\u591c\u5267\u70c8\u8fd0\u52a8',
    'toolbox.sleep.support.daily.warm_bath':
        '\u70ed\u6c34\u6fa1\u6216\u6dcb\u6d74',
    'toolbox.sleep.support.daily.stretching': '\u5df2\u5b8c\u6210\u4f38\u5c55',
    'toolbox.sleep.support.daily.white_noise':
        '\u5df2\u4f7f\u7528\u767d\u566a\u97f3',
    'toolbox.sleep.support.daily.room_hot': '\u5367\u5ba4\u592a\u70ed',
    'toolbox.sleep.support.daily.room_bright': '\u5367\u5ba4\u592a\u4eae',
    'toolbox.sleep.support.daily.room_noisy': '\u5367\u5ba4\u592a\u5435',
    'toolbox.sleep.support.daily.clock_checking': '\u53cd\u590d\u770b\u949f',
    'toolbox.sleep.support.daily_hint.caffeine':
        '\u5728\u622a\u6b62\u65f6\u95f4\u4e4b\u540e\u559d\u4e86\u5496\u5561\u3001\u8336\u6216\u80fd\u91cf\u996e\u6599',
    'toolbox.sleep.support.daily_hint.screens':
        '\u6df1\u591c\u4f7f\u7528\u624b\u673a\u3001\u5e73\u677f\u6216\u7535\u8111',
    'toolbox.sleep.support.daily_hint.alcohol':
        '\u4e34\u7761\u524d\u996e\u9152',
    'toolbox.sleep.support.daily_hint.morning_light':
        '\u8d77\u5e8a\u540e30\u5206\u949f\u5185\u63a5\u89e6\u81ea\u7136\u5149\u6216\u4eae\u5149',
    'toolbox.sleep.support.daily_hint.clock':
        '\u591c\u95f4\u53cd\u590d\u67e5\u770b\u65f6\u95f4',
    'toolbox.sleep.support.daily_hint.white_noise':
        '\u4f7f\u7528\u4e86\u767d\u566a\u97f3\u3001\u98ce\u6247\u6216\u73af\u5883\u97f3',

    // --- toolbox sleep report (Chinese) ---
    'toolbox.sleep.report.title': '\u7761\u7720\u62a5\u544a',
    'toolbox.sleep.report.intro':
        '\u53ef\u89c6\u5316\u4f60\u7684\u7761\u7720\u8d8b\u52bf\u548c\u957f\u671f\u6a21\u5f0f\u3002',
    'toolbox.sleep.report.noData': '\u6682\u65e0\u6570\u636e',
    'toolbox.sleep.report.noDataHint':
        '\u8bf7\u81f3\u5c11\u8bb0\u5f55\u4e00\u665a\u4ee5\u67e5\u770b\u4f60\u7684\u7761\u7720\u62a5\u544a\u3002',
    'toolbox.sleep.report.range': '\u65f6\u95f4\u8303\u56f4',
    'toolbox.sleep.report.range7d': '7\u5929',
    'toolbox.sleep.report.range14d': '14\u5929',
    'toolbox.sleep.report.avgSleep': '\u5e73\u5747\u7761\u7720',
    'toolbox.sleep.report.avgEfficiency': '\u5e73\u5747\u6548\u7387',
    'toolbox.sleep.report.morningEnergy': '\u6668\u95f4\u7cbe\u529b',
    'toolbox.sleep.report.daytimeSleepiness': '\u767d\u5929\u56f0\u5026',
    'toolbox.sleep.report.sleepDurationTrend':
        '\u7761\u7720\u65f6\u957f\u8d8b\u52bf',
    'toolbox.sleep.report.sleepDurationTrendHint':
        '\u4f60\u7684\u603b\u7761\u7720\u65f6\u95f4\u5982\u4f55\u53d8\u5316\u3002',
    'toolbox.sleep.report.efficiencyTrend': '\u6548\u7387\u8d8b\u52bf',
    'toolbox.sleep.report.efficiencyTrendHint':
        '\u4f60\u7684\u7761\u7720\u6548\u7387\u5982\u4f55\u53d8\u5316\u3002',
    'toolbox.sleep.report.energyTrend': '\u6668\u95f4\u7cbe\u529b\u8d8b\u52bf',
    'toolbox.sleep.report.energyTrendHint':
        '\u4f60\u9192\u6765\u65f6\u611f\u89c9\u6709\u591a\u7cbe\u795e\u3002',
    'toolbox.sleep.report.wakeBurden': '\u591c\u95f4\u6e05\u9192\u8d1f\u62c5',
    'toolbox.sleep.report.wakeBurdenHint':
        '\u591c\u95f4\u6e05\u9192\u7684\u603b\u65f6\u957f\u3002',
    'toolbox.sleep.report.lateCaffeineDays':
        '\u5496\u5561\u56e0\u8fc7\u665a\u5929\u6570',
    'toolbox.sleep.report.lateCaffeineDaysHint':
        '\u8d85\u8fc7\u622a\u6b62\u65f6\u95f4\u6444\u5165\u5496\u5561\u56e0\u7684\u591c\u665a\u6570\u3002',
    'toolbox.sleep.report.lateScreenDays':
        '\u5c4f\u5e55\u8fc7\u665a\u5929\u6570',
    'toolbox.sleep.report.lateScreenDaysHint':
        '\u4e34\u7761\u524d\u4f7f\u7528\u5c4f\u5e55\u7684\u591c\u665a\u6570\u3002',
    'toolbox.sleep.report.morningLightDays':
        '\u6668\u95f4\u5149\u7167\u5929\u6570',
    'toolbox.sleep.report.morningLightDaysHint':
        '\u65e9\u6668\u63a5\u89e6\u81ea\u7136\u4eae\u5149\u7684\u5929\u6570\u3002',
    'toolbox.sleep.report.envIssueDays': '\u73af\u5883\u95ee\u9898\u5929\u6570',
    'toolbox.sleep.report.envIssueDaysHint':
        '\u5367\u5ba4\u73af\u5883\u6709\u95ee\u9898\u7684\u591c\u665a\u6570\u3002',
    'toolbox.sleep.report.nextCycleAdvice':
        '\u67e5\u770b\u4eca\u665a90\u5206\u949f\u5468\u671f\u7a97\u53e3\u3002',

    // --- toolbox sleep science (Chinese) ---
    'toolbox.sleep.science.title': '\u7761\u7720\u79d1\u5b66',
    'toolbox.sleep.science.intro':
        '\u57fa\u4e8e\u8bc1\u636e\u7684\u7761\u7720\u77e5\u8bc6\u3001\u53c2\u8003\u6587\u732e\u548c\u5b9e\u7528\u539f\u7406\u3002',
    'toolbox.sleep.science.disclaimer':
        '\u6b64\u4fe1\u606f\u4ec5\u4f9b\u6559\u80b2\u53c2\u8003\uff0c\u4e0d\u80fd\u66ff\u4ee3\u533b\u7597\u5efa\u8bae\u3002\u6301\u7eed\u7684\u7761\u7720\u95ee\u9898\u8bf7\u54a8\u8be2\u533b\u7597\u4e13\u4e1a\u4eba\u5458\u3002',
    'toolbox.sleep.science.anchorRhythm':
        '\u951a\u5b9a\u4f60\u7684\u8282\u5f8b',
    'toolbox.sleep.science.anchorRhythmBody':
        '\u8d77\u5e8a\u540e30\u5206\u949f\u5185\u7684\u6668\u95f4\u5149\u7167\u662f\u8bbe\u5b9a\u4f53\u5185\u65f6\u949f\u7684\u6700\u5f3a\u4fe1\u53f7\u3002\u5373\u4f7f\u5728\u9634\u5929\u6237\u5916\u5f8510\u5206\u949f\u4e5f\u80fd\u4ea7\u751f\u53ef\u6d4b\u91cf\u7684\u6548\u679c\u3002',
    'toolbox.sleep.science.keepBedForSleep':
        '\u5e8a\u53ea\u7528\u6765\u7761\u89c9',
    'toolbox.sleep.science.keepBedForSleepBody':
        '\u5982\u679c\u4f60\u8eba\u4e8620\u5206\u949f\u4ee5\u4e0a\u8fd8\u7761\u4e0d\u7740\uff0c\u5c31\u8d77\u5e8a\u505a\u4e9b\u4f4e\u523a\u6fc0\u7684\u4e8b\u60c5\u76f4\u5230\u56f0\u5026\u3002\u8fd9\u6837\u53ef\u4ee5\u91cd\u65b0\u52a0\u5f3a\u5e8a\u4e0e\u7761\u7720\u7684\u5173\u8054\u3002',
    'toolbox.sleep.science.logLightly': '\u8f7b\u677e\u8bb0\u5f55',
    'toolbox.sleep.science.logLightlyBody':
        '\u4e00\u4e2a30\u79d2\u7684\u7761\u7720\u65e5\u8bb0\u8db3\u4ee5\u968f\u7740\u65f6\u95f4\u7684\u63a8\u79fb\u63ed\u793a\u6a21\u5f0f\u3002\u4e0d\u9700\u8981\u5b8c\u7f8e\u2014\u2014\u575a\u6301\u6bd4\u7ec6\u8282\u66f4\u91cd\u8981\u3002',
    'toolbox.sleep.science.referenceIndex': '\u53c2\u8003\u7d22\u5f15',
    'toolbox.sleep.science.referenceSource': '\u6765\u6e90',
    'toolbox.sleep.science.refGroupCbti': 'CBT-I \u6307\u5357',
    'toolbox.sleep.science.refGroupCbtiBody':
        '\u9488\u5bf9\u6162\u6027\u5931\u7720\u7684\u523a\u6fc0\u63a7\u5236\u3001\u7761\u7720\u9650\u5236\u548c\u8ba4\u77e5\u6280\u672f\u3002',
    'toolbox.sleep.science.refGroupRhythm':
        '\u663c\u591c\u8282\u5f8b\u79d1\u5b66',
    'toolbox.sleep.science.refGroupRhythmBody':
        '\u5149\u7167\u66b4\u9732\u3001\u892a\u9ed1\u7d20\u65f6\u673a\u548c\u751f\u7269\u949f\u57fa\u7840\u3002',
    'toolbox.sleep.science.refGroupMedical': '\u533b\u5b66\u7b5b\u67e5',
    'toolbox.sleep.science.refGroupMedicalBody':
        '\u4f55\u65f6\u8003\u8651\u7761\u7720\u547c\u5438\u6682\u505c\u7b5b\u67e5\u3001RLS\u6216\u4e13\u79d1\u8f6c\u8bca\u3002',
    'toolbox.sleep.science.refGroupPopular':
        '\u5927\u4f17\u5faa\u8bc1\u6458\u8981',
    'toolbox.sleep.science.refGroupPopularBody':
        '\u5c06\u7814\u7a76\u8f6c\u5316\u4e3a\u65e5\u5e38\u7761\u7720\u4e60\u60ef\u3002',
    'toolbox.sleep.science.riskFirst':
        '\u5148\u6392\u9664\u533b\u5b66\u95ee\u9898',
    'toolbox.sleep.science.riskFirstBody':
        '\u67d0\u4e9b\u7761\u7720\u95ee\u9898\u53ef\u80fd\u6709\u6f5c\u5728\u7684\u533b\u5b66\u539f\u56e0\u3002\u5728\u81ea\u6211\u8c03\u6574\u524d\u8bf7\u6ce8\u610f\u5173\u952e\u8b66\u544a\u4fe1\u53f7\u3002',
    'toolbox.sleep.science.riskSnoring':
        '\u5927\u58f0\u6253\u9f3e\u4f34\u6709\u4eba\u89c1\u8bc1\u7684\u547c\u5438\u6682\u505c',
    'toolbox.sleep.science.riskMental':
        '\u4e0e\u60c5\u7eea\u53d1\u4f5c\u6216\u521b\u4f24\u76f8\u5173\u7684\u7761\u7720\u969c\u788d',
    'toolbox.sleep.science.riskMedical':
        '\u4e0d\u5b81\u817f\u3001\u6162\u6027\u75bc\u75db\u6216\u836f\u7269\u526f\u4f5c\u7528',
    'toolbox.sleep.science.dayAnchors':
        '\u65e5\u95f4\u951a\u70b9\u7a33\u5b9a\u591c\u665a',
    'toolbox.sleep.science.dayAnchorsBody':
        '\u7a33\u5b9a\u7684\u8d77\u5e8a\u65f6\u95f4\u3001\u6668\u95f4\u5149\u7167\u548c\u89c4\u5f8b\u7684\u7528\u9910\u65f6\u95f4\u53ef\u4ee5\u951a\u5b9a\u4f60\u7684\u663c\u591c\u8282\u5f8b\u3002',
    'toolbox.sleep.science.fixWakeTime':
        '\u6bcf\u5929\u56fa\u5b9a\u8d77\u5e8a\u65f6\u95f4\uff0c\u6d6e\u52a8\u4e0d\u8d85\u8fc730\u5206\u949f',
    'toolbox.sleep.science.caffeineRule':
        '\u4e0b\u53482\u70b9\u540e\u4e0d\u6444\u5165\u5496\u5561\u56e0\uff08\u6216\u7761\u524d8-10\u5c0f\u65f6\uff09',
    'toolbox.sleep.science.napRule':
        '\u5348\u7761\u4e0d\u8d85\u8fc720\u5206\u949f\u4e14\u5728\u4e0b\u53483\u70b9\u524d\uff0c\u6216\u8005\u5b8c\u5168\u4e0d\u5348\u7761',
    'toolbox.sleep.science.windDownSm':
        '\u5c0f\u5c0f\u7684\u653e\u677e\u5f88\u91cd\u8981',
    'toolbox.sleep.science.windDownSmBody':
        '\u5373\u4f7f\u4e00\u4e2a\u5fae\u5c0f\u7684\u4e09\u6b65\u6d41\u7a0b\u4e5f\u80fd\u5411\u4f60\u7684\u5927\u8111\u53d1\u51fa"\u4e00\u5929\u7ed3\u675f\u4e86"\u7684\u4fe1\u53f7\u3002\u575a\u6301\u6bd4\u4eea\u5f0f\u7684\u590d\u6742\u5ea6\u66f4\u91cd\u8981\u3002',
    'toolbox.sleep.science.windDownDetail1':
        '\u7761\u524d30-60\u5206\u949f\u8c03\u6697\u706f\u5149',
    'toolbox.sleep.science.windDownDetail2':
        '\u6536\u8d77\u5c4f\u5e55\u6216\u5207\u6362\u5230\u591c\u95f4\u6a21\u5f0f',
    'toolbox.sleep.science.windDownDetail3':
        '\u505a\u4e00\u4ef6\u5b89\u9759\u7684\u4e8b\uff1a\u9605\u8bfb\u3001\u4f38\u5c55\u6216\u547c\u5438',
    'toolbox.sleep.science.nightWaking':
        '\u591c\u91cc\u9192\u6765\u662f\u6b63\u5e38\u7684',
    'toolbox.sleep.science.nightWakingBody':
        '\u7761\u7720\u5468\u671f\u4e4b\u95f4\u7684\u77ed\u6682\u9192\u6765\u662f\u6b63\u5e38\u7684\u3002\u95ee\u9898\u5728\u4e8e\u6211\u4eec\u7684\u53cd\u5e94\u2014\u2014\u53cd\u590d\u770b\u949f\u548c\u6cae\u4e27\u60c5\u7eea\u4f1a\u5ef6\u957f\u6e05\u9192\u65f6\u95f4\u3002',
    'toolbox.sleep.science.nightWakingDetail1':
        '\u907f\u514d\u770b\u949f\u6216\u624b\u673a',
    'toolbox.sleep.science.nightWakingDetail2':
        '\u5982\u679c20\u5206\u949f\u540e\u4ecd\u7136\u6e05\u9192\uff0c\u5c31\u79bb\u5f00\u5e8a\u94fa',
    'toolbox.sleep.science.nightWakingDetail3':
        '\u5728\u660f\u6697\u7684\u5149\u7ebf\u4e0b\u505a\u4e00\u4e9b\u65e0\u804a\u7684\u4e8b\u76f4\u5230\u56f0\u5026',
    'toolbox.sleep.science.easyMisuse': '\u5e38\u89c1\u8bef\u89e3',
    'toolbox.sleep.science.easyMisuseIntro':
        '\u6d41\u884c\u7684\u7761\u7720\u5efa\u8bae\u53ef\u80fd\u88ab\u8bef\u7528\u3002\u4ee5\u4e0b\u662f\u4e09\u4e2a\u5e38\u89c1\u8bef\u533a\u3002',
    'toolbox.sleep.science.eightHour':
        '"\u6bcf\u4e2a\u4eba\u90fd\u9700\u89818\u5c0f\u65f6"\u2014\u2014\u6b63\u5e38\u7761\u7720\u56e0\u4eba\u800c\u5f02\uff0c\u4ece6\u52309\u5c0f\u65f6\u4e0d\u7b49\u3002',
    'toolbox.sleep.science.cycle90':
        '"\u5fc5\u987b\u5728\u5468\u671f\u7ed3\u675f\u65f6\u9192\u6765"\u2014\u2014\u7761\u7720\u7ed3\u6784\u6bd4\u56fa\u5b9a\u768490\u5206\u949f\u533a\u5757\u66f4\u590d\u6742\u3002',
    'toolbox.sleep.science.hygiene':
        '"\u7761\u7720\u536b\u751f\u5c31\u80fd\u6cbb\u6108\u5931\u7720"\u2014\u2014\u6162\u6027\u5931\u7720\u901a\u5e38\u9700\u8981\u7ed3\u6784\u5316\u7684CBT-I\u6280\u672f\u3002',

    // --- toolbox sleep tools (Chinese) ---
    'toolbox.sleep.tools.ambientNoise': '\u73af\u5883\u58f0\u97f3',
    'toolbox.sleep.tools.ambientNoiseHint':
        '\u4f7f\u7528\u767d\u566a\u97f3\u3001\u96e8\u58f0\u6216\u73af\u5883\u97f3\u6765\u63a9\u76d6\u5e72\u6270\u3002',
    'toolbox.sleep.tools.enableAmbient': '\u542f\u7528\u73af\u5883\u97f3',
    'toolbox.sleep.tools.masterSwitch': '\u603b\u5f00\u5173',
    'toolbox.sleep.tools.mySounds': '\u6211\u7684\u58f0\u97f3',
    'toolbox.sleep.tools.onlineCatalog': '\u5728\u7ebf\u76ee\u5f55',
    'toolbox.sleep.tools.available': '\u53ef\u7528',
    'toolbox.sleep.tools.disabled': '\u5df2\u7981\u7528',
    'toolbox.sleep.tools.volume': '\u97f3\u91cf {pct}%',
    'toolbox.sleep.tools.notDownloaded': '\u672a\u4e0b\u8f7d',
    'toolbox.sleep.tools.downloadedReady':
        '\u5df2\u4e0b\u8f7d\uff0c\u53ef\u7528',
    'toolbox.sleep.tools.downloading': '\u4e0b\u8f7d\u4e2d...',
    'toolbox.sleep.tools.download': '\u4e0b\u8f7d',
    'toolbox.sleep.tools.enabled': '\u5df2\u542f\u7528',
    'toolbox.sleep.tools.use': '\u4f7f\u7528',

    // --- toolbox sleep sheets (Chinese) ---
    'toolbox.sleep.sheets.plannedBedtime':
        '\u8ba1\u5212\u5c31\u5bdd\u65f6\u95f4',
    'toolbox.sleep.sheets.caffeineSensitive':
        '\u5496\u5561\u56e0\u654f\u611f\u5ea6',
    'toolbox.sleep.sheets.caffeineSuggestion':
        '\u6839\u636e\u4f60\u7684\u654f\u611f\u5ea6\u548c\u8ba1\u5212\u5c31\u5bdd\u65f6\u95f4\uff0c\u8bf7\u5728 {time} \u524d\u505c\u6b62\u6444\u5165\u5496\u5561\u56e0\u3002',
    'toolbox.sleep.sheets.lightTimer': '\u5149\u7167\u8ba1\u65f6\u5668',
    'toolbox.sleep.sheets.lightTimerHint':
        '\u63a5\u89e6 {minutes} \u5206\u949f\u7684\u4eae\u5149\u4ee5\u7a33\u56fa\u4f60\u7684\u8282\u5f8b\u3002',
    'toolbox.sleep.core.cancel': '\u53d6\u6d88',
    'toolbox.sleep.sheets.cyclePlan': '90\u5206\u949f\u5468\u671f\u8ba1\u5212',
    'toolbox.sleep.sheets.cyclePlanHint':
        '\u7761\u7720\u5468\u671f\u5927\u7ea690\u5206\u949f\u3002\u56f4\u7ed5\u5468\u671f\u8fb9\u754c\u6765\u5b89\u6392\u4f60\u7684\u65f6\u95f4\u3002',
    'toolbox.sleep.sheets.targetWake': '\u76ee\u6807\u8d77\u5e8a\u65f6\u95f4',
    'toolbox.sleep.sheets.settleBuffer':
        '\u5165\u7761\u7f13\u51b2\uff1a{minutes} \u5206\u949f',
    'toolbox.sleep.sheets.backPlanLightsOff':
        '\u8ba1\u5212\uff1a{time} \u524d\u5173\u706f',
    'toolbox.sleep.sheets.backPlanHint':
        '\u4ece\u76ee\u6807\u8d77\u5e8a\u65f6\u95f4\u5012\u63a85-6\u4e2a\u5468\u671f\u3002',
    'toolbox.sleep.sheets.sleepNow': '\u5982\u679c\u73b0\u5728\u5c31\u7761',
    'toolbox.sleep.sheets.sleepNowHint':
        '\u5927\u7ea6\u5728 {time} \u9192\u6765\uff0c\u5b8c\u6210 {cycles} \u4e2a\u5b8c\u6574\u5468\u671f\u3002',
    'toolbox.sleep.sheets.leaveBed': '\u79bb\u5f00\u5e8a\u94fa',
    'toolbox.sleep.sheets.awakeAWhile':
        '\u6211\u5df2\u7ecf\u9192\u4e86\u4e00\u4f1a\u513f',
    'toolbox.sleep.sheets.stillSleepy': '\u4ecd\u7136\u611f\u5230\u56f0\u5026',
    'toolbox.sleep.sheets.busyMind':
        '\u5927\u8111\u5fd9\u788c/\u601d\u7eea\u7eb7\u98de',
    'toolbox.sleep.sheets.bodyUncomfortable':
        '\u8eab\u4f53\u611f\u89c9\u4e0d\u8212\u670d',
    'toolbox.sleep.sheets.adviceUncomfortable':
        '\u68c0\u67e5\u6e29\u5ea6\uff0c\u8c03\u6574\u88ab\u8925\uff0c\u5c1d\u8bd5\u8f7b\u67d4\u4f38\u5c55\u3002',
    'toolbox.sleep.sheets.adviceAwake':
        '\u8d77\u676515-20\u5206\u949f\uff0c\u505a\u5b89\u9759\u7684\u6d3b\u52a8\uff0c\u611f\u5230\u56f0\u5026\u518d\u56de\u5e8a\u3002',
    'toolbox.sleep.sheets.adviceBusy':
        '\u5199\u4e0b\u8111\u4e2d\u7684\u60f3\u6cd5\uff0c\u7136\u540e\u505a2\u5206\u949f\u76844-7-8\u547c\u5438\u3002',
    'toolbox.sleep.sheets.adviceSleepy':
        '\u95ed\u4e0a\u773c\u775b\uff0c\u6162\u6162\u547c\u5438\uff0c\u8ba9\u81ea\u5df1\u6e10\u6e10\u5165\u7761\u3002',

    // --- toolbox sleep library (Chinese) ---
    'toolbox.sleep.library.topic.light.title':
        '\u6668\u5149\u4e0e\u663c\u591c\u8282\u5f8b\u951a\u5b9a',
    'toolbox.sleep.library.topic.light.summary':
        '\u8d77\u5e8a\u540e30\u5206\u949f\u5185\u7684\u4eae\u5149\u662f\u8bbe\u5b9a\u4f53\u5185\u65f6\u949f\u7684\u6700\u5f3a\u4fe1\u53f7\u3002',
    'toolbox.sleep.library.topic.light.detail':
        '\u89c6\u4ea4\u53c9\u4e0a\u6838\uff08SCN\uff09\u5229\u7528\u89c6\u7f51\u819c\u4e2d\u7684ipRGC\u7ec6\u80de\u68c0\u6d4b\u5230\u7684\u5149\u7ebf\u6765\u540c\u6b65\u4f60\u7684\u663c\u591c\u8282\u5f8b\u3002\u6668\u5149\u4f7f\u4f60\u7684\u65f6\u949f\u63d0\u524d\uff0c\u8ba9\u4f60\u66f4\u5bb9\u6613\u5728\u665a\u4e0a\u5165\u7761\u3002\u5373\u4f7f\u5728\u9634\u5929\u6237\u5916\u5f8510-15\u5206\u949f\u4e5f\u80fd\u63d0\u4f9b\u8db3\u591f\u7684\u5149\u7167\u5f3a\u5ea6\u6765\u4ea7\u751f\u53ef\u6d4b\u91cf\u7684\u5dee\u5f02\u3002',
    'toolbox.sleep.library.topic.light.action_hint':
        '\u8d77\u5e8a\u540e30\u5206\u949f\u5185\u5230\u6237\u5916\u3002\u524d10\u5206\u949f\u4e0d\u8981\u6234\u592a\u9633\u955c\u3002',
    'toolbox.sleep.library.source.light_1':
        'Czeisler CA \u7b49\u3002\u4eba\u7c7b\u663c\u591c\u8282\u5f8b\u8d77\u640f\u5668\u7684\u7a33\u5b9a\u6027\u3001\u7cbe\u786e\u5ea6\u4e0e\u8fd124\u5c0f\u65f6\u5468\u671f\u3002Science (1999)\u3002',
    'toolbox.sleep.library.source.light_2':
        'Duffy JF, Czeisler CA\u3002\u5149\u7167\u5bf9\u4eba\u7c7b\u663c\u591c\u8282\u5f8b\u751f\u7406\u7684\u5f71\u54cd\u3002Sleep Med Clin (2009)\u3002',
    'toolbox.sleep.library.source.light_3':
        'Blume C \u7b49\u3002\u5149\u7167\u5bf9\u4eba\u7c7b\u663c\u591c\u8282\u5f8b\u3001\u7761\u7720\u4e0e\u60c5\u7eea\u7684\u5f71\u54cd\u3002Somnologie (2019)\u3002',
    'toolbox.sleep.library.topic.caffeine.title':
        '\u5496\u5561\u56e0\u65f6\u673a\u4e0e\u817a\u82f7\u963b\u65ad',
    'toolbox.sleep.library.topic.caffeine.summary':
        '\u5496\u5561\u56e0\u901a\u8fc7\u963b\u65ad\u817a\u82f7\u53d7\u4f53\u8d77\u4f5c\u7528\u3002\u5176\u534a\u8870\u671f\u4e3a3-7\u5c0f\u65f6\uff0c\u610f\u5473\u7740\u4e0b\u53482\u70b9\u7684\u5496\u5561\u5230\u4e86\u5348\u591c\u4ecd\u53ef\u80fd\u5f71\u54cd\u7761\u7720\u3002',
    'toolbox.sleep.library.topic.caffeine.detail':
        '\u817a\u82f7\u5728\u767d\u5929\u79ef\u7d2f\uff0c\u4ea7\u751f"\u7761\u7720\u538b\u529b"\u3002\u5496\u5561\u56e0\u6682\u65f6\u963b\u65ad\u817a\u82f7\u53d7\u4f53\uff0c\u63a9\u76d6\u56f0\u5026\u611f\u800c\u4e0d\u51cf\u5c11\u6f5c\u5728\u7684\u7761\u7720\u538b\u529b\u3002CYP1A2\u57fa\u56e0\u5dee\u5f02\u610f\u5473\u7740\u6709\u4e9b\u4eba\u4ee3\u8c22\u5496\u5561\u56e0\u7684\u901f\u5ea6\u6bd4\u5176\u4ed6\u4eba\u6162\u5f97\u591a\u3002',
    'toolbox.sleep.library.topic.caffeine.action_hint':
        '\u8bbe\u5b9a\u4e2a\u4eba\u5496\u5561\u56e0\u622a\u6b62\u65f6\u95f4\uff0c\u5728\u901a\u5e38\u5c31\u5bdd\u65f6\u95f4\u524d8-10\u5c0f\u65f6\u3002',
    'toolbox.sleep.library.source.caffeine_1':
        'Drake C \u7b49\u3002\u7761\u524d0\u30013\u62166\u5c0f\u65f6\u6444\u5165\u5496\u5561\u56e0\u5bf9\u7761\u7720\u7684\u5f71\u54cd\u3002J Clin Sleep Med (2013)\u3002',
    'toolbox.sleep.library.source.caffeine_2':
        'Landolt HP\u3002\u7761\u7720\u3001\u8b66\u89c9\u6027\u548c\u5174\u594b\u5242\u53cd\u5e94\u4e2d\u7684\u57fa\u56e0\u578b\u4f9d\u8d56\u6027\u5dee\u5f02\u3002Curr Pharm Des (2008)\u3002',
    'toolbox.sleep.library.source.caffeine_3':
        'Roehrs T, Roth T\u3002\u5496\u5561\u56e0\uff1a\u7761\u7720\u4e0e\u65e5\u95f4\u56f0\u5026\u3002Sleep Med Rev (2008)\u3002',
    'toolbox.sleep.library.topic.digital_sunset.title':
        '\u6570\u5b57\u65e5\u843d\u4e0e\u84dd\u5149',
    'toolbox.sleep.library.topic.digital_sunset.summary':
        '\u665a\u95f4\u5c4f\u5e55\u5149\u7167\uff0c\u5c24\u5176\u662f\u84dd\u8272\u6ce2\u957f\uff0c\u53ef\u80fd\u901a\u8fc7\u6fc0\u6d3b\u4e0e\u6668\u5149\u53cd\u5e94\u76f8\u540c\u7684ipRGC\u7ec6\u80de\u6765\u6291\u5236\u892a\u9ed1\u7d20\u3002',
    'toolbox.sleep.library.topic.digital_sunset.detail':
        'ipRGC\u7ec6\u80de\u4e2d\u7684\u9ed1\u89c6\u86cb\u767d\u5149\u8272\u7d20\u5bf9\u7ea6480nm\uff08\u84dd\u8272\uff09\u5149\u6700\u654f\u611f\u3002\u665a\u95f4\u66b4\u9732\u4f1a\u4f7f\u663c\u591c\u8282\u5f8b\u65f6\u949f\u5411\u540e\u63a8\u79fb\uff0c\u4f7f\u5165\u7761\u66f4\u52a0\u56f0\u96be\u3002\u7136\u800c\uff0c\u6548\u5e94\u5927\u5c0f\u5728\u4e0d\u540c\u4e2a\u4f53\u4e4b\u95f4\u5dee\u5f02\u5f88\u5927\uff0c\u5185\u5bb9\u5f15\u8d77\u7684\u7cbe\u795e\u5524\u8d77\u53ef\u80fd\u4e0e\u5149\u7167\u672c\u8eab\u540c\u6837\u91cd\u8981\u3002',
    'toolbox.sleep.library.topic.digital_sunset.action_hint':
        '\u65e5\u843d\u540e\u5c06\u8bbe\u5907\u5207\u6362\u81f3\u591c\u95f4\u6a21\u5f0f\u3002\u7761\u524d30-60\u5206\u949f\u505c\u6b62\u4e3b\u52a8\u4f7f\u7528\u5c4f\u5e55\u3002',
    'toolbox.sleep.library.source.digital_sunset_1':
        'Chang AM \u7b49\u3002\u665a\u95f4\u4f7f\u7528\u53d1\u5149\u7535\u5b50\u9605\u8bfb\u5668\u5bf9\u7761\u7720\u7684\u4e0d\u5229\u5f71\u54cd\u3002PNAS (2015)\u3002',
    'toolbox.sleep.library.source.digital_sunset_2':
        'Cajochen C \u7b49\u3002\u665a\u95f4\u66b4\u9732\u4e8e\u53d1\u5149\u4e8c\u6781\u7ba1\uff08LED\uff09\u80cc\u5149\u7535\u8111\u5c4f\u5e55\u5f71\u54cd\u663c\u591c\u8282\u5f8b\u751f\u7406\u3002J Appl Physiol (2011)\u3002',
    'toolbox.sleep.library.source.digital_sunset_3':
        'Exelmans L, Van den Bulck J\u3002\u6210\u5e74\u4eba\u7761\u524d\u624b\u673a\u4f7f\u7528\u4e0e\u7761\u7720\u3002Soc Sci Med (2016)\u3002',
    'toolbox.sleep.library.topic.stimulus_control.title':
        '\u523a\u6fc0\u63a7\u5236\uff1a\u5e8a = \u7761\u7720',
    'toolbox.sleep.library.topic.stimulus_control.summary':
        '\u6700\u6709\u6548\u7684CBT-I\u6280\u672f\u4e4b\u4e00\uff1a\u91cd\u65b0\u5c06\u5e8a\u4e0e\u7761\u7720\u8054\u7cfb\u8d77\u6765\u3002',
    'toolbox.sleep.library.topic.stimulus_control.detail':
        '\u5f53\u4eba\u4eec\u5728\u5e8a\u4e0a\u82b1\u8d39\u6e05\u9192\u65f6\u95f4\uff08\u62c5\u5fe7\u3001\u5de5\u4f5c\u3001\u770b\u8282\u76ee\uff09\uff0c\u5927\u8111\u4f1a\u5b66\u5230\u5e8a\u662f\u6e05\u9192\u7684\u5730\u65b9\u3002\u523a\u6fc0\u63a7\u5236\u7597\u6cd5\u901a\u8fc7\u89c4\u5b9a\u53ea\u5728\u56f0\u5026\u65f6\u4e0a\u5e8a\u3001\u9192\u7740\u8d85\u8fc720\u5206\u949f\u5c31\u8d77\u6765\u3001\u5e8a\u53ea\u7528\u4e8e\u7761\u7720\u6765\u6253\u7834\u8fd9\u4e2a\u5faa\u73af\u3002',
    'toolbox.sleep.library.topic.stimulus_control.action_hint':
        '\u5982\u679c\u4f60\u5728\u5e8a\u4e0a\u6e05\u9192\u8d85\u8fc720\u5206\u949f\uff0c\u5c31\u8d77\u6765\u5728\u660f\u6697\u7684\u706f\u5149\u4e0b\u505a\u4e9b\u65e0\u804a\u7684\u4e8b\u3002',
    'toolbox.sleep.library.source.stimulus_control_1':
        'Bootzin RR, Epstein D, Wood JM\u3002\u523a\u6fc0\u63a7\u5236\u6307\u5bfc\u3002\u6536\u5f55\u4e8e\uff1a\u5931\u7720\u6848\u4f8b\u7814\u7a76 (1991)\u3002',
    'toolbox.sleep.library.source.stimulus_control_2':
        'Morin CM \u7b49\u3002\u5931\u7720\u7684\u5fc3\u7406\u4e0e\u884c\u4e3a\u6cbb\u7597\uff1a\u8fd1\u671f\u8bc1\u636e\u66f4\u65b0\u3002Sleep (2006)\u3002',
    'toolbox.sleep.library.topic.diary_trends.title':
        '\u7b80\u6613\u7761\u7720\u65e5\u8bb0\u7684\u529b\u91cf',
    'toolbox.sleep.library.topic.diary_trends.summary':
        '\u4e00\u4e2a30\u79d2\u7684\u7761\u7720\u65e5\u5fd7\u63ed\u793a\u7684\u89c4\u5f8b\uff0c\u751a\u81f3\u8d85\u8fc7\u8be6\u7ec6\u7684\u7761\u7720\u8ffd\u8e2a\u5668\u3002',
    'toolbox.sleep.library.topic.diary_trends.detail':
        '\u6d88\u8d39\u7ea7\u7761\u7720\u8ffd\u8e2a\u5668\u901a\u8fc7\u8fd0\u52a8\u548c\u5fc3\u7387\u4f30\u8ba1\u7761\u7720\u9636\u6bb5\uff0c\u4f46\u5176\u51c6\u786e\u6027\u5dee\u5f02\u5f88\u5927\uff0c\u4e14\u5e38\u5e38\u9ad8\u4f30\u7761\u7720\u3002\u4e00\u4e2a\u7b80\u5355\u7684\u65e5\u8bb0\u8bb0\u5f55\u5c31\u5bdd\u65f6\u95f4\u3001\u8d77\u5e8a\u65f6\u95f4\u548c\u4e3b\u89c2\u6062\u590d\u611f\uff0c\u63d0\u4f9b\u4e86\u8ffd\u8e2a\u5668\u770b\u4e0d\u5230\u7684\u884c\u4e3a\u6a21\u5f0f\u8865\u5145\u6570\u636e\u3002',
    'toolbox.sleep.library.topic.diary_trends.action_hint':
        '\u6bcf\u665a\u53ea\u8bb0\u5f553\u4e2a\u6570\u636e\u70b9\uff1a\u4e0a\u5e8a\u65f6\u95f4\u3001\u8d77\u5e8a\u65f6\u95f4\u548c\u4f60\u611f\u89c9\u6709\u591a\u7cbe\u795e\u3002',
    'toolbox.sleep.library.source.diary_trends_1':
        'Carney CE \u7b49\u3002\u5171\u8bc6\u7761\u7720\u65e5\u8bb0\uff1a\u6807\u51c6\u5316\u524d\u77bb\u6027\u7761\u7720\u81ea\u6211\u76d1\u6d4b\u3002Sleep (2012)\u3002',
    'toolbox.sleep.library.source.diary_trends_2':
        'Baron KG \u7b49\u3002\u611f\u89c9\u88ab\u9a8c\u8bc1\u4e86\u5417\uff1f\u6d88\u8d39\u7ea7\u53ef\u7a7f\u6234\u7761\u7720\u6280\u672f\u7684\u8303\u56f4\u7efc\u8ff0\u3002Sleep Med Rev (2018)\u3002',
    'toolbox.sleep.library.source.diary_trends_3':
        'de Zambotti M \u7b49\u3002\u6212\u6307\u7684\u7761\u7720\uff1a\u014cURA\u7761\u7720\u8ffd\u8e2a\u5668\u4e0e\u591a\u5bfc\u7761\u7720\u56fe\u7684\u6bd4\u8f83\u3002Behav Sleep Med (2019)\u3002',
    'toolbox.sleep.library.topic.sleep_cycles.title':
        '\u7761\u7720\u5468\u671f\u4e0e90\u5206\u949f\u8ff7\u601d',
    'toolbox.sleep.library.topic.sleep_cycles.summary':
        '\u7761\u7720\u5468\u671f\u5e73\u5747\u7ea690\u5206\u949f\uff0c\u4f46\u8303\u56f4\u662f70-120\u5206\u949f\uff0c\u4e14\u5728\u6574\u4e2a\u591c\u95f4\u4f1a\u53d8\u5316\u3002',
    'toolbox.sleep.library.topic.sleep_cycles.detail':
        'NREM-REM\u5468\u671f\u786e\u5b9e\u9075\u5faa\u5927\u7ea690\u5206\u949f\u7684\u8282\u5f8b\uff0c\u4f46\u591c\u665a\u7684\u7b2c\u4e00\u4e2a\u5468\u671f\u901a\u5e38\u8f83\u77ed\uff08\u7ea670\u5206\u949f\uff09\u4e14\u5305\u542b\u66f4\u591a\u6df1\u5ea6\u7761\u7720\uff0c\u800c\u540e\u671f\u5468\u671f\u66f4\u957f\uff08\u7ea6100-120\u5206\u949f\uff09\u4e14\u5305\u542b\u66f4\u591aREM\u3002\u81ea\u7136\u9192\u6765\u901a\u5e38\u53d1\u751f\u5728REM\u671f\uff0c\u53ef\u4ee5\u611f\u5230\u6062\u590d\u7cbe\u529b\u3002',
    'toolbox.sleep.library.topic.sleep_cycles.action_hint':
        '\u5c0690\u5206\u949f\u7a97\u53e3\u4f5c\u4e3a\u7c97\u7565\u53c2\u8003\uff0c\u800c\u975e\u4e25\u683c\u89c4\u5219\u3002\u8d77\u5e8a\u65f6\u95f4\u7684\u4e00\u81f4\u6027\u66f4\u4e3a\u91cd\u8981\u3002',
    'toolbox.sleep.library.source.sleep_cycles_1':
        'Feinberg I, Floyd TC\u3002\u4eba\u7c7b\u7761\u7720\u5468\u671f\u5728\u591c\u95f4\u7684\u7cfb\u7edf\u6027\u8d8b\u52bf\u3002Psychophysiology (1979)\u3002',
    'toolbox.sleep.library.source.sleep_cycles_2':
        'Carskadon MA, Dement WC\u3002\u6b63\u5e38\u4eba\u7c7b\u7761\u7720\uff1a\u6982\u8ff0\u3002\u6536\u5f55\u4e8e\uff1a\u7761\u7720\u533b\u5b66\u539f\u7406\u4e0e\u5b9e\u8df5 (2011)\u3002',
    'toolbox.sleep.library.source.sleep_cycles_3':
        'Achermann P, Borb\u00e9ly AA\u3002\u7761\u7720\u7a33\u6001\u4e0e\u7761\u7720\u8c03\u8282\u6a21\u578b\u3002J Biol Rhythms (1999)\u3002',
    'toolbox.sleep.library.topic.worry_unload.title':
        '\u7761\u524d\u5378\u8f7d\u70e6\u607c',
    'toolbox.sleep.library.topic.worry_unload.summary':
        '\u7761\u524d\u8fdb\u884c\u7b80\u77ed\u7684\u3001\u6709\u7ed3\u6784\u7684\u4e66\u5199\u7ec3\u4e60\u53ef\u4ee5\u51cf\u5c11\u7761\u524d\u8ba4\u77e5\u5524\u8d77\u3002',
    'toolbox.sleep.library.topic.worry_unload.detail':
        '\u7761\u524d\u8ba4\u77e5\u5524\u8d77\u2014\u2014\u62c5\u5fe7\u3001\u8ba1\u5212\u3001\u56de\u653e\u4e8b\u4ef6\u2014\u2014\u662f\u5165\u7761\u56f0\u96be\u578b\u5931\u7720\u7684\u4e3b\u8981\u9a71\u52a8\u56e0\u7d20\u3002\u508d\u665a\u8fdb\u884c\u6709\u7ed3\u6784\u7684"\u70e6\u607c\u65f6\u95f4"\u52a0\u4e0a\u5e8a\u8fb9\u7b80\u77ed\u7684\u5378\u8f7d\u7ec3\u4e60\uff08\u5199\u4e0b\u6700\u91cd\u8981\u7684\u5fe7\u8651\u548c\u4e00\u4e2a\u6e29\u548c\u7684\u91cd\u65b0\u8868\u8ff0\uff09\u53ef\u4ee5\u51cf\u5c11\u5ef6\u8fdf\u7761\u7720\u7684\u7cbe\u795e\u6d3b\u8dc3\u3002',
    'toolbox.sleep.library.topic.worry_unload.action_hint':
        '\u5173\u706f\u4e4b\u524d\uff0c\u5199\u4e0b\u4f60\u6700\u5728\u610f\u7684\u70e6\u607c\u548c\u4e00\u4e2a\u66f4\u6e29\u548c\u7684\u89c6\u89d2\u3002',
    'toolbox.sleep.library.source.worry_unload_1':
        'Harvey AG\u3002\u5931\u7720\u7684\u8ba4\u77e5\u6a21\u578b\u3002Behav Res Ther (2002)\u3002',
    'toolbox.sleep.library.source.worry_unload_2':
        'Espie CA \u7b49\u3002\u5fc3\u7406\u751f\u7406\u6027\u5931\u7720\u53d1\u5c55\u4e2d\u7684\u6ce8\u610f-\u610f\u56fe-\u52aa\u529b\u901a\u8def\u3002Sleep Med Rev (2006)\u3002',
    'toolbox.sleep.library.topic.bedroom.title':
        '\u5367\u5ba4\u73af\u5883\u4f18\u5316',
    'toolbox.sleep.library.topic.bedroom.summary':
        '\u6e29\u5ea6\u3001\u566a\u97f3\u548c\u5149\u7ebf\u662f\u5f71\u54cd\u7761\u7720\u8d28\u91cf\u7684\u4e09\u4e2a\u4e3b\u8981\u73af\u5883\u56e0\u7d20\u3002',
    'toolbox.sleep.library.topic.bedroom.detail':
        '\u7406\u60f3\u7684\u5367\u5ba4\u7761\u7720\u6e29\u5ea6\u4e3a18-20\u00b0C\u3002\u6838\u5fc3\u4f53\u6e29\u5fc5\u987b\u4e0b\u964d\u7ea61\u00b0C\u624d\u80fd\u8fdb\u5165\u548c\u7ef4\u6301\u7761\u7720\u3002\u623f\u95f4\u592a\u70ed\u4f1a\u963b\u6b62\u8fd9\u79cd\u4e0b\u964d\u3002\u8d85\u8fc740\u5206\u8d1d\u7684\u566a\u97f3\u5373\u4f7f\u6ca1\u6709\u5b8c\u5168\u9192\u6765\u4e5f\u80fd\u5f15\u8d77\u5524\u9192\u3002',
    'toolbox.sleep.library.topic.bedroom.action_hint':
        '\u4fdd\u6301\u5367\u5ba4\u51c9\u723d\u3001\u9ed1\u6697\u548c\u5b89\u9759\u3002\u5c1d\u8bd518-20\u00b0C\u7684\u6e29\u5ea6\u3002',
    'toolbox.sleep.library.source.bedroom_1':
        'Okamoto-Mizuno K, Mizuno K\u3002\u70ed\u73af\u5883\u5bf9\u7761\u7720\u548c\u663c\u591c\u8282\u5f8b\u7684\u5f71\u54cd\u3002J Physiol Anthropol (2012)\u3002',
    'toolbox.sleep.library.source.bedroom_2':
        'Muzet A\u3002\u73af\u5883\u566a\u97f3\u3001\u7761\u7720\u4e0e\u5065\u5eb7\u3002Sleep Med Rev (2007)\u3002',
    'toolbox.sleep.library.source.bedroom_3':
        'van Maanen A \u7b49\u3002\u5149\u7597\u5bf9\u7761\u7720\u95ee\u9898\u7684\u5f71\u54cd\u3002Sleep Med Rev (2016)\u3002',
    'toolbox.sleep.library.topic.temperature.title':
        '\u6838\u5fc3\u4f53\u6e29\u4e0e\u5165\u7761',
    'toolbox.sleep.library.topic.temperature.summary':
        '\u6838\u5fc3\u4f53\u6e29\u5fc5\u987b\u4e0b\u964d\u7ea61\u00b0C\u624d\u80fd\u8fdb\u5165\u548c\u7ef4\u6301\u7761\u7720\u3002',
    'toolbox.sleep.library.topic.temperature.detail':
        '\u8eab\u4f53\u7684\u4f53\u6e29\u8c03\u8282\u7cfb\u7edf\u4e0e\u7761\u7720\u8c03\u8282\u5bc6\u5207\u76f8\u5173\u3002\u624b\u90e8\u548c\u811a\u90e8\u7684\u8840\u7ba1\u6269\u5f20\uff08\u8fd9\u5c31\u662f\u4e3a\u4ec0\u4e48\u6e29\u6696\u7684\u624b\u6709\u52a9\u4e8e\u5165\u7761\uff09\u4fc3\u8fdb\u70ed\u91cf\u6563\u5931\u3002\u7761\u524d1-2\u5c0f\u65f6\u6d17\u4e2a\u6e29\u6c34\u6fa1\u53cd\u800c\u6709\u5e2e\u52a9\uff0c\u56e0\u4e3a\u5b83\u5c06\u8840\u6db2\u5f15\u81f3\u76ae\u80a4\u8868\u9762\uff0c\u89e6\u53d1\u4f53\u6e29\u7684\u53cd\u5f39\u6027\u4e0b\u964d\u3002',
    'toolbox.sleep.library.topic.temperature.action_hint':
        '\u7761\u524d1-2\u5c0f\u65f6\u5c1d\u8bd5\u6e29\u6c34\u6fa1\u6216\u6dcb\u6d74\u3002\u4fdd\u6301\u5367\u5ba4\u7a0d\u5fae\u51c9\u723d\u3002',
    'toolbox.sleep.library.source.temperature_1':
        'Kr\u00e4uchi K \u7b49\u3002\u6e29\u6696\u7684\u811a\u4fc3\u8fdb\u5feb\u901f\u5165\u7761\u3002Nature (1999)\u3002',
    'toolbox.sleep.library.source.temperature_2':
        'Raymann RJ \u7b49\u3002\u76ae\u80a4\u6e29\u5ea6\u4e0e\u5165\u7761\u6f5c\u4f0f\u671f\u3002Physiol Behav (2007)\u3002',
    'toolbox.sleep.library.topic.nap.title':
        '\u5348\u7761\uff1a\u7b56\u7565\u6027\u4f7f\u7528\u4e0e\u65f6\u673a',
    'toolbox.sleep.library.topic.nap.summary':
        '\u5c11\u4e8e20\u5206\u949f\u7684\u77ed\u5348\u7761\u53ef\u4ee5\u63d0\u5347\u8b66\u89c9\u6027\uff0c\u800c\u4e0d\u4f1a\u5f15\u8d77\u7761\u7720\u60ef\u6027\u6216\u5e72\u6270\u591c\u95f4\u7761\u7720\u3002',
    'toolbox.sleep.library.topic.nap.detail':
        '\u7406\u60f3\u7684\u5348\u7761\u7a97\u53e3\u662f10-20\u5206\u949f\uff08"\u80fd\u91cf\u5348\u7761"\uff09\uff0c\u505c\u7559\u5728\u8f83\u6d45\u7684NREM\u7761\u7720\u9636\u6bb5\uff0c\u672a\u8fdb\u5165\u6df1\u5ea6\u6162\u6ce2\u7761\u7720\u3002\u8f83\u957f\u7684\u5348\u7761\uff0830\u5206\u949f\u4ee5\u4e0a\uff09\u6709\u7761\u7720\u60ef\u6027\u98ce\u9669\u2014\u2014\u9192\u6765\u65f6\u660f\u660f\u6c89\u6c89\u2014\u2014\u5e76\u4e14\u4f1a\u51cf\u5c11\u7a33\u6001\u7761\u7720\u538b\u529b\uff0c\u4f7f\u665a\u4e0a\u66f4\u96be\u5165\u7761\u3002',
    'toolbox.sleep.library.topic.nap.action_hint':
        '\u5348\u7761\u4e0d\u8d85\u8fc720\u5206\u949f\uff0c\u5728\u4e0b\u53483\u70b9\u4e4b\u524d\u3002\u5982\u679c\u4f60\u6709\u5931\u7720\u95ee\u9898\uff0c\u5b8c\u5168\u4e0d\u8981\u5348\u7761\u3002',
    'toolbox.sleep.library.source.nap_1':
        'Milner CE, Cote KA\u3002\u5065\u5eb7\u6210\u5e74\u4eba\u5348\u7761\u7684\u76ca\u5904\u3002J Sleep Res (2009)\u3002',
    'toolbox.sleep.library.source.nap_2':
        'Brooks A, Lack L\u3002\u591c\u95f4\u7761\u7720\u9650\u5236\u540e\u7684\u77ed\u6682\u4e0b\u5348\u5348\u7761\u3002Sleep (2006)\u3002',
    'toolbox.sleep.library.topic.white_noise.title':
        '\u767d\u566a\u97f3\u4e0e\u542c\u89c9\u63a9\u853d',
    'toolbox.sleep.library.topic.white_noise.summary':
        '\u767d\u566a\u97f3\u53ef\u4ee5\u901a\u8fc7\u63a9\u76d6\u7a81\u7136\u7684\u73af\u5883\u58f0\u97f3\u6765\u5e2e\u52a9\u51cf\u5c11\u5fae\u89c9\u9192\u3002',
    'toolbox.sleep.library.topic.white_noise.detail':
        '\u767d\u566a\u97f3\u63d0\u9ad8\u4e86\u542c\u89c9\u9608\u503c\uff0c\u4f7f\u7a81\u7136\u7684\u58f0\u97f3\uff08\u5173\u95e8\u3001\u4ea4\u901a\u3001\u90bb\u5c45\u566a\u97f3\uff09\u66f4\u96be\u89e6\u53d1\u6e05\u9192\u53cd\u5e94\u3002\u5728\u95f4\u6b47\u6027\u566a\u97f3\u800c\u975e\u6301\u7eed\u6027\u566a\u97f3\u7684\u73af\u5883\u4e2d\u6548\u679c\u6700\u4e3a\u660e\u663e\u3002',
    'toolbox.sleep.library.topic.white_noise.action_hint':
        '\u5c06\u767d\u566a\u97f3\u8bbe\u7f6e\u5728\u8212\u9002\u7684\u97f3\u91cf\uff0c\u521a\u597d\u80fd\u63a9\u76d6\u80cc\u666f\u5e72\u6270\u3002',
    'toolbox.sleep.library.source.white_noise_1':
        'Stanchina ML \u7b49\u3002\u767d\u566a\u97f3\u5bf9\u66b4\u9732\u4e8eICU\u566a\u97f3\u7684\u53d7\u8bd5\u8005\u7761\u7720\u7684\u5f71\u54cd\u3002Sleep Med (2005)\u3002',
    'toolbox.sleep.library.source.white_noise_2':
        'Forquer LM, Johnson CM\u3002\u6301\u7eed\u767d\u566a\u97f3\u51cf\u5c11\u5927\u5b66\u751f\u5165\u7761\u6f5c\u4f0f\u671f\u548c\u591c\u95f4\u9192\u6765\u6b21\u6570\u3002Sleep Hypn (2007)\u3002',
    'toolbox.sleep.library.topic.red_flags.title':
        '\u4f55\u65f6\u9700\u8981\u770b\u533b\u751f',
    'toolbox.sleep.library.topic.red_flags.summary':
        '\u67d0\u4e9b\u7761\u7720\u75c7\u72b6\u9700\u8981\u5728\u5c1d\u8bd5\u81ea\u52a9\u65b9\u6cd5\u4e4b\u524d\u8fdb\u884c\u533b\u5b66\u8bc4\u4f30\u3002',
    'toolbox.sleep.library.topic.red_flags.detail':
        '\u5927\u58f0\u3001\u4e60\u60ef\u6027\u6253\u9f3e\u5e76\u4f34\u6709\u76ee\u51fb\u7684\u547c\u5438\u6682\u505c\u63d0\u793a\u53ef\u80fd\u662f\u7761\u7720\u547c\u5438\u6682\u505c\uff0c\u5f71\u54cd10-30%\u7684\u6210\u5e74\u4eba\uff0c\u9700\u8981\u533b\u5b66\u8bca\u65ad\u3002\u4e0d\u5b81\u817f\u3001\u5e72\u6270\u7761\u7720\u7684\u6162\u6027\u75bc\u75db\u4ee5\u53ca\u4e0e\u60c5\u7eea\u53d1\u4f5c\u76f8\u5173\u7684\u7761\u7720\u969c\u788d\u4e5f\u9700\u8981\u4e13\u4e1a\u8bc4\u4f30\u3002',
    'toolbox.sleep.library.topic.red_flags.action_hint':
        '\u5982\u679c\u4f60\u5927\u58f0\u6253\u9f3e\u4e14\u5c3d\u7ba1\u7761\u7720\u65f6\u957f\u5145\u8db3\u4ecd\u611f\u89c9\u672a\u6062\u590d\u7cbe\u795e\uff0c\u8bf7\u54a8\u8be2\u533b\u751f\u8fdb\u884c\u7761\u7720\u68c0\u67e5\u3002',
    'toolbox.sleep.library.source.red_flags_1':
        'Young T \u7b49\u3002\u4e2d\u5e74\u6210\u5e74\u4eba\u4e2d\u7761\u7720\u547c\u5438\u969c\u788d\u7684\u53d1\u751f\u7387\u3002N Engl J Med (1993)\u3002',
    'toolbox.sleep.library.source.red_flags_2':
        'Winkelman JW \u7b49\u3002\u4e0d\u5b81\u817f\u7efc\u5408\u5f81\u4e34\u5e8a\u5b9e\u8df5\u6307\u5357\u3002J Clin Sleep Med (2016)\u3002',
    'toolbox.sleep.library.source.red_flags_3':
        'Baglioni C \u7b49\u3002\u7761\u7720\u4e0e\u7cbe\u795e\u969c\u788d\uff1a\u591a\u5bfc\u7761\u7720\u56fe\u7814\u7a76\u7684\u835f\u8403\u5206\u6790\u3002Psychol Bull (2016)\u3002',
    'toolbox.sleep.library.topic.references': '\u53c2\u8003\u6587\u732e',
    'toolbox.sleep.library.advice_assessment_rhythm.title':
        '\u5f00\u59cb7\u5929\u8282\u5f8b\u91cd\u7f6e',
    'toolbox.sleep.library.advice_assessment_rhythm.body':
        '\u4f60\u7684\u8bc4\u4f30\u663e\u793a\u7761\u7720\u65f6\u95f4\u8868\u4e0d\u89c4\u5f8b\u3002\u4e00\u4e2a\u4e13\u6ce8\u4e8e\u7a33\u5b9a\u8d77\u5e8a\u65f6\u95f4\u548c\u6668\u5149\u7684\u7ed3\u6784\u5316\u8282\u5f8b\u8ba1\u5212\u53ef\u4ee5\u7a33\u5b9a\u4f60\u7684\u663c\u591c\u8282\u5f8b\u3002',
    'toolbox.sleep.library.advice_assessment_rhythm.reason':
        '\u4e0d\u89c4\u5f8b\u7684\u65f6\u95f4\u8868\u524a\u5f31\u4e86\u663c\u591c\u8282\u5f8b\u4fe1\u53f7\uff0c\u4f7f\u5f97\u6309\u65f6\u5165\u7761\u548c\u8d77\u5e8a\u66f4\u52a0\u56f0\u96be\u3002',
    'toolbox.sleep.library.tag.rhythm': '\u8282\u5f8b',
    'toolbox.sleep.library.advice_assessment_wind_down.title':
        '\u5efa\u7acb\u4e00\u4e2a\u7b80\u5355\u7684\u7761\u524d\u653e\u677e\u6d41\u7a0b',
    'toolbox.sleep.library.advice_assessment_wind_down.body':
        '\u5373\u4f7f\u662f\u7b80\u5355\u7684\u4e09\u6b65\u7761\u524d\u6d41\u7a0b\uff0c\u4e5f\u80fd\u663e\u8457\u51cf\u5c11\u5165\u7761\u6240\u9700\u7684\u65f6\u95f4\uff0c\u56e0\u4e3a\u5b83\u5411\u5927\u8111\u53d1\u51fa"\u4e00\u5929\u7ed3\u675f\u4e86"\u7684\u4fe1\u53f7\u3002',
    'toolbox.sleep.library.advice_assessment_wind_down.reason':
        '\u601d\u7eea\u7eb7\u98de\u548c\u96be\u4ee5\u653e\u677e\u5bf9\u7a33\u5b9a\u7684\u884c\u4e3a\u6d41\u7a0b\u53cd\u5e94\u826f\u597d\u3002',
    'toolbox.sleep.library.tag.wind_down': '\u653e\u677e',
    'toolbox.sleep.library.advice_assessment_caffeine.title':
        '\u4f18\u5316\u4f60\u7684\u5496\u5561\u56e0\u622a\u6b62\u65f6\u95f4',
    'toolbox.sleep.library.advice_assessment_caffeine.body':
        '\u6839\u636e\u4f60\u7684\u654f\u611f\u5ea6\uff0c\u5728\u901a\u5e38\u5c31\u5bdd\u65f6\u95f4\u524d8-10\u5c0f\u65f6\u8bbe\u5b9a\u4e00\u4e2a\u4e25\u683c\u7684\u5496\u5561\u56e0\u622a\u6b62\u65f6\u95f4\uff0c\u4ee5\u4fdd\u62a4\u4f60\u7684\u81ea\u7136\u7761\u7720\u538b\u529b\u3002',
    'toolbox.sleep.library.advice_assessment_caffeine.reason':
        '\u5496\u5561\u56e0\u963b\u65ad\u817a\u82f7\u53d7\u4f53\uff0c\u63a9\u76d6\u4e86\u4f60\u5927\u8111\u8fdb\u5165\u7761\u7720\u6240\u9700\u7684\u7761\u7720\u538b\u529b\u3002',
    'toolbox.sleep.library.tag.behavior': '\u884c\u4e3a',
    'toolbox.sleep.library.advice_assessment_environment.title':
        '\u4f18\u5316\u4f60\u7684\u5367\u5ba4\u73af\u5883',
    'toolbox.sleep.library.advice_assessment_environment.body':
        '\u51c9\u723d\u3001\u9ed1\u6697\u548c\u5b89\u9759\u7684\u5367\u5ba4\u6709\u52a9\u4e8e\u6838\u5fc3\u4f53\u6e29\u7684\u81ea\u7136\u4e0b\u964d\uff0c\u8fd9\u662f\u7761\u7720\u6240\u9700\u7684\u3002',
    'toolbox.sleep.library.advice_assessment_environment.reason':
        '\u73af\u5883\u56e0\u7d20\u53ef\u80fd\u5e72\u6270\u8fdb\u5165\u7761\u7720\u7684\u751f\u7406\u8fc7\u6e21\u3002',
    'toolbox.sleep.library.tag.environment': '\u73af\u5883',
    'toolbox.sleep.library.advice_assessment_temp.title':
        '\u5229\u7528\u6e29\u5ea6\u5e2e\u52a9\u5165\u7761',
    'toolbox.sleep.library.advice_assessment_temp.body':
        '\u7761\u524d1-2\u5c0f\u65f6\u6d17\u4e2a\u6e29\u6c34\u6fa1\uff0c\u52a0\u4e0a\u51c9\u723d\u7684\u5367\u5ba4\uff0c\u6709\u52a9\u4e8e\u89e6\u53d1\u5165\u7761\u6240\u9700\u7684\u6838\u5fc3\u4f53\u6e29\u4e0b\u964d\u3002',
    'toolbox.sleep.library.advice_assessment_temp.reason':
        '\u6838\u5fc3\u4f53\u6e29\u5fc5\u987b\u4e0b\u964d\u7ea61\u00b0C\u624d\u80fd\u8fdb\u5165\u548c\u7ef4\u6301\u7761\u7720\u3002',
    'toolbox.sleep.library.tag.temperature': '\u6e29\u5ea6',
    'toolbox.sleep.library.advice_assessment_risk.title':
        '\u8003\u8651\u8fdb\u884c\u533b\u5b66\u8bc4\u4f30',
    'toolbox.sleep.library.advice_assessment_risk.body':
        '\u4f60\u7684\u8bc4\u4f30\u6807\u8bb0\u4e86\u53ef\u80fd\u7684\u98ce\u9669\u56e0\u7d20\uff0c\u8fd9\u4e9b\u56e0\u7d20\u53ef\u80fd\u9700\u8981\u5728\u81ea\u6211\u6307\u5bfc\u65b9\u6cd5\u7684\u540c\u65f6\u8fdb\u884c\u4e13\u4e1a\u8bc4\u4f30\u3002',
    'toolbox.sleep.library.advice_assessment_risk.reason':
        '\u67d0\u4e9b\u7761\u7720\u75c7\u72b6\u6709\u6f5c\u5728\u533b\u5b66\u539f\u56e0\uff0c\u6700\u597d\u7531\u533b\u7597\u4e13\u4e1a\u4eba\u5458\u8fdb\u884c\u8bc4\u4f30\u3002',
    'toolbox.sleep.library.tag.risk': '\u5065\u5eb7',
    'toolbox.sleep.library.advice_daily_minimal_log.title':
        '\u575a\u6301\u8bb0\u5f55\u2014\u2014\u4e00\u81f4\u6027\u80dc\u8fc7\u7ec6\u8282',
    'toolbox.sleep.library.advice_daily_minimal_log.body':
        '\u4f60\u7684\u6bcf\u65e5\u65e5\u5fd7\u6761\u76ee\u6b63\u5728\u6784\u5efa\u4e00\u4e2a\u80fd\u63ed\u793a\u89c4\u5f8b\u7684\u6570\u636e\u96c6\u3002\u7ee7\u7eed\u575a\u6301\u2014\u2014\u5373\u4f7f30\u79d2\u7684\u8bb0\u5f55\u4e5f\u80fd\u79ef\u7d2f\u3002',
    'toolbox.sleep.library.advice_daily_minimal_log.reason':
        '\u591a\u665a\u7684\u7761\u7720\u65e5\u8bb0\u6570\u636e\u63ed\u793a\u4e86\u5355\u665a\u5feb\u7167\u6240\u9057\u6f0f\u7684\u6a21\u5f0f\u3002',
    'toolbox.sleep.library.tag.log': '\u8bb0\u5f55',
    'toolbox.sleep.library.advice_daily_caffeine.title':
        '\u6ce8\u610f\u5496\u5561\u56e0\u8fc7\u665a\u7684\u6a21\u5f0f',
    'toolbox.sleep.library.advice_daily_caffeine.body':
        '\u4f60\u7684\u65e5\u5fd7\u663e\u793a\u67d0\u4e9b\u591c\u665a\u5728\u4e34\u7761\u65f6\u6444\u5165\u5496\u5561\u56e0\u3002\u5373\u4f7f\u4f60\u80fd\u591f\u5165\u7761\uff0c\u5496\u5561\u56e0\u4e5f\u4f1a\u51cf\u5c11\u6df1\u5ea6\u7761\u7720\u3002',
    'toolbox.sleep.library.advice_daily_caffeine.reason':
        '\u622a\u6b62\u65f6\u95f4\u540e\u7684\u5496\u5561\u56e0\u53ef\u80fd\u7834\u574f\u7761\u7720\u7ed3\u6784\uff0c\u5373\u4f7f\u6ca1\u6709\u5ef6\u8fdf\u5165\u7761\u3002',
    'toolbox.sleep.library.advice_daily_light.title':
        '\u4f18\u5148\u6668\u95f4\u5149\u7167',
    'toolbox.sleep.library.advice_daily_light.body':
        '\u4f60\u7684\u7761\u7720\u8d28\u91cf\u4e0e\u6668\u95f4\u5149\u7167\u66b4\u9732\u76f8\u5173\u3002\u8d77\u5e8a\u540e30\u5206\u949f\u5185\u5c1d\u8bd5\u6237\u5916\u6d3b\u52a810-15\u5206\u949f\u3002',
    'toolbox.sleep.library.advice_daily_light.reason':
        '\u6668\u5149\u662f\u951a\u5b9a\u663c\u591c\u8282\u5f8b\u7684\u6700\u5f3a\u65f6\u95f4\u7ebf\u7d22\u3002',
    'toolbox.sleep.library.advice_daily_screen.title':
        '\u4eca\u665a\u5c1d\u8bd5\u6570\u5b57\u65e5\u843d',
    'toolbox.sleep.library.advice_daily_screen.body':
        '\u4f60\u7684\u8fd1\u671f\u65e5\u5fd7\u4e2d\u51fa\u73b0\u6df1\u591c\u5c4f\u5e55\u4f7f\u7528\u3002\u5207\u6362\u5230\u591c\u95f4\u6a21\u5f0f\u6216\u5728\u7761\u524d30-60\u5206\u949f\u653e\u4e0b\u8bbe\u5907\u53ef\u4ee5\u6539\u5584\u7761\u7720\u8d28\u91cf\u3002',
    'toolbox.sleep.library.advice_daily_screen.reason':
        '\u665a\u95f4\u84dd\u5149\u53ef\u80fd\u6291\u5236\u892a\u9ed1\u7d20\u5e76\u5ef6\u8fdf\u5165\u7761\u3002',
    'toolbox.sleep.library.advice_daily_worry.title':
        '\u5c1d\u8bd5\u70e6\u607c\u5378\u8f7d\u7ec3\u4e60',
    'toolbox.sleep.library.advice_daily_worry.body':
        '\u4f60\u7684\u6570\u636e\u663e\u793a\u51fa\u7761\u524d\u70e6\u607c\u6216\u601d\u7eea\u5fd9\u788c\u7684\u6a21\u5f0f\u3002\u7761\u524d2\u5206\u949f\u7684\u4e66\u5199\u7ec3\u4e60\u53ef\u4ee5\u663e\u8457\u51cf\u5c11\u8fd9\u79cd\u8ba4\u77e5\u5524\u8d77\u3002',
    'toolbox.sleep.library.advice_daily_worry.reason':
        '\u7761\u524d\u8ba4\u77e5\u5524\u8d77\u662f\u5165\u7761\u56f0\u96be\u7684\u4e3b\u8981\u9a71\u52a8\u56e0\u7d20\u3002',
    'toolbox.sleep.library.tag.cognitive': '\u8ba4\u77e5',
    'toolbox.sleep.library.advice_daily_rescue.title':
        '\u628a\u591c\u9192\u5b89\u629a\u5de5\u5177\u653e\u5728\u624b\u8fb9',
    'toolbox.sleep.library.advice_daily_rescue.body':
        '\u4f60\u7684\u8fd1\u671f\u65e5\u5fd7\u4e2d\u51fa\u73b0\u591c\u95f4\u9192\u6765\u3002\u6709\u4e00\u4e2a\u9884\u5148\u8ba1\u5212\u597d\u7684\u4f4e\u523a\u6fc0\u5e94\u5bf9\u65b9\u6848\u53ef\u4ee5\u5e2e\u52a9\u4f60\u5e73\u9759\u5730\u5904\u7406\u5b83\u4eec\u3002',
    'toolbox.sleep.library.advice_daily_rescue.reason':
        '\u5bf9\u591c\u95f4\u9192\u6765\u7684\u6709\u8ba1\u5212\u7684\u56de\u5e94\u53ef\u4ee5\u51cf\u5c11\u7126\u8651\u548c\u5ef6\u957f\u6e05\u9192\u65f6\u95f4\u7684\u53cd\u590d\u770b\u949f\u3002',
    'toolbox.sleep.library.tag.rescue': '\u591c\u9192',
    'toolbox.sleep.library.advice_daily_environment.title':
        '\u8c03\u6574\u4f60\u7684\u5367\u5ba4\u73af\u5883',
    'toolbox.sleep.library.advice_daily_environment.body':
        '\u4f60\u7684\u65e5\u5fd7\u663e\u793a\u73af\u5883\u56e0\u7d20\u6b63\u5728\u5f71\u54cd\u4f60\u7684\u7761\u7720\u3002\u5bf9\u6e29\u5ea6\u3001\u5149\u7ebf\u6216\u566a\u97f3\u7684\u5c0f\u8c03\u6574\u53ef\u4ee5\u5e26\u6765\u6709\u610f\u4e49\u7684\u6539\u5584\u3002',
    'toolbox.sleep.library.advice_daily_environment.reason':
        '\u5367\u5ba4\u73af\u5883\u76f4\u63a5\u5f71\u54cd\u8eab\u4f53\u8fdb\u5165\u548c\u7ef4\u6301\u7761\u7720\u7684\u80fd\u529b\u3002',
    'toolbox.sleep.library.advice_daily_nap.title':
        '\u4f18\u5316\u4f60\u7684\u5348\u7761\u7b56\u7565',
    'toolbox.sleep.library.advice_daily_nap.body':
        '\u4f60\u7684\u6570\u636e\u663e\u793a\u51fa\u767d\u5929\u56f0\u5026\u3002\u5982\u679c\u4f60\u5348\u7761\uff0c\u8bf7\u4fdd\u6301\u572820\u5206\u949f\u4ee5\u5185\u4e14\u5728\u4e0b\u53483\u70b9\u524d\u3002\u5982\u679c\u4f60\u6709\u5931\u7720\u95ee\u9898\uff0c\u8003\u8651\u4e0d\u5348\u7761\u3002',
    'toolbox.sleep.library.advice_daily_nap.reason':
        '\u5348\u7761\u53ef\u80fd\u4f1a\u6709\u5e2e\u52a9\u4e5f\u53ef\u80fd\u635f\u5bb3\u591c\u95f4\u7761\u7720\uff0c\u53d6\u51b3\u4e8e\u65f6\u673a\u548c\u65f6\u957f\u3002',
    'toolbox.sleep.library.tag.recovery': '\u6062\u590d',
    'toolbox.sleep.library.advice_weekly_light.title':
        '\u6668\u5149\u662f\u4f60\u7684\u6700\u5f3a\u8282\u5f8b\u5de5\u5177',
    'toolbox.sleep.library.advice_weekly_light.body':
        '\u4f60\u7684\u6bcf\u5468\u6570\u636e\u663e\u793a\u6668\u5149\u4e0d\u7a33\u5b9a\u3002\u8d77\u5e8a\u540e30\u5206\u949f\u5185\u5373\u4f7f\u53ea\u5728\u6237\u5916\u5f8510\u5206\u949f\u4e5f\u80fd\u589e\u5f3a\u4f60\u7684\u7761\u7720-\u6e05\u9192\u5468\u671f\u3002',
    'toolbox.sleep.library.advice_weekly_light.reason':
        '\u7a33\u5b9a\u7684\u6668\u5149\u66b4\u9732\u662f\u7a33\u5b9a\u663c\u591c\u8282\u5f8b\u7684\u6700\u6709\u6548\u65b9\u6cd5\u3002',
    'toolbox.sleep.library.advice_weekly_caffeine.title':
        '\u4f60\u7684\u5496\u5561\u56e0\u6a21\u5f0f\u53ef\u80fd\u6b63\u5728\u964d\u4f4e\u7761\u7720\u8d28\u91cf',
    'toolbox.sleep.library.advice_weekly_caffeine.body':
        '\u4f60\u7684\u6bcf\u5468\u6570\u636e\u4e2d\uff0c\u4e34\u7761\u524d\u7684\u5496\u5561\u56e0\u4e0e\u8f83\u4f4e\u7684\u7761\u7720\u6548\u7387\u548c\u8f83\u5c11\u7684\u6df1\u5ea6\u7761\u7720\u76f8\u5173\u3002',
    'toolbox.sleep.library.advice_weekly_caffeine.reason':
        '\u8fc7\u665a\u7684\u5496\u5561\u56e0\u5373\u4f7f\u4f60\u6ca1\u6709\u6ce8\u610f\u5230\u5165\u7761\u56f0\u96be\uff0c\u4e5f\u4f1a\u5f71\u54cd\u7761\u7720\u7ed3\u6784\u3002',
    'toolbox.sleep.library.advice_weekly_screen.title':
        '\u665a\u95f4\u5c4f\u5e55\u4f7f\u7528\u6b63\u5728\u5f71\u54cd\u4f60\u7684\u7761\u7720',
    'toolbox.sleep.library.advice_weekly_screen.body':
        '\u4f60\u7684\u6570\u636e\u663e\u793a\u665a\u95f4\u5c4f\u5e55\u4f7f\u7528\u4e0e\u5165\u7761\u65f6\u95f4\u5ef6\u957f\u76f8\u5173\u3002\u5c1d\u8bd5\u7761\u524d30-60\u5206\u949f\u7684\u65e0\u5c4f\u5e55\u7f13\u51b2\u65f6\u95f4\u3002',
    'toolbox.sleep.library.advice_weekly_screen.reason':
        '\u5c4f\u5e55\u5149\u7ebf\u548c\u5185\u5bb9\u5524\u8d77\u90fd\u4f1a\u5bfc\u81f4\u5165\u7761\u5ef6\u8fdf\u3002',
    'toolbox.sleep.library.advice_weekly_rescue.title':
        '\u591c\u95f4\u9192\u6765\uff1a\u51c6\u5907\u4e00\u4e2a\u5e94\u5bf9\u8ba1\u5212',
    'toolbox.sleep.library.advice_weekly_rescue.body':
        '\u4f60\u8fd1\u671f\u65e5\u5fd7\u4e2d\u7684\u591a\u6b21\u591c\u95f4\u9192\u6765\u63d0\u793a\uff0c\u6709\u4e00\u4e2a\u9884\u5148\u8ba1\u5212\u7684\u5b89\u629a\u5e94\u5bf9\u53ef\u80fd\u6709\u6240\u5e2e\u52a9\u3002\u5173\u952e\uff1a\u907f\u514d\u770b\u949f\uff0c\u5982\u679c\u9192\u676520\u5206\u949f\u4ee5\u4e0a\u5c31\u77ed\u6682\u8d77\u6765\u3002',
    'toolbox.sleep.library.advice_weekly_rescue.reason':
        '\u5bf9\u591c\u95f4\u9192\u6765\u7684\u6709\u8ba1\u5212\u7684\u56de\u5e94\u53ef\u4ee5\u51cf\u5c11\u5ef6\u7eed\u6e05\u9192\u7684\u632b\u6298\u611f\u3002',
    'toolbox.sleep.library.advice_weekly_worry.title':
        '\u7761\u524d\u70e6\u607c\uff1a\u4e00\u4e2a\u7b80\u5355\u7684\u4e66\u5199\u7ec3\u4e60\u53ef\u80fd\u6709\u5e2e\u52a9',
    'toolbox.sleep.library.advice_weekly_worry.body':
        '\u4f60\u7684\u6570\u636e\u663e\u793a\u51fa\u8f83\u9ad8\u7684\u70e6\u607c\u6216\u601d\u7eea\u5fd9\u788c\u8bc4\u5206\u3002\u7761\u524d\u4e00\u4e2a\u7ed3\u6784\u5316\u76842\u5206\u949f"\u70e6\u607c\u5378\u8f7d"\u53ef\u4ee5\u6e05\u7406\u5fc3\u7406\u7a7a\u95f4\u4ee5\u4fbf\u5165\u7761\u3002',
    'toolbox.sleep.library.advice_weekly_worry.reason':
        '\u7761\u524d\u8ba4\u77e5\u5524\u8d77\u662f\u5ef6\u957f\u5165\u7761\u65f6\u95f4\u7684\u6700\u5f3a\u9884\u6d4b\u56e0\u7d20\u4e4b\u4e00\u3002',
    'toolbox.sleep.library.advice_weekly_environment.title':
        '\u4f60\u7684\u7761\u7720\u73af\u5883\u9700\u8981\u5173\u6ce8',
    'toolbox.sleep.library.advice_weekly_environment.body':
        '\u73af\u5883\u95ee\u9898\uff08\u6e29\u5ea6\u3001\u566a\u97f3\u3001\u5149\u7ebf\uff09\u5728\u591a\u4e2a\u591c\u665a\u4e2d\u51fa\u73b0\u3002\u6301\u7eed\u7684\u5367\u5ba4\u4f18\u5316\u53ef\u4ee5\u4ea7\u751f\u7d2f\u79ef\u7684\u76ca\u5904\u3002',
    'toolbox.sleep.library.advice_weekly_environment.reason':
        '\u6301\u7eed\u7684\u73af\u5883\u95ee\u9898\u5bf9\u7761\u7720\u8d28\u91cf\u6709\u7d2f\u79ef\u6027\u7684\u8d1f\u9762\u5f71\u54cd\u3002',
    'toolbox.sleep.library.advice_weekly_sleep_amount.title':
        '\u4f60\u7684\u603b\u7761\u7720\u65f6\u957f\u663e\u793a\u51fa\u4e00\u79cd\u6a21\u5f0f',
    'toolbox.sleep.library.advice_weekly_sleep_amount.body':
        '\u4f60\u7684\u6bcf\u5468\u7761\u7720\u65f6\u957f\u663e\u793a\u51fa\u53d8\u5f02\u6027\u3002\u5173\u6ce8\u7a33\u5b9a\u7684\u8d77\u5e8a\u65f6\u95f4\u800c\u975e\u5c31\u5bdd\u65f6\u95f4\u2014\u2014\u8fd9\u5bf9\u663c\u591c\u8282\u5f8b\u662f\u66f4\u5f3a\u7684\u951a\u70b9\u3002',
    'toolbox.sleep.library.advice_weekly_sleep_amount.reason':
        '\u8d77\u5e8a\u65f6\u95f4\u7684\u4e00\u81f4\u6027\u5bf9\u663c\u591c\u8282\u5f8b\u5065\u5eb7\u6bd4\u5c31\u5bdd\u65f6\u95f4\u7684\u4e00\u81f4\u6027\u66f4\u91cd\u8981\u3002',
    'toolbox.sleep.library.tag.sleep_amount': '\u7761\u7720\u91cf',
    'toolbox.sleep.library.empty.no_advice':
        '\u6682\u65e0\u53ef\u7528\u5efa\u8bae',
    'toolbox.sleep.library.empty.no_advice_hint':
        '\u7ee7\u7eed\u8bb0\u5f55\u4f60\u7684\u7761\u7720\u4ee5\u83b7\u53d6\u4e2a\u6027\u5316\u5efa\u8bae\u3002',
    'toolbox.sleep.library.research_detail': '\u7814\u7a76\u8be6\u60c5',

    // --- Breathing tool (toolbox_breathing_tool.dart) ---
    'toolbox.breathing.guide_title': '\u547c\u5438\u8bf4\u660e',
    'toolbox.breathing.research_basis': '\u7814\u7a76\u4f9d\u636e',
    'toolbox.breathing.how_it_works': '\u4f5c\u7528\u673a\u5236',
    'toolbox.breathing.body_focus': '\u8eab\u4f53\u5173\u6ce8',
    'toolbox.breathing.when_to_use': '\u9002\u7528\u60c5\u5883',
    'toolbox.breathing.cycle_flow': '\u8282\u62cd\u6d41\u7a0b',
    'toolbox.breathing.practice_steps': '\u7ec3\u4e60\u6b65\u9aa4',
    'toolbox.breathing.core_technique': '\u901a\u7528\u6280\u5de7',
    'toolbox.breathing.caution': '\u6ce8\u610f',
    'toolbox.breathing.advanced': '\u8fdb\u9636',
    'toolbox.breathing.altitude_simulation_prompt':
        '\u542f\u7528\u9ad8\u6d77\u62d4\u6a21\u62df\uff1f',
    'toolbox.breathing.altitude_simulation_description':
        '\u9ad8\u6d77\u62d4\u6a21\u62df\u4f1a\u6539\u53d8\u547c\u5438\u8282\u62cd\u548c\u96be\u5ea6\uff0c\u9002\u5408\u6709\u7ecf\u9a8c\u7684\u7528\u6237\u4f5c\u4e3a\u8fdb\u9636\u6311\u6218\u3002\u5982\u679c\u4f60\u6709\u547c\u5438\u7cfb\u7edf\u75be\u75c5\u3001\u5fc3\u8840\u7ba1\u95ee\u9898\u6216\u5904\u4e8e\u5b55\u671f\uff0c\u8bf7\u5148\u54a8\u8be2\u533b\u751f\u518d\u5c1d\u8bd5\u3002',
    'toolbox.breathing.altitude_extra_warning':
        '\u9ad8\u6d77\u62d4\u6a21\u62df\u4e0d\u662f\u533b\u7597\u5efa\u8bae\uff0c\u5982\u679c\u4f60\u611f\u5230\u5934\u6655\u3001\u80f8\u95f7\u6216\u5176\u4ed6\u4e0d\u9002\uff0c\u8bf7\u7acb\u5373\u505c\u6b62\u5e76\u56de\u5230\u81ea\u7136\u547c\u5438\u3002',
    'toolbox.breathing.cancel': '\u53d6\u6d88',
    'toolbox.breathing.continue_select': '\u7ee7\u7eed\u9009\u62e9',
    'toolbox.breathing.bolt_test': 'BOLT \u6d4b\u8bd5',
    'toolbox.breathing.bolt_description':
        '\u8861\u91cf\u8eab\u4f53\u5bf9\u4e8c\u6c27\u5316\u78b3\u7684\u8010\u53d7\u7a0b\u5ea6\uff0c\u5e2e\u52a9\u5224\u65ad\u76ee\u524d\u7684\u547c\u5438\u6548\u7387\u3002\u5f97\u5206\u504f\u4f4e\u901a\u5e38\u63d0\u793a\u547c\u5438\u504f\u6d45\u6216\u5bb9\u6613\u7d27\u5f20\u3002',
    'toolbox.breathing.current': '\u5f53\u524d',
    'toolbox.breathing.band': '\u533a\u95f4',
    'toolbox.breathing.best': '\u6700\u4f73',
    'toolbox.breathing.preparing': '\u51c6\u5907\u4e2d',
    'toolbox.breathing.save_result': '\u8bb0\u5f55\u7ed3\u679c',
    'toolbox.breathing.start_test': '\u5f00\u59cb\u6d4b\u8bd5',
    'toolbox.breathing.test_steps': '\u6d4b\u8bd5\u6b65\u9aa4',
    'toolbox.breathing.recommended_drills': '\u63a8\u8350\u7ec3\u4e60',
    'toolbox.breathing.reset': '\u91cd\u7f6e',
    'toolbox.breathing.seconds_unit': '\u79d2',
    'toolbox.breathing.follow_orb': '\u8ddf\u968f\u5149\u7403',
    'toolbox.breathing.keep_natural': '\u4fdd\u6301\u81ea\u7136\u547c\u5438',
    'toolbox.breathing.cycle_duration': '\u5355\u8f6e\u65f6\u957f',
    'toolbox.breathing.target': '\u76ee\u6807',
    'toolbox.breathing.done': '\u5df2\u5b8c\u6210',
    'toolbox.breathing.left': '\u5269\u4f59',
    'toolbox.breathing.pause': '\u6682\u505c',
    'toolbox.breathing.start': '\u5f00\u59cb',
    'toolbox.breathing.next_stage': '\u4e0b\u4e00\u9636\u6bb5',
    'toolbox.breathing.session_setup': '\u8bad\u7ec3\u8bbe\u7f6e',
    'toolbox.breathing.theme': '\u4e3b\u9898',
    'toolbox.breathing.duration': '\u65f6\u957f',
    'toolbox.breathing.minutes': '{minutes} \u5206\u949f',
    'toolbox.breathing.breath_hold_stage': '\u5c4f\u606f\u9636\u6bb5',
    'toolbox.breathing.breath_hold_on':
        '\u5f00\u542f\uff1a\u5c4f\u606f\u4f1a\u8ba9\u8282\u62cd\u66f4\u5b8c\u6574\uff0c\u4f46\u4e5f\u66f4\u9700\u8981\u8eab\u4f53\u9002\u5e94\u3002',
    'toolbox.breathing.breath_hold_off':
        '\u5173\u95ed\uff1a\u9002\u5408\u521d\u6b21\u7ec3\u4e60\u6216\u4e0d\u5e0c\u671b\u989d\u5916\u618b\u6c14\u7684\u7528\u6237\u3002',
    'toolbox.breathing.recovery_stage': '\u4fdd\u7559\u6062\u590d\u6bb5',
    'toolbox.breathing.recovery_on':
        '\u5f00\u542f\uff1a\u6bcf\u4e2a\u5faa\u73af\u672b\u5c3e\u6709\u4e00\u6bb5\u5b89\u9759\u6062\u590d\u3002',
    'toolbox.breathing.recovery_off':
        '\u5173\u95ed\uff1a\u53bb\u6389\u6062\u590d\u505c\u987f\uff0c\u8282\u594f\u66f4\u7d27\u51d1\u3002',
    'toolbox.breathing.voice_cues': '\u8bed\u97f3\u63d0\u793a',
    'toolbox.breathing.voice_on':
        '\u5f00\u542f\uff1a\u5728\u6bcf\u4e2a\u9636\u6bb5\u4f1a\u7528\u8bed\u97f3\u63d0\u9192\u4f60\u5438\u6c14\u3001\u547c\u6c14\u6216\u5c4f\u606f\u3002',
    'toolbox.breathing.voice_off':
        '\u5173\u95ed\uff1a\u53ea\u4fdd\u7559\u6587\u5b57\u3001\u52a8\u753b\u548c\u9707\u52a8\u53cd\u9988\u3002',
    'toolbox.breathing.text_cues': '\u6587\u5b57\u63d0\u793a',
    'toolbox.breathing.text_on':
        '\u5f00\u542f\uff1a\u5728\u5149\u7403\u65c1\u663e\u793a\u5f53\u524d\u9636\u6bb5\u7684\u6587\u5b57\u5f15\u5bfc\u3002',
    'toolbox.breathing.text_off':
        '\u5173\u95ed\uff1a\u4ec5\u4f9d\u9760\u52a8\u753b\u548c\u8bed\u97f3\u3002',
    'toolbox.breathing.haptics': '\u9707\u52a8\u53cd\u9988',
    'toolbox.breathing.haptics_on':
        '\u5f00\u542f\uff1a\u6bcf\u4e2a\u9636\u6bb5\u5207\u6362\u65f6\u6709\u8f7b\u5fae\u9707\u52a8\u63d0\u793a\u3002',
    'toolbox.breathing.haptics_off':
        '\u5173\u95ed\uff1a\u4e0d\u989d\u5916\u9707\u52a8\u3002',
    'toolbox.breathing.scenarios_title': '\u547c\u5438\u8bad\u7ec3\u573a\u666f',
    'toolbox.breathing.scenarios_subtitle':
        '\u4ece\u4e13\u6ce8\u5230\u653e\u677e\uff0c\u4ece\u65e5\u5e38\u7ec3\u4e60\u5230 BOLT \u6d4b\u8bd5\u548c\u9ad8\u6d77\u62d4\u6a21\u62df\u3002\u6bcf\u4e2a\u573a\u666f\u90fd\u6709\u8be6\u7ec6\u7684\u547c\u5438\u8bf4\u660e\u548c\u9636\u6bb5\u62c6\u89e3\u3002',
    'toolbox.breathing.rounds': '\u8f6e\u6570',
    'toolbox.breathing.sessions_completed': '\u5df2\u5b8c\u6210\u573a\u6b21',
    'toolbox.breathing.total_time': '\u7d2f\u8ba1\u65f6\u957f',
    'toolbox.breathing.voice_source': '\u8bed\u97f3\u6765\u6e90',
    'toolbox.breathing.bolt': 'BOLT',
    'toolbox.breathing.safety_note_title': '\u5b89\u5168\u63d0\u9192',
    'toolbox.breathing.safety_note_body':
        '\u547c\u5438\u8bad\u7ec3\u4e0d\u80fd\u66ff\u4ee3\u533b\u7597\u5efa\u8bae\u3002\u5982\u679c\u4f60\u6709\u547c\u5438\u7cfb\u7edf\u6216\u5fc3\u8840\u7ba1\u65b9\u9762\u7684\u95ee\u9898\uff0c\u6216\u6b63\u5728\u5b55\u671f\uff0c\u8bf7\u5728\u5f00\u59cb\u65b0\u8bad\u7ec3\u524d\u5148\u54a8\u8be2\u533b\u751f\u3002\u8bad\u7ec3\u4e2d\u5982\u51fa\u73b0\u5934\u6655\u3001\u80f8\u95f7\u6216\u4efb\u4f55\u4e0d\u8212\u670d\uff0c\u8bf7\u7acb\u5373\u505c\u4e0b\u5e76\u6062\u590d\u81ea\u7136\u547c\u5438\u3002',
    'toolbox.breathing.stop_preview': '\u505c\u6b62\u9884\u542c',
    'toolbox.breathing.preview_guidance': '\u9884\u542c\u5f15\u5bfc',
    'toolbox.breathing.voice_only_chinese_title':
        '\u5f53\u524d\u8bed\u97f3\u4ec5\u652f\u6301\u4e2d\u6587',
    'toolbox.breathing.voice_only_chinese_body':
        '\u547c\u5438\u9636\u6bb5\u8bed\u97f3\u76ee\u524d\u53ea\u63d0\u4f9b\u4e2d\u6587\u5f55\u97f3\u3002\u4f60\u4ecd\u53ef\u7ee7\u7eed\u4f7f\u7528\u5f53\u524d\u754c\u9762\u8bed\u8a00\u7684\u6587\u6848\u4e0e\u8ba1\u65f6\uff0c\u4f46\u8bed\u97f3\u4f1a\u64ad\u653e\u4e2d\u6587\u5f15\u5bfc\u3002',
    'toolbox.breathing.turn_voice_off': '\u5173\u95ed\u8bed\u97f3',
    'toolbox.breathing.keep_chinese_voice':
        '\u7ee7\u7eed\u4f7f\u7528\u4e2d\u6587\u8bed\u97f3',
    'toolbox.breathing.voice_off_status': '\u8bed\u97f3\u5df2\u5173\u95ed',
    'toolbox.breathing.voice_checking_status':
        '\u6b63\u5728\u68c0\u67e5\u8bed\u97f3\u8d44\u6e90',
    'toolbox.breathing.voice_remote_status':
        '\u5728\u7ebf\u8bed\u97f3\u5df2\u5c31\u7eea',
    'toolbox.breathing.voice_bundled_status':
        '\u5185\u7f6e\u8bed\u97f3\u5df2\u5c31\u7eea',
    'toolbox.breathing.voice_unavailable_status':
        '\u5f53\u524d\u65e0\u53ef\u7528\u7684\u9636\u6bb5\u8bed\u97f3',
    'toolbox.breathing.voice_availability_short':
        '\u8bed\u97f3\u53ef\u7528\u3002',
    'toolbox.breathing.short_stage_mute_hint':
        '\u505c\u987f\u9636\u6bb5\u4fdd\u6301\u9759\u97f3',
    'toolbox.breathing.pause_stays_silent':
        '\u505c\u987f\u9636\u6bb5\u4fdd\u6301\u9759\u97f3',
    'toolbox.breathing.remote_source': '\u5728\u7ebf\u8d44\u6e90',
    'toolbox.breathing.bundled_source': '\u5185\u7f6e\u8d44\u6e90',
    'toolbox.breathing.ready': '\u5df2\u5c31\u7eea',
    'toolbox.breathing.not_tested_yet': '\u5c1a\u672a\u6d4b\u8bd5',
    'toolbox.breathing.not_tested_body':
        '\u4f60\u8fd8\u6ca1\u6709\u5b8c\u6210 BOLT \u6d4b\u8bd5\u3002BOLT\uff08\u4f53\u5185\u6c27\u6c14\u6c34\u5e73\u6d4b\u8bd5\uff09\u8861\u91cf\u4f60\u5bf9\u4e8c\u6c27\u5316\u78b3\u7684\u8010\u53d7\u7a0b\u5ea6\uff1a\u5206\u6570\u8d8a\u9ad8\uff0c\u901a\u5e38\u547c\u5438\u6548\u7387\u8d8a\u597d\u3002',
    'toolbox.breathing.not_tested_next':
        '\u5efa\u8bae\uff1a\u5b8c\u6210\u4e00\u6b21 BOLT \u6d4b\u8bd5\u4ee5\u83b7\u5f97\u57fa\u51c6\u5206\u6570\u3002',
    'toolbox.breathing.low_bolt': 'BOLT \u504f\u4f4e',
    'toolbox.breathing.low_bolt_body':
        '\u4f60\u7684 BOLT \u504f\u4f4e\uff08\u4f4e\u4e8e 20 \u79d2\uff09\uff0c\u8bf4\u660e\u8eab\u4f53\u5bf9\u4e8c\u6c27\u5316\u78b3\u7684\u8010\u53d7\u5ea6\u8fd8\u6709\u63d0\u5347\u7a7a\u95f4\u3002\u5e38\u89c1\u539f\u56e0\u662f\u547c\u5438\u504f\u6d45\u6216\u504f\u5feb\u3002',
    'toolbox.breathing.low_bolt_next':
        '\u5148\u53bb\u8bad\u7ec3\u6a21\u5f0f\u505a\u8179\u5f0f\u57fa\u7840\u7ec3\u4e60\uff0c\u7b49 BOLT \u5347\u5230 20 \u4ee5\u4e0a\u518d\u5c1d\u8bd5\u5c4f\u606f\u7c7b\u8282\u594f\u3002',
    'toolbox.breathing.building_bolt': 'BOLT \u5efa\u8bbe\u671f',
    'toolbox.breathing.building_bolt_body':
        '\u4f60\u7684 BOLT \u5728 20-29 \u79d2\uff0c\u5904\u4e8e\u5efa\u8bbe\u671f\u3002\u547c\u5438\u6548\u7387\u8fd8\u6709\u8fdb\u6b65\u7a7a\u95f4\u3002',
    'toolbox.breathing.building_bolt_next':
        '\u7ee7\u7eed\u7ec3\u4e60\u8179\u5f0f\u547c\u5438\u548c\u65e0\u5c4f\u606f\u7684\u6162\u547c\u5438\u6a21\u5f0f\uff0c\u9010\u6b65\u63d0\u9ad8\u4e8c\u6c27\u5316\u78b3\u8010\u53d7\u3002',
    'toolbox.breathing.stable_bolt': 'BOLT \u7a33\u5b9a\u533a',
    'toolbox.breathing.stable_bolt_body':
        '\u4f60\u7684 BOLT \u5728 30-39 \u79d2\uff0c\u5c5e\u4e8e\u7a33\u5b9a\u533a\u95f4\uff0c\u9002\u5408\u5c1d\u8bd5\u5e26\u5c4f\u606f\u7684\u547c\u5438\u6a21\u5f0f\u3002',
    'toolbox.breathing.stable_bolt_next':
        '\u53ef\u4ee5\u5b89\u5168\u5c1d\u8bd5\u65b9\u5757\u547c\u5438\u30014-7-8 \u7b49\u5e26\u5c4f\u606f\u7684\u6a21\u5f0f\u3002',
    'toolbox.breathing.advanced_bolt': 'BOLT \u8fdb\u9636\u533a',
    'toolbox.breathing.advanced_bolt_body':
        '\u4f60\u7684 BOLT \u8d85\u8fc7 40 \u79d2\uff0c\u547c\u5438\u6548\u7387\u5f88\u597d\uff0c\u53ef\u4ee5\u6311\u6218\u9ad8\u6d77\u62d4\u6a21\u62df\u548c\u8fdb\u9636\u5c4f\u606f\u8bad\u7ec3\u3002',
    'toolbox.breathing.advanced_bolt_next':
        '\u53ef\u4ee5\u5c1d\u8bd5\u9ad8\u6d77\u62d4\u6a21\u62df\u548c\u66f4\u957f\u7684\u5c4f\u606f\u8bad\u7ec3\u3002\u7ee7\u7eed\u4fdd\u6301\u5b9a\u671f\u7ec3\u4e60\u3002',
    'toolbox.breathing.next_step_prefix': '\u4e0b\u4e00\u6b65\uff1a',

    // --- Daily decision / Daily choice (daily_choice_*.dart) ---
    'toolbox.daily_choice.page_title': '\u6bcf\u65e5\u6289\u62e9',
    'toolbox.daily_choice.page_subtitle':
        '\u4ece\u5403\u4ec0\u4e48\u3001\u7a7f\u4ec0\u4e48\u3001\u53bb\u54ea\u513f\u5230\u884c\u52a8\u9009\u62e9\u548c\u8f7b\u91cf\u51b3\u7b56\u8ba1\u7b97\uff0c\u628a\u65e5\u5e38\u5c0f\u7ea0\u7ed3\u53d8\u6210\u53ef\u968f\u673a\u3001\u53ef\u7f16\u8f91\u3001\u53ef\u56de\u770b\u7684\u8f7b\u91cf\u9009\u62e9\u3002',
    'toolbox.daily_choice.decision_workbench': '\u51b3\u7b56\u52a9\u624b',
    'toolbox.daily_choice.rational_guide': '\u6307\u5357',
    'toolbox.daily_choice.six_elements': '\u516d\u8981\u7d20\u6846\u67b6',
    'toolbox.daily_choice.bias_vs_noise': '\u504f\u5dee vs \u566a\u58f0',
    'toolbox.daily_choice.set_context': '\u5148\u5b9a\u51b3\u7b56\u60c5\u5883',
    'toolbox.daily_choice.calculation_model': '\u8ba1\u7b97\u6a21\u578b',
    'toolbox.daily_choice.context_influences':
        '\u60c5\u5883\u4f1a\u5f71\u54cd\u4f60\u66f4\u8be5\u5148\u770b\u968f\u673a\u3001\u52a0\u6743\u3001\u60c5\u666f\u5206\u6790\u8fd8\u662f\u5b89\u5168\u7ebf\u4f18\u5148\u3002',
    'toolbox.daily_choice.high_stakes_guardrail':
        '\u9ad8\u98ce\u9669\u573a\u666f\u5148\u770b\u5b89\u5168\u95e8\u69db\uff0c\u518d\u8c08\u6536\u76ca\u3002\u5b8c\u6574\u6e05\u5355\u5df2\u4e0b\u6c89\u5230\u5f39\u7a97\u3002',
    'toolbox.daily_choice.pre_commit_scan':
        '\u6700\u7ec8\u62cd\u677f\u524d\uff0c\u5feb\u901f\u626b\u4e00\u904d\u504f\u5dee\u3001\u566a\u58f0\u548c\u590d\u76d8\u6761\u4ef6\u3002',
    'toolbox.daily_choice.guided_decision_flow': '\u5feb\u901f\u51b3\u7b56',
    'toolbox.daily_choice.frame_question': '\u5148\u5199\u6e05\u95ee\u9898',
    'toolbox.daily_choice.options': '\u53ef\u9009\u9879',
    'toolbox.daily_choice.classify_situation': '\u60c5\u5883\u5206\u578b',
    'toolbox.daily_choice.check_guardrails_first':
        '\u5148\u68c0\u67e5\u5b89\u5168\u95e8\u69db\uff0c\u518d\u8c08\u6536\u76ca\u3002',
    'toolbox.daily_choice.guardrail_best_for':
        '\u9002\u7528\uff1a\u9ad8\u98ce\u9669\u3001\u96be\u56de\u5934\u3001\u65f6\u95f4\u7d27\u6216\u9700\u8981\u5148\u5b88\u4f4f\u57fa\u672c\u76d8\u3002',
    'toolbox.daily_choice.six_modules': '\u516d\u6a21\u5757\u57fa\u7840\u7248',
    'toolbox.daily_choice.local_custom': '\u672c\u5730\u81ea\u5b9a\u4e49',
    'toolbox.daily_choice.let_choice_move':
        '\u5148\u8ba9\u9009\u62e9\u52a8\u8d77\u6765',
    'toolbox.daily_choice.uniform_random': '\u5747\u5300\u968f\u673a',
    'toolbox.daily_choice.uniform_random_subtitle':
        '\u9002\u5408\u4f4e\u98ce\u9669\u3001\u53ef\u56de\u9000\u3001\u5dee\u522b\u4e0d\u5927\u7684\u65e5\u5e38\u9009\u62e9\u3002',
    'toolbox.daily_choice.uniform_random_formula':
        '\u6bcf\u4e2a\u9009\u9879\u6982\u7387\u76f8\u540c\uff0c\u76ee\u7684\u662f\u5c3d\u5feb\u7ed3\u675f\u72b9\u8c6b\u3002',
    'toolbox.daily_choice.uniform_random_caution':
        '\u4e0d\u8981\u628a\u968f\u673a\u5f53\u6210\u9ad8\u98ce\u9669\u51b3\u7b56\u7684\u4f9d\u636e\u3002',
    'toolbox.daily_choice.weighted_factors': '\u52a0\u6743\u56e0\u7d20',
    'toolbox.daily_choice.weighted_factors_subtitle':
        '\u628a\u4ef7\u503c\u3001\u6210\u529f\u7387\u3001\u53ef\u56de\u9000\u6027\u3001\u98ce\u9669\u548c\u4fe1\u606f\u5dee\u653e\u5230\u540c\u4e00\u628a\u5c3a\u5b50\u4e0a\u6bd4\u8f83\u3002',
    'toolbox.daily_choice.weighted_factors_formula':
        '\u6b63\u5411\u9879\u52a0\u6743 - \u98ce\u9669/\u6295\u5165/\u540e\u6094/\u4fe1\u606f\u5dee\u60e9\u7f5a\u3002',
    'toolbox.daily_choice.weighted_factors_caution':
        '\u5b83\u9002\u5408\u6392\u5e8f\uff0c\u4e0d\u4ee3\u8868\u7edd\u5bf9\u6b63\u786e\u3002',
    'toolbox.daily_choice.expected_value': '\u671f\u671b\u6536\u76ca',
    'toolbox.daily_choice.expected_value_subtitle':
        '\u9002\u5408\u7ed3\u679c\u4e0d\u786e\u5b9a\u3001\u4f46\u53ef\u4ee5\u4f30\u4e00\u4e2a\u5927\u81f4\u6210\u529f\u7387\u7684\u9009\u62e9\u3002',
    'toolbox.daily_choice.expected_value_formula':
        '\u6210\u529f\u6982\u7387 \u00d7 \u6536\u76ca - \u5931\u8d25\u66b4\u9732 - \u6295\u5165\u6210\u672c\u3002',
    'toolbox.daily_choice.expected_value_caution':
        '\u8f93\u5165\u6982\u7387\u6765\u81ea\u4f60\u7684\u5224\u65ad\uff0c\u5148\u505a\u72ec\u7acb\u4f30\u503c\u518d\u8ba8\u8bba\u3002',
    'toolbox.daily_choice.joint_probability': '\u8054\u5408\u6982\u7387',
    'toolbox.daily_choice.joint_probability_subtitle':
        '\u5f53\u7ed3\u679c\u9700\u8981\u201c\u5224\u65ad\u5bf9 + \u6267\u884c\u5230\u4f4d + \u6761\u4ef6\u771f\u7684\u6210\u7acb\u201d\u65f6\uff0c\u7528\u66f4\u4fdd\u5b88\u7684\u4e58\u6cd5\u3002',
    'toolbox.daily_choice.joint_probability_formula':
        '\u6210\u529f\u6982\u7387 \u00d7 \u6267\u884c\u6982\u7387 \u00d7 \u628a\u63e1\u5ea6\uff0c\u518d\u6263\u6389\u4e0b\u884c\u66b4\u9732\u3002',
    'toolbox.daily_choice.joint_probability_caution':
        '\u9002\u5408\u591a\u6761\u4ef6\u8054\u52a8\uff0c\u4e0d\u9002\u5408\u628a\u5f7c\u6b64\u5f3a\u76f8\u5173\u7684\u4e8b\u4ef6\u786c\u62c6\u5f00\u3002',
    'toolbox.daily_choice.scenario_blend': '\u60c5\u666f\u5206\u6790',
    'toolbox.daily_choice.scenario_blend_subtitle':
        '\u628a\u4e50\u89c2\u3001\u57fa\u51c6\u3001\u60b2\u89c2\u4e09\u79cd\u60c5\u666f\u540c\u65f6\u6446\u51fa\u6765\uff0c\u907f\u514d\u53ea\u76ef\u7740\u6700\u597d\u7ed3\u679c\u3002',
    'toolbox.daily_choice.scenario_blend_formula':
        '\u4e50\u89c2 + \u57fa\u51c6 + \u60b2\u89c2\u6309\u4e0d\u786e\u5b9a\u6027\u52a0\u6743\u6c47\u603b\u3002',
    'toolbox.daily_choice.scenario_blend_caution':
        '\u9ad8\u4e0d\u786e\u5b9a\u65f6\u8981\u8ba9\u60b2\u89c2\u60c5\u666f\u771f\u6b63\u8fdb\u573a\u3002',
    'toolbox.daily_choice.regret_balance':
        '\u540e\u6094\u4e0e\u673a\u4f1a\u6210\u672c',
    'toolbox.daily_choice.regret_balance_subtitle':
        '\u9002\u5408\u5bb9\u6613\u4e8b\u540e\u53cd\u590d\u60f3\u201c\u65e9\u77e5\u9053\u5c31\u9009\u53e6\u4e00\u4e2a\u201d\u7684\u9009\u62e9\u3002',
    'toolbox.daily_choice.regret_balance_formula':
        '\u5df2\u5b9e\u73b0\u6f5c\u529b + \u53ef\u56de\u9000\u8865\u507f - \u540e\u6094\u66b4\u9732 - \u673a\u4f1a\u6210\u672c\u3002',
    'toolbox.daily_choice.regret_balance_caution':
        '\u5b83\u662f\u5728\u6821\u6b63\u60c5\u7eea\uff0c\u4e0d\u662f\u5728\u9884\u6d4b\u547d\u8fd0\u3002',
    'toolbox.daily_choice.threshold_guardrail':
        '\u5b89\u5168\u7ebf\u4f18\u5148',
    'toolbox.daily_choice.threshold_guardrail_subtitle':
        '\u5148\u770b\u662f\u5426\u8fc7\u6700\u4f4e\u95e8\u69db\uff0c\u518d\u5728\u8fc7\u5173\u9009\u9879\u91cc\u6bd4\u8f83\u4f18\u5148\u7ea7\u3002',
    'toolbox.daily_choice.threshold_guardrail_formula':
        '\u5148\u5224\u5b9a\u4fe1\u5fc3\u3001\u98ce\u9669\u3001\u53ef\u56de\u9000\u6027\u3001\u4fe1\u606f\u5dee\u662f\u5426\u8fc7\u7ebf\uff0c\u518d\u7528\u7efc\u5408\u5206\u505a\u540c\u6863\u6bd4\u8f83\u3002',
    'toolbox.daily_choice.threshold_guardrail_caution':
        '\u9ad8\u98ce\u9669\u573a\u666f\u5148\u770b\u5b89\u5168\u7ebf\uff0c\u518d\u8c08\u6536\u76ca\u3002',
    'toolbox.daily_choice.calibrated_forecast': '\u6821\u51c6\u9884\u6d4b',
    'toolbox.daily_choice.calibrated_forecast_subtitle':
        '\u628a\u8fc7\u4e8e\u6781\u7aef\u7684\u671f\u671b\u503c\u5f80\u5747\u503c\u62c9\u56de\uff0c\u51cf\u5c11\u8fc7\u5ea6\u81ea\u4fe1\u3002',
    'toolbox.daily_choice.calibrated_forecast_formula':
        '\u5e73\u5747\u503c + \u628a\u63e1\u5ea6 \u00d7 (\u539f\u59cb\u9884\u671f - \u5e73\u5747\u503c)\u3002',
    'toolbox.daily_choice.calibrated_forecast_caution':
        '\u5b83\u4e0d\u662f\u673a\u5668\u5b66\u4e60\uff0c\u53ea\u662f\u628a\u6781\u7aef\u5224\u65ad\u6536\u4e00\u70b9\u3002',
    'toolbox.daily_choice.classify_first':
        '\u5148\u5206\u578b\u518d\u9009\u6cd5',
    'toolbox.daily_choice.classify_first_subtitle':
        '\u771f\u6b63\u9ad8\u8d28\u91cf\u7684\u51b3\u7b56\uff0c\u5148\u5224\u65ad\u662f\u4ec0\u4e48\u7c7b\u578b\uff0c\u518d\u51b3\u5b9a\u7528\u54ea\u79cd\u8ba1\u7b97\u955c\u5934\u3002',
    'toolbox.daily_choice.low_stakes_fast':
        '\u4f4e\u98ce\u9669\u4e14\u53ef\u56de\u9000\uff1a\u76f4\u63a5\u5feb\u51b3',
    'toolbox.daily_choice.low_stakes_fast_body':
        '\u9910\u5385\u3001\u5468\u672b\u5b89\u6392\u3001\u8f7b\u91cf\u8d2d\u4e70\u8fd9\u7c7b\u95ee\u9898\uff0c\u91cd\u70b9\u4e0d\u662f\u201c\u6700\u4f18\u201d\uff0c\u800c\u662f\u522b\u628a\u7cbe\u529b\u8017\u5728\u72b9\u8c6b\u4e0a\u3002\u968f\u673a\u6216\u52a0\u6743\u56e0\u7d20\u901a\u5e38\u5c31\u591f\u3002',
    'toolbox.daily_choice.high_stakes_guardrail_title':
        '\u9ad8\u98ce\u9669\u6216\u96be\u56de\u5934\uff1a\u5148\u8bbe\u5b89\u5168\u95e8\u69db',
    'toolbox.daily_choice.high_stakes_guardrail_body':
        '\u5982\u679c\u4e00\u65e6\u505a\u9519\u5f88\u96be\u8865\u6551\uff0c\u5148\u770b\u98ce\u9669\u3001\u628a\u63e1\u5ea6\u3001\u4fe1\u606f\u5dee\u548c\u53ef\u56de\u9000\u6027\u662f\u5426\u8fc7\u7ebf\uff0c\u518d\u6bd4\u8f83\u6536\u76ca\u3002',
    'toolbox.daily_choice.high_uncertainty_pessimistic':
        '\u9ad8\u4e0d\u786e\u5b9a\uff1a\u4e00\u5b9a\u8981\u628a\u60b2\u89c2\u60c5\u666f\u62c9\u8fdb\u6765',
    'toolbox.daily_choice.high_uncertainty_pessimistic_body':
        '\u5f53\u4f60\u77e5\u9053\u81ea\u5df1\u4e0d\u77e5\u9053\u5f88\u591a\u65f6\uff0c\u5355\u4e00\u5206\u6570\u4e0d\u591f\uff0c\u8981\u540c\u65f6\u770b\u8054\u5408\u6982\u7387\u3001\u60c5\u666f\u5206\u6790\u548c\u4fe1\u606f\u4ef7\u503c\u3002',
    'toolbox.daily_choice.six_elements_quality':
        '\u4f18\u8d28\u51b3\u7b56\u516d\u8981\u7d20',
    'toolbox.daily_choice.six_elements_quality_subtitle':
        '\u6765\u81ea\u65af\u5766\u798f\u51b3\u7b56\u8d28\u91cf\u6846\u67b6\uff0c\u662f\u8fd9\u4e2a\u5b50\u6a21\u5757\u6700\u91cd\u8981\u7684\u9aa8\u67b6\u3002',
    'toolbox.daily_choice.frame_question_right':
        '\u5148\u628a\u95ee\u9898\u6846\u51c6',
    'toolbox.daily_choice.frame_question_right_body':
        '\u5148\u660e\u786e\u4f60\u5728\u51b3\u5b9a\u4ec0\u4e48\u3001\u65f6\u95f4\u8303\u56f4\u662f\u4ec0\u4e48\u3001\u54ea\u4e9b\u7ea6\u675f\u4e0d\u80fd\u7834\u3002\u95ee\u9898\u6846\u9519\u4e86\uff0c\u518d\u7cbe\u7ec6\u8ba1\u7b97\u4e5f\u4f1a\u504f\u3002',
    'toolbox.daily_choice.generate_options':
        '\u81f3\u5c11\u9020\u51fa 2 \u5230 3 \u4e2a\u53ef\u9009\u9879',
    'toolbox.daily_choice.generate_options_body':
        '\u5f88\u591a\u7cdf\u7cd5\u51b3\u7b56\u4e0d\u662f\u5728\u574f\u9009\u9879\u91cc\u9009\uff0c\u800c\u662f\u6839\u672c\u6ca1\u6709\u8ba4\u771f\u751f\u6210\u5907\u9009\u3002\u5148\u6269\u5c55\uff0c\u518d\u6536\u53e3\u3002',
    'toolbox.daily_choice.reliable_info':
        '\u4fe1\u606f\u8981\u76f8\u5173\u4e14\u53ef\u9760',
    'toolbox.daily_choice.values_tradeoffs':
        '\u628a\u4ef7\u503c\u548c\u6743\u8861\u5199\u51fa\u6765',
    'toolbox.daily_choice.transparent_reasoning':
        '\u8bba\u8bc1\u8981\u900f\u660e\uff0c\u53ef\u590d\u76d8',
    'toolbox.daily_choice.decision_to_action':
        '\u51b3\u5b9a\u540e\u5fc5\u987b\u843d\u5230\u52a8\u4f5c',
    'toolbox.daily_choice.probability_uncertainty':
        '\u6982\u7387\u4e0e\u4e0d\u786e\u5b9a\u6027',
    'toolbox.daily_choice.probability_uncertainty_subtitle':
        '\u628a\u201c\u786e\u5b9a/\u4e0d\u786e\u5b9a\u201d\u7684\u60c5\u7eea\u8bed\u8a00\uff0c\u8f6c\u6210\u66f4\u53ef\u6bd4\u8f83\u7684\u6982\u7387\u8bed\u8a00\u3002',
    'toolbox.daily_choice.assign_probabilities':
        '\u5148\u7ed9\u6982\u7387\uff0c\u518d\u8c08\u7ed3\u8bba',
    'toolbox.daily_choice.use_multiplication':
        '\u591a\u6761\u4ef6\u540c\u65f6\u6210\u7acb\u65f6\uff0c\u7528\u4e58\u6cd5\u66f4\u4fdd\u5b88',
    'toolbox.daily_choice.pull_extremes_back':
        '\u9ad8\u4e0d\u786e\u5b9a\u65f6\uff0c\u628a\u6781\u7aef\u5224\u65ad\u5f80\u5747\u503c\u62c9\u56de',
    'toolbox.daily_choice.update_evidence':
        '\u65b0\u8bc1\u636e\u6765\u4e86\uff0c\u5c31\u66f4\u65b0\uff0c\u4e0d\u8981\u786c\u625b',
    'toolbox.daily_choice.bias_noise_control':
        '\u504f\u5dee\u4e0e\u566a\u58f0\u6821\u6b63',
    'toolbox.daily_choice.bias_noise_control_subtitle':
        '\u907f\u514d\u88ab\u951a\u70b9\u3001\u6c89\u6ca1\u6210\u672c\u3001\u6545\u4e8b\u611f\u548c\u7fa4\u4f53\u566a\u58f0\u5e26\u8dd1\u3002',
    'toolbox.daily_choice.independent_estimate':
        '\u5148\u72ec\u7acb\u4f30\uff0c\u518d\u4ea4\u6d41\uff0c\u9632\u951a\u5b9a',
    'toolbox.daily_choice.sunk_cost':
        '\u6c89\u6ca1\u6210\u672c\u4e0d\u662f\u7ee7\u7eed\u6295\u5165\u7684\u7406\u7531',
    'toolbox.daily_choice.common_scale':
        '\u7528\u7edf\u4e00\u5c3a\u5ea6\u9010\u9879\u6bd4\u8f83\uff0c\u964d\u4f4e\u566a\u58f0',
    'toolbox.daily_choice.good_story':
        '\u6545\u4e8b\u597d\u542c\uff0c\u4e0d\u7b49\u4e8e\u8bc1\u636e\u591f\u5f3a',
    'toolbox.daily_choice.when_to_research':
        '\u4f55\u65f6\u7ee7\u7eed\u67e5\uff0c\u4f55\u65f6\u76f4\u63a5\u505a',
    'toolbox.daily_choice.when_to_research_subtitle':
        '\u4fe1\u606f\u4ef7\u503c\u4e0d\u662f\u65e0\u9650\u7684\uff0c\u5206\u6790\u4e5f\u9700\u8981\u505c\u8868\u70b9\u3002',
    'toolbox.daily_choice.most_likely_flip':
        '\u5982\u679c\u4e00\u6761\u4fe1\u606f\u6700\u53ef\u80fd\u6539\u7ed3\u8bba\uff0c\u5c31\u5148\u53bb\u8865\u5b83',
    'toolbox.daily_choice.stop_rule':
        '\u8bbe\u505c\u6b62\u89c4\u5219\uff0c\u9632\u6b62\u65e0\u9650\u5206\u6790',
    'toolbox.daily_choice.premortem':
        '\u9ad8\u98ce\u9669\u5148\u505a\u4e00\u6b21\u9884\u6f14\u5f0f\u5931\u8d25\u590d\u76d8',
    'toolbox.daily_choice.professional_judgment':
        '\u533b\u7597\u3001\u6cd5\u5f8b\u3001\u91d1\u878d\u4ecd\u9700\u4e13\u4e1a\u5224\u65ad',
    'toolbox.daily_choice.score_independently':
        '\u5148\u72ec\u7acb\u6253\u5206\uff0c\u518d\u770b\u522b\u4eba\u610f\u89c1',
    'toolbox.daily_choice.no_double_down':
        '\u4e0d\u8981\u4e3a\u6c89\u6ca1\u6210\u672c\u8ffd\u52a0\u6295\u5165',
    'toolbox.daily_choice.same_fields':
        '\u7528\u540c\u4e00\u5957\u5b57\u6bb5\u6bd4\u8f83\u6240\u6709\u9009\u9879',
    'toolbox.daily_choice.base_rates_high_uncertainty':
        '\u9ad8\u4e0d\u786e\u5b9a\u65f6\uff0c\u4f18\u5148\u770b\u57fa\u51c6\u7387\u548c\u5747\u503c\u56de\u5f52',
    'toolbox.daily_choice.research_flip_fact':
        '\u5148\u8865\u6700\u53ef\u80fd\u6539\u53d8\u7ed3\u8bba\u7684\u90a3\u6761\u4fe1\u606f',
    'toolbox.daily_choice.premortem_high_stakes':
        '\u9ad8\u98ce\u9669\u51b3\u7b56\u5148\u505a\u4e00\u6b21\u9884\u6f14\u5f0f\u590d\u76d8',
    'toolbox.daily_choice.value_ranking_disagree':
        '\u8de8\u65b9\u6cd5\u5206\u6b67\u5927\u65f6\uff0c\u56de\u5230\u4ef7\u503c\u6392\u5e8f',
    'toolbox.daily_choice.stop_rule_now':
        '\u73b0\u5728\u5c31\u8981\u5b9a\u65f6\uff0c\u5148\u5199\u4e0b\u505c\u6b62\u89c4\u5219',
    'toolbox.daily_choice.joint_rounds': '\u8054\u5408\u5206\u5e03\u8f6e\u6b21',
    'toolbox.daily_choice.dice_count': '\u9ab0\u5b50\u6570\u91cf',
    'toolbox.daily_choice.guide': '\u6307\u5357',
    'toolbox.daily_choice.ready_to_draw': '\u7b49\u5f85\u62bd\u53d6',
    'toolbox.daily_choice.picked': '\u62bd\u4e2d\uff1a{winner}',
    'toolbox.daily_choice.low_stakes_choice': '\u4f4e\u98ce\u9669\u9009\u62e9',
    'toolbox.daily_choice.hub_title': '\u6bcf\u65e5\u6289\u62e9',
    'toolbox.daily_choice.hub_subtitle':
        '\u628a\u65e5\u5e38\u5c0f\u7ea0\u7ed3\u53d8\u6210\u53ef\u968f\u673a\u3001\u53ef\u7f16\u8f91\u3001\u53ef\u56de\u770b\u7684\u8f7b\u91cf\u9009\u62e9\u3002',
    'toolbox.daily_choice.recipe_library': '\u83dc\u8c31\u5e93',
    'toolbox.daily_choice.wear_library': '\u8863\u67dc\u642d\u914d',
    'toolbox.daily_choice.activity_library': '\u6d3b\u52a8\u5e93',
    'toolbox.daily_choice.place_library': '\u5730\u70b9\u5e93',
    'toolbox.daily_choice.weather_not_ready':
        '\u5f53\u524d\u5148\u67e5\u770b\u5168\u90e8\u6c14\u6e29\uff1b\u82e5\u5929\u6c14\u63d0\u9192\u5df2\u8bfb\u53d6\u5929\u6c14\uff0c\u8fd9\u91cc\u4f1a\u81ea\u52a8\u7528\u4e8e\u7a7f\u642d\u5efa\u8bae\u3002',
  };

  String t(
    String key, {
    Map<String, Object?> params = const <String, Object?>{},
  }) {
    final lang = normalizeLanguageCode(languageCode);
    final table = switch (lang) {
      'zh' => {
        ..._zh,
        ..._focusZh,
        ..._extraZh,
        ..._focusEnhancedZh,
        ..._toolboxEn,
        ..._toolboxZh,
      },
      'ja' => {
        ..._ja,
        ..._focusJa,
        ..._extraJa,
        ..._focusEnhancedJa,
        ..._toolboxEn,
      },
      'de' => {
        ..._de,
        ..._focusDe,
        ..._extraDe,
        ..._focusEnhancedDe,
        ..._toolboxEn,
      },
      'fr' => {
        ..._fr,
        ..._focusFr,
        ..._extraFr,
        ..._focusEnhancedFr,
        ..._toolboxEn,
      },
      'es' => {
        ..._es,
        ..._focusEs,
        ..._extraEs,
        ..._focusEnhancedEs,
        ..._toolboxEn,
      },
      'ru' => {
        ..._en,
        ..._focusEn,
        ..._extraEn,
        ..._focusEnhancedEn,
        ..._ru,
        ..._extraRu,
        ..._focusEnhancedRu,
        ..._toolboxEn,
      },
      _ => {
        ..._en,
        ..._focusEn,
        ..._extraEn,
        ..._focusEnhancedEn,
        ..._toolboxEn,
      },
    };
    var value =
        AppI18nCatalog.lookup(lang, key) ??
        AppI18nCatalog.lookup('en', key) ??
        AppI18nCatalog.lookup('zh', key) ??
        table[key] ??
        _extraEn[key] ??
        _focusEnhancedEn[key] ??
        _en[key] ??
        _focusEn[key] ??
        _humanizeKey(key);
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
    }
    return value;
  }

  String _humanizeKey(String key) {
    final withSpaces = key.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    if (withSpaces.isEmpty) return key;
    return withSpaces[0].toUpperCase() + withSpaces.substring(1);
  }
}
