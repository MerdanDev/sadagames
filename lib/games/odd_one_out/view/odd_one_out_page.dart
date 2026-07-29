import 'package:flame/game.dart' hide Route;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/games/odd_one_out/odd_one_out.dart';
import 'package:sadagames/games/widgets/widgets.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

class OddOneOutPage extends StatelessWidget {
  const OddOneOutPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const OddOneOutPage());
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
      child: const Scaffold(body: OddOneOutView()),
    );
  }
}

class OddOneOutView extends StatefulWidget {
  const OddOneOutView({super.key, this.game});

  final OddOneOutGame? game;

  @override
  State<OddOneOutView> createState() => _OddOneOutViewState();
}

class _OddOneOutViewState extends State<OddOneOutView> {
  /// Held rather than read in dispose, where context is gone.
  late final GameSounds _sounds;

  late final OddOneOutGame _game;

  @override
  void initState() {
    super.initState();
    _sounds = context.read<GameSounds>();
    _game =
        widget.game ??
        OddOneOutGame(
          sounds: _sounds,
          records: context.read<GameRecords>(),
        );
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
            OddOneOutGame.gameOverOverlayId: (_, OddOneOutGame game) =>
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
                      _LevelLabel(
                        level: _game.levelNotifier,
                        best: _game.bestLevelNotifier,
                      ),
                      const Spacer(),
                      LivesIndicator(
                        lives: _game.livesNotifier,
                        maxLives: OddOneOutGame.maxLives,
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
                  const SizedBox(height: 4),
                  _TimeBar(timeLeft: _game.timeLeftNotifier),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelLabel extends StatelessWidget {
  const _LevelLabel({required this.level, required this.best});

  final ValueListenable<int> level;
  final ValueListenable<int?> best;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<int>(
      valueListenable: level,
      builder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Level $value',
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

/// Shrinking bar showing how long is left to find the odd tile.
class _TimeBar extends StatelessWidget {
  const _TimeBar({required this.timeLeft});

  final ValueListenable<double> timeLeft;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: timeLeft,
      builder: (context, value, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(
              value < 0.3 ? const Color(0xFFE63946) : const Color(0xFFFFD166),
            ),
          ),
        );
      },
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.game});

  final OddOneOutGame game;

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
              'You reached level ${game.level}',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            RecordLine(
              isNewRecord: game.isNewRecord,
              text: game.isNewRecord
                  ? 'New record!'
                  : 'Best: level ${game.bestLevel ?? game.level}',
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
