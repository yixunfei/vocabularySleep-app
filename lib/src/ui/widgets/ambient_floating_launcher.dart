import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../sheets/ambient_sheet.dart';

class AmbientFloatingLauncher extends StatelessWidget {
  static const double diameter = 56;

  const AmbientFloatingLauncher({
    super.key,
    required this.state,
    required this.i18n,
    this.enabled = true,
    this.surfaceAlpha = 0.84,
  });

  final AppState state;
  final AppI18n i18n;
  final bool enabled;
  final double surfaceAlpha;

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
    final ambientEnabled = state.ambientEnabled;
    final selectedCount = state.ambientSources
        .where((source) => source.enabled)
        .length;
    final activeCount = ambientEnabled ? selectedCount : 0;

    return Tooltip(
      message: i18n.t('ambientAudio'),
      triggerMode: TooltipTriggerMode.tap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey<String>('global-ambient-launcher'),
          borderRadius: BorderRadius.circular(999),
          onTap: enabled ? () => _openAmbientSheet(context) : null,
          child: Ink(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHigh.withValues(
                alpha: surfaceAlpha,
              ),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                Icon(
                  !ambientEnabled
                      ? Icons.volume_off_rounded
                      : activeCount > 0
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
