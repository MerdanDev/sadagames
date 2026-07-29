import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/settings/settings.dart';

part 'audio_state.dart';

/// Owns the mute switch. The sounds themselves are shared app wide, so this
/// only decides whether they are heard.
class AudioCubit extends Cubit<AudioState> {
  /// Starts from the choice the player last made and applies it straight
  /// away, so an app opened while muted is silent before anything plays.
  AudioCubit({
    required this.sounds,
    required GameSettings settings,
  }) : settings = settings,
       super(AudioState(volume: settings.isMuted ? 0 : 1)) {
    sounds.setMuted(isMuted: settings.isMuted);
  }

  @visibleForTesting
  AudioCubit.test({
    required this.sounds,
    this.settings,
    double volume = 1.0,
  }) : super(AudioState(volume: volume));

  final GameSounds sounds;

  /// Where the mute choice is kept. Only null in tests that do not care.
  final GameSettings? settings;

  Future<void> _changeVolume(double volume) async {
    final isMuted = volume == 0;
    sounds.setMuted(isMuted: isMuted);
    await settings?.setMuted(isMuted: isMuted);
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
}
