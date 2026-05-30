import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/ambient_preset.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../modal_helpers.dart';

class AmbientPresetsPage extends ConsumerWidget {
  const AmbientPresetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final presets = state.ambientPresets;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.t('inline.ui.pages.ambient_presets_page.ambient_presets_df4f07'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createPreset(context, state, i18n),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          i18n.t(
            'inline.ui.pages.ambient_presets_page.save_current_mix_7bf35c',
          ),
        ),
      ),
      body: presets.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  i18n.t(
                    'inline.ui.pages.ambient_presets_page.turn_on_the_sounds_you_want_in_the_ambient_panel_adjust_ed52e9',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemBuilder: (context, index) {
                final preset = presets[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const Icon(Icons.tune_rounded),
                    title: Text(preset.name),
                    subtitle: Text(_subtitle(i18n, preset)),
                    onTap: () async {
                      await state.applyAmbientPreset(preset.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            i18n.t(
                              'inline.ui.pages.ambient_presets_page.applied_preset_preset_name_044da2',
                              params: <String, Object?>{'preset': preset.name},
                            ),
                          ),
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    trailing: IconButton(
                      onPressed: () =>
                          _deletePreset(context, state, i18n, preset),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, unusedIndex) => const SizedBox(height: 10),
              itemCount: presets.length,
            ),
    );
  }

  String _subtitle(AppI18n i18n, AmbientPreset preset) {
    return i18n.t(
      'inline.ui.pages.ambient_presets_page.preset_entries_length_sounds_master_preset_mastervolume_2f5f31',
      params: <String, Object?>{
        'presetEntries': preset.entries.length,
        'presetMasterVolume': (preset.masterVolume * 100).round(),
      },
    );
  }

  Future<void> _createPreset(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    final enabledCount = state.ambientSources
        .where((item) => item.enabled)
        .length;
    if (enabledCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            i18n.t(
              'inline.ui.pages.ambient_presets_page.turn_on_at_least_one_ambient_sound_before_saving_a_prese_cdb9e4',
            ),
          ),
        ),
      );
      return;
    }
    final name = await showTextPromptDialog(
      context: context,
      title: i18n.t('inline.ui.pages.ambient_presets_page.new_preset_620c29'),
      subtitle: i18n.t(
        'inline.ui.pages.ambient_presets_page.save_the_currently_enabled_ambient_sounds_and_their_volu_0804dd',
      ),
      hintText: i18n.t(
        'inline.ui.pages.ambient_presets_page.for_example_cafe_focus_3c296b',
      ),
      confirmText: i18n.t('save'),
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }
    await state.saveAmbientPresetFromCurrentMix(name.trim());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n.t(
            'inline.ui.pages.ambient_presets_page.saved_preset_name_trim_f76b76',
            params: <String, Object?>{'trim': name.trim()},
          ),
        ),
      ),
    );
  }

  Future<void> _deletePreset(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    AmbientPreset preset,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: i18n.t(
        'inline.ui.pages.ambient_presets_page.delete_preset_8cfec5',
      ),
      message: i18n.t(
        'inline.ui.pages.ambient_presets_page.delete_preset_preset_name_6329ee',
        params: <String, Object?>{'preset': preset.name},
      ),
      confirmText: i18n.t('delete'),
      danger: true,
    );
    if (!confirmed) {
      return;
    }
    await state.deleteAmbientPreset(preset.id);
  }
}
