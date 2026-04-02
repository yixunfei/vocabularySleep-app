part of '../toolbox_sound_tools.dart';

class SoothingMusicToolPage extends StatelessWidget {
  const SoothingMusicToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(
        i18n,
        zh: '舒缓轻音',
        en: 'Soothing music',
        ja: 'ヒーリング音楽',
        de: 'Beruhigende Musik',
        fr: 'Musique apaisante',
        es: 'Musica relajante',
        ru: 'Успокаивающая музыка',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '本地合成的柔和氛围音色，用来慢慢降速与放松。',
        en: 'Locally synthesized soft textures for slowing down and settling your rhythm.',
        ja: 'ローカル合成の柔らかい音色で、気持ちとペースを落ち着かせます。',
        de: 'Lokal synthetisierte, weiche Klangtexturen zum Entschleunigen.',
        fr: 'Textures sonores locales et douces pour ralentir et se poser.',
        es: 'Texturas suaves sintetizadas en local para bajar el ritmo y relajarte.',
        ru: 'Локально синтезированные мягкие текстуры для замедления и расслабления.',
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
      title: pickUiText(
        i18n,
        zh: '空灵竖琴',
        en: 'Ethereal harp',
        ja: 'エーテルハープ',
        de: 'Ätherharfe',
        fr: 'Harpe éthérée',
        es: 'Arpa etérea',
        ru: 'Эфирная арфа',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '在同一乐器台中切换竖琴、钢琴、长笛、鼓垫、吉他、三角铁和小提琴。',
        en: 'Switch harp, piano, flute, drum pad, guitar, triangle, violin, and pickup in one instrument deck.',
        ja: '1つのデッキでハープ、ピアノ、フルート、ドラム、ギター、トライアングルを切替。',
        de: 'Harfe, Klavier, Flöte, Drum-Pad, Gitarre und Triangel in einem Deck umschalten.',
        fr: 'Basculez harpe, piano, flûte, pad de batterie, guitare et triangle dans un même deck.',
        es: 'Cambia arpa, piano, flauta, pad de batería, guitarra y triángulo en un solo panel.',
        ru: 'Переключайте арфу, пианино, флейту, драм-пэд, гитару и треугольник в одной панели.',
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

  void _onHarpConfigChanged(_HarpConfig config) {
    _harpConfig = config;
  }

  String _label(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => pickUiText(
        i18n,
        zh: '钢琴',
        en: 'Piano',
        ja: 'ピアノ',
        de: 'Klavier',
        fr: 'Piano',
        es: 'Piano',
        ru: 'Пианино',
      ),
      _HarpDeckInstrument.flute => pickUiText(
        i18n,
        zh: '长笛',
        en: 'Flute',
        ja: 'フルート',
        de: 'Flöte',
        fr: 'Flûte',
        es: 'Flauta',
        ru: 'Флейта',
      ),
      _HarpDeckInstrument.drumPad => pickUiText(
        i18n,
        zh: '鼓垫',
        en: 'Drum pad',
        ja: 'ドラムパッド',
        de: 'Drum-Pad',
        fr: 'Pad de batterie',
        es: 'Pad de batería',
        ru: 'Драм-пэд',
      ),
      _HarpDeckInstrument.guitar => pickUiText(
        i18n,
        zh: '吉他',
        en: 'Guitar',
        ja: 'ギター',
        de: 'Gitarre',
        fr: 'Guitare',
        es: 'Guitarra',
        ru: 'Гитара',
      ),
      _HarpDeckInstrument.triangle => pickUiText(
        i18n,
        zh: '三角铁',
        en: 'Triangle',
        ja: 'トライアングル',
        de: 'Triangel',
        fr: 'Triangle',
        es: 'Triángulo',
        ru: 'Треугольник',
      ),
      _HarpDeckInstrument.violin => pickUiText(
        i18n,
        zh: '小提琴',
        en: 'Violin',
        ja: 'バイオリン',
        de: 'Violine',
        fr: 'Violon',
        es: 'Violin',
        ru: 'Скрипка',
      ),
      _ => pickUiText(
        i18n,
        zh: '竖琴',
        en: 'Harp',
        ja: 'ハープ',
        de: 'Harfe',
        fr: 'Harpe',
        es: 'Arpa',
        ru: 'Арфа',
      ),
    };
  }

  String _subtitle(AppI18n i18n, _HarpDeckInstrument instrument) {
    return switch (instrument) {
      _HarpDeckInstrument.piano => pickUiText(
        i18n,
        zh: '带预设包的触控钢琴。',
        en: 'Touch piano with preset packs.',
        ja: 'プリセット対応のタッチピアノ。',
        de: 'Touch-Klavier mit Preset-Paketen.',
        fr: 'Piano tactile avec packs de préréglages.',
        es: 'Piano táctil con paquetes de presets.',
        ru: 'Сенсорное пианино с пакетами пресетов.',
      ),
      _HarpDeckInstrument.flute => pickUiText(
        i18n,
        zh: '支持调式与音色预设的长笛。',
        en: 'Flute with scale and timbre presets.',
        ja: 'スケールと音色プリセット対応のフルート。',
        de: 'Flöte mit Skalen- und Klang-Presets.',
        fr: 'Flûte avec gammes et presets de timbre.',
        es: 'Flauta con escalas y presets de timbre.',
        ru: 'Флейта с ладовыми и тембровыми пресетами.',
      ),
      _HarpDeckInstrument.drumPad => pickUiText(
        i18n,
        zh: '四块鼓垫与鼓组预设切换。',
        en: 'Four pads with switchable drum kits.',
        ja: '4パッドと切替可能なドラムキット。',
        de: 'Vier Pads mit umschaltbaren Drum-Kits.',
        fr: 'Quatre pads avec kits de batterie commutables.',
        es: 'Cuatro pads con kits de batería intercambiables.',
        ru: 'Четыре пэда с переключаемыми наборами ударных.',
      ),
      _HarpDeckInstrument.guitar => pickUiText(
        i18n,
        zh: '点弦与扫弦一体的吉他面板。',
        en: 'Guitar panel for pluck and strum.',
        ja: 'ピッキングとストラムを一体化したギターパネル。',
        de: 'Gitarrenpanel für Zupfen und Strumming.',
        fr: 'Panneau guitare pour pincé et strum.',
        es: 'Panel de guitarra para pulsar y rasguear.',
        ru: 'Гитарная панель для щипка и боя.',
      ),
      _HarpDeckInstrument.triangle => pickUiText(
        i18n,
        zh: '三角铁振铃风格预设。',
        en: 'Triangle with ring-style presets.',
        ja: '余韻スタイルを切替できるトライアングル。',
        de: 'Triangel mit Ring-Style-Presets.',
        fr: 'Triangle avec presets de style de résonance.',
        es: 'Triángulo con presets de estilo de resonancia.',
        ru: 'Треугольник с пресетами стиля звона.',
      ),
      _HarpDeckInstrument.violin => pickUiText(
        i18n,
        zh: '以触摸滑动发音的小提琴舞台，可按调式分区演奏。',
        en: 'Touch-slide violin stage with playable scale regions.',
      ),
      _HarpDeckInstrument.pickup => pickUiText(
        i18n,
        zh: '用麦克风实时分析电平、峰值、音高与音色倾向，辅助完成拾音调校。',
        en: 'Use the microphone to calibrate pickup level, peaks, pitch, and tonal balance in real time.',
      ),
      _ => pickUiText(
        i18n,
        zh: '保留竖琴二阶段调音与手势能力。',
        en: 'Harp with phase-two gesture and tone controls.',
        ja: '第2段階のジェスチャーと音色制御を備えたハープ。',
        de: 'Harfe mit Gesten- und Klangsteuerung aus Phase 2.',
        fr: 'Harpe avec gestes et réglages sonores de phase 2.',
        es: 'Arpa con gestos y control de tono de la fase dos.',
        ru: 'Арфа с жестами и тональными настройками второго этапа.',
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionHeader(
                  title: pickUiText(
                    i18n,
                    zh: '乐器切换',
                    en: 'Instrument switch',
                    ja: '楽器切替',
                    de: 'Instrumentenwechsel',
                    fr: 'Changement d’instrument',
                    es: 'Cambio de instrumento',
                    ru: 'Переключение инструмента',
                  ),
                  subtitle: pickUiText(
                    i18n,
                    zh: '在竖琴模块中集中使用 7 种乐器。',
                    en: 'Use all 8 instruments inside the harp module.',
                    ja: 'ハープモジュール内で6種の楽器を集中使用。',
                    de: 'Alle 6 Instrumente direkt im Harfenmodul nutzen.',
                    fr: 'Utilisez les 6 instruments dans le module harpe.',
                    es: 'Usa los 6 instrumentos dentro del módulo de arpa.',
                    ru: 'Используйте все 6 инструментов внутри модуля арфы.',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _HarpDeckInstrument.values
                      .map(
                        (item) => ChoiceChip(
                          avatar: Icon(_icon(item), size: 16),
                          label: Text(_label(i18n, item)),
                          selected: item == _selected,
                          onSelected: (_) => setState(() => _selected = item),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 8),
                Text(
                  _subtitle(i18n, _selected),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _openInstrumentFullScreen,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(pickUiText(i18n, zh: '全屏模式', en: 'Full screen')),
                ),
              ],
            ),
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
      title: pickUiText(
        i18n,
        zh: '专注节拍',
        en: 'Focus beats',
        ja: '集中ビート',
        de: 'Fokus-Beat',
        fr: 'Rythmes de focus',
        es: 'Beats de enfoque',
        ru: 'Фокус-бит',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '可调 BPM 的本地节拍器，适合学习、写作和呼吸同步。',
        en: 'A local BPM-adjustable metronome for writing, study, or breath syncing.',
        ja: 'BPM調整可能なローカルメトロノーム。学習や呼吸同期に最適。',
        de: 'Lokales BPM-Metronom fur Lernen, Schreiben und Atem-Synchronisation.',
        fr: 'Metronome BPM local pour etude, ecriture et respiration guidee.',
        es: 'Metronomo BPM local para estudio, escritura y sincronizacion de respiracion.',
        ru: 'Локальный метроном с BPM для учебы, письма и дыхательной синхронизации.',
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
      title: pickUiText(
        i18n,
        zh: '电子木鱼',
        en: 'Digital woodfish',
        ja: '電子木魚',
        de: 'Digitales Mokugyo',
        fr: 'Mokugyo numerique',
        es: 'Mokugyo digital',
        ru: 'Цифровой мокугё',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '轻敲一下记一次数，也给自己一个短暂停顿。',
        en: 'Tap once for a count and give yourself a short reset in the middle of the day.',
        ja: '1回タップでカウントし、気分を短くリセット。',
        de: 'Einmal tippen, einmal zahlen und kurz neu fokussieren.',
        fr: 'Un tap pour compter et vous offrir une courte remise a zero.',
        es: 'Un toque para contar y darte un breve reinicio.',
        ru: 'Один удар - один счет и короткая перезагрузка.',
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
      title: pickUiText(
        i18n,
        zh: '钢琴',
        en: 'Piano',
        ja: 'ピアノ',
        de: 'Klavier',
        fr: 'Piano',
        es: 'Piano',
        ru: 'Пианино',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '本地合成触控钢琴，支持实时键盘演奏与预设切换。',
        en: 'Local touch piano with responsive keys and switchable preset packs.',
        ja: 'レスポンスの良いタッチ鍵盤。プリセットを切り替えて演奏できます。',
        de: 'Lokales Touch-Piano mit reaktionsschnellen Tasten und umschaltbaren Presets.',
        fr: 'Piano tactile local avec touches réactives et packs de préréglages.',
        es: 'Piano táctil local con teclas sensibles y paquetes de ajustes.',
        ru: 'Локальное сенсорное пианино с отзывчивыми клавишами и пакетами пресетов.',
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
      title: pickUiText(
        i18n,
        zh: '长笛',
        en: 'Flute',
        ja: 'フルート',
        de: 'Flöte',
        fr: 'Flûte',
        es: 'Flauta',
        ru: 'Флейта',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '一键吹奏的本地长笛，支持调式切换与音色预设。',
        en: 'Breath-like local flute notes with scale switching and preset packs.',
        ja: '息づかいのあるローカルフルート音色。スケールとプリセットを切り替え可能。',
        de: 'Atmungsähnliche lokale Flötentöne mit Skalenwechsel und Presets.',
        fr: 'Notes de flûte locales au souffle naturel avec gammes et préréglages.',
        es: 'Notas de flauta locales con respiración natural, escalas y presets.',
        ru: 'Локальная флейта с дыхательным тембром, сменой ладов и пресетов.',
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
      title: pickUiText(
        i18n,
        zh: '鼓垫',
        en: 'Drum pad',
        ja: 'ドラムパッド',
        de: 'Drum-Pad',
        fr: 'Pad de batterie',
        es: 'Pad de batería',
        ru: 'Драм-пэд',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '紧凑鼓垫整合底鼓、军鼓、踩镲与嗵鼓，并支持音色预设。',
        en: 'Compact drum pad with kick, snare, hi-hat and tom, plus kit presets.',
        ja: 'キック、スネア、ハイハット、タムをまとめたコンパクトなドラムパッド。',
        de: 'Kompaktes Drum-Pad mit Kick, Snare, Hi-Hat und Tom inklusive Kit-Presets.',
        fr: 'Pad compact avec kick, caisse claire, charleston et tom, avec presets de kit.',
        es: 'Pad compacto con bombo, caja, hi-hat y tom, con presets de kit.',
        ru: 'Компактный драм-пэд: бочка, малый, хай-хэт и томы с наборами пресетов.',
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
      title: pickUiText(
        i18n,
        zh: '吉他',
        en: 'Guitar',
        ja: 'ギター',
        de: 'Gitarre',
        fr: 'Guitare',
        es: 'Guitarra',
        ru: 'Гитара',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '可点弦与扫弦的本地吉他，支持尼龙/钢弦/氛围预设。',
        en: 'Tap strings or strum with local nylon, steel, and ambient preset packs.',
        ja: 'タップ弾きとストラムに対応。ナイロン/スチール/アンビエントを切替可能。',
        de: 'Saiten antippen oder strummen mit Nylon-, Steel- und Ambient-Presets.',
        fr: 'Pincez ou grattez les cordes avec presets nylon, acier et ambient.',
        es: 'Pulsa o rasguea cuerdas con presets de nailon, acero y ambient.',
        ru: 'Щипок и бой по струнам с пресетами нейлон, сталь и ambient.',
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
      title: pickUiText(
        i18n,
        zh: '三角铁',
        en: 'Triangle',
        ja: 'トライアングル',
        de: 'Triangel',
        fr: 'Triangle',
        es: 'Triángulo',
        ru: 'Треугольник',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '清亮金属敲击音，支持不同振铃质感预设。',
        en: 'Clean metallic strikes with controllable ring and style presets.',
        ja: '澄んだ金属打音。余韻コントロールとスタイルプリセット対応。',
        de: 'Klarer metallischer Anschlag mit steuerbarem Nachklang und Presets.',
        fr: 'Frappe métallique nette avec résonance réglable et presets.',
        es: 'Golpe metálico limpio con resonancia ajustable y presets.',
        ru: 'Чистый металлический удар с регулировкой звона и пресетами.',
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
        zh: '通过手机麦克风分析拾音电平、峰值、音高与亮度，辅助完成拾音调校。',
        en: 'Use the phone microphone to analyze pickup level, peaks, pitch, and brightness.',
      ),
      child: const _PickupTool(),
    );
  }
}
