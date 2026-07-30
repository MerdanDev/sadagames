import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/games/snake/components/components.dart';
import 'package:sadagames/records/records.dart';

/// Which way the snake is heading, with the step it takes on the grid.
enum SnakeDirection {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  const SnakeDirection(this.dx, this.dy);

  /// Columns moved per step, positive to the right.
  final int dx;

  /// Rows moved per step, positive downwards.
  final int dy;

  /// The direction that would double the snake back into its own neck.
  SnakeDirection get opposite => switch (this) {
    SnakeDirection.up => SnakeDirection.down,
    SnakeDirection.down => SnakeDirection.up,
    SnakeDirection.left => SnakeDirection.right,
    SnakeDirection.right => SnakeDirection.left,
  };
}

/// Swipe to steer the snake, eat, grow, and stay off yourself.
///
/// The snake never stops, and every apple shortens the tick, so the board that
/// felt roomy at three apples is a maze at twenty. A gold trim fruit turns up
/// once the snake is long enough for length to be the problem: it scores like
/// an apple but hands back four segments of room.
class SnakeGame extends FlameGame with DragCallbacks {
  SnakeGame({required this.sounds, required this.records, Random? random})
    : _random = random ?? Random();

  /// Identifier of the game over overlay rendered by the Flutter layer.
  static const gameOverOverlayId = 'snakeGameOver';

  /// Catalog id and metric this game stores its personal best under.
  static const recordGameId = 'snake';
  static const recordMetric = 'apple';

  /// Cells across and down. The board is taller than it is wide because a
  /// phone is: a square one leaves half the screen doing nothing.
  static const columns = 15;
  static const rows = 23;

  /// Cells on the board.
  static const int cellCount = columns * rows;

  /// Segments the snake starts a run with, and the shortest a trim will
  /// ever leave it.
  static const startingLength = 3;

  /// Length at which the trim fruit starts turning up. Below it, length is
  /// not yet the thing killing runs.
  static const trimUnlockLength = 12;

  /// Segments a trim fruit hands back.
  static const trimAmount = 4;

  /// Chance that a fruit spawned past [trimUnlockLength] is a trim.
  static const trimChance = 0.2;

  /// Seconds per step at the start of a run, and the floor the ramp stops at.
  static const _startInterval = 0.24;
  static const _minInterval = 0.085;
  static const _intervalStep = 0.006;

  /// Distance a drag has to cover before it counts as a turn. The second,
  /// smaller figure catches a flick that ends before it gets that far.
  static const _swipeThreshold = 16.0;
  static const _flickThreshold = 8.0;

  /// Turns held in reserve. Two is enough to draw a corner in one gesture
  /// without a stray third flick queueing up moves the player forgot about.
  static const _queuedTurns = 2;

  /// Short sounds for turns, apples and the end of a run.
  final GameSounds sounds;

  /// Store holding the player's best run between launches.
  final GameRecords records;

  final Random _random;

  /// The snake, head first, as cell indices counted left to right and top to
  /// bottom.
  final List<int> body = [];

  /// Apples eaten so far, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> applesNotifier = ValueNotifier(0);

  /// Current length, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> lengthNotifier = ValueNotifier(startingLength);

  /// Best run so far, or `null` until the first run ends.
  final ValueNotifier<int?> bestApplesNotifier = ValueNotifier(null);

  int get apples => applesNotifier.value;

  int get length => lengthNotifier.value;

  int? get bestApples => bestApplesNotifier.value;

  bool isGameOver = false;

  /// Whether the run that just ended beat the previous best.
  bool isNewRecord = false;

  /// Where the snake is headed on the next step.
  SnakeDirection direction = SnakeDirection.right;

  /// Whether the step just taken grew the snake, so the tail stayed put. The
  /// body component needs it to know whether to slide the tail along.
  bool grewLastStep = false;

  late final SnakeBoard board = SnakeBoard()..priority = -2;
  late final SnakeBodyComponent snake = SnakeBodyComponent();
  late final Fruit fruit = Fruit()..priority = -1;

  final List<SnakeDirection> _pending = [];

  int? _fruitCell;
  bool _isFruitTrim = false;
  bool _isMoving = false;
  double _elapsed = 0;
  double _cellSize = 0;
  Vector2 _boardOrigin = Vector2.zero();
  Vector2? _dragFrom;
  Vector2? _dragTo;
  bool _hasSteeredThisDrag = false;

  /// Where the fruit is sitting, or `null` when the board has no room left.
  int? get fruitCell => _fruitCell;

  /// Whether the fruit on the board is the gold one that trims the tail.
  bool get isFruitTrim => _isFruitTrim;

  /// Whether the snake has been set going by a first swipe.
  bool get isMoving => _isMoving;

  /// Side of one board cell in logical pixels.
  double get cellSize => _cellSize;

  /// Top left corner of the board in game coordinates.
  Vector2 get boardOrigin => _boardOrigin;

  /// Seconds between steps, which shortens with every apple and then stops.
  double get tickInterval =>
      max(_startInterval - apples * _intervalStep, _minInterval);

  /// How far the snake is through the current step, for drawing it between
  /// two cells rather than jumping a whole cell at a time.
  double get tickProgress => (_elapsed / tickInterval).clamp(0, 1);

  @override
  Color backgroundColor() => const Color(0xFF10143A);

  @override
  Future<void> onLoad() async {
    bestApplesNotifier.value = records.read(recordGameId, recordMetric);
    _measure();
    _layOutBoard();
    await addAll([board, snake, fruit]);
    _layOutSnake();
    _spawnFruit();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (body.isEmpty) return;
    _measure();
    _layOutBoard();
    if (_fruitCell != null) fruit.placeAt(centreOf(_fruitCell!), _cellSize);
  }

  void _measure() {
    // Whichever runs out first: the width of the screen, or the height left
    // once the HUD has had its room off the top.
    _cellSize = min(size.x * 0.94 / columns, size.y * 0.68 / rows);
    // Centred in what is left under the HUD rather than on the screen, or the
    // gap between the two reads as a mistake.
    final top = size.y * 0.17;
    _boardOrigin = Vector2(
      (size.x - _cellSize * columns) / 2,
      top + (size.y - top - _cellSize * rows) / 2,
    );
  }

  void _layOutBoard() {
    final area = Vector2(_cellSize * columns, _cellSize * rows);
    board
      ..position = _boardOrigin
      ..size = area;
    snake
      ..position = _boardOrigin
      ..size = area;
  }

  int _columnOf(int cell) => cell % columns;

  int _rowOf(int cell) => cell ~/ columns;

  /// Centre of [cell] in game coordinates.
  Vector2 centreOf(int cell) =>
      _boardOrigin +
      Vector2(
        (_columnOf(cell) + 0.5) * _cellSize,
        (_rowOf(cell) + 0.5) * _cellSize,
      );

  void _layOutSnake() {
    const row = rows ~/ 2;
    const headColumn = startingLength + 1;
    body
      ..clear()
      ..addAll([
        for (var i = 0; i < startingLength; i++) row * columns + headColumn - i,
      ]);
    direction = SnakeDirection.right;
    _pending.clear();
    _elapsed = 0;
    _isMoving = false;
    grewLastStep = false;
    lengthNotifier.value = body.length;
  }

  void _spawnFruit() {
    final empty = [
      for (var cell = 0; cell < cellCount; cell++)
        if (!body.contains(cell)) cell,
    ];
    if (empty.isEmpty) {
      // Nowhere to put one. The run ends the next time the snake moves.
      _fruitCell = null;
      fruit.removeFromParent();
      return;
    }

    // A trim only shows up once length itself is the thing killing runs.
    final isTrim =
        body.length >= trimUnlockLength && _random.nextDouble() < trimChance;
    _place(empty[_random.nextInt(empty.length)], isTrim: isTrim);
  }

  void _place(int cell, {required bool isTrim}) {
    _fruitCell = cell;
    _isFruitTrim = isTrim;
    if (!fruit.isMounted) {
      final added = add(fruit);
      if (added is Future<void>) unawaited(added);
    }
    fruit
      ..isTrim = isTrim
      ..placeAt(centreOf(cell), _cellSize)
      ..appear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    // The snake waits for the first swipe. It is still live — the swipe both
    // starts it and steers it — but a player who looks at the board for a
    // moment first does not come back to a run that ended without them.
    if (!_isMoving) return;

    _elapsed += dt;
    while (!isGameOver && _elapsed >= tickInterval) {
      _elapsed -= tickInterval;
      _step();
    }
  }

  void _step() {
    if (_pending.isNotEmpty) direction = _pending.removeAt(0);

    final column = _columnOf(body.first) + direction.dx;
    final row = _rowOf(body.first) + direction.dy;
    if (column < 0 || column >= columns || row < 0 || row >= rows) {
      _endGame();
      return;
    }

    final next = row * columns + column;
    final isEating = next == _fruitCell;
    // The tail cell frees up as the snake moves into it, so following your own
    // tail is fine — unless this step is the one that grows the snake.
    final blockers = isEating ? body : body.take(body.length - 1);
    if (blockers.contains(next)) {
      _endGame();
      return;
    }

    body.insert(0, next);
    grewLastStep = isEating;
    if (isEating) {
      _eat();
    } else {
      body.removeLast();
    }
    lengthNotifier.value = body.length;
  }

  void _eat() {
    applesNotifier.value = apples + 1;
    if (_isFruitTrim) {
      // Room back, without costing the number the player is chasing.
      sounds.win();
      body.removeRange(
        max(startingLength, body.length - trimAmount),
        body.length,
      );
    } else {
      // Each apple lands a step higher up the scale than the last.
      sounds.note(apples);
    }
    _spawnFruit();
  }

  /// Points the snake at [to] on one of the next steps, and sets it going if
  /// this is the swipe that starts the run.
  ///
  /// Returns whether the turn was taken up. Turns queue rather than overwrite
  /// each other: judging two flicks in the same tick against the same
  /// direction is what lets a player fold the snake into its own neck.
  bool steer(SnakeDirection to) {
    if (isGameOver) return false;

    final wasWaiting = !_isMoving;
    _isMoving = true;
    if (_pending.length >= _queuedTurns) return false;

    final last = _pending.isEmpty ? direction : _pending.last;
    if (to == last || to == last.opposite) {
      // A swipe that sets the snake off still has to answer back, even when
      // it asked for the way the snake was already pointing.
      if (wasWaiting) sounds.tap();
      return false;
    }

    _pending.add(to);
    sounds.tap();
    return true;
  }

  SnakeDirection _directionOf(Vector2 delta) => delta.x.abs() > delta.y.abs()
      ? (delta.x > 0 ? SnakeDirection.right : SnakeDirection.left)
      : (delta.y > 0 ? SnakeDirection.down : SnakeDirection.up);

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragFrom = event.localPosition.clone();
    _dragTo = null;
    _hasSteeredThisDrag = false;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final from = _dragFrom;
    if (from == null) return;

    _dragTo = event.localEndPosition.clone();
    final delta = _dragTo! - from;
    if (delta.length < _swipeThreshold) return;

    // Steering mid-drag, and measuring the next turn from here, lets a player
    // draw a whole path with one finger instead of lifting it per corner.
    steer(_directionOf(delta));
    _dragFrom = _dragTo!.clone();
    _hasSteeredThisDrag = true;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final from = _dragFrom;
    final to = _dragTo;
    _dragFrom = null;
    _dragTo = null;
    if (_hasSteeredThisDrag || from == null || to == null) return;

    // A flick too short to have steered on the way still counts.
    final delta = to - from;
    if (delta.length < _flickThreshold) return;
    steer(_directionOf(delta));
  }

  void _endGame() {
    isGameOver = true;
    sounds.fail();
    // Decide and show straight away; the write itself can settle in the
    // background rather than holding up the overlay.
    isNewRecord = records.beatsRecord(
      recordGameId,
      recordMetric,
      apples,
      goal: RecordGoal.higher,
    );
    if (isNewRecord) bestApplesNotifier.value = apples;
    unawaited(
      records.submit(
        recordGameId,
        recordMetric,
        apples,
        goal: RecordGoal.higher,
      ),
    );
    overlays.add(gameOverOverlayId);
  }

  /// Puts a fresh snake back on an empty board.
  void restart() {
    applesNotifier.value = 0;
    isGameOver = false;
    isNewRecord = false;
    overlays.remove(gameOverOverlayId);
    _layOutSnake();
    _spawnFruit();
  }

  /// Puts the fruit on a known cell, for tests that need a set position.
  @visibleForTesting
  void setFruit(int cell, {bool isTrim = false}) =>
      _place(cell, isTrim: isTrim);

  /// Replaces the snake, head first, for tests that need a set position.
  @visibleForTesting
  void setBody(List<int> cells) {
    body
      ..clear()
      ..addAll(cells);
    lengthNotifier.value = body.length;
  }

  /// Takes exactly one step, for tests that would rather not count frames.
  @visibleForTesting
  void stepOnce() {
    if (isGameOver) return;
    _step();
  }

  @override
  void onRemove() {
    applesNotifier.dispose();
    lengthNotifier.dispose();
    bestApplesNotifier.dispose();
    super.onRemove();
  }
}
