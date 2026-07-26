import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../../getxify.dart';

@immutable
class RouteDecoder {
  const RouteDecoder(this.currentTreeBranch, this.pageSettings);
  final List<GetPage> currentTreeBranch;
  final PageSettings? pageSettings;

  factory RouteDecoder.fromRoute(String location, {Object? arguments}) {
    var uri = Uri.parse(location);
    final args = PageSettings(uri, arguments);
    final decoder = (Get.rootController.rootDelegate).matchRoute(
      location,
      arguments: args,
    );
    decoder.route = decoder.route?.copyWith(
      completer: null,
      arguments: args,
      parameters: args.params,
    );
    return decoder;
  }

  GetPage? get route =>
      currentTreeBranch.isEmpty ? null : currentTreeBranch.last;

  GetPage routeOrUnknown(GetPage onUnknow) =>
      currentTreeBranch.isEmpty ? onUnknow : currentTreeBranch.last;

  set route(GetPage? getPage) {
    if (getPage == null) return;
    if (currentTreeBranch.isEmpty) {
      currentTreeBranch.add(getPage);
    } else {
      currentTreeBranch[currentTreeBranch.length - 1] = getPage;
    }
  }

  List<GetPage>? get currentChildren => route?.children;

  Map<String, String> get parameters => pageSettings?.params ?? {};

  Object? get args {
    return pageSettings?.arguments;
  }

  T? arguments<T>() {
    final args = pageSettings?.arguments;
    return args is T ? args : null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RouteDecoder &&
        listEquals(other.currentTreeBranch, currentTreeBranch) &&
        other.pageSettings == pageSettings;
  }

  @override
  int get hashCode => currentTreeBranch.hashCode ^ pageSettings.hashCode;

  @override
  String toString() =>
      'RouteDecoder(currentTreeBranch: $currentTreeBranch, pageSettings: $pageSettings)';
}

class ParseRouteTree {
  ParseRouteTree({required this.routes});

  final List<GetPage> routes;

  RouteDecoder matchRoute(String name, {PageSettings? arguments}) {
    final uri = Uri.parse(name);
    final split = uri.path.split('/').where((element) => element.isNotEmpty);
    var curPath = '/';
    final cumulativePaths = <String>['/'];
    for (var item in split) {
      if (curPath.endsWith('/')) {
        curPath += item;
      } else {
        curPath += '/$item';
      }
      cumulativePaths.add(curPath);
    }

    final treeBranch = cumulativePaths
        .map((e) => MapEntry(e, _findRoute(e)))
        .where((element) => element.value != null)
        ///Prevent page be disposed
        .map((e) => MapEntry(e.key, e.value!.copyWith(key: ValueKey(e.key))))
        .toList();

    final params = Map<String, String>.from(uri.queryParameters);
    if (treeBranch.isNotEmpty && treeBranch.last.key == cumulativePaths.last) {
      //route is found, do further parsing to get nested query params
      final lastRoute = treeBranch.last;
      final parsedParams = _parseParams(name, lastRoute.value.name);
      if (parsedParams.isNotEmpty) {
        params.addAll(parsedParams);
      }
      //copy parameters to all pages.
      final mappedTreeBranch = treeBranch
          .map(
            (e) => e.value.copyWith(
              parameters: {
                if (e.value.parameters != null) ...e.value.parameters!,
                ...params,
              },
              name: e.key,
            ),
          )
          .toList();
      arguments?.params.clear();
      arguments?.params.addAll(params);
      return RouteDecoder(mappedTreeBranch, arguments);
    }

    arguments?.params.clear();
    arguments?.params.addAll(params);

    //route not found
    return RouteDecoder([], arguments);
  }

  void addRoutes<T>(List<GetPage<T>> getPages) {
    for (final route in getPages) {
      addRoute(route);
    }
  }

  void removeRoutes<T>(List<GetPage<T>> getPages) {
    for (final route in getPages) {
      removeRoute(route);
    }
  }

  void removeRoute<T>(GetPage<T> route) {
    routes.remove(route);
    for (final page in _flattenPage(route)) {
      routes.remove(page);
    }
  }

  void addRoute<T>(GetPage<T> route) {
    routes.add(route);

    // Add Page children.
    for (final page in _flattenPage(route)) {
      routes.add(page);
    }
  }

  /// The middlewares declared directly on the page each flattened child
  /// page was created from, keyed by the flattened instance stored in
  /// [routes].
  ///
  /// Flattened child pages carry the merged middleware list of their whole
  /// ancestor chain so that redirects and guards are inherited, but page
  /// lifecycle callbacks ([GetMiddleware.onBindingsStart],
  /// [GetMiddleware.onPageBuildStart], [GetMiddleware.onPageBuilt] and
  /// [GetMiddleware.onPageDispose]) must only run on the route of the page
  /// that declared the middleware. This registry keeps the declared subset
  /// retrievable through [ownMiddlewaresOf].
  final Expando<List<GetMiddleware>> _ownMiddlewares =
      Expando<List<GetMiddleware>>();

  /// Returns the middlewares declared directly on the registered page
  /// matching [name], excluding middlewares inherited from ancestor pages
  /// during route-tree flattening, or `null` when no registered page
  /// matches [name].
  List<GetMiddleware>? ownMiddlewaresOf(String name) {
    final route = _findRoute(name);
    if (route == null) return null;
    return _ownMiddlewares[route] ?? route.middlewares;
  }

  /// Maps every binding instance carried by the leaf of [branch] (a tree
  /// branch as produced by [matchRoute]) to the name of the page that
  /// declared it.
  ///
  /// Route-tree flattening merges each page's bindings into all of its
  /// descendants ([_flattenChildren]), so a page's binding list is its
  /// parent's merged list followed by its own declarations. This walks that
  /// prefix structure to attribute each binding to the branch page that
  /// declared it, letting a route report dependencies registered by an
  /// inherited (ancestor) binding against the ancestor's route instead of
  /// its own — a deep link to a nested page must not take ownership of its
  /// ancestors' controllers.
  ///
  /// Bindings that do not follow the prefix structure (e.g. added by
  /// `onBindingsStart` later, or a list not produced by the flattening) are
  /// simply absent from the result and treated as declared by the page
  /// running them.
  static Map<BindingsInterface, String> bindingOwnersOf(List<GetPage> branch) {
    final owners = LinkedHashMap<BindingsInterface, String>.identity();
    if (branch.isEmpty) return owners;

    // The branch root is a page as declared (never flattened): its own
    // declarations are its `binding` field plus its `bindings` list, and
    // both were folded — `binding` first — into every descendant's merged
    // list by the flattening.
    final root = branch.first;
    final rootBinding = root.binding;
    if (rootBinding != null) {
      owners.putIfAbsent(rootBinding, () => root.name);
    }
    for (final binding in root.bindings) {
      owners.putIfAbsent(binding, () => root.name);
    }
    var prefixLength = (rootBinding != null ? 1 : 0) + root.bindings.length;

    for (final page in branch.skip(1)) {
      final bindings = page.bindings;
      if (bindings.length < prefixLength) break;
      for (var i = prefixLength; i < bindings.length; i++) {
        owners.putIfAbsent(bindings[i], () => page.name);
      }
      prefixLength = bindings.length;
    }
    return owners;
  }

  /// Returns every descendant of [route] as a flat list of pages whose
  /// names are the cumulative paths of their ancestor chain and whose
  /// middleware, binding and bind lists include the entries inherited from
  /// every ancestor (ancestors first), each descendant appearing exactly
  /// once.
  List<GetPage> _flattenPage(GetPage route) {
    final result = <GetPage>[];
    if (route.children.isEmpty) {
      return result;
    }

    _flattenChildren(
      route,
      route.name,
      route.middlewares,
      [if (route.binding != null) route.binding!, ...route.bindings],
      route.binds,
      result,
    );
    return result;
  }

  void _flattenChildren(
    GetPage parent,
    String parentPath,
    List<GetMiddleware> inheritedMiddlewares,
    List<BindingsInterface> inheritedBindings,
    List<Bind> inheritedBinds,
    List<GetPage> result,
  ) {
    for (final child in parent.children) {
      final middlewares = [...inheritedMiddlewares, ...child.middlewares];
      final bindings = [
        ...inheritedBindings,
        if (child.binding != null) child.binding!,
        ...child.bindings,
      ];
      final binds = [...inheritedBinds, ...child.binds];

      final flattened = _addChild(
        child,
        parentPath,
        middlewares,
        bindings,
        binds,
      );
      _ownMiddlewares[flattened] = child.middlewares;
      result.add(flattened);

      _flattenChildren(
        child,
        flattened.name,
        middlewares,
        bindings,
        binds,
        result,
      );
    }
  }

  /// Change the Path for a [GetPage]
  GetPage _addChild(
    GetPage origin,
    String parentPath,
    List<GetMiddleware> middlewares,
    List<BindingsInterface> bindings,
    List<Bind> binds,
  ) {
    return origin.copyWith(
      middlewares: middlewares,
      name: origin.inheritParentPath
          ? (parentPath + origin.name).replaceAll(r'//', '/')
          : origin.name,
      bindings: bindings,
      binds: binds,
      // key:
    );
  }

  GetPage? _findRoute(String name) {
    final uri = Uri.parse(name);
    final value = routes.firstWhereOrNull(
      (route) => _matchesPath(route.name, uri.path),
    );

    return value;
  }

  bool _matchesPath(String routeName, String path) {
    final routeSegments = Uri.parse(routeName).pathSegments;
    final pathSegments = Uri.parse(path).pathSegments;

    if (routeSegments.length != pathSegments.length) return false;

    for (var i = 0; i < routeSegments.length; i++) {
      final routeSegment = routeSegments[i];
      if (routeSegment.startsWith(':')) continue;
      if (routeSegment != pathSegments[i]) return false;
    }
    return true;
  }

  Map<String, String> _parseParams(String path, String routeName) {
    final params = <String, String>{};
    final uri = Uri.tryParse(path);
    if (uri == null) return params;
    if (path.contains('?')) {
      params.addAll(uri.queryParameters);
    }

    final routeSegments = Uri.parse(routeName).pathSegments;
    final pathSegments = uri.pathSegments;

    for (var i = 0; i < routeSegments.length; i++) {
      if (i < pathSegments.length) {
        final routeSegment = routeSegments[i];
        if (routeSegment.startsWith(':')) {
          params[routeSegment.substring(1)] = Uri.decodeQueryComponent(
            pathSegments[i],
          );
        }
      }
    }
    return params;
  }
}
