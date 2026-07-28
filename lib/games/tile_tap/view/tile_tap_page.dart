import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flame_audio/bgm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/cubit/cubit.dart';
import 'package:sadagames/games/tile_tap/tile_tap.dart';
import 'package:sadagames/gen/assets.gen.dart';
import 'package:sadagames/loading/cubit/cubit.dart';
import 'package:sadagames/records/records.dart';
import 'package:sadagames/settings/settings.dart';

class TileTapPage extends StatelessWidget {
  const TileTapPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const TileTapPage());
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
      // No SafeArea here on purpose: the track fills the screen edge to edge
      // and only the HUD is inset.
      child: const Scaffold(body: TileTapView()),
    );
  }
}

class TileTapView extends StatefulWidget {
  const TileTapView({super.key, this.game});

  final TileTapGame? game;

  @override
  State<TileTapView> createState() => _TileTapViewState();
}

class _TileTapViewState extends State<TileTapView> {
  late final TileTapGame _game;
  late final Bgm bgm;

  @override
  void initState() {
    super.initState();
    _game =
        widget.game ??
        TileTapGame(
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
            TileTapGame.gameOverOverlayId: (_, TileTapGame game) =>
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
                  _TilesLabel(
                    tiles: _game.tilesNotifier,
                    best: _game.bestTilesNotifier,
                  ),
                  const Spacer(),
                  _SkipCounter(skips: _game.skipsNotifier),
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

class _TilesLabel extends StatelessWidget {
  const _TilesLabel({required this.tiles, required this.best});

  final ValueListenable<int> tiles;
  final ValueListenable<int?> best;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<int>(
      valueListenable: tiles,
      builder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tiles: $value',
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

/// Skips in hand. Each one covers a single mistake, and they are earned by
/// hitting tiles rather than handed out.
class _SkipCounter extends StatelessWidget {
  const _SkipCounter({required this.skips});

  final ValueListenable<int> skips;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: skips,
      builder: (context, value, _) {
        if (value == 0) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_rounded,
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

  final TileTapGame game;

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
              'Missed it',
              style: textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'You hit ${formatRecord(game.tiles, 'tile')}',
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            RecordLine(
              isNewRecord: game.isNewRecord,
              text: game.isNewRecord
                  ? 'New record!'
                  : 'Best: ${formatRecord(
                      game.bestTiles ?? game.tiles,
                      'tile',
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
