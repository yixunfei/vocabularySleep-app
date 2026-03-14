import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class AmbientSheet extends StatelessWidget {
  const AmbientSheet({super.key, required this.state, required this.i18n});

  final AppState state;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
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
              title: pickUiText(i18n, zh: '环境音', en: 'Ambient sound'),
              subtitle: pickUiText(
                i18n,
                zh: '在播放页保持低干扰、可单手调节',
                en: 'Keep ambient sound close to playback, not buried in settings.',
              ),
            ),
            const SizedBox(height: 18),
            Text(
              pickUiText(i18n, zh: '总音量', en: 'Master volume'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Slider(
              value: state.ambientMasterVolume,
              onChanged: (value) => state.setAmbientMasterVolume(value),
            ),
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: state.ambientSources.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == state.ambientSources.length) {
                    return OutlinedButton.icon(
                      onPressed: state.addAmbientFileSource,
                      icon: const Icon(Icons.library_music_rounded),
                      label: Text(
                        pickUiText(i18n, zh: '导入自定义音频', en: 'Add custom audio'),
                      ),
                    );
                  }

                  final source = state.ambientSources[index];
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
                                  localizedAmbientName(i18n, source),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Switch(
                                value: source.enabled,
                                onChanged: (value) => state
                                    .setAmbientSourceEnabled(source.id, value),
                              ),
                              if (!source.isAsset)
                                IconButton(
                                  onPressed: () =>
                                      state.removeAmbientSource(source.id),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                            ],
                          ),
                          Slider(
                            value: source.volume,
                            onChanged: source.enabled
                                ? (value) => state.setAmbientSourceVolume(
                                    source.id,
                                    value,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
