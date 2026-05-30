part of 'toolbox_soothing_music_v2_page.dart';

extension _SoothingMusicV2Arrangement on _SoothingMusicV2PageState {
  Future<void> _saveArrangementTemplate(AppI18n i18n) async {
    final steps = List<SoothingPlaybackArrangementStep>.from(_arrangementSteps);
    if (steps.isEmpty) {
      return;
    }
    final suggestedName =
        _activeArrangementTemplate?.name ??
        i18n.t('toolbox.sound.soothing.my_arrangement');
    final name = await showTextPromptDialog(
      context: context,
      title: i18n.t('toolbox.sound.soothing.save_arrangement'),
      subtitle: i18n.t('toolbox.sound.soothing.save_arrangement_subtitle'),
      initialValue: suggestedName,
      hintText: i18n.t('toolbox.sound.soothing.save_arrangement_hint'),
      confirmText: i18n.t('toolbox.sound.soothing.save'),
    );
    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }
    final trimmedName = name.trim();
    final existing = _activeArrangementTemplate;
    final template = SoothingPlaybackArrangementTemplate(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmedName,
      steps: steps,
    );
    final templates = List<SoothingPlaybackArrangementTemplate>.from(
      _SoothingRuntimeStore.arrangementTemplates,
    );
    final existingIndex = templates.indexWhere(
      (item) => item.id == template.id,
    );
    if (existingIndex >= 0) {
      templates[existingIndex] = template;
    } else {
      templates.insert(0, template);
    }
    _setViewState(() {
      _SoothingRuntimeStore.arrangementTemplates = templates;
      _SoothingRuntimeStore.activeArrangementTemplateId = template.id;
    });
    _SoothingRuntimeStore.notifyChanged();
    await _persistPrefs();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n.t(
            'toolbox.sound.soothing.arrangement_saved',
            params: <String, Object?>{'name': trimmedName},
          ),
        ),
      ),
    );
  }

  Future<void> _renameArrangementTemplate(
    AppI18n i18n,
    SoothingPlaybackArrangementTemplate template,
  ) async {
    final name = await showTextPromptDialog(
      context: context,
      title: i18n.t('toolbox.sound.soothing.rename_arrangement'),
      initialValue: template.name,
      hintText: i18n.t('toolbox.sound.soothing.rename_hint'),
      confirmText: i18n.t('toolbox.sound.soothing.save'),
    );
    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }
    final trimmedName = name.trim();
    _setViewState(() {
      _SoothingRuntimeStore.arrangementTemplates = _SoothingRuntimeStore
          .arrangementTemplates
          .map(
            (item) => item.id == template.id
                ? item.copyWith(name: trimmedName)
                : item,
          )
          .toList(growable: false);
    });
    _SoothingRuntimeStore.notifyChanged();
    await _persistPrefs();
  }

  Future<void> _deleteArrangementTemplate(
    AppI18n i18n,
    SoothingPlaybackArrangementTemplate template,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: i18n.t('toolbox.sound.soothing.delete_arrangement'),
      message: i18n.t(
        'toolbox.sound.soothing.delete_arrangement_confirm',
        params: <String, Object?>{'name': template.name},
      ),
      confirmText: i18n.t('toolbox.sound.soothing.delete'),
      danger: true,
    );
    if (!mounted || !confirmed) {
      return;
    }
    _setViewState(() {
      _SoothingRuntimeStore.arrangementTemplates = _SoothingRuntimeStore
          .arrangementTemplates
          .where((item) => item.id != template.id)
          .toList(growable: false);
      if (_SoothingRuntimeStore.activeArrangementTemplateId == template.id) {
        _SoothingRuntimeStore.activeArrangementTemplateId = null;
      }
    });
    _SoothingRuntimeStore.notifyChanged();
    await _persistPrefs();
  }

  void _applyArrangementTemplate(SoothingPlaybackArrangementTemplate template) {
    _setViewState(() {
      _SoothingRuntimeStore.playbackMode = SoothingPlaybackMode.arrangement;
      _SoothingRuntimeStore.arrangementSteps =
          List<SoothingPlaybackArrangementStep>.from(template.steps);
      _SoothingRuntimeStore.activeArrangementTemplateId = template.id;
      _SoothingRuntimeStore.arrangementStepIndex = 0;
      _SoothingRuntimeStore.arrangementStepPlayCount = 0;
    });
    _SoothingRuntimeStore.notifyChanged();
    unawaited(_persistPrefs());
    unawaited(
      _startArrangementPlayback(
        autoplay: _playbackVisualActive || _playbackIntent || !_loading,
      ),
    );
  }

  void _useCurrentArrangementDraft(
    List<SoothingPlaybackArrangementStep> steps,
  ) {
    final snapshot = List<SoothingPlaybackArrangementStep>.from(steps);
    final activeTemplate = _activeArrangementTemplate;
    if (activeTemplate == null) {
      _SoothingRuntimeStore.activeArrangementTemplateId = null;
      return;
    }
    final sameLength = activeTemplate.steps.length == snapshot.length;
    final sameSteps =
        sameLength &&
        Iterable<int>.generate(snapshot.length).every((index) {
          final left = activeTemplate.steps[index];
          final right = snapshot[index];
          return left.modeId == right.modeId &&
              left.trackIndex == right.trackIndex &&
              left.repeatCount == right.repeatCount;
        });
    if (!sameSteps) {
      _SoothingRuntimeStore.activeArrangementTemplateId = null;
    }
  }

  Future<void> _showArrangementSheet(BuildContext context, AppI18n i18n) async {
    var selectedMode = _playbackMode;
    var draftSteps = List<SoothingPlaybackArrangementStep>.from(
      _arrangementSteps,
    );
    if (draftSteps.isEmpty) {
      draftSteps = <SoothingPlaybackArrangementStep>[
        SoothingPlaybackArrangementStep(
          modeId: _mode.id,
          trackIndex: _trackIndex,
          repeatCount: 1,
        ),
      ];
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final templates = _SoothingRuntimeStore.arrangementTemplates;
            final activeTemplate = _activeArrangementTemplate;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    i18n.t('toolbox.sound.soothing.playback_order'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n.t('toolbox.sound.soothing.playback_order_desc'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<SoothingPlaybackMode>(
                    segments: <ButtonSegment<SoothingPlaybackMode>>[
                      ButtonSegment<SoothingPlaybackMode>(
                        value: SoothingPlaybackMode.singleLoop,
                        label: Text(
                          _playbackModeLabel(
                            i18n,
                            SoothingPlaybackMode.singleLoop,
                          ),
                        ),
                      ),
                      ButtonSegment<SoothingPlaybackMode>(
                        value: SoothingPlaybackMode.modeCycle,
                        label: Text(
                          _playbackModeLabel(
                            i18n,
                            SoothingPlaybackMode.modeCycle,
                          ),
                        ),
                      ),
                      ButtonSegment<SoothingPlaybackMode>(
                        value: SoothingPlaybackMode.arrangement,
                        label: Text(
                          _playbackModeLabel(
                            i18n,
                            SoothingPlaybackMode.arrangement,
                          ),
                        ),
                      ),
                    ],
                    selected: <SoothingPlaybackMode>{selectedMode},
                    onSelectionChanged: (selection) {
                      final nextMode = selection.firstOrNull;
                      if (nextMode == null) return;
                      setModalState(() {
                        selectedMode = nextMode;
                      });
                    },
                  ),
                  if (selectedMode ==
                      SoothingPlaybackMode.arrangement) ...<Widget>[
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const Icon(Icons.bookmark_added_outlined),
                        title: Text(
                          activeTemplate?.name ??
                              i18n.t(
                                'toolbox.sound.soothing.arrangement_not_saved',
                              ),
                        ),
                        subtitle: Text(
                          i18n.t(
                            'toolbox.sound.soothing.arrangement_steps_info',
                            params: <String, Object?>{
                              'steps': '${draftSteps.length}',
                              'templates': '${templates.length}',
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            _setViewState(() {
                              _SoothingRuntimeStore.arrangementSteps =
                                  List<SoothingPlaybackArrangementStep>.from(
                                    draftSteps,
                                  );
                            });
                            _useCurrentArrangementDraft(draftSteps);
                            _SoothingRuntimeStore.notifyChanged();
                            await _saveArrangementTemplate(i18n);
                          },
                          icon: const Icon(Icons.save_outlined),
                          label: Text(
                            i18n.t('toolbox.sound.soothing.save_current'),
                          ),
                        ),
                        if (templates.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final selected =
                                  await showModalBottomSheet<
                                    SoothingPlaybackArrangementTemplate
                                  >(
                                    context: context,
                                    useSafeArea: true,
                                    showDragHandle: true,
                                    builder: (dialogContext) {
                                      return ListView.separated(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          8,
                                          12,
                                          24,
                                        ),
                                        itemCount: templates.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (dialogContext, index) {
                                          final template = templates[index];
                                          return Card(
                                            child: ListTile(
                                              leading: Icon(
                                                template.id ==
                                                        _SoothingRuntimeStore
                                                            .activeArrangementTemplateId
                                                    ? Icons.check_circle_rounded
                                                    : Icons
                                                          .playlist_play_rounded,
                                              ),
                                              title: Text(template.name),
                                              subtitle: Text(
                                                i18n.t(
                                                  'toolbox.sound.soothing.template_steps',
                                                  params: <String, Object?>{
                                                    'count':
                                                        template.steps.length,
                                                  },
                                                ),
                                              ),
                                              onTap: () => Navigator.of(
                                                dialogContext,
                                              ).pop(template),
                                              trailing: PopupMenuButton<String>(
                                                onSelected: (action) async {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                  if (action == 'rename') {
                                                    await _renameArrangementTemplate(
                                                      i18n,
                                                      template,
                                                    );
                                                  } else if (action ==
                                                      'delete') {
                                                    await _deleteArrangementTemplate(
                                                      i18n,
                                                      template,
                                                    );
                                                  }
                                                },
                                                itemBuilder: (_) =>
                                                    <PopupMenuEntry<String>>[
                                                      PopupMenuItem<String>(
                                                        value: 'rename',
                                                        child: Text(
                                                          i18n.t(
                                                            'toolbox.sound.soothing.rename',
                                                          ),
                                                        ),
                                                      ),
                                                      PopupMenuItem<String>(
                                                        value: 'delete',
                                                        child: Text(
                                                          i18n.t(
                                                            'toolbox.sound.soothing.delete',
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                              if (selected == null || !mounted) {
                                return;
                              }
                              setModalState(() {
                                draftSteps =
                                    List<SoothingPlaybackArrangementStep>.from(
                                      selected.steps,
                                    );
                              });
                              _applyArrangementTemplate(selected);
                            },
                            icon: const Icon(Icons.folder_open_rounded),
                            label: Text(
                              i18n.t('toolbox.sound.soothing.load_saved'),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            i18n.t(
                              'toolbox.sound.soothing.arrangement_steps_title',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              draftSteps.add(
                                SoothingPlaybackArrangementStep(
                                  modeId: _mode.id,
                                  trackIndex: _trackIndex,
                                  repeatCount: 1,
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            i18n.t('toolbox.sound.soothing.add_current'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: draftSteps.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final step = draftSteps[index];
                          final stepMode = _modes.firstWhere(
                            (mode) => mode.id == step.modeId,
                            orElse: () => _mode,
                          );
                          final tracks =
                              _SoothingMusicV2PageState._tracksForMode(
                                stepMode.id,
                              );
                          final safeTrackIndex = step.trackIndex.clamp(
                            0,
                            tracks.length - 1,
                          );
                          final track = tracks[safeTrackIndex];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          '${index + 1}. ${stepMode.title(i18n)} · ${SoothingMusicCopy.trackLabel(i18n, track.labelKey)}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: index > 0
                                            ? () {
                                                setModalState(() {
                                                  final item = draftSteps
                                                      .removeAt(index);
                                                  draftSteps.insert(
                                                    index - 1,
                                                    item,
                                                  );
                                                });
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.arrow_upward_rounded,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: index < draftSteps.length - 1
                                            ? () {
                                                setModalState(() {
                                                  final item = draftSteps
                                                      .removeAt(index);
                                                  draftSteps.insert(
                                                    index + 1,
                                                    item,
                                                  );
                                                });
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.arrow_downward_rounded,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: draftSteps.length > 1
                                            ? () {
                                                setModalState(() {
                                                  draftSteps.removeAt(index);
                                                });
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: stepMode.id,
                                    decoration: InputDecoration(
                                      labelText: i18n.t(
                                        'toolbox.sound.soothing.theme',
                                      ),
                                    ),
                                    items: _modes
                                        .map(
                                          (mode) => DropdownMenuItem<String>(
                                            value: mode.id,
                                            child: Text(mode.title(i18n)),
                                          ),
                                        )
                                        .toList(growable: false),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setModalState(() {
                                        draftSteps[index] = draftSteps[index]
                                            .copyWith(
                                              modeId: value,
                                              trackIndex: 0,
                                            );
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<int>(
                                    initialValue: safeTrackIndex,
                                    decoration: InputDecoration(
                                      labelText: i18n.t(
                                        'toolbox.sound.soothing.track',
                                      ),
                                    ),
                                    items: List<DropdownMenuItem<int>>.generate(
                                      tracks.length,
                                      (trackIndex) => DropdownMenuItem<int>(
                                        value: trackIndex,
                                        child: Text(
                                          SoothingMusicCopy.trackLabel(
                                            i18n,
                                            tracks[trackIndex].labelKey,
                                          ),
                                        ),
                                      ),
                                      growable: false,
                                    ),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setModalState(() {
                                        draftSteps[index] = draftSteps[index]
                                            .copyWith(trackIndex: value);
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        i18n.t(
                                          'toolbox.sound.soothing.repeats',
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        onPressed: step.repeatCount > 1
                                            ? () {
                                                setModalState(() {
                                                  draftSteps[index] =
                                                      draftSteps[index].copyWith(
                                                        repeatCount:
                                                            step.repeatCount -
                                                            1,
                                                      );
                                                });
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.remove_circle_outline_rounded,
                                        ),
                                      ),
                                      Text('${step.repeatCount}'),
                                      IconButton(
                                        onPressed: step.repeatCount < 99
                                            ? () {
                                                setModalState(() {
                                                  draftSteps[index] =
                                                      draftSteps[index].copyWith(
                                                        repeatCount:
                                                            step.repeatCount +
                                                            1,
                                                      );
                                                });
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.add_circle_outline_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(
                          MaterialLocalizations.of(context).cancelButtonLabel,
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          if (selectedMode ==
                                  SoothingPlaybackMode.arrangement &&
                              draftSteps.isEmpty) {
                            return;
                          }
                          final sheetNavigator = Navigator.of(sheetContext);
                          _setViewState(() {
                            _SoothingRuntimeStore.playbackMode = selectedMode;
                            _SoothingRuntimeStore.arrangementSteps =
                                List<SoothingPlaybackArrangementStep>.from(
                                  draftSteps,
                                );
                            _SoothingRuntimeStore.arrangementStepIndex = 0;
                            _SoothingRuntimeStore.arrangementStepPlayCount = 0;
                            _useCurrentArrangementDraft(draftSteps);
                          });
                          _SoothingRuntimeStore.notifyChanged();
                          await _persistPrefs();
                          if (!mounted) {
                            return;
                          }
                          sheetNavigator.pop();
                          if (selectedMode ==
                              SoothingPlaybackMode.arrangement) {
                            await _startArrangementPlayback(
                              autoplay:
                                  _playbackVisualActive ||
                                  _playbackIntent ||
                                  !_loading,
                            );
                          }
                        },
                        child: Text(i18n.t('toolbox.sound.soothing.apply')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
