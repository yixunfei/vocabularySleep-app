import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../sheets/ambient_sheet.dart';

class AmbientFloatingLauncher extends StatelessWidget {
  const AmbientFloatingLauncher({
    super.key,
    required this.state,
    required this.i18n,
  });

  final AppState state;
  final AppI18n i18n;

  Future<void> _openAmbientSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: AmbientSheet(
            key: const ValueKey<String>('ambient-sheet'),
            state: state,
            i18n: i18n,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = state.ambientSources
        .where((source) => source.enabled)
        .length;

    return Tooltip(
      message: i18n.t('ambientAudio'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey<String>('global-ambient-launcher'),
          borderRadius: BorderRadius.circular(999),
          onTap: () => _openAmbientSheet(context),
          child: Ink(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHigh.withValues(
                alpha: 0.96,
              ),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.9),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                Icon(
                  activeCount > 0
                      ? Icons.surround_sound_rounded
                      : Icons.music_note_rounded,
                  color: theme.colorScheme.primary,
                ),
                if (activeCount > 0)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$activeCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
