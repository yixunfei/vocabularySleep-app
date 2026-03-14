import 'package:flutter/material.dart';

class BusyOverlay extends StatelessWidget {
  const BusyOverlay({
    super.key,
    required this.visible,
    this.message,
    this.detail,
  });

  final bool visible;
  final String? message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final text = (message ?? 'Processing...').trim();
    final extra = (detail ?? '').trim();

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
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
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
