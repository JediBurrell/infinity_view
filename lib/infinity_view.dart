library infinity_view;

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'infinity_events.dart';

typedef TransformTestCallback = bool Function(
    GenericTransformUpdateDetails details);
typedef ScrollWheelCallback = ScrollWheelBehavior? Function();

/// [InfinityView] allows the child widget to be translated, scaled and rotated
/// infinitely with user input.
///
/// It works across all platforms and devices, including touch, mouse and trackpad.
///
/// You can customize which gestures are enabled with [shouldTranslate], [shouldScale]
/// and [shouldRotate].
///
/// You can also give custom conditions for when each gesture should be applied with
/// [translationTest], [scaleTest] and [rotateTest].
class InfinityView extends StatefulWidget {
  /// The [child] widget that will be transformed by the [InfinityView].
  final Widget child;

  /// Whether or not translation gestures should be applied.
  ///
  /// Defaults to true.
  final bool shouldTranslate;

  /// Whether or not scale gestures should be applied.
  ///
  /// Defaults to true.
  final bool shouldScale;

  /// Whether or not rotation gestures should be applied.
  ///
  /// Defaults to false.
  final bool shouldRotate;

  /// Whether the [InfinityView] is locked from any gesture.
  ///
  /// This returns true if translation, scale and rotation are all false.
  bool get locked => !shouldTranslate && !shouldScale && !shouldRotate;

  /// When set, it will align the focal point to the specified alignment.
  /// By default, the focal point is based on the user input.
  final Alignment? focalPointAlignment;

  /// The default behavior for the scroll wheel.
  /// This will be overridden by [scrollWheelHandler] if it returns a non-null value.
  ///
  /// Defaults to [ScrollWheelBehavior.scale].
  final ScrollWheelBehavior scrollWheelBehavior;

  /// A callback that allows for changing the scroll wheel behavior based on
  /// external factors.
  ///
  /// If the callback returns null, the [scrollWheelBehavior] will be used.
  final ScrollWheelCallback? scrollWheelHandler;

  /// The sensitivity of the scroll wheel.
  /// The scale factor is calculated as `1 ± scrollWheelSensitivity / 10`.
  /// So, with the default value, zooming in with the scroll wheel will apply
  /// a scale factor of 1.1, and zooming out will apply a scale factor of 0.9.
  ///
  /// Defaults to 1.0.
  final double scrollWheelSensitivity;

  /// The threshold for snapping to the nearest 90 degree angle when rotating.
  /// If the angle is within this threshold, it will snap to the nearest 90 degree angle.
  ///
  /// Defaults to 0.0, or no snapping.
  final double rotationSnappingTheshold;
  double get _rotationSnappingThesholdRadians =>
      rotationSnappingTheshold * pi / 180;

  /// The angles that the rotation will snap to.
  /// This number is in degrees and should be a fraction of 360.
  ///
  /// This will only be applied if [rotationSnappingTheshold] is greater than 0.
  ///
  /// Defaults to 90 degrees.
  final double rotationSnappingIncrements;
  double get _snappingMultiplesRadians => rotationSnappingIncrements * pi / 180;

  /// Determines whether the [InfinityView] should apply the translation
  ///
  /// You can use this to only allow translation when a certain condition is met.
  /// For example, if your view should pan with the middle mouse button, you can
  /// return `details.buttons == kMiddleMouseButton` from this callback.
  ///
  /// If null and [shouldTranslate] is true, translation will always be applied.
  final TransformTestCallback? translationTest;

  /// Determines whether the [InfinityView] should apply scale.
  ///
  /// You can use this to only allow scaling when a certain condition is met.
  ///
  /// If null and [shouldScale] is true, scaling will always be applied.
  final TransformTestCallback? scaleTest;

  /// Determines whether the [InfinityView] should apply rotation.
  ///
  /// You can use this to only allow rotation when a certain condition is met.
  ///
  /// If null and [shouldRotate] is true, rotation will always be applied.
  final TransformTestCallback? rotateTest;

  const InfinityView({
    Key? key,
    required this.child,
    this.shouldTranslate = true,
    this.shouldScale = true,
    this.shouldRotate = false,
    this.scrollWheelBehavior = ScrollWheelBehavior.scale,
    this.scrollWheelHandler,
    this.scrollWheelSensitivity = 1.0,
    this.rotationSnappingTheshold = 0.0,
    this.rotationSnappingIncrements = 90.0,
    this.focalPointAlignment,
    this.translationTest,
    this.scaleTest,
    this.rotateTest,
  }) : super(key: key);

  @override
  State<InfinityView> createState() => _InfinityViewState();
}

class _InfinityViewState extends State<InfinityView> {
  Matrix4 matrix = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    final array = matrix.applyToVector3Array([0, 0, 0, 1, 0, 0]);
    double rot = Offset(array[3] - array[0], array[4] - array[1]).direction;
    double snappedRot = rot;
    if ((rot.abs() + widget._rotationSnappingThesholdRadians / 2) %
            (widget._snappingMultiplesRadians) <
        widget._rotationSnappingThesholdRadians) {
      snappedRot = widget._snappingMultiplesRadians *
          (rot / widget._snappingMultiplesRadians).round();
    }

    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerPanZoomStart: (details) =>
          onScaleStart(GenericTransformStartDetails.fromPointerStart(details)),
      onPointerPanZoomUpdate: (details) => onScaleUpdate(
          GenericTransformUpdateDetails.fromPointerUpdate(details)),
      onPointerDown: (details) {
        if (details.kind != PointerDeviceKind.touch) {
          onScaleStart(GenericTransformStartDetails.fromPointerDown(details));
        }
      },
      onPointerMove: (details) {
        if (details.kind != PointerDeviceKind.touch) {
          onScaleUpdate(GenericTransformUpdateDetails.fromPointerMove(details));
        }
      },
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          ScrollWheelBehavior behavior =
              widget.scrollWheelHandler?.call() ?? widget.scrollWheelBehavior;
          if (behavior == ScrollWheelBehavior.ignore) return;

          onScaleStart(GenericTransformStartDetails.fromPointerScroll(event));
          onScaleUpdate(GenericTransformUpdateDetails.fromPointerScroll(
              event, behavior, widget.scrollWheelSensitivity));
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        supportedDevices: const {PointerDeviceKind.touch},
        onScaleStart: (details) =>
            onScaleStart(GenericTransformStartDetails.fromScaleStart(details)),
        onScaleUpdate: (details) => onScaleUpdate(
            GenericTransformUpdateDetails.fromScaleUpdate(details)),
        child: Container(
          // We're using a transparent container to allow the child to receive
          // pointer events outside of the child's bounds.
          color: Colors.transparent,
          child: Transform.rotate(
            angle: snappedRot - rot,
            child: Transform(
              transform: matrix,
              child: Container(
                color: Colors.transparent,
                child: SizedBox.expand(
                  child: ClipRect(child: widget.child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset translation = Offset.zero;
  Offset _tDelta(Offset newTranslation) {
    Offset oldTranslation = translation;
    translation = newTranslation;
    return newTranslation - oldTranslation;
  }

  double scale = 1.0;
  double _sDelta(double newScale) {
    double oldScale = scale;
    scale = newScale;
    return newScale / oldScale;
  }

  double rotation = 0.0;
  double _rDelta(double newRotation) {
    double oldRotation = rotation;
    rotation = newRotation;
    return newRotation - oldRotation;
  }

  void onScaleStart(GenericTransformStartDetails details) {
    translation = details.focalPoint;
    scale = 1.0;
    rotation = 0.0;
  }

  void onScaleUpdate(GenericTransformUpdateDetails details) {
    if (widget.locked) return;

    final focalPointAlignment = widget.focalPointAlignment;
    final focalPoint = focalPointAlignment?.alongSize(context.size!) ??
        details.localFocalPoint;
    Matrix4 newMatrix = Matrix4.copy(matrix);

    if (widget.shouldTranslate &&
        widget.translationTest?.call(details) != false) {
      Offset delta = _tDelta(details.focalPoint);
      newMatrix = _translate(delta) * newMatrix;
    }

    if (widget.shouldScale &&
        details.scale != 1.0 &&
        widget.scaleTest?.call(details) != false) {
      double delta = _sDelta(details.scale);
      newMatrix = _scale(delta, focalPoint) * newMatrix;
    }

    if (widget.shouldRotate &&
        details.rotation != 0.0 &&
        widget.rotateTest?.call(details) != false) {
      double delta = _rDelta(details.rotation);
      newMatrix = _rotate(delta, focalPoint) * newMatrix;
    }

    setState(() => matrix = newMatrix);
  }

  Matrix4 _translate(Offset translation) =>
      Matrix4.identity()..translate(translation.dx, translation.dy);

  Matrix4 _scale(double scale, Offset focalPoint) {
    var delta = focalPoint * (1 - scale);
    return Matrix4.identity()
      ..scale(scale)
      ..translate(delta.dx, delta.dy);
  }

  Matrix4 _rotate(double angle, Offset focalPoint) {
    var dx = (1 - cos(angle)) * focalPoint.dx + sin(angle) * focalPoint.dy;
    var dy = (1 - cos(angle)) * focalPoint.dy - sin(angle) * focalPoint.dx;

    return Matrix4.identity()
      ..translate(dx, dy)
      ..rotateZ(angle);
  }
}

/// Defines different behaviors for how the scroll wheel on a mouse is handled.
enum ScrollWheelBehavior {
  /// Scroll wheel events are ignored.
  ignore,

  /// Scroll wheel events scroll in the X axis.
  ///
  /// A positive scroll wheel event pans to the right (x += delta).<br/>
  /// A negative scroll wheel event pans to the left (x -= delta).
  translateX,

  /// Scroll wheel events scroll in the X axis, but inverted.
  ///
  /// A positive scroll wheel event pans to the left (x -= delta).<br/>
  /// A negative scroll wheel event pans to the right (x += delta).
  translateXInvert,

  /// Scroll wheel events scroll in the Y axis.
  ///
  /// A positive scroll wheel event pans up (y -= delta).<br/>
  /// A negative scroll wheel event pans down (y += delta).
  translateY,

  /// Scroll wheel events scroll in the Y axis, but inverted.
  ///
  /// A positive scroll wheel event pans down (y += delta).<br/>
  /// A negative scroll wheel event pans up (y -= delta).
  translateYInvert,

  /// Scroll wheel events rotate clockwise.
  ///
  /// A positive scroll wheel event rotates clockwise (angle += delta).<br/>
  /// A negative scroll wheel event rotates counter-clockwise (angle -= delta).
  rotateClockwise,

  /// Scroll wheel events rotate counter-clockwise.
  ///
  /// A positive scroll wheel event rotates counter-clockwise (angle -= delta).<br/>
  /// A negative scroll wheel event rotates clockwise (angle += delta).
  rotateCounterClockwise,

  /// Scroll wheel events zoom in and out.
  scale,
}
