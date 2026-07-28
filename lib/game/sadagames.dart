import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:sadagames/audio/audio.dart';
import 'package:sadagames/game/game.dart';
import 'package:sadagames/l10n/l10n.dart';

class Sadagames extends FlameGame {
  Sadagames({
    required this.l10n,
    required this.sounds,
    required this.textStyle,
    required Images images,
  }) {
    this.images = images;
  }

  final AppLocalizations l10n;

  /// Short sound played when the unicorn is tapped.
  final GameSounds sounds;

  final TextStyle textStyle;

  int counter = 0;

  CounterComponent? counterComponent;

  EdgeInsets _safeArea = EdgeInsets.zero;

  /// Insets of the system bars, in logical pixels.
  ///
  /// The canvas is deliberately edge to edge, so the counter has to be pushed
  /// clear of the home indicator by hand.
  EdgeInsets get safeArea => _safeArea;

  set safeArea(EdgeInsets value) {
    if (value == _safeArea) return;
    _safeArea = value;
    // The view hands this over before the first layout, when `size` would
    // still throw; `onLoad` positions the counter with it soon after.
    if (hasLayout) _positionCounterComponent(size);
  }

  @override
  Color backgroundColor() => const Color(0xFF2A48DF);

  @override
  Future<void> onLoad() async {
    final world = World(
      children: [
        Unicorn(position: size / 2),
      ],
    );

    final camera = CameraComponent(world: world);
    await addAll([world, camera]);

    camera.viewfinder.position = size / 2;
    camera.viewfinder.zoom = 8;

    // add a HUD component showing number of taps on unicorn
    counterComponent = CounterComponent(position: Vector2(0, 0));
    camera.viewport.add(counterComponent!);
    _positionCounterComponent(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _positionCounterComponent(size);
  }

  void _positionCounterComponent(Vector2 size) {
    counterComponent?.position = Vector2(
      10 + _safeArea.left,
      size.y - 10 - _safeArea.bottom,
    );
  }
}
