part of '../toolbox_sound_tools.dart';

class _SoothingPreset {
  const _SoothingPreset({required this.id});

  final String id;

  String title(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.preset.$id.title');

  String subtitle(AppI18n i18n) =>
      i18n.t('toolbox.sound.soothing.preset.$id.subtitle');
}

class _SoothingMusicTool extends StatefulWidget {
  const _SoothingMusicTool();

  @override
  State<_SoothingMusicTool> createState() => _SoothingMusicToolState();
}

class _SoothingMusicToolState extends State<_SoothingMusicTool>
    with SingleTickerProviderStateMixin {
  static const List<_SoothingPreset> _presets = <_SoothingPreset>[
    _SoothingPreset(id: 'moon'),
    _SoothingPreset(id: 'mist'),
    _SoothingPreset(id: 'harbor'),
  ];

  final ToolboxLoopController _loop = ToolboxLoopController();
  late final AnimationController _pulseController;

  String _presetId = _presets.first.id;
  double _volume = 0.56;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    unawaited(_loop.dispose());
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_playing) {
      await _loop.stop();
      _pulseController.stop();
      setState(() {
        _playing = false;
      });
      return;
    }
    await _loop.play(ToolboxAudioBank.soothingLoop(_presetId), volume: _volume);
    _pulseController.repeat();
    setState(() {
      _playing = true;
    });
  }

  Future<void> _selectPreset(String presetId) async {
    if (_presetId == presetId) return;
    setState(() {
      _presetId = presetId;
    });
    if (_playing) {
      await _loop.play(
        ToolboxAudioBank.soothingLoop(_presetId),
        volume: _volume,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final i18n = _toolboxI18n(context);
    final preset = _presets.firstWhere((item) => item.id == _presetId);

    return Column(
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 220,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final t = _playing ? _pulseController.value : 0.0;
                      final scale = 0.94 + math.sin(t * math.pi * 2) * 0.04;
                      final glow = 0.18 + math.sin(t * math.pi * 2) * 0.08;
                      return Center(
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: <Color>[
                                  theme.colorScheme.primary.withValues(
                                    alpha: 0.24 + glow,
                                  ),
                                  theme.colorScheme.primaryContainer,
                                  theme.colorScheme.surfaceContainerHighest,
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.12 + glow,
                                  ),
                                  blurRadius: 32,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  _playing
                                      ? Icons.graphic_eq_rounded
                                      : Icons.spa_rounded,
                                  size: 42,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  preset.title(i18n),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preset.subtitle(i18n),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _togglePlayback,
                  icon: Icon(
                    _playing
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                  ),
                  label: Text(
                    i18n.t(
                      _playing
                          ? 'toolbox.sound.soothing.pause_ambience'
                          : 'toolbox.sound.soothing.start_ambience',
                    ),
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
                  title: i18n.t('toolbox.sound.soothing.preset_section_title'),
                  subtitle: i18n.t(
                    'toolbox.sound.soothing.preset_section_subtitle',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets
                      .map((item) {
                        final selected = item.id == _presetId;
                        return ChoiceChip(
                          label: Text(item.title(i18n)),
                          selected: selected,
                          onSelected: (_) => _selectPreset(item.id),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
                Text(
                  i18n.t(
                    'toolbox.sound.soothing.volume_percent',
                    params: <String, Object?>{
                      'percent': (100 * _volume).round(),
                    },
                  ),
                  style: theme.textTheme.labelLarge,
                ),
                Slider(
                  value: _volume,
                  min: 0.15,
                  max: 1,
                  onChanged: (value) async {
                    setState(() {
                      _volume = value;
                    });
                    if (_playing) {
                      await _loop.setVolume(value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
