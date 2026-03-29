import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_audio_service.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'toolbox_tool_shell.dart';

AppI18n _toolboxI18n(BuildContext context, {bool listen = true}) {
  final state = listen
      ? context.watch<AppState?>()
      : Provider.of<AppState?>(context, listen: false);
  final language =
      state?.uiLanguage ?? Localizations.localeOf(context).languageCode;
  return AppI18n(language);
}

class _TutorialStep {
  const _TutorialStep({required this.zh, required this.en});

  final String zh;
  final String en;
}

void _showInstrumentTutorialDialog({
  required BuildContext context,
  required String titleZh,
  required String titleEn,
  required List<_TutorialStep> steps,
}) {
  final i18n = _toolboxI18n(context, listen: false);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final maxHeight = math
          .min(MediaQuery.sizeOf(sheetContext).height * 0.72, 540.0)
          .toDouble();
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(i18n, zh: titleZh, en: titleEn),
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pickUiText(
                    i18n,
                    zh: '按顺序跟着操作一遍，能最快上手当前乐器。',
                    en: 'Follow these steps once to get comfortable with the instrument.',
                  ),
                  style: Theme.of(sheetContext).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    itemCount: steps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          radius: 13,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(pickUiText(i18n, zh: step.zh, en: step.en)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

const List<DeviceOrientation> _toolboxAllOrientations = <DeviceOrientation>[
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

bool _supportsMobileOrientationLock() => Platform.isAndroid || Platform.isIOS;

Future<void> _enterToolboxLandscapeMode() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  if (_supportsMobileOrientationLock()) {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}

Future<void> _exitToolboxLandscapeMode() async {
  if (_supportsMobileOrientationLock()) {
    await SystemChrome.setPreferredOrientations(_toolboxAllOrientations);
  }
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

class SoothingMusicToolPage extends StatelessWidget {
  const SoothingMusicToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(
        i18n,
        zh: '????',
        en: 'Soothing music',
        ja: '???????',
        de: 'Beruhigende Musik',
        fr: 'Musique apaisante',
        es: 'Musica relajante',
        ru: '????????????? ??????',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '??????????????????????',
        en: 'Locally synthesized soft textures for slowing down and settling your rhythm.',
        ja: '???????????????????????????????',
        de: 'Lokal synthetisierte, weiche Klangtexturen zum Entschleunigen.',
        fr: 'Textures sonores locales et douces pour ralentir et se poser.',
        es: 'Texturas suaves sintetizadas en local para bajar el ritmo y relajarte.',
        ru: '???????? ??????????????? ?????? ???????? ??? ?????????? ? ????????????.',
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
      return const _DeckInstrumentFullScreenPage(
        instrument: _HarpDeckInstrument.harp,
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
        zh: '在同一工具台中切换竖琴、钢琴、长笛、鼓垫、吉他和三角铁。',
        en: 'Switch harp, piano, flute, drum pad, guitar, and triangle from the same instrument desk.',
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

enum _HarpDeckInstrument { harp, piano, flute, drumPad, guitar, triangle }

class _HarpInstrumentDeck extends StatefulWidget {
  const _HarpInstrumentDeck();

  @override
  State<_HarpInstrumentDeck> createState() => _HarpInstrumentDeckState();
}

class _HarpInstrumentDeckState extends State<_HarpInstrumentDeck> {
  _HarpDeckInstrument _selected = _HarpDeckInstrument.harp;

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
      _ => const _HarpTool(),
    };
  }

  void _openInstrumentFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DeckInstrumentFullScreenPage(instrument: _selected),
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
                    zh: '竖琴模块内可快速切换 6 种乐器，并共享全屏入口。',
                    en: 'Switch between 6 instruments inside the harp module and reuse the same fullscreen workflow.',
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
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '当前乐器全屏',
                      en: 'Fullscreen current instrument',
                    ),
                  ),
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
  const _DeckInstrumentFullScreenPage({required this.instrument});

  final _HarpDeckInstrument instrument;

  @override
  State<_DeckInstrumentFullScreenPage> createState() =>
      _DeckInstrumentFullScreenPageState();
}

class _DeckInstrumentFullScreenPageState
    extends State<_DeckInstrumentFullScreenPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_enterToolboxLandscapeMode());
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
      _ => _HarpTool(
        fullScreen: true,
        onExitFullScreen: () => Navigator.of(context).pop(),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.instrument == _HarpDeckInstrument.harp) {
      return Scaffold(backgroundColor: Colors.black, body: _tool());
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: _tool(),
              ),
            ),
            Positioned(
              left: 12,
              top: 8,
              child: FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.38),
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
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

class _SoothingPreset {
  const _SoothingPreset({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

class _SoothingMusicTool extends StatefulWidget {
  const _SoothingMusicTool();

  @override
  State<_SoothingMusicTool> createState() => _SoothingMusicToolState();
}

class _SoothingMusicToolState extends State<_SoothingMusicTool>
    with SingleTickerProviderStateMixin {
  static const List<_SoothingPreset> _presets = <_SoothingPreset>[
    _SoothingPreset(id: 'moon', title: 'Moon', subtitle: 'Soft floating bed'),
    _SoothingPreset(id: 'mist', title: 'Mist', subtitle: 'Airy and slow'),
    _SoothingPreset(
      id: 'harbor',
      title: 'Harbor',
      subtitle: 'Brighter for evening focus',
    ),
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
                                  preset.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preset.subtitle,
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
                  label: Text(_playing ? 'Pause ambience' : 'Start ambience'),
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
                const SectionHeader(
                  title: 'Preset',
                  subtitle:
                      'Switch between three locally synthesized textures.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets
                      .map((item) {
                        final selected = item.id == _presetId;
                        return ChoiceChip(
                          label: Text(item.title),
                          selected: selected,
                          onSelected: (_) => _selectPreset(item.id),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
                Text(
                  'Volume ${(100 * _volume).round()}%',
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

class _HarpTool extends StatefulWidget {
  const _HarpTool({this.fullScreen = false, this.onExitFullScreen});

  final bool fullScreen;
  final VoidCallback? onExitFullScreen;

  @override
  State<_HarpTool> createState() => _HarpToolState();
}

class _HarpScalePreset {
  const _HarpScalePreset({
    required this.id,
    required this.label,
    required this.notes,
  });

  final String id;
  final String label;
  final List<double> notes;
}

class _HarpChordPreset {
  const _HarpChordPreset({
    required this.id,
    required this.label,
    required this.intervals,
  });

  final String id;
  final String label;
  final List<int> intervals;
}

class _HarpPalettePreset {
  const _HarpPalettePreset({
    required this.id,
    required this.label,
    required this.colors,
  });

  final String id;
  final String label;
  final List<Color> colors;
}

class _HarpPluckPreset {
  const _HarpPluckPreset({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class _HarpPatternPreset {
  const _HarpPatternPreset({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class _HarpRealismPreset {
  const _HarpRealismPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.scaleId,
    required this.chordId,
    required this.pluckStyleId,
    required this.patternId,
    required this.paletteId,
    required this.reverb,
    required this.damping,
    required this.swipeThreshold,
    required this.chordResonanceEnabled,
  });

  final String id;
  final String label;
  final String description;
  final String scaleId;
  final String chordId;
  final String pluckStyleId;
  final String patternId;
  final String paletteId;
  final double reverb;
  final double damping;
  final double swipeThreshold;
  final bool chordResonanceEnabled;
}

class _HarpToolState extends State<_HarpTool>
    with SingleTickerProviderStateMixin {
  static const int _stringCount = 12;
  static const double _springStiffness = 34;
  static const List<_HarpScalePreset> _scalePresets = <_HarpScalePreset>[
    _HarpScalePreset(
      id: 'c_major',
      label: 'C Major',
      notes: <double>[
        130.81,
        146.83,
        164.81,
        196.0,
        220.0,
        261.63,
        293.66,
        329.63,
        392.0,
        440.0,
        523.25,
        587.33,
      ],
    ),
    _HarpScalePreset(
      id: 'a_minor',
      label: 'A Minor',
      notes: <double>[
        110.0,
        130.81,
        146.83,
        164.81,
        196.0,
        220.0,
        261.63,
        293.66,
        329.63,
        392.0,
        440.0,
        523.25,
      ],
    ),
    _HarpScalePreset(
      id: 'd_dorian',
      label: 'D Dorian',
      notes: <double>[
        146.83,
        164.81,
        174.61,
        196.0,
        220.0,
        261.63,
        293.66,
        329.63,
        349.23,
        392.0,
        440.0,
        523.25,
      ],
    ),
    _HarpScalePreset(
      id: 'zen',
      label: 'Zen Pentatonic',
      notes: <double>[
        130.81,
        138.59,
        155.56,
        196.0,
        207.65,
        261.63,
        277.18,
        311.13,
        392.0,
        415.3,
        523.25,
        554.37,
      ],
    ),
    _HarpScalePreset(
      id: 'c_lydian',
      label: 'C Lydian',
      notes: <double>[
        130.81,
        146.83,
        164.81,
        185.0,
        196.0,
        220.0,
        246.94,
        261.63,
        293.66,
        329.63,
        369.99,
        392.0,
      ],
    ),
    _HarpScalePreset(
      id: 'hirajoshi',
      label: 'Hirajoshi',
      notes: <double>[
        130.81,
        138.59,
        174.61,
        196.0,
        233.08,
        261.63,
        277.18,
        349.23,
        392.0,
        466.16,
        523.25,
        554.37,
      ],
    ),
  ];
  static const List<_HarpChordPreset> _chordPresets = <_HarpChordPreset>[
    _HarpChordPreset(
      id: 'major',
      label: 'Major',
      intervals: <int>[0, 4, 7, 12],
    ),
    _HarpChordPreset(
      id: 'minor',
      label: 'Minor',
      intervals: <int>[0, 3, 7, 12],
    ),
    _HarpChordPreset(id: 'sus2', label: 'Sus2', intervals: <int>[0, 2, 7, 12]),
    _HarpChordPreset(id: 'add9', label: 'Add9', intervals: <int>[0, 4, 7, 14]),
    _HarpChordPreset(id: 'sus4', label: 'Sus4', intervals: <int>[0, 5, 7, 12]),
    _HarpChordPreset(id: 'maj7', label: 'Maj7', intervals: <int>[0, 4, 7, 11]),
    _HarpChordPreset(id: 'min7', label: 'Min7', intervals: <int>[0, 3, 7, 10]),
  ];
  static const List<_HarpPluckPreset> _pluckPresets = <_HarpPluckPreset>[
    _HarpPluckPreset(
      id: 'silk',
      label: 'Silk',
      description: 'Balanced and soft.',
    ),
    _HarpPluckPreset(
      id: 'warm',
      label: 'Warm',
      description: 'More body and slower tail.',
    ),
    _HarpPluckPreset(
      id: 'crystal',
      label: 'Crystal',
      description: 'Sharper upper harmonics.',
    ),
    _HarpPluckPreset(
      id: 'bright',
      label: 'Bright',
      description: 'Clear attack for active strum.',
    ),
    _HarpPluckPreset(
      id: 'nylon',
      label: 'Nylon',
      description: 'Round body with light transient.',
    ),
    _HarpPluckPreset(
      id: 'glass',
      label: 'Glass',
      description: 'Thin body and sparkling top.',
    ),
    _HarpPluckPreset(
      id: 'concert',
      label: 'Concert',
      description: 'Pedal-harp like balance and sustain.',
    ),
    _HarpPluckPreset(
      id: 'steel',
      label: 'Steel',
      description: 'Stronger core and brighter attack.',
    ),
  ];
  static const List<_HarpPatternPreset> _patternPresets = <_HarpPatternPreset>[
    _HarpPatternPreset(
      id: 'glide',
      label: 'Glide',
      description: 'Ascending sweep.',
    ),
    _HarpPatternPreset(
      id: 'cascade',
      label: 'Cascade',
      description: 'Up then down.',
    ),
    _HarpPatternPreset(
      id: 'chord',
      label: 'Chord',
      description: 'Pulse active chord tones.',
    ),
  ];
  static const List<_HarpPalettePreset> _palettePresets = <_HarpPalettePreset>[
    _HarpPalettePreset(
      id: 'moon',
      label: 'Moon',
      colors: <Color>[Color(0xFF8B5CF6), Color(0xFF60A5FA), Color(0xFF22D3EE)],
    ),
    _HarpPalettePreset(
      id: 'aurora',
      label: 'Aurora',
      colors: <Color>[Color(0xFF0EA5E9), Color(0xFF22C55E), Color(0xFFFDE047)],
    ),
    _HarpPalettePreset(
      id: 'ember',
      label: 'Ember',
      colors: <Color>[Color(0xFFFB7185), Color(0xFFFB923C), Color(0xFFFACC15)],
    ),
    _HarpPalettePreset(
      id: 'jade',
      label: 'Jade',
      colors: <Color>[Color(0xFF10B981), Color(0xFF2DD4BF), Color(0xFF7DD3FC)],
    ),
  ];
  static const List<_HarpRealismPreset> _realismPresets = <_HarpRealismPreset>[
    _HarpRealismPreset(
      id: 'concert_nylon',
      label: 'Concert Nylon',
      description: 'Round body with controlled hall tail.',
      scaleId: 'c_major',
      chordId: 'major',
      pluckStyleId: 'nylon',
      patternId: 'glide',
      paletteId: 'jade',
      reverb: 0.2,
      damping: 11.8,
      swipeThreshold: 1.0,
      chordResonanceEnabled: false,
    ),
    _HarpRealismPreset(
      id: 'pedal_harp',
      label: 'Pedal Harp',
      description: 'Balanced sustain for melodic passages.',
      scaleId: 'c_lydian',
      chordId: 'maj7',
      pluckStyleId: 'concert',
      patternId: 'cascade',
      paletteId: 'moon',
      reverb: 0.26,
      damping: 10.4,
      swipeThreshold: 1.2,
      chordResonanceEnabled: false,
    ),
    _HarpRealismPreset(
      id: 'steel_studio',
      label: 'Steel Studio',
      description: 'Tight transient and clear note separation.',
      scaleId: 'd_dorian',
      chordId: 'sus2',
      pluckStyleId: 'steel',
      patternId: 'glide',
      paletteId: 'aurora',
      reverb: 0.16,
      damping: 12.8,
      swipeThreshold: 0.9,
      chordResonanceEnabled: false,
    ),
    _HarpRealismPreset(
      id: 'chamber_soft',
      label: 'Chamber Soft',
      description: 'Soft finger-pluck with gentle bloom.',
      scaleId: 'a_minor',
      chordId: 'minor',
      pluckStyleId: 'warm',
      patternId: 'chord',
      paletteId: 'ember',
      reverb: 0.3,
      damping: 9.6,
      swipeThreshold: 1.4,
      chordResonanceEnabled: false,
    ),
  ];

  final Map<String, ToolboxEffectPlayer> _playersByKey =
      <String, ToolboxEffectPlayer>{};
  final List<double> _stringOffsets = List<double>.filled(_stringCount, 0);
  final List<double> _stringVelocities = List<double>.filled(_stringCount, 0);
  final List<int> _lastPluckAtMillis = List<int>.filled(_stringCount, 0);
  late final Ticker _vibrationTicker;

  Offset? _lastDragPoint;
  int? _lastDragStringIndex;
  int? _activePointerId;
  Offset? _pointerDownPosition;
  bool _pointerDragActive = false;
  int? _focusedString;
  int? _lastTickMicros;
  bool _muted = false;
  String _scaleId = _scalePresets.first.id;
  String _chordId = _chordPresets.first.id;
  String _pluckStyleId = _pluckPresets.first.id;
  String _patternId = _patternPresets.first.id;
  String _paletteId = _palettePresets.first.id;
  int _chordRootIndex = 0;
  bool _chordResonanceEnabled = false;
  double _reverbUi = 0.24;
  double _reverbForAudio = 0.24;
  double _damping = 10;
  double _swipeThreshold = 1.2;
  String? _activeRealismPresetId;
  String _backdropMaterial = 'crystal';

  @override
  void initState() {
    super.initState();
    _vibrationTicker = createTicker(_tickStrings);
    _applyRealismPreset(_realismPresets.first, withSetState: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActiveTone());
    });
  }

  _HarpScalePreset get _activeScale =>
      _scalePresets.firstWhere((preset) => preset.id == _scaleId);

  _HarpChordPreset get _activeChord =>
      _chordPresets.firstWhere((preset) => preset.id == _chordId);

  _HarpPalettePreset get _activePalette =>
      _palettePresets.firstWhere((preset) => preset.id == _paletteId);

  List<double> get _activeNotes => _activeScale.notes;

  bool get _isHorizontalLayout => widget.fullScreen;

  String _scaleLabel(AppI18n i18n, _HarpScalePreset preset) {
    return switch (preset.id) {
      'a_minor' => pickUiText(i18n, zh: 'A小调', en: 'A Minor'),
      'd_dorian' => pickUiText(i18n, zh: 'D多利亚', en: 'D Dorian'),
      'zen' => pickUiText(i18n, zh: '禅意五声音阶', en: 'Zen Pentatonic'),
      'c_lydian' => pickUiText(i18n, zh: 'C利底亚', en: 'C Lydian'),
      'hirajoshi' => pickUiText(i18n, zh: '平调子', en: 'Hirajoshi'),
      _ => pickUiText(i18n, zh: 'C大调', en: 'C Major'),
    };
  }

  String _chordLabel(AppI18n i18n, _HarpChordPreset preset) {
    return switch (preset.id) {
      'minor' => pickUiText(i18n, zh: '小三和弦', en: 'Minor'),
      'sus2' => pickUiText(i18n, zh: '挂二', en: 'Sus2'),
      'add9' => pickUiText(i18n, zh: '加九', en: 'Add9'),
      'sus4' => pickUiText(i18n, zh: '挂四', en: 'Sus4'),
      'maj7' => pickUiText(i18n, zh: '大七', en: 'Maj7'),
      'min7' => pickUiText(i18n, zh: '小七', en: 'Min7'),
      _ => pickUiText(i18n, zh: '大三和弦', en: 'Major'),
    };
  }

  String _pluckLabel(AppI18n i18n, _HarpPluckPreset preset) {
    return switch (preset.id) {
      'warm' => pickUiText(i18n, zh: '温暖', en: 'Warm'),
      'crystal' => pickUiText(i18n, zh: '水晶', en: 'Crystal'),
      'bright' => pickUiText(i18n, zh: '明亮', en: 'Bright'),
      'nylon' => pickUiText(i18n, zh: '尼龙', en: 'Nylon'),
      'glass' => pickUiText(i18n, zh: '玻璃', en: 'Glass'),
      'concert' => pickUiText(i18n, zh: '音乐厅', en: 'Concert'),
      'steel' => pickUiText(i18n, zh: '钢弦', en: 'Steel'),
      _ => pickUiText(i18n, zh: '丝绸', en: 'Silk'),
    };
  }

  String _pluckDescription(AppI18n i18n, _HarpPluckPreset preset) {
    return switch (preset.id) {
      'warm' => pickUiText(
        i18n,
        zh: '更厚实、尾音更慢。',
        en: 'More body and slower tail.',
      ),
      'crystal' => pickUiText(
        i18n,
        zh: '高频更亮，颗粒更清晰。',
        en: 'Sharper upper harmonics.',
      ),
      'bright' => pickUiText(
        i18n,
        zh: '起音更清楚，适合扫弦。',
        en: 'Clear attack for active strum.',
      ),
      'nylon' => pickUiText(
        i18n,
        zh: '圆润柔和，瞬态较轻。',
        en: 'Round body with light transient.',
      ),
      'glass' => pickUiText(
        i18n,
        zh: '更薄更亮，泛音闪烁。',
        en: 'Thin body and sparkling top.',
      ),
      'concert' => pickUiText(
        i18n,
        zh: '接近踏板竖琴的均衡延音。',
        en: 'Pedal-harp like balance and sustain.',
      ),
      'steel' => pickUiText(
        i18n,
        zh: '核心更强，拨弦更亮。',
        en: 'Stronger core and brighter attack.',
      ),
      _ => pickUiText(i18n, zh: '平衡柔和。', en: 'Balanced and soft.'),
    };
  }

  String _patternLabel(AppI18n i18n, _HarpPatternPreset preset) {
    return switch (preset.id) {
      'cascade' => pickUiText(i18n, zh: '瀑布', en: 'Cascade'),
      'chord' => pickUiText(i18n, zh: '和弦脉冲', en: 'Chord'),
      _ => pickUiText(i18n, zh: '滑行', en: 'Glide'),
    };
  }

  String _patternDescription(AppI18n i18n, _HarpPatternPreset preset) {
    return switch (preset.id) {
      'cascade' => pickUiText(i18n, zh: '先上行再下行。', en: 'Up then down.'),
      'chord' => pickUiText(
        i18n,
        zh: '脉冲弹奏当前和弦音。',
        en: 'Pulse active chord tones.',
      ),
      _ => pickUiText(i18n, zh: '连续上行扫弦。', en: 'Ascending sweep.'),
    };
  }

  String _paletteLabel(AppI18n i18n, _HarpPalettePreset preset) {
    return switch (preset.id) {
      'aurora' => pickUiText(i18n, zh: '极光', en: 'Aurora'),
      'ember' => pickUiText(i18n, zh: '余烬', en: 'Ember'),
      'jade' => pickUiText(i18n, zh: '翡翠', en: 'Jade'),
      _ => pickUiText(i18n, zh: '月光', en: 'Moon'),
    };
  }

  String _realismLabel(AppI18n i18n, _HarpRealismPreset preset) {
    return switch (preset.id) {
      'pedal_harp' => pickUiText(i18n, zh: '踏板竖琴', en: 'Pedal Harp'),
      'steel_studio' => pickUiText(i18n, zh: '钢弦录音棚', en: 'Steel Studio'),
      'chamber_soft' => pickUiText(i18n, zh: '室内柔和', en: 'Chamber Soft'),
      _ => pickUiText(i18n, zh: '音乐会尼龙', en: 'Concert Nylon'),
    };
  }

  String _realismDescription(AppI18n i18n, _HarpRealismPreset preset) {
    return switch (preset.id) {
      'pedal_harp' => pickUiText(
        i18n,
        zh: '适合旋律线条的平衡延音。',
        en: 'Balanced sustain for melodic passages.',
      ),
      'steel_studio' => pickUiText(
        i18n,
        zh: '瞬态紧致，音符分离清晰。',
        en: 'Tight transient and clear note separation.',
      ),
      'chamber_soft' => pickUiText(
        i18n,
        zh: '柔和拨弦，余韵舒展。',
        en: 'Soft finger-pluck with gentle bloom.',
      ),
      _ => pickUiText(
        i18n,
        zh: '圆润琴体与受控厅堂尾音。',
        en: 'Round body with controlled hall tail.',
      ),
    };
  }

  void _markRealismCustom() {
    _activeRealismPresetId = null;
  }

  void _applyRealismPreset(
    _HarpRealismPreset preset, {
    bool withSetState = true,
  }) {
    void applyValues() {
      _scaleId = preset.scaleId;
      _chordId = preset.chordId;
      _pluckStyleId = preset.pluckStyleId;
      _patternId = preset.patternId;
      _paletteId = preset.paletteId;
      _reverbUi = preset.reverb;
      _reverbForAudio = preset.reverb;
      _damping = preset.damping;
      _swipeThreshold = preset.swipeThreshold;
      _chordResonanceEnabled = preset.chordResonanceEnabled;
      _activeRealismPresetId = preset.id;
    }

    if (withSetState && mounted) {
      setState(applyValues);
    } else {
      applyValues();
    }
    _invalidateAudioPlayers();
  }

  void _invalidateAudioPlayers({bool warmUp = true}) {
    for (final player in _playersByKey.values) {
      unawaited(player.dispose());
    }
    _playersByKey.clear();
    if (warmUp) {
      unawaited(_warmUpActiveTone());
    }
  }

  Future<void> _warmUpActiveTone() async {
    for (final frequency in _activeNotes) {
      await _playerForFrequency(frequency).warmUp();
    }
  }

  ToolboxEffectPlayer _playerForFrequency(double frequency) {
    final key =
        '${frequency.toStringAsFixed(2)}|$_pluckStyleId|${_reverbForAudio.toStringAsFixed(2)}';
    final existing = _playersByKey[key];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.harpNote(
        frequency,
        style: _pluckStyleId,
        reverb: _reverbForAudio,
      ),
      maxPlayers: 8,
    );
    _playersByKey[key] = created;
    return created;
  }

  double _stringTrackAt(
    int index,
    Size size, {
    required bool horizontalLayout,
  }) {
    final totalSpan = horizontalLayout ? size.height : size.width;
    final adaptiveInset = totalSpan * (horizontalLayout ? 0.12 : 0.11);
    final minInset = horizontalLayout ? 28.0 : 22.0;
    final leadingInset = math.max(minInset, adaptiveInset);
    final trailingInset = math.max(minInset, adaptiveInset);
    final usableSpan = math.max(1.0, totalSpan - leadingInset - trailingInset);
    if (_stringCount == 1) {
      return horizontalLayout ? size.height / 2 : size.width / 2;
    }
    return leadingInset + usableSpan * (index / (_stringCount - 1));
  }

  int _nearestStringByPosition(
    Offset point,
    Size size, {
    required bool horizontalLayout,
  }) {
    final axisValue = horizontalLayout ? point.dy : point.dx;
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < _stringCount; i += 1) {
      final distance =
          (_stringTrackAt(i, size, horizontalLayout: horizontalLayout) -
                  axisValue)
              .abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  List<int> _crossedStrings(
    Offset previous,
    Offset current,
    Size size, {
    required bool horizontalLayout,
  }) {
    final startIndex = _nearestStringByPosition(
      previous,
      size,
      horizontalLayout: horizontalLayout,
    );
    final endIndex = _nearestStringByPosition(
      current,
      size,
      horizontalLayout: horizontalLayout,
    );
    if (startIndex == endIndex) {
      return const <int>[];
    }
    final step = endIndex > startIndex ? 1 : -1;
    final indexes = <int>[];
    for (var i = startIndex + step; i != endIndex + step; i += step) {
      indexes.add(i);
    }
    return indexes;
  }

  double _swipeIntensity(Offset delta) {
    final effectiveDistance = math.max(0.0, delta.distance - _swipeThreshold);
    return (effectiveDistance / 52).clamp(0.18, 1.0).toDouble();
  }

  double _swipeDirection(Offset delta, {required bool horizontalLayout}) {
    final axisDelta = horizontalLayout ? delta.dy : delta.dx;
    return axisDelta >= 0 ? 1.0 : -1.0;
  }

  void _startVibrationTicker() {
    if (_vibrationTicker.isActive) return;
    _lastTickMicros = null;
    _vibrationTicker.start();
  }

  void _tickStrings(Duration elapsed) {
    final currentMicros = elapsed.inMicroseconds;
    final previousMicros = _lastTickMicros;
    _lastTickMicros = currentMicros;
    if (previousMicros == null) return;

    var deltaSeconds =
        (currentMicros - previousMicros) / Duration.microsecondsPerSecond;
    if (deltaSeconds <= 0 || deltaSeconds > 0.08) {
      deltaSeconds = 1 / 60;
    }

    var hasMotion = false;
    for (var i = 0; i < _stringOffsets.length; i += 1) {
      final offset = _stringOffsets[i];
      final velocity = _stringVelocities[i];
      final acceleration = (-_springStiffness * offset) - (_damping * velocity);
      final nextVelocity = velocity + acceleration * deltaSeconds;
      final nextOffset = offset + nextVelocity * deltaSeconds;

      if (nextOffset.abs() < 0.02 && nextVelocity.abs() < 0.02) {
        _stringOffsets[i] = 0;
        _stringVelocities[i] = 0;
        continue;
      }

      _stringOffsets[i] = nextOffset;
      _stringVelocities[i] = nextVelocity;
      hasMotion = true;
    }

    if (!hasMotion) {
      _vibrationTicker.stop();
      _lastTickMicros = null;
      if (_focusedString != null && mounted) {
        setState(() {
          _focusedString = null;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _pluckString(
    int index, {
    required double intensity,
    required double direction,
    bool force = false,
    double? frequencyOverride,
    bool applyChordResonance = true,
  }) {
    if (index < 0 || index >= _stringCount) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _lastPluckAtMillis[index] < 28) return;
    _lastPluckAtMillis[index] = now;

    final frequency = frequencyOverride ?? _activeNotes[index];
    final clampedIntensity = intensity.clamp(0.18, 1.0).toDouble();
    if (!_muted) {
      final volume = (0.22 + clampedIntensity * 0.78).clamp(0.0, 1.0);
      unawaited(_playerForFrequency(frequency).play(volume: volume.toDouble()));
    }

    _stringOffsets[index] += direction * (1.8 + clampedIntensity * 2.4);
    _stringVelocities[index] += direction * (42 + clampedIntensity * 68);
    if (applyChordResonance && _chordResonanceEnabled) {
      _triggerChordResonance(
        sourceIndex: index,
        baseFrequency: frequency,
        intensity: clampedIntensity,
        direction: direction,
      );
    }
    _startVibrationTicker();
    if (mounted) {
      setState(() {
        _focusedString = index;
      });
    }
  }

  void _handleTap(Offset localPosition, Size size) {
    final index = _nearestStringByPosition(
      localPosition,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    final axis = _isHorizontalLayout ? localPosition.dy : localPosition.dx;
    final span = _isHorizontalLayout ? size.height : size.width;
    final spacing = _stringCount <= 1 ? span : span / (_stringCount - 1);
    final distance =
        (_stringTrackAt(index, size, horizontalLayout: _isHorizontalLayout) -
                axis)
            .abs();
    if (distance > spacing * 0.45) return;
    _pluckString(
      index,
      intensity: 0.46,
      direction: 1,
      force: true,
      applyChordResonance: false,
    );
  }

  void _handlePanStart(Offset localPosition, Size size) {
    _lastDragPoint = localPosition;
    final startIndex = _nearestStringByPosition(
      localPosition,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    _lastDragStringIndex = startIndex;
    _pluckString(
      startIndex,
      intensity: 0.32,
      direction: 1,
      force: true,
      applyChordResonance: false,
    );
  }

  void _handlePanUpdate(Offset localPosition, Size size) {
    final current = localPosition;
    final previous = _lastDragPoint;
    _lastDragPoint = current;
    if (previous == null) return;

    final delta = current - previous;
    if (delta.distance <= _swipeThreshold) return;

    final intensity = _swipeIntensity(delta);
    final direction = _swipeDirection(
      delta,
      horizontalLayout: _isHorizontalLayout,
    );
    final crossed = _crossedStrings(
      previous,
      current,
      size,
      horizontalLayout: _isHorizontalLayout,
    );
    if (crossed.isEmpty) {
      final nearest = _nearestStringByPosition(
        current,
        size,
        horizontalLayout: _isHorizontalLayout,
      );
      if (nearest == _lastDragStringIndex) return;
      _lastDragStringIndex = nearest;
      _pluckString(
        nearest,
        intensity: intensity,
        direction: direction,
        applyChordResonance: false,
      );
      return;
    }
    for (final index in crossed) {
      if (index == _lastDragStringIndex) continue;
      _lastDragStringIndex = index;
      _pluckString(
        index,
        intensity: intensity,
        direction: direction,
        applyChordResonance: false,
      );
    }
  }

  void _handlePanEnd() {
    _lastDragPoint = null;
    _lastDragStringIndex = null;
  }

  bool _shouldEnterSweepMode(Offset delta) {
    final primaryDelta = (_isHorizontalLayout ? delta.dy : delta.dx).abs();
    final crossDelta = (_isHorizontalLayout ? delta.dx : delta.dy).abs();
    if (primaryDelta < _swipeThreshold) return false;
    return primaryDelta >= crossDelta * 1.2;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointerId != null) return;
    _activePointerId = event.pointer;
    _pointerDownPosition = event.localPosition;
    _pointerDragActive = false;
    _lastDragPoint = null;
    _lastDragStringIndex = null;
  }

  void _handlePointerMove(PointerMoveEvent event, Size size) {
    if (_activePointerId != event.pointer) return;
    final start = _pointerDownPosition;
    if (start == null) return;
    final current = event.localPosition;
    if (!_pointerDragActive) {
      final delta = current - start;
      if (!_shouldEnterSweepMode(delta)) return;
      _pointerDragActive = true;
      _handlePanStart(start, size);
    }
    _handlePanUpdate(current, size);
  }

  void _handlePointerUp(PointerUpEvent event, Size size) {
    if (_activePointerId != event.pointer) return;
    if (_pointerDragActive) {
      _handlePanEnd();
    } else {
      _handleTap(event.localPosition, size);
    }
    _activePointerId = null;
    _pointerDownPosition = null;
    _pointerDragActive = false;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_activePointerId != event.pointer) return;
    _handlePanEnd();
    _activePointerId = null;
    _pointerDownPosition = null;
    _pointerDragActive = false;
  }

  int _nearestStringByFrequency(double frequency) {
    var bestIndex = 0;
    var bestDistance = double.infinity;
    final notes = _activeNotes;
    for (var i = 0; i < notes.length; i += 1) {
      final distance = (notes[i] - frequency).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  List<double> _activeChordFrequencies() {
    final root = _activeNotes[_chordRootIndex.clamp(0, _stringCount - 1)];
    return _activeChord.intervals
        .map((step) => root * math.pow(2.0, step / 12.0).toDouble())
        .toList(growable: false);
  }

  void _triggerChordResonance({
    required int sourceIndex,
    required double baseFrequency,
    required double intensity,
    required double direction,
  }) {
    // Only on strong strums; avoid accidental multi-trigger on regular taps.
    if (intensity < 0.72) return;
    final resonanceIntervals = _activeChord.intervals.where((step) => step > 0);
    var slot = 0;
    for (final step in resonanceIntervals) {
      if (slot >= 1) break;
      final frequency = baseFrequency * math.pow(2.0, step / 12.0).toDouble();
      final index = _nearestStringByFrequency(frequency);
      if (index == sourceIndex) continue;
      final strength = (0.035 + intensity * 0.08) / (slot + 1);
      if (!_muted) {
        unawaited(
          _playerForFrequency(
            frequency,
          ).play(volume: strength.clamp(0.02, 0.12).toDouble()),
        );
      }
      _stringOffsets[index] += direction * (0.16 + strength * 0.8);
      _stringVelocities[index] += direction * (3 + strength * 12);
      slot += 1;
    }
  }

  Future<void> _playArpeggio() async {
    if (_patternId == 'chord') {
      final chordNotes = _activeChordFrequencies();
      final extended = <double>[...chordNotes, chordNotes.first * 2];
      for (var pass = 0; pass < 2; pass += 1) {
        final forward = pass == 0;
        final sequence = forward
            ? extended
            : extended.reversed.toList(growable: false);
        for (var i = 0; i < sequence.length; i += 1) {
          final frequency = sequence[i];
          final visualIndex = _nearestStringByFrequency(frequency);
          final intensity = (0.55 + (1 - i / sequence.length) * 0.26).clamp(
            0.35,
            0.9,
          );
          _pluckString(
            visualIndex,
            intensity: intensity.toDouble(),
            direction: forward ? 1.0 : -1.0,
            force: true,
            frequencyOverride: frequency,
            applyChordResonance: false,
          );
          await Future<void>.delayed(const Duration(milliseconds: 44));
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      return;
    }

    final ascending = List<int>.generate(_stringCount, (index) => index);
    final sequence = switch (_patternId) {
      'cascade' => <int>[
        ...ascending,
        ...List<int>.generate(_stringCount - 2, (i) => _stringCount - 2 - i),
      ],
      _ => ascending,
    };
    final delay = _patternId == 'cascade' ? 68 : 86;
    for (final index in sequence) {
      _pluckString(
        index,
        intensity: 0.68,
        direction: 1,
        force: true,
        applyChordResonance: false,
      );
      await Future<void>.delayed(Duration(milliseconds: delay));
    }
  }

  @override
  void dispose() {
    _vibrationTicker.dispose();
    _invalidateAudioPlayers(warmUp: false);
    super.dispose();
  }

  _HarpRealismPreset? get _activeRealismPresetOrNull {
    for (final preset in _realismPresets) {
      if (preset.id == _activeRealismPresetId) {
        return preset;
      }
    }
    return null;
  }

  String _backdropLabel(AppI18n i18n, String id) {
    return switch (id) {
      'wood' => pickUiText(i18n, zh: '暖木音板', en: 'Warm wood'),
      _ => pickUiText(i18n, zh: '透亮水晶', en: 'Crystal glass'),
    };
  }

  void _showHarpTutorial() {
    _showInstrumentTutorialDialog(
      context: context,
      titleZh: '竖琴快速教程',
      titleEn: 'Harp Quick Tutorial',
      steps: const <_TutorialStep>[
        _TutorialStep(
          zh: '点击单根琴弦可稳定拨弦，沿弦方向滑动会触发连续扫弦。',
          en: 'Tap a string for a stable pluck, then swipe along the strings for connected sweeps.',
        ),
        _TutorialStep(
          zh: '更快、更长的扫弦会带来更亮的起音与更强的共振感。',
          en: 'Faster, longer swipes create a brighter attack and stronger resonance.',
        ),
        _TutorialStep(
          zh: '先从拟真预设起步，再微调混响、阻尼和触发阈值。',
          en: 'Start from a realism preset, then fine-tune reverb, damping, and trigger threshold.',
        ),
        _TutorialStep(
          zh: '手机全屏会锁定为横向，双手操作会更接近真实竖琴台。',
          en: 'Phone fullscreen locks to landscape so two-hand playing feels closer to a real harp desk.',
        ),
      ],
    );
  }

  void _openFullScreen() {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HarpToolPage(fullScreen: true),
      ),
    );
  }

  Widget _buildHarpSurface({
    required BuildContext context,
    required Size size,
    required bool rounded,
  }) {
    Widget content = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: (event) => _handlePointerMove(event, size),
      onPointerUp: (event) => _handlePointerUp(event, size),
      onPointerCancel: _handlePointerCancel,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: CustomPaint(
          painter: _HarpPainter(
            stringCount: _stringCount,
            noteFrequencies: _activeNotes,
            stringOffsets: _stringOffsets,
            focusedString: _focusedString,
            colorScheme: Theme.of(context).colorScheme,
            paletteColors: _activePalette.colors,
            pluckStyleId: _pluckStyleId,
            horizontalLayout: _isHorizontalLayout,
            backdropMaterial: _backdropMaterial,
          ),
        ),
      ),
    );
    if (rounded) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: content,
      );
    }
    return content;
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final background = widget.fullScreen
        ? const Color(0xFFF7F5EF).withValues(alpha: 0.94)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72);
    final borderColor = widget.fullScreen
        ? const Color(0xFFE5E7EB)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.65);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBackdropSelector(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <String>['crystal', 'wood']
          .map(
            (material) => ChoiceChip(
              label: Text(_backdropLabel(i18n, material)),
              selected: _backdropMaterial == material,
              onSelected: (_) {
                if (_backdropMaterial == material) return;
                setState(() => _backdropMaterial = material);
              },
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildStageMetrics(
    AppI18n i18n, {
    required String presetLabel,
    required int reverbPercent,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _CompactMetric(
          label: pickUiText(i18n, zh: '布局', en: 'Layout'),
          value: widget.fullScreen
              ? pickUiText(i18n, zh: '横向全屏', en: 'Landscape fullscreen')
              : pickUiText(i18n, zh: '自适应', en: 'Adaptive'),
        ),
        _CompactMetric(
          label: pickUiText(i18n, zh: '预设', en: 'Preset'),
          value: presetLabel,
        ),
        _CompactMetric(
          label: pickUiText(i18n, zh: '混响', en: 'Reverb'),
          value: '$reverbPercent%',
        ),
        _CompactMetric(
          label: pickUiText(i18n, zh: '舞台材质', en: 'Backdrop'),
          value: _backdropLabel(i18n, _backdropMaterial),
        ),
      ],
    );
  }

  Widget _buildQuickActions(AppI18n i18n, {required bool fullScreen}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _muted = !_muted),
          icon: Icon(
            _muted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          ),
          label: Text(
            _muted
                ? pickUiText(i18n, zh: '取消静音', en: 'Unmute')
                : pickUiText(i18n, zh: '静音', en: 'Mute'),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _playArpeggio,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(pickUiText(i18n, zh: '自动琶音', en: 'Auto arpeggio')),
        ),
        OutlinedButton.icon(
          onPressed: _showHarpTutorial,
          icon: const Icon(Icons.school_rounded),
          label: Text(pickUiText(i18n, zh: '教程', en: 'Tutorial')),
        ),
        OutlinedButton.icon(
          onPressed: fullScreen
              ? (widget.onExitFullScreen ?? () => Navigator.of(context).pop())
              : _openFullScreen,
          icon: Icon(
            fullScreen
                ? Icons.fullscreen_exit_rounded
                : Icons.open_in_full_rounded,
          ),
          label: Text(
            pickUiText(
              i18n,
              zh: fullScreen ? '退出全屏' : '横向全屏',
              en: fullScreen ? 'Exit fullscreen' : 'Landscape fullscreen',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHarpStage(
    BuildContext context, {
    required double height,
    required bool fullScreen,
  }) {
    final i18n = _toolboxI18n(context);
    final statusText = _muted
        ? pickUiText(i18n, zh: '已静音', en: 'Muted')
        : pickUiText(i18n, zh: '声音开启', en: 'Sound on');
    final hintText = fullScreen
        ? pickUiText(
            i18n,
            zh: '横屏更适合双手连拨和长距离扫弦。',
            en: 'Landscape play gives you more room for two-hand sweeps.',
          )
        : pickUiText(
            i18n,
            zh: '点击单弦，沿弦滑动即可触发连续扫弦。',
            en: 'Tap single strings and swipe along the strings for continuous strums.',
          );
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fullScreen ? 28 : 24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: fullScreen ? 0.34 : 0.16),
            blurRadius: fullScreen ? 30 : 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildHarpSurface(
                  context: context,
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  rounded: false,
                );
              },
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          pickUiText(i18n, zh: '竖琴演奏台', en: 'Harp stage'),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pickUiText(
                            i18n,
                            zh: '12 弦拟真触控，支持拨弦、扫弦、和弦共振与自动琶音。',
                            en: '12 strings with plucks, sweeps, chord resonance, and auto arpeggios.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: IgnorePointer(
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          hintText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSections(
    BuildContext context,
    AppI18n i18n, {
    required double maxWidth,
  }) {
    final theme = Theme.of(context);
    final reverbPercent = (_reverbUi * 100).round();
    final activePreset = _activeRealismPresetOrNull;
    final presetLabel = activePreset == null
        ? pickUiText(i18n, zh: '自定义', en: 'Custom')
        : _realismLabel(i18n, activePreset);
    final presetDescription = activePreset == null
        ? pickUiText(
            i18n,
            zh: '当前参数已经偏离预设，可继续按需要微调。',
            en: 'The current settings have drifted from presets and can be tuned further.',
          )
        : _realismDescription(i18n, activePreset);

    final sections = <Widget>[
      _buildSection(
        context: context,
        title: pickUiText(i18n, zh: '拟真预设', en: 'Realism preset'),
        subtitle: pickUiText(
          i18n,
          zh: '先套用拟真方案，再决定是否细调弦体和空间响应。',
          en: 'Start from a realism pack, then decide how much detail you want to fine-tune.',
        ),
        children: <Widget>[
          Text(
            pickUiText(
              i18n,
              zh: '当前方案：$presetLabel',
              en: 'Active preset: $presetLabel',
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(presetDescription, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _realismPresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_realismLabel(i18n, preset)),
                    selected: _activeRealismPresetId == preset.id,
                    tooltip: _realismDescription(i18n, preset),
                    onSelected: (_) => _applyRealismPreset(preset),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          _buildStageMetrics(
            i18n,
            presetLabel: presetLabel,
            reverbPercent: reverbPercent,
          ),
        ],
      ),
      _buildSection(
        context: context,
        title: pickUiText(i18n, zh: '音色与舞台', en: 'Tone & stage'),
        subtitle: pickUiText(
          i18n,
          zh: '拨弦材质、色彩预设、混响和舞台背板共同决定听感与沉浸度。',
          en: 'Pluck material, color palette, reverb, and backdrop shape both realism and mood.',
        ),
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '拨弦质感', en: 'Pluck response'),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pluckPresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_pluckLabel(i18n, preset)),
                    selected: _pluckStyleId == preset.id,
                    tooltip: _pluckDescription(i18n, preset),
                    onSelected: (_) {
                      if (_pluckStyleId == preset.id) return;
                      setState(() {
                        _pluckStyleId = preset.id;
                        _markRealismCustom();
                      });
                      _invalidateAudioPlayers();
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(i18n, zh: '色彩预设', en: 'Palette'),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palettePresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_paletteLabel(i18n, preset)),
                    selected: _paletteId == preset.id,
                    onSelected: (_) {
                      if (_paletteId == preset.id) return;
                      setState(() {
                        _paletteId = preset.id;
                        _markRealismCustom();
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(i18n, zh: '舞台材质', en: 'Backdrop'),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          _buildBackdropSelector(i18n),
          const SizedBox(height: 12),
          Text(
            pickUiText(
              i18n,
              zh: '混响 $reverbPercent%',
              en: 'Reverb $reverbPercent%',
            ),
          ),
          Slider(
            value: _reverbUi,
            min: 0.0,
            max: 0.8,
            divisions: 16,
            onChanged: (value) {
              setState(() {
                _reverbUi = value;
                _markRealismCustom();
              });
            },
            onChangeEnd: (value) {
              final quantized = (value * 20).round() / 20;
              setState(() {
                _reverbUi = quantized;
                _reverbForAudio = quantized;
                _markRealismCustom();
              });
              _invalidateAudioPlayers();
            },
          ),
        ],
      ),
      _buildSection(
        context: context,
        title: pickUiText(i18n, zh: '调式与和弦', en: 'Scale & chord'),
        subtitle: pickUiText(
          i18n,
          zh: '从调式到自动琶音路径，都可以在同一控制台里完成。',
          en: 'Configure scale, voicing, and auto-arpeggio behavior from one control stack.',
        ),
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '调式', en: 'Scale'),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _scalePresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_scaleLabel(i18n, preset)),
                    selected: _scaleId == preset.id,
                    onSelected: (_) {
                      if (_scaleId == preset.id) return;
                      setState(() {
                        _scaleId = preset.id;
                        _markRealismCustom();
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(i18n, zh: '和弦', en: 'Chord'),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _chordPresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_chordLabel(i18n, preset)),
                    selected: _chordId == preset.id,
                    onSelected: (_) {
                      if (_chordId == preset.id) return;
                      setState(() {
                        _chordId = preset.id;
                        _markRealismCustom();
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(i18n, zh: '自动琶音', en: 'Auto arpeggio'),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _patternPresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_patternLabel(i18n, preset)),
                    selected: _patternId == preset.id,
                    tooltip: _patternDescription(i18n, preset),
                    onSelected: (_) {
                      if (_patternId == preset.id) return;
                      setState(() {
                        _patternId = preset.id;
                        _markRealismCustom();
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          FilterChip(
            label: Text(pickUiText(i18n, zh: '和弦共振', en: 'Chord resonance')),
            selected: _chordResonanceEnabled,
            onSelected: (selected) {
              setState(() {
                _chordResonanceEnabled = selected;
                _markRealismCustom();
              });
            },
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(
              i18n,
              zh: '和弦根音 ${_chordRootIndex + 1} / $_stringCount',
              en: 'Chord root ${_chordRootIndex + 1} / $_stringCount',
            ),
          ),
          Slider(
            value: _chordRootIndex.toDouble(),
            min: 0,
            max: (_stringCount - 1).toDouble(),
            divisions: _stringCount - 1,
            onChanged: (value) {
              setState(() {
                _chordRootIndex = value.round();
              });
            },
          ),
        ],
      ),
      _buildSection(
        context: context,
        title: pickUiText(i18n, zh: '触感与响应', en: 'Feel & response'),
        subtitle: pickUiText(
          i18n,
          zh: '阻尼决定余振收束，阈值决定多快会进入扫弦判定。',
          en: 'Damping controls decay while threshold controls how quickly a gesture becomes a sweep.',
        ),
        children: <Widget>[
          Text(
            pickUiText(
              i18n,
              zh: '阻尼 ${_damping.toStringAsFixed(1)}',
              en: 'Damping ${_damping.toStringAsFixed(1)}',
            ),
          ),
          Slider(
            value: _damping,
            min: 4,
            max: 18,
            divisions: 28,
            onChanged: (value) {
              setState(() {
                _damping = value;
                _markRealismCustom();
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '触发阈值 ${_swipeThreshold.toStringAsFixed(1)} px',
              en: 'Trigger threshold ${_swipeThreshold.toStringAsFixed(1)} px',
            ),
          ),
          Slider(
            value: _swipeThreshold,
            min: 0.4,
            max: 8,
            divisions: 38,
            onChanged: (value) {
              setState(() {
                _swipeThreshold = value;
                _markRealismCustom();
              });
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              pickUiText(
                i18n,
                zh: '建议先用较低阈值熟悉扫弦，再逐步提高以减少误触。',
                en: 'Start with a lower threshold to learn sweeping, then raise it to reduce accidental triggers.',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ];

    if (maxWidth < 760) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections
            .expand((section) => <Widget>[section, const SizedBox(height: 12)])
            .take(sections.length * 2 - 1)
            .toList(growable: false),
      );
    }

    final sectionWidth = ((maxWidth - 12) / 2).clamp(280.0, 520.0).toDouble();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: sections
          .map((section) => SizedBox(width: sectionWidth, child: section))
          .toList(growable: false),
    );
  }

  Widget _buildFullScreenBody(BuildContext context) {
    final fullscreenI18n = _toolboxI18n(context);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth = math
              .min(math.max(constraints.maxWidth * 0.34, 300.0), 380.0)
              .toDouble();
          final stageHeight = math.max(320.0, constraints.maxHeight - 24);
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: _buildHarpStage(
                          context,
                          height: stageHeight,
                          fullScreen: true,
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Wrap(
                          spacing: 8,
                          children: <Widget>[
                            FilledButton.tonal(
                              onPressed:
                                  widget.onExitFullScreen ??
                                  () => Navigator.of(context).pop(),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(46, 46),
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.34,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 20,
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () => setState(() => _muted = !_muted),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(46, 46),
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.34,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: Icon(
                                _muted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                size: 20,
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: _showHarpTutorial,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(46, 46),
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.34,
                                ),
                                foregroundColor: Colors.white,
                              ),
                              child: const Icon(Icons.school_rounded, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: panelWidth,
                  child: Container(
                    height: stageHeight,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F1EC).withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            pickUiText(
                              fullscreenI18n,
                              zh: '横向全屏控制台',
                              en: 'Landscape control rail',
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pickUiText(
                              fullscreenI18n,
                              zh: '左侧演奏，右侧调参，适合手机横屏连续操作。',
                              en: 'Play on the left and tune on the right for a better phone landscape workflow.',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActions(fullscreenI18n, fullScreen: true),
                          const SizedBox(height: 12),
                          _buildControlSections(
                            context,
                            fullscreenI18n,
                            maxWidth: panelWidth - 28,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );


  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final reverbPercent = (_reverbUi * 100).round();
    if (widget.fullScreen) {
      return _buildFullScreenBody(context);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: pickUiText(i18n, zh: '琴弦', en: 'Strings'),
              subtitle: pickUiText(
                i18n,
                zh: '二阶段竖琴：开放音色、和声与手势手感参数。',
                en: 'Second-pass harp with exposed tone, harmony, and gesture feel controls.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '弦数', en: 'Strings'),
                  value: '12',
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '调式', en: 'Scale'),
                  value: _scaleLabel(i18n, _activeScale),
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '残响', en: 'Reverb'),
                  value: '$reverbPercent%',
                ),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _muted = !_muted),
                  icon: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  ),
                  label: Text(
                    _muted
                        ? pickUiText(i18n, zh: '静音', en: 'Muted')
                        : pickUiText(i18n, zh: '声音开', en: 'Sound on'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openFullScreen,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(pickUiText(i18n, zh: '全屏', en: 'Full screen')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final size = Size(width, math.max(260, width * 0.86));
                return _buildHarpSurface(
                  context: context,
                  size: size,
                  rounded: true,
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _playArpeggio,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    pickUiText(i18n, zh: '自动琶音', en: 'Auto arpeggio'),
                  ),
                ),
                Text(
                  pickUiText(
                    i18n,
                    zh: '提示：更宽更快的扫弦会产生更明亮的音色。',
                    en: 'Tip: a wider, faster swipe creates a brighter strum.',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SectionHeader(
              title: pickUiText(i18n, zh: '高真实度预设', en: 'High Realism Presets'),
              subtitle: pickUiText(
                i18n,
                zh: '针对琴弦行为与空间响应调校的预设包。',
                en: 'Preset bundles tuned for realistic string behavior and room response.',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _realismPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_realismLabel(i18n, preset)),
                      selected: _activeRealismPresetId == preset.id,
                      tooltip: _realismDescription(i18n, preset),
                      onSelected: (_) {
                        _applyRealismPreset(preset);
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            SectionHeader(
              title: pickUiText(i18n, zh: '音色与配色', en: 'Tone & Palette'),
              subtitle: pickUiText(
                i18n,
                zh: '弦色、拨弦音色与残响均为本地实时渲染。',
                en: 'String color, pluck timbre, and reverb are all local and real-time.',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _pluckPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_pluckLabel(i18n, preset)),
                      selected: _pluckStyleId == preset.id,
                      tooltip: _pluckDescription(i18n, preset),
                      onSelected: (_) {
                        if (_pluckStyleId == preset.id) return;
                        setState(() {
                          _pluckStyleId = preset.id;
                          _markRealismCustom();
                        });
                        _invalidateAudioPlayers();
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _palettePresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_paletteLabel(i18n, preset)),
                      selected: _paletteId == preset.id,
                      onSelected: (_) {
                        if (_paletteId == preset.id) return;
                        setState(() {
                          _paletteId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              pickUiText(
                i18n,
                zh: '残响 $reverbPercent%',
                en: 'Reverb $reverbPercent%',
              ),
            ),
            Slider(
              value: _reverbUi,
              min: 0.0,
              max: 0.8,
              divisions: 16,
              onChanged: (value) {
                setState(() {
                  _reverbUi = value;
                  _markRealismCustom();
                });
              },
              onChangeEnd: (value) {
                final quantized = (value * 20).round() / 20;
                setState(() {
                  _reverbUi = quantized;
                  _reverbForAudio = quantized;
                  _markRealismCustom();
                });
                _invalidateAudioPlayers();
              },
            ),
            const SizedBox(height: 8),
            SectionHeader(
              title: pickUiText(i18n, zh: '和弦与调式', en: 'Scale & Chord'),
              subtitle: pickUiText(
                i18n,
                zh: '在同一竖琴面板中开放调式、和弦与琶音模式。',
                en: 'Expose mode, chord voicing, and arpeggio pattern from the same harp deck.',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _scalePresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_scaleLabel(i18n, preset)),
                      selected: _scaleId == preset.id,
                      onSelected: (_) {
                        if (_scaleId == preset.id) return;
                        setState(() {
                          _scaleId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _chordPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_chordLabel(i18n, preset)),
                      selected: _chordId == preset.id,
                      onSelected: (_) {
                        if (_chordId == preset.id) return;
                        setState(() {
                          _chordId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _patternPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(_patternLabel(i18n, preset)),
                      selected: _patternId == preset.id,
                      tooltip: _patternDescription(i18n, preset),
                      onSelected: (_) {
                        if (_patternId == preset.id) return;
                        setState(() {
                          _patternId = preset.id;
                          _markRealismCustom();
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: Text(pickUiText(i18n, zh: '和弦共振', en: 'Chord resonance')),
              selected: _chordResonanceEnabled,
              onSelected: (selected) {
                setState(() {
                  _chordResonanceEnabled = selected;
                  _markRealismCustom();
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              pickUiText(
                i18n,
                zh: '和弦根音 ${_chordRootIndex + 1} / $_stringCount',
                en: 'Chord root ${_chordRootIndex + 1} / $_stringCount',
              ),
            ),
            Slider(
              value: _chordRootIndex.toDouble(),
              min: 0,
              max: (_stringCount - 1).toDouble(),
              divisions: _stringCount - 1,
              onChanged: (value) {
                setState(() {
                  _chordRootIndex = value.round();
                });
              },
            ),
            const SizedBox(height: 8),
            SectionHeader(
              title: pickUiText(i18n, zh: '手感参数', en: 'Feel'),
              subtitle: pickUiText(
                i18n,
                zh: '开放阻尼与触发阈值，便于触控灵敏度调节。',
                en: 'Expose damping and trigger threshold for touch sensitivity tuning.',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pickUiText(
                i18n,
                zh: '阻尼 ${_damping.toStringAsFixed(1)}',
                en: 'Damping ${_damping.toStringAsFixed(1)}',
              ),
            ),
            Slider(
              value: _damping,
              min: 4,
              max: 18,
              divisions: 28,
              onChanged: (value) {
                setState(() {
                  _damping = value;
                  _markRealismCustom();
                });
              },
            ),
            const SizedBox(height: 6),
            Text(
              pickUiText(
                i18n,
                zh: '触发阈值 ${_swipeThreshold.toStringAsFixed(1)} px',
                en: 'Trigger threshold ${_swipeThreshold.toStringAsFixed(1)} px',
              ),
            ),
            Slider(
              value: _swipeThreshold,
              min: 0.4,
              max: 8,
              divisions: 38,
              onChanged: (value) {
                setState(() {
                  _swipeThreshold = value;
                  _markRealismCustom();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusBeatsTool extends StatefulWidget {
  const _FocusBeatsTool();

  @override
  State<_FocusBeatsTool> createState() => _FocusBeatsToolState();
}

class _FocusBeatsToolState extends State<_FocusBeatsTool>
    with SingleTickerProviderStateMixin {
  late final ToolboxEffectPlayer _accentPlayer;
  late final ToolboxEffectPlayer _regularPlayer;
  late final AnimationController _pulseController;

  Timer? _timer;
  int _bpm = 72;
  int _beatsPerBar = 4;
  int _activeBeat = -1;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _accentPlayer = ToolboxEffectPlayer(
      ToolboxAudioBank.metronomeClick(accent: true),
      maxPlayers: 4,
    );
    _regularPlayer = ToolboxEffectPlayer(
      ToolboxAudioBank.metronomeClick(accent: false),
      maxPlayers: 4,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_accentPlayer.warmUp());
      unawaited(_regularPlayer.warmUp());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    unawaited(_accentPlayer.dispose());
    unawaited(_regularPlayer.dispose());
    super.dispose();
  }

  Duration get _interval => Duration(milliseconds: (60000 / _bpm).round());

  void _tick() {
    final nextBeat = (_activeBeat + 1) % _beatsPerBar;
    if (nextBeat == 0) {
      unawaited(_accentPlayer.play(volume: 0.95));
    } else {
      unawaited(_regularPlayer.play(volume: 0.8));
    }
    if (!mounted) return;
    _pulseController
      ..stop()
      ..forward(from: 0);
    setState(() {
      _activeBeat = nextBeat;
    });
  }

  void _start() {
    _timer?.cancel();
    _running = true;
    _tick();
    _timer = Timer.periodic(_interval, (_) {
      _tick();
    });
    setState(() {});
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _activeBeat = -1;
    setState(() {});
  }

  void _restartIfNeeded() {
    if (_running) {
      _start();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBeat = _activeBeat < 0 ? '--' : '${_activeBeat + 1}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(label: 'BPM', value: '$_bpm'),
                ToolboxMetricCard(label: 'Bar', value: '$_beatsPerBar beats'),
                ToolboxMetricCard(label: 'Beat', value: currentBeat),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final pulse = 1 + (1 - _pulseController.value) * 0.08;
                return Center(
                  child: Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.9),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.16),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        currentBeat,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _running ? _stop : _start,
              icon: Icon(
                _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(_running ? 'Stop beats' : 'Start beats'),
            ),
            const SizedBox(height: 14),
            Text('Tempo $_bpm BPM'),
            Slider(
              value: _bpm.toDouble(),
              min: 40,
              max: 160,
              divisions: 120,
              onChanged: (value) {
                _bpm = value.round();
                _restartIfNeeded();
              },
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: <int>[2, 3, 4, 6]
                  .map(
                    (count) => ChoiceChip(
                      label: Text('$count / bar'),
                      selected: _beatsPerBar == count,
                      onSelected: (_) {
                        _beatsPerBar = count;
                        _activeBeat = -1;
                        _restartIfNeeded();
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _WoodfishTool extends StatefulWidget {
  const _WoodfishTool();

  @override
  State<_WoodfishTool> createState() => _WoodfishToolState();
}

class _WoodfishToolState extends State<_WoodfishTool> {
  late final ToolboxEffectPlayer _player;
  int _count = 0;
  int _flashCounter = 0;

  @override
  void initState() {
    super.initState();
    _player = ToolboxEffectPlayer(
      ToolboxAudioBank.woodfishClick(),
      maxPlayers: 6,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_player.warmUp());
    });
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  void _hit() {
    HapticFeedback.mediumImpact();
    unawaited(_player.play(volume: 1.0));
    if (!mounted) return;
    setState(() {
      _count += 1;
      _flashCounter += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(label: 'Today', value: '$_count taps'),
                const ToolboxMetricCard(label: 'Mode', value: 'Single strike'),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _hit,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 1.35,
                    child: CustomPaint(
                      painter: _WoodfishPainter(
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '$_count',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          '+1',
                          key: ValueKey<int>(_flashCounter),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _hit,
                  icon: const Icon(Icons.pan_tool_alt_rounded),
                  label: const Text('Strike once'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _count = 0),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset count'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PianoKey {
  const _PianoKey({
    required this.id,
    required this.label,
    required this.frequency,
    this.blackAfter = false,
  });

  final String id;
  final String label;
  final double frequency;
  final bool blackAfter;
}

class _PianoPreset {
  const _PianoPreset({
    required this.id,
    required this.styleId,
    required this.touch,
  });

  final String id;
  final String styleId;
  final double touch;
}

class _FlutePreset {
  const _FlutePreset({
    required this.id,
    required this.styleId,
    required this.scaleId,
    required this.breath,
  });

  final String id;
  final String styleId;
  final String scaleId;
  final double breath;
}

class _DrumKitPreset {
  const _DrumKitPreset({
    required this.id,
    required this.kitId,
    required this.drive,
  });

  final String id;
  final String kitId;
  final double drive;
}

class _GuitarPreset {
  const _GuitarPreset({
    required this.id,
    required this.styleId,
    required this.pluckVolume,
    required this.strumVolume,
    required this.strumDelayMs,
  });

  final String id;
  final String styleId;
  final double pluckVolume;
  final double strumVolume;
  final int strumDelayMs;
}

class _TrianglePreset {
  const _TrianglePreset({
    required this.id,
    required this.styleId,
    required this.ring,
  });

  final String id;
  final String styleId;
  final double ring;
}

class _PianoTool extends StatefulWidget {
  const _PianoTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_PianoTool> createState() => _PianoToolState();
}

class _PianoToolState extends State<_PianoTool> {
  static const List<_PianoKey> _whiteKeys = <_PianoKey>[
    _PianoKey(id: 'C2', label: 'C2', frequency: 65.41, blackAfter: true),
    _PianoKey(id: 'D2', label: 'D2', frequency: 73.42, blackAfter: true),
    _PianoKey(id: 'E2', label: 'E2', frequency: 82.41),
    _PianoKey(id: 'F2', label: 'F2', frequency: 87.31, blackAfter: true),
    _PianoKey(id: 'G2', label: 'G2', frequency: 98.0, blackAfter: true),
    _PianoKey(id: 'A2', label: 'A2', frequency: 110.0, blackAfter: true),
    _PianoKey(id: 'B2', label: 'B2', frequency: 123.47),
    _PianoKey(id: 'C3', label: 'C3', frequency: 130.81, blackAfter: true),
    _PianoKey(id: 'D3', label: 'D3', frequency: 146.83, blackAfter: true),
    _PianoKey(id: 'E3', label: 'E3', frequency: 164.81),
    _PianoKey(id: 'F3', label: 'F3', frequency: 174.61, blackAfter: true),
    _PianoKey(id: 'G3', label: 'G3', frequency: 196.0, blackAfter: true),
    _PianoKey(id: 'A3', label: 'A3', frequency: 220.0, blackAfter: true),
    _PianoKey(id: 'B3', label: 'B3', frequency: 246.94),
    _PianoKey(id: 'C4', label: 'C4', frequency: 261.63, blackAfter: true),
    _PianoKey(id: 'D4', label: 'D4', frequency: 293.66, blackAfter: true),
    _PianoKey(id: 'E4', label: 'E4', frequency: 329.63),
    _PianoKey(id: 'F4', label: 'F4', frequency: 349.23, blackAfter: true),
    _PianoKey(id: 'G4', label: 'G4', frequency: 392.0, blackAfter: true),
    _PianoKey(id: 'A4', label: 'A4', frequency: 440.0, blackAfter: true),
    _PianoKey(id: 'B4', label: 'B4', frequency: 493.88),
    _PianoKey(id: 'C5', label: 'C5', frequency: 523.25, blackAfter: true),
    _PianoKey(id: 'D5', label: 'D5', frequency: 587.33, blackAfter: true),
    _PianoKey(id: 'E5', label: 'E5', frequency: 659.25),
    _PianoKey(id: 'F5', label: 'F5', frequency: 698.46, blackAfter: true),
    _PianoKey(id: 'G5', label: 'G5', frequency: 783.99, blackAfter: true),
    _PianoKey(id: 'A5', label: 'A5', frequency: 880.0, blackAfter: true),
    _PianoKey(id: 'B5', label: 'B5', frequency: 987.77),
    _PianoKey(id: 'C6', label: 'C6', frequency: 1046.5),
  ];
  static const List<_PianoKey> _blackKeys = <_PianoKey>[
    _PianoKey(id: 'C#2', label: 'C#2', frequency: 69.30),
    _PianoKey(id: 'D#2', label: 'D#2', frequency: 77.78),
    _PianoKey(id: 'F#2', label: 'F#2', frequency: 92.50),
    _PianoKey(id: 'G#2', label: 'G#2', frequency: 103.83),
    _PianoKey(id: 'A#2', label: 'A#2', frequency: 116.54),
    _PianoKey(id: 'C#3', label: 'C#3', frequency: 138.59),
    _PianoKey(id: 'D#3', label: 'D#3', frequency: 155.56),
    _PianoKey(id: 'F#3', label: 'F#3', frequency: 185.0),
    _PianoKey(id: 'G#3', label: 'G#3', frequency: 207.65),
    _PianoKey(id: 'A#3', label: 'A#3', frequency: 233.08),
    _PianoKey(id: 'C#4', label: 'C#4', frequency: 277.18),
    _PianoKey(id: 'D#4', label: 'D#4', frequency: 311.13),
    _PianoKey(id: 'F#4', label: 'F#4', frequency: 369.99),
    _PianoKey(id: 'G#4', label: 'G#4', frequency: 415.3),
    _PianoKey(id: 'A#4', label: 'A#4', frequency: 466.16),
    _PianoKey(id: 'C#5', label: 'C#5', frequency: 554.37),
    _PianoKey(id: 'D#5', label: 'D#5', frequency: 622.25),
    _PianoKey(id: 'F#5', label: 'F#5', frequency: 739.99),
    _PianoKey(id: 'G#5', label: 'G#5', frequency: 830.61),
    _PianoKey(id: 'A#5', label: 'A#5', frequency: 932.33),
  ];
  static const List<int> _blackSlots = <int>[
    0,
    1,
    3,
    4,
    5,
    7,
    8,
    10,
    11,
    12,
    14,
    15,
    17,
    18,
    19,
    21,
    22,
    24,
    25,
    26,
  ];
  static const List<_PianoPreset> _presets = <_PianoPreset>[
    _PianoPreset(id: 'concert_hall', styleId: 'concert', touch: 0.92),
    _PianoPreset(id: 'bright_stage', styleId: 'bright', touch: 0.96),
    _PianoPreset(id: 'felt_room', styleId: 'felt', touch: 0.84),
  ];

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  String? _activeKeyId;
  String _presetId = _presets.first.id;
  double _touch = _presets.first.touch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _PianoPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'bright_stage' => pickUiText(
        i18n,
        zh: '明亮舞台',
        en: 'Bright stage',
        ja: 'ブライトステージ',
        de: 'Helle Bühne',
        fr: 'Scène brillante',
        es: 'Escenario brillante',
        ru: 'Яркая сцена',
      ),
      'felt_room' => pickUiText(
        i18n,
        zh: '毛毡小室',
        en: 'Felt room',
        ja: 'フェルトルーム',
        de: 'Felt-Raum',
        fr: 'Pièce feutrée',
        es: 'Sala de fieltro',
        ru: 'Фетровая комната',
      ),
      _ => pickUiText(
        i18n,
        zh: '音乐厅',
        en: 'Concert hall',
        ja: 'コンサートホール',
        de: 'Konzertsaal',
        fr: 'Salle de concert',
        es: 'Sala de conciertos',
        ru: 'Концертный зал',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'bright_stage' => pickUiText(
        i18n,
        zh: '更强击弦感与亮度，适合旋律突出。',
        en: 'Sharper hammer attack and brighter harmonics for lead lines.',
        ja: 'ハンマー感と高域を強めた、主旋律向けの音色。',
        de: 'Klarerer Anschlag und hellere Obertöne für Lead-Melodien.',
        fr: 'Attaque plus nette et harmoniques brillantes pour la mélodie.',
        es: 'Ataque más marcado y armónicos brillantes para la melodía.',
        ru: 'Более резкая атака и яркие обертоны для ведущей мелодии.',
      ),
      'felt_room' => pickUiText(
        i18n,
        zh: '柔和包裹感，适合夜间安静弹奏。',
        en: 'Softer felt-like body for intimate and quiet playing.',
        ja: '柔らかいフェルト感で、静かな演奏に向くトーン。',
        de: 'Weicher, intimer Felt-Charakter für ruhiges Spielen.',
        fr: 'Corps feutré et doux pour un jeu intime et calme.',
        es: 'Cuerpo más suave tipo fieltro para tocar en calma.',
        ru: 'Мягкий, камерный тембр в стиле felt для спокойной игры.',
      ),
      _ => pickUiText(
        i18n,
        zh: '均衡延音与空间感，通用演奏音色。',
        en: 'Balanced sustain and room feel for all-purpose playing.',
        ja: 'サステインと空間感のバランスが良い標準トーン。',
        de: 'Ausgewogener Sustain mit Raumgefühl für vielseitiges Spiel.',
        fr: 'Sustain équilibré et sensation d’espace polyvalente.',
        es: 'Sustain equilibrado y sensación de sala para todo uso.',
        ru: 'Сбалансированный сустейн и пространство для универсальной игры.',
      ),
    };
  }

  void _invalidatePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  void _applyPreset(String presetId) {
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    if (_presetId == preset.id) return;
    setState(() {
      _presetId = preset.id;
      _touch = preset.touch;
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
  }

  Future<void> _warmUpActivePreset() async {
    final warmupKeys = <_PianoKey>[..._whiteKeys, ..._blackKeys];
    for (final key in warmupKeys) {
      await _playerFor(key).warmUp();
    }
  }

  ToolboxEffectPlayer _playerFor(_PianoKey key) {
    final styleId = _activePreset.styleId;
    final cacheKey = '${key.id}:$styleId';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.pianoNote(key.frequency, style: styleId),
      maxPlayers: 8,
    );
    _players[cacheKey] = created;
    return created;
  }

  Future<void> _hitKey(_PianoKey key, {double? volume}) async {
    HapticFeedback.selectionClick();
    unawaited(_playerFor(key).play(volume: volume ?? _touch));
    if (!mounted) return;
    setState(() {
      _activeKeyId = key.id;
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || _activeKeyId != key.id) return;
      setState(() {
        _activeKeyId = null;
      });
    });
  }

  @override
  void dispose() {
    _invalidatePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final preset = _activePreset;
    final presetLabel = _presetLabel(i18n, preset);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '琴键',
                    en: 'Keys',
                    ja: '鍵盤',
                    de: 'Tasten',
                    fr: 'Touches',
                    es: 'Teclas',
                    ru: 'Клавиши',
                  ),
                  value: '${_whiteKeys.length + _blackKeys.length}',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '音域',
                    en: 'Range',
                    ja: '音域',
                    de: 'Umfang',
                    fr: 'Étendue',
                    es: 'Rango',
                    ru: 'Диапазон',
                  ),
                  value: 'C2-C6',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '预设',
                    en: 'Preset',
                    ja: 'プリセット',
                    de: 'Preset',
                    fr: 'Préréglage',
                    es: 'Preajuste',
                    ru: 'Пресет',
                  ),
                  value: presetLabel,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SectionHeader(
              title: pickUiText(
                i18n,
                zh: '预设包',
                en: 'Preset pack',
                ja: 'プリセットパック',
                de: 'Preset-Paket',
                fr: 'Pack de préréglages',
                es: 'Paquete de presets',
                ru: 'Пакет пресетов',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '切换钢琴音色与默认触键力度。',
                en: 'Switch timbre and default touch intensity.',
                ja: '音色と初期タッチ強度を切り替えます。',
                de: 'Wechselt Klangfarbe und Standard-Anschlagsstärke.',
                fr: 'Basculez le timbre et l’intensité de toucher par défaut.',
                es: 'Cambia timbre e intensidad de toque por defecto.',
                ru: 'Переключает тембр и базовую силу нажатия.',
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
            Text(
              _presetSubtitle(i18n, preset),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              pickUiText(
                i18n,
                zh: '触键力度 ${(_touch * 100).round()}%',
                en: 'Touch ${(_touch * 100).round()}%',
                ja: 'タッチ ${(_touch * 100).round()}%',
                de: 'Anschlag ${(_touch * 100).round()}%',
                fr: 'Toucher ${(_touch * 100).round()}%',
                es: 'Toque ${(_touch * 100).round()}%',
                ru: 'Касание ${(_touch * 100).round()}%',
              ),
              style: theme.textTheme.labelLarge,
            ),
            Slider(
              value: _touch,
              min: 0.55,
              max: 1.0,
              divisions: 18,
              onChanged: (value) => setState(() => _touch = value),
            ),
            const SizedBox(height: 6),
            SectionHeader(
              title: pickUiText(
                i18n,
                zh: '键盘',
                en: 'Keyboard',
                ja: '鍵盤',
                de: 'Klaviatur',
                fr: 'Clavier',
                es: 'Teclado',
                ru: 'Клавиатура',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '直接点击琴键演奏，黑键覆盖在白键上层。',
                en: 'Tap keys directly. Black keys are layered above.',
                ja: '鍵盤を直接タップ。黒鍵は白鍵の上に重なります。',
                de: 'Tasten direkt antippen. Schwarze Tasten liegen darüber.',
                fr: 'Touchez directement les touches. Les noires sont au-dessus.',
                es: 'Toca directamente las teclas. Las negras van por encima.',
                ru: 'Нажимайте клавиши напрямую; чёрные расположены поверх белых.',
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: widget.fullScreen ? 300 : 240,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minWhiteWidth = 44.0;
                  final totalWidth = math.max(
                    constraints.maxWidth,
                    _whiteKeys.length * minWhiteWidth,
                  );
                  final whiteWidth = totalWidth / _whiteKeys.length;
                  final blackWidth = whiteWidth * 0.64;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: totalWidth,
                      child: Stack(
                        children: <Widget>[
                          Row(
                            children: _whiteKeys
                                .map(
                                  (key) => SizedBox(
                                    width: whiteWidth,
                                    child: Listener(
                                      behavior: HitTestBehavior.opaque,
                                      onPointerDown: (_) =>
                                          unawaited(_hitKey(key)),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 90,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                bottom: Radius.circular(12),
                                              ),
                                          border: Border.all(
                                            color: theme
                                                .colorScheme
                                                .outlineVariant,
                                          ),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: <Color>[
                                              _activeKeyId == key.id
                                                  ? theme
                                                        .colorScheme
                                                        .primaryContainer
                                                  : Colors.white,
                                              _activeKeyId == key.id
                                                  ? theme.colorScheme.primary
                                                        .withValues(alpha: 0.32)
                                                  : const Color(0xFFEFF2F8),
                                            ],
                                          ),
                                        ),
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: Text(
                                              key.label,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          ...List<Widget>.generate(_blackKeys.length, (index) {
                            final key = _blackKeys[index];
                            final slot = _blackSlots[index];
                            return Positioned(
                              left: whiteWidth * (slot + 1) - blackWidth / 2,
                              top: 0,
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: (_) =>
                                    unawaited(_hitKey(key, volume: 0.9)),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 90),
                                  width: blackWidth,
                                  height: widget.fullScreen ? 180 : 148,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(10),
                                    ),
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                        alpha: 0.38,
                                      ),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: <Color>[
                                        _activeKeyId == key.id
                                            ? const Color(0xFF2F56A6)
                                            : const Color(0xFF12141A),
                                        _activeKeyId == key.id
                                            ? const Color(0xFF1A2E63)
                                            : const Color(0xFF050608),
                                      ],
                                    ),
                                  ),
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      key.label,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
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

class _FluteTool extends StatefulWidget {
  const _FluteTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_FluteTool> createState() => _FluteToolState();
}

class _FluteToolState extends State<_FluteTool> {
  static const List<_PianoKey> _majorNotes = <_PianoKey>[
    _PianoKey(id: 'C5', label: 'C', frequency: 523.25),
    _PianoKey(id: 'D5', label: 'D', frequency: 587.33),
    _PianoKey(id: 'E5', label: 'E', frequency: 659.25),
    _PianoKey(id: 'F5', label: 'F', frequency: 698.46),
    _PianoKey(id: 'G5', label: 'G', frequency: 783.99),
    _PianoKey(id: 'A5', label: 'A', frequency: 880.0),
    _PianoKey(id: 'B5', label: 'B', frequency: 987.77),
  ];
  static const List<_PianoKey> _pentatonicNotes = <_PianoKey>[
    _PianoKey(id: 'C5', label: 'C', frequency: 523.25),
    _PianoKey(id: 'D5', label: 'D', frequency: 587.33),
    _PianoKey(id: 'E5', label: 'E', frequency: 659.25),
    _PianoKey(id: 'G5', label: 'G', frequency: 783.99),
    _PianoKey(id: 'A5', label: 'A', frequency: 880.0),
    _PianoKey(id: 'C6', label: 'C6', frequency: 1046.5),
  ];
  static const List<_PianoKey> _dorianNotes = <_PianoKey>[
    _PianoKey(id: 'D5', label: 'D', frequency: 587.33),
    _PianoKey(id: 'E5', label: 'E', frequency: 659.25),
    _PianoKey(id: 'F5', label: 'F', frequency: 698.46),
    _PianoKey(id: 'G5', label: 'G', frequency: 783.99),
    _PianoKey(id: 'A5', label: 'A', frequency: 880.0),
    _PianoKey(id: 'B5', label: 'B', frequency: 987.77),
    _PianoKey(id: 'C6', label: 'C6', frequency: 1046.5),
  ];
  static const List<_FlutePreset> _presets = <_FlutePreset>[
    _FlutePreset(
      id: 'airy_flow',
      styleId: 'airy',
      scaleId: 'major',
      breath: 0.76,
    ),
    _FlutePreset(
      id: 'lead_solo',
      styleId: 'lead',
      scaleId: 'pentatonic',
      breath: 0.86,
    ),
    _FlutePreset(
      id: 'alto_warm',
      styleId: 'alto',
      scaleId: 'dorian',
      breath: 0.68,
    ),
  ];

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  final AudioRecorder _micRecorder = AudioRecorder();
  final ToolboxLoopController _sustainLoop = ToolboxLoopController();
  StreamSubscription<Amplitude>? _amplitudeSub;
  final Set<int> _pressedHoles = <int>{};
  String _presetId = _presets.first.id;
  String _scale = _presets.first.scaleId;
  String _style = _presets.first.styleId;
  double _breath = _presets.first.breath;
  bool _blowSensorEnabled = false;
  bool _blowPermissionDenied = false;
  bool _isBlowing = false;
  double _micLevel = 0;
  double _blowThreshold = 0.34;
  int? _sustainedNoteIndex;
  String? _lastNote;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _FlutePreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  List<_PianoKey> get _activeNotes {
    return switch (_scale) {
      'pentatonic' => _pentatonicNotes,
      'dorian' => _dorianNotes,
      _ => _majorNotes,
    };
  }

  String _presetLabel(AppI18n i18n, _FlutePreset preset) {
    return switch (preset.id) {
      'lead_solo' => pickUiText(
        i18n,
        zh: '独奏领奏',
        en: 'Lead solo',
        ja: 'リードソロ',
        de: 'Lead-Solo',
        fr: 'Solo lead',
        es: 'Solo lead',
        ru: 'Лид-соло',
      ),
      'alto_warm' => pickUiText(
        i18n,
        zh: '暖音中音',
        en: 'Warm alto',
        ja: 'ウォームアルト',
        de: 'Warmes Alt',
        fr: 'Alto chaud',
        es: 'Alto cálido',
        ru: 'Тёплый альт',
      ),
      _ => pickUiText(
        i18n,
        zh: '空气流',
        en: 'Airy flow',
        ja: 'エアリーフロー',
        de: 'Luftiger Fluss',
        fr: 'Flux aérien',
        es: 'Flujo aéreo',
        ru: 'Воздушный поток',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _FlutePreset preset) {
    return switch (preset.id) {
      'lead_solo' => pickUiText(
        i18n,
        zh: '更亮、更靠前，适合旋律句的突出。',
        en: 'Brighter lead tone with stronger presence for melodic phrases.',
        ja: '明るく前に出る音色で、主旋律を際立たせます。',
        de: 'Hellerer Lead-Sound mit mehr Präsenz für Melodielinien.',
        fr: 'Timbre plus brillant et présent pour les lignes mélodiques.',
        es: 'Tono más brillante y presente para frases melódicas.',
        ru: 'Более яркий и выдвинутый тембр для мелодических фраз.',
      ),
      'alto_warm' => pickUiText(
        i18n,
        zh: '更厚实的中频和更柔和尾音，适合氛围铺底。',
        en: 'Warmer midrange and softer tail for calm backing layers.',
        ja: '中域を厚くし、余韻を柔らかくした落ち着いたトーン。',
        de: 'Wärmere Mitten und weicheres Ausklingen für ruhige Flächen.',
        fr: 'Médiums plus chauds et fin de note douce pour des nappes calmes.',
        es: 'Medios más cálidos y cola suave para capas tranquilas.',
        ru: 'Тёплая середина и мягкий хвост для спокойной подложки.',
      ),
      _ => pickUiText(
        i18n,
        zh: '自然气息感，适合轻柔演奏。',
        en: 'Natural breathy tone for gentle and flowing play.',
        ja: '自然な息づかいで、やわらかな演奏に向きます。',
        de: 'Natürlicher, luftiger Klang für sanftes Spiel.',
        fr: 'Souffle naturel pour un jeu doux et fluide.',
        es: 'Tono de soplo natural para tocar suave y fluido.',
        ru: 'Естественное дыхание тембра для мягкой и плавной игры.',
      ),
    };
  }

  String _scaleLabel(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'pentatonic' => pickUiText(
        i18n,
        zh: '五声音阶',
        en: 'Pentatonic',
        ja: 'ペンタトニック',
        de: 'Pentatonik',
        fr: 'Pentatonique',
        es: 'Pentatónica',
        ru: 'Пентатоника',
      ),
      'dorian' => pickUiText(
        i18n,
        zh: '多利亚',
        en: 'Dorian',
        ja: 'ドリアン',
        de: 'Dorisch',
        fr: 'Dorien',
        es: 'Dórico',
        ru: 'Дорийский',
      ),
      _ => pickUiText(
        i18n,
        zh: '大调',
        en: 'Major',
        ja: 'メジャー',
        de: 'Dur',
        fr: 'Majeur',
        es: 'Mayor',
        ru: 'Мажор',
      ),
    };
  }

  String _styleLabel(AppI18n i18n, String styleId) {
    return switch (styleId) {
      'lead' => pickUiText(
        i18n,
        zh: '领奏',
        en: 'Lead',
        ja: 'リード',
        de: 'Lead',
        fr: 'Lead',
        es: 'Lead',
        ru: 'Лид',
      ),
      'alto' => pickUiText(
        i18n,
        zh: '中音',
        en: 'Alto',
        ja: 'アルト',
        de: 'Alt',
        fr: 'Alto',
        es: 'Alto',
        ru: 'Альт',
      ),
      _ => pickUiText(
        i18n,
        zh: '空气',
        en: 'Airy',
        ja: 'エアリー',
        de: 'Luftig',
        fr: 'Aérien',
        es: 'Aéreo',
        ru: 'Воздушный',
      ),
    };
  }

  double _normalizedMicLevel(Amplitude amplitude) {
    final value = amplitude.current;
    if (value.isNaN || value.isInfinite) return 0;
    if (value >= 0 && value <= 1.2) {
      return value.clamp(0.0, 1.0).toDouble();
    }
    return ((value + 60) / 60).clamp(0.0, 1.0).toDouble();
  }

  int? _noteIndexFromHoles() {
    if (_pressedHoles.isEmpty) return null;
    final notes = _activeNotes;
    if (notes.isEmpty) return null;
    final closed = _pressedHoles.length.clamp(1, 6);
    return (notes.length - closed).clamp(0, notes.length - 1);
  }

  Future<void> _syncBreathSustain() async {
    final nextIndex = (_blowSensorEnabled && _isBlowing)
        ? _noteIndexFromHoles()
        : null;
    if (nextIndex == null) {
      if (_sustainedNoteIndex != null) {
        _sustainedNoteIndex = null;
        await _sustainLoop.stop();
      }
      return;
    }
    final note = _activeNotes[nextIndex];
    if (_sustainedNoteIndex == nextIndex) {
      await _sustainLoop.setVolume(_breath.clamp(0.2, 1.0));
      return;
    }
    _sustainedNoteIndex = nextIndex;
    _lastNote = note.label;
    await _sustainLoop.play(
      ToolboxAudioBank.fluteNote(note.frequency, style: _style),
      volume: _breath.clamp(0.2, 1.0),
    );
    if (mounted) {
      setState(() {});
    }
  }

  void _setHolePressed(int index, bool pressed) {
    var changed = false;
    if (pressed) {
      changed = _pressedHoles.add(index);
    } else {
      changed = _pressedHoles.remove(index);
    }
    if (!changed) return;
    if (mounted) {
      setState(() {});
    }
    unawaited(_syncBreathSustain());
  }

  Future<void> _startBlowSensor() async {
    if (_blowSensorEnabled) return;
    try {
      final granted = await _micRecorder.hasPermission();
      if (!granted) {
        if (mounted) {
          setState(() {
            _blowPermissionDenied = true;
            _blowSensorEnabled = false;
            _isBlowing = false;
            _micLevel = 0;
          });
        }
        await _syncBreathSustain();
        return;
      }
      await _micRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path:
            '${Directory.systemTemp.path}${Platform.pathSeparator}'
            'flute_blow_meter_${DateTime.now().microsecondsSinceEpoch}.wav',
      );
      await _amplitudeSub?.cancel();
      _amplitudeSub = _micRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 60))
          .listen((amplitude) {
            final level = _normalizedMicLevel(amplitude);
            final blowing = level >= _blowThreshold;
            var shouldRefresh = false;
            if ((_micLevel - level).abs() > 0.01) {
              _micLevel = level;
              shouldRefresh = true;
            }
            if (_isBlowing != blowing) {
              _isBlowing = blowing;
              shouldRefresh = true;
              unawaited(_syncBreathSustain());
            }
            if (shouldRefresh && mounted) {
              setState(() {});
            }
          });
      if (mounted) {
        setState(() {
          _blowSensorEnabled = true;
          _blowPermissionDenied = false;
          _isBlowing = false;
          _micLevel = 0;
        });
      }
      unawaited(_warmUpActivePreset());
    } catch (_) {
      if (mounted) {
        setState(() {
          _blowPermissionDenied = true;
          _blowSensorEnabled = false;
          _isBlowing = false;
          _micLevel = 0;
        });
      }
      await _syncBreathSustain();
    }
  }

  Future<void> _stopBlowSensor({bool resetUi = true}) async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    try {
      await _micRecorder.stop();
    } catch (_) {}
    _isBlowing = false;
    _blowSensorEnabled = false;
    if (resetUi) {
      _micLevel = 0;
    }
    await _syncBreathSustain();
    if (resetUi && mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleBlowSensor() async {
    if (_blowSensorEnabled) {
      await _stopBlowSensor();
      return;
    }
    await _startBlowSensor();
  }

  Future<void> _disposeMicRecorder() async {
    try {
      await _micRecorder.stop();
    } catch (_) {}
    try {
      await _micRecorder.dispose();
    } catch (_) {}
  }

  void _invalidatePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  Future<void> _warmUpActivePreset() async {
    for (final note in _activeNotes.take(6)) {
      await _playerFor(note).warmUp();
    }
  }

  void _applyPreset(String presetId) {
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    setState(() {
      _presetId = preset.id;
      _style = preset.styleId;
      _scale = preset.scaleId;
      _breath = preset.breath;
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
    unawaited(_syncBreathSustain());
  }

  ToolboxEffectPlayer _playerFor(_PianoKey key) {
    final cacheKey = 'flute:${key.id}:$_style';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.fluteNote(key.frequency, style: _style),
      maxPlayers: 6,
    );
    _players[cacheKey] = created;
    return created;
  }

  Future<void> _play(_PianoKey key) async {
    HapticFeedback.selectionClick();
    unawaited(_playerFor(key).play(volume: _breath.clamp(0.2, 1.0)));
    if (!mounted) return;
    setState(() {
      _lastNote = key.label;
    });
  }

  @override
  void dispose() {
    final amplitudeSub = _amplitudeSub;
    _amplitudeSub = null;
    if (amplitudeSub != null) {
      unawaited(amplitudeSub.cancel());
    }
    unawaited(_disposeMicRecorder());
    unawaited(_sustainLoop.dispose());
    _invalidatePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final preset = _activePreset;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '预设',
                    en: 'Preset',
                    ja: 'プリセット',
                    de: 'Preset',
                    fr: 'Préréglage',
                    es: 'Preajuste',
                    ru: 'Пресет',
                  ),
                  value: _presetLabel(i18n, preset),
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '调式',
                    en: 'Scale',
                    ja: 'スケール',
                    de: 'Skala',
                    fr: 'Gamme',
                    es: 'Escala',
                    ru: 'Лад',
                  ),
                  value: _scaleLabel(i18n, _scale),
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '气息',
                    en: 'Breath',
                    ja: 'ブレス',
                    de: 'Atem',
                    fr: 'Souffle',
                    es: 'Soplo',
                    ru: 'Дыхание',
                  ),
                  value: '${(_breath * 100).round()}%',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '最近音符',
                    en: 'Last note',
                    ja: '直前ノート',
                    de: 'Letzter Ton',
                    fr: 'Dernière note',
                    es: 'Última nota',
                    ru: 'Последняя нота',
                  ),
                  value: _lastNote ?? '--',
                ),
              ],
            ),
            const SizedBox(height: 14),
            SectionHeader(
              title: pickUiText(
                i18n,
                zh: '预设包',
                en: 'Preset pack',
                ja: 'プリセットパック',
                de: 'Preset-Paket',
                fr: 'Pack de préréglages',
                es: 'Paquete de presets',
                ru: 'Пакет пресетов',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '每个预设同时绑定音色、调式和默认气息强度。',
                en: 'Each preset binds timbre, scale, and default breath intensity.',
                ja: '各プリセットは音色・スケール・ブレス強度をまとめて切り替えます。',
                de: 'Jedes Preset verknüpft Klangfarbe, Skala und Atemintensität.',
                fr: 'Chaque preset relie timbre, gamme et intensité de souffle.',
                es: 'Cada preset combina timbre, escala e intensidad de soplo.',
                ru: 'Каждый пресет связывает тембр, лад и силу дыхания.',
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
            Text(
              _presetSubtitle(i18n, preset),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFE7F2FF),
                    Color(0xFFCFE6FF),
                    Color(0xFFBADBFF),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
              ),
              child: Row(
                children: List<Widget>.generate(7, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index.isEven
                            ? const Color(0xFF7A9AC8)
                            : const Color(0xFF5578AB),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <String>['major', 'pentatonic', 'dorian']
                  .map(
                    (item) => ChoiceChip(
                      label: Text(_scaleLabel(i18n, item)),
                      selected: _scale == item,
                      onSelected: (_) {
                        if (_scale == item) return;
                        setState(() => _scale = item);
                        _invalidatePlayers();
                        unawaited(_warmUpActivePreset());
                        unawaited(_syncBreathSustain());
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Text(
              pickUiText(
                i18n,
                zh: '气息 ${(_breath * 100).round()}% · 音色 ${_styleLabel(i18n, _style)}',
                en: 'Breath ${(_breath * 100).round()}% · Tone ${_styleLabel(i18n, _style)}',
                ja: 'ブレス ${(_breath * 100).round()}% · 音色 ${_styleLabel(i18n, _style)}',
                de: 'Atem ${(_breath * 100).round()}% · Klang ${_styleLabel(i18n, _style)}',
                fr: 'Souffle ${(_breath * 100).round()}% · Timbre ${_styleLabel(i18n, _style)}',
                es: 'Soplo ${(_breath * 100).round()}% · Timbre ${_styleLabel(i18n, _style)}',
                ru: 'Дыхание ${(_breath * 100).round()}% · Тембр ${_styleLabel(i18n, _style)}',
              ),
            ),
            Slider(
              value: _breath,
              min: 0.2,
              max: 1.0,
              divisions: 16,
              onChanged: (value) {
                setState(() => _breath = value);
                unawaited(_syncBreathSustain());
              },
            ),
            const SizedBox(height: 8),
            SectionHeader(
              title: pickUiText(i18n, zh: '模拟吹奏', en: 'Blow Simulation'),
              subtitle: pickUiText(
                i18n,
                zh: '使用麦克风吹气 + 按孔触发持续发音，松手后结束。',
                en: 'Use microphone breath + hole buttons for sustained notes, then stop on release.',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: _toggleBlowSensor,
                  icon: Icon(
                    _blowSensorEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                  ),
                  label: Text(
                    _blowSensorEnabled
                        ? pickUiText(
                            i18n,
                            zh: '关闭吹气检测',
                            en: 'Disable blow sensor',
                          )
                        : pickUiText(
                            i18n,
                            zh: '开启吹气检测',
                            en: 'Enable blow sensor',
                          ),
                  ),
                ),
                if (_blowPermissionDenied)
                  Text(
                    pickUiText(
                      i18n,
                      zh: '麦克风权限不可用',
                      en: 'Microphone permission unavailable',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '吹气阈值 ${(_blowThreshold * 100).round()}% · 当前 ${(_micLevel * 100).round()}%',
                en: 'Blow threshold ${(_blowThreshold * 100).round()}% · Current ${(_micLevel * 100).round()}%',
              ),
            ),
            Slider(
              value: _blowThreshold,
              min: 0.12,
              max: 0.75,
              divisions: 21,
              onChanged: (value) {
                setState(() => _blowThreshold = value);
              },
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _micLevel.clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List<Widget>.generate(6, (index) {
                final holeNumber = index + 1;
                final pressed = _pressedHoles.contains(holeNumber);
                return Listener(
                  onPointerDown: (_) => _setHolePressed(holeNumber, true),
                  onPointerUp: (_) => _setHolePressed(holeNumber, false),
                  onPointerCancel: (_) => _setHolePressed(holeNumber, false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: widget.fullScreen ? 62 : 54,
                    height: widget.fullScreen ? 62 : 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pressed
                          ? const Color(0xFF2563EB)
                          : theme.colorScheme.surfaceContainerHigh,
                      border: Border.all(
                        color: pressed
                            ? const Color(0xFF1D4ED8)
                            : theme.colorScheme.outlineVariant,
                      ),
                      boxShadow: pressed
                          ? <BoxShadow>[
                              BoxShadow(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.28),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : const <BoxShadow>[],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'H$holeNumber',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: pressed
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '吹气状态：${_isBlowing ? "进行中" : "未吹气"} · 按孔：${_pressedHoles.length}',
                en: 'Blow: ${_isBlowing ? "active" : "idle"} · Holes pressed: ${_pressedHoles.length}',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activeNotes
                  .map(
                    (note) => FilledButton.tonal(
                      onPressed: () => unawaited(_play(note)),
                      child: Text(note.label),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrumPad {
  const _DrumPad({required this.id, required this.color});

  final String id;
  final Color color;
}

class _DrumPadTool extends StatefulWidget {
  const _DrumPadTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_DrumPadTool> createState() => _DrumPadToolState();
}

class _DrumPadToolState extends State<_DrumPadTool> {
  static const List<_DrumPad> _pads = <_DrumPad>[
    _DrumPad(id: 'kick', color: Color(0xFF2563EB)),
    _DrumPad(id: 'snare', color: Color(0xFFEF4444)),
    _DrumPad(id: 'hihat', color: Color(0xFFF59E0B)),
    _DrumPad(id: 'tom', color: Color(0xFF10B981)),
  ];
  static const List<_DrumKitPreset> _presets = <_DrumKitPreset>[
    _DrumKitPreset(id: 'acoustic_kit', kitId: 'acoustic', drive: 1.0),
    _DrumKitPreset(id: 'electro_kit', kitId: 'electro', drive: 0.96),
    _DrumKitPreset(id: 'lofi_kit', kitId: 'lofi', drive: 0.88),
  ];

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  String? _activePadId;
  String? _lastHitId;
  int _hits = 0;
  String _presetId = _presets.first.id;
  String _kit = _presets.first.kitId;
  double _drive = _presets.first.drive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _DrumKitPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _DrumKitPreset preset) {
    return switch (preset.id) {
      'electro_kit' => pickUiText(
        i18n,
        zh: '电子套件',
        en: 'Electro kit',
        ja: 'エレクトロキット',
        de: 'Elektro-Kit',
        fr: 'Kit électro',
        es: 'Kit electro',
        ru: 'Электро-набор',
      ),
      'lofi_kit' => pickUiText(
        i18n,
        zh: '低保真套件',
        en: 'Lo-fi kit',
        ja: 'ローファイキット',
        de: 'Lo-fi-Kit',
        fr: 'Kit lo-fi',
        es: 'Kit lo-fi',
        ru: 'Lo-fi набор',
      ),
      _ => pickUiText(
        i18n,
        zh: '原声套件',
        en: 'Acoustic kit',
        ja: 'アコースティックキット',
        de: 'Akustik-Kit',
        fr: 'Kit acoustique',
        es: 'Kit acústico',
        ru: 'Акустический набор',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _DrumKitPreset preset) {
    return switch (preset.id) {
      'electro_kit' => pickUiText(
        i18n,
        zh: '更利落的瞬态与电子感打击纹理。',
        en: 'Sharper transients and synthetic drum character.',
        ja: 'アタックが強く、電子的な質感を持つキット。',
        de: 'Klarere Transienten mit elektronischem Drum-Charakter.',
        fr: 'Transitoires plus nettes et caractère électronique.',
        es: 'Transitorios más marcados y carácter electrónico.',
        ru: 'Более резкая атака и электронный характер ударов.',
      ),
      'lofi_kit' => pickUiText(
        i18n,
        zh: '更松弛的质感与轻微低保真尾音。',
        en: 'Relaxed impact with slightly dusty lo-fi tail.',
        ja: '柔らかいアタックと少しざらついたローファイ感。',
        de: 'Entspannter Anschlag mit leicht staubigem Lo-fi-Ausklang.',
        fr: 'Impact plus doux avec une légère queue lo-fi.',
        es: 'Impacto relajado con una cola lo-fi ligera.',
        ru: 'Более мягкий удар с лёгким lo-fi хвостом.',
      ),
      _ => pickUiText(
        i18n,
        zh: '更接近原声鼓组的自然敲击感。',
        en: 'Natural punch closer to an acoustic drum set.',
        ja: 'アコースティック寄りの自然な打撃感。',
        de: 'Natürlicher Punch wie bei einem akustischen Drumset.',
        fr: 'Impact naturel proche d’une batterie acoustique.',
        es: 'Golpe natural cercano a una batería acústica.',
        ru: 'Естественный панч, близкий к акустической установке.',
      ),
    };
  }

  String _padLabel(AppI18n i18n, String id) {
    return switch (id) {
      'snare' => pickUiText(
        i18n,
        zh: '军鼓',
        en: 'Snare',
        ja: 'スネア',
        de: 'Snare',
        fr: 'Caisse claire',
        es: 'Caja',
        ru: 'Малый',
      ),
      'hihat' => pickUiText(
        i18n,
        zh: '踩镲',
        en: 'Hi-hat',
        ja: 'ハイハット',
        de: 'Hi-Hat',
        fr: 'Charleston',
        es: 'Hi-hat',
        ru: 'Хай-хэт',
      ),
      'tom' => pickUiText(
        i18n,
        zh: '嗵鼓',
        en: 'Tom',
        ja: 'タム',
        de: 'Tom',
        fr: 'Tom',
        es: 'Tom',
        ru: 'Том',
      ),
      _ => pickUiText(
        i18n,
        zh: '底鼓',
        en: 'Kick',
        ja: 'キック',
        de: 'Kick',
        fr: 'Kick',
        es: 'Bombo',
        ru: 'Бочка',
      ),
    };
  }

  void _invalidatePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  void _applyPreset(String presetId) {
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    setState(() {
      _presetId = preset.id;
      _kit = preset.kitId;
      _drive = preset.drive;
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
  }

  Future<void> _warmUpActivePreset() async {
    for (final pad in _pads) {
      await _playerFor(pad.id).warmUp();
    }
  }

  ToolboxEffectPlayer _playerFor(String id) {
    final cacheKey = '$id:$_kit';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.drumHit(id, kit: _kit),
      maxPlayers: 8,
    );
    _players[cacheKey] = created;
    return created;
  }

  Future<void> _hit(_DrumPad pad) async {
    HapticFeedback.heavyImpact();
    unawaited(_playerFor(pad.id).play(volume: _drive.clamp(0.2, 1.0)));
    if (!mounted) return;
    setState(() {
      _activePadId = pad.id;
      _lastHitId = pad.id;
      _hits += 1;
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || _activePadId != pad.id) return;
      setState(() => _activePadId = null);
    });
  }

  @override
  void dispose() {
    _invalidatePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final preset = _activePreset;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '鼓垫',
                    en: 'Pads',
                    ja: 'パッド',
                    de: 'Pads',
                    fr: 'Pads',
                    es: 'Pads',
                    ru: 'Пэды',
                  ),
                  value: '${_pads.length}',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '最近击打',
                    en: 'Last hit',
                    ja: '直前ヒット',
                    de: 'Letzter Schlag',
                    fr: 'Dernier coup',
                    es: 'Último golpe',
                    ru: 'Последний удар',
                  ),
                  value: _lastHitId == null
                      ? '--'
                      : _padLabel(i18n, _lastHitId!),
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '次数',
                    en: 'Count',
                    ja: '回数',
                    de: 'Anzahl',
                    fr: 'Compteur',
                    es: 'Conteo',
                    ru: 'Счёт',
                  ),
                  value: '$_hits',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '预设',
                    en: 'Preset',
                    ja: 'プリセット',
                    de: 'Preset',
                    fr: 'Préréglage',
                    es: 'Preajuste',
                    ru: 'Пресет',
                  ),
                  value: _presetLabel(i18n, preset),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionHeader(
              title: pickUiText(
                i18n,
                zh: '预设包',
                en: 'Preset pack',
                ja: 'プリセットパック',
                de: 'Preset-Paket',
                fr: 'Pack de préréglages',
                es: 'Paquete de presets',
                ru: 'Пакет пресетов',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '切换鼓组类型，并同步设置默认冲击力度。',
                en: 'Switch kit type and default impact drive together.',
                ja: 'キット種類と標準の打撃ドライブをまとめて切り替えます。',
                de: 'Wechselt Kit-Typ und Standard-Drive gemeinsam.',
                fr: 'Changez le type de kit et le drive d’impact par défaut.',
                es: 'Cambia el kit y el nivel de impacto por defecto.',
                ru: 'Переключает тип набора и силу удара по умолчанию.',
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
            Text(
              _presetSubtitle(i18n, preset),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Text(
              pickUiText(
                i18n,
                zh: '冲击力度 ${(_drive * 100).round()}%',
                en: 'Drive ${(_drive * 100).round()}%',
                ja: 'ドライブ ${(_drive * 100).round()}%',
                de: 'Drive ${(_drive * 100).round()}%',
                fr: 'Drive ${(_drive * 100).round()}%',
                es: 'Drive ${(_drive * 100).round()}%',
                ru: 'Драйв ${(_drive * 100).round()}%',
              ),
            ),
            Slider(
              value: _drive,
              min: 0.45,
              max: 1.0,
              divisions: 11,
              onChanged: (value) => setState(() => _drive = value),
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: widget.fullScreen ? 1.35 : 1.1,
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: _pads
                    .map((pad) {
                      final active = _activePadId == pad.id;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => unawaited(_hit(pad)),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  pad.color.withValues(
                                    alpha: active ? 0.95 : 0.74,
                                  ),
                                  pad.color.withValues(
                                    alpha: active ? 0.7 : 0.52,
                                  ),
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: pad.color.withValues(
                                    alpha: active ? 0.42 : 0.24,
                                  ),
                                  blurRadius: active ? 18 : 12,
                                  spreadRadius: active ? 2 : 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _padLabel(i18n, pad.id),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuitarTool extends StatefulWidget {
  const _GuitarTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_GuitarTool> createState() => _GuitarToolState();
}

class _GuitarToolState extends State<_GuitarTool> {
  static const List<_PianoKey> _strings = <_PianoKey>[
    _PianoKey(id: 'E2', label: 'E2', frequency: 82.41),
    _PianoKey(id: 'A2', label: 'A2', frequency: 110.0),
    _PianoKey(id: 'D3', label: 'D3', frequency: 146.83),
    _PianoKey(id: 'G3', label: 'G3', frequency: 196.0),
    _PianoKey(id: 'B3', label: 'B3', frequency: 246.94),
    _PianoKey(id: 'E4', label: 'E4', frequency: 329.63),
  ];

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  static const List<_GuitarPreset> _presets = <_GuitarPreset>[
    _GuitarPreset(
      id: 'steel_strum',
      styleId: 'steel',
      pluckVolume: 0.9,
      strumVolume: 0.84,
      strumDelayMs: 34,
    ),
    _GuitarPreset(
      id: 'nylon_finger',
      styleId: 'nylon',
      pluckVolume: 0.84,
      strumVolume: 0.78,
      strumDelayMs: 42,
    ),
    _GuitarPreset(
      id: 'ambient_chime',
      styleId: 'ambient',
      pluckVolume: 0.78,
      strumVolume: 0.72,
      strumDelayMs: 52,
    ),
  ];
  String _presetId = _presets.first.id;
  int? _activeString;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _GuitarPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _GuitarPreset preset) {
    return switch (preset.id) {
      'nylon_finger' => pickUiText(
        i18n,
        zh: '尼龙指弹',
        en: 'Nylon finger',
        ja: 'ナイロン指弾き',
        de: 'Nylon Fingerstyle',
        fr: 'Nylon finger',
        es: 'Nailon finger',
        ru: 'Нейлон фингер',
      ),
      'ambient_chime' => pickUiText(
        i18n,
        zh: '氛围铃音',
        en: 'Ambient chime',
        ja: 'アンビエントチャイム',
        de: 'Ambient Chime',
        fr: 'Ambient chime',
        es: 'Ambient chime',
        ru: 'Ambient chime',
      ),
      _ => pickUiText(
        i18n,
        zh: '钢弦扫弦',
        en: 'Steel strum',
        ja: 'スチールストラム',
        de: 'Steel Strum',
        fr: 'Steel strum',
        es: 'Steel strum',
        ru: 'Steel strum',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _GuitarPreset preset) {
    return switch (preset.id) {
      'nylon_finger' => pickUiText(
        i18n,
        zh: '圆润柔和，适合慢速分解和指弹。',
        en: 'Round and soft tone for slow arpeggios and finger picking.',
        ja: '丸く柔らかい音で、ゆっくりした分散和音に最適。',
        de: 'Runder, weicher Klang für langsame Arpeggios und Fingerpicking.',
        fr: 'Timbre rond et doux pour arpèges lents et fingerstyle.',
        es: 'Tono redondo y suave para arpegios lentos y fingerpicking.',
        ru: 'Мягкий округлый тембр для медленных арпеджио и фингерстайла.',
      ),
      'ambient_chime' => pickUiText(
        i18n,
        zh: '更空灵的泛音尾音，适合氛围铺底。',
        en: 'Airier overtones and longer shimmer for ambient layers.',
        ja: '倍音を強めた余韻で、アンビエント層に向くサウンド。',
        de: 'Luftigere Obertöne mit längerem Schimmer für Ambient-Flächen.',
        fr: 'Harmoniques aériennes et résonance longue pour l’ambient.',
        es: 'Armónicos más aéreos y cola larga para capas ambient.',
        ru: 'Более воздушные обертоны и длинный шимер для ambient-подложки.',
      ),
      _ => pickUiText(
        i18n,
        zh: '清晰有力的钢弦核心，适合节奏扫弦。',
        en: 'Clear steel-core tone tuned for rhythmic strumming.',
        ja: '明瞭なスチール芯で、リズムストラム向け。',
        de: 'Klarer Steel-Kernklang für rhythmisches Strumming.',
        fr: 'Noyau acier net, idéal pour le strumming rythmique.',
        es: 'Núcleo claro de acero, ideal para rasgueo rítmico.',
        ru: 'Чёткий стальной тон, настроенный под ритмический бой.',
      ),
    };
  }

  String _styleLabel(AppI18n i18n, String styleId) {
    return switch (styleId) {
      'nylon' => pickUiText(
        i18n,
        zh: '尼龙',
        en: 'Nylon',
        ja: 'ナイロン',
        de: 'Nylon',
        fr: 'Nylon',
        es: 'Nailon',
        ru: 'Нейлон',
      ),
      'ambient' => pickUiText(
        i18n,
        zh: '氛围',
        en: 'Ambient',
        ja: 'アンビエント',
        de: 'Ambient',
        fr: 'Ambient',
        es: 'Ambient',
        ru: 'Ambient',
      ),
      _ => pickUiText(
        i18n,
        zh: '钢弦',
        en: 'Steel',
        ja: 'スチール',
        de: 'Steel',
        fr: 'Acier',
        es: 'Acero',
        ru: 'Сталь',
      ),
    };
  }

  void _applyPreset(String presetId) {
    if (_presetId == presetId) return;
    setState(() => _presetId = presetId);
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
  }

  Future<void> _warmUpActivePreset() async {
    for (final note in _strings) {
      await _playerFor(note).warmUp();
    }
  }

  ToolboxEffectPlayer _playerFor(_PianoKey note) {
    final key = '${note.id}:${_activePreset.styleId}';
    final existing = _players[key];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.guitarNote(note.frequency, style: _activePreset.styleId),
      maxPlayers: 8,
    );
    _players[key] = created;
    return created;
  }

  Future<void> _pluck(int index, {double? volume}) async {
    if (index < 0 || index >= _strings.length) return;
    HapticFeedback.selectionClick();
    final note = _strings[index];
    unawaited(
      _playerFor(note).play(volume: volume ?? _activePreset.pluckVolume),
    );
    if (!mounted) return;
    setState(() => _activeString = index);
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || _activeString != index) return;
      setState(() => _activeString = null);
    });
  }

  Future<void> _strum({required bool down}) async {
    final preset = _activePreset;
    final indexes = down
        ? List<int>.generate(_strings.length, (i) => i)
        : List<int>.generate(_strings.length, (i) => _strings.length - 1 - i);
    for (final index in indexes) {
      await _pluck(index, volume: preset.strumVolume);
      await Future<void>.delayed(Duration(milliseconds: preset.strumDelayMs));
    }
  }

  void _invalidatePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  @override
  void dispose() {
    _invalidatePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final preset = _activePreset;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '琴弦',
                    en: 'Strings',
                    ja: '弦',
                    de: 'Saiten',
                    fr: 'Cordes',
                    es: 'Cuerdas',
                    ru: 'Струны',
                  ),
                  value: '6',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '预设',
                    en: 'Preset',
                    ja: 'プリセット',
                    de: 'Preset',
                    fr: 'Préréglage',
                    es: 'Preajuste',
                    ru: 'Пресет',
                  ),
                  value: _presetLabel(i18n, preset),
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '音色',
                    en: 'Tone',
                    ja: '音色',
                    de: 'Klang',
                    fr: 'Timbre',
                    es: 'Timbre',
                    ru: 'Тембр',
                  ),
                  value: _styleLabel(i18n, preset.styleId),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SectionHeader(
              title: pickUiText(
                i18n,
                zh: '预设包',
                en: 'Preset pack',
                ja: 'プリセットパック',
                de: 'Preset-Paket',
                fr: 'Pack de préréglages',
                es: 'Paquete de presets',
                ru: 'Пакет пресетов',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '预设同时控制琴弦材质、拨弦力度和扫弦速度。',
                en: 'Presets control string material, pluck volume, and strum speed.',
                ja: 'プリセットで弦素材、ピッキング強度、ストラム速度を一括制御。',
                de: 'Presets steuern Saitenmaterial, Zupf-Lautstärke und Strum-Tempo.',
                fr: 'Les presets pilotent matériau, attaque et vitesse de strum.',
                es: 'Los presets controlan material, ataque y velocidad de rasgueo.',
                ru: 'Пресеты управляют материалом струн, атакой и скоростью боя.',
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
                      selected: _presetId == item.id,
                      onSelected: (_) => _applyPreset(item.id),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Text(
              _presetSubtitle(i18n, preset),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFFF6E7C8), Color(0xFFEBCF9A)],
                ),
              ),
              child: Column(
                children: List<Widget>.generate(_strings.length, (index) {
                  final active = _activeString == index;
                  final note = _strings[index];
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => unawaited(_pluck(index)),
                    child: Container(
                      height: widget.fullScreen ? 40 : 34,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 28,
                            child: Text(
                              note.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5A3818),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 90),
                              height: active ? 3.4 : 2.2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: active
                                    ? const Color(0xFFFB923C)
                                    : const Color(0xFF7C5A3A),
                                boxShadow: active
                                    ? <BoxShadow>[
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFB923C,
                                          ).withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : const <BoxShadow>[],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: () => unawaited(_strum(down: true)),
                  icon: const Icon(Icons.south_rounded),
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '下扫弦',
                      en: 'Strum down',
                      ja: 'ダウンストラム',
                      de: 'Abschlag',
                      fr: 'Strum vers le bas',
                      es: 'Rasgueo abajo',
                      ru: 'Бой вниз',
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => unawaited(_strum(down: false)),
                  icon: const Icon(Icons.north_rounded),
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '上扫弦',
                      en: 'Strum up',
                      ja: 'アップストラム',
                      de: 'Aufschlag',
                      fr: 'Strum vers le haut',
                      es: 'Rasgueo arriba',
                      ru: 'Бой вверх',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TriangleTool extends StatefulWidget {
  const _TriangleTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_TriangleTool> createState() => _TriangleToolState();
}

class _TriangleToolState extends State<_TriangleTool> {
  static const List<_TrianglePreset> _presets = <_TrianglePreset>[
    _TrianglePreset(id: 'orchestral_ring', styleId: 'orchestral', ring: 0.86),
    _TrianglePreset(id: 'soft_ring', styleId: 'soft', ring: 0.74),
    _TrianglePreset(id: 'bright_ring', styleId: 'bright', ring: 0.96),
  ];
  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  String _presetId = _presets.first.id;
  int _hits = 0;
  double _ring = _presets.first.ring;
  double _flash = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _TrianglePreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _TrianglePreset preset) {
    return switch (preset.id) {
      'soft_ring' => pickUiText(
        i18n,
        zh: '柔和振铃',
        en: 'Soft ring',
        ja: 'ソフトリング',
        de: 'Sanfter Ring',
        fr: 'Résonance douce',
        es: 'Resonancia suave',
        ru: 'Мягкий звон',
      ),
      'bright_ring' => pickUiText(
        i18n,
        zh: '明亮振铃',
        en: 'Bright ring',
        ja: 'ブライトリング',
        de: 'Heller Ring',
        fr: 'Résonance brillante',
        es: 'Resonancia brillante',
        ru: 'Яркий звон',
      ),
      _ => pickUiText(
        i18n,
        zh: '管弦振铃',
        en: 'Orchestral ring',
        ja: 'オーケストラリング',
        de: 'Orchestraler Ring',
        fr: 'Résonance orchestrale',
        es: 'Resonancia orquestal',
        ru: 'Оркестровый звон',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _TrianglePreset preset) {
    return switch (preset.id) {
      'soft_ring' => pickUiText(
        i18n,
        zh: '更柔和的高频和更短的余音，适合轻节奏。',
        en: 'Softer highs and shorter tail for gentle rhythm support.',
        ja: '高域を抑えた短めの余韻で、軽いリズム向け。',
        de: 'Sanftere Höhen und kürzeres Ausklingen für leichte Patterns.',
        fr: 'Aigus adoucis et queue plus courte pour un rythme léger.',
        es: 'Agudos suaves y cola corta para ritmos ligeros.',
        ru: 'Мягкие верха и короткий хвост для лёгкого ритма.',
      ),
      'bright_ring' => pickUiText(
        i18n,
        zh: '更亮更脆，余音更明显，适合强调节拍。',
        en: 'Brighter attack and stronger ring to mark accents.',
        ja: '明るく鋭いアタックで、アクセントを強調。',
        de: 'Hellerer Anschlag und stärkerer Ring für Akzente.',
        fr: 'Attaque plus brillante et résonance marquée.',
        es: 'Ataque brillante y resonancia más marcada para acentos.',
        ru: 'Более яркая атака и выраженный звон для акцентов.',
      ),
      _ => pickUiText(
        i18n,
        zh: '均衡明亮与延音，接近管弦乐中的三角铁表现。',
        en: 'Balanced brightness and decay close to orchestral behavior.',
        ja: '明るさと余韻のバランスが良い標準オーケストラ音。',
        de: 'Ausgewogene Helligkeit und Decay wie im Orchester.',
        fr: 'Équilibre entre brillance et décroissance orchestral.',
        es: 'Equilibrio entre brillo y decaimiento de estilo orquestal.',
        ru: 'Сбалансированная яркость и затухание в оркестровом стиле.',
      ),
    };
  }

  ToolboxEffectPlayer _playerFor(String styleId) {
    final existing = _players[styleId];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.triangleHit(style: styleId),
      maxPlayers: 6,
    );
    _players[styleId] = created;
    return created;
  }

  void _disposePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  void _applyPreset(String presetId) {
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    setState(() {
      _presetId = preset.id;
      _ring = preset.ring;
    });
    unawaited(_warmUpActivePreset());
  }

  Future<void> _warmUpActivePreset() async {
    await _playerFor(_activePreset.styleId).warmUp();
  }

  @override
  void dispose() {
    _disposePlayers();
    super.dispose();
  }

  Future<void> _strike() async {
    HapticFeedback.lightImpact();
    unawaited(
      _playerFor(_activePreset.styleId).play(volume: _ring.clamp(0.2, 1.0)),
    );
    if (!mounted) return;
    setState(() {
      _hits += 1;
      _flash = 1;
    });
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() => _flash = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final preset = _activePreset;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '击打',
                    en: 'Hits',
                    ja: 'ヒット',
                    de: 'Treffer',
                    fr: 'Coups',
                    es: 'Golpes',
                    ru: 'Удары',
                  ),
                  value: '$_hits',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '振铃',
                    en: 'Ring',
                    ja: 'リング',
                    de: 'Ring',
                    fr: 'Résonance',
                    es: 'Resonancia',
                    ru: 'Звон',
                  ),
                  value: '${(_ring * 100).round()}%',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '预设',
                    en: 'Preset',
                    ja: 'プリセット',
                    de: 'Preset',
                    fr: 'Préréglage',
                    es: 'Preajuste',
                    ru: 'Пресет',
                  ),
                  value: _presetLabel(i18n, preset),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionHeader(
              title: pickUiText(
                i18n,
                zh: '预设包',
                en: 'Preset pack',
                ja: 'プリセットパック',
                de: 'Preset-Paket',
                fr: 'Pack de préréglages',
                es: 'Paquete de presets',
                ru: 'Пакет пресетов',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '预设会同步调整三角铁音色与默认振铃长度。',
                en: 'Presets change triangle tone and default ring length together.',
                ja: 'プリセットで音色と余韻長を同時に切り替えます。',
                de: 'Presets ändern Klangfarbe und Nachklanglänge gemeinsam.',
                fr: 'Les presets ajustent timbre et longueur de résonance.',
                es: 'Los presets ajustan timbre y longitud de resonancia.',
                ru: 'Пресеты одновременно меняют тембр и длину звона.',
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
            Text(
              _presetSubtitle(i18n, preset),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => unawaited(_strike()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: widget.fullScreen ? 260 : 210,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFFE6EEF9),
                      Color.lerp(
                        const Color(0xFFC9DDF8),
                        const Color(0xFFEAB308),
                        _flash * 0.24,
                      )!,
                    ],
                  ),
                  border: Border.all(color: const Color(0xFF98B6DE)),
                ),
                child: CustomPaint(
                  painter: _TriangleInstrumentPainter(intensity: _flash),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              pickUiText(
                i18n,
                zh: '振铃 ${(_ring * 100).round()}%',
                en: 'Ring ${(_ring * 100).round()}%',
                ja: 'リング ${(_ring * 100).round()}%',
                de: 'Ring ${(_ring * 100).round()}%',
                fr: 'Résonance ${(_ring * 100).round()}%',
                es: 'Resonancia ${(_ring * 100).round()}%',
                ru: 'Звон ${(_ring * 100).round()}%',
              ),
            ),
            Slider(
              value: _ring,
              min: 0.2,
              max: 1,
              divisions: 16,
              onChanged: (value) => setState(() => _ring = value),
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () => unawaited(_strike()),
              icon: const Icon(Icons.music_video_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '敲击三角铁',
                  en: 'Strike triangle',
                  ja: 'トライアングルを鳴らす',
                  de: 'Triangel anschlagen',
                  fr: 'Frapper le triangle',
                  es: 'Golpear triángulo',
                  ru: 'Ударить треугольник',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HarpPainter extends CustomPainter {
  const _HarpPainter({
    required this.stringCount,
    required this.noteFrequencies,
    required this.stringOffsets,
    required this.focusedString,
    required this.colorScheme,
    required this.paletteColors,
    required this.pluckStyleId,
    required this.horizontalLayout,
    required this.backdropMaterial,
  });

  final int stringCount;
  final List<double> noteFrequencies;
  final List<double> stringOffsets;
  final int? focusedString;
  final ColorScheme colorScheme;
  final List<Color> paletteColors;
  final String pluckStyleId;
  final bool horizontalLayout;
  final String backdropMaterial;

  double _stringTrackAt(int index, Size size) {
    final totalSpan = horizontalLayout ? size.height : size.width;
    final adaptiveInset = totalSpan * (horizontalLayout ? 0.12 : 0.11);
    final minInset = horizontalLayout ? 28.0 : 22.0;
    final leadingInset = math.max(minInset, adaptiveInset);
    final trailingInset = math.max(minInset, adaptiveInset);
    final usableSpan = math.max(1.0, totalSpan - leadingInset - trailingInset);
    if (stringCount == 1) return totalSpan / 2;
    return leadingInset + usableSpan * (index / (stringCount - 1));
  }

  Color _paletteColorAt(double t) {
    if (paletteColors.isEmpty) return colorScheme.primary;
    if (paletteColors.length == 1) return paletteColors.first;
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (paletteColors.length - 1);
    final index = scaled.floor().clamp(0, paletteColors.length - 1);
    final next = math.min(index + 1, paletteColors.length - 1);
    final localT = scaled - index;
    return Color.lerp(paletteColors[index], paletteColors[next], localT) ??
        paletteColors[index];
  }

  int _pitchClassFromFrequency(double frequency) {
    final midi = (69 + 12 * (math.log(frequency / 440.0) / math.ln2)).round();
    return ((midi % 12) + 12) % 12;
  }

  String _noteName(int pitchClass) {
    const names = <String>[
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
    return names[pitchClass];
  }

  Color _pitchColor(int pitchClass) {
    const pitchColors = <Color>[
      Color(0xFFEF4444),
      Color(0xFFF97316),
      Color(0xFFF59E0B),
      Color(0xFFEAB308),
      Color(0xFF84CC16),
      Color(0xFF22C55E),
      Color(0xFF14B8A6),
      Color(0xFF06B6D4),
      Color(0xFF3B82F6),
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFD946EF),
    ];
    return pitchColors[pitchClass.clamp(0, 11)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final styleCurve = switch (pluckStyleId) {
      'warm' => 0.78,
      'crystal' => 1.18,
      'bright' => 1.05,
      'glass' => 1.24,
      'nylon' => 0.72,
      'concert' => 0.82,
      'steel' => 0.98,
      _ => 0.9,
    };
    final idleStroke = switch (pluckStyleId) {
      'warm' => 2.2,
      'crystal' => 1.75,
      'bright' => 1.95,
      'glass' => 1.62,
      'nylon' => 2.35,
      'concert' => 2.08,
      'steel' => 1.88,
      _ => 1.9,
    };

    final useWoodBackdrop = backdropMaterial == 'wood';
    final topGradient = useWoodBackdrop
        ? Color.lerp(_paletteColorAt(0.05), const Color(0xFF6B4228), 0.4)
        : Color.lerp(_paletteColorAt(0.05), const Color(0xFF041224), 0.42);
    final middleGradient = useWoodBackdrop
        ? Color.lerp(_paletteColorAt(0.45), const Color(0xFF4C2E1C), 0.46)
        : Color.lerp(_paletteColorAt(0.45), const Color(0xFF0B2A43), 0.46);
    final bottomGradient = useWoodBackdrop
        ? Color.lerp(_paletteColorAt(0.95), const Color(0xFF2F1D12), 0.36)
        : Color.lerp(_paletteColorAt(0.95), const Color(0xFF0F172A), 0.28);
    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          topGradient ?? const Color(0xFF0F172A),
          middleGradient ?? (topGradient ?? colorScheme.primary),
          bottomGradient ??
              (useWoodBackdrop
                  ? const Color(0xFF1E140D)
                  : const Color(0xFF1E1B4B)),
        ],
      ).createShader(Offset.zero & size);
    final borderPaint = Paint()
      ..color = colorScheme.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    );
    canvas.drawRRect(frame, framePaint);
    canvas.drawRRect(frame, borderPaint);

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: <Color>[
              _paletteColorAt(0.5).withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.42),
              radius: size.width * 0.42,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.42),
      size.width * 0.42,
      glowPaint,
    );
    final auroraPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          _paletteColorAt(0.12).withValues(alpha: 0.08),
          Colors.transparent,
          _paletteColorAt(0.86).withValues(alpha: 0.1),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, auroraPaint);
    if (useWoodBackdrop) {
      final grainPaint = Paint()
        ..color = const Color(0x66F8E5C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7;
      final grainCount = math.max(6, (size.height / 34).round());
      for (var i = 0; i < grainCount; i += 1) {
        final y = (i + 1) * size.height / (grainCount + 1);
        final wave = 4 + (i % 3) * 1.8;
        final path = Path()
          ..moveTo(0, y)
          ..quadraticBezierTo(size.width * 0.36, y - wave, size.width * 0.68, y)
          ..quadraticBezierTo(
            size.width * 0.84,
            y + wave,
            size.width,
            y - wave * 0.2,
          );
        canvas.drawPath(path, grainPaint);
      }
    }

    final topY = size.height * 0.06;
    final bottomY = size.height * 0.94;
    final leftX = size.width * 0.06;
    final rightX = size.width * 0.94;
    final midY = (topY + bottomY) / 2;
    final midX = (leftX + rightX) / 2;
    final textScale = horizontalLayout
        ? (size.height / 520).clamp(0.72, 1.06)
        : (size.width / 420).clamp(0.72, 1.0);
    for (var index = 0; index < stringCount; index += 1) {
      final track = _stringTrackAt(index, size);
      final frequency = noteFrequencies[index % noteFrequencies.length];
      final pitchClass = _pitchClassFromFrequency(frequency);
      final noteColor = _pitchColor(pitchClass);
      final sway = (index < stringOffsets.length ? stringOffsets[index] : 0.0)
          .clamp(-22.0, 22.0)
          .toDouble();
      final activity = (sway.abs() / 22).clamp(0.0, 1.0).toDouble();
      final active = focusedString == index || activity > 0.04;
      final paletteColor = _paletteColorAt(index / (stringCount - 1));
      final baseColor = Color.lerp(noteColor, paletteColor, 0.22) ?? noteColor;
      final idleColor =
          Color.lerp(baseColor.withValues(alpha: 0.92), Colors.white, 0.42) ??
          baseColor.withValues(alpha: 0.92);
      final strokeColor = Color.lerp(
        idleColor,
        Colors.white,
        active ? (0.52 + activity * 0.48).clamp(0.0, 1.0) : 0.0,
      );
      final skeletonPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.26)
        ..strokeWidth = math.max(1.35, idleStroke - 0.72)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final basePaint = Paint()
        ..color = baseColor.withValues(alpha: 0.86)
        ..strokeWidth = math.max(1.5, idleStroke - 0.42)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final basePath = horizontalLayout
          ? (Path()
              ..moveTo(leftX, track)
              ..quadraticBezierTo(midX, track, rightX, track))
          : (Path()
              ..moveTo(track, topY)
              ..quadraticBezierTo(track, midY, track, bottomY));
      canvas.drawPath(basePath, skeletonPaint);
      canvas.drawPath(basePath, basePaint);
      final paint = Paint()
        ..color = strokeColor ?? colorScheme.primary
        ..strokeWidth = active ? idleStroke + 1.2 + activity * 0.95 : idleStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (active) {
        final underGlow = Paint()
          ..color = baseColor.withValues(alpha: 0.2)
          ..strokeWidth = 5.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(basePath, underGlow);

        final glow = Paint()
          ..color = (strokeColor ?? colorScheme.primary).withValues(alpha: 0.28)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        final glowPath = horizontalLayout
            ? (Path()
                ..moveTo(leftX, track)
                ..quadraticBezierTo(
                  midX,
                  track + sway * styleCurve,
                  rightX,
                  track,
                ))
            : (Path()
                ..moveTo(track, topY)
                ..quadraticBezierTo(
                  track + sway * styleCurve,
                  midY,
                  track,
                  bottomY,
                ));
        canvas.drawPath(glowPath, glow);
      }

      final path = horizontalLayout
          ? (Path()
              ..moveTo(leftX, track)
              ..quadraticBezierTo(
                midX,
                track + sway * styleCurve,
                rightX,
                track,
              ))
          : (Path()
              ..moveTo(track, topY)
              ..quadraticBezierTo(
                track + sway * styleCurve,
                midY,
                track,
                bottomY,
              ));
      canvas.drawPath(path, paint);

      final anchorPaint = Paint()
        ..color = (strokeColor ?? colorScheme.primary).withValues(alpha: 0.75);
      if (horizontalLayout) {
        canvas.drawCircle(Offset(leftX, track), 2.5, anchorPaint);
        canvas.drawCircle(Offset(rightX, track), 2.2, anchorPaint);
      } else {
        canvas.drawCircle(Offset(track, topY), 2.5, anchorPaint);
        canvas.drawCircle(Offset(track, bottomY), 2.2, anchorPaint);
      }

      final activeDot = Paint()
        ..color = baseColor.withValues(alpha: active ? 0.96 : 0.5);
      final activeDotOffset = horizontalLayout
          ? Offset(rightX, track)
          : Offset(track, bottomY);
      canvas.drawCircle(activeDotOffset, active ? 3.4 : 2.4, activeDot);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: _noteName(pitchClass),
          style: TextStyle(
            color: (strokeColor ?? noteColor).withValues(alpha: 0.9),
            fontSize: 9.5 * textScale,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelOffset = horizontalLayout
          ? Offset(
              leftX - labelPainter.width - 8,
              track - labelPainter.height / 2,
            )
          : Offset(track - labelPainter.width / 2, topY - 16 * textScale);
      labelPainter.paint(canvas, labelOffset);
    }
  }

  @override
  bool shouldRepaint(covariant _HarpPainter oldDelegate) {
    return true;
  }
}

class _TriangleInstrumentPainter extends CustomPainter {
  const _TriangleInstrumentPainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final top = Offset(size.width * 0.5, size.height * 0.18);
    final left = Offset(size.width * 0.24, size.height * 0.8);
    final right = Offset(size.width * 0.76, size.height * 0.8);
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    final glow = Paint()
      ..color = const Color(
        0xFFF59E0B,
      ).withValues(alpha: 0.18 + intensity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glow);

    final stroke = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF6B7D99),
          Color(0xFF314255),
          Color(0xFF1C2937),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);

    final striker = Paint()
      ..color = const Color(0xFF243447)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final strikerX = size.width * 0.78;
    final strikerY = size.height * (0.28 + intensity * 0.02);
    canvas.drawLine(
      Offset(strikerX, strikerY),
      Offset(strikerX + 34, strikerY + 50),
      striker,
    );
    canvas.drawCircle(
      Offset(strikerX + 34, strikerY + 50),
      5,
      Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _TriangleInstrumentPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}

class _WoodfishPainter extends CustomPainter {
  const _WoodfishPainter({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.72,
      height: size.height * 0.44,
    );
    final body = RRect.fromRectAndRadius(bodyRect, const Radius.circular(999));
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFFC78743),
          Color(0xFF9C5B21),
          Color(0xFF6E3D18),
        ],
      ).createShader(bodyRect);
    canvas.drawRRect(body, paint);
    canvas.drawRRect(
      body,
      Paint()
        ..color = colorScheme.outline.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final groovePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromCenter(
        center: bodyRect.center,
        width: bodyRect.width * 0.42,
        height: bodyRect.height * 0.35,
      ),
      0.2,
      math.pi - 0.4,
      false,
      groovePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WoodfishPainter oldDelegate) => false;
}
