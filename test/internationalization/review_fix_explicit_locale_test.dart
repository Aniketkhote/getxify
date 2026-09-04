import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

void main() {
  setUp(() {
    Get.locale = null;
  });

  tearDown(() {
    Get.locale = null;
    Get.reset();
  });

  Future<void> setDeviceLocale(WidgetTester tester, Locale locale) async {
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.localesTestValue = [locale];
    await tester.pumpAndSettle();
  }

  Future<void> resetDeviceLocale(WidgetTester tester) async {
    tester.platformDispatcher.clearLocaleTestValue();
    tester.platformDispatcher.clearLocalesTestValue();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'explicit Get.updateLocale equal to the auto-applied device locale '
    'is not clobbered by a later device locale change',
    (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          getPages: [GetPage(name: '/', page: () => const Home())],
        ),
      );
      await tester.pumpAndSettle();

      // Device locale 'es' is auto-adopted because the app never set one.
      await setDeviceLocale(tester, const Locale('es'));
      expect(Get.locale, const Locale('es'));

      // The user now EXPLICITLY selects Spanish, which happens to equal the
      // locale that was just auto-applied from the device.
      Get.updateLocale(const Locale('es'));
      await tester.pumpAndSettle();
      expect(Get.locale, const Locale('es'));

      // A later OS locale change must NOT override the explicit choice.
      await setDeviceLocale(tester, const Locale('fr'));
      expect(Get.locale, const Locale('es'));

      await resetDeviceLocale(tester);
    },
  );

  testWidgets(
    'automatic device locale adoption alone keeps following the device',
    (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          getPages: [GetPage(name: '/', page: () => const Home())],
        ),
      );
      await tester.pumpAndSettle();

      // Auto-adoption must not be recorded as an explicit choice, so the
      // app keeps following subsequent device locale changes.
      await setDeviceLocale(tester, const Locale('es'));
      expect(Get.locale, const Locale('es'));

      await setDeviceLocale(tester, const Locale('fr'));
      expect(Get.locale, const Locale('fr'));

      await resetDeviceLocale(tester);
    },
  );
}
