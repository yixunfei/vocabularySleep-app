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
import '../../services/toolbox_i18n_text_ref.dart';
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
import '../layout/app_width_tier.dart';
import '../motion/app_motion.dart';
import '../widgets/back_intent_consumed_notification.dart';
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

String _lifeI18nText(
  BuildContext context,
  String key, {
  Map<String, Object?> params = const <String, Object?>{},
}) {
  final i18n = AppI18n(Localizations.localeOf(context).languageCode);
  return i18n.t(key, params: params);
}

String _lifeI18nRefText(BuildContext context, ToolboxI18nTextRef ref) {
  return _lifeI18nText(
    context,
    ref.key,
    params: _lifeResolveI18nParams(context, ref.params),
  );
}

Map<String, Object?> _lifeResolveI18nParams(
  BuildContext context,
  Map<String, Object?> params,
) {
  if (params.isEmpty) {
    return params;
  }
  return <String, Object?>{
    for (final entry in params.entries)
      entry.key: switch (entry.value) {
        final ToolboxI18nTextRef ref => _lifeI18nRefText(context, ref),
        _ => entry.value,
      },
  };
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
    required this.titleKey,
    required this.summaryKey,
    required this.category,
    required this.icon,
    this.sources = const <_LifeToolSource>[],
  });

  final String id;
  final String titleKey;
  final String summaryKey;
  final String category;
  final IconData icon;
  final List<_LifeToolSource> sources;
}

const List<_LifeTool> _lifeTools = <_LifeTool>[
  _LifeTool(
    id: 'time_screen',
    titleKey: 'inline.plan295.life.time_screen.62f5d9ae9d5d',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.fullscreen_square_flip_clock_16aab7',
    category: 'display',
    icon: Icons.access_time_rounded,
  ),
  _LifeTool(
    id: 'barrage',
    titleKey: 'inline.plan295.life.handheld_barrage.eb37eeab9e11',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.configurable_style_and_speed_4ce488',
    category: 'display',
    icon: Icons.view_stream_rounded,
  ),
  _LifeTool(
    id: 'ruler',
    titleKey: 'inline.plan295.life.ruler_and_protractor.34ba83f7ca22',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.screen_ruler_and_protractor_view_10b800',
    category: 'device',
    icon: Icons.straighten_rounded,
  ),
  _LifeTool(
    id: 'scoreboard',
    titleKey: 'inline.plan295.life.scoreboard.331767dc94ac',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.two_team_and_mixed_points_202bf7',
    category: 'display',
    icon: Icons.scoreboard_rounded,
  ),
  _LifeTool(
    id: 'color_helper',
    titleKey: 'inline.plan295.life.color_helper.10ac659af588',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.palette_and_image_picker_2df8cb',
    category: 'image',
    icon: Icons.palette_rounded,
  ),
  _LifeTool(
    id: 'wallpaper_helper',
    titleKey: 'inline.plan295.life.wallpaper_helper.bda912c53aec',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.source_based_wallpaper_helper_81133a',
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
    titleKey: 'inline.plan295.life.postal_lookup.1ce6c88311a4',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.common_city_and_district_zip_lookup_2bd81d',
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
    titleKey: 'inline.plan295.life.reverse_image.c5edca6a6947',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.multi_engine_reverse_image_links_588100',
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
    titleKey: 'inline.plan295.life.garbage_sorting.3e693c2be494',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.local_catalog_and_disposal_hints_ddab1a',
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
    titleKey: 'inline.plan295.life.image_compression_upscale.6a89f70da7a2',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.switch_quickly_between_compression_and_upscale_with_ligh_8f2b96',
    category: 'image',
    icon: Icons.photo_size_select_large_rounded,
  ),
  _LifeTool(
    id: 'relatives',
    titleKey: 'inline.plan295.life.relative_calculator.fc170b634aa5',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.local_relation_chain_hints_fa3a03',
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
    titleKey: 'inline.plan295.life.text_split_and_count.1f879ec08a67',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.count_text_and_split_long_content_b85a9d',
    category: 'text',
    icon: Icons.calculate_rounded,
  ),
  _LifeTool(
    id: 'mind_map',
    titleKey: 'inline.plan295.life.simple_mind_map.e5993d3e2573',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.node_and_relation_sketch_69973c',
    category: 'text',
    icon: Icons.account_tree_rounded,
  ),
  _LifeTool(
    id: 'timeline_periodic',
    titleKey: 'inline.plan295.life.timeline_and_periodic_table.a8ffb824aa25',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.dynamic_consensus_timeline_and_118_element_data_203811',
    category: 'study',
    icon: Icons.auto_graph_rounded,
    sources: _timelinePeriodicSources,
  ),
  _LifeTool(
    id: 'text_encoding',
    titleKey: 'inline.plan295.life.text_transform.9571d3b531bd',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.pinyin_number_calendar_ganzhi_language_code_and_common_t_eb56dd',
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
    titleKey: 'inline.plan295.life.compass.64c372418a25',
    summaryKey: 'literal.ui.pages.toolbox_life_tools.compass_dial_panel_9b44bd',
    category: 'device',
    icon: Icons.explore_rounded,
  ),
  _LifeTool(
    id: 'level',
    titleKey: 'inline.plan295.life.level_meter.12381487172b',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.horizontal_and_vertical_helper_df8e36',
    category: 'device',
    icon: Icons.horizontal_split_rounded,
  ),
  _LifeTool(
    id: 'vibration',
    titleKey: 'inline.plan295.life.vibration_tool.e1833c0d758f',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.rhythm_and_duration_pattern_c458ba',
    category: 'device',
    icon: Icons.vibration_rounded,
  ),
  _LifeTool(
    id: 'notify_me',
    titleKey: 'inline.plan295.life.notify_me.a1cb3fafbdd1',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.schedule_self_reminders_with_notifications_lock_screen_a_96e02b',
    category: 'device',
    icon: Icons.notifications_active_rounded,
  ),
  _LifeTool(
    id: 'fake_call',
    titleKey: 'inline.plan295.life.fake_incoming_call.a3cd1b946f9f',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.schedule_a_full_screen_fake_incoming_call_with_caller_de_adef9f',
    category: 'device',
    icon: Icons.call_rounded,
  ),
  _LifeTool(
    id: 'sup_sub',
    titleKey: 'inline.plan295.life.super_or_subscript.725857aea674',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.convert_text_into_number_marks_and_normalize_it_back_86e322',
    category: 'text',
    icon: Icons.text_fields_rounded,
  ),
  _LifeTool(
    id: 'meme_maker',
    titleKey: 'inline.plan295.life.meme_maker.b757bab40693',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.import_an_image_add_captions_and_export_a_png_meme_071f00',
    category: 'image',
    icon: Icons.mood_rounded,
    sources: <_LifeToolSource>[
      _LifeToolSource(
        name: 'zhaoolee/ChineseBQB',
        url: 'https://github.com/zhaoolee/ChineseBQB',
        copyrightNote: '在线获取原版素材，不直接引入项目。',
      ),
    ],
  ),
  _LifeTool(
    id: 'device_frame',
    titleKey: 'inline.plan295.life.device_frame_shot.e3a794041162',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.frame_and_status_bar_overlay_b389ee',
    category: 'image',
    icon: Icons.phone_iphone_rounded,
  ),
  _LifeTool(
    id: 'unit_converter',
    titleKey: 'inline.plan295.life.unit_converter.53644e92a340',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.length_weight_temp_and_more_79d354',
    category: 'calc',
    icon: Icons.swap_horiz_rounded,
  ),
  _LifeTool(
    id: 'work_worth',
    titleKey: 'inline.plan295.life.work_value_calculator.766dbe3047f2',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.income_cost_and_health_factor_a81081',
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
    titleKey: 'inline.plan295.life.city_salary_compare.0924c6268506',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.city_income_and_cost_compare_d06597',
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
    titleKey: 'inline.plan295.life.mortgage_calculator.3e4f4dddc3e6',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.amortized_and_equal_principal_178e28',
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
    titleKey: 'inline.plan295.life.date_calculator.20630c7c40d6',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.date_diff_and_life_progress_a40341',
    category: 'calc',
    icon: Icons.date_range_rounded,
  ),
  _LifeTool(
    id: 'world_clock',
    titleKey: 'inline.plan295.life.world_clock.8c72a17e8d79',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.current_time_local_difference_and_business_hours_lookup_b96eaa',
    category: 'calc',
    icon: Icons.public_rounded,
  ),
  _LifeTool(
    id: 'bmi',
    titleKey: 'inline.plan295.life.bmi_calculator.9086420041e2',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.adult_youth_bmi_waist_metrics_and_energy_estimates_1adb25',
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
    titleKey: 'inline.plan295.life.image_to_webpage.1ddd6465ce87',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.generate_a_single_file_image_page_and_share_via_uguu_68cd03',
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
    titleKey: 'inline.plan295.life.short_link_tool.001f0902e016',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.multi_service_short_links_local_aliases_and_redirect_res_261585',
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
    titleKey: 'inline.plan295.life.qr_generator.5f240db63805',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.templates_styles_image_qr_and_multiple_2d_code_standards_f0246c',
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
    titleKey: 'inline.plan295.life.id_photo.0d7cf4d70985',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.local_crop_background_color_and_id_photo_export_4d4767',
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
    titleKey: 'inline.plan295.life.ai_interview.0618cad69887',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.local_interview_practice_answer_framing_follow_ups_promp_93dc06',
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
    titleKey: 'inline.plan295.life.offer_selector.f837d5d3336b',
    summaryKey:
        'literal.ui.pages.toolbox_life_tools.local_multi_offer_scoring_risk_checks_and_negotiation_an_f8c251',
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
