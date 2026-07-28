import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flame_audio/bgm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/games/star_catcher/star_catcher.dart';
import 'package:sadagames/gen/assets.gen.dart';
import 'package:sadagames/loading/cubit/cubit.dart';

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
          backgroundMusic: Bgm(audioCache: audioCache),
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
  late final Bgm bgm;

  @override
  void initState() {
    super.initState();
    _game =
        widget.game ??
        StarCatcherGame(effectPlayer: context.read<AudioCubit>().effectPlayer);
    bgm = context.read<AudioCubit>().bgm;
    unawaited(bgm.play(Assets.audio.background));
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
                  _ScoreLabel(score: _game.scoreNotifier),
                  const Spacer(),
                  _LivesIndicator(lives: _game.livesNotifier),
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
  const _ScoreLabel({required this.score});

  final ValueListenable<int> score;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: score,
      builder: (context, value, _) {
        return Text(
          'Score: $value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}

class _LivesIndicator extends StatelessWidget {
  const _LivesIndicator({required this.lives});

  final ValueListenable<int> lives;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: lives,
      builder: (context, value, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < StarCatcherGame.maxLives; i++)
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
              'You caught ${game.score} stars',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
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
