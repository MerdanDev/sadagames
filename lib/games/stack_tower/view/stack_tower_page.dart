import 'package:flame/game.dart' hide Route;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/games/stack_tower/stack_tower.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

class StackTowerPage extends StatelessWidget {
  const StackTowerPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const StackTowerPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AudioCubit(
        sounds: context.read<GameSounds>(),
        settings: context.read<GameSettings>(),
      ),
      // No SafeArea here on purpose: the tower fills the screen edge to edge
      // and only the HUD is inset.
      child: const Scaffold(body: StackTowerView()),
    );
  }
}

class StackTowerView extends StatefulWidget {
  const StackTowerView({super.key, this.game});

  final StackTowerGame? game;

  @override
  State<StackTowerView> createState() => _StackTowerViewState();
}

class _StackTowerViewState extends State<StackTowerView> {
  /// Held rather than read in dispose, where context is gone.
  late final GameSounds _sounds;

  late final StackTowerGame _game;

  @override
  void initState() {
    super.initState();
    _sounds = context.read<GameSounds>();
    _game =
        widget.game ??
        StackTowerGame(
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
            StackTowerGame.gameOverOverlayId: (_, StackTowerGame game) =>
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
                  _HeightLabel(
                    height: _game.heightNotifier,
                    best: _game.bestHeightNotifier,
                  ),
                  const Spacer(),
                  _PerfectCounter(perfect: _game.perfectNotifier),
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

class _HeightLabel extends StatelessWidget {
  const _HeightLabel({required this.height, required this.best});

  final ValueListenable<int> height;
  final ValueListenable<int?> best;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<int>(
      valueListenable: height,
      builder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Height: $value',
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

/// Perfect drops so far, the only way the tower gets its width back.
class _PerfectCounter extends StatelessWidget {
  const _PerfectCounter({required this.perfect});

  final ValueListenable<int> perfect;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: perfect,
      builder: (context, value, _) {
        if (value == 0) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.center_focus_strong_rounded,
              size: 20,
              color: Color(0xFFFFD166),
            ),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFFFFD166),
                fontWeight: FontWeight.w700,
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

  final StackTowerGame game;

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
              'Toppled',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'You stacked ${formatRecord(game.height, 'block')}',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            RecordLine(
              isNewRecord: game.isNewRecord,
              text: game.isNewRecord
                  ? 'New record!'
                  : 'Best: ${formatRecord(
                      game.bestHeight ?? game.height,
                      'block',
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
