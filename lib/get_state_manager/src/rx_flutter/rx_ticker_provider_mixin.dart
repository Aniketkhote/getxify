// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

import '../../get_state_manager.dart';

/// Common interface of [GetSingleTickerProviderStateMixin] and
/// [GetTickerProviderStateMixin]: a [TickerProvider] whose tickers follow
/// the [TickerMode] of the widget subtree that forwards its dependency
/// changes to [didChangeDependencies].
///
/// [GetX], [GetBuilder] and [Bind] check for this interface once instead of
/// dispatching on each concrete mixin.
abstract interface class GetTickerProvider implements TickerProvider {
  /// Binds the tickers created by this provider to the [TickerMode] that
  /// surrounds [context], so they are muted whenever tickers are disabled
  /// in that subtree.
  void didChangeDependencies(BuildContext context);
}

/// Used like `SingleTickerProviderMixin` but only with Get Controllers.
/// Simplifies AnimationController creation inside GetxController.
///
/// Example:
///```
///class SplashController extends GetxController with
///    GetSingleTickerProviderStateMixin {
///  AnimationController controller;
///
///  @override
///  void onInit() {
///    final duration = const Duration(seconds: 2);
///    controller =
///        AnimationController.unbounded(duration: duration, vsync: this);
///    controller.repeat();
///    controller.addListener(() =>
///        print("Animation Controller value: ${controller.value}"));
///  }
///  ...
/// ```
mixin GetSingleTickerProviderStateMixin on GetxController
    implements GetTickerProvider {
  Ticker? _ticker;
  ValueListenable<TickerModeData>? _tickerModeNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          '$runtimeType is a GetSingleTickerProviderStateMixin but multiple tickers were created.',
        ),
        ErrorDescription(
          'A GetSingleTickerProviderStateMixin can only be used as a TickerProvider once.',
        ),
        ErrorHint(
          'If a State is used for multiple AnimationController objects, or if it is passed to other '
          'objects and those objects might use it more than one time in total, then instead of '
          'mixing in a GetSingleTickerProviderStateMixin, use a regular GetTickerProviderStateMixin.',
        ),
      ]);
    }());
    _ticker = Ticker(
      onTick,
      debugLabel: kDebugMode ? 'created by $this' : null,
    );
    // We assume that this is called from initState, build, or some sort of
    // event handler, and that thus TickerMode.valuesOf(context).enabled would return true. We
    // can't actually check that here because if we're in initState then we're
    // not allowed to do inheritance checks yet.
    _updateTicker();
    return _ticker!;
  }

  /// Binds the ticker created by this controller to the [TickerMode] that
  /// surrounds [context], so the ticker is muted whenever tickers are
  /// disabled in that subtree (for example while the route that shows the
  /// widget is covered by another route).
  ///
  /// [GetX], [GetBuilder] and [Bind] call this automatically for the
  /// controllers they manage; it only needs to be called manually when the
  /// controller is used with a custom widget that provides its own
  /// [BuildContext].
  @override
  void didChangeDependencies(BuildContext context) {
    _updateTickerModeNotifier(context);
    _updateTicker();
  }

  void _updateTicker() {
    final values = _tickerModeNotifier?.value;
    if (values == null || _ticker == null) return;
    _ticker!
      ..muted = !values.enabled
      ..forceFrames = values.forceFrames;
  }

  void _updateTickerModeNotifier(BuildContext context) {
    final newNotifier = TickerMode.getValuesNotifier(context);
    if (newNotifier == _tickerModeNotifier) return;
    _tickerModeNotifier?.removeListener(_updateTicker);
    newNotifier.addListener(_updateTicker);
    _tickerModeNotifier = newNotifier;
  }

  @override
  void onClose() {
    assert(() {
      if (_ticker == null || !_ticker!.isActive) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('$this was disposed with an active Ticker.'),
        ErrorDescription(
          '$runtimeType created a Ticker via its GetSingleTickerProviderStateMixin, but at the time '
          'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
          'be disposed before calling super.dispose().',
        ),
        ErrorHint(
          'Tickers used by AnimationControllers '
          'should be disposed by calling dispose() on the AnimationController itself. '
          'Otherwise, the ticker will leak.',
        ),
        _ticker!.describeForError('The offending ticker was'),
      ]);
    }());
    _tickerModeNotifier?.removeListener(_updateTicker);
    _tickerModeNotifier = null;
    super.onClose();
  }
}

/// Used like `TickerProviderMixin` but only with Get Controllers.
/// Simplifies multiple AnimationController creation inside GetxController.
///
/// Example:
///```
///class SplashController extends GetxController with
///    GetTickerProviderStateMixin {
///  AnimationController first_controller;
///  AnimationController second_controller;
///
///  @override
///  void onInit() {
///    final duration = const Duration(seconds: 2);
///    first_controller =
///        AnimationController.unbounded(duration: duration, vsync: this);
///    second_controller =
///        AnimationController.unbounded(duration: duration, vsync: this);
///    first_controller.repeat();
///    first_controller.addListener(() =>
///        print("Animation Controller value: ${first_controller.value}"));
///    second_controller.addListener(() =>
///        print("Animation Controller value: ${second_controller.value}"));
///  }
///  ...
/// ```
mixin GetTickerProviderStateMixin on GetxController
    implements GetTickerProvider {
  Set<Ticker>? _tickers;
  ValueListenable<TickerModeData>? _tickerModeNotifier;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= <_WidgetTicker>{};
    final result = _WidgetTicker(
      onTick,
      this,
      debugLabel: kDebugMode ? 'created by ${describeIdentity(this)}' : null,
    );
    final values = _tickerModeNotifier?.value;
    if (values != null) {
      result
        ..muted = !values.enabled
        ..forceFrames = values.forceFrames;
    }
    _tickers!.add(result);
    return result;
  }

  void _removeTicker(_WidgetTicker ticker) {
    assert(_tickers != null);
    assert(_tickers!.contains(ticker));
    _tickers!.remove(ticker);
  }

  /// Binds the tickers created by this controller to the [TickerMode] that
  /// surrounds [context], so they are muted whenever tickers are disabled in
  /// that subtree (for example while the route that shows the widget is
  /// covered by another route).
  ///
  /// [GetX], [GetBuilder] and [Bind] call this automatically for the
  /// controllers they manage; it only needs to be called manually when the
  /// controller is used with a custom widget that provides its own
  /// [BuildContext].
  @override
  void didChangeDependencies(BuildContext context) {
    _updateTickerModeNotifier(context);
    _updateTickers();
  }

  void _updateTickers() {
    final values = _tickerModeNotifier?.value;
    if (values == null || _tickers == null) return;
    for (final ticker in _tickers!) {
      ticker
        ..muted = !values.enabled
        ..forceFrames = values.forceFrames;
    }
  }

  void _updateTickerModeNotifier(BuildContext context) {
    final newNotifier = TickerMode.getValuesNotifier(context);
    if (newNotifier == _tickerModeNotifier) return;
    _tickerModeNotifier?.removeListener(_updateTickers);
    newNotifier.addListener(_updateTickers);
    _tickerModeNotifier = newNotifier;
  }

  @override
  void onClose() {
    assert(() {
      if (_tickers != null) {
        for (final ticker in _tickers!) {
          if (ticker.isActive) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$this was disposed with an active Ticker.'),
              ErrorDescription(
                '$runtimeType created a Ticker via its GetTickerProviderStateMixin, but at the time '
                'dispose() was called on the mixin, that Ticker was still active. All Tickers must '
                'be disposed before calling super.dispose().',
              ),
              ErrorHint(
                'Tickers used by AnimationControllers '
                'should be disposed by calling dispose() on the AnimationController itself. '
                'Otherwise, the ticker will leak.',
              ),
              ticker.describeForError('The offending ticker was'),
            ]);
          }
        }
      }
      return true;
    }());
    _tickerModeNotifier?.removeListener(_updateTickers);
    _tickerModeNotifier = null;
    super.onClose();
  }
}

class _WidgetTicker extends Ticker {
  _WidgetTicker(super.onTick, this._creator, {super.debugLabel});

  final GetTickerProviderStateMixin _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}
