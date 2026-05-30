import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_crypto_service.dart';
import '../../services/toolbox_steganography_service.dart';
import 'toolbox/toolbox_ui_components.dart';
import 'toolbox/toolbox_ui_tokens.dart';
import 'toolbox_tool_shell.dart';

part 'toolbox_crypto_security/toolbox_crypto_security_hub.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_shared.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_steganography.dart';

String _lifeI18nText(
  BuildContext context,
  String key, {
  Map<String, Object?>? params,
}) {
  final i18n = AppI18n(Localizations.localeOf(context).languageCode);
  return i18n.t(key, params: params ?? const <String, Object?>{});
}
