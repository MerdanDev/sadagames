import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/sliding_puzzle/components/components.dart';
import 'package:sadagames/gen/assets.gen.dart';

/// A classic sliding puzzle: put the tiles back in order in as few moves as
/// possible.
///
/// The board is shuffled by replaying random legal moves from the solved state,
/// which guarantees every shuffle can actually be solved.
class SlidingPuzzleGame extends FlameGame {
  SlidingPuzzleGame({required this.effectPlayer, Random? random})
    : _random = random ?? Random();

  /// Identifier of the solved overlay rendered by the Flutter layer.
  static const solvedOverlayId = 'slidingPuzzleSolved';

  /// Tiles per row and per column.
  static const gridSize = 3;

  /// Numbered tiles on the board, the empty slot excluded.
  static const int tileCount = gridSize * gridSize - 1;

  static const _shuffleMoves = 80;
  static const _slideDuration = 0.14;

  /// Player used for the short slide and win sound effects.
  final AudioPlayer effectPlayer;

  final Random _random;

  /// Board state, where index is the slot and the value is the tile number.
  /// `0` marks the empty slot.
  final List<int> board = List<int>.generate(gridSize * gridSize, (i) => i + 1)
    ..[gridSize * gridSize - 1] = 0;

  final Map<int, PuzzleTile> _tiles = <int, PuzzleTile>{};

  /// Moves played so far, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> movesNotifier = ValueNotifier(0);

  /// Seconds elapsed since the first move.
  final ValueNotifier<int> secondsNotifier = ValueNotifier(0);

  bool isSolved = false;

  bool _isRunning = false;
  double _elapsed = 0;
  double _side = 0;
  Vector2 _origin = Vector2.zero();

  int get moves => movesNotifier.value;

  @override
  Color backgroundColor() => const Color(0xFF10143A);

  @override
  Future<void> onLoad() async {
    shuffle();
    _measureBoard();

    for (var slot = 0; slot < board.length; slot++) {
      final value = board[slot];
      if (value == 0) continue;
      final tile = PuzzleTile(
        value: value,
        position: _positionOf(slot),
        side: _side,
      );
      _tiles[value] = tile;
      await add(tile);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isRunning || isSolved) return;
    _elapsed += dt;
    secondsNotifier.value = _elapsed.floor();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_tiles.isEmpty) return;
    _measureBoard();
    for (final entry in _tiles.entries) {
      entry.value
        ..resize(_side)
        ..position = _positionOf(board.indexOf(entry.key));
    }
  }

  void _measureBoard() {
    final boardSide = min(size.x, size.y) * 0.82;
    _side = boardSide / gridSize;
    _origin = Vector2(
      (size.x - boardSide) / 2,
      (size.y - boardSide) / 2,
    );
  }

  Vector2 _positionOf(int slot) {
    final row = slot ~/ gridSize;
    final column = slot % gridSize;
    return _origin + Vector2(column * _side, row * _side);
  }

  /// Index of the empty slot.
  int get emptySlot => board.indexOf(0);

  /// Whether the tile sitting in [slot] is next to the empty slot.
  bool canMoveSlot(int slot) {
    final rowDistance = (slot ~/ gridSize) - (emptySlot ~/ gridSize);
    final columnDistance = (slot % gridSize) - (emptySlot % gridSize);
    return rowDistance.abs() + columnDistance.abs() == 1;
  }

  /// Slides the tile showing [value], if it is next to the empty slot.
  ///
  /// Returns whether the move was legal.
  bool tryMoveValue(int value) {
    if (isSolved) return false;

    final slot = board.indexOf(value);
    if (slot == -1 || !canMoveSlot(slot)) return false;

    _swapWithEmpty(slot);
    movesNotifier.value = moves + 1;
    _isRunning = true;

    final slide = _tiles[value]?.add(
      MoveToEffect(
        _positionOf(board.indexOf(value)),
        EffectController(duration: _slideDuration, curve: Curves.easeOut),
      ),
    );
    if (slide is Future<void>) unawaited(slide);

    if (_checkSolved()) {
      _onSolved();
    } else {
      unawaited(_playEffect(rate: 1.2));
    }
    return true;
  }

  void _swapWithEmpty(int slot) {
    final empty = emptySlot;
    board[empty] = board[slot];
    board[slot] = 0;
  }

  bool _checkSolved() {
    for (var slot = 0; slot < tileCount; slot++) {
      if (board[slot] != slot + 1) return false;
    }
    return board.last == 0;
  }

  void _onSolved() {
    isSolved = true;
    _isRunning = false;
    unawaited(_playEffect(rate: 0.9));
    overlays.add(solvedOverlayId);
  }

  Future<void> _playEffect({required double rate}) async {
    await effectPlayer.setPlaybackRate(rate);
    await effectPlayer.play(AssetSource(Assets.audio.effect));
  }

  /// Shuffles the board by replaying random legal moves, so the result is
  /// always solvable. Reshuffles in the unlikely case it lands solved.
  void shuffle() {
    do {
      for (var i = 0; i < _shuffleMoves; i++) {
        final movable = <int>[
          for (var slot = 0; slot < board.length; slot++)
            if (canMoveSlot(slot) && board[slot] != 0) slot,
        ];
        _swapWithEmpty(movable[_random.nextInt(movable.length)]);
      }
    } while (_checkSolved());
  }

  /// Reshuffles the board and clears the move and time counters.
  void restart() {
    shuffle();
    for (final entry in _tiles.entries) {
      entry.value.position = _positionOf(board.indexOf(entry.key));
    }
    movesNotifier.value = 0;
    secondsNotifier.value = 0;
    _elapsed = 0;
    _isRunning = false;
    isSolved = false;
    overlays.remove(solvedOverlayId);
  }

  @override
  void onRemove() {
    movesNotifier.dispose();
    secondsNotifier.dispose();
    super.onRemove();
  }
}
