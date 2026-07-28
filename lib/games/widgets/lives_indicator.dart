import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Remaining lives, drawn as hearts.
///
/// Filled versus outlined carries the meaning as well as the colour does, so
/// it still reads without relying on red.
class LivesIndicator extends StatelessWidget {
  const LivesIndicator({
    required this.lives,
    required this.maxLives,
    super.key,
  });

  final ValueListenable<int> lives;

  final int maxLives;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: lives,
      builder: (context, value, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < maxLives; i++)
              Icon(
                i < value ? Icons.favorite : Icons.favorite_border,
                color: i < value ? const Color(0xFFE63946) : Colors.white38,
                size: 22,
              ),
          ],
        );
      },
    );
  }
}
