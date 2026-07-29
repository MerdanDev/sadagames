import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/ads/ads.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/settings/settings.dart';

/// The pair of buttons every game over panel ends with.
///
/// Both of them are the moment the player *leaves* a finished run, which is
/// the only place the between-runs interstitial belongs. Putting it on the
/// panel itself would cover a score the player is still reading, and putting
/// it on every game over would fire it every half minute — see [AdPacing] for
/// how rarely it actually appears.
class GameOverActions extends StatelessWidget {
  const GameOverActions({
    required this.onPlayAgain,
    required this.wasNewRecord,
    this.playAgainLabel = 'Play again',
    super.key,
  });

  /// Starts the next run. Called after any ad has been dismissed.
  final VoidCallback onPlayAgain;

  /// Whether the run just set a personal best, which suppresses the ad.
  final bool wasNewRecord;

  final String playAgainLabel;

  Future<void> _adBreak(BuildContext context) {
    final ads = context.read<GameAds>();
    return duringAdBreak(
      sounds: context.read<GameSounds>(),
      settings: context.read<GameSettings>(),
      show: () => ads.showBetweenRuns(wasNewRecord: wasNewRecord),
    );
  }

  Future<void> _playAgain(BuildContext context) async {
    await _adBreak(context);
    onPlayAgain();
  }

  Future<void> _backToGames(BuildContext context) async {
    // Taken before the await: the ad outlives this frame, and the context may
    // not be around to look a Navigator up by the time it closes.
    final navigator = Navigator.of(context);
    await _adBreak(context);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => _playAgain(context),
          child: Text(playAgainLabel),
        ),
        TextButton(
          onPressed: () => _backToGames(context),
          child: const Text(
            'Back to games',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
