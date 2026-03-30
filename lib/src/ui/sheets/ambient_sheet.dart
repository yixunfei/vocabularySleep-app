import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../services/ambient_service.dart';
import '../../state/app_state.dart';
import '../pages/ambient_presets_page.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'online_ambient_sheet.dart';

class AmbientSheet extends StatefulWidget {
  const AmbientSheet({super.key, required this.state, required this.i18n});

  final AppState state;
  final AppI18n i18n;

  @override
  State<AmbientSheet> createState() => _AmbientSheetState();
}

class _AmbientSheetState extends State<AmbientSheet> {
  final Set<String> _togglingSourceIds = <String>{};
  bool _isTogglingMaster = false;

  Future<void> _toggleSource(String sourceId, bool value) async {
    if (_togglingSourceIds.contains(sourceId)) {
      return;
    }
    setState(() {
      _togglingSourceIds.add(sourceId);
    });
    try {
      await widget.state.setAmbientSourceEnabled(sourceId, value);
    } finally {
      if (mounted) {
        setState(() {
          _togglingSourceIds.remove(sourceId);
        });
      }
    }
  }

  Future<void> _toggleMaster(bool value) async {
    if (_isTogglingMaster) {
      return;
    }
    setState(() {
      _isTogglingMaster = true;
    });
    try {
      await widget.state.setAmbientEnabled(value);
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingMaster = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, liveState, _) {
        final i18n = AppI18n(liveState.uiLanguage);
        final ambientEnabled = liveState.ambientEnabled;
        final enabledCount = liveState.ambientSources
            .where((item) => item.enabled)
            .length;
        final builtInSources = liveState.ambientSources
            .where((source) => source.isBuiltIn)
            .toList(growable: false);
        final onlineSources = liveState.ambientSources
            .where((source) => source.isRemote)
            .toList(growable: false);
        final localSources = liveState.ambientSources
            .where((source) => source.isFile && !source.isBuiltIn)
            .toList(growable: false);

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(
                  title: pickUiText(i18n, zh: '环境音', en: 'Ambient sound'),
                  subtitle: pickUiText(
                    i18n,
                    zh: '把常用环境音、下载资源和预设放在一起，切换更顺手。',
                    en: 'Keep local sounds, downloads, and presets together for faster switching.',
                  ),
                ),
                const SizedBox(height: 12),
                _AmbientMasterCard(
                  ambientEnabled: ambientEnabled,
                  isBusy: _isTogglingMaster,
                  onChanged: _isTogglingMaster ? null : _toggleMaster,
                  i18n: i18n,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: liveState.addAmbientFileSource,
                      icon: const Icon(Icons.library_music_rounded, size: 18),
                      label: Text(pickUiText(i18n, zh: '导入音频', en: 'Add audio')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showOnlineAmbientCatalogSheet(context),
                      icon: const Icon(Icons.cloud_download_rounded, size: 18),
                      label: Text(pickUiText(i18n, zh: '资源库', en: 'Catalog')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AmbientPresetsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bookmarks_rounded, size: 18),
                      label: Text(pickUiText(i18n, zh: '预设管理', en: 'Presets')),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  pickUiText(
                    i18n,
                    zh: '当前已启用 $enabledCount 个环境音，可在预设里保存这一组组合。',
                    en: '$enabledCount ambient sounds enabled. Save this mix as a preset for quick recall.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  pickUiText(i18n, zh: '总音量', en: 'Master volume'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Slider(
                  value: liveState.ambientMasterVolume,
                  onChanged: (value) => liveState.setAmbientMasterVolume(value),
                ),
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      ...builtInSources.map(
                        (source) => _buildSourceCard(
                          context,
                          i18n,
                          liveState,
                          ambientEnabled,
                          source,
                        ),
                      ),
                      if (onlineSources.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          pickUiText(i18n, zh: '在线资源', en: 'Online sources'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...onlineSources.map(
                          (source) => _buildSourceCard(
                            context,
                            i18n,
                            liveState,
                            ambientEnabled,
                            source,
                            removable: true,
                          ),
                        ),
                      ],
                      if (localSources.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          pickUiText(
                            i18n,
                            zh: '已下载 / 本地音频',
                            en: 'Downloaded / local audio',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...localSources.map(
                          (source) => _buildSourceCard(
                            context,
                            i18n,
                            liveState,
                            ambientEnabled,
                            source,
                            removable: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceCard(
    BuildContext context,
    AppI18n i18n,
    AppState liveState,
    bool ambientEnabled,
    AmbientSource source, {
    bool removable = false,
  }) {
    final isToggling = _togglingSourceIds.contains(source.id);
    return Opacity(
      opacity: ambientEnabled ? 1 : 0.72,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      localizedAmbientName(i18n, source),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (isToggling)
                    const SizedBox(
                      width: 44,
                      height: 24,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    Switch(
                      value: source.enabled,
                      onChanged: (value) => _toggleSource(source.id, value),
                    ),
                  if (removable && !isToggling)
                    IconButton(
                      onPressed: () => liveState.removeAmbientSource(source.id),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  if (removable && isToggling) const SizedBox(width: 48),
                ],
              ),
              Slider(
                value: source.volume,
                onChanged: (source.enabled && !isToggling)
                    ? (value) => liveState.setAmbientSourceVolume(source.id, value)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmbientMasterCard extends StatelessWidget {
  const _AmbientMasterCard({
    required this.ambientEnabled,
    required this.isBusy,
    required this.onChanged,
    required this.i18n,
  });

  final bool ambientEnabled;
  final bool isBusy;
  final ValueChanged<bool>? onChanged;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final statusText = ambientEnabled
        ? pickUiText(
            i18n,
            zh: '已开启，可一键静音全部环境音。',
            en: 'On. Mute every ambient source at once.',
          )
        : pickUiText(
            i18n,
            zh: '已关闭，重新开启后恢复当前组合。',
            en: 'Off. Restore the current mix when enabled.',
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerLow
            .withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: <Widget>[
            Icon(
              ambientEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '总开关', en: 'Master switch'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isBusy)
              const SizedBox(
                width: 50,
                height: 28,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Switch.adaptive(value: ambientEnabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
