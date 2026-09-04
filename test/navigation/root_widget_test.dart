import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

void main() {
  testWidgets("GetMaterialApp builds with home successfully", (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: Scaffold(body: Text('Home Page'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home Page'), findsOneWidget);
  });

  testWidgets("GetMaterialApp builds with routerConfig successfully", (
    tester,
  ) async {
    final GoRouter router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Router Home')),
        ),
      ],
    );

    await tester.pumpWidget(GetMaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Router Home'), findsOneWidget);
  });
}

// Simple mock for GoRouter-like structure to avoid external dependencies
class GoRouter implements RouterConfig<Object> {
  GoRouter({required this.routes});
  final List<GoRoute> routes;

  @override
  BackButtonDispatcher? get backButtonDispatcher => RootBackButtonDispatcher();

  @override
  RouteInformationParser<Object>? get routeInformationParser => _MockParser();

  @override
  RouteInformationProvider? get routeInformationProvider => _MockProvider();

  @override
  RouterDelegate<Object> get routerDelegate => _MockDelegate(routes);
}

class GoRoute {
  GoRoute({required this.path, required this.builder});
  final String path;
  final Widget Function(BuildContext, Object) builder;
}

class _MockParser extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return routeInformation.uri.path;
  }
}

class _MockProvider extends RouteInformationProvider {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  RouteInformation get value => RouteInformation(uri: Uri.parse('/'));
}

class _MockDelegate extends RouterDelegate<Object> with ChangeNotifier {
  _MockDelegate(this.routes);
  final List<GoRoute> routes;

  @override
  Widget build(BuildContext context) {
    return routes.first.builder(context, Object());
  }

  @override
  Future<bool> popRoute() async => true;

  @override
  Future<void> setNewRoutePath(Object configuration) async {}
}
