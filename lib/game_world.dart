import 'dart:async';
import 'dart:math';

import 'package:fish_face/arrow_sprite_component.dart';
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
const _lowPoleAngle = -12 * degrees2Radians;
const _debugKey = LogicalKeyboardKey.keyZ;
const _numberOfMouths = 4;
const _numberOfEyes = 4;

class GameWorld extends World with KeyboardHandler, HasGameRef<FishFaceGame> {
  static const lrKeyHeight = 450.0;

  var _successes = 0;
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
      _PreparatoryState(
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

  void _updateStatusMessage() {
    _statusMessage.text = 'Successes: $_successes.';
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

      game.world._setState(_PreparatoryState(nextInput));
    }
  }
}

/// Preparing for it to be the right time to press a key by showing
/// an animation on the relevant key.
class _PreparatoryState extends _State with KeyboardHandler {
  static const _activationEffectDuration = 0.75;

  final LogicalKeyboardKey _desiredKey;
  late final ArrowSpriteComponent _attractor;

  _PreparatoryState(this._desiredKey);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    final slot = game.world._indicators[_desiredKey]!;

    _attractor =
        ArrowSpriteComponent(switch (_desiredKey) {
            LogicalKeyboardKey.arrowUp => ArrowSpriteType.up,
            LogicalKeyboardKey.arrowLeft => ArrowSpriteType.left,
            LogicalKeyboardKey.arrowRight => ArrowSpriteType.right,
            LogicalKeyboardKey() => throw UnimplementedError(),
          })
          ..scale = Vector2.all(3.0)
          ..opacity = 0.0
          ..add(
            OpacityEffect.to(
              1.0,
              CurvedEffectController(_activationEffectDuration, Curves.easeIn),
            ),
          )
          ..add(
            ScaleEffect.to(
              Vector2.all(1.0),
              CurvedEffectController(_activationEffectDuration, Curves.easeOut),
              onComplete: () {
                _attractor.removeFromParent();
                game.world._setState(
                  _KeyReactiveState(requiredInput: _desiredKey),
                );
              },
            ),
          );
    slot.add(_attractor..position = slot.size / 2);
  }

  @override
  void onRemove() {
    if (_attractor.parent != null) {
      _attractor.removeFromParent();
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Pressing a key in this state means failure unless it's the automatic
    // success key.
    if (event is KeyDownEvent) {
      if (event.logicalKey == _debugKey) {
        game.world._setState(_CatchState());
        return true;
      } else {
        print('Failure sound here');
        game.world._setState(_IdleState());
        return true;
      }
    }
    return false;
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
    game.world._indicators[requiredInput]!.activate();
  }

  @override
  void onRemove() {
    game.world._indicators[requiredInput]!.deactivate();
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
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        game.world._setState(_CatchState());
      } else if (event.logicalKey == requiredInput) {
        // If we're pulling up, we're catching something
        if (requiredInput == LogicalKeyboardKey.arrowUp) {
          game.world._setState(_CatchState());
        }
        // Otherwise it's just a step along the way
        else {
          game.world._addSuccess();
          game.world._setState(_IdleState());
        }
      } else {
        print('Failed to hit the right key');
        game.world._setState(_IdleState());
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
  static const _partX = 500.0;
  static const _partY = 300.0;
  static const _arrowDistanceFromPart = 120.0;

  late final FacePart _part;
  var _listeningForKeyEvent = false;
  final ArrowSpriteComponent _left = ArrowSpriteComponent(ArrowSpriteType.left);
  final ArrowSpriteComponent _right = ArrowSpriteComponent(
    ArrowSpriteType.right,
  );

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();

    game.world._hideIndicators();

    add(
      _left
        ..position = Vector2(_partX - _arrowDistanceFromPart, _partY)
        ..isVisible = false,
    );
    add(
      _right
        ..position = Vector2(_partX + _arrowDistanceFromPart, _partY)
        ..isVisible = false,
    );

    // Move the part into the middle of the screen as it's reeled in.
    _part =
        _randomFacePart()
          ..position = Vector2(game.size.x / 2, game.size.y + 100)
          ..add(
            MoveToEffect(
              Vector2(_partX, _partY),
              CurvedEffectController(_raiseDuration, Curves.easeIn),
              onComplete: () {
                _listeningForKeyEvent = true;
                _left.isVisible = true;
                _right.isVisible = true;
              },
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
      for (final arrow in [_left, _right]) {
        arrow.isVisible = false;
      }

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

  FacePart _randomFacePart() {
    if (_random.nextDouble() < 0.5) {
      // It would be nice to dynamically figure out how many pieces were loaded,
      // but it's a game jam.
      final int index = _random.nextInt(_numberOfEyes) + 1;
      return FacePart(PartType.eye, Flame.images.fromCache('eye$index.png'));
    } else {
      final int index = _random.nextInt(_numberOfMouths) + 1;
      return FacePart(
        PartType.mouth,
        Flame.images.fromCache('mouth$index.png'),
      );
    }
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
