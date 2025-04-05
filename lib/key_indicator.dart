import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart' hide Image;

class KeyIndicator extends PositionComponent {
  static const _inactiveColor = Colors.black26;
  static const _activeColor = Colors.white;

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
    _spriteComponent.scale = Vector2.all(2.0);
  }

  void makeInactive() {
    _spriteComponent.scale = Vector2.all(1.0);
  }
}
