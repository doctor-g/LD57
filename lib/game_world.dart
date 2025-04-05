import 'dart:async';
import 'dart:math';

import 'package:fish_face/game.dart';
import 'package:fish_face/key_indicator.dart';
import 'package:fish_face/pole.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const tau = pi * 2;

class GameWorld extends World with KeyboardHandler, HasGameRef<FishFaceGame> {
  static const lrKeyHeight = 450.0;

  var _successes = 0;
  var _misses = 0;
  _State? _state;

  final TextComponent _statusMessage = TextComponent();

  final _indicators = {
    LogicalKeyboardKey.arrowLeft: KeyIndicator('LEFT')
      ..position = Vector2(500, lrKeyHeight),
    LogicalKeyboardKey.arrowRight: KeyIndicator('RIGHT')
      ..position = Vector2(700, lrKeyHeight),
    LogicalKeyboardKey.arrowUp: KeyIndicator('UP')
      ..position = Vector2(600, 300),
  };

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    add(
      RectangleComponent(
        size: game.size,
        paint: Paint()..color = Colors.blueGrey,
      ),
    );
    add(
      Pole()
        ..position = Vector2(-40, 500)
        ..angle = -12 * degrees2Radians,
    );

    for (final indicator in _indicators.values) {
      add(indicator);
    }
    add(_statusMessage..position = Vector2(0, 50));

    _setState(_KeyReactiveState(requiredInput: LogicalKeyboardKey.arrowLeft));
    _updateStatusMessage();
  }

  void _addSuccess() {
    _successes += 1;
    _updateStatusMessage();
  }

  void _addMiss() {
    _misses += 1;
    _updateStatusMessage();
  }

  void _updateStatusMessage() {
    _statusMessage.text = 'Successes: $_successes.  Misses: $_misses';
  }

  void _setState(_State newState) {
    if (_state != null) {
      remove(_state!);
    }
    _state = newState;
    add(newState);
  }
}

sealed class _State extends Component
    with KeyboardHandler, HasGameRef<FishFaceGame> {}

class _IdleState extends _State {
  late final Timer timer;

  _IdleState({double duration = 1.0}) {
    timer = Timer(duration);
  }

  @override
  void update(double dt) {
    timer.update(dt);
    if (timer.finished) {
      final nextInput =
          game.world._successes < 3
              ? LogicalKeyboardKey.arrowLeft
              : LogicalKeyboardKey.arrowUp;

      game.world._setState(_KeyReactiveState(requiredInput: nextInput));
    }
  }
}

class _KeyReactiveState extends _State {
  static const _defaultDuration = 1.0;
  final LogicalKeyboardKey requiredInput;
  late final Timer _timer;

  _KeyReactiveState({required this.requiredInput});

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    _timer = Timer(_defaultDuration);
    game.world._indicators[requiredInput]!.makeActive();
  }

  @override
  void onRemove() {
    game.world._indicators[requiredInput]!.makeInactive();
  }

  @override
  void update(double dt) {
    _timer.update(dt);
    if (_timer.finished) {
      game.world._setState(_IdleState(duration: 2));
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == requiredInput) {
        if (requiredInput == LogicalKeyboardKey.arrowUp) {
          game.world._setState(_WinState());
        } else {
          game.world._addSuccess();
          game.world._setState(_IdleState());
        }
      } else {
        game.world._addMiss();
        if (game.world._misses > 3) {
          game.world._setState(_LoseState());
        } else {
          game.world._setState(_IdleState());
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() {
    return '${runtimeType.toString()}(${requiredInput.keyLabel})';
  }
}

class _WinState extends _State {
  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    add(TextComponent(text: 'Win!'));
  }
}

class _LoseState extends _State {
  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    add(TextComponent(text: 'Lose!'));
  }
}
