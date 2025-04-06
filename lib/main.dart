import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game.dart';

const _titleId = 'title';

void main() {
  final game = FishFaceGame();
  runApp(
    // The MaterialApp and Scaffold are needed for showAboutDialog.
    // Otherwise, this could just have the game widget.
    MaterialApp(
      theme: ThemeData(fontFamily: 'Alatsi'),
      home: Scaffold(
        body: GameWidget(
          game: game,
          overlayBuilderMap: {_titleId: (_, _) => TitleOverlay(game: game)},
          initialActiveOverlays: [_titleId],
        ),
      ),
    ),
  );
}

class TitleOverlay extends StatelessWidget {
  final FishFaceGame game;

  const TitleOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.blue,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Fish Face', style: TextStyle(fontFamily: 'Oi', fontSize: 80)),
            Text(
              'A ridiculous game by Paul Gestwicki\nMade for Ludum Dare 57',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            ElevatedButton(
              onPressed: _startGame,
              child: Text('Play', style: TextStyle(fontSize: 32)),
            ),
            ElevatedButton(
              onPressed:
                  () => showAboutDialog(
                    context: context,
                    applicationName: 'Fish Face',
                    applicationLegalese: '©2025 Paul Gestwicki',
                  ),
              child: Text('About', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    game.overlays.remove(_titleId);
    game.start();
  }
}
