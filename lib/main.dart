import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game.dart';

void main() {
  final game = FishFaceGame();
  runApp(GameWidget(game: game));
}
