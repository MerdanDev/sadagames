import 'package:flutter/material.dart';
import 'package:sadagames/game/game.dart';
import 'package:sadagames/games/sliding_puzzle/sliding_puzzle.dart';
import 'package:sadagames/games/star_catcher/star_catcher.dart';

/// A single entry of the game collection, as shown on the menu page.
class GameCatalogEntry {
  const GameCatalogEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.routeBuilder,
  });

  /// Stable identifier, also used as the widget key on the menu page.
  final String id;

  final String name;

  final String description;

  final IconData icon;

  /// Accent color used for the entry's leading icon.
  final Color color;

  /// Builds the route that starts this game.
  final Route<void> Function() routeBuilder;
}

/// Every game available in the collection.
///
/// Adding a new game is a matter of appending an entry here; the menu page
/// renders whatever this list contains.
abstract final class GameCatalog {
  static const entries = <GameCatalogEntry>[
    GameCatalogEntry(
      id: 'star_catcher',
      name: 'Star Catcher',
      description: 'Drag the basket and catch the falling stars.',
      icon: Icons.star_rounded,
      color: Color(0xFFFFD166),
      routeBuilder: StarCatcherPage.route,
    ),
    GameCatalogEntry(
      id: 'sliding_puzzle',
      name: 'Sliding Puzzle',
      description: 'Slide the tiles back into order, fast.',
      icon: Icons.grid_view_rounded,
      color: Color(0xFF9B5DE5),
      routeBuilder: SlidingPuzzlePage.route,
    ),
    GameCatalogEntry(
      id: 'unicorn_tap',
      name: 'Unicorn Tap',
      description: 'Tap the unicorn and watch the counter climb.',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF2A48DF),
      routeBuilder: GamePage.route,
    ),
  ];
}
