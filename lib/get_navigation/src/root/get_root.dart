import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:getxify/get_navigation/src/routes/core/test_kit.dart';

import '../../../getxify.dart';

/// The central configuration container used internally by GetXify.
///
/// [ConfigData] aggregates all properties required to bootstrap a
/// GetMaterialApp or GetCupertinoApp, bridging the gap between legacy
/// Flutter properties and GetXify's advanced routing, localization, and state systems.
class ConfigData {
  final ValueChanged<Routing?>? routingCallback;
  final Transition? defaultTransition;
  final VoidCallback? onInit;
  final VoidCallback? onReady;
  final VoidCallback? onDispose;
  final bool? enableLog;
  final LogWriterCallback? logWriterCallback;

  final List<Bind> binds;
  final Duration? transitionDuration;
  final bool? defaultGlobalState;
  final List<GetPage>? getPages;
  final GetPage? unknownRoute;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final RouterConfig<Object>? routerConfig;
  final BackButtonDispatcher? backButtonDispatcher;
  final List<NavigatorObserver>? navigatorObservers;
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
  final Map<String, Map<String, String>>? translationsKeys;
  final Translations? translations;
  final Locale? locale;
  final Locale? fallbackLocale;
  final String? initialRoute;
  final CustomTransition? customTransition;
  final Widget? home;
  final bool testMode;
  final Key? unikey;
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode? themeMode;
  final bool? defaultPopGesture;
  final bool defaultOpaqueRoute;
  final Duration defaultTransitionDuration;
  final Curve defaultTransitionCurve;
  final Curve defaultDialogTransitionCurve;
  final Duration defaultDialogTransitionDuration;
  final Routing routing;
  final Map<String, String?> parameters;
  final SnackBarQueue snackBarQueue = SnackBarQueue();

  ConfigData({
    required this.routingCallback,
    required this.defaultTransition,
    required this.onInit,
    required this.onReady,
    required this.onDispose,
    required this.enableLog,
    required this.logWriterCallback,

    required this.binds,
    required this.transitionDuration,
    required this.defaultGlobalState,
    required this.getPages,
    required this.unknownRoute,
    required this.routeInformationProvider,
    required this.routeInformationParser,
    required this.routerDelegate,
    required this.routerConfig,
    required this.backButtonDispatcher,
    required this.navigatorObservers,
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
    required this.translationsKeys,
    required this.translations,
    required this.locale,
    required this.fallbackLocale,
    required this.initialRoute,
    required this.customTransition,
    required this.home,
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.unikey,
    this.testMode = false,
    this.defaultOpaqueRoute = true,
    this.defaultTransitionDuration = const Duration(milliseconds: 300),
    this.defaultTransitionCurve = Curves.easeOutQuad,
    this.defaultDialogTransitionCurve = Curves.easeOutQuad,
    this.defaultDialogTransitionDuration = const Duration(milliseconds: 300),
    this.parameters = const {},
    required this.defaultPopGesture,
    Routing? routing,
  }) : routing = routing ?? Routing();

  ConfigData copyWith({
    ValueChanged<Routing?>? routingCallback,
    Transition? defaultTransition,
    VoidCallback? onInit,
    VoidCallback? onReady,
    VoidCallback? onDispose,
    bool? enableLog,
    LogWriterCallback? logWriterCallback,
    List<Bind>? binds,
    Duration? transitionDuration,
    bool? defaultGlobalState,
    List<GetPage>? getPages,
    GetPage? unknownRoute,
    RouteInformationProvider? routeInformationProvider,
    RouteInformationParser<Object>? routeInformationParser,
    RouterDelegate<Object>? routerDelegate,
    RouterConfig<Object>? routerConfig,
    BackButtonDispatcher? backButtonDispatcher,
    List<NavigatorObserver>? navigatorObservers,
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
    Map<String, Map<String, String>>? translationsKeys,
    Translations? translations,
    Locale? locale,
    Locale? fallbackLocale,
    String? initialRoute,
    CustomTransition? customTransition,
    Widget? home,
    bool? testMode,
    Key? unikey,
    ThemeData? theme,
    ThemeData? darkTheme,
    ThemeMode? themeMode,
    bool? defaultPopGesture,
    bool? defaultOpaqueRoute,
    Duration? defaultTransitionDuration,
    Curve? defaultTransitionCurve,
    Curve? defaultDialogTransitionCurve,
    Duration? defaultDialogTransitionDuration,
    Routing? routing,
    Map<String, String?>? parameters,
  }) {
    return ConfigData(
      routingCallback: routingCallback ?? this.routingCallback,
      defaultTransition: defaultTransition ?? this.defaultTransition,
      onInit: onInit ?? this.onInit,
      onReady: onReady ?? this.onReady,
      onDispose: onDispose ?? this.onDispose,
      enableLog: enableLog ?? this.enableLog,
      logWriterCallback: logWriterCallback ?? this.logWriterCallback,
      binds: binds ?? this.binds,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      defaultGlobalState: defaultGlobalState ?? this.defaultGlobalState,
      getPages: getPages ?? this.getPages,
      unknownRoute: unknownRoute ?? this.unknownRoute,
      routeInformationProvider:
          routeInformationProvider ?? this.routeInformationProvider,
      routeInformationParser:
          routeInformationParser ?? this.routeInformationParser,
      routerDelegate: routerDelegate ?? this.routerDelegate,
      routerConfig: routerConfig ?? this.routerConfig,
      backButtonDispatcher: backButtonDispatcher ?? this.backButtonDispatcher,
      navigatorObservers: navigatorObservers ?? this.navigatorObservers,
      navigatorKey: navigatorKey ?? this.navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey ?? this.scaffoldMessengerKey,
      translationsKeys: translationsKeys ?? this.translationsKeys,
      translations: translations ?? this.translations,
      locale: locale ?? this.locale,
      fallbackLocale: fallbackLocale ?? this.fallbackLocale,
      initialRoute: initialRoute ?? this.initialRoute,
      customTransition: customTransition ?? this.customTransition,
      home: home ?? this.home,
      testMode: testMode ?? this.testMode,
      unikey: unikey ?? this.unikey,
      theme: theme ?? this.theme,
      darkTheme: darkTheme ?? this.darkTheme,
      themeMode: themeMode ?? this.themeMode,
      defaultPopGesture: defaultPopGesture ?? this.defaultPopGesture,
      defaultOpaqueRoute: defaultOpaqueRoute ?? this.defaultOpaqueRoute,
      defaultTransitionDuration:
          defaultTransitionDuration ?? this.defaultTransitionDuration,
      defaultTransitionCurve:
          defaultTransitionCurve ?? this.defaultTransitionCurve,
      defaultDialogTransitionCurve:
          defaultDialogTransitionCurve ?? this.defaultDialogTransitionCurve,
      defaultDialogTransitionDuration:
          defaultDialogTransitionDuration ??
          this.defaultDialogTransitionDuration,
      routing: routing ?? this.routing,
      parameters: parameters ?? this.parameters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ConfigData &&
        other.routingCallback == routingCallback &&
        other.defaultTransition == defaultTransition &&
        other.onInit == onInit &&
        other.onReady == onReady &&
        other.onDispose == onDispose &&
        other.enableLog == enableLog &&
        other.logWriterCallback == logWriterCallback &&
        other.binds == binds &&
        other.transitionDuration == transitionDuration &&
        other.defaultGlobalState == defaultGlobalState &&
        listEquals(other.getPages, getPages) &&
        other.unknownRoute == unknownRoute &&
        other.routeInformationProvider == routeInformationProvider &&
        other.routeInformationParser == routeInformationParser &&
        other.routerDelegate == routerDelegate &&
        other.routerConfig == routerConfig &&
        other.backButtonDispatcher == backButtonDispatcher &&
        listEquals(other.navigatorObservers, navigatorObservers) &&
        other.navigatorKey == navigatorKey &&
        other.scaffoldMessengerKey == scaffoldMessengerKey &&
        mapEquals(other.translationsKeys, translationsKeys) &&
        other.translations == translations &&
        other.locale == locale &&
        other.fallbackLocale == fallbackLocale &&
        other.initialRoute == initialRoute &&
        other.customTransition == customTransition &&
        other.home == home &&
        other.testMode == testMode &&
        other.unikey == unikey &&
        other.theme == theme &&
        other.darkTheme == darkTheme &&
        other.themeMode == themeMode &&
        other.defaultPopGesture == defaultPopGesture &&
        other.defaultOpaqueRoute == defaultOpaqueRoute &&
        other.defaultTransitionDuration == defaultTransitionDuration &&
        other.defaultTransitionCurve == defaultTransitionCurve &&
        other.defaultDialogTransitionCurve == defaultDialogTransitionCurve &&
        other.defaultDialogTransitionDuration ==
            defaultDialogTransitionDuration &&
        other.routing == routing &&
        mapEquals(other.parameters, parameters);
  }

  @override
  int get hashCode {
    return routingCallback.hashCode ^
        defaultTransition.hashCode ^
        onInit.hashCode ^
        onReady.hashCode ^
        onDispose.hashCode ^
        enableLog.hashCode ^
        logWriterCallback.hashCode ^
        binds.hashCode ^
        transitionDuration.hashCode ^
        defaultGlobalState.hashCode ^
        getPages.hashCode ^
        unknownRoute.hashCode ^
        routeInformationProvider.hashCode ^
        routeInformationParser.hashCode ^
        routerDelegate.hashCode ^
        routerConfig.hashCode ^
        backButtonDispatcher.hashCode ^
        navigatorObservers.hashCode ^
        navigatorKey.hashCode ^
        scaffoldMessengerKey.hashCode ^
        translationsKeys.hashCode ^
        translations.hashCode ^
        locale.hashCode ^
        fallbackLocale.hashCode ^
        initialRoute.hashCode ^
        customTransition.hashCode ^
        home.hashCode ^
        testMode.hashCode ^
        unikey.hashCode ^
        theme.hashCode ^
        darkTheme.hashCode ^
        themeMode.hashCode ^
        defaultPopGesture.hashCode ^
        defaultOpaqueRoute.hashCode ^
        defaultTransitionDuration.hashCode ^
        defaultTransitionCurve.hashCode ^
        defaultDialogTransitionCurve.hashCode ^
        defaultDialogTransitionDuration.hashCode ^
        routing.hashCode ^
        parameters.hashCode;
  }
}

/// The underlying StatefulWidget serving as the structural anchor for all GetXify apps.
///
/// [GetRoot] intercepts configuration from `GetMaterialApp` and `GetCupertinoApp`,
/// processes the [ConfigData], initializes localization, translations, routing, and
/// theme systems before injecting them into the standard Flutter application widget.
class GetRoot extends StatefulWidget {
  const GetRoot({super.key, required this.config, required this.child});
  final ConfigData config;
  final Widget child;
  @override
  State<GetRoot> createState() => GetRootState();

  static bool get treeInitialized => GetRootState._controller != null;

  static GetRootState of(BuildContext context) {
    // Handles the case where the input context is a navigator element.
    GetRootState? root;
    if (context is StatefulElement && context.state is GetRootState) {
      root = context.state as GetRootState;
    }
    root = context.findRootAncestorStateOfType<GetRootState>() ?? root;
    assert(() {
      if (root == null) {
        throw FlutterError(
          'GetRoot operation requested with a context that does not include a GetRoot.\n'
          'The context used must be that of a '
          'widget that is a descendant of a GetRoot widget.',
        );
      }
      return true;
    }());
    return root!;
  }
}

class GetRootState extends State<GetRoot> with WidgetsBindingObserver {
  static GetRootState? _controller;

  /// Detached placeholder returned by [controller] before a [GetRoot] is
  /// inserted in the tree. It allows key-based APIs such as `Get.key` to be
  /// evaluated while the app widget is still being constructed (for example
  /// `GetMaterialApp(navigatorKey: Get.key)`), while any access that truly
  /// requires a mounted [GetRoot] keeps throwing a descriptive exception.
  static GetRootState? _detached;

  static GetRootState get controller =>
      _controller ?? (_detached ??= GetRootState());

  ConfigData? _config;

  ConfigData get config {
    final currentConfig = _config;
    if (currentConfig == null) {
      throw Exception('GetRoot is not part of the tree');
    }
    return currentConfig;
  }

  set config(ConfigData newConfig) => _config = newConfig;

  @override
  void initState() {
    config = widget.config;
    GetRootState._controller = this;
    Engine.instance.addObserver(this);
    onInit();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant GetRoot oldWidget) {
    final oldConfig = oldWidget.config;
    final newConfig = widget.config;
    if (oldConfig.theme != newConfig.theme && newConfig.theme != null) {
      config = config.copyWith(theme: newConfig.theme);
    }
    if (oldConfig.darkTheme != newConfig.darkTheme &&
        newConfig.darkTheme != null) {
      config = config.copyWith(darkTheme: newConfig.darkTheme);
    }
    if (oldConfig.themeMode != newConfig.themeMode &&
        newConfig.themeMode != null) {
      config = config.copyWith(themeMode: newConfig.themeMode);
    }
    if (oldConfig.locale != newConfig.locale && newConfig.locale != null) {
      Get.locale = newConfig.locale;
      config = config.copyWith(locale: newConfig.locale);
    }
    super.didUpdateWidget(oldWidget);
  }

  void onClose() {
    config.onDispose?.call();
    Get.clearTranslations();
    config.snackBarQueue.disposeControllers();

    Get.resetInstance(clearRouteBindings: true);
    _controller = null;
    Engine.instance.removeObserver(this);
  }

  @override
  void dispose() {
    onClose();
    super.dispose();
  }

  void onInit() {
    if (config.routerConfig == null) {
      if (config.getPages == null && config.home == null) {
        throw Exception('You need add pages or home');
      }

      if (config.routerDelegate == null) {
        final newDelegate = GetDelegate.createDelegate(
          pages:
              config.getPages ??
              [
                GetPage(
                  name: cleanRouteName("/${config.home.runtimeType}"),
                  page: () => config.home!,
                ),
              ],
          notFoundRoute: config.unknownRoute,
          navigatorKey: config.navigatorKey ?? _fallbackKey,
          navigatorObservers: (config.navigatorObservers == null
              ? <NavigatorObserver>[
                  GetObserver(config.routingCallback, Get.routing),
                ]
              : <NavigatorObserver>[
                  GetObserver(config.routingCallback, config.routing),
                  ...config.navigatorObservers!,
                ]),
        );
        config = config.copyWith(routerDelegate: newDelegate);
      }

      if (config.routeInformationParser == null) {
        final newRouteInformationParser =
            GetInformationParser.createInformationParser(
              initialRoute:
                  config.initialRoute ??
                  config.getPages?.first.name ??
                  cleanRouteName("/${config.home.runtimeType}"),
            );

        config = config.copyWith(
          routeInformationParser: newRouteInformationParser,
        );
      }

      final delegate = config.routerDelegate;
      if (config.routeInformationProvider == null && delegate is GetDelegate) {
        final newRouteInformationProvider = GetRouteInformationProvider(
          delegate,
          initialRouteInformation: RouteInformation(
            uri: Uri.parse(
              WidgetsBinding.instance.platformDispatcher.defaultRouteName,
            ),
          ),
        );

        config = config.copyWith(
          routeInformationProvider: newRouteInformationProvider,
        );
      }
    }

    if (config.locale != null) Get.locale = config.locale;

    if (config.fallbackLocale != null) {
      Get.fallbackLocale = config.fallbackLocale;
    }

    if (config.translations != null) {
      Get.addTranslations(config.translations!.keys);
    } else if (config.translationsKeys != null) {
      Get.addTranslations(config.translationsKeys!);
    }

    config.onInit?.call();

    Get.isLogEnable = config.enableLog ?? kDebugMode;
    Get.log = config.logWriterCallback ?? defaultLogWriterCallback;

    Future(() => onReady());
  }

  set parameters(Map<String, String?> newParameters) {
    config = config.copyWith(parameters: newParameters);
  }

  set testMode(bool isTest) {
    config = config.copyWith(testMode: isTest);
    GetTestMode.active = isTest;
  }

  void onReady() {
    config.onReady?.call();
  }

  /// The last locale this state applied automatically from the device.
  ///
  /// Used by [didChangeLocales] to distinguish a device-derived locale from
  /// one that was chosen explicitly (via `GetMaterialApp(locale:)` or
  /// `Get.updateLocale`), so system locale changes never clobber an explicit
  /// in-app language selection.
  Locale? _appliedDeviceLocale;

  /// Whether the app locale was chosen explicitly through `Get.updateLocale`.
  ///
  /// Once set, [didChangeLocales] stops following the device locale, even if
  /// the explicitly chosen locale happens to be identical to the last locale
  /// that was auto-applied from the device. Automatic device-locale adoption
  /// never sets this flag.
  bool localeSetExplicitly = false;

  @override
  void didChangeLocales(List<Locale>? locales) {
    Get.asap(() {
      final deviceLocale = Get.deviceLocale;
      if (deviceLocale == null) {
        return;
      }
      final appLocale = Get.locale;
      final followsDeviceLocale =
          !localeSetExplicitly &&
          config.locale == null &&
          (appLocale == null || appLocale == _appliedDeviceLocale);
      if (followsDeviceLocale) {
        _appliedDeviceLocale = deviceLocale;
        // Apply the device locale without going through Get.updateLocale,
        // so automatic adoption is never recorded as an explicit choice.
        Get.locale = deviceLocale;
        Get.forceAppUpdate();
      }
    });
  }

  void setTheme(ThemeData value) {
    if (config.darkTheme == null) {
      config = config.copyWith(theme: value);
    } else {
      if (value.brightness == Brightness.light) {
        config = config.copyWith(theme: value);
      } else {
        config = config.copyWith(darkTheme: value);
      }
    }
    update();
  }

  void setThemeMode(ThemeMode value) {
    config = config.copyWith(themeMode: value);
    update();
  }

  void restartApp() {
    config = config.copyWith(unikey: UniqueKey());
    update();
  }

  void update() {
    context.visitAncestorElements((element) {
      element.markNeedsBuild();
      return false;
    });
  }

  /// Shared navigator key handed out whenever no explicit key is available.
  ///
  /// It is static so that `Get.key` returns the same instance before and
  /// after [GetRoot] is mounted, which makes
  /// `GetMaterialApp(navigatorKey: Get.key)` safe to write.
  static final GlobalKey<NavigatorState> _fallbackKey =
      GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState> get key {
    final currentConfig = _config;
    if (currentConfig == null) {
      return _fallbackKey;
    }
    if (currentConfig.routerConfig != null) {
      return currentConfig.navigatorKey ?? _fallbackKey;
    }
    if (currentConfig.routerDelegate == null) {
      return currentConfig.navigatorKey ?? _fallbackKey;
    }
    return currentConfig.navigatorKey ?? rootDelegate.navigatorKey;
  }

  GetDelegate get rootDelegate => config.routerDelegate as GetDelegate;

  RouteInformationParser<Object> get informationParser =>
      config.routeInformationParser!;

  GlobalKey<NavigatorState>? addKey(GlobalKey<NavigatorState> newKey) {
    if (config.routerConfig == null && config.routerDelegate != null) {
      rootDelegate.navigatorKey = newKey;
    }
    return key;
  }

  final Map<String, GetDelegate> _keys = {};

  /// Public getter for nested delegate keys
  Map<String, GetDelegate> get keys => _keys;

  GetDelegate? nestedKey(String? key) {
    if (key == null) {
      if (config.routerConfig != null) return null;
      if (config.routerDelegate == null) return null;
      return rootDelegate;
    }
    _keys.putIfAbsent(
      key,
      () => GetDelegate(
        showHashOnUrl: true,
        pages: RouteDecoder.fromRoute(key).currentChildren ?? [],
      ),
    );
    return _keys[key];
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  String cleanRouteName(String name) {
    name = name.replaceAll('() => ', '');
    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return Uri.tryParse(name)?.toString() ?? name;
  }
}
