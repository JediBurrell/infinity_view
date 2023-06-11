library infinity_view;

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

part 'infinity_controller.dart';
part 'infinity_events.dart';

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

  /// Provides access to manipulate the [InfinityView] programmaticaly.
  final InfinityViewController? controller;

  /// Whether the overflow is constrained by the parent.
  ///
  /// If this value is true, the overflow will be sized to its parent which will
  /// allow an infinite child widget (e.g. Stack) and pass the constraints onto its child.
  ///
  /// If the value is false the overflow will be infinite, which means that the
  /// constraints will not be passed onto the child and the child must have a defined
  /// size less than infinity (though conceivably any size).
  ///
  /// As a general rule, if you want to have an infinite child widget, set this to true.
  /// If the child widget has a defined size (or should size according to its parent,
  /// e.g. Scaffold) set this to false.
  ///
  /// If you're getting an overflow error, this is probably the parameter you want to change.
  ///
  /// This is set to true by default.
  final bool shrinkWrap;

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

  /// The curve to use when animating a transformation with the [InfinityViewController].
  ///
  /// Defaults to [Curves.linear].
  final Curve animationCurve;

  /// The duration to use when animating a transformation with the [InfinityViewController].
  ///
  /// Defaults to 300 milliseconds.
  final Duration animationDuration;

  const InfinityView({
    Key? key,
    required this.child,
    this.controller,
    this.shrinkWrap = true,
    this.shouldTranslate = true,
    this.shouldScale = true,
    this.shouldRotate = false,
    this.scrollWheelBehavior = ScrollWheelBehavior.scale,
    this.scrollWheelHandler,
    this.scrollWheelSensitivity = 1.0,
    this.rotationSnappingTheshold = 0.0,
    this.rotationSnappingIncrements = 90.0,
    this.animationCurve = Curves.linear,
    this.animationDuration = const Duration(milliseconds: 300),
    this.focalPointAlignment,
    this.translationTest,
    this.scaleTest,
    this.rotateTest,
  }) : super(key: key);

  @override
  State<InfinityView> createState() => _InfinityViewState();
}

class _InfinityViewState extends State<InfinityView>
    with TickerProviderStateMixin {
  Animation<Matrix4> matrix = AlwaysStoppedAnimation(Matrix4.identity());
  Matrix4 _animatedMatrix = Matrix4.identity();
  late AnimationController controller;
  List<double> get array =>
      matrix.value.applyToVector3Array([0, 0, 0, 1, 0, 0]);
  Offset get delta => Offset(array[3] - array[0], array[4] - array[1]);

  @override
  void initState() {
    super.initState();
    _attachController();
    controller =
        AnimationController(vsync: this, duration: widget.animationDuration)
          ..addListener(() => setState(
                () {},
              ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller?.onReady?.call(widget.controller!);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InfinityView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _attachController();
    controller.duration = widget.animationDuration;
  }

  void _attachController() {
    widget.controller?._reset = _resetView;
    widget.controller?._setTranslation = _setTranslation;
    widget.controller?._getTranslation = _getTranslation;
    widget.controller?._setRotation = _setRotation;
    widget.controller?._getRotation = _getRotation;
    widget.controller?._setScale = _setScale;
    widget.controller?._getScale = _getScale;
    widget.controller?._initAnimation = _initAnimation;
    widget.controller?._pushAnimation = _pushAnimation;
  }

  @override
  Widget build(BuildContext context) {
    double rot = delta.direction;
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
        child: SizedBox.expand(
          child: Container(
            // We're using a transparent container to allow the child to receive
            // pointer events outside of the child's bounds.
            color: Colors.transparent,
            child: Transform.rotate(
              angle: snappedRot - rot,
              child: Transform(
                transform: matrix.value,
                child: OverflowBox(
                  minWidth: widget.shrinkWrap ? null : 0,
                  minHeight: widget.shrinkWrap ? null : 0,
                  maxWidth: widget.shrinkWrap ? null : double.infinity,
                  maxHeight: widget.shrinkWrap ? null : double.infinity,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void onScaleStart(GenericTransformStartDetails details) {
    translation = details.focalPoint;
    scale = 1.0;
    rotation = 0.0;
  }

  void onScaleUpdate(GenericTransformUpdateDetails details) {
    if (widget.locked) return;

    final focalPoint = widget.focalPointAlignment?.alongSize(context.size!) ??
        details.localFocalPoint;
    Matrix4 newMatrix = Matrix4.copy(matrix.value);

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

    setState(() => matrix = AlwaysStoppedAnimation(newMatrix));
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

  Matrix4 _translate(Offset translation) =>
      Matrix4.identity()..translate(translation.dx, translation.dy);

  Matrix4 _scale(double scale, Offset focalPoint) {
    var delta = focalPoint * (1 - scale);
    return Matrix4.identity()
      ..translate(delta.dx, delta.dy)
      ..scale(scale);
  }

  Matrix4 _rotate(double angle, Offset focalPoint) {
    var dx = (1 - cos(angle)) * focalPoint.dx + sin(angle) * focalPoint.dy;
    var dy = (1 - cos(angle)) * focalPoint.dy - sin(angle) * focalPoint.dx;

    return Matrix4.identity()
      ..translate(dx, dy)
      ..rotateZ(angle);
  }

  Offset _getTranslation() => Offset(array[0], array[1]);
  double _getRotation() => delta.direction;
  double _getScale() => delta.distance;

  void _setTranslation(Offset translation, [bool animate = false]) {
    if (animate) {
      _animatedMatrix.setTranslationRaw(translation.dx, translation.dy, 0);
      return;
    }
    setState(() {
      matrix.value.setTranslationRaw(translation.dx, translation.dy, 0);
    });
  }

  void _setRotation(double rotation, [bool animate = false]) {
    if (animate) {
      _animatedMatrix *= _rotate(-delta.direction + rotation,
          Alignment.center.alongSize(context.size!));
      return;
    }
    setState(() {
      matrix = AlwaysStoppedAnimation(matrix.value *
          _rotate(-delta.direction + rotation,
              Alignment.center.alongSize(context.size!)));
    });
  }

  void _setScale(double scale, [bool animate = false]) {
    if (animate) {
      _animatedMatrix *=
          _scale(1 / delta.distance, Alignment.center.alongSize(context.size!));
      _animatedMatrix *=
          _scale(scale, Alignment.center.alongSize(context.size!));
      return;
    }
    setState(() {
      var descaled = matrix.value *
          _scale(1 / delta.distance, Alignment.center.alongSize(context.size!));
      matrix = AlwaysStoppedAnimation(
          descaled * _scale(scale, Alignment.center.alongSize(context.size!)));
    });
  }

  void _initAnimation() {
    _animatedMatrix = matrix.value.clone();
  }

  void _pushAnimation() {
    setState(() {
      matrix = Matrix4Tween(
        begin: matrix.value,
        end: _animatedMatrix,
      ).chain(CurveTween(curve: widget.animationCurve)).animate(controller);
      controller.forward(from: 0.0);
    });
  }

  void _resetView([bool animate = false]) {
    if (animate) {
      _animatedMatrix = Matrix4.identity();
      return;
    }

    setState(() {
      matrix = AlwaysStoppedAnimation(Matrix4.identity());
    });
  }
}
