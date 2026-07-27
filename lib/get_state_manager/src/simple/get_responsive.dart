import 'package:flutter/widgets.dart';

import '../../../getxify.dart';

/// Mixin that provides responsive building capabilities.
///
/// This mixin allows widgets to build different UI based on the
/// screen type (desktop, tablet, phone, watch). It provides methods
/// to build specific UI for each screen type.
mixin GetResponsiveMixin on Widget {
  /// The responsive screen information.
  ResponsiveScreen get screen;

  /// Whether to always use the [builder] method.
  bool get alwaysUseBuilder;

  @protected
  Widget build(BuildContext context) {
    screen.context = context;
    Widget? widget;
    if (alwaysUseBuilder) {
      widget = builder();
      if (widget != null) return widget;
    }
    if (screen.isDesktop) {
      widget = desktop() ?? widget;
      if (widget != null) return widget;
    }
    if (screen.isTablet) {
      widget = tablet() ?? desktop();
      if (widget != null) return widget;
    }
    if (screen.isPhone) {
      widget = phone() ?? tablet() ?? desktop();
      if (widget != null) return widget;
    }
    return watch() ?? phone() ?? tablet() ?? desktop() ?? builder()!;
  }

  /// Builds the widget using the builder method.
  Widget? builder() => null;

  /// Builds the widget for desktop screens.
  Widget? desktop() => null;

  /// Builds the widget for phone screens.
  Widget? phone() => null;

  /// Builds the widget for tablet screens.
  Widget? tablet() => null;

  /// Builds the widget for watch screens.
  Widget? watch() => null;
}

/// A responsive view that extends [GetView] with responsive capabilities.
///
/// This widget provides the `screen` property that contains all
/// information about the screen size and type. You have two options
/// to build it:
/// 1. Use the `builder` method to return the widget to build
/// 2. Use the specific methods `desktop`, `tablet`, `phone`, `watch`
///    which will be called when the screen type matches
///
/// Note: If you use the specific methods, set `alwaysUseBuilder` to false.
class GetResponsiveView<T> extends GetView<T> with GetResponsiveMixin {
  @override
  final bool alwaysUseBuilder;

  @override
  final ResponsiveScreen screen;

  GetResponsiveView({
    this.alwaysUseBuilder = false,
    ResponsiveScreenSettings settings = const ResponsiveScreenSettings(),
    super.key,
  }) : screen = ResponsiveScreen(settings);
}

/// Settings for responsive screen breakpoints.
///
/// This class defines the width thresholds for different screen types.
class ResponsiveScreenSettings {
  /// When the width is greater than this value, the display will be set as [ScreenType.desktop].
  final double desktopChangePoint;

  /// When the width is greater than this value, the display will be set as [ScreenType.tablet],
  /// or when width is greater than [watchChangePoint] and smaller than this value,
  /// the display will be [ScreenType.phone].
  final double tabletChangePoint;

  /// When the width is smaller than this value, the display will be set as [ScreenType.watch],
  /// or when width is greater than this value and smaller than [tabletChangePoint],
  /// the display will be [ScreenType.phone].
  final double watchChangePoint;

  const ResponsiveScreenSettings({
    this.desktopChangePoint = 1200,
    this.tabletChangePoint = 600,
    this.watchChangePoint = 300,
  });
}

/// Provides information about the current screen.
///
/// This class determines the screen type based on the device width
/// and the configured breakpoints.
class ResponsiveScreen {
  late BuildContext context;
  final ResponsiveScreenSettings settings;

  late bool _isPlatformDesktop;

  /// Creates a new [ResponsiveScreen] with the given settings.
  ResponsiveScreen(this.settings) {
    _isPlatformDesktop = GetPlatform.isDesktop;
  }

  /// The height of the screen.
  double get height => context.height;

  /// The width of the screen.
  double get width => context.width;

  /// Whether the screen type is [ScreenType.desktop].
  bool get isDesktop => (screenType == ScreenType.desktop);

  /// Whether the screen type is [ScreenType.tablet].
  bool get isTablet => (screenType == ScreenType.tablet);

  /// Whether the screen type is [ScreenType.phone].
  bool get isPhone => (screenType == ScreenType.phone);

  /// Whether the screen type is [ScreenType.watch].
  bool get isWatch => (screenType == ScreenType.watch);

  /// Gets the device width, accounting for platform differences.
  double get _getDeviceWidth {
    if (_isPlatformDesktop) {
      return width;
    }
    return context.mediaQueryShortestSide;
  }

  /// The current screen type based on the device width.
  ScreenType get screenType {
    final deviceWidth = _getDeviceWidth;
    if (deviceWidth >= settings.desktopChangePoint) return ScreenType.desktop;
    if (deviceWidth >= settings.tabletChangePoint) return ScreenType.tablet;
    if (deviceWidth < settings.watchChangePoint) return ScreenType.watch;
    return ScreenType.phone;
  }

  /// Returns a value based on the current screen type.
  ///
  /// If the [screenType] is [ScreenType.desktop] and `desktop` is null,
  /// the `tablet` value will be returned. If `tablet` is also null,
  /// the `mobile` value will be returned, and so on.
  T? responsiveValue<T>({T? mobile, T? tablet, T? desktop, T? watch}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    if (isPhone && mobile != null) return mobile;
    return watch;
  }
}

/// Enum representing different screen types.
enum ScreenType { watch, phone, tablet, desktop }
