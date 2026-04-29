part of 'toolbox_human_tests.dart';

class _HumanTestEntry {
  const _HumanTestEntry({
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

class _HumanTestEntryCard extends StatelessWidget {
  const _HumanTestEntryCard({required this.entry});

  final _HumanTestEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => entry.pageBuilder()));
        },
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                entry.accent.withValues(alpha: 0.10),
                colorScheme.surfaceContainerLow,
                colorScheme.surface,
              ],
            ),
            border: Border.all(color: entry.accent.withValues(alpha: 0.20)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: entry.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HumanTestScaffold extends StatelessWidget {
  const _HumanTestScaffold({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.status,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String status;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _HumanHeroPanel(
            title: title,
            subtitle: subtitle,
            accent: accent,
            icon: icon,
            status: status,
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _HumanHeroPanel extends StatelessWidget {
  const _HumanHeroPanel({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.status,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.14),
            colorScheme.surfaceContainerLowest,
            colorScheme.secondaryContainer.withValues(alpha: 0.34),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent.withValues(alpha: 0.16)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 12),
                _HumanPill(text: status, accent: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HumanPanel extends StatelessWidget {
  const _HumanPanel({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _HumanPill extends StatelessWidget {
  const _HumanPill({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HumanMetricWrap extends StatelessWidget {
  const _HumanMetricWrap({required this.metrics});

  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: metrics
          .map(
            (metric) => ToolboxMetricCard(label: metric.$1, value: metric.$2),
          )
          .toList(growable: false),
    );
  }
}

class _HumanActionButton extends StatelessWidget {
  const _HumanActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(120, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _formatMilliseconds(num value) => '${value.round()} ms';

String _formatSeconds(num value) => '${value.toStringAsFixed(2)} s';

T _sample<T>(math.Random random, List<T> values) {
  return values[random.nextInt(values.length)];
}
