import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:sadagames/game/game.dart';

class TappingBehavior extends Behavior<Unicorn>
    with TapCallbacks, HasGameReference<Sadagames> {
  @override
  bool containsLocalPoint(Vector2 point) {
    return parent.containsLocalPoint(point);
  }

  @override
  Future<void> onTapDown(TapDownEvent event) async {
    if (parent.isAnimationPlaying()) {
      return;
    }
    game.counter++;
    parent.playAnimation();

    await game.sounds.blip();
  }
}
