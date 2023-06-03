import 'package:flutter/gestures.dart';
import 'package:infinity_view/infinity_view.dart';

/// [GenericTransformStartDetails] genericizes all used input down events
/// into a single class. This allows us to use the same logic for all input events.
class GenericTransformStartDetails {
  /// The global focal point of the pointers in contact with the screen.
  ///
  /// Typically this is where the touch event is happening, though if the user
  /// is performing a pinch or zoom gesture involving multiple fingers this
  /// is the center of those points.
  ///
  /// Supports mouse, trackpad, and touch events.
  final Offset focalPoint;

  GenericTransformStartDetails({
    required this.focalPoint,
  });

  factory GenericTransformStartDetails.fromScaleStart(
      ScaleStartDetails details) {
    return GenericTransformStartDetails(
      focalPoint: details.focalPoint,
    );
  }

  factory GenericTransformStartDetails.fromPointerStart(
      PointerPanZoomStartEvent details) {
    return GenericTransformStartDetails(
      focalPoint: details.position,
    );
  }

  factory GenericTransformStartDetails.fromPointerDown(
      PointerDownEvent details) {
    return GenericTransformStartDetails(
      focalPoint: details.position,
    );
  }

  factory GenericTransformStartDetails.fromPointerScroll(
      PointerScrollEvent details) {
    return GenericTransformStartDetails(
      focalPoint: details.position,
    );
  }
}

/// [GenericTransformUpdateDetails] genericizes all used input events into a
/// single class. This allows us to use the same logic for all input events.
///
/// Not all properties are used for all input events. For example, the
/// [PointerMoveEvent] does not have a [scale] property, so it will always
/// be 1.0.
///
/// You can use [kind] to determine the input type.
class GenericTransformUpdateDetails {
  /// The global focal point of the pointers in contact with the screen.
  ///
  /// Typically this is where the touch event is happening, though if the user
  /// is performing a pinch or zoom gesture involving multiple fingers this
  /// is the center of those points.
  ///
  /// Supports mouse, trackpad, and touch events.
  final Offset focalPoint;

  /// The local focal point of the pointers in contact with the screen.
  ///
  /// Typically this is where the touch event is happening, though if the user
  /// is performing a pinch or zoom gesture involving multiple fingers this
  /// is the center of those points.
  ///
  /// Supports mouse, trackpad, and touch events.
  final Offset localFocalPoint;

  /// This is the scale factor for the scale event.
  ///
  /// Supports mouse, trackpad, and touch events.
  /// Defaults to 1.0 when no scaling is happening.
  final double scale;

  /// This is the rotation factor for the rotation event.
  ///
  /// Supports trackpad and touch events.
  /// Defaults to 0.0 when no rotation is happening.
  final double rotation;

  /// The kind of input device from which the update originated.
  final PointerDeviceKind kind;

  /// The buttons that were pressed when the pointer event occurred.
  ///
  /// This is a nullable value because not all input devices have buttons.
  /// You should check the input device's [kind] before using this value.
  ///
  /// Supports mouse and trackpad events.
  final int? buttons;

  /// The number of pointers involved in the event.
  ///
  /// Supports mouse, trackpad, and touch events.
  final int pointerCount;

  GenericTransformUpdateDetails({
    required this.focalPoint,
    required this.localFocalPoint,
    required this.scale,
    required this.rotation,
    required this.pointerCount,
    required this.kind,
    this.buttons,
  });

  factory GenericTransformUpdateDetails.fromScaleUpdate(
      ScaleUpdateDetails details) {
    return GenericTransformUpdateDetails(
      focalPoint: details.focalPoint,
      localFocalPoint: details.localFocalPoint,
      scale: details.scale,
      rotation: details.rotation,
      pointerCount: details.pointerCount,
      kind: PointerDeviceKind.touch,
    );
  }

  factory GenericTransformUpdateDetails.fromPointerUpdate(
      PointerPanZoomUpdateEvent details) {
    return GenericTransformUpdateDetails(
      focalPoint: details.position + details.pan,
      localFocalPoint: details.localPosition + details.localPan,
      scale: details.scale,
      rotation: details.rotation,
      kind: details.kind,
      buttons: details.buttons,
      pointerCount: 0,
    );
  }

  factory GenericTransformUpdateDetails.fromPointerMove(
      PointerMoveEvent details) {
    return GenericTransformUpdateDetails(
      focalPoint: details.position,
      localFocalPoint: details.localPosition,
      scale: 1.0,
      rotation: 0.0,
      kind: details.kind,
      buttons: details.buttons,
      pointerCount: 1,
    );
  }

  factory GenericTransformUpdateDetails.fromPointerScroll(
      PointerScrollEvent details, ScrollWheelBehavior scrollWheelBehavior,
      [double scrollWheelSensitivity = 1.0]) {
    Offset focalPoint = details.position;
    Offset localFocalPoint = details.localPosition;
    double rotation = 0.0;
    double scale = 1.0;

    switch (scrollWheelBehavior) {
      case ScrollWheelBehavior.translateX:
        focalPoint -= Offset(details.scrollDelta.dy / 5, 0);
        localFocalPoint -= Offset(details.scrollDelta.dy / 5, 0);
        break;
      case ScrollWheelBehavior.translateXInvert:
        focalPoint += Offset(details.scrollDelta.dy / 5, 0);
        localFocalPoint += Offset(details.scrollDelta.dy / 5, 0);
        break;
      case ScrollWheelBehavior.translateY:
        focalPoint -= details.scrollDelta / 5;
        localFocalPoint -= details.scrollDelta / 5;
        break;
      case ScrollWheelBehavior.translateYInvert:
        focalPoint += details.scrollDelta / 5;
        localFocalPoint += details.scrollDelta / 5;
        break;
      case ScrollWheelBehavior.rotateClockwise:
        rotation += details.scrollDelta.dy > 0 ? -0.1 : 0.1;
        break;
      case ScrollWheelBehavior.rotateCounterClockwise:
        rotation += details.scrollDelta.dy > 0 ? 0.1 : -0.1;
        break;
      default:
        scale += details.scrollDelta.dy > 0
            ? -scrollWheelSensitivity / 10
            : scrollWheelSensitivity / 10;
    }

    return GenericTransformUpdateDetails(
      focalPoint: focalPoint,
      localFocalPoint: localFocalPoint,
      scale: scale,
      rotation: rotation,
      kind: details.kind,
      buttons: details.buttons,
      pointerCount: 0,
    );
  }
}
