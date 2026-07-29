import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/games/stack_tower/components/components.dart';
import 'package:sadagames/records/records.dart';

/// Tap to drop the sliding slab onto the tower.
///
/// Whatever hangs over the edge is sliced off, so a sloppy drop makes every
/// later drop harder. Landing one dead centre is the only way to win width
/// back, which is what keeps a long run alive.
class StackTowerGame extends FlameGame with TapCallbacks {
  StackTowerGame({required this.sounds, required this.records});

  /// Identifier of the game over overlay rendered by the Flutter layer.
  static const gameOverOverlayId = 'stackTowerGameOver';

  /// Catalog id and metric this game stores its personal best under.
  static const recordGameId = 'stack_tower';
  static const recordMetric = 'height';

  /// A drop within this many pixels of centre counts as perfect.
  static const perfectTolerance = 6.0;

  /// Width handed back for a perfect drop, never beyond the starting width.
  static const perfectBonus = 12.0;

  /// Narrower than this and the tower is beyond saving.
  static const _minWidth = 8.0;

  static const _baseSpeed = 150.0;
  static const _maxSpeed = 520.0;
  static const _scrollDuration = 0.16;

  /// Short sounds for drops, perfect hits and the collapse.
  final GameSounds sounds;

  /// Store holding the player's tallest tower between launches.
  final GameRecords records;

  /// Blocks already stacked, oldest first.
  final List<TowerBlock> blocks = [];

  /// Blocks stacked so far, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> heightNotifier = ValueNotifier(0);

  /// Perfect drops this run, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> perfectNotifier = ValueNotifier(0);

  /// Tallest tower so far, or `null` until the first run ends.
  final ValueNotifier<int?> bestHeightNotifier = ValueNotifier(null);

  int get height => heightNotifier.value;

  int get perfectDrops => perfectNotifier.value;

  int? get bestHeight => bestHeightNotifier.value;

  bool isGameOver = false;

  /// Whether the run that just ended beat the previous best.
  bool isNewRecord = false;

  /// The slab currently sliding across, or `null` once the run is over.
  TowerBlock? movingBlock;

  late PositionComponent tower;

  double _blockHeight = 0;
  double _startWidth = 0;
  double _activeY = 0;
  double _direction = 1;

  @override
  Color backgroundColor() => const Color(0xFF10143A);

  /// How fast the slab slides, which climbs with the tower.
  double get speed => min(_baseSpeed + height * 7, _maxSpeed);

  @override
  Future<void> onLoad() async {
    bestHeightNotifier.value = records.read(recordGameId, recordMetric);
    _measure();
    tower = PositionComponent(position: Vector2(0, _activeY));
    await add(tower);
    await _startTower();
  }

  void _measure() {
    _blockHeight = size.y * 0.042;
    _startWidth = size.x * 0.6;
    _activeY = size.y * 0.66;
  }

  /// `Component.add` hands back a `FutureOr`, which cannot be unawaited on
  /// its own.
  void _addToTower(Component component) {
    final added = tower.add(component);
    if (added is Future<void>) unawaited(added);
  }

  Color _colourFor(int index) =>
      HSLColor.fromAHSL(1, (index * 14) % 360, 0.55, 0.58).toColor();

  Future<void> _startTower() async {
    final base = TowerBlock(
      colour: _colourFor(0),
      position: Vector2((size.x - _startWidth) / 2, 0),
      size: Vector2(_startWidth, _blockHeight),
    );
    blocks.add(base);
    heightNotifier.value = 1;
    await tower.add(base);
    await _spawnMovingBlock();
  }

  Future<void> _spawnMovingBlock() async {
    final top = blocks.last;
    // Start on the opposite side each time so the run does not fall into a
    // rhythm the player can tap through blindly.
    _direction = -_direction;
    final block = TowerBlock(
      colour: _colourFor(blocks.length),
      position: Vector2(
        _direction > 0 ? 0 : size.x - top.width,
        -blocks.length * _blockHeight,
      ),
      size: Vector2(top.width, _blockHeight),
    );
    movingBlock = block;
    await tower.add(block);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final block = movingBlock;
    if (isGameOver || block == null) return;

    block.position.x += _direction * speed * dt;
    if (block.position.x <= 0) {
      block.position.x = 0;
      _direction = 1;
    } else if (block.right >= size.x) {
      block.position.x = size.x - block.width;
      _direction = -1;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    dropBlock();
  }

  /// Drops the sliding slab onto the tower.
  ///
  /// Returns whether the tower survived.
  bool dropBlock() {
    final block = movingBlock;
    final top = blocks.last;
    if (isGameOver || block == null) return false;

    final overlapLeft = max(block.left, top.left);
    final overlapRight = min(block.right, top.right);
    final overlap = overlapRight - overlapLeft;

    if (overlap <= 0) {
      _endGame();
      return false;
    }

    final drift = (block.left - top.left).abs();
    if (drift <= perfectTolerance) {
      _landPerfectly(block, top);
    } else {
      _landTrimmed(block, overlapLeft, overlap);
    }

    blocks.add(block);
    movingBlock = null;
    heightNotifier.value = blocks.length;

    _scrollTower();
    unawaited(_spawnMovingBlock());
    return true;
  }

  void _landPerfectly(TowerBlock block, TowerBlock top) {
    // Snap it flush and hand a little width back, capped at the width the
    // tower started with.
    final regained = min(perfectBonus, _startWidth - top.width);
    block
      ..position.x = top.left - regained / 2
      ..size.x = top.width + regained;
    perfectNotifier.value = perfectDrops + 1;
    sounds.win();
  }

  void _landTrimmed(TowerBlock block, double overlapLeft, double overlap) {
    final wasLeftOfTop = block.left < overlapLeft;
    final cutWidth = block.width - overlap;

    _addToTower(
      FallingCut(
        colour: block.colour,
        towardsLeft: wasLeftOfTop,
        position: Vector2(
          wasLeftOfTop ? block.left : overlapLeft + overlap,
          block.position.y,
        ),
        size: Vector2(cutWidth, _blockHeight),
      ),
    );

    block
      ..position.x = overlapLeft
      ..size.x = overlap;
    sounds.note(height);
  }

  /// Slides the tower down so the next slab sits at the same height on screen.
  void _scrollTower() {
    _addToTower(
      MoveToEffect(
        Vector2(0, _activeY + (blocks.length - 1) * _blockHeight),
        EffectController(duration: _scrollDuration, curve: Curves.easeOut),
      ),
    );
  }

  void _endGame() {
    isGameOver = true;
    final block = movingBlock;
    if (block != null) {
      // The slab that missed tumbles away rather than hanging in mid air.
      _addToTower(
        FallingCut(
          colour: block.colour,
          towardsLeft: block.left < blocks.last.left,
          position: block.position.clone(),
          size: block.size.clone(),
        ),
      );
      block.removeFromParent();
      movingBlock = null;
    }
    sounds.fail();

    // Decide and show straight away; the write itself can settle in the
    // background rather than holding up the overlay.
    isNewRecord = records.beatsRecord(
      recordGameId,
      recordMetric,
      height,
      goal: RecordGoal.higher,
    );
    if (isNewRecord) bestHeightNotifier.value = height;
    unawaited(
      records.submit(
        recordGameId,
        recordMetric,
        height,
        goal: RecordGoal.higher,
      ),
    );
    overlays.add(gameOverOverlayId);
  }

  /// Whether the tower has been whittled down to nothing worth playing.
  bool get isTooNarrow => blocks.isNotEmpty && blocks.last.width < _minWidth;

  /// Clears the tower and starts again from a full width base.
  Future<void> restart() async {
    for (final block in tower.children) {
      block.removeFromParent();
    }
    blocks.clear();
    movingBlock = null;
    heightNotifier.value = 0;
    perfectNotifier.value = 0;
    isGameOver = false;
    isNewRecord = false;
    _direction = 1;
    tower.position = Vector2(0, _activeY);
    overlays.remove(gameOverOverlayId);
    await _startTower();
  }

  @override
  void onRemove() {
    heightNotifier.dispose();
    perfectNotifier.dispose();
    bestHeightNotifier.dispose();
    super.onRemove();
  }
}
