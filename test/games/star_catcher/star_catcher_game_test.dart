import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadagames/games/star_catcher/star_catcher.dart';

/// Builds the game with a stub overlay, which the `GameWidget` would otherwise
/// register through its `overlayBuilderMap`.
StarCatcherGame _buildGame() {
  return StarCatcherGame()
    ..overlays.addEntry(
      StarCatcherGame.gameOverOverlayId,
      (_, _) => const SizedBox.shrink(),
    );
}

Star _missedStar(StarCatcherGame game) =>
    Star(position: Vector2(10, game.size.y + 100), speed: 0);

Future<void> _loseAllLives(StarCatcherGame game) async {
  for (var i = 0; i < StarCatcherGame.maxLives; i++) {
    await game.ensureAdd(_missedStar(game));
    game.update(0);
  }
}

void main() {
  group('StarCatcherGame', () {
    testWithGame<StarCatcherGame>(
      'starts with a full set of lives and no score',
      _buildGame,
      (game) async {
        expect(game.score, equals(0));
        expect(game.lives, equals(StarCatcherGame.maxLives));
        expect(game.isGameOver, isFalse);
      },
    );

    testWithGame<StarCatcherGame>(
      'spawns stars over time',
      _buildGame,
      (game) async {
        game.update(1);
        await game.ready();

        expect(game.children.query<Star>(), isNotEmpty);
      },
    );

    testWithGame<StarCatcherGame>(
      'scores a point when a star reaches the basket',
      _buildGame,
      (game) async {
        final star = Star(position: game.basket.position.clone(), speed: 0);
        await game.ensureAdd(star);

        game.update(0);

        expect(game.score, equals(1));
        expect(star.isRemoving || star.isRemoved, isTrue);
      },
    );

    testWithGame<StarCatcherGame>(
      'loses a life when a star falls past the bottom',
      _buildGame,
      (game) async {
        await game.ensureAdd(_missedStar(game));

        game.update(0);

        expect(game.lives, equals(StarCatcherGame.maxLives - 1));
      },
    );

    testWithGame<StarCatcherGame>(
      'ends the game once every life is lost',
      _buildGame,
      (game) async {
        await _loseAllLives(game);

        expect(game.lives, equals(0));
        expect(game.isGameOver, isTrue);
        expect(
          game.overlays.isActive(StarCatcherGame.gameOverOverlayId),
          isTrue,
        );
      },
    );

    testWithGame<StarCatcherGame>(
      'restart resets the score, lives and overlay',
      _buildGame,
      (game) async {
        await _loseAllLives(game);
        expect(game.isGameOver, isTrue);

        game.restart();

        expect(game.score, equals(0));
        expect(game.lives, equals(StarCatcherGame.maxLives));
        expect(game.isGameOver, isFalse);
        expect(
          game.overlays.isActive(StarCatcherGame.gameOverOverlayId),
          isFalse,
        );
      },
    );
  });

  group('Basket', () {
    testWithGame<StarCatcherGame>(
      'stays inside the screen bounds',
      _buildGame,
      (game) async {
        game.basket.moveTo(-500, game.size.x);
        expect(game.basket.position.x, equals(game.basket.size.x / 2));

        game.basket.moveTo(game.size.x + 500, game.size.x);
        expect(
          game.basket.position.x,
          equals(game.size.x - game.basket.size.x / 2),
        );
      },
    );
  });
}
