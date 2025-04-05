import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/rendering.dart';

class KeyIndicator extends PositionComponent with HasVisibility {
  final Image image;
  late final SpriteComponent _spriteComponent;

  KeyIndicator(this.image) : super(anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    _spriteComponent = SpriteComponent(
      sprite: Sprite(image),
      size: image.size,
      priority: 10,
    );
    size = image.size;
    add(_spriteComponent);
  }

  void activate() {
    _spriteComponent.decorator.addLast(
      PaintDecorator.tint(const Color(0xAAFFFF00)),
    );
  }

  void deactivate() {
    _spriteComponent.decorator.removeLast();
  }
}
