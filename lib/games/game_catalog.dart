import 'package:flutter/material.dart';
import 'package:sadagames/game/game.dart';
import 'package:sadagames/games/block_fit/block_fit.dart';
import 'package:sadagames/games/colour_sequence/colour_sequence.dart';
import 'package:sadagames/games/merge_tiles/merge_tiles.dart';
import 'package:sadagames/games/odd_one_out/odd_one_out.dart';
import 'package:sadagames/games/sliding_puzzle/sliding_puzzle.dart';
import 'package:sadagames/games/stack_tower/stack_tower.dart';
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
    this.recordMetric,
    this.recordUnit = '',
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

  /// Metric this game stores a personal best under, or `null` if it keeps no
  /// record. Used to look the record up for the menu tile.
  final String? recordMetric;

  /// Singular word shown after the record, for example `star` or `move`. It is
  /// pluralised for display.
  final String recordUnit;
}

/// Every game available in the collection.
///
/// Adding a new game is a matter of appending an entry here; the menu page
/// renders whatever this list contains.
abstract final class GameCatalog {
  static const entries = <GameCatalogEntry>[
    GameCatalogEntry(
      id: 'block_fit',
      name: 'Block Fit',
      description: 'Drop the pieces in and clear full rows and columns.',
      icon: Icons.dashboard_rounded,
      color: Color(0xFF4CC9F0),
      routeBuilder: BlockFitPage.route,
      recordMetric: BlockFitGame.recordMetric,
      recordUnit: 'point',
    ),
    GameCatalogEntry(
      id: 'merge_tiles',
      name: 'Merge Tiles',
      description: 'Swipe to slide the tiles and merge matching numbers.',
      icon: Icons.grid_4x4_rounded,
      color: Color(0xFFF3722C),
      routeBuilder: MergeTilesPage.route,
      recordMetric: MergeTilesGame.recordMetric,
      recordUnit: 'point',
    ),
    GameCatalogEntry(
      id: 'stack_tower',
      name: 'Stack Tower',
      description: 'Tap to drop each slab. Miss and it gets cut down.',
      icon: Icons.layers_rounded,
      color: Color(0xFF06D6A0),
      routeBuilder: StackTowerPage.route,
      recordMetric: StackTowerGame.recordMetric,
      recordUnit: 'block',
    ),
    GameCatalogEntry(
      id: 'star_catcher',
      name: 'Star Catcher',
      description: 'Drag the basket and catch the falling stars.',
      icon: Icons.star_rounded,
      color: Color(0xFFFFD166),
      routeBuilder: StarCatcherPage.route,
      recordMetric: StarCatcherGame.recordMetric,
      recordUnit: 'star',
    ),
    GameCatalogEntry(
      id: 'sliding_puzzle',
      name: 'Sliding Puzzle',
      description: 'Slide the tiles back into order, fast.',
      icon: Icons.grid_view_rounded,
      color: Color(0xFF9B5DE5),
      routeBuilder: SlidingPuzzlePage.route,
      recordMetric: SlidingPuzzleGame.recordMetric,
      recordUnit: 'move',
    ),
    GameCatalogEntry(
      id: 'odd_one_out',
      name: 'Odd One Out',
      description: 'Spot the tile with the odd colour before time runs out.',
      icon: Icons.palette_rounded,
      color: Color(0xFF06D6A0),
      routeBuilder: OddOneOutPage.route,
      recordMetric: OddOneOutGame.recordMetric,
      recordUnit: 'level',
    ),
    GameCatalogEntry(
      id: 'colour_sequence',
      name: 'Colour Sequence',
      description: 'Watch the pads flash, then play them back in order.',
      icon: Icons.graphic_eq_rounded,
      color: Color(0xFFE63946),
      routeBuilder: ColourSequencePage.route,
      recordMetric: ColourSequenceGame.recordMetric,
      recordUnit: 'round',
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
