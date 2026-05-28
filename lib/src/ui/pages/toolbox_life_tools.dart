import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:kinship_calculator/kinship_calculator.dart' as kinship;
import 'package:locale_names/locale_names.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pinyin/pinyin.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/app_i18n.dart';
import '../../models/todo_item.dart';
import '../../services/app_log_service.dart';
import '../../services/toolbox_ai_interview_service.dart';
import '../../services/toolbox_fake_call_service.dart';
import '../../services/toolbox_life_notify_service.dart';
import '../../services/toolbox_meme_service.dart';
import '../../services/toolbox_bmi_service.dart';
import '../../services/toolbox_date_calculator_service.dart';
import '../../services/toolbox_image_to_web_service.dart';
import '../../services/toolbox_id_photo_service.dart';
import '../../services/toolbox_number_mark_service.dart';
import '../../services/toolbox_offer_select_service.dart';
import '../../services/toolbox_qr_service.dart';
import '../../services/toolbox_short_link_service.dart';
import '../../services/toolbox_city_compare_service.dart';
import '../../services/toolbox_mortgage_service.dart';
import '../../services/toolbox_work_worth_service.dart';
import '../../services/toolbox_world_clock_service.dart';
import '../../services/todo_reminder_service.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'toolbox_tool_shell.dart';

part 'toolbox_life_tools/toolbox_life_tools_hub.dart';
part 'toolbox_life_tools/toolbox_life_tools_shared.dart';
part 'toolbox_life_tools/toolbox_life_tools_time_screen.dart';
part 'toolbox_life_tools/toolbox_life_tools_time_screen_flip.dart';
part 'toolbox_life_tools/toolbox_life_tools_barrage.dart';
part 'toolbox_life_tools/toolbox_life_tools_display.dart';
part 'toolbox_life_tools/toolbox_life_tools_scoreboard.dart';
part 'toolbox_life_tools/toolbox_life_tools_scoreboard_shared.dart';
part 'toolbox_life_tools/toolbox_life_tools_scoreboard_dual.dart';
part 'toolbox_life_tools/toolbox_life_tools_scoreboard_immersive.dart';
part 'toolbox_life_tools/toolbox_life_tools_scoreboard_mixed.dart';
part 'toolbox_life_tools/toolbox_life_tools_color_models.dart';
part 'toolbox_life_tools/toolbox_life_tools_color_widgets.dart';
part 'toolbox_life_tools/toolbox_life_tools_color.dart';
part 'toolbox_life_tools/toolbox_life_tools_compass.dart';
part 'toolbox_life_tools/toolbox_life_tools_level.dart';
part 'toolbox_life_tools/toolbox_life_tools_vibration.dart';
part 'toolbox_life_tools/toolbox_life_tools_wallpaper_cache.dart';
part 'toolbox_life_tools/toolbox_life_tools_wallpaper.dart';
part 'toolbox_life_tools/toolbox_life_tools_garbage.dart';
part 'toolbox_life_tools/toolbox_life_tools_postal.dart';
part 'toolbox_life_tools/toolbox_life_tools_reverse_image.dart';
part 'toolbox_life_tools/toolbox_life_tools_text_counter.dart';
part 'toolbox_life_tools/toolbox_life_tools_text_transform.dart';
part 'toolbox_life_tools/toolbox_life_tools_work_worth.dart';
part 'toolbox_life_tools/toolbox_life_tools_offer_select.dart';
part 'toolbox_life_tools/toolbox_life_tools_mortgage.dart';
part 'toolbox_life_tools/toolbox_life_tools_city_compare.dart';
part 'toolbox_life_tools/toolbox_life_tools_timeline_periodic_data.dart';
part 'toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_premodern_data.dart';
part 'toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_dense_modern_data.dart';
part 'toolbox_life_tools/toolbox_life_tools_timeline_periodic_history_data.dart';
part 'toolbox_life_tools/toolbox_life_tools_timeline_periodic.dart';
part 'toolbox_life_tools/toolbox_life_tools_short_link.dart';
part 'toolbox_life_tools/toolbox_life_tools_qr.dart';
part 'toolbox_life_tools/toolbox_life_tools_utilities.dart';
part 'toolbox_life_tools/toolbox_life_tools_device_frame_models.dart';
part 'toolbox_life_tools/toolbox_life_tools_device_frame_labels.dart';
part 'toolbox_life_tools/toolbox_life_tools_device_frame_preview.dart';
part 'toolbox_life_tools/toolbox_life_tools_device_frame.dart';
part 'toolbox_life_tools/toolbox_life_tools_unit_converter.dart';
part 'toolbox_life_tools/toolbox_life_tools_date_calculator.dart';
part 'toolbox_life_tools/toolbox_life_tools_bmi.dart';
part 'toolbox_life_tools/toolbox_life_tools_world_clock.dart';
part 'toolbox_life_tools/toolbox_life_tools_notify_me.dart';
part 'toolbox_life_tools/toolbox_life_tools_notify_me_widgets.dart';
part 'toolbox_life_tools/toolbox_life_tools_fake_call.dart';
part 'toolbox_life_tools/toolbox_life_tools_number_marks.dart';
part 'toolbox_life_tools/toolbox_life_tools_meme_maker.dart';
part 'toolbox_life_tools/toolbox_life_tools_image_compress.dart';
part 'toolbox_life_tools/toolbox_life_tools_image_upscale.dart';
part 'toolbox_life_tools/toolbox_life_tools_image_transform.dart';
part 'toolbox_life_tools/toolbox_life_tools_image_to_web.dart';
part 'toolbox_life_tools/toolbox_life_tools_id_photo.dart';
part 'toolbox_life_tools/toolbox_life_tools_relatives.dart';
part 'toolbox_life_tools/toolbox_life_tools_mind_map.dart';
part 'toolbox_life_tools/toolbox_life_tools_mind_map_canvas.dart';
part 'toolbox_life_tools/toolbox_life_tools_mind_map_fullscreen.dart';
part 'toolbox_life_tools/toolbox_life_tools_ai_interview.dart';

const MethodChannel _lifeDisplayChannel = MethodChannel(
  'vocabulary_sleep/life_display',
);
const MethodChannel _lifeDeviceChannel = MethodChannel(
  'vocabulary_sleep/life_device',
);

const List<DeviceOrientation> _lifeAllOrientations = <DeviceOrientation>[
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

Future<void> _setLifeScreenAwake({
  required bool enabled,
  double brightness = 1.0,
}) async {
  try {
    await _lifeDisplayChannel.invokeMethod<void>('setKeepScreenOn', {
      'enabled': enabled,
      'brightness': brightness.clamp(0.0, 1.0),
    });
  } on MissingPluginException {
    // Desktop/web test runners do not provide this channel.
  } on PlatformException {
    // Keep the immersive UI usable even if the platform rejects brightness.
  }
}

Future<Map<String, Object?>> _setLifeWallpaper({
  required String filePath,
  required String target,
}) async {
  try {
    final raw = await _lifeDisplayChannel.invokeMethod<Map<Object?, Object?>>(
      'setWallpaper',
      <String, Object?>{'filePath': filePath, 'target': target},
    );
    return raw == null
        ? <String, Object?>{'success': false, 'errorCode': 'failed'}
        : raw.map((key, value) => MapEntry(key.toString(), value));
  } on MissingPluginException {
    return <String, Object?>{'success': false, 'errorCode': 'unsupported'};
  } on PlatformException catch (error) {
    return <String, Object?>{
      'success': false,
      'errorCode': error.code,
      'errorMessage': error.message,
    };
  }
}

class _LifeVibrationCapability {
  const _LifeVibrationCapability({
    required this.platform,
    required this.hasVibrator,
    required this.supportsWaveform,
    required this.supportsAmplitudeControl,
  });

  final String platform;
  final bool hasVibrator;
  final bool supportsWaveform;
  final bool supportsAmplitudeControl;

  bool get isSupported =>
      hasVibrator || defaultTargetPlatform == TargetPlatform.iOS;

  static const _LifeVibrationCapability fallback = _LifeVibrationCapability(
    platform: 'fallback',
    hasVibrator: false,
    supportsWaveform: false,
    supportsAmplitudeControl: false,
  );
}

Future<_LifeVibrationCapability> _getLifeVibrationCapability() async {
  try {
    final raw = await _lifeDeviceChannel.invokeMethod<Map<Object?, Object?>>(
      'getVibrationCapability',
    );
    if (raw == null) {
      return _LifeVibrationCapability.fallback;
    }
    final capability = raw.map((key, value) => MapEntry(key.toString(), value));
    return _LifeVibrationCapability(
      platform: capability['platform'] as String? ?? 'unknown',
      hasVibrator: capability['hasVibrator'] as bool? ?? false,
      supportsWaveform: capability['supportsWaveform'] as bool? ?? false,
      supportsAmplitudeControl:
          capability['supportsAmplitudeControl'] as bool? ?? false,
    );
  } on MissingPluginException {
    return _LifeVibrationCapability.fallback;
  } on PlatformException {
    return _LifeVibrationCapability.fallback;
  }
}

Future<bool> _playLifeVibrationPattern({
  required List<int> timingsMs,
  required List<int> amplitudes,
}) async {
  try {
    final played = await _lifeDeviceChannel.invokeMethod<bool>(
      'playVibrationPattern',
      <String, Object?>{'timingsMs': timingsMs, 'amplitudes': amplitudes},
    );
    return played ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

Future<void> _cancelLifeVibration() async {
  try {
    await _lifeDeviceChannel.invokeMethod<void>('cancelVibration');
  } on MissingPluginException {
    // Tests and unsupported platforms can ignore this cleanup.
  } on PlatformException {
    // Best-effort stop only.
  }
}

Future<void> _enterLifeImmersive({
  required List<DeviceOrientation> orientations,
  double brightness = 1.0,
}) async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(orientations);
  await _setLifeScreenAwake(enabled: true, brightness: brightness);
}

Future<void> _enterLifeLandscapeImmersive({double brightness = 1.0}) async {
  await _enterLifeImmersive(
    orientations: const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    brightness: brightness,
  );
}

Future<void> _enterLifePortraitImmersive({double brightness = 1.0}) async {
  await _enterLifeImmersive(
    orientations: const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    brightness: brightness,
  );
}

Future<void> _exitLifeImmersive() async {
  await _setLifeScreenAwake(enabled: false);
  await SystemChrome.setPreferredOrientations(_lifeAllOrientations);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

String _lifeText(
  BuildContext context, {
  required String zh,
  required String en,
}) {
  final i18n = AppI18n(Localizations.localeOf(context).languageCode);
  return pickUiText(i18n, zh: zh, en: en);
}

class _LifeToolSource {
  const _LifeToolSource({
    required this.name,
    required this.url,
    this.copyrightNote = '',
  });

  final String name;
  final String url;
  final String copyrightNote;
}

class _LifeTool {
  const _LifeTool({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.summaryZh,
    required this.summaryEn,
    required this.category,
    required this.icon,
    this.sources = const <_LifeToolSource>[],
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final String summaryZh;
  final String summaryEn;
  final String category;
  final IconData icon;
  final List<_LifeToolSource> sources;
}

const List<_LifeTool> _lifeTools = <_LifeTool>[
  _LifeTool(
    id: 'time_screen',
    titleZh: '时间屏幕',
    titleEn: 'Time screen',
    summaryZh: '全屏方形翻页时钟',
    summaryEn: 'Fullscreen square flip clock',
    category: 'display',
    icon: Icons.access_time_rounded,
  ),
  _LifeTool(
    id: 'barrage',
    titleZh: '手持弹幕',
    titleEn: 'Handheld barrage',
    summaryZh: '可调字体、速度、颜色和方向的全屏弹幕',
    summaryEn: 'Configurable style and speed',
    category: 'display',
    icon: Icons.view_stream_rounded,
  ),
  _LifeTool(
    id: 'ruler',
    titleZh: '尺子和量角器',
    titleEn: 'Ruler and protractor',
    summaryZh: '支持屏幕标尺和量角器校准',
    summaryEn: 'Screen ruler and protractor view',
    category: 'device',
    icon: Icons.straighten_rounded,
  ),
  _LifeTool(
    id: 'scoreboard',
    titleZh: '记分牌',
    titleEn: 'Scoreboard',
    summaryZh: '双队计分和混合积分模式',
    summaryEn: 'Two-team and mixed points',
    category: 'display',
    icon: Icons.scoreboard_rounded,
  ),
  _LifeTool(
    id: 'color_helper',
    titleZh: '配色助手',
    titleEn: 'Color helper',
    summaryZh: '色卡和图片取色',
    summaryEn: 'Palette and image picker',
    category: 'image',
    icon: Icons.palette_rounded,
  ),
  _LifeTool(
    id: 'wallpaper_helper',
    titleZh: '壁纸助手',
    titleEn: 'Wallpaper helper',
    summaryZh: '按来源分类并支持搜索的壁纸助手',
    summaryEn: 'Source-based wallpaper helper',
    category: 'web',
    icon: Icons.wallpaper_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(name: 'Bing Wallpaper', url: 'https://www.bing.com'),
      _LifeToolSource(
        name: 'Anime Pictures',
        url: 'https://anime-pictures.net/',
      ),
      _LifeToolSource(name: 'Konachan', url: 'https://konachan.net/post'),
      _LifeToolSource(name: 'Wallhaven', url: 'https://wallhaven.cc/'),
    ],
  ),
  _LifeTool(
    id: 'postal_code',
    titleZh: '邮编查询',
    titleEn: 'Postal lookup',
    summaryZh: '常用城市/区县邮编速查',
    summaryEn: 'Common city and district ZIP lookup',
    category: 'web',
    icon: Icons.local_post_office_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'China Post public page',
        url: 'https://www.chinapost.com.cn/html1/folder/181312/9531-1.htm',
      ),
      _LifeToolSource(name: 'Youbianku', url: 'https://www.youbianku.com/'),
    ],
  ),
  _LifeTool(
    id: 'reverse_image',
    titleZh: '以图搜图',
    titleEn: 'Reverse image',
    summaryZh: '多引擎以图搜图入口',
    summaryEn: 'Multi-engine reverse image links',
    category: 'web',
    icon: Icons.image_search_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'Baidu image',
        url: 'https://graph.baidu.com/pcpage/index?tpl_from=pc',
      ),
      _LifeToolSource(name: 'Sogou image', url: 'https://pic.sogou.com/'),
      _LifeToolSource(name: 'Yandex Images', url: 'https://yandex.com/images/'),
      _LifeToolSource(name: 'Google Lens', url: 'https://lens.google.com/'),
    ],
  ),
  _LifeTool(
    id: 'garbage',
    titleZh: '垃圾分类查询',
    titleEn: 'Garbage sorting',
    summaryZh: '本地词库和分类投放提示',
    summaryEn: 'Local catalog and disposal hints',
    category: 'web',
    icon: Icons.recycling_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'QQ Browser tool',
        url: 'https://tool.browser.qq.com/garbage.html',
      ),
    ],
  ),
  _LifeTool(
    id: 'image_transform',
    titleZh: '图片压缩/扩大',
    titleEn: 'Image compression / upscale',
    summaryZh: '在同一工具内快速切换压缩与扩大，并提供更轻量的放大算法',
    summaryEn:
        'Switch quickly between compression and upscale with lighter upscale algorithms',
    category: 'image',
    icon: Icons.photo_size_select_large_rounded,
  ),
  _LifeTool(
    id: 'relatives',
    titleZh: '亲戚关系计算器',
    titleEn: 'Relative calculator',
    summaryZh: '本地亲戚称谓推算',
    summaryEn: 'Local relation chain hints',
    category: 'text',
    icon: Icons.groups_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'QQ Browser relatives',
        url: 'https://tool.browser.qq.com/relatives_name.html',
      ),
    ],
  ),
  _LifeTool(
    id: 'text_count',
    titleZh: '字数拆分与统计',
    titleEn: 'Text split and count',
    summaryZh: '统计字符并按规则拆分长文本',
    summaryEn: 'Count text and split long content',
    category: 'text',
    icon: Icons.calculate_rounded,
  ),
  _LifeTool(
    id: 'mind_map',
    titleZh: '简易思维导图',
    titleEn: 'Simple mind map',
    summaryZh: '创建节点关系并导出图片',
    summaryEn: 'Node and relation sketch',
    category: 'text',
    icon: Icons.account_tree_rounded,
  ),
  _LifeTool(
    id: 'timeline_periodic',
    titleZh: '历史年表/元素周期表',
    titleEn: 'Timeline and periodic table',
    summaryZh: '动态查看共识历史节点与 118 元素数据',
    summaryEn: 'Dynamic consensus timeline and 118-element data',
    category: 'study',
    icon: Icons.auto_graph_rounded,
    sources: _timelinePeriodicSources,
  ),
  _LifeTool(
    id: 'text_encoding',
    titleZh: '文本转换',
    titleEn: 'Text transform',
    summaryZh: '拼音简繁、数字、农历干支、语言代码与常用文本转换',
    summaryEn:
        'Pinyin, number, calendar, ganzhi, language code, and common text transforms',
    category: 'text',
    icon: Icons.lock_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'Toolg Mars text',
        url: 'https://www.toolg.cn/toolbox/hufont.html',
      ),
      _LifeToolSource(
        name: 'Toolg hidden text',
        url: 'https://www.toolg.cn/toolbox/txthidder.html',
      ),
      _LifeToolSource(
        name: 'Toolg vertical text',
        url: 'https://www.toolg.cn/toolbox/shutxt.html',
      ),
      _LifeToolSource(
        name: 'Toolg Bazi',
        url: 'https://www.toolg.cn/toolbox/bazi.html',
      ),
      _LifeToolSource(
        name: 'Toolg Bazi to date',
        url: 'https://www.toolg.cn/toolbox/bazi2date.html',
      ),
      _LifeToolSource(
        name: 'Toolg Jiazi table',
        url: 'https://www.toolg.cn/toolbox/jiazitable.html',
      ),
      _LifeToolSource(
        name: 'Toolg language codes',
        url: 'https://www.toolg.cn/toolbox/langcodes.html',
      ),
    ],
  ),
  _LifeTool(
    id: 'compass',
    titleZh: '指南针',
    titleEn: 'Compass',
    summaryZh: '指南针表盘与方向指示',
    summaryEn: 'Compass dial panel',
    category: 'device',
    icon: Icons.explore_rounded,
  ),
  _LifeTool(
    id: 'level',
    titleZh: '水平仪',
    titleEn: 'Level meter',
    summaryZh: '横竖方向水平校准辅助',
    summaryEn: 'Horizontal and vertical helper',
    category: 'device',
    icon: Icons.horizontal_split_rounded,
  ),
  _LifeTool(
    id: 'vibration',
    titleZh: '震动仪',
    titleEn: 'Vibration tool',
    summaryZh: '按强度、时长和节奏控制震动',
    summaryEn: 'Rhythm and duration pattern',
    category: 'device',
    icon: Icons.vibration_rounded,
  ),
  _LifeTool(
    id: 'notify_me',
    titleZh: '通知自己',
    titleEn: 'Notify me',
    summaryZh: '定时提醒自己，并同步到状态栏、锁屏和系统日历',
    summaryEn:
        'Schedule self-reminders with notifications, lock-screen alerts, and calendar sync',
    category: 'device',
    icon: Icons.notifications_active_rounded,
  ),
  _LifeTool(
    id: 'fake_call',
    titleZh: '模拟来电',
    titleEn: 'Fake incoming call',
    summaryZh: '定时或倒计时触发全屏来电模拟，支持号码、归属地和标签',
    summaryEn: 'Schedule a full-screen fake incoming call with caller details',
    category: 'device',
    icon: Icons.call_rounded,
  ),
  _LifeTool(
    id: 'sup_sub',
    titleZh: '数字转标',
    titleEn: 'Super or subscript',
    summaryZh: '支持上标、下标、带圈、括号编号和反向还原',
    summaryEn: 'Convert text into number marks and normalize it back',
    category: 'text',
    icon: Icons.text_fields_rounded,
  ),
  _LifeTool(
    id: 'meme_maker',
    titleZh: '表情包制作',
    titleEn: 'Meme maker',
    summaryZh: '导入本地图片，叠加文案并导出 PNG 表情包',
    summaryEn: 'Import an image, add captions, and export a PNG meme',
    category: 'image',
    icon: Icons.mood_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'zhaoolee/ChineseBQB',
        url: 'https://github.com/zhaoolee/ChineseBQB',
        copyrightNote: '仅用于用户在线获取原版素材，不直接引入项目；国内访问 GitHub 可能较慢。',
      ),
    ],
  ),
  _LifeTool(
    id: 'device_frame',
    titleZh: '带壳截图',
    titleEn: 'Device frame shot',
    summaryZh: '生成带手机壳或状态栏的截图',
    summaryEn: 'Frame and status-bar overlay',
    category: 'image',
    icon: Icons.phone_iphone_rounded,
  ),
  _LifeTool(
    id: 'unit_converter',
    titleZh: '全能单位换算',
    titleEn: 'Unit converter',
    summaryZh: '长度、重量、温度等单位换算',
    summaryEn: 'Length, weight, temp and more',
    category: 'calc',
    icon: Icons.swap_horiz_rounded,
  ),
  _LifeTool(
    id: 'work_worth',
    titleZh: '工作性价比计算器',
    titleEn: 'Work value calculator',
    summaryZh: '综合收入、生活开销和健康因子',
    summaryEn: 'Income, cost and health factor',
    category: 'calc',
    icon: Icons.work_history_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'worth-calculator',
        url: 'https://github.com/zippland/worth-calculator',
      ),
      _LifeToolSource(
        name: 'worthjob web',
        url: 'https://worthjob.zippland.com/',
      ),
    ],
  ),
  _LifeTool(
    id: 'city_compare',
    titleZh: '城市薪资对比工具',
    titleEn: 'City salary compare',
    summaryZh: '城市收入和生活成本对比',
    summaryEn: 'City income and cost compare',
    category: 'calc',
    icon: Icons.location_city_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'city_compare',
        url: 'https://github.com/Zippland/city_compare',
      ),
      _LifeToolSource(
        name: 'citycompare web',
        url: 'https://citycompare.zippland.com/',
      ),
      _LifeToolSource(
        name: 'Numbeo common data',
        url: 'https://www.numbeo.com/common/',
        copyrightNote: '参考项目 README 中声明的公开数据来源。',
      ),
    ],
  ),
  _LifeTool(
    id: 'mortgage',
    titleZh: '房贷计算器',
    titleEn: 'Mortgage calculator',
    summaryZh: '等额本息和等额本金计算',
    summaryEn: 'Amortized and equal principal',
    category: 'calc',
    icon: Icons.home_work_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'fangdaijisuanqi',
        url: 'https://www.fangdaijisuanqi.com/',
      ),
    ],
  ),
  _LifeTool(
    id: 'date_calculator',
    titleZh: '日期计算器',
    titleEn: 'Date calculator',
    summaryZh: '时间差与阶段剩余计算',
    summaryEn: 'Date diff and life progress',
    category: 'calc',
    icon: Icons.date_range_rounded,
  ),
  _LifeTool(
    id: 'world_clock',
    titleZh: '世界时钟',
    titleEn: 'World clock',
    summaryZh: '常用城市当前时间、本地时差和办公时段速查',
    summaryEn: 'Current time, local difference, and business-hours lookup',
    category: 'calc',
    icon: Icons.public_rounded,
  ),
  _LifeTool(
    id: 'bmi',
    titleZh: 'BMI 计算器',
    titleEn: 'BMI calculator',
    summaryZh: '成人/儿童青少年 BMI、围度和能量估算',
    summaryEn: 'Adult/youth BMI, waist metrics, and energy estimates',
    category: 'calc',
    icon: Icons.monitor_weight_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'WHO obesity and overweight',
        url:
            'https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight',
      ),
      _LifeToolSource(
        name: 'CDC adult BMI categories',
        url: 'https://www.cdc.gov/bmi/adult-calculator/bmi-categories.html',
      ),
      _LifeToolSource(
        name: 'CDC child and teen BMI categories',
        url:
            'https://www.cdc.gov/bmi/child-teen-calculator/bmi-categories.html',
      ),
      _LifeToolSource(
        name: 'CDC BMI-for-age LMS data',
        url: 'https://www.cdc.gov/growthcharts/data/zscore/bmiagerev.csv',
      ),
      _LifeToolSource(
        name: 'WS/T 428-2013 adult weight criteria',
        url:
            'https://www.nhc.gov.cn/ewebeditor/uploadfile/2013/08/20130808135715967.pdf',
      ),
      _LifeToolSource(
        name: 'Mifflin-St Jeor REE equation',
        url: 'https://pubmed.ncbi.nlm.nih.gov/2305711/',
      ),
      _LifeToolSource(
        name: 'NICE waist-to-height guidance',
        url: 'https://www.nice.org.uk/guidance/ng246/chapter/Recommendations',
      ),
    ],
  ),
  _LifeTool(
    id: 'image_to_web',
    titleZh: '图片转网页',
    titleEn: 'Image to webpage',
    summaryZh: '生成单文件图片网页，并可上传到 Uguu 临时分享',
    summaryEn: 'Generate a single-file image page and share via Uguu',
    category: 'image',
    icon: Icons.web_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'Vim-cn/elimage',
        url: 'https://github.com/Vim-cn/elimage',
        copyrightNote: '作为图片上传服务形态参考；本页落地为本地 HTML 生成和 Uguu 临时分享。',
      ),
      _LifeToolSource(
        name: 'Uguu API',
        url: 'https://uguu.se/api',
        copyrightNote: '第三方临时文件上传服务，当前公开站 FAQ 声明文件约 3 小时后删除。',
      ),
    ],
  ),
  _LifeTool(
    id: 'short_link',
    titleZh: '短链接生成与还原',
    titleEn: 'Short link tool',
    summaryZh: '多服务短链、本地短码与重定向链路还原',
    summaryEn: 'Multi-service short links, local aliases, and redirect restore',
    category: 'web',
    icon: Icons.link_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(name: 'TinyURL API', url: 'https://tinyurl.com/app/dev'),
      _LifeToolSource(name: 'is.gd API', url: 'https://is.gd/developers.php'),
      _LifeToolSource(name: 'v.gd API', url: 'https://v.gd/developers.php'),
      _LifeToolSource(name: 'CleanURI API', url: 'https://cleanuri.com/docs'),
    ],
  ),
  _LifeTool(
    id: 'qr',
    titleZh: '二维码生成',
    titleEn: 'QR generator',
    summaryZh: '模板、样式、图片二维码化与多种二维编码标准',
    summaryEn: 'Templates, styles, image QR, and multiple 2D code standards',
    category: 'web',
    icon: Icons.qr_code_2_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'qr_flutter',
        url: 'https://pub.dev/packages/qr_flutter',
      ),
      _LifeToolSource(
        name: 'barcode_widget',
        url: 'https://pub.dev/packages/barcode_widget',
      ),
    ],
  ),
  _LifeTool(
    id: 'id_photo',
    titleZh: '证件照生成',
    titleEn: 'ID photo',
    summaryZh: '本地裁切、换底色并导出常见证件照规格',
    summaryEn: 'Local crop, background color, and ID photo export',
    category: 'image',
    icon: Icons.badge_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'QQ Browser ID photo',
        url: 'https://tool.browser.qq.com/id_photo.html',
      ),
    ],
  ),
  _LifeTool(
    id: 'ai_interview',
    titleZh: 'AI 面试',
    titleEn: 'AI interview',
    summaryZh: '本地题目拆解、答案框架、追问与提示词草稿',
    summaryEn: 'Local interview practice, answer framing, follow-ups, prompts',
    category: 'study',
    icon: Icons.record_voice_over_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'Snap-Solver',
        url: 'https://github.com/Zippland/Snap-Solver/',
        copyrightNote: '参考其题目输入、多模型偏好和提示词配置思路；本页落地为本地练习工具，不实现屏幕捕获或实时代答。',
      ),
    ],
  ),
  _LifeTool(
    id: 'offer_select',
    titleZh: 'Offer 选择助手',
    titleEn: 'Offer selector',
    summaryZh: '多 Offer 本地评分、风险提示和谈薪追平测算',
    summaryEn: 'Local multi-offer scoring, risk checks, and negotiation anchor',
    category: 'calc',
    icon: Icons.checklist_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'OfferSelect',
        url: 'https://offerselect.zippland.com/',
      ),
      _LifeToolSource(
        name: 'worthjob web',
        url: 'https://worthjob.zippland.com/',
      ),
      _LifeToolSource(
        name: 'citycompare web',
        url: 'https://citycompare.zippland.com/',
      ),
      _LifeToolSource(
        name: 'Snap-Solver',
        url: 'https://github.com/Zippland/Snap-Solver/',
      ),
    ],
  ),
];
