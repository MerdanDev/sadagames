import 'package:flame/game.dart' hide Route;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/ads/ads.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/games/merge_tiles/merge_tiles.dart';
import 'package:sadagames/games/widgets/widgets.dart';
import 'package:sadagames/progress/progress.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

class MergeTilesPage extends StatelessWidget {
  const MergeTilesPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const MergeTilesPage());
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
      child: const Scaffold(body: MergeTilesView()),
    );
  }
}

class MergeTilesView extends StatefulWidget {
  const MergeTilesView({super.key, this.game});

  final MergeTilesGame? game;

  @override
  State<MergeTilesView> createState() => _MergeTilesViewState();
}

class _MergeTilesViewState extends State<MergeTilesView> {
  /// Held rather than read in dispose, where context is gone.
  late final GameSounds _sounds;

  late final MergeTilesGame _game;

  @override
  void initState() {
    super.initState();
    _sounds = context.read<GameSounds>();
    _game =
        widget.game ??
        MergeTilesGame(
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
            MergeTilesGame.gameOverOverlayId: (_, MergeTilesGame game) =>
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
              child: Column(
                children: [
                  Row(
                    children: [
                      _ScoreLabel(
                        score: _game.scoreNotifier,
                        best: _game.bestScoreNotifier,
                      ),
                      const Spacer(),
                      _UndoButton(game: _game),
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
                  const SizedBox(height: 4),
                  _HighestLabel(highest: _game.highestNotifier),
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

/// The biggest tile so far, which is the number players actually chase.
class _HighestLabel extends StatelessWidget {
  const _HighestLabel({required this.highest});

  final ValueListenable<int> highest;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: highest,
      builder: (context, value, _) {
        if (value == 0) return const SizedBox.shrink();
        return Text(
          'Biggest tile: $value',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: const Color(0xFFFFD166)),
        );
      },
    );
  }
}

/// Takes the last move back. One is held from the start, and another comes
/// with every new biggest tile.
class _UndoButton extends StatelessWidget {
  const _UndoButton({required this.game});

  final MergeTilesGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.undosNotifier,
      builder: (context, undos, _) {
        final isReady = undos > 0;
        return TextButton.icon(
          onPressed: isReady ? game.undo : null,
          icon: Icon(
            Icons.undo_rounded,
            size: 20,
            color: isReady ? const Color(0xFFFFD166) : Colors.white24,
          ),
          label: Text(
            '$undos',
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

  final MergeTilesGame game;

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
              'Board full',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'You scored ${game.score}, biggest tile ${game.highestTile}',
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
            if (game.undosLeft > 0)
              TextButton.icon(
                onPressed: game.undo,
                icon: const Icon(Icons.undo_rounded, color: Color(0xFFFFD166)),
                label: const Text(
                  'Take that move back',
                  style: TextStyle(color: Color(0xFFFFD166)),
                ),
              ),
            RewardedButton(
              label: 'Remove a tile',
              icon: Icons.auto_fix_high_rounded,
              isOffered: game.canContinue,
              game: game,
              onReward: game.removeTileForContinue,
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
