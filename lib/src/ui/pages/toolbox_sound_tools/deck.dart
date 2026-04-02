part of '../toolbox_sound_tools.dart';

class SoothingMusicToolPage extends StatelessWidget {
  const SoothingMusicToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '舒缓音乐', en: 'Soothing music'),
      subtitle: pickUiText(
        i18n,
        zh: '本地合成的柔和氛围音色，用来慢慢降速与放松。',
        en: 'Locally synthesized soft textures for slowing down and settling your rhythm.',
      ),
      child: const _SoothingMusicTool(),
    );
  }
}

class HarpToolPage extends StatelessWidget {
  const HarpToolPage({super.key, this.fullScreen = false});

  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    if (fullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _HarpTool(
          fullScreen: true,
          onExitFullScreen: () => Navigator.of(context).pop(),
        ),
      );
    }
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '空灵竖琴', en: 'Ethereal harp'),
      subtitle: pickUiText(
        i18n,
        zh: '在同一面板中切换竖琴、钢琴、长笛、鼓垫、吉他、三角铁、小提琴与拾音器。',
        en: 'Switch harp, piano, flute, drum pad, guitar, triangle, violin, and pickup in one instrument deck.',
      ),
      child: const _HarpInstrumentDeck(),
    );
  }
}

enum _HarpDeckInstrument {
  harp,
  piano,
  flute,
  drumPad,
  guitar,
  triangle,
  violin,
  pickup,
}

class _HarpInstrumentDeck extends StatefulWidget {
  const _HarpInstrumentDeck();

  @override
  State<_HarpInstrumentDeck> createState() => _HarpInstrumentDeckState();
}

class _HarpInstrumentDeckState extends State<_HarpInstrumentDeck> {
  _HarpDeckInstrument _selected = _HarpDeckInstrument.harp;
  _HarpConfig _harpConfig = const _HarpConfig();
  bool _switchSectionExpanded = true;
  bool _infoSectionExpanded = false;

  void _onHarpConfigChanged(_HarpConfig config) {
    _harpConfig = config;
  }

  String _label(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => pickUiText(i18n, zh: '钢琴', en: 'Piano'),
      _HarpDeckInstrument.flute => pickUiText(i18n, zh: '长笛', en: 'Flute'),
      _HarpDeckInstrument.drumPad => pickUiText(i18n, zh: '鼓垫', en: 'Drum pad'),
      _HarpDeckInstrument.guitar => pickUiText(i18n, zh: '吉他', en: 'Guitar'),
      _HarpDeckInstrument.triangle => pickUiText(
        i18n,
        zh: '三角铁',
        en: 'Triangle',
      ),
      _HarpDeckInstrument.violin => pickUiText(i18n, zh: '小提琴', en: 'Violin'),
      _HarpDeckInstrument.pickup => pickUiText(i18n, zh: '拾音器', en: 'Pickup'),
      _ => pickUiText(i18n, zh: '竖琴', en: 'Harp'),
    };
  }

  String _subtitle(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => pickUiText(
        i18n,
        zh: '带预设音色包的触控钢琴。',
        en: 'Touch piano with preset packs.',
      ),
      _HarpDeckInstrument.flute => pickUiText(
        i18n,
        zh: '支持调式与音色预设的长笛。',
        en: 'Flute with scale and timbre presets.',
      ),
      _HarpDeckInstrument.drumPad => pickUiText(
        i18n,
        zh: '四块鼓垫，可切换鼓组。',
        en: 'Four pads with switchable drum kits.',
      ),
      _HarpDeckInstrument.guitar => pickUiText(
        i18n,
        zh: '支持点弦与扫弦的吉他面板。',
        en: 'Guitar panel for pluck and strum.',
      ),
      _HarpDeckInstrument.triangle => pickUiText(
        i18n,
        zh: '带振铃风格预设的三角铁。',
        en: 'Triangle with ring-style presets.',
      ),
      _HarpDeckInstrument.violin => pickUiText(
        i18n,
        zh: '支持滑奏与可弹调式区域的小提琴舞台。',
        en: 'Touch-slide violin stage with playable scale regions.',
      ),
      _HarpDeckInstrument.pickup => pickUiText(
        i18n,
        zh: '使用麦克风实时校准拾音电平、峰值、音高与音色平衡。',
        en: 'Use the microphone to calibrate pickup level, peaks, pitch, and tonal balance in real time.',
      ),
      _ => pickUiText(
        i18n,
        zh: '支持二阶段手势与音色控制的竖琴。',
        en: 'Harp with phase-two gesture and tone controls.',
      ),
    };
  }

  String _gestureHint(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => pickUiText(
        i18n,
        zh: 'Use two thumbs for chord + melody.',
        en: 'Use two thumbs for chord + melody.',
      ),
      _HarpDeckInstrument.flute => pickUiText(
        i18n,
        zh: 'Hold holes first, then tap note buttons.',
        en: 'Hold holes first, then tap note buttons.',
      ),
      _HarpDeckInstrument.drumPad => pickUiText(
        i18n,
        zh: 'Multi-touch on pads for fuller groove.',
        en: 'Multi-touch on pads for fuller groove.',
      ),
      _HarpDeckInstrument.guitar => pickUiText(
        i18n,
        zh: 'Tap for pluck, swipe across strings for strum.',
        en: 'Tap for pluck, swipe across strings for strum.',
      ),
      _HarpDeckInstrument.triangle => pickUiText(
        i18n,
        zh: 'Light taps for accents, leave ring for ambience.',
        en: 'Light taps for accents, leave ring for ambience.',
      ),
      _HarpDeckInstrument.violin => pickUiText(
        i18n,
        zh: 'Slow drag for stable tone, fast drag for expression.',
        en: 'Slow drag for stable tone, fast drag for expression.',
      ),
      _HarpDeckInstrument.pickup => pickUiText(
        i18n,
        zh: 'Tune in a quiet room before real-time pickup check.',
        en: 'Tune in a quiet room before real-time pickup check.',
      ),
      _ => pickUiText(
        i18n,
        zh: 'Tap a single string or swipe to sweep.',
        en: 'Tap a single string or swipe to sweep.',
      ),
    };
  }

  String _mixHint(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => pickUiText(
        i18n,
        zh: 'Start with medium reverb for clearer runs.',
        en: 'Start with medium reverb for clearer runs.',
      ),
      _HarpDeckInstrument.flute => pickUiText(
        i18n,
        zh: 'Breath around 50-60% is usually easiest to control.',
        en: 'Breath around 50-60% is usually easiest to control.',
      ),
      _HarpDeckInstrument.drumPad => pickUiText(
        i18n,
        zh: 'Keep drive moderate to avoid clipping on phones.',
        en: 'Keep drive moderate to avoid clipping on phones.',
      ),
      _HarpDeckInstrument.guitar => pickUiText(
        i18n,
        zh: 'Raise strum volume only after pluck level is balanced.',
        en: 'Raise strum volume only after pluck level is balanced.',
      ),
      _HarpDeckInstrument.triangle => pickUiText(
        i18n,
        zh: 'High ring + low damping works best for sleep ambience.',
        en: 'High ring + low damping works best for sleep ambience.',
      ),
      _HarpDeckInstrument.violin => pickUiText(
        i18n,
        zh: 'Use shorter reverb to keep pitch center focused.',
        en: 'Use shorter reverb to keep pitch center focused.',
      ),
      _HarpDeckInstrument.pickup => pickUiText(
        i18n,
        zh: 'Set gain just below clipping for stable monitoring.',
        en: 'Set gain just below clipping for stable monitoring.',
      ),
      _ => pickUiText(
        i18n,
        zh: 'Try realism presets first, then fine-tune damping.',
        en: 'Try realism presets first, then fine-tune damping.',
      ),
    };
  }

  String _layoutHint(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => pickUiText(
        i18n,
        zh: 'Portrait recommended.',
        en: 'Portrait recommended.',
      ),
      _HarpDeckInstrument.pickup => pickUiText(
        i18n,
        zh: 'Portrait recommended.',
        en: 'Portrait recommended.',
      ),
      _ => pickUiText(
        i18n,
        zh: 'Landscape recommended.',
        en: 'Landscape recommended.',
      ),
    };
  }

  IconData _icon(_HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => Icons.piano_rounded,
      _HarpDeckInstrument.flute => Icons.air_rounded,
      _HarpDeckInstrument.drumPad => Icons.album_rounded,
      _HarpDeckInstrument.guitar => Icons.queue_music_rounded,
      _HarpDeckInstrument.triangle => Icons.change_history_rounded,
      _HarpDeckInstrument.violin => Icons.multitrack_audio_rounded,
      _HarpDeckInstrument.pickup => Icons.graphic_eq_rounded,
      _ => Icons.music_note_rounded,
    };
  }

  Widget _activeTool() {
    return switch (_selected) {
      _HarpDeckInstrument.piano => const _PianoTool(),
      _HarpDeckInstrument.flute => const _FluteTool(),
      _HarpDeckInstrument.drumPad => const _DrumPadTool(),
      _HarpDeckInstrument.guitar => const _GuitarTool(),
      _HarpDeckInstrument.triangle => const _TriangleTool(),
      _HarpDeckInstrument.violin => const _ViolinTool(),
      _HarpDeckInstrument.pickup => const _PickupTool(),
      _ => _HarpTool(
        initialConfig: _harpConfig,
        onConfigChanged: _onHarpConfigChanged,
      ),
    };
  }

  void _openInstrumentFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DeckInstrumentFullScreenPage(
          instrument: _selected,
          harpConfig: _harpConfig,
          onHarpConfigChanged: _onHarpConfigChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Card(
          child: ExpansionTile(
            initiallyExpanded: _switchSectionExpanded,
            onExpansionChanged: (value) {
              setState(() {
                _switchSectionExpanded = value;
              });
            },
            title: Text(pickUiText(i18n, zh: '切换乐器', en: 'Instrument switch')),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '在一个面板中切换 8 种乐器。',
                en: 'Switch among 8 instruments in one deck.',
              ),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 6,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final item in _HarpDeckInstrument.values)
                          ChoiceChip(
                            avatar: Icon(_icon(item), size: 16),
                            label: Text(_label(i18n, item)),
                            selected: item == _selected,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            onSelected: (_) => setState(() => _selected = item),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: _openInstrumentFullScreen,
                      icon: const Icon(Icons.open_in_full_rounded),
                      label: Text(
                        pickUiText(i18n, zh: '全屏', en: 'Full screen'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _infoSectionExpanded = true;
                        });
                      },
                      icon: const Icon(Icons.tips_and_updates_rounded),
                      label: const Text('Quick tips'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current: ${_label(i18n, _selected)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            initiallyExpanded: _infoSectionExpanded,
            onExpansionChanged: (value) {
              setState(() {
                _infoSectionExpanded = value;
              });
            },
            title: Text(pickUiText(i18n, zh: '乐器信息', en: 'Instrument info')),
            subtitle: Text(_label(i18n, _selected)),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(_icon(_selected), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _subtitle(i18n, _selected),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _DeckHintChip(
                          icon: Icons.touch_app_rounded,
                          text: _gestureHint(i18n, _selected),
                        ),
                        _DeckHintChip(
                          icon: Icons.tune_rounded,
                          text: _mixHint(i18n, _selected),
                        ),
                        _DeckHintChip(
                          icon: Icons.screen_rotation_alt_rounded,
                          text: _layoutHint(i18n, _selected),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<_HarpDeckInstrument>(_selected),
            child: _activeTool(),
          ),
        ),
      ],
    );
  }
}

class _DeckHintChip extends StatelessWidget {
  const _DeckHintChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _DeckInstrumentFullScreenPage extends StatefulWidget {
  const _DeckInstrumentFullScreenPage({
    required this.instrument,
    this.harpConfig,
    this.onHarpConfigChanged,
  });

  final _HarpDeckInstrument instrument;
  final _HarpConfig? harpConfig;
  final void Function(_HarpConfig config)? onHarpConfigChanged;

  @override
  State<_DeckInstrumentFullScreenPage> createState() =>
      _DeckInstrumentFullScreenPageState();
}

class _DeckInstrumentFullScreenPageState
    extends State<_DeckInstrumentFullScreenPage> {
  @override
  void initState() {
    super.initState();
    unawaited(
      widget.instrument == _HarpDeckInstrument.piano
          ? _enterToolboxPortraitMode()
          : _enterToolboxLandscapeMode(),
    );
  }

  @override
  void dispose() {
    unawaited(_exitToolboxLandscapeMode());
    super.dispose();
  }

  Widget _tool() {
    return switch (widget.instrument) {
      _HarpDeckInstrument.piano => const _PianoTool(fullScreen: true),
      _HarpDeckInstrument.flute => const _FluteTool(fullScreen: true),
      _HarpDeckInstrument.drumPad => const _DrumPadTool(fullScreen: true),
      _HarpDeckInstrument.guitar => const _GuitarTool(fullScreen: true),
      _HarpDeckInstrument.triangle => const _TriangleTool(fullScreen: true),
      _HarpDeckInstrument.violin => const _ViolinTool(fullScreen: true),
      _HarpDeckInstrument.pickup => const _PickupTool(fullScreen: true),
      _ => _HarpTool(
        fullScreen: true,
        initialConfig: widget.harpConfig,
        onConfigChanged: widget.onHarpConfigChanged,
        onExitFullScreen: () => Navigator.of(context).pop(),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _tool());
  }
}

class FocusBeatsToolPage extends StatelessWidget {
  const FocusBeatsToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '专注节拍', en: 'Focus beats'),
      subtitle: pickUiText(
        i18n,
        zh: '可调 BPM 的本地节拍器，适合写作、学习或呼吸同步。',
        en: 'A local BPM-adjustable metronome for writing, study, or breath syncing.',
      ),
      child: const _FocusBeatsTool(),
    );
  }
}

class WoodfishToolPage extends StatelessWidget {
  const WoodfishToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '电子木鱼', en: 'Digital woodfish'),
      subtitle: pickUiText(
        i18n,
        zh: '轻敲一次记一次数，也给自己一个短暂重置。',
        en: 'Tap once for a count and give yourself a short reset in the middle of the day.',
      ),
      child: const _WoodfishTool(),
    );
  }
}

class PianoToolPage extends StatelessWidget {
  const PianoToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '钢琴', en: 'Piano'),
      subtitle: pickUiText(
        i18n,
        zh: '本地触控钢琴，带响应式按键与可切换预设包。',
        en: 'Local touch piano with responsive keys and switchable preset packs.',
      ),
      child: const _PianoTool(),
    );
  }
}

class FluteToolPage extends StatelessWidget {
  const FluteToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '长笛', en: 'Flute'),
      subtitle: pickUiText(
        i18n,
        zh: '呼吸感本地长笛，支持调式切换与预设包。',
        en: 'Breath-like local flute notes with scale switching and preset packs.',
      ),
      child: const _FluteTool(),
    );
  }
}

class DrumPadToolPage extends StatelessWidget {
  const DrumPadToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '鼓垫', en: 'Drum pad'),
      subtitle: pickUiText(
        i18n,
        zh: '紧凑鼓垫，含底鼓、军鼓、踩镲和嗵鼓，并支持鼓组预设。',
        en: 'Compact drum pad with kick, snare, hi-hat and tom, plus kit presets.',
      ),
      child: const _DrumPadTool(),
    );
  }
}

class GuitarToolPage extends StatelessWidget {
  const GuitarToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '吉他', en: 'Guitar'),
      subtitle: pickUiText(
        i18n,
        zh: '可点弦或扫弦，支持尼龙、钢弦与氛围预设包。',
        en: 'Tap strings or strum with local nylon, steel, and ambient preset packs.',
      ),
      child: const _GuitarTool(),
    );
  }
}

class TriangleToolPage extends StatelessWidget {
  const TriangleToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '三角铁', en: 'Triangle'),
      subtitle: pickUiText(
        i18n,
        zh: '干净金属敲击，振铃和风格预设可调。',
        en: 'Clean metallic strikes with controllable ring and style presets.',
      ),
      child: const _TriangleTool(),
    );
  }
}

class PickupToolPage extends StatelessWidget {
  const PickupToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '拾音器', en: 'Pickup'),
      subtitle: pickUiText(
        i18n,
        zh: '使用手机麦克风分析拾音电平、峰值、音高与明亮度。',
        en: 'Use the phone microphone to analyze pickup level, peaks, pitch, and brightness.',
      ),
      child: const _PickupTool(),
    );
  }
}
