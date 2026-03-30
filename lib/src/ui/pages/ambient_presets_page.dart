import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/ambient_preset.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';

class AmbientPresetsPage extends StatelessWidget {
  const AmbientPresetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final i18n = AppI18n(state.uiLanguage);
        final presets = state.ambientPresets;
        return Scaffold(
          appBar: AppBar(
            title: Text(pickUiText(i18n, zh: '环境音预设', en: 'Ambient presets')),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createPreset(context, state, i18n),
            icon: const Icon(Icons.add_rounded),
            label: Text(pickUiText(i18n, zh: '保存当前组合', en: 'Save current mix')),
          ),
          body: presets.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      pickUiText(
                        i18n,
                        zh: '先在环境音面板里打开想要的声音并调整音量，再来保存为预设。',
                        en: 'Turn on the sounds you want in the ambient panel, adjust their volumes, then save them as a preset here.',
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
                                pickUiText(
                                  i18n,
                                  zh: '已应用预设：${preset.name}',
                                  en: 'Applied preset: ${preset.name}',
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
                  separatorBuilder: (_, unusedIndex) =>
                      const SizedBox(height: 10),
                  itemCount: presets.length,
                ),
        );
      },
    );
  }

  String _subtitle(AppI18n i18n, AmbientPreset preset) {
    return pickUiText(
      i18n,
      zh: '${preset.entries.length} 个环境音 · 总音量 ${(preset.masterVolume * 100).round()}%',
      en: '${preset.entries.length} sounds · master ${(preset.masterVolume * 100).round()}%',
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
            pickUiText(
              i18n,
              zh: '请先至少启用一个环境音，再保存为预设。',
              en: 'Turn on at least one ambient sound before saving a preset.',
            ),
          ),
        ),
      );
      return;
    }
    final name = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '新建预设', en: 'New preset'),
      subtitle: pickUiText(
        i18n,
        zh: '保存当前启用的环境音和音量组合。',
        en: 'Save the currently enabled ambient sounds and their volumes.',
      ),
      hintText: pickUiText(i18n, zh: '例如：午后咖啡馆', en: 'For example: Cafe Focus'),
      confirmText: pickUiText(i18n, zh: '保存', en: 'Save'),
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }
    await state.saveAmbientPresetFromCurrentMix(name.trim());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(
            i18n,
            zh: '已保存预设：${name.trim()}',
            en: 'Saved preset: ${name.trim()}',
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
      title: pickUiText(i18n, zh: '删除预设', en: 'Delete preset'),
      message: pickUiText(
        i18n,
        zh: '确定删除预设“${preset.name}”？',
        en: 'Delete preset "${preset.name}"?',
      ),
      confirmText: pickUiText(i18n, zh: '删除', en: 'Delete'),
      danger: true,
    );
    if (!confirmed) {
      return;
    }
    await state.deleteAmbientPreset(preset.id);
  }
}
