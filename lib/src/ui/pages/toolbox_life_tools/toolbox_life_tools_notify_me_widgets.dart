part of '../toolbox_life_tools.dart';

class _NotifyHeroPanel extends StatelessWidget {
  const _NotifyHeroPanel({
    required this.title,
    required this.body,
    required this.modeLabel,
    required this.scheduleLabel,
    required this.dueLabel,
    required this.alertLabel,
    required this.nextLabel,
    required this.nativeReady,
    required this.calendarEnabled,
    required this.sticky,
    required this.cancelOnOpen,
  });

  final String title;
  final String body;
  final String modeLabel;
  final String scheduleLabel;
  final String dueLabel;
  final String alertLabel;
  final String nextLabel;
  final bool nativeReady;
  final bool calendarEnabled;
  final bool sticky;
  final bool cancelOnOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.colorScheme.primaryContainer.withValues(alpha: 0.82),
            theme.colorScheme.tertiaryContainer.withValues(alpha: 0.58),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _NotifyStatusChip(
                icon: Icons.layers_rounded,
                label: modeLabel,
                active: true,
              ),
              _NotifyStatusChip(
                icon: Icons.schedule_rounded,
                label: scheduleLabel,
                active: true,
              ),
              _NotifyStatusChip(
                icon: Icons.push_pin_rounded,
                label: sticky
                    ? _lifeText(context, zh: '常驻', en: 'Sticky')
                    : _lifeText(context, zh: '一次性', en: 'One-shot'),
                active: sticky,
              ),
              _NotifyStatusChip(
                icon: Icons.open_in_new_rounded,
                label: cancelOnOpen
                    ? _lifeText(context, zh: '打开后取消', en: 'Open cancels')
                    : _lifeText(context, zh: '打开后保留', en: 'Open keeps'),
                active: cancelOnOpen,
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final tiles = <Widget>[
                _NotifyInfoTile(
                  icon: Icons.event_available_rounded,
                  label: _lifeText(context, zh: '提醒时间', en: 'Due'),
                  value: dueLabel,
                ),
                _NotifyInfoTile(
                  icon: Icons.alarm_rounded,
                  label: _lifeText(context, zh: '触发时间', en: 'Alert'),
                  value: alertLabel,
                ),
                _NotifyInfoTile(
                  icon: Icons.upcoming_rounded,
                  label: _lifeText(context, zh: '下一条', en: 'Next'),
                  value: nextLabel,
                ),
              ];
              if (compact) {
                return Column(
                  children: tiles
                      .map(
                        (tile) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: tile,
                        ),
                      )
                      .toList(growable: false),
                );
              }
              return Row(
                children: tiles
                    .map(
                      (tile) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: tile,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          const SizedBox(height: 8),
          _NotifySummaryStrip(
            items: <String>[
              nativeReady
                  ? _lifeText(context, zh: '原生提醒可用', en: 'Native ready')
                  : _lifeText(context, zh: '原生提醒受限', en: 'Native limited'),
              calendarEnabled
                  ? _lifeText(context, zh: '日历镜像开启', en: 'Calendar on')
                  : _lifeText(context, zh: '日历镜像关闭', en: 'Calendar off'),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotifyStatusChip extends StatelessWidget {
  const _NotifyStatusChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.60),
    );
  }
}

class _NotifyInfoTile extends StatelessWidget {
  const _NotifyInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifyMinuteInput extends StatelessWidget {
  const _NotifyMinuteInput({
    required this.controller,
    required this.label,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        suffixText: _lifeText(context, zh: '分钟', en: 'min'),
        prefixIcon: const Icon(Icons.tune_rounded),
      ),
      onChanged: (value) {
        final parsed = int.tryParse(value.trim());
        if (parsed == null) {
          return;
        }
        onChanged(parsed.clamp(min, max));
      },
    );
  }
}

class _NotifySummaryStrip extends StatelessWidget {
  const _NotifySummaryStrip({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.48,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: items
            .map(
              (item) => Text(
                item,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _NotifyReminderCard extends StatelessWidget {
  const _NotifyReminderCard({
    super.key,
    required this.title,
    required this.note,
    required this.stateLabel,
    required this.dueLabel,
    required this.presentationLabel,
    required this.sticky,
    required this.calendarEnabled,
    required this.onComplete,
    required this.onSnooze10,
    required this.onSnooze60,
    required this.onReuse,
    required this.onDelete,
  });

  final String title;
  final String note;
  final String stateLabel;
  final String dueLabel;
  final String presentationLabel;
  final bool sticky;
  final bool calendarEnabled;
  final VoidCallback onComplete;
  final VoidCallback onSnooze10;
  final VoidCallback onSnooze60;
  final VoidCallback onReuse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.notification_important_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (note.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(note),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text(stateLabel)),
                Chip(label: Text(dueLabel)),
                Chip(label: Text(presentationLabel)),
                if (sticky)
                  Chip(
                    label: Text(_lifeText(context, zh: '常驻', en: 'Sticky')),
                  ),
                if (calendarEnabled)
                  Chip(
                    label: Text(_lifeText(context, zh: '日历镜像', en: 'Calendar')),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            OverflowBar(
              spacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(_lifeText(context, zh: '完成', en: 'Complete')),
                ),
                OutlinedButton.icon(
                  onPressed: onSnooze10,
                  icon: const Icon(Icons.snooze_rounded),
                  label: Text(_lifeText(context, zh: '10 分钟后', en: '10 min')),
                ),
                OutlinedButton.icon(
                  onPressed: onSnooze60,
                  icon: const Icon(Icons.more_time_rounded),
                  label: Text(_lifeText(context, zh: '1 小时后', en: '1 hour')),
                ),
                TextButton.icon(
                  onPressed: onReuse,
                  icon: const Icon(Icons.content_copy_rounded),
                  label: Text(_lifeText(context, zh: '套用', en: 'Reuse')),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(_lifeText(context, zh: '删除', en: 'Delete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
