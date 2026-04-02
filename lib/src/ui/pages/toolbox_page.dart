import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import '../widgets/section_header.dart';
import 'toolbox_daily_choice_tool.dart';
import 'toolbox_mind_tools.dart';
import 'toolbox_soothing_music_v2_page.dart';
import 'toolbox_sound_tools.dart';

class ToolboxPage extends StatelessWidget {
  const ToolboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(context.watch<AppState>().uiLanguage);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        PageHeader(
          eyebrow: pageLabelToolbox(i18n),
          title: pickUiText(
            i18n,
            zh: '多功能工具箱',
            en: 'Multi-tool toolbox',
            ja: 'マルチツールボックス',
            de: 'Mehrzweck-Werkzeugkasten',
            fr: 'Boite a outils multi-usage',
            es: 'Caja de herramientas multiple',
            ru: 'Многофункциональный набор инструментов',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '把声音、专注、解压和随机决策工具集中在一个本地工具箱中。',
            en: 'Bring sound, focus, decompression, and small decision tools into one local toolbox.',
            ja: 'サウンド、集中、リラックス、意思決定ツールを1つのローカルツール箱に集約。',
            de: 'Sound-, Fokus-, Entspannungs- und Entscheidungs-Tools in einer lokalen Toolbox.',
            fr: 'Regroupez son, concentration, detente et choix aleatoire dans une seule toolbox locale.',
            es: 'Reune sonido, enfoque, descompresion y decisiones aleatorias en una caja local.',
            ru: 'Объедините звук, фокус, разгрузку и выбор в одном локальном наборе.',
          ),
        ),
        const SizedBox(height: 18),
        _ToolboxLeadCard(i18n: i18n),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(
            i18n,
            zh: '声音工具',
            en: 'Sound tools',
            ja: 'サウンドツール',
            de: 'Sound-Tools',
            fr: 'Outils sonores',
            es: 'Herramientas de sonido',
            ru: 'Звуковые инструменты',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '本地优先的交互乐器与节奏工具。',
            en: 'Local-first interactive instruments and rhythm tools.',
            ja: 'ローカル優先のインタラクティブ楽器とリズムツール。',
            de: 'Lokale, interaktive Instrumente und Rhythmus-Tools.',
            fr: 'Instruments interactifs et outils rythmiques en local.',
            es: 'Instrumentos interactivos y herramientas ritmicas en local.',
            ru: 'Локальные интерактивные инструменты и ритм-инструменты.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
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
                zh: '本地曲目与沉浸视觉，支持平滑控制。',
                en: 'Local tracks with immersive visuals and smooth controls.',
                ja: 'ローカル音源と没入ビジュアル、滑らかな操作。',
                de: 'Lokale Tracks mit immersiven Visuals und sanfter Steuerung.',
                fr: 'Pistes locales, visuels immersifs et controle fluide.',
                es: 'Pistas locales con visuales inmersivos y control fluido.',
                ru: 'Локальные треки, иммерсивная визуализация и плавное управление.',
              ),
              icon: Icons.spa_rounded,
              accent: const Color(0xFF6E9BC3),
              pageBuilder: () => const SoothingMusicV2Page(),
            ),
            _ToolboxEntry(
              title: pickUiText(
                i18n,
                zh: '空灵竖琴',
                en: 'Ethereal harp',
                ja: 'エーテルハープ',
                de: 'Ätherharfe',
                fr: 'Harpe etheree',
                es: 'Arpa eterea',
                ru: 'Эфирная арфа',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '统一入口切换竖琴、钢琴、长笛、鼓垫、吉他和三角铁。',
                en: 'Unified deck for harp, piano, flute, drum pad, guitar, triangle, violin, and pickup.',
                ja: 'ハープ、ピアノ、フルート、ドラム、ギター、トライアングルを1画面で切替。',
                de: 'Einheitliches Deck fur Harfe, Klavier, Flote, Drum-Pad, Gitarre und Triangel.',
                fr: 'Deck unifie pour harpe, piano, flute, pad batterie, guitare et triangle.',
                es: 'Panel unificado para arpa, piano, flauta, pad, guitarra y triangulo.',
                ru: 'Единая панель для арфы, пианино, флейты, драм-пэда, гитары и треугольника.',
              ),
              icon: Icons.music_note_rounded,
              accent: const Color(0xFF8A84D6),
              pageBuilder: () => const HarpToolPage(),
            ),
            _ToolboxEntry(
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
                zh: '简洁本地节拍器，支持 BPM 调整。',
                en: 'Simple local BPM metronome.',
                ja: 'BPM調整対応のシンプルなローカルメトロノーム。',
                de: 'Einfaches lokales BPM-Metronom.',
                fr: 'Metronome BPM local et simple.',
                es: 'Metronomo BPM local y sencillo.',
                ru: 'Простой локальный метроном с BPM.',
              ),
              icon: Icons.av_timer_rounded,
              accent: const Color(0xFF61A78A),
              pageBuilder: () => const FocusBeatsToolPage(),
            ),
            _ToolboxEntry(
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
                zh: '轻敲计数，随手完成一次微小重置。',
                en: 'Quick strike and count for a tiny reset.',
                ja: '軽く叩いてカウント、気分をリセット。',
                de: 'Kurzer Schlag und Zahler fur einen kleinen Reset.',
                fr: 'Frappe rapide et compteur pour une micro-pause.',
                es: 'Golpe rapido y conteo para un pequeno reinicio.',
                ru: 'Быстрый удар и счёт для короткой перезагрузки.',
              ),
              icon: Icons.self_improvement_rounded,
              accent: const Color(0xFFB36E3D),
              pageBuilder: () => const WoodfishToolPage(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(
            i18n,
            zh: '专注训练',
            en: 'Focus drills',
            ja: '集中トレーニング',
            de: 'Fokusubungen',
            fr: 'Exercices de concentration',
            es: 'Entrenamiento de enfoque',
            ru: 'Тренировка фокуса',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '稳定你的注意力、节奏与呼吸。',
            en: 'Steady your attention, rhythm, and breathing.',
            ja: '注意力、リズム、呼吸を整える。',
            de: 'Stabilisiert Aufmerksamkeit, Rhythmus und Atmung.',
            fr: 'Stabilisez attention, rythme et respiration.',
            es: 'Estabiliza atencion, ritmo y respiracion.',
            ru: 'Стабилизируйте внимание, ритм и дыхание.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(
                i18n,
                zh: '舒尔特方格',
                en: 'Schulte grid',
                ja: 'シュルテ表',
                de: 'Schulte-Gitter',
                fr: 'Grille de Schulte',
                es: 'Cuadricula Schulte',
                ru: 'Таблица Шульте',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '按顺序找数字，训练视觉搜索。',
                en: 'Find numbers in order to train visual search.',
                ja: '数字を順に探して視覚探索を鍛える。',
                de: 'Zahlen in Reihenfolge finden und visuelle Suche trainieren.',
                fr: 'Trouvez les nombres dans lordre pour entrainer le balayage visuel.',
                es: 'Encuentra numeros en orden para entrenar busqueda visual.',
                ru: 'Ищите числа по порядку для тренировки визуального поиска.',
              ),
              icon: Icons.grid_view_rounded,
              accent: const Color(0xFF5B88D6),
              pageBuilder: () => const SchulteGridToolPage(),
            ),
            _ToolboxEntry(
              title: pickUiText(
                i18n,
                zh: '呼吸练习',
                en: 'Breathing practice',
                ja: '呼吸練習',
                de: 'Atemubung',
                fr: 'Exercice respiratoire',
                es: 'Practica de respiracion',
                ru: 'Дыхательная практика',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '引导吸气、停顿和呼气节奏。',
                en: 'Guide inhale, hold, and exhale with pacing.',
                ja: '吸う・止める・吐くをペースでガイド。',
                de: 'Einatmen, Halten und Ausatmen im Rhythmus fuhren.',
                fr: 'Guidez inspiration, pause et expiration avec rythme.',
                es: 'Guia inhalar, mantener y exhalar con ritmo.',
                ru: 'Проводит по ритму вдоха, задержки и выдоха.',
              ),
              icon: Icons.air_rounded,
              accent: const Color(0xFF4A9FA8),
              pageBuilder: () => const BreathingToolPage(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(
            i18n,
            zh: '禅意解压',
            en: 'Zen decompression',
            ja: '禅リラックス',
            de: 'Zen-Entspannung',
            fr: 'Decompression zen',
            es: 'Descompresion zen',
            ru: 'Дзен-разгрузка',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '通过动作、计数和简洁视觉放松下来。',
            en: 'Use motion, counting, and simple visuals to unwind.',
            ja: '動き、カウント、シンプルな視覚要素で緊張をほどく。',
            de: 'Mit Bewegung, Zahlen und einfachen Visuals entspannen.',
            fr: 'Utilisez mouvement, comptage et visuels simples pour relacher.',
            es: 'Usa movimiento, conteo y visuales simples para relajarte.',
            ru: 'Снимайте напряжение через движение, счёт и простую визуализацию.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(
                i18n,
                zh: '念珠',
                en: 'Prayer beads',
                ja: '念珠',
                de: 'Gebetskette',
                fr: 'Perles de priere',
                es: 'Cuentas de oracion',
                ru: 'Четки',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '按自己的节奏一颗颗拨动。',
                en: 'Advance bead by bead at your own rhythm.',
                ja: '自分のリズムで一珠ずつ進める。',
                de: 'Perle fur Perle im eigenen Rhythmus bewegen.',
                fr: 'Faites avancer perle par perle a votre rythme.',
                es: 'Avanza cuenta por cuenta a tu propio ritmo.',
                ru: 'Перебирайте бусины в своём ритме.',
              ),
              icon: Icons.trip_origin_rounded,
              accent: const Color(0xFF8570B5),
              pageBuilder: () => const PrayerBeadsToolPage(),
            ),
            _ToolboxEntry(
              title: pickUiText(
                i18n,
                zh: '禅意沙盘',
                en: 'Zen sand tray',
                ja: '禅砂盆',
                de: 'Zen-Sandtablett',
                fr: 'Plateau de sable zen',
                es: 'Bandeja zen de arena',
                ru: 'Дзен-песочница',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '画耙痕、摆石头，做一个迷你沙盘。',
                en: 'Draw rake lines and place stones in a tiny sand tray.',
                ja: '熊手の線を描き、石を置いて小さな砂庭を作る。',
                de: 'Harkenspuren zeichnen und Steine im Mini-Sandtablett platzieren.',
                fr: 'Tracez des sillons et placez des pierres dans un mini jardin de sable.',
                es: 'Dibuja lineas y coloca piedras en una mini bandeja de arena.',
                ru: 'Рисуйте граблями и размещайте камни в мини-песочнице.',
              ),
              icon: Icons.landscape_rounded,
              accent: const Color(0xFFC6A96A),
              pageBuilder: () => const ZenSandToolPage(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(
            i18n,
            zh: '随机决策',
            en: 'Random choice',
            ja: 'ランダム選択',
            de: 'Zufallsauswahl',
            fr: 'Choix aleatoire',
            es: 'Eleccion aleatoria',
            ru: 'Случайный выбор',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '用转盘打破犹豫，快速继续推进。',
            en: 'Use a wheel to break indecision and keep moving.',
            ja: 'ルーレットで迷いを断ち、前に進む。',
            de: 'Mit einem Rad Unentschlossenheit losen und weitermachen.',
            fr: 'Utilisez une roue pour sortir de lhesitation et avancer.',
            es: 'Usa una ruleta para romper la indecision y avanzar.',
            ru: 'Колесо помогает выйти из сомнений и двигаться дальше.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(
                i18n,
                zh: '每日决策',
                en: 'Daily decision',
                ja: '今日の決定',
                de: 'Tagesentscheidung',
                fr: 'Decision du jour',
                es: 'Decision diaria',
                ru: 'Решение дня',
              ),
              subtitle: pickUiText(
                i18n,
                zh: '输入选项后转一次，直接给出结果。',
                en: 'Drop in your options and spin once.',
                ja: '候補を入れて1回回すだけ。',
                de: 'Optionen eintragen und einmal drehen.',
                fr: 'Ajoutez vos options et lancez une fois.',
                es: 'Ingresa opciones y gira una vez.',
                ru: 'Добавьте варианты и прокрутите один раз.',
              ),
              icon: Icons.casino_rounded,
              accent: const Color(0xFFE08B58),
              pageBuilder: () => const DailyDecisionToolPage(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolboxLeadCard extends StatelessWidget {
  const _ToolboxLeadCard({required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickUiText(
                i18n,
                zh: '工具箱新阶段已上线',
                en: 'Toolbox phase update is live',
                ja: 'ツールボックス新フェーズ公開',
                de: 'Toolbox-Update ist live',
                fr: 'La nouvelle phase de la toolbox est en ligne',
                es: 'La nueva fase de la toolbox ya esta activa',
                ru: 'Новая фаза toolbox уже доступна',
              ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '这一轮重点是本地音频真实感、乐器整合和移动端触控交互。',
                en: 'This pass focuses on local audio realism, instrument integration, and mobile touch interaction.',
                ja: '今回はローカル音の質感、楽器統合、モバイル操作性を重点強化。',
                de: 'Dieser Durchlauf fokussiert auf lokalen Klangrealismus, Instrumentenintegration und Mobile-Touch.',
                fr: 'Cette passe met laccent sur le realisme audio local, lintegration des instruments et le tactile mobile.',
                es: 'Esta iteracion se centra en realismo de audio local, integracion de instrumentos e interaccion movil.',
                ru: 'Этот этап фокусируется на реализме локального звука, интеграции инструментов и мобильных жестах.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _InfoChip(
                  label: pickUiText(
                    i18n,
                    zh: '离线优先',
                    en: 'Offline first',
                    ja: 'オフライン優先',
                    de: 'Offline-first',
                    fr: 'Priorite hors ligne',
                    es: 'Prioridad offline',
                    ru: 'Офлайн в приоритете',
                  ),
                ),
                _InfoChip(
                  label: pickUiText(
                    i18n,
                    zh: '本地音频',
                    en: 'Local audio',
                    ja: 'ローカル音声',
                    de: 'Lokales Audio',
                    fr: 'Audio local',
                    es: 'Audio local',
                    ru: 'Локальный звук',
                  ),
                ),
                _InfoChip(
                  label: pickUiText(
                    i18n,
                    zh: '移动优先',
                    en: 'Mobile first',
                    ja: 'モバイル優先',
                    de: 'Mobile-first',
                    fr: 'Priorite mobile',
                    es: 'Enfoque movil',
                    ru: 'Мобильный приоритет',
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

class _ToolboxSection extends StatelessWidget {
  const _ToolboxSection({
    required this.title,
    required this.subtitle,
    required this.entries,
  });

  final String title;
  final String subtitle;
  final List<_ToolboxEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final spacing = 12.0;
            final cardWidth = compact
                ? constraints.maxWidth
                : (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: entries
                  .map(
                    (entry) => SizedBox(
                      width: cardWidth,
                      child: _ToolboxEntryCard(entry: entry),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _ToolboxEntry {
  const _ToolboxEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.pageBuilder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget Function() pageBuilder;
}

class _ToolboxEntryCard extends StatelessWidget {
  const _ToolboxEntryCard({required this.entry});

  final _ToolboxEntry entry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => entry.pageBuilder()));
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: entry.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(entry.icon, color: entry.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
