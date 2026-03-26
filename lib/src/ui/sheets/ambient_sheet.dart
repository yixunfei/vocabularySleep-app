import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'online_ambient_sheet.dart';

class AmbientSheet extends StatelessWidget {
  const AmbientSheet({super.key, required this.state, required this.i18n});

  final AppState state;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, liveState, _) {
        final liveI18n = AppI18n(liveState.uiLanguage);
        final builtInSources = liveState.ambientSources
            .where((source) => source.isAsset)
            .toList(growable: false);
        final onlineSources = liveState.ambientSources
            .where((source) => source.isRemote)
            .toList(growable: false);
        final localSources = liveState.ambientSources
            .where((source) => source.isFile)
            .toList(growable: false);

        Widget buildSourceCard(source, {bool removable = false}) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          localizedAmbientName(liveI18n, source),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Switch(
                        value: source.enabled,
                        onChanged: (value) =>
                            liveState.setAmbientSourceEnabled(source.id, value),
                      ),
                      if (removable)
                        IconButton(
                          onPressed: () =>
                              liveState.removeAmbientSource(source.id),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                    ],
                  ),
                  Slider(
                    value: source.volume,
                    onChanged: source.enabled
                        ? (value) =>
                              liveState.setAmbientSourceVolume(source.id, value)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(
                  title: pickUiText(liveI18n, zh: '环境音', en: 'Ambient sound'),
                  subtitle: pickUiText(
                    liveI18n,
                    zh: '把环境音放在播放流程附近，可直接切换在线或本地声音。',
                    en: 'Keep ambient sound close to playback, with direct access to online and local sounds.',
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: liveState.addAmbientFileSource,
                      icon: const Icon(Icons.library_music_rounded),
                      label: Text(
                        pickUiText(
                          liveI18n,
                          zh: '导入本地音频',
                          en: 'Add local audio',
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showOnlineAmbientCatalogSheet(context),
                      icon: const Icon(Icons.cloud_rounded),
                      label: Text(
                        pickUiText(liveI18n, zh: '在线白噪音', en: 'Online ambient'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  pickUiText(liveI18n, zh: '总音量', en: 'Master volume'),
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
                        (source) => buildSourceCard(source),
                      ),
                      if (onlineSources.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          pickUiText(
                            liveI18n,
                            zh: '在线音源',
                            en: 'Online sources',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...onlineSources.map(
                          (source) => buildSourceCard(source, removable: true),
                        ),
                      ],
                      if (localSources.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          pickUiText(
                            liveI18n,
                            zh: '已下载 / 本地音频',
                            en: 'Downloaded / local audio',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...localSources.map(
                          (source) => buildSourceCard(source, removable: true),
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
}
