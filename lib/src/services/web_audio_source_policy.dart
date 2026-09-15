import 'package:flutter/foundation.dart';

/// Browser-safe audio source policy. Native file sources are rejected rather
/// than being passed to a File/Directory implementation unavailable on Web.
class WebAudioSourcePolicy {
  const WebAudioSourcePolicy();

  bool acceptsAsset(String assetPath) => assetPath.trim().isNotEmpty;
  bool acceptsUrl(String url) {
    final value = Uri.tryParse(url.trim());
    return value != null && (value.scheme == 'https' || value.scheme == 'http');
  }

  bool acceptsBytes(Uint8List bytes) => bytes.isNotEmpty;
}
