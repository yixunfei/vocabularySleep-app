part of 'focus_page.dart';

extension _FocusPageWorkspaceExtension on _FocusPageState {
  Widget _buildWorkspaceTab(
    FocusService focus,
    List<PlanNote> notes,
    AppI18n i18n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthTier = AppWidthBreakpoints.tierFor(constraints.maxWidth);
        final contentWidth = math.min(
          constraints.maxWidth,
          _pageContentMaxWidth(widthTier),
        );
        final compactWorkspace = constraints.maxWidth < 600;
        final outerPadding = compactWorkspace ? 12.0 : 16.0;
        if (compactWorkspace) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Padding(
                padding: EdgeInsets.all(outerPadding),
                child: _buildTodoPanel(focus, i18n, notes: notes),
              ),
            ),
          );
        }
        final layoutWidth = math.max(0.0, contentWidth - outerPadding * 2);
        final drawerWidth = _notesDrawerWidth(layoutWidth, focus);
        final railWidth = 60.0;
        final railGutter = railWidth + 10.0;
        final hiddenOffset = drawerWidth - railWidth;
        final progress = _notesDrawerProgress.clamp(0.0, 1.0).toDouble();

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Padding(
              padding: EdgeInsets.all(outerPadding),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: progress, end: progress),
                duration: _notesDrawerDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, _) {
                  return Stack(
                    children: <Widget>[
                      Positioned(
                        top: 0,
                        left: 0,
                        bottom: 0,
                        right: railGutter,
                        child: Transform.translate(
                          offset: Offset(-12 * animatedProgress, 0),
                          child: _buildTodoPanel(focus, i18n, notes: notes),
                        ),
                      ),
                      if (animatedProgress > 0.01)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _settleNotesDrawer(open: false),
                            onHorizontalDragStart: (_) {
                              _setViewState(() {
                                _notesDrawerDragging = true;
                              });
                            },
                            onHorizontalDragUpdate: (details) =>
                                _updateNotesDrawerProgress(
                                  details.delta.dx,
                                  drawerWidth,
                                ),
                            onHorizontalDragEnd: (details) =>
                                _settleNotesDrawerFromVelocity(
                                  details.primaryVelocity ?? 0,
                                ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(
                                  alpha: 0.04 + animatedProgress * 0.10,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: -hiddenOffset * (1 - animatedProgress),
                        child: _buildNotesDrawer(
                          focus: focus,
                          notes: notes,
                          i18n: i18n,
                          width: drawerWidth,
                          handleWidth: railWidth,
                          progress: animatedProgress,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
