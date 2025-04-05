import 'dart:async';

import 'package:fish_face/face.dart';
import 'package:fish_face/face_part.dart';
import 'package:fish_face/game.dart';
import 'package:fish_face/key_indicator.dart';
import 'package:fish_face/pole.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GameWorld extends World with KeyboardHandler, HasGameRef<FishFaceGame> {
  static const lrKeyHeight = 450.0;

  var _successes = 0;
  var _misses = 0;
  _State? _state;
  late final Face _face;

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

    // Background
    add(
      RectangleComponent(
        size: game.size,
        paint: Paint()..color = Colors.blueGrey,
      ),
    );

    // Game scene
    _face = Face()..position = Vector2(100, 90);
    add(_face);
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

  void _addToFace(FacePart part) {
    final p = part.absolutePosition;
    part.removeFromParent();
    _face.add(part..position = p - _face.absolutePosition);
    part.add(
      MoveToEffect(
        _face.center,
        CurvedEffectController(1.0, Curves.easeIn),
        onComplete: _startNextRound,
      ),
    );
  }

  void _startNextRound() {
    _successes = 0;
    _misses = 0;
    _updateStatusMessage();
    _setState(_IdleState());
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
  static const _defaultDuration = 3.0;
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
          game.world._setState(_CatchState());
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

class _CatchState extends _State with KeyboardHandler {
  late final FacePart _part;
  var _listeningForKeyEvent = false;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    _part =
        FacePart()
          ..position = Vector2(game.size.x / 2, game.size.y + 100)
          ..add(
            MoveToEffect(
              game.size / 2,
              CurvedEffectController(1.0, Curves.easeIn),
              onComplete: () => _listeningForKeyEvent = true,
            ),
          );
    add(_part);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (_listeningForKeyEvent && event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _part.add(
          SequenceEffect([
            MoveToEffect(
              Vector2(game.size.x + 100, _part.position.y),
              CurvedEffectController(1.0, Curves.easeOut),
            ),
            RemoveEffect(),
          ], onComplete: () => game.world._setState(_IdleState())),
        );
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _listeningForKeyEvent = false;
        game.world._addToFace(_part);
      }
    }
    return false;
  }
}

class _LoseState extends _State {
  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    add(TextComponent(text: 'Lose!'));
  }
}
