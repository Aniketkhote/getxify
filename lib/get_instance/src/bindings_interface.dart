import '../../get_core/get_core.dart';
import 'extension_instance.dart';

/// An interface to define dependency injection rules for routes or specific flows in GetXify v5.0.0.
///
/// Classes implementing [Binding] override the [dependencies] method
/// to register controllers, services, or other objects before a route/page is built
/// or when entering a specific scope.
///
/// Options for defining bindings:
///
/// 1. **Class-based Binding:**
/// ```dart
/// class HomeBinding extends Binding {
///   @override
///   void dependencies() {
///     Get.put(HomeController());
///   }
/// }
/// ```
///
/// 2. **Inline Direct Bindings (`Binding.put` / `Binding.lazyPut`):**
/// ```dart
/// GetPage(
///   name: '/home',
///   page: () => HomePage(),
///   bindings: [
///     Binding.put(HomeController()),
///     Binding.lazyPut(() => UserController()),
///   ],
/// );
/// ```
///
/// 3. **Inline Functional Builder (`Binding.builder`):**
/// ```dart
/// GetPage(
///   name: '/home',
///   page: () => HomePage(),
///   bindings: [
///     Binding.builder(() {
///       Get.put(HomeController());
///     }),
///   ],
/// );
/// ```
abstract class Binding {
  const Binding();

  /// Defines and registers dependencies.
  void dependencies();

  /// Creates a [Binding] using an inline builder callback.
  /// Accepts either `void Function()` or `void Function(GetInterface i)`.
  factory Binding.builder(Function builder) = _DelegateBinding;

  /// Creates a [Binding] that immediately registers [dependency].
  static Binding put<S>(
    S dependency, {
    String? tag,
    bool permanent = false,
  }) => _PutBinding<S>(dependency, tag: tag, permanent: permanent);

  /// Creates a [Binding] that lazily initializes [builder] on first access.
  static Binding lazyPut<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool fenix = false,
  }) => _LazyPutBinding<S>(builder, tag: tag, fenix: fenix);

  /// Creates a [Binding] that registers a factory [builder] created on demand.
  static Binding create<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = false,
  }) => _CreateBinding<S>(builder, tag: tag, permanent: permanent);
}

class _PutBinding<S> implements Binding {
  final S dependency;
  final String? tag;
  final bool permanent;

  const _PutBinding(this.dependency, {this.tag, this.permanent = false});

  @override
  void dependencies() {
    Get.put<S>(dependency, tag: tag, permanent: permanent);
  }
}

class _LazyPutBinding<S> implements Binding {
  final InstanceBuilderCallback<S> builder;
  final String? tag;
  final bool fenix;

  const _LazyPutBinding(this.builder, {this.tag, this.fenix = false});

  @override
  void dependencies() {
    Get.lazyPut<S>(builder, tag: tag, fenix: fenix);
  }
}

class _CreateBinding<S> implements Binding {
  final InstanceBuilderCallback<S> builder;
  final String? tag;
  final bool permanent;

  const _CreateBinding(this.builder, {this.tag, this.permanent = false});

  @override
  void dependencies() {
    Get.spawn<S>(builder, tag: tag, permanent: permanent);
  }
}

class _DelegateBinding implements Binding {
  final Function _builder;

  const _DelegateBinding(this._builder);

  @override
  void dependencies() {
    final builder = _builder;
    if (builder is void Function(GetInterface)) {
      builder(Get);
    } else if (builder is void Function()) {
      builder();
    } else {
      try {
        (builder as dynamic)();
      } catch (_) {
        (builder as dynamic)(Get);
      }
    }
  }
}

/// A callback used to lazily initialize or register bindings.
typedef BindingBuilderCallback = void Function();
