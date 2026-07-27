// used to make GetDelegate.runMiddleware recurse forever, hanging the
// navigation. The delegate must detect the cycle and degrade to the
// not-found route, mirroring PageRedirect.getPageToRoute's guard.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class RedirectToSecond extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      const RouteSettings(name: '/second');
}

class RedirectToFirst extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) => const RouteSettings(name: '/first');
}

void main() {
  tearDown(() {
    Get.reset();
  });

  testWidgets('mutual middleware redirects settle on the not-found route', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        unknownRoute: GetPage(name: '/404', page: () => const Text('lost')),
        getPages: [
          GetPage(name: '/', page: () => const Text('home')),
          GetPage(
            name: '/first',
            page: () => const Text('first'),
            middlewares: [RedirectToSecond()],
          ),
          GetPage(
            name: '/second',
            page: () => const Text('second'),
            middlewares: [RedirectToFirst()],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    Get.toNamed('/first');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/404');
    expect(find.text('lost'), findsOneWidget);
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsNothing);
  });

  testWidgets('offAllNamed into a redirect cycle also settles on not-found', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        unknownRoute: GetPage(name: '/404', page: () => const Text('lost')),
        getPages: [
          GetPage(name: '/', page: () => const Text('home')),
          GetPage(
            name: '/first',
            page: () => const Text('first'),
            middlewares: [RedirectToSecond()],
          ),
          GetPage(
            name: '/second',
            page: () => const Text('second'),
            middlewares: [RedirectToFirst()],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    Get.offAllNamed('/second');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/404');
    expect(find.text('lost'), findsOneWidget);
  });

  testWidgets('a plain redirect chain without a cycle still works', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Text('home')),
          GetPage(
            name: '/first',
            page: () => const Text('first'),
            middlewares: [RedirectToSecond()],
          ),
          GetPage(name: '/second', page: () => const Text('second')),
        ],
      ),
    );
    await tester.pumpAndSettle();

    Get.toNamed('/first');
    await tester.pumpAndSettle();

    expect(Get.currentRoute, '/second');
    expect(find.text('second'), findsOneWidget);
  });
}
