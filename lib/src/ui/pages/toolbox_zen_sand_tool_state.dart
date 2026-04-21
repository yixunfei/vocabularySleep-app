part of 'toolbox_zen_sand_tool.dart';

class _ZenSandCanvasStore {
  List<ZenSandAction> actions = <ZenSandAction>[];
  List<ZenSandAction> redoStack = <ZenSandAction>[];
  List<Offset> workingStroke = <Offset>[];
  String backgroundId = zenSandDefaultBackgroundId;
  String toolId = zenSandDefaultToolId;
  double brushSize = zenSandDefaultBrushSize;
  int colorValue = zenSandDefaultColorValue;
  bool hapticsEnabled = true;
  bool guideEnabled = true;
  bool soundEnabled = zenSandDefaultSoundEnabled;
  bool drawFromContactPoint = zenSandDefaultDrawFromContactPoint;
  double touchOffset = zenSandDefaultTouchOffset;
  bool immersiveMode = false;
  double viewportScale = 1;
  Offset viewportOffset = Offset.zero;
  _ZenGestureMode gestureMode = _ZenGestureMode.idle;
  double gestureScaleStart = 1;
  Offset gestureWorldAnchor = Offset.zero;
  String? lastPresetId;

  void restoreFromPrefs(ZenSandPrefsState prefs, {required int maxActions}) {
    backgroundId = prefs.backgroundId;
    toolId = prefs.toolId;
    brushSize = prefs.brushSize;
    colorValue = prefs.colorValue;
    hapticsEnabled = prefs.hapticsEnabled;
    guideEnabled = prefs.guidanceEnabled;
    soundEnabled = prefs.soundEnabled;
    drawFromContactPoint = prefs.drawFromContactPoint;
    touchOffset = prefs.touchOffset;
    actions = prefs.actions.take(maxActions).toList(growable: false);
    redoStack = <ZenSandAction>[];
    workingStroke = <Offset>[];
    gestureMode = _ZenGestureMode.idle;
    lastPresetId = null;
  }

  ZenSandPrefsState toPrefsState({required int maxActions}) {
    return ZenSandPrefsState(
      backgroundId: backgroundId,
      toolId: toolId,
      brushSize: brushSize,
      colorValue: colorValue,
      hapticsEnabled: hapticsEnabled,
      guidanceEnabled: guideEnabled,
      soundEnabled: soundEnabled,
      drawFromContactPoint: drawFromContactPoint,
      touchOffset: touchOffset,
      actions: actions.take(maxActions).toList(growable: false),
    );
  }

  void appendAction(ZenSandAction action, {required int maxActions}) {
    final nextActions = <ZenSandAction>[...actions, action];
    if (nextActions.length > maxActions) {
      nextActions.removeRange(0, nextActions.length - maxActions);
    }
    actions = nextActions;
    redoStack = <ZenSandAction>[];
  }

  void resetViewport() {
    viewportScale = 1;
    viewportOffset = Offset.zero;
  }

  void setBrushSize(double value) {
    brushSize = value.clamp(14.0, 96.0);
  }

  void startTransform({
    required Offset focalPoint,
    required Size size,
  }) {
    gestureMode = _ZenGestureMode.transform;
    gestureScaleStart = viewportScale;
    final worldFocal = (focalPoint - viewportOffset) / viewportScale;
    gestureWorldAnchor = Offset(
      worldFocal.dx.clamp(0.0, size.width).toDouble(),
      worldFocal.dy.clamp(0.0, size.height).toDouble(),
    );
  }

  bool updateTransform({
    required Offset focalPoint,
    required double scale,
    required Size size,
    required Offset Function(Offset offset, Size size, double scale)
    clampViewportOffset,
  }) {
    final nextScale = (gestureScaleStart * scale).clamp(1.0, _maxViewportScale);
    final rawOffset = focalPoint - (gestureWorldAnchor * nextScale);
    final nextOffset = clampViewportOffset(rawOffset, size, nextScale);
    if (viewportScale == nextScale && viewportOffset == nextOffset) {
      return false;
    }
    viewportScale = nextScale;
    viewportOffset = nextOffset;
    return true;
  }

  bool undo() {
    if (actions.isEmpty) {
      return false;
    }
    final nextActions = <ZenSandAction>[...actions];
    final removed = nextActions.removeLast();
    actions = nextActions;
    redoStack = <ZenSandAction>[removed, ...redoStack];
    gestureMode = _ZenGestureMode.idle;
    workingStroke = <Offset>[];
    return true;
  }

  bool redo({required int maxActions}) {
    if (redoStack.isEmpty) {
      return false;
    }
    final redoActions = <ZenSandAction>[...redoStack];
    final restored = redoActions.removeAt(0);
    redoStack = redoActions;
    final nextActions = <ZenSandAction>[...actions, restored];
    if (nextActions.length > maxActions) {
      nextActions.removeRange(0, nextActions.length - maxActions);
    }
    actions = nextActions;
    gestureMode = _ZenGestureMode.idle;
    workingStroke = <Offset>[];
    return true;
  }

  bool keepOnlyStones() {
    if (!actions.any((action) => action.isStroke)) {
      return false;
    }
    actions = actions.where((action) => action.isStone).toList(growable: false);
    redoStack = <ZenSandAction>[];
    gestureMode = _ZenGestureMode.idle;
    workingStroke = <Offset>[];
    lastPresetId = null;
    return true;
  }

  bool clearAllActions() {
    if (actions.isEmpty) {
      return false;
    }
    actions = <ZenSandAction>[];
    redoStack = <ZenSandAction>[];
    gestureMode = _ZenGestureMode.idle;
    workingStroke = <Offset>[];
    lastPresetId = null;
    return true;
  }

  void applyRitualPreset({
    required _ZenRitualPresetSpec preset,
    required List<ZenSandAction> presetActions,
    required bool replace,
    required int maxActions,
  }) {
    final nextActions = replace
        ? presetActions
        : <ZenSandAction>[...actions, ...presetActions];
    if (nextActions.length > maxActions) {
      nextActions.removeRange(0, nextActions.length - maxActions);
    }
    if (replace) {
      backgroundId = preset.backgroundId;
      resetViewport();
    }
    toolId = preset.toolId;
    brushSize = preset.brushSize;
    if (preset.colorValue != null) {
      colorValue = preset.colorValue!;
    }
    actions = nextActions;
    redoStack = <ZenSandAction>[];
    workingStroke = <Offset>[];
    gestureMode = _ZenGestureMode.idle;
    lastPresetId = preset.id;
  }
}

class _ZenSandInteractionStore {
  final Set<int> activePointers = <int>{};
  Size? currentCanvasSize;
  Offset? lastTouchContactPoint;
  Offset? lastResolvedInputPoint;
  double strokeTravelDistance = 0;
  double lastAccentDistance = 0;
  int waterHoldTicks = 0;
  DateTime lastSoundAccentAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool transformHintVisible = false;

  bool get hasTransformPointers => activePointers.length >= 2;
  bool get hasLessThanTransformPointers => activePointers.length < 2;
  bool get hasNoPointers => activePointers.isEmpty;

  bool canDriveWaterHold({
    required bool mounted,
    required _ZenGestureMode gestureMode,
    required String toolId,
    required List<Offset> workingStroke,
    required Offset? lastResolvedInputPoint,
    required Size? canvasSize,
  }) {
    return mounted &&
        gestureMode == _ZenGestureMode.draw &&
        toolId == 'water' &&
        workingStroke.isNotEmpty &&
        lastResolvedInputPoint != null &&
        canvasSize != null;
  }

  bool canFireTransformIntent({required bool mounted}) {
    return mounted && !hasLessThanTransformPointers;
  }

  void addActivePointer(int pointer) {
    activePointers.add(pointer);
  }

  void removeActivePointer(int pointer) {
    activePointers.remove(pointer);
  }

  bool updateTransformHintVisible(bool value) {
    if (transformHintVisible == value) {
      return false;
    }
    transformHintVisible = value;
    return true;
  }

  void resetStrokeAudioSync() {
    strokeTravelDistance = 0;
    lastAccentDistance = 0;
    waterHoldTicks = 0;
    lastSoundAccentAt = DateTime.fromMillisecondsSinceEpoch(0);
  }

  void beginWaterHoldCycle() {
    waterHoldTicks = 0;
  }

  int incrementWaterHoldTicks() {
    waterHoldTicks += 1;
    return waterHoldTicks;
  }

  bool shouldPlayAccent({
    required double gestureDistance,
    required double accentStride,
    required Duration accentGap,
    required bool force,
    required DateTime now,
  }) {
    strokeTravelDistance += gestureDistance;
    final shouldPlay =
        force ||
        (strokeTravelDistance - lastAccentDistance >= accentStride &&
            now.difference(lastSoundAccentAt) >= accentGap);
    if (!shouldPlay) {
      return false;
    }
    lastAccentDistance = strokeTravelDistance;
    lastSoundAccentAt = now;
    return true;
  }

  void clearTouchPoints() {
    lastTouchContactPoint = null;
    lastResolvedInputPoint = null;
  }
}

class _ZenSandInteractionController {
  Timer? _waterHoldTimer;
  Timer? _transformIntentTimer;

  void startWaterHoldFlow({
    required Duration period,
    required bool Function() shouldContinue,
    required void Function() onTick,
    required void Function() onStop,
  }) {
    _waterHoldTimer?.cancel();
    _waterHoldTimer = Timer.periodic(period, (_) {
      if (!shouldContinue()) {
        onStop();
        return;
      }
      onTick();
    });
  }

  void cancelWaterHoldTimer() {
    _waterHoldTimer?.cancel();
    _waterHoldTimer = null;
  }

  void scheduleTransformIntent({
    required Duration delay,
    required bool Function() shouldFire,
    required void Function() onFire,
    required void Function() onCancel,
  }) {
    _transformIntentTimer?.cancel();
    _transformIntentTimer = Timer(delay, () {
      _transformIntentTimer = null;
      if (!shouldFire()) {
        onCancel();
        return;
      }
      onFire();
    });
  }

  void cancelTransformIntent() {
    _transformIntentTimer?.cancel();
    _transformIntentTimer = null;
  }

  void dispose() {
    cancelWaterHoldTimer();
    cancelTransformIntent();
  }
}
