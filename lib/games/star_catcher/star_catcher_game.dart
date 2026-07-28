import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:sadagames/games/star_catcher/components/components.dart';

/// A small arcade game: drag the basket to catch the falling stars.
///
/// Every caught star awards a point and makes the next stars fall faster.
/// Missing a star costs a life, and the game ends once all lives are gone.
class StarCatcherGame extends FlameGame with DragCallbacks, TapCallbacks {
  StarCatcherGame({Random? random}) : _random = random ?? Random();

  /// Identifier of the game over overlay rendered by the Flutter layer.
  static const gameOverOverlayId = 'starCatcherGameOver';

  /// Amount of stars the player may miss before the game ends.
  static const maxLives = 3;

  static const _spawnInterval = 0.9;
  static const _baseSpeed = 110.0;
  static const _maxSpeed = 420.0;

  final Random _random;

  late final Basket basket;
  late final TextComponent _hud;

  int score = 0;
  int lives = maxLives;
  bool isGameOver = false;

  double _spawnTimer = 0;

  @override
  Color backgroundColor() => const Color(0xFF10143A);

  @override
  Future<void> onLoad() async {
    basket = Basket(position: Vector2(size.x / 2, size.y - 80));
    _hud = TextComponent(
      position: Vector2(16, 16),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    await addAll([basket, _hud]);
    _updateHud();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      unawaited(_spawnStar());
    }

    _resolveStars();
  }

  Future<void> _spawnStar() async {
    const margin = 24.0;
    final x = margin + _random.nextDouble() * (size.x - margin * 2);
    final speed = min(_baseSpeed + score * 6, _maxSpeed);
    await add(Star(position: Vector2(x, -30), speed: speed));
  }

  void _resolveStars() {
    final basketTop = basket.position.y - basket.size.y / 2;
    final basketBottom = basket.position.y + basket.size.y / 2;
    final catchRadius = basket.size.x / 2;

    for (final star in children.query<Star>()) {
      final isWithinBasketRow =
          star.position.y >= basketTop && star.position.y <= basketBottom;
      final isWithinBasketColumn =
          (star.position.x - basket.position.x).abs() <= catchRadius;

      if (isWithinBasketRow && isWithinBasketColumn) {
        star.removeFromParent();
        score++;
        _updateHud();
      } else if (star.position.y - star.size.y > size.y) {
        star.removeFromParent();
        lives--;
        _updateHud();
        if (lives <= 0) _endGame();
      }
    }
  }

  void _updateHud() {
    _hud.text = 'Score: $score    Lives: ${'♥' * lives.clamp(0, maxLives)}';
  }

  void _endGame() {
    isGameOver = true;
    overlays.add(gameOverOverlayId);
  }

  /// Clears the board and starts a fresh run.
  void restart() {
    for (final star in children.query<Star>()) {
      star.removeFromParent();
    }
    score = 0;
    lives = maxLives;
    isGameOver = false;
    _spawnTimer = 0;
    basket.moveTo(size.x / 2, size.x);
    overlays.remove(gameOverOverlayId);
    _updateHud();
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
}
