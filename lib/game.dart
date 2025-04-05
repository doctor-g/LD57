import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final _random = Random();

class FishFaceGame extends FlameGame with KeyboardEvents {
  LogicalKeyboardKey? _currentRequirement = LogicalKeyboardKey.arrowLeft;
  final _message = TextComponent(text: '');
  late final TextComponent _statusComponent;
  var _misses = 0;
  var _successes = 0;

  String _makeStatusMessage() => '$_successes Successes. $_misses Misses.';

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    _statusComponent = TextComponent(
      text: _makeStatusMessage(),
      position: Vector2(0, 30),
    );
    add(_message);
    add(_statusComponent);
    setCurrentRequirement(LogicalKeyboardKey.arrowLeft);
  }

  void setCurrentRequirement(LogicalKeyboardKey key) {
    _currentRequirement = key;
    _message.text = key.keyLabel;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == _currentRequirement) {
        _successes++;
      } else {
        _misses++;
      }
      _statusComponent.text = _makeStatusMessage();
      setCurrentRequirement(
        _random.nextDouble() < 0.5
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight,
      );
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }
  }
}
