part of '../extension_navigation.dart';

extension GetNavigationExt on GetInterface {
  /// **Navigation.push()** shortcut.<br><br>
  ///
  /// Pushes a new `page` to the stack
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, GetX will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// For fully custom transition animations, pass a [customTransition];
  /// it takes precedence over [transition].
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
    List<BindingsInterface> bindings = const [],
    bool preventDuplicates = true,
    bool? popGesture,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
    CustomTransition? customTransition,
    bool rebuildStack = true,
    PreventDuplicateHandlingMode preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
  }) {
    return searchDelegate(id).to(
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

  /// **Navigation.pushNamed()** shortcut.<br><br>
  ///
  /// Pushes a new named `page` to the stack.
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// By default, GetX will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
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

    return searchDelegate(id).toNamed(
      page,
      arguments: arguments,
      id: id,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
    );
  }

  /// **Navigation.pushReplacementNamed()** shortcut.<br><br>
  ///
  /// Pop the current named `page` in the stack and push a new one in its place
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// By default, GetX will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
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
    return searchDelegate(id).offNamed(
      page,
      arguments: arguments,
      id: id,
      // preventDuplicates: preventDuplicates,
      parameters: parameters,
    );
  }

  /// **Navigation.popUntil()** shortcut.<br><br>
  ///
  /// Calls pop several times in the stack until [predicate] returns true
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// [predicate] can be used like this:
  /// `Get.until((route) => Get.currentRoute == '/home')`so when you get to home page,
  ///
  /// or also like this:
  /// `Get.until((route) => !Get.isDialogOpen())`, to make sure the
  /// dialog is closed
  void until(bool Function(GetPage<dynamic>) predicate, {String? id}) {
    return searchDelegate(id).backUntil(predicate);
  }

  /// **Navigation.pushNamedAndRemoveUntil()** shortcut.<br><br>
  ///
  /// Push the given named `page`, and then pop several pages in the stack
  /// until [predicate] returns true
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// [predicate] can be used like this:
  /// `Get.offNamedUntil(page, ModalRoute.withName('/home'))`
  /// to pop routes in stack until home,
  /// or like this:
  /// `Get.offNamedUntil((route) => !Get.isDialogOpen())`,
  /// to make sure the dialog is closed
  ///
  /// Note: Always put a slash on the route name ('/page1'), to avoid unexpected errors
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

    return searchDelegate(id).offNamedUntil<T>(
      page,
      predicate: predicate,
      id: id,
      arguments: arguments,
      parameters: parameters,
    );
  }

  /// **Navigation.popAndPushNamed()** shortcut.<br><br>
  ///
  /// Pop the current named page and pushes a new `page` to the stack
  /// in its place
  ///
  /// You can send any type of value to the other route in the [arguments].
  /// It is very similar to `offNamed()` but use a different approach
  ///
  /// The `offNamed()` pop a page, and goes to the next. The
  /// `offAndToNamed()` goes to the next page, and removes the previous one.
  /// The route transition animation is different.
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
    return searchDelegate(
      id,
    ).backAndtoNamed(page, arguments: arguments, result: result);
  }

  /// **Navigation.removeRoute()** shortcut.<br><br>
  ///
  /// Remove a specific [route] from the stack
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  void removeRoute(String name, {String? id}) {
    return searchDelegate(id).removeRoute(name);
  }

  /// **Navigation.pushNamedAndRemoveUntil()** shortcut.<br><br>
  ///
  /// Push a named `page` and pop several pages in the stack
  /// until [predicate] returns true. [predicate] is optional
  ///
  /// It has the advantage of not needing context, so you can
  /// call from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [predicate] can be used like this:
  /// `Get.until((route) => Get.currentRoute == '/home')`so when you get to home page,
  /// or also like
  /// `Get.until((route) => !Get.isDialogOpen())`, to make sure the dialog
  /// is closed
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
  Future<T?>? offAllNamed<T>(
    String newRouteName, {
    // bool Function(GetPage<dynamic>)? predicate,
    Object? arguments,
    String? id,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: newRouteName, queryParameters: parameters);
      newRouteName = uri.toString();
    }

    return searchDelegate(id).offAllNamed<T>(
      newRouteName,
      arguments: arguments,
      id: id,
      parameters: parameters,
    );
  }

  /// Returns true if a Snackbar, Dialog or BottomSheet is currently OPEN
  bool get isOverlaysOpen =>
      (isSnackbarOpen ||
      (isDialogOpen ?? false) ||
      (isBottomSheetOpen ?? false));

  /// Returns true if there is no Snackbar, Dialog or BottomSheet open
  bool get isOverlaysClosed =>
      (!isSnackbarOpen &&
      !(isDialogOpen ?? false) &&
      !(isBottomSheetOpen ?? false));

  /// **Navigation.popUntil()** shortcut.<br><br>
  ///
  /// Pop the current page, snackbar, dialog or bottomsheet in the stack
  ///
  /// if your set [closeOverlays] to true, Get.back() will close the
  /// currently open snackbar/dialog/bottomsheet AND the current page
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// When the topmost route handles the pop internally — for example a
  /// [Scaffold] with an open drawer, or a persistent bottom sheet, both of
  /// which register a [LocalHistoryEntry] on the enclosing route — that
  /// entry is consumed (e.g. the drawer closes) and the page itself stays,
  /// matching `Navigator.pop` semantics.
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  ///
  /// Returns whether the back navigation was performed: `false` when
  /// [canPop] is true but there is no route to go back to (e.g. the
  /// current page is the only one in the stack, as after a deep link),
  /// so callers can detect the ignored back and react, `true` otherwise.
  bool back<T>({T? result, bool canPop = true, int times = 1, String? id}) {
    if (times < 1) {
      times = 1;
    }

    if (times > 1) {
      var count = 0;
      searchDelegate(id).backUntil((route) => count++ == times);
      return true;
    } else {
      if (_topRoute(id: id)?.willHandlePopInternally == true) {
        searchDelegate(id).navigatorKey.currentState?.pop<T>(result);
        return true;
      }
      if (canPop) {
        if (searchDelegate(id).canBack == true) {
          searchDelegate(id).back<T>(result);
          return true;
        }
        return false;
      } else {
        searchDelegate(id).back<T>(result);
        return true;
      }
    }
  }

  void backLegacy<T>({
    T? result,
    bool closeOverlays = false,
    bool canPop = true,
    int times = 1,
    String? id,
  }) {
    if (closeOverlays) {
      closeAllOverlays();
    }

    if (times < 1) {
      times = 1;
    }

    if (times > 1) {
      var count = 0;
      return searchDelegate(id).navigatorKey.currentState?.popUntil((route) {
        return count++ == times;
      });
    } else {
      if (canPop) {
        if (searchDelegate(id).navigatorKey.currentState?.canPop() == true) {
          return searchDelegate(id).navigatorKey.currentState?.pop<T>(result);
        }
      } else {
        return searchDelegate(id).navigatorKey.currentState?.pop<T>(result);
      }
    }
  }

  /// Returns the topmost [Route] on the navigator of the delegate
  /// matching [id], without popping it.
  Route<dynamic>? _topRoute({String? id}) {
    Route<dynamic>? currentRoute;
    searchDelegate(id).navigatorKey.currentState?.popUntil((route) {
      currentRoute = route;
      return true;
    });
    return currentRoute;
  }

  void closeAllDialogsAndBottomSheets(String? id) {
    // It can not be divided, because dialogs and bottomsheets can not be consecutive
    var topRoute = _topRoute(id: id);
    while (_isDialogRoute(topRoute) || _isBottomSheetRoute(topRoute)) {
      _popOverlayRoute(topRoute!, id: id, result: null);
      topRoute = _topRoute(id: id);
    }
  }

  /// Close all currently open dialogs, returning a [result] to each
  /// of them, if provided
  void closeAllDialogs<T>({String? id, T? result}) {
    var topRoute = _topRoute(id: id);
    while (_isDialogRoute(topRoute)) {
      _popOverlayRoute(topRoute!, id: id, result: result);
      topRoute = _topRoute(id: id);
    }
  }

  /// Close the currently open dialog, returning a [result], if provided
  void closeDialog<T>({String? id, T? result}) {
    final topRoute = _topRoute(id: id);
    // Stop if there is no dialog open
    if (!_isDialogRoute(topRoute)) return;

    _popOverlayRoute(topRoute!, id: id, result: result);
  }

  void closeBottomSheet<T>({String? id, T? result}) {
    final topRoute = _topRoute(id: id);
    // Stop if there is no bottomsheet open
    if (!_isBottomSheetRoute(topRoute)) return;

    _popOverlayRoute(topRoute!, id: id, result: result);
  }

  /// Close the current overlay (e.g. dialog or bottom sheet) returning
  /// the [result], if provided.
  ///
  /// Page routes managed by the router delegate are never popped by this
  /// method. If the navigator still shows a page that was already removed
  /// declaratively (for example by a [back] call awaited in the same frame),
  /// the pop is retried once after the pending frame settles, so the actual
  /// overlay is closed instead of a page.
  void closeOverlay<T>({String? id, T? result}) {
    final topRoute = _topRoute(id: id);
    if (topRoute == null) return;

    _popOverlayRoute(topRoute, id: id, result: result);
  }

  /// Pops [topRoute] — the already-resolved topmost route of the navigator
  /// matching [id] — following the [closeOverlay] semantics, without
  /// scanning the navigator again.
  void _popOverlayRoute<T>(
    Route<dynamic> topRoute, {
    required String? id,
    required T? result,
  }) {
    final navigatorState = searchDelegate(id).navigatorKey.currentState;
    if (navigatorState == null) return;

    if (topRoute.settings is Page) {
      engine.addPostFrameCallback((_) {
        if (_routingOrNull == null) return;
        final route = _topRoute(id: id);
        if (route != null && route.settings is! Page) {
          searchDelegate(id).navigatorKey.currentState?.pop(result);
        }
      });
      return;
    }

    navigatorState.pop(result);
  }

  /// Close all currently open bottom sheets, returning a [result] to each
  /// of them, if provided
  void closeAllBottomSheets<T>({String? id, T? result}) {
    var topRoute = _topRoute(id: id);
    while (_isBottomSheetRoute(topRoute)) {
      _popOverlayRoute(topRoute!, id: id, result: result);
      topRoute = _topRoute(id: id);
    }
  }

  void closeAllOverlays() {
    closeAllDialogsAndBottomSheets(null);
    closeAllSnackbars();
  }

  /// Closes the currently open snackbars, dialogs and bottom sheets.
  ///
  /// When [closeAll] is true (the default), every open overlay of the
  /// selected kinds is closed; otherwise only the topmost one is.
  /// Dialogs and bottom sheets are closed returning [result] to the
  /// `Future` returned when they were opened.
  ///
  /// If the topmost route handles the pop internally — for example a
  /// [Scaffold] with an open drawer, which registers a [LocalHistoryEntry]
  /// on the enclosing route — that entry is consumed first (e.g. the
  /// drawer closes) while the page itself stays.
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  void close<T extends Object>({
    bool closeAll = true,
    bool closeSnackbar = true,
    bool closeDialog = true,
    bool closeBottomSheet = true,
    String? id,
    T? result,
  }) {
    if (_topRoute(id: id)?.willHandlePopInternally == true) {
      searchDelegate(id).navigatorKey.currentState?.pop();
    }

    void handleClose(
      bool closeCondition,
      void Function() closeAllFunction,
      void Function() closeSingleFunction, [
      bool Function()? isOpenCondition,
    ]) {
      if (closeCondition) {
        if (closeAll) {
          closeAllFunction();
        } else if (isOpenCondition?.call() == true) {
          closeSingleFunction();
        }
      }
    }

    handleClose(closeSnackbar, closeAllSnackbars, closeCurrentSnackbar);
    handleClose(
      closeDialog,
      () => closeAllDialogs(id: id, result: result),
      () => closeOverlay(id: id, result: result),
      () => _isDialogRoute(_topRoute(id: id)),
    );
    handleClose(
      closeBottomSheet,
      () => closeAllBottomSheets(id: id, result: result),
      () => closeOverlay(id: id, result: result),
      () => _isBottomSheetRoute(_topRoute(id: id)),
    );
  }

  /// **Navigation.pushReplacement()** shortcut .<br><br>
  ///
  /// Pop the current page and pushes a new `page` to the stack
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], define a Tween [curve],
  /// and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, GetX will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// For fully custom transition animations, pass a [customTransition];
  /// it takes precedence over [transition].
  Future<T?>? off<T>(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    bool? popGesture,
    String? id,
    String? routeName,
    Object? arguments,
    List<BindingsInterface> bindings = const [],
    bool fullscreenDialog = false,
    bool preventDuplicates = true,
    Duration? duration,
    double Function(BuildContext context)? gestureWidth,
    CustomTransition? customTransition,
  }) {
    routeName ??= "/${page.runtimeType.toString()}";
    routeName = _cleanRouteName(routeName);
    if (preventDuplicates && routeName == currentRoute) {
      return null;
    }
    return searchDelegate(id).off(
      page,
      opaque: opaque ?? true,
      transition: transition,
      curve: curve,
      popGesture: popGesture,
      id: id,
      routeName: routeName,
      arguments: arguments,
      bindings: bindings,
      fullscreenDialog: fullscreenDialog,
      preventDuplicates: preventDuplicates,
      duration: duration,
      gestureWidth: gestureWidth,
      customTransition: customTransition,
    );
  }

  Future<T?> offUntil<T>(
    Widget Function() page,
    bool Function(GetPage) predicate, [
    Object? arguments,
    String? id,
  ]) {
    return searchDelegate(id).offUntil(page, predicate, arguments);
  }

  ///
  /// Push a `page` and pop several pages in the stack
  /// until [predicate] returns true. [predicate] is optional
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], a [curve] and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [predicate] can be used like this:
  /// `Get.until((route) => Get.currentRoute == '/home')`so when you get to home page,
  /// or also like
  /// `Get.until((route) => !Get.isDialogOpen())`, to make sure the dialog
  /// is closed
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, GetX will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// For fully custom transition animations, pass a [customTransition];
  /// it takes precedence over [transition].
  Future<T?>? offAll<T>(
    Widget Function() page, {
    bool Function(GetPage<dynamic>)? predicate,
    bool? opaque,
    bool? popGesture,
    String? id,
    String? routeName,
    Object? arguments,
    List<BindingsInterface> bindings = const [],
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    double Function(BuildContext context)? gestureWidth,
    CustomTransition? customTransition,
  }) {
    routeName ??= "/${page.runtimeType.toString()}";
    routeName = _cleanRouteName(routeName);
    return searchDelegate(id).offAll<T>(
      page,
      predicate: predicate,
      opaque: opaque ?? true,
      popGesture: popGesture,
      id: id,
      //  routeName routeName,
      arguments: arguments,
      bindings: bindings,
      fullscreenDialog: fullscreenDialog,
      transition: transition,
      curve: curve,
      duration: duration,
      gestureWidth: gestureWidth,
      customTransition: customTransition,
    );
  }

  /// Takes a route [name] String generated by [to], [off], [offAll]
  /// (and similar context navigation methods), cleans the extra chars and
  /// accommodates the format.
  String _cleanRouteName(String name) {
    name = name.replaceAll('() => ', '');

    /// uncomment for URL styling.
    // name = name.paramCase!;
    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return Uri.tryParse(name)?.toString() ?? name;
  }

  Future<void> updateLocale(Locale l) async {
    Get.locale = l;
    // Record that the locale was chosen explicitly so that subsequent
    // device locale changes never clobber the user's selection, even when
    // the chosen locale matches the locale last auto-applied from the device.
    rootController.localeSetExplicitly = true;
    await forceAppUpdate();
  }

  /// As a rule, Flutter knows which widget to update,
  /// so this command is rarely needed. We can mention situations
  /// where you use const so that widgets are not updated with setState,
  /// but you want it to be forcefully updated when an event like
  /// language change happens. using context to make the widget dirty
  /// for performRebuild() is a viable solution.
  /// However, in situations where this is not possible, or at least,
  /// is not desired by the developer, the only solution for updating
  /// widgets that Flutter does not want to update is to use reassemble
  /// to forcibly rebuild all widgets. Attention: calling this function will
  /// reconstruct the application from the sketch, use this with caution.
  /// Your entire application will be rebuilt, and touch events will not
  /// work until the end of rendering.
  Future<void> forceAppUpdate() async {
    await engine.performReassemble();
  }

  void appUpdate() => rootController.update();

  void changeTheme(ThemeData theme) {
    rootController.setTheme(theme);
  }

  void changeThemeMode(ThemeMode themeMode) {
    rootController.setThemeMode(themeMode);
  }

  GlobalKey<NavigatorState>? addKey(GlobalKey<NavigatorState> newKey) {
    return rootController.addKey(newKey);
  }

  GetDelegate? nestedKey(String? key) {
    return rootController.nestedKey(key);
  }

  GetDelegate searchDelegate(String? k) {
    if (k != null) {
      if (!keys.containsKey(k)) {
        throw RouteNotFoundException('Route id ($k) not found');
      }
      return keys[k]!;
    }

    final currentContext = context;
    if (currentContext != null) {
      try {
        final router = Router.of(currentContext);
        if (router.routerDelegate is GetDelegate) {
          return router.routerDelegate as GetDelegate;
        }
      } catch (_) {}
    }

    return Get.rootController.rootDelegate;
  }

  /// give name from current route
  String get currentRoute => routing.current;

  /// give name from previous route
  String get previousRoute => routing.previous;

  /// check if snackbar is open,
  /// or false if routing is not initialized yet
  bool get isSnackbarOpen =>
      _routingOrNull != null &&
      SnackbarController.isSnackbarBeingShown; //routing.isSnackbar;

  /// Closes all queued snackbars.
  ///
  /// When [withAnimations] is false, the currently visible snackbar is
  /// removed immediately, skipping its exit animation.
  void closeAllSnackbars({bool withAnimations = true}) {
    SnackbarController.cancelAllSnackbars(withAnimations: withAnimations);
  }

  /// Closes the currently visible snackbar, if any.
  ///
  /// When [withAnimations] is false, the snackbar is removed immediately,
  /// skipping its exit animation.
  Future<void> closeCurrentSnackbar({bool withAnimations = true}) async {
    await SnackbarController.closeCurrentSnackbar(
      withAnimations: withAnimations,
    );
  }

  /// check if dialog is open,
  /// or null if routing is not initialized yet
  bool? get isDialogOpen => _routingOrNull?.isDialog;

  /// check if bottomsheet is open,
  /// or null if routing is not initialized yet
  bool? get isBottomSheetOpen => _routingOrNull?.isBottomSheet;

  /// check a raw current route
  Route<dynamic>? get rawRoute => routing.route;

  /// check if default opaque route is enable
  bool get isOpaqueRouteDefault => defaultOpaqueRoute;

  /// give access to currentContext
  BuildContext? get context => key.currentContext;

  /// give access to current Overlay Context
  BuildContext? get overlayContext {
    BuildContext? overlay;
    key.currentState?.overlay?.context.visitChildElements((element) {
      overlay = element;
    });
    return overlay;
  }

  /// give access to Theme.of(context)
  ThemeData get theme {
    var theme = ThemeData.fallback();
    if (context != null) {
      theme = Theme.of(context!);
    }
    return theme;
  }

  /// The current null safe [WidgetsBinding]
  WidgetsBinding get engine {
    return WidgetsFlutterBinding.ensureInitialized();
  }

  /// The window to which this binding is bound.
  ui.PlatformDispatcher get window => engine.platformDispatcher;

  Locale? get deviceLocale => window.locale;

  GlobalKey<NavigatorState> get key => rootController.key;

  Map<String, GetDelegate> get keys => rootController.keys;

  GetRootState get rootController => GetRootState.controller;

  ConfigData get _getxController => GetRootState.controller.config;

  bool? get defaultPopGesture => _getxController.defaultPopGesture;
  bool get defaultOpaqueRoute => _getxController.defaultOpaqueRoute;

  Transition? get defaultTransition => _getxController.defaultTransition;

  /// The transition duration applied to routes that don't set their own:
  /// the `transitionDuration` given to `GetMaterialApp`/`GetCupertinoApp`,
  /// or 300 milliseconds when none was provided.
  Duration get defaultTransitionDuration {
    return _getxController.transitionDuration ??
        _getxController.defaultTransitionDuration;
  }

  Curve get defaultTransitionCurve => _getxController.defaultTransitionCurve;

  Curve get defaultDialogTransitionCurve {
    return _getxController.defaultDialogTransitionCurve;
  }

  Duration get defaultDialogTransitionDuration {
    return _getxController.defaultDialogTransitionDuration;
  }

  Routing get routing => _getxController.routing;

  /// [routing] when the GetX widget tree is initialized, or `null` before
  /// that (accessing [routing] earlier would throw).
  Routing? get _routingOrNull => GetRoot.treeInitialized ? routing : null;

  bool get _shouldUseMock => GetTestMode.active && !GetRoot.treeInitialized;

  /// give current arguments
  dynamic get arguments {
    return args();
  }

  T args<T>() {
    if (_shouldUseMock) {
      return GetTestMode.arguments as T;
    }
    // Dialogs and bottom sheets are pushed imperatively on the navigator
    // and never enter the delegate's page stack, so arguments given to
    // `Get.dialog`/`Get.bottomSheet` live only in the overlay route's
    // settings. While such an overlay is topmost, honor its arguments;
    // an overlay opened without arguments keeps exposing the underlying
    // page's arguments, and closing the overlay restores them.
    final overlayRoute = _routingOrNull?.route;
    if (overlayRoute != null &&
        (_isDialogRoute(overlayRoute) || _isBottomSheetRoute(overlayRoute)) &&
        overlayRoute.isCurrent &&
        overlayRoute.settings.arguments != null) {
      return overlayRoute.settings.arguments as T;
    }
    return rootController.rootDelegate.arguments<T>();
  }

  Map<String, String?> get parameters {
    if (_shouldUseMock) {
      return GetTestMode.parameters;
    }

    return rootController.rootDelegate.parameters;
  }

  /// Casts the stored router delegate to a desired type
  TDelegate? delegate<TDelegate extends RouterDelegate<TPage>, TPage>() =>
      _getxController.routerDelegate as TDelegate?;
}
