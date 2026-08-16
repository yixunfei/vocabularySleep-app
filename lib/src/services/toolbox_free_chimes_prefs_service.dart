import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'toolbox_free_chimes_controller.dart';

class FreeChimesPrefsState {
  const FreeChimesPrefsState({
    this.customLayerAmounts = const <ToolboxFreeChimeLayer, double>{},
    this.naturalWindEnabled = false,
    this.naturalWindMix = 0.48,
    this.naturalWindBreezeBoost = 0.62,
  });

  final Map<ToolboxFreeChimeLayer, double> customLayerAmounts;
  final bool naturalWindEnabled;
  final double naturalWindMix;
  final double naturalWindBreezeBoost;

  bool get hasCustomPreset => customLayerAmounts.isNotEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'custom_layer_amounts': <String, double>{
        for (final entry in customLayerAmounts.entries)
          entry.key.id: entry.value.clamp(0.0, 1.0).toDouble(),
      },
      'natural_wind_enabled': naturalWindEnabled,
      'natural_wind_mix': naturalWindMix.clamp(0.0, 1.0).toDouble(),
      'natural_wind_breeze_boost': naturalWindBreezeBoost
          .clamp(0.0, 1.0)
          .toDouble(),
    };
  }

  static FreeChimesPrefsState fromJsonValue(Object? value) {
    if (value is! Map) {
      return const FreeChimesPrefsState();
    }
    final map = value.cast<Object?, Object?>();
    final rawAmounts = map['custom_layer_amounts'];
    final rawNaturalWindMix = map['natural_wind_mix'];
    final rawNaturalWindBreezeBoost = map['natural_wind_breeze_boost'];
    double normalizedDouble(Object? raw, double fallback) {
      if (raw is! num) {
        return fallback;
      }
      return raw.toDouble().clamp(0.0, 1.0).toDouble();
    }

    if (rawAmounts is! Map) {
      return FreeChimesPrefsState(
        naturalWindEnabled: map['natural_wind_enabled'] == true,
        naturalWindMix: normalizedDouble(rawNaturalWindMix, 0.48),
        naturalWindBreezeBoost: normalizedDouble(
          rawNaturalWindBreezeBoost,
          0.62,
        ),
      );
    }
    final amounts = <ToolboxFreeChimeLayer, double>{};
    for (final entry in rawAmounts.entries) {
      final layer = _layerById('${entry.key}');
      final amount = entry.value;
      if (layer == null || amount is! num) {
        continue;
      }
      amounts[layer] = amount.toDouble().clamp(0.0, 1.0).toDouble();
    }
    return FreeChimesPrefsState(
      customLayerAmounts: amounts,
      naturalWindEnabled: map['natural_wind_enabled'] == true,
      naturalWindMix: normalizedDouble(rawNaturalWindMix, 0.48),
      naturalWindBreezeBoost: normalizedDouble(rawNaturalWindBreezeBoost, 0.62),
    );
  }

  static ToolboxFreeChimeLayer? _layerById(String id) {
    for (final layer in ToolboxFreeChimeLayer.values) {
      if (layer.id == id.trim()) {
        return layer;
      }
    }
    return null;
  }
}

class ToolboxFreeChimesPrefsService {
  const ToolboxFreeChimesPrefsService._();

  static Future<File> _resolveFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'toolbox'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'free_chimes_prefs.json'));
  }

  static Future<FreeChimesPrefsState> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return const FreeChimesPrefsState();
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const FreeChimesPrefsState();
      }
      return FreeChimesPrefsState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return const FreeChimesPrefsState();
    }
  }

  static Future<void> save(FreeChimesPrefsState state) async {
    try {
      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {
      // Best-effort persistence.
    }
  }
}
