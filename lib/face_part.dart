import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

class FacePart extends PositionComponent {
  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    await Flame.images.loadAllImages();
    final sprite = await Sprite.load('eye1.png');
    final spriteComponent = SpriteComponent(sprite: sprite);
    add(spriteComponent);
  }
}
