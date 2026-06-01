part of '../toolbox_sound_tools.dart';

class _KalimbaTine extends StatelessWidget {
  const _KalimbaTine({
    required this.left,
    required this.width,
    required this.height,
    required this.active,
    required this.label,
    required this.index,
    required this.count,
    required this.immersive,
    required this.textStyle,
  });

  final double left;
  final double width;
  final double height;
  final bool active;
  final String label;
  final int index;
  final int count;
  final bool immersive;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final lowToHigh = count <= 1 ? 0.0 : index / (count - 1);
    final tineHeight = height * (0.66 - lowToHigh * 0.24);
    final top = height * 0.22;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: tineHeight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, active ? 5 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              active ? const Color(0xFFFFE08A) : const Color(0xFFF7EFE2),
              active ? const Color(0xFFD8A734) : const Color(0xFF9CA3AF),
              immersive ? const Color(0xFF394150) : const Color(0xFF60717A),
            ],
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFFFD166).withValues(alpha: 0.42),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: textStyle?.copyWith(
                  color: active
                      ? const Color(0xFF3B2A09)
                      : (immersive ? Colors.white : const Color(0xFF24333A)),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KalimbaSideTine extends StatelessWidget {
  const _KalimbaSideTine({
    required this.top,
    required this.left,
    required this.width,
    required this.height,
    required this.active,
    required this.label,
    required this.immersive,
    required this.textStyle,
  });

  final double top;
  final double left;
  final double width;
  final double height;
  final bool active;
  final String label;
  final bool immersive;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: math.max(18, height),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(active ? 7 : 0, 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              active ? const Color(0xFFFFE08A) : const Color(0xFFF8EFE0),
              active ? const Color(0xFFE0B13E) : const Color(0xFFBFC6CA),
              immersive ? const Color(0xFF3F4655) : const Color(0xFF64747D),
            ],
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFFFFD166).withValues(alpha: 0.42),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 8,
                    offset: const Offset(5, 0),
                  ),
                ],
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: textStyle?.copyWith(
                  color: active
                      ? const Color(0xFF3B2A09)
                      : (immersive ? Colors.white : const Color(0xFF24333A)),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
