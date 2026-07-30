import 'package:flame/game.dart' hide Route;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/games/snake/snake.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

class SnakePage extends StatelessWidget {
  const SnakePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SnakePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AudioCubit(
        sounds: context.read<GameSounds>(),
        settings: context.read<GameSettings>(),
      ),
      // No SafeArea here on purpose: the canvas fills the screen edge to edge
      // and only the HUD is inset.
      child: const Scaffold(body: SnakeView()),
    );
  }
}

class SnakeView extends StatefulWidget {
  const SnakeView({super.key, this.game});

  final SnakeGame? game;

  @override
  State<SnakeView> createState() => _SnakeViewState();
}

class _SnakeViewState extends State<SnakeView> {
  /// Held rather than read in dispose, where context is gone.
  late final GameSounds _sounds;

  late final SnakeGame _game;

  @override
  void initState() {
    super.initState();
    _sounds = context.read<GameSounds>();
    _game =
        widget.game ??
        SnakeGame(sounds: _sounds, records: context.read<GameRecords>());
    _sounds.startMusic();
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
            SnakeGame.gameOverOverlayId: (_, SnakeGame game) =>
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
                      _AppleLabel(
                        apples: _game.applesNotifier,
                        best: _game.bestApplesNotifier,
                      ),
                      const Spacer(),
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
                  _LengthLabel(length: _game.lengthNotifier),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppleLabel extends StatelessWidget {
  const _AppleLabel({required this.apples, required this.best});

  final ValueListenable<int> apples;
  final ValueListenable<int?> best;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<int>(
      valueListenable: apples,
      builder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Apples: $value',
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

/// How long the snake is right now, which is what the board feels like rather
/// than what the run scores.
class _LengthLabel extends StatelessWidget {
  const _LengthLabel({required this.length});

  final ValueListenable<int> length;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: length,
      builder: (context, value, _) {
        return Text(
          'Length: $value',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: const Color(0xFF9BF6C8)),
        );
      },
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.game});

  final SnakeGame game;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final best = formatRecord(game.bestApples ?? game.apples, 'apple');

    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You crashed',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'You ate ${formatRecord(game.apples, 'apple')}',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            RecordLine(
              isNewRecord: game.isNewRecord,
              text: game.isNewRecord ? 'New record!' : 'Best: $best',
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
