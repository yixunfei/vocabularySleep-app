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

AppI18n _toolboxI18n(BuildContext context) {
  final state = context.watch<AppState?>();
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
  final i18n = _toolboxI18n(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(i18n, zh: titleZh, en: titleEn),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          radius: 11,
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

Widget _wrapInstrumentPanel({
  required bool fullScreen,
  required Widget child,
}) {
  final content = Padding(
    padding: const EdgeInsets.all(18),
    child: child,
  );
  if (!fullScreen) {
    return Card(child: content);
  }
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF111827), Color(0xFF020617)],
      ),
    ),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: content,
      ),
    ),
  );
}

class SoothingMusicToolPage extends StatelessWidget {
  const SoothingMusicToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return ToolboxToolPage(
      title: pickUiText(
        i18n,
        zh: '鑸掔紦杞婚煶',
        en: 'Soothing music',
        ja'',
        de: 'Beruhigende Musik',
        fr: 'Musique apaisante',
        es: 'Musica relajante',
        ru: '校褋锌芯泻邪懈胁邪褞褖邪褟 屑褍蟹褘泻邪',
      ),
      subtitle: pickUiText(
        i18n,
        zh'',
        en: 'Locally synthesized soft textures for slowing down and settling your rhythm.',
        ja'',
        de: 'Lokal synthetisierte, weiche Klangtexturen zum Entschleunigen.',
        fr: 'Textures sonores locales et douces pour ralentir et se poser.',
        es: 'Texturas suaves sintetizadas en local para bajar el ritmo y relajarte.',
        ru: '袥芯泻邪谢褜薪芯 褋懈薪褌械蟹懈褉芯胁邪薪薪褘械 屑褟谐泻懈械 褌械泻褋褌褍褉褘 写谢褟 蟹邪屑械写谢械薪懈褟 懈 褉邪褋褋谢邪斜谢械薪懈褟.',
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
        zh: '绌虹伒绔栫惔',
        en: 'Ethereal harp',
        ja'',
        de: '脛therharfe',
        fr: 'Harpe 茅th茅r茅e',
        es: 'Arpa et茅rea',
        ru: '协褎懈褉薪邪褟 邪褉褎邪',
      ),
      subtitle: pickUiText(
        i18n,
        zh'',
        en: 'Switch harp, piano, flute, drum pad, guitar, and triangle in one instrument deck.',
        ja'',
        de: 'Harfe, Klavier, Fl枚te, Drum-Pad, Gitarre und Triangel in einem Deck umschalten.',
        fr: 'Basculez harpe, piano, fl没te, pad de batterie, guitare et triangle dans un m锚me deck.',
        es: 'Cambia arpa, piano, flauta, pad de bater铆a, guitarra y tri谩ngulo en un solo panel.',
        ru: '袩械褉械泻谢褞褔邪泄褌械 邪褉褎褍, 锌懈邪薪懈薪芯, 褎谢械泄褌褍, 写褉邪屑-锌褝写, 谐懈褌邪褉褍 懈 褌褉械褍谐芯谢褜薪懈泻 胁 芯写薪芯泄 锌邪薪械谢懈.',
      ),
      child: const _HarpInstrumentDeck(),
    );
  }
}

enum _HarpDeckInstrument { harp, piano, flute, drumPad, guitar, triangle, guqin }

class _HarpInstrumentDeck extends StatefulWidget {
  const _HarpInstrumentDeck();

  @override
  State<_HarpInstrumentDeck> createState() => _HarpInstrumentDeckState();
}

class _HarpInstrumentDeckState extends State<_HarpInstrumentDeck> {
  _HarpDeckInstrument _selected = _HarpDeckInstrument.harp;

  String _label(AppI18n i18n, _HarpDeckInstrument instrument) {
    if (instrument == _HarpDeckInstrument.guqin) {
      return pickUiText(i18n, zh: '鍙ょ惔', en: 'Guqin');
    }
    return switch (instrument) {
      _HarpDeckInstrument.piano => pickUiText(
        i18n,
        zh: '閽㈢惔',
        en: 'Piano',
        ja'',
        de: 'Klavier',
        fr: 'Piano',
        es: 'Piano',
        ru: '袩懈邪薪懈薪芯',
      ),
      _HarpDeckInstrument.flute => pickUiText(
        i18n,
        zh: '闀跨瑳',
        en: 'Flute',
        ja: '銉曘儷銉笺儓',
        de: 'Fl枚te',
        fr: 'Fl没te',
        es: 'Flauta',
        ru: '肖谢械泄褌邪',
      ),
      _HarpDeckInstrument.drumPad => pickUiText(
        i18n,
        zh: '榧撳灚',
        en: 'Drum pad',
        ja: '銉夈儵銉犮儜銉冦儔',
        de: 'Drum-Pad',
        fr: 'Pad de batterie',
        es: 'Pad de bater铆a',
        ru: '袛褉邪屑-锌褝写',
      ),
      _HarpDeckInstrument.guitar => pickUiText(
        i18n,
        zh: '鍚変粬',
        en: 'Guitar',
        ja'',
        de: 'Gitarre',
        fr: 'Guitare',
        es: 'Guitarra',
        ru: '袚懈褌邪褉邪',
      ),
      _HarpDeckInstrument.triangle => pickUiText(
        i18n,
        zh'',
        en: 'Triangle',
        ja'',
        de: 'Triangel',
        fr: 'Triangle',
        es: 'Tri谩ngulo',
        ru: '孝褉械褍谐芯谢褜薪懈泻',
      ),
      _ => pickUiText(
        i18n,
        zh: '绔栫惔',
        en: 'Harp',
        ja'',
        de: 'Harfe',
        fr: 'Harpe',
        es: 'Arpa',
        ru: '袗褉褎邪',
      ),
    };
  }

  String _subtitle(AppI18n i18n, _HarpDeckInstrument instrument) {
    if (instrument == _HarpDeckInstrument.guqin) {
      return pickUiText(
        i18n,
        zh'',
        en: 'Seven-string guqin with slide, roll, and harmonic simulation.',
      );
    }
    return switch (instrument) {
      _HarpDeckInstrument.piano => pickUiText(
        i18n,
        zh'',
        en: 'Touch piano with preset packs.',
        ja'',
        de: 'Touch-Klavier mit Preset-Paketen.',
        fr: 'Piano tactile avec packs de pr茅r茅glages.',
        es: 'Piano t谩ctil con paquetes de presets.',
        ru: '小械薪褋芯褉薪芯械 锌懈邪薪懈薪芯 褋 锌邪泻械褌邪屑懈 锌褉械褋械褌芯胁.',
      ),
      _HarpDeckInstrument.flute => pickUiText(
        i18n,
        zh'',
        en: 'Flute with scale and timbre presets.',
        ja'',
        de: 'Fl枚te mit Skalen- und Klang-Presets.',
        fr: 'Fl没te avec gammes et presets de timbre.',
        es: 'Flauta con escalas y presets de timbre.',
        ru: '肖谢械泄褌邪 褋 谢邪写芯胁褘屑懈 懈 褌械屑斜褉芯胁褘屑懈 锌褉械褋械褌邪屑懈.',
      ),
      _HarpDeckInstrument.drumPad => pickUiText(
        i18n,
        zh'',
        en: 'Four pads with switchable drum kits.',
        ja'',
        de: 'Vier Pads mit umschaltbaren Drum-Kits.',
        fr: 'Quatre pads avec kits de batterie commutables.',
        es: 'Cuatro pads con kits de bater铆a intercambiables.',
        ru: '效械褌褘褉械 锌褝写邪 褋 锌械褉械泻谢褞褔邪械屑褘屑懈 薪邪斜芯褉邪屑懈 褍写邪褉薪褘褏.',
      ),
      _HarpDeckInstrument.guitar => pickUiText(
        i18n,
        zh'',
        en: 'Guitar panel for pluck and strum.',
        ja'',
        de: 'Gitarrenpanel f眉r Zupfen und Strumming.',
        fr: 'Panneau guitare pour pinc茅 et strum.',
        es: 'Panel de guitarra para pulsar y rasguear.',
        ru: '袚懈褌邪褉薪邪褟 锌邪薪械谢褜 写谢褟 褖懈锌泻邪 懈 斜芯褟.',
      ),
      _HarpDeckInstrument.triangle => pickUiText(
        i18n,
        zh'',
        en: 'Triangle with ring-style presets.',
        ja'',
        de: 'Triangel mit Ring-Style-Presets.',
        fr: 'Triangle avec presets de style de r茅sonance.',
        es: 'Tri谩ngulo con presets de estilo de resonancia.',
        ru: '孝褉械褍谐芯谢褜薪懈泻 褋 锌褉械褋械褌邪屑懈 褋褌懈谢褟 蟹胁芯薪邪.',
      ),
      _ => pickUiText(
        i18n,
        zh'',
        en: 'Harp with phase-two gesture and tone controls.',
        ja'',
        de: 'Harfe mit Gesten- und Klangsteuerung aus Phase 2.',
        fr: 'Harpe avec gestes et r茅glages sonores de phase 2.',
        es: 'Arpa con gestos y control de tono de la fase dos.',
        ru: '袗褉褎邪 褋 卸械褋褌邪屑懈 懈 褌芯薪邪谢褜薪褘屑懈 薪邪褋褌褉芯泄泻邪屑懈 胁褌芯褉芯谐芯 褝褌邪锌邪.',
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
      _HarpDeckInstrument.guqin => Icons.music_note_outlined,
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
      _HarpDeckInstrument.guqin => const _GuqinTool(),
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
                    zh: '涔愬櫒鍒囨崲',
                    en: 'Instrument switch',
                    ja: '妤藉櫒鍒囨浛',
                    de: 'Instrumentenwechsel',
                    fr: 'Changement d鈥檌nstrument',
                    es: 'Cambio de instrumento',
                    ru: '袩械褉械泻谢褞褔械薪懈械 懈薪褋褌褉褍屑械薪褌邪',
                  ),
                  subtitle: pickUiText(
                    i18n,
                    zh'',
                    en: 'Use all 7 instruments inside the harp module.',
                    ja'',
                    de: 'Alle 6 Instrumente direkt im Harfenmodul nutzen.',
                    fr: 'Utilisez les 6 instruments dans le module harpe.',
                    es: 'Usa los 6 instrumentos dentro del m贸dulo de arpa.',
                    ru: '袠褋锌芯谢褜蟹褍泄褌械 胁褋械 6 懈薪褋褌褉褍屑械薪褌芯胁 胁薪褍褌褉懈 屑芯写褍谢褟 邪褉褎褘.',
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
                  label: Text(pickUiText(i18n, zh: '鍏ㄥ睆妯″紡', en: 'Full screen')),
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
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  Widget _tool() {
    return switch (widget.instrument) {
      _HarpDeckInstrument.piano => const _PianoTool(fullScreen: true),
      _HarpDeckInstrument.flute => const _FluteTool(fullScreen: true),
      _HarpDeckInstrument.drumPad => const _DrumPadTool(fullScreen: true),
      _HarpDeckInstrument.guitar => const _GuitarTool(fullScreen: true),
      _HarpDeckInstrument.triangle => const _TriangleTool(fullScreen: true),
      _HarpDeckInstrument.guqin => const _GuqinTool(fullScreen: true),
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
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: _tool()),
          Positioned(
            left: 12,
            top: MediaQuery.paddingOf(context).top + 8,
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
        zh: '涓撴敞鑺傛媿',
        en: 'Focus beats',
        ja'',
        de: 'Fokus-Beat',
        fr: 'Rythmes de focus',
        es: 'Beats de enfoque',
        ru: '肖芯泻褍褋-斜懈褌',
      ),
      subtitle: pickUiText(
        i18n,
        zh'',
        en: 'A local BPM-adjustable metronome for writing, study, or breath syncing.',
        ja'',
        de: 'Lokales BPM-Metronom fur Lernen, Schreiben und Atem-Synchronisation.',
        fr: 'Metronome BPM local pour etude, ecriture et respiration guidee.',
        es: 'Metronomo BPM local para estudio, escritura y sincronizacion de respiracion.',
        ru: '袥芯泻邪谢褜薪褘泄 屑械褌褉芯薪芯屑 褋 BPM 写谢褟 褍褔械斜褘, 锌懈褋褜屑邪 懈 写褘褏邪褌械谢褜薪芯泄 褋懈薪褏褉芯薪懈蟹邪褑懈懈.',
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
        zh: '鐢靛瓙鏈ㄩ奔',
        en: 'Digital woodfish',
        ja: '闆诲瓙鏈ㄩ瓪',
        de: 'Digitales Mokugyo',
        fr: 'Mokugyo numerique',
        es: 'Mokugyo digital',
        ru: '笑懈褎褉芯胁芯泄 屑芯泻褍谐褢',
      ),
      subtitle: pickUiText(
        i18n,
        zh'',
        en: 'Tap once for a count and give yourself a short reset in the middle of the day.',
        ja'',
        de: 'Einmal tippen, einmal zahlen und kurz neu fokussieren.',
        fr: 'Un tap pour compter et vous offrir une courte remise a zero.',
        es: 'Un toque para contar y darte un breve reinicio.',
        ru: '袨写懈薪 褍写邪褉 - 芯写懈薪 褋褔械褌 懈 泻芯褉芯褌泻邪褟 锌械褉械蟹邪谐褉褍蟹泻邪.',
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
        zh: '閽㈢惔',
        en: 'Piano',
        ja'',
        de: 'Klavier',
        fr: 'Piano',
        es: 'Piano',
        ru: '袩懈邪薪懈薪芯',
      ),
      subtitle: pickUiText(
        i18n,
        zh'',
        en: 'Local touch piano with responsive keys and switchable preset packs.',
        ja'',
        de: 'Lokales Touch-Piano mit reaktionsschnellen Tasten und umschaltbaren Presets.',
        fr: 'Piano tactile local avec touches r茅actives et packs de pr茅r茅glages.',
        es: 'Piano t谩ctil local con teclas sensibles y paquetes de ajustes.',
        ru: '袥芯泻邪谢褜薪芯械 褋械薪褋芯褉薪芯械 锌懈邪薪懈薪芯 褋 芯褌蟹褘胁褔懈胁褘屑懈 泻谢邪胁懈褕邪屑懈 懈 锌邪泻械褌邪屑懈 锌褉械褋械褌芯胁.',
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
        zh: '闀跨瑳',
        en: 'Flute',
        ja: '銉曘儷銉笺儓',
        de: 'Fl枚te',
        fr: 'Fl没te',
        es: 'Flauta',
        ru: '肖谢械泄褌邪',
      ),
      subtitle: pickUiText(
        i18n,
        zh'',
        en: 'Breath-like local flute notes with scale switching and preset packs.',
        ja'',
        de: 'Atmungs盲hnliche lokale Fl枚tent枚ne mit Skalenwechsel und Presets.',
        fr: 'Notes de fl没te locales au souffle naturel avec gammes et pr茅r茅glages.',
        es: 'Notas de flauta locales con respiraci贸n natural, escalas y presets.',
        ru: '袥芯泻邪谢褜薪邪褟 褎谢械泄褌邪 褋 写褘褏邪褌械谢褜薪褘屑 褌械屑斜褉芯屑, 褋屑械薪芯泄 谢邪写芯胁 懈 锌褉械褋械褌芯胁.',
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
        zh: '榧撳灚',
        en: 'Drum pad',
        ja: '銉夈儵銉犮儜銉冦儔',
        de: 'Drum-Pad',
        fr: 'Pad de batterie',
        es: 'Pad de bater铆a',
        ru: '袛褉邪屑-锌褝写',
      ),
      subtitle: pickUiText(
        i18n,
        zh'',
        en: 'Compact drum pad with kick, snare, hi-hat and tom, plus kit presets.',
        ja'',
        de: 'Kompaktes Drum-Pad mit Kick, Snare, Hi-Hat und Tom inklusive Kit-Presets.',
        fr: 'Pad compact avec kick, caisse claire, charleston et tom, avec presets de kit.',
        es: 'Pad compacto con bombo, caja, hi-hat y tom, con presets de kit.',
        ru: '袣芯屑锌邪泻褌薪褘泄 写褉邪屑-锌褝写: 斜芯褔泻邪, 屑邪谢褘泄, 褏邪泄-褏褝褌 懈 褌芯屑褘 褋 薪邪斜芯褉邪屑懈 锌褉械褋械褌芯胁.',
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
        zh: '鍚変粬',
        en: 'Guitar',
        ja'',
        de: 'Gitarre',
        fr: 'Guitare',
        es: 'Guitarra',
        ru: '袚懈褌邪褉邪',
      ),
      subtitle: pickUiText(
        i18n,
        zh'',
        en: 'Tap strings or strum with local nylon, steel, and ambient preset packs.',
        ja'',
        de: 'Saiten antippen oder strummen mit Nylon-, Steel- und Ambient-Presets.',
        fr: 'Pincez ou grattez les cordes avec presets nylon, acier et ambient.',
        es: 'Pulsa o rasguea cuerdas con presets de nailon, acero y ambient.',
        ru: '些懈锌芯泻 懈 斜芯泄 锌芯 褋褌褉褍薪邪屑 褋 锌褉械褋械褌邪屑懈 薪械泄谢芯薪, 褋褌邪谢褜 懈 ambient.',
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
        zh'',
        en: 'Triangle',
        ja'',
        de: 'Triangel',
        fr: 'Triangle',
        es: 'Tri谩ngulo',
        ru: '孝褉械褍谐芯谢褜薪懈泻',
      ),
      subtitle: pickUiText(
        i18n,
        zh'',
        en: 'Clean metallic strikes with controllable ring and style presets.',
        ja'',
        de: 'Klarer metallischer Anschlag mit steuerbarem Nachklang und Presets.',
        fr: 'Frappe m茅tallique nette avec r茅sonance r茅glable et presets.',
        es: 'Golpe met谩lico limpio con resonancia ajustable y presets.',
        ru: '效懈褋褌褘泄 屑械褌邪谢谢懈褔械褋泻懈泄 褍写邪褉 褋 褉械谐褍谢懈褉芯胁泻芯泄 蟹胁芯薪邪 懈 锌褉械褋械褌邪屑懈.',
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
    if (widget.fullScreen) {
      unawaited(_enterImmersiveMode());
    }
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
      'a_minor' => pickUiText(i18n, zh: 'A灏忚皟', en: 'A Minor'),
      'd_dorian' => pickUiText(i18n, zh'', en: 'D Dorian'),
      'zen' => pickUiText(i18n, zh: '绂呮剰浜斿０闊抽樁', en: 'Zen Pentatonic'),
      'c_lydian' => pickUiText(i18n, zh'', en: 'C Lydian'),
      'hirajoshi' => pickUiText(i18n, zh'', en: 'Hirajoshi'),
      _ => pickUiText(i18n, zh: 'C澶ц皟', en: 'C Major'),
    };
  }

  String _chordLabel(AppI18n i18n, _HarpChordPreset preset) {
    return switch (preset.id) {
      'minor' => pickUiText(i18n, zh: '灏忎笁鍜屽鸡', en: 'Minor'),
      'sus2' => pickUiText(i18n, zh: '鎸備簩', en: 'Sus2'),
      'add9' => pickUiText(i18n, zh: '鍔犱節', en: 'Add9'),
      'sus4' => pickUiText(i18n, zh: '鎸傚洓', en: 'Sus4'),
      'maj7' => pickUiText(i18n, zh: '澶т竷', en: 'Maj7'),
      'min7' => pickUiText(i18n, zh: '灏忎竷', en: 'Min7'),
      _ => pickUiText(i18n, zh: '澶т笁鍜屽鸡', en: 'Major'),
    };
  }

  String _pluckLabel(AppI18n i18n, _HarpPluckPreset preset) {
    return switch (preset.id) {
      'warm' => pickUiText(i18n, zh: '娓╂殩', en: 'Warm'),
      'crystal' => pickUiText(i18n, zh: '姘存櫠', en: 'Crystal'),
      'bright' => pickUiText(i18n, zh: '鏄庝寒', en: 'Bright'),
      'nylon' => pickUiText(i18n, zh: '灏奸緳', en: 'Nylon'),
      'glass' => pickUiText(i18n, zh: '鐜荤拑', en: 'Glass'),
      'concert' => pickUiText(i18n, zh'', en: 'Concert'),
      'steel' => pickUiText(i18n, zh: '閽㈠鸡', en: 'Steel'),
      _ => pickUiText(i18n, zh: '涓濈桓', en: 'Silk'),
    };
  }

  String _pluckDescription(AppI18n i18n, _HarpPluckPreset preset) {
    return switch (preset.id) {
      'warm' => pickUiText(
        i18n,
        zh'',
        en: 'More body and slower tail.',
      ),
      'crystal' => pickUiText(
        i18n,
        zh'',
        en: 'Sharper upper harmonics.',
      ),
      'bright' => pickUiText(
        i18n,
        zh'',
        en: 'Clear attack for active strum.',
      ),
      'nylon' => pickUiText(
        i18n,
        zh'',
        en: 'Round body with light transient.',
      ),
      'glass' => pickUiText(
        i18n,
        zh'',
        en: 'Thin body and sparkling top.',
      ),
      'concert' => pickUiText(
        i18n,
        zh'',
        en: 'Pedal-harp like balance and sustain.',
      ),
      'steel' => pickUiText(
        i18n,
        zh'',
        en: 'Stronger core and brighter attack.',
      ),
      _ => pickUiText(i18n, zh'', en: 'Balanced and soft.'),
    };
  }

  String _patternLabel(AppI18n i18n, _HarpPatternPreset preset) {
    return switch (preset.id) {
      'cascade' => pickUiText(i18n, zh: '鐎戝竷', en: 'Cascade'),
      'chord' => pickUiText(i18n, zh: '鍜屽鸡鑴夊啿', en: 'Chord'),
      _ => pickUiText(i18n, zh: '婊戣', en: 'Glide'),
    };
  }

  String _patternDescription(AppI18n i18n, _HarpPatternPreset preset) {
    return switch (preset.id) {
      'cascade' => pickUiText(i18n, zh'', en: 'Up then down.'),
      'chord' => pickUiText(
        i18n,
        zh'',
        en: 'Pulse active chord tones.',
      ),
      _ => pickUiText(i18n, zh'', en: 'Ascending sweep.'),
    };
  }

  String _paletteLabel(AppI18n i18n, _HarpPalettePreset preset) {
    return switch (preset.id) {
      'aurora' => pickUiText(i18n, zh: '鏋佸厜', en: 'Aurora'),
      'ember' => pickUiText(i18n, zh: '浣欑儸', en: 'Ember'),
      'jade' => pickUiText(i18n, zh: '缈＄繝', en: 'Jade'),
      _ => pickUiText(i18n, zh: '鏈堝厜', en: 'Moon'),
    };
  }

  String _realismLabel(AppI18n i18n, _HarpRealismPreset preset) {
    return switch (preset.id) {
      'pedal_harp' => pickUiText(i18n, zh: '韪忔澘绔栫惔', en: 'Pedal Harp'),
      'steel_studio' => pickUiText(i18n, zh'', en: 'Steel Studio'),
      'chamber_soft' => pickUiText(i18n, zh: '瀹ゅ唴鏌斿拰', en: 'Chamber Soft'),
      _ => pickUiText(i18n, zh'', en: 'Concert Nylon'),
    };
  }

  String _realismDescription(AppI18n i18n, _HarpRealismPreset preset) {
    return switch (preset.id) {
      'pedal_harp' => pickUiText(
        i18n,
        zh'',
        en: 'Balanced sustain for melodic passages.',
      ),
      'steel_studio' => pickUiText(
        i18n,
        zh'',
        en: 'Tight transient and clear note separation.',
      ),
      'chamber_soft' => pickUiText(
        i18n,
        zh'',
        en: 'Soft finger-pluck with gentle bloom.',
      ),
      _ => pickUiText(
        i18n,
        zh'',
        en: 'Round body with controlled hall tail.',
      ),
    };
  }

  Future<void> _enterImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  Future<void> _exitImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

  String _styleForGestureIntensity(double intensity) {
    final clamped = intensity.clamp(0.0, 1.0).toDouble();
    if (clamped > 0.82) return 'steel';
    if (clamped > 0.66) return 'concert';
    if (clamped > 0.5) return 'bright';
    if (clamped < 0.26) return 'nylon';
    return _pluckStyleId;
  }

  double _reverbForGestureIntensity(double intensity) {
    final clamped = intensity.clamp(0.0, 1.0).toDouble();
    return (_reverbForAudio + (1 - clamped) * 0.08).clamp(0.05, 0.78).toDouble();
  }

  ToolboxEffectPlayer _playerForFrequency(
    double frequency, {
    String? styleOverride,
    double? reverbOverride,
  }) {
    final styleId = styleOverride ?? _pluckStyleId;
    final reverb = reverbOverride ?? _reverbForAudio;
    final key =
        '${frequency.toStringAsFixed(2)}|$styleId|${reverb.toStringAsFixed(2)}';
    final existing = _playersByKey[key];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.harpNote(
        frequency,
        style: styleId,
        reverb: reverb,
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
    final styleForTouch = _styleForGestureIntensity(clampedIntensity);
    final reverbForTouch = _reverbForGestureIntensity(clampedIntensity);
    if (!_muted) {
      final volume = (0.22 + clampedIntensity * 0.78).clamp(0.0, 1.0);
      unawaited(
        _playerForFrequency(
          frequency,
          styleOverride: styleForTouch,
          reverbOverride: reverbForTouch,
        ).play(volume: volume.toDouble()),
      );
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
    if (distance > spacing * 0.64) return;
    _pluckString(
      index,
      intensity: 0.54,
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
      intensity: 0.42,
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
      if (nearest == _lastDragStringIndex) {
        if (delta.distance >= _swipeThreshold * 1.35) {
          final nudgedIntensity = (intensity * 0.78).clamp(0.2, 0.86).toDouble();
          _pluckString(
            nearest,
            intensity: nudgedIntensity,
            direction: direction,
            applyChordResonance: false,
          );
        }
        return;
      }
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
    final threshold = (_swipeThreshold * 0.76).clamp(0.24, 4.0).toDouble();
    if (primaryDelta < threshold) return false;
    return primaryDelta >= crossDelta * 0.95;
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
    if (widget.fullScreen) {
      unawaited(_exitImmersiveMode());
    }
    _vibrationTicker.dispose();
    _invalidateAudioPlayers(warmUp: false);
    super.dispose();
  }

  void _openFullScreen() {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const HarpToolPage(fullScreen: true),
      ),
    );
  }

  String _backdropLabel(AppI18n i18n, String id) {
    return switch (id) {
      'wood' => pickUiText(i18n, zh: '鏈ㄨ川閫忓厜', en: 'Luminous wood'),
      _ => pickUiText(i18n, zh: '閫忔槑姘存櫠', en: 'Crystal glass'),
    };
  }

  void _showHarpTutorial() {
    _showInstrumentTutorialDialog(
      context: context,
      titleZh'',
      titleEn: 'Harp Quick Tutorial',
      steps: const <_TutorialStep>[
        _TutorialStep(
          zh'',
          en: 'Tap for stable plucks; drag across strings for connected arpeggios.',
        ),
        _TutorialStep(
          zh'',
          en: 'Faster and longer swipes produce brighter and stronger tone.',
        ),
        _TutorialStep(
          zh'',
          en: 'Switch crystal or wood backdrop for different visual immersion.',
        ),
        _TutorialStep(
          zh'',
          en: 'Start from a realism preset, then fine-tune damping and trigger threshold.',
        ),
      ],
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

  Widget _buildFullScreenBody(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final reverbPercent = (_reverbUi * 100).round();
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final activePreset = _realismPresets.where((preset) {
      return preset.id == _activeRealismPresetId;
    });
    final presetLabel = activePreset.isEmpty
        ? pickUiText(i18n, zh'', en: 'Custom')
        : _realismLabel(i18n, activePreset.first);

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return _buildHarpSurface(
                context: context,
                size: size,
                rounded: false,
              );
            },
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomInset + 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  FilledButton.tonal(
                    onPressed:
                        widget.onExitFullScreen ??
                        () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.38),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonal(
                    onPressed: () => setState(() => _muted = !_muted),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.38),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Icon(
                      _muted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonal(
                    onPressed: _showHarpTutorial,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.38),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Icon(Icons.school_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  _CompactMetric(
                    label: pickUiText(i18n, zh: '甯冨眬', en: 'Layout'),
                    value: pickUiText(i18n, zh: '妯悜', en: 'Horizontal'),
                  ),
                  const SizedBox(width: 8),
                  _CompactMetric(
                    label: pickUiText(i18n, zh: '棰勮', en: 'Preset'),
                    value: presetLabel,
                  ),
                  const SizedBox(width: 8),
                  _CompactMetric(
                    label: pickUiText(i18n, zh: '娈嬪搷', en: 'Reverb'),
                    value: '$reverbPercent%',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <String>['crystal', 'wood']
                    .map(
                      (material) => ChoiceChip(
                        label: Text(_backdropLabel(i18n, material)),
                        selected: _backdropMaterial == material,
                        onSelected: (_) {
                          setState(() => _backdropMaterial = material);
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
              title: pickUiText(i18n, zh: '鐞村鸡', en: 'Strings'),
              subtitle: pickUiText(
                i18n,
                zh'',
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
                  label: pickUiText(i18n, zh: '寮︽暟', en: 'Strings'),
                  value: '12',
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '璋冨紡', en: 'Scale'),
                  value: _scaleLabel(i18n, _activeScale),
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '娈嬪搷', en: 'Reverb'),
                  value: '$reverbPercent%',
                ),
                FilledButton.tonalIcon(
                  onPressed: () => setState(() => _muted = !_muted),
                  icon: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  ),
                  label: Text(
                    _muted
                        ? pickUiText(i18n, zh: '闈欓煶', en: 'Muted')
                        : pickUiText(i18n, zh: '澹伴煶寮€', en: 'Sound on'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openFullScreen,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(pickUiText(i18n, zh: '鍏ㄥ睆', en: 'Full screen')),
                ),
                OutlinedButton.icon(
                  onPressed: _showHarpTutorial,
                  icon: const Icon(Icons.school_rounded),
                  label: Text(pickUiText(i18n, zh: '鏁欑▼', en: 'Tutorial')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <String>['crystal', 'wood']
                  .map(
                    (material) => ChoiceChip(
                      label: Text(_backdropLabel(i18n, material)),
                      selected: _backdropMaterial == material,
                      onSelected: (_) {
                        setState(() => _backdropMaterial = material);
                      },
                    ),
                  )
                  .toList(growable: false),
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
                    pickUiText(i18n, zh: '鑷姩鐞堕煶', en: 'Auto arpeggio'),
                  ),
                ),
                Text(
                  pickUiText(
                    i18n,
                    zh'',
                    en: 'Tip: a wider, faster swipe creates a brighter strum.',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SectionHeader(
              title: pickUiText(i18n, zh: '楂樼湡瀹炲害棰勮', en: 'High Realism Presets'),
              subtitle: pickUiText(
                i18n,
                zh'',
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
              title: pickUiText(i18n, zh'', en: 'Tone & Palette'),
              subtitle: pickUiText(
                i18n,
                zh'',
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
                zh: '娈嬪搷 $reverbPercent%',
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
              title: pickUiText(i18n, zh'', en: 'Scale & Chord'),
              subtitle: pickUiText(
                i18n,
                zh'',
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
              label: Text(pickUiText(i18n, zh: '鍜屽鸡鍏辨尟', en: 'Chord resonance')),
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
                zh: '鍜屽鸡鏍归煶 ${_chordRootIndex + 1} / $_stringCount',
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
              title: pickUiText(i18n, zh: '鎵嬫劅鍙傛暟', en: 'Feel'),
              subtitle: pickUiText(
                i18n,
                zh'',
                en: 'Expose damping and trigger threshold for touch sensitivity tuning.',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pickUiText(
                i18n,
                zh: '闃诲凹 ${_damping.toStringAsFixed(1)}',
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
                zh: '瑙﹀彂闃堝€?${_swipeThreshold.toStringAsFixed(1)} px',
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
    return Expanded(
      child: Container(
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

class _GuqinLesson {
  const _GuqinLesson({
    required this.id,
    required this.level,
    required this.title,
    required this.summary,
  });

  final String id;
  final String level;
  final String title;
  final String summary;
}

class _GuqinPreset {
  const _GuqinPreset({
    required this.id,
    required this.styleId,
    required this.resonance,
    required this.slide,
  });

  final String id;
  final String styleId;
  final double resonance;
  final double slide;
}

class _GuqinTechniqueSeed {
  const _GuqinTechniqueSeed({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.focusZh,
    required this.focusEn,
  });

  final String id;
  final String titleZh;
  final String titleEn;
  final String focusZh;
  final String focusEn;
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
    _PianoPreset(id: 'upright_study', styleId: 'upright', touch: 0.9),
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
      'upright_study' => pickUiText(i18n, zh: '绔嬪紡缁冧範', en: 'Upright study'),
      'bright_stage' => pickUiText(
        i18n,
        zh: '鏄庝寒鑸炲彴',
        en: 'Bright stage',
        ja: '銉栥儵銈ゃ儓銈广儐銉笺偢',
        de: 'Helle B眉hne',
        fr: 'Sc猫ne brillante',
        es: 'Escenario brillante',
        ru: '携褉泻邪褟 褋褑械薪邪',
      ),
      'felt_room' => pickUiText(
        i18n,
        zh: '姣涙灏忓',
        en: 'Felt room',
        ja'',
        de: 'Felt-Raum',
        fr: 'Pi猫ce feutr茅e',
        es: 'Sala de fieltro',
        ru: '肖械褌褉芯胁邪褟 泻芯屑薪邪褌邪',
      ),
      _ => pickUiText(
        i18n,
        zh'',
        en: 'Concert hall',
        ja: '銈炽兂銈点兗銉堛儧銉笺儷',
        de: 'Konzertsaal',
        fr: 'Salle de concert',
        es: 'Sala de conciertos',
        ru: '袣芯薪褑械褉褌薪褘泄 蟹邪谢',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'upright_study' => pickUiText(
        i18n,
        zh'',
        en: 'Upright-like key response tailored for daily practice.',
      ),
      'bright_stage' => pickUiText(
        i18n,
        zh'',
        en: 'Sharper hammer attack and brighter harmonics for lead lines.',
        ja'',
        de: 'Klarerer Anschlag und hellere Obert枚ne f眉r Lead-Melodien.',
        fr: 'Attaque plus nette et harmoniques brillantes pour la m茅lodie.',
        es: 'Ataque m谩s marcado y arm贸nicos brillantes para la melod铆a.',
        ru: '袘芯谢械械 褉械蟹泻邪褟 邪褌邪泻邪 懈 褟褉泻懈械 芯斜械褉褌芯薪褘 写谢褟 胁械写褍褖械泄 屑械谢芯写懈懈.',
      ),
      'felt_room' => pickUiText(
        i18n,
        zh'',
        en: 'Softer felt-like body for intimate and quiet playing.',
        ja'',
        de: 'Weicher, intimer Felt-Charakter f眉r ruhiges Spielen.',
        fr: 'Corps feutr茅 et doux pour un jeu intime et calme.',
        es: 'Cuerpo m谩s suave tipo fieltro para tocar en calma.',
        ru: '袦褟谐泻懈泄, 泻邪屑械褉薪褘泄 褌械屑斜褉 胁 褋褌懈谢械 felt 写谢褟 褋锌芯泻芯泄薪芯泄 懈谐褉褘.',
      ),
      _ => pickUiText(
        i18n,
        zh'',
        en: 'Balanced sustain and room feel for all-purpose playing.',
        ja'',
        de: 'Ausgewogener Sustain mit Raumgef眉hl f眉r vielseitiges Spiel.',
        fr: 'Sustain 茅quilibr茅 et sensation d鈥檈space polyvalente.',
        es: 'Sustain equilibrado y sensaci贸n de sala para todo uso.',
        ru: '小斜邪谢邪薪褋懈褉芯胁邪薪薪褘泄 褋褍褋褌械泄薪 懈 锌褉芯褋褌褉邪薪褋褌胁芯 写谢褟 褍薪懈胁械褉褋邪谢褜薪芯泄 懈谐褉褘.',
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

  _PianoKey? _keyById(String id) {
    for (final item in _whiteKeys) {
      if (item.id == id) return item;
    }
    for (final item in _blackKeys) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _playChord(List<String> noteIds) async {
    HapticFeedback.mediumImpact();
    for (final id in noteIds) {
      final key = _keyById(id);
      if (key != null) {
        unawaited(_playerFor(key).play(volume: (_touch * 0.9).clamp(0.2, 1.0)));
      }
    }
    if (!mounted || noteIds.isEmpty) return;
    setState(() => _activeKeyId = noteIds.first);
    Future<void>.delayed(const Duration(milliseconds: 130), () {
      if (!mounted) return;
      setState(() => _activeKeyId = null);
    });
  }

  void _openFullScreen() {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const _DeckInstrumentFullScreenPage(instrument: _HarpDeckInstrument.piano),
      ),
    );
  }

  void _showPianoTutorial() {
    _showInstrumentTutorialDialog(
      context: context,
      titleZh'',
      titleEn: 'Piano Quick Tutorial',
      steps: const <_TutorialStep>[
        _TutorialStep(
          zh'',
          en: 'Swipe horizontally to reach all keys; small screens get larger hit tolerance.',
        ),
        _TutorialStep(
          zh'',
          en: 'Pick a preset, adjust touch, then validate intonation with chord shortcuts.',
        ),
        _TutorialStep(
          zh'',
          en: 'Fullscreen expands white-key width for a more physical keyboard feel.',
        ),
      ],
    );
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
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '鐞撮敭',
                    en: 'Keys',
                    ja: '閸电洡',
                    de: 'Tasten',
                    fr: 'Touches',
                    es: 'Teclas',
                    ru: '袣谢邪胁懈褕懈',
                  ),
                  value: '${_whiteKeys.length + _blackKeys.length}',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '闊冲煙',
                    en: 'Range',
                    ja: '闊冲煙',
                    de: 'Umfang',
                    fr: '脡tendue',
                    es: 'Rango',
                    ru: '袛懈邪锌邪蟹芯薪',
                  ),
                  value: 'C2-C6',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '棰勮',
                    en: 'Preset',
                    ja'',
                    de: 'Preset',
                    fr: 'Pr茅r茅glage',
                    es: 'Preajuste',
                    ru: '袩褉械褋械褌',
                  ),
                  value: presetLabel,
                ),
                OutlinedButton.icon(
                  onPressed: _openFullScreen,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(pickUiText(i18n, zh: '鍏ㄥ睆', en: 'Full screen')),
                ),
                OutlinedButton.icon(
                  onPressed: _showPianoTutorial,
                  icon: const Icon(Icons.school_rounded),
                  label: Text(pickUiText(i18n, zh: '鏁欑▼', en: 'Tutorial')),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SectionHeader(
              title: pickUiText(
                i18n,
                zh'',
                en: 'Preset pack',
                ja: '銉椼儶銈汇儍銉堛儜銉冦偗',
                de: 'Preset-Paket',
                fr: 'Pack de pr茅r茅glages',
                es: 'Paquete de presets',
                ru: '袩邪泻械褌 锌褉械褋械褌芯胁',
              ),
              subtitle: pickUiText(
                i18n,
                zh'',
                en: 'Switch timbre and default touch intensity.',
                ja'',
                de: 'Wechselt Klangfarbe und Standard-Anschlagsst盲rke.',
                fr: 'Basculez le timbre et l鈥檌ntensit茅 de toucher par d茅faut.',
                es: 'Cambia timbre e intensidad de toque por defecto.',
                ru: '袩械褉械泻谢褞褔邪械褌 褌械屑斜褉 懈 斜邪蟹芯胁褍褞 褋懈谢褍 薪邪卸邪褌懈褟.',
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
                zh: '瑙﹂敭鍔涘害 ${(_touch * 100).round()}%',
                en: 'Touch ${(_touch * 100).round()}%',
                ja: '銈裤儍銉?${(_touch * 100).round()}%',
                de: 'Anschlag ${(_touch * 100).round()}%',
                fr: 'Toucher ${(_touch * 100).round()}%',
                es: 'Toque ${(_touch * 100).round()}%',
                ru: '袣邪褋邪薪懈械 ${(_touch * 100).round()}%',
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: () => unawaited(_playChord(const <String>['C4', 'E4', 'G4'])),
                  child: const Text('C major'),
                ),
                FilledButton.tonal(
                  onPressed: () => unawaited(_playChord(const <String>['F4', 'A4', 'C5'])),
                  child: const Text('F major'),
                ),
                FilledButton.tonal(
                  onPressed: () => unawaited(_playChord(const <String>['G4', 'B4', 'D5'])),
                  child: const Text('G major'),
                ),
                FilledButton.tonal(
                  onPressed: () => unawaited(_playChord(const <String>['A4', 'C5', 'E5'])),
                  child: const Text('A minor'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SectionHeader(
              title: pickUiText(
                i18n,
                zh: '閿洏',
                en: 'Keyboard',
                ja: '閸电洡',
                de: 'Klaviatur',
                fr: 'Clavier',
                es: 'Teclado',
                ru: '袣谢邪胁懈邪褌褍褉邪',
              ),
              subtitle: pickUiText(
                i18n,
                zh'',
                en: 'Tap keys directly. Black keys are layered above.',
                ja'',
                de: 'Tasten direkt antippen. Schwarze Tasten liegen dar眉ber.',
                fr: 'Touchez directement les touches. Les noires sont au-dessus.',
                es: 'Toca directamente las teclas. Las negras van por encima.',
                ru: '袧邪卸懈屑邪泄褌械 泻谢邪胁懈褕懈 薪邪锌褉褟屑褍褞; 褔褢褉薪褘械 褉邪褋锌芯谢芯卸械薪褘 锌芯胁械褉褏 斜械谢褘褏.',
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: widget.fullScreen ? 300 : 240,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shortestSide = MediaQuery.sizeOf(context).shortestSide;
                  final minWhiteWidth = widget.fullScreen
                      ? 56.0
                      : (shortestSide < 360 ? 36.0 : 44.0);
                  final totalWidth = math.max(
                    constraints.maxWidth,
                    _whiteKeys.length * minWhiteWidth,
                  );
                  final whiteWidth = totalWidth / _whiteKeys.length;
                  final blackWidth = whiteWidth * 0.66;
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
        );
    return _wrapInstrumentPanel(fullScreen: widget.fullScreen, child: content);
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
      id: 'bamboo_natural',
      styleId: 'bamboo',
      scaleId: 'major',
      breath: 0.73,
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
      'bamboo_natural' => pickUiText(i18n, zh: '绔圭瑳鑷劧', en: 'Bamboo natural'),
      'lead_solo' => pickUiText(
        i18n,
        zh: '鐙棰嗗',
        en: 'Lead solo',
        ja'',
        de: 'Lead-Solo',
        fr: 'Solo lead',
        es: 'Solo lead',
        ru: '袥懈写-褋芯谢芯',
      ),
      'alto_warm' => pickUiText(
        i18n,
        zh: '鏆栭煶涓煶',
        en: 'Warm alto',
        ja'',
        de: 'Warmes Alt',
        fr: 'Alto chaud',
        es: 'Alto c谩lido',
        ru: '孝褢锌谢褘泄 邪谢褜褌',
      ),
      _ => pickUiText(
        i18n,
        zh'',
        en: 'Airy flow',
        ja'',
        de: 'Luftiger Fluss',
        fr: 'Flux a茅rien',
        es: 'Flujo a茅reo',
        ru: '袙芯蟹写褍褕薪褘泄 锌芯褌芯泻',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _FlutePreset preset) {
    return switch (preset.id) {
      'bamboo_natural' => pickUiText(
        i18n,
        zh'',
        en: 'Stronger bamboo resonance with a more natural tail and decay.',
      ),
      'lead_solo' => pickUiText(
        i18n,
        zh'',
        en: 'Brighter lead tone with stronger presence for melodic phrases.',
        ja'',
        de: 'Hellerer Lead-Sound mit mehr Pr盲senz f眉r Melodielinien.',
        fr: 'Timbre plus brillant et pr茅sent pour les lignes m茅lodiques.',
        es: 'Tono m谩s brillante y presente para frases mel贸dicas.',
        ru: '袘芯谢械械 褟褉泻懈泄 懈 胁褘写胁懈薪褍褌褘泄 褌械屑斜褉 写谢褟 屑械谢芯写懈褔械褋泻懈褏 褎褉邪蟹.',
      ),
      'alto_warm' => pickUiText(
        i18n,
        zh'',
        en: 'Warmer midrange and softer tail for calm backing layers.',
        ja'',
        de: 'W盲rmere Mitten und weicheres Ausklingen f眉r ruhige Fl盲chen.',
        fr: 'M茅diums plus chauds et fin de note douce pour des nappes calmes.',
        es: 'Medios m谩s c谩lidos y cola suave para capas tranquilas.',
        ru: '孝褢锌谢邪褟 褋械褉械写懈薪邪 懈 屑褟谐泻懈泄 褏胁芯褋褌 写谢褟 褋锌芯泻芯泄薪芯泄 锌芯写谢芯卸泻懈.',
      ),
      _ => pickUiText(
        i18n,
        zh'',
        en: 'Natural breathy tone for gentle and flowing play.',
        ja'',
        de: 'Nat眉rlicher, luftiger Klang f眉r sanftes Spiel.',
        fr: 'Souffle naturel pour un jeu doux et fluide.',
        es: 'Tono de soplo natural para tocar suave y fluido.',
        ru: '袝褋褌械褋褌胁械薪薪芯械 写褘褏邪薪懈械 褌械屑斜褉邪 写谢褟 屑褟谐泻芯泄 懈 锌谢邪胁薪芯泄 懈谐褉褘.',
      ),
    };
  }

  String _scaleLabel(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'pentatonic' => pickUiText(
        i18n,
        zh: '浜斿０闊抽樁',
        en: 'Pentatonic',
        ja'',
        de: 'Pentatonik',
        fr: 'Pentatonique',
        es: 'Pentat贸nica',
        ru: '袩械薪褌邪褌芯薪懈泻邪',
      ),
      'dorian' => pickUiText(
        i18n,
        zh'',
        en: 'Dorian',
        ja: '銉夈儶銈兂',
        de: 'Dorisch',
        fr: 'Dorien',
        es: 'D贸rico',
        ru: '袛芯褉懈泄褋泻懈泄',
      ),
      _ => pickUiText(
        i18n,
        zh: '澶ц皟',
        en: 'Major',
        ja: '銉°偢銉ｃ兗',
        de: 'Dur',
        fr: 'Majeur',
        es: 'Mayor',
        ru: '袦邪卸芯褉',
      ),
    };
  }

  String _styleLabel(AppI18n i18n, String styleId) {
    return switch (styleId) {
      'bamboo' => pickUiText(i18n, zh: '绔硅川', en: 'Bamboo'),
      'lead' => pickUiText(
        i18n,
        zh: '棰嗗',
        en: 'Lead',
        ja'',
        de: 'Lead',
        fr: 'Lead',
        es: 'Lead',
        ru: '袥懈写',
      ),
      'alto' => pickUiText(
        i18n,
        zh: '涓煶',
        en: 'Alto',
        ja'',
        de: 'Alt',
        fr: 'Alto',
        es: 'Alto',
        ru: '袗谢褜褌',
      ),
      _ => pickUiText(
        i18n,
        zh: '绌烘皵',
        en: 'Airy',
        ja: '銈ㄣ偄銉兗',
        de: 'Luftig',
        fr: 'A茅rien',
        es: 'A茅reo',
        ru: '袙芯蟹写褍褕薪褘泄',
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
    final notes = _activeNotes;
    if (notes.isEmpty) return null;
    if (_pressedHoles.isEmpty) {
      return notes.length - 1;
    }
    final closed = _pressedHoles.length.clamp(1, 6);
    return (notes.length - closed).clamp(0, notes.length - 1);
  }

  Future<void> _syncBreathSustain() async {
    final nextIndex = (_blowSensorEnabled && _isBlowing)
        ? _noteIndexFromHoles()
        : null;
    if (nextIndex == null) {
      if (_sustainedNoteIndex != null) {
        final releasedIndex = _sustainedNoteIndex!;
        final releasedNote = _activeNotes[releasedIndex.clamp(0, _activeNotes.length - 1)];
        unawaited(
          _playerFor(releasedNote).play(
            volume: (_breath * 0.32).clamp(0.08, 0.3),
          ),
        );
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

  void _openFullScreen() {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const _DeckInstrumentFullScreenPage(instrument: _HarpDeckInstrument.flute),
      ),
    );
  }

  void _showFluteTutorial() {
    _showInstrumentTutorialDialog(
      context: context,
      titleZh'',
      titleEn: 'Flute Quick Tutorial',
      steps: const <_TutorialStep>[
        _TutorialStep(
          zh'',
          en: 'Enable breath detection, then press holes; release keeps a natural tail.',
        ),
        _TutorialStep(
          zh'',
          en: 'Open-hole state maps to open-tube note for quick entry.',
        ),
        _TutorialStep(
          zh'',
          en: 'Bamboo preset gives a more physical bamboo-like resonance.',
        ),
      ],
    );
  }

  Widget _buildFluteHoleBoard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFECD6A8), Color(0xFFD4B27A), Color(0xFFB88D52)],
        ),
        border: Border.all(color: const Color(0x66FFFFFF)),
      ),
      child: Row(
        children: List<Widget>.generate(6, (index) {
          final holeNumber = index + 1;
          final pressed = _pressedHoles.contains(holeNumber);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _setHolePressed(holeNumber, true),
                onPointerUp: (_) => _setHolePressed(holeNumber, false),
                onPointerCancel: (_) => _setHolePressed(holeNumber, false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  height: widget.fullScreen ? 84 : 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pressed ? const Color(0xFF1E293B) : const Color(0xFFF8F3EA),
                    border: Border.all(
                      color: pressed ? const Color(0xFF0F172A) : const Color(0xFF8C6A3D),
                      width: pressed ? 2.2 : 1.6,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: pressed ? 0.25 : 0.12),
                        blurRadius: pressed ? 8 : 4,
                        spreadRadius: pressed ? 1 : 0,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'H$holeNumber',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: pressed ? Colors.white : const Color(0xFF4A331B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
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
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '棰勮',
                    en: 'Preset',
                    ja'',
                    de: 'Preset',
                    fr: 'Pr茅r茅glage',
                    es: 'Preajuste',
                    ru: '袩褉械褋械褌',
                  ),
                  value: _presetLabel(i18n, preset),
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '璋冨紡',
                    en: 'Scale',
                    ja: '銈广偙銉笺儷',
                    de: 'Skala',
                    fr: 'Gamme',
                    es: 'Escala',
                    ru: '袥邪写',
                  ),
                  value: _scaleLabel(i18n, _scale),
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '姘旀伅',
                    en: 'Breath',
                    ja'',
                    de: 'Atem',
                    fr: 'Souffle',
                    es: 'Soplo',
                    ru: '袛褘褏邪薪懈械',
                  ),
                  value: '${(_breath * 100).round()}%',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh'',
                    en: 'Last note',
                    ja'',
                    de: 'Letzter Ton',
                    fr: 'Derni猫re note',
                    es: '脷ltima nota',
                    ru: '袩芯褋谢械写薪褟褟 薪芯褌邪',
                  ),
                  value: _lastNote ?? '--',
                ),
                OutlinedButton.icon(
                  onPressed: _openFullScreen,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(pickUiText(i18n, zh: '鍏ㄥ睆', en: 'Full screen')),
                ),
                OutlinedButton.icon(
                  onPressed: _showFluteTutorial,
                  icon: const Icon(Icons.school_rounded),
                  label: Text(pickUiText(i18n, zh: '鏁欑▼', en: 'Tutorial')),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SectionHeader(
              title: pickUiText(
                i18n,
                zh'',
                en: 'Preset pack',
                ja: '銉椼儶銈汇儍銉堛儜銉冦偗',
                de: 'Preset-Paket',
                fr: 'Pack de pr茅r茅glages',
                es: 'Paquete de presets',
                ru: '袩邪泻械褌 锌褉械褋械褌芯胁',
              ),
              subtitle: pickUiText(
                i18n,
                zh'',
                en: 'Each preset binds timbre, scale, and default breath intensity.',
                ja'',
                de: 'Jedes Preset verkn眉pft Klangfarbe, Skala und Atemintensit盲t.',
                fr: 'Chaque preset relie timbre, gamme et intensit茅 de souffle.',
                es: 'Cada preset combina timbre, escala e intensidad de soplo.',
                ru: '袣邪卸写褘泄 锌褉械褋械褌 褋胁褟蟹褘胁邪械褌 褌械屑斜褉, 谢邪写 懈 褋懈谢褍 写褘褏邪薪懈褟.',
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
                zh: '姘旀伅 ${(_breath * 100).round()}% 路 闊宠壊 ${_styleLabel(i18n, _style)}',
                en: 'Breath ${(_breath * 100).round()}% 路 Tone ${_styleLabel(i18n, _style)}',
                ja: '銉栥儸銈?${(_breath * 100).round()}% 路 闊宠壊 ${_styleLabel(i18n, _style)}',
                de: 'Atem ${(_breath * 100).round()}% 路 Klang ${_styleLabel(i18n, _style)}',
                fr: 'Souffle ${(_breath * 100).round()}% 路 Timbre ${_styleLabel(i18n, _style)}',
                es: 'Soplo ${(_breath * 100).round()}% 路 Timbre ${_styleLabel(i18n, _style)}',
                ru: '袛褘褏邪薪懈械 ${(_breath * 100).round()}% 路 孝械屑斜褉 ${_styleLabel(i18n, _style)}',
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
              title: pickUiText(i18n, zh: '妯℃嫙鍚瑰', en: 'Blow Simulation'),
              subtitle: pickUiText(
                i18n,
                zh'',
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
                            zh'',
                            en: 'Disable blow sensor',
                          )
                        : pickUiText(
                            i18n,
                            zh'',
                            en: 'Enable blow sensor',
                          ),
                  ),
                ),
                if (_blowPermissionDenied)
                  Text(
                    pickUiText(
                      i18n,
                      zh: '楹﹀厠椋庢潈闄愪笉鍙敤',
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
                zh: '鍚规皵闃堝€?${(_blowThreshold * 100).round()}% 路 褰撳墠 ${(_micLevel * 100).round()}%',
                en: 'Blow threshold ${(_blowThreshold * 100).round()}% 路 Current ${(_micLevel * 100).round()}%',
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
            _buildFluteHoleBoard(theme),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () {
                if (_pressedHoles.isEmpty) return;
                setState(() => _pressedHoles.clear());
                unawaited(_syncBreathSustain());
              },
              icon: const Icon(Icons.air_rounded),
              label: Text(pickUiText(i18n, zh: '寮€绠￠煶', en: 'Open tube')),
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '鍚规皵鐘舵€侊細${_isBlowing ? "杩涜涓? : "鏈惞姘?} 路 鎸夊瓟锛?{_pressedHoles.length}',
                en: 'Blow: ${_isBlowing ? "active" : "idle"} 路 Holes pressed: ${_pressedHoles.length}',
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
        );
    return _wrapInstrumentPanel(fullScreen: widget.fullScreen, child: content);
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
  double _tone = 0.5;
  double _tail = 0.42;
  String _material = 'wood';

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
        zh: '鐢靛瓙濂椾欢',
        en: 'Electro kit',
        ja: '銈ㄣ儸銈儓銉偔銉冦儓',
        de: 'Elektro-Kit',
        fr: 'Kit 茅lectro',
        es: 'Kit electro',
        ru: '协谢械泻褌褉芯-薪邪斜芯褉',
      ),
      'lofi_kit' => pickUiText(
        i18n,
        zh'',
        en: 'Lo-fi kit',
        ja: '銉兗銉曘偂銈ゃ偔銉冦儓',
        de: 'Lo-fi-Kit',
        fr: 'Kit lo-fi',
        es: 'Kit lo-fi',
        ru: 'Lo-fi 薪邪斜芯褉',
      ),
      _ => pickUiText(
        i18n,
        zh: '鍘熷０濂椾欢',
        en: 'Acoustic kit',
        ja'',
        de: 'Akustik-Kit',
        fr: 'Kit acoustique',
        es: 'Kit ac煤stico',
        ru: '袗泻褍褋褌懈褔械褋泻懈泄 薪邪斜芯褉',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _DrumKitPreset preset) {
    return switch (preset.id) {
      'electro_kit' => pickUiText(
        i18n,
        zh'',
        en: 'Sharper transients and synthetic drum character.',
        ja'',
        de: 'Klarere Transienten mit elektronischem Drum-Charakter.',
        fr: 'Transitoires plus nettes et caract猫re 茅lectronique.',
        es: 'Transitorios m谩s marcados y car谩cter electr贸nico.',
        ru: '袘芯谢械械 褉械蟹泻邪褟 邪褌邪泻邪 懈 褝谢械泻褌褉芯薪薪褘泄 褏邪褉邪泻褌械褉 褍写邪褉芯胁.',
      ),
      'lofi_kit' => pickUiText(
        i18n,
        zh'',
        en: 'Relaxed impact with slightly dusty lo-fi tail.',
        ja'',
        de: 'Entspannter Anschlag mit leicht staubigem Lo-fi-Ausklang.',
        fr: 'Impact plus doux avec une l茅g猫re queue lo-fi.',
        es: 'Impacto relajado con una cola lo-fi ligera.',
        ru: '袘芯谢械械 屑褟谐泻懈泄 褍写邪褉 褋 谢褢谐泻懈屑 lo-fi 褏胁芯褋褌芯屑.',
      ),
      _ => pickUiText(
        i18n,
        zh'',
        en: 'Natural punch closer to an acoustic drum set.',
        ja'',
        de: 'Nat眉rlicher Punch wie bei einem akustischen Drumset.',
        fr: 'Impact naturel proche d鈥檜ne batterie acoustique.',
        es: 'Golpe natural cercano a una bater铆a ac煤stica.',
        ru: '袝褋褌械褋褌胁械薪薪褘泄 锌邪薪褔, 斜谢懈蟹泻懈泄 泻 邪泻褍褋褌懈褔械褋泻芯泄 褍褋褌邪薪芯胁泻械.',
      ),
    };
  }

  String _padLabel(AppI18n i18n, String id) {
    return switch (id) {
      'snare' => pickUiText(
        i18n,
        zh: '鍐涢紦',
        en: 'Snare',
        ja'',
        de: 'Snare',
        fr: 'Caisse claire',
        es: 'Caja',
        ru: '袦邪谢褘泄',
      ),
      'hihat' => pickUiText(
        i18n,
        zh: '韪╅暡',
        en: 'Hi-hat',
        ja'',
        de: 'Hi-Hat',
        fr: 'Charleston',
        es: 'Hi-hat',
        ru: '啸邪泄-褏褝褌',
      ),
      'tom' => pickUiText(
        i18n,
        zh: '鍡甸紦',
        en: 'Tom',
        ja: '銈裤儬',
        de: 'Tom',
        fr: 'Tom',
        es: 'Tom',
        ru: '孝芯屑',
      ),
      _ => pickUiText(
        i18n,
        zh: '搴曢紦',
        en: 'Kick',
        ja'',
        de: 'Kick',
        fr: 'Kick',
        es: 'Bombo',
        ru: '袘芯褔泻邪',
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
      if (preset.kitId == 'electro') {
        _tone = 0.62;
        _tail = 0.32;
        _material = 'metal';
      } else if (preset.kitId == 'lofi') {
        _tone = 0.38;
        _tail = 0.52;
        _material = 'hybrid';
      } else {
        _tone = 0.5;
        _tail = 0.44;
        _material = 'wood';
      }
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
    final cacheKey =
        '$id:$_kit:${_tone.toStringAsFixed(2)}:${_tail.toStringAsFixed(2)}:$_material';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.drumHit(
        id,
        kit: _kit,
        tone: _tone,
        tail: _tail,
        material: _material,
      ),
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

  void _openFullScreen() {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const _DeckInstrumentFullScreenPage(instrument: _HarpDeckInstrument.drumPad),
      ),
    );
  }

  void _showDrumTutorial() {
    _showInstrumentTutorialDialog(
      context: context,
      titleZh'',
      titleEn: 'Drum Pad Quick Tutorial',
      steps: const <_TutorialStep>[
        _TutorialStep(
          zh'',
          en: 'Pick a kit, then tune drive, tone, and tail for the target feel.',
        ),
        _TutorialStep(
          zh'',
          en: 'Material changes metallic versus wooden impact character.',
        ),
        _TutorialStep(
          zh'',
          en: 'On small screens, alternate two fingers for steadier rhythm.',
        ),
      ],
    );
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
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '榧撳灚',
                    en: 'Pads',
                    ja'',
                    de: 'Pads',
                    fr: 'Pads',
                    es: 'Pads',
                    ru: '袩褝写褘',
                  ),
                  value: '${_pads.length}',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh'',
                    en: 'Last hit',
                    ja'',
                    de: 'Letzter Schlag',
                    fr: 'Dernier coup',
                    es: '脷ltimo golpe',
                    ru: '袩芯褋谢械写薪懈泄 褍写邪褉',
                  ),
                  value: _lastHitId == null
                      ? '--'
                      : _padLabel(i18n, _lastHitId!),
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '娆℃暟',
                    en: 'Count',
                    ja: '鍥炴暟',
                    de: 'Anzahl',
                    fr: 'Compteur',
                    es: 'Conteo',
                    ru: '小褔褢褌',
                  ),
                  value: '$_hits',
                ),
                ToolboxMetricCard(
                  label: pickUiText(
                    i18n,
                    zh: '棰勮',
                    en: 'Preset',
                    ja'',
                    de: 'Preset',
                    fr: 'Pr茅r茅glage',
                    es: 'Preajuste',
                    ru: '袩褉械褋械褌',
                  ),
                  value: _presetLabel(i18n, preset),
                ),
                OutlinedButton.icon(
                  onPressed: _openFullScreen,
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(pickUiText(i18n, zh: '鍏ㄥ睆', en: 'Full screen')),
                ),
                OutlinedButton.icon(
                  onPressed: _showDrumTutorial,
                  icon: const Icon(Icons.school_rounded),
                  label: Text(pickUiText(i18n, zh: '鏁欑▼', en: 'Tutorial')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionHeader(
              title: pickUiText(
                i18n,
                zh'',
                en: 'Preset pack',
                ja: '銉椼儶銈汇儍銉堛儜銉冦偗',
                de: 'Preset-Paket',
                fr: 'Pack de pr茅r茅glages',
                es: 'Paquete de presets',
                ru: '袩邪泻械褌 锌褉械褋械褌芯胁',
              ),
              subtitle: pickUiText(
                i18n,
                zh'',
                en: 'Switch kit type and default impact drive together.',
                ja'',
                de: 'Wechselt Kit-Typ und Standard-Drive gemeinsam.',
                fr: 'Changez le type de kit et le drive d鈥檌mpact par d茅faut.',
                es: 'Cambia el kit y el nivel de impacto por defecto.',
                ru: '袩械褉械泻谢褞褔邪械褌 褌懈锌 薪邪斜芯褉邪 懈 褋懈谢褍 褍写邪褉邪 锌芯 褍屑芯谢褔邪薪懈褞.',
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
                zh: '鍐插嚮鍔涘害 ${(_drive * 100).round()}%',
                en: 'Drive ${(_drive * 100).round()}%',
                ja: '銉夈儵銈ゃ儢 ${(_drive * 100).round()}%',
                de: 'Drive ${(_drive * 100).round()}%',
                fr: 'Drive ${(_drive * 100).round()}%',
                es: 'Drive ${(_drive * 100).round()}%',
                ru: '袛褉邪泄胁 ${(_drive * 100).round()}%',
              ),
            ),
            Slider(
              value: _drive,
              min: 0.45,
              max: 1.0,
              divisions: 11,
              onChanged: (value) => setState(() => _drive = value),
            ),
            Text(pickUiText(i18n, zh: '闊宠壊 ${(_tone * 100).round()}%', en: 'Tone ${(_tone * 100).round()}%')),
            Slider(
              value: _tone,
              min: 0,
              max: 1,
              divisions: 20,
              onChanged: (value) {
                setState(() => _tone = value);
                _invalidatePlayers();
              },
            ),
            Text(pickUiText(i18n, zh: '灏鹃煶 ${(_tail * 100).round()}%', en: 'Tail ${(_tail * 100).round()}%')),
            Slider(
              value: _tail,
              min: 0,
              max: 1,
              divisions: 20,
              onChanged: (value) {
                setState(() => _tail = value);
                _invalidatePlayers();
              },
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <String>['wood', 'metal', 'hybrid']
                  .map(
                    (material) => ChoiceChip(
                      label: Text(material),
                      selected: _material == material,
                      onSelected: (_) {
                        setState(() => _material = material);
                        _invalidatePlayers();
                      },
                    ),
                  )
                  .toList(growable: false),
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
        );
    return _wrapInstrumentPanel(fullScreen: widget.fullScreen, child: content);
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
  double _resonance = 0.56;
  double _pickPosition = 0.55;
  int? _lastSweepString;

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
        zh: '灏奸緳鎸囧脊',
        en: 'Nylon finger',
        ja'',
        de: 'Nylon Fingerstyle',
        fr: 'Nylon finger',
        es: 'Nailon finger',
        ru: '袧械泄谢芯薪 褎懈薪谐械褉',
      ),
      'ambient_chime' => pickUiText(
        i18n,
        zh: '姘涘洿閾冮煶',
        en: 'Ambient chime',
        ja: '銈兂銉撱偍銉炽儓銉併儯銈ゃ儬',
        de: 'Ambient Chime',
        fr: 'Ambient chime',
        es: 'Ambient chime',
        ru: 'Ambient chime',
      ),
      _ => pickUiText(
        i18n,
        zh: '閽㈠鸡鎵鸡',
        en: 'Steel strum',
        ja: '銈广儊銉笺儷銈广儓銉┿儬',
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
        zh'',
        en: 'Round and soft tone for slow arpeggios and finger picking.',
        ja'',
        de: 'Runder, weicher Klang f眉r langsame Arpeggios und Fingerpicking.',
        fr: 'Timbre rond et doux pour arp猫ges lents et fingerstyle.',
        es: 'Tono redondo y suave para arpegios lentos y fingerpicking.',
        ru: '袦褟谐泻懈泄 芯泻褉褍谐谢褘泄 褌械屑斜褉 写谢褟 屑械写谢械薪薪褘褏 邪褉锌械写卸懈芯 懈 褎懈薪谐械褉褋褌邪泄谢邪.',
      ),
      'ambient_chime' => pickUiText(
        i18n,
        zh'',
        en: 'Airier overtones and longer shimmer for ambient layers.',
        ja'',
        de: 'Luftigere Obert枚ne mit l盲ngerem Schimmer f眉r Ambient-Fl盲chen.',
        fr: 'Harmoniques a茅riennes et r茅sonance longue pour l鈥檃mbient.',
        es: 'Arm贸nicos m谩s a茅reos y cola larga para capas ambient.',
        ru: '袘芯谢械械 胁芯蟹写褍褕薪褘械 芯斜械褉褌芯薪褘 懈 写谢懈薪薪褘泄 褕懈屑械褉 写谢褟 ambient-锌芯写谢芯卸泻懈.',
      ),
      _ => pickUiText(
        i18n,
        zh'',
        en: 'Clear steel-core tone tuned for rhythmic strumming.',
        ja'',
        de: 'Klarer Steel-Kernklang f眉r rhythmisches Strumming.',
        fr: 'Noyau acier net, id茅al pour le strumming rythmique.',
        es: 'N煤cleo claro de acero, ideal para rasgueo r铆tmico.',
        ru: '效褢褌泻懈泄 褋褌邪谢褜薪芯泄 褌芯薪, 薪邪褋褌褉芯械薪薪褘泄 锌芯写 褉懈褌屑懈褔械褋泻懈泄 斜芯泄.',
      ),
    };
  }

  String _styleLabel(AppI18n i18n, String styleId) {
    return switch (styleId) {
      'nylon' => pickUiText(
        i18n,
        zh: '灏奸緳',
        en: 'Nylon',
        ja: '銉娿偆銉兂',
        de: 'Nylon',
        fr: 'Nylon',
        es: 'Nailon',
        ru: '袧械泄谢芯薪',
      ),
      'ambient' => pickUiText(
        i18n,
        zh: '姘涘洿',
        en: 'Ambient',
        ja: '銈兂銉撱偍銉炽儓',
        de: 'Ambient',
        fr: 'Ambient',
        es: 'Ambient',
        ru: 'Ambient',
      ),
      _ => pickUiText(
        i18n,
        zh: '閽㈠鸡',
        en: 'Steel',
        ja: '銈广儊銉笺儷',
        de: 'Steel',
        fr: 'Acier',
        es: 'Acero',
        ru: '小褌邪谢褜',
      ),
    };
  }

  void _applyPreset(String presetId) {
    if (_presetId == presetId) return;
    setState(() {
      _presetId = presetId;
      if (presetId == 'nylon_finger') {
        _resonance = 0.44;
        _pickPosition = 0.68;
      } else if (presetId == 'ambient_chime') {
        _resonance = 0.72;
        _pickPosition = 0.38;
      } else {
        _resonance = 0.56;
        _pickPosition = 0.55;
      }
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
  }

  Future<void> _warmUpActivePreset() async {
    for (final note in _strings) {
      await _playerFor(note).warmUp();
    }
  }

  ToolboxEffectPlayer _playerFor(_PianoKey note) {
    final key =
        '${note.id}:${_activePreset.styleId}:${_resonance.toStringAsFixed(2)}:${_pickPosition.toStringAsFixed(2)}';
    final existing = _players[key];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.guitarNote(
        note.frequency,
        style: _activePreset.styleId,
        resonance: _resonance,
        pickPosition: _pickPosition,
      ),
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

  int _stringIndexFromDy(double dy, double boardHeight) {
    final laneHeight = boardHeight / _strings.length;
    final raw = (dy / laneHeight).floor();
    return raw.clamp(0, _strings.length - 1);
  }

  void _handleSweepPluck(
    double dy,
    double boardHeight, {
    required bool initial,
  }) {
    final index = _stringIndexFromDy(dy, boardHeight);
    if (!initial && index == _lastSweepString) return;
    _lastSweepString = index;
    unawaited(
      _pluck(
        index,
        volume: initial ? _activePreset.pluckVolume : _activePreset.strumVolume,
      ),
    );
  }

  void _openFullScreen() {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const _DeckInstrumentFullScreenPage(instrument: _HarpDeckInstrument.guitar),
      ),
    );
  }

  void _showGuitarTutorial() {
    _showInstrumentTutorialDialog(
      context: context,
      titleZh'',
      titleEn: 'Guitar Quick Tutorial',
      steps: const <_TutorialStep>[
        _TutorialStep(
          zh'',
          en: 'Tap a single string for pitch; use up/down strum for chord rhythm.',
        ),
        _TutorialStep(
          zh'',
          en: 'Resonance and pick position directly reshape brightness and grain.',
        ),
        _TutorialStep(
          zh'',
          en: 'On small screens, tap near the string middle for higher hit accuracy.',
        ),
      ],
    );
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
    final compact = MediaQuery.sizeOf(context).shortestSide < 360;
    final laneHeight = widget.fullScreen ? 54.0 : (compact ? 46.0 : 42.0);
    final boardHeight = laneHeight * _strings.length;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '琴弦', en: 'Strings'),
              value: '${_strings.length}',
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '预设', en: 'Preset'),
              value: _presetLabel(i18n, preset),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '音色', en: 'Tone'),
              value: _styleLabel(i18n, preset.styleId),
            ),
            OutlinedButton.icon(
              onPressed: _openFullScreen,
              icon: const Icon(Icons.open_in_full_rounded),
              label: Text(pickUiText(i18n, zh: '全屏', en: 'Full screen')),
            ),
            OutlinedButton.icon(
              onPressed: _showGuitarTutorial,
              icon: const Icon(Icons.school_rounded),
              label: Text(pickUiText(i18n, zh: '教程', en: 'Tutorial')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SectionHeader(
          title: pickUiText(i18n, zh: '预设包', en: 'Preset pack'),
          subtitle: pickUiText(
            i18n,
            zh: '预设会联动琴弦材质、触弦力度和扫弦速度。',
            en: 'Each preset combines string material, touch response, and strum speed.',
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
        Text(_presetSubtitle(i18n, preset), style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        Text(
          pickUiText(
            i18n,
            zh: '共鸣 ${(_resonance * 100).round()}%',
            en: 'Resonance ${(_resonance * 100).round()}%',
          ),
        ),
        Slider(
          value: _resonance,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (value) {
            setState(() => _resonance = value);
            _invalidatePlayers();
          },
        ),
        Text(
          pickUiText(
            i18n,
            zh: '拨弦位置 ${(_pickPosition * 100).round()}%',
            en: 'Pick position ${(_pickPosition * 100).round()}%',
          ),
        ),
        Slider(
          value: _pickPosition,
          min: 0.05,
          max: 0.95,
          divisions: 18,
          onChanged: (value) {
            setState(() => _pickPosition = value);
            _invalidatePlayers();
          },
        ),
        const SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFF6E7C8), Color(0xFFEBCF9A)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => _handleSweepPluck(
                  event.localPosition.dy,
                  boardHeight,
                  initial: true,
                ),
                onPointerMove: (event) => _handleSweepPluck(
                  event.localPosition.dy,
                  boardHeight,
                  initial: false,
                ),
                onPointerUp: (_) => _lastSweepString = null,
                onPointerCancel: (_) => _lastSweepString = null,
                child: SizedBox(
                  height: boardHeight,
                  child: Column(
                    children: List<Widget>.generate(_strings.length, (index) {
                      final active = _activeString == index;
                      final note = _strings[index];
                      return Container(
                        height: laneHeight,
                        margin: const EdgeInsets.symmetric(vertical: 1.2),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: compact ? 24 : 30,
                              child: Text(
                                note.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: compact ? 11 : null,
                                  color: const Color(0xFF5A3818),
                                ),
                              ),
                            ),
                            SizedBox(width: compact ? 6 : 8),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 90),
                                height: active ? 4.2 : 2.8,
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
                      );
                    }),
                  ),
                ),
              );
            },
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
              label: Text(pickUiText(i18n, zh: '下扫弦', en: 'Strum down')),
            ),
            FilledButton.tonalIcon(
              onPressed: () => unawaited(_strum(down: false)),
              icon: const Icon(Icons.north_rounded),
              label: Text(pickUiText(i18n, zh: '上扫弦', en: 'Strum up')),
            ),
          ],
        ),
      ],
    );
    return _wrapInstrumentPanel(fullScreen: widget.fullScreen, child: content);
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
  String _material = 'steel';
  double _strike = 0.65;
  double _damping = 0.2;

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
      'soft_ring' => pickUiText(i18n, zh: '柔和振铃', en: 'Soft ring'),
      'bright_ring' => pickUiText(i18n, zh: '明亮振铃', en: 'Bright ring'),
      _ => pickUiText(i18n, zh: '管弦振铃', en: 'Orchestral ring'),
    };
  }

  String _presetSubtitle(AppI18n i18n, _TrianglePreset preset) {
    return switch (preset.id) {
      'soft_ring' => pickUiText(
        i18n,
        zh: '高频更柔和，余音更短，适合轻节奏。',
        en: 'Softer highs with shorter decay for gentle rhythm support.',
      ),
      'bright_ring' => pickUiText(
        i18n,
        zh: '起音更亮更脆，强调拍点更明显。',
        en: 'Brighter attack with stronger ring for accents.',
      ),
      _ => pickUiText(
        i18n,
        zh: '明亮与衰减均衡，接近管弦乐中的三角铁。',
        en: 'Balanced brightness and decay close to orchestral behavior.',
      ),
    };
  }

  String _materialLabel(AppI18n i18n, String material) {
    return switch (material) {
      'brass' => pickUiText(i18n, zh: '黄铜', en: 'Brass'),
      'aluminum' => pickUiText(i18n, zh: '铝', en: 'Aluminum'),
      _ => pickUiText(i18n, zh: '钢', en: 'Steel'),
    };
  }

  ToolboxEffectPlayer _playerFor(String styleId) {
    final cacheKey =
        '$styleId:$_material:${_strike.toStringAsFixed(2)}:${_damping.toStringAsFixed(2)}';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.triangleHit(
        style: styleId,
        material: _material,
        strike: _strike,
        damping: _damping,
      ),
      maxPlayers: 6,
    );
    _players[cacheKey] = created;
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
      switch (preset.id) {
        case 'soft_ring':
          _material = 'aluminum';
          _strike = 0.48;
          _damping = 0.38;
          break;
        case 'bright_ring':
          _material = 'steel';
          _strike = 0.82;
          _damping = 0.16;
          break;
        default:
          _material = 'brass';
          _strike = 0.66;
          _damping = 0.24;
          break;
      }
    });
    _disposePlayers();
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

  void _openFullScreen() {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _DeckInstrumentFullScreenPage(
          instrument: _HarpDeckInstrument.triangle,
        ),
      ),
    );
  }

  void _showTriangleTutorial() {
    _showInstrumentTutorialDialog(
      context: context,
      titleZh: '三角铁快速教程',
      titleEn: 'Triangle Quick Tutorial',
      steps: const <_TutorialStep>[
        _TutorialStep(
          zh: '先选预设，再调节材质、击打力度和阻尼，找到目标质感。',
          en: 'Start with a preset, then tune material, strike, and damping.',
        ),
        _TutorialStep(
          zh: '小屏建议点中三角铁边缘附近，命中更稳定。',
          en: 'On small screens, tapping near the triangle edge is more reliable.',
        ),
        _TutorialStep(
          zh: '振铃控制整体余音量感，阻尼控制余音衰减速度。',
          en: 'Ring controls tail energy; damping controls tail decay speed.',
        ),
      ],
    );
  }

  Future<void> _strike({double force = 1.0}) async {
    HapticFeedback.lightImpact();
    final effective = force.clamp(0.4, 1.0);
    unawaited(
      _playerFor(_activePreset.styleId).play(
        volume: (_ring * effective).clamp(0.18, 1.0),
      ),
    );
    if (!mounted) return;
    setState(() {
      _hits += 1;
      _flash = effective;
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
    final compact = MediaQuery.sizeOf(context).shortestSide < 360;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '击打', en: 'Hits'),
              value: '$_hits',
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '振铃', en: 'Ring'),
              value: '${(_ring * 100).round()}%',
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '预设', en: 'Preset'),
              value: _presetLabel(i18n, preset),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '材质', en: 'Material'),
              value: _materialLabel(i18n, _material),
            ),
            OutlinedButton.icon(
              onPressed: _openFullScreen,
              icon: const Icon(Icons.open_in_full_rounded),
              label: Text(pickUiText(i18n, zh: '全屏', en: 'Full screen')),
            ),
            OutlinedButton.icon(
              onPressed: _showTriangleTutorial,
              icon: const Icon(Icons.school_rounded),
              label: Text(pickUiText(i18n, zh: '教程', en: 'Tutorial')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionHeader(
          title: pickUiText(i18n, zh: '预设包', en: 'Preset pack'),
          subtitle: pickUiText(
            i18n,
            zh: '预设会联动音色和默认振铃长度，适合快速切换表现。',
            en: 'Presets switch tone and default ring length together.',
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
            zh: '振铃 ${(_ring * 100).round()}%',
            en: 'Ring ${(_ring * 100).round()}%',
          ),
        ),
        Slider(
          value: _ring,
          min: 0.2,
          max: 1.0,
          divisions: 16,
          onChanged: (value) => setState(() => _ring = value),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '击打力度 ${(_strike * 100).round()}%',
            en: 'Strike ${(_strike * 100).round()}%',
          ),
        ),
        Slider(
          value: _strike,
          min: 0.1,
          max: 1.0,
          divisions: 18,
          onChanged: (value) {
            setState(() => _strike = value);
            _disposePlayers();
          },
        ),
        Text(
          pickUiText(
            i18n,
            zh: '阻尼 ${(_damping * 100).round()}%',
            en: 'Damping ${(_damping * 100).round()}%',
          ),
        ),
        Slider(
          value: _damping,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (value) {
            setState(() => _damping = value);
            _disposePlayers();
          },
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <String>['steel', 'brass', 'aluminum']
              .map(
                (material) => ChoiceChip(
                  label: Text(_materialLabel(i18n, material)),
                  selected: _material == material,
                  onSelected: (_) {
                    setState(() => _material = material);
                    _disposePlayers();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            final maxWidth = (box?.size.width ?? 320).clamp(1, double.infinity);
            final force = (details.localPosition.dx / maxWidth).clamp(0.4, 1.0);
            unawaited(_strike(force: force));
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: widget.fullScreen ? 280 : (compact ? 196 : 220),
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
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => unawaited(_strike()),
          icon: const Icon(Icons.music_video_rounded),
          label: Text(pickUiText(i18n, zh: '敲击三角铁', en: 'Strike triangle')),
        ),
      ],
    );
    return _wrapInstrumentPanel(fullScreen: widget.fullScreen, child: content);
  }
}

class _GuqinTool extends StatefulWidget {
  const _GuqinTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_GuqinTool> createState() => _GuqinToolState();
}

class _GuqinToolState extends State<_GuqinTool> {
  static const List<_PianoKey> _strings = <_PianoKey>[
    _PianoKey(id: 'S1', label: '1', frequency: 98.0),
    _PianoKey(id: 'S2', label: '2', frequency: 110.0),
    _PianoKey(id: 'S3', label: '3', frequency: 130.81),
    _PianoKey(id: 'S4', label: '4', frequency: 146.83),
    _PianoKey(id: 'S5', label: '5', frequency: 164.81),
    _PianoKey(id: 'S6', label: '6', frequency: 196.0),
    _PianoKey(id: 'S7', label: '7', frequency: 220.0),
  ];

  static const List<_GuqinPreset> _presets = <_GuqinPreset>[
    _GuqinPreset(
      id: 'silk_classic',
      styleId: 'silk',
      resonance: 0.62,
      slide: 0.08,
    ),
    _GuqinPreset(
      id: 'bright_stage',
      styleId: 'bright',
      resonance: 0.7,
      slide: 0.18,
    ),
    _GuqinPreset(
      id: 'hollow_meditation',
      styleId: 'hollow',
      resonance: 0.82,
      slide: -0.06,
    ),
  ];

  static const List<_GuqinTechniqueSeed> _lessonSeeds =
      <_GuqinTechniqueSeed>[
        _GuqinTechniqueSeed(
          id: 'jianzipu',
          titleZh: '简字谱识读',
          titleEn: 'Jianzipu Reading',
          focusZh: '认识减字谱结构和指法符号的基本组合。',
          focusEn: 'Read core jianzipu symbols and phrase structure.',
        ),
        _GuqinTechniqueSeed(
          id: 'gou',
          titleZh: '勾',
          titleEn: 'Gou',
          focusZh: '食指向内勾弦，保证起音清晰。',
          focusEn: 'Inward index pluck with clean attack.',
        ),
        _GuqinTechniqueSeed(
          id: 'tiao',
          titleZh: '挑',
          titleEn: 'Tiao',
          focusZh: '拇指外挑保持均匀力度。',
          focusEn: 'Outward thumb pluck with stable force.',
        ),
        _GuqinTechniqueSeed(
          id: 'ti',
          titleZh: '剔',
          titleEn: 'Ti',
          focusZh: '连续剔弦控制颗粒感和节奏。',
          focusEn: 'Repeated ti strokes with rhythmic clarity.',
        ),
        _GuqinTechniqueSeed(
          id: 'mo',
          titleZh: '抹',
          titleEn: 'Mo',
          focusZh: '向内抹弦的方向与速度统一。',
          focusEn: 'Inward mo stroke with controlled speed.',
        ),
        _GuqinTechniqueSeed(
          id: 'tuo',
          titleZh: '托',
          titleEn: 'Tuo',
          focusZh: '托弦时保持手腕放松和音头圆润。',
          focusEn: 'Relaxed wrist for rounded tuo articulation.',
        ),
        _GuqinTechniqueSeed(
          id: 'da_yuan',
          titleZh: '打圆',
          titleEn: 'Da Yuan',
          focusZh: '右手圆运动保持连贯音流。',
          focusEn: 'Circular hand motion for fluid tone flow.',
        ),
        _GuqinTechniqueSeed(
          id: 'cuo',
          titleZh: '撮',
          titleEn: 'Cuo',
          focusZh: '双弦撮音对齐时间与力度。',
          focusEn: 'Dual-string cuo timing and balance.',
        ),
        _GuqinTechniqueSeed(
          id: 'lun_zhi',
          titleZh: '轮指',
          titleEn: 'Lun Zhi',
          focusZh: '轮指均匀轮替，避免音量突变。',
          focusEn: 'Even alternating fingers in rolling strokes.',
        ),
        _GuqinTechniqueSeed(
          id: 'chang_suo',
          titleZh: '长锁',
          titleEn: 'Chang Suo',
          focusZh: '长锁保持线条持续与层次。',
          focusEn: 'Sustained long-lock phrasing control.',
        ),
        _GuqinTechniqueSeed(
          id: 'duan_suo',
          titleZh: '短锁',
          titleEn: 'Duan Suo',
          focusZh: '短锁强调断句与颗粒节奏。',
          focusEn: 'Short-lock articulation with crisp phrasing.',
        ),
        _GuqinTechniqueSeed(
          id: 'gui_zhi',
          titleZh: '跪指',
          titleEn: 'Gui Zhi',
          focusZh: '跪指换位时保持音高稳定。',
          focusEn: 'Intonation stability in gui-zhi shifts.',
        ),
        _GuqinTechniqueSeed(
          id: 'yin',
          titleZh: '吟',
          titleEn: 'Yin',
          focusZh: '细腻吟揉塑造气口与语气。',
          focusEn: 'Subtle vibrato phrasing with yin.',
        ),
        _GuqinTechniqueSeed(
          id: 'nao',
          titleZh: '猱',
          titleEn: 'Nao',
          focusZh: '猱的宽度与频率需可控。',
          focusEn: 'Control nao width and modulation speed.',
        ),
        _GuqinTechniqueSeed(
          id: 'chuo',
          titleZh: '绰',
          titleEn: 'Chuo',
          focusZh: '上滑绰音保持连贯过渡。',
          focusEn: 'Smooth upward slide in chuo motion.',
        ),
        _GuqinTechniqueSeed(
          id: 'zhu',
          titleZh: '注',
          titleEn: 'Zhu',
          focusZh: '下注回归准确落点。',
          focusEn: 'Precise return pitch in zhu descent.',
        ),
        _GuqinTechniqueSeed(
          id: 'hua_yin',
          titleZh: '滑音',
          titleEn: 'Hua Yin',
          focusZh: '滑音衔接句子并避免噪声。',
          focusEn: 'Connect phrases with clean slides.',
        ),
        _GuqinTechniqueSeed(
          id: 'dai_qi',
          titleZh: '带起',
          titleEn: 'Dai Qi',
          focusZh: '带起动作需要提前准备手位。',
          focusEn: 'Prepare hand position before lift-off.',
        ),
        _GuqinTechniqueSeed(
          id: 'fan_yin',
          titleZh: '泛音定位',
          titleEn: 'Harmonic Positioning',
          focusZh: '徽位触弦点与力度的精确配合。',
          focusEn: 'Accurate harmonic nodes and touch force.',
        ),
        _GuqinTechniqueSeed(
          id: 'san_yin',
          titleZh: '散音发力',
          titleEn: 'Open String Attack',
          focusZh: '散音强调音头和共鸣长度。',
          focusEn: 'Open-string attack and resonance shaping.',
        ),
        _GuqinTechniqueSeed(
          id: 'an_yin',
          titleZh: '按音落弦',
          titleEn: 'Stopped Notes',
          focusZh: '按音压弦深度与音准协同。',
          focusEn: 'Finger pressure and intonation in stopped notes.',
        ),
        _GuqinTechniqueSeed(
          id: 'huan_ba',
          titleZh: '换把',
          titleEn: 'Position Shift',
          focusZh: '换把过程保持旋律线不断裂。',
          focusEn: 'Maintain line continuity across shifts.',
        ),
        _GuqinTechniqueSeed(
          id: 'zou_shou',
          titleZh: '走手串联',
          titleEn: 'Hand Transitions',
          focusZh: '左右手接力时保持节拍平稳。',
          focusEn: 'Stable pulse in hand-to-hand transitions.',
        ),
        _GuqinTechniqueSeed(
          id: 'shuang_sheng',
          titleZh: '双声',
          titleEn: 'Double Stops',
          focusZh: '双声平衡主次音量。',
          focusEn: 'Balance voice-leading in double stops.',
        ),
        _GuqinTechniqueSeed(
          id: 'die_yin',
          titleZh: '叠音',
          titleEn: 'Layered Tone',
          focusZh: '叠音层次避免浑浊。',
          focusEn: 'Keep layered tones clear, not muddy.',
        ),
        _GuqinTechniqueSeed(
          id: 'gun_fu',
          titleZh: '滚拂',
          titleEn: 'Gun/Fu',
          focusZh: '滚拂需保持连续方向感。',
          focusEn: 'Directional consistency in rolling sweeps.',
        ),
        _GuqinTechniqueSeed(
          id: 'yao_zhi',
          titleZh: '摇指',
          titleEn: 'Yao Zhi',
          focusZh: '摇指保持速度均匀和手指放松。',
          focusEn: 'Even-speed tremolo with relaxed fingers.',
        ),
        _GuqinTechniqueSeed(
          id: 'hui_wei',
          titleZh: '琴徽定位',
          titleEn: 'Hui Positioning',
          focusZh: '熟悉各徽位的音高映射。',
          focusEn: 'Map hui positions to stable pitch memory.',
        ),
        _GuqinTechniqueSeed(
          id: 'jie_pai',
          titleZh: '节拍分组',
          titleEn: 'Beat Grouping',
          focusZh: '复杂节拍中的重音分组。',
          focusEn: 'Accent grouping in compound rhythm.',
        ),
        _GuqinTechniqueSeed(
          id: 'qi_xi',
          titleZh: '句息控制',
          titleEn: 'Phrase Breathing',
          focusZh: '句末换气与力度回收。',
          focusEn: 'Phrase-end breath and dynamic release.',
        ),
        _GuqinTechniqueSeed(
          id: 'you_shou_junheng',
          titleZh: '右手均衡',
          titleEn: 'Right Hand Balance',
          focusZh: '不同指法切换时音量一致。',
          focusEn: 'Consistent volume across right-hand patterns.',
        ),
        _GuqinTechniqueSeed(
          id: 'zuo_shou_wending',
          titleZh: '左手稳定',
          titleEn: 'Left Hand Stability',
          focusZh: '按滑过程中减少多余位移。',
          focusEn: 'Minimize extra movement in left-hand slides.',
        ),
        _GuqinTechniqueSeed(
          id: 'lian_tuo_mo',
          titleZh: '连托连抹',
          titleEn: 'Linked Tuo/Mo',
          focusZh: '托抹连奏的衔接顺滑度。',
          focusEn: 'Smooth legato connection of tuo and mo.',
        ),
        _GuqinTechniqueSeed(
          id: 'fuhe_jiezou',
          titleZh: '复合节奏',
          titleEn: 'Polyrhythm',
          focusZh: '复合节奏中内在拍点保持稳定。',
          focusEn: 'Internal pulse control in mixed rhythm.',
        ),
        _GuqinTechniqueSeed(
          id: 'changju_kongzhi',
          titleZh: '长句控制',
          titleEn: 'Long Phrase Control',
          focusZh: '长句强弱起伏与呼吸规划。',
          focusEn: 'Dynamic contour planning for long phrases.',
        ),
        _GuqinTechniqueSeed(
          id: 'tai_feng',
          titleZh: '舞台演绎',
          titleEn: 'Stage Interpretation',
          focusZh: '演奏姿态、触弦稳定与表现一致。',
          focusEn: 'Performance posture and expressive consistency.',
        ),
      ];

  static List<_GuqinLesson> _buildLessons() {
    const levels = <String>['beginner', 'intermediate', 'advanced'];
    final lessons = <_GuqinLesson>[];
    var order = 1;
    for (final seed in _lessonSeeds) {
      for (final level in levels) {
        final stageZh = switch (level) {
          'beginner' => '初级',
          'intermediate' => '中级',
          _ => '高级',
        };
        final stageEn = switch (level) {
          'beginner' => 'Beginner',
          'intermediate' => 'Intermediate',
          _ => 'Advanced',
        };
        final summaryZh = switch (level) {
          'beginner' => '建立基础动作和节拍稳定。${seed.focusZh}',
          'intermediate' => '结合换把与句法连贯。${seed.focusZh}',
          _ => '面向乐句表达与舞台可用性。${seed.focusZh}',
        };
        final summaryEn = switch (level) {
          'beginner' => 'Build core motion and pulse stability. ${seed.focusEn}',
          'intermediate' =>
            'Integrate shifting and phrase continuity. ${seed.focusEn}',
          _ => 'Focus on expression and stage-ready reliability. ${seed.focusEn}',
        };
        lessons.add(
          _GuqinLesson(
            id: order.toString().padLeft(3, '0'),
            level: level,
            title: '${seed.titleZh} (${seed.titleEn}) · $stageZh/$stageEn',
            summary: '$summaryZh\n$summaryEn',
          ),
        );
        order += 1;
      }
    }
    return lessons;
  }

  static final List<_GuqinLesson> _lessons = _buildLessons();

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  final TextEditingController _lessonQueryController = TextEditingController();
  String _presetId = _presets.first.id;
  String _style = _presets.first.styleId;
  double _resonance = _presets.first.resonance;
  double _slide = _presets.first.slide;
  String _lessonLevel = 'all';
  String _lessonQuery = '';
  int? _activeString;
  int? _lastSweepString;
  String? _lastNote;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _GuqinPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _GuqinPreset preset) {
    return switch (preset.id) {
      'bright_stage' => pickUiText(i18n, zh: '明亮舞台', en: 'Bright stage'),
      'hollow_meditation' =>
        pickUiText(i18n, zh: '空谷冥想', en: 'Hollow meditation'),
      _ => pickUiText(i18n, zh: '丝弦古韵', en: 'Silk classic'),
    };
  }

  String _presetSubtitle(AppI18n i18n, _GuqinPreset preset) {
    return switch (preset.id) {
      'bright_stage' => pickUiText(
        i18n,
        zh: '更亮的音头与更强存在感，适合主旋律。',
        en: 'Brighter attack and stronger presence for lead lines.',
      ),
      'hollow_meditation' => pickUiText(
        i18n,
        zh: '空灵共鸣和更长余韵，适合静态氛围。',
        en: 'Hollow resonance with longer decay for meditative mood.',
      ),
      _ => pickUiText(
        i18n,
        zh: '平衡散音、按音与滑音表现，接近传统古琴手感。',
        en: 'Balanced open, stopped, and slide behavior with guqin-like feel.',
      ),
    };
  }

  String _styleLabel(AppI18n i18n, String style) {
    return switch (style) {
      'bright' => pickUiText(i18n, zh: '明亮', en: 'Bright'),
      'hollow' => pickUiText(i18n, zh: '空谷', en: 'Hollow'),
      _ => pickUiText(i18n, zh: '丝弦', en: 'Silk'),
    };
  }

  String _levelLabel(AppI18n i18n, String level) {
    return switch (level) {
      'beginner' => pickUiText(i18n, zh: '初级', en: 'Beginner'),
      'intermediate' => pickUiText(i18n, zh: '中级', en: 'Intermediate'),
      'advanced' => pickUiText(i18n, zh: '高级', en: 'Advanced'),
      _ => pickUiText(i18n, zh: '全部', en: 'All'),
    };
  }

  List<_GuqinLesson> get _filteredLessons {
    final query = _lessonQuery.trim().toLowerCase();
    return _lessons.where((lesson) {
      final levelOk = _lessonLevel == 'all' || lesson.level == _lessonLevel;
      if (!levelOk) return false;
      if (query.isEmpty) return true;
      final haystack = '${lesson.title}\n${lesson.summary}'.toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
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
      _style = preset.styleId;
      _resonance = preset.resonance;
      _slide = preset.slide;
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
  }

  Future<void> _warmUpActivePreset() async {
    for (final note in _strings) {
      await _playerFor(note, slide: _slide).warmUp();
    }
  }

  ToolboxEffectPlayer _playerFor(_PianoKey note, {required double slide}) {
    final quantizedSlide = ((slide.clamp(-1.0, 1.0)) * 10).round() / 10;
    final key =
        '${note.id}:$_style:${_resonance.toStringAsFixed(2)}:${quantizedSlide.toStringAsFixed(1)}';
    final existing = _players[key];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.guqinNote(
        note.frequency,
        style: _style,
        resonance: _resonance,
        slide: quantizedSlide.toDouble(),
      ),
      maxPlayers: 8,
    );
    _players[key] = created;
    return created;
  }

  Future<void> _playString(
    int index, {
    required double strength,
    double slideOffset = 0,
  }) async {
    if (index < 0 || index >= _strings.length) return;
    final note = _strings[index];
    final effectiveSlide = (_slide + slideOffset).clamp(-1.0, 1.0).toDouble();
    final volume = (0.18 + strength.clamp(0.12, 1.0) * 0.78).clamp(0.18, 1.0);
    HapticFeedback.selectionClick();
    unawaited(_playerFor(note, slide: effectiveSlide).play(volume: volume));
    if (!mounted) return;
    setState(() {
      _activeString = index;
      _lastNote = 'S${index + 1}';
    });
    Future<void>.delayed(const Duration(milliseconds: 110), () {
      if (!mounted || _activeString != index) return;
      setState(() => _activeString = null);
    });
  }

  int _stringIndexFromDy(double dy, double boardHeight) {
    final laneHeight = boardHeight / _strings.length;
    final raw = (dy / laneHeight).floor();
    return raw.clamp(0, _strings.length - 1);
  }

  void _handleSweepPluck(
    Offset localPosition,
    Size size, {
    required bool initial,
  }) {
    final index = _stringIndexFromDy(localPosition.dy, size.height);
    if (!initial && index == _lastSweepString) return;
    _lastSweepString = index;
    final normalizedX = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final strength = (0.22 + normalizedX * 0.78).clamp(0.12, 1.0);
    final slideOffset = (normalizedX - 0.5) * 0.45;
    unawaited(
      _playString(
        index,
        strength: strength,
        slideOffset: initial ? 0 : slideOffset,
      ),
    );
  }

  void _openFullScreen() {
    if (widget.fullScreen) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const _DeckInstrumentFullScreenPage(instrument: _HarpDeckInstrument.guqin),
      ),
    );
  }

  void _showGuqinTutorial() {
    _showInstrumentTutorialDialog(
      context: context,
      titleZh: '古琴快速教程',
      titleEn: 'Guqin Quick Tutorial',
      steps: const <_TutorialStep>[
        _TutorialStep(
          zh: '先用丝弦古韵预设熟悉七弦，再切换明亮或空谷风格。',
          en: 'Start with Silk Classic to learn the 7 strings, then switch styles.',
        ),
        _TutorialStep(
          zh: '沿弦方向拖动会触发连续扫弦并改变力度和滑音感。',
          en: 'Dragging across strings triggers sweep plucks with dynamic intensity.',
        ),
        _TutorialStep(
          zh: '教程区提供 108 条分级指法文案，可按级别和关键字筛选。',
          en: 'Use the 108 graded lessons and filter by level or keyword.',
        ),
      ],
    );
  }

  void _openLessonDialog(_GuqinLesson lesson) {
    final i18n = _toolboxI18n(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.62,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${lesson.id}. ${lesson.title}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Chip(label: Text(_levelLabel(i18n, lesson.level))),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        lesson.summary,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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

  @override
  void dispose() {
    _lessonQueryController.dispose();
    _invalidatePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final preset = _activePreset;
    final compact = MediaQuery.sizeOf(context).shortestSide < 360;
    final laneHeight = widget.fullScreen ? 58.0 : (compact ? 46.0 : 50.0);
    final boardHeight = laneHeight * _strings.length;
    final filteredLessons = _filteredLessons;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '琴弦', en: 'Strings'),
              value: '${_strings.length}',
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '预设', en: 'Preset'),
              value: _presetLabel(i18n, preset),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '音色', en: 'Tone'),
              value: _styleLabel(i18n, _style),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '最近', en: 'Last'),
              value: _lastNote ?? '--',
            ),
            OutlinedButton.icon(
              onPressed: _openFullScreen,
              icon: const Icon(Icons.open_in_full_rounded),
              label: Text(pickUiText(i18n, zh: '全屏', en: 'Full screen')),
            ),
            OutlinedButton.icon(
              onPressed: _showGuqinTutorial,
              icon: const Icon(Icons.school_rounded),
              label: Text(pickUiText(i18n, zh: '教程', en: 'Tutorial')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SectionHeader(
          title: pickUiText(i18n, zh: '预设包', en: 'Preset pack'),
          subtitle: pickUiText(
            i18n,
            zh: '预设会联动音色、共鸣和滑音幅度，便于快速进入演奏状态。',
            en: 'Presets link tone, resonance, and slide amount for quick setup.',
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
        Text(_presetSubtitle(i18n, preset), style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        Text(
          pickUiText(
            i18n,
            zh: '共鸣 ${(_resonance * 100).round()}%',
            en: 'Resonance ${(_resonance * 100).round()}%',
          ),
        ),
        Slider(
          value: _resonance,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (value) {
            setState(() => _resonance = value);
            _invalidatePlayers();
          },
        ),
        Text(
          pickUiText(
            i18n,
            zh: '滑音 ${_slide.toStringAsFixed(2)}',
            en: 'Slide ${_slide.toStringAsFixed(2)}',
          ),
        ),
        Slider(
          value: _slide,
          min: -1.0,
          max: 1.0,
          divisions: 20,
          onChanged: (value) {
            setState(() => _slide = value);
            _invalidatePlayers();
          },
        ),
        const SizedBox(height: 4),
        SectionHeader(
          title: pickUiText(i18n, zh: '演奏区', en: 'Play Zone'),
          subtitle: pickUiText(
            i18n,
            zh: '点击或沿弦拖动，力度与滑音会随触点变化。',
            en: 'Tap or sweep across strings; touch point affects force and glide.',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0xFFEED7AE), Color(0xFFD4B07A), Color(0xFFB88C52)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, boardHeight);
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) =>
                    _handleSweepPluck(event.localPosition, size, initial: true),
                onPointerMove: (event) =>
                    _handleSweepPluck(event.localPosition, size, initial: false),
                onPointerUp: (_) => _lastSweepString = null,
                onPointerCancel: (_) => _lastSweepString = null,
                child: SizedBox(
                  height: boardHeight,
                  child: Column(
                    children: List<Widget>.generate(_strings.length, (index) {
                      final active = _activeString == index;
                      return Container(
                        height: laneHeight,
                        margin: const EdgeInsets.symmetric(vertical: 1.2),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: compact ? 26 : 34,
                              child: Text(
                                'S${index + 1}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontSize: compact ? 11 : null,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF4A2A13),
                                ),
                              ),
                            ),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 90),
                                height: active ? 4.5 : 2.9,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: <Color>[
                                      active
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFFF5E6C8),
                                      active
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFF6B4A2F),
                                    ],
                                  ),
                                  boxShadow: active
                                      ? <BoxShadow>[
                                          BoxShadow(
                                            color: const Color(
                                              0xFFF59E0B,
                                            ).withValues(alpha: 0.28),
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
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        SectionHeader(
          title: pickUiText(i18n, zh: '古琴 108 条教程', en: 'Guqin 108 Lessons'),
          subtitle: pickUiText(
            i18n,
            zh: '按级别筛选并搜索关键字，点击可查看详细练习文案。',
            en: 'Filter by level and search keywords. Tap a lesson for details.',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <String>['all', 'beginner', 'intermediate', 'advanced']
              .map(
                (level) => ChoiceChip(
                  label: Text(_levelLabel(i18n, level)),
                  selected: _lessonLevel == level,
                  onSelected: (_) {
                    if (_lessonLevel == level) return;
                    setState(() => _lessonLevel = level);
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _lessonQueryController,
          onChanged: (value) => setState(() => _lessonQuery = value),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: pickUiText(
              i18n,
              zh: '搜索指法关键词（如 勾、轮指、长锁）',
              en: 'Search technique keywords (e.g. Gou, Lun Zhi, Chang Suo)',
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pickUiText(
            i18n,
            zh: '当前显示 ${filteredLessons.length} / 108',
            en: 'Showing ${filteredLessons.length} / 108',
          ),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: widget.fullScreen ? 360 : 280,
          child: ListView.separated(
            primary: false,
            itemCount: filteredLessons.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final lesson = filteredLessons[index];
              return ListTile(
                dense: compact,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  '${lesson.id}. ${lesson.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  lesson.summary,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _levelLabel(i18n, lesson.level),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _openLessonDialog(lesson),
              );
            },
          ),
        ),
      ],
    );
    return _wrapInstrumentPanel(fullScreen: widget.fullScreen, child: content);
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
          ..quadraticBezierTo(size.width * 0.84, y + wave, size.width, y - wave * 0.2);
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

