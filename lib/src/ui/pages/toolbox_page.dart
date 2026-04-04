import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import '../widgets/section_header.dart';
import 'toolbox_daily_choice_tool.dart';
import 'toolbox_mini_games.dart';
import 'toolbox_mind_tools.dart';
import 'toolbox_soothing_music_v2_page.dart';
import 'toolbox_sound_tools.dart';
import 'toolbox_zen_sand_tool.dart';

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
            zh: '把声音、专注、放松和小决策工具集中到一个本地工具箱里。',
            en: 'Bring sound, focus, decompression, and small decision tools into one local toolbox.',
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              pickUiText(
                i18n,
                zh: '这一版重点清理了舒尔特方格和相关入口，让训练流程更清楚。',
                en: 'This pass cleans up the Schulte module and its toolbox entry so the training flow is easier to follow.',
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(i18n, zh: '小游戏', en: 'Mini games'),
          subtitle: pickUiText(
            i18n,
            zh: '轻量益智与拼图。',
            en: 'Lightweight puzzles and small games.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '游戏中心', en: 'Game hub'),
              subtitle: pickUiText(
                i18n,
                zh: '包含数独、扫雷和导入图片拼图。',
                en: 'Includes Sudoku, Minesweeper, and imported-image jigsaw.',
              ),
              icon: Icons.videogame_asset_rounded,
              accent: const Color(0xFF5B86C5),
              pageBuilder: () => const MiniGamesToolPage(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(i18n, zh: '声音工具', en: 'Sound tools'),
          subtitle: pickUiText(
            i18n,
            zh: '本地优先的乐器、节拍与放松声音。',
            en: 'Local-first instruments, beats, and calming sound tools.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '舒缓音乐', en: 'Soothing music'),
              subtitle: pickUiText(
                i18n,
                zh: '本地曲目配合沉浸式视觉。',
                en: 'Local tracks with immersive visuals.',
              ),
              icon: Icons.spa_rounded,
              accent: const Color(0xFF6E9BC3),
              pageBuilder: () => const SoothingMusicV2Page(),
            ),
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '空灵竖琴', en: 'Ethereal harp'),
              subtitle: pickUiText(
                i18n,
                zh: '统一入口切换多种乐器。',
                en: 'Unified deck for harp, piano, flute, drum pad, guitar, triangle, violin, and pickup.',
              ),
              icon: Icons.music_note_rounded,
              accent: const Color(0xFF8A84D6),
              pageBuilder: () => const HarpToolPage(),
            ),
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '专注节拍', en: 'Focus beats'),
              subtitle: pickUiText(
                i18n,
                zh: '沉浸式节拍训练与循环编排。',
                en: 'Immersive rhythm practice with cycle arrangement.',
              ),
              icon: Icons.av_timer_rounded,
              accent: const Color(0xFF61A78A),
              pageBuilder: () => const FocusBeatsToolPage(),
            ),
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '电子木鱼', en: 'Digital woodfish'),
              subtitle: pickUiText(
                i18n,
                zh: '轻敲计数，做一个微型重置。',
                en: 'Quick strike and count for a tiny reset.',
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
            zh: '稳定你的注意力、节奏与呼吸。',
            en: 'Steady your attention, rhythm, and breathing.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '舒尔特方格', en: 'Schulte grid'),
              subtitle: pickUiText(
                i18n,
                zh: '按顺序寻找数字，训练视觉搜索。',
                en: 'Find numbers in order to train visual search.',
              ),
              icon: Icons.grid_view_rounded,
              accent: const Color(0xFF5B88D6),
              pageBuilder: () => const SchulteGridToolPage(),
            ),
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '呼吸训练', en: 'Breathing practice'),
              subtitle: pickUiText(
                i18n,
                zh: '做专注、放松、睡前和生理叹息练习。',
                en: 'Scenario-based breathing for focus, relaxation, bedtime, and physiological sigh drills.',
              ),
              icon: Icons.air_rounded,
              accent: const Color(0xFF4A9FA8),
              pageBuilder: () => const BreathingToolPage(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(i18n, zh: '静心减压', en: 'Calm tools'),
          subtitle: pickUiText(
            i18n,
            zh: '通过计数、动作和简洁视觉放松。',
            en: 'Unwind through counting, touch, and simple visuals.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '静心念珠', en: 'Prayer beads'),
              subtitle: pickUiText(
                i18n,
                zh: '按自己的节奏一颗颗拨动。',
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
                zh: '画耙痕、摆石子，做一个迷你沙盘。',
                en: 'Draw rake lines and place stones in a tiny sand tray.',
              ),
              icon: Icons.landscape_rounded,
              accent: const Color(0xFFC6A96A),
              pageBuilder: () => const ZenSandStudioPage(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ToolboxSection(
          title: pickUiText(i18n, zh: '随机决策', en: 'Random choice'),
          subtitle: pickUiText(
            i18n,
            zh: '用转盘快速打破犹豫。',
            en: 'Use a wheel to break indecision and keep moving.',
          ),
          entries: <_ToolboxEntry>[
            _ToolboxEntry(
              title: pickUiText(i18n, zh: '每日决策', en: 'Daily decision'),
              subtitle: pickUiText(
                i18n,
                zh: '输入选项后转一次，直接给出结果。',
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
