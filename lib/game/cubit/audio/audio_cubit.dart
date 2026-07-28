import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flame_audio/bgm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sadagames/settings/settings.dart';

part 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  /// Starts from the volume the player last chose and pushes it to the players
  /// straight away: a cubit built while muted has to be silent before anything
  /// asks it to play.
  AudioCubit({
    required AudioPlayer audioPlayer,
    required Bgm backgroundMusic,
    required GameSettings this.settings,
  }) : effectPlayer = audioPlayer,
       bgm = backgroundMusic,
       super(AudioState(volume: settings.isMuted ? 0 : 1)) {
    unawaited(_applyVolume(state.volume));
  }

  @visibleForTesting
  AudioCubit.test({
    required this.effectPlayer,
    required this.bgm,
    this.settings,
    double volume = 1.0,
  }) : super(AudioState(volume: volume));

  final AudioPlayer effectPlayer;

  final Bgm bgm;

  /// Where the mute choice is kept. Only null in tests that do not care.
  final GameSettings? settings;

  Future<void> _applyVolume(double volume) async {
    await effectPlayer.setVolume(volume);
    await bgm.audioPlayer.setVolume(volume);
  }

  Future<void> _changeVolume(double volume) async {
    await _applyVolume(volume);
    await settings?.setMuted(isMuted: volume == 0);
    if (!isClosed) {
      emit(state.copyWith(volume: volume));
    }
  }

  Future<void> toggleVolume() async {
    if (state.volume == 0) {
      return _changeVolume(1);
    }
    return _changeVolume(0);
  }

  @override
  Future<void> close() async {
    await effectPlayer.dispose();
    await bgm.dispose();
    return super.close();
  }
}
