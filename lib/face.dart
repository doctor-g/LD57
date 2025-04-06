import 'dart:async';

import 'package:fish_face/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart' hide Image;

enum PartType { eye, nose, mouth }

class Face extends PositionComponent with HasGameRef<FishFaceGame> {
  late final PositionComponent leftEyeSlot;
  late final PositionComponent rightEyeSlot;
  late final PositionComponent mouthSlot;

  Face() : super(size: Vector2(270, 325));

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    leftEyeSlot = PositionComponent(
      position: Vector2(size.x * 2 / 5, size.y / 2),
    );
    rightEyeSlot = PositionComponent(
      position: Vector2(size.x * 4 / 5, size.y / 2),
    );
    mouthSlot = PositionComponent(
      position: Vector2(size.x * 3 / 5, size.y * 4 / 5),
    );
    addAll([leftEyeSlot, rightEyeSlot, mouthSlot]);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTRB(0, 0, size.x, size.y);
    canvas.drawOval(rect, Paint()..color = Colors.yellow);
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black
        ..strokeWidth = 10.0,
    );
  }

  Future addPart(FacePart part) {
    late PositionComponent slot;
    if (part.type == PartType.mouth) {
      if (mouthSlot.children.isNotEmpty) {
        _discardChildFrom(mouthSlot);
      }
      slot = mouthSlot;
    }

    if (part.type == PartType.eye) {
      if (leftEyeSlot.children.isNotEmpty) {
        _discardChildFrom(leftEyeSlot);
      }
      if (rightEyeSlot.children.isNotEmpty) {
        _addPartToSlot(rightEyeSlot.children.first as FacePart, leftEyeSlot);
      }
      slot = rightEyeSlot;
    }

    return _addPartToSlot(part, slot);
  }

  bool get isFull => [
    leftEyeSlot,
    rightEyeSlot,
    mouthSlot,
  ].every((component) => component.children.isNotEmpty);

  Future _addPartToSlot(FacePart part, PositionComponent slot) {
    final completer = Completer();
    final globalPosition = part.absolutePosition;
    part.removeFromParent();
    slot.add(part);

    // This will keep the part in the same global position even though its
    // parent has changed.
    part.position = globalPosition - slot.absolutePosition;

    // Animate the part onto the face.
    part.add(
      MoveToEffect(
        Vector2.zero(),
        CurvedEffectController(1.0, Curves.easeIn),
        onComplete: completer.complete,
      ),
    );
    return completer.future;
  }

  Future _discardChildFrom(PositionComponent slot) {
    final completer = Completer();
    slot.children.first.add(
      SequenceEffect([
        MoveToEffect(
          mouthSlot.absoluteToLocal(Vector2(-100, game.size.y * 2 / 3)),
          CurvedEffectController(1.0, Curves.easeOut),
        ),
        RemoveEffect(),
      ], onComplete: completer.complete),
    );
    return completer.future;
  }

  Future reset() async {
    final futures = <Future>[];
    for (final slot in [
      leftEyeSlot,
      rightEyeSlot,
      mouthSlot,
    ].where((element) => element.children.isNotEmpty)) {
      final future = _discardChildFrom(slot);
      futures.add(future);
    }
    await Future.wait(futures);
  }
}

class FacePart extends PositionComponent {
  final PartType type;
  final Image image;

  FacePart(this.type, this.image) : super(anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    final sprite = Sprite(image);

    // The size of this component can't be known until the image is loaded,
    // so it is specified here.
    size = sprite.originalSize;

    final spriteComponent = SpriteComponent(sprite: sprite);
    add(spriteComponent);
  }
}
