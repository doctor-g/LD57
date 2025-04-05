import 'dart:async';

import 'package:fish_face/game_world.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart' hide Route;

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
  FutureOr<void> onLoad() async {
    await super.onLoad();
    await FlameAudio.bgm.initialize();
    await Flame.images.loadAllImages();
    add(
      RouterComponent(
        initialRoute: 'playing',
        routes: {
          'title': Route(TitlePage.new),
          'playing': WorldRoute(GameWorld.new),
        },
      ),
    );
  }

  @override
  Color backgroundColor() => Colors.black54;

  void start() {
    FlameAudio.bgm.play('theme.ogg');
    world.start();
  }
}

class TitlePage extends PositionComponent {}
