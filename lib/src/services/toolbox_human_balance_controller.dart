import 'dart:math' as math;

class ToolboxHumanBalanceTilt {
  const ToolboxHumanBalanceTilt({
    required this.xDegrees,
    required this.yDegrees,
  });

  final double xDegrees;
  final double yDegrees;

  double get magnitudeDegrees {
    return math.sqrt(xDegrees * xDegrees + yDegrees * yDegrees);
  }
}

class ToolboxHumanBalanceState {
  const ToolboxHumanBalanceState({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.elapsedSeconds,
    required this.maxOffset,
    required this.initialImpulse,
    required this.maxTiltMagnitude,
    required this.running,
    required this.fallen,
  });

  const ToolboxHumanBalanceState.idle()
    : x = 0,
      y = 0,
      vx = 0,
      vy = 0,
      elapsedSeconds = 0,
      maxOffset = 0,
      initialImpulse = 0,
      maxTiltMagnitude = 0,
      running = false,
      fallen = false;

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double elapsedSeconds;
  final double maxOffset;
  final double initialImpulse;
  final double maxTiltMagnitude;
  final bool running;
  final bool fallen;

  double get currentOffset => math.max(x.abs(), y.abs());

  double get maxOffsetPercent => maxOffset * 100;

  double get currentOffsetPercent => currentOffset * 100;

  ToolboxHumanBalanceState copyWith({
    double? x,
    double? y,
    double? vx,
    double? vy,
    double? elapsedSeconds,
    double? maxOffset,
    double? initialImpulse,
    double? maxTiltMagnitude,
    bool? running,
    bool? fallen,
  }) {
    return ToolboxHumanBalanceState(
      x: x ?? this.x,
      y: y ?? this.y,
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      maxOffset: maxOffset ?? this.maxOffset,
      initialImpulse: initialImpulse ?? this.initialImpulse,
      maxTiltMagnitude: maxTiltMagnitude ?? this.maxTiltMagnitude,
      running: running ?? this.running,
      fallen: fallen ?? this.fallen,
    );
  }
}

class ToolboxHumanBalanceController {
  ToolboxHumanBalanceController({math.Random? random})
    : _random = random ?? math.Random();

  static const double maxTiltDegrees = 42;
  static const double fallLimit = 1.07;
  static const double maxBallSpeed = 0.82;
  static const double _gravityScale = 0.98;
  static const double _dampingPerSecond = 0.60;
  static const double _edgeGripStart = 0.72;
  static const double _edgeGripDampingPerSecond = 0.34;
  static const double _tiltDeadZoneDegrees = 1.15;
  static const double _tiltResponseGain = 1.18;
  static const double _minInitialImpulse = 0.08;
  static const double _maxInitialImpulse = 0.15;

  final math.Random _random;
  ToolboxHumanBalanceState _state = const ToolboxHumanBalanceState.idle();

  ToolboxHumanBalanceState get state => _state;

  void reset() {
    _state = const ToolboxHumanBalanceState.idle();
  }

  void start({math.Random? random}) {
    final source = random ?? _random;
    final direction = source.nextDouble() * math.pi * 2;
    final impulse =
        _minInitialImpulse +
        source.nextDouble() * (_maxInitialImpulse - _minInitialImpulse);
    _state = ToolboxHumanBalanceState(
      x: 0,
      y: 0,
      vx: math.cos(direction) * impulse,
      vy: math.sin(direction) * impulse,
      elapsedSeconds: 0,
      maxOffset: 0,
      initialImpulse: impulse,
      maxTiltMagnitude: 0,
      running: true,
      fallen: false,
    );
  }

  void tick({
    required double dtSeconds,
    required double tiltXDegrees,
    required double tiltYDegrees,
  }) {
    if (!_state.running || _state.fallen || dtSeconds <= 0) {
      return;
    }
    final dt = dtSeconds.clamp(0.001, 0.08).toDouble();
    final clampedX = clampTilt(tiltXDegrees);
    final clampedY = clampTilt(tiltYDegrees);
    final ax = math.sin(_toRadians(_effectiveTilt(clampedX))) * _gravityScale;
    final ay = math.sin(_toRadians(_effectiveTilt(clampedY))) * _gravityScale;
    final damping = math.pow(_dampingPerSecond, dt).toDouble();
    var vx = (_state.vx + ax * dt) * damping;
    var vy = (_state.vy + ay * dt) * damping;
    final edgeFactor =
        ((_state.currentOffset - _edgeGripStart) / (fallLimit - _edgeGripStart))
            .clamp(0, 1)
            .toDouble();
    if (edgeFactor > 0) {
      final edgeDamping = math
          .pow(_edgeGripDampingPerSecond, dt * edgeFactor)
          .toDouble();
      if (_isMovingOutward(position: _state.x, velocity: vx)) {
        vx *= edgeDamping;
      }
      if (_isMovingOutward(position: _state.y, velocity: vy)) {
        vy *= edgeDamping;
      }
    }
    final cappedVelocity = _capVelocity(vx, vy);
    vx = cappedVelocity.$1;
    vy = cappedVelocity.$2;
    final x = _state.x + vx * dt;
    final y = _state.y + vy * dt;
    final currentOffset = math.max(x.abs(), y.abs());
    final tiltMagnitude = math
        .sqrt(clampedX * clampedX + clampedY * clampedY)
        .clamp(0, maxTiltDegrees);
    final fallen = x.abs() > fallLimit || y.abs() > fallLimit;
    _state = ToolboxHumanBalanceState(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      elapsedSeconds: _state.elapsedSeconds + dt,
      maxOffset: math.max(_state.maxOffset, currentOffset),
      initialImpulse: _state.initialImpulse,
      maxTiltMagnitude: math.max(
        _state.maxTiltMagnitude,
        tiltMagnitude.toDouble(),
      ),
      running: !fallen,
      fallen: fallen,
    );
  }

  static double clampTilt(double value) {
    return value.clamp(-maxTiltDegrees, maxTiltDegrees).toDouble();
  }

  static double _effectiveTilt(double value) {
    final magnitude = value.abs();
    if (magnitude <= _tiltDeadZoneDegrees) {
      return 0;
    }
    final adjusted = (magnitude - _tiltDeadZoneDegrees) * _tiltResponseGain;
    return clampTilt(adjusted) * value.sign;
  }

  static bool _isMovingOutward({
    required double position,
    required double velocity,
  }) {
    return position.abs() > _edgeGripStart &&
        position.sign == velocity.sign &&
        velocity.abs() > 0;
  }

  static (double, double) _capVelocity(double vx, double vy) {
    final speed = math.sqrt(vx * vx + vy * vy);
    if (speed <= maxBallSpeed || speed == 0) {
      return (vx, vy);
    }
    final scale = maxBallSpeed / speed;
    return (vx * scale, vy * scale);
  }

  static ToolboxHumanBalanceTilt tiltFromGravity({
    required double x,
    required double y,
    required double z,
  }) {
    final pitch = math.atan2(-x, math.sqrt(y * y + z * z)) * 180 / math.pi;
    final roll = math.atan2(y, z) * 180 / math.pi;
    return ToolboxHumanBalanceTilt(
      xDegrees: clampTilt(roll),
      yDegrees: clampTilt(pitch),
    );
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
