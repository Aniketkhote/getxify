# GetXify v5.0.0 Migration Guide (`MIGRATION_V5.md`)

This guide assists developers migrating to **GetXify v5.0.0** from legacy GetX or GetXify v4.x, covering all unreleased architectural modernizations, breaking changes, and new API features.

---

## 📋 Table of Contents
1. [Removal of Obsolete Hybrid Widgets](#1-removal-of-obsolete-hybrid-widgets)
2. [Element-Bound Dependency Injection & Removal of SmartManagement](#2-element-bound-dependency-injection--removal-of-smartmanagement)
3. [Sealed GetState<T> & Dart 3 Pattern Matching](#3-sealed-getstatet--dart-3-pattern-matching)
4. [Context-Aware Navigation Extensions](#4-context-aware-navigation-extensions)
5. [Native ListenableBuilder & State Engine Integration](#5-native-listenablebuilder--state-engine-integration)
6. [Unified Reactive Primitives & Dart 3 Typedefs](#6-unified-reactive-primitives--dart-3-typedefs)
7. [Modernized Uri-Based Route Tree Engine](#7-modernized-uri-based-route-tree-engine)

---

## 1. Removal of Obsolete Hybrid Widgets

### ❌ Removed: `GetWidget<T>`, `GetWidgetCache`, `GetResponsiveWidget<T>`
- **Why:** `GetWidget` cached controller instances using a hidden global `Expando` map. This caused memory leaks and unexpected controller retention during rapid route transitions.
- **Migration:** Migrate `GetWidget<T>` to `GetView<T>` or use `context.find<T>()`. Migrate `GetResponsiveWidget<T>` to `GetResponsiveView<T>`.

```dart
// ❌ BEFORE (v4.x)
class UserProfile extends GetWidget<UserController> {
  const UserProfile({super.key});
  @override
  Widget build(BuildContext context) {
    return Text(controller.name);
  }
}

// ✅ AFTER (v5.0.0)
class UserProfile extends GetView<UserController> {
  const UserProfile({super.key});
  @override
  Widget build(BuildContext context) {
    return Text(controller.name);
  }
}
```

### ❌ Removed: `GetX<T>` and `MixinBuilder` Widgets
- **Why:** `GetX<T>` and `MixinBuilder` were hybrid wrappers combining `GetBuilder` updaters with `Obx` stream listeners, introducing unnecessary runtime overhead and verbose type parameters (`GetX<UserController>`).
- **Migration:** Use `Obx(() => ...)` for reactive observables (`.obs`), or `GetBuilder<UserController>(...)` for manual `update()` triggers.

```dart
// ❌ BEFORE (v4.x)
GetX<UserController>(
  init: UserController(),
  builder: (controller) => Text(controller.name.value),
)

// ✅ AFTER (v5.0.0)
Obx(() => Text(controller.name.value))
```

---

## 2. Element-Bound Dependency Injection & Removal of `SmartManagement`

- **Why:** Legacy `SmartManagement` configurations (`SmartManagement.full`, `onlyBuilder`, `keepFactory`) and `RouterReportManager` relied on complex global route heuristics that could leak memory or prematurely dispose controllers when dependencies crossed navigation boundaries.
- **Migration:** Dependency lifecycles are now bound strictly to the widget Element tree via `GetDependencyScope`. No configuration is required.
- **Removed Parameters:** The `smartManagement` parameter on `GetMaterialApp` and `GetCupertinoApp` has been removed.

```dart
// ❌ BEFORE (v4.x)
GetMaterialApp(
  smartManagement: SmartManagement.full,
  home: HomePage(),
)

// ✅ AFTER (v5.0.0)
GetMaterialApp(
  home: HomePage(), // Automatically uses element-bound GetDependencyScope
)
```

---

## 3. State Restoration Support (`GetRestorationMixin`)

- **Feature:** Added `GetRestorationMixin` providing `restore(key, defaultValue)` and `persist(key, value)` methods to allow `GetxController` states to seamlessly survive OS process termination on Android and iOS via Flutter's native `RestorationBucket`.

```dart
// ✅ State Restoration in GetxController
class CounterController extends GetxController with GetRestorationMixin {
  @override
  String? get restorationId => 'counter_controller';

  int get count => restore('count', 0);
  set count(int val) => persist('count', val);
}
```

---

## 4. Sealed `GetState<T>` & Dart 3 Pattern Matching

- **Feature:** `GetStatus<T>` (`GetState<T>`) is now a sealed class hierarchy supporting exhaustive Dart 3 switch pattern matching as well as functional `.when(...)` and `.maybeWhen(...)` methods.

```dart
// ✅ Option A: Functional Pattern Matching
Widget build(BuildContext context) {
  return controller.status.when(
    loading: () => const CircularProgressIndicator(),
    success: (data) => UserList(data: data),
    error: (err) => Text('Error: $err'),
    empty: () => const Text('No items found'),
  );
}

// ✅ Option B: Native Dart 3 Switch Expressions
Widget build(BuildContext context) {
  return switch (controller.status) {
    LoadingStatus() => const CircularProgressIndicator(),
    SuccessStatus(:final data) => UserList(data: data),
    ErrorStatus(:final error) => Text('Error: $error'),
    EmptyStatus() => const Text('No items found'),
    CustomStatus() => const SizedBox.shrink(),
  };
}
```

---

## 4. Context-Aware Navigation Extensions

- **Feature:** Added `ContextNavigationExt` on `BuildContext` to enable context-aware routing that automatically respects local nested router scopes instead of always falling back to global `Get.key`.

```dart
// ✅ Modern Context-Aware Routing
void onNavigate(BuildContext context) {
  context.toNamed('/details');
  context.to(DetailsPage());
  context.offNamed('/home');
  context.back();
}
```

---

## 5. Native `ListenableBuilder` & State Engine Integration

- **Feature:** `GetBuilder` and `BindElement` now utilize Flutter's native `ListenableBuilder` and $O(1)$ `ChangeNotifier` engines under the hood. Custom `_updaters` array management has been removed from the state core.
- **Timing Bug Fix:** Changes to `tag` on rebuild (`tag: oldTag` $\rightarrow$ `tag: newTag`) safely defer old controller disposal via `scheduleMicrotask`, preventing premature controller deletion while descendant widgets are unmounting.

---

## 6. Unified Reactive Primitives & Dart 3 Typedefs

- **Feature:** Custom primitive wrapper classes (`RxInt`, `RxBool`, `RxString`, `RxDouble`) are consolidated into Dart 3 `typedef`s over `Rx<T>`.
- **Operators:** Primitive operators (`+`, `-`, etc.) live in extension classes (`RxIntExt`, `RxNumExt`, `RxStringExt`), preserving full backward compatibility while simplifying the class hierarchy.

```dart
// Native type safety with Dart 3 typedefs
RxInt counter = 0.obs;      // typedef RxInt = Rx<int>;
RxString name = 'Alex'.obs; // typedef RxString = Rx<String>;
```

---

## 7. Modernized Uri-Based Route Tree Engine

- **Feature:** `ParseRouteTree` replaced runtime `RegExp` pattern matching (`PathDecoded`) with native `Uri` string segment iterations.
- **Benefit:** Significantly speeds up route resolution, path parameter parsing, and query string extraction during screen transitions.

---

> 📖 For full release notes and commit history, refer to [CHANGELOG.md](file:///home/aniket/Desktop/getxify/CHANGELOG.md).
