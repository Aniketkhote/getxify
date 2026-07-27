import 'package:getxify/getxify.dart';

import '../controllers/profile_controller.dart';

class ProfileBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<ProfileController>(() => ProfileController(), fenix: true),
    ];
  }
}
