import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:sadagames/gen/assets.gen.dart';

/// Plays the shared effect clip as short, pitched sounds.
///
/// There is only one effect asset and it runs for three seconds, which is far
/// longer than any single game event. Left alone it drones on and each new
/// event restarts it mid-flow, so nothing lines up with what the player just
/// did. This class cuts it down to a blip per event and pitches it, so a catch,
/// a mistake and a win are told apart by ear.
class GameSounds {
  GameSounds(this._player);

  static const _blipLength = Duration(milliseconds: 220);
  static const _thudLength = Duration(milliseconds: 420);
  static const _fanfareLength = Duration(milliseconds: 1100);

  final AudioPlayer _player;

  Future<void>? _sourceReady;
  Timer? _stopTimer;

  /// A short, bright sound for a hit, a press or a step forward.
  ///
  /// [pitch] rises with the player's streak, so progress is audible.
  Future<void> blip({double pitch = 1}) =>
      _play(pitch: pitch, length: _blipLength);

  /// A low, blunt sound for a mistake or a lost life.
  Future<void> thud() => _play(pitch: 0.55, length: _thudLength);

  /// A longer, warmer sound for finishing a run well.
  Future<void> fanfare() => _play(pitch: 0.9, length: _fanfareLength);

  Future<void> _play({required double pitch, required Duration length}) async {
    _stopTimer?.cancel();

    // The source only has to be handed over once; after that rewinding is
    // enough and keeps the sound responsive.
    _sourceReady ??= _player.setSource(AssetSource(Assets.audio.effect));
    await _sourceReady;

    await _player.seek(Duration.zero);
    await _player.resume();
    // The rate has to be set while the clip is playing; setting it beforehand
    // is dropped when playback starts, which is why pitches used to be lost.
    await _player.setPlaybackRate(pitch);

    _stopTimer = Timer(length, () => unawaited(_player.stop()));
  }

  /// Cancels any pending stop. Call when the game is torn down.
  void dispose() => _stopTimer?.cancel();
}
