import 'package:flutter/widgets.dart';

import '../../../core/core.dart';
import '../../../instance/instance.dart';

/// [GetView] is a lightweight [StatelessWidget] providing easy access to a controller
/// registered in dependency injection without calling `Get.find<Controller>()` manually.
///
/// Example:
/// ```dart
/// class AwesomeController extends GetxController {
///   final String title = 'My Awesome View';
/// }
///
/// class AwesomeView extends GetView<AwesomeController> {
///   const AwesomeView({super.key, super.tag});
///
///   @override
///   Widget build(BuildContext context) {
///     return Container(
///       padding: const EdgeInsets.all(20),
///       child: Text(controller.title),
///     );
///   }
/// }
/// ```
abstract class GetView<T> extends StatelessWidget {
  const GetView({super.key, this.tag});

  /// Optional tag parameter for tag-registered controllers (`Get.find<T>(tag: tag)`).
  final String? tag;

  /// Gets the controller instance from the dependency injection container.
  T get controller => Get.find<T>(tag: tag)!;

  @override
  Widget build(BuildContext context);
}
