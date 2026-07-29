import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/games/tile_tap/components/components.dart';
import 'package:sadagames/records/records.dart';

/// Tap the dark tile in each row before it scrolls off the bottom.
///
/// Each column has its own note, so a good run turns into a tune. The board
/// speeds up with every tile, and a skip earned along the way covers exactly
/// one mistake.
class TileTapGame extends FlameGame with TapCallbacks {
  TileTapGame({required this.sounds, required this.records, Random? random})
    : _random = random ?? Random();

  /// Identifier of the game over overlay rendered by the Flutter layer.
  static const gameOverOverlayId = 'tileTapGameOver';

  /// Catalog id and metric this game stores its personal best under.
  static const recordGameId = 'tile_tap';
  static const recordMetric = 'tile';

  /// Columns across the board.
  static const columns = 4;

  /// Tiles that have to be hit to earn one skip.
  static const tilesPerSkip = 15;

  /// Skips the player may hold at once.
  static const maxSkips = 2;

  static const _baseSpeed = 260.0;
  static const _maxSpeed = 720.0;
  static const _rowsOnScreen = 4;
  static const _queuedRows = 3;

  /// Rows of clear space under the first tile at the start of a run, so the
  /// player has a moment to find it before it can slip past.
  static const _startLead = 3;

  /// Short sounds giving each column its own note.
  final GameSounds sounds;

  /// Store holding the player's best run between launches.
  final GameRecords records;

  final Random _random;

  /// Rows on the board, lowest first.
  final List<TileRow> rows = [];

  /// Tiles hit so far, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> tilesNotifier = ValueNotifier(0);

  /// Skips in hand, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> skipsNotifier = ValueNotifier(0);

  /// Best run so far, or `null` until the first run ends.
  final ValueNotifier<int?> bestTilesNotifier = ValueNotifier(null);

  int get tiles => tilesNotifier.value;

  int get skips => skipsNotifier.value;

  int? get bestTiles => bestTilesNotifier.value;

  bool isGameOver = false;

  /// Whether the run that just ended beat the previous best.
  bool isNewRecord = false;

  double _rowHeight = 0;
  int _tilesSinceSkip = 0;

  /// The row the player has to deal with next, or `null` if there is none.
  TileRow? get targetRow {
    for (final row in rows) {
      if (!row.isTapped) return row;
    }
    return null;
  }

  /// How fast the board scrolls, which climbs with every tile hit.
  double get speed => min(_baseSpeed + tiles * 7, _maxSpeed);

  @override
  Color backgroundColor() => const Color(0xFF10143A);

  @override
  Future<void> onLoad() async {
    bestTilesNotifier.value = records.read(recordGameId, recordMetric);
    _rowHeight = size.y / _rowsOnScreen;
    await _fillBoard();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (rows.isEmpty) return;
    _rowHeight = size.y / _rowsOnScreen;
    for (final row in rows) {
      row.size = Vector2(size.x, _rowHeight);
    }
  }

  Future<void> _fillBoard() async {
    // Stack rows upwards, starting clear of the bottom edge so the run does
    // not begin with a row already on its way out.
    for (var i = 0; i < _rowsOnScreen + _queuedRows; i++) {
      await _addRow(size.y - (_startLead + i) * _rowHeight);
    }
  }

  Future<void> _addRow(double y) async {
    final row = TileRow(
      column: _random.nextInt(columns),
      position: Vector2(0, y),
      size: Vector2(size.x, _rowHeight),
    );
    rows.add(row);
    await add(row);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    final step = speed * dt;
    for (final row in rows) {
      row.position.y += step;
    }

    _retireRows();
    _topUpRows();
  }

  void _retireRows() {
    for (final row in [...rows]) {
      if (row.position.y < size.y) continue;
      rows.remove(row);
      row.removeFromParent();
      // A row that leaves untapped is a miss, which is what a skip covers.
      if (!row.isTapped) _mistake();
    }
  }

  /// Keeps a few untapped rows queued above the screen.
  ///
  /// Counting rows rather than untapped ones is not enough: a quick player
  /// can clear every row on screen before the track scrolls, and then there
  /// would be nothing left to tap.
  void _topUpRows() {
    while (rows.where((row) => !row.isTapped).length < _queuedRows) {
      final highest = rows.isEmpty
          ? size.y
          : rows.map((row) => row.position.y).reduce(min);
      unawaited(_addRow(highest - _rowHeight));
    }
  }

  /// Hits [column], judged against the row the player owes.
  ///
  /// Returns whether it was the right column.
  bool tapColumn(int column) {
    if (isGameOver) return false;
    final target = targetRow;
    if (target == null) return false;

    sounds.note(column);

    if (target.column != column) {
      _mistake();
      return false;
    }

    target.isTapped = true;
    tilesNotifier.value = tiles + 1;
    _tilesSinceSkip++;
    if (_tilesSinceSkip >= tilesPerSkip) {
      _tilesSinceSkip = 0;
      skipsNotifier.value = min(skips + 1, maxSkips);
    }
    return true;
  }

  void _mistake() {
    if (isGameOver) return;
    if (skips > 0) {
      // Spend a skip instead of ending the run.
      skipsNotifier.value = skips - 1;
      sounds.win();
      return;
    }
    _endGame();
  }

  void _endGame() {
    isGameOver = true;
    sounds.fail();
    // Decide and show straight away; the write itself can settle in the
    // background rather than holding up the overlay.
    isNewRecord = records.beatsRecord(
      recordGameId,
      recordMetric,
      tiles,
      goal: RecordGoal.higher,
    );
    if (isNewRecord) bestTilesNotifier.value = tiles;
    unawaited(
      records.submit(
        recordGameId,
        recordMetric,
        tiles,
        goal: RecordGoal.higher,
      ),
    );
    overlays.add(gameOverOverlayId);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    final column = (event.localPosition.x / (size.x / columns)).floor();
    tapColumn(column.clamp(0, columns - 1));
  }

  /// Clears the board and starts a fresh run.
  Future<void> restart() async {
    for (final row in rows) {
      row.removeFromParent();
    }
    rows.clear();
    tilesNotifier.value = 0;
    skipsNotifier.value = 0;
    _tilesSinceSkip = 0;
    isGameOver = false;
    isNewRecord = false;
    overlays.remove(gameOverOverlayId);
    await _fillBoard();
  }

  @override
  void onRemove() {
    tilesNotifier.dispose();
    skipsNotifier.dispose();
    bestTilesNotifier.dispose();
    super.onRemove();
  }
}
