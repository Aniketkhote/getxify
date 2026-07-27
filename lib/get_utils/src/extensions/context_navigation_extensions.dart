import 'package:flutter/material.dart';
import '../../../../getxify.dart';

extension ContextNavigationExt on BuildContext {
  GetDelegate? get _delegate {
    try {
      final router = Router.of(this);
      if (router.routerDelegate is GetDelegate) {
        return router.routerDelegate as GetDelegate;
      }
    } catch (_) {}
    return Get.rootController.rootDelegate;
  }

  Future<T?>? to<T extends Object?>(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    String? id,
    String? routeName,
    bool fullscreenDialog = false,
    Object? arguments,
    List<Binding> bindings = const [],
    bool preventDuplicates = true,
    bool? popGesture,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
    CustomTransition? customTransition,
    bool rebuildStack = true,
    PreventDuplicateHandlingMode preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
  }) {
    return _delegate?.to<T>(
      page,
      opaque: opaque,
      transition: transition,
      curve: curve,
      duration: duration,
      id: id,
      routeName: routeName,
      fullscreenDialog: fullscreenDialog,
      arguments: arguments,
      bindings: bindings,
      preventDuplicates: preventDuplicates,
      popGesture: popGesture,
      showCupertinoParallax: showCupertinoParallax,
      gestureWidth: gestureWidth,
      customTransition: customTransition,
      rebuildStack: rebuildStack,
      preventDuplicateHandlingMode: preventDuplicateHandlingMode,
    );
  }

  Future<T?>? toNamed<T>(
    String page, {
    Object? arguments,
    String? id,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    return _delegate?.toNamed(
      page,
      arguments: arguments,
      id: id,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
    );
  }

  Future<T?>? offNamed<T>(
    String page, {
    Object? arguments,
    String? id,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return _delegate?.offNamed(
      page,
      arguments: arguments,
      id: id,
      parameters: parameters,
    );
  }

  Future<T?>? offNamedUntil<T>(
    String page,
    bool Function(GetPage<dynamic>)? predicate, {
    String? id,
    Object? arguments,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    return _delegate?.offNamedUntil<T>(
      page,
      predicate: predicate,
      id: id,
      arguments: arguments,
      parameters: parameters,
    );
  }

  Future<T?>? offAndToNamed<T>(
    String page, {
    Object? arguments,
    String? id,
    Object? result,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return _delegate?.backAndtoNamed(
      page,
      arguments: arguments,
      result: result,
    );
  }

  Future<T?>? offAllNamed<T>(
    String newRouteName, {
    Object? arguments,
    String? id,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: newRouteName, queryParameters: parameters);
      newRouteName = uri.toString();
    }

    return _delegate?.offAllNamed<T>(
      newRouteName,
      arguments: arguments,
      id: id,
      parameters: parameters,
    );
  }

  bool back<T>({T? result, bool canPop = true, int times = 1, String? id}) {
    if (times < 1) times = 1;

    final delegate = _delegate;
    if (delegate == null) return false;

    if (times > 1) {
      var count = 0;
      delegate.backUntil((route) => count++ == times);
      return true;
    } else {
      if (canPop) {
        if (delegate.canBack == true) {
          delegate.back<T>(result);
          return true;
        }
        return false;
      } else {
        delegate.back<T>(result);
        return true;
      }
    }
  }
}
