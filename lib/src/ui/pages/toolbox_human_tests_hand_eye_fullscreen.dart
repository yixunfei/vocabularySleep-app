part of 'toolbox_human_tests.dart';

class _JoystickFullscreenView extends StatefulWidget {
  const _JoystickFullscreenView({required this.state});

  final _JoystickHandEyeCardState state;

  @override
  State<_JoystickFullscreenView> createState() =>
      _JoystickFullscreenViewState();
}

class _JoystickFullscreenViewState extends State<_JoystickFullscreenView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fullscreenTicker;
  bool _statusExpanded = false;
  Offset? _joystickCenter;
  Offset? _fireCenter;
  int? _fullscreenJoystickPointer;
  Size _fullscreenJoystickControlSize = Size.zero;
  bool _practiceControlActive = false;

  _JoystickHandEyeCardState get state => widget.state;

  static const EdgeInsets _controlMargin = EdgeInsets.all(10);

  @override
  void initState() {
    super.initState();
    state._activateFullscreenMotionDriver();
    _fullscreenTicker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tick);
    state._viewSignal.addListener(_syncTicker);
    _syncTicker();
  }

  @override
  void dispose() {
    state._viewSignal.removeListener(_syncTicker);
    _fullscreenTicker
      ..removeListener(_tick)
      ..dispose();
    state._deactivateFullscreenMotionDriver();
    super.dispose();
  }

  void _tick() {
    state._tickCrosshairAt(
      _fullscreenTicker.lastElapsedDuration,
      allowPractice: _practiceControlActive,
    );
  }

  void _syncTicker() {
    final shouldRun = state._running || _practiceControlActive;
    if (shouldRun && !_fullscreenTicker.isAnimating) {
      _fullscreenTicker.repeat();
      return;
    }
    if (!shouldRun && _fullscreenTicker.isAnimating) {
      _fullscreenTicker.stop();
    }
  }

  void _toggleStatus() {
    setState(() => _statusExpanded = !_statusExpanded);
  }

  Offset _clampControlCenter(
    Offset center,
    Size surfaceSize,
    Size controlSize, {
    EdgeInsets margin = _controlMargin,
  }) {
    final minX = margin.left + controlSize.width / 2;
    final maxX = math.max(
      minX,
      surfaceSize.width - margin.right - controlSize.width / 2,
    );
    final minY = margin.top + controlSize.height / 2;
    final maxY = math.max(
      minY,
      surfaceSize.height - margin.bottom - controlSize.height / 2,
    );
    return Offset(
      center.dx.clamp(minX, maxX).toDouble(),
      center.dy.clamp(minY, maxY).toDouble(),
    );
  }

  Offset _defaultJoystickCenter(Size surfaceSize, Size controlSize) {
    return Offset(
      _controlMargin.left + controlSize.width / 2,
      surfaceSize.height - _controlMargin.bottom - controlSize.height / 2,
    );
  }

  Offset _defaultFireCenter(Size surfaceSize, Size controlSize) {
    return Offset(
      surfaceSize.width - _controlMargin.right - controlSize.width / 2,
      surfaceSize.height - _controlMargin.bottom - controlSize.height / 2,
    );
  }

  EdgeInsets _sideZoneMargin(Size surfaceSize, {required bool leftSide}) {
    final horizontalSplit = surfaceSize.width >= surfaceSize.height;
    if (!horizontalSplit) {
      return _controlMargin;
    }
    final centerGap = surfaceSize.width * 0.52;
    return leftSide
        ? EdgeInsets.fromLTRB(
            _controlMargin.left,
            _controlMargin.top,
            centerGap,
            _controlMargin.bottom,
          )
        : EdgeInsets.fromLTRB(
            centerGap,
            _controlMargin.top,
            _controlMargin.right,
            _controlMargin.bottom,
          );
  }

  bool _isFireZone(Offset local, Size surfaceSize) {
    final horizontalSplit = surfaceSize.width >= surfaceSize.height;
    if (horizontalSplit) {
      return local.dx >= surfaceSize.width * 0.52;
    }
    return local.dx > surfaceSize.width * 0.56 &&
        local.dy > surfaceSize.height * 0.40;
  }

  bool _isJoystickZone(Offset local, Size surfaceSize) {
    final horizontalSplit = surfaceSize.width >= surfaceSize.height;
    if (horizontalSplit) {
      return local.dx <= surfaceSize.width * 0.48;
    }
    return !_isFireZone(local, surfaceSize);
  }

  Offset _eventCenter(BuildContext surfaceContext, PointerEvent event) {
    final renderObject = surfaceContext.findRenderObject();
    if (renderObject is! RenderBox) {
      return event.localPosition;
    }
    return renderObject.globalToLocal(event.position);
  }

  Offset _resolveFullscreenJoystickVector(Offset pointerPosition) {
    final center = _joystickCenter;
    if (center == null || _fullscreenJoystickControlSize == Size.zero) {
      return Offset.zero;
    }
    final radius = _fullscreenJoystickControlSize.shortestSide / 2;
    if (radius <= 0) {
      return Offset.zero;
    }
    final raw = (pointerPosition - center) / radius;
    final distance = raw.distance;
    if (distance <= 1.8) {
      return raw;
    }
    return raw / distance * 1.8;
  }

  void _handleJoystickFieldDown(
    BuildContext surfaceContext,
    PointerDownEvent event,
    Size surfaceSize,
    Size controlSize,
  ) {
    if (_fullscreenJoystickPointer != null) {
      return;
    }
    final local = _eventCenter(surfaceContext, event);
    if (!_isJoystickZone(local, surfaceSize)) {
      return;
    }
    final center = _clampControlCenter(
      local,
      surfaceSize,
      controlSize,
      margin: _sideZoneMargin(surfaceSize, leftSide: true),
    );
    setState(() {
      _fullscreenJoystickPointer = event.pointer;
      _joystickCenter = center;
      _fullscreenJoystickControlSize = controlSize;
      _practiceControlActive = !state._running;
    });
    state._lastTick = null;
    state._setJoystickVector(Offset.zero);
    _syncTicker();
  }

  void _handleFullscreenFieldDown(
    BuildContext surfaceContext,
    PointerDownEvent event,
    Size surfaceSize,
    Size joystickControlSize,
    Size fireControlSize,
  ) {
    final local = _eventCenter(surfaceContext, event);
    if (_isFireZone(local, surfaceSize)) {
      _moveFireControl(surfaceContext, event, surfaceSize, fireControlSize);
      if (state._running) {
        state._fire();
      }
      return;
    }
    if (_isJoystickZone(local, surfaceSize)) {
      _handleJoystickFieldDown(
        surfaceContext,
        event,
        surfaceSize,
        joystickControlSize,
      );
    }
  }

  void _handleJoystickFieldMove(
    BuildContext surfaceContext,
    PointerMoveEvent event,
  ) {
    if (event.pointer != _fullscreenJoystickPointer) {
      return;
    }
    state._setJoystickVector(
      _resolveFullscreenJoystickVector(_eventCenter(surfaceContext, event)),
    );
  }

  void _handleJoystickFieldUp(PointerEvent event) {
    if (event.pointer != _fullscreenJoystickPointer) {
      return;
    }
    setState(() {
      _fullscreenJoystickPointer = null;
      _practiceControlActive = false;
    });
    state._setJoystickVector(Offset.zero);
    _syncTicker();
  }

  void _moveFireControl(
    BuildContext surfaceContext,
    PointerDownEvent event,
    Size surfaceSize,
    Size controlSize,
  ) {
    final local = _eventCenter(surfaceContext, event);
    if (!_isFireZone(local, surfaceSize)) {
      return;
    }
    setState(() {
      _fireCenter = _clampControlCenter(
        local,
        surfaceSize,
        controlSize,
        margin: _sideZoneMargin(surfaceSize, leftSide: false),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('joystick_hand_eye_fullscreen_view'),
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: state._viewSignal,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final surfaceSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final compact = surfaceSize.shortestSide < 380;
              final joystickSize = compact ? 96.0 : 124.0;
              final joystickControlSize = Size.square(joystickSize + 16);
              final fireHeight = compact ? 84.0 : 104.0;
              final fireControlSize = Size(
                compact ? 118 : 142,
                fireHeight + 16,
              );
              final joystickCenter = _clampControlCenter(
                _joystickCenter ??
                    _defaultJoystickCenter(surfaceSize, joystickControlSize),
                surfaceSize,
                joystickControlSize,
                margin: _sideZoneMargin(surfaceSize, leftSide: true),
              );
              final fireCenter = _clampControlCenter(
                _fireCenter ?? _defaultFireCenter(surfaceSize, fireControlSize),
                surfaceSize,
                fireControlSize,
                margin: _sideZoneMargin(surfaceSize, leftSide: false),
              );
              return Stack(
                key: const ValueKey<String>('joystick_fullscreen_white_stage'),
                children: <Widget>[
                  Positioned.fill(
                    child: _stageBox(
                      activePadding: EdgeInsets.fromLTRB(
                        12,
                        compact ? 50 : 62,
                        12,
                        12,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (event) => _handleFullscreenFieldDown(
                        context,
                        event,
                        surfaceSize,
                        joystickControlSize,
                        fireControlSize,
                      ),
                      onPointerMove: (event) =>
                          _handleJoystickFieldMove(context, event),
                      onPointerUp: _handleJoystickFieldUp,
                      onPointerCancel: _handleJoystickFieldUp,
                    ),
                  ),
                  Positioned(
                    top: compact ? 6 : 8,
                    left: compact ? 6 : 8,
                    right: compact ? 6 : 8,
                    child: SafeArea(
                      bottom: false,
                      child: _topFullscreenBar(context, compact: compact),
                    ),
                  ),
                  if (_fullscreenJoystickPointer != null)
                    _floatingControl(
                      key: const ValueKey<String>(
                        'joystick_fullscreen_left_controls',
                      ),
                      center: joystickCenter,
                      size: joystickControlSize,
                      onPointerDown: (event) => _handleJoystickFieldDown(
                        context,
                        event,
                        surfaceSize,
                        joystickControlSize,
                      ),
                      child: _joystickControl(size: joystickSize),
                    ),
                  _floatingControl(
                    key: const ValueKey<String>(
                      'joystick_fullscreen_right_controls',
                    ),
                    center: fireCenter,
                    size: fireControlSize,
                    onPointerDown: (event) => _moveFireControl(
                      context,
                      event,
                      surfaceSize,
                      fireControlSize,
                    ),
                    child: _fireControl(height: fireHeight),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _floatingControl({
    required Key key,
    required Offset center,
    required Size size,
    required ValueChanged<PointerDownEvent> onPointerDown,
    required Widget child,
  }) {
    return Positioned(
      left: center.dx - size.width / 2,
      top: center.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: onPointerDown,
        child: KeyedSubtree(key: key, child: child),
      ),
    );
  }

  Widget _topFullscreenBar(BuildContext context, {required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _closeButton(context),
            const SizedBox(width: 8),
            Expanded(
              child: _JoystickFullscreenStatusPeek(
                state: state,
                expanded: _statusExpanded,
                compact: compact,
                onToggle: _toggleStatus,
              ),
            ),
            const SizedBox(width: 8),
            _JoystickFullscreenSessionActions(state: state),
          ],
        ),
        if (_statusExpanded) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _JoystickFullscreenStatusPanel(
              state: state,
              compact: compact,
            ),
          ),
        ],
      ],
    );
  }

  Widget _stageBox({EdgeInsets activePadding = EdgeInsets.zero}) {
    return KeyedSubtree(
      key: const ValueKey<String>('joystick_fullscreen_stage_zone'),
      child: _JoystickPlayStage(
        state: state,
        showStartOverlay: false,
        showStageStatus: false,
        activePadding: activePadding,
        fullBleed: true,
        whiteSurface: true,
        heightForConstraints: (constraints) => constraints.maxHeight,
      ),
    );
  }

  Widget _closeButton(BuildContext context) {
    return _HumanTestFullscreenIconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: Icons.close_rounded,
      tooltip: MaterialLocalizations.of(context).closeButtonLabel,
    );
  }

  Widget _fireControl({required double height}) {
    return _HumanTestFullscreenPanel(
      opacity: 0.42,
      shadowOpacity: 0.06,
      padding: const EdgeInsets.all(6),
      child: _JoystickFullscreenFireButton(state: state, height: height),
    );
  }

  Widget _joystickControl({required double size}) {
    return Center(
      child: _HandEyeJoystickPad(
        key: const ValueKey<String>('joystick_fullscreen_pad'),
        vector: state._joystickVector,
        enabled: true,
        size: size,
        fullscreenStyle: true,
        onChanged: state._setJoystickVector,
      ),
    );
  }
}

class _JoystickFullscreenStatusPeek extends StatelessWidget {
  const _JoystickFullscreenStatusPeek({
    required this.state,
    required this.expanded,
    required this.compact,
    required this.onToggle,
  });

  final _JoystickHandEyeCardState state;
  final bool expanded;
  final bool compact;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final progress = state._mode == _JoystickTestMode.timed
        ? _formatSeconds(state._remainingTenths / 10)
        : '${state._hits}/${state._targetGoal}';
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 250 : 480),
      child: _HumanTestFullscreenPanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: InkWell(
          key: const ValueKey<String>('joystick_fullscreen_status_toggle'),
          borderRadius: BorderRadius.circular(18),
          onTap: onToggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: _JoystickHandEyeCardState._accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pickUiText(
                    i18n,
                    zh: '进度 $progress · 命中 ${state._hits}',
                    en: 'Progress $progress · Hits ${state._hits}',
                    ja: 'Progress $progress · Hits ${state._hits}',
                    de: 'Progress $progress · Hits ${state._hits}',
                    fr: 'Progrès $progress · Affichages ${state._hits}',
                    es: 'Progresos alcanzados 1/año · Visto',
                    ru: 'Прогресс $progress · Хиты ${state._hits}',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoystickFullscreenStatusPanel extends StatelessWidget {
  const _JoystickFullscreenStatusPanel({
    required this.state,
    required this.compact,
  });

  final _JoystickHandEyeCardState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accuracy = state._shots == 0
        ? null
        : state._hits / state._shots * 100;
    final progress = state._mode == _JoystickTestMode.timed
        ? _formatSeconds(state._remainingTenths / 10)
        : '${state._hits}/${state._targetGoal}';
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 250 : 480),
      child: _HumanTestFullscreenPanel(
        key: const ValueKey<String>('joystick_fullscreen_status_panel'),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _HumanTestFullscreenMetric(
              label: pickUiText(
                i18n,
                zh: '进度',
                en: 'Progress',
                ja: 'Progress',
                de: 'Progress',
                fr: 'Progrès accomplis',
                es: 'Progresos',
                ru: 'Прогресс',
              ),
              value: progress,
              accent: _JoystickHandEyeCardState._accent,
            ),
            _HumanTestFullscreenMetric(
              label: pickUiText(
                i18n,
                zh: '命中',
                en: 'Hits',
                ja: 'Hits',
                de: 'Hits',
                fr: 'Coups',
                es: 'Golpes',
                ru: 'Хиты',
              ),
              value: '${state._hits}',
              accent: _JoystickHandEyeCardState._accent,
            ),
            _HumanTestFullscreenMetric(
              label: pickUiText(
                i18n,
                zh: '射空',
                en: 'Miss',
                ja: 'Miss',
                de: 'Miss',
                fr: 'Mlle',
                es: 'Miss',
                ru: 'Мисс.',
              ),
              value: '${state._shotsOff}',
              accent: _JoystickHandEyeCardState._accent,
            ),
            if (!compact)
              _HumanTestFullscreenMetric(
                label: pickUiText(
                  i18n,
                  zh: '准度',
                  en: 'Accuracy',
                  ja: '精度',
                  de: 'Accuracy',
                  fr: 'Accuracy',
                  es: 'Precisión',
                  ru: 'точность',
                ),
                value: accuracy == null ? '-' : '${accuracy.round()}%',
                accent: _JoystickHandEyeCardState._accent,
              ),
          ],
        ),
      ),
    );
  }
}

class _JoystickFullscreenSessionActions extends StatelessWidget {
  const _JoystickFullscreenSessionActions({required this.state});

  final _JoystickHandEyeCardState state;

  Future<void> _showSettings(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => _JoystickFullscreenSettingsDialog(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final reportEnabled = state._shots != 0 || state._hits != 0 || state._done;
    return _HumanTestFullscreenPanel(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            key: const ValueKey<String>('joystick_fullscreen_start_button'),
            tooltip: state._running
                ? pickUiText(
                    i18n,
                    zh: '结束',
                    en: 'Finish',
                    ja: 'Finish',
                    de: 'Finish',
                    fr: 'Finition',
                    es: 'Acabado',
                    ru: 'Закончить',
                  )
                : pickUiText(
                    i18n,
                    zh: '开始',
                    en: 'Start',
                    ja: 'Start',
                    de: 'Start',
                    fr: 'Démarrer',
                    es: 'Comienzo',
                    ru: 'Начинать',
                  ),
            onPressed: state._running ? state._finish : state._start,
            icon: Icon(
              state._running ? Icons.stop_rounded : Icons.play_arrow_rounded,
            ),
          ),
          IconButton(
            key: const ValueKey<String>('joystick_fullscreen_reset_button'),
            tooltip: pickUiText(
              i18n,
              zh: '重置',
              en: 'Reset',
              ja: 'Reset',
              de: 'Reset',
              fr: 'Réinitialiser',
              es: 'Reset',
              ru: 'сброс',
            ),
            onPressed: state._reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('joystick_fullscreen_settings_button'),
            tooltip: pickUiText(
              i18n,
              zh: '设置',
              en: 'Settings',
              ja: 'Settings',
              de: 'Settings',
              fr: 'Paramètres',
              es: 'Ajustes',
              ru: 'Настройки',
            ),
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('joystick_fullscreen_report_button'),
            tooltip: pickUiText(
              i18n,
              zh: '报告',
              en: 'Report',
              ja: 'Report',
              de: 'Report',
              fr: 'Rapport annuel',
              es: 'Informe',
              ru: 'Доклад',
            ),
            onPressed: reportEnabled ? state._showJoystickReport : null,
            icon: const Icon(Icons.assessment_rounded),
          ),
        ],
      ),
    );
  }
}

class _JoystickFullscreenSettingsDialog extends StatelessWidget {
  const _JoystickFullscreenSettingsDialog({required this.state});

  final _JoystickHandEyeCardState state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state._viewSignal,
      builder: (context, _) {
        final i18n = AppI18n(Localizations.localeOf(context).languageCode);
        final mediaSize = MediaQuery.sizeOf(context);
        final dialogWidth = math.min(
          420.0,
          math.max(280.0, mediaSize.width - 32),
        );
        return AlertDialog(
          key: const ValueKey<String>('joystick_fullscreen_settings_dialog'),
          title: Text(
            pickUiText(
              i18n,
              zh: '摇杆设置',
              en: 'Joystick settings',
              ja: 'Joystick settings',
              de: 'Joystick settings',
              fr: 'Paramètres du joystick',
              es: 'Ajustes de joystick',
              ru: 'Настройка Joystick',
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          content: SizedBox(
            width: dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HumanSettingsSection(
                    title: pickUiText(
                      i18n,
                      zh: '摇杆设置',
                      en: 'Joystick settings',
                      ja: 'Joystick settings',
                      de: 'Joystick settings',
                      fr: 'Paramètres du joystick',
                      es: 'Ajustes de joystick',
                      ru: 'Настройка Joystick',
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '测试方案、准星速率和命中后刷新方式',
                      en: 'Test mode, crosshair response speed, and respawn timing',
                      ja: 'Test mode, crosshair response speed, and respawn timing',
                      de: 'Test mode, crosshair response speed, and respawn timing',
                      fr: 'Mode d\'essai, vitesse de réponse des cheveux croisés et chronométrage de remise en suspension',
                      es: 'Modo de prueba, velocidad de respuesta cruzada y tiempo de reaparecer',
                      ru: 'Режим испытания, скорость перекрестного реагирования и время повторного запуска',
                    ),
                    child: state._buildJoystickSettings(i18n),
                  ),
                  const SizedBox(height: 12),
                  _HumanSettingsSection(
                    title: pickUiText(
                      i18n,
                      zh: '目标移动设置',
                      en: 'Target movement settings',
                      ja: 'Target movement settings',
                      de: 'Target movement settings',
                      fr: 'Paramètres de mouvement de la cible',
                      es: 'Ajustes del movimiento objetivo',
                      ru: 'Настройки движения цели',
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '默认关闭：让目标在刷新后持续移动，增加追踪压力。',
                      en: 'Off by default: keeps targets moving after spawn for harder tracking.',
                      ja: 'Off by default: keeps targets moving after spawn for harder tracking.',
                      de: 'Off by default: keeps targets moving after spawn for harder tracking.',
                      fr: 'Arrêt par défaut : maintient les cibles en mouvement après le frai pour un suivi plus difficile.',
                      es: 'De forma predeterminada: mantiene los objetivos que se mueven después de desove para un seguimiento más difícil.',
                      ru: 'Выключено по умолчанию: держит цели движутся после нереста для более сложного отслеживания.',
                    ),
                    child: state._buildJoystickMovementSettings(i18n),
                  ),
                  const SizedBox(height: 12),
                  _HumanSettingsSection(
                    title: pickUiText(
                      i18n,
                      zh: '高阶干扰设置',
                      en: 'Advanced interference',
                      ja: '高度な干渉',
                      de: 'Advanced interference',
                      fr: 'Advanced interference',
                      es: 'Interferencia avanzada',
                      ru: 'Расширенное вмешательство',
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '默认关闭：目标附近可随机出现不同颜色的假目标。',
                      en: 'Off by default: color-coded false targets may appear around the real target.',
                      ja: 'Off by default: color-coded false targets may appear around the real target.',
                      de: 'Off by default: color-coded false targets may appear around the real target.',
                      fr: 'Désactivé par défaut : les fausses cibles codées en couleur peuvent apparaître autour de la cible réelle.',
                      es: 'De forma predeterminada: los falsos blancos codificados por colores pueden aparecer alrededor del objetivo real.',
                      ru: 'Выключено по умолчанию: цветные ложные цели могут появляться вокруг реальной цели.',
                    ),
                    child: state._buildJoystickDistractorSettings(i18n),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        );
      },
    );
  }
}

class _JoystickFullscreenFireButton extends StatelessWidget {
  const _JoystickFullscreenFireButton({
    required this.state,
    required this.height,
  });

  final _JoystickHandEyeCardState state;
  final double height;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: FilledButton.icon(
        key: const ValueKey<String>('joystick_fullscreen_fire_button'),
        onPressed: state._running ? state._fire : null,
        icon: const Icon(Icons.my_location_rounded, size: 28),
        label: Text(
          pickUiText(
            i18n,
            zh: '射击',
            en: 'Fire',
            ja: 'Fire',
            de: 'Fire',
            fr: 'Feu',
            es: 'Fuego',
            ru: 'Огонь',
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.surface.withValues(alpha: 0.62),
          foregroundColor: _JoystickHandEyeCardState._accent,
          disabledBackgroundColor: colorScheme.surface.withValues(alpha: 0.34),
          disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(
            alpha: 0.60,
          ),
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: height < 92 ? 10 : 14,
          ),
          minimumSize: Size.fromHeight(height),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(
            color: _JoystickHandEyeCardState._accent.withValues(alpha: 0.28),
          ),
        ),
      ),
    );
  }
}
