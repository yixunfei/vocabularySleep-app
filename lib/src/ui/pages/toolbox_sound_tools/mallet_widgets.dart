part of '../toolbox_sound_tools.dart';

class _MalletBar extends StatelessWidget {
  const _MalletBar({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
    required this.label,
    required this.active,
    required this.immersive,
    required this.rotated,
    required this.textStyle,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final Color color;
  final String label;
  final bool active;
  final bool immersive;
  final bool rotated;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final highlight = active ? 0.16 : 0.0;
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(
          rotated ? (active ? 7 : 0) : 0,
          rotated ? 0 : (active ? 7 : 0),
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: rotated ? Alignment.centerLeft : Alignment.topCenter,
            end: rotated ? Alignment.centerRight : Alignment.bottomCenter,
            colors: <Color>[
              Color.lerp(color, Colors.white, 0.34 + highlight)!,
              color,
              Color.lerp(color, Colors.black, immersive ? 0.18 : 0.1)!,
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.48)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: active
                  ? color.withValues(alpha: 0.48)
                  : Colors.black.withValues(alpha: immersive ? 0.26 : 0.14),
              blurRadius: active ? 20 : 10,
              offset: rotated ? const Offset(5, 0) : const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Align(
              alignment: rotated ? Alignment.centerRight : Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  right: rotated ? 9 : 0,
                  top: rotated ? 0 : 9,
                ),
                child: _MalletScrew(immersive: immersive),
              ),
            ),
            Align(
              alignment: rotated
                  ? Alignment.centerLeft
                  : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  left: rotated ? 10 : 0,
                  bottom: rotated ? 0 : 10,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: textStyle?.copyWith(
                      color: immersive ? Colors.white : const Color(0xFF1F2937),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MalletScrew extends StatelessWidget {
  const _MalletScrew({required this.immersive});

  final bool immersive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: immersive
            ? Colors.white.withValues(alpha: 0.82)
            : const Color(0xFFE8EDF3),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF64748B)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const SizedBox(width: 10, height: 10),
    );
  }
}
