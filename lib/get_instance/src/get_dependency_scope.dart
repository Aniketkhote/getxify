import 'package:flutter/widgets.dart';
import '../../get_core/get_core.dart';
import 'extension_instance.dart';

/// A widget that manages the lifecycle of dependencies created within its scope.
///
/// A widget that manages the lifecycle of dependencies created within its scope.
///
/// When this widget is unmounted, it automatically deletes the dependencies
/// specified in [keys].
class GetDependencyScope extends StatefulWidget {
  final Widget child;
  final Set<String> keys;

  const GetDependencyScope({
    super.key,
    required this.child,
    this.keys = const {},
  });

  @override
  State<GetDependencyScope> createState() => _GetDependencyScopeState();
}

class _GetDependencyScopeState extends State<GetDependencyScope> {
  @override
  void dispose() {
    for (final key in widget.keys) {
      Get.delete(key: key);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
