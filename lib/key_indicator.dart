import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/rendering.dart';

class KeyIndicator extends PositionComponent with HasVisibility {
  final Image image;
  late final SpriteComponent _spriteComponent;

  KeyIndicator(this.image);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    _spriteComponent = SpriteComponent(sprite: Sprite(image));
    makeInactive();
    add(_spriteComponent);
  }

  void makeActive() {
    _spriteComponent.decorator = PaintDecorator.tint(const Color(0xAAFFFF00));
  }

  void makeInactive() {
    _spriteComponent.decorator = Decorator();
  }
}
