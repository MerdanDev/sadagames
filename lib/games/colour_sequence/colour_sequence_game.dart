import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/colour_sequence/components/components.dart';
import 'package:sadagames/gen/assets.gen.dart';
import 'package:sadagames/records/records.dart';

/// What the game is waiting for right now.
enum SequenceStatus {
  /// The game is playing the sequence back; taps are ignored.
  showing,

  /// The player is repeating the sequence.
  awaitingInput,

  /// The run is over.
  finished,
}

/// Watch the pads flash, then play the sequence back.
///
/// Every round adds one more pad to remember and shortens the flashes, so the
/// sequence gets both longer and quicker.
class ColourSequenceGame extends FlameGame {
  ColourSequenceGame({
    required this.effectPlayer,
    required this.records,
    Random? random,
  }) : _random = random ?? Random();

  /// Identifier of the game over overlay rendered by the Flutter layer.
  static const gameOverOverlayId = 'colourSequenceGameOver';

  /// Catalog id and metric this game stores its personal best under.
  static const recordGameId = 'colour_sequence';
  static const recordMetric = 'round';

  /// One slip is forgiven; the second ends the run.
  static const maxLives = 2;

  /// Pads on the board.
  static const padCount = 4;

  /// Playback rate per pad, so each one has its own note.
  static const padRates = [0.7, 0.95, 1.2, 1.5];

  static const _padColours = [
    Color(0xFFE63946),
    Color(0xFF06D6A0),
    Color(0xFF2A48DF),
    Color(0xFFFFD166),
  ];

  static const _startFlash = 0.5;
  static const _minFlash = 0.22;
  static const _gapSeconds = 0.16;
  static const _leadInSeconds = 0.45;
  static const _pressSeconds = 0.18;

  /// Player used for the pad notes.
  final AudioPlayer effectPlayer;

  /// Store holding the player's longest sequence between launches.
  final GameRecords records;

  final Random _random;

  /// Pads to press, in order.
  final List<int> sequence = [];

  /// Rounds fully repeated so far, exposed so the HUD can rebuild on change.
  final ValueNotifier<int> completedNotifier = ValueNotifier(0);

  /// Remaining lives, exposed so the HUD can rebuild on change.
  final ValueNotifier<int> livesNotifier = ValueNotifier(maxLives);

  /// Whether the player should be watching or answering.
  final ValueNotifier<SequenceStatus> statusNotifier = ValueNotifier(
    SequenceStatus.showing,
  );

  /// Longest run of rounds so far, or `null` until the first run ends.
  final ValueNotifier<int?> bestRoundsNotifier = ValueNotifier(null);

  final List<SequencePad> _pads = [];

  int get completedRounds => completedNotifier.value;

  int get lives => livesNotifier.value;

  int? get bestRounds => bestRoundsNotifier.value;

  SequenceStatus get status => statusNotifier.value;

  bool get isGameOver => status == SequenceStatus.finished;

  /// Whether the run that just ended beat the previous best.
  bool isNewRecord = false;

  int _playbackIndex = 0;
  int _inputIndex = 0;
  double _timer = 0;

  @override
  Color backgroundColor() => const Color(0xFF10143A);

  @override
  Future<void> onLoad() async {
    bestRoundsNotifier.value = records.read(recordGameId, recordMetric);
    await _buildPads();
    _startRound();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (status != SequenceStatus.showing) return;

    _timer -= dt;
    if (_timer <= 0) _stepPlayback();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_pads.isEmpty) return;
    _layOutPads();
  }

  /// Flashes get quicker as the sequence grows.
  double get flashSeconds =>
      max(_startFlash - sequence.length * 0.015, _minFlash);

  Future<void> _buildPads() async {
    for (var i = 0; i < padCount; i++) {
      final pad = SequencePad(
        index: i,
        colour: _padColours[i],
        position: Vector2.zero(),
        side: 1,
      );
      _pads.add(pad);
      await add(pad);
    }
    _layOutPads();
  }

  void _layOutPads() {
    final boardSide = min(size.x, size.y) * 0.78;
    final side = boardSide / 2;
    final origin = Vector2((size.x - boardSide) / 2, (size.y - boardSide) / 2);

    for (final pad in _pads) {
      pad
        ..size = Vector2.all(side)
        ..position =
            origin + Vector2((pad.index % 2) * side, (pad.index ~/ 2) * side);
    }
  }

  void _startRound() {
    sequence.add(_random.nextInt(padCount));
    _beginPlayback();
  }

  void _beginPlayback() {
    _playbackIndex = 0;
    _inputIndex = 0;
    _timer = _leadInSeconds;
    statusNotifier.value = SequenceStatus.showing;
  }

  void _stepPlayback() {
    if (_playbackIndex >= sequence.length) {
      statusNotifier.value = SequenceStatus.awaitingInput;
      return;
    }

    final padIndex = sequence[_playbackIndex];
    _pads[padIndex].litSeconds = flashSeconds;
    unawaited(_playEffect(rate: padRates[padIndex]));
    _playbackIndex++;
    _timer = flashSeconds + _gapSeconds;
  }

  /// Handles a press on the pad sitting at [index].
  void pressPad(int index) {
    if (status != SequenceStatus.awaitingInput) return;

    _pads[index].litSeconds = _pressSeconds;
    unawaited(_playEffect(rate: padRates[index]));

    if (sequence[_inputIndex] != index) {
      _onMistake();
      return;
    }

    _inputIndex++;
    if (_inputIndex == sequence.length) {
      completedNotifier.value = completedRounds + 1;
      _startRound();
    }
  }

  void _onMistake() {
    livesNotifier.value = lives - 1;
    unawaited(_playEffect(rate: 0.45));

    if (lives <= 0) {
      _endGame();
    } else {
      // Forgive the slip by replaying the same sequence instead of ending it.
      _beginPlayback();
    }
  }

  void _endGame() {
    statusNotifier.value = SequenceStatus.finished;
    // Decide and show straight away; the write itself can settle in the
    // background rather than holding up the overlay.
    isNewRecord = records.beatsRecord(
      recordGameId,
      recordMetric,
      completedRounds,
      goal: RecordGoal.higher,
    );
    if (isNewRecord) bestRoundsNotifier.value = completedRounds;
    unawaited(
      records.submit(
        recordGameId,
        recordMetric,
        completedRounds,
        goal: RecordGoal.higher,
      ),
    );
    overlays.add(gameOverOverlayId);
  }

  Future<void> _playEffect({required double rate}) async {
    await effectPlayer.setPlaybackRate(rate);
    await effectPlayer.play(AssetSource(Assets.audio.effect));
  }

  /// Starts a fresh run from a single pad.
  void restart() {
    sequence.clear();
    completedNotifier.value = 0;
    livesNotifier.value = maxLives;
    isNewRecord = false;
    overlays.remove(gameOverOverlayId);
    _startRound();
  }

  @override
  void onRemove() {
    completedNotifier.dispose();
    livesNotifier.dispose();
    statusNotifier.dispose();
    bestRoundsNotifier.dispose();
    super.onRemove();
  }
}
