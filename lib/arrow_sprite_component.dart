import 'package:flame/components.dart';
import 'package:flame/flame.dart';

enum ArrowSpriteType { left, right, up }

class ArrowSpriteComponent extends SpriteComponent with HasVisibility {
  final ArrowSpriteType type;

  ArrowSpriteComponent(this.type)
    : super(
        sprite: Sprite(
          Flame.images.fromCache(switch (type) {
            ArrowSpriteType.left => 'left.png',
            ArrowSpriteType.right => 'right.png',
            ArrowSpriteType.up => 'up.png',
          }),
        ),
        anchor: Anchor.center,
      );
}
