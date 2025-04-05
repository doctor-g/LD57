import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class KeyIndicator extends PositionComponent {
  static const _inactiveColor = Colors.black26;
  static const _activeColor = Colors.white;

  final String label;
  late final TextComponent _textComponent;

  KeyIndicator(this.label);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    _textComponent = TextComponent(text: label);
    makeInactive();
    add(_textComponent);
  }

  void makeActive() {
    _textComponent.textRenderer = TextPaint(
      style: TextStyle(color: _activeColor),
    );
  }

  void makeInactive() {
    _textComponent.textRenderer = TextPaint(
      style: TextStyle(color: _inactiveColor),
    );
  }
}
