import 'package:material_ui/material_ui.dart';

import 'animations.dart';
import 'get_animated_builder.dart';

const _defaultDuration = Duration(seconds: 2);
const _defaultDelay = Duration.zero;

/// Extension to easily chain animation builders onto any [Widget].
extension AnimationExtension on Widget {
  GetAnimatedBuilder? get _currentAnimation =>
      (this is GetAnimatedBuilder) ? this as GetAnimatedBuilder : null;

  /// Animates the widget's opacity from 0.0 to 1.0.
  ///
  /// - [duration] The duration of the animation transition.
  /// - [delay] The delay duration before the animation starts playing.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder fadeIn({
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    assert(
      isSequential || this is! FadeOutAnimation,
      'Can not use fadeOut + fadeIn when isSequential is false',
    );

    return FadeInAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      onComplete: onComplete,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  /// Animates the widget's opacity from 1.0 to 0.0.
  ///
  /// - [duration] The duration of the animation transition.
  /// - [delay] The delay duration before the animation starts playing.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder fadeOut({
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    assert(
      isSequential || this is! FadeInAnimation,
      'Can not use fadeOut() + fadeIn when isSequential is false',
    );

    return FadeOutAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      onComplete: onComplete,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  /// Rotates the widget from [begin] to [end] angle in radians.
  ///
  /// - [begin] Starting rotation angle in radians.
  /// - [end] Ending rotation angle in radians.
  /// - [duration] The duration of the rotation transition.
  /// - [delay] The delay duration before the rotation starts.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder rotate({
    required double begin,
    required double end,
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    return RotateAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      begin: begin,
      end: end,
      onComplete: onComplete,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  /// Scales the widget from [begin] to [end] factor.
  ///
  /// - [begin] Starting scale factor.
  /// - [end] Ending scale factor.
  /// - [duration] The duration of the scale transition.
  /// - [delay] The delay duration before scaling starts.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder scale({
    required double begin,
    required double end,
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    return ScaleAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      begin: begin,
      end: end,
      onComplete: onComplete,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  /// Translates/slides the widget dynamically using an [offset] builder.
  ///
  /// The [offset] callback is invoked on every animation frame with the
  /// current tweened value (interpolated from [begin] to [end]) as its second
  /// parameter, and must use that value to produce the translation for that
  /// frame. Returning a constant [Offset] results in no visible motion.
  ///
  /// ```dart
  /// // Slides the widget 25 logical pixels downward.
  /// Text('Hello').slide(
  ///   offset: (context, value) => Offset(0, 25 * value),
  /// );
  /// ```
  ///
  /// - [offset] Callback that builds the slide offset from the current animation value.
  /// - [begin] Starting interpolation value.
  /// - [end] Ending interpolation value.
  /// - [duration] The duration of the slide transition.
  /// - [delay] The delay duration before sliding starts.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder slide({
    required OffsetBuilder offset,
    double begin = 0,
    double end = 1,
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    return SlideAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      begin: begin,
      end: end,
      onComplete: onComplete,
      offsetBuild: offset,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  /// Bounces the scale of the widget from [begin] to [end].
  ///
  /// - [begin] Starting scale offset value.
  /// - [end] Ending scale offset value.
  /// - [duration] The duration of the bounce animation.
  /// - [delay] The delay duration before bouncing starts.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder bounce({
    required double begin,
    required double end,
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    return BounceAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      begin: begin,
      end: end,
      onComplete: onComplete,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  /// Spins the widget 360 degrees.
  ///
  /// - [duration] The duration of the spin transition.
  /// - [delay] The delay duration before the spin starts.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder spin({
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    return SpinAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      onComplete: onComplete,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  /// Animates the widget's layout size/scale from [begin] to [end].
  ///
  /// - [begin] Starting scale.
  /// - [end] Ending scale.
  /// - [duration] The duration of the size transition.
  /// - [delay] The delay duration before resizing starts.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder size({
    required double begin,
    required double end,
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    return SizeAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      begin: begin,
      end: end,
      onComplete: onComplete,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  /// Blurs the widget from [begin] to [end] sigma factor.
  ///
  /// - [begin] Starting blur factor.
  /// - [end] Ending blur factor.
  /// - [duration] The duration of the blur transition.
  /// - [delay] The delay duration before blurring starts.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder blur({
    double begin = 0,
    double end = 15,
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    return BlurAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      begin: begin,
      end: end,
      onComplete: onComplete,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  /// Flips the widget around the Y-axis from [begin] to [end].
  ///
  /// - [begin] Starting rotation value factor.
  /// - [end] Ending rotation value factor.
  /// - [duration] The duration of the flip transition.
  /// - [delay] The delay duration before flipping starts.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder flip({
    double begin = 0,
    double end = 1,
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    return FlipAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      begin: begin,
      end: end,
      onComplete: onComplete,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  /// Animates the widget with a translation wave on the Y-axis.
  ///
  /// - [begin] Starting wave phase value.
  /// - [end] Ending wave phase value.
  /// - [duration] The duration of the wave transition.
  /// - [delay] The delay duration before the wave starts.
  /// - [onComplete] A callback triggered when the animation completes.
  /// - [isSequential] If true, starts this animation after the previous one in the chain completes.
  /// - [autoPlayOnUpdate] If true, replays the animation when rebuilt with a different tween.
  GetAnimatedBuilder wave({
    double begin = 0,
    double end = 1,
    Duration duration = _defaultDuration,
    Duration delay = _defaultDelay,
    ValueSetter<AnimationController>? onComplete,
    bool isSequential = false,
    bool autoPlayOnUpdate = false,
  }) {
    return WaveAnimation(
      duration: duration,
      delay: _getDelay(isSequential, delay),
      begin: begin,
      end: end,
      onComplete: onComplete,
      autoPlayOnUpdate: autoPlayOnUpdate,
      child: this,
    );
  }

  Duration _getDelay(bool isSequential, Duration delay) {
    assert(
      !(isSequential && delay != Duration.zero),
      "Error: When isSequential is true, delay must be zero. Context: isSequential: $isSequential delay: $delay",
    );

    return isSequential
        ? (_currentAnimation?.totalDuration ?? Duration.zero)
        : delay;
  }
}
