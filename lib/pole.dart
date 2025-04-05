import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Pole extends PositionComponent {
  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTRB(0, 0, 700, 20),
      Paint()..color = Colors.brown,
    );
  }
}
