part of '../toolbox_sound_tools.dart';

class _ViolinTool extends StatefulWidget {
  const _ViolinTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_ViolinTool> createState() => _ViolinToolState();
}

class _ViolinPreset {
  const _ViolinPreset({
    required this.id,
    required this.styleId,
    required this.bow,
    required this.reverb,
    required this.scaleId,
  });

  final String id;
  final String styleId;
  final double bow;
  final double reverb;
  final String scaleId;
}

class _ViolinString {
  const _ViolinString({required this.label, required this.openMidi});

  final String label;
  final int openMidi;
}

class _ViolinToolState extends State<_ViolinTool> {
  static const List<_ViolinString> _strings = <_ViolinString>[
    _ViolinString(label: 'G3', openMidi: 55),
    _ViolinString(label: 'D4', openMidi: 62),
    _ViolinString(label: 'A4', openMidi: 69),
    _ViolinString(label: 'E5', openMidi: 76),
  ];
  static const List<_ViolinPreset> _presets = <_ViolinPreset>[
    _ViolinPreset(
      id: 'solo_bow',
      styleId: 'solo',
      bow: 0.66,
      reverb: 0.24,
      scaleId: 'major',
    ),
    _ViolinPreset(
      id: 'warm_legato',
      styleId: 'warm',
      bow: 0.58,
      reverb: 0.3,
      scaleId: 'minor',
    ),
    _ViolinPreset(
      id: 'glass_harmonic',
      styleId: 'glass',
      bow: 0.76,
      reverb: 0.18,
      scaleId: 'pentatonic',
    ),
  ];
  static const Map<String, List<int>> _scaleIntervals = <String, List<int>>{
    'major': <int>[0, 2, 4, 5, 7, 9, 11, 12],
    'minor': <int>[0, 2, 3, 5, 7, 8, 10, 12],
    'dorian': <int>[0, 2, 3, 5, 7, 9, 10, 12],
    'pentatonic': <int>[0, 3, 5, 7, 10, 12, 15],
    'chromatic': <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  };
  static const List<int> _positionOffsets = <int>[0, 2, 5, 7];
  static const List<String> _pitchNames = <String>[
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  final ToolboxLoopController _sustainLoop = ToolboxLoopController();
  final ToolboxLoopController _doubleStopLoop = ToolboxLoopController();
  final Map<int, Offset> _activePointers = <int, Offset>{};

  String _presetId = _presets.first.id;
  String _scaleId = _presets.first.scaleId;
  double _bow = _presets.first.bow;
  double _reverb = _presets.first.reverb;
  int _positionIndex = 0;
  int? _activeStringIndex;
  int? _activeNoteMidi;
  String? _lastNoteLabel;

  _ViolinPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _ViolinPreset preset) {
    return switch (preset.id) {
      'warm_legato' => pickUiText(i18n, zh: '温暖连奏', en: 'Warm legato'),
      'glass_harmonic' => pickUiText(i18n, zh: '泛音晶辉', en: 'Glass harmonic'),
      _ => pickUiText(i18n, zh: '独奏弓法', en: 'Solo bow'),
    };
  }

  String _presetSubtitle(AppI18n i18n, _ViolinPreset preset) {
    return switch (preset.id) {
      'warm_legato' => pickUiText(
        i18n,
        zh: '更柔和的弓压和更长的尾音，适合慢速歌唱线。',
        en: 'Softer bow pressure with a longer tail for lyrical lines.',
      ),
      'glass_harmonic' => pickUiText(
        i18n,
        zh: '更亮的泛音和更清晰的前缘，适合空灵铺底。',
        en: 'Brighter harmonics with a cleaner edge for airy textures.',
      ),
      _ => pickUiText(
        i18n,
        zh: '平衡的独奏音色，适合旋律滑音。',
        en: 'Balanced solo tone for melodic glides.',
      ),
    };
  }

  String _scaleLabel(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'minor' => pickUiText(i18n, zh: '小调', en: 'Minor'),
      'dorian' => pickUiText(i18n, zh: '多利亚', en: 'Dorian'),
      'pentatonic' => pickUiText(i18n, zh: '五声音阶', en: 'Pentatonic'),
      'chromatic' => pickUiText(i18n, zh: '半音阶', en: 'Chromatic'),
      _ => pickUiText(i18n, zh: '大调', en: 'Major'),
    };
  }

  String _styleLabel(AppI18n i18n, String styleId) {
    return switch (styleId) {
      'warm' => pickUiText(i18n, zh: '柔暖', en: 'Warm'),
      'glass' => pickUiText(i18n, zh: '晶亮', en: 'Glass'),
      _ => pickUiText(i18n, zh: '独奏', en: 'Solo'),
    };
  }

  String _positionLabel(AppI18n i18n, int positionIndex) {
    return pickUiText(
      i18n,
      zh: '把位 ${positionIndex + 1}',
      en: 'Position ${positionIndex + 1}',
    );
  }

  List<int> _notesForString(_ViolinString string) {
    final offset = _positionOffsets[_positionIndex];
    final intervals = _scaleIntervals[_scaleId] ?? _scaleIntervals['major']!;
    return intervals
        .map((interval) => string.openMidi + offset + interval)
        .toList(growable: false);
  }

  String _noteLabelFromMidi(int midi) {
    final pitch = _pitchNames[((midi % 12) + 12) % 12];
    final octave = (midi ~/ 12) - 1;
    return '$pitch$octave';
  }

  double _frequencyFromMidi(int midi) {
    return (440 * math.pow(2, (midi - 69) / 12)).toDouble();
  }

  Future<void> _playSustain({
    required int stringIndex,
    required int noteIndex,
  }) async {
    final notes = _notesForString(_strings[stringIndex]);
    final midi = notes[noteIndex.clamp(0, notes.length - 1)];
    await _sustainLoop.play(
      ToolboxAudioBank.violinNote(
        _frequencyFromMidi(midi),
        style: _activePreset.styleId,
        bow: _bow,
        reverb: _reverb,
      ),
      volume: (0.42 + _bow * 0.5).clamp(0.0, 1.0),
    );

    if (_activePointers.length >= 2) {
      final secondStringIndex = math.min(stringIndex + 1, _strings.length - 1);
      if (secondStringIndex != stringIndex) {
        final secondNotes = _notesForString(_strings[secondStringIndex]);
        final secondMidi =
            secondNotes[noteIndex.clamp(0, secondNotes.length - 1)];
        await _doubleStopLoop.play(
          ToolboxAudioBank.violinNote(
            _frequencyFromMidi(secondMidi),
            style: _activePreset.styleId,
            bow: (_bow * 0.92).clamp(0.15, 1.0),
            reverb: _reverb,
          ),
          volume: (0.32 + _bow * 0.36).clamp(0.0, 1.0),
        );
      }
    } else {
      await _doubleStopLoop.stop();
    }

    if (!mounted) return;
    setState(() {
      _activeStringIndex = stringIndex;
      _activeNoteMidi = midi;
      _lastNoteLabel = _noteLabelFromMidi(midi);
    });
  }

  Future<void> _stopSustain() async {
    await _sustainLoop.stop();
    await _doubleStopLoop.stop();
    if (!mounted) return;
    setState(() {
      _activeStringIndex = null;
      _activeNoteMidi = null;
    });
  }

  void _applyPreset(String presetId) {
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    setState(() {
      _presetId = preset.id;
      _scaleId = preset.scaleId;
      _bow = preset.bow;
      _reverb = preset.reverb;
    });
  }

  void _handleFingerboardTouch(Offset localPosition, Size size) {
    final laneHeight = size.height / _strings.length;
    final stringIndex = (localPosition.dy / laneHeight).floor().clamp(
      0,
      _strings.length - 1,
    );
    final notes = _notesForString(_strings[stringIndex]);
    final cellWidth = size.width / notes.length;
    final noteIndex = (localPosition.dx / cellWidth).floor().clamp(
      0,
      notes.length - 1,
    );
    final midi = notes[noteIndex];
    if (_activeStringIndex == stringIndex && _activeNoteMidi == midi) {
      return;
    }
    HapticFeedback.selectionClick();
    unawaited(_playSustain(stringIndex: stringIndex, noteIndex: noteIndex));
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
  }

  void _handlePointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      unawaited(_doubleStopLoop.stop());
    }
  }

  Widget _buildFingerboardStage(
    BuildContext context,
    AppI18n i18n,
    ThemeData theme, {
    required double width,
    required double height,
  }) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      child: GestureDetector(
        onPanStart: (details) =>
            _handleFingerboardTouch(details.localPosition, Size(width, height)),
        onPanUpdate: (details) =>
            _handleFingerboardTouch(details.localPosition, Size(width, height)),
        onPanEnd: (_) => unawaited(_stopSustain()),
        onPanCancel: () => unawaited(_stopSustain()),
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF3A2A22),
                Color(0xFF5D4638),
                Color(0xFF2A1D18),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              ...List<Widget>.generate(_strings.length, (index) {
                final string = _strings[index];
                final active = _activeStringIndex == index;
                return Positioned(
                  left: 16,
                  right: 16,
                  top: (height / _strings.length) * index + 18,
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 38,
                        child: Text(
                          string.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: active ? 4.6 : 3.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: active
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFE5D7C5),
                            boxShadow: active
                                ? <BoxShadow>[
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFBBF24,
                                      ).withValues(alpha: 0.32),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : const <BoxShadow>[],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Positioned(
                left: 64,
                right: 18,
                bottom: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _notesForString(_strings.last)
                      .map(
                        (midi) => Text(
                          _noteLabelFromMidi(midi),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              Positioned(
                right: 16,
                top: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      pickUiText(
                        i18n,
                        zh: '双指可触发双音',
                        en: 'Two fingers enable double-stop',
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViolinSettingsContent(
    BuildContext context,
    AppI18n i18n,
    ThemeData theme,
  ) {
    final preset = _activePreset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          pickUiText(i18n, zh: '小提琴设置', en: 'Violin settings'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: 'Scale',
              value: _scaleLabel(i18n, _scaleId),
            ),
            ToolboxMetricCard(
              label: 'Position',
              value: _positionLabel(i18n, _positionIndex),
            ),
            ToolboxMetricCard(
              label: 'Preset',
              value: _presetLabel(i18n, preset),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets
              .map(
                (item) => ChoiceChip(
                  label: Text(_presetLabel(i18n, item)),
                  selected: item.id == _presetId,
                  onSelected: (_) => _applyPreset(item.id),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Text(_presetSubtitle(i18n, preset), style: theme.textTheme.bodySmall),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scaleIntervals.keys
              .map(
                (scaleId) => ChoiceChip(
                  label: Text(_scaleLabel(i18n, scaleId)),
                  selected: _scaleId == scaleId,
                  onSelected: (_) => setState(() => _scaleId = scaleId),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(_positionOffsets.length, (index) {
            return ChoiceChip(
              label: Text(_positionLabel(i18n, index)),
              selected: _positionIndex == index,
              onSelected: (_) => setState(() => _positionIndex = index),
            );
          }),
        ),
        const SizedBox(height: 14),
        Text(
          pickUiText(
            i18n,
            zh: '弓压 ${(_bow * 100).round()}% · 音色 ${_styleLabel(i18n, preset.styleId)}',
            en: 'Bow ${(_bow * 100).round()}% · Tone ${_styleLabel(i18n, preset.styleId)}',
          ),
        ),
        Slider(
          value: _bow,
          min: 0.15,
          max: 1.0,
          divisions: 17,
          onChanged: (value) => setState(() => _bow = value),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '残响 ${(_reverb * 100).round()}%',
            en: 'Reverb ${(_reverb * 100).round()}%',
          ),
        ),
        Slider(
          value: _reverb,
          min: 0.0,
          max: 0.5,
          divisions: 10,
          onChanged: (value) => setState(() => _reverb = value),
        ),
      ],
    );
  }

  Future<void> _openViolinSettingsSheet(
    BuildContext context,
    AppI18n i18n,
    ThemeData theme,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SingleChildScrollView(
          child: _buildViolinSettingsContent(sheetContext, i18n, theme),
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_sustainLoop.dispose());
    unawaited(_doubleStopLoop.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final preset = _activePreset;

    if (widget.fullScreen) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF020617), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stageHeight = math.min(360.0, constraints.maxHeight - 120);
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 54, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              _PianoOverlayChip(
                                label: 'Scale',
                                value: _scaleLabel(i18n, _scaleId),
                              ),
                              _PianoOverlayChip(
                                label: 'Position',
                                value: _positionLabel(i18n, _positionIndex),
                              ),
                              _PianoOverlayChip(
                                label: 'Preset',
                                value: _presetLabel(i18n, preset),
                              ),
                              const _PianoOverlayChip(
                                label: 'Gesture',
                                value: '2-finger double-stop',
                              ),
                            ],
                          ),
                          const Spacer(),
                          _buildFingerboardStage(
                            context,
                            i18n,
                            theme,
                            width: constraints.maxWidth - 32,
                            height: stageHeight,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 8,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.38),
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 8,
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          _openViolinSettingsSheet(context, i18n, theme),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.38),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return _buildInstrumentPanelShell(
      context,
      fullScreen: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '弦数', en: 'Strings'),
                value: '${_strings.length}',
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '调式', en: 'Scale'),
                value: _scaleLabel(i18n, _scaleId),
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '把位', en: 'Position'),
                value: _positionLabel(i18n, _positionIndex),
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '最近音符', en: 'Last note'),
                value: _lastNoteLabel ?? '--',
              ),
            ],
          ),
          const SizedBox(height: 14),
          SectionHeader(
            title: pickUiText(i18n, zh: '预设包', en: 'Preset pack'),
            subtitle: pickUiText(
              i18n,
              zh: '同步切换弓法音色、空间感和默认调式。',
              en: 'Switch bow tone, room feel, and default scale together.',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets
                .map(
                  (item) => ChoiceChip(
                    label: Text(_presetLabel(i18n, item)),
                    selected: item.id == _presetId,
                    onSelected: (_) => _applyPreset(item.id),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          Text(_presetSubtitle(i18n, preset), style: theme.textTheme.bodySmall),
          const SizedBox(height: 14),
          SectionHeader(
            title: pickUiText(i18n, zh: '指板舞台', en: 'Fingerboard stage'),
            subtitle: pickUiText(
              i18n,
              zh: '横向滑动改变音高，纵向切换弦位；优先保证滑动演奏区完整。',
              en: 'Slide horizontally for pitch and vertically for strings while keeping the playing stage intact.',
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) => _buildFingerboardStage(
              context,
              i18n,
              theme,
              width: constraints.maxWidth,
              height: 220,
            ),
          ),
          const SizedBox(height: 14),
          SectionHeader(
            title: pickUiText(i18n, zh: '调式与把位', en: 'Scale and position'),
            subtitle: pickUiText(
              i18n,
              zh: '用调式分类和把位窗口控制手机屏幕中的有效演奏区域。',
              en: 'Use scale categories and position windows to keep the fingerboard playable on phones.',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _scaleIntervals.keys
                .map(
                  (scaleId) => ChoiceChip(
                    label: Text(_scaleLabel(i18n, scaleId)),
                    selected: _scaleId == scaleId,
                    onSelected: (_) => setState(() => _scaleId = scaleId),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(_positionOffsets.length, (index) {
              return ChoiceChip(
                label: Text(_positionLabel(i18n, index)),
                selected: _positionIndex == index,
                onSelected: (_) => setState(() => _positionIndex = index),
              );
            }),
          ),
          const SizedBox(height: 14),
          SectionHeader(
            title: pickUiText(i18n, zh: '弓压与空间', en: 'Bow and space'),
            subtitle: pickUiText(
              i18n,
              zh: '像竖琴一样开放弓压和残响参数。',
              en: 'Expose bow pressure and reverb controls like the harp module.',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '弓压 ${(_bow * 100).round()}% · 音色 ${_styleLabel(i18n, preset.styleId)}',
              en: 'Bow ${(_bow * 100).round()}% · Tone ${_styleLabel(i18n, preset.styleId)}',
            ),
          ),
          Slider(
            value: _bow,
            min: 0.15,
            max: 1.0,
            divisions: 17,
            onChanged: (value) => setState(() => _bow = value),
          ),
          Text(
            pickUiText(
              i18n,
              zh: '残响 ${(_reverb * 100).round()}%',
              en: 'Reverb ${(_reverb * 100).round()}%',
            ),
          ),
          Slider(
            value: _reverb,
            min: 0.0,
            max: 0.5,
            divisions: 10,
            onChanged: (value) => setState(() => _reverb = value),
          ),
        ],
      ),
    );
  }
}
