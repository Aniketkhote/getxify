import 'package:getxify/getxify.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<HomeController>(() => HomeController(), fenix: true),
      Bind.lazyPut<DashboardController>(
        () => DashboardController(),
        fenix: true,
      ),
    ];
  }
}
