import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_soothing_prefs_service.dart';
import '../pages/toolbox_soothing_music/runtime_store.dart';
import '../pages/toolbox_soothing_music/track_catalog.dart';
import '../pages/toolbox_soothing_music_v2_copy.dart';
import '../ui_copy.dart';

class SoothingMiniPlayer extends StatelessWidget {
  const SoothingMiniPlayer({
    super.key,
    required this.i18n,
    required this.onOpen,
    this.onTogglePlayback,
  });

  final AppI18n i18n;
  final VoidCallback onOpen;
  final Future<void> Function()? onTogglePlayback;

  static const List<String> _modeIds = <String>[
    'chill',
    'study',
    'sleep',
    'jazz',
    'piano',
    'motion',
    'harp',
    'music_box',
    'dreaming',
  ];

  static bool get isVisible {
    return SoothingMusicRuntimeStore.activePlaying ||
        (SoothingMusicRuntimeStore.retainedPlayer != null &&
            SoothingMusicRuntimeStore.activeModeId != null);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: SoothingMusicRuntimeStore.revision,
      builder: (context, _, _) {
        if (!isVisible) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        final modeId =
            SoothingMusicRuntimeStore.activeModeId ??
            SoothingMusicRuntimeStore.lastModeId ??
            _modeIds.first;
        final trackIndex = SoothingMusicRuntimeStore.activeTrackIndex;
        final tracks = SoothingMusicTrackCatalog.tracksForMode(modeId);
        final safeTrackIndex = tracks.isEmpty
            ? 0
            : trackIndex.clamp(0, tracks.length - 1);
        final trackLabel = tracks.isEmpty
            ? '-'
            : SoothingMusicCopy.trackLabel(
                i18n,
                tracks[safeTrackIndex].labelKey,
              );
        final modeTitle = SoothingMusicCopy.modeTitle(i18n, modeId);
        final playbackMode = SoothingMusicRuntimeStore.playbackMode;
        final playbackLabel = switch (playbackMode) {
          SoothingPlaybackMode.singleLoop => pickUiText(
            i18n,
            zh: '单曲循环',
            en: 'Single loop',
          ),
          SoothingPlaybackMode.modeCycle => pickUiText(
            i18n,
            zh: '主题顺播',
            en: 'Mode cycle',
          ),
          SoothingPlaybackMode.arrangement => pickUiText(
            i18n,
            zh: '编排播放',
            en: 'Arrangement',
          ),
        };
        final arrangementLabel =
            playbackMode == SoothingPlaybackMode.arrangement &&
                SoothingMusicRuntimeStore.arrangementSteps.isNotEmpty
            ? pickUiText(
                i18n,
                zh: '第 ${SoothingMusicRuntimeStore.arrangementStepIndex.clamp(0, SoothingMusicRuntimeStore.arrangementSteps.length - 1) + 1}/${SoothingMusicRuntimeStore.arrangementSteps.length} 段',
                en: 'Step ${SoothingMusicRuntimeStore.arrangementStepIndex.clamp(0, SoothingMusicRuntimeStore.arrangementSteps.length - 1) + 1}/${SoothingMusicRuntimeStore.arrangementSteps.length}',
              )
            : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Material(
            elevation: 6,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onOpen,
              child: Ink(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.spa_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              modeTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trackLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: <Widget>[
                                _MiniBadge(label: playbackLabel),
                                if (arrangementLabel != null)
                                  _MiniBadge(label: arrangementLabel),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: SoothingMusicRuntimeStore.activePlaying
                            ? pickUiText(i18n, zh: '暂停', en: 'Pause')
                            : pickUiText(i18n, zh: '播放', en: 'Play'),
                        onPressed: onTogglePlayback == null
                            ? null
                            : () {
                                onTogglePlayback!.call();
                              },
                        icon: Icon(
                          SoothingMusicRuntimeStore.activePlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
