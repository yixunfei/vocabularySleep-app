import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../services/asr_service.dart';
import '../../state/app_state_provider.dart';
import '../../utils/asr_language.dart';
import '../../utils/speech_api_model_options.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class VoiceInputSettingsPage extends ConsumerStatefulWidget {
  const VoiceInputSettingsPage({super.key});

  @override
  ConsumerState<VoiceInputSettingsPage> createState() =>
      _VoiceInputSettingsPageState();
}

class _VoiceInputSettingsPageState
    extends ConsumerState<VoiceInputSettingsPage> {
  static const String _offlineModelSizeHint = '~150 MB';

  AsrOfflineModelStatus? _offlineStatus;
  bool _offlineBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshOfflineStatus();
    });
  }

  Future<void> _refreshOfflineStatus() async {
    final status = await ref
        .read(appStateProvider)
        .getVoiceInputOfflineModelStatus();
    if (!mounted) return;
    setState(() {
      _offlineStatus = status;
    });
  }

  Future<void> _handleOfflineAction({required bool install}) async {
    setState(() {
      _offlineBusy = true;
    });
    try {
      final state = ref.read(appStateProvider);
      if (install) {
        await state.prepareVoiceInputOfflineModel();
      } else {
        await state.removeVoiceInputOfflineModel();
      }
      await _refreshOfflineStatus();
    } catch (error) {
      if (!mounted) return;
      final i18n = AppI18n(ref.read(appStateProvider).uiLanguage);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            i18n.t(
              'inline.ui.pages.voice_input_settings_page.voice_input_offline_model_action_failed_error_aad121',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _offlineBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final voiceInput = config.voiceInput;
    final language = normalizeAsrLanguageTag(voiceInput.language);
    final selectedApiModel = normalizeSpeechApiModelValue(voiceInput.model);
    final apiModelOptions = resolveSpeechApiModelOptions(selectedApiModel);
    final languageOptions = <String>[
      ...kAsrLanguagePresetOptions,
      if (!kAsrLanguagePresetOptions.contains(language)) language,
    ];
    final offlineInstalled = _offlineStatus?.installed ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.t(
            'inline.ui.pages.help_center_page.voice_input_settings_2bf6ed',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(
                    title: i18n.t(
                      'inline.ui.pages.voice_input_settings_page.input_engine_79c053',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.voice_input_settings_page.quick_note_voice_input_is_configured_separately_from_fol_39b5ac',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<VoiceInputProviderType>(
                    initialValue: voiceInput.provider,
                    decoration: InputDecoration(
                      labelText: i18n.t(
                        'inline.ui.pages.voice_input_settings_page.voice_input_provider_f43cc4',
                      ),
                    ),
                    items: VoiceInputProviderType.values
                        .map(
                          (provider) =>
                              DropdownMenuItem<VoiceInputProviderType>(
                                value: provider,
                                child: Text(
                                  voiceInputProviderLabel(i18n, provider),
                                ),
                              ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      state.updateConfig(
                        config.copyWith(
                          voiceInput: voiceInput.copyWith(provider: value),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _providerHint(i18n, voiceInput.provider),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(
                    title: i18n.t(
                      'inline.ui.pages.voice_input_settings_page.input_language_d81557',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.voice_input_settings_page.prefer_the_system_default_or_a_full_locale_tag_such_as_z_f69b54',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: language,
                    decoration: InputDecoration(
                      labelText: i18n.t(
                        'inline.ui.pages.recognition_settings_page.recognition_language_0dd524',
                      ),
                    ),
                    items: languageOptions
                        .map(
                          (code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(asrLanguageLabel(i18n, code)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null || value.trim().isEmpty) return;
                      state.updateConfig(
                        config.copyWith(
                          voiceInput: voiceInput.copyWith(language: value),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (voiceInput.provider == VoiceInputProviderType.api) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: i18n.t(
                        'inline.ui.pages.voice_input_settings_page.api_fields_342300',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.voice_input_settings_page.these_api_fields_are_used_only_for_voice_input_transcrip_f12c2a',
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedApiModel,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: i18n.t('asrModel'),
                      ),
                      items: apiModelOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(
                                speechApiModelOptionLabel(i18n, option),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null || value.trim().isEmpty) return;
                        state.updateConfig(
                          config.copyWith(
                            voiceInput: voiceInput.copyWith(
                              model: value.trim(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      speechApiModelHelperText(i18n),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: voiceInput.apiKey ?? '',
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: i18n.t('asrApiKey'),
                      ),
                      onChanged: (value) {
                        state.updateConfig(
                          config.copyWith(
                            voiceInput: voiceInput.copyWith(
                              apiKey: value.trim(),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (voiceInput.provider ==
              VoiceInputProviderType.offline) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: i18n.t(
                        'inline.ui.pages.voice_input_settings_page.offline_model_0cdf80',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.voice_input_settings_page.download_the_offline_package_before_using_offline_voice_d739a2',
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t(
                          'inline.ui.pages.voice_input_settings_page.offline_engine_package_cdec31',
                        ),
                      ),
                      subtitle: Text(
                        offlineInstalled
                            ? i18n.t(
                                'inline.ui.pages.voice_input_settings_page.installed_and_ready_for_voice_input_d05a98',
                              )
                            : i18n.t(
                                'asrModelNotInstalled',
                                params: const <String, Object?>{
                                  'size': _offlineModelSizeHint,
                                },
                              ),
                      ),
                      trailing: _offlineBusy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : FilledButton.tonal(
                              onPressed: () => _handleOfflineAction(
                                install: !offlineInstalled,
                              ),
                              child: Text(
                                offlineInstalled
                                    ? i18n.t(
                                        'inline.ui.pages.practice_notebook_page.remove_2837f7',
                                      )
                                    : i18n.t('toolbox.sleep.tools.download'),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (voiceInput.provider == VoiceInputProviderType.system) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: i18n.t(
                        'inline.ui.pages.voice_input_settings_page.system_speech_recognition_4b0cef',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.voice_input_settings_page.android_uses_speechrecognizer_recognizerintent_and_ios_u_8dfad6',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      i18n.t(
                        'inline.ui.pages.voice_input_settings_page.this_mode_uses_the_platform_recognizer_directly_and_is_i_b29b9c',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _providerHint(AppI18n i18n, VoiceInputProviderType provider) {
    return switch (provider) {
      VoiceInputProviderType.api => i18n.t(
        'inline.ui.pages.voice_input_settings_page.uses_a_remote_api_for_transcription_higher_quality_but_r_8da13c',
      ),
      VoiceInputProviderType.offline => i18n.t(
        'inline.ui.pages.voice_input_settings_page.transcribes_voice_input_locally_on_device_and_needs_a_on_78298c',
      ),
      VoiceInputProviderType.system => i18n.t(
        'inline.ui.pages.voice_input_settings_page.uses_built_in_system_dictation_great_for_quick_input_but_69d42e',
      ),
    };
  }
}
