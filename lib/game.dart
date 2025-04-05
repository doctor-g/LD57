import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

class FishFaceGame extends FlameGame {
  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    add(TextComponent(text: 'Hello, world'));
  }
}
