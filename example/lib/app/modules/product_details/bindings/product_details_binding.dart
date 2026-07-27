import 'package:getxify/getxify.dart';

import '../controllers/product_details_controller.dart';

class ProductDetailsBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut<ProductDetailsController>(
        () => ProductDetailsController(Get.parameters['productId'] ?? ''),
        fenix: true,
      ),
    ];
  }
}
