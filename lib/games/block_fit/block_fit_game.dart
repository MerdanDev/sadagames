import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/games/block_fit/block_shape.dart';
import 'package:sadagames/games/block_fit/components/components.dart';
import 'package:sadagames/records/records.dart';

/// Drop pieces onto the grid and clear full rows and columns.
///
/// There is no clock: the pressure comes from the board filling up, and from
/// the pieces getting more awkward the better the player does. The run ends
/// when none of the three pieces in the tray fit anywhere.
class BlockFitGame extends FlameGame with DragCallbacks {
  BlockFitGame({required this.sounds, required this.records, Random? random})
    : _random = random ?? Random();

  /// Identifier of the game over overlay rendered by the Flutter layer.
  static const gameOverOverlayId = 'blockFitGameOver';

  /// Catalog id and metric this game stores its personal best under.
  static const recordGameId = 'block_fit';
  static const recordMetric = 'score';

  /// Cells per row and per column.
  static const gridSize = 8;

  /// Pieces offered at a time.
  static const trySize = 3;

  /// Lines the player has to clear to earn one tray swap.
  static const linesPerSwap = 8;

  /// Swaps the player may hold at once.
  static const maxSwaps = 3;

  /// Head start added per cell along a clearing line, so it sweeps.
  static const _sweepPerCell = 0.022;

  /// Short sounds for placing, clearing and failing.
  final GameSounds sounds;

  /// Store holding the player's best score between launches.
  final GameRecords records;

  final Random _random;

  /// Filled cells, indexed `row * gridSize + column`; `null` is empty.
  final List<Color?> cells = List<Color?>.filled(gridSize * gridSize, null);

  /// Pieces on offer. A slot is `null` once its piece has been placed.
  final List<BlockShape?> tray = List<BlockShape?>.filled(trySize, null);

  /// Score so far, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);

  /// Tray swaps in hand, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> swapsNotifier = ValueNotifier(0);

  /// Best score so far, or `null` until the first run ends.
  final ValueNotifier<int?> bestScoreNotifier = ValueNotifier(null);

  int get score => scoreNotifier.value;

  int get swaps => swapsNotifier.value;

  int? get bestScore => bestScoreNotifier.value;

  bool isGameOver = false;

  /// Whether the run that just ended beat the previous best.
  bool isNewRecord = false;

  /// Where the dragged piece would land, for the board to preview.
  (BlockShape, int, int)? preview;

  late BlockBoard board;

  final List<BlockPiece> _pieces = [];

  int _linesCleared = 0;
  double _cellSize = 0;
  double _trayCellSize = 0;
  Vector2 _boardOrigin = Vector2.zero();
  BlockPiece? _dragged;

  /// Side of one board cell in logical pixels.
  double get cellSize => _cellSize;

  @override
  Color backgroundColor() => const Color(0xFF10143A);

  @override
  Future<void> onLoad() async {
    bestScoreNotifier.value = records.read(recordGameId, recordMetric);
    _measure();
    board = BlockBoard()
      ..position = _boardOrigin
      ..size = Vector2.all(_cellSize * gridSize);
    await add(board);
    await _refillTray();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_pieces.isEmpty) return;
    _measure();
    board
      ..position = _boardOrigin
      ..size = Vector2.all(_cellSize * gridSize);
    _layOutTray();
  }

  void _measure() {
    final boardSide = min(size.x * 0.9, size.y * 0.56);
    _cellSize = boardSide / gridSize;
    _trayCellSize = _cellSize * 0.52;
    _boardOrigin = Vector2((size.x - boardSide) / 2, size.y * 0.17);
  }

  /// The colour filling the cell, or `null` when it is empty.
  Color? cellAt(int column, int row) => cells[row * gridSize + column];

  void _setCell(int column, int row, Color? colour) =>
      cells[row * gridSize + column] = colour;

  /// Whether [shape] fits with its top left corner at [column], [row].
  bool canPlace(BlockShape shape, int column, int row) {
    for (final (offsetColumn, offsetRow) in shape.cells) {
      final targetColumn = column + offsetColumn;
      final targetRow = row + offsetRow;
      final isInside =
          targetColumn >= 0 &&
          targetColumn < gridSize &&
          targetRow >= 0 &&
          targetRow < gridSize;
      if (!isInside || cellAt(targetColumn, targetRow) != null) return false;
    }
    return true;
  }

  /// Whether [shape] fits anywhere at all.
  bool fitsAnywhere(BlockShape shape) {
    for (var row = 0; row < gridSize; row++) {
      for (var column = 0; column < gridSize; column++) {
        if (canPlace(shape, column, row)) return true;
      }
    }
    return false;
  }

  /// Whether any piece still in the tray can be placed.
  bool get hasAnyMove => tray.whereType<BlockShape>().any(fitsAnywhere);

  /// Places the tray piece in [slot] at [column], [row].
  ///
  /// Returns whether the move was legal.
  bool placeFromTray(int slot, int column, int row) {
    if (isGameOver) return false;
    final shape = tray[slot];
    if (shape == null || !canPlace(shape, column, row)) return false;

    for (final (offsetColumn, offsetRow) in shape.cells) {
      _setCell(column + offsetColumn, row + offsetRow, shape.colour);
    }
    tray[slot] = null;
    scoreNotifier.value = score + shape.size;

    final cleared = _clearFullLines();
    if (cleared > 0) {
      // Clearing several lines at once is worth far more than doing it one at
      // a time, which is what makes setting a big clear up worthwhile.
      scoreNotifier.value = score + cleared * cleared * gridSize;
      _linesCleared += cleared;
      if (_linesCleared >= linesPerSwap) {
        _linesCleared -= linesPerSwap;
        swapsNotifier.value = min(swaps + 1, maxSwaps);
      }
      // A bigger clear reaches further up the scale.
      sounds.note(cleared * 2);
    } else {
      sounds.tap();
    }

    return true;
  }

  int _clearFullLines() {
    final fullRows = <int>[];
    final fullColumns = <int>[];

    for (var row = 0; row < gridSize; row++) {
      var isFull = true;
      for (var column = 0; column < gridSize; column++) {
        if (cellAt(column, row) == null) {
          isFull = false;
          break;
        }
      }
      if (isFull) fullRows.add(row);
    }

    for (var column = 0; column < gridSize; column++) {
      var isFull = true;
      for (var row = 0; row < gridSize; row++) {
        if (cellAt(column, row) == null) {
          isFull = false;
          break;
        }
      }
      if (isFull) fullColumns.add(column);
    }

    // Collect first, clear after, so a row and a column crossing each other
    // both count. Cells are keyed by index so a crossing cell is only
    // animated once.
    final clearing = <int, ClearedCell>{};

    void mark(int column, int row, double delay) {
      final index = row * gridSize + column;
      final colour = cellAt(column, row);
      if (colour == null || clearing.containsKey(index)) return;
      clearing[index] = ClearedCell(
        colour: colour,
        delay: delay,
        side: _cellSize,
        position: Vector2(
          (column + 0.5) * _cellSize,
          (row + 0.5) * _cellSize,
        ),
      );
    }

    for (final row in fullRows) {
      for (var column = 0; column < gridSize; column++) {
        mark(column, row, column * _sweepPerCell);
      }
    }
    for (final column in fullColumns) {
      for (var row = 0; row < gridSize; row++) {
        mark(column, row, row * _sweepPerCell);
      }
    }

    for (final row in fullRows) {
      for (var column = 0; column < gridSize; column++) {
        _setCell(column, row, null);
      }
    }
    for (final column in fullColumns) {
      for (var row = 0; row < gridSize; row++) {
        _setCell(column, row, null);
      }
    }

    unawaited(board.addAll(clearing.values));

    return fullRows.length + fullColumns.length;
  }

  /// Replaces the whole tray, spending one earned swap.
  ///
  /// Returns whether a swap was available.
  bool swapTray() {
    if (isGameOver || swaps <= 0) return false;
    swapsNotifier.value = swaps - 1;
    sounds.win();
    unawaited(_refillTray(force: true));
    return true;
  }

  /// Bigger, more awkward pieces creep in as the score climbs.
  BlockShape _rollShape() {
    final bigChance = min(0.15 + score / 1500, 0.55);
    final pool = _random.nextDouble() < bigChance ? bigShapes : smallShapes;
    return pool[_random.nextInt(pool.length)];
  }

  Future<void> _refillTray({bool force = false}) async {
    if (!force && tray.any((shape) => shape != null)) return;

    for (final piece in _pieces) {
      piece.removeFromParent();
    }
    _pieces.clear();

    for (var slot = 0; slot < trySize; slot++) {
      tray[slot] = _rollShape();
    }
    await _buildTrayPieces();
    _checkForGameOver();
  }

  Future<void> _buildTrayPieces() async {
    for (var slot = 0; slot < trySize; slot++) {
      final shape = tray[slot];
      if (shape == null) continue;
      final piece = BlockPiece(
        shape: shape,
        slot: slot,
        cellSize: _trayCellSize,
      );
      _pieces.add(piece);
      await add(piece);
    }
    _layOutTray();
  }

  void _layOutTray() {
    final trayTop = _boardOrigin.y + _cellSize * gridSize + size.y * 0.06;
    final slotWidth = size.x / trySize;

    for (var slot = 0; slot < trySize; slot++) {
      final piece = _pieceForSlot(slot);
      if (piece == null) continue;
      piece
        ..cellSize = _trayCellSize
        ..traySlot = Vector2(
          slotWidth * slot + (slotWidth - piece.width) / 2,
          trayTop,
        )
        ..position = piece.traySlot.clone();
    }
  }

  BlockPiece? _pieceForSlot(int slot) {
    for (final piece in _pieces) {
      if (piece.slot == slot) return piece;
    }
    return null;
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
    if (isGameOver) return;

    for (final piece in _pieces.reversed) {
      if (piece.toRect().contains(event.localPosition.toOffset())) {
        _dragged = piece
          ..cellSize = _cellSize
          ..priority = 10;
        _positionDragged(event.localPosition);
        return;
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final piece = _dragged;
    if (piece == null) return;

    _positionDragged(event.localEndPosition);
    final target = _targetCell(piece);
    preview = target != null && canPlace(piece.shape, target.$1, target.$2)
        ? (piece.shape, target.$1, target.$2)
        : null;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final piece = _dragged;
    _dragged = null;
    preview = null;
    if (piece == null) return;

    piece.priority = 0;
    final target = _targetCell(piece);

    if (target != null && placeFromTray(piece.slot, target.$1, target.$2)) {
      _pieces.remove(piece);
      piece.removeFromParent();
      unawaited(_refillTray());
      _checkForGameOver();
    } else {
      piece.returnToTray(_trayCellSize);
    }
  }

  /// Lifts the piece above the finger so it is not hidden while dragging.
  void _positionDragged(Vector2 pointer) {
    final piece = _dragged;
    if (piece == null) return;
    piece.position = Vector2(
      pointer.x - piece.width / 2,
      pointer.y - piece.height - _cellSize * 0.6,
    );
  }

  (int, int)? _targetCell(BlockPiece piece) {
    final column = ((piece.position.x - _boardOrigin.x) / _cellSize).round();
    final row = ((piece.position.y - _boardOrigin.y) / _cellSize).round();
    if (column < 0 || row < 0 || column >= gridSize || row >= gridSize) {
      return null;
    }
    return (column, row);
  }

  /// Clears the board and starts a fresh run.
  void restart() {
    cells.fillRange(0, cells.length, null);
    scoreNotifier.value = 0;
    swapsNotifier.value = 0;
    _linesCleared = 0;
    isGameOver = false;
    isNewRecord = false;
    preview = null;
    overlays.remove(gameOverOverlayId);
    unawaited(_refillTray(force: true));
  }

  @override
  void onRemove() {
    scoreNotifier.dispose();
    swapsNotifier.dispose();
    bestScoreNotifier.dispose();
    super.onRemove();
  }
}
