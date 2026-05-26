import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/app_i18n.dart';
import '../../services/app_log_service.dart';
import '../../services/toolbox_crypto_service.dart';
import '../../services/toolbox_steganography_service.dart';
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
part 'toolbox_life_tools/toolbox_life_tools_wallpaper_cache.dart';
part 'toolbox_life_tools/toolbox_life_tools_wallpaper.dart';
part 'toolbox_life_tools/toolbox_life_tools_garbage.dart';
part 'toolbox_life_tools/toolbox_life_tools_postal.dart';
part 'toolbox_life_tools/toolbox_life_tools_reverse_image.dart';
part 'toolbox_life_tools/toolbox_life_tools_utilities.dart';
part 'toolbox_life_tools/toolbox_life_tools_image_compress.dart';
part 'toolbox_life_tools/toolbox_life_tools_steganography.dart';
part 'toolbox_life_tools/toolbox_life_tools_relatives.dart';
part 'toolbox_life_tools/toolbox_life_tools_mind_map.dart';
part 'toolbox_life_tools/toolbox_life_tools_mind_map_canvas.dart';
part 'toolbox_life_tools/toolbox_life_tools_mind_map_fullscreen.dart';

const MethodChannel _lifeDisplayChannel = MethodChannel(
  'vocabulary_sleep/life_display',
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
    id: 'image_compress',
    titleZh: '图片压缩',
    titleEn: 'Image compression',
    summaryZh: '按尺寸和质量压缩图片',
    summaryEn: 'Resolution and ratio based compression',
    category: 'image',
    icon: Icons.compress_rounded,
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
    titleZh: '字数计算',
    titleEn: 'Text counter',
    summaryZh: '统计字符、符号和空白信息',
    summaryEn: 'Character and symbol statistics',
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
    summaryZh: '快速查看历史年表和元素周期表',
    summaryEn: 'Quick reference panel',
    category: 'study',
    icon: Icons.auto_graph_rounded,
  ),
  _LifeTool(
    id: 'text_encoding',
    titleZh: '文本编码',
    titleEn: 'Text encoding',
    summaryZh: '趣味编码、哈希和 Base64 转换',
    summaryEn: 'Fun encoding plus hash and base64',
    category: 'text',
    icon: Icons.lock_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'Shouyin reference',
        url: 'https://shouyinfanyi.com/',
      ),
    ],
  ),
  _LifeTool(
    id: 'steganography',
    titleZh: '图片/音频/视频隐写',
    titleEn: 'Steganography',
    summaryZh: '文本加密后写入多媒体内容',
    summaryEn: 'Hide encrypted text in image/audio/video',
    category: 'image',
    icon: Icons.hide_image_rounded,
  ),
  _LifeTool(
    id: 'rc4',
    titleZh: 'RC4 加密',
    titleEn: 'RC4 cipher',
    summaryZh: '基于密钥流的加密助手',
    summaryEn: 'Key-stream encryption helper',
    category: 'text',
    icon: Icons.vpn_key_rounded,
  ),
  _LifeTool(
    id: 'pinyin',
    titleZh: '中文转拼音',
    titleEn: 'Chinese to pinyin',
    summaryZh: '常用汉字转拼音',
    summaryEn: 'Phase-1 common-char mapping',
    category: 'text',
    icon: Icons.translate_rounded,
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
    summaryZh: '自定义提醒列表和通知模拟',
    summaryEn: 'In-app reminder queue',
    category: 'device',
    icon: Icons.notifications_active_rounded,
  ),
  _LifeTool(
    id: 'sup_sub',
    titleZh: '数字转标',
    titleEn: 'Super or subscript',
    summaryZh: '文本和数字转上标或下标',
    summaryEn: 'Transform numbers to marks',
    category: 'text',
    icon: Icons.text_fields_rounded,
  ),
  _LifeTool(
    id: 'meme_maker',
    titleZh: '表情包制作',
    titleEn: 'Meme maker',
    summaryZh: '导入图片并叠加文本',
    summaryEn: 'Import image and overlay text',
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
    id: 'bmi',
    titleZh: 'BMI 计算器',
    titleEn: 'BMI calculator',
    summaryZh: '计算 BMI 指数',
    summaryEn: 'Height and weight calculator',
    category: 'calc',
    icon: Icons.monitor_weight_rounded,
  ),
  _LifeTool(
    id: 'image_to_web',
    titleZh: '图片转网页',
    titleEn: 'Image to webpage',
    summaryZh: '把图片转换为网页预览',
    summaryEn: 'Pixel to HTML preview',
    category: 'image',
    icon: Icons.web_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'Vim-cn/elimage',
        url: 'https://github.com/Vim-cn/elimage',
      ),
    ],
  ),
  _LifeTool(
    id: 'short_link',
    titleZh: '短链接生成与还原',
    titleEn: 'Short link tool',
    summaryZh: '创建并解析短链接',
    summaryEn: 'Create and resolve short links',
    category: 'web',
    icon: Icons.link_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(name: 'TinyURL API', url: 'https://tinyurl.com/app/dev'),
    ],
  ),
  _LifeTool(
    id: 'qr',
    titleZh: '二维码生成',
    titleEn: 'QR generator',
    summaryZh: '输入内容生成二维码',
    summaryEn: 'Generate QR from text',
    category: 'web',
    icon: Icons.qr_code_2_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(name: 'goQR API', url: 'https://goqr.me/api/'),
    ],
  ),
  _LifeTool(
    id: 'id_photo',
    titleZh: '证件照生成',
    titleEn: 'ID photo',
    summaryZh: '在线证件照工具入口',
    summaryEn: 'ID photo online tool',
    category: 'web',
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
    summaryZh: '面试辅助入口',
    summaryEn: 'Interview helper link',
    category: 'web',
    icon: Icons.record_voice_over_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'Snap-Solver',
        url: 'https://github.com/Zippland/Snap-Solver/',
      ),
    ],
  ),
  _LifeTool(
    id: 'offer_select',
    titleZh: 'Offer 选择助手',
    titleEn: 'Offer selector',
    summaryZh: 'Offer 对比辅助入口',
    summaryEn: 'Offer compare helper link',
    category: 'web',
    icon: Icons.checklist_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'OfferSelect',
        url: 'https://offerselect.zippland.com/',
      ),
    ],
  ),
];
