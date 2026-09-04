import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

import 'app/routes/app_pages.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';

void main() {
  runApp(
    GetMaterialApp(
      title: "GetXify Mart",
      debugShowCheckedModeBanner: false,
      binds: [Bind.put(AuthService()), Bind.put(CartService())],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      getPages: AppPages.routes,
      initialRoute: AppPages.initial,
    ),
  );
}
