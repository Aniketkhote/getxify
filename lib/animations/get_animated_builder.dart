import 'package:material_ui/material_ui.dart';

import 'animations.dart';

/// A widget that animates a [tween] value over a [duration] after a specified [delay].
///
/// Implements animation lifecycle hooks such as [onStart] and [onComplete].
///
/// The animation plays once, when the widget is first inserted into the tree.
/// Rebuilding the widget with a different [duration], [tween], or [curve]
/// updates the animation configuration but does not replay it. To replay the
/// animation, either provide a new [Key] (recreating the state), enable
/// [autoPlayOnUpdate], or keep the [AnimationController] received in
/// [onStart]/[onComplete] and call `controller.forward(from: 0)`.
class GetAnimatedBuilder<T> extends StatefulWidget {
  /// The duration of the animation transition itself.
  final Duration duration;

  /// The delay duration before the animation starts playing.
  final Duration delay;

  /// The child widget to be animated.
  final Widget child;

  /// A callback triggered when the animation completes.
  final ValueSetter<AnimationController>? onComplete;

  /// A callback triggered when the animation starts playing.
  final ValueSetter<AnimationController>? onStart;

  /// The tween defining the start and end values for the animation.
  final Tween<T> tween;

  /// The idle or initial value of the animation before it starts playing.
  final T idleValue;

  /// The builder function that builds a widget with the current animated value.
  final ValueWidgetBuilder<T> builder;

  /// The animation curve to apply to the transition.
  final Curve curve;

  /// Whether to replay the animation from the beginning when the widget is
  /// rebuilt with a different [tween].
  ///
  /// Useful when the tween is derived from reactive state (for example inside
  /// an `Obx`): each change to the observed value replays the animation with
  /// the new bounds. The replay starts immediately, without waiting [delay]
  /// again. Defaults to false, preserving the play-once behavior.
  final bool autoPlayOnUpdate;

  /// Returns the total duration including both the animation duration and the delay.
  Duration get totalDuration => duration + delay;

  /// Creates a [GetAnimatedBuilder] with the given parameters.
  const GetAnimatedBuilder({
    super.key,
    this.curve = Curves.linear,
    this.onComplete,
    this.onStart,
    required this.duration,
    required this.tween,
    required this.idleValue,
    required this.builder,
    required this.child,
    required this.delay,
    this.autoPlayOnUpdate = false,
  });

  @override
  GetAnimatedBuilderState<T> createState() => GetAnimatedBuilderState<T>();
}

/// The state for [GetAnimatedBuilder] managing the animation lifecycle.
class GetAnimatedBuilderState<T> extends State<GetAnimatedBuilder<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _curvedAnimation;
  late Animation<T> _animation;

  bool _wasStarted = false;

  late T _idleValue;

  bool _willResetOnDispose = false;

  /// Whether the controller will be reset when this state is disposed.
  bool get willResetOnDispose => _willResetOnDispose;

  void _listener(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        widget.onComplete?.call(_controller);
        if (_willResetOnDispose) {
          _controller.reset();
        }
        break;
      // case AnimationStatus.dismissed:
      case AnimationStatus.forward:
        widget.onStart?.call(_controller);
        break;
      // case AnimationStatus.reverse:
      default:
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget is OpacityAnimation) {
      final current = context
          .findRootAncestorStateOfType<GetAnimatedBuilderState>();
      final isLast = current == null;

      if (widget is FadeInAnimation) {
        _idleValue = 1.0 as T;
      } else {
        if (isLast) {
          _willResetOnDispose = false;
        } else {
          _willResetOnDispose = true;
        }
        _idleValue = widget.idleValue;
      }
    } else {
      _idleValue = widget.idleValue;
    }

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _controller.addStatusListener(_listener);

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _animation = widget.tween.animate(_curvedAnimation);

    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _wasStarted = true;
          _controller.forward();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant GetAnimatedBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }

    final tweenChanged =
        widget.tween.begin != oldWidget.tween.begin ||
        widget.tween.end != oldWidget.tween.end;

    if (tweenChanged || widget.curve != oldWidget.curve) {
      // Dispose the replaced CurvedAnimation: it holds a status listener on
      // the controller and would otherwise leak.
      _curvedAnimation.dispose();
      _curvedAnimation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      );
      _animation = widget.tween.animate(_curvedAnimation);
    }

    if (widget.autoPlayOnUpdate && tweenChanged) {
      _wasStarted = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_listener);
    _curvedAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _wasStarted ? _animation.value : _idleValue;
        return widget.builder(context, value, child);
      },
      child: widget.child,
    );
  }
}
