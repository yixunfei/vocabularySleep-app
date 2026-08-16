import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/app_i18n.dart';
import '../../services/audio_player_source_helper.dart';
import '../../services/toolbox_content_media_codec_service.dart';
import '../../services/toolbox_crypto_extra_service.dart';
import '../../services/toolbox_crypto_service.dart';
import '../../services/toolbox_password_vault_service.dart';
import '../../services/toolbox_image_to_web_service.dart';
import '../../services/toolbox_steganography_service.dart';
import '../../services/toolbox_veracrypt_crypto.dart';
import '../../services/toolbox_veracrypt_service.dart';
import 'toolbox/toolbox_ui_components.dart';
import 'toolbox/toolbox_ui_tokens.dart';
import 'toolbox_tool_shell.dart';

part 'toolbox_crypto_security/toolbox_crypto_security_hub.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_shared.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_file_crypto.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_text_crypto.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_hash_check.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_hmac.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_asymmetric.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_key_files.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_passwords.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_password_vault.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_otp.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_shamir.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_content_media.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_content_media_stage.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_content_media_config.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_content_media_result.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_steganography.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_veracrypt.dart';
part 'toolbox_crypto_security/toolbox_crypto_security_veracrypt_widgets.dart';

String _lifeI18nText(
  BuildContext context,
  String key, {
  Map<String, Object?>? params,
}) {
  final i18n = AppI18n(Localizations.localeOf(context).languageCode);
  return i18n.t(key, params: params ?? const <String, Object?>{});
}
