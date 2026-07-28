import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/games/star_catcher/star_catcher.dart';
import 'package:sadagames/games/widgets/widgets.dart';
import 'package:sadagames/loading/cubit/cubit.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

class StarCatcherPage extends StatelessWidget {
  const StarCatcherPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const StarCatcherPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final audioCache = context.read<PreloadCubit>().audio;
        return AudioCubit(
          audioPlayer: AudioPlayer()..audioCache = audioCache,
          settings: context.read<GameSettings>(),
        );
      },
      // No SafeArea here on purpose: the game fills the screen edge to edge and
      // only the HUD is inset.
      child: const Scaffold(body: StarCatcherView()),
    );
  }
}

class StarCatcherView extends StatefulWidget {
  const StarCatcherView({super.key, this.game});

  final StarCatcherGame? game;

  @override
  State<StarCatcherView> createState() => _StarCatcherViewState();
}

class _StarCatcherViewState extends State<StarCatcherView> {
  late final StarCatcherGame _game;

  @override
  void initState() {
    super.initState();
    _game =
        widget.game ??
        StarCatcherGame(
          sounds: GameSounds(context.read<AudioCubit>().effectPlayer),
          records: context.read<GameRecords>(),
        );
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
            StarCatcherGame.gameOverOverlayId: (_, StarCatcherGame game) =>
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
                  LivesIndicator(
                    lives: _game.livesNotifier,
                    maxLives: StarCatcherGame.maxLives,
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

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.game});

  final StarCatcherGame game;

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
              'Game over',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'You caught ${formatRecord(game.score, 'star')}',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            RecordLine(
              isNewRecord: game.isNewRecord,
              text: game.isNewRecord
                  ? 'New record!'
                  : 'Best: '
                        '${formatRecord(game.bestScore ?? game.score, 'star')}',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: game.restart,
              child: const Text('Play again'),
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
