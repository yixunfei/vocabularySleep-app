part of 'focus_page.dart';

mixin _FocusPageDialogsMixin on ConsumerState<FocusPage> {
  Widget _buildNotesSheetContent(
    FocusService focus,
    List<PlanNote> notes,
    AppI18n i18n,
  );

  String _formatUnitSummary(int seconds, AppI18n i18n);

  Future<void> _showDurationPicker({
    required String title,
    required int totalSeconds,
    required AppI18n i18n,
    required ValueChanged<int> onChanged,
  }) async {
    var draft = Duration(seconds: totalSeconds.clamp(1, 359999));
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      enableDrag: false,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    _formatUnitSummary(draft.inSeconds, i18n),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hms,
                      initialTimerDuration: draft,
                      onTimerDurationChanged: (value) {
                        setSheetState(() {
                          draft = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(i18n.t('cancel')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          onChanged(draft.inSeconds.clamp(1, 359999));
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(i18n.t('save')),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showNotesSheet(FocusService focus, AppI18n i18n) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final sheetHeight = math.max(320.0, mediaQuery.size.height * 0.72);
        return ValueListenableBuilder<int>(
          valueListenable: focus.viewRevision,
          builder: (context, revision, child) {
            final notes = focus.getNotes();
            return SizedBox(
              key: const ValueKey<String>('notes-sheet'),
              height: sheetHeight,
              child: _buildNotesSheetContent(focus, notes, i18n),
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _pickTodoReminderDateTime(DateTime? current) async {
    final seed = current ?? DateTime.now().add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _openAmbientAudioSheet(BuildContext context) async {
    final state = ref.read(appStateProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: AmbientSheet(state: state, i18n: AppI18n(state.uiLanguage)),
      ),
    );
  }
}
