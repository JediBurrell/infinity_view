import 'dart:math';

import 'package:flutter/material.dart';

/// [InfinityViewController] allows you to manipulate the [InfinityView] from
/// outside of the widget.
///
/// None of the methods are available until the [InfinityView] has initialized.
/// If you want to manipulate the [InfinityView] before it is ready, you can
/// pass a callback to the [onReady] parameter that will be called as soon as
/// the functions are plugged into the controller.
///
/// If you would like to do this outside of the controller (for example, in
/// `initState`), you can use `WidgetsBinding.instance.addPostFrameCallback` to
/// safely call the methods.
class InfinityViewController {
  /// Resets the [InfinityView] to its original transformations.
  late Function reset;

  /// Sets the scale of the [InfinityView].
  ///
  /// The default scale is 1.0, a greater value will zoom in and a lesser value
  /// will zoom out.
  late Function(double scale) setScale;

  /// Returns the current scale of the [InfinityView].
  late double Function() getScale;

  /// Sets the translation of the [InfinityView].
  ///
  /// This takes an [Offset] that represents the translation in the X and Y
  /// axis.
  late Function(Offset translation) setTranslation;

  /// Returns the current translation of the [InfinityView].
  late Offset Function() getTranslation;

  /// Sets the rotation of the [InfinityView].
  ///
  /// This takes a double that represents the rotation in radians.
  late Function(double rotation) setRotation;

  /// Sets the rotation of the [InfinityView].
  ///
  /// This takes a double that represents the rotation in degrees.
  void setRotationInDegrees(double rotation) {
    setRotation(rotation * pi / 180);
  }

  /// Returns the current rotation of the [InfinityView].
  late double Function() getRotation;

  /// Returns the current rotation of the [InfinityView] in degrees.
  double get rotationInDegrees => getRotation() * 180 / pi;

  /// Since none of the methods are available until the [InfinityView] has
  /// initialized, you can pass a callback that will be called as soon as the
  /// functions are plugged into the controller.
  ///
  /// This is only necessary if you want to manipulate the [InfinityView]
  /// immediately when the widget is first built.
  final void Function(InfinityViewController controller)? onReady;
  InfinityViewController({this.onReady});
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
