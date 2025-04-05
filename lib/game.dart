import 'package:fish_face/game_world.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

class FishFaceGame extends FlameGame<GameWorld>
    with HasKeyboardHandlerComponents {
  FishFaceGame() : super(world: GameWorld());
}
