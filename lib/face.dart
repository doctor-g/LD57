import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Face extends PositionComponent {
  @override
  void render(Canvas canvas) {
    canvas.drawOval(
      Rect.fromLTRB(0, 0, 270, 325),
      Paint()..color = Colors.yellow,
    );
  }
}
