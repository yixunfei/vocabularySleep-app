import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../services/toolbox_soothing_audio_service.dart';
import '../../services/toolbox_soothing_prefs_service.dart';
import '../legacy_style.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';

final AudioContext _soothingAudioContext = AudioContextConfig(
  focus: AudioContextConfigFocus.mixWithOthers,
).build();

class SoothingMusicV2Page extends StatefulWidget {
  const SoothingMusicV2Page({super.key});

  @override
  State<SoothingMusicV2Page> createState() => _SoothingMusicV2PageState();
}

enum _ModeLibraryFilter { all, favorites, recent }

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

  String title(AppI18n i18n) => pickUiText(i18n, zh: zhTitle, en: enTitle);
  String subtitle(AppI18n i18n) =>
      pickUiText(i18n, zh: zhSubtitle, en: enSubtitle);
  String description(AppI18n i18n) =>
      pickUiText(i18n, zh: zhDescription, en: enDescription);
  String footer(AppI18n i18n) => pickUiText(i18n, zh: footerZh, en: footerEn);
}

class _TrackLabelPair {
  const _TrackLabelPair({required this.zh, required this.en});

  final String zh;
  final String en;
}

class _SoothingTrack {
  const _SoothingTrack({
    required this.assetPath,
    required this.zhLabel,
    required this.enLabel,
    required this.seed,
  });

  final String assetPath;
  final String zhLabel;
  final String enLabel;
  final int seed;

  String label(AppI18n i18n) => zhLabel;
}

class _SoothingRuntimeStore {
  static Set<String> favoriteModeIds = <String>{};
  static List<String> recentModeIds = <String>[];
  static Map<String, int> lastTrackIndexByMode = <String, int>{};
  static String? lastModeId;
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
    required AppThemeTokens tokens,
    required AppearanceConfig appearance,
    required _SoothingModeTheme mode,
  }) {
    final gradientStrength =
        0.18 +
        appearance.normalizedGradientIntensity * (tokens.isDark ? 0.44 : 0.28);
    final effectStrength =
        0.34 +
        appearance.normalizedEffectIntensity * (tokens.isDark ? 0.9 : 0.7);
    final accent = Color.lerp(tokens.accent, mode.accent, 0.58)!;
    final orbitAccent = Color.lerp(tokens.accentSoft, mode.orbitAccent, 0.8)!;
    final backgroundTop = Color.lerp(
      tokens.canvas,
      mode.backgroundA,
      tokens.isDark
          ? 0.72 + gradientStrength * 0.14
          : 0.14 + gradientStrength * 0.16,
    )!;
    final backgroundBottom = Color.lerp(
      tokens.canvas,
      mode.backgroundB,
      tokens.isDark
          ? 0.86 + gradientStrength * 0.08
          : 0.18 + gradientStrength * 0.14,
    )!;
    final panelSurface = Color.lerp(
      tokens.surfaceOverlay,
      backgroundTop,
      tokens.isDark
          ? 0.34 + effectStrength * 0.08
          : 0.08 + effectStrength * 0.04,
    )!.withValues(alpha: tokens.isDark ? 0.93 : 0.94);
    final panelSurfaceMuted = Color.lerp(
      tokens.surfaceMuted,
      backgroundBottom,
      tokens.isDark ? 0.26 : 0.06,
    )!.withValues(alpha: tokens.isDark ? 0.9 : 0.96);
    final controlSurface = Color.lerp(
      tokens.surfaceStrong,
      backgroundBottom,
      tokens.isDark ? 0.3 : 0.08,
    )!.withValues(alpha: tokens.isDark ? 0.94 : 0.97);
    final border = Color.lerp(
      tokens.outline,
      accent,
      tokens.isDark ? 0.24 : 0.16,
    )!;
    final textPrimary = tokens.isDark
        ? Color.lerp(tokens.textPrimary, Colors.white, 0.12)!
        : Color.lerp(tokens.textPrimary, const Color(0xFF0E2436), 0.14)!;
    final textSecondary = tokens.isDark
        ? Color.lerp(tokens.textSecondary, Colors.white, 0.04)!
        : Color.lerp(tokens.textSecondary, const Color(0xFF4D677B), 0.12)!;

    return _SoothingVisualPalette(
      isDark: tokens.isDark,
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
      dangerBg: Color.lerp(tokens.danger, backgroundBottom, 0.72)!,
      dangerFg: Color.lerp(tokens.danger, Colors.white, 0.72)!,
    );
  }
}

class _SoothingMusicV2PageState extends State<SoothingMusicV2Page>
    with SingleTickerProviderStateMixin {
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
    final labels =
        _trackLabelsByMode[modeId] ??
        const <_TrackLabelPair>[
          _TrackLabelPair(zh: '默认曲目', en: 'Default track'),
        ];
    return List<_SoothingTrack>.generate(labels.length, (index) {
      final number = index + 1;
      final suffix = number == 1 ? '' : '$number';
      final label = labels[index];
      return _SoothingTrack(
        assetPath: 'music/$modeId$suffix.m4a',
        zhLabel: label.zh,
        enLabel: label.en,
        seed: (modeId.hashCode.abs() % 97) + number * 31,
      );
    }, growable: false);
  }

  final AudioPlayer _player = AudioPlayer();
  late final AnimationController _orbitController;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  Timer? _sleepTimer;

  _SoothingModeTheme _mode = _modes[1];
  _ModeLibraryFilter _modeFilter = _ModeLibraryFilter.all;
  SoothingSceneAudio? _scene;
  int _trackIndex = 0;
  bool _playing = false;
  bool _muted = false;
  bool _loading = false;
  double _volume = 0.62;
  double? _draggingRatio;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 2);
  Duration? _sleepRemaining;
  String? _audioErrorLabelZh;
  String? _audioErrorLabelEn;
  final Map<String, Uint8List> _trackBytesCache = <String, Uint8List>{};

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _positionSubscription = _player.onPositionChanged.listen((value) {
      if (!mounted) return;
      setState(() {
        _position = value;
      });
    });
    _durationSubscription = _player.onDurationChanged.listen((value) {
      if (!mounted || value.inMilliseconds <= 0) return;
      setState(() {
        _duration = value;
      });
    });
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final nextPlaying = state == PlayerState.playing;
      if (_playing == nextPlaying) return;
      setState(() {
        _playing = nextPlaying;
      });
      if (nextPlaying) {
        _orbitController.repeat();
      } else {
        _orbitController.stop();
      }
    });
    unawaited(_initAudio());
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _sleepTimer?.cancel();
    _orbitController.dispose();
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _initAudio() async {
    final prefs = await ToolboxSoothingPrefsService.load();
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
    _mode = _modes.firstWhere(
      (mode) => mode.id == _SoothingRuntimeStore.lastModeId,
      orElse: () => _mode,
    );
    _trackIndex = _restoredTrackIndexForMode(_mode.id);

    await _player.setAudioContext(_soothingAudioContext);
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_volume);
    await _preloadModeAssets(_mode.id);
    await _loadMode(_mode, autoplay: false);
    for (final mode in _modes.where((item) => item.id != _mode.id).take(2)) {
      unawaited(_preloadModeAssets(mode.id));
    }
  }

  Future<void> _preloadModeAssets(String modeId) async {
    for (final track in _tracksForMode(modeId)) {
      try {
        final data = await rootBundle.load(track.assetPath);
        _trackBytesCache[track.assetPath] = data.buffer.asUint8List();
      } catch (_) {
        // Ignore warmup failures.
      }
    }
  }

  List<_SoothingTrack> get _tracks => _tracksForMode(_mode.id);
  _SoothingTrack get _currentTrack => _tracks[_trackIndex];

  Future<void> _loadMode(
    _SoothingModeTheme mode, {
    required bool autoplay,
  }) async {
    final restoredTrackIndex = _restoredTrackIndexForMode(mode.id);
    setState(() {
      _mode = mode;
      _trackIndex = restoredTrackIndex;
      _loading = true;
      _position = Duration.zero;
      _draggingRatio = null;
      _clearAudioError();
    });

    try {
      final scene = await ToolboxSoothingAudioService.load(mode.id);
      final track = _tracksForMode(mode.id)[restoredTrackIndex];
      final bytes =
          _trackBytesCache[track.assetPath] ??
          (await rootBundle.load(track.assetPath)).buffer.asUint8List();
      _trackBytesCache[track.assetPath] = bytes;
      await _player.setSourceBytes(bytes, mimeType: 'audio/mp4');
      await _player.setVolume(_muted ? 0 : _volume);
      if (autoplay) {
        await _player.resume();
      } else {
        await _player.stop();
      }
      if (!mounted) return;
      setState(() {
        _scene = scene;
      });
      _rememberRecent(mode.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _audioErrorLabelZh = mode.zhTitle;
        _audioErrorLabelEn = mode.enTitle;
      });
    } finally {
      if (mounted) {
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
      _orbitController.stop();
      return;
    }
    await _player.resume();
    _rememberRecent(_mode.id);
    _orbitController.repeat();
  }

  Future<void> _setMode(_SoothingModeTheme mode) async {
    if (_mode.id == mode.id && _scene != null) return;
    await _loadMode(mode, autoplay: _playing);
  }

  Future<void> _setTrackIndex(int index) async {
    if (index == _trackIndex) return;
    setState(() {
      _trackIndex = index;
      _loading = true;
      _position = Duration.zero;
      _draggingRatio = null;
      _clearAudioError();
    });

    try {
      final bytes =
          _trackBytesCache[_currentTrack.assetPath] ??
          (await rootBundle.load(_currentTrack.assetPath)).buffer.asUint8List();
      _trackBytesCache[_currentTrack.assetPath] = bytes;
      await _player.setSourceBytes(bytes, mimeType: 'audio/mp4');
      await _player.setVolume(_muted ? 0 : _volume);
      if (_playing) {
        await _player.resume();
      } else {
        await _player.stop();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _audioErrorLabelZh = _currentTrack.zhLabel;
        _audioErrorLabelEn = _currentTrack.enLabel;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }

    _SoothingRuntimeStore.lastTrackIndexByMode[_mode.id] = _trackIndex;
    _SoothingRuntimeStore.lastModeId = _mode.id;
    unawaited(_persistPrefs());
  }

  Future<void> _stepTrack(int delta) async {
    if (_tracks.length <= 1) return;
    final nextIndex = (_trackIndex + delta) % _tracks.length;
    await _setTrackIndex(
      nextIndex < 0 ? nextIndex + _tracks.length : nextIndex,
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
    unawaited(_persistPrefs());
  }

  Future<void> _setMuted(bool value) async {
    setState(() {
      _muted = value;
    });
    await _player.setVolume(value ? 0 : _volume);
  }

  Future<void> _setVolume(double value) async {
    setState(() {
      _volume = value;
    });
    if (!_muted) {
      await _player.setVolume(value);
    }
  }

  double get _progressRatio {
    if (_draggingRatio != null) return _draggingRatio!;
    final durationMs = _duration.inMilliseconds;
    if (durationMs <= 0) return 0;
    return (_position.inMilliseconds / durationMs).clamp(0.0, 1.0);
  }

  List<double> get _currentSpectrum {
    final frames = _scene?.spectrumFrames;
    final base = (frames == null || frames.isEmpty)
        ? const <double>[0.18, 0.22, 0.26, 0.24, 0.18, 0.14]
        : frames[(_progressRatio * (frames.length - 1)).round().clamp(
            0,
            frames.length - 1,
          )];
    final seed = _currentTrack.seed.toDouble();
    return List<double>.generate(base.length, (index) {
      final mod =
          math.sin(_progressRatio * math.pi * 6 + seed * 0.013 + index * 0.4) *
          0.08;
      return (base[index] + mod).clamp(0.04, 1.0);
    }, growable: false);
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

  int _restoredTrackIndexForMode(String modeId) {
    final tracks = _tracksForMode(modeId);
    final saved = _SoothingRuntimeStore.lastTrackIndexByMode[modeId] ?? 0;
    return saved.clamp(0, tracks.length - 1).toInt();
  }

  Future<void> _seekToRatio(double ratio) async {
    final durationMs = _duration.inMilliseconds;
    if (durationMs <= 0) return;
    await _player.seek(Duration(milliseconds: (durationMs * ratio).round()));
  }

  Future<void> _persistPrefs() {
    return ToolboxSoothingPrefsService.save(
      SoothingPrefsState(
        favoriteModeIds: _SoothingRuntimeStore.favoriteModeIds,
        recentModeIds: _SoothingRuntimeStore.recentModeIds,
        lastTrackIndexByMode: _SoothingRuntimeStore.lastTrackIndexByMode,
        lastModeId: _SoothingRuntimeStore.lastModeId,
      ),
    );
  }

  void _clearAudioError() {
    _audioErrorLabelZh = null;
    _audioErrorLabelEn = null;
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.toString();
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String? _audioErrorText(AppI18n i18n) {
    final zh = _audioErrorLabelZh;
    final en = _audioErrorLabelEn;
    if (zh == null || en == null) return null;
    return pickUiText(
      i18n,
      zh: '无法加载 $zh',
      en: 'Unable to load $en',
      ja: '$en を読み込めません',
      de: '$en konnte nicht geladen werden',
      fr: 'Impossible de charger $en',
      es: 'No se pudo cargar $en',
      ru: 'Не удалось загрузить $en',
    );
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
    final tokens = AppThemeTokens.of(context);
    final appearance = LegacyStyle.appearance;
    final palette = _SoothingVisualPalette.resolve(
      tokens: tokens,
      appearance: appearance,
      mode: _mode,
    );
    final effectBoost = 0.82 + appearance.normalizedEffectIntensity * 1.1;
    final waveBoost = 0.76 + appearance.normalizedGradientIntensity * 0.9;

    return Scaffold(
      backgroundColor: palette.backgroundBottom,
      appBar: AppBar(
        backgroundColor: palette.backgroundBottom,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: Text(_pageTitle(i18n)),
        actions: <Widget>[
          IconButton(
            tooltip: _sleepTimerButtonLabel(i18n),
            onPressed: () => _showSleepTimerSheet(context, i18n),
            icon: const Icon(Icons.timer_outlined),
          ),
        ],
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
          Row(
            children: <Widget>[
              Expanded(
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
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: () =>
                    _showModeSheet(context, i18n, palette: palette),
                icon: const Icon(Icons.tune_rounded),
                label: Text(_modesButtonLabel(i18n)),
              ),
            ],
          ),
          if (_sleepRemaining != null) ...<Widget>[
            const SizedBox(height: 10),
            _InfoPill(
              icon: Icons.timer_outlined,
              label: _activeSleepTimerLabel(i18n, _sleepRemaining!),
              palette: palette,
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
            _pageTitle(i18n),
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _pageSubtitle(i18n),
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
              label: _activeSleepTimerLabel(i18n, _sleepRemaining!),
              palette: palette,
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
            _emptyModeTitle(i18n, filter),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _emptyModeSubtitle(i18n, filter),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onReset,
            child: Text(_showAllModesLabel(i18n)),
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
              label: _modeFilterLabel(i18n, value),
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
                                  _activeModeLabel(i18n),
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
                      label: _trackCountLabel(i18n, trackCount),
                      palette: palette,
                      dense: true,
                      accent: tileAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: _favoriteToggleLabel(i18n),
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
    final bands = _currentSpectrum;

    return Column(
      children: <Widget>[
        _buildTrackShelf(i18n, palette: palette, compact: compact),
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.08),
                      radius: 0.96,
                      colors: <Color>[
                        palette.glowA.withValues(
                          alpha: palette.isDark ? 0.3 : 0.16,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: compact ? -54 : 72,
                top: compact ? 70 : 90,
                child: _GlowBlob(
                  color: palette.glowA,
                  size: compact ? 190 : 250,
                ),
              ),
              Positioned(
                right: compact ? -38 : 112,
                top: compact ? 86 : 66,
                child: _GlowBlob(
                  color: palette.glowB,
                  size: compact ? 180 : 236,
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _orbitController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SoothingSpectrumPainter(
                        accent: palette.accent,
                        orbitAccent: palette.orbitAccent,
                        phase: _orbitController.value * math.pi * 2,
                        bands: bands,
                        barGain:
                            (_mode.id == 'motion'
                                ? 1
                                : _mode.id == 'study' || _mode.id == 'jazz'
                                ? 0.82
                                : 0.56) *
                            effectBoost,
                        particleGain:
                            (_mode.id == 'dreaming'
                                ? 1
                                : _mode.id == 'motion'
                                ? 0.9
                                : _mode.id == 'sleep'
                                ? 0.35
                                : 0.6) *
                            effectBoost,
                        breathingGain:
                            (_mode.id == 'sleep'
                                ? 1
                                : _mode.id == 'music_box' || _mode.id == 'harp'
                                ? 0.86
                                : 0.62) *
                            waveBoost,
                        rippleGain: waveBoost,
                        waveGain:
                            (0.84 + effectBoost * 0.26) *
                            (_mode.id == 'dreaming' ? 1.1 : 1),
                        compact: compact,
                        isDark: palette.isDark,
                      ),
                      child: LayoutBuilder(
                        builder: (context, stageConstraints) {
                          final cramped = stageConstraints.maxHeight < 250;
                          final veryCramped = stageConstraints.maxHeight < 180;
                          return Center(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 24 : 56,
                                vertical: veryCramped ? 8 : 18,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: compact ? 460 : 520,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      _mode.title(i18n),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: palette.textPrimary,
                                        fontSize: veryCramped
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
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.panelSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: palette.accent.withValues(
                                            alpha: 0.54,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        _currentTrack.label(i18n),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: palette.accent,
                                          fontSize: narrow ? 12 : 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (!cramped) ...<Widget>[
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
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        _buildBottomControls(context, i18n, palette: palette, compact: compact),
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
                label: _trackCountLabel(i18n, _tracks.length),
                palette: palette,
              ),
              if (_sleepRemaining != null)
                _InfoPill(
                  icon: Icons.timer_outlined,
                  label: _activeSleepTimerLabel(i18n, _sleepRemaining!),
                  palette: palette,
                  accent: palette.orbitAccent,
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
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
        color: palette.controlSurface,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, compact ? 10 : 14, 18, 10),
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
              final stacked = compact || constraints.maxWidth < 1000;

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
                    tooltip: _volumeToggleLabel(i18n),
                    onPressed: () => _setMuted(!_muted),
                    icon: Icon(
                      _muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: palette.textSecondary,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: narrow
                          ? 96
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
                    tooltip: _previousTrackLabel(i18n),
                    icon: Icons.skip_previous_rounded,
                    palette: palette,
                    compact: stacked,
                    onPressed: _tracks.length > 1 ? () => _stepTrack(-1) : null,
                  ),
                  SizedBox(width: stacked ? 4 : 8),
                  FilledButton(
                    onPressed: _togglePlayback,
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.isDark
                          ? const Color(0xFF051C2B)
                          : const Color(0xFF082337),
                      minimumSize: Size(stacked ? 54 : 70, stacked ? 54 : 70),
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
                            size: stacked ? 26 : 34,
                          ),
                  ),
                  SizedBox(width: stacked ? 4 : 8),
                  _TransportIconButton(
                    tooltip: _nextTrackLabel(i18n),
                    icon: Icons.skip_next_rounded,
                    palette: palette,
                    compact: stacked,
                    onPressed: _tracks.length > 1 ? () => _stepTrack(1) : null,
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
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _draggingRatio = value;
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
                    maxLines: narrow ? 2 : 1,
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
                        Row(
                          children: <Widget>[
                            Expanded(child: volumeControl),
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
                  final label = _sleepTimerOptionLabel(i18n, value);
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
                        _browseModesTitle(i18n),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _browseModesSubtitle(i18n),
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
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final _SoothingVisualPalette palette;

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
                color: palette.textSecondary,
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
  const _SoothingSpectrumPainter({
    required this.accent,
    required this.orbitAccent,
    required this.phase,
    required this.bands,
    required this.barGain,
    required this.particleGain,
    required this.breathingGain,
    required this.rippleGain,
    required this.waveGain,
    required this.compact,
    required this.isDark,
  });

  final Color accent;
  final Color orbitAccent;
  final double phase;
  final List<double> bands;
  final double barGain;
  final double particleGain;
  final double breathingGain;
  final double rippleGain;
  final double waveGain;
  final bool compact;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final shortest = math.min(size.width, size.height);
    final compactBoost = compact ? 1.16 : 1.0;
    final innerRadius = shortest * (compact ? 0.17 : 0.14);
    final energy =
        bands.fold<double>(0, (sum, item) => sum + item) / bands.length;

    _drawWaveRibbon(
      canvas,
      size,
      center,
      color: accent.withValues(alpha: isDark ? 0.2 : 0.14),
      phase: phase,
      amplitude: shortest * 0.034 * waveGain,
      verticalOffset: -shortest * 0.06,
      direction: 1,
    );
    _drawWaveRibbon(
      canvas,
      size,
      center,
      color: orbitAccent.withValues(alpha: isDark ? 0.16 : 0.12),
      phase: phase + 1.6,
      amplitude: shortest * 0.028 * waveGain,
      verticalOffset: shortest * 0.08,
      direction: -1,
    );

    for (var ring = 0; ring < 3; ring += 1) {
      final progress = ((phase / (math.pi * 2)) + ring * 0.32) % 1;
      final radius =
          innerRadius * (1.04 + progress * (1.75 + rippleGain * 0.18));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withValues(
            alpha: (1 - progress) * (isDark ? 0.12 : 0.08) * rippleGain,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = compact ? 1.6 : 2.1,
      );
    }

    for (
      var i = 0;
      i < (10 + particleGain * 24 * compactBoost).round();
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
        1.3 + (i % 3) * 0.8,
        Paint()
          ..color = orbitAccent.withValues(
            alpha: (0.08 + (i % 5) * 0.03).clamp(0.08, 0.28),
          ),
      );
    }

    for (var i = 0; i < (6 + particleGain * 14).round(); i += 1) {
      final drift = phase * 1.24 + i * 1.34;
      final radius =
          innerRadius * (0.72 + (i % 4) * 0.18 + math.sin(drift) * 0.08);
      final point = Offset(
        center.dx + math.cos(drift) * radius,
        center.dy + math.sin(drift * 0.9) * radius,
      );
      canvas.drawCircle(
        point,
        1.8 + (i % 2) * 0.6,
        Paint()..color = accent.withValues(alpha: isDark ? 0.24 : 0.16),
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
    for (var i = 0; i < bands.length; i += 1) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / bands.length);
      final amplitude = bands[i];
      final length =
          (18 + amplitude * shortest * 0.064 * barGain * compactBoost)
              .toDouble();
      final barWidth = 4.6 + barGain * 1.8;
      final barCenter = Offset(
        center.dx + math.cos(angle) * (innerRadius * 2.16 + length * 0.5),
        center.dy + math.sin(angle) * (innerRadius * 2.16 + length * 0.5),
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
              accent.withValues(alpha: 0.12 + energy * 0.12),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: innerRadius * 2.2),
          );
    canvas.drawCircle(center, innerRadius * 1.8, glowPaint);

    for (var ring = 0; ring < 5; ring += 1) {
      final breath =
          1 +
          math.sin(phase * (0.7 + ring * 0.1) + ring) * 0.035 * breathingGain;
      final radius = innerRadius * (1.68 + ring * 0.35) * breath;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withValues(alpha: 0.018 * (5 - ring))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18,
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
      bands: bands.reversed.toList(growable: false),
      direction: -1,
    );
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
      ..strokeWidth = compact ? 2.2 : 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
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
  }) {
    final path = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i += 1) {
      final t = i / steps;
      final angle = t * math.pi * 2;
      final bandIndex = ((t * bands.length).floor()).clamp(0, bands.length - 1);
      final band = bands[bandIndex];
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
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SoothingSpectrumPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.accent != accent ||
        oldDelegate.orbitAccent != orbitAccent ||
        oldDelegate.bands != bands ||
        oldDelegate.barGain != barGain ||
        oldDelegate.particleGain != particleGain ||
        oldDelegate.breathingGain != breathingGain ||
        oldDelegate.rippleGain != rippleGain ||
        oldDelegate.waveGain != waveGain ||
        oldDelegate.compact != compact ||
        oldDelegate.isDark != isDark;
  }
}
