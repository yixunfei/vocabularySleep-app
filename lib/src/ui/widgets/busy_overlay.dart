import 'package:flutter/material.dart';

class BusyOverlay extends StatelessWidget {
  const BusyOverlay({
    super.key,
    required this.visible,
    this.message,
    this.detail,
    this.progress,
  });

  final bool visible;
  final String? message;
  final String? detail;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final text = (message ?? 'Processing...').trim();
    final extra = (detail ?? '').trim();
    final normalizedProgress = progress?.clamp(0.0, 1.0).toDouble();
    final progressLabel = normalizedProgress == null
        ? null
        : '${(normalizedProgress * 100).round()}%';

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.18),
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (normalizedProgress == null)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.6),
                      )
                    else
                      Column(
                        children: <Widget>[
                          SizedBox(
                            width: 220,
                            child: LinearProgressIndicator(
                              value: normalizedProgress,
                              minHeight: 7,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            progressLabel!,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    Text(
                      text.isEmpty ? 'Processing...' : text,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (extra.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        extra,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
