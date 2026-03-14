import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_i18n.dart';
import '../state/app_state.dart';
import 'pages/focus_page.dart';
import 'pages/library_page.dart';
import 'pages/more_page.dart';
import 'pages/play_page.dart';
import 'pages/practice_page.dart';
import 'ui_copy.dart';
import 'widgets/app_background.dart';
import 'widgets/busy_overlay.dart';
import 'widgets/focus_lock_overlay.dart';
import 'widgets/mini_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const double _navigationBarHeight = 80;

  int _index = 0;
  double _miniPlayerReservedHeight = 0;
  VoidCallback? _scrollLibraryToTop;
  bool _exitDialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().init();
    });
  }

  void _setIndex(int index) {
    if (_index == index) {
      if (index == 1) {
        _scrollLibraryToTop?.call();
      }
      return;
    }
    setState(() {
      _index = index;
    });
  }

  void _handleMiniPlayerPresentation(
    bool visible,
    bool collapsed,
    double reservedHeight,
  ) {
    final nextHeight = visible && !collapsed ? reservedHeight : 0.0;
    if ((_miniPlayerReservedHeight - nextHeight).abs() < 0.5) {
      return;
    }
    setState(() {
      _miniPlayerReservedHeight = nextHeight;
    });
  }

  String? _busyDetail(AppI18n i18n, AppState state) {
    final key = state.busyMessageKey;
    if (key == 'busyLoadingWordbook' ||
        key == 'busyImportingWordbook' ||
        key == 'busyMigratingLegacyData') {
      return i18n.t('busyPatienceHint');
    }
    return null;
  }

  Widget _buildInitializingView(BuildContext context, AppI18n i18n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.8),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    i18n.t('busyInitializingApp'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    i18n.t('busyInitializingHint'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit(AppI18n i18n) async {
    if (_exitDialogVisible || !mounted) return;
    _exitDialogVisible = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            pickUiText(
              i18n,
              zh: '确认退出',
              en: 'Exit app?',
              ja: 'アプリを終了しますか',
              de: 'App beenden?',
              fr: 'Quitter l’application ?',
              es: '¿Salir de la app?',
              ru: 'Выйти из приложения?',
            ),
          ),
          content: Text(
            pickUiText(
              i18n,
              zh: '将退出当前应用，是否继续？',
              en: 'This will close the current app. Continue?',
              ja: '現在のアプリを終了します。続行しますか。',
              de: 'Die aktuelle App wird geschlossen. Fortfahren?',
              fr: 'L’application va se fermer. Continuer ?',
              es: 'La aplicación se cerrará. ¿Continuar?',
              ru: 'Приложение будет закрыто. Продолжить?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '取消',
                  en: 'Cancel',
                  ja: 'キャンセル',
                  de: 'Abbrechen',
                  fr: 'Annuler',
                  es: 'Cancelar',
                  ru: 'Отмена',
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '退出',
                  en: 'Exit',
                  ja: '終了',
                  de: 'Beenden',
                  fr: 'Quitter',
                  es: 'Salir',
                  ru: 'Выйти',
                ),
              ),
            ),
          ],
        );
      },
    );
    _exitDialogVisible = false;
    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    final navigationChromeHeight = _navigationBarHeight + bottomInset;
    final message = state.error;
    final isInitializing = state.initializing && !state.initialized;

    if (message != null && message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        state.clearMessage();
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExit(i18n);
      },
      child: Scaffold(
        body: AppBackground(
          appearance: state.config.appearance,
          child: Stack(
            children: <Widget>[
              SafeArea(
                bottom: false,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.only(
                          bottom: _miniPlayerReservedHeight,
                        ),
                        child: isInitializing
                            ? _buildInitializingView(context, i18n)
                            : IndexedStack(
                                index: _index,
                                children: <Widget>[
                                  PlayPage(
                                    onOpenPractice: () => _setIndex(2),
                                    onOpenLibrary: () => _setIndex(1),
                                  ),
                                  LibraryPage(
                                    onAttachScrollToTop: (callback) {
                                      _scrollLibraryToTop = callback;
                                    },
                                  ),
                                  const PracticePage(),
                                  const FocusPage(),
                                  const MorePage(),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(
                      height: navigationChromeHeight,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomInset),
                        child: NavigationBar(
                          height: _navigationBarHeight,
                          selectedIndex: _index,
                          onDestinationSelected: _setIndex,
                          destinations: <NavigationDestination>[
                            NavigationDestination(
                              icon: const Icon(
                                Icons.play_circle_outline_rounded,
                              ),
                              selectedIcon: const Icon(
                                Icons.play_circle_filled_rounded,
                              ),
                              label: pageLabelPlay(i18n),
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.menu_book_outlined),
                              selectedIcon: const Icon(Icons.menu_book_rounded),
                              label: pageLabelLibrary(i18n),
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.fitness_center_outlined),
                              selectedIcon: const Icon(
                                Icons.fitness_center_rounded,
                              ),
                              label: pageLabelPractice(i18n),
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.timer_outlined),
                              selectedIcon: const Icon(Icons.timer_rounded),
                              label: pageLabelFocus(i18n),
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.widgets_outlined),
                              selectedIcon: const Icon(Icons.widgets_rounded),
                              label: pageLabelMore(i18n),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset + _navigationBarHeight + 8,
                child: MiniPlayer(
                  state: state,
                  i18n: i18n,
                  onOpenPractice: () => _setIndex(2),
                  onOpenLibrary: () => _setIndex(1),
                  onPresentationChanged: _handleMiniPlayerPresentation,
                ),
              ),
              BusyOverlay(
                visible: state.busy,
                message: state.busyMessage ?? i18n.t('processing'),
                detail: _busyDetail(i18n, state),
              ),
              if (state.focusService.lockScreenActive)
                const Positioned.fill(child: FocusLockOverlay()),
            ],
          ),
        ),
      ),
    );
  }
}
