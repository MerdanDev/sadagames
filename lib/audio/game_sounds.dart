import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// The cues a game can ask for.
///
/// Games talk in terms of what happened, not what it should sound like, so the
/// whole collection can be retuned in one place.
abstract class GameSounds {
  /// Plays a musical note. [degree] walks up a scale and wraps into higher
  /// octaves, so a rising streak keeps climbing without ever going sour.
  void note(int degree);

  /// A short, neutral click for an ordinary action: a piece placed, a tile
  /// slid, a tap that neither wins nor loses anything.
  void tap();

  /// A low, blunt sound for a mistake, a lost life or the end of a run.
  void fail();

  /// A rising flourish for something worth celebrating.
  void win();

  /// Silences or restores everything.
  void setMuted({required bool isMuted});

  /// Releases the engine. Call when the app is done with audio.
  Future<void> dispose();
}

/// Synthesises every cue with SoLoud, so the collection ships no audio files.
///
/// Notes come from a pentatonic scale: any two of them sound consonant
/// together, which is what lets a game hand out notes in whatever order the
/// player happens to produce and still have it sound like music.
class SoLoudGameSounds implements GameSounds {
  SoLoudGameSounds();

  /// Semitone offsets of a minor pentatonic scale, from the root.
  static const _scale = [0, 3, 5, 7, 10];

  /// Root of the scale, in hertz. A3.
  static const _root = 220.0;

  static const _noteLength = Duration(milliseconds: 260);
  static const _tapLength = Duration(milliseconds: 90);
  static const _failLength = Duration(milliseconds: 420);

  /// One source per note, because SoLoud holds the frequency on the source:
  /// sharing one would make overlapping notes steal each other's pitch.
  final List<AudioSource> _notes = [];

  AudioSource? _tap;
  AudioSource? _fail;

  bool _isReady = false;
  bool _isMuted = false;

  /// Whether the engine came up. Everything is a no-op until it does.
  bool get isReady => _isReady;

  /// Brings the engine up and builds every voice.
  ///
  /// Audio is never worth crashing a game over, so a failure here leaves the
  /// app silent rather than broken.
  Future<void> init() async {
    try {
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init();
      }

      // Two octaves of the scale is enough range for the longest streak.
      for (var octave = 0; octave < 2; octave++) {
        for (final semitones in _scale) {
          final source = await SoLoud.instance.loadWaveform(
            WaveForm.sin,
            true,
            0.4,
            1,
          );
          SoLoud.instance.setWaveformFreq(
            source,
            _frequencyFor(semitones + octave * 12),
          );
          _notes.add(source);
        }
      }

      _tap = await SoLoud.instance.loadWaveform(WaveForm.triangle, false, 0, 0);
      SoLoud.instance.setWaveformFreq(_tap!, _frequencyFor(24));

      _fail = await SoLoud.instance.loadWaveform(WaveForm.saw, false, 0, 0);
      SoLoud.instance.setWaveformFreq(_fail!, _frequencyFor(-12));

      _isReady = true;
      setMuted(isMuted: _isMuted);
    } on Object catch (error, stackTrace) {
      _isReady = false;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'sadagames audio',
          context: ErrorDescription('bringing the sound engine up'),
        ),
      );
    }
  }

  static double _frequencyFor(int semitones) =>
      _root * _semitoneRatio(semitones);

  /// Equal temperament: every semitone is the twelfth root of two apart.
  static double _semitoneRatio(int semitones) {
    var ratio = 1.0;
    final step = semitones.isNegative
        ? 1 / 1.0594630943592953
        : 1.0594630943592953;
    for (var i = 0; i < semitones.abs(); i++) {
      ratio *= step;
    }
    return ratio;
  }

  /// Plays [source] and fades it out, which is the whole envelope: an
  /// oscillator runs forever otherwise.
  void _pluck(AudioSource? source, Duration length, {double volume = 0.5}) {
    if (!_isReady || source == null) return;
    try {
      final handle = SoLoud.instance.play(source, volume: volume);
      SoLoud.instance
        ..fadeVolume(handle, 0, length)
        ..scheduleStop(handle, length);
    } on Object {
      // A dropped cue is not worth interrupting play for.
    }
  }

  @override
  void note(int degree) {
    if (_notes.isEmpty) return;
    _pluck(_notes[degree.abs() % _notes.length], _noteLength, volume: 0.45);
  }

  @override
  void tap() => _pluck(_tap, _tapLength, volume: 0.3);

  @override
  void fail() => _pluck(_fail, _failLength, volume: 0.35);

  @override
  void win() {
    // A three note arpeggio up the scale, spaced so it reads as a flourish.
    for (var i = 0; i < 3; i++) {
      Timer(Duration(milliseconds: i * 70), () => note(i * 2));
    }
  }

  @override
  void setMuted({required bool isMuted}) {
    _isMuted = isMuted;
    if (!_isReady) return;
    SoLoud.instance.setGlobalVolume(isMuted ? 0 : 1);
  }

  @override
  Future<void> dispose() async {
    if (!_isReady) return;
    _isReady = false;
    await SoLoud.instance.disposeAllSources();
    SoLoud.instance.deinit();
  }
}

/// Sounds that make no sound, and remember what they were asked to play.
///
/// Used by tests, and as the fallback when the engine cannot start.
class SilentGameSounds implements GameSounds {
  /// Cues asked for, in order, as `note:3`, `tap`, `fail` or `win`.
  final List<String> played = [];

  bool isMuted = false;

  @override
  void note(int degree) => played.add('note:$degree');

  @override
  void tap() => played.add('tap');

  @override
  void fail() => played.add('fail');

  @override
  void win() => played.add('win');

  @override
  void setMuted({required bool isMuted}) => this.isMuted = isMuted;

  @override
  Future<void> dispose() async {}
}
