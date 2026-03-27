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
          title: pickUiText(i18n, zh: '多功能工具箱', en: 'Multi-tool toolbox'),
          subtitle: pickUiText(
            i18n,
            zh: '把声音疗愈、专注训练、禅意解压和随机决策聚合到一个本地工具箱里。',
            en: 'Bring sound therapy, focus drills, zen decompression, and small decision tools into one local toolbox.',
          ),
        ),
        const SizedBox(height: 18),
        _ToolboxLeadCard(i18n: i18n),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(i18n, zh: '声音疗愈', en: 'Sound tools'),
          subtitle: pickUiText(
            i18n,
            zh: '不嵌网页，直接在本地运行的轻音、竖琴、节拍和木鱼。',
            en: 'Local-first sound tools without embedding web pages.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '舒缓轻音', en: 'Soothing music'),
              subtitle: pickUiText(
                i18n,
                zh: '本地曲库、多模式切换与更完整的沉浸式动效。',
                en: 'Local tracks, multi-mode switching, and richer immersive visuals.',
              ),
              icon: Icons.spa_rounded,
              accent: const Color(0xFF6E9BC3),
              pageBuilder: () => const SoothingMusicV2Page(),
            ),
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '空灵竖琴', en: 'Ethereal harp'),
              subtitle: pickUiText(
                i18n,
                zh: '手指轻扫就能弹出一串安静音符。',
                en: 'Strum calm notes with a fingertip glide.',
              ),
              icon: Icons.music_note_rounded,
              accent: const Color(0xFF8A84D6),
              pageBuilder: () => const HarpToolPage(),
            ),
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '专注节拍', en: 'Focus beats'),
              subtitle: pickUiText(
                i18n,
                zh: '可调 BPM 的本地节拍器。',
                en: 'A local BPM metronome.',
              ),
              icon: Icons.av_timer_rounded,
              accent: const Color(0xFF61A78A),
              pageBuilder: () => const FocusBeatsToolPage(),
            ),
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '电子木鱼', en: 'Digital woodfish'),
              subtitle: pickUiText(
                i18n,
                zh: '一敲一响，顺手做一次短暂停顿。',
                en: 'A quick strike for a tiny reset.',
              ),
              icon: Icons.self_improvement_rounded,
              accent: const Color(0xFFB36E3D),
              pageBuilder: () => const WoodfishToolPage(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(i18n, zh: '专注训练', en: 'Focus drills'),
          subtitle: pickUiText(
            i18n,
            zh: '把注意力、节律和呼吸稳定下来。',
            en: 'Steady your attention, rhythm, and breathing.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '舒尔特方格', en: 'Schulte grid'),
              subtitle: pickUiText(
                i18n,
                zh: '按顺序找数字，训练视觉搜索。',
                en: 'Find numbers in order to train visual search.',
              ),
              icon: Icons.grid_view_rounded,
              accent: const Color(0xFF5B88D6),
              pageBuilder: () => const SchulteGridToolPage(),
            ),
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '呼吸练习', en: 'Breathing practice'),
              subtitle: pickUiText(
                i18n,
                zh: '用节奏引导吸气、停留、呼气。',
                en: 'Guide inhale, hold, and exhale with pacing.',
              ),
              icon: Icons.air_rounded,
              accent: const Color(0xFF4A9FA8),
              pageBuilder: () => const BreathingToolPage(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(i18n, zh: '禅意解压', en: 'Zen decompression'),
          subtitle: pickUiText(
            i18n,
            zh: '用手势、计数和简单图形让情绪落下来。',
            en: 'Use motion, counting, and simple visuals to unwind.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '静心念珠', en: 'Prayer beads'),
              subtitle: pickUiText(
                i18n,
                zh: '一颗一颗拨动，保持自己的节律。',
                en: 'Advance bead by bead at your own rhythm.',
              ),
              icon: Icons.trip_origin_rounded,
              accent: const Color(0xFF8570B5),
              pageBuilder: () => const PrayerBeadsToolPage(),
            ),
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '禅意沙盘', en: 'Zen sand tray'),
              subtitle: pickUiText(
                i18n,
                zh: '画耙纹、落石子，做一个小型触觉沙盘。',
                en: 'Draw rake lines and place stones in a tiny sand tray.',
              ),
              icon: Icons.landscape_rounded,
              accent: const Color(0xFFC6A96A),
              pageBuilder: () => const ZenSandToolPage(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(i18n, zh: '随机与选择', en: 'Random choice'),
          subtitle: pickUiText(
            i18n,
            zh: '把纠结交给转盘，用一个结果帮助继续行动。',
            en: 'Let a wheel break indecision and keep you moving.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '每日抉择', en: 'Daily decision'),
              subtitle: pickUiText(
                i18n,
                zh: '把选项放进去，转一下就有结果。',
                en: 'Drop in your options and spin once.',
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
              pickUiText(i18n, zh: '首批聚合已上线', en: 'First batch is live'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '当前先覆盖 9 个高频小工具，优先做离线可用、本地交互和移动端手感。',
                en: 'This first pass covers 9 high-frequency tools with offline behavior, local interaction, and mobile-first feel.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _InfoChip(
                  label: pickUiText(i18n, zh: '离线优先', en: 'Offline first'),
                ),
                _InfoChip(
                  label: pickUiText(i18n, zh: '本地音频', en: 'Local audio'),
                ),
                _InfoChip(
                  label: pickUiText(i18n, zh: '移动优先', en: 'Mobile first'),
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
