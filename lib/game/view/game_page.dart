import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flame_audio/bgm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/game.dart';
import 'package:sadagames/gen/assets.gen.dart';
import 'package:sadagames/l10n/l10n.dart';
import 'package:sadagames/loading/cubit/cubit.dart';
import 'package:sadagames/settings/settings.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const GamePage());
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
      // No SafeArea here on purpose: the game fills the screen edge to edge and
      // only the controls are inset.
      child: const Scaffold(body: GameView()),
    );
  }
}

class GameView extends StatefulWidget {
  const GameView({super.key, this.game});

  final FlameGame? game;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  FlameGame? _game;

  late final Bgm bgm;

  @override
  void initState() {
    super.initState();
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
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall!.copyWith(color: Colors.white, fontSize: 4);

    _game ??=
        widget.game ??
        Sadagames(
          l10n: context.l10n,
          sounds: GameSounds(context.read<AudioCubit>().effectPlayer),
          textStyle: textStyle,
          images: context.read<PreloadCubit>().images,
        );
    // Keep the counter clear of the home indicator now the canvas runs edge
    // to edge.
    final game = _game;
    if (game is Sadagames) game.safeArea = MediaQuery.paddingOf(context);

    return Stack(
      children: [
        Positioned.fill(child: GameWidget(game: _game!)),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlocBuilder<AudioCubit, AudioState>(
                  builder: (context, state) {
                    return IconButton(
                      icon: Icon(
                        state.volume == 0 ? Icons.volume_off : Icons.volume_up,
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
      ],
    );
  }
}
