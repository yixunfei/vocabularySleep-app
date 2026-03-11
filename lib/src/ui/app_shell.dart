import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_i18n.dart';
import '../state/app_state.dart';
import 'pages/library_page.dart';
import 'pages/more_page.dart';
import 'pages/play_page.dart';
import 'pages/practice_page.dart';
import 'ui_copy.dart';
import 'widgets/app_background.dart';
import 'widgets/busy_overlay.dart';
import 'widgets/mini_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  VoidCallback? _scrollLibraryToTop;

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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final message = state.error;
    if (message != null && message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        state.clearMessage();
      });
    }

    return Scaffold(
      body: AppBackground(
        appearance: state.config.appearance,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Expanded(
                    child: state.initializing && !state.initialized
                        ? const Center(child: CircularProgressIndicator())
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
                              const MorePage(),
                            ],
                          ),
                  ),
                  MiniPlayer(
                    state: state,
                    i18n: i18n,
                    onOpenPractice: () => _setIndex(2),
                    onOpenLibrary: () => _setIndex(1),
                  ),
                  NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: _setIndex,
                    destinations: <NavigationDestination>[
                      NavigationDestination(
                        icon: const Icon(Icons.play_circle_outline_rounded),
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
                        selectedIcon: const Icon(Icons.fitness_center_rounded),
                        label: pageLabelPractice(i18n),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.widgets_outlined),
                        selectedIcon: const Icon(Icons.widgets_rounded),
                        label: pageLabelMore(i18n),
                      ),
                    ],
                  ),
                ],
              ),
              BusyOverlay(
                visible: state.busy,
                message: pickUiText(i18n, zh: '处理中...', en: 'Processing...'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
