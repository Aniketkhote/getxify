import '../../getxify.dart';

/// Callback type for building singleton or lazy instances of type [S].
typedef InstanceBuilderCallback<S> = S Function();

/// Callback type for building instances of type [S] on demand using [BuildContext].
typedef InstanceCreateBuilderCallback<S> = S Function(Object _);

/// Callback type for asynchronously building instances of type [S].
typedef AsyncInstanceBuilderCallback<S> = Future<S> Function();

/// Internal class to register instances with `Get.put<S>()`.
class InstanceBuilderFactory<S> {
  /// Marks the Builder as a single instance.
  /// For reusing [dependency] instead of [builderFunc]
  bool? isSingleton;

  /// When fenix mode is available, when a new instance is need
  /// Instance manager will recreate a new instance of S
  bool fenix;

  /// Stores the actual object instance when [isSingleton]=true.
  S? dependency;

  /// Generates (and regenerates) the instance when [isSingleton]=false.
  /// Usually used by factory methods
  InstanceBuilderCallback<S> builderFunc;

  /// Flag to persist the instance in memory.
  bool permanent = false;

  bool isInit = false;

  InstanceBuilderFactory<S>? lateRemove;

  bool isDirty = false;

  String? tag;

  /// The name of the route whose page binding created this registration,
  /// or `null` when it was not created by a page binding. Used to link the
  /// instance to the declaring page's route on its first resolution.
  final String? bindingOwnerRouteName;

  InstanceBuilderFactory({
    required this.isSingleton,
    required this.builderFunc,
    required this.permanent,
    required this.isInit,
    required this.fenix,
    required this.tag,
    required this.lateRemove,
    this.bindingOwnerRouteName,
  });

  void _showInitLog() {
    if (tag == null) {
      Get.log('Instance "$S" has been created');
    } else {
      Get.log('Instance "$S" has been created with tag "$tag"');
    }
  }

  /// Gets the actual instance by its [builderFunc] or the persisted instance.
  S getDependency() {
    if (isSingleton ?? false) {
      if (dependency case final dep?) {
        return dep;
      }
      _showInitLog();
      return dependency = builderFunc();
    }
    return builderFunc();
  }
}
