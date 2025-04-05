import 'package:fish_face/game_world.dart';
import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';

class FishFaceGame extends FlameGame<GameWorld>
    with HasKeyboardHandlerComponents {
  FishFaceGame()
    : super(
        world: GameWorld(),
        camera: CameraComponent.withFixedResolution(
          width: 800,
          height: 600,
          viewfinder: Viewfinder()..anchor = Anchor.topLeft,
        ),
      );

  @override
  Color backgroundColor() => Colors.black54;
}
