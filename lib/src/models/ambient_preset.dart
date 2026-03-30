class AmbientPresetEntry {
  const AmbientPresetEntry({
    required this.sourceId,
    required this.name,
    required this.volume,
    this.assetPath,
    this.filePath,
    this.remoteUrl,
    this.remoteKey,
    this.categoryKey,
    this.builtIn = false,
  });

  final String sourceId;
  final String name;
  final double volume;
  final String? assetPath;
  final String? filePath;
  final String? remoteUrl;
  final String? remoteKey;
  final String? categoryKey;
  final bool builtIn;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'source_id': sourceId,
      'name': name,
      'volume': volume,
      'asset_path': assetPath,
      'file_path': filePath,
      'remote_url': remoteUrl,
      'remote_key': remoteKey,
      'category_key': categoryKey,
      'built_in': builtIn,
    };
  }

  static AmbientPresetEntry? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final sourceId = '${map['source_id'] ?? ''}'.trim();
    final name = '${map['name'] ?? ''}'.trim();
    if (sourceId.isEmpty || name.isEmpty) {
      return null;
    }
    return AmbientPresetEntry(
      sourceId: sourceId,
      name: name,
      volume: ((map['volume'] as num?) ?? 0.5).toDouble().clamp(0.0, 1.0),
      assetPath: _normalizedString(map['asset_path']),
      filePath: _normalizedString(map['file_path']),
      remoteUrl: _normalizedString(map['remote_url']),
      remoteKey: _normalizedString(map['remote_key']),
      categoryKey: _normalizedString(map['category_key']),
      builtIn: map['built_in'] == true,
    );
  }

  static String? _normalizedString(Object? value) {
    final text = '$value'.trim();
    return text.isEmpty || text == 'null' ? null : text;
  }
}

class AmbientPreset {
  const AmbientPreset({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.masterVolume,
    required this.entries,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final double masterVolume;
  final List<AmbientPresetEntry> entries;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'master_volume': masterVolume,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  static AmbientPreset? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final id = '${map['id'] ?? ''}'.trim();
    final name = '${map['name'] ?? ''}'.trim();
    if (id.isEmpty || name.isEmpty) {
      return null;
    }
    final entriesRaw = map['entries'];
    final entries = entriesRaw is List
        ? entriesRaw
              .map(AmbientPresetEntry.fromJsonValue)
              .whereType<AmbientPresetEntry>()
              .toList(growable: false)
        : const <AmbientPresetEntry>[];
    final createdAtRaw = '${map['created_at'] ?? ''}'.trim();
    return AmbientPreset(
      id: id,
      name: name,
      createdAt:
          DateTime.tryParse(createdAtRaw) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      masterVolume: ((map['master_volume'] as num?) ?? 0.7).toDouble().clamp(
        0.0,
        1.0,
      ),
      entries: entries,
    );
  }
}
