import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';

import 'get_animated_builder.dart';

/// Signature for a builder function that determines the slide [Offset] based on value.
typedef OffsetBuilder = Offset Function(BuildContext, double);

/// Animation that fades in a widget by transitioning its opacity from 0.0 to 1.0.
class FadeInAnimation extends OpacityAnimation {
  /// Creates a [FadeInAnimation] with specified durations, delays, and callbacks.
  FadeInAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    super.begin = 0,
    super.end = 1,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  });
}

/// Animation that fades out a widget by transitioning its opacity from 1.0 to 0.0.
class FadeOutAnimation extends OpacityAnimation {
  /// Creates a [FadeOutAnimation] with specified durations, delays, and callbacks.
  FadeOutAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    super.begin = 1,
    super.end = 0,
    super.idleValue = 1,
    super.autoPlayOnUpdate,
  });
}

/// Base class for opacity-based animations.
class OpacityAnimation extends GetAnimatedBuilder<double> {
  /// Creates an [OpacityAnimation] transitioning between [begin] and [end] opacity values.
  OpacityAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    required super.onComplete,
    required double begin,
    required double end,
    required super.idleValue,
    super.autoPlayOnUpdate,
  }) : super(
         tween: Tween<double>(begin: begin, end: end),
         builder: (context, value, child) {
           return Opacity(opacity: value, child: child!);
         },
       );
}

/// Animation that rotates a widget from [begin] to [end] angle in radians.
class RotateAnimation extends GetAnimatedBuilder<double> {
  /// Creates a [RotateAnimation] rotating the child widget.
  RotateAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required double begin,
    required double end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) =>
             Transform.rotate(angle: value, child: child),
         tween: Tween<double>(begin: begin, end: end),
       );
}

/// Animation that scales a widget from [begin] to [end] scale factor.
class ScaleAnimation extends GetAnimatedBuilder<double> {
  /// Creates a [ScaleAnimation] scaling the child widget.
  ScaleAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required double begin,
    required double end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) =>
             Transform.scale(scale: value, child: child),
         tween: Tween<double>(begin: begin, end: end),
       );
}

/// Animation that applies a bouncing scale effect to a widget.
class BounceAnimation extends GetAnimatedBuilder<double> {
  /// Creates a [BounceAnimation] scaling the child widget with a bounce curve.
  BounceAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    super.curve = Curves.bounceOut,
    required double begin,
    required double end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) =>
             Transform.scale(scale: 1 + value.abs(), child: child),
         tween: Tween<double>(begin: begin, end: end),
       );
}

/// Animation that spins a widget 360 degrees.
class SpinAnimation extends GetAnimatedBuilder<double> {
  /// Creates a [SpinAnimation] spinning the child widget.
  SpinAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) =>
             Transform.rotate(angle: value * pi / 180.0, child: child),
         tween: Tween<double>(begin: 0, end: 360),
       );
}

/// Animation that transitions a widget's size/scale from [begin] to [end].
class SizeAnimation extends GetAnimatedBuilder<double> {
  /// Creates a [SizeAnimation] sizing/scaling the child widget.
  SizeAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    super.idleValue = 0,
    required double begin,
    required double end,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) =>
             Transform.scale(scale: value, child: child),
         tween: Tween<double>(begin: begin, end: end),
       );
}

/// Animation that applies a blur filter to the child from [begin] to [end] sigma.
///
/// Uses [ImageFiltered] so the blur is applied to the child widget itself,
/// unlike [BackdropFilter] which blurs the content painted behind the widget.
class BlurAnimation extends GetAnimatedBuilder<double> {
  /// Creates a [BlurAnimation] blurring the child widget.
  BlurAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required double begin,
    required double end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) => ImageFiltered(
           imageFilter: ImageFilter.blur(sigmaX: value, sigmaY: value),
           child: child,
         ),
         tween: Tween<double>(begin: begin, end: end),
       );
}

/// Animation that flips a widget around its Y-axis from [begin] to [end] phase.
class FlipAnimation extends GetAnimatedBuilder<double> {
  /// Creates a [FlipAnimation] flipping the child widget Y-axis.
  FlipAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required double begin,
    required double end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) {
           final radians = value * pi;
           return Transform(
             transform: Matrix4.rotationY(radians),
             alignment: Alignment.center,
             child: child,
           );
         },
         tween: Tween<double>(begin: begin, end: end),
       );
}

/// Animation that moves a widget up and down in a wave motion on the Y-axis.
class WaveAnimation extends GetAnimatedBuilder<double> {
  /// Creates a [WaveAnimation] waving the child widget.
  WaveAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required double begin,
    required double end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) => Transform(
           transform: Matrix4.translationValues(
             0.0,
             20.0 * sin(value * pi * 2),
             0.0,
           ),
           child: child,
         ),
         tween: Tween<double>(begin: begin, end: end),
       );
}

/// Animation that wobbles a widget with a perspective rotation Z.
class WobbleAnimation extends GetAnimatedBuilder<double> {
  /// Creates a [WobbleAnimation] wobbling the child widget.
  WobbleAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required double begin,
    required double end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) => Transform(
           transform: Matrix4.identity()
             ..setEntry(3, 2, 0.001)
             ..rotateZ(sin(value * pi * 2) * 0.1),
           alignment: Alignment.center,
           child: child,
         ),
         tween: Tween<double>(begin: begin, end: end),
       );
}

/// Slide animation that enters the child widget from the left of the screen.
class SlideInLeftAnimation extends SlideAnimation {
  /// Creates a [SlideInLeftAnimation] sliding from the left.
  SlideInLeftAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required super.begin,
    required super.end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         offsetBuild: (context, value) =>
             Offset(value * MediaQuery.of(context).size.width, 0),
       );
}

/// Slide animation that enters the child widget from the right of the screen.
class SlideInRightAnimation extends SlideAnimation {
  /// Creates a [SlideInRightAnimation] sliding from the right.
  SlideInRightAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required super.begin,
    required super.end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         offsetBuild: (context, value) =>
             Offset((1 - value) * MediaQuery.of(context).size.width, 0),
       );
}

/// Slide animation that enters the child widget from the bottom upward.
class SlideInUpAnimation extends SlideAnimation {
  /// Creates a [SlideInUpAnimation] sliding upward.
  SlideInUpAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required super.begin,
    required super.end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         offsetBuild: (context, value) =>
             Offset(0, value * MediaQuery.of(context).size.height),
       );
}

/// Slide animation that enters the child widget from the top downward.
class SlideInDownAnimation extends SlideAnimation {
  /// Creates a [SlideInDownAnimation] sliding downward.
  SlideInDownAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required super.begin,
    required super.end,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         offsetBuild: (context, value) =>
             Offset(0, (1 - value) * MediaQuery.of(context).size.height),
       );
}

/// Base slide animation class that shifts a widget position using [OffsetBuilder].
class SlideAnimation extends GetAnimatedBuilder<double> {
  /// Creates a [SlideAnimation] translating the child widget.
  SlideAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    required double begin,
    required double end,
    required OffsetBuilder offsetBuild,
    super.onComplete,
    super.idleValue = 0,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) => Transform.translate(
           offset: offsetBuild(context, value),
           child: child,
         ),
         tween: Tween<double>(begin: begin, end: end),
       );
}

/// Animation that transitions the color filter of a widget between two colors.
class ColorAnimation extends GetAnimatedBuilder<Color?> {
  /// Creates a [ColorAnimation] applying color transitions to the child widget.
  ColorAnimation({
    super.key,
    required super.duration,
    required super.delay,
    required super.child,
    super.onComplete,
    required Color begin,
    required Color end,
    Color? idleColor,
    super.autoPlayOnUpdate,
  }) : super(
         builder: (context, value, child) => ColorFiltered(
           colorFilter: ColorFilter.mode(value!, BlendMode.srcIn),
           child: child,
         ),
         idleValue: idleColor ?? begin,
         tween: ColorTween(begin: begin, end: end),
       );
}
