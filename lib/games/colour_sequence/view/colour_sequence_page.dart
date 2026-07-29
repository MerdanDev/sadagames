import 'package:flame/game.dart' hide Route;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/games/colour_sequence/colour_sequence.dart';
import 'package:sadagames/games/widgets/widgets.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

class ColourSequencePage extends StatelessWidget {
  const ColourSequencePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const ColourSequencePage());
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
      child: const Scaffold(body: ColourSequenceView()),
    );
  }
}

class ColourSequenceView extends StatefulWidget {
  const ColourSequenceView({super.key, this.game});

  final ColourSequenceGame? game;

  @override
  State<ColourSequenceView> createState() => _ColourSequenceViewState();
}

class _ColourSequenceViewState extends State<ColourSequenceView> {
  /// Held rather than read in dispose, where context is gone.
  late final GameSounds _sounds;

  late final ColourSequenceGame _game;

  @override
  void initState() {
    super.initState();
    _sounds = context.read<GameSounds>();
    _game =
        widget.game ??
        ColourSequenceGame(
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
            ColourSequenceGame.gameOverOverlayId:
                (_, ColourSequenceGame game) => _GameOverOverlay(game: game),
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
                      _RoundLabel(
                        completed: _game.completedNotifier,
                        best: _game.bestRoundsNotifier,
                      ),
                      const Spacer(),
                      LivesIndicator(
                        lives: _game.livesNotifier,
                        maxLives: ColourSequenceGame.maxLives,
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
                  _StatusLabel(status: _game.statusNotifier),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundLabel extends StatelessWidget {
  const _RoundLabel({required this.completed, required this.best});

  final ValueListenable<int> completed;
  final ValueListenable<int?> best;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<int>(
      valueListenable: completed,
      builder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Round ${value + 1}',
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

/// Tells the player whether to watch the pads or answer with them.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final ValueListenable<SequenceStatus> status;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SequenceStatus>(
      valueListenable: status,
      builder: (context, value, _) {
        final isWatching = value == SequenceStatus.showing;
        if (value == SequenceStatus.finished) return const SizedBox.shrink();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWatching ? Icons.visibility_rounded : Icons.touch_app_rounded,
              size: 18,
              color: isWatching ? Colors.white70 : const Color(0xFFFFD166),
            ),
            const SizedBox(width: 6),
            Text(
              isWatching ? 'Watch' : 'Your turn',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isWatching ? Colors.white70 : const Color(0xFFFFD166),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.game});

  final ColourSequenceGame game;

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
              'You repeated ${formatRecord(game.completedRounds, 'round')}',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            RecordLine(
              isNewRecord: game.isNewRecord,
              text: game.isNewRecord
                  ? 'New record!'
                  : 'Best: ${formatRecord(
                      game.bestRounds ?? game.completedRounds,
                      'round',
                    )}',
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
