// ignore_for_file: unused_element, unused_field

import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../services/app_log_service.dart';
import '../../services/audio_player_source_helper.dart';
import '../../services/cstcloud_resource_cache_service.dart';
import '../../services/toolbox_soothing_audio_service.dart';
import '../../services/toolbox_soothing_prefs_service.dart';
import 'toolbox_soothing_music/runtime_store.dart';
import 'toolbox_soothing_music/track_catalog.dart';
import 'toolbox_soothing_music/track_loader.dart';
import 'toolbox_soothing_music_v2_copy.dart';
import '../legacy_style.dart';
import '../modal_helpers.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';

final AudioContext _soothingAudioContext = AudioContextConfig(
  focus: AudioContextConfigFocus.mixWithOthers,
).build();

typedef _SoothingTrack = SoothingMusicTrack;
typedef _SoothingRuntimeStore = SoothingMusicRuntimeStore;

class SoothingMusicV2Page extends StatefulWidget {
  const SoothingMusicV2Page({super.key});

  @override
  State<SoothingMusicV2Page> createState() => _SoothingMusicV2PageState();
}

enum _ModeLibraryFilter { all, favorites, recent }

enum _SoothingPageMenuAction {
  toggleContinuePlayback,
  playbackSingleLoop,
  playbackModeCycle,
  playbackArrangement,
  editArrangement,
  toggleFullscreen,
}

class _SoothingModeTheme {
  const _SoothingModeTheme({
    required this.id,
    required this.zhTitle,
    required this.enTitle,
    required this.zhSubtitle,
    required this.enSubtitle,
    required this.zhDescription,
    required this.enDescription,
    required this.icon,
    required this.accent,
    required this.orbitAccent,
    required this.backgroundA,
    required this.backgroundB,
    required this.blobA,
    required this.blobB,
    required this.footerZh,
    required this.footerEn,
  });

  final String id;
  final String zhTitle;
  final String enTitle;
  final String zhSubtitle;
  final String enSubtitle;
  final String zhDescription;
  final String enDescription;
  final IconData icon;
  final Color accent;
  final Color orbitAccent;
  final Color backgroundA;
  final Color backgroundB;
  final Color blobA;
  final Color blobB;
  final String footerZh;
  final String footerEn;

  String title(AppI18n i18n) => SoothingMusicCopy.modeTitle(i18n, id);
  String subtitle(AppI18n i18n) => SoothingMusicCopy.modeSubtitle(i18n, id);
  String description(AppI18n i18n) =>
      SoothingMusicCopy.modeDescription(i18n, id);
  String footer(AppI18n i18n) => SoothingMusicCopy.modeFooter(i18n, id);
}

class _TrackLabelPair {
  const _TrackLabelPair({required this.zh, required this.en});

  final String zh;
  final String en;
}

class _SoothingVisualPalette {
  const _SoothingVisualPalette({
    required this.isDark,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.panelSurface,
    required this.panelSurfaceMuted,
    required this.controlSurface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.orbitAccent,
    required this.glowA,
    required this.glowB,
    required this.dangerBg,
    required this.dangerFg,
  });

  final bool isDark;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color panelSurface;
  final Color panelSurfaceMuted;
  final Color controlSurface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color orbitAccent;
  final Color glowA;
  final Color glowB;
  final Color dangerBg;
  final Color dangerFg;

  factory _SoothingVisualPalette.resolve({
    required bool isDark,
    required AppearanceConfig appearance,
    required _SoothingModeTheme mode,
  }) {
    final effectStrength =
        0.34 + appearance.normalizedEffectIntensity * (isDark ? 0.42 : 0.28);
    final accent = mode.accent;
    final orbitAccent = mode.orbitAccent;
    final backgroundTop = isDark
        ? const Color(0xFF2A384B)
        : const Color(0xFFF4F7F9);
    final backgroundBottom = isDark
        ? const Color(0xFF101823)
        : const Color(0xFFDDE5EA);
    final panelSurface = Color.lerp(
      isDark ? const Color(0xFF182433) : Colors.white,
      accent,
      isDark ? 0.1 + effectStrength * 0.04 : 0.04 + effectStrength * 0.03,
    )!.withValues(alpha: isDark ? 0.94 : 0.96);
    final panelSurfaceMuted = Color.lerp(
      isDark ? const Color(0xFF1E2B3C) : const Color(0xFFF7FAFC),
      orbitAccent,
      isDark ? 0.08 : 0.04,
    )!.withValues(alpha: isDark ? 0.92 : 0.96);
    final controlSurface = Color.lerp(
      isDark ? const Color(0xFF233245) : Colors.white,
      accent,
      isDark ? 0.14 : 0.06,
    )!.withValues(alpha: isDark ? 0.96 : 0.98);
    final border = Color.lerp(
      isDark ? const Color(0xFF41556D) : const Color(0xFFB8C4CE),
      accent,
      isDark ? 0.18 : 0.12,
    )!;
    final textPrimary = isDark
        ? const Color(0xFFF5F7FA)
        : const Color(0xFF122235);
    final textSecondary = isDark
        ? const Color(0xFFB5C2CF)
        : const Color(0xFF586978);

    return _SoothingVisualPalette(
      isDark: isDark,
      backgroundTop: backgroundTop,
      backgroundBottom: backgroundBottom,
      panelSurface: panelSurface,
      panelSurfaceMuted: panelSurfaceMuted,
      controlSurface: controlSurface,
      border: border,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      accent: accent,
      orbitAccent: orbitAccent,
      glowA: Color.lerp(mode.blobA, accent, 0.42)!,
      glowB: Color.lerp(mode.blobB, orbitAccent, 0.36)!,
      dangerBg: isDark ? const Color(0xFF4B2B30) : const Color(0xFFF3D7DA),
      dangerFg: isDark ? const Color(0xFFFFC5CB) : const Color(0xFF7A1E27),
    );
  }
}

class _SoothingMusicV2PageState extends State<SoothingMusicV2Page>
    with SingleTickerProviderStateMixin {
  final AppLogService _log = AppLogService.instance;
  static const List<double> _defaultStageBands = <double>[
    0.18,
    0.22,
    0.26,
    0.24,
    0.18,
    0.14,
  ];
  static const List<_SoothingModeTheme> _modes = <_SoothingModeTheme>[
    _SoothingModeTheme(
      id: 'chill',
      zhTitle: '轻松',
      enTitle: 'Relax',
      zhSubtitle: 'Lofi 轻松',
      enSubtitle: 'Lofi Chill',
      zhDescription: '柔和鼓点与暖色和弦，适合放空、恢复和轻阅读。',
      enDescription:
          'Soft pulses and warm chords for drifting, recovery, and light reading.',
      icon: Icons.music_note_rounded,
      accent: Color(0xFF7D8CFF),
      orbitAccent: Color(0xFFFFB15C),
      backgroundA: Color(0xFF0B1326),
      backgroundB: Color(0xFF08111C),
      blobA: Color(0xFF2C3E8F),
      blobB: Color(0xFF5A2B86),
      footerZh: '轻缓摆动，适合从紧绷切回松弛。',
      footerEn: 'A soft sway for easing out of tension.',
    ),
    _SoothingModeTheme(
      id: 'study',
      zhTitle: '学习',
      enTitle: 'Study',
      zhSubtitle: 'Lofi 学习',
      enSubtitle: 'Lofi Study',
      zhDescription: '稳定拍点与清晰中频，更适合长时间阅读、写作与专注工作。',
      enDescription:
          'Steady pacing and clearer mids for long reading, writing, and desk sessions.',
      icon: Icons.radio_button_checked_rounded,
      accent: Color(0xFF62A5FF),
      orbitAccent: Color(0xFFFFAE61),
      backgroundA: Color(0xFF09111D),
      backgroundB: Color(0xFF07121F),
      blobA: Color(0xFF15437D),
      blobB: Color(0xFF274A9B),
      footerZh: '清晰拍点与稳定底色，适合持续专注。',
      footerEn: 'Clear mids and steady pacing for sustained focus.',
    ),
    _SoothingModeTheme(
      id: 'sleep',
      zhTitle: '助眠',
      enTitle: 'Sleep',
      zhSubtitle: 'Lofi 助眠',
      enSubtitle: 'Lofi Sleep',
      zhDescription: '减弱击打刺激，保留慢速铺底与稀疏点音，更适合夜间放松。',
      enDescription:
          'Slower pads and sparse accents for low-stimulation night wind-down.',
      icon: Icons.nightlight_round_rounded,
      accent: Color(0xFFB57CFF),
      orbitAccent: Color(0xFF8E9FFF),
      backgroundA: Color(0xFF090F1A),
      backgroundB: Color(0xFF060A12),
      blobA: Color(0xFF322155),
      blobB: Color(0xFF1D2B5B),
      footerZh: '更少刺激、更慢呼吸、更适合夜晚。',
      footerEn: 'Less stimulation and slower breath for night use.',
    ),
    _SoothingModeTheme(
      id: 'jazz',
      zhTitle: '爵士',
      enTitle: 'Jazz',
      zhSubtitle: 'Lofi 爵士',
      enSubtitle: 'Lofi Jazz',
      zhDescription: '慵懒低音与轻刷节奏，适合傍晚工作、写字和慢节奏输入。',
      enDescription:
          'Walking bass and brushed motion for evening work and low-pressure flow.',
      icon: Icons.mic_external_on_rounded,
      accent: Color(0xFFFF8B7B),
      orbitAccent: Color(0xFFFFC36E),
      backgroundA: Color(0xFF12101A),
      backgroundB: Color(0xFF0C1017),
      blobA: Color(0xFF6A2D35),
      blobB: Color(0xFF5D4428),
      footerZh: '懒散弹跳与暖色质感，适合傍晚与低压工作。',
      footerEn: 'Lazy bounce and warm texture for evening focus.',
    ),
    _SoothingModeTheme(
      id: 'piano',
      zhTitle: '钢琴',
      enTitle: 'Piano',
      zhSubtitle: 'Lofi 钢琴',
      enSubtitle: 'Lofi Piano',
      zhDescription: '把旋律交给钢琴，保留轻拍与铺底，适合安静阅读与独处。',
      enDescription:
          'Piano-forward melody with gentle rhythm for quiet reading and solitude.',
      icon: Icons.piano_rounded,
      accent: Color(0xFFC9D1E2),
      orbitAccent: Color(0xFF8DA8D4),
      backgroundA: Color(0xFF0E1520),
      backgroundB: Color(0xFF0A1018),
      blobA: Color(0xFF3B4557),
      blobB: Color(0xFF26415E),
      footerZh: '旋律更靠前，适合沉浸和独处。',
      footerEn: 'A more forward melody line for immersion.',
    ),
    _SoothingModeTheme(
      id: 'motion',
      zhTitle: '律动',
      enTitle: 'Motion',
      zhSubtitle: '轻动节奏',
      enSubtitle: 'Motion Flow',
      zhDescription: '更明显的推进感，适合走动、整理房间、切换状态与轻运动。',
      enDescription:
          'A stronger forward push for walking, tidying up, and light movement.',
      icon: Icons.directions_run_rounded,
      accent: Color(0xFF32C8A8),
      orbitAccent: Color(0xFF6DE5FF),
      backgroundA: Color(0xFF07161A),
      backgroundB: Color(0xFF07101A),
      blobA: Color(0xFF0E5C56),
      blobB: Color(0xFF15406C),
      footerZh: '更明确的推进感，适合把状态提起来。',
      footerEn: 'Forward momentum for lifting your state.',
    ),
    _SoothingModeTheme(
      id: 'harp',
      zhTitle: '竖琴',
      enTitle: 'Harp',
      zhSubtitle: '空灵竖琴',
      enSubtitle: 'Harp Loop',
      zhDescription: '拨弦感更明显，适合放空、安静恢复与轻度冥想。',
      enDescription:
          'More tactile plucks for quiet recovery, soft meditation, and calm resets.',
      icon: Icons.auto_awesome_rounded,
      accent: Color(0xFF8F93FF),
      orbitAccent: Color(0xFFFFB9AA),
      backgroundA: Color(0xFF101127),
      backgroundB: Color(0xFF0A0E1B),
      blobA: Color(0xFF353C8D),
      blobB: Color(0xFF62367F),
      footerZh: '细碎拨弦，适合放空和安静恢复。',
      footerEn: 'Fine plucks for restoring calm.',
    ),
    _SoothingModeTheme(
      id: 'music_box',
      zhTitle: '八音盒',
      enTitle: 'Music Box',
      zhSubtitle: '微光铃音',
      enSubtitle: 'Music Box',
      zhDescription: '铃音更亮、尾音更短，适合作为夜间轻陪伴与低刺激安抚。',
      enDescription:
          'Brighter chimes and shorter tails for gentle evening companionship.',
      icon: Icons.toys_rounded,
      accent: Color(0xFFFFB061),
      orbitAccent: Color(0xFFFFE0A1),
      backgroundA: Color(0xFF14101A),
      backgroundB: Color(0xFF0F0D16),
      blobA: Color(0xFF7B4E1B),
      blobB: Color(0xFF5B3258),
      footerZh: '清亮微光，适合夜间和轻陪伴。',
      footerEn: 'A bright little glow for evening company.',
    ),
    _SoothingModeTheme(
      id: 'dreaming',
      zhTitle: '遐想',
      enTitle: 'Dreaming',
      zhSubtitle: '漂浮氛围',
      enSubtitle: 'Dreaming',
      zhDescription: '更漂浮、更梦境化，适合夜读、发散思绪与轻想象。',
      enDescription:
          'A floating dream-walk texture for imagination, night reading, and drift.',
      icon: Icons.cloud_outlined,
      accent: Color(0xFF9BB2FF),
      orbitAccent: Color(0xFFE1A8FF),
      backgroundA: Color(0xFF0D1020),
      backgroundB: Color(0xFF090B14),
      blobA: Color(0xFF29417A),
      blobB: Color(0xFF5A2C6F),
      footerZh: '更漂浮、更梦境化，适合夜读与想象。',
      footerEn: 'More floating and dreamlike for imagination.',
    ),
  ];

  static const Map<String, List<_TrackLabelPair>> _trackLabelsByMode =
      <String, List<_TrackLabelPair>>{
        'chill': <_TrackLabelPair>[
          _TrackLabelPair(zh: '午后暖流', en: 'Afternoon Hush'),
          _TrackLabelPair(zh: '窗边慢拍', en: 'Window Pulse'),
          _TrackLabelPair(zh: '松弛漂流', en: 'Soft Drift'),
          _TrackLabelPair(zh: '夜灯余温', en: 'Lamp Afterglow'),
        ],
        'study': <_TrackLabelPair>[
          _TrackLabelPair(zh: '专注底色', en: 'Focus Base'),
          _TrackLabelPair(zh: '长文阅读', en: 'Deep Reading'),
          _TrackLabelPair(zh: '桌面流线', en: 'Desk Flow'),
          _TrackLabelPair(zh: '清醒延展', en: 'Clear Stretch'),
        ],
        'sleep': <_TrackLabelPair>[
          _TrackLabelPair(zh: '缓夜铺底', en: 'Slow Nightfall'),
          _TrackLabelPair(zh: '深夜白雾', en: 'Midnight Haze'),
          _TrackLabelPair(zh: '低刺激陪伴', en: 'Gentle Company'),
          _TrackLabelPair(zh: '慢慢坠落', en: 'Soft Descent'),
          _TrackLabelPair(zh: '安睡前奏', en: 'Sleep Prelude'),
        ],
        'jazz': <_TrackLabelPair>[
          _TrackLabelPair(zh: '暖调漫步', en: 'Warm Walk'),
          _TrackLabelPair(zh: '傍晚酒馆', en: 'Evening Bar'),
          _TrackLabelPair(zh: '懒散摇摆', en: 'Lazy Swing'),
          _TrackLabelPair(zh: '低压输入', en: 'Low-Key Typing'),
          _TrackLabelPair(zh: '轻刷鼓点', en: 'Brush Beat'),
          _TrackLabelPair(zh: '爵士余晖', en: 'Jazz Glow'),
        ],
        'piano': <_TrackLabelPair>[
          _TrackLabelPair(zh: '纸页钢琴', en: 'Paper Keys'),
          _TrackLabelPair(zh: '雨后独奏', en: 'After-Rain Solo'),
          _TrackLabelPair(zh: '夜读旋律', en: 'Night Reading'),
          _TrackLabelPair(zh: '轻触琴键', en: 'Soft Touch'),
          _TrackLabelPair(zh: '独处回声', en: 'Solo Echo'),
        ],
        'motion': <_TrackLabelPair>[
          _TrackLabelPair(zh: '步行推进', en: 'Walking Push'),
          _TrackLabelPair(zh: '轻跑唤醒', en: 'Easy Jog'),
          _TrackLabelPair(zh: '状态拉起', en: 'State Lift'),
          _TrackLabelPair(zh: '晨间动能', en: 'Morning Drive'),
          _TrackLabelPair(zh: '节律前行', en: 'Beat Forward'),
          _TrackLabelPair(zh: '切换速度', en: 'Switch Pace'),
        ],
        'harp': <_TrackLabelPair>[
          _TrackLabelPair(zh: '弦光一', en: 'String Glow I'),
          _TrackLabelPair(zh: '月下拨弦', en: 'Moon Pluck'),
          _TrackLabelPair(zh: '清澈回响', en: 'Clear Echo'),
          _TrackLabelPair(zh: '松风竖琴', en: 'Pine Breeze Harp'),
          _TrackLabelPair(zh: '静夜细弦', en: 'Quiet Strings'),
        ],
        'music_box': <_TrackLabelPair>[
          _TrackLabelPair(zh: '盒中月光', en: 'Moon in the Box'),
          _TrackLabelPair(zh: '夜色铃音', en: 'Night Chime'),
          _TrackLabelPair(zh: '短梦碎片', en: 'Dream Fragment'),
          _TrackLabelPair(zh: '微光陪伴', en: 'Little Glow'),
          _TrackLabelPair(zh: '床边回旋', en: 'Bedside Spin'),
          _TrackLabelPair(zh: '轻眠序曲', en: 'Sleep Waltz'),
        ],
        'dreaming': <_TrackLabelPair>[
          _TrackLabelPair(zh: '漂浮想象', en: 'Floating Thought'),
          _TrackLabelPair(zh: '梦游云层', en: 'Cloud Drift'),
        ],
      };

  static List<_SoothingTrack> _tracksForMode(String modeId) {
    return SoothingMusicTrackCatalog.tracksForMode(modeId);
  }

  late final AudioPlayer _player;
  late final AnimationController _orbitController;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<void>? _completeSubscription;
  Timer? _sleepTimer;
  CstCloudResourceCacheService? _remoteResourceCache;
  SoothingMusicTrackLoader? _trackLoader;

  _SoothingModeTheme _mode = _modes[1];
  _ModeLibraryFilter _modeFilter = _ModeLibraryFilter.all;
  SoothingSceneAudio? _scene;
  int _trackIndex = 0;
  bool _playing = false;
  bool _muted = false;
  bool _loading = false;
  bool _tracksExpanded = false;
  bool _continuePlaybackOnExit = false;
  bool _fullscreen = false;
  double _volume = 0.62;
  double? _draggingRatio;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 2);
  Duration? _sleepRemaining;
  int _spectrumFrameIndex = -1;
  List<double> _stageBands = _defaultStageBands;
  String? _audioErrorLabelKey;
  String? _trackLoadLabelKey;
  double? _trackLoadProgress;
  int _trackLoadReceivedBytes = 0;
  int _trackLoadTotalBytes = 0;
  int _asyncLoadToken = 0;
  bool _handlingPlaybackCompletion = false;
  bool _disposed = false;
  Future<void> _playerMutationQueue = Future<void>.value();

  Future<void> _enterImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  Future<void> _exitImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _setFullscreen(bool value) async {
    if (_fullscreen == value) {
      return;
    }
    setState(() {
      _fullscreen = value;
    });
    if (value) {
      await _enterImmersiveMode();
    } else {
      await _exitImmersiveMode();
    }
  }

  @override
  void initState() {
    super.initState();
    _player = _SoothingRuntimeStore.retainedPlayer ?? AudioPlayer();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _positionSubscription = _player.onPositionChanged.listen((value) {
      if (!mounted) return;
      setState(() {
        _position = value;
        _updateStageSpectrum();
      });
      _SoothingRuntimeStore.activePosition = value;
      _SoothingRuntimeStore.notifyChanged();
    });
    _durationSubscription = _player.onDurationChanged.listen((value) {
      if (!mounted || value.inMilliseconds <= 0) return;
      setState(() {
        _duration = value;
        _updateStageSpectrum(force: true);
      });
      _SoothingRuntimeStore.activeDuration = value;
      _SoothingRuntimeStore.notifyChanged();
    });
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final nextPlaying = state == PlayerState.playing;
      if (_playing == nextPlaying) return;
      setState(() {
        _playing = nextPlaying;
      });
      _SoothingRuntimeStore.activePlaying = nextPlaying;
      _SoothingRuntimeStore.notifyChanged();
      if (nextPlaying) {
        _orbitController.repeat();
      } else {
        _orbitController.stop();
      }
    });
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      unawaited(_handlePlaybackCompletion());
    });
    unawaited(_initAudio());
  }

  @override
  void dispose() {
    _disposed = true;
    _asyncLoadToken += 1;
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _completeSubscription?.cancel();
    _sleepTimer?.cancel();
    _orbitController.dispose();
    if (_fullscreen) {
      unawaited(_exitImmersiveMode());
    }
    final shouldRetainPlayer = _continuePlaybackOnExit && _playing;
    if (shouldRetainPlayer) {
      unawaited(
        _SoothingRuntimeStore.attachRetainedPlaybackController(_player),
      );
      _SoothingRuntimeStore.retainedPlayer = _player;
      _SoothingRuntimeStore.activeModeId = _mode.id;
      _SoothingRuntimeStore.activeTrackIndex = _trackIndex;
      _SoothingRuntimeStore.activePlaying = _playing;
      _SoothingRuntimeStore.activeVolume = _volume;
      _SoothingRuntimeStore.activeMuted = _muted;
      _SoothingRuntimeStore.activePosition = _position;
      _SoothingRuntimeStore.activeDuration = _duration;
      _SoothingRuntimeStore.notifyChanged();
    } else {
      _SoothingRuntimeStore.detachRetainedPlaybackController();
      if (identical(_SoothingRuntimeStore.retainedPlayer, _player)) {
        _SoothingRuntimeStore.retainedPlayer = null;
      }
      _SoothingRuntimeStore.activePlaying = false;
      _SoothingRuntimeStore.notifyChanged();
      unawaited(_player.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CstCloudResourceCacheService? nextCache;
    try {
      nextCache = Provider.of<CstCloudResourceCacheService>(
        context,
        listen: false,
      );
    } on ProviderNotFoundException {
      nextCache = null;
    }
    if (!identical(_remoteResourceCache, nextCache) || _trackLoader == null) {
      _remoteResourceCache = nextCache;
      _trackLoader = SoothingMusicTrackLoader(
        remoteResourceCache: _remoteResourceCache,
      );
      _SoothingRuntimeStore.updateRemoteResourceCache(_remoteResourceCache);
    }
  }

  Future<void> _initAudio() async {
    final prefs = await ToolboxSoothingPrefsService.load();
    if (!mounted) return;
    _SoothingRuntimeStore.favoriteModeIds = Set<String>.from(
      prefs.favoriteModeIds,
    );
    _SoothingRuntimeStore.recentModeIds = List<String>.from(
      prefs.recentModeIds,
    );
    _SoothingRuntimeStore.lastTrackIndexByMode = Map<String, int>.from(
      prefs.lastTrackIndexByMode,
    );
    _SoothingRuntimeStore.lastModeId = prefs.lastModeId;
    _SoothingRuntimeStore.continuePlaybackOnExit = prefs.continuePlaybackOnExit;
    _SoothingRuntimeStore.playbackMode = prefs.playbackMode;
    _SoothingRuntimeStore.arrangementSteps =
        List<SoothingPlaybackArrangementStep>.from(prefs.arrangementSteps);
    _SoothingRuntimeStore.arrangementTemplates =
        List<SoothingPlaybackArrangementTemplate>.from(
          prefs.arrangementTemplates,
        );
    _SoothingRuntimeStore.activeArrangementTemplateId =
        prefs.activeArrangementTemplateId;
    _continuePlaybackOnExit = prefs.continuePlaybackOnExit;
    _mode = _modes.firstWhere(
      (mode) => mode.id == _SoothingRuntimeStore.lastModeId,
      orElse: () => _mode,
    );
    _trackIndex = _restoredTrackIndexForMode(_mode.id);

    await _player.setAudioContext(_soothingAudioContext);
    await _player.setReleaseMode(ReleaseMode.stop);
    if (!mounted) return;
    _volume = _SoothingRuntimeStore.activeVolume;
    _muted = _SoothingRuntimeStore.activeMuted;
    await _player.setVolume(_muted ? 0 : _volume);
    if (!mounted) return;
    if (_SoothingRuntimeStore.retainedPlayer != null &&
        _SoothingRuntimeStore.activeModeId != null) {
      _SoothingRuntimeStore.detachRetainedPlaybackController();
      final retainedModeId = _SoothingRuntimeStore.activeModeId!;
      _mode = _modes.firstWhere(
        (mode) => mode.id == retainedModeId,
        orElse: () => _mode,
      );
      final retainedTracks = _tracksForMode(_mode.id);
      _trackIndex = retainedTracks.isEmpty
          ? 0
          : _SoothingRuntimeStore.activeTrackIndex.clamp(
              0,
              retainedTracks.length - 1,
            );
      _position = _SoothingRuntimeStore.activePosition;
      _duration = _SoothingRuntimeStore.activeDuration;
      _playing = _SoothingRuntimeStore.activePlaying;
      _scene = await ToolboxSoothingAudioService.load(_mode.id);
      _updateStageSpectrum(force: true);
      if (_playing) {
        _orbitController.repeat();
      }
      _SoothingRuntimeStore.notifyChanged();
      if (mounted) {
        setState(() {});
      }
      for (final mode in _modes.where((item) => item.id != _mode.id).take(2)) {
        unawaited(_preloadModeAssets(mode.id));
      }
      return;
    }

    unawaited(_preloadModeAssets(_mode.id));
    if (!mounted) return;
    await _loadMode(_mode, autoplay: false);
    if (!mounted) return;
    for (final mode in _modes.where((item) => item.id != _mode.id).take(2)) {
      unawaited(_preloadModeAssets(mode.id));
    }
  }

  Future<void> _preloadModeAssets(String modeId) async {
    try {
      await _resolvedTrackLoader.preloadMode(modeId);
    } catch (error, stackTrace) {
      _log.w(
        'soothing_audio',
        'preload mode assets failed',
        data: <String, Object?>{'modeId': modeId},
      );
      _log.e(
        'soothing_audio',
        'preload mode assets failure detail',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{'modeId': modeId},
      );
    }
  }

  Future<Uint8List> _loadTrackBytes(
    _SoothingTrack track, {
    int? loadToken,
  }) async {
    _trackLoadLabelKey = track.labelKey;
    _trackLoadProgress = null;
    _trackLoadReceivedBytes = 0;
    _trackLoadTotalBytes = 0;
    if (mounted) {
      setState(() {});
    }
    try {
      return await _resolvedTrackLoader.load(
        track,
        onProgress: (progress) {
          if (!mounted || !_isLoadTokenActive(loadToken)) return;
          setState(() {
            _trackLoadLabelKey = track.labelKey;
            _trackLoadProgress = progress.progress;
            _trackLoadReceivedBytes = progress.receivedBytes;
            _trackLoadTotalBytes = progress.totalBytes;
          });
        },
      );
    } finally {
      _clearTrackLoadState(loadToken: loadToken);
    }
  }

  SoothingMusicTrackLoader get _resolvedTrackLoader => _trackLoader ??=
      SoothingMusicTrackLoader(remoteResourceCache: _remoteResourceCache);

  List<_SoothingTrack> get _tracks => _tracksForMode(_mode.id);
  _SoothingTrack get _currentTrack => _tracks[_trackIndex];

  bool _isLoadTokenActive(int? loadToken) {
    return !_disposed &&
        mounted &&
        (loadToken == null || loadToken == _asyncLoadToken);
  }

  Future<T> _runSerializedPlayerMutation<T>(Future<T> Function() action) {
    final previous = _playerMutationQueue;
    final completer = Completer<void>();
    _playerMutationQueue = completer.future;
    return previous.catchError((_) {}).then((_) => action()).whenComplete(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
  }

  Future<void> _startArrangementPlayback({bool autoplay = true}) async {
    if (_arrangementSteps.isEmpty) {
      return;
    }
    final firstStep = _arrangementSteps.first;
    _SoothingRuntimeStore.arrangementStepIndex = 0;
    _SoothingRuntimeStore.arrangementStepPlayCount = 0;
    final firstMode = _modes.firstWhere(
      (mode) => mode.id == firstStep.modeId,
      orElse: () => _mode,
    );
    _SoothingRuntimeStore.activeModeId = firstMode.id;
    _SoothingRuntimeStore.activeTrackIndex = firstStep.trackIndex;
    _SoothingRuntimeStore.notifyChanged();
    if (_mode.id != firstMode.id) {
      await _loadMode(
        firstMode,
        autoplay: autoplay,
        preferredTrackIndex: firstStep.trackIndex,
      );
      return;
    }
    if (_trackIndex != firstStep.trackIndex) {
      await _setTrackIndex(firstStep.trackIndex, autoplayOverride: autoplay);
      return;
    }
    if (autoplay) {
      await _seekToRatio(0);
      await _player.resume();
      _SoothingRuntimeStore.activePlaying = true;
      _SoothingRuntimeStore.notifyChanged();
    } else {
      await _player.stop();
      _SoothingRuntimeStore.activePlaying = false;
      _SoothingRuntimeStore.notifyChanged();
    }
  }

  Future<void> _loadMode(
    _SoothingModeTheme mode, {
    required bool autoplay,
    int? preferredTrackIndex,
  }) async {
    if (!mounted) return;
    final tracks = _tracksForMode(mode.id);
    if (tracks.isEmpty) {
      return;
    }
    final loadToken = ++_asyncLoadToken;
    final restoredTrackIndex =
        preferredTrackIndex?.clamp(0, tracks.length - 1).toInt() ??
        _restoredTrackIndexForMode(mode.id);
    final shouldAutoplay =
        autoplay || _playbackMode == SoothingPlaybackMode.arrangement;
    setState(() {
      _mode = mode;
      _trackIndex = restoredTrackIndex;
      _loading = true;
      _position = Duration.zero;
      _draggingRatio = null;
      _resetStageSpectrum();
      _clearAudioError();
    });

    try {
      final scene = await ToolboxSoothingAudioService.load(mode.id);
      if (!_isLoadTokenActive(loadToken)) {
        return;
      }
      final track = tracks[restoredTrackIndex];
      final bytes = await _loadTrackBytes(track, loadToken: loadToken);
      if (!_isLoadTokenActive(loadToken)) {
        return;
      }
      final duration = await _runSerializedPlayerMutation<Duration?>(() async {
        if (!_isLoadTokenActive(loadToken)) {
          return null;
        }
        await AudioPlayerSourceHelper.setSource(
          _player,
          BytesSource(bytes, mimeType: 'audio/mp4'),
          tag: 'soothing_audio',
          data: <String, Object?>{
            'modeId': mode.id,
            'trackAssetPath': track.assetPath,
            'bytes': bytes.length,
          },
        );
        final resolvedDuration = await AudioPlayerSourceHelper.waitForDuration(
          _player,
          tag: 'soothing_audio',
          data: <String, Object?>{
            'modeId': mode.id,
            'trackAssetPath': track.assetPath,
            'playerId': _player.playerId,
          },
        );
        await _player.setVolume(_muted ? 0 : _volume);
        if (_isLoadTokenActive(loadToken)) {
          if (shouldAutoplay) {
            await _player.resume();
          } else {
            await _player.stop();
          }
        }
        return resolvedDuration;
      });
      if (duration != null) {
        _duration = duration;
      }
      _updateStageSpectrum(force: true);
      _SoothingRuntimeStore.activeDuration = _duration;
      if (!_isLoadTokenActive(loadToken)) return;
      setState(() {
        _scene = scene;
        _updateStageSpectrum(force: true);
      });
      _SoothingRuntimeStore.lastTrackIndexByMode[mode.id] = restoredTrackIndex;
      _SoothingRuntimeStore.lastModeId = mode.id;
      _SoothingRuntimeStore.activeModeId = mode.id;
      _SoothingRuntimeStore.activeTrackIndex = restoredTrackIndex;
      _SoothingRuntimeStore.activeVolume = _volume;
      _SoothingRuntimeStore.activeMuted = _muted;
      _SoothingRuntimeStore.activePlaying = shouldAutoplay;
      _SoothingRuntimeStore.notifyChanged();
      _rememberRecent(mode.id);
    } catch (error, stackTrace) {
      _log.e(
        'soothing_audio',
        'load mode failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'modeId': mode.id,
          'trackIndex': restoredTrackIndex,
          'playerId': _player.playerId,
        },
      );
      if (!_isLoadTokenActive(loadToken)) return;
      setState(() {
        _audioErrorLabelKey = 'mode:${mode.id}';
      });
    } finally {
      if (mounted && loadToken == _asyncLoadToken) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_loading) return;
    if (_scene == null) {
      await _loadMode(_mode, autoplay: true);
      return;
    }
    if (_playing) {
      await _player.pause();
      _SoothingRuntimeStore.activePlaying = false;
      _SoothingRuntimeStore.notifyChanged();
      _orbitController.stop();
      return;
    }
    // CRITICAL FIX: Wait for player to be ready before resuming.
    // Without this, resume() may be called before the audio source is loaded,
    // causing no sound output.
    await AudioPlayerSourceHelper.waitForDuration(
      _player,
      tag: 'soothing_audio',
      data: <String, Object?>{'playerId': _player.playerId, 'modeId': _mode.id},
      timeout: const Duration(seconds: 5),
    );
    await _player.resume();
    _rememberRecent(_mode.id);
    _SoothingRuntimeStore.activePlaying = true;
    _SoothingRuntimeStore.notifyChanged();
    _orbitController.repeat();
  }

  Future<void> _handlePlaybackCompletion() async {
    if (_handlingPlaybackCompletion) {
      return;
    }
    _handlingPlaybackCompletion = true;
    try {
      switch (_playbackMode) {
        case SoothingPlaybackMode.singleLoop:
          await _seekToRatio(0);
          await _player.resume();
          _SoothingRuntimeStore.activePlaying = true;
          _SoothingRuntimeStore.notifyChanged();
          if (mounted) {
            setState(() {
              _position = Duration.zero;
              _updateStageSpectrum(force: true);
            });
          }
          return;
        case SoothingPlaybackMode.modeCycle:
          if (_tracks.length <= 1) {
            await _seekToRatio(0);
            await _player.resume();
            _SoothingRuntimeStore.activePlaying = true;
            _SoothingRuntimeStore.notifyChanged();
            return;
          }
          await _stepTrack(1, autoplayOverride: true);
          return;
        case SoothingPlaybackMode.arrangement:
          await _advanceArrangement();
          return;
      }
    } finally {
      _handlingPlaybackCompletion = false;
    }
  }

  Future<void> _advanceArrangement() async {
    if (_arrangementSteps.isEmpty) {
      _setPlaybackMode(SoothingPlaybackMode.singleLoop);
      await _handlePlaybackCompletion();
      return;
    }
    final currentIndex = _SoothingRuntimeStore.arrangementStepIndex.clamp(
      0,
      _arrangementSteps.length - 1,
    );
    final currentStep = _arrangementSteps[currentIndex];
    final playedCount = _SoothingRuntimeStore.arrangementStepPlayCount + 1;
    if (playedCount < currentStep.repeatCount) {
      _SoothingRuntimeStore.arrangementStepPlayCount = playedCount;
      await _seekToRatio(0);
      await _player.resume();
      _SoothingRuntimeStore.activePlaying = true;
      _SoothingRuntimeStore.notifyChanged();
      if (mounted) {
        setState(() {
          _position = Duration.zero;
        });
      }
      return;
    }

    final nextIndex = (currentIndex + 1) % _arrangementSteps.length;
    final nextStep = _arrangementSteps[nextIndex];
    _SoothingRuntimeStore.arrangementStepIndex = nextIndex;
    _SoothingRuntimeStore.arrangementStepPlayCount = 0;

    final nextMode = _modes.firstWhere(
      (mode) => mode.id == nextStep.modeId,
      orElse: () => _mode,
    );
    if (_mode.id != nextMode.id) {
      await _loadMode(
        nextMode,
        autoplay: true,
        preferredTrackIndex: nextStep.trackIndex,
      );
      return;
    }
    if (_trackIndex == nextStep.trackIndex) {
      await _seekToRatio(0);
      await _player.resume();
      _SoothingRuntimeStore.activePlaying = true;
      _SoothingRuntimeStore.notifyChanged();
      if (mounted) {
        setState(() {
          _position = Duration.zero;
        });
      }
      return;
    }
    await _setTrackIndex(nextStep.trackIndex, autoplayOverride: true);
  }

  Future<void> _setMode(
    _SoothingModeTheme mode, {
    bool? autoplayOverride,
    int? preferredTrackIndex,
  }) async {
    if (_mode.id == mode.id && _scene != null) return;
    await _loadMode(
      mode,
      autoplay: autoplayOverride ?? _playing,
      preferredTrackIndex: preferredTrackIndex,
    );
  }

  Future<void> _setTrackIndex(int index, {bool? autoplayOverride}) async {
    if (index == _trackIndex) return;
    if (!mounted) return;
    if (_tracks.isEmpty) return;
    final loadToken = ++_asyncLoadToken;
    final nextTrackIndex = index.clamp(0, _tracks.length - 1);
    late final _SoothingTrack track;
    setState(() {
      _trackIndex = nextTrackIndex;
      _loading = true;
      _position = Duration.zero;
      _draggingRatio = null;
      _resetStageSpectrum();
      _clearAudioError();
    });

    try {
      track = _currentTrack;
      final bytes = await _loadTrackBytes(track, loadToken: loadToken);
      if (!_isLoadTokenActive(loadToken)) {
        return;
      }
      final duration = await _runSerializedPlayerMutation<Duration?>(() async {
        if (!_isLoadTokenActive(loadToken)) {
          return null;
        }
        await AudioPlayerSourceHelper.setSource(
          _player,
          BytesSource(bytes, mimeType: 'audio/mp4'),
          tag: 'soothing_audio',
          data: <String, Object?>{
            'modeId': _mode.id,
            'trackAssetPath': track.assetPath,
            'bytes': bytes.length,
          },
        );
        final resolvedDuration = await AudioPlayerSourceHelper.waitForDuration(
          _player,
          tag: 'soothing_audio',
          data: <String, Object?>{
            'modeId': _mode.id,
            'trackAssetPath': track.assetPath,
            'playerId': _player.playerId,
          },
        );
        await _player.setVolume(_muted ? 0 : _volume);
        final shouldResume = autoplayOverride ?? _playing;
        if (_isLoadTokenActive(loadToken)) {
          if (shouldResume) {
            await _player.resume();
          } else {
            await _player.stop();
          }
        }
        return resolvedDuration;
      });
      if (duration != null) {
        _duration = duration;
      }
      _updateStageSpectrum(force: true);
      _SoothingRuntimeStore.activeDuration = _duration;
      if (!_isLoadTokenActive(loadToken)) return;
      final shouldResume = autoplayOverride ?? _playing;
      _SoothingRuntimeStore.activePlaying = shouldResume;
    } catch (error, stackTrace) {
      _log.e(
        'soothing_audio',
        'set track failed',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'modeId': _mode.id,
          'trackIndex': _trackIndex,
          'trackAssetPath': track.assetPath,
          'playerId': _player.playerId,
        },
      );
      if (!_isLoadTokenActive(loadToken)) return;
      setState(() {
        _audioErrorLabelKey = 'track:${track.labelKey}';
      });
    } finally {
      if (mounted && loadToken == _asyncLoadToken) {
        setState(() {
          _loading = false;
        });
      }
    }

    _SoothingRuntimeStore.lastTrackIndexByMode[_mode.id] = _trackIndex;
    _SoothingRuntimeStore.lastModeId = _mode.id;
    _SoothingRuntimeStore.activeTrackIndex = _trackIndex;
    _SoothingRuntimeStore.notifyChanged();
    unawaited(_persistPrefs());
  }

  Future<void> _stepTrack(int delta, {bool? autoplayOverride}) async {
    if (_tracks.length <= 1) return;
    final nextIndex = (_trackIndex + delta) % _tracks.length;
    await _setTrackIndex(
      nextIndex < 0 ? nextIndex + _tracks.length : nextIndex,
      autoplayOverride: autoplayOverride,
    );
  }

  void _toggleFavorite(String modeId) {
    setState(() {
      if (_SoothingRuntimeStore.favoriteModeIds.contains(modeId)) {
        _SoothingRuntimeStore.favoriteModeIds.remove(modeId);
      } else {
        _SoothingRuntimeStore.favoriteModeIds.add(modeId);
      }
    });
    unawaited(_persistPrefs());
  }

  void _rememberRecent(String modeId) {
    _SoothingRuntimeStore.recentModeIds.remove(modeId);
    _SoothingRuntimeStore.recentModeIds.insert(0, modeId);
    if (_SoothingRuntimeStore.recentModeIds.length > 6) {
      _SoothingRuntimeStore.recentModeIds.removeRange(
        6,
        _SoothingRuntimeStore.recentModeIds.length,
      );
    }
    _SoothingRuntimeStore.lastModeId = modeId;
    _SoothingRuntimeStore.notifyChanged();
    unawaited(_persistPrefs());
  }

  Future<void> _setMuted(bool value) async {
    setState(() {
      _muted = value;
    });
    _SoothingRuntimeStore.activeMuted = value;
    _SoothingRuntimeStore.notifyChanged();
    await _player.setVolume(value ? 0 : _volume);
    unawaited(_persistPrefs());
  }

  Future<void> _setVolume(double value) async {
    setState(() {
      _volume = value;
    });
    _SoothingRuntimeStore.activeVolume = value;
    _SoothingRuntimeStore.notifyChanged();
    if (!_muted) {
      await _player.setVolume(value);
    }
    unawaited(_persistPrefs());
  }

  double get _progressRatio {
    if (_draggingRatio != null) return _draggingRatio!;
    final durationMs = _duration.inMilliseconds;
    if (durationMs <= 0) return 0;
    return (_position.inMilliseconds / durationMs).clamp(0.0, 1.0);
  }

  void _resetStageSpectrum() {
    _spectrumFrameIndex = -1;
    _stageBands = _defaultStageBands;
  }

  int _resolvedSpectrumFrameIndex() {
    final frames = _scene?.spectrumFrames;
    if (frames == null || frames.isEmpty) {
      return -1;
    }
    return (_progressRatio * (frames.length - 1)).round().clamp(
      0,
      frames.length - 1,
    );
  }

  void _updateStageSpectrum({bool force = false}) {
    final frames = _scene?.spectrumFrames;
    if (frames == null || frames.isEmpty) {
      if (force || !identical(_stageBands, _defaultStageBands)) {
        _resetStageSpectrum();
      }
      return;
    }
    final nextFrameIndex = _resolvedSpectrumFrameIndex();
    if (!force && nextFrameIndex == _spectrumFrameIndex) {
      return;
    }
    _spectrumFrameIndex = nextFrameIndex;
    _stageBands = List<double>.unmodifiable(frames[nextFrameIndex]);
  }

  List<_SoothingModeTheme> _modesForFilter(_ModeLibraryFilter filter) {
    switch (filter) {
      case _ModeLibraryFilter.all:
        return _modes;
      case _ModeLibraryFilter.favorites:
        final favoriteIds = _SoothingRuntimeStore.favoriteModeIds;
        return _modes.where((mode) => favoriteIds.contains(mode.id)).toList();
      case _ModeLibraryFilter.recent:
        return _recentModes;
    }
  }

  List<_SoothingModeTheme> get _recentModes {
    return _SoothingRuntimeStore.recentModeIds
        .map(
          (id) => _modes
              .where((mode) => mode.id == id)
              .cast<_SoothingModeTheme?>()
              .firstOrNull,
        )
        .whereType<_SoothingModeTheme>()
        .toList(growable: false);
  }

  SoothingPlaybackMode get _playbackMode => _SoothingRuntimeStore.playbackMode;
  List<SoothingPlaybackArrangementStep> get _arrangementSteps =>
      _SoothingRuntimeStore.arrangementSteps;

  int _restoredTrackIndexForMode(String modeId) {
    final tracks = _tracksForMode(modeId);
    if (tracks.isEmpty) {
      return 0;
    }
    final saved = _SoothingRuntimeStore.lastTrackIndexByMode[modeId] ?? 0;
    return saved.clamp(0, tracks.length - 1).toInt();
  }

  String _playbackModeLabel(AppI18n i18n, SoothingPlaybackMode mode) {
    return switch (mode) {
      SoothingPlaybackMode.singleLoop => pickUiText(
        i18n,
        zh: '单曲循环',
        en: 'Single loop',
      ),
      SoothingPlaybackMode.modeCycle => pickUiText(
        i18n,
        zh: '主题内顺播',
        en: 'Mode cycle',
      ),
      SoothingPlaybackMode.arrangement => pickUiText(
        i18n,
        zh: '编排播放',
        en: 'Arrangement',
      ),
    };
  }

  String _playbackModeSummary(AppI18n i18n) {
    if (_playbackMode != SoothingPlaybackMode.arrangement) {
      return _playbackModeLabel(i18n, _playbackMode);
    }
    final steps = _arrangementSteps.length;
    if (steps <= 0) {
      return pickUiText(
        i18n,
        zh: '编排播放（未配置）',
        en: 'Arrangement (not configured)',
      );
    }
    final activeTemplate = _activeArrangementTemplate;
    if (activeTemplate != null) {
      return pickUiText(
        i18n,
        zh: '编排播放 · ${activeTemplate.name}',
        en: 'Arrangement · ${activeTemplate.name}',
      );
    }
    return pickUiText(
      i18n,
      zh: '编排播放 · $steps 段',
      en: 'Arrangement · $steps steps',
    );
  }

  SoothingPlaybackArrangementTemplate? get _activeArrangementTemplate {
    final activeId = _SoothingRuntimeStore.activeArrangementTemplateId;
    if ((activeId ?? '').trim().isEmpty) {
      return null;
    }
    for (final template in _SoothingRuntimeStore.arrangementTemplates) {
      if (template.id == activeId) {
        return template;
      }
    }
    return null;
  }

  String _arrangementProgressSummary(AppI18n i18n) {
    if (_playbackMode != SoothingPlaybackMode.arrangement ||
        _arrangementSteps.isEmpty) {
      return _playbackModeSummary(i18n);
    }
    final currentIndex = _SoothingRuntimeStore.arrangementStepIndex.clamp(
      0,
      _arrangementSteps.length - 1,
    );
    final currentStep = _arrangementSteps[currentIndex];
    final currentMode = _modes.firstWhere(
      (mode) => mode.id == currentStep.modeId,
      orElse: () => _mode,
    );
    final tracks = _tracksForMode(currentMode.id);
    final safeTrackIndex = currentStep.trackIndex.clamp(0, tracks.length - 1);
    final trackLabel = SoothingMusicCopy.trackLabel(
      i18n,
      tracks[safeTrackIndex].labelKey,
    );
    final repeat = (_SoothingRuntimeStore.arrangementStepPlayCount + 1).clamp(
      1,
      currentStep.repeatCount,
    );
    return pickUiText(
      i18n,
      zh: '第 ${currentIndex + 1}/${_arrangementSteps.length} 段 · ${currentMode.title(i18n)} · $trackLabel · $repeat/${currentStep.repeatCount} 次',
      en: 'Step ${currentIndex + 1}/${_arrangementSteps.length} · ${currentMode.title(i18n)} · $trackLabel · $repeat/${currentStep.repeatCount}',
    );
  }

  void _setPlaybackMode(SoothingPlaybackMode mode) {
    if (_playbackMode == mode) {
      return;
    }
    if (mode == SoothingPlaybackMode.arrangement && _arrangementSteps.isEmpty) {
      _SoothingRuntimeStore.arrangementSteps =
          <SoothingPlaybackArrangementStep>[
            SoothingPlaybackArrangementStep(
              modeId: _mode.id,
              trackIndex: _trackIndex,
              repeatCount: 1,
            ),
          ];
      _SoothingRuntimeStore.arrangementStepIndex = 0;
      _SoothingRuntimeStore.arrangementStepPlayCount = 0;
      _SoothingRuntimeStore.activeArrangementTemplateId = null;
    }
    setState(() {
      _SoothingRuntimeStore.playbackMode = mode;
    });
    _SoothingRuntimeStore.notifyChanged();
    unawaited(_persistPrefs());
  }

  Future<void> _seekToRatio(double ratio) async {
    final durationMs = _duration.inMilliseconds;
    if (durationMs <= 0) return;
    final nextPosition = Duration(milliseconds: (durationMs * ratio).round());
    await _player.seek(nextPosition);
    if (!mounted) return;
    setState(() {
      _position = nextPosition;
      _updateStageSpectrum(force: true);
    });
  }

  Future<void> _persistPrefs() {
    return ToolboxSoothingPrefsService.save(
      SoothingPrefsState(
        favoriteModeIds: _SoothingRuntimeStore.favoriteModeIds,
        recentModeIds: _SoothingRuntimeStore.recentModeIds,
        lastTrackIndexByMode: _SoothingRuntimeStore.lastTrackIndexByMode,
        lastModeId: _SoothingRuntimeStore.lastModeId,
        continuePlaybackOnExit: _continuePlaybackOnExit,
        playbackMode: _SoothingRuntimeStore.playbackMode,
        arrangementSteps: _SoothingRuntimeStore.arrangementSteps,
        arrangementTemplates: _SoothingRuntimeStore.arrangementTemplates,
        activeArrangementTemplateId:
            _SoothingRuntimeStore.activeArrangementTemplateId,
      ),
    );
  }

  void _clearAudioError() {
    _audioErrorLabelKey = null;
  }

  void _clearTrackLoadState({int? loadToken}) {
    if (!_isLoadTokenActive(loadToken)) {
      return;
    }
    if (!mounted) {
      _trackLoadLabelKey = null;
      _trackLoadProgress = null;
      _trackLoadReceivedBytes = 0;
      _trackLoadTotalBytes = 0;
      return;
    }
    setState(() {
      _trackLoadLabelKey = null;
      _trackLoadProgress = null;
      _trackLoadReceivedBytes = 0;
      _trackLoadTotalBytes = 0;
    });
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.toString();
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = <String>['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }
    final digits = value >= 10 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(digits)} ${units[unitIndex]}';
  }

  String? _audioErrorText(AppI18n i18n) {
    final key = _audioErrorLabelKey;
    if (key == null || key.isEmpty) return null;
    final label = key.startsWith('mode:')
        ? SoothingMusicCopy.modeTitle(i18n, key.substring(5))
        : key.startsWith('track:')
        ? SoothingMusicCopy.trackLabel(i18n, key.substring(6))
        : key;
    return SoothingMusicCopy.text(
      i18n,
      'track.audio_error',
      params: <String, Object?>{'label': label},
    );
  }

  String? _trackLoadText(AppI18n i18n) {
    final labelKey = _trackLoadLabelKey;
    if (!_loading || labelKey == null || labelKey.isEmpty) {
      return null;
    }
    final label = SoothingMusicCopy.trackLabel(i18n, labelKey);
    final progress = _trackLoadProgress;
    final bytesText = _trackLoadTotalBytes > 0
        ? '${_formatBytes(_trackLoadReceivedBytes)} / ${_formatBytes(_trackLoadTotalBytes)}'
        : _trackLoadReceivedBytes > 0
        ? _formatBytes(_trackLoadReceivedBytes)
        : null;
    if (progress == null) {
      return bytesText == null ? label : '$label · $bytesText';
    }
    final percent = (progress * 100).round();
    return bytesText == null
        ? '$label · $percent%'
        : '$label · $percent% · $bytesText';
  }

  void _startSleepTimer(Duration? value) {
    _sleepTimer?.cancel();
    setState(() {
      _sleepRemaining = value;
    });
    if (value == null) return;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = _sleepRemaining;
      if (remaining == null) {
        timer.cancel();
        return;
      }
      if (remaining <= const Duration(seconds: 1)) {
        timer.cancel();
        await _player.pause();
        _SoothingRuntimeStore.activePlaying = false;
        _SoothingRuntimeStore.notifyChanged();
        if (!mounted) return;
        setState(() {
          _sleepRemaining = null;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _sleepRemaining = remaining - const Duration(seconds: 1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final isDark = AppThemeTokens.of(context).isDark;
    final appearance = LegacyStyle.appearance;
    final palette = _SoothingVisualPalette.resolve(
      isDark: isDark,
      appearance: appearance,
      mode: _mode,
    );
    final effectBoost =
        (_fullscreen ? 1.22 : 0.82) +
        appearance.normalizedEffectIntensity * (_fullscreen ? 1.46 : 1.1);
    final waveBoost =
        (_fullscreen ? 1.08 : 0.76) +
        appearance.normalizedGradientIntensity * (_fullscreen ? 1.18 : 0.9);

    final controls = <Widget>[
      IconButton(
        tooltip: _copySleepTimerButtonLabel(i18n),
        onPressed: () => _showSleepTimerSheet(context, i18n),
        icon: Icon(
          Icons.timer_outlined,
          color: _fullscreen ? Colors.white : const Color(0xFF10263A),
        ),
      ),
      PopupMenuButton<_SoothingPageMenuAction>(
        tooltip: pickUiText(i18n, zh: '播放设置', en: 'Playback settings'),
        icon: Icon(
          Icons.more_vert_rounded,
          color: _fullscreen ? Colors.white : const Color(0xFF10263A),
        ),
        onSelected: (value) {
          switch (value) {
            case _SoothingPageMenuAction.toggleContinuePlayback:
              setState(() {
                _continuePlaybackOnExit = !_continuePlaybackOnExit;
                _SoothingRuntimeStore.continuePlaybackOnExit =
                    _continuePlaybackOnExit;
              });
              _SoothingRuntimeStore.notifyChanged();
              unawaited(_persistPrefs());
              return;
            case _SoothingPageMenuAction.playbackSingleLoop:
              _setPlaybackMode(SoothingPlaybackMode.singleLoop);
              return;
            case _SoothingPageMenuAction.playbackModeCycle:
              _setPlaybackMode(SoothingPlaybackMode.modeCycle);
              return;
            case _SoothingPageMenuAction.playbackArrangement:
              _setPlaybackMode(SoothingPlaybackMode.arrangement);
              return;
            case _SoothingPageMenuAction.editArrangement:
              unawaited(_showArrangementSheet(context, i18n));
              return;
            case _SoothingPageMenuAction.toggleFullscreen:
              unawaited(_setFullscreen(!_fullscreen));
              return;
          }
        },
        itemBuilder: (context) => <PopupMenuEntry<_SoothingPageMenuAction>>[
          CheckedPopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.playbackSingleLoop,
            checked: _playbackMode == SoothingPlaybackMode.singleLoop,
            child: Text(pickUiText(i18n, zh: '单曲循环', en: 'Single loop')),
          ),
          CheckedPopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.playbackModeCycle,
            checked: _playbackMode == SoothingPlaybackMode.modeCycle,
            child: Text(pickUiText(i18n, zh: '主题内顺播', en: 'Mode cycle')),
          ),
          CheckedPopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.playbackArrangement,
            checked: _playbackMode == SoothingPlaybackMode.arrangement,
            child: Text(pickUiText(i18n, zh: '编排播放', en: 'Arrangement')),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.editArrangement,
            child: Text(pickUiText(i18n, zh: '编辑编排', en: 'Edit arrangement')),
          ),
          PopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.toggleFullscreen,
            child: Text(
              pickUiText(
                i18n,
                zh: _fullscreen ? '退出全屏' : '进入全屏',
                en: _fullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
              ),
            ),
          ),
          const PopupMenuDivider(),
          CheckedPopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.toggleContinuePlayback,
            checked: _continuePlaybackOnExit,
            child: Text(SoothingMusicCopy.text(i18n, 'setting.keep_playing')),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: palette.backgroundBottom,
      extendBodyBehindAppBar: _fullscreen,
      appBar: _fullscreen
          ? AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              title: Text(
                _copyPageTitle(i18n),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: controls,
            )
          : AppBar(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF10263A),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              flexibleSpace: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: const Color(0xFFE4EBF0)),
                  ),
                ),
              ),
              title: Text(
                _copyPageTitle(i18n),
                style: const TextStyle(
                  color: Color(0xFF10263A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: controls,
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  palette.backgroundTop,
                  palette.backgroundBottom,
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: wide
                  ? Row(
                      children: <Widget>[
                        SizedBox(
                          width: 332,
                          child: _buildModePanel(
                            context,
                            i18n,
                            palette: palette,
                          ),
                        ),
                        Expanded(
                          child: _buildStageArea(
                            context,
                            i18n,
                            palette: palette,
                            compact: false,
                            effectBoost: effectBoost,
                            waveBoost: waveBoost,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        _buildCompactHeader(context, i18n, palette: palette),
                        Expanded(
                          child: _buildStageArea(
                            context,
                            i18n,
                            palette: palette,
                            compact: true,
                            effectBoost: effectBoost,
                            waveBoost: waveBoost,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactHeader(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.panelSurface,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _copyModesButtonLabel(i18n),
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: PopupMenuButton<_SoothingModeTheme>(
                  tooltip: _copyModesButtonLabel(i18n),
                  onSelected: (mode) => unawaited(_setMode(mode)),
                  itemBuilder: (context) => _modes
                      .map(
                        (mode) => PopupMenuItem<_SoothingModeTheme>(
                          value: mode,
                          child: Row(
                            children: <Widget>[
                              Icon(
                                mode.icon,
                                size: 18,
                                color: _mode.id == mode.id
                                    ? palette.accent
                                    : palette.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  mode.title(i18n),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_mode.id == mode.id)
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: palette.accent,
                                ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                  child: _CompactCurrentModeCard(
                    title: _mode.title(i18n),
                    subtitle: _mode.subtitle(i18n),
                    accent: palette.accent,
                    icon: _mode.icon,
                    isFavorite: _SoothingRuntimeStore.favoriteModeIds.contains(
                      _mode.id,
                    ),
                    onToggleFavorite: () => _toggleFavorite(_mode.id),
                    palette: palette,
                    dropdownEnabled: true,
                    showFavoriteButton: false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: palette.panelSurfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _toggleFavorite(_mode.id),
                  icon: Icon(
                    _SoothingRuntimeStore.favoriteModeIds.contains(_mode.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color:
                        _SoothingRuntimeStore.favoriteModeIds.contains(_mode.id)
                        ? palette.accent
                        : palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (_sleepRemaining != null) ...<Widget>[
            const SizedBox(height: 10),
            _InfoPill(
              icon: Icons.timer_outlined,
              label: _copyActiveSleepTimerLabel(i18n, _sleepRemaining!),
              palette: palette,
              accent: palette.accent,
            ),
          ],
          const SizedBox(height: 10),
          _InfoPill(
            icon: Icons.repeat_rounded,
            label: _playbackModeSummary(i18n),
            palette: palette,
            accent: palette.orbitAccent,
          ),
          if (_playbackMode == SoothingPlaybackMode.arrangement) ...<Widget>[
            const SizedBox(height: 8),
            _InfoPill(
              icon: Icons.playlist_play_rounded,
              label: _arrangementProgressSummary(i18n),
              palette: palette,
              accent: palette.accent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModePanel(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
  }) {
    final visibleModes = _modesForFilter(_modeFilter);

    return Container(
      decoration: BoxDecoration(
        color: palette.panelSurface,
        border: Border(right: BorderSide(color: palette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _copyPageTitle(i18n),
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _copyPageSubtitle(i18n),
            style: TextStyle(color: palette.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 16),
          _buildModeFilterBar(
            i18n,
            palette: palette,
            filter: _modeFilter,
            onChanged: (value) {
              setState(() {
                _modeFilter = value;
              });
            },
          ),
          if (_sleepRemaining != null) ...<Widget>[
            const SizedBox(height: 12),
            _InfoPill(
              icon: Icons.timer_outlined,
              label: _copyActiveSleepTimerLabel(i18n, _sleepRemaining!),
              palette: palette,
              accent: palette.accent,
            ),
          ],
          const SizedBox(height: 12),
          _InfoPill(
            icon: Icons.repeat_rounded,
            label: _playbackModeSummary(i18n),
            palette: palette,
            accent: palette.orbitAccent,
          ),
          if (_playbackMode == SoothingPlaybackMode.arrangement) ...<Widget>[
            const SizedBox(height: 8),
            _InfoPill(
              icon: Icons.playlist_play_rounded,
              label: _arrangementProgressSummary(i18n),
              palette: palette,
              accent: palette.accent,
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: visibleModes.isEmpty
                ? _buildEmptyModeState(
                    i18n,
                    palette: palette,
                    filter: _modeFilter,
                    onReset: () {
                      setState(() {
                        _modeFilter = _ModeLibraryFilter.all;
                      });
                    },
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        for (
                          var index = 0;
                          index < visibleModes.length;
                          index += 1
                        )
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == visibleModes.length - 1 ? 0 : 10,
                            ),
                            child: _buildModeTile(
                              visibleModes[index],
                              i18n,
                              palette: palette,
                              compact: false,
                              onTap: () => _setMode(visibleModes[index]),
                              onFavoriteTap: () =>
                                  _toggleFavorite(visibleModes[index].id),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyModeState(
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required _ModeLibraryFilter filter,
    required VoidCallback onReset,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.panelSurfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            filter == _ModeLibraryFilter.favorites
                ? Icons.favorite_outline_rounded
                : Icons.history_toggle_off_rounded,
            size: 34,
            color: palette.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            _copyEmptyModeTitle(i18n, filter),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _copyEmptyModeSubtitle(i18n, filter),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onReset,
            child: Text(_copyShowAllModesLabel(i18n)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeFilterBar(
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required _ModeLibraryFilter filter,
    required ValueChanged<_ModeLibraryFilter> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ModeLibraryFilter.values
          .map(
            (value) => _ModeFilterChip(
              label: _copyModeFilterLabel(i18n, value),
              selected: filter == value,
              palette: palette,
              onTap: () => onChanged(value),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildModeTile(
    _SoothingModeTheme mode,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required bool compact,
    required VoidCallback onTap,
    required VoidCallback onFavoriteTap,
  }) {
    final selected = _mode.id == mode.id;
    final favorite = _SoothingRuntimeStore.favoriteModeIds.contains(mode.id);
    final tileAccent = Color.lerp(palette.accent, mode.accent, 0.66)!;
    final trackCount = _tracksForMode(mode.id).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? Color.lerp(palette.panelSurfaceMuted, tileAccent, 0.12)!
                : palette.panelSurfaceMuted,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? tileAccent.withValues(alpha: 0.84)
                  : palette.border.withValues(alpha: 0.95),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: tileAccent.withValues(
                        alpha: palette.isDark ? 0.2 : 0.12,
                      ),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tileAccent.withValues(alpha: selected ? 0.18 : 0.1),
                  border: Border.all(
                    color: tileAccent.withValues(alpha: selected ? 0.58 : 0.24),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(mode.icon, color: tileAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            mode.title(i18n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (selected)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tileAccent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: tileAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _copyActiveModeLabel(i18n),
                                  style: TextStyle(
                                    color: tileAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.subtitle(i18n),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoPill(
                      icon: Icons.library_music_rounded,
                      label: _copyTrackCountLabel(i18n, trackCount),
                      palette: palette,
                      dense: true,
                      accent: tileAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: _copyFavoriteToggleLabel(i18n),
                visualDensity: VisualDensity.compact,
                onPressed: onFavoriteTap,
                icon: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: favorite ? tileAccent : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageArea(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required bool compact,
    required double effectBoost,
    required double waveBoost,
  }) {
    final narrow = compact && MediaQuery.of(context).size.width < 430;
    final screenSize = MediaQuery.of(context).size;
    final effectiveCompact = compact && !_fullscreen;
    final bands = _stageBands;
    final playbackGain = _playing ? (_fullscreen ? 1.58 : 1.28) : 0.82;
    final fullscreenStageTopPadding =
        MediaQuery.of(context).padding.top + (_fullscreen ? 8 : 0);
    final phaseOffset = _currentTrack.seed.toDouble() * 0.013;

    return Column(
      children: <Widget>[
        if (!_fullscreen)
          _buildTrackShelf(i18n, palette: palette, compact: effectiveCompact),
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.08),
                      radius: _fullscreen ? 1.2 : 0.96,
                      colors: <Color>[
                        palette.glowA.withValues(
                          alpha: _fullscreen
                              ? (palette.isDark ? 0.62 : 0.42)
                              : (palette.isDark ? 0.44 : 0.3),
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        palette.accent.withValues(
                          alpha: _fullscreen
                              ? (palette.isDark ? 0.14 : 0.16)
                              : (palette.isDark ? 0.08 : 0.1),
                        ),
                        Colors.transparent,
                        palette.orbitAccent.withValues(
                          alpha: _fullscreen
                              ? (palette.isDark ? 0.12 : 0.14)
                              : (palette.isDark ? 0.06 : 0.08),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_fullscreen)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, 0),
                          radius: 1.08,
                          colors: <Color>[
                            Colors.white.withValues(
                              alpha: palette.isDark ? 0.08 : 0.05,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: _fullscreen
                    ? 24
                    : compact
                    ? 70
                    : 90,
                child: _GlowBlob(
                  color: palette.glowA,
                  size: _fullscreen
                      ? screenSize.width * 0.72
                      : compact
                      ? 220
                      : 290,
                ),
              ),
              Positioned(
                right: _fullscreen
                    ? -88
                    : compact
                    ? -38
                    : 112,
                top: _fullscreen
                    ? 36
                    : compact
                    ? 86
                    : 66,
                child: _GlowBlob(
                  color: palette.glowB,
                  size: _fullscreen
                      ? screenSize.width * 0.66
                      : compact
                      ? 210
                      : 270,
                ),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _SoothingSpectrumPainter(
                      accent: palette.accent,
                      orbitAccent: palette.orbitAccent,
                      orbit: _orbitController,
                      phaseOffset: phaseOffset,
                      bands: bands,
                      barGain:
                          (_mode.id == 'motion'
                              ? 1
                              : _mode.id == 'study' || _mode.id == 'jazz'
                              ? 0.82
                              : 0.56) *
                          effectBoost *
                          playbackGain,
                      particleGain:
                          (_mode.id == 'dreaming'
                              ? 1
                              : _mode.id == 'motion'
                              ? 0.9
                              : _mode.id == 'sleep'
                              ? 0.35
                              : 0.6) *
                          effectBoost *
                          playbackGain,
                      breathingGain:
                          (_mode.id == 'sleep'
                              ? 1
                              : _mode.id == 'music_box' || _mode.id == 'harp'
                              ? 0.86
                              : 0.62) *
                          waveBoost *
                          playbackGain,
                      rippleGain: waveBoost * playbackGain,
                      waveGain:
                          (1.04 + effectBoost * 0.34) *
                          playbackGain *
                          (_mode.id == 'dreaming' ? 1.1 : 1),
                      compact: effectiveCompact,
                      isDark: palette.isDark,
                      fullscreen: _fullscreen,
                      animate: _playing,
                    ),
                    child: LayoutBuilder(
                      builder: (context, stageConstraints) {
                        final cramped = stageConstraints.maxHeight < 250;
                        final veryCramped = stageConstraints.maxHeight < 180;
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: _fullscreen ? fullscreenStageTopPadding : 0,
                            ),
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: _fullscreen
                                    ? 16
                                    : compact
                                    ? 24
                                    : 56,
                                vertical: _fullscreen
                                    ? 0
                                    : veryCramped
                                    ? 8
                                    : 18,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: _fullscreen
                                      ? screenSize.width
                                      : compact
                                      ? 460
                                      : 520,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      _mode.title(i18n),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: palette.isDark
                                            ? Colors.white
                                            : const Color(0xFF10263A),
                                        fontSize: _fullscreen
                                            ? math.min(
                                                screenSize.width * 0.16,
                                                76,
                                              )
                                            : veryCramped
                                            ? 26
                                            : cramped
                                            ? 30
                                            : narrow
                                            ? 34
                                            : compact
                                            ? 40
                                            : 54,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: palette.accent.withValues(
                                              alpha: palette.isDark
                                                  ? 0.24
                                                  : 0.12,
                                            ),
                                            blurRadius: 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _fullscreen ? 18 : 14,
                                        vertical: _fullscreen ? 10 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.panelSurface.withValues(
                                          alpha: _fullscreen ? 0.58 : 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: palette.accent.withValues(
                                            alpha: _fullscreen ? 0.72 : 0.54,
                                          ),
                                        ),
                                        boxShadow: _fullscreen
                                            ? <BoxShadow>[
                                                BoxShadow(
                                                  color: palette.accent
                                                      .withValues(alpha: 0.22),
                                                  blurRadius: 30,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : const <BoxShadow>[],
                                      ),
                                      child: Text(
                                        _currentTrack.label(i18n),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: palette.accent,
                                          fontSize: _fullscreen
                                              ? math.min(
                                                  screenSize.width * 0.038,
                                                  18,
                                                )
                                              : narrow
                                              ? 12
                                              : 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (!cramped && !_fullscreen) ...<Widget>[
                                      const SizedBox(height: 18),
                                      Text(
                                        _mode.description(i18n),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: palette.textSecondary,
                                          fontSize: narrow ? 12 : 13,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                    if (_trackLoadText(i18n)
                                        case final String
                                            loadingText) ...<Widget>[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.panelSurface
                                              .withValues(alpha: 0.9),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: palette.border,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              loadingText,
                                              style: TextStyle(
                                                color: palette.textPrimary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (_trackLoadProgress !=
                                                null) ...<Widget>[
                                              const SizedBox(height: 8),
                                              LinearProgressIndicator(
                                                value: _trackLoadProgress,
                                                minHeight: 4,
                                                backgroundColor: palette.border
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (_audioErrorText(i18n)
                                        case final String
                                            errorText) ...<Widget>[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.dangerBg.withValues(
                                            alpha: 0.9,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          errorText,
                                          style: TextStyle(
                                            color: palette.dangerFg,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildBottomControls(
          context,
          i18n,
          palette: palette,
          compact: effectiveCompact,
        ),
      ],
    );
  }

  Widget _buildTrackShelf(
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, compact ? 10 : 12, 16, 12),
      decoration: BoxDecoration(
        color: palette.panelSurface.withValues(
          alpha: palette.isDark ? 0.82 : 0.94,
        ),
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoPill(
                icon: _mode.icon,
                label: _mode.title(i18n),
                palette: palette,
                accent: palette.accent,
              ),
              _InfoPill(
                icon: Icons.library_music_rounded,
                label: _copyTrackCountLabel(i18n, _tracks.length),
                palette: palette,
              ),
              if (_sleepRemaining != null)
                _InfoPill(
                  icon: Icons.timer_outlined,
                  label: _copyActiveSleepTimerLabel(i18n, _sleepRemaining!),
                  palette: palette,
                  accent: palette.orbitAccent,
                ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _tracksExpanded = !_tracksExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: palette.panelSurfaceMuted,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          SoothingMusicCopy.text(i18n, 'track.selector'),
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentTrack.label(i18n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        if (SoothingMusicCopy.trackLabel(
                              AppI18n('zh'),
                              _currentTrack.labelKey,
                            ) !=
                            _currentTrack.label(i18n)) ...<Widget>[
                          const SizedBox(height: 1),
                          Text(
                            SoothingMusicCopy.trackLabel(
                              AppI18n('zh'),
                              _currentTrack.labelKey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    SoothingMusicCopy.text(
                      i18n,
                      _tracksExpanded ? 'track.hide' : 'track.show',
                    ),
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _tracksExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _tracksExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tracks.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _TrackPill(
                    label: _tracks[index].label(i18n),
                    selected: _trackIndex == index,
                    palette: palette,
                    compact: compact,
                    onTap: () => _setTrackIndex(index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required bool compact,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fullscreen
            ? palette.controlSurface.withValues(alpha: 0.76)
            : palette.controlSurface,
        border: Border(
          top: BorderSide(
            color: _fullscreen
                ? palette.border.withValues(alpha: 0.38)
                : palette.border,
          ),
        ),
        boxShadow: _fullscreen
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            _fullscreen ? 14 : 18,
            compact
                ? 10
                : _fullscreen
                ? 8
                : 14,
            _fullscreen ? 14 : 18,
            _fullscreen ? 6 : 10,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progress = _progressRatio;
              final currentLabel = _format(
                Duration(
                  milliseconds: (_duration.inMilliseconds * progress)
                      .round()
                      .clamp(0, _duration.inMilliseconds),
                ),
              );
              final totalLabel = _format(_duration);
              final narrow = compact && MediaQuery.of(context).size.width < 430;
              final screenSize = MediaQuery.of(context).size;
              final stacked =
                  _fullscreen || compact || constraints.maxWidth < 1000;
              final ultraNarrow = constraints.maxWidth < 360;
              final sideBySideControls =
                  !_fullscreen && stacked && !ultraNarrow;

              final sliderTheme = SliderTheme.of(context).copyWith(
                trackHeight: 3.2,
                activeTrackColor: palette.accent,
                inactiveTrackColor: palette.border.withValues(alpha: 0.6),
                thumbColor: palette.accent,
                overlayColor: palette.accent.withValues(alpha: 0.16),
              );

              final volumeControl = Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    tooltip: _copyVolumeToggleLabel(i18n),
                    onPressed: () => _setMuted(!_muted),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    icon: Icon(
                      _muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: palette.textSecondary,
                      size: 18,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: sideBySideControls
                          ? (narrow ? 64 : 84)
                          : narrow
                          ? 96
                          : _fullscreen
                          ? 110
                          : stacked
                          ? 128
                          : 176,
                    ),
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        value: _muted ? 0 : _volume,
                        min: 0,
                        max: 1,
                        onChanged: _setVolume,
                      ),
                    ),
                  ),
                ],
              );

              final transportControls = Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _TransportIconButton(
                    tooltip: _copyPreviousTrackLabel(i18n),
                    icon: Icons.skip_previous_rounded,
                    palette: palette,
                    compact: stacked,
                    onPressed: _loading || _tracks.length <= 1
                        ? null
                        : () => _stepTrack(-1),
                  ),
                  SizedBox(width: stacked ? 4 : 8),
                  FilledButton(
                    onPressed: _loading ? null : _togglePlayback,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.isDark
                          ? const Color(0xFF051C2B)
                          : const Color(0xFF082337),
                      minimumSize: Size(
                        _fullscreen
                            ? 68
                            : stacked
                            ? 54
                            : 70,
                        _fullscreen
                            ? 68
                            : stacked
                            ? 54
                            : 70,
                      ),
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: _loading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: palette.isDark
                                  ? const Color(0xFF042033)
                                  : const Color(0xFF0A2940),
                            ),
                          )
                        : Icon(
                            _playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: _fullscreen
                                ? 32
                                : stacked
                                ? 26
                                : 34,
                          ),
                  ),
                  SizedBox(width: stacked ? 4 : 8),
                  _TransportIconButton(
                    tooltip: _copyNextTrackLabel(i18n),
                    icon: Icons.skip_next_rounded,
                    palette: palette,
                    compact: stacked,
                    onPressed: _loading || _tracks.length <= 1
                        ? null
                        : () => _stepTrack(1),
                  ),
                ],
              );

              final progressBlock = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: stacked
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '$currentLabel / $totalLabel',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: narrow
                        ? double.infinity
                        : _fullscreen
                        ? screenSize.width * 0.74
                        : stacked
                        ? 260
                        : 240,
                    child: SliderTheme(
                      data: sliderTheme,
                      child: Slider(
                        value: progress,
                        min: 0,
                        max: 1,
                        onChangeStart: (value) {
                          setState(() {
                            _draggingRatio = value;
                            _updateStageSpectrum(force: true);
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _draggingRatio = value;
                            _updateStageSpectrum(force: true);
                          });
                        },
                        onChangeEnd: (value) async {
                          setState(() {
                            _draggingRatio = null;
                          });
                          await _seekToRatio(value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _mode.footer(i18n),
                    maxLines: _fullscreen
                        ? 1
                        : narrow
                        ? 2
                        : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              );

              return stacked
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_fullscreen)
                          Row(
                            children: <Widget>[
                              Expanded(child: Center(child: transportControls)),
                              const SizedBox(width: 12),
                              volumeControl,
                            ],
                          )
                        else if (sideBySideControls)
                          Row(
                            children: <Widget>[
                              Expanded(child: volumeControl),
                              const SizedBox(width: 8),
                              transportControls,
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              volumeControl,
                              const SizedBox(height: 8),
                              transportControls,
                            ],
                          ),
                        const SizedBox(height: 8),
                        progressBlock,
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        volumeControl,
                        Expanded(child: Center(child: transportControls)),
                        progressBlock,
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showSleepTimerSheet(BuildContext context, AppI18n i18n) async {
    final values = <Duration?>[
      null,
      const Duration(minutes: 10),
      const Duration(minutes: 20),
      const Duration(minutes: 30),
      const Duration(minutes: 45),
      const Duration(minutes: 60),
    ];
    final selection = await showModalBottomSheet<Duration?>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: values
                .map((value) {
                  final label = _copySleepTimerOptionLabel(i18n, value);
                  final selected = value == null
                      ? _sleepRemaining == null
                      : _sleepRemaining?.inMinutes == value.inMinutes;
                  return ListTile(
                    title: Text(label),
                    trailing: selected ? const Icon(Icons.check_rounded) : null,
                    onTap: () => Navigator.of(context).pop(value),
                  );
                })
                .toList(growable: false),
          ),
        );
      },
    );
    if (!mounted) return;
    _startSleepTimer(selection);
  }

  Future<void> _saveArrangementTemplate(AppI18n i18n) async {
    final steps = List<SoothingPlaybackArrangementStep>.from(_arrangementSteps);
    if (steps.isEmpty) {
      return;
    }
    final suggestedName =
        _activeArrangementTemplate?.name ??
        pickUiText(i18n, zh: '我的编排', en: 'My arrangement');
    final name = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '保存编排模板', en: 'Save arrangement'),
      subtitle: pickUiText(
        i18n,
        zh: '保存当前编排，方便下次直接套用。',
        en: 'Save the current arrangement for quick reuse.',
      ),
      initialValue: suggestedName,
      hintText: pickUiText(
        i18n,
        zh: '例如：睡前 20 分钟',
        en: 'For example: Wind-down 20m',
      ),
      confirmText: pickUiText(i18n, zh: '保存', en: 'Save'),
    );
    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }
    final trimmedName = name.trim();
    final existing = _activeArrangementTemplate;
    final template = SoothingPlaybackArrangementTemplate(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmedName,
      steps: steps,
    );
    final templates = List<SoothingPlaybackArrangementTemplate>.from(
      _SoothingRuntimeStore.arrangementTemplates,
    );
    final existingIndex = templates.indexWhere(
      (item) => item.id == template.id,
    );
    if (existingIndex >= 0) {
      templates[existingIndex] = template;
    } else {
      templates.insert(0, template);
    }
    setState(() {
      _SoothingRuntimeStore.arrangementTemplates = templates;
      _SoothingRuntimeStore.activeArrangementTemplateId = template.id;
    });
    _SoothingRuntimeStore.notifyChanged();
    await _persistPrefs();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(
            i18n,
            zh: '已保存编排模板：$trimmedName',
            en: 'Saved arrangement: $trimmedName',
          ),
        ),
      ),
    );
  }

  Future<void> _renameArrangementTemplate(
    AppI18n i18n,
    SoothingPlaybackArrangementTemplate template,
  ) async {
    final name = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '重命名编排模板', en: 'Rename arrangement'),
      initialValue: template.name,
      hintText: pickUiText(i18n, zh: '输入新名称', en: 'Enter a new name'),
      confirmText: pickUiText(i18n, zh: '保存', en: 'Save'),
    );
    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }
    final trimmedName = name.trim();
    setState(() {
      _SoothingRuntimeStore.arrangementTemplates = _SoothingRuntimeStore
          .arrangementTemplates
          .map(
            (item) => item.id == template.id
                ? item.copyWith(name: trimmedName)
                : item,
          )
          .toList(growable: false);
    });
    _SoothingRuntimeStore.notifyChanged();
    await _persistPrefs();
  }

  Future<void> _deleteArrangementTemplate(
    AppI18n i18n,
    SoothingPlaybackArrangementTemplate template,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '删除编排模板', en: 'Delete arrangement'),
      message: pickUiText(
        i18n,
        zh: '确定删除“${template.name}”？',
        en: 'Delete "${template.name}"?',
      ),
      confirmText: pickUiText(i18n, zh: '删除', en: 'Delete'),
      danger: true,
    );
    if (!mounted || !confirmed) {
      return;
    }
    setState(() {
      _SoothingRuntimeStore.arrangementTemplates = _SoothingRuntimeStore
          .arrangementTemplates
          .where((item) => item.id != template.id)
          .toList(growable: false);
      if (_SoothingRuntimeStore.activeArrangementTemplateId == template.id) {
        _SoothingRuntimeStore.activeArrangementTemplateId = null;
      }
    });
    _SoothingRuntimeStore.notifyChanged();
    await _persistPrefs();
  }

  void _applyArrangementTemplate(SoothingPlaybackArrangementTemplate template) {
    setState(() {
      _SoothingRuntimeStore.playbackMode = SoothingPlaybackMode.arrangement;
      _SoothingRuntimeStore.arrangementSteps =
          List<SoothingPlaybackArrangementStep>.from(template.steps);
      _SoothingRuntimeStore.activeArrangementTemplateId = template.id;
      _SoothingRuntimeStore.arrangementStepIndex = 0;
      _SoothingRuntimeStore.arrangementStepPlayCount = 0;
    });
    _SoothingRuntimeStore.notifyChanged();
    unawaited(_persistPrefs());
    unawaited(_startArrangementPlayback(autoplay: _playing || !_loading));
  }

  void _useCurrentArrangementDraft(
    List<SoothingPlaybackArrangementStep> steps,
  ) {
    final snapshot = List<SoothingPlaybackArrangementStep>.from(steps);
    final activeTemplate = _activeArrangementTemplate;
    if (activeTemplate == null) {
      _SoothingRuntimeStore.activeArrangementTemplateId = null;
      return;
    }
    final sameLength = activeTemplate.steps.length == snapshot.length;
    final sameSteps =
        sameLength &&
        Iterable<int>.generate(snapshot.length).every((index) {
          final left = activeTemplate.steps[index];
          final right = snapshot[index];
          return left.modeId == right.modeId &&
              left.trackIndex == right.trackIndex &&
              left.repeatCount == right.repeatCount;
        });
    if (!sameSteps) {
      _SoothingRuntimeStore.activeArrangementTemplateId = null;
    }
  }

  Future<void> _showArrangementSheet(BuildContext context, AppI18n i18n) async {
    var selectedMode = _playbackMode;
    var draftSteps = List<SoothingPlaybackArrangementStep>.from(
      _arrangementSteps,
    );
    if (draftSteps.isEmpty) {
      draftSteps = <SoothingPlaybackArrangementStep>[
        SoothingPlaybackArrangementStep(
          modeId: _mode.id,
          trackIndex: _trackIndex,
          repeatCount: 1,
        ),
      ];
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final templates = _SoothingRuntimeStore.arrangementTemplates;
            final activeTemplate = _activeArrangementTemplate;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '播放顺序与编排', en: 'Playback order'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '默认使用单曲循环。切到编排播放后，可按设定顺序自动切换主题和曲目。',
                      en: 'Single loop is the default. Switch to arrangement mode to auto-advance across themes and tracks.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<SoothingPlaybackMode>(
                    segments: <ButtonSegment<SoothingPlaybackMode>>[
                      ButtonSegment<SoothingPlaybackMode>(
                        value: SoothingPlaybackMode.singleLoop,
                        label: Text(
                          _playbackModeLabel(
                            i18n,
                            SoothingPlaybackMode.singleLoop,
                          ),
                        ),
                      ),
                      ButtonSegment<SoothingPlaybackMode>(
                        value: SoothingPlaybackMode.modeCycle,
                        label: Text(
                          _playbackModeLabel(
                            i18n,
                            SoothingPlaybackMode.modeCycle,
                          ),
                        ),
                      ),
                      ButtonSegment<SoothingPlaybackMode>(
                        value: SoothingPlaybackMode.arrangement,
                        label: Text(
                          _playbackModeLabel(
                            i18n,
                            SoothingPlaybackMode.arrangement,
                          ),
                        ),
                      ),
                    ],
                    selected: <SoothingPlaybackMode>{selectedMode},
                    onSelectionChanged: (selection) {
                      final nextMode = selection.firstOrNull;
                      if (nextMode == null) return;
                      setModalState(() {
                        selectedMode = nextMode;
                      });
                    },
                  ),
                  if (selectedMode ==
                      SoothingPlaybackMode.arrangement) ...<Widget>[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const Icon(Icons.bookmark_added_outlined),
                        title: Text(
                          activeTemplate?.name ??
                              pickUiText(
                                i18n,
                                zh: '当前编排未保存',
                                en: 'Current arrangement not saved',
                              ),
                        ),
                        subtitle: Text(
                          pickUiText(
                            i18n,
                            zh: '${draftSteps.length} 段 · 已保存模板 ${templates.length} 个',
                            en: '${draftSteps.length} steps · ${templates.length} saved',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            setState(() {
                              _SoothingRuntimeStore.arrangementSteps =
                                  List<SoothingPlaybackArrangementStep>.from(
                                    draftSteps,
                                  );
                            });
                            _useCurrentArrangementDraft(draftSteps);
                            _SoothingRuntimeStore.notifyChanged();
                            await _saveArrangementTemplate(i18n);
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                            pickUiText(i18n, zh: '保存当前编排', en: 'Save current'),
                          ),
                        ),
                        if (templates.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final selected =
                                  await showModalBottomSheet<
                                    SoothingPlaybackArrangementTemplate
                                  >(
                                    context: context,
                                    useSafeArea: true,
                                    showDragHandle: true,
                                    builder: (dialogContext) {
                                      return ListView.separated(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          8,
                                          12,
                                          24,
                                        ),
                                        itemCount: templates.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (dialogContext, index) {
                                          final template = templates[index];
                                          return Card(
                                            child: ListTile(
                                              leading: Icon(
                                                template.id ==
                                                        _SoothingRuntimeStore
                                                            .activeArrangementTemplateId
                                                    ? Icons.check_circle_rounded
                                                    : Icons
                                                          .playlist_play_rounded,
                                              ),
                                              title: Text(template.name),
                                              subtitle: Text(
                                                pickUiText(
                                                  i18n,
                                                  zh: '${template.steps.length} 段',
                                                  en: '${template.steps.length} steps',
                                                ),
                                              ),
                                              onTap: () => Navigator.of(
                                                dialogContext,
                                              ).pop(template),
                                              trailing: PopupMenuButton<String>(
                                                onSelected: (action) async {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                  if (action == 'rename') {
                                                    await _renameArrangementTemplate(
                                                      i18n,
                                                      template,
                                                    );
                                                  } else if (action ==
                                                      'delete') {
                                                    await _deleteArrangementTemplate(
                                                      i18n,
                                                      template,
                                                    );
                                                  }
                                                },
                                                itemBuilder: (_) =>
                                                    <PopupMenuEntry<String>>[
                                                      PopupMenuItem<String>(
                                                        value: 'rename',
                                                        child: Text(
                                                          pickUiText(
                                                            i18n,
                                                            zh: '重命名',
                                                            en: 'Rename',
                                                          ),
                                                        ),
                                                      ),
                                                      PopupMenuItem<String>(
                                                        value: 'delete',
                                                        child: Text(
                                                          pickUiText(
                                                            i18n,
                                                            zh: '删除',
                                                            en: 'Delete',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                              if (selected == null || !mounted) {
                                return;
                              }
                              setModalState(() {
                                draftSteps =
                                    List<SoothingPlaybackArrangementStep>.from(
                                      selected.steps,
                                    );
                              });
                              _applyArrangementTemplate(selected);
                            },
                            icon: const Icon(Icons.folder_open_rounded),
                            label: Text(
                              pickUiText(i18n, zh: '加载模板', en: 'Load saved'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            pickUiText(
                              i18n,
                              zh: '编排步骤',
                              en: 'Arrangement steps',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              draftSteps.add(
                                SoothingPlaybackArrangementStep(
                                  modeId: _mode.id,
                                  trackIndex: _trackIndex,
                                  repeatCount: 1,
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            pickUiText(i18n, zh: '添加当前曲目', en: 'Add current'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: draftSteps.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final step = draftSteps[index];
                          final stepMode = _modes.firstWhere(
                            (mode) => mode.id == step.modeId,
                            orElse: () => _mode,
                          );
                          final tracks = _tracksForMode(stepMode.id);
                          final safeTrackIndex = step.trackIndex.clamp(
                            0,
                            tracks.length - 1,
                          );
                          final track = tracks[safeTrackIndex];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          '${index + 1}. ${stepMode.title(i18n)} · ${SoothingMusicCopy.trackLabel(i18n, track.labelKey)}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: index > 0
                                            ? () {
                                                setModalState(() {
                                                  final item = draftSteps
                                                      .removeAt(index);
                                                  draftSteps.insert(
                                                    index - 1,
                                                    item,
                                                  );
                                                });
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.arrow_upward_rounded,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: index < draftSteps.length - 1
                                            ? () {
                                                setModalState(() {
                                                  final item = draftSteps
                                                      .removeAt(index);
                                                  draftSteps.insert(
                                                    index + 1,
                                                    item,
                                                  );
                                                });
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.arrow_downward_rounded,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: draftSteps.length > 1
                                            ? () {
                                                setModalState(() {
                                                  draftSteps.removeAt(index);
                                                });
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: stepMode.id,
                                    decoration: InputDecoration(
                                      labelText: pickUiText(
                                        i18n,
                                        zh: '主题',
                                        en: 'Theme',
                                      ),
                                    ),
                                    items: _modes
                                        .map(
                                          (mode) => DropdownMenuItem<String>(
                                            value: mode.id,
                                            child: Text(mode.title(i18n)),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setModalState(() {
                                        draftSteps[index] = draftSteps[index]
                                            .copyWith(
                                              modeId: value,
                                              trackIndex: 0,
                                            );
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<int>(
                                    initialValue: safeTrackIndex,
                                    decoration: InputDecoration(
                                      labelText: pickUiText(
                                        i18n,
                                        zh: '曲目',
                                        en: 'Track',
                                      ),
                                    ),
                                    items: List<DropdownMenuItem<int>>.generate(
                                      tracks.length,
                                      (trackIndex) => DropdownMenuItem<int>(
                                        value: trackIndex,
                                        child: Text(
                                          SoothingMusicCopy.trackLabel(
                                            i18n,
                                            tracks[trackIndex].labelKey,
                                          ),
                                        ),
                                      ),
                                      growable: false,
                                    ),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setModalState(() {
                                        draftSteps[index] = draftSteps[index]
                                            .copyWith(trackIndex: value);
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        pickUiText(
                                          i18n,
                                          zh: '重复次数',
                                          en: 'Repeats',
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: step.repeatCount > 1
                                            ? () {
                                                setModalState(() {
                                                  draftSteps[index] =
                                                      draftSteps[index].copyWith(
                                                        repeatCount:
                                                            step.repeatCount -
                                                            1,
                                                      );
                                                });
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.remove_circle_outline_rounded,
                                        ),
                                      ),
                                      Text('${step.repeatCount}'),
                                      IconButton(
                                        onPressed: step.repeatCount < 99
                                            ? () {
                                                setModalState(() {
                                                  draftSteps[index] =
                                                      draftSteps[index].copyWith(
                                                        repeatCount:
                                                            step.repeatCount +
                                                            1,
                                                      );
                                                });
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.add_circle_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(
                          MaterialLocalizations.of(context).cancelButtonLabel,
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          if (selectedMode ==
                                  SoothingPlaybackMode.arrangement &&
                              draftSteps.isEmpty) {
                            return;
                          }
                          final sheetNavigator = Navigator.of(sheetContext);
                          setState(() {
                            _SoothingRuntimeStore.playbackMode = selectedMode;
                            _SoothingRuntimeStore.arrangementSteps =
                                List<SoothingPlaybackArrangementStep>.from(
                                  draftSteps,
                                );
                            _SoothingRuntimeStore.arrangementStepIndex = 0;
                            _SoothingRuntimeStore.arrangementStepPlayCount = 0;
                            _useCurrentArrangementDraft(draftSteps);
                          });
                          _SoothingRuntimeStore.notifyChanged();
                          await _persistPrefs();
                          if (!mounted) {
                            return;
                          }
                          sheetNavigator.pop();
                          if (selectedMode ==
                              SoothingPlaybackMode.arrangement) {
                            await _startArrangementPlayback(
                              autoplay: _playing || !_loading,
                            );
                          }
                        },
                        child: Text(pickUiText(i18n, zh: '应用', en: 'Apply')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showModeSheet(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
  }) async {
    var sheetFilter = _modeFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final visibleModes = _modesForFilter(sheetFilter);
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.84,
              minChildSize: 0.54,
              maxChildSize: 0.94,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _copyBrowseModesTitle(i18n),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _copyBrowseModesSubtitle(i18n),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      _buildModeFilterBar(
                        i18n,
                        palette: palette,
                        filter: sheetFilter,
                        onChanged: (value) {
                          setState(() {
                            _modeFilter = value;
                          });
                          setModalState(() {
                            sheetFilter = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: visibleModes.isEmpty
                            ? _buildEmptyModeState(
                                i18n,
                                palette: palette,
                                filter: sheetFilter,
                                onReset: () {
                                  setState(() {
                                    _modeFilter = _ModeLibraryFilter.all;
                                  });
                                  setModalState(() {
                                    sheetFilter = _ModeLibraryFilter.all;
                                  });
                                },
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: visibleModes.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final mode = visibleModes[index];
                                  return _buildModeTile(
                                    mode,
                                    i18n,
                                    palette: palette,
                                    compact: false,
                                    onTap: () {
                                      Navigator.of(sheetContext).pop();
                                      unawaited(_setMode(mode));
                                    },
                                    onFavoriteTap: () {
                                      _toggleFavorite(mode.id);
                                      setModalState(() {});
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _copyPageTitle(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'page.title');

  String _copyPageSubtitle(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'page.subtitle');

  String _copyBrowseModesTitle(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.browser.title');

  String _copyBrowseModesSubtitle(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.browser.subtitle');

  String _copyModesButtonLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.button');

  String _copyModeFilterLabel(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.all => SoothingMusicCopy.text(i18n, 'mode.filter.all'),
      _ModeLibraryFilter.favorites => SoothingMusicCopy.text(
        i18n,
        'mode.filter.favorites',
      ),
      _ModeLibraryFilter.recent => SoothingMusicCopy.text(
        i18n,
        'mode.filter.recent',
      ),
    };
  }

  String _copyEmptyModeTitle(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.favorites => SoothingMusicCopy.text(
        i18n,
        'mode.empty.favorites.title',
      ),
      _ModeLibraryFilter.recent => SoothingMusicCopy.text(
        i18n,
        'mode.empty.recent.title',
      ),
      _ModeLibraryFilter.all => '',
    };
  }

  String _copyEmptyModeSubtitle(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.favorites => SoothingMusicCopy.text(
        i18n,
        'mode.empty.favorites.subtitle',
      ),
      _ModeLibraryFilter.recent => SoothingMusicCopy.text(
        i18n,
        'mode.empty.recent.subtitle',
      ),
      _ModeLibraryFilter.all => '',
    };
  }

  String _copyShowAllModesLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.show_all');

  String _copySleepTimerButtonLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'timer.button');

  String _copySleepTimerOptionLabel(AppI18n i18n, Duration? value) {
    if (value == null) return SoothingMusicCopy.text(i18n, 'timer.off');
    return SoothingMusicCopy.text(
      i18n,
      'timer.minutes',
      params: <String, Object?>{'count': value.inMinutes},
    );
  }

  String _copyActiveSleepTimerLabel(AppI18n i18n, Duration value) =>
      SoothingMusicCopy.text(
        i18n,
        'timer.active',
        params: <String, Object?>{'duration': _format(value)},
      );

  String _copyTrackCountLabel(AppI18n i18n, int count) =>
      SoothingMusicCopy.text(
        i18n,
        'track.count',
        params: <String, Object?>{'count': count},
      );

  String _copyActiveModeLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.active');

  String _copyFavoriteToggleLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'mode.favorite_toggle');

  String _copyPreviousTrackLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'track.previous');

  String _copyNextTrackLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'track.next');

  String _copyVolumeToggleLabel(AppI18n i18n) =>
      SoothingMusicCopy.text(i18n, 'audio.toggle_mute');

  String _pageTitle(AppI18n i18n) => pickUiText(
    i18n,
    zh: '舒缓轻音',
    en: 'Soothing music',
    ja: 'やわらぎミュージック',
    de: 'Sanfte Musik',
    fr: 'Musique apaisante',
    es: 'Música relajante',
    ru: 'Спокойная музыка',
  );

  String _pageSubtitle(AppI18n i18n) => pickUiText(
    i18n,
    zh: '精选疗愈系轻音乐与氛围旋律，配合动态呼吸光效与本地曲库，适合手机端沉浸使用。',
    en: 'Curated calming loops with breathing light effects, local tracks, and a mobile-first immersive layout.',
  );

  String _browseModesTitle(AppI18n i18n) => pickUiText(
    i18n,
    zh: '浏览模式',
    en: 'Browse modes',
    ja: 'モード一覧',
    de: 'Modi durchsuchen',
    fr: 'Parcourir les modes',
    es: 'Explorar modos',
    ru: 'Режимы',
  );

  String _browseModesSubtitle(AppI18n i18n) => pickUiText(
    i18n,
    zh: '切换模式后会自动回到播放页，当前模式会高亮显示。',
    en: 'Selecting a mode closes the menu and keeps the current mode clearly highlighted.',
  );

  String _modesButtonLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '模式',
    en: 'Modes',
    ja: 'モード',
    de: 'Modi',
    fr: 'Modes',
    es: 'Modos',
    ru: 'Режимы',
  );

  String _modeFilterLabel(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.all => pickUiText(
        i18n,
        zh: '全部',
        en: 'All',
        ja: 'すべて',
        de: 'Alle',
        fr: 'Tout',
        es: 'Todo',
        ru: 'Все',
      ),
      _ModeLibraryFilter.favorites => pickUiText(
        i18n,
        zh: '收藏',
        en: 'Favorites',
        ja: 'お気に入り',
        de: 'Favoriten',
        fr: 'Favoris',
        es: 'Favoritos',
        ru: 'Избранное',
      ),
      _ModeLibraryFilter.recent => pickUiText(
        i18n,
        zh: '最近',
        en: 'Recent',
        ja: '最近',
        de: 'Zuletzt',
        fr: 'Récents',
        es: 'Recientes',
        ru: 'Недавние',
      ),
    };
  }

  String _emptyModeTitle(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.favorites => pickUiText(
        i18n,
        zh: '还没有收藏模式',
        en: 'No favorite modes yet',
        ja: 'お気に入りのモードはまだありません',
        de: 'Noch keine Favoriten',
        fr: 'Aucun favori pour le moment',
        es: 'Aún no hay favoritos',
        ru: 'Пока нет избранных режимов',
      ),
      _ModeLibraryFilter.recent => pickUiText(
        i18n,
        zh: '最近还没有播放记录',
        en: 'No recent modes yet',
        ja: '最近使ったモードはまだありません',
        de: 'Noch keine zuletzt verwendeten Modi',
        fr: 'Aucun mode récent pour le moment',
        es: 'Aún no hay modos recientes',
        ru: 'Пока нет недавних режимов',
      ),
      _ModeLibraryFilter.all => '',
    };
  }

  String _emptyModeSubtitle(AppI18n i18n, _ModeLibraryFilter filter) {
    return switch (filter) {
      _ModeLibraryFilter.favorites => pickUiText(
        i18n,
        zh: '给常用模式点亮爱心，之后就能在这里快速切换。',
        en: 'Mark modes you use often and they will appear here for quick switching.',
      ),
      _ModeLibraryFilter.recent => pickUiText(
        i18n,
        zh: '切换或播放几个模式后，这里会自动记录最近使用内容。',
        en: 'Once you switch or play a few modes, your recent history will appear here.',
      ),
      _ModeLibraryFilter.all => '',
    };
  }

  String _showAllModesLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '查看全部',
    en: 'Show all',
    ja: 'すべて表示',
    de: 'Alle anzeigen',
    fr: 'Tout afficher',
    es: 'Ver todo',
    ru: 'Показать все',
  );

  String _sleepTimerButtonLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '睡眠定时',
    en: 'Sleep timer',
    ja: 'スリープタイマー',
    de: 'Schlaftimer',
    fr: 'Minuteur de veille',
    es: 'Temporizador de sueño',
    ru: 'Таймер сна',
  );

  String _sleepTimerOptionLabel(AppI18n i18n, Duration? value) {
    if (value == null) {
      return pickUiText(
        i18n,
        zh: '关闭',
        en: 'Off',
        ja: 'オフ',
        de: 'Aus',
        fr: 'Désactivé',
        es: 'Desactivado',
        ru: 'Выкл',
      );
    }
    return pickUiText(
      i18n,
      zh: '${value.inMinutes} 分钟',
      en: '${value.inMinutes} min',
      ja: '${value.inMinutes}分',
      de: '${value.inMinutes} Min',
      fr: '${value.inMinutes} min',
      es: '${value.inMinutes} min',
      ru: '${value.inMinutes} мин',
    );
  }

  String _activeSleepTimerLabel(AppI18n i18n, Duration value) => pickUiText(
    i18n,
    zh: '睡眠定时 ${_format(value)}',
    en: 'Sleep timer ${_format(value)}',
    ja: 'スリープタイマー ${_format(value)}',
    de: 'Schlaftimer ${_format(value)}',
    fr: 'Minuteur ${_format(value)}',
    es: 'Temporizador ${_format(value)}',
    ru: 'Таймер ${_format(value)}',
  );

  String _trackCountLabel(AppI18n i18n, int count) => pickUiText(
    i18n,
    zh: '$count 首曲目',
    en: '$count tracks',
    ja: '$count 曲',
    de: '$count Titel',
    fr: '$count pistes',
    es: '$count pistas',
    ru: '$count треков',
  );

  String _activeModeLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '当前',
    en: 'Active',
    ja: '再生中',
    de: 'Aktiv',
    fr: 'Actif',
    es: 'Activo',
    ru: 'Активен',
  );

  String _favoriteToggleLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '收藏模式',
    en: 'Toggle favorite',
    ja: 'お気に入り',
    de: 'Favorit umschalten',
    fr: 'Mettre en favori',
    es: 'Marcar favorito',
    ru: 'В избранное',
  );

  String _previousTrackLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '上一首',
    en: 'Previous track',
    ja: '前の曲',
    de: 'Vorheriger Titel',
    fr: 'Piste précédente',
    es: 'Pista anterior',
    ru: 'Предыдущий трек',
  );

  String _nextTrackLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '下一首',
    en: 'Next track',
    ja: '次の曲',
    de: 'Nächster Titel',
    fr: 'Piste suivante',
    es: 'Siguiente pista',
    ru: 'Следующий трек',
  );

  String _volumeToggleLabel(AppI18n i18n) => pickUiText(
    i18n,
    zh: '静音切换',
    en: 'Toggle mute',
    ja: 'ミュート切替',
    de: 'Stumm schalten',
    fr: 'Couper le son',
    es: 'Silenciar',
    ru: 'Вкл/выкл звук',
  );
}

class _CompactCurrentModeCard extends StatelessWidget {
  const _CompactCurrentModeCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.palette,
    this.dropdownEnabled = false,
    this.showFavoriteButton = true,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final _SoothingVisualPalette palette;
  final bool dropdownEnabled;
  final bool showFavoriteButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.panelSurfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: palette.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          if (showFavoriteButton)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onToggleFavorite,
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 18,
                color: isFavorite ? accent : palette.textSecondary,
              ),
            ),
          if (dropdownEnabled)
            Padding(
              padding: EdgeInsets.only(left: showFavoriteButton ? 2 : 0),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: palette.accent,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeFilterChip extends StatelessWidget {
  const _ModeFilterChip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _SoothingVisualPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? palette.accent.withValues(alpha: palette.isDark ? 0.18 : 0.12)
                : palette.panelSurfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.76)
                  : palette.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? palette.accent : palette.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackPill extends StatelessWidget {
  const _TrackPill({
    required this.label,
    required this.selected,
    required this.palette,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _SoothingVisualPalette palette;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(
            minHeight: 38,
            maxWidth: compact ? 176 : 240,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? palette.accent.withValues(alpha: palette.isDark ? 0.18 : 0.12)
                : palette.panelSurfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.76)
                  : palette.border,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: palette.accent.withValues(
                        alpha: palette.isDark ? 0.18 : 0.1,
                      ),
                      blurRadius: 18,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (selected) ...<Widget>[
                Icon(Icons.graphic_eq_rounded, size: 16, color: palette.accent),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? palette.accent : palette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.palette,
    this.dense = false,
    this.accent,
  });

  final IconData icon;
  final String label;
  final _SoothingVisualPalette palette;
  final bool dense;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ?? palette.orbitAccent;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: palette.panelSurfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.border.withValues(alpha: 0.82)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: dense ? 13 : 14, color: resolvedAccent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent == null
                    ? palette.textSecondary
                    : Color.lerp(resolvedAccent, palette.textPrimary, 0.3),
                fontSize: dense ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransportIconButton extends StatelessWidget {
  const _TransportIconButton({
    required this.tooltip,
    required this.icon,
    required this.palette,
    required this.compact,
    this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final _SoothingVisualPalette palette;
  final bool compact;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.panelSurfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
      ),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        iconSize: compact ? 20 : 24,
        padding: EdgeInsets.all(compact ? 8 : 12),
        constraints: BoxConstraints.tightFor(
          width: compact ? 36 : 44,
          height: compact ? 36 : 44,
        ),
        icon: Icon(icon, color: palette.textPrimary),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: size * 0.36,
            spreadRadius: size * 0.06,
          ),
        ],
      ),
    );
  }
}

class _SoothingSpectrumPainter extends CustomPainter {
  _SoothingSpectrumPainter({
    required this.accent,
    required this.orbitAccent,
    required this.orbit,
    required this.phaseOffset,
    required this.bands,
    required this.barGain,
    required this.particleGain,
    required this.breathingGain,
    required this.rippleGain,
    required this.waveGain,
    required this.compact,
    required this.isDark,
    required this.animate,
    this.fullscreen = false,
  }) : super(repaint: orbit);

  final Color accent;
  final Color orbitAccent;
  final Animation<double> orbit;
  final double phaseOffset;
  final List<double> bands;
  final double barGain;
  final double particleGain;
  final double breathingGain;
  final double rippleGain;
  final double waveGain;
  final bool compact;
  final bool isDark;
  final bool fullscreen;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final phase =
        (animate ? orbit.value : orbit.value.roundToDouble()) * math.pi * 2 +
        phaseOffset;
    final center = size.center(Offset.zero);
    final shortest = math.min(size.width, size.height);
    final compactBoost = compact ? 1.16 : 1.0;
    final fullscreenBoost = fullscreen ? 1.22 : 1.0;
    final innerRadius =
        shortest *
        (compact
            ? 0.17
            : fullscreen
            ? 0.19
            : 0.14);
    final expandedBands = _expandBands(bands, 24);
    final energy =
        bands.fold<double>(0, (sum, item) => sum + item) / bands.length;

    _drawWaveRibbon(
      canvas,
      size,
      center,
      color: accent.withValues(alpha: isDark ? 0.34 : 0.24),
      phase: phase,
      amplitude: shortest * 0.046 * waveGain * fullscreenBoost,
      verticalOffset: -shortest * 0.06,
      direction: 1,
    );
    _drawWaveRibbon(
      canvas,
      size,
      center,
      color: orbitAccent.withValues(alpha: isDark ? 0.28 : 0.2),
      phase: phase + 1.6,
      amplitude: shortest * 0.036 * waveGain * fullscreenBoost,
      verticalOffset: shortest * 0.08,
      direction: -1,
    );

    for (var ring = 0; ring < (fullscreen ? 6 : 4); ring += 1) {
      final progress = ((phase / (math.pi * 2)) + ring * 0.32) % 1;
      final radius =
          innerRadius * (1.04 + progress * (1.75 + rippleGain * 0.18));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withValues(
            alpha: (1 - progress) * (isDark ? 0.18 : 0.14) * rippleGain,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = fullscreen
              ? 3.2
              : compact
              ? 2.0
              : 2.8,
      );
    }

    for (
      var i = 0;
      i <
          (fullscreen
                  ? 26 + particleGain * 48 * compactBoost
                  : 16 + particleGain * 34 * compactBoost)
              .round();
      i += 1
    ) {
      final drift = phase + i * 0.47;
      final radius = innerRadius * (2.22 + (i % 6) * 0.22) * compactBoost;
      final point = Offset(
        center.dx + math.cos(drift) * radius,
        center.dy + math.sin(drift * 1.14) * radius * 0.72,
      );
      canvas.drawCircle(
        point,
        1.6 + (i % 3) * (fullscreen ? 1.2 : 0.9),
        Paint()
          ..color = orbitAccent.withValues(
            alpha: (0.14 + (i % 5) * 0.04).clamp(0.14, 0.42),
          ),
      );
    }

    for (
      var i = 0;
      i <
          (fullscreen ? 18 + particleGain * 30 : 10 + particleGain * 20)
              .round();
      i += 1
    ) {
      final drift = phase * 1.24 + i * 1.34;
      final radius =
          innerRadius * (0.72 + (i % 4) * 0.18 + math.sin(drift) * 0.08);
      final point = Offset(
        center.dx + math.cos(drift) * radius,
        center.dy + math.sin(drift * 0.9) * radius,
      );
      canvas.drawCircle(
        point,
        2.0 + (i % 2) * (fullscreen ? 1.2 : 0.8),
        Paint()..color = accent.withValues(alpha: isDark ? 0.34 : 0.24),
      );
    }

    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader =
          LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: <Color>[
              accent.withValues(alpha: 0.88),
              orbitAccent.withValues(alpha: 0.96),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: innerRadius * 2.8),
          );
    for (var i = 0; i < expandedBands.length; i += 1) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / expandedBands.length);
      final amplitude = expandedBands[i];
      final pulse =
          0.84 + 0.38 * math.sin(phase * 1.8 + i * 0.42 + amplitude * 3.2);
      final length =
          (22 + amplitude * shortest * 0.08 * barGain * compactBoost)
              .toDouble() *
          pulse.clamp(0.72, 1.28);
      final barWidth = 3.4 + barGain * 1.4;
      final barCenter = Offset(
        center.dx + math.cos(angle) * (innerRadius * 2.08 + length * 0.5),
        center.dy + math.sin(angle) * (innerRadius * 2.08 + length * 0.5),
      );
      canvas.save();
      canvas.translate(barCenter.dx, barCenter.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: barWidth, height: length),
          Radius.circular(barWidth),
        ),
        barPaint,
      );
      canvas.restore();
    }

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: 0.26 + energy * 0.1),
              accent.withValues(alpha: 0.2 + energy * 0.16),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: innerRadius * 2.2),
          );
    canvas.drawCircle(
      center,
      innerRadius * (fullscreen ? 2.05 : 1.8),
      glowPaint,
    );

    for (var ring = 0; ring < 5; ring += 1) {
      final breath =
          1 +
          math.sin(phase * (0.7 + ring * 0.1) + ring) * 0.035 * breathingGain;
      final radius = innerRadius * (1.68 + ring * 0.35) * breath;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withValues(alpha: 0.028 * (5 - ring))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16,
      );
    }

    _drawSpectrumOrbit(
      canvas,
      center,
      baseRadius: innerRadius * 2.45,
      phase: phase,
      color: accent.withValues(alpha: 0.98),
      bands: bands,
      direction: 1,
    );
    _drawSpectrumOrbit(
      canvas,
      center,
      baseRadius: innerRadius * 2.72,
      phase: phase + 1.4,
      color: orbitAccent.withValues(alpha: 0.94),
      bands: bands,
      direction: -1,
      reverseBands: true,
    );
  }

  List<double> _expandBands(List<double> source, int count) {
    if (source.isEmpty) return List<double>.filled(count, 0.2);
    return List<double>.generate(count, (index) {
      final position = index * (source.length - 1) / math.max(1, count - 1);
      final lower = position.floor().clamp(0, source.length - 1);
      final upper = position.ceil().clamp(0, source.length - 1);
      if (lower == upper) return source[lower];
      final t = position - lower;
      return source[lower] * (1 - t) + source[upper] * t;
    }, growable: false);
  }

  void _drawWaveRibbon(
    Canvas canvas,
    Size size,
    Offset center, {
    required Color color,
    required double phase,
    required double amplitude,
    required double verticalOffset,
    required double direction,
  }) {
    final path = Path();
    final left = size.width * 0.1;
    final right = size.width * 0.9;
    const steps = 84;
    for (var i = 0; i <= steps; i += 1) {
      final t = i / steps;
      final x = left + (right - left) * t;
      final waveA = math.sin(t * math.pi * 4 + phase * direction);
      final waveB = math.cos(t * math.pi * 7 - phase * 0.36);
      final y =
          center.dy +
          verticalOffset +
          waveA * amplitude * 0.72 +
          waveB * amplitude * 0.38;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 2.8 : 3.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, paint);
  }

  void _drawSpectrumOrbit(
    Canvas canvas,
    Offset center, {
    required double baseRadius,
    required double phase,
    required Color color,
    required List<double> bands,
    required double direction,
    bool reverseBands = false,
  }) {
    final path = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i += 1) {
      final t = i / steps;
      final angle = t * math.pi * 2;
      final bandIndex = ((t * bands.length).floor()).clamp(0, bands.length - 1);
      final sourceIndex = reverseBands
          ? bands.length - 1 - bandIndex
          : bandIndex;
      final band = bands[sourceIndex];
      final modulation =
          math.sin(angle * 4 + phase * direction) * (0.08 + band * 0.1) +
          math.cos(angle * 7 - phase * 0.35) * (0.03 + band * 0.05);
      final currentRadius = baseRadius * (1 + modulation);
      final point = Offset(
        center.dx + math.cos(angle) * currentRadius,
        center.dy + math.sin(angle) * currentRadius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SoothingSpectrumPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.orbitAccent != orbitAccent ||
        !identical(oldDelegate.bands, bands) ||
        oldDelegate.barGain != barGain ||
        oldDelegate.particleGain != particleGain ||
        oldDelegate.breathingGain != breathingGain ||
        oldDelegate.rippleGain != rippleGain ||
        oldDelegate.waveGain != waveGain ||
        oldDelegate.compact != compact ||
        oldDelegate.isDark != isDark ||
        oldDelegate.fullscreen != fullscreen ||
        oldDelegate.animate != animate ||
        oldDelegate.phaseOffset != phaseOffset;
  }
}
