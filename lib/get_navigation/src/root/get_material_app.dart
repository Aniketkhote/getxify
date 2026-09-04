import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:getxify/get_core/get_core.dart';

import '../../../get_state_manager/get_state_manager.dart';
import '../../../get_utils/get_utils.dart';
import '../../get_navigation.dart';
import 'get_root.dart';

/// A fully customized [MaterialApp] designed to be the entry point for GetXify applications.
///
/// It extends [MaterialApp] capabilities by seamlessly integrating:
/// * **Routing:** Built-in declarative routing via [getPages] or standard [routes].
/// * **State Management:** Dependency injection configuration using [binds].
/// * **Theming:** Dynamic theme swapping and transition management.
/// * **Localization:** Simple language setup with [translations] and [locale].
///
/// Use [GetMaterialApp.router] to construct an app using the Router API,
/// supplying a [routerConfig] or custom [routerDelegate].
class GetMaterialApp extends StatelessWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey;
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
  final ThemeData? theme;
  final ThemeData? darkTheme;
  final ThemeMode themeMode;
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
  final ScrollBehavior? scrollBehavior;
  final ThemeData? highContrastTheme;
  final ThemeData? highContrastDarkTheme;
  final Map<Type, Action<Intent>>? actions;
  final bool debugShowMaterialGrid;
  final ValueChanged<Routing?>? routingCallback;
  final Transition? defaultTransition;
  final bool? opaqueRoute;
  final VoidCallback? onInit;
  final VoidCallback? onReady;
  final VoidCallback? onDispose;
  final bool? enableLog;
  final LogWriterCallback? logWriterCallback;
  final bool? popGesture;

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
  final bool useInheritedMediaQuery;

  /// The identifier to use for state restoration of this app.
  ///
  /// Forwarded to [MaterialApp.restorationScopeId]. Providing a non-null
  /// value enables state restoration for the application.
  final String? restorationScopeId;

  /// Creates a [GetMaterialApp] instance for a standard GetX application.
  ///
  /// You can use [home] to set the main entry widget, or provide a list of [getPages]
  /// with an [initialRoute] to utilize the GetX declarative routing system.
  const GetMaterialApp({
    super.key,
    this.navigatorKey,
    this.scaffoldMessengerKey,
    this.home,
    Map<String, Widget Function(BuildContext)> this.routes =
        const <String, WidgetBuilder>{},
    this.initialRoute,
    this.onGenerateRoute,
    this.onGenerateInitialRoutes,
    this.onUnknownRoute,
    this.useInheritedMediaQuery = false,
    List<NavigatorObserver> this.navigatorObservers =
        const <NavigatorObserver>[],
    this.builder,
    this.textDirection,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.theme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.locale,
    this.fallbackLocale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.scrollBehavior,
    this.customTransition,
    this.translationsKeys,
    this.translations,
    this.onInit,
    this.onReady,
    this.onDispose,
    this.routingCallback,
    this.defaultTransition,
    this.getPages,
    this.opaqueRoute,
    this.enableLog = kDebugMode,
    this.logWriterCallback,
    this.popGesture,
    this.transitionDuration,
    this.defaultGlobalState,

    this.binds = const [],
    this.unknownRoute,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.actions,
    this.restorationScopeId,
  }) : routeInformationProvider = null,
       backButtonDispatcher = null,
       routeInformationParser = null,
       routerDelegate = null,
       routerConfig = null;

  /// Creates a [GetMaterialApp] that uses the standard Flutter Router API.
  ///
  /// You can use [routerConfig] to provide a fully configured router, or
  /// use legacy Router properties like [routerDelegate] and [routeInformationParser].
  /// Note: [routerConfig] is mutually exclusive with [routerDelegate] and other legacy properties.
  const GetMaterialApp.router({
    super.key,
    this.routeInformationProvider,
    this.scaffoldMessengerKey,
    this.routeInformationParser,
    this.routerDelegate,
    this.routerConfig,
    this.backButtonDispatcher,
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.color,
    this.theme,
    this.darkTheme,
    this.useInheritedMediaQuery = false,
    this.highContrastTheme,
    this.highContrastDarkTheme,
    this.themeMode = ThemeMode.system,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.debugShowMaterialGrid = false,
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowCheckedModeBanner = true,
    this.shortcuts,
    this.scrollBehavior,
    this.actions,
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

    this.binds = const [],
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
        scaffoldMessengerKey: scaffoldMessengerKey,
        transitionDuration: transitionDuration,
        translations: translations,
        translationsKeys: translationsKeys,
        unknownRoute: unknownRoute,
        theme: theme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        defaultPopGesture: popGesture,
      ),
      child: Builder(
        builder: (context) {
          final controller = GetRoot.of(context);

          // Use regular MaterialApp when getPages is null to support imperative navigation
          // with proper secondary animations
          if (controller.config.getPages == null &&
              controller.config.routerConfig == null &&
              controller.config.routerDelegate == null) {
            return MaterialApp(
              key: controller.config.unikey,
              navigatorKey: controller.config.navigatorKey,
              scaffoldMessengerKey: controller.config.scaffoldMessengerKey,
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
              theme: controller.config.theme ?? ThemeData.fallback(),
              darkTheme:
                  controller.config.darkTheme ??
                  controller.config.theme ??
                  ThemeData.fallback(),
              themeMode: controller.config.themeMode,
              locale: Get.locale ?? locale,
              localizationsDelegates: localizationsDelegates,
              localeListResolutionCallback: localeListResolutionCallback,
              localeResolutionCallback: localeResolutionCallback,
              supportedLocales: supportedLocales,
              debugShowMaterialGrid: debugShowMaterialGrid,
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
              ? MaterialApp.router(
                  routerConfig: controller.config.routerConfig,
                  key: controller.config.unikey,
                  builder: (context, child) => Directionality(
                    textDirection:
                        textDirection ??
                        (rtlLanguages.contains(Get.locale?.languageCode)
                            ? TextDirection.rtl
                            : TextDirection.ltr),
                    child: builder == null
                        ? (child ?? const Material())
                        : builder!(context, child ?? const Material()),
                  ),
                  title: title,
                  onGenerateTitle: onGenerateTitle,
                  color: color,
                  theme: controller.config.theme ?? ThemeData.fallback(),
                  darkTheme:
                      controller.config.darkTheme ??
                      controller.config.theme ??
                      ThemeData.fallback(),
                  themeMode: controller.config.themeMode,
                  locale: Get.locale ?? locale,
                  scaffoldMessengerKey: controller.config.scaffoldMessengerKey,
                  localizationsDelegates: localizationsDelegates,
                  localeListResolutionCallback: localeListResolutionCallback,
                  localeResolutionCallback: localeResolutionCallback,
                  supportedLocales: supportedLocales,
                  debugShowMaterialGrid: debugShowMaterialGrid,
                  showPerformanceOverlay: showPerformanceOverlay,
                  checkerboardRasterCacheImages: checkerboardRasterCacheImages,
                  checkerboardOffscreenLayers: checkerboardOffscreenLayers,
                  showSemanticsDebugger: showSemanticsDebugger,
                  debugShowCheckedModeBanner: debugShowCheckedModeBanner,
                  shortcuts: shortcuts,
                  scrollBehavior: scrollBehavior,
                  restorationScopeId: restorationScopeId,
                )
              : MaterialApp.router(
                  routerDelegate: controller.config.routerDelegate,
                  routeInformationParser:
                      controller.config.routeInformationParser,
                  backButtonDispatcher: backButtonDispatcher,
                  routeInformationProvider:
                      controller.config.routeInformationProvider,
                  key: controller.config.unikey,
                  builder: (context, child) => Directionality(
                    textDirection:
                        textDirection ??
                        (rtlLanguages.contains(Get.locale?.languageCode)
                            ? TextDirection.rtl
                            : TextDirection.ltr),
                    child: builder == null
                        ? (child ?? const Material())
                        : builder!(context, child ?? const Material()),
                  ),
                  title: title,
                  onGenerateTitle: onGenerateTitle,
                  color: color,
                  theme: controller.config.theme ?? ThemeData.fallback(),
                  darkTheme:
                      controller.config.darkTheme ??
                      controller.config.theme ??
                      ThemeData.fallback(),
                  themeMode: controller.config.themeMode,
                  locale: Get.locale ?? locale,
                  scaffoldMessengerKey: controller.config.scaffoldMessengerKey,
                  localizationsDelegates: localizationsDelegates,
                  localeListResolutionCallback: localeListResolutionCallback,
                  localeResolutionCallback: localeResolutionCallback,
                  supportedLocales: supportedLocales,
                  debugShowMaterialGrid: debugShowMaterialGrid,
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
