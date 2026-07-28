import 'package:flutter/material.dart';

/// End-of-run line that either celebrates a new personal best or shows the
/// record still to beat.
///
/// Games pass their own wording, since "best" means a high score in one game
/// and a low move count in another.
class RecordLine extends StatelessWidget {
  const RecordLine({
    required this.isNewRecord,
    required this.text,
    super.key,
  });

  /// Whether the run that just ended set a new record.
  final bool isNewRecord;

  /// Wording to show, for example `New record!` or `Best: 24 moves`.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isNewRecord) ...[
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFFD166),
            size: 20,
          ),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isNewRecord ? const Color(0xFFFFD166) : Colors.white70,
            fontWeight: isNewRecord ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
