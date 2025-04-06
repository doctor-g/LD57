import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart';

class Pole extends PositionComponent {
  static const _length = 700.0;
  static const _width = 20.0;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    add(
      MoveByEffect(
        Vector2(0, 10),
        InfiniteEffectController(
          NoiseEffectController(
            duration: 10.0,
            noise: PerlinNoise(frequency: 3),
          ),
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTRB(0, 0, _length, _width),
      Paint()..color = Colors.brown,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, 0, _length, _width),
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 10.0,
    );
  }
}
