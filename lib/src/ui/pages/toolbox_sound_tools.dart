import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_audio_service.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'toolbox_tool_shell.dart';

part 'toolbox_sound_tools/deck.dart';
part 'toolbox_sound_tools/soothing.dart';
part 'toolbox_sound_tools/harp.dart';
part 'toolbox_sound_tools/focus.dart';
part 'toolbox_sound_tools/models.dart';
part 'toolbox_sound_tools/piano.dart';
part 'toolbox_sound_tools/flute.dart';
part 'toolbox_sound_tools/drum_pad.dart';
part 'toolbox_sound_tools/guitar.dart';
part 'toolbox_sound_tools/triangle.dart';
part 'toolbox_sound_tools/violin.dart';

AppI18n _toolboxI18n(BuildContext context, {bool listen = true}) {
  final state = listen
      ? context.watch<AppState?>()
      : Provider.of<AppState?>(context, listen: false);
  final language =
      state?.uiLanguage ?? Localizations.localeOf(context).languageCode;
  return AppI18n(language);
}

const List<DeviceOrientation> _toolboxAllOrientations = <DeviceOrientation>[
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

bool _supportsMobileOrientationLock() {
  return Platform.isAndroid || Platform.isIOS;
}

Future<void> _enterToolboxLandscapeMode() async {
  await _enterToolboxImmersiveMode(
    orientations: const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  );
}

Future<void> _enterToolboxPortraitMode() async {
  await _enterToolboxImmersiveMode(
    orientations: const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );
}

Future<void> _enterToolboxImmersiveMode({
  List<DeviceOrientation>? orientations,
}) async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  if (_supportsMobileOrientationLock() && orientations != null) {
    await SystemChrome.setPreferredOrientations(orientations);
  }
}

Future<void> _exitToolboxLandscapeMode() async {
  if (_supportsMobileOrientationLock()) {
    await SystemChrome.setPreferredOrientations(_toolboxAllOrientations);
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

Widget _buildInstrumentPanelShell(
  BuildContext context, {
  required bool fullScreen,
  required Widget child,
}) {
  final content = Padding(
    padding: EdgeInsets.all(fullScreen ? 14 : 18),
    child: child,
  );
  if (!fullScreen) {
    return Card(child: content);
  }
  final viewPadding = MediaQuery.viewPaddingOf(context);
  final minHeight =
      MediaQuery.sizeOf(context).height -
      viewPadding.top -
      viewPadding.bottom -
      28;
  return DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF020617),
          Color(0xFF0F172A),
          Color(0xFF111827),
        ],
      ),
    ),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(0, minHeight)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: content,
          ),
        ),
      ),
    ),
  );
}
