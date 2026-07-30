import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/ads/ads.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/settings/settings.dart';

/// The one way a game offers a rewarded ad.
///
/// It renders nothing at all unless an ad is loaded and the game still has an
/// offer left, so a player never taps a deal the app cannot honour. [onReward]
/// runs only when the ad played through and the reward was earned — every
/// other outcome leaves the run exactly as it was.
class RewardedButton extends StatefulWidget {
  const RewardedButton({
    required this.label,
    required this.onReward,
    this.icon = Icons.play_circle_fill_rounded,
    this.isOffered = true,
    this.game,
    super.key,
  });

  /// What the player gets, in their words: 'Keep playing', 'Clear a tile'.
  final String label;

  final IconData icon;

  /// Applied when the reward is earned.
  final VoidCallback onReward;

  /// Whether the game still has an offer left this run. A game passes `false`
  /// once its per-run cap is spent, which hides the button rather than
  /// letting the player tap into a refusal.
  final bool isOffered;

  /// Frozen while the ad is up. Null where there is nothing to freeze.
  final FlameGame? game;

  @override
  State<RewardedButton> createState() => _RewardedButtonState();
}

class _RewardedButtonState extends State<RewardedButton> {
  bool _isShowing = false;

  Future<void> _watch() async {
    final ads = context.read<GameAds>();
    final sounds = context.read<GameSounds>();
    final settings = context.read<GameSettings>();

    setState(() => _isShowing = true);
    final earned = await duringAdBreak(
      sounds: sounds,
      settings: settings,
      game: widget.game,
      show: ads.showReward,
    );

    if (!mounted) return;
    setState(() => _isShowing = false);
    if (earned) widget.onReward();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOffered) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: context.read<GameAds>().isRewardReady,
      builder: (context, isReady, _) {
        if (!isReady && !_isShowing) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FilledButton.icon(
            onPressed: _isShowing ? null : _watch,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFB703),
              foregroundColor: const Color(0xFF10143A),
              disabledBackgroundColor: const Color(0x66FFB703),
            ),
            icon: _isShowing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(widget.icon),
            // The ad is named on the button on purpose. An opt-in reward the
            // player did not know was an ad is a bait, and it only works once.
            label: Text('${widget.label} (watch ad)'),
          ),
        );
      },
    );
  }
}
