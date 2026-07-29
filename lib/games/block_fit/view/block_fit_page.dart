import 'package:flame/game.dart' hide Route;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/ads/ads.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/games/block_fit/block_fit.dart';
import 'package:sadagames/games/widgets/widgets.dart';
import 'package:sadagames/progress/progress.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

class BlockFitPage extends StatelessWidget {
  const BlockFitPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const BlockFitPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AudioCubit(
        sounds: context.read<GameSounds>(),
        settings: context.read<GameSettings>(),
      ),
      // No SafeArea here on purpose: the board fills the screen edge to edge
      // and only the HUD is inset.
      child: const Scaffold(body: BlockFitView()),
    );
  }
}

class BlockFitView extends StatefulWidget {
  const BlockFitView({super.key, this.game});

  final BlockFitGame? game;

  @override
  State<BlockFitView> createState() => _BlockFitViewState();
}

class _BlockFitViewState extends State<BlockFitView> {
  /// Held rather than read in dispose, where context is gone.
  late final GameSounds _sounds;

  late final BlockFitGame _game;

  @override
  void initState() {
    super.initState();
    _sounds = context.read<GameSounds>();
    _game =
        widget.game ??
        BlockFitGame(
          sounds: _sounds,
          records: context.read<GameRecords>(),
          progress: context.read<GameProgress>(),
        );
    _sounds.startMusic();
    // Warmed on the way in, so the offer is already there when the run
    // ends. Loading at game over would show the player a button that
    // appears seconds late, after they have moved on.
    context.read<GameAds>().loadReward();
  }

  @override
  void dispose() {
    _sounds.stopMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // StackFit.expand keeps the canvas full screen: the HUD is positioned, so
    // it cannot size the stack, and a loose stack would collapse onto it.
    return Stack(
      fit: StackFit.expand,
      children: [
        GameWidget(
          game: _game,
          overlayBuilderMap: {
            BlockFitGame.gameOverOverlayId: (_, BlockFitGame game) =>
                _GameOverOverlay(game: game),
          },
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _ScoreLabel(
                    score: _game.scoreNotifier,
                    best: _game.bestScoreNotifier,
                  ),
                  const Spacer(),
                  _SwapButton(game: _game),
                  BlocBuilder<AudioCubit, AudioState>(
                    builder: (context, state) {
                      return IconButton(
                        icon: Icon(
                          state.volume == 0
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            context.read<AudioCubit>().toggleVolume(),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreLabel extends StatelessWidget {
  const _ScoreLabel({required this.score, required this.best});

  final ValueListenable<int> score;
  final ValueListenable<int?> best;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<int>(
      valueListenable: score,
      builder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $value',
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            ValueListenableBuilder<int?>(
              valueListenable: best,
              builder: (context, record, _) {
                if (record == null) return const SizedBox.shrink();
                return Text(
                  'Best: $record',
                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Spends an earned swap to replace the tray, the way out when nothing fits.
class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.game});

  final BlockFitGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.swapsNotifier,
      builder: (context, swaps, _) {
        final isReady = swaps > 0;
        return TextButton.icon(
          onPressed: isReady ? game.swapTray : null,
          icon: Icon(
            Icons.autorenew_rounded,
            size: 20,
            color: isReady ? const Color(0xFFFFD166) : Colors.white24,
          ),
          label: Text(
            '$swaps',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isReady ? const Color(0xFFFFD166) : Colors.white24,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.game});

  final BlockFitGame game;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No room left',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'You scored ${game.score}',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            RecordLine(
              isNewRecord: game.isNewRecord,
              text: game.isNewRecord
                  ? 'New record!'
                  : 'Best: ${game.bestScore ?? game.score}',
            ),
            const SizedBox(height: 24),
            RewardedButton(
              label: 'Clear the board',
              icon: Icons.auto_fix_high_rounded,
              isOffered: game.canContinue,
              game: game,
              onReward: game.clearForContinue,
            ),
            GameOverActions(
              onPlayAgain: game.restart,
              wasNewRecord: game.isNewRecord,
            ),
          ],
        ),
      ),
    );
  }
}
