import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game.dart';

const _titleId = 'title';

void main() {
  final game = FishFaceGame();
  runApp(
    GameWidget(
      game: game,
      overlayBuilderMap: {_titleId: (_, _) => TitleOverlay(game: game)},
      initialActiveOverlays: [_titleId],
    ),
  );
}

class TitleOverlay extends StatelessWidget {
  final FishFaceGame game;

  const TitleOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(onPressed: _startGame, child: const Text('Play')),
    );
  }

  void _startGame() {
    game.overlays.remove(_titleId);
    game.start();
  }
}
