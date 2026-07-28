import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/odd_one_out/components/components.dart';
import 'package:sadagames/gen/assets.gen.dart';
import 'package:sadagames/records/records.dart';

/// Spot the one tile whose colour is slightly off, before the timer runs out.
///
/// Each level adds pressure from three directions at once: the grid grows, the
/// colours move closer together and the clock gets shorter.
class OddOneOutGame extends FlameGame {
  OddOneOutGame({
    required this.effectPlayer,
    required this.records,
    Random? random,
  }) : _random = random ?? Random();

  /// Identifier of the game over overlay rendered by the Flutter layer.
  static const gameOverOverlayId = 'oddOneOutGameOver';

  /// Catalog id and metric this game stores its personal best under.
  static const recordGameId = 'odd_one_out';
  static const recordMetric = 'level';

  /// Wrong taps and time outs the player may spend before the run ends.
  static const maxLives = 3;

  /// A life comes back every time the player clears this many levels.
  static const levelsPerExtraLife = 5;

  static const _maxGridSize = 5;
  static const _startColourGap = 0.3;
  static const _minColourGap = 0.045;
  static const _startSeconds = 6.0;
  static const _minSeconds = 2.5;

  /// Player used for the short right and wrong sound effects.
  final AudioPlayer effectPlayer;

  /// Store holding the player's furthest level between launches.
  final GameRecords records;

  final Random _random;

  /// Level being played, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> levelNotifier = ValueNotifier(1);

  /// Remaining lives, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> livesNotifier = ValueNotifier(maxLives);

  /// How much of the level's time is left, from 1 down to 0.
  final ValueNotifier<double> timeLeftNotifier = ValueNotifier(1);

  /// Furthest level reached so far, or `null` until the first run ends.
  final ValueNotifier<int?> bestLevelNotifier = ValueNotifier(null);

  int get level => levelNotifier.value;

  int get lives => livesNotifier.value;

  int? get bestLevel => bestLevelNotifier.value;

  /// Slot holding the odd tile on the current board.
  int oddIndex = 0;

  bool isGameOver = false;

  /// Whether the run that just ended beat the previous best.
  bool isNewRecord = false;

  double _secondsLeft = _startSeconds;

  @override
  Color backgroundColor() => const Color(0xFF10143A);

  @override
  Future<void> onLoad() async {
    bestLevelNotifier.value = records.read(recordGameId, recordMetric);
    await _buildBoard();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    _secondsLeft -= dt;
    timeLeftNotifier.value = (_secondsLeft / _levelSeconds).clamp(0, 1);
    if (_secondsLeft <= 0) _loseLife();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (children.query<ColourTile>().isEmpty) return;
    unawaited(_buildBoard(keepLevelState: true));
  }

  /// Tiles per row on the current level, growing every three levels.
  int get gridSize => min(2 + (level - 1) ~/ 3, _maxGridSize);

  /// How far apart the two colours are; smaller means harder to spot.
  double get colourGap =>
      max(_startColourGap - (level - 1) * 0.02, _minColourGap);

  double get _levelSeconds => max(_startSeconds - level * 0.15, _minSeconds);

  Future<void> _buildBoard({bool keepLevelState = false}) async {
    for (final tile in children.query<ColourTile>()) {
      tile.removeFromParent();
    }

    final count = gridSize * gridSize;
    if (!keepLevelState) oddIndex = _random.nextInt(count);

    // Rotate the hue per level so consecutive boards look different.
    final base = HSLColor.fromAHSL(1, (level * 37) % 360, 0.55, 0.5);
    final odd = base.withLightness(
      (base.lightness + colourGap).clamp(0.0, 1.0),
    );

    final boardSide = min(size.x, size.y) * 0.8;
    final side = boardSide / gridSize;
    final origin = Vector2((size.x - boardSide) / 2, (size.y - boardSide) / 2);

    for (var i = 0; i < count; i++) {
      await add(
        ColourTile(
          index: i,
          colour: (i == oddIndex ? odd : base).toColor(),
          position:
              origin + Vector2((i % gridSize) * side, (i ~/ gridSize) * side),
          side: side,
        ),
      );
    }
  }

  /// Handles a tap on the tile sitting in [index].
  void chooseTile(int index) {
    if (isGameOver) return;

    if (index == oddIndex) {
      _advanceLevel();
    } else {
      children
          .query<ColourTile>()
          .firstWhere((tile) => tile.index == index)
          .rejectTap();
      _loseLife();
    }
  }

  void _advanceLevel() {
    levelNotifier.value = level + 1;
    // Clearing a stretch of levels earns a life back, so a good run can
    // recover from an early slip.
    if ((level - 1) % levelsPerExtraLife == 0 && lives < maxLives) {
      livesNotifier.value = lives + 1;
    }
    unawaited(_playEffect(rate: min(1 + level * 0.02, 1.6)));
    _restartTimer();
    unawaited(_buildBoard());
  }

  void _loseLife() {
    livesNotifier.value = lives - 1;
    unawaited(_playEffect(rate: 0.6));

    if (lives <= 0) {
      _endGame();
    } else {
      _restartTimer();
    }
  }

  void _restartTimer() {
    _secondsLeft = _levelSeconds;
    timeLeftNotifier.value = 1;
  }

  void _endGame() {
    isGameOver = true;
    // Decide and show straight away; the write itself can settle in the
    // background rather than holding up the overlay.
    isNewRecord = records.beatsRecord(
      recordGameId,
      recordMetric,
      level,
      goal: RecordGoal.higher,
    );
    if (isNewRecord) bestLevelNotifier.value = level;
    unawaited(
      records.submit(
        recordGameId,
        recordMetric,
        level,
        goal: RecordGoal.higher,
      ),
    );
    overlays.add(gameOverOverlayId);
  }

  Future<void> _playEffect({required double rate}) async {
    await effectPlayer.setPlaybackRate(rate);
    await effectPlayer.play(AssetSource(Assets.audio.effect));
  }

  /// Starts a fresh run from level one.
  void restart() {
    levelNotifier.value = 1;
    livesNotifier.value = maxLives;
    isGameOver = false;
    isNewRecord = false;
    _restartTimer();
    unawaited(_buildBoard());
    overlays.remove(gameOverOverlayId);
  }

  @override
  void onRemove() {
    levelNotifier.dispose();
    livesNotifier.dispose();
    timeLeftNotifier.dispose();
    bestLevelNotifier.dispose();
    super.onRemove();
  }
}
