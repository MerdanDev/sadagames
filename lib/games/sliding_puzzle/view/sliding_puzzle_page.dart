import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flame_audio/bgm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/games/sliding_puzzle/sliding_puzzle.dart';
import 'package:sadagames/gen/assets.gen.dart';
import 'package:sadagames/loading/cubit/cubit.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

class SlidingPuzzlePage extends StatelessWidget {
  const SlidingPuzzlePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SlidingPuzzlePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final audioCache = context.read<PreloadCubit>().audio;
        return AudioCubit(
          audioPlayer: AudioPlayer()..audioCache = audioCache,
          backgroundMusic: Bgm(audioCache: audioCache),
          settings: context.read<GameSettings>(),
        );
      },
      // No SafeArea here on purpose: the board fills the screen edge to edge
      // and only the HUD is inset.
      child: const Scaffold(body: SlidingPuzzleView()),
    );
  }
}

class SlidingPuzzleView extends StatefulWidget {
  const SlidingPuzzleView({super.key, this.game});

  final SlidingPuzzleGame? game;

  @override
  State<SlidingPuzzleView> createState() => _SlidingPuzzleViewState();
}

class _SlidingPuzzleViewState extends State<SlidingPuzzleView> {
  late final SlidingPuzzleGame _game;
  late final Bgm bgm;

  @override
  void initState() {
    super.initState();
    _game =
        widget.game ??
        SlidingPuzzleGame(
          sounds: GameSounds(context.read<AudioCubit>().effectPlayer),
          records: context.read<GameRecords>(),
        );
    final audio = context.read<AudioCubit>();
    bgm = audio.bgm;
    unawaited(bgm.play(Assets.audio.background, volume: audio.state.volume));
  }

  @override
  void dispose() {
    unawaited(bgm.pause());
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
            SlidingPuzzleGame.solvedOverlayId: (_, SlidingPuzzleGame game) =>
                _SolvedOverlay(game: game),
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
                  _CounterLabel(
                    icon: Icons.swap_horiz_rounded,
                    value: _game.movesNotifier,
                  ),
                  const SizedBox(width: 16),
                  _CounterLabel(
                    icon: Icons.timer_outlined,
                    value: _game.secondsNotifier,
                    suffix: 's',
                  ),
                  const SizedBox(width: 16),
                  _BestLabel(best: _game.bestMovesNotifier),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _game.restart,
                  ),
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

class _CounterLabel extends StatelessWidget {
  const _CounterLabel({
    required this.icon,
    required this.value,
    this.suffix = '',
  });

  final IconData icon;
  final ValueListenable<int> value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: value,
      builder: (context, current, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 4),
            Text(
              '$current$suffix',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shows the fewest moves the puzzle has ever been solved in.
class _BestLabel extends StatelessWidget {
  const _BestLabel({required this.best});

  final ValueListenable<int?> best;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: best,
      builder: (context, record, _) {
        if (record == null) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD166),
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '$record',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SolvedOverlay extends StatelessWidget {
  const _SolvedOverlay({required this.game});

  final SlidingPuzzleGame game;

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
              'Solved!',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              '${formatRecord(game.moves, 'move')} in '
              '${game.secondsNotifier.value}s',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            RecordLine(
              isNewRecord: game.isNewRecord,
              text: game.isNewRecord
                  ? 'New record!'
                  : 'Best: '
                        '${formatRecord(game.bestMoves ?? game.moves, 'move')}',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: game.restart,
              child: const Text('Shuffle again'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Back to games',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
