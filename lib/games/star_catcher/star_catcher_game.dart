import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/star_catcher/components/components.dart';
import 'package:sadagames/gen/assets.gen.dart';

/// A small arcade game: drag the basket to catch the falling stars.
///
/// Every caught star awards a point, speeds the next stars up and shrinks them
/// a little, so the game keeps getting harder. Missing a star costs a life;
/// hearts drop in once the player is warmed up and give a life back.
class StarCatcherGame extends FlameGame with DragCallbacks, TapCallbacks {
  StarCatcherGame({required this.effectPlayer, Random? random})
    : _random = random ?? Random();

  /// Identifier of the game over overlay rendered by the Flutter layer.
  static const gameOverOverlayId = 'starCatcherGameOver';

  /// Amount of stars the player may miss before the game ends.
  static const maxLives = 3;

  /// Score from which hearts may start dropping.
  static const heartUnlockScore = 5;

  static const _spawnInterval = 0.9;
  static const _baseSpeed = 110.0;
  static const _maxSpeed = 420.0;
  static const _maxStarDiameter = 32.0;
  static const _minStarDiameter = 18.0;
  static const _heartChance = 0.12;

  /// Player used for the short catch and miss sound effects.
  final AudioPlayer effectPlayer;

  final Random _random;

  late final Basket basket;

  /// Current score, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);

  /// Remaining lives, exposed so the Flutter HUD can rebuild on change.
  final ValueNotifier<int> livesNotifier = ValueNotifier(maxLives);

  int get score => scoreNotifier.value;

  int get lives => livesNotifier.value;

  bool isGameOver = false;

  double _spawnTimer = 0;

  @override
  Color backgroundColor() => const Color(0xFF10143A);

  @override
  Future<void> onLoad() async {
    basket = Basket(position: Vector2(size.x / 2, size.y - 110));
    await add(basket);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      unawaited(_spawn());
    }

    _resolveCollectibles();
  }

  /// Stars shrink as the score climbs, which makes them harder to line up.
  double get _starDiameter =>
      max(_maxStarDiameter - score * 0.4, _minStarDiameter);

  bool get _shouldSpawnHeart =>
      score >= heartUnlockScore &&
      lives < maxLives &&
      _random.nextDouble() < _heartChance;

  Future<void> _spawn() async {
    const margin = 24.0;
    final x = margin + _random.nextDouble() * (size.x - margin * 2);
    final speed = min(_baseSpeed + score * 6, _maxSpeed);

    await add(
      _shouldSpawnHeart
          ? Heart(position: Vector2(x, -30), speed: speed * 0.8)
          : Star(
              position: Vector2(x, -30),
              speed: speed,
              diameter: _starDiameter,
            ),
    );
  }

  void _resolveCollectibles() {
    final basketTop = basket.position.y - basket.size.y / 2;
    final basketBottom = basket.position.y + basket.size.y / 2;
    final catchRadius = basket.size.x / 2;

    for (final collectible in children.query<FallingCollectible>()) {
      final isWithinBasketRow =
          collectible.position.y >= basketTop &&
          collectible.position.y <= basketBottom;
      final isWithinBasketColumn =
          (collectible.position.x - basket.position.x).abs() <= catchRadius;

      if (isWithinBasketRow && isWithinBasketColumn) {
        collectible.removeFromParent();
        _onCaught(collectible);
      } else if (collectible.position.y - collectible.size.y > size.y) {
        collectible.removeFromParent();
        if (collectible is Star) _onMissed();
      }
    }
  }

  void _onCaught(FallingCollectible collectible) {
    if (collectible is Heart) {
      livesNotifier.value = min(lives + 1, maxLives);
      unawaited(_playEffect(rate: 0.8));
      return;
    }

    scoreNotifier.value = score + 1;
    // Nudge the pitch up as the streak grows so catching keeps feeling better.
    unawaited(_playEffect(rate: min(1 + score * 0.02, 1.6)));
  }

  void _onMissed() {
    livesNotifier.value = lives - 1;
    unawaited(_playEffect(rate: 0.6));
    if (lives <= 0) _endGame();
  }

  Future<void> _playEffect({required double rate}) async {
    await effectPlayer.setPlaybackRate(rate);
    await effectPlayer.play(AssetSource(Assets.audio.effect));
  }

  void _endGame() {
    isGameOver = true;
    overlays.add(gameOverOverlayId);
  }

  /// Clears the board and starts a fresh run.
  void restart() {
    for (final collectible in children.query<FallingCollectible>()) {
      collectible.removeFromParent();
    }
    scoreNotifier.value = 0;
    livesNotifier.value = maxLives;
    isGameOver = false;
    _spawnTimer = 0;
    basket.moveTo(size.x / 2, size.x);
    overlays.remove(gameOverOverlayId);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (isGameOver) return;
    basket.moveTo(event.localEndPosition.x, size.x);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver) return;
    basket.moveTo(event.localPosition.x, size.x);
  }

  @override
  void onRemove() {
    scoreNotifier.dispose();
    livesNotifier.dispose();
    super.onRemove();
  }
}
