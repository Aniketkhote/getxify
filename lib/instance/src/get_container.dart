import 'instance_builder_factory.dart';
import 'instance_info.dart';
import 'lifecycle.dart';

/// An isolated dependency injection container.
///
/// Encapsulates dependency registration, resolution, and lifecycle disposal,
/// allowing multiple isolated DI contexts (e.g. for multi-window applications,
/// modular subtrees, or concurrent unit test isolation).
class GetContainer {
  final Map<String, InstanceBuilderFactory<Object?>> _factories = {};

  /// All factories currently registered in this container.
  Map<String, InstanceBuilderFactory<Object?>> get factories => _factories;

  /// Retrieves an instance of type [S].
  S find<S>({String? tag}) {
    final key = _getKey(S, tag);
    if (_factories.containsKey(key)) {
      final dep = _factories[key]!;
      final instance = dep.getDependency() as S;
      if (!dep.isInit) {
        dep.isInit = true;
        if (instance is GetLifeCycleMixin) {
          instance.onStart();
        }
      }
      return instance;
    }
    throw InstanceNotFoundException(
      'Instance "$S" with tag "$tag" not found in GetContainer.',
    );
  }

  /// Injects an existing dependency [dependency] into this container.
  S put<S>(S dependency, {String? tag, bool permanent = false}) {
    final key = _getKey(S, tag);
    final factory = InstanceBuilderFactory<S>(
      isSingleton: true,
      builderFunc: () => dependency,
      permanent: permanent,
      isInit: true,
      fenix: false,
      tag: tag,
      lateRemove: null,
    );
    factory.dependency = dependency;
    _factories[key] = factory;
    if (dependency is GetLifeCycleMixin) {
      dependency.onStart();
    }
    return dependency;
  }

  /// Lazily registers an instance builder.
  void lazyPut<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool fenix = false,
  }) {
    final key = _getKey(S, tag);
    _factories[key] = InstanceBuilderFactory<S>(
      isSingleton: true,
      builderFunc: builder,
      permanent: false,
      isInit: false,
      fenix: fenix,
      tag: tag,
      lateRemove: null,
    );
  }

  /// Checks if an instance of [S] is registered.
  bool isRegistered<S>({String? tag}) {
    return _factories.containsKey(_getKey(S, tag));
  }

  /// Checks if an instance of [S] has been initialized.
  bool isPrepared<S>({String? tag}) {
    final key = _getKey(S, tag);
    return _factories.containsKey(key) && _factories[key]!.isInit;
  }

  /// Deletes a registered dependency.
  Future<bool> delete<S>({String? tag, bool force = false}) async {
    final key = _getKey(S, tag);
    if (!_factories.containsKey(key)) return false;
    final dep = _factories[key]!;
    if (dep.permanent && !force) return false;

    final instance = dep.dependency;
    if (instance is GetLifeCycleMixin) {
      instance.onDelete();
    }
    _factories.remove(key);
    return true;
  }

  /// Clears all registered instances, invoking `onDelete()` on active lifecycles.
  void reset() {
    for (final dep in _factories.values) {
      final instance = dep.dependency;
      if (instance is GetLifeCycleMixin) {
        instance.onDelete();
      }
    }
    _factories.clear();
  }

  String _getKey(Type type, String? tag) =>
      tag == null ? type.toString() : '$type$tag';
}
