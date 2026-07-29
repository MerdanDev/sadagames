import 'dart:async';
import 'dart:math';

import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/games/merge_tiles/components/components.dart';
import 'package:sadagames/records/records.dart';

/// Which way a swipe pushes the board.
enum SwipeDirection { up, down, left, right }

/// Swipe to slide every tile, merging equal ones as they meet.
///
/// The board only gets tighter: each move adds a tile, so a careless swipe
/// costs space the player cannot win back. One undo is held in reserve, and
/// another is earned every time a new biggest tile appears.
class MergeTilesGame extends FlameGame with DragCallbacks {
  MergeTilesGame({required this.sounds, required this.records, Random? random})
    : _random = random ?? Random();

  /// Identifier of the game over overlay rendered by the Flutter layer.
  static const gameOverOverlayId = 'mergeTilesGameOver';

  /// Catalog id and metric this game stores its personal best under.
  static const recordGameId = 'merge_tiles';
  static const recordMetric = 'score';

  /// Tiles per row and per column.
  static const gridSize = 4;

  /// Undos held at the start of a run.
  static const startingUndos = 1;

  /// Undos the player may hold at once.
  static const maxUndos = 3;

  static const _slideDuration = 0.11;
  static const _swipeThreshold = 18.0;

  /// Short sounds for slides, merges and the last move.
  final GameSounds sounds;

  /// Store holding the player's best score between launches.
  final GameRecords records;

  final Random _random;

  /// Tiles by slot; `null` where the board is empty.
  final List<MergeTile?> board = List<MergeTile?>.filled(
    gridSize * gridSize,
    null,
  );

  /// Score so far, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);

  /// Biggest tile made this run, exposed so the HUD can rebuild on change.
  final ValueNotifier<int> highestNotifier = ValueNotifier(0);

  /// Undos in hand, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> undosNotifier = ValueNotifier(startingUndos);

  /// Best score so far, or `null` until the first run ends.
  final ValueNotifier<int?> bestScoreNotifier = ValueNotifier(null);

  int get score => scoreNotifier.value;

  int get highestTile => highestNotifier.value;

  int get undosLeft => undosNotifier.value;

  int? get bestScore => bestScoreNotifier.value;

  bool isGameOver = false;

  /// Whether the run that just ended beat the previous best.
  bool isNewRecord = false;

  /// Set once the game is torn down. A move finishes asynchronously, so a page
  /// closed mid-move would otherwise come back to disposed notifiers.
  bool _isTornDown = false;

  late BoardGrid grid;

  double _cellSize = 0;
  Vector2 _boardOrigin = Vector2.zero();
  Vector2? _dragFrom;
  Vector2? _dragTo;

  /// Board state kept from before the last move, for the undo.
  List<int>? _snapshotValues;
  int _snapshotScore = 0;

  /// The value in each slot, `0` where empty.
  List<int> get values => [
    for (final tile in board) tile?.value ?? 0,
  ];

  /// Side of one board cell in logical pixels.
  double get cellSize => _cellSize;

  @override
  Color backgroundColor() => const Color(0xFF10143A);

  @override
  Future<void> onLoad() async {
    bestScoreNotifier.value = records.read(recordGameId, recordMetric);
    _measure();
    // Behind the tiles, and behind the one being swallowed by a merge.
    grid = BoardGrid()
      ..position = _boardOrigin
      ..size = Vector2.all(_cellSize * gridSize)
      ..priority = -2;
    await add(grid);
    await _spawnTile();
    await _spawnTile();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (board.every((tile) => tile == null)) return;
    _measure();
    grid
      ..position = _boardOrigin
      ..size = Vector2.all(_cellSize * gridSize);
    for (final tile in board) {
      if (tile == null) continue;
      tile
        ..resize(_cellSize)
        ..position = _positionOf(tile.slot);
    }
  }

  void _measure() {
    final boardSide = min(size.x * 0.9, size.y * 0.5);
    _cellSize = boardSide / gridSize;
    _boardOrigin = Vector2((size.x - boardSide) / 2, size.y * 0.28);
  }

  Vector2 _positionOf(int slot) =>
      _boardOrigin +
      Vector2(
        (slot % gridSize) * _cellSize,
        (slot ~/ gridSize) * _cellSize,
      );

  Future<void> _spawnTile() async {
    if (_isTornDown) return;
    final empty = [
      for (var slot = 0; slot < board.length; slot++)
        if (board[slot] == null) slot,
    ];
    if (empty.isEmpty) return;

    final slot = empty[_random.nextInt(empty.length)];
    // Four turns up occasionally, which is what makes a board fill awkwardly.
    final value = _random.nextDouble() < 0.1 ? 4 : 2;
    final tile = MergeTile(
      value: value,
      slot: slot,
      position: _positionOf(slot),
      side: _cellSize,
    );
    board[slot] = tile;
    await add(tile);
    tile.appear();
    if (value > highestTile) highestNotifier.value = value;
  }

  /// Slot indices of [line], walked from the edge the swipe pushes towards.
  List<int> _traversal(int line, SwipeDirection direction) {
    return switch (direction) {
      SwipeDirection.left => [
        for (var i = 0; i < gridSize; i++) line * gridSize + i,
      ],
      SwipeDirection.right => [
        for (var i = gridSize - 1; i >= 0; i--) line * gridSize + i,
      ],
      SwipeDirection.up => [
        for (var i = 0; i < gridSize; i++) i * gridSize + line,
      ],
      SwipeDirection.down => [
        for (var i = gridSize - 1; i >= 0; i--) i * gridSize + line,
      ],
    };
  }

  /// Slides and merges everything in [direction].
  ///
  /// Returns whether anything actually moved; a swipe that changes nothing is
  /// not a turn and does not add a tile.
  bool move(SwipeDirection direction) {
    if (isGameOver) return false;

    final before = values;
    final beforeScore = score;
    var moved = false;
    var gained = 0;

    for (var line = 0; line < gridSize; line++) {
      final slots = _traversal(line, direction);
      var cursor = 0;
      MergeTile? lastPlaced;
      var lastPlacedMerged = false;

      for (final slot in slots) {
        final tile = board[slot];
        if (tile == null) continue;
        board[slot] = null;

        if (lastPlaced != null &&
            !lastPlacedMerged &&
            lastPlaced.value == tile.value) {
          // Slide onto the tile it merges with, then disappear behind it.
          _slide(tile, lastPlaced.slot, thenRemove: true);
          final merged = lastPlaced.value * 2;
          lastPlaced.promoteTo(merged);
          gained += merged;
          if (merged > highestTile) highestNotifier.value = merged;
          lastPlacedMerged = true;
          moved = true;
          continue;
        }

        final target = slots[cursor++];
        board[target] = tile;
        if (target != slot) {
          _slide(tile, target);
          moved = true;
        }
        lastPlaced = tile;
        lastPlacedMerged = false;
      }
    }

    if (!moved) return false;

    _snapshotValues = before;
    _snapshotScore = beforeScore;
    if (gained > 0) {
      scoreNotifier.value = score + gained;
      // Bigger merges land higher up the scale.
      sounds.note(gained ~/ 4);
    } else {
      sounds.tap();
    }

    unawaited(_finishMove(gained));
    return true;
  }

  Future<void> _finishMove(int gained) async {
    await _spawnTile();
    if (_isTornDown) return;
    if (gained > 0 && _isNewMilestone(gained)) {
      undosNotifier.value = min(undosLeft + 1, maxUndos);
    }
    _checkForGameOver();
  }

  /// Whether the merge that just happened produced a new biggest tile, which
  /// is what earns another undo.
  bool _isNewMilestone(int gained) => highestTile == gained && gained >= 64;

  void _slide(MergeTile tile, int target, {bool thenRemove = false}) {
    tile.slot = target;
    final slide = tile.add(
      MoveToEffect(
        _positionOf(target),
        EffectController(duration: _slideDuration, curve: Curves.easeOut),
        onComplete: thenRemove ? tile.removeFromParent : null,
      ),
    );
    if (slide is Future<void>) unawaited(slide);
    // The tile being swallowed slides underneath the one it merges into.
    if (thenRemove) tile.priority = -1;
  }

  /// Whether any swipe would still change the board.
  bool get hasAnyMove {
    if (board.any((tile) => tile == null)) return true;
    for (var row = 0; row < gridSize; row++) {
      for (var column = 0; column < gridSize; column++) {
        final value = board[row * gridSize + column]!.value;
        if (column + 1 < gridSize &&
            board[row * gridSize + column + 1]!.value == value) {
          return true;
        }
        if (row + 1 < gridSize &&
            board[(row + 1) * gridSize + column]!.value == value) {
          return true;
        }
      }
    }
    return false;
  }

  /// Puts the board back as it was before the last move.
  ///
  /// Returns whether an undo was available to spend.
  bool undo() {
    final snapshot = _snapshotValues;
    if (snapshot == null || undosLeft <= 0) return false;

    undosNotifier.value = undosLeft - 1;
    scoreNotifier.value = _snapshotScore;
    _snapshotValues = null;
    isGameOver = false;
    overlays.remove(gameOverOverlayId);
    sounds.note(3);
    unawaited(_rebuild(snapshot));
    return true;
  }

  Future<void> _rebuild(List<int> snapshot) async {
    for (final tile in board) {
      tile?.removeFromParent();
    }
    board.fillRange(0, board.length, null);

    for (var slot = 0; slot < snapshot.length; slot++) {
      final value = snapshot[slot];
      if (value == 0) continue;
      final tile = MergeTile(
        value: value,
        slot: slot,
        position: _positionOf(slot),
        side: _cellSize,
      );
      board[slot] = tile;
      await add(tile);
    }
  }

  void _checkForGameOver() {
    if (isGameOver || hasAnyMove) return;
    isGameOver = true;
    sounds.fail();
    // Decide and show straight away; the write itself can settle in the
    // background rather than holding up the overlay.
    isNewRecord = records.beatsRecord(
      recordGameId,
      recordMetric,
      score,
      goal: RecordGoal.higher,
    );
    if (isNewRecord) bestScoreNotifier.value = score;
    unawaited(
      records.submit(
        recordGameId,
        recordMetric,
        score,
        goal: RecordGoal.higher,
      ),
    );
    overlays.add(gameOverOverlayId);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragFrom = event.localPosition.clone();
    _dragTo = null;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _dragTo = event.localEndPosition.clone();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final from = _dragFrom;
    final to = _dragTo;
    _dragFrom = null;
    _dragTo = null;
    if (from == null || to == null) return;

    final delta = to - from;
    if (delta.length < _swipeThreshold) return;

    move(
      delta.x.abs() > delta.y.abs()
          ? (delta.x > 0 ? SwipeDirection.right : SwipeDirection.left)
          : (delta.y > 0 ? SwipeDirection.down : SwipeDirection.up),
    );
  }

  /// Clears the board and starts a fresh run.
  Future<void> restart() async {
    for (final tile in board) {
      tile?.removeFromParent();
    }
    board.fillRange(0, board.length, null);
    scoreNotifier.value = 0;
    highestNotifier.value = 0;
    undosNotifier.value = startingUndos;
    _snapshotValues = null;
    _snapshotScore = 0;
    isGameOver = false;
    isNewRecord = false;
    overlays.remove(gameOverOverlayId);
    await _spawnTile();
    await _spawnTile();
  }

  /// Replaces the board with [newValues], for tests that need a set position.
  @visibleForTesting
  Future<void> setBoard(List<int> newValues) async {
    await _rebuild(newValues);
    highestNotifier.value = newValues.fold(0, max);
  }

  @override
  void onRemove() {
    _isTornDown = true;
    scoreNotifier.dispose();
    highestNotifier.dispose();
    undosNotifier.dispose();
    bestScoreNotifier.dispose();
    super.onRemove();
  }
}
