import 'dart:async';
import 'dart:math';

import 'package:fish_face/face.dart';
import 'package:fish_face/game.dart';
import 'package:fish_face/key_indicator.dart';
import 'package:fish_face/pole.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final _random = Random();
final _lowPoleAngle = -12 * degrees2Radians;

class GameWorld extends World with KeyboardHandler, HasGameRef<FishFaceGame> {
  static const lrKeyHeight = 450.0;

  var _successes = 0;
  var _misses = 0;
  _State? _state;
  late final Face _face;
  late final Pole _pole;

  final TextComponent _statusMessage = TextComponent();

  final _indicators = <LogicalKeyboardKey, KeyIndicator>{};

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    _indicators.addAll({
      LogicalKeyboardKey.arrowLeft: KeyIndicator(
        Flame.images.fromCache('left.png'),
      )..position = Vector2(500, lrKeyHeight),
      LogicalKeyboardKey.arrowRight: KeyIndicator(
        Flame.images.fromCache('right.png'),
      )..position = Vector2(700, lrKeyHeight),
      LogicalKeyboardKey.arrowUp: KeyIndicator(Flame.images.fromCache('up.png'))
        ..position = Vector2(600, 300),
    });

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
      _pole =
          Pole()
            ..position = Vector2(-40, 500)
            ..angle = _lowPoleAngle,
    );

    for (final indicator in _indicators.values) {
      add(indicator);
      indicator.isVisible = false;
    }
    add(_statusMessage..position = Vector2(0, 50));
    _updateStatusMessage();
  }

  void start() {
    _showIndicators();
    _setState(
      _KeyReactiveState(
        requiredInput:
            _random.nextDouble() < 0.5
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowRight,
      ),
    );
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

  void _startNextRound() {
    _showIndicators();
    _successes = 0;
    _misses = 0;
    _updateStatusMessage();
    _setState(_IdleState());
  }

  Future _reset() async {
    await _face.reset();
    _startNextRound();
  }

  void _finishRound() {
    if (_face.isFull) {
      _setState(_EndState());
    } else {
      _startNextRound();
    }
  }

  void _hideIndicators() {
    for (final indicator in _indicators.values) {
      indicator.isVisible = false;
    }
  }

  void _showIndicators() {
    for (final indicator in _indicators.values) {
      indicator.isVisible = true;
    }
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
      // Check the debugging key
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        game.world._setState(_CatchState());
      } else if (event.logicalKey == requiredInput) {
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
  static const _raiseDuration = 0.5;
  static const _raiseAmount = -30.0 * degrees2Radians;

  late final FacePart _part;
  var _listeningForKeyEvent = false;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    game.world._hideIndicators();

    // Move the part into the middle of the screen as it's reeled in.
    _part =
        _randomFacePart()
          ..position = Vector2(game.size.x / 2, game.size.y + 100)
          ..add(
            MoveToEffect(
              game.size / 2,
              CurvedEffectController(1.0, Curves.easeIn),
              onComplete: () => _listeningForKeyEvent = true,
            ),
          );
    add(_part);

    game.world._pole.add(
      RotateEffect.by(
        _raiseAmount,
        CurvedEffectController(_raiseDuration, Curves.easeIn),
      ),
    );
  }

  @override
  void onRemove() {
    game.world._pole.add(
      RotateEffect.by(
        -_raiseAmount,
        CurvedEffectController(_raiseDuration, Curves.easeOut),
      ),
    );
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (_listeningForKeyEvent && event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        // Throw the part away
        _part.add(
          SequenceEffect([
            MoveToEffect(
              Vector2(game.size.x + 100, _part.position.y),
              CurvedEffectController(1.0, Curves.easeOut),
            ),
            RemoveEffect(),
          ], onComplete: game.world._startNextRound),
        );
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _listeningForKeyEvent = false;
        game.world._face.addPart(_part).then((_) => game.world._finishRound());
      }
    }
    return false;
  }

  FacePart _randomFacePart() =>
      _random.nextDouble() < 0.5
          ? FacePart(PartType.eye, Flame.images.fromCache('eye1.png'))
          : FacePart(PartType.mouth, Flame.images.fromCache('mouth1.png'));
}

class _LoseState extends _State {
  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    add(TextComponent(text: 'Lose!'));
  }
}

class _EndState extends _State with KeyboardHandler {
  var _listeningForKeys = true;

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    add(TextComponent(text: 'Your face is full! Press up to reset.'));
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (_listeningForKeys &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _listeningForKeys = false;
      game.world._reset();
      return true;
    } else {
      return false;
    }
  }
}
