part of 'infinity_view.dart';

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
  InfinityViewController({this.onReady});

  /// Since none of the methods are available until the [InfinityView] has
  /// initialized, you can pass a callback that will be called as soon as the
  /// functions are plugged into the controller.
  ///
  /// This is only necessary if you want to manipulate the [InfinityView]
  /// immediately when the widget is first built.
  final void Function(InfinityViewController controller)? onReady;

  late Function(double scale) _setScale;
  late double Function() _getScale;
  late Function(Offset translation) _setTranslation;
  late Offset Function() _getTranslation;
  late Function(double rotation) _setRotation;
  late double Function() _getRotation;

  /// The scale transformation of the [InfinityView].
  double get scale => _getScale();
  set scale(double scale) => _setScale(scale);

  /// The translation transformation of the [InfinityView].
  ///
  /// This is an Offset that represents the translation in the X and Y axes.
  Offset get translation => _getTranslation();
  set translation(Offset translation) => _setTranslation(translation);

  /// The rotation transformation of the [InfinityView] in radians.
  double get rotation => _getRotation();
  set rotation(double rotation) => _setRotation(rotation);

  /// The rotation transformation of the [InfinityView] in degrees.
  double get rotationInDegrees => _getRotation() * 180 / pi;
  set rotationInDegrees(double rotation) => _setRotation(rotation * pi / 180);

  /// Resets the [InfinityView] to its original transformations.
  ///
  /// Scale will be set to 1.0, translation will be set to (0, 0), and rotation
  /// will be set to 0.0.
  late Function reset;
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
