import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../get_core/get_core.dart';
import '../../../get_instance/get_instance.dart';
import '../../../get_state_manager/get_state_manager.dart';
import '../../../get_utils/get_utils.dart';
import '../../get_navigation.dart';
import 'get_root.dart';

/// A fully customized [CupertinoApp] designed to be the entry point for GetXify applications.
///
/// It extends [CupertinoApp] capabilities by seamlessly integrating:
/// * **Routing:** Built-in declarative routing via [getPages] or standard [routes].
/// * **State Management:** Dependency injection configuration using [binds].
/// * **Localization:** Simple language setup with [translations] and [locale].
///
/// Use [GetCupertinoApp.router] to construct an app using the Router API,
/// supplying a [routerConfig] or custom [routerDelegate].
class GetCupertinoApp extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  final Widget? home;
  final Map<String, WidgetBuilder>? routes;
  final String? initialRoute;
  final RouteFactory? onGenerateRoute;
  final InitialRouteListFactory? onGenerateInitialRoutes;
  final RouteFactory? onUnknownRoute;
  final List<NavigatorObserver>? navigatorObservers;
  final TransitionBuilder? builder;
  final String title;
  final GenerateAppTitle? onGenerateTitle;
  final CustomTransition? customTransition;
  final Color? color;
  final Map<String, Map<String, String>>? translationsKeys;
  final Translations? translations;
  final TextDirection? textDirection;
  final Locale? locale;
  final Locale? fallbackLocale;
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final LocaleListResolutionCallback? localeListResolutionCallback;
  final LocaleResolutionCallback? localeResolutionCallback;
  final Iterable<Locale> supportedLocales;
  final bool showPerformanceOverlay;
  final bool checkerboardRasterCacheImages;
  final bool checkerboardOffscreenLayers;
  final bool showSemanticsDebugger;
  final bool debugShowCheckedModeBanner;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final Function(Routing?)? routingCallback;
  final Transition? defaultTransition;
  final bool? opaqueRoute;
  final VoidCallback? onInit;
  final VoidCallback? onReady;
  final VoidCallback? onDispose;
  final bool? enableLog;
  final LogWriterCallback? logWriterCallback;
  final bool? popGesture;

  final BindingsInterface? initialBinding;
  final Duration? transitionDuration;
  final bool? defaultGlobalState;
  final List<GetPage>? getPages;
  final GetPage? unknownRoute;
  final RouteInformationProvider? routeInformationProvider;
  final RouteInformationParser<Object>? routeInformationParser;
  final RouterDelegate<Object>? routerDelegate;
  final RouterConfig<Object>? routerConfig;
  final BackButtonDispatcher? backButtonDispatcher;
  final CupertinoThemeData? theme;
  final bool useInheritedMediaQuery;
  final List<Bind> binds;
  final ScrollBehavior? scrollBehavior;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;

  /// The identifier to use for state restoration of this app.
  ///
  /// Forwarded to [CupertinoApp.restorationScopeId]. Providing a non-null
  /// value enables state restoration for the application.
  final String? restorationScopeId;

  /// Creates a [GetCupertinoApp] instance for a standard GetX application.
  ///
  /// You can use [home] to set the main entry widget, or provide a list of [getPages]
  /// with an [initialRoute] to utilize the GetX declarative routing system.
  const GetCupertinoApp({
    super.key,
    this.theme,
    this.navigatorKey,
    this.home,
    Map<String, Widget Function(BuildContext)> this.routes =
        const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onGenerateInitialRoutes,
    this.onUnknownRoute,
    List<NavigatorObserver> this.navigatorObservers =
        const <NavigatorObserver>[],
    this.builder,
    this.translationsKeys,
    this.translations,
    this.textDirection,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.customTransition,
    this.onInit,
    this.onDispose,
    this.locale,
    this.binds = const [],
    this.scrollBehavior,
    this.scaffoldMessengerKey,
    this.fallbackLocale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,

    this.initialBinding,
    this.useInheritedMediaQuery = false,
    this.unknownRoute,
    this.routingCallback,
    this.defaultTransition,
    this.onReady,
    this.getPages,
    this.opaqueRoute,
    this.enableLog = kDebugMode,
    this.logWriterCallback,
    this.popGesture,
    this.transitionDuration,
    this.defaultGlobalState,
    this.restorationScopeId,
  }) : routeInformationProvider = null,
       backButtonDispatcher = null,
       routeInformationParser = null,
       routerDelegate = null,
       routerConfig = null;

  /// Creates a [GetCupertinoApp] that uses the standard Flutter Router API.
  ///
  /// You can use [routerConfig] to provide a fully configured router, or
  /// use legacy Router properties like [routerDelegate] and [routeInformationParser].
  /// Note: [routerConfig] is mutually exclusive with [routerDelegate] and other legacy properties.
  const GetCupertinoApp.router({
    super.key,
    this.theme,
    this.routeInformationProvider,
    this.routeInformationParser,
    this.routerDelegate,
    this.routerConfig,
    this.backButtonDispatcher,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.useInheritedMediaQuery = false,
    this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.binds = const [],
    this.scrollBehavior,
    this.scaffoldMessengerKey,
    this.customTransition,
    this.translationsKeys,
    this.translations,
    this.textDirection,
    this.fallbackLocale,
    this.routingCallback,
    this.defaultTransition,
    this.opaqueRoute,
    this.onInit,
    this.onReady,
    this.onDispose,
    this.enableLog = kDebugMode,
    this.logWriterCallback,
    this.popGesture,

    this.initialBinding,
    this.transitionDuration,
    this.defaultGlobalState,
    this.getPages,
    this.navigatorObservers,
    this.unknownRoute,
    this.restorationScopeId,
  }) : navigatorKey = null,
       onGenerateRoute = null,
       home = null,
       onGenerateInitialRoutes = null,
       onUnknownRoute = null,
       routes = null,
       initialRoute = null;

  @override
  Widget build(BuildContext context) {
    return GetRoot(
      config: ConfigData(
        backButtonDispatcher: backButtonDispatcher,
        scaffoldMessengerKey: scaffoldMessengerKey,
        binds: binds,
        customTransition: customTransition,
        defaultGlobalState: defaultGlobalState,
        defaultTransition: defaultTransition,
        enableLog: enableLog,
        fallbackLocale: fallbackLocale,
        getPages: getPages,
        home: home,
        initialRoute: initialRoute,
        locale: locale,
        logWriterCallback: logWriterCallback,
        navigatorKey: navigatorKey,
        navigatorObservers: navigatorObservers,
        onDispose: onDispose,
        onInit: onInit,
        onReady: onReady,
        routeInformationParser: routeInformationParser,
        routeInformationProvider: routeInformationProvider,
        routerDelegate: routerDelegate,
        routerConfig: routerConfig,
        routingCallback: routingCallback,
        transitionDuration: transitionDuration,
        translations: translations,
        translationsKeys: translationsKeys,
        unknownRoute: unknownRoute,
        defaultPopGesture: popGesture,
      ),
      child: Builder(
        builder: (context) {
          final controller = GetRoot.of(context);

          // Use regular CupertinoApp when getPages is null to support imperative navigation
          // with proper secondary animations
          if (controller.config.getPages == null &&
              controller.config.routerConfig == null &&
              controller.config.routerDelegate == null) {
            return CupertinoApp(
              key: controller.config.unikey,
              navigatorKey: controller.config.navigatorKey,
              home: controller.config.home,
              routes: routes ?? const {},
              initialRoute: initialRoute,
              onGenerateRoute: onGenerateRoute,
              onGenerateInitialRoutes: onGenerateInitialRoutes,
              onUnknownRoute: onUnknownRoute,
              builder: (context, child) {
                final effectiveBuilder = builder;
                return Directionality(
                  textDirection:
                      textDirection ??
                      (rtlLanguages.contains(Get.locale?.languageCode)
                          ? TextDirection.rtl
                          : TextDirection.ltr),
                  child: effectiveBuilder == null
                      ? (child ?? const Material())
                      : effectiveBuilder(context, child ?? const Material()),
                );
              },
              title: title,
              onGenerateTitle: onGenerateTitle,
              color: color,
              theme: theme,
              locale: Get.locale ?? locale,
              localizationsDelegates: localizationsDelegates,
              localeListResolutionCallback: localeListResolutionCallback,
              localeResolutionCallback: localeResolutionCallback,
              supportedLocales: supportedLocales,
              showPerformanceOverlay: showPerformanceOverlay,
              checkerboardRasterCacheImages: checkerboardRasterCacheImages,
              checkerboardOffscreenLayers: checkerboardOffscreenLayers,
              showSemanticsDebugger: showSemanticsDebugger,
              debugShowCheckedModeBanner: debugShowCheckedModeBanner,
              shortcuts: shortcuts,
              scrollBehavior: scrollBehavior,
              restorationScopeId: restorationScopeId,
            );
          }

          return controller.config.routerConfig != null
              ? CupertinoApp.router(
                  routerConfig: controller.config.routerConfig,
                  key: controller.config.unikey,
                  builder: (context, child) {
                    final effectiveBuilder = builder;
                    return Directionality(
                      textDirection:
                          textDirection ??
                          (rtlLanguages.contains(Get.locale?.languageCode)
                              ? TextDirection.rtl
                              : TextDirection.ltr),
                      child: effectiveBuilder == null
                          ? (child ?? const Material())
                          : effectiveBuilder(
                              context,
                              child ?? const Material(),
                            ),
                    );
                  },
                  title: title,
                  onGenerateTitle: onGenerateTitle,
                  color: color,
                  theme: theme,
                  locale: Get.locale ?? locale,
                  localizationsDelegates: localizationsDelegates,
                  localeListResolutionCallback: localeListResolutionCallback,
                  localeResolutionCallback: localeResolutionCallback,
                  supportedLocales: supportedLocales,
                  showPerformanceOverlay: showPerformanceOverlay,
                  checkerboardRasterCacheImages: checkerboardRasterCacheImages,
                  checkerboardOffscreenLayers: checkerboardOffscreenLayers,
                  showSemanticsDebugger: showSemanticsDebugger,
                  debugShowCheckedModeBanner: debugShowCheckedModeBanner,
                  shortcuts: shortcuts,
                  scrollBehavior: scrollBehavior,
                  restorationScopeId: restorationScopeId,
                )
              : CupertinoApp.router(
                  routerDelegate: controller.config.routerDelegate,
                  routeInformationParser:
                      controller.config.routeInformationParser,
                  backButtonDispatcher: backButtonDispatcher,
                  routeInformationProvider:
                      controller.config.routeInformationProvider,
                  key: controller.config.unikey,
                  builder: (context, child) {
                    final effectiveBuilder = builder;
                    return Directionality(
                      textDirection:
                          textDirection ??
                          (rtlLanguages.contains(Get.locale?.languageCode)
                              ? TextDirection.rtl
                              : TextDirection.ltr),
                      child: effectiveBuilder == null
                          ? (child ?? const Material())
                          : effectiveBuilder(
                              context,
                              child ?? const Material(),
                            ),
                    );
                  },
                  title: title,
                  onGenerateTitle: onGenerateTitle,
                  color: color,
                  theme: theme,
                  locale: Get.locale ?? locale,
                  localizationsDelegates: localizationsDelegates,
                  localeListResolutionCallback: localeListResolutionCallback,
                  localeResolutionCallback: localeResolutionCallback,
                  supportedLocales: supportedLocales,
                  showPerformanceOverlay: showPerformanceOverlay,
                  checkerboardRasterCacheImages: checkerboardRasterCacheImages,
                  checkerboardOffscreenLayers: checkerboardOffscreenLayers,
                  showSemanticsDebugger: showSemanticsDebugger,
                  debugShowCheckedModeBanner: debugShowCheckedModeBanner,
                  shortcuts: shortcuts,
                  scrollBehavior: scrollBehavior,
                  restorationScopeId: restorationScopeId,
                );
        },
      ),
    );
  }
}
