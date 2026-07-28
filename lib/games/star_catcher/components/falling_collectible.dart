import 'package:flame/components.dart';

/// Base class for anything that drops from the top of the screen towards the
/// basket.
abstract class FallingCollectible extends PositionComponent {
  FallingCollectible({
    required super.position,
    required this.speed,
    required double diameter,
  }) : super(size: Vector2.all(diameter), anchor: Anchor.center);

  /// Falling speed in logical pixels per second.
  final double speed;

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;
  }
}
